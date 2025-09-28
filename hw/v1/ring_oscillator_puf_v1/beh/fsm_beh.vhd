--==============================================================================
-- Title       : FSM Behavioural TestBench
-- File        : fsm_beh.vhd
-- Description : 
-- Generics    : 
-- Author      : Alberto Caravantes Arranz
-- Date        : 30/04/2025
-- Version     : 1.0
--==============================================================================

-- Revision History:
-- Version 1.0 - Initial version

library ieee;
use ieee.std_logic_1164.all;

entity fsm_beh is
end fsm_beh;

architecture beh of fsm_beh is

    component fsm is
        generic(
            g_reset_polarity : std_logic := '0'
        );
        port(
            -- Global signals
            enable                  : in std_logic;
            reset_n                 : in std_logic;
            clk                     : in std_logic;
    
            -- LFSR seed ready signal from seed module
            lfsr_seed_value_ready   : in std_logic;
    
            -- Register to store seed value
            reg_lfsr_seed           : out std_logic;
    
            -- LFSR module control
            lfsr_clk                : out std_logic;
    
            -- Comparator control
            comparator_value_ready_d: in std_logic;
    
            -- FIFO control and status
            fifo_full               : in std_logic;
            
            -- Acknowledge signal from PS to PL
            ack_to_pl               : in std_logic;
    
            -- Register trigger for FIFO
            reg_fifo_enable         : out std_logic;
    
            -- Control Reset
            fsm_reset_n             : out std_logic;
            comparison_reset_n      : out std_logic
        );
    end component fsm;
    
    -- Constants
    constant c_reset_polarity: std_logic := '0';
    
    -- Signals
    signal enable_i: std_logic;
    signal reset_n_i:  std_logic;
    signal clk_i: std_logic;
    signal lfsr_seed_value_ready_i: std_logic;
    signal comparator_value_ready_d_i: std_logic;
    signal fifo_full_i: std_logic;

begin

    fsm_inst: fsm
        generic map(
            g_reset_polarity => c_reset_polarity
        )
        port map(
            -- Global signals
            enable => enable_i,
            reset_n => reset_n_i,
            clk => clk_i,
    
            -- LFSR seed ready signal from seed module
            lfsr_seed_value_ready => lfsr_seed_value_ready_i,
    
            -- Register to store seed value
            reg_lfsr_seed => open,
    
            -- LFSR module control
            lfsr_clk => open,
    
            -- Comparator control
            comparator_value_ready_d => comparator_value_ready_d_i,
    
            -- FIFO control and status
            fifo_full => fifo_full_i,
            
            ack_to_pl => '1',
    
            -- Register trigger for FIFO
            reg_fifo_enable => open,
    
            -- Control Reset
            fsm_reset_n => open,
            comparison_reset_n => open
        );

    proc_enable: process
    begin
        enable_i <= '0';
        wait for 10 us;
        enable_i <= '1';
        wait;
    end process proc_enable;

    proc_reset_n: process
    begin
        reset_n_i <= '0';
        wait for 10 us;
        reset_n_i <= '1';
        wait;
    end process proc_reset_n;
    
    proc_clk: process -- 50 MHz
    begin
        while true loop
            clk_i <= '0';
            wait for 10 ns;
            clk_i <= '1';
            wait for 10 ns;
        end loop;
    end process proc_clk;
    
    proc_inputs: process
    begin
        lfsr_seed_value_ready_i <= '0';
        comparator_value_ready_d_i <= '0';
        fifo_full_i <= '0';
        wait for 15 us;
        lfsr_seed_value_ready_i <= '1';
        wait for 90 ns;
        comparator_value_ready_d_i <= '1';
        wait for 10010 ns;
        fifo_full_i <= '1';
        wait;
    end process proc_inputs;    
    

end beh;
