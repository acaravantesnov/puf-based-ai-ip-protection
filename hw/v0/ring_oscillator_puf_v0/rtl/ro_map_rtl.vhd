--=================================================================================================
-- Title       : Ring Oscillator Map
-- File        : ro_map_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 01/06/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ro_map is
    generic(
        g_n_ROs_main: natural := 8
    );
    port(
        RO_unit_main_clks: in std_logic_vector(g_n_ROs_main - 1 downto 0);
        lfsr: in natural;
        g_out: out natural;
        s_out: out natural;
        map_out: out std_logic_vector(1 downto 0)
    );
end entity ro_map;

architecture rtl of ro_map is

    signal g_i: natural := 0;
    signal s_i: natural := 0;

begin

    proc_get_indexes: process(lfsr, RO_unit_main_clks)
        variable g, s: natural;
        variable sum: integer;
        variable current_index: natural;
        variable found: boolean;
    begin
        g := 0;
        s := 0;
        sum := g_n_ROs_main - 2;
        current_index := 0;
        found := false;

        for i in 0 to g_n_ROs_main - 2 loop
            if (not found) and (lfsr >= current_index) and (lfsr <= current_index + sum) then
                s := lfsr - current_index;
                g := i;
                found := true;
            else
                current_index := current_index + sum + 1;
                sum := sum - 1;
            end if;
        end loop;

        g_i <= g;
        s_i <= s;
    end process proc_get_indexes;

    map_out(0) <= RO_unit_main_clks(g_i);
    map_out(1) <= RO_unit_main_clks(g_i + s_i + 1);
    
    g_out <= g_i;
    s_out <= s_i;

end rtl;
