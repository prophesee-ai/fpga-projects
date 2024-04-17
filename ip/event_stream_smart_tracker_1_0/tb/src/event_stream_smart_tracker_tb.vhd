-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.env.all;
use std.textio.all;

library work;

------------------------------
-- ESST IP Testbench
entity event_stream_smart_tracker_tb is
  generic (
    AXIL_MASTER_PATTERN_FILE_G        : string                        := "axil_bfm_file.pat";
    IN_DATA_FILE_PATH_G               : string                        := "in_evt_file.evt";
    REF_DATA_FILE_PATH_G              : string                        := "ref_evt_file.evt";
    TIMEOUT_G                         : natural                       := 1000;
    START_DATA_IN_TASK_G              : natural                       := 1;
    BACK_PRESSURE_SIM_G               : boolean                       := false
  );
end entity event_stream_smart_tracker_tb;

architecture behavioral of event_stream_smart_tracker_tb is

  ---------------
  -- Constants --
  ---------------
  constant AXIL_ADDR_WIDTH_C  : integer := 32;
  constant AXIL_DATA_WIDTH_C  : integer := 32;
  constant CORE_CLK_FREQ_HZ_C : integer := 1330000;
  constant EXT_CLK_FREQ_HZ_C  : integer := 1000000;
  

  ----------------------------
  -- Component Declarations --
  ----------------------------
  
  
  ----------------------------
  -- DUT
  COMPONENT event_stream_smart_tracker_0
    PORT (
      clk : IN STD_LOGIC;
      arst_n : IN STD_LOGIC;
      srst : IN STD_LOGIC;
      in_ready_o : OUT STD_LOGIC;
      in_valid_i : IN STD_LOGIC;
      in_last_i : IN STD_LOGIC;
      in_data_i : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      in_tkeep_i : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      in_tuser_i : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      out_ready_i : IN STD_LOGIC;
      out_valid_o : OUT STD_LOGIC;
      out_last_o : OUT STD_LOGIC;
      out_data_o : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      out_tkeep_o : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      out_tuser_o : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      axil_s_awaddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      axil_s_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      axil_s_awvalid : IN STD_LOGIC;
      axil_s_awready : OUT STD_LOGIC;
      axil_s_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      axil_s_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      axil_s_wvalid : IN STD_LOGIC;
      axil_s_wready : OUT STD_LOGIC;
      axil_s_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axil_s_bvalid : OUT STD_LOGIC;
      axil_s_bready : IN STD_LOGIC;
      axil_s_araddr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      axil_s_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      axil_s_arvalid : IN STD_LOGIC;
      axil_s_arready : OUT STD_LOGIC;
      axil_s_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      axil_s_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      axil_s_rvalid : OUT STD_LOGIC;
      axil_s_rready : IN STD_LOGIC 
    );
  END COMPONENT;

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
 
  --------------------------------------------------
  -- AXI4-Stream Pipeline Stage with enable control
  component axi4s_pipeline_stage_ena is
    generic (
      PIPELINE_STAGES_G : positive := 2;
      DATA_WIDTH_G      : positive := 32
    );
    port (
      clk               : in  std_logic;
      rst               : in  std_logic;
  
      -- Control enable
      cfg_enable_i      : in std_logic;
  
      -- Input interface
      in_ready_o        : out std_logic;
      in_valid_i        : in  std_logic;
      in_first_i        : in  std_logic;
      in_last_i         : in  std_logic;
      in_data_i         : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);
  
      -- Output interface
      out_ready_i       : in  std_logic;
      out_valid_o       : out std_logic;
      out_first_o       : out std_logic;
      out_last_o        : out std_logic;
      out_data_o        : out std_logic_vector(DATA_WIDTH_G-1 downto 0)
    );
  end component axi4s_pipeline_stage_ena;
  
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
  
  -------------------------
  -- Constants Declarations --
  -------------------------
  constant BP_EN_ADDR_C : std_logic_vector(31 downto 0) := x"10000000";
  -------------------------
  -- Signals Declarations --
  -------------------------

  -- Clock and Reset Signals
  signal core_clk_s                          : std_logic;
  signal core_arst_n_s                       : std_logic;
  signal core_srst_s                         : std_logic;

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
  signal in_data_s                          : std_logic_vector(63 DOWNTO 0);
  signal out_ready_s                        : std_logic;
  signal out_valid_s                        : std_logic;
  signal out_data_s                         : std_logic_vector(63 DOWNTO 0) := (others => '0');
  
  signal esst_out_ready_s                        : std_logic;
  signal esst_out_valid_s                        : std_logic;
  signal esst_out_data_s                         : std_logic_vector(63 DOWNTO 0) := (others => '0');
    
  --
  signal checker_process_s                   : std_logic_vector(1 downto 0) := (others => '0');
  signal start_replay_s                      : std_logic := '0';
  signal evt_record_err                      : std_logic := '0';
  signal timeout                             : integer := 0;
  signal back_pressure_en_s                  : std_logic_vector(AXIL_DATA_WIDTH_C-1 downto 0) := (others => '0');
  signal bfm_tasks_s                         : natural := 0;
  
  constant CHECKERS_END_C                    : std_logic_vector(checker_process_s'LEFT downto 0) := (others => '1');

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

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
    DATA_WIDTH   => 64, -- first bit is data(64) and last bit is data(65) and 64 bits for data
    EN_TLAST     => false
    
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
    last_o  => open ,
    data_o  => in_data_s
  );
  
  -------------------------------------------
  dut_event_stream_smart_tracker_ip_u : event_stream_smart_tracker_0
  port map (    
    clk                 => core_clk_s,
    arst_n              => core_arst_n_s,
    srst                => core_srst_s,
    
    in_ready_o          => in_ready_s,
    in_valid_i          => in_valid_s,
    in_last_i           => '0',
    in_data_i           => in_data_s,
    in_tkeep_i          => x"5A",
    in_tuser_i          => (others => '0'),
    
    out_ready_i         => esst_out_ready_s,
    out_valid_o         => esst_out_valid_s,
    out_last_o          => open,
    out_data_o          => esst_out_data_s,
    out_tkeep_o         => open,
    out_tuser_o         => open,
    
    axil_s_araddr       => axil_m_araddr_s    ,
    axil_s_arprot       => axil_m_arprot_s    ,
    axil_s_arready      => axil_m_arready_s   ,
    axil_s_arvalid      => axil_m_arvalid_s   ,
    axil_s_awaddr       => axil_m_awaddr_s    ,
    axil_s_awprot       => axil_m_awprot_s    ,
    axil_s_awready      => axil_m_awready_s   ,
    axil_s_awvalid      => axil_m_awvalid_s   ,
    axil_s_bready       => axil_m_bready_s    ,
    axil_s_bresp        => axil_m_bresp_s     ,
    axil_s_bvalid       => axil_m_bvalid_s    ,
    axil_s_rdata        => axil_m_rdata_s     ,
    axil_s_rready       => axil_m_rready_s    ,
    axil_s_rresp        => axil_m_rresp_s     ,
    axil_s_rvalid       => axil_m_rvalid_s    ,
    axil_s_wdata        => axil_m_wdata_s     ,
    axil_s_wready       => axil_m_wready_s    ,
    axil_s_wstrb        => axil_m_wstrb_s     ,
    axil_s_wvalid       => axil_m_wvalid_s      
  );
  
  --------------------------------------------------
  -- Back Pressure simulation
  back_pressure_gen: if(BACK_PRESSURE_SIM_G) generate
    axi4s_pipeline_u: axi4s_pipeline_stage_ena
    generic map(
      PIPELINE_STAGES_G => 2,
      DATA_WIDTH_G => 64
    )
    port map(
      clk               => core_clk_s,
      rst               => core_srst_s,

      -- Control enable
      cfg_enable_i      => back_pressure_en_s(0),

      -- Input interface
      in_ready_o        => esst_out_ready_s,
      in_valid_i        => esst_out_valid_s,
      in_first_i        => '0',
      in_last_i         => '0',
      in_data_i         => esst_out_data_s,

      -- Output interface
      out_ready_i       => out_ready_s,
      out_valid_o       => out_valid_s,
      out_first_o       => open,
      out_last_o        => open,
      out_data_o        => out_data_s
    );  
    
  axi_lite_reg_write_catcher_u: axi_lite_reg_write_catcher
    generic map(
      REG_ADDR_G             => to_integer(unsigned(BP_EN_ADDR_C)),
      REG_DEFAULT_VALUE_G    => 0
    )
    port map(
      clk => core_clk_s,
      rst => core_srst_s,
      
      axil_s_awready_i => axil_m_awready_s,
      axil_s_awvalid_i => axil_m_awvalid_s,
      axil_s_awaddr_i  => axil_m_awaddr_s,
      axil_s_wready_i  => axil_m_wready_s,
      axil_s_wvalid_i  => axil_m_wvalid_s,
      axil_s_wstrb_i   => axil_m_wstrb_s,
      axil_s_wdata_i   => axil_m_wdata_s,
      
      out_value_o => back_pressure_en_s,
      out_valid_flag_o => open
    );
  end generate back_pressure_gen;
  
  back_pressure_not_gen: if(not BACK_PRESSURE_SIM_G) generate
    esst_out_ready_s <= out_ready_s;
    out_valid_s <= esst_out_valid_s;
    out_data_s <= esst_out_data_s;
  end generate back_pressure_not_gen; 
  
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
    clk     => core_clk_s,
  
    -- Control
    error_o => evt_record_err,
    end_o   => checker_process_s(1),
  
    -- Stream
    ready_o => out_ready_s,
    valid_i => out_valid_s,
    mask_i  => (others => '1'),
    data_i  => out_data_s
  );
  ---------------
  -- Test Process
  test_process : process
  begin
    axil_master_bfm_run_step_s        <= '0';
    bfm_tasks_s    <= 0;
    
    -- Wait for a couple of clock cycles after the reset has been de-asserted
    wait until falling_edge(core_srst_s);
    wait until rising_edge(core_clk_s);
    wait until rising_edge(core_clk_s);
    
    -- BFM tasks
    while(axil_master_bfm_end_s = '0') loop
    
        -- Send new Task
        while (axil_master_bfm_busy_s = '0' and axil_master_bfm_end_s = '0') loop
            wait until rising_edge(core_clk_s); 
            axil_master_bfm_run_step_s <= '1'; 
        end loop;
        axil_master_bfm_run_step_s        <= '0';
        
        ---- BFM Task Done wait for Busy goes down
        while (axil_master_bfm_busy_s = '1') loop
          wait until rising_edge(core_clk_s);
        end loop;
        
        bfm_tasks_s <= bfm_tasks_s + 1;

    end loop;
    
    -- While the Replay and Record blocks have not reached the respective end of file
    while (checker_process_s /= CHECKERS_END_C) loop
      wait until rising_edge(core_clk_s);
    end loop;

    -- no error was found, report the test as success, then exit
    report string'("End of Test with Success");

    finish(1);

  end process test_process;
  
  --------------
  -- Start Stream process
  start_stream_process : process
  begin
    start_replay_s <= '0';
    while (bfm_tasks_s < START_DATA_IN_TASK_G) loop
      wait until rising_edge(core_clk_s);
    end loop;
    start_replay_s <= '1';
    wait;
  end process start_stream_process;
  
  --------------
  -- Timeout process
  timeout_process : process
  begin
    while (timeout < TIMEOUT_G) loop
      wait until rising_edge(core_clk_s);
      timeout <= timeout + 1;    
    end loop;
    assert false report "Timeout Error during simulation" severity failure;
    finish(1);
  end process timeout_process;
  
  
  --------------
  -- Errors process
  record_error_process : process
  begin
    wait until (evt_record_err = '1');
    assert false report "Data recording error during simulation" severity failure;
    finish(1);
  end process record_error_process;  
  
  
  ------------
  -- Checkers 
  
 

end behavioral;
