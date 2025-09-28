--=================================================================================================
-- Title       : LFSR
-- File        : lfsr_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 01/06/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
    generic(
        g_width             : natural := 5;
        g_polynomial        : natural := 20;
        g_reset_polarity    : std_logic := '0'
    );
    port(
        lfsr_clk    : in  std_logic;
        aux_reset_n : in std_logic;
        reset_n     : in  std_logic;
        seed        : in  std_logic_vector(g_width - 1 downto 0);
        clk         : in std_logic;
        lfsr        : out natural
    );
end entity lfsr;

architecture rtl of lfsr is

    -- Convert integer taps into a std_logic_vector mask
    constant c_taps: std_logic_vector(g_width - 1 downto 0) := std_logic_vector(to_unsigned(g_polynomial, g_width));

    -- Register to store lfsr state
    signal reg_i: std_logic_vector(g_width - 1 downto 0)    := (others => '0');

    signal reset_n_comb_i: std_logic    := '0';
    signal reset_sync_i: std_logic      := '0';

begin

    reset_n_comb_i <= '1' when (reset_n = g_reset_polarity or aux_reset_n = g_reset_polarity) else '0';
    
    proc_sync_reset: process(clk)
    begin
        if rising_edge(clk) then
            reset_sync_i <= reset_n_comb_i;
        end if;
    end process proc_sync_reset;
    
    process (clk)
        variable feedback : std_logic;
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1') then
                reg_i <= seed;
            elsif (lfsr_clk = '1') then
                -- Compute XOR feedback
                feedback := '0';
                for i in 0 to g_width - 1 loop
                    if (c_taps(g_width - 1 - i) = '1') then
                        feedback := feedback xor reg_i(i);
                    end if;
                end loop;
    
                -- Shift register (shift right, insert feedback at MSB)
                reg_i <= feedback & reg_i(g_width - 1 downto 1);
            end if;
        end if;
    end process;

    lfsr <= to_integer(unsigned(reg_i));

end architecture rtl;
