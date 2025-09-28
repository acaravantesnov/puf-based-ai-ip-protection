library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter_map is
    generic(
        g_n_regs          : natural   := 32;
        g_axi_reg_width   : natural   := 32;
        g_reset_polarity  : std_logic := '0'
    );
    port(
        -- Clock and Reset
        clk               : in  std_logic;
        reset_n           : in  std_logic;

        -- comparator_inst communication (Input side)
        counters_to_counter_map : in  std_logic_vector((2 * g_axi_reg_width) - 1 downto 0);
        ready_to_counter_map    : in  std_logic;
        ack_to_comparator       : out std_logic;

        -- main_ro_counters_v1 communication (Output side)
        counters_to_main_ro_counters_v1 : out std_logic_vector((g_n_regs * g_axi_reg_width) - 1 downto 0);
        ready_to_main_ro_counters_v1    : out std_logic;
        ack_to_counter_map              : in  std_logic;

        -- External trigger to start the main transfer
        puf_response_ready : in std_logic;

        -- Indices for storing the incoming pair of counters
        ro0_index   : in natural;
        ro1_index   : in natural
    );
end entity counter_map;

architecture rtl of counter_map is

    -- Internal register array to store the collected counter values.
    type t_vector_array is array (0 to g_n_regs - 1) of std_logic_vector(g_axi_reg_width - 1 downto 0);
    signal regs_i : t_vector_array := (others => (others => '0'));

    -- State machine for the handshake with the main destination component.
    type t_main_handshake_state is (IDLE, WAIT_FOR_ACK);
    signal main_handshake_state : t_main_handshake_state := IDLE;
    signal ready_to_main_ro_counters_i  : std_logic := '0';

begin

    proc_comparator_comm: process(clk)
    begin
        if rising_edge(clk) then
            -- Default ack to low, it will only pulse high for one cycle.
            ack_to_comparator <= '0';

            if (reset_n = g_reset_polarity) then
                regs_i <= (others => (others => '0'));
            else
                if (ready_to_counter_map = '1') then
                    -- A new pair of counters is ready from the comparator.
                    -- Store them in our internal register map at the specified indices.
                    regs_i(ro0_index) <= counters_to_counter_map(g_axi_reg_width - 1 downto 0);
                    regs_i(ro1_index) <= counters_to_counter_map((2 * g_axi_reg_width) - 1 downto g_axi_reg_width);

                    -- Send a one-cycle acknowledgement pulse to the comparator.
                    ack_to_comparator <= '1';
                end if;
            end if;
        end if;
    end process proc_comparator_comm;


    ready_to_main_ro_counters_v1 <= ready_to_main_ro_counters_i;

    proc_main_handshake: process(clk)
    begin
        if rising_edge(clk) then
            if (reset_n = g_reset_polarity) then
                main_handshake_state <= IDLE;
                ready_to_main_ro_counters_i  <= '0';
            else
                case main_handshake_state is
                    when IDLE =>
                        -- Stay in this state until the external trigger is received.
                        ready_to_main_ro_counters_i <= '0';
                        if (puf_response_ready = '1') then
                            -- Trigger received. Assert ready and move to wait for the ack.
                            ready_to_main_ro_counters_i  <= '1';
                            main_handshake_state <= WAIT_FOR_ACK;
                        end if;

                    when WAIT_FOR_ACK =>
                        -- Keep the ready signal high until the destination acknowledges.
                        if (ack_to_counter_map = '1') then
                            -- Acknowledgement received. De-assert ready and return to idle.
                            ready_to_main_ro_counters_i  <= '0';
                            main_handshake_state <= IDLE;
                        else
                            -- Continue to assert ready.
                            ready_to_main_ro_counters_i <= '1';
                        end if;

                end case;
            end if;
        end if;
    end process proc_main_handshake;

    gen_combine_counters: for i in 0 to g_n_regs - 1 generate
        counters_to_main_ro_counters_v1((i + 1) * g_axi_reg_width - 1 downto i * g_axi_reg_width) <= regs_i(i);
    end generate gen_combine_counters;


end architecture rtl;
