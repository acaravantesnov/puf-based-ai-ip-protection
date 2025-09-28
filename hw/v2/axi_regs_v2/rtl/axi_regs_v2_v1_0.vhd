library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_regs_v2_v1_0 is
	generic (
		-- Users to add parameters here
		g_lfsr_width		: natural := 9;
		g_n_ROs_main		: natural := 32;
		g_response_width	: natural := 128;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
		-- lfsr counters axi regs
        lfsr_ros_counters	: in std_logic_vector(((g_lfsr_width * 2) * C_S00_AXI_DATA_WIDTH) - 1 downto 0);
        lfsr_ros_ready		: in std_logic;

        -- main counters axi regs
        main_ros_counters   : in std_logic_vector((g_n_ROs_main * C_S00_AXI_DATA_WIDTH) - 1 downto 0);
        main_ros_ready      : in std_logic;
        main_ros_ack        : out std_logic;

        -- puf response mlp agent
        puf_response		: in std_logic_vector(g_response_width - 1 downto 0);
        puf_response_ready	: in std_logic;
        puf_response_ack 	: out std_logic;
		
		-- lfsr seed mlp agent
        lfsr_ros_corrected	: out std_logic_vector(g_lfsr_width - 1 downto 0);
        lfsr_ros_ack		: out std_logic;

		-- control signals
		reset_n_to_puf		: out std_logic;
		enable_to_puf		: out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_regs_v2_v1_0;

architecture arch_imp of axi_regs_v2_v1_0 is

	-- component declaration
	component axi_regs_v2_v1_0_S00_AXI is
		generic (
			g_lfsr_width		: natural := 9;
			g_n_ROs_main		: natural := 32;
			g_response_width	: natural := 128;
			C_S_AXI_DATA_WIDTH	: integer := 32;
			C_S_AXI_ADDR_WIDTH	: integer := 8
		);
		port (
			lfsr_ros_counters	: in std_logic_vector(((g_lfsr_width * 2) * C_S00_AXI_DATA_WIDTH) - 1 downto 0);
			lfsr_ros_ready		: in std_logic;
			main_ros_counters   : in std_logic_vector((g_n_ROs_main * C_S00_AXI_DATA_WIDTH) - 1 downto 0);
			main_ros_ready      : in std_logic;
			main_ros_ack        : out std_logic;
			puf_response		: in std_logic_vector(g_response_width - 1 downto 0);
			puf_response_ready	: in std_logic;
			puf_response_ack 	: out std_logic;
			lfsr_ros_corrected	: out std_logic_vector(g_lfsr_width - 1 downto 0);
			lfsr_ros_ack		: out std_logic;
			reset_n_to_puf		: out std_logic;
			enable_to_puf		: out std_logic;
			S_AXI_ACLK			: in std_logic;
			S_AXI_ARESETN		: in std_logic;
			S_AXI_AWADDR		: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_AWPROT		: in std_logic_vector(2 downto 0);
			S_AXI_AWVALID		: in std_logic;
			S_AXI_AWREADY		: out std_logic;
			S_AXI_WDATA			: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_WSTRB			: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
			S_AXI_WVALID		: in std_logic;
			S_AXI_WREADY		: out std_logic;
			S_AXI_BRESP			: out std_logic_vector(1 downto 0);
			S_AXI_BVALID		: out std_logic;
			S_AXI_BREADY		: in std_logic;
			S_AXI_ARADDR		: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
			S_AXI_ARPROT		: in std_logic_vector(2 downto 0);
			S_AXI_ARVALID		: in std_logic;
			S_AXI_ARREADY		: out std_logic;
			S_AXI_RDATA			: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
			S_AXI_RRESP			: out std_logic_vector(1 downto 0);
			S_AXI_RVALID		: out std_logic;
			S_AXI_RREADY		: in std_logic
		);
	end component axi_regs_v2_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
axi_regs_v2_v1_0_S00_AXI_inst : axi_regs_v2_v1_0_S00_AXI
	generic map (
		g_lfsr_width => g_lfsr_width,
		g_n_ROs_main => g_n_ROs_main,
		g_response_width => g_response_width,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		lfsr_ros_counters => lfsr_ros_counters,
        lfsr_ros_ready => lfsr_ros_ready,
        main_ros_counters => main_ros_counters,
        main_ros_ready => main_ros_ready,
        main_ros_ack => main_ros_ack,
        puf_response => puf_response,
        puf_response_ready => puf_response_ready,
        puf_response_ack => puf_response_ack,
        lfsr_ros_corrected => lfsr_ros_corrected,
        lfsr_ros_ack => lfsr_ros_ack,
		reset_n_to_puf => reset_n_to_puf,
		enable_to_puf => enable_to_puf,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here

	-- User logic ends

end arch_imp;
