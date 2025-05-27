-- convolution_unit.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.box_filter_pkg.all;
use work.lzc_wire.all;
use work.fp_wire.all;
use work.all;

entity convolution_unit is
    port (
        clk           : in  std_logic;
        reset_n       : in  std_logic;
        ena           : in  std_logic;
        
        -- 3x3 Pixel window inputs
        p00           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p01           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p02           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p10           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p11           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p12           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p20           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p21           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        p22           : in  std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        
        -- Output
        result_pixel  : out std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
        conv_done_o   : out std_logic
    );
end entity convolution_unit;

architecture behavioral of convolution_unit is
    -- Internal array
    signal flat_window : flat_window_array;

    -- In and Out for FPU
	signal fpu_i : fp_unit_in_type;
	signal fpu_o : fp_unit_out_type;
	
	-- State machine registers
	signal cntr, next_cntr : integer range 0 to 255;
	signal fpu_i_en, next_fpu_i_en : std_logic_vector(1 downto 0);
	signal sum, next_sum : std_logic_vector(31 downto 0);
	signal float_window, next_float_window : float_window_array;
	
	TYPE states IS (
        S_IDLE,
        S_I2F,
        S_DONE,
        S_MADD
    );
    signal current_state, next_state : states;

    component fp_unit
		port(
			reset     : in  std_logic;
			clock     : in  std_logic;
			fp_unit_i : in  fp_unit_in_type;
			fp_unit_o : out fp_unit_out_type;
			clear     : in  std_logic
		);
	end component;

begin

    fp_unit_comp : fp_unit
    port map(
        reset     => reset_n,
        clock     => clk,
        fp_unit_i => fpu_i,
        fp_unit_o => fpu_o,
        clear     => '0'
    );
    
    -- Place pixels in iterable array
    flat_window(0) <= p00;
    flat_window(1) <= p01;
    flat_window(2) <= p02;
    flat_window(3) <= p10;
    flat_window(4) <= p11;
    flat_window(5) <= p12;
    flat_window(6) <= p20;
    flat_window(7) <= p21;
    flat_window(8) <= p22;
    
    -- State Register
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            current_state <= S_IDLE;
            cntr            <= 0;
            float_window(0) <= (others => '0');
            float_window(1) <= (others => '0');
            float_window(2) <= (others => '0');
            float_window(3) <= (others => '0');
            float_window(4) <= (others => '0');
            float_window(5) <= (others => '0');
            float_window(6) <= (others => '0');
            float_window(7) <= (others => '0');
            float_window(8) <= (others => '0');
            fpu_i_en        <= (others => '0');
            sum             <= (others => '0');
            
        elsif rising_edge(clk) then
            current_state <= next_state;
            cntr <= next_cntr;
            fpu_i_en <= next_fpu_i_en;
            sum <= next_sum;
            float_window <= next_float_window;
        end if;
    end process;
    
    -- Next State Logic & Outputs
    process(current_state, cntr, fpu_i_en, ena, sum, flat_window, float_window, fpu_o.fp_exe_o.result)
    
    begin
    -- Default outputs
    next_state <= current_state;
    conv_done_o <= '0';
    next_cntr <= cntr;
    next_fpu_i_en <= fpu_i_en;
    next_sum <= sum;
    next_float_window <= float_window;
    fpu_i.fp_exe_i.fmt <= "00";
    fpu_i.fp_exe_i.rm <= "000";
    fpu_i.fp_exe_i.op <= init_fp_operation;
    fpu_i.fp_exe_i.enable <= '0';
    fpu_i.fp_exe_i.data1 <= (31 downto 0 => '0');
    fpu_i.fp_exe_i.data2 <= (31 downto 0 => '0');
    fpu_i.fp_exe_i.data3 <= (31 downto 0 => '0');
    result_pixel <= "00000000";
    
    case current_state is
        when S_IDLE =>
            if ena = '1' then
                    next_state <= S_I2F;
                    
                    next_fpu_i_en <= "00";
                    next_cntr <= 0;
            end if;
        
        -- Convert UINT8 pixels to SP32    
        when S_I2F =>
            -- Set FPU Values
            fpu_i.fp_exe_i.enable <= '1';
            fpu_i.fp_exe_i.op <= OP_I2F; -- UINT32 to FP32
           
            
            if cntr < 9 then
                fpu_i.fp_exe_i.data1 <= (31 downto p00'length => '0') & flat_window(cntr); -- load UINT8 pixel to FPU as UINT32
                if fpu_i_en = "00" then 
                    next_fpu_i_en <= "01"; 
                elsif fpu_i_en = "01" then
                    next_float_window(cntr) <= fpu_o.fp_exe_o.result; -- load FP32 pixel from FPU
                    next_fpu_i_en <= "00"; 
                    next_cntr <= cntr + 1; 
                end if;
                
            elsif cntr >= 9 then
                next_state <= S_MADD;
                next_cntr <= 0;
                next_sum <= (others => '0');
            end if;
            
        -- Calculate sum of all Kernel*Pixel Products    
        when S_MADD =>
            -- Set FPU Values
            fpu_i.fp_exe_i.enable <= '1';
            fpu_i.fp_exe_i.op <= OP_MADD; -- (data1 * data2) + data3
            fpu_i.fp_exe_i.data3 <= sum; -- accumulating sum
            
            if cntr < 9 then
                fpu_i.fp_exe_i.data1 <= float_window(cntr); -- load FP32 pixel
                fpu_i.fp_exe_i.data2 <= KERNEL(cntr); -- load kernel value
                if fpu_i_en = "00" then
                    next_fpu_i_en <= "01";
                elsif fpu_i_en = "01" then -- Result is ready after 3 cycles
                    next_fpu_i_en <= "10";
                elsif fpu_i_en = "10" then
                    next_sum <= fpu_o.fp_exe_o.result; -- (data1 * data2) + data3
                    next_fpu_i_en <= "00"; 
                    next_cntr <= cntr + 1;
                end if;
            
            elsif cntr >= 9 then
                next_state <= S_DONE;
                next_cntr <= 0;
                fpu_i.fp_exe_i.enable <= '0';
            end if;
        
        -- Convert back to UINT32    
        when S_DONE =>
            -- Set FPU Values
            fpu_i.fp_exe_i.enable <= '1';
            fpu_i.fp_exe_i.op <= OP_F2I; -- FP32 to UINT32
            fpu_i.fp_exe_i.data2 <= (31 downto 0 => '0');
            fpu_i.fp_exe_i.data3 <= (31 downto 0 => '0');
            fpu_i.fp_exe_i.data1 <= sum; -- load UINT8 pixel to FPU as UINT32
            
            if fpu_i_en = "00" then 
                    next_fpu_i_en <= "01";
            elsif fpu_i_en = "01" then
                    result_pixel <= fpu_o.fp_exe_o.result(7 downto 0); -- Output final pixel
                    conv_done_o <= '1';
                    next_state <= S_IDLE;
            end if;
            
        when others =>
            next_state <= S_IDLE;
    end case;
    end process;

end architecture behavioral;
