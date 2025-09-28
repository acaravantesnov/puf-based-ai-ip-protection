--=================================================================================================
-- Title       : FSM
-- File        : fsm_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 01/06/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;

entity fsm is
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
end entity fsm;

architecture rtl of fsm is

    -- Define FSM states
    type t_state is (IDLE, REG_SEED, SEED_READY, ONE_BIT, WAIT_BRAM_1, WAIT_BRAM_2, WAIT_FOR_VALUE, REG_FIFO);
    signal current_state: t_state               := IDLE;
    signal next_state: t_state                  := IDLE;
    signal flag_i: natural range 0 to 2         := 0;
    signal next_flag_i: natural range 0 to 2    := 0;
    
begin

    STATE_REGISTER: process(reset_n, clk)
    begin
        if (reset_n = g_reset_polarity) then
            current_state <= IDLE;
            flag_i <= 0;
        elsif (rising_edge(clk)) then
            current_state <= next_state;
            flag_i <= next_flag_i;
        end if;
    end process STATE_REGISTER;

    STATE_TRANSITION: process(current_state, lfsr_seed_value_ready, enable, comparator_value_ready_d, fifo_full, flag_i, ack_to_pl)
    begin
        next_state <= current_state;
        next_flag_i <= flag_i;

        case current_state is
            when IDLE =>
                if (lfsr_seed_value_ready = '1') then
                    next_state <= REG_SEED;
                end if;
            when REG_SEED =>
                next_state <= SEED_READY;
            when SEED_READY =>
                next_flag_i <= 0;
                if (enable = '1') then
                    next_state <= ONE_BIT;
                end if;
            when ONE_BIT =>
                next_state <= WAIT_BRAM_1;
            when WAIT_BRAM_1 =>
                next_state <= WAIT_BRAM_2;
            when WAIT_BRAM_2 =>
                next_state <= WAIT_FOR_VALUE;
            when WAIT_FOR_VALUE =>
                if (comparator_value_ready_d = '1')then
                    if (fifo_full = '0') then
                        next_state <= ONE_BIT;
                    else
                        next_state <= REG_FIFO;
                    end if;
                end if;
            when REG_FIFO =>
                if (flag_i < 2) then
                    next_state <= REG_FIFO;
                    next_flag_i <= flag_i + 1;
                elsif (ack_to_pl = '1') then
                    next_state <= SEED_READY;
                end if;
            when others =>
                null;
        end case;
    end process STATE_TRANSITION;

    OUTPUT: process(current_state)
    begin
        reg_lfsr_seed <= '0';
        lfsr_clk <= '0';
        reg_fifo_enable <= '0';
        fsm_reset_n <= not g_reset_polarity;
        comparison_reset_n <= g_reset_polarity;

        case current_state is
            when REG_SEED =>
                reg_lfsr_seed <= '1';
            when SEED_READY =>
                fsm_reset_n <= g_reset_polarity;
            when ONE_BIT =>
                lfsr_clk <= '1';
            when WAIT_FOR_VALUE =>
                comparison_reset_n <= not g_reset_polarity;
            when REG_FIFO =>
                reg_fifo_enable <= '1';
            when others => 
                null;
        end case;
    end process OUTPUT;

end architecture rtl;
