--==============================================================================
-- Title       : LFSR Behavioural TestBench
-- File        : lfsr_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 24/04/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity lfsr_beh is
end lfsr_beh;

architecture beh of lfsr_beh is

    component lfsr is
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
    end component lfsr;

    -- Constants
    constant c_width: natural := 5;
    constant c_polynomial: natural := 20;
    constant c_reset_polarity: std_logic := '0';
    constant c_seed: std_logic_vector(c_width - 1 downto 0) := "01010";
    
    -- Signals
    signal clk_i: std_logic;
    signal reset_n_i: std_logic;
    signal fsm_reset_n_i: std_logic;

begin

    lfsr_inst: lfsr
        generic map(
            g_width => c_width,
            g_polynomial => c_polynomial,
            g_reset_polarity => c_reset_polarity
        )
        port map(
            lfsr_clk => '1',
            aux_reset_n => fsm_reset_n_i,
            reset_n => reset_n_i,
            seed => c_seed,
            clk => clk_i,
            lfsr => open
        );
        
    proc_clk: process
    begin
        while true loop
            clk_i <= '1';
            wait for 15 ns; -- 33.33 MHz
            clk_i <= '0';
            wait for 15 ns;
        end loop;
    end process proc_clk;
    
    proc_reset_n: process
    begin
        reset_n_i <= c_reset_polarity;
        wait for 1 ms;
        reset_n_i <= not c_reset_polarity;
--        wait for 1 ms;
--        reset_n_i <= c_reset_polarity;
        wait;
    end process proc_reset_n;

    proc_fsm_reset_n: process
    begin
        fsm_reset_n_i <= c_reset_polarity;
        wait for 1.5 ms;
        fsm_reset_n_i <= not c_reset_polarity;
        wait;
    end process proc_fsm_reset_n;

end beh;
