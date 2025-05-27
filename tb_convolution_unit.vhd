-- tb_convolution_unit.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.gaussian_filter_pkg.all;
use work.all;

entity tb_convolution_unit is
--  Port ( );
end tb_convolution_unit;

architecture Behavioral of tb_convolution_unit is

    -- Testbench specific constants
    constant TB_CLK_PERIOD      : time    := 10 ns;
    
    -- DUT signals
    signal clk_tb             : std_logic := '0';
    signal reset_n_tb         : std_logic;
    signal ena_tb             : std_logic := '0';
        
    -- 3x3 Pixel window inputs
    signal p00_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p01_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p02_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p10_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p11_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p12_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p20_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p21_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal p22_tb           : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    
    -- Output
    signal result_pixel_tb  : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    signal conv_done_o_tb   : std_logic; -- Signals that the result is ready (1 cycle after ena)
   

begin

    -- Instantiate the DUT
    dut_convolution_unit : entity work.convolution_unit
        port map (
            clk              => clk_tb,
            reset_n          => reset_n_tb,
            ena              => ena_tb,
            
            p00              => p00_tb,
            p01              => p01_tb,
            p02              => p02_tb,
            p10              => p10_tb,
            p11              => p11_tb,
            p12              => p12_tb,
            p20              => p20_tb,
            p21              => p21_tb,
            p22              => p22_tb,
            
            result_pixel     => result_pixel_tb,
            conv_done_o      => conv_done_o_tb
        );
    
    -- Clock generation process
    clk_process : process
    begin
        clk_tb <= '0';
        wait for TB_CLK_PERIOD / 2;
        clk_tb <= '1';
        wait for TB_CLK_PERIOD / 2;
    end process clk_process;        
    
    -- Stimulus process
    stimulus_process : process
    begin
        -- Reset
        reset_n_tb <= '0';
        wait for TB_CLK_PERIOD * 2;
        reset_n_tb <= '1';
        wait for TB_CLK_PERIOD;
    
        -- Init Pixel Window
        p00_tb <= std_logic_vector(to_unsigned(1, 8));
        p01_tb <= std_logic_vector(to_unsigned(2, 8));
        p02_tb <= std_logic_vector(to_unsigned(3, 8));
        p10_tb <= std_logic_vector(to_unsigned(4, 8));
        p11_tb <= std_logic_vector(to_unsigned(5, 8));
        p12_tb <= std_logic_vector(to_unsigned(6, 8));
        p20_tb <= std_logic_vector(to_unsigned(7, 8));
        p21_tb <= std_logic_vector(to_unsigned(8, 8));
        p22_tb <= std_logic_vector(to_unsigned(9, 8));
        
        -- Start Convolution
        ena_tb <= '1';
        wait for TB_CLK_PERIOD;
        wait;
                  
    end process stimulus_process;
    
end Behavioral;
