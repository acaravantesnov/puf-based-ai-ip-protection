--=================================================================================================
-- Title       : Ring Oscillator Map
-- File        : ro_map_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 09/07/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ro_map is
    generic(
        g_n_ROs_main: natural := 32;
        g_lfsr_width: natural := 9
    );
    port(
        -- Input signals
        clk                 : in std_logic;
        RO_unit_main_clks   : in  std_logic_vector(g_n_ROs_main - 1 downto 0);
        lfsr                : in  std_logic_vector(g_lfsr_width - 1 downto 0);

        -- Output signals
        ro0_index         : out natural;
        ro1_index         : out natural;
        map_out           : out std_logic_vector(1 downto 0)
    );
end entity ro_map;

architecture rtl of ro_map is

    -- Component declaration
    component ro_map_bram is
        port(
            clka    : in std_logic;
            ena     : in std_logic;
            addra   : in std_logic_vector(8 downto 0);
            douta   : out std_logic_vector(9 downto 0)
        );
    end component ro_map_bram;

    -- Internal signals
    signal bram_addr_i: std_logic_vector(8 downto 0);
    signal bram_data_out_i: std_logic_vector(9 downto 0);
    signal ro0_index_i: natural range 0 to g_n_ROs_main - 1;
    signal ro1_index_i: natural range 0 to g_n_ROs_main - 1;

begin

    bram_addr_i <= lfsr;

    bram_inst: ro_map_bram
        port map(
            clka => clk,
            ena => '1',
            addra => bram_addr_i,
            douta => bram_data_out_i
        );

    proc_reg_output_from_bram: process(clk)
    begin
        if (rising_edge(clk)) then
            ro0_index_i <= to_integer(unsigned(bram_data_out_i(4 downto 0)));
            ro1_index_i <= to_integer(unsigned(bram_data_out_i(9 downto 5)));
        end if;
    end process proc_reg_output_from_bram;

    map_out(0) <= RO_unit_main_clks(ro0_index_i);
    map_out(1) <= RO_unit_main_clks(ro1_index_i);

    ro0_index <= ro0_index_i;
    ro1_index <= ro1_index_i;

end architecture rtl;
