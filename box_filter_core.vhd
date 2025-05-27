-- box_filter_core.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.box_filter_pkg.all;

entity box_filter_core is
    generic (
        IMAGE_WIDTH  : natural := IMAGE_WIDTH_CONST; 
        IMAGE_HEIGHT : natural := IMAGE_HEIGHT_CONST;
        ADDR_WIDTH   : natural := natural(ceil(log2(real(IMAGE_WIDTH_CONST * IMAGE_HEIGHT_CONST))))
    );
    port (
        clk               : in  std_logic;
        reset_n           : in  std_logic;
        start_process_i   : in  std_logic;
        processing_done_o : out std_logic;

        -- Input Image RAM Interface
        in_ram_addr_o     : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        in_ram_rd_en_o    : out std_logic;
        in_ram_dout_i     : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);

        -- Output Image RAM Interface
        out_ram_addr_o    : out std_logic_vector(ADDR_WIDTH-1 downto 0);
        out_ram_we_o      : out std_logic;
        out_ram_rd_en_o   : out std_logic;
        out_ram_din_o     : out std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0)
    );
end entity box_filter_core;

architecture fsm of box_filter_core is

    -- FSM states
    type state_type is (
        S_IDLE,
        S_INIT_ROW_COL,
        S_FETCH_WINDOW_SETUP,
        S_FETCH_PIXEL,      
        S_LOAD_PIXEL_INIT,
        S_LOAD_PIXEL,
        S_START_CONV,
        S_WAIT_CONV,
        S_NEXT_PIXEL_COL,
        S_NEXT_PIXEL_ROW,
        S_DONE
    );
    signal current_state, next_state : state_type;

    -- Counters for image traversal (output pixel coordinates)
    signal y_out_cnt, next_y_out : integer range 0 to IMAGE_HEIGHT-1; -- Current row for output
    signal x_out_cnt, next_x_out : integer range 0 to IMAGE_WIDTH-1;  -- Current col for output

    -- Counters for fetching 3x3 window
    signal win_row_fetch_cnt, next_row_fetch : integer range 0 to 2; -- 0, 1, 2 for rows of window
    signal win_col_fetch_cnt, next_col_fetch : integer range 0 to 2; -- 0, 1, 2 for cols of window
    
    -- Registers for the 3x3 pixel window
    signal pixel_window, next_pixel_window : pixel_window_array;

    -- Convolution unit signals
    signal conv_ena        : std_logic;
    signal conv_done_s     : std_logic;
    signal conv_result_s   : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    
    -- Internal control signals
    signal current_in_ram_addr, next_in_ram_addr  : unsigned(ADDR_WIDTH-1 downto 0);
    signal current_out_ram_addr, next_out_ram_addr: unsigned(ADDR_WIDTH-1 downto 0);
    
    -- Image ram read delay
    signal rd_dly, next_dly : std_logic := '0';


begin

    -- Instantiate Convolution Unit
    conv_unit_inst : entity work.convolution_unit
        port map (
            clk          => clk,
            reset_n      => reset_n,
            ena          => conv_ena,
            p00          => pixel_window(0,0), p01 => pixel_window(0,1), p02 => pixel_window(0,2),
            p10          => pixel_window(1,0), p11 => pixel_window(1,1), p12 => pixel_window(1,2),
            p20          => pixel_window(2,0), p21 => pixel_window(2,1), p22 => pixel_window(2,2),
            result_pixel => conv_result_s,
            conv_done_o  => conv_done_s
        );

    -- State Register
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= S_IDLE;
            current_in_ram_addr <= (others => '0');
            current_out_ram_addr <= (others => '0');
            pixel_window(0, 0) <= (others => '0');
            pixel_window(0, 1) <= (others => '0');
            pixel_window(0, 2) <= (others => '0');
            pixel_window(1, 0) <= (others => '0');
            pixel_window(1, 1) <= (others => '0');
            pixel_window(1, 2) <= (others => '0');
            pixel_window(2, 0) <= (others => '0');
            pixel_window(2, 1) <= (others => '0');
            pixel_window(2, 2) <= (others => '0');
            rd_dly <= '0';
            win_row_fetch_cnt <= 0;
            win_col_fetch_cnt <= 0;
            y_out_cnt <= 0;
            x_out_cnt <= 0;
        elsif rising_edge(clk) then
            current_state <= next_state;
            win_row_fetch_cnt <= next_row_fetch;
            win_col_fetch_cnt <= next_col_fetch;
            current_in_ram_addr <= next_in_ram_addr;
            current_out_ram_addr <= next_out_ram_addr;
            y_out_cnt <= next_y_out;
            x_out_cnt <= next_x_out;
            pixel_window <= next_pixel_window;
            rd_dly <= next_dly;
        end if;
    end process;

    -- Next State Logic & Outputs
    --process(current_state, start_process_i, conv_done_s, y_out_cnt, x_out_cnt, 
    --        win_row_fetch_cnt, win_col_fetch_cnt, in_ram_dout_i, conv_result_s)
    process(current_state, start_process_i, conv_done_s, win_row_fetch_cnt, win_col_fetch_cnt, y_out_cnt, rd_dly,
            x_out_cnt, current_in_ram_addr, in_ram_dout_i, current_out_ram_addr, conv_result_s, pixel_window)
    variable x_fetch, y_fetch : integer; -- Absolute coordinates for fetching
    begin
        -- Default outputs
        next_state          <= current_state;
        next_row_fetch      <= win_row_fetch_cnt;         
        next_col_fetch      <= win_col_fetch_cnt;
        next_in_ram_addr    <= current_in_ram_addr;
        next_out_ram_addr   <= current_out_ram_addr;
        next_y_out          <= y_out_cnt;
        next_x_out          <= x_out_cnt;
        next_pixel_window   <= pixel_window;
        next_dly            <= rd_dly;    
        processing_done_o   <= '0';
        in_ram_addr_o       <= std_logic_vector(current_in_ram_addr);
        in_ram_rd_en_o      <= '1';
        out_ram_addr_o      <= std_logic_vector(current_out_ram_addr);
        out_ram_rd_en_o     <= '0';
        out_ram_we_o        <= '0';
        out_ram_din_o       <= (others => '0');
        conv_ena            <= '0';

        case current_state is
            when S_IDLE =>
                if start_process_i = '1' then
                    next_state <= S_INIT_ROW_COL;
                end if;

            when S_INIT_ROW_COL =>
                next_y_out <= 0; -- Start from the first row for output
                next_x_out <= 0; -- Start from the first col for output
                next_state <= S_FETCH_WINDOW_SETUP;
                
            
            when S_FETCH_WINDOW_SETUP =>
                -- Start fetching for the window centered at (x_out_cnt, y_out_cnt)
                -- The top-left of the 3x3 window is (x_out_cnt-1, y_out_cnt-1)
                next_row_fetch <= 0;
                next_col_fetch <= 0;
                next_state <= S_FETCH_PIXEL;

            when S_FETCH_PIXEL =>
                -- Calculate address for current pixel in the 3x3 window
                y_fetch := y_out_cnt - 1 + win_row_fetch_cnt;
                x_fetch := x_out_cnt - 1 + win_col_fetch_cnt;

                -- Replicate border pixels to handle boundary
                if y_fetch < 0 then y_fetch := 0;
                elsif y_fetch >= IMAGE_HEIGHT then y_fetch := IMAGE_HEIGHT - 1;
                end if;
                if x_fetch < 0 then x_fetch := 0;
                elsif x_fetch >= IMAGE_WIDTH then x_fetch := IMAGE_WIDTH - 1;
                end if;
                
                next_in_ram_addr <= to_unsigned(y_fetch * IMAGE_WIDTH + x_fetch, ADDR_WIDTH);
                next_state <= S_LOAD_PIXEL_INIT;
                
            when S_LOAD_PIXEL_INIT =>
                -- Input RAM has two cycle read latency
                if rd_dly = '0' then
                    next_dly <= '1';
                elsif rd_dly = '1' then
                    next_dly <= '0';
                    next_state <= S_LOAD_PIXEL;
                end if;

            when S_LOAD_PIXEL =>
                in_ram_rd_en_o <= '1';
                next_pixel_window(win_row_fetch_cnt, win_col_fetch_cnt) <= in_ram_dout_i;
                

                if win_col_fetch_cnt = 2 then
                    if win_row_fetch_cnt = 2 then
                        -- All 9 pixels fetched
                        next_state <= S_START_CONV;
                    else
                        next_row_fetch <= win_row_fetch_cnt + 1;
                        next_col_fetch <= 0;
                        next_state <= S_FETCH_PIXEL;
                    end if;
                else
                    next_col_fetch <= win_col_fetch_cnt + 1;
                    next_state <= S_FETCH_PIXEL;
                end if;

            when S_START_CONV =>
                next_state <= S_WAIT_CONV;
                next_out_ram_addr <= to_unsigned(y_out_cnt * IMAGE_WIDTH + x_out_cnt, ADDR_WIDTH);

            when S_WAIT_CONV =>
                conv_ena <= '1';
                if conv_done_s = '1' then
                    conv_ena <= '0'; 
                    out_ram_rd_en_o <= '1';
                    out_ram_we_o    <= '1';
                    out_ram_din_o   <= conv_result_s;
                    next_state      <= S_NEXT_PIXEL_COL;
                else
                    next_state <= S_WAIT_CONV;
                end if;

            when S_NEXT_PIXEL_COL =>
                out_ram_we_o <= '0'; -- Stop writing
                if x_out_cnt = IMAGE_WIDTH - 1 then
                    next_x_out <= 0;
                    next_state <= S_NEXT_PIXEL_ROW;
                else
                    next_x_out <= x_out_cnt + 1;
                    next_state <= S_FETCH_WINDOW_SETUP;
                end if;

            when S_NEXT_PIXEL_ROW =>
                if y_out_cnt = IMAGE_HEIGHT - 1 then
                    next_state <= S_DONE;
                else
                    next_y_out <= y_out_cnt + 1;
                    next_state <= S_FETCH_WINDOW_SETUP;
                end if;

            when S_DONE =>
                processing_done_o <= '1';
                next_state <= S_IDLE;
                
            when others =>
                next_state <= S_IDLE;

        end case;
    end process;
    
end architecture fsm;
