--==============================================================================
-- Title       : FIFO Behavioural TestBench
-- File        : fifo_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 24/04/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity fifo_beh is
end fifo_beh;

architecture beh of fifo_beh is

    component fifo is
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
    end component fifo;
    
    -- Constants
    constant c_width: natural := 8;
    constant c_reset_polarity: std_logic := '0';
    
    -- Signals
    signal clk_i: std_logic;
    signal comparator_value_ready_i: std_logic;
    signal reset_n_i: std_logic;
    signal aux_reset_n_i: std_logic;
    signal input_value_i: std_logic;

begin

    fifo_inst: fifo
        generic map(
            g_width => c_width,
            g_reset_polarity => c_reset_polarity
        )
        port map(
            clk => clk_i,
            comparator_value_ready => comparator_value_ready_i,
            aux_reset_n => aux_reset_n_i,
            reset_n => reset_n_i,
            input_value => input_value_i,
            output_value => open,
            fifo_full => open
        );
        
    proc_clk: process
    begin
        while true loop
            clk_i <= '1';
            wait for 50 us;
            clk_i <= '0';
            wait for 50 us;
        end loop;
    end process proc_clk;
    
    proc_comparator_value_ready: process
    begin
        while true loop
            comparator_value_ready_i <= '1';
            wait for 100 us;
            comparator_value_ready_i <= '0';
            wait for 100 us;
        end loop;
    end process proc_comparator_value_ready;
    
    proc_reset_n: process
    begin
        reset_n_i <= c_reset_polarity;
        wait for 1 ms;
        reset_n_i <= not c_reset_polarity;
        wait for 0.8 ms;
        reset_n_i <= c_reset_polarity;
        wait for 0.1 ms;
        reset_n_i <= not c_reset_polarity;
        wait;
    end process proc_reset_n;

    proc_aux_reset_n: process
    begin
        aux_reset_n_i <= c_reset_polarity;
        wait for 1.5 ms;
        aux_reset_n_i <= not c_reset_polarity;
        wait for 6 ms;
        aux_reset_n_i <= c_reset_polarity;
        wait for 1 ms;
        aux_reset_n_i <= not c_reset_polarity;
        wait;
    end process proc_aux_reset_n;
    
    proc_input: process
    begin
--        while true loop
--            input_value_i <= '0';
--            wait for 1 ms;
--            input_value_i <= '1';
--            wait for 1 ms;
--        end loop;
        input_value_i <= '1';
        wait;
    end process;
        
end beh;
