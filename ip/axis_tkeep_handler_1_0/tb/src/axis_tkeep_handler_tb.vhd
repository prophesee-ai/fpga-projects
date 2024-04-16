----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Benoit Michel (bmichel@prophesee.ai)
-- Create Date:    November 2, 2023
-- Module Name:    axis_tkeep_handler_tb
-- Target Devices:
-- Tool versions:  Xilinx Vivado 2022.2
-- Description:    Skid buffer testbench
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axis_tkeep_handler_tb is
  generic (
    AXIL_ADDR_WIDTH_G : integer := 32;
    AXIL_DATA_WIDTH_G : integer := 32;
    DATA_BUS_WIDTH_G  : integer := 64
  );
end axis_tkeep_handler_tb;

architecture behavioral of axis_tkeep_handler_tb is

  ----------------------------
  -- Component Declarations --
  ----------------------------

  ----------------------------
  -- Clock and Reset Generator
  component clk_rst_gen is
    generic (
      CLK_FREQ_HZ_G               : positive := 100000000;
      CLK_PHASE_SHIFT_DEGREES_G   : natural  := 0;
      RST_ASSERT_DELAY_CYCLES_G   : natural  := 0;
      RST_DEASSERT_DELAY_CYCLES_G : natural  := 100
    );
    port (
      -- Clock and Reset Outputs
      clk_o    : out std_logic;
      arst_n_o : out std_logic;
      srst_o   : out std_logic
    );
  end component clk_rst_gen;

  -----------------------------------------------------
  -- Reads an events stream from a file and replays it
  -- on its AXI4-Stream output port.
  -- Valid line toggles with the VALID_RATIO_G.
  component evt_replay_raw is
    generic (
      READER_NAME_G    : string   := "Reader";
      INPUT_FILE_G     : string   := "input_file.pat";
      VALID_RATIO_G    : real     := 1.0;
      DATA_WIDTH_G     : positive := 64
    );
    port (
      -- Clock
      clk              : in  std_logic;

      -- Control
      start_i          : in  std_logic;
      end_o            : out std_logic;

      -- Stream
      ready_i          : in  std_logic;
      valid_o          : out std_logic;
      data_o           : out std_logic_vector(DATA_WIDTH_G-1 downto 0);
      keep_o           : out std_logic_vector((DATA_WIDTH_G/8)-1 downto 0);
      first_o          : out std_logic;
      last_o           : out std_logic
    );
  end component evt_replay_raw;

  --------------------------
  -- AXI4-Stream Skid Buffer
  component skid_buffer is
    generic (
      DATA_WIDTH_G : positive := 64
    );
    port (
      clk          : in  std_logic;
      rst          : in  std_logic;

      -- Input Data Stream
      in_ready_o   : out std_logic;
      in_valid_i   : in  std_logic;
      in_data_i    : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);
      in_keep_i    : in  std_logic_vector((DATA_WIDTH_G/8)-1 downto 0);
      in_first_i   : in  std_logic;
      in_last_i    : in  std_logic;

      -- Output Data Stream
      out_ready_i  : in  std_logic;
      out_valid_o  : out std_logic;
      out_data_o   : out std_logic_vector(DATA_WIDTH_G-1 downto 0);
      out_keep_o   : out std_logic_vector((DATA_WIDTH_G/8)-1 downto 0);
      out_first_o  : out std_logic;
      out_last_o   : out std_logic
    );
  end component skid_buffer;

  ----------------------------
  -- AXI4-Stream TKEEP Handler
  component axis_tkeep_handler is
    generic (
      AXIL_ADDR_WIDTH_G : positive := 32;
      AXIL_DATA_WIDTH_G : positive := 32;
      DATA_BUS_WIDTH_G  : positive := 64
    );
    port (
      clk               : in  std_logic;
      rst               : in  std_logic;

      -- Slave AXI4-Lite Interface for Registers Configuration
      s_axi_aclk        : in  std_logic;
      s_axi_aresetn     : in  std_logic;
      s_axi_araddr      : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_arprot      : in  std_logic_vector(2 downto 0);
      s_axi_arready     : out std_logic;
      s_axi_arvalid     : in  std_logic;
      s_axi_awaddr      : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_awprot      : in  std_logic_vector(2 downto 0);
      s_axi_awready     : out std_logic;
      s_axi_awvalid     : in  std_logic;
      s_axi_bready      : in  std_logic;
      s_axi_bresp       : out std_logic_vector(1 downto 0);
      s_axi_bvalid      : out std_logic;
      s_axi_rdata       : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      s_axi_rready      : in  std_logic;
      s_axi_rresp       : out std_logic_vector(1 downto 0);
      s_axi_rvalid      : out std_logic;
      s_axi_wdata       : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      s_axi_wready      : out std_logic;
      s_axi_wstrb       : in  std_logic_vector(3 downto 0);
      s_axi_wvalid      : in  std_logic;

      -- Input Data Stream
      s_axis_tready     : out std_logic;
      s_axis_tvalid     : in  std_logic;
      s_axis_tdata      : in  std_logic_vector(63 downto 0);
      s_axis_tkeep      : in  std_logic_vector(7 downto 0);
      --s_axis_tfirst     : in  std_logic;
      s_axis_tlast      : in  std_logic;

      -- Output Data Stream
      m_axis_tready     : in  std_logic;
      m_axis_tvalid     : out std_logic;
      m_axis_tdata      : out std_logic_vector(63 downto 0);
      m_axis_tkeep      : out std_logic_vector(7 downto 0);
      --m_axis_tfirst     : out std_logic;
      m_axis_tlast      : out std_logic
    );
  end component axis_tkeep_handler;

  --------------------------------------------------
  -- Toggle a ready signal to generate back pressure
  component back_pressure_generator is
    generic (
      VALID_RATIO_G    : real                 := 1.0
    );
    port (
      -- Clock
      clk              : in  std_logic;

      -- Control
      start_i          : in  std_logic;

      -- Output
      ready_o          : out std_logic
    );
  end component back_pressure_generator;

  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Clock and Reset Signals
  signal clk_s                          : std_logic;
  signal arst_n_s                       : std_logic;
  signal srst_s                         : std_logic;

  -- Data streams
  signal file_reader_out_ready_s        : std_logic;
  signal file_reader_out_valid_s        : std_logic;
  signal file_reader_out_data_s         : std_logic_vector(DATA_BUS_WIDTH_G-1 DOWNTO 0);
  signal file_reader_out_keep_s         : std_logic_vector((DATA_BUS_WIDTH_G/8)-1 DOWNTO 0);
  signal file_reader_out_first_s        : std_logic;
  signal file_reader_out_last_s         : std_logic;

  signal skid_buffer_out_ready_s        : std_logic;
  signal skid_buffer_out_valid_s        : std_logic;
  signal skid_buffer_out_data_s         : std_logic_vector(DATA_BUS_WIDTH_G-1 DOWNTO 0);
  signal skid_buffer_out_keep_s         : std_logic_vector((DATA_BUS_WIDTH_G/8)-1 DOWNTO 0);
  signal skid_buffer_out_first_s        : std_logic;
  signal skid_buffer_out_last_s         : std_logic;

  signal tkeep_handler_out_ready_s      : std_logic;
  signal tkeep_handler_out_valid_s      : std_logic;
  signal tkeep_handler_out_data_s       : std_logic_vector(DATA_BUS_WIDTH_G-1 DOWNTO 0);
  signal tkeep_handler_out_keep_s       : std_logic_vector((DATA_BUS_WIDTH_G/8)-1 DOWNTO 0);
  signal tkeep_handler_out_first_s      : std_logic;
  signal tkeep_handler_out_last_s       : std_logic;

  -- Signal to help visualizing when data is valid
  signal tkeep_handler_out_data_valid_s : std_logic;

  -- AXI4-Lite Interface
  signal s_axi_aclk                     : std_logic;
  signal s_axi_aresetn                  : std_logic;
  -- Read address channel
  signal s_axi_araddr                   : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal s_axi_arprot                   : std_logic_vector(2 downto 0);
  signal s_axi_arready                  : std_logic;
  signal s_axi_arvalid                  : std_logic;
  -- Write address channel
  signal s_axi_awaddr                   : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal s_axi_awprot                   : std_logic_vector(2 downto 0);
  signal s_axi_awready                  : std_logic;
  signal s_axi_awvalid                  : std_logic;
  -- Write response channel
  signal s_axi_bready                   : std_logic;
  signal s_axi_bresp                    : std_logic_vector(1 downto 0);
  signal s_axi_bvalid                   : std_logic;
  -- Read data channel
  signal s_axi_rdata                    : std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
  signal s_axi_rready                   : std_logic;
  signal s_axi_rresp                    : std_logic_vector(1 downto 0);
  signal s_axi_rvalid                   : std_logic;
  -- Write data channel
  signal s_axi_wdata                    : std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
  signal s_axi_wready                   : std_logic;
  signal s_axi_wstrb                    : std_logic_vector(3 downto 0);
  signal s_axi_wvalid                   : std_logic;


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Help visualizing when data is valid in the waveform
  tkeep_handler_out_data_valid_s <= tkeep_handler_out_ready_s and tkeep_handler_out_valid_s and clk_s;

  s_axi_aclk    <= clk_s;
  s_axi_aresetn <= arst_n_s;

  -- AXI4-Lite transactions
  axil_transactions : process

    procedure axil_read(araddr : in std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0)) is
    begin
      wait until rising_edge(clk_s);
      -- The master can assert the ARVALID signal only when it drives valid address and control information
      s_axi_araddr  <= araddr;
      s_axi_arprot  <= "010";
      s_axi_arvalid <= '1';

      wait until rising_edge(clk_s);

      -- ARVALID must remain asserted until the rising clock edge after the slave asserts the ARREADY signal
      wait until s_axi_arready = '1';
      --wait until rising_edge(clk_s);
      s_axi_arvalid <= '0';

      -- The slave can assert the RVALID signal only when it drives valid read data. When asserted, RVALID must remain
      -- asserted until the rising clock edge after the master asserts RREADY.
      --if s_axi_rvalid = '0' then
      --  wait until s_axi_rvalid = '1';
      --end if;
    end procedure;

    procedure axil_write(awaddr : in std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
                         wdata : in std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0)) is
    begin
      wait until rising_edge(clk_s);
      -- The master can assert the AWVALID signal only when it drives valid address and control information
      s_axi_awaddr  <= awaddr;
      s_axi_awprot  <= "010";
      s_axi_awvalid <= '1';

      -- The master can assert the WVALID signal only when it drives valid write data
      s_axi_wdata   <= wdata;
      s_axi_wvalid  <= '1';

      wait until rising_edge(clk_s);

      -- AWVALID must remain asserted until the rising clock edge after the slave asserts AWREADY
      wait until s_axi_awready = '1';
      --wait until rising_edge(clk_s);
      s_axi_awvalid <= '0';

      -- WVALID must remain asserted until the rising clock edge after the slave asserts WREADY
      if s_axi_wready = '0' then
        wait until s_axi_wready = '1';
        wait until rising_edge(clk_s);
      end if;
      s_axi_wvalid  <= '0';
    end procedure;

  begin
    s_axi_araddr  <= (others => '0');
    -- Access permissions:
    -- AxPROT[0]: 1 => Privileged Access,  0 => Unprivileged Access
    -- AxPROT[1]: 1 => Non-Secure Access,  0 => Secure Access
    -- AxPROT[2]: 1 => Instruction Access, 0 => Data Access
    s_axi_arprot  <= "010";
    s_axi_arvalid <= '0';
    s_axi_awaddr  <= (others => '0');
    s_axi_awprot  <= "010";
    s_axi_awvalid <= '0';
    -- The default state of BREADY can be HIGH, but only if the master can always accept a write response in a single cycle
    s_axi_bready  <= '1';
    -- The default state of RREADY can be HIGH, but only if the master is able to accept read data immediately, whenever it starts a read transaction
    s_axi_rready  <= '1';
    s_axi_wdata   <= (others => '0');
    s_axi_wstrb   <= (others => '0');
    s_axi_wvalid  <= '0';

    -- Wait for reset to complete
    if (srst_s /= '1') then
      wait until srst_s = '1';
    end if;
    wait until srst_s = '0';

    wait until rising_edge(clk_s);
    wait until rising_edge(clk_s);
    wait until rising_edge(clk_s);
    wait until rising_edge(clk_s);
    wait until rising_edge(clk_s);

    axil_read(x"0000_0000");                 -- Read VERSION register
    axil_read(x"0000_0004");                 -- Read CONTROL register
    axil_read(x"0000_0008");                 -- Read CONFIG register
    axil_read(x"0000_000C");                 -- Read unmapped register
    axil_read(x"0000_0104");                 -- Read unmapped register
    axil_read(x"0000_0004");                 -- Read CONTROL register
    axil_read(x"0000_0000");                 -- Read VERSION register

    axil_write(x"0000_0000", x"FFFF_FFFF");  -- write VERSION register
    axil_write(x"0000_0004", x"FFFF_FFFF");  -- write CONTROL register
    axil_write(x"0000_0008", x"FFFF_FFFF");  -- write CONFIG register
    axil_write(x"0000_000C", x"FFFF_FFFF");  -- write unmapped register
    axil_write(x"0000_0104", x"FFFF_FFFF");  -- write unmapped register
    axil_write(x"0000_0004", x"FFFF_FFFF");  -- write CONTROL register
    axil_write(x"0000_0000", x"FFFF_FFFF");  -- write VERSION register

    axil_read(x"0000_0000");                 -- Read VERSION register
    axil_read(x"0000_0004");                 -- Read CONTROL register
    axil_read(x"0000_0008");                 -- Read CONFIG register

    wait;

  end process;


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------

  ---------------------------------
  -- Core Clock and Reset Generator
  clk_rst_gen_u : clk_rst_gen
  generic map (
    CLK_FREQ_HZ_G               => 100000000,
    CLK_PHASE_SHIFT_DEGREES_G   => 0,
    RST_ASSERT_DELAY_CYCLES_G   => 0,
    RST_DEASSERT_DELAY_CYCLES_G => 10
  )
  port map (
    -- Clock and Reset Outputs
    clk_o    => clk_s,
    arst_n_o => arst_n_s,
    srst_o   => srst_s
  );

  --------------
  -- File reader
  evt_replay_raw_u : evt_replay_raw
  generic map (
    READER_NAME_G => "File Input Reader",
    INPUT_FILE_G  => "in_evt_file.pat",
    VALID_RATIO_G => 0.68,
    DATA_WIDTH_G  => DATA_BUS_WIDTH_G
  )
  port map (
    -- Clock
    clk           => clk_s,

    -- Control
    start_i       => arst_n_s,
    end_o         => open,

    -- Stream
    ready_i       => file_reader_out_ready_s,
    valid_o       => file_reader_out_valid_s,
    data_o        => file_reader_out_data_s,
    keep_o        => file_reader_out_keep_s,
    first_o       => file_reader_out_first_s,
    last_o        => file_reader_out_last_s
  );

  --------------------------
  -- AXI4-Stream Skid Buffer
  skid_buffer_u : skid_buffer
  generic map (
    DATA_WIDTH_G => DATA_BUS_WIDTH_G
  )
  port map (
    clk          => clk_s,
    rst          => srst_s,

    -- Input Data Stream
    in_ready_o   => file_reader_out_ready_s,
    in_valid_i   => file_reader_out_valid_s,
    in_data_i    => file_reader_out_data_s,
    in_keep_i    => file_reader_out_keep_s,
    in_first_i   => file_reader_out_first_s,
    in_last_i    => file_reader_out_last_s,

    -- Output Data Stream
    out_ready_i  => skid_buffer_out_ready_s,
    out_valid_o  => skid_buffer_out_valid_s,
    out_data_o   => skid_buffer_out_data_s,
    out_keep_o   => skid_buffer_out_keep_s,
    out_first_o  => open,  --skid_buffer_out_first_s,
    out_last_o   => skid_buffer_out_last_s
  );

  ----------------------------
  -- AXI4-Stream TKEEP handler
  axis_tkeep_handler_u : axis_tkeep_handler
  generic map (
    AXIL_ADDR_WIDTH_G => AXIL_ADDR_WIDTH_G,
    AXIL_DATA_WIDTH_G => AXIL_DATA_WIDTH_G,
    DATA_BUS_WIDTH_G  => DATA_BUS_WIDTH_G
  )
  port map (
    clk               => clk_s,
    rst               => srst_s,

    s_axi_aclk        => s_axi_aclk,
    s_axi_aresetn     => s_axi_aresetn,
    s_axi_araddr      => s_axi_araddr,
    s_axi_arprot      => s_axi_arprot,
    s_axi_arready     => s_axi_arready,
    s_axi_arvalid     => s_axi_arvalid,
    s_axi_awaddr      => s_axi_awaddr,
    s_axi_awprot      => s_axi_awprot,
    s_axi_awready     => s_axi_awready,
    s_axi_awvalid     => s_axi_awvalid,
    s_axi_bready      => s_axi_bready,
    s_axi_bresp       => s_axi_bresp,
    s_axi_bvalid      => s_axi_bvalid,
    s_axi_rdata       => s_axi_rdata,
    s_axi_rready      => s_axi_rready,
    s_axi_rresp       => s_axi_rresp,
    s_axi_rvalid      => s_axi_rvalid,
    s_axi_wdata       => s_axi_wdata,
    s_axi_wready      => s_axi_wready,
    s_axi_wstrb       => s_axi_wstrb,
    s_axi_wvalid      => s_axi_wvalid,

    -- Input Data Stream
    s_axis_tready     => skid_buffer_out_ready_s,
    s_axis_tvalid     => skid_buffer_out_valid_s,
    s_axis_tdata      => skid_buffer_out_data_s,
    s_axis_tkeep      => skid_buffer_out_keep_s,
    --s_axis_tfirst     => skid_buffer_out_first_s,
    s_axis_tlast      => skid_buffer_out_last_s,

    -- Output Data Stream
    m_axis_tready     => tkeep_handler_out_ready_s,
    m_axis_tvalid     => tkeep_handler_out_valid_s,
    m_axis_tdata      => tkeep_handler_out_data_s,
    m_axis_tkeep      => tkeep_handler_out_keep_s,
    --m_axis_tfirst     => tkeep_handler_out_first_s,
    m_axis_tlast      => tkeep_handler_out_last_s
  );

  --------------------------------------------------
  -- Toggle a ready signal to generate back pressure
  back_pressure_generator_u : back_pressure_generator
    generic map (
      VALID_RATIO_G => 0.39
    )
    port map (
      -- Clock
      clk           => clk_s,

      -- Control
      start_i       => arst_n_s,

      -- Output
      ready_o       => tkeep_handler_out_ready_s
    );

end behavioral;
