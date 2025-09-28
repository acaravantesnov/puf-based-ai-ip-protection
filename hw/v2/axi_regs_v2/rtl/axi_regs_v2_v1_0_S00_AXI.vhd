library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_regs_v2_v1_0_S00_AXI is
	generic (
		-- Users to add parameters here
		g_lfsr_width		: natural := 9;
		g_n_ROs_main		: natural := 32;
		g_response_width	: natural := 128;
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 8
	);
	port (
		-- Users to add ports here
		-- lfsr counters axi regs
        lfsr_ros_counters	: in std_logic_vector(((g_lfsr_width * 2) * C_S_AXI_DATA_WIDTH) - 1 downto 0);
        lfsr_ros_ready		: in std_logic;

        -- main counters axi regs
        main_ros_counters   : in std_logic_vector((g_n_ROs_main * C_S_AXI_DATA_WIDTH) - 1 downto 0);
        main_ros_ready      : in std_logic;
        main_ros_ack        : out std_logic;

        -- puf response mlp agent
        puf_response		: in std_logic_vector(g_response_width - 1 downto 0);
        puf_response_ready	: in std_logic;
        puf_response_ack 	: out std_logic;
		
		-- lfsr seed mlp agent
        lfsr_ros_corrected	: out std_logic_vector(g_lfsr_width - 1 downto 0);
        lfsr_ros_ack		: out std_logic;

		-- control reg signals
		reset_n_to_puf		: out std_logic;
		enable_to_puf		: out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_axi_awready	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end axi_regs_v2_v1_0_S00_AXI;

architecture arch_imp of axi_regs_v2_v1_0_S00_AXI is

	-- Constants
	constant ADDR_LSB  			: integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS 	: integer := 5;

	-- AXI4LITE signals
	signal axi_awaddr_i		: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready_i	: std_logic;
	signal axi_wready_i		: std_logic;
	signal axi_bresp_i		: std_logic_vector(1 downto 0);
	signal axi_bvalid_i		: std_logic;
	signal axi_araddr_i		: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready_i	: std_logic;
	signal axi_rdata_i		: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp_i		: std_logic_vector(1 downto 0);
	signal axi_rvalid_i		: std_logic;

	------------------------------------------------
	---- User Logic Signals and Registers
	--------------------------------------------------

	-- AXI Regs v2 IP ============================================================================== --
	--
	-- 0x00 - 0x11	:	lfsr ros counters		-	[R] for PS, [W] by ring_oscilaltor_puf_v2
	-- 0x12 - 0x31	:	main ros counters		-	[R] for PS, [W] by ring_oscilaltor_puf_v2
	-- 0x32 - 0x35	:	puf response			-	[R] for PS, [W] by ring_oscilaltor_puf_v2
	-- 0x36			:	lfsr ros corrected		-	[R/W] for PS, [R] by ring_oscilaltor_puf_v2
	-- 0x37 - 0x3A	:	puf response corrected	-	[R/W] for PS
	--
	-- 0x3B			:	control reg
	--
	--   - Bit 0     :   reset_n                 -   [R/W]
	--   - Bit 1     :   enable                  -   [R/W]
	--   - Bit 2     :   lfsr ros counters ready -   [R]
	--   - Bit 3     :   main ros counters ready -   [R]
	--   - Bit 4     :   puf response ready      -   [R]
	--
	-- ============================================================================================= --

	type slv_reg_array_t is array (0 to 59) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_i: slv_reg_array_t := (others => (others => '0'));

	-- Signals for ring_oscillator_puf_v2 ready edge detection
	signal lfsr_ros_ready_d1_i		: std_logic := '0';
	signal main_ros_ready_d1_i		: std_logic := '0';
	signal puf_response_ready_d1_i	: std_logic := '0';

	-- Internal signals for one-shot acknowledgements
	signal lfsr_ros_ack_i    	: std_logic := '0';
	signal main_ros_ack_i     	: std_logic := '0';
    signal puf_response_ack_i 	: std_logic := '0';

	-- Signals for AXI interface control
	signal slv_reg_rden_i	: std_logic;
	signal slv_reg_wren_i	: std_logic;
	signal reg_data_out_i	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal aw_en_i			: std_logic;

begin

	-- I/O Connections assignments (Generated)
	S_AXI_AWREADY	<= axi_awready_i;
	S_AXI_WREADY	<= axi_wready_i;
	S_AXI_BRESP		<= axi_bresp_i;
	S_AXI_BVALID	<= axi_bvalid_i;
	S_AXI_ARREADY	<= axi_arready_i;
	S_AXI_RDATA		<= axi_rdata_i;
	S_AXI_RRESP		<= axi_rresp_i;
	S_AXI_RVALID	<= axi_rvalid_i;

	--------------------------------------------------------------------------
    ---- User Logic Connections: Signals read by ring_oscillator_puf_v2
    --------------------------------------------------------------------------
	-- [R] by ring_oscillator_puf_v2: Control register signals
	reset_n_to_puf <= slv_reg_i(59)(0);
	enable_to_puf <= slv_reg_i(59)(1);

	-- [R] by ring_oscillator_puf_v2: LFSR Seed Corrected register
	lfsr_ros_corrected <= slv_reg_i(54)(g_lfsr_width - 1 downto 0);

	-- Acknowledgement signals for ring_oscillator_puf_v2
	lfsr_ros_ack <= lfsr_ros_ack_i;
	main_ros_ack <= main_ros_ack_i;
	puf_response_ack <= puf_response_ack_i;


	--------------------------------------------------------------------------
    ---- AXI4-Lite Control Logic and Register Update Logic
    --------------------------------------------------------------------------

	-- Implement axi_awready generation
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if S_AXI_ARESETN = '0' then
				axi_awready_i <= '0';
				aw_en_i <= '1';
			else
				if (axi_awready_i = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en_i = '1') then
					axi_awready_i <= '1';
					aw_en_i <= '0';
				elsif (S_AXI_BREADY = '1' and axi_bvalid_i = '1') then
					aw_en_i <= '1';
					axi_awready_i <= '0';
				else
					axi_awready_i <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_awaddr_i latching
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if S_AXI_ARESETN = '0' then
				axi_awaddr_i <= (others => '0');
			else
				if (axi_awready_i = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en_i = '1') then
					axi_awaddr_i <= S_AXI_AWADDR;
				end if;
			end if;
		end if;
	end process; 

	-- Implement axi_wready generation
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	    	axi_wready_i <= '0';
	    else
			if (axi_wready_i = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en_i = '1') then        
				axi_wready_i <= '1';
			else
				axi_wready_i <= '0';
			end if;
	    end if;
	  end if;
	end process;

	-- Implement write response logic generation
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if S_AXI_ARESETN = '0' then
				axi_bvalid_i  <= '0';
				axi_bresp_i   <= "00";
			else
				if (axi_awready_i = '1' and S_AXI_AWVALID = '1' and axi_wready_i = '1' and S_AXI_WVALID = '1' and axi_bvalid_i = '0') then
					axi_bvalid_i <= '1';
					axi_bresp_i  <= "00"; 
				elsif (S_AXI_BREADY = '1' and axi_bvalid_i = '1') then
					axi_bvalid_i <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement axi_arready generation
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if S_AXI_ARESETN = '0' then
				axi_arready_i <= '0';
				axi_araddr_i  <= (others => '1');
			else
				if (axi_arready_i = '0' and S_AXI_ARVALID = '1') then
					axi_arready_i <= '1';
					axi_araddr_i  <= S_AXI_ARADDR;           
				else
					axi_arready_i <= '0';
				end if;
			end if;
		end if;                   
	end process;

	-- Implement axi_arvalid generation
	process (S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then
			if S_AXI_ARESETN = '0' then
				axi_rvalid_i <= '0';
				axi_rresp_i  <= "00";
			else
				if (axi_arready_i = '1' and S_AXI_ARVALID = '1' and axi_rvalid_i = '0') then
					axi_rvalid_i <= '1';
					axi_rresp_i  <= "00";
				elsif (axi_rvalid_i = '1' and S_AXI_RREADY = '1') then
					axi_rvalid_i <= '0';
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	slv_reg_rden_i <= axi_arready_i and S_AXI_ARVALID and (not axi_rvalid_i);

	--------------------------------------------------------------------------
    ---- PS (AXI Master) Read Accesses [R]
    --------------------------------------------------------------------------
    -- This process selects the register data to be output on the AXI read data bus.
	process (slv_reg_i, axi_araddr_i)
		variable loc_addr_v :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr_v := axi_araddr_i(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr_v is
			when b"000000" => reg_data_out_i <= slv_reg_i(0); -- 0x00: start lfsr ros counters (R by PS)
			when b"000001" => reg_data_out_i <= slv_reg_i(1);
			when b"000010" => reg_data_out_i <= slv_reg_i(2);
			when b"000011" => reg_data_out_i <= slv_reg_i(3);
			when b"000100" => reg_data_out_i <= slv_reg_i(4);
			when b"000101" => reg_data_out_i <= slv_reg_i(5);
			when b"000110" => reg_data_out_i <= slv_reg_i(6);
			when b"000111" => reg_data_out_i <= slv_reg_i(7);
			when b"001000" => reg_data_out_i <= slv_reg_i(8);
			when b"001001" => reg_data_out_i <= slv_reg_i(9);
			when b"001010" => reg_data_out_i <= slv_reg_i(10);
			when b"001011" => reg_data_out_i <= slv_reg_i(11);
			when b"001100" => reg_data_out_i <= slv_reg_i(12);
			when b"001101" => reg_data_out_i <= slv_reg_i(13);
			when b"001110" => reg_data_out_i <= slv_reg_i(14);
			when b"001111" => reg_data_out_i <= slv_reg_i(15);
			when b"010000" => reg_data_out_i <= slv_reg_i(16);
			when b"010001" => reg_data_out_i <= slv_reg_i(17); -- 0x11: end lfsr ros counters (R by PS)

			when b"010010" => reg_data_out_i <= slv_reg_i(18); -- 0x12: start main ros counters (R by PS)
			when b"010011" => reg_data_out_i <= slv_reg_i(19);
			when b"010100" => reg_data_out_i <= slv_reg_i(20);
			when b"010101" => reg_data_out_i <= slv_reg_i(21);
			when b"010110" => reg_data_out_i <= slv_reg_i(22);
			when b"010111" => reg_data_out_i <= slv_reg_i(23);
			when b"011000" => reg_data_out_i <= slv_reg_i(24);
			when b"011001" => reg_data_out_i <= slv_reg_i(25);
			when b"011010" => reg_data_out_i <= slv_reg_i(26);
			when b"011011" => reg_data_out_i <= slv_reg_i(27);
			when b"011100" => reg_data_out_i <= slv_reg_i(28);
			when b"011101" => reg_data_out_i <= slv_reg_i(29);
			when b"011110" => reg_data_out_i <= slv_reg_i(30);
			when b"011111" => reg_data_out_i <= slv_reg_i(31);
			when b"100000" => reg_data_out_i <= slv_reg_i(32);
			when b"100001" => reg_data_out_i <= slv_reg_i(33);
			when b"100010" => reg_data_out_i <= slv_reg_i(34);
			when b"100011" => reg_data_out_i <= slv_reg_i(35);
			when b"100100" => reg_data_out_i <= slv_reg_i(36);
			when b"100101" => reg_data_out_i <= slv_reg_i(37);
			when b"100110" => reg_data_out_i <= slv_reg_i(38);
			when b"100111" => reg_data_out_i <= slv_reg_i(39);
			when b"101000" => reg_data_out_i <= slv_reg_i(40);
			when b"101001" => reg_data_out_i <= slv_reg_i(41);
			when b"101010" => reg_data_out_i <= slv_reg_i(42);
			when b"101011" => reg_data_out_i <= slv_reg_i(43);
			when b"101100" => reg_data_out_i <= slv_reg_i(44);
			when b"101101" => reg_data_out_i <= slv_reg_i(45);
			when b"101110" => reg_data_out_i <= slv_reg_i(46);
			when b"101111" => reg_data_out_i <= slv_reg_i(47);
			when b"110000" => reg_data_out_i <= slv_reg_i(48);
			when b"110001" => reg_data_out_i <= slv_reg_i(49); -- 0x31: end main ros counters (R by PS)

			when b"110010" => reg_data_out_i <= slv_reg_i(50); -- 0x32: start puf response (R by PS)
			when b"110011" => reg_data_out_i <= slv_reg_i(51);
			when b"110100" => reg_data_out_i <= slv_reg_i(52);
			when b"110101" => reg_data_out_i <= slv_reg_i(53); -- 0x35: end puf response (R by PS)

			when b"110110" => reg_data_out_i <= slv_reg_i(54); -- 0x36: lfsr ros corrected (R/W by PS)

			when b"110111" => reg_data_out_i <= slv_reg_i(55); -- 0x37: start puf response corrected (R/W by PS)
			when b"111000" => reg_data_out_i <= slv_reg_i(56);
			when b"111001" => reg_data_out_i <= slv_reg_i(57);
			when b"111010" => reg_data_out_i <= slv_reg_i(58); -- 0x3A: end puf response (R/W by PS)

			when b"111011" => reg_data_out_i <= slv_reg_i(59); -- 0x3B: control reg (R/W by PS)
			when others => reg_data_out_i  <= (others => '0');
	    end case;
	end process;

	-- Output register or memory read data
	process(S_AXI_ACLK) is
	begin
		if (rising_edge (S_AXI_ACLK)) then
			if (S_AXI_ARESETN = '0') then
				axi_rdata_i  <= (others => '0');
			else
				if (slv_reg_rden_i = '1') then
					axi_rdata_i <= reg_data_out_i;
				end if;
			end if;
		end if;
	end process;

	-- Implement memory mapped register select and write logic generation
	slv_reg_wren_i <= axi_wready_i and S_AXI_WVALID and axi_awready_i and S_AXI_AWVALID;

	--------------------------------------------------------------------------
    ---- Register Update Logic (PS Writes and ring_oscillator_puf_v2 Writes)
    --------------------------------------------------------------------------
	-- This process handles both AXI write transactions and updates from the custom IP.
	-- Combined Register Update Process for both AXI and ring_oscillator_puf_v2
	process (S_AXI_ACLK)
        variable loc_addr_v 	: std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
		variable byte_index_v	: integer;
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                -- Reset all internal registers and acknowledgement signals
                for i in slv_reg_i'range loop
                    slv_reg_i(i) <= (others => '0');
                end loop;

                main_ros_ack_i    <= '0';
                puf_response_ack_i <= '0';
                lfsr_ros_ack_i    <= '0';

                -- Reset edge detection flip-flops
                lfsr_ros_ready_d1_i <= '0';
                main_ros_ready_d1_i <= '0';
                puf_response_ready_d1_i <= '0';

            else
                -- Capture previous states of ready signals for edge detection
                lfsr_ros_ready_d1_i <= lfsr_ros_ready;
                main_ros_ready_d1_i <= main_ros_ready;
                puf_response_ready_d1_i <= puf_response_ready;

                -- Default acknowledge signals to low (one-shot pulse)
                main_ros_ack_i    	<= '0';
                puf_response_ack_i	<= '0';
                lfsr_ros_ack_i    	<= '0';

				-- Latch the address for write transactions
				loc_addr_v := axi_awaddr_i(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

                ------------------------------------------------------------------
                ---- PS (AXI Master) Write Accesses [W] to data registers
                ------------------------------------------------------------------
                if (slv_reg_wren_i = '1') then -- AXI write transaction is valid
                    case loc_addr_v is
						-- 0x36 : lfsr seed corrected (slv_reg54) - [R/W] for PS
                        when b"110110" =>
                            for byte_index_v in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if (S_AXI_WSTRB(byte_index_v) = '1') then
                                    slv_reg_i(54)(byte_index_v*8+7 downto byte_index_v*8) <= S_AXI_WDATA(byte_index_v*8+7 downto byte_index_v*8);
                                end if;
                            end loop;
                            -- Trigger lfsr_ros_ack for one cycle when PS writes to this register
                            lfsr_ros_ack_i <= '1';

                        -- 0x37 - 0x3A: PUF Response Corrected (slv_reg55 to slv_reg58) - [R/W] for PS
                        when b"110111" => -- slv_reg55 (0x37)
                            for byte_index_v in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if (S_AXI_WSTRB(byte_index_v) = '1') then
                                    slv_reg_i(55)(byte_index_v*8+7 downto byte_index_v*8) <= S_AXI_WDATA(byte_index_v*8+7 downto byte_index_v*8);
                                end if;
                            end loop;
                        when b"111000" => -- slv_reg56 (0x38)
                            for byte_index_v in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if (S_AXI_WSTRB(byte_index_v) = '1') then
                                    slv_reg_i(56)(byte_index_v*8+7 downto byte_index_v*8) <= S_AXI_WDATA(byte_index_v*8+7 downto byte_index_v*8);
                                end if;
                            end loop;
                        when b"111001" => -- slv_reg57 (0x39)
                            for byte_index_v in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if (S_AXI_WSTRB(byte_index_v) = '1') then
                                    slv_reg_i(57)(byte_index_v*8+7 downto byte_index_v*8) <= S_AXI_WDATA(byte_index_v*8+7 downto byte_index_v*8);
                                end if;
                            end loop;
                        when b"111010" => -- slv_reg58 (0x3A)
                            for byte_index_v in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                                if (S_AXI_WSTRB(byte_index_v) = '1') then
                                    slv_reg_i(58)(byte_index_v*8+7 downto byte_index_v*8) <= S_AXI_WDATA(byte_index_v*8+7 downto byte_index_v*8);
                                end if;
                            end loop;
						
						-- All other addresses are handled elsewhere or are read-only from the PS side.
                        when others =>
                            null;
                    end case;
                end if;

				------------------------------------------------------------------
                ---- Control Register (slv_reg_i(59)) Logic
                ------------------------------------------------------------------
				-- Handle direct write bits (enable 1, reset_n 0)
				if (slv_reg_wren_i = '1' and loc_addr_v = b"111011") then
					if (S_AXI_WSTRB(0) = '1') then
						slv_reg_i(59)(1 downto 0) <= S_AXI_WDATA(1 downto 0);
					end if;
				end if;

				-- Handle status flag bit 2 (lfsr_ros_counters_ready) with clear_on_write priority
				if (slv_reg_wren_i = '1' and loc_addr_v = b"111011" and S_AXI_WDATA(2) = '0' and S_AXI_WSTRB(0) = '1') then
					slv_reg_i(59)(2) <= '0'; -- PS clears the flag
				elsif (lfsr_ros_ready = '1' and lfsr_ros_ready_d1_i = '0') then
					slv_reg_i(59)(2) <= '1'; -- ring_oscillator_puf_v2 sets the flag
				end if;

				-- Handle status flag bit 3 (main_ros_counters_ready) with clear_on_write priority
				if (slv_reg_wren_i = '1' and loc_addr_v = b"111011" and S_AXI_WDATA(3) = '0' and S_AXI_WSTRB(0) = '1') then
					slv_reg_i(59)(3) <= '0'; -- PS clears the flag
				elsif (main_ros_ready = '1' and main_ros_ready_d1_i = '0') then
					slv_reg_i(59)(3) <= '1'; -- Peripheral sets the flag
				end if;

				-- Handle status flag bit 4 (puf_rresponse_ready) with clear_on_write priority
				if (slv_reg_wren_i = '1' and loc_addr_v = b"111011" and S_AXI_WDATA(4) = '0' and S_AXI_WSTRB(0) = '1') then
					slv_reg_i(59)(4) <= '0'; -- PS clears the flag
				elsif (puf_response_ready = '1' and puf_response_ready_d1_i = '0') then
					slv_reg_i(59)(4) <= '1'; -- Peripheral sets the flag
				end if;

                ------------------------------------------------------------------
                ---- ring_oscillator_puf_v2 Write Accesses [W]
                ------------------------------------------------------------------
                -- 0x00 - 0x11: lfsr ros counters (slv_reg0 to slv_reg17)
                -- These are updated by the ring_oscillator_puf_v2.
                -- Total LFSR width: (g_lfsr_width * 2) * C_S_AXI_DATA_WIDTH = 18 * 32 = 576 bits
                if (lfsr_ros_ready = '1' and lfsr_ros_ready_d1_i = '0') then -- Rising edge of lfsr_ros_ready
                    for i in 0 to 17 loop -- 18 registers from slv_reg0 to slv_reg17
                        slv_reg_i(i) <= lfsr_ros_counters(((i+1)*C_S_AXI_DATA_WIDTH)-1 downto i*C_S_AXI_DATA_WIDTH);
                    end loop;
                    -- lfsr_ros_ack is triggered by PS write, not by data reception here.
                end if;

                -- 0x12 - 0x31: Main Counters (slv_reg18 to slv_reg49)
                -- These are updated by the ring_oscillator_puf_v2.
                -- Total main counters width: g_n_ROs_main * C_S_AXI_DATA_WIDTH = 32 * 32 = 1024 bits
                if (main_ros_ready = '1' and main_ros_ready_d1_i = '0') then -- Rising edge of main_ros_ready
                    for i in 0 to (g_n_ROs_main-1) loop -- 32 registers from slv_reg18 to slv_reg49
                        slv_reg_i(18+i) <= main_ros_counters(((i+1)*C_S_AXI_DATA_WIDTH)-1 downto i*C_S_AXI_DATA_WIDTH);
                    end loop;
                    main_ros_ack_i <= '1'; -- Assert acknowledgment for one cycle
                end if;

                -- 0x32 - 0x35: PUF Response (slv_reg50 to slv_reg53)
                -- These are updated by the ring_oscillator_puf_v2.
                -- Total PUF response width: g_response_width = 128 bits = 4 * 32 bits
                if (puf_response_ready = '1' and puf_response_ready_d1_i = '0') then -- Rising edge of puf_response_ready
                    for i in 0 to 3 loop -- 4 registers from slv_reg50 to slv_reg53
                        slv_reg_i(50+i) <= puf_response(((i+1)*C_S_AXI_DATA_WIDTH)-1 downto i*C_S_AXI_DATA_WIDTH);
                    end loop;
                    puf_response_ack_i <= '1'; -- Assert acknowledgment for one cycle
                end if;

            end if;
        end if;
    end process;

end arch_imp;
