-- ram_sync.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_sync is
    generic (
        DATA_WIDTH : natural := 8;
        ADDR_WIDTH : natural := 12  -- 2^12 = 4096 addresses
    );
    port (
        clk   : in  std_logic;
        ena   : in  std_logic; -- RAM enable
        we    : in  std_logic; -- Write enable (1 for write, 0 for read)
        addr  : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        din   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity ram_sync;

architecture behavioral of ram_sync is
    -- RAM type
    type ram_type is array (0 to 2**ADDR_WIDTH - 1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    signal memory : ram_type;

    signal read_addr_reg : std_logic_vector(ADDR_WIDTH-1 downto 0);
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if ena = '1' then
                if we = '1' then
                    memory(to_integer(unsigned(addr))) <= din;
                end if;
                -- Register address for read operation to model BRAM output register
                read_addr_reg <= addr; 
            end if;
        end if;
    end process;

     dout <= memory(to_integer(unsigned(read_addr_reg))) when ena = '1' else (others => 'X'); -- Registered address read

end architecture behavioral;

