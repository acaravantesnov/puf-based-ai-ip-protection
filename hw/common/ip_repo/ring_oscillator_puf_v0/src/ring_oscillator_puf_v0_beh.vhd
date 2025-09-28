--==============================================================================
-- Title       : Ring Oscillator PUF Behavioural TestBench
-- File        : ring_oscillator_puf_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 18/06/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ring_oscillator_puf_v0_beh is
end ring_oscillator_puf_v0_beh;

architecture beh of ring_oscillator_puf_v0_beh is

    component ring_oscillator_puf_v0 is
        generic(
            g_timer_lfsr_seed_eoc   : natural := 100E3;
            g_timer_comparator_eoc  : natural := 100E3;
            g_clk_freq              : natural := 100E6;
            g_n_inverters_main      : natural := 5;
            g_n_ROs_main            : natural := 8;
            g_n_inverters_lfsr      : natural := 5;
            g_lfsr_polynomial       : natural := 20;
            g_response_width        : natural := 8;
            g_reset_polarity        : std_logic := '0';
            -- Debugging
            g_axi_reg_width         : natural := 32
        );
        port(
            clk                       : in  std_logic;
            reset_n                   : in  std_logic;
            enable                    : in  std_logic;
            ack_to_pl                 : in  std_logic;
            response                  : out std_logic_vector(g_response_width - 1 downto 0);
            ready_to_ps               : out std_logic;
            -- Debugging
            sampled_counters_ack_lfsr   : in  std_logic;
            sampled_counters            : out std_logic_vector((10 * g_axi_reg_width) - 1 downto 0);
            sampled_counters_ready_lfsr : out std_logic
        );
    end component ring_oscillator_puf_v0;

    -- Constants
    constant c_timer_lfsr_seed_eoc  : natural := 100E3;
    constant c_timer_comparator_eoc : natural := 100E3;
    constant c_clk_freq             : natural := 100E6;
    constant c_n_inverters_main     : natural := 5;
    constant c_n_ROs_main           : natural := 8;
    constant c_n_inverters_lfsr     : natural := 5;
    constant c_lfsr_polynomial      : natural := 20;
    constant c_response_width       : natural := 8;
    constant c_reset_polarity       : std_logic := '0';
    constant c_axi_reg_width        : natural := 32;
    constant c_clk_period           : time    := 10 ns;

    -- Signals
    signal clk_i                        : std_logic;
    signal reset_n_i                    : std_logic;
    signal enable_i                     : std_logic;
    signal ack_to_pl_i                  : std_logic;
    signal response_i                   : std_logic_vector(c_response_width - 1 downto 0);
    signal ready_to_ps_i                : std_logic;

    -- Signals for LFSR seed comparator debug interface
    signal sampled_counters_ack_lfsr_i  : std_logic;
    signal sampled_counters_lfsr_data_i : std_logic_vector((10 * c_axi_reg_width) - 1 downto 0);
    signal sampled_counters_ready_lfsr_i: std_logic;

begin

    ring_oscillator_puf_v0_inst: ring_oscillator_puf_v0
        generic map(
            g_timer_lfsr_seed_eoc    => c_timer_lfsr_seed_eoc,
            g_timer_comparator_eoc   => c_timer_comparator_eoc,
            g_clk_freq               => c_clk_freq,
            g_n_inverters_main       => c_n_inverters_main,
            g_n_ROs_main             => c_n_ROs_main,
            g_n_inverters_lfsr       => c_n_inverters_lfsr,
            g_lfsr_polynomial        => c_lfsr_polynomial,
            g_response_width         => c_response_width,
            g_reset_polarity         => c_reset_polarity,
            g_axi_reg_width          => c_axi_reg_width
        )
        port map(
            clk                       => clk_i,
            reset_n                   => reset_n_i,
            enable                    => enable_i,
            ack_to_pl                 => ack_to_pl_i,
            response                  => response_i,
            ready_to_ps               => ready_to_ps_i,
            -- Debugging ports for LFSR seed comparator
            sampled_counters_ack_lfsr   => sampled_counters_ack_lfsr_i,
            sampled_counters            => sampled_counters_lfsr_data_i,
            sampled_counters_ready_lfsr => sampled_counters_ready_lfsr_i
        );

    proc_clk: process
    begin
        clk_i <= '0';
        wait for c_clk_period / 2;
        clk_i <= '1';
        wait for c_clk_period / 2;
    end process proc_clk;

    proc_reset_n: process
    begin
        reset_n_i <= '0';
        wait for 1 us;
        reset_n_i <= '1';
        wait;
    end process proc_reset_n;

    proc_enable: process
    begin
        enable_i <= '0';
        wait until rising_edge(clk_i) and reset_n_i = '1';
        wait for c_clk_period * 10;
        enable_i <= '1';
        wait;
    end process proc_enable;

    -- Process to simulate PS acknowledging data via ack_to_pl
    proc_ps_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            ack_to_pl_i <= '0';
            if ready_to_ps_i = '1' then
                ack_to_pl_i <= '1';
            end if;
        end if;
    end process proc_ps_ack;

    -- Process to simulate AXI slave acknowledging data for the LFSR seed comparator
    proc_lfsr_counters_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            sampled_counters_ack_lfsr_i <= '0';
            if sampled_counters_ready_lfsr_i = '1' then
                sampled_counters_ack_lfsr_i <= '1';
            end if;
        end if;
    end process proc_lfsr_counters_ack;

end beh;
