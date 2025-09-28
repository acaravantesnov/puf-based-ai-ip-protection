library ieee;
use ieee.std_logic_1164.all;

entity sticky_bit is
    port (
        clk           : in  std_logic;
        pulse_in      : in  std_logic;
        clear         : in  std_logic;
        latched_out   : out std_logic
    );
end sticky_bit;

architecture rtl of sticky_bit is
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if clear = '1' then
                latched_out <= '0';
            elsif pulse_in = '1' then
                latched_out <= '1';
            end if;
        end if;
    end process;
end rtl;
