--=================================================================================================
-- Title       : Comparator
-- File        : comparator_rtl.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 01/06/2025
--=================================================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity comparator is
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
end entity comparator;

architecture rtl of comparator is

    -- Constants
    constant c_output_width: natural := (g_input_width / 2);

    -- Reset logic
    signal reset_n_comb_i: std_logic    := '0';
    signal temp_reset_sync_i: std_logic := '0';
    signal reset_sync_i: std_logic      := '0';

    type t_natural_array is array (natural range <>) of natural;
    signal counter_i: t_natural_array(g_input_width - 1 downto 0)           := (others => 0);
   
    signal ro_clk_stage1: std_logic_vector(g_input_width - 1 downto 0)      := (others => '0');
    signal ro_clk_stage2: std_logic_vector(g_input_width - 1 downto 0)      := (others => '0');
    signal ro_clk_stage2_prev: std_logic_vector(g_input_width - 1 downto 0) := (others => '0');
    
    signal sampled_counters_i : t_natural_array(g_input_width - 1 downto 0) := (others => 0);

    signal timer_i: natural range 0 to g_timer_eoc  := 0;
    signal eoc_i: std_logic                         := '0';
    signal eoc_i_d: std_logic                       := '0';

    -- Comparison result logic
    signal comparison_result_i: std_logic_vector(c_output_width - 1 downto 0)   := (others => '0');
    signal value_ready_i: std_logic                                             := '0';
    signal value_ready_sent: std_logic                                          := '0';
    

    -- AXI debug logic
    type t_handshake_state is (IDLE, WAIT_FOR_ACK);
    
    signal sampled_counters_ready_comb_i: std_logic     := '0';
    signal counters_handshake_state: t_handshake_state  := IDLE;
    signal sampled_counters_ready_i: std_logic          := '0';

begin

    -----------------------------------------------------------------------------------------------
    -- Reset logic
    -----------------------------------------------------------------------------------------------
    -- Two-stage asynchronous reset synchronizer
    -----------------------------------------------------------------------------------------------

    reset_n_comb_i <= '1' when ((reset_n = g_reset_polarity) or (aux_reset_n = g_reset_polarity) or (aux_2_reset_n = g_reset_polarity)) else '0';
   
    process(clk)
    begin
        if rising_edge(clk) then
            temp_reset_sync_i <= reset_n_comb_i;
            reset_sync_i      <= temp_reset_sync_i;
        end if;
    end process;
    
    -----------------------------------------------------------------------------------------------
    -- Ring Oscillators logic
    -----------------------------------------------------------------------------------------------

    -- Doubly synchronizing Ring Oscillator clocks
    proc_ro_clk_synchronizer: process(clk)
    begin
        if rising_edge(clk) then
            ro_clk_stage1 <= RO_clks;
            ro_clk_stage2 <= ro_clk_stage1;
        end if;
    end process proc_ro_clk_synchronizer;
    
    -- Counting ring oscillator clock edges
    gen_counters: for i in 0 to g_input_width - 1 generate
        proc_single_counter: process(clk)
        begin
            if rising_edge(clk) then
                if reset_sync_i = '1' then
                    counter_i(i)          <= 0;
                    ro_clk_stage2_prev(i) <= '0';
                else
                    ro_clk_stage2_prev(i) <= ro_clk_stage2(i);
    
                    -- Edge Detection Logic
                    if ro_clk_stage2(i) = '1' and ro_clk_stage2_prev(i) = '0' then
                        counter_i(i) <= counter_i(i) + 1;
                    end if;
                end if;
            end if;
        end process proc_single_counter;
    end generate gen_counters;
    
    proc_timer: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1')  then
                timer_i <= 0;
                eoc_i <= '0';
            elsif (timer_i < g_timer_eoc) then
                timer_i <= timer_i + 1;
                eoc_i <= '0';
            else
                eoc_i <= '1';
            end if;
        end if;
    end process proc_timer;

    proc_sampling: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1') then
                sampled_counters_i <= (others => 0);
            elsif (eoc_i = '1') and (eoc_i_d = '0') then
                for i in 0 to g_input_width - 1 loop
                    sampled_counters_i(i) <= counter_i(i);
                end loop;
            end if;
        end if;
    end process proc_sampling;

    -----------------------------------------------------------------------------------------------
    -- Comparison result logic
    -----------------------------------------------------------------------------------------------

    comparison_result <= comparison_result_i;
    value_ready <= value_ready_i;

    proc_comparison_result: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1') then
                comparison_result_i <= (others => '0');
            elsif (value_ready_sent = '1') then
                for i in 0 to c_output_width - 1 loop
                    if (sampled_counters_i(2 * i) > sampled_counters_i(2 * i + 1)) then
                        comparison_result_i(i) <= '1';
                    else
                        comparison_result_i(i) <= '0';
                    end if;
                end loop;
            end if;
        end if;
    end process proc_comparison_result;

    proc_value_ready: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1') then
                value_ready_i     <= '0';
                value_ready_sent  <= '0';
            elsif (eoc_i = '1') and (eoc_i_d = '0') then
                value_ready_i     <= '1'; -- pulse
                value_ready_sent  <= '1';
            else
                value_ready_i     <= '0'; -- clear after 1 cycle
            end if;
        end if;
    end process proc_value_ready;
    
    -----------------------------------------------------------------------------------------------
    -- AXI debug logic
    -----------------------------------------------------------------------------------------------
    
    sampled_counters_ready_comb_i <= '1' when (eoc_i_d = '1') else '0';
    
    process(clk)
    begin
        if rising_edge(clk) then
            if (reset_sync_i = '1') then
                eoc_i_d <= '0';
            else
                eoc_i_d <= eoc_i;
            end if;
        end if;
    end process;

    -- Combine the sampled counters values into a single std_logic_vector
    proc_combine_counters: process(sampled_counters_i)
    begin
        for i in g_input_width downto 1 loop
            sampled_counters(((i * g_axi_reg_width) - 1) downto ((i - 1) * g_axi_reg_width)) <= std_logic_vector(to_unsigned(sampled_counters_i(i - 1), g_axi_reg_width));
        end loop;
    end process proc_combine_counters;
    
    -- Handshake fsm logic
    sampled_counters_ready <= sampled_counters_ready_i;

    proc_counters_handshake: process(clk)
    begin
        if rising_edge(clk) then
            if reset_sync_i = '1' then
                sampled_counters_ready_i <= '0';
                counters_handshake_state <= IDLE;
            else
                case counters_handshake_state is
                    when IDLE =>
                        sampled_counters_ready_i <= '0';
                        if sampled_counters_ready_comb_i = '1' then
                            counters_handshake_state <= WAIT_FOR_ACK;
                        end if;
                    when WAIT_FOR_ACK =>
                        -- Assert the internal ready signal to tell the AXI slave the data is valid.
                        sampled_counters_ready_i <= '1';
    
                        -- Halt, keeping the signal high, until the AXI slave acknowledges it by sending back sampled_counters_ack = '1'.
                        if sampled_counters_ack = '1' then
                            counters_handshake_state <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process proc_counters_handshake;

end architecture rtl;
