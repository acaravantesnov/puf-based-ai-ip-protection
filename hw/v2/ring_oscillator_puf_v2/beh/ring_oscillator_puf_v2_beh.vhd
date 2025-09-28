--==============================================================================
-- Title       : Ring Oscillator PUF Behavioural TestBench
-- File        : ring_oscillator_puf_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 09/07/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ring_oscillator_puf_v2_beh is
end ring_oscillator_puf_v2_beh;

architecture beh of ring_oscillator_puf_v2_beh is

    component ring_oscillator_puf_v2 is
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
            clk                         : in  std_logic;
            reset_n                     : in  std_logic;
            enable                      : in std_logic;
            
            -- lfsr counters axi regs
            lfsr_ros_counters           : out std_logic_vector(((g_lfsr_width * 2) * g_axi_reg_width) - 1 downto 0);
            lfsr_ros_ready              : out std_logic;

            -- main counters axi regs
            main_ros_counters   : out std_logic_vector((g_n_ROs_main * g_axi_reg_width) - 1 downto 0);
            main_ros_ready      : out std_logic;
            main_ros_ack        : in std_logic;

            -- lfsr seed mlp agent
            lfsr_ros_corrected          : in std_logic_vector(g_lfsr_width - 1 downto 0);
            lfsr_ros_ack                : in std_logic;

            -- puf response mlp agent
            puf_response                : out std_logic_vector(g_response_width - 1 downto 0);
            puf_response_ready          : out std_logic;
            puf_response_ack            : in std_logic
        );
    end component ring_oscillator_puf_v2;

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
    signal clk_i                : std_logic := '0';
    signal reset_n_i            : std_logic := '0';
    signal enable_i             : std_logic := '0';
    signal puf_response_ack_i   : std_logic := '0';
    signal puf_response_i       : std_logic_vector(c_response_width - 1 downto 0)  := (others => '0');
    signal puf_response_ready_i : std_logic := '0';

    -- lfsr seed mlp agent
    signal lfsr_ros_counters_i  : std_logic_vector(((c_lfsr_width * 2) * c_axi_reg_width) - 1 downto 0) := (others => '0');
    signal lfsr_ros_ready_i     : std_logic := '0';
    signal lfsr_ros_ack_i       : std_logic := '0';
    signal lfsr_ros_corrected_i         : std_logic_vector(c_lfsr_width - 1 downto 0);

    -- main ros counters_i
    signal main_ros_counters_i  : std_logic_vector((c_n_ROs_main * c_axi_reg_width) - 1 downto 0) := (others => '0');
    signal main_ros_ready_i     : std_logic := '0';
    signal main_ros_ack_i       : std_logic := '0';

begin

    ring_oscillator_puf_v2_inst: ring_oscillator_puf_v2
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
            
            -- lfsr counters axi regs
            lfsr_ros_counters => lfsr_ros_counters_i,
            lfsr_ros_ready => lfsr_ros_ready_i,

            -- main counters axi regs
            main_ros_counters => main_ros_counters_i,
            main_ros_ready => main_ros_ready_i,
            main_ros_ack => main_ros_ack_i,

            -- lfsr seed mlp agent
            lfsr_ros_corrected => lfsr_ros_corrected_i,
            lfsr_ros_ack => lfsr_ros_ack_i,

            -- puf response mlp agent
            puf_response => puf_response_i,
            puf_response_ready => puf_response_ready_i,
            puf_response_ack => puf_response_ack_i
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
        reset_n_i <= '0'; -- Assert reset (active low if c_reset_polarity is '0')
        wait for 1 us;
        reset_n_i <= '1'; -- De-assert reset
        wait;
    end process proc_reset_n;

    proc_enable: process
    begin
        enable_i <= '0';
        wait until rising_edge(clk_i) and reset_n_i = '1'; -- Wait until reset is de-asserted
        wait for c_clk_period * 10; -- Wait a few more cycles
        enable_i <= '1'; -- Enable the PUF
        wait;
    end process proc_enable;

    proc_lfsr_handshake: process(clk_i)
        variable ack_delay_counter: natural := 0;
        variable ack_delay_active: std_logic := '0';
    begin

        if rising_edge(clk_i) then
            if (reset_n_i <= c_reset_polarity) then
                lfsr_ros_corrected_i <= (others => '0');
                lfsr_ros_ack_i <= '0';
                ack_delay_counter := 0;
                ack_delay_active := '0';
            else
                if lfsr_ros_ready_i = '1' then
                    lfsr_ros_corrected_i <= (others => '1');
                    ack_delay_active := '1';
                else
                    lfsr_ros_corrected_i <= (others => '0');
                    ack_delay_active := '0';
                    ack_delay_counter := 0;
                end if;
                if ack_delay_active = '1' then
                    if ack_delay_counter < 100 then
                        ack_delay_counter := ack_delay_counter + 1;
                        lfsr_ros_ack_i <= '0';
                    else
                        ack_delay_counter := 0;
                        lfsr_ros_ack_i <= '1';
                        ack_delay_active := '0';
                    end if;
                end if;
            end if;
        end if;
    end process proc_lfsr_handshake;

    -- This process simulates a module receiving the main RO counter values.
    proc_main_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if main_ros_ready_i = '1' then
                main_ros_ack_i <= '1';
            else
                main_ros_ack_i <= '0';
            end if;
        end if;
    end process proc_main_ack;

    -- This process simulates the Processor System receiving the final PUF response.
    -- It watches for the 'ready_to_ps' signal and acknowledges it for one cycle.
    proc_response_ack: process(clk_i)
    begin
        if rising_edge(clk_i) then
            if puf_response_ready_i = '1' then
                puf_response_ack_i <= '1';
            else
                puf_response_ack_i <= '0';
            end if;
        end if;
    end process proc_response_ack;

end beh;
