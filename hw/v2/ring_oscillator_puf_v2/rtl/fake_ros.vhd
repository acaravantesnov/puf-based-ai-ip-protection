library ieee;
use ieee.std_logic_1164.all;

entity fake_ros is
    generic(
        g_n_ROs      : natural := 8;        -- number of clocks
        g_base_tH    : time    := 3.33 ns;  -- half-period of the slowest clock
        g_delta_tH   : time    := 0.01 ns   -- amount of time removed to make each subsequent clock faster
    );
    port(
        enable  : in  std_logic;
        clk_out : out std_logic_vector(g_n_ROs - 1 downto 0)
    );
end entity fake_ros;

architecture rtl of fake_ros is
begin
    
    ------------------------------------------------------------------
    -- One clock generator per bit
    ------------------------------------------------------------------
    gen_clks : for i in 0 to g_n_ROs - 1 generate
        clk_proc : process
            constant t_half : time := g_base_tH - i * g_delta_tH;
        begin
            loop
                if enable = '1' then
                    clk_out(i) <= '0';
                    wait for t_half;
                    clk_out(i) <= '1';
                    wait for t_half;
                else
                    clk_out(i) <= '0';
                    wait until enable = '1';
                end if;
            end loop;
        end process;
    end generate;
end architecture rtl;
