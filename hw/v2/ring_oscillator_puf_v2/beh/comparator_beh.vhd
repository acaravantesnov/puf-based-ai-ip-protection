--==============================================================================
-- Title       : Comparator Behavioural TestBench
-- File        : comparator_beh.vhd
-- Author      : Alberto Caravantes Arranz
-- Date        : 24/04/2025
--==============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity comparator_beh is
end comparator_beh;

architecture beh of comparator_beh is

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
    
    -- Constants
    constant c_input_width: natural := 4;
    constant c_timer_eoc: natural := 100E3;
    constant c_reset_Polarity: std_logic := '0';
    constant c_axi_reg_width: natural := 32;
    
    -- Signals
    signal clk_i: std_logic;
    signal reset_n_i: std_logic;
    signal aux_reset_n_i: std_logic;
    signal aux_2_reset_n_i: std_logic;
    signal RO_clks_i: std_logic_vector(c_input_width - 1 downto 0);
    
    signal sampled_counters_ack_i: std_logic;
    signal sampled_counters_ready_i: std_logic;

begin

    comparator_inst: comparator
        generic map(
            g_input_width => c_input_width,
            g_timer_eoc => c_timer_eoc,
            g_reset_polarity => c_reset_Polarity,
            g_axi_reg_width => c_axi_reg_width
        )
        port map(
            clk => clk_i,
            aux_reset_n => aux_reset_n_i,
            aux_2_reset_n => aux_2_reset_n_i,
            reset_n => reset_n_i,
            RO_clks => RO_clks_i,
            comparison_result => open,
            value_ready => open,
            sampled_counters_ack => sampled_counters_ack_i,
            sampled_counters => open,
            sampled_counters_ready => sampled_counters_ready_i
        );
        
    proc_reset_n: process
    begin
        reset_n_i <= c_reset_polarity;
        wait for 1 ms;
        reset_n_i <= not c_reset_polarity;
        wait for 2.2 ms;
        reset_n_i <= c_reset_polarity;
        wait for 1 ms;
        reset_n_i <= not c_reset_polarity;
        wait;
    end process proc_reset_n;
    
    proc_aux_reset_n: process
    begin
        aux_reset_n_i <= c_reset_polarity;
        wait for 1.01 ms;
        aux_reset_n_i <= not c_reset_polarity;
--        wait for 1 ms;
--        aux_reset_n_i <= c_reset_polarity;
        wait;
    end process proc_aux_reset_n;
    
    proc_aux_2_reset_n: process
    begin
        aux_2_reset_n_i <= c_reset_polarity;
        wait for 1.02 ms;
        aux_2_reset_n_i <= not c_reset_polarity;
--        wait for 1 ms;
--        aux_2_reset_n_i <= c_reset_polarity;
        wait;
    end process proc_aux_2_reset_n;
        
    proc_clk: process
    begin
        while true loop
            clk_i <= '1';
            wait for 5 ns;
            clk_i <= '0';
            wait for 5 ns;
        end loop;
    end process proc_clk;
    
    proc_ro_clk_0: process
    begin
        while true loop
            RO_clks_i(0) <= '1';
            wait for 3 ns;
            RO_clks_i(0) <= '0';
            wait for 3 ns;
        end loop;
    end process proc_ro_clk_0;
    
    proc_ro_clk_1: process
    begin
        while true loop
            RO_clks_i(1) <= '1';
            wait for 3.1 ns;
            RO_clks_i(1) <= '0';
            wait for 3.1 ns;
        end loop;
    end process proc_ro_clk_1;
    
    proc_ro_clk_2: process
    begin
        while true loop
            RO_clks_i(2) <= '1';
            wait for 3.3 ns;
            RO_clks_i(2) <= '0';
            wait for 3.3 ns;
        end loop;
    end process proc_ro_clk_2;
    
    proc_ro_clk_3: process
    begin
        while true loop
            RO_clks_i(3) <= '1';
            wait for 3.2 ns;
            RO_clks_i(3) <= '0';
            wait for 3.2 ns;
        end loop;
    end process proc_ro_clk_3;
    
    -- This process simulates the AXI slave acknowledging the data.
    proc_ack_generator: process(clk_i)
    begin
        if rising_edge(clk_i) then
            -- By default, the acknowledge signal is low.
            sampled_counters_ack_i <= '0';
    
            -- When the comparator says the data is ready,
            -- we assert the acknowledge signal for one clock cycle.
            if sampled_counters_ready_i = '1' then
                sampled_counters_ack_i <= '1';
            end if;
        end if;
    end process proc_ack_generator;

end beh;
