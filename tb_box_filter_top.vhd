-- tb_box_filter_top.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all; -- For ceil, log2
use work.box_filter_pkg.all; -- Make sure this is compiled first

entity tb_box_filter_top is
end entity tb_box_filter_top;

architecture behavioral of tb_box_filter_top is

    -- Testbench specific constants
    constant TB_CLK_PERIOD      : time    := 10 ns;
    constant TB_IMAGE_WIDTH     : natural := 64;
    constant TB_IMAGE_HEIGHT    : natural := 64;
    constant TB_RAM_ADDR_WIDTH  : natural := natural(ceil(log2(real(TB_IMAGE_WIDTH * TB_IMAGE_HEIGHT))));

    -- DUT signals
    signal clk_tb             : std_logic := '0';
    signal reset_n_tb         : std_logic;
    signal start_i_tb         : std_logic := '0';
    signal done_o_tb          : std_logic;
    signal output_tb          : std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);

begin

    -- Instantiate the DUT
    dut_box_filter_top : entity work.box_filter_top
        generic map (
            IMAGE_WIDTH    => TB_IMAGE_WIDTH,
            IMAGE_HEIGHT   => TB_IMAGE_HEIGHT,
            RAM_ADDR_WIDTH => TB_RAM_ADDR_WIDTH
        )
        port map (
            clk              => clk_tb,
            reset_n          => reset_n_tb,
            start_i          => start_i_tb,
            done_o           => done_o_tb
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
        variable pixel_value : std_logic_vector(7 downto 0);
        variable pixel_value_num : Integer;
    begin
        report "TB: Starting Testbench for Gaussian Filter" severity note;

        -- 1. Apply Reset
        reset_n_tb <= '0';
        wait for TB_CLK_PERIOD * 2;
        reset_n_tb <= '1';
        wait for TB_CLK_PERIOD;
        report "TB: Reset released." severity note;

        -- 2. Start Processing
        report "TB: Asserting start_i signal." severity note;
        start_i_tb <= '1';
        wait for TB_CLK_PERIOD;
        start_i_tb <= '0';
        report "TB: start_i de-asserted. Waiting for done_o..." severity note;

        -- 3. Wait for DUT to finish (done_o = '1')
        wait until done_o_tb = '1' or now > 10 ms; -- Timeout to prevent infinite loop
        if done_o_tb = '1' then
            report "TB: DUT processing finished (done_o asserted)." severity note;
        else
            report "TB: Timeout waiting for done_o!" severity error;
            report "TB: Testbench FAILED due to timeout." severity failure;
            wait; -- Stop simulation
        end if;
        wait for TB_CLK_PERIOD; -- Give a cycle after done

        report "TB: Testbench finished successfully." severity note;
        wait; -- End of simulation
    end process stimulus_process;

end architecture behavioral;
