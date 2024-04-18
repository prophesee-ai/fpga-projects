-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;

entity mipi_tx_sim_bfm is
  generic(
    EVT_FORMAT_G                      : integer                      := 0; -- RAW (2.1)   
    AXIL_MASTER_PATTERN_FILE_G        : string                       := "axil_bfm_file.pat";
    IN_DATA_FILE_PATH_G               : string                       := "in_evt_file.evt";
    BUS_ADDR_WIDTH_G                  : positive                     := 32;
    BUS_DATA_WIDTH_G                  : positive                     := 32 
  );  
  port (
    -- Clock and Reset
    clk                  : in  std_logic;
    arst_n               : in  std_logic := '1';
    srst                 : in  std_logic := '0';
    hs_clk               : in  std_logic; -- HS Clock
    hs_arst_n            : in  std_logic;
    hs_srst              : in  std_logic;
    
    -- BFM MIPI TX Configuration and Synchronization I/F
    bfm_mipi_tx_enable_i : in  std_logic;
    bfm_mipi_tx_eof_o    : out std_logic;
    
    -- Synchronization Of Sequencer
    bfm_mipi_tx_sync_request_i : in  std_logic;
    bfm_mipi_tx_sync_ack_o     : out std_logic;
    
    -- BFM Control Interface
    bfm_axil_run_step_i  : in  std_logic;
    bfm_axil_busy_o      : out std_logic;
    bfm_axil_end_o       : out std_logic;   
    
    -- MIPI CSI2 TX Interface
    mipi_tx_hs_clk_o     : out std_logic_vector(1 downto 0);   -- (P => 1, N => 0)
    mipi_tx_hs_d1_o      : out std_logic_vector(1 downto 0);   -- (P => 1, N => 0)
    mipi_tx_hs_d0_o      : out std_logic_vector(1 downto 0);   -- (P => 1, N => 0)
    mipi_tx_lp_clk_o     : out std_logic_vector(1 downto 0);   -- (P => 1, N => 0)
    mipi_tx_lp_d1_o      : out std_logic_vector(1 downto 0);   -- (P => 1, N => 0)
    mipi_tx_lp_d0_o      : out std_logic_vector(1 downto 0)    -- (P => 1, N => 0) 
  );
end mipi_tx_sim_bfm;

architecture sim of mipi_tx_sim_bfm is

  ---------------------------
  -- Constant Declarations --
  ---------------------------
  constant CORE_CLK_FREQ_C                : natural                      := 100000000;
  constant ENABLE_DEBUG_C                 : boolean                      := false;
  constant EVT_TIME_HIGH_SYNC_PERIOD_US_C : positive                     := 16;
  constant EVT_TIME_BASE_WIDTH_C          : positive                     := CCAM_EVT_TIME_BITS;
  constant FILTER_TYPES_C                 : boolean                      := false;
  constant FILTER_SUBTYPES_C              : boolean                      := false;
  constant FILTER_TRIGGER_IDS_C           : boolean                      := false;
  constant MIPI_HS_CLK_FREQ_HZ_C          : positive                     := 800000000;
  constant MIPI_LANES_C                   : positive                     := 2;                               -- Number of MIPI Lanes.
  constant MIPI_TX_BFM_INSERT_EOT_C       : boolean                      := false;
  constant MSB_FIRST_C                    : boolean                      := false;
  constant NEEDED_TYPES_C                 : ccam_evt_type_vector_t       := (-1 downto 0 => (others => '0'));
  constant NEEDED_SUBTYPES_C              : ccam_evt_subtype_vector_t    := (-1 downto 0 => (others => '0'));
  constant NEEDED_V3_TYPES_C              : ccam_evt_v3_type_vector_t    := (-1 downto 0 => (others => '0'));
  constant NEEDED_V3_SUBTYPES_C           : ccam_evt_v3_subtype_vector_t := (-1 downto 0 => (others => '0'));
  constant NEEDED_TRIGGER_IDS_C           : natural_vector_t             := (-1 downto 0 => 0);
  constant DATA_WIDTH_C                   : positive                     := iff(EVT_FORMAT_G=0, 64, iff(EVT_FORMAT_G=2, 32, 16));

  ----------------------------
  -- Component Declarations --
  ----------------------------
  
  ---------------------
  -- MIPI TX 2-lane BFM
  component mipi_tx_2l_bfm is
  generic (
    BUS_BASE_ADDR_G                : natural                      := 0;
    BUS_ADDR_WIDTH_G               : positive                     := 32;
    BUS_DATA_WIDTH_G               : positive                     := 32;
    CLK_FREQ_HZ_G                  : positive                     := 100000000;
    EVT_FORMAT_G                   : integer                      := 2;                               -- 0: raw; 2: evt2.0; 3: evt3.0
    EVT_TIME_HIGH_SYNC_PERIOD_US_G : integer                      := 128;
    EVT30_SUPPORT_G                : boolean                      := true;
    FILE_PATH_G                    : string                       := "file.dat";
    FILTER_TYPES_G                 : boolean                      := true;
    FILTER_SUBTYPES_G              : boolean                      := false;
    FILTER_TRIGGER_IDS_G           : boolean                      := false;
    INSERT_EOT_G                   : boolean                      := false;                           -- Insert end of task event
    MIPI_HS_CLK_FREQ_HZ_G          : positive                     := 800000000;
    MIPI_LANES_G                   : positive                     := 2;                               -- Number of MIPI Lanes.
    NEEDED_TYPES_G                 : ccam_evt_type_vector_t       := (-1 downto 0 => (others => '0'));
    NEEDED_SUBTYPES_G              : ccam_evt_subtype_vector_t    := (-1 downto 0 => (others => '0'));
    NEEDED_V3_TYPES_G              : ccam_evt_v3_type_vector_t    := (-1 downto 0 => (others => '0'));
    NEEDED_V3_SUBTYPES_G           : ccam_evt_v3_subtype_vector_t := (-1 downto 0 => (others => '0'));
    NEEDED_TRIGGER_IDS_G           : natural_vector_t             := (-1 downto 0 => 0);
    RAW_MODE_SUPPORT_G             : boolean                      := true;
    USE_LANE_MIXER_G               : boolean                      := true;
    USE_TIME_BASE_INPUT_G          : boolean                      := false;
    WHOIAM_G                       : string                       := "MIPI TX BFM";
    FPGA_FAMILY_G                  : string                       := "ULTRASCALE_PLUS"                -- "7SERIES", "ULTRASCALE_PLUS"
  );
  port (
    -- Clock and Reset
    clk                  : in  std_logic;
    arst_n               : in  std_logic := '1';
    srst                 : in  std_logic := '0';
    hs_clk               : in  std_logic; -- HS Clock
    hs_arst_n            : in  std_logic;
    hs_srst              : in  std_logic;

    -- BFM Configuration and Synchronization I/F
    bfm_enable_i         : in  std_logic;
    bfm_eof_o            : out std_logic;

    -- Event Time Base (us)
    evt_time_base_i      : in  ccam_evt_time_data_t;
    evt_time_high_sync_i : in  std_logic;

    -- Synchronization Of Sequencer
    sync_request_i       : in  std_logic;
    sync_ack_o           : out std_logic;

    -- MIPI RX Flow CONTROL
    mipi_rx_ready_i      : in  std_logic;

    -- MIPI CSI2 TX Interface
    mipi_tx_hs_clk_o     : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)
    mipi_tx_hs_d1_o      : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)
    mipi_tx_hs_d0_o      : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)
    mipi_tx_lp_clk_o     : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)
    mipi_tx_lp_d1_o      : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)
    mipi_tx_lp_d0_o      : out std_logic_vector(1 downto 0);                        -- (P => 1, N => 0)

    -- MIPI CSI2 TX Interface for Verification
    mipi_tx_if_clk_o     : out std_logic;
    mipi_tx_if_rst_o     : out std_logic;
    mipi_tx_if_valid_o   : out std_logic;
    mipi_tx_if_data_o    : out std_logic_vector((8*MIPI_LANES_G)-1 downto 0);

    -- AXI LITE port in/out signals
    s_axi_aclk           : in   std_logic;
    s_axi_aresetn        : in   std_logic;
    s_axi_awaddr         : in   std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    s_axi_awprot         : in   std_logic_vector(2 downto 0);
    s_axi_awvalid        : in   std_logic;
    s_axi_awready        : out  std_logic;
    s_axi_wdata          : in   std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    s_axi_wstrb          : in   std_logic_vector((BUS_DATA_WIDTH_G/8)-1 downto 0);
    s_axi_wvalid         : in   std_logic;
    s_axi_wready         : out  std_logic;
    s_axi_bresp          : out  std_logic_vector(1 downto 0);
    s_axi_bvalid         : out  std_logic;
    s_axi_bready         : in   std_logic;
    s_axi_araddr         : in   std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    s_axi_arprot         : in   std_logic_vector(2 downto 0);
    s_axi_arvalid        : in   std_logic;
    s_axi_arready        : out  std_logic;
    s_axi_rdata          : out  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
    s_axi_rresp          : out  std_logic_vector(1 downto 0);
    s_axi_rvalid         : out  std_logic;
    s_axi_rready         : in   std_logic
  );
  end component mipi_tx_2l_bfm;
  
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
  
  -------------------------
  -- Signal Declarations --
  -------------------------
  
  -- Master AXI Lite interface for registers configuration
  signal axil_m_araddr_s                     : std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
  signal axil_m_arprot_s                     : std_logic_vector(2 downto 0);
  signal axil_m_arready_s                    : std_logic;
  signal axil_m_arvalid_s                    : std_logic;
  signal axil_m_awaddr_s                     : std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
  signal axil_m_awprot_s                     : std_logic_vector(2 downto 0);
  signal axil_m_awready_s                    : std_logic;
  signal axil_m_awvalid_s                    : std_logic;
  signal axil_m_bready_s                     : std_logic;
  signal axil_m_bresp_s                      : std_logic_vector(1 downto 0);
  signal axil_m_bvalid_s                     : std_logic;
  signal axil_m_rdata_s                      : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
  signal axil_m_rready_s                     : std_logic;
  signal axil_m_rresp_s                      : std_logic_vector(1 downto 0);
  signal axil_m_rvalid_s                     : std_logic;
  signal axil_m_wdata_s                      : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
  signal axil_m_wready_s                     : std_logic;
  signal axil_m_wstrb_s                      : std_logic_vector(3 downto 0);
  signal axil_m_wvalid_s                     : std_logic;
  
begin

  -----------------------
  -- AXI4-Lite Master BFM
  axil_master_bfm_u : axi_lite_master_bfm
  generic map (
    BUS_ADDR_WIDTH_G => BUS_ADDR_WIDTH_G,
    BUS_DATA_WIDTH_G => BUS_DATA_WIDTH_G,
    PATTERN_FILE_G   => AXIL_MASTER_PATTERN_FILE_G,
    USE_TASK_CTL_G   => true
  )
  port map (
    -- Clock and Reset
    clk              => clk,
    rst              => srst,

    -- BFM Control Interface
    bfm_run_step_i   => bfm_axil_run_step_i,
    bfm_busy_o       => bfm_axil_busy_o,
    bfm_end_o        => bfm_axil_end_o,

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
  
  ---------------------
  -- MIPI TX 2-lane BFM
  mipi_tx_2l_bfm_u: mipi_tx_2l_bfm
  generic map(
    BUS_ADDR_WIDTH_G               => 32,
    BUS_DATA_WIDTH_G               => 32,
    CLK_FREQ_HZ_G                  => CORE_CLK_FREQ_C,
    EVT_FORMAT_G                   => EVT_FORMAT_G,
    EVT_TIME_HIGH_SYNC_PERIOD_US_G => EVT_TIME_HIGH_SYNC_PERIOD_US_C,
    FILTER_TYPES_G                 => FILTER_TYPES_C,
    FILTER_SUBTYPES_G              => FILTER_SUBTYPES_C,
    FILTER_TRIGGER_IDS_G           => FILTER_TRIGGER_IDS_C,
    INSERT_EOT_G                   => MIPI_TX_BFM_INSERT_EOT_C,   -- Insert end of task event
    MIPI_HS_CLK_FREQ_HZ_G          => MIPI_HS_CLK_FREQ_HZ_C,
    MIPI_LANES_G                   => MIPI_LANES_C,
    NEEDED_TYPES_G                 => NEEDED_TYPES_C,
    NEEDED_SUBTYPES_G              => NEEDED_SUBTYPES_C,
    NEEDED_V3_TYPES_G              => NEEDED_V3_TYPES_C,
    NEEDED_V3_SUBTYPES_G           => NEEDED_V3_SUBTYPES_C,
    NEEDED_TRIGGER_IDS_G           => NEEDED_TRIGGER_IDS_C,  
    USE_TIME_BASE_INPUT_G          => false, 
    EVT30_SUPPORT_G                => false,
    FILE_PATH_G                    => IN_DATA_FILE_PATH_G,
    RAW_MODE_SUPPORT_G             => true,
    USE_LANE_MIXER_G               => true,
    WHOIAM_G                       => "MIPI TX BFM",
    FPGA_FAMILY_G                  => "ULTRASCALE_PLUS"                -- "7SERIES", "ULTRASCALE_PLUS"
  )
  port map(
    -- Clock and Reset
    clk                  => clk      ,
    arst_n               => arst_n   ,
    srst                 => srst     ,
    hs_clk               => hs_clk   ,
    hs_arst_n            => hs_arst_n,
    hs_srst              => hs_srst  ,

    -- BFM Configuration and Synchronization I/F
    bfm_enable_i         => bfm_mipi_tx_enable_i,
    bfm_eof_o            => bfm_mipi_tx_eof_o,

    -- MIPI RX Flow CONTROL
    mipi_rx_ready_i      => '1', -- always on
    
    -- Event Time Base (us)
    evt_time_base_i      => (others => '0'),
    evt_time_high_sync_i => '0',
    
    -- Synchronization Of Sequencer
    sync_request_i       => bfm_mipi_tx_sync_request_i,
    sync_ack_o           => bfm_mipi_tx_sync_ack_o,

    -- MIPI CSI2 TX Interface
    mipi_tx_hs_clk_o     => mipi_tx_hs_clk_o,
    mipi_tx_hs_d1_o      => mipi_tx_hs_d1_o ,
    mipi_tx_hs_d0_o      => mipi_tx_hs_d0_o ,
    mipi_tx_lp_clk_o     => mipi_tx_lp_clk_o,
    mipi_tx_lp_d1_o      => mipi_tx_lp_d1_o ,
    mipi_tx_lp_d0_o      => mipi_tx_lp_d0_o ,
    
    -- MIPI CSI2 TX Interface for Verification
    mipi_tx_if_clk_o     => open,
    mipi_tx_if_rst_o     => open,
    mipi_tx_if_valid_o   => open,
    mipi_tx_if_data_o    => open,

    -- AXI-Lite Slave Interface
    s_axi_aclk           => clk,
    s_axi_aresetn        => arst_n,
    s_axi_awaddr         => axil_m_awaddr_s,
    s_axi_awprot         => axil_m_awprot_s ,
    s_axi_awvalid        => axil_m_awvalid_s,
    s_axi_awready        => axil_m_awready_s,
    s_axi_wdata          => axil_m_wdata_s  ,
    s_axi_wstrb          => axil_m_wstrb_s  ,
    s_axi_wvalid         => axil_m_wvalid_s ,
    s_axi_wready         => axil_m_wready_s ,
    s_axi_bresp          => axil_m_bresp_s  ,
    s_axi_bvalid         => axil_m_bvalid_s ,
    s_axi_bready         => axil_m_bready_s ,
    s_axi_araddr         => axil_m_araddr_s ,
    s_axi_arprot         => axil_m_arprot_s ,
    s_axi_arvalid        => axil_m_arvalid_s, 
    s_axi_arready        => axil_m_arready_s, 
    s_axi_rdata          => axil_m_rdata_s  ,
    s_axi_rresp          => axil_m_rresp_s  ,
    s_axi_rvalid         => axil_m_rvalid_s ,
    s_axi_rready         => axil_m_rready_s
  );


end sim;
