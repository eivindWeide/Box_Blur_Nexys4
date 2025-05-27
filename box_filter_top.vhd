-- box_filter_top.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.box_filter_pkg.all;

entity box_filter_top is
    generic (
        IMAGE_WIDTH  : natural := IMAGE_WIDTH_CONST; 
        IMAGE_HEIGHT : natural := IMAGE_HEIGHT_CONST;
        RAM_ADDR_WIDTH : natural := natural(ceil(log2(real(IMAGE_WIDTH_CONST * IMAGE_HEIGHT_CONST))))
    );
    port (
        clk     : in  std_logic;
        reset_n : in  std_logic;
        start_i : in  std_logic;
        done_o  : out std_logic
        
    );
end entity box_filter_top;

architecture structural of box_filter_top is

    -- Input Image RAM signals
    signal in_ram_addr     : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
    signal in_ram_rd_en    : std_logic;
    signal in_ram_dout     : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);

    -- Output Image RAM signals
    signal out_ram_addr    : std_logic_vector(RAM_ADDR_WIDTH-1 downto 0);
    signal out_ram_rd_en   : std_logic;
    signal out_ram_we      : std_logic;
    signal out_ram_din     : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal out_ram_dout       : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);

Component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

begin
    
    -- Block RAM IP with pre-loaded image
    input_ram_inst : blk_mem_gen_0
    port map (
        clka => clk,
        ena => in_ram_rd_en,
        wea => "0",
        addra => in_ram_addr,
        dina => (others => '0'),
        douta => in_ram_dout
  );

    -- Instantiate Output Image RAM
    output_ram_inst : entity work.ram_sync
        generic map (
            DATA_WIDTH => PIXEL_DATA_WIDTH,
            ADDR_WIDTH => RAM_ADDR_WIDTH
        )
        port map (
            clk   => clk,
            ena   => out_ram_rd_en,
            we    => out_ram_we,
            addr  => out_ram_addr,
            din   => out_ram_din,
            dout  => out_ram_dout
        );

    -- Instantiate Box Filter Core
    core_inst : entity work.box_filter_core
        generic map (
            IMAGE_WIDTH  => IMAGE_WIDTH,
            IMAGE_HEIGHT => IMAGE_HEIGHT,
            ADDR_WIDTH   => RAM_ADDR_WIDTH
        )
        port map (
            clk               => clk,
            reset_n           => reset_n,
            start_process_i   => start_i,
            processing_done_o => done_o,
            in_ram_addr_o     => in_ram_addr,
            in_ram_rd_en_o    => in_ram_rd_en,
            in_ram_dout_i     => in_ram_dout,
            out_ram_rd_en_o   => out_ram_rd_en,
            out_ram_addr_o    => out_ram_addr,
            out_ram_we_o      => out_ram_we,
            out_ram_din_o     => out_ram_din
        );

end architecture structural;
