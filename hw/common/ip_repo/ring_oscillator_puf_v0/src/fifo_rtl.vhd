--=================================================================================================
-- Title       : FIFO
-- File        : fifo_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 01/06/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;

entity fifo is
    generic(
        g_width         : natural range 2 to 16 := 8;
        g_reset_polarity: std_logic := '0'
    );
    port(
        clk                     : in std_logic;
        comparator_value_ready  : in std_logic;
        aux_reset_n             : in std_logic;
        reset_n                 : in std_logic;
        input_value             : in std_logic;
        output_value            : out std_logic_vector(g_width - 1 downto 0);
        fifo_full               : out std_logic
    );
end entity fifo;

architecture rtl of fifo is

    signal fifo_i: std_logic_vector(g_width - 1 downto 0)   := (others => '0');
    signal n_shifts_i: natural                              := 0;
    
    signal reset_condition_i : std_logic;

begin

    reset_condition_i <= '1' when (reset_n = g_reset_polarity) or (aux_reset_n = g_reset_polarity) else '0';

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (reset_condition_i = '1') then
                fifo_i <= (others => '0');
                n_shifts_i <= 0;
            else
                if (comparator_value_ready = '1' ) and (n_shifts_i < g_width) then
                    n_shifts_i <= n_shifts_i + 1;
                    fifo_i(g_width - 1) <= input_value;
                    for i in 2 to g_width loop
                        fifo_i(g_width - i) <= fifo_i(g_width - (i - 1));
                    end loop;
                end if;
            end if;
        end if;
    end process;

    output_value <= fifo_i;
    fifo_full <= '1' when n_shifts_i >= g_width else '0';

end architecture rtl;
