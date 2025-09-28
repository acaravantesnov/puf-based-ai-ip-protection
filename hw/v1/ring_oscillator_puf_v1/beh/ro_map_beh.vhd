--==============================================================================
-- Title       : Ring Oscillator Map Behavioural TestBench
-- File        : ro_map_beh.vhd
-- Description : 
-- Generics    : 
-- Author      : Alberto Caravantes Arranz
-- Date        : 24/04/2025
-- Version     : 1.0
--==============================================================================

-- Revision History:
-- Version 1.0 - Initial version

library ieee;
use ieee.std_logic_1164.all;

entity ro_map_beh is
end ro_map_beh;

architecture Behavioral of ro_map_beh is

    component ro_map is
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
    end component ro_map;
    
    -- Constants
    constant c_n_ROs_main: natural := 8;
    
    -- Signals
    signal RO_unit_main_clks_i: std_logic_vector(c_n_ROs_main - 1 downto 0);
    signal lfsr_i: natural;

begin

    ro_map_inst: ro_map
        generic map(
            g_n_ROs_main => c_n_ROs_main
        )
        port map(
            RO_unit_main_clks => RO_unit_main_clks_i,
            lfsr => lfsr_i,
            g_out => open,
            s_out => open,
            map_out => open
        );
        
    RO_unit_main_clks_i <= (others => '1');
    
    proc_gen_lfsr_values: process
    begin
        lfsr_i <= 3;
        wait for 5 us;
        lfsr_i <= 18;
        wait for 5 us;
        lfsr_i <= 0;
        wait for 5 us;
        lfsr_i <= 22;
        wait for 5 us;
        lfsr_i <= 27;
        wait for 5 us;
        lfsr_i <= 26;
        wait for 5 us;
        lfsr_i <= 25;
        wait for 5 us;
        lfsr_i <= 24;
        wait;
    end process proc_gen_lfsr_values;

end Behavioral;
