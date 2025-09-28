--=================================================================================================
-- Title       : Ring Oscillator PUF
-- File        : ring_oscillator_puf_1_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 27/07/2025
-- Version     : 4.0
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ring_oscillator_puf_v2 is
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
end entity ring_oscillator_puf_v2;

architecture rtl of ring_oscillator_puf_v2 is

    -----------------------------------------------------------------------------------------------
    -- Internal Signals
    -----------------------------------------------------------------------------------------------

    -- Ring Oscillator Units
    signal RO_unit_main_clks_i: std_logic_vector(g_n_ROs_main - 1 downto 0)         := (others => '0');
    signal RO_unit_lfsr_clks_i: std_logic_vector((g_lfsr_width * 2) - 1 downto 0)   := (others => '0');

    -- LFSR
    signal lfsr_seed_i_d: std_logic_vector(g_lfsr_width - 1 downto 0)   := (others => '0');
    signal lfsr_seed_value_ready_i: std_logic                           := '0';
    signal lfsr_i: std_logic_vector(g_lfsr_width - 1 downto 0)          := (others => '0');

    -- Map
    signal ro0_index_i  : natural                      := 0;
    signal ro1_index_i  : natural                      := 0;
    signal map_out_i    : std_logic_vector(1 downto 0)  := (others => '0');

    -- Comparator
    signal comparator_result_i: std_logic_vector(0 downto 0)    := "0";
    signal comparator_value_ready_i: std_logic                  := '0';
    signal comparator_value_ready_i_d: std_logic                := '0';

    -- Comparator - Counter map
    signal counters_to_counter_map_i: std_logic_vector((2 * g_axi_reg_width) - 1 downto 0) := (others => '0');
    signal ready_to_counter_map_i: std_logic := '0';
    signal ack_to_comparator_i: std_logic := '0';

    -- FIFO
    signal fifo_i: std_logic_vector(g_response_width - 1 downto 0)  := (others => '0');
    signal fifo_full_i: std_logic                                   := '0';

    -- FSM
    signal fsm_reset_n_i: std_logic         := not g_reset_polarity;
    signal comparison_reset_n_i: std_logic  := not g_reset_polarity;
    signal reg_lfsr_seed_i: std_logic       := '0';
    signal lfsr_clk_i: std_logic            := '0';
    signal puf_response_ack_i: std_logic           := '0';

    -- Output Register
    signal fifo_i_d: std_logic_vector(g_response_width - 1 downto 0)    := (others => '0');
    signal reg_fifo_i: std_logic                                        := '0';
    signal reg_fifo_i_d: std_logic                                      := '0';

    -----------------------------------------------------------------------------------------------
    -- Component Declarations
    -----------------------------------------------------------------------------------------------

    component ring_oscillator is
        generic(
            g_n_inverters: natural := 5
        );
        port(
            enable  : in  std_logic;
            clk_out : out std_logic
        );
    end component ring_oscillator;
    
    component fake_ros is
        generic (
            g_n_ROs      : natural := 8;
            g_base_tH    : time    := 3.33 ns;
            g_delta_tH   : time    := 0.01 ns
        );
        port (
            enable  : in  std_logic;
            clk_out : out std_logic_vector(g_n_ROs-1 downto 0)
        );
    end component fake_ros;

    component comparator is
        generic(
            g_input_width   : natural := 10;
            g_timer_eoc     : natural := 100E3;
            g_reset_polarity: std_logic := '0';
            -- Debugging
            g_axi_reg_width : natural := 32
        );
        port(
            clk                 : in std_logic;
            aux_reset_n         : in std_logic;
            aux_2_reset_n       : in std_logic;
            reset_n             : in std_logic;
            RO_clks             : in std_logic_vector(g_input_width - 1 downto 0);
            comparison_result   : out std_logic_vector((g_input_width / 2) - 1 downto 0);
            value_ready         : out std_logic;
            -- AXI debugging
            sampled_counters_ack    : in std_logic;
            sampled_counters        : out std_logic_vector((g_input_width * g_axi_reg_width) - 1 downto 0);
            sampled_counters_ready  : out std_logic
        );
    end component comparator;

    component counter_map is
        generic(
            g_n_regs          : natural   := 32;
            g_axi_reg_width   : natural   := 32;
            g_reset_polarity  : std_logic := '0'
        );
        port(
            -- Clock and Reset
            clk               : in  std_logic;
            reset_n           : in  std_logic;

            -- comparator_inst communication
            counters_to_counter_map : in  std_logic_vector((2 * g_axi_reg_width) - 1 downto 0);
            ready_to_counter_map    : in  std_logic;
            ack_to_comparator       : out std_logic;

            -- main_ro_counters_v1 communication
            counters_to_main_ro_counters_v1 : out std_logic_vector((g_n_regs * g_axi_reg_width) - 1 downto 0);
            ready_to_main_ro_counters_v1    : out std_logic;
            ack_to_counter_map              : in  std_logic;

            puf_response_ready : in std_logic;

            ro0_index   : in natural;
            ro1_index   : in natural
        );
    end component counter_map;

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
            lfsr        : out std_logic_vector(g_width - 1 downto 0)
        );
    end component lfsr;

    component ro_map is
        generic(
            g_n_ROs_main: natural := 32;
            g_lfsr_width: natural := 9
        );
        port(
            RO_unit_main_clks : in  std_logic_vector(g_n_ROs_main - 1 downto 0);
            lfsr              : in  std_logic_vector(g_lfsr_width - 1 downto 0);
            ro0_index         : out natural;
            ro1_index         : out natural;
            map_out           : out std_logic_vector(1 downto 0)
        );
    end component ro_map;

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
            lfsr_ros_ack    : in std_logic;
    
            -- Register to store seed value
            reg_lfsr_seed           : out std_logic;
    
            -- LFSR module control
            lfsr_clk                : out std_logic;
    
            -- Comparator control
            comparator_value_ready_d: in std_logic;
    
            -- FIFO control and status
            fifo_full               : in std_logic;
            
            -- Acknowledge signal from PS to PL
            puf_response_ack        : in std_logic;
    
            -- Register trigger for FIFO
            reg_fifo_enable         : out std_logic;
    
            -- Control Reset
            fsm_reset_n             : out std_logic;
            comparison_reset_n      : out std_logic
        );
    end component fsm;

begin

    -----------------------------------------------------------------------------------------------
    -- Ring Oscillator Unit (main)
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
   GEN_ROS_MAIN: for i in 0 to g_n_ROs_main - 1 generate
       RO_inst: entity work.Ring_Oscillator
           generic map(
               g_n_inverters => g_n_inverters_main
           )
           port map(
               enable  => enable,
               clk_out => RO_unit_main_clks_i(i)
           );
   end generate GEN_ROS_MAIN;

--    BEH SIMULATION
--     fake_ros_main_inst: entity work.fake_ros
--         generic map(
--             g_n_ROs => g_n_ROs_main,
--             g_base_tH => 3.3 ns,
--             g_delta_tH => 0.01 ns
--         )
--         port map(
--             enable => enable,
--             clk_out => RO_unit_main_clks_i
--         );

    -----------------------------------------------------------------------------------------------
    -- Ring Oscillator Unit (lfsr)
    -----------------------------------------------------------------------------------------------
    --
--    -----------------------------------------------------------------------------------------------
   GEN_ROS_LFSR: for i in 0 to (g_lfsr_width * 2) - 1 generate
       RO_inst: entity work.Ring_Oscillator
           generic map(
               g_n_inverters => g_n_inverters_lfsr
           )
           port map(
               enable  => not enable,
               clk_out => RO_unit_lfsr_clks_i(i)
           );
   end generate GEN_ROS_LFSR;

--    BEH SIMULATION
--     fake_ros_lfsr_inst: entity work.fake_ros
--         generic map(
--             g_n_ROs => g_lfsr_width * 2,
--             g_base_tH => 3.3 ns,
--             g_delta_tH => 0.01 ns
--         )
--         port map(
--             enable => '1',
--             clk_out => RO_unit_lfsr_clks_i
--         );

    -----------------------------------------------------------------------------------------------
    -- LFSR Seed
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    lfsr_seed_inst: entity work.comparator
        generic map(
            g_input_width => g_lfsr_width * 2,
            g_timer_eoc => g_timer_lfsr_seed_eoc,
            g_reset_polarity => g_reset_polarity,
            g_axi_reg_width => g_axi_reg_width
        )
        port map(
            clk => clk,
            aux_reset_n => not g_reset_polarity,
            aux_2_reset_n => not g_reset_polarity,
            reset_n => reset_n,
            RO_clks => RO_unit_lfsr_clks_i,
            comparison_result => open,
            value_ready => lfsr_seed_value_ready_i,
            sampled_counters_ack => lfsr_ros_ack,
            sampled_counters => lfsr_ros_counters,
            sampled_counters_ready => lfsr_ros_ready
        );

    proc_reg_lfsr_seed: process(reset_n, clk)
    begin
        if (reset_n = g_reset_polarity) then
            lfsr_seed_i_d <= (others => '0');
        elsif (rising_edge(clk)) then
            if (reg_lfsr_seed_i = '1') then
                lfsr_seed_i_d <= lfsr_ros_corrected;
            end if;
        end if;
    end process proc_reg_lfsr_seed;

    -----------------------------------------------------------------------------------------------
    -- LFSR
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    lfsr_inst: entity work.lfsr
        generic map(
            g_width => g_lfsr_width,
            g_polynomial => g_lfsr_polynomial,
            g_reset_polarity => g_reset_polarity
        )
        port map(
            lfsr_clk => lfsr_clk_i,
            aux_reset_n => fsm_reset_n_i,
            reset_n => reset_n,
            seed => lfsr_seed_i_d,
            clk => clk,
            lfsr => lfsr_i
        );

    -----------------------------------------------------------------------------------------------
    -- RO Clock Pair Mapping
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    ro_map_inst: entity work.ro_map
        generic map(
            g_n_ROs_main => g_n_ROs_main,
            g_lfsr_width => g_lfsr_width
        )
        port map(
            clk => clk,
            RO_unit_main_clks => RO_unit_main_clks_i,
            lfsr => lfsr_i,
            ro0_index => ro0_index_i,
            ro1_index => ro1_index_i,
            map_out => map_out_i
        );

    -----------------------------------------------------------------------------------------------
    -- Comparator Unit
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    comparator_inst: entity work.comparator
        generic map(
            g_input_width => 2,
            g_timer_eoc => g_timer_comparator_eoc,
            g_reset_polarity => g_reset_polarity,
            g_axi_reg_width => g_axi_reg_width
        )
        port map(
            clk => clk,
            aux_reset_n => fsm_reset_n_i,
            aux_2_reset_n => comparison_reset_n_i,
            reset_n => reset_n,
            RO_clks => map_out_i,
            comparison_result => comparator_result_i,
            value_ready => comparator_value_ready_i,
            sampled_counters_ack => ack_to_comparator_i,
            sampled_counters => counters_to_counter_map_i,
            sampled_counters_ready => ready_to_counter_map_i
        );

    counter_map_inst: entity work.counter_map
        generic map(
            g_n_regs => g_n_ROs_main,
            g_axi_reg_width => g_axi_reg_width,
            g_reset_polarity => g_reset_polarity
        )
        port map(
            -- Clock and Reset
            clk => clk,
            reset_n => reset_n,

            -- comparator_inst communication
            counters_to_counter_map => counters_to_counter_map_i,
            ready_to_counter_map => ready_to_counter_map_i,
            ack_to_comparator => ack_to_comparator_i,

            -- main_ro_counters_v1 communication
            counters_to_main_ro_counters_v1 => main_ros_counters,
            ready_to_main_ro_counters_v1 => main_ros_ready,
            ack_to_counter_map => main_ros_ack,

            puf_response_ready => reg_fifo_i_d,

            ro0_index => ro0_index_i,
            ro1_index => ro1_index_i
        );

    proc_reg_comparator_value_ready: process(reset_n, clk)
    begin
        if (reset_n = g_reset_polarity) then
            comparator_value_ready_i_d <= '0';
        elsif (rising_edge(clk)) then
            comparator_value_ready_i_d <= comparator_value_ready_i;
        end if;
    end process proc_reg_comparator_value_ready;

    -----------------------------------------------------------------------------------------------
    -- 1-bit FIFO
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    fifo_inst: entity work.fifo
        generic map(
            g_width => g_response_width,
            g_reset_polarity => g_reset_polarity
        )
        port map(
            clk => clk,
            comparator_value_ready => comparator_value_ready_i_d,
            aux_reset_n => fsm_reset_n_i,
            reset_n => reset_n,
            input_value => comparator_result_i(0),
            output_value => fifo_i,
            fifo_full => fifo_full_i
        );

    -----------------------------------------------------------------------------------------------
    -- FSM
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    fsm_inst: entity work.fsm
        generic map(
            g_reset_polarity => g_reset_polarity
        )
        port map(
            -- Global signals
            enable => enable,
            reset_n => reset_n,
            clk => clk,

            -- LFSR seed ready signal from seed module
            lfsr_seed_value_ready => lfsr_seed_value_ready_i,
            lfsr_ros_ack => lfsr_ros_ack,

            -- Register to store seed value
            reg_lfsr_seed => reg_lfsr_seed_i,

            -- LFSR module control
            lfsr_clk => lfsr_clk_i,

            -- Comparator control
            comparator_value_ready_d => comparator_value_ready_i_d,

            -- FIFO control and status
            fifo_full => fifo_full_i,

            -- Acknowledge signal from PS to PL
            puf_response_ack => puf_response_ack_i,

            -- Register trigger for FIFO
            reg_fifo_enable => reg_fifo_i,

            -- Control Reset
            fsm_reset_n => fsm_reset_n_i,
            comparison_reset_n => comparison_reset_n_i
        );

    -----------------------------------------------------------------------------------------------
    -- Output
    -----------------------------------------------------------------------------------------------
    --
    -----------------------------------------------------------------------------------------------
    -- reg_fifo_i_d created as a delayed version of reg_fifo_i to check rising edge
    proc_reg_fifo_reg: process(reset_n, clk)
    begin
        if (reset_n = g_reset_polarity) then
            reg_fifo_i_d <= '0';
        elsif rising_edge(clk) then
            reg_fifo_i_d <= reg_fifo_i;
        end if;
    end process proc_reg_fifo_reg;

    -- If rising edge of reg_fifo_i -> register fifo
    proc_reg_fifo: process(reset_n, clk)
    begin
        if (reset_n = g_reset_polarity) then
            fifo_i_d <= (others => '0');
        elsif rising_edge(clk) then
            if ((reg_fifo_i_d = '0') and (reg_fifo_i = '1')) then
                fifo_i_d <= fifo_i;
            end if;
        end if;
    end process proc_reg_fifo;

    puf_response <= fifo_i_d;
    puf_response_ready <= reg_fifo_i_d;
    puf_response_ack_i <= puf_response_ack;

end architecture rtl;
