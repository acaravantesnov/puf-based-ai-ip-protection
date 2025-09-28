library ieee;
use ieee.std_logic_1164.all;

entity fake_ros_beh is
end fake_ros_beh;

architecture Behavioral of fake_ros_beh is

    component fake_ros is
        generic(
            g_n_ROs      : natural := 8;        -- number of clocks
            g_base_tH    : time    := 3.33 ns;  -- half-period of the fastest clock
            g_delta_tH   : time    := 0.01 ns      -- extra time added per slower clock
        );
        port(
            enable  : in  std_logic;
            clk_out : out std_logic_vector(g_n_ROs - 1 downto 0)
        );
    end component fake_ros;
    
    -- Constants
    constant c_n_ROs: natural := 8;
    constant c_base_tH: time    := 3.33 ns;
    constant c_delta_tH: time    := 0.01 ns;
    
    -- Signals
    signal enable_i: std_logic;

begin

    fake_ros_inst: fake_ros
        generic map(
            g_n_ROs => c_n_ROs,
            g_base_tH => c_base_tH,
            g_delta_tH => c_delta_tH
        )
        port map(
            enable => enable_i,
            clk_out => open
        );
        
    proc_enable: process
    begin
        enable_i <= '0';
        wait for 1 us;
        enable_i <= '1';
        wait;
    end process proc_enable;

end Behavioral;
