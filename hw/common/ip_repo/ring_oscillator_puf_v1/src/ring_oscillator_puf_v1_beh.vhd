--==============================================================================
-- Title       : Ring Oscillator PUF Behavioural TestBench
-- File        : ring_oscillator_puf_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 09/07/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ring_oscillator_puf_v1_beh is
end ring_oscillator_puf_v1_beh;

architecture beh of ring_oscillator_puf_v1_beh is

    component ring_oscillator_puf_v1 is
        generic(
            g_timer_lfsr_seed_eoc   : natural := 100E3;
            g_timer_comparator_eoc  : natural := 100E3;
            g_clk_freq              : natural := 100E6;
            g_n_inverters_main      : natural := 5;
            g_n_ROs_main            : natural := 32;
            g_n_inverters_lfsr      : natural := 5;
            g_lfsr_width            : natural := 9;
            g_lfsr_polynomial       : natural := 272;
            g_response_width        : natural := 128;
            g_reset_polarity        : std_logic := '0';
            g_axi_reg_width         : natural := 32
        );
        port(
            clk                 : in  std_logic;
            reset_n             : in  std_logic;
            enable              : in std_logic;
            ack_to_pl           : in std_logic;
            response            : out std_logic_vector(g_response_width - 1 downto 0);
            ready_to_ps         : out std_logic;
            -- lfsr ros counters
            sampled_lfsr_ros_counters   : out std_logic_vector(((g_lfsr_width * 2) * g_axi_reg_width) - 1 downto 0);
            sampled_lfsr_ros_ready      : out std_logic;
            sampled_lfsr_ros_ack        : in std_logic;
            -- main ros counters
            sampled_main_ros_counters   : out std_logic_vector((g_n_ROs_main * g_axi_reg_width) - 1 downto 0);
            sampled_main_ros_ready      : out std_logic;
            sampled_main_ros_ack        : in std_logic
        );
    end component ring_oscillator_puf_v1;

    -- Constants
    constant c_timer_lfsr_seed_eoc  : natural := 100E3;
    constant c_timer_comparator_eoc : natural := 100E3;
    constant c_clk_freq             : natural := 100E6;
    constant c_n_inverters_main     : natural := 5;
    constant c_n_ROs_main           : natural := 32;
    constant c_n_inverters_lfsr     : natural := 5;
    constant c_lfsr_width           : natural := 9;
    constant c_lfsr_polynomial      : natural := 20;
    constant c_response_width       : natural := 128;
    constant c_reset_polarity       : std_logic := '0';
    constant c_axi_reg_width        : natural := 32;
    constant c_clk_period           : time    := 10 ns; -- For 100 MHz clock

    -- Signals
    signal clk_i        : std_logic := '0';
    signal reset_n_i    : std_logic := '0';
    signal enable_i     : std_logic := '0';
    signal ack_to_pl_i  : std_logic := '0';
    signal response_i   : std_logic_vector(c_response_width - 1 downto 0)  := (others => '0');
    signal ready_to_ps_i: std_logic := '0';

    -- Signals for AXI Regs
    -- lfsr ros counters
    signal sampled_lfsr_ros_counters_i  : std_logic_vector(((c_lfsr_width * 2) * c_axi_reg_width) - 1 downto 0) := (others => '0');
    signal sampled_lfsr_ros_ready_i     : std_logic := '0';
    signal sampled_lfsr_ros_ack_i       : std_logic := '0';
    -- main ros counters_i
    signal sampled_main_ros_counters_i  : std_logic_vector((c_n_ROs_main * c_axi_reg_width) - 1 downto 0) := (others => '0');
    signal sampled_main_ros_ready_i     : std_logic := '0';
    signal sampled_main_ros_ack_i       : std_logic := '0';
    
begin

    ring_oscillator_puf_v1_inst: ring_oscillator_puf_v1
        generic map(
            g_timer_lfsr_seed_eoc => c_timer_lfsr_seed_eoc,
            g_timer_comparator_eoc => c_timer_comparator_eoc,
            g_clk_freq => c_clk_freq,
            g_n_inverters_main => c_n_inverters_main,
            g_n_ROs_main => c_n_ROs_main,
            g_n_inverters_lfsr => c_n_inverters_lfsr,
            g_lfsr_width => c_lfsr_width,
            g_lfsr_polynomial => c_lfsr_polynomial,
            g_response_width => c_response_width,
            g_reset_polarity => c_reset_polarity,
            g_axi_reg_width => c_axi_reg_width
        )
        port map(
            clk => clk_i,
            reset_n => reset_n_i,
            enable => enable_i,
            ack_to_pl => ack_to_pl_i,
            response => response_i,
            ready_to_ps => ready_to_ps_i,
            -- lfsr ros counters
            sampled_lfsr_ros_counters => sampled_lfsr_ros_counters_i,
            sampled_lfsr_ros_ready => sampled_lfsr_ros_ready_i,
            sampled_lfsr_ros_ack => sampled_lfsr_ros_ack_i,
            -- main ros counters
            sampled_main_ros_counters => sampled_main_ros_counters_i,
            sampled_main_ros_ready => sampled_main_ros_ready_i,
            sampled_main_ros_ack => sampled_main_ros_ack_i
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

    -- This process simulates a module receiving the LFSR seed counter values.
    -- It watches for the ready signal and acknowledges it for one cycle.
    proc_lfsr_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if sampled_lfsr_ros_ready_i = '1' then
                sampled_lfsr_ros_ack_i <= '1';
            else
                sampled_lfsr_ros_ack_i <= '0';
            end if;
        end if;
    end process proc_lfsr_ack;

    -- This process simulates a module receiving the main RO counter values.
    proc_main_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if sampled_main_ros_ready_i = '1' then
                sampled_main_ros_ack_i <= '1';
            else
                sampled_main_ros_ack_i <= '0';
            end if;
        end if;
    end process proc_main_ack;

    -- This process simulates the PS receiving the final PUF response.
    -- It watches for the ready_to_ps signal and acknowledges it for one cycle.
    proc_response_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if ready_to_ps_i = '1' then
                ack_to_pl_i <= '1';
            else
                ack_to_pl_i <= '0';
            end if;
        end if;
    end process proc_response_ack;

end beh;
