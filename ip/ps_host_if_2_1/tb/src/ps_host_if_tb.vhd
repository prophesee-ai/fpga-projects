library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;
use std.textio.all;

library work;
use work.ps_host_if_reg_bank_pkg.all;

------------------------------
-- PS Host IF IP Testbench
entity ps_host_if_tb is
  generic (
    AXIL_MASTER_PATTERN_FILE_G        : string                        := "axil_bfm_file.pat";
    IN_DATA_FILE_PATH_G               : string                        := "in_evt_file.evt";
    REF_DATA_FILE_PATH_G              : string                        := "ref_evt_file.evt";
    TIMEOUT_G                         : natural                       := 1000
  );
end entity ps_host_if_tb;

architecture behavioral of ps_host_if_tb is

  ---------------
  -- Constants --
  ---------------
  constant AXIL_ADDR_WIDTH_C  : integer := 32;
  constant AXIL_DATA_WIDTH_C  : integer := 32;
  constant CORE_CLK_FREQ_HZ_C : integer := 1330000;
  constant EXT_CLK_FREQ_HZ_C  : integer := 1000000;

  constant AXIL_ADDR_WIDTH_G  : positive := AXIL_ADDR_WIDTH_C;
  constant AXIL_DATA_WIDTH_G  : positive := AXIL_DATA_WIDTH_C;
  constant AXIS_TDATA_WIDTH_G : positive := 64;
  constant AXIS_TUSER_WIDTH_G : positive := 1;


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ----------------------------
  -- DUT
  component ps_host_if_0 is
  port (
    -- Clock and Reset
    aclk                  : in  std_logic;
    aresetn               : in  std_logic;

    -- Slave AXI4-Lite Interface for Registers Configuration
    s_axi_araddr          : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_arprot          : in  std_logic_vector(2 downto 0);
    s_axi_arready         : out std_logic;
    s_axi_arvalid         : in  std_logic;
    s_axi_awaddr          : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_awprot          : in  std_logic_vector(2 downto 0);
    s_axi_awready         : out std_logic;
    s_axi_awvalid         : in  std_logic;
    s_axi_bready          : in  std_logic;
    s_axi_bresp           : out std_logic_vector(1 downto 0);
    s_axi_bvalid          : out std_logic;
    s_axi_rdata           : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_rready          : in  std_logic;
    s_axi_rresp           : out std_logic_vector(1 downto 0);
    s_axi_rvalid          : out std_logic;
    s_axi_wdata           : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_wready          : out std_logic;
    s_axi_wstrb           : in  std_logic_vector(3 downto 0);
    s_axi_wvalid          : in  std_logic;

    -- Input Data Stream
    s_axis_tready         : out std_logic;
    s_axis_tvalid         : in  std_logic;
    s_axis_tdata          : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    s_axis_tkeep          : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    s_axis_tuser          : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    s_axis_tlast          : in  std_logic;

    -- Output Data Stream
    m_axis_tready         : in  std_logic;
    m_axis_tvalid         : out std_logic;
    m_axis_tdata          : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    m_axis_tkeep          : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    m_axis_tuser          : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    m_axis_tlast          : out std_logic
  );
  end component ps_host_if_0;

  ----------------------
  -- Clock and Reset BFM
  component clk_rst_bfm is
    generic (
      CORE_CLK_FREQ_HZ_G    : positive := 100e6 -- Default 100 MHz frequency
    );
    port (
      -- Core Clock and Reset
      core_clk_o            : out std_logic;
      core_arst_n_o         : out std_logic;
      core_srst_o           : out std_logic;

      -- MIPI TX HS Clock and Reset
      mipi_tx_hs_clk_o      : out std_logic;
      mipi_tx_hs_arst_n_o   : out std_logic;
      mipi_tx_hs_srst_o     : out std_logic;
      mipi_tx_hs_clk90_o    : out std_logic;

      -- MIPI RX DPHY Clock and Reset
      mipi_rx_dphy_clk_o    : out std_logic;
      mipi_rx_dphy_arst_n_o : out std_logic;
      mipi_rx_dphy_srst_o   : out std_logic
    );
  end component clk_rst_bfm;

  -----------------------
  -- AXI4-Lite Master BFM
  component axi_lite_master_bfm is
    generic (
      BUS_ADDR_WIDTH_G : positive := 32;
      BUS_DATA_WIDTH_G : positive := 32;
      PATTERN_FILE_G   : string   := "axil_bfm_file.pat";
      USE_TASK_CTL_G   : boolean  := false;
      WHOIAM_G         : string   := "ICN Master BFM"
    );
    port (
      -- Clock and Reset
      clk              : in  std_logic;
      rst              : in  std_logic;

      -- BFM Control Interface
      bfm_run_step_i   : in  std_logic;
      bfm_busy_o       : out std_logic;
      bfm_end_o        : out std_logic;

      -- AXI4-Lite Master Interface
      axil_m_araddr_o  : out std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
      axil_m_arprot_o  : out std_logic_vector(2 downto 0);
      axil_m_arready_i : in  std_logic;
      axil_m_arvalid_o : out std_logic;
      axil_m_rready_o  : out std_logic;
      axil_m_rresp_i   : in  std_logic_vector(1 downto 0);
      axil_m_rvalid_i  : in  std_logic;
      axil_m_bready_o  : out std_logic;
      axil_m_bresp_i   : in  std_logic_vector(1 downto 0);
      axil_m_bvalid_i  : in  std_logic;
      axil_m_rdata_i   : in  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
      axil_m_awaddr_o  : out std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
      axil_m_awprot_o  : out std_logic_vector(2 downto 0);
      axil_m_awready_i : in  std_logic;
      axil_m_awvalid_o : out std_logic;
      axil_m_wdata_o   : out std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
      axil_m_wready_i  : in  std_logic;
      axil_m_wstrb_o   : out std_logic_vector(3 downto 0);
      axil_m_wvalid_o  : out std_logic
    );
  end component axi_lite_master_bfm;

  ----------------------------
  -- AXI4 Stream TLAST checker
  component axi4s_tlast_checker is
    generic (
      DATA_WIDTH_G       : positive := 32;
      LITTLE_ENDIAN_G    : boolean  := false;
      TLAST_CHECK_EN_G   : boolean  := true;
      TKEEP_CHECK_EN_G   : boolean  := true
    );
    port (
      -- Clock and Reset
      clk                 : in std_logic;
      arst_n              : in std_logic;
      srst                : in std_logic;

      -- Configuration Inputs
      cfg_packet_length_i : in std_logic_vector(31 downto 0);

      -- AXI4-Stream Slave Interface
      in_ready_i          : in std_logic;
      in_valid_i          : in std_logic;
      in_last_i           : in std_logic;
      in_keep_i           : in std_logic_vector(((DATA_WIDTH_G+7)/8)-1 downto 0);
      in_data_i           : in std_logic_vector(DATA_WIDTH_G-1 downto 0)
    );
  end component axi4s_tlast_checker;


  ----------------------------------------------
  -- AXI4 write register catcher
  component axi_lite_reg_write_catcher is
    generic(
      BUS_ADDR_WIDTH_G             : positive := 32;
      BUS_DATA_WIDTH_G             : positive := 32;
      REG_ADDR_G                   : natural  := 0;
      REG_DEFAULT_VALUE_G          : natural  := 0
    );
    port(
      -- Clock, reset
      clk                          : in  std_logic;
      rst                          : in  std_logic;

      -- AXI4 Lite slave write interface
      axil_s_awready_i             : in  std_logic;
      axil_s_awvalid_i             : in  std_logic;
      axil_s_awaddr_i              : in  std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
      axil_s_wready_i              : in  std_logic;
      axil_s_wvalid_i              : in  std_logic;
      axil_s_wstrb_i               : in  std_logic_vector((BUS_DATA_WIDTH_G/8)-1 downto 0);
      axil_s_wdata_i               : in  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);

      -- Output register value
      out_valid_flag_o						 : out std_logic;
      out_value_o                  : out std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0)
    );
  end component axi_lite_reg_write_catcher;

  -----------------------------------------------------
 -- Reads an events stream from a file and replays it
 -- on its AXI4-Stream output port.
 -- Valid line toggles with the VALID_RATIO.
 component evt_replay is
   generic (
     READER_NAME    : string               := "Reader";
     PATTERN_FILE   : string               := "input_file.pat";
     VALID_RATIO    : real                 := 1.0;
     EVT_FORMAT     : integer range 0 to 3 := 1;
     MSG_EVT_NB_MOD : positive             := 100000;
     DATA_WIDTH     : positive             := 32;
     EN_TLAST       : boolean              := true
   );
   port (
     -- Clock
     clk     : in  std_logic;

     -- Control
     start_i : in  std_logic;
     end_o   : out std_logic;

     -- Stream
     ready_i : in  std_logic;
     valid_o : out std_logic;
     last_o  : out std_logic;
     data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
   );
 end component evt_replay;

 --------------------------------------------------
 -- Reads a reference events stream from a file and
 -- compares it with the stream on its AXI4-Stream
 -- input port.
 -- Ready line toggles with the READY_RATIO.
 component evt_record is
   generic (
     CHECKER_NAME        : string               := "Checker";
     DISPLAY_ITERATION_G : natural              := 1000;
     PATTERN_FILE        : string               := "ref_file.pat";
     READY_RATIO         : real                 := 1.0;
     EVT_FORMAT          : integer range 0 to 3 := 1;
     MSG_EVT_NB_MOD      : positive             := 100000;
     DATA_WIDTH          : positive             := 32
   );
   port (
     -- Clock
     clk     : in  std_logic;

     -- Control
     error_o : out std_logic;
     end_o   : out std_logic;

     -- Stream
     ready_o : out std_logic;
     valid_i : in  std_logic;
     mask_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '1');
     data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
   );
 end component evt_record;

  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Clock and Reset Signals
  signal core_clk_s                          : std_logic;
  signal core_arst_n_s                       : std_logic;
  signal core_srst_s                         : std_logic;
  signal ext_clk_s                           : std_logic;
  signal ext_arst_n_s                        : std_logic;
  signal ext_srst_s                          : std_logic;

  -- AXI-Lite Master BFM Signals for Synchronization with the Testbench
  signal axil_master_bfm_busy_s              : std_logic;
  signal axil_master_bfm_run_step_s          : std_logic;
  signal axil_master_bfm_end_s               : std_logic;

  -- Master AXI Lite interface for registers configuration
  signal axil_m_araddr_s                     : std_logic_vector(AXIL_ADDR_WIDTH_C-1 downto 0);
  signal axil_m_arprot_s                     : std_logic_vector(2 downto 0);
  signal axil_m_arready_s                    : std_logic;
  signal axil_m_arvalid_s                    : std_logic;
  signal axil_m_awaddr_s                     : std_logic_vector(AXIL_ADDR_WIDTH_C-1 downto 0);
  signal axil_m_awprot_s                     : std_logic_vector(2 downto 0);
  signal axil_m_awready_s                    : std_logic;
  signal axil_m_awvalid_s                    : std_logic;
  signal axil_m_bready_s                     : std_logic;
  signal axil_m_bresp_s                      : std_logic_vector(1 downto 0);
  signal axil_m_bvalid_s                     : std_logic;
  signal axil_m_rdata_s                      : std_logic_vector(AXIL_DATA_WIDTH_C-1 downto 0);
  signal axil_m_rready_s                     : std_logic;
  signal axil_m_rresp_s                      : std_logic_vector(1 downto 0);
  signal axil_m_rvalid_s                     : std_logic;
  signal axil_m_wdata_s                      : std_logic_vector(AXIL_DATA_WIDTH_C-1 downto 0);
  signal axil_m_wready_s                     : std_logic;
  signal axil_m_wstrb_s                      : std_logic_vector(3 downto 0);
  signal axil_m_wvalid_s                     : std_logic;

  --
  signal in_ready_s                         : std_logic;
  signal in_valid_s                         : std_logic;
  signal in_last_s                          : std_logic;
  signal in_keep_s                          : std_logic_vector(7 DOWNTO 0);
  signal in_data_s                          : std_logic_vector(63 DOWNTO 0);
  signal dma_axis_m_tready_s                : std_logic;
  signal dma_axis_m_tvalid_s                : std_logic;
  signal dma_axis_m_tlast_s                 : std_logic;
  signal dma_axis_m_tkeep_s                 : std_logic_vector(7 DOWNTO 0);
  signal dma_axis_m_tdata_s                 : std_logic_vector(63 DOWNTO 0);

  --
  signal cfg_packet_length_s                : std_logic_vector(31 DOWNTO 0);

  --
  signal checker_process_s                   : std_logic_vector(1 downto 0) := (others => '0');
  signal start_replay_s                      : std_logic := '0';
  signal timeout                             : integer := 0;

  constant CHECKERS_END_C                    : std_logic_vector(checker_process_s'LEFT downto 0) := (others => '1');

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  in_keep_s <= x"FF";

  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------

  ----------------------
  -- Clock and Reset BFM
  clk_rst_bfm_u : clk_rst_bfm
  generic map (
    CORE_CLK_FREQ_HZ_G    => CORE_CLK_FREQ_HZ_C
  )
  port map (
    -- Core Clock and Reset
    core_clk_o            => core_clk_s,
    core_arst_n_o         => core_arst_n_s,
    core_srst_o           => core_srst_s
  );

  clk_rst_ext_u : clk_rst_bfm
  generic map (
    CORE_CLK_FREQ_HZ_G    => EXT_CLK_FREQ_HZ_C
  )
  port map (
    -- Core Clock and Reset
    core_clk_o            => ext_clk_s,
    core_arst_n_o         => ext_arst_n_s,
    core_srst_o           => ext_srst_s
  );

  -----------------------
  -- AXI4-Lite Master BFM
  axil_master_bfm_u : axi_lite_master_bfm
  generic map (
    BUS_ADDR_WIDTH_G => AXIL_ADDR_WIDTH_C,
    BUS_DATA_WIDTH_G => AXIL_DATA_WIDTH_C,
    PATTERN_FILE_G   => AXIL_MASTER_PATTERN_FILE_G,
    USE_TASK_CTL_G   => true
  )
  port map (
    -- Clock and Reset
    clk              => core_clk_s,
    rst              => core_srst_s,

    -- BFM Control Interface
    bfm_run_step_i   => axil_master_bfm_run_step_s,
    bfm_busy_o       => axil_master_bfm_busy_s,
    bfm_end_o        => axil_master_bfm_end_s,

    -- AXI4-Lite Master Interface
    axil_m_araddr_o  => axil_m_araddr_s,
    axil_m_arprot_o  => axil_m_arprot_s,
    axil_m_arready_i => axil_m_arready_s,
    axil_m_arvalid_o => axil_m_arvalid_s,
    axil_m_awaddr_o  => axil_m_awaddr_s,
    axil_m_awprot_o  => axil_m_awprot_s,
    axil_m_awready_i => axil_m_awready_s,
    axil_m_awvalid_o => axil_m_awvalid_s,
    axil_m_bready_o  => axil_m_bready_s,
    axil_m_bresp_i   => axil_m_bresp_s,
    axil_m_bvalid_i  => axil_m_bvalid_s,
    axil_m_rdata_i   => axil_m_rdata_s,
    axil_m_rready_o  => axil_m_rready_s,
    axil_m_rresp_i   => axil_m_rresp_s,
    axil_m_rvalid_i  => axil_m_rvalid_s,
    axil_m_wdata_o   => axil_m_wdata_s,
    axil_m_wready_i  => axil_m_wready_s,
    axil_m_wstrb_o   => axil_m_wstrb_s,
    axil_m_wvalid_o  => axil_m_wvalid_s
  );

  -----------------------------------------------------
  -- Reads an events stream from a file and replays it
  -- on its AXI4-Stream output port.
  -- Valid line toggles with the VALID_RATIO.
  evt_replay_u : evt_replay
  generic map (
    PATTERN_FILE => IN_DATA_FILE_PATH_G,
    EVT_FORMAT   => 0,
    DATA_WIDTH   => 64

  )
  port map (
    -- Clock
    clk     => core_clk_s,

    -- Control
    start_i => start_replay_s,
    end_o   => checker_process_s(0),

    -- Stream
    ready_i => in_ready_s,
    valid_o => in_valid_s,
    last_o  => in_last_s ,
    data_o  => in_data_s
  );


  -------------------------------------------
  dut_ps_host_if_ip_u : ps_host_if_0
  port map (
    aclk          => core_clk_s,
    aresetn       => core_arst_n_s,

    s_axi_araddr  => axil_m_araddr_s,
    s_axi_arprot  => axil_m_arprot_s,
    s_axi_arready => axil_m_arready_s,
    s_axi_arvalid => axil_m_arvalid_s,
    s_axi_awaddr  => axil_m_awaddr_s,
    s_axi_awprot  => axil_m_awprot_s,
    s_axi_awready => axil_m_awready_s,
    s_axi_awvalid => axil_m_awvalid_s,
    s_axi_bready  => axil_m_bready_s,
    s_axi_bresp   => axil_m_bresp_s,
    s_axi_bvalid  => axil_m_bvalid_s,
    s_axi_rdata   => axil_m_rdata_s,
    s_axi_rready  => axil_m_rready_s,
    s_axi_rresp   => axil_m_rresp_s,
    s_axi_rvalid  => axil_m_rvalid_s,
    s_axi_wdata   => axil_m_wdata_s,
    s_axi_wready  => axil_m_wready_s,
    s_axi_wstrb   => axil_m_wstrb_s,
    s_axi_wvalid  => axil_m_wvalid_s,

    s_axis_tready => in_ready_s,
    s_axis_tvalid => in_valid_s,
    s_axis_tdata  => in_data_s,
    s_axis_tkeep  => in_keep_s,
    s_axis_tuser  => (others => '0'),
    s_axis_tlast  => in_last_s,

    m_axis_tready => dma_axis_m_tready_s,
    m_axis_tvalid => dma_axis_m_tvalid_s,
    m_axis_tdata  => dma_axis_m_tdata_s,
    m_axis_tkeep  => dma_axis_m_tkeep_s,
    m_axis_tuser  => open,
    m_axis_tlast  => dma_axis_m_tlast_s
  );

  --------------------------------------------------
  -- Reads a reference events stream from a file and
  -- compares it with the stream on its AXI4-Stream
  -- input port.
  -- Ready line toggles with the READY_RATIO.
  evt_record_u : evt_record
  generic map(
    PATTERN_FILE        => REF_DATA_FILE_PATH_G,
    EVT_FORMAT          => 0,
    DATA_WIDTH          => 64
  )
  port map(
    -- Clock
    clk     => ext_clk_s,

    -- Control
    error_o => open,
    end_o   => checker_process_s(1),

    -- Stream
    ready_o => dma_axis_m_tready_s,
    valid_i => dma_axis_m_tvalid_s,
    mask_i  => (others => '1'),
    data_i  => dma_axis_m_tdata_s
  );

  ----------------------------------------------
  axi4s_tlast_checker_u : axi4s_tlast_checker
  generic map(
    DATA_WIDTH_G      => 64,
    LITTLE_ENDIAN_G   => false,
    TLAST_CHECK_EN_G  => true,
    TKEEP_CHECK_EN_G  => false
  )
  port map(
    -- Clock and Reset
    clk                 => ext_clk_s,
    arst_n              => ext_arst_n_s,
    srst                => ext_srst_s,

    -- Configuration Inputs
    cfg_packet_length_i => cfg_packet_length_s,

    -- AXI4-Stream Slave Interface
    in_ready_i          =>  dma_axis_m_tready_s,
    in_valid_i          =>  dma_axis_m_tvalid_s,
    in_last_i           =>  dma_axis_m_tlast_s ,
    in_keep_i           =>  dma_axis_m_tkeep_s ,
    in_data_i           =>  dma_axis_m_tdata_s
  );

  axi4s_tlast_reg_catcher_u: axi_lite_reg_write_catcher
  generic map(
      BUS_ADDR_WIDTH_G             => 32,
      BUS_DATA_WIDTH_G             => PACKET_LENGTH_VALUE_WIDTH,
      REG_ADDR_G                   => to_integer(unsigned(PACKET_LENGTH_ADDR)),
      REG_DEFAULT_VALUE_G          => to_integer(unsigned(PACKET_LENGTH_VALUE_DEFAULT))
  )
  port map(
  -- Clock, reset
    clk                          => core_clk_s,
    rst                          => core_srst_s,

    -- AXI4 Lite slave write interface
    axil_s_awready_i             => axil_m_awready_s,
    axil_s_awvalid_i             => axil_m_awvalid_s,
    axil_s_awaddr_i              => axil_m_awaddr_s,
    axil_s_wready_i              => axil_m_wready_s,
    axil_s_wvalid_i              => axil_m_wvalid_s,
    axil_s_wstrb_i               => axil_m_wstrb_s,
    axil_s_wdata_i               => axil_m_wdata_s,

    -- Output register value
    out_valid_flag_o		     => open,
    out_value_o                  => cfg_packet_length_s
  );



  ---------------
  -- Test Process
  test_process : process
  begin
    axil_master_bfm_run_step_s        <= '0';
    start_replay_s <= '0';

    -- Wait for a couple of clock cycles after the reset has been de-asserted
    wait until falling_edge(core_srst_s);
    wait until rising_edge(core_clk_s);
    wait until rising_edge(core_clk_s);

    -- BFM Task Controller Send Config
    axil_master_bfm_run_step_s        <= '1';
    wait until (axil_master_bfm_busy_s = '1');
    axil_master_bfm_run_step_s        <= '0';

    -- BFM Task config done
    wait until (axil_master_bfm_busy_s = '0');

    -- BFM Task Controller End config
    axil_master_bfm_run_step_s        <= '1';
    wait until (axil_master_bfm_busy_s = '1');
    axil_master_bfm_run_step_s        <= '0';

    -- Start sending data
    start_replay_s <= '1';

    -- While the Replay and Record blocks have not reached the respective end of file
    while ((axil_master_bfm_end_s = '0' or checker_process_s /= CHECKERS_END_C) and (timeout < TIMEOUT_G)) loop
      wait until rising_edge(core_clk_s);
      timeout <= timeout + 1;
    end loop;

    -- If both the Replay and Record blocks have reached the end of the test and
    -- no error was found, report the test as success, then exit
    if (timeout >= TIMEOUT_G) then
      assert false report "Timeout Error during simulation" severity failure;
    else
      report string'("End of Test with Success");
    end if;
    finish(1);

  end process test_process;

  ------------
  -- Checkers



end behavioral;
