-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
-- Unless required by applicable law or agreed to in writing, software distributed
-- under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License
-- for the specific language governing permissions and limitations under the License.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;
use work.evt_verification_pkg;


---------------------
-- MIPI TX 2-lane BFM
entity mipi_tx_2l_bfm is
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
end entity mipi_tx_2l_bfm;

architecture rtl of mipi_tx_2l_bfm is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant USE_EVT_ENABLE_C : boolean := true;


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ----------------------
  -- Event Stream Reader
  component evt_stream_reader is
    generic (
      EVT_FORMAT                   : natural range 0 to 3         := 2;
      EVT_TIME_HIGH_SYNC_PERIOD_US : integer                      := 128;
      FILE_PATH                    : string                       := "file.dat";
      FILTER_TYPES                 : boolean                      := true;
      FILTER_SUBTYPES              : boolean                      := false;
      FILTER_TRIGGER_IDS           : boolean                      := false;
      INSERT_EOT                   : boolean                      := false;                            -- Insert end of task event
      NEEDED_TYPES                 : ccam_evt_type_vector_t       := (-1 downto 0 => (others => '0'));
      NEEDED_SUBTYPES              : ccam_evt_subtype_vector_t    := (-1 downto 0 => (others => '0'));
      NEEDED_V3_TYPES              : ccam_evt_v3_type_vector_t    := (-1 downto 0 => (others => '0'));
      NEEDED_V3_SUBTYPES           : ccam_evt_v3_subtype_vector_t := (-1 downto 0 => (others => '0'));
      NEEDED_TRIGGER_IDS           : natural_vector_t             := (-1 downto 0 => 0);
      USE_TIME_BASE_INPUT          : boolean                      := false;
      WHOIAM                       : string                       := "Evt. Stream Reader"
    );
    port (
      -- Clock
      clk             : in  std_logic;
      arst_n          : in  std_logic;
      srst            : in  std_logic;

      -- Enable
      enable_i        : in  std_logic;
      eof_o           : out std_logic;

      -- Event Time Base (us)
      evt_time_base_i : in  ccam_evt_time_data_t;

      -- Synchronization Of Sequencer
      sync_request_i  : in  std_logic;
      sync_ack_o      : out std_logic;

      -- Output Event Stream Interface
      out_ready_i     : in  std_logic;
      out_valid_o     : out std_logic;
      out_last_o      : out std_logic;
      out_data_o      : out ccam_evt_data_t
    );
  end component evt_stream_reader;


  ----------------------------------------------------------
  -- Control and Interface for the Xilinx's MIPI CSI2 TX IP
  component xilinx_mipi_tx_2l is
    generic (
      BUS_BASE_ADDR      : natural  := 0;
      BUS_ADDR_WIDTH     : positive := 32;
      BUS_DATA_WIDTH     : positive := 32;
      EVT30_SUPPORT      : boolean  := true;
      CLK_FREQ           : positive := 100000000;
      MIPI_LANES         : positive := 2;         -- Number of MIPI Lanes.
      TIME_HIGH_PERIOD   : positive := 16;
      RAW_MODE_SUPPORT_G : boolean  := true;
      USE_EXT_ENABLE     : boolean  := false;
      FPGA_FAMILY_G      : string                 -- "7SERIES", "ULTRASCALE_PLUS"
    );
    port (
      -- Clock and Reset
      clk                      : in    std_logic;
      arst_n                   : in    std_logic;
      srst                     : in    std_logic;
      hs_clk                   : in    std_logic; -- HS Clock
      hs_arst_n                : in    std_logic;
      hs_srst                  : in    std_logic;

      -- Configuration Inputs
      cfg_enable_i             : in    std_logic;
      cfg_evt_format_i         : in    evt_format_data_t;
      cfg_evt_time_high_sync_i : in    std_logic;

      -- Input Interface
      evt_in_ready_o           : out   std_logic;
      evt_in_valid_i           : in    std_logic;
      evt_in_first_i           : in    std_logic;
      evt_in_last_i            : in    std_logic;
      evt_in_data_i            : in    ccam_evt_data_t;

      -- I/O control
      io_ctrl_clk_en_o         : out   std_logic;                               -- MIPI TX Tristate IO Controllers for Clock Lane
      io_ctrl_d1_en_o          : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D1 Lane
      io_ctrl_d0_en_o          : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D0 Lane

      -- MIPI RX Flow CONTROL
      mipi_rx_ready_i          : in  std_logic;

      -- MIPI CSI2 TX Interface
      mipi_tx_hs_clk_o         : out   std_logic;
      mipi_tx_hs_d3_o          : out   std_logic;
      mipi_tx_hs_d2_o          : out   std_logic;
      mipi_tx_hs_d1_o          : out   std_logic;
      mipi_tx_hs_d0_o          : out   std_logic;
      mipi_tx_lp_clk_io        : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d3_io         : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d2_io         : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d1_io         : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d0_io         : inout std_logic_vector(1 downto 0);

      -- MIPI CSI2 TX Interface for Verification
      mipi_tx_if_clk_o         : out   std_logic;
      mipi_tx_if_rst_o         : out   std_logic;
      mipi_tx_if_valid_o       : out   std_logic;
      mipi_tx_if_data_o        : out   std_logic_vector((8*MIPI_LANES)-1 downto 0);

      -- AXI-Lite Slave Interface
      s_axi_aclk               : in   std_logic;
      s_axi_aresetn            : in   std_logic;
      s_axi_awaddr             : in   std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
      s_axi_awprot             : in   std_logic_vector(2 downto 0);
      s_axi_awvalid            : in   std_logic;
      s_axi_awready            : out  std_logic;
      s_axi_wdata              : in   std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
      s_axi_wstrb              : in   std_logic_vector((BUS_DATA_WIDTH_G/8)-1 downto 0);
      s_axi_wvalid             : in   std_logic;
      s_axi_wready             : out  std_logic;
      s_axi_bresp              : out  std_logic_vector(1 downto 0);
      s_axi_bvalid             : out  std_logic;
      s_axi_bready             : in   std_logic;
      s_axi_araddr             : in   std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
      s_axi_arprot             : in   std_logic_vector(2 downto 0);
      s_axi_arvalid            : in   std_logic;
      s_axi_arready            : out  std_logic;
      s_axi_rdata              : out  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);
      s_axi_rresp              : out  std_logic_vector(1 downto 0);
      s_axi_rvalid             : out  std_logic;
      s_axi_rready             : in   std_logic
    );
  end component xilinx_mipi_tx_2l;


  --------------------------------------------------------------------
  -- Mixing Low Power and High Speed MIPI interface to be able to
  -- connect the MIPI TX to a MIPI RX core
  component mipi_tx_lane_hs_lp_mixer is
    port (
      -- Input MIPI CSI2 TX Interface from mipi_host_if
      in_mipi_tx_hs_clk_i   : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      in_mipi_tx_hs_d0_i    : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      in_mipi_tx_hs_d1_i    : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      in_mipi_tx_lp_clk_io  : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      in_mipi_tx_lp_d0_io   : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      in_mipi_tx_lp_d1_io   : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)

      -- Output MIPI CSI2 TX Interface with High Speed interface only (LP lines are don't care)
      out_mipi_tx_hs_clk_o  : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      out_mipi_tx_hs_d0_o   : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      out_mipi_tx_hs_d1_o   : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      out_mipi_tx_lp_clk_io : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      out_mipi_tx_lp_d0_io  : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
      out_mipi_tx_lp_d1_io  : inout std_logic_vector(1 downto 0)  -- (P => 1, N => 0)
    );
  end component mipi_tx_lane_hs_lp_mixer;


  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Configuration Signals
  signal cfg_evt_format_s              : evt_format_data_t;

  -- Event Stream Reader Signals
  signal evt_stream_reader_out_ready_s : std_logic;
  signal evt_stream_reader_out_valid_s : std_logic;
  signal evt_stream_reader_out_first_s : std_logic;
  signal evt_stream_reader_out_last_s  : std_logic;
  signal evt_stream_reader_out_data_s  : ccam_evt_data_t;

  -- CCAM5 MIPI CSI2 TX IP Interface
  signal mipi_tx_ip_io_ctrl_clk_en_s   : std_logic;                   -- MIPI TX Tristate IO Controllers for Clock Lane
  signal mipi_tx_ip_io_ctrl_d1_en_s    : std_logic;                   -- MIPI TX Tristate IO Controllers for D1 Lane
  signal mipi_tx_ip_io_ctrl_d0_en_s    : std_logic;                   -- MIPI TX Tristate IO Controllers for D0 Lane
  signal mipi_tx_ip_hs_clk_s           : std_logic;
  signal mipi_tx_ip_hs_d0_s            : std_logic;
  signal mipi_tx_ip_hs_d1_s            : std_logic;
  signal mipi_tx_ip_lp_clk_s           : std_logic_vector(1 downto 0);
  signal mipi_tx_ip_lp_d0_s            : std_logic_vector(1 downto 0);
  signal mipi_tx_ip_lp_d1_s            : std_logic_vector(1 downto 0);

  -- CCAM5 MIPI CSI2 TX Interface
  signal mipi_tx_hs_clk_s              : std_logic_vector(1 downto 0);
  signal mipi_tx_hs_d0_s               : std_logic_vector(1 downto 0);
  signal mipi_tx_hs_d1_s               : std_logic_vector(1 downto 0);
  signal mipi_tx_lp_clk_s              : std_logic_vector(1 downto 0);
  signal mipi_tx_lp_d0_s               : std_logic_vector(1 downto 0);
  signal mipi_tx_lp_d1_s               : std_logic_vector(1 downto 0);

  -- CCAM5 MIPI CSI2 TX Lane Mixer Interface
  signal mipi_tx_lmix_hs_clk_s         : std_logic_vector(1 downto 0);
  signal mipi_tx_lmix_hs_d0_s          : std_logic_vector(1 downto 0);
  signal mipi_tx_lmix_hs_d1_s          : std_logic_vector(1 downto 0);
  signal mipi_tx_lmix_lp_clk_s         : std_logic_vector(1 downto 0);
  signal mipi_tx_lmix_lp_d0_s          : std_logic_vector(1 downto 0);
  signal mipi_tx_lmix_lp_d1_s          : std_logic_vector(1 downto 0);


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Configuration Signals
  cfg_evt_format_s              <= to_evt_format_data(EVT_FORMAT_G);

  -- Event Stream Reader Signals
  evt_stream_reader_out_first_s <= '0';

  -- CCAM5 MIPI CSI2 TX IP Interface
  mipi_tx_hs_clk_s              <= (mipi_tx_ip_hs_clk_s, not mipi_tx_ip_hs_clk_s) when (mipi_tx_ip_io_ctrl_clk_en_s = '1') else (others => 'Z'); -- (P => 1, N => 0)
  mipi_tx_hs_d1_s               <= (mipi_tx_ip_hs_d1_s,  not mipi_tx_ip_hs_d1_s ) when (mipi_tx_ip_io_ctrl_d1_en_s  = '1') else (others => 'Z'); -- (P => 1, N => 0)
  mipi_tx_hs_d0_s               <= (mipi_tx_ip_hs_d0_s,  not mipi_tx_ip_hs_d0_s ) when (mipi_tx_ip_io_ctrl_d0_en_s  = '1') else (others => 'Z'); -- (P => 1, N => 0)
  mipi_tx_lp_clk_s              <= mipi_tx_ip_lp_clk_s;                                                                                          -- (P => 1, N => 0)
  mipi_tx_lp_d1_s               <= mipi_tx_ip_lp_d1_s;                                                                                           -- (P => 1, N => 0)
  mipi_tx_lp_d0_s               <= mipi_tx_ip_lp_d0_s;                                                                                           -- (P => 1, N => 0)
  mipi_tx_ip_lp_clk_s           <= (others => 'Z');                                                                                              -- (P => 1, N => 0)
  mipi_tx_ip_lp_d1_s            <= (others => 'Z');                                                                                              -- (P => 1, N => 0)
  mipi_tx_ip_lp_d0_s            <= (others => 'Z');                                                                                              -- (P => 1, N => 0)

  -- CCAM5 MIPI CSI2 TX Interface
  mipi_tx_hs_clk_o              <= mipi_tx_lmix_hs_clk_s when (USE_LANE_MIXER_G) else mipi_tx_hs_clk_s;                                          -- (P => 1, N => 0)
  mipi_tx_hs_d1_o               <= mipi_tx_lmix_hs_d1_s  when (USE_LANE_MIXER_G) else mipi_tx_hs_d1_s;                                           -- (P => 1, N => 0)
  mipi_tx_hs_d0_o               <= mipi_tx_lmix_hs_d0_s  when (USE_LANE_MIXER_G) else mipi_tx_hs_d0_s;                                           -- (P => 1, N => 0)
  mipi_tx_lp_clk_o              <= mipi_tx_lmix_lp_clk_s when (USE_LANE_MIXER_G) else mipi_tx_hs_clk_s;                                          -- (P => 1, N => 0)
  mipi_tx_lp_d1_o               <= mipi_tx_lmix_lp_d1_s  when (USE_LANE_MIXER_G) else mipi_tx_hs_d1_s;                                           -- (P => 1, N => 0)
  mipi_tx_lp_d0_o               <= mipi_tx_lmix_lp_d0_s  when (USE_LANE_MIXER_G) else mipi_tx_hs_d0_s;                                           -- (P => 1, N => 0)


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ----------------------
  -- Event Stream Reader
  evt_stream_reader_u : evt_stream_reader
  generic map (
    EVT_FORMAT                   => EVT_FORMAT_G,
    EVT_TIME_HIGH_SYNC_PERIOD_US => EVT_TIME_HIGH_SYNC_PERIOD_US_G,
    FILE_PATH                    => FILE_PATH_G,
    FILTER_TYPES                 => FILTER_TYPES_G,
    FILTER_SUBTYPES              => FILTER_SUBTYPES_G,
    FILTER_TRIGGER_IDS           => FILTER_TRIGGER_IDS_G,
    INSERT_EOT                   => INSERT_EOT_G,
    NEEDED_TYPES                 => NEEDED_TYPES_G,
    NEEDED_SUBTYPES              => NEEDED_SUBTYPES_G,
    NEEDED_V3_TYPES              => NEEDED_V3_TYPES_G,
    NEEDED_V3_SUBTYPES           => NEEDED_V3_SUBTYPES_G,
    NEEDED_TRIGGER_IDS           => NEEDED_TRIGGER_IDS_G,
    USE_TIME_BASE_INPUT          => USE_TIME_BASE_INPUT_G,
    WHOIAM                       => WHOIAM_G
  )
  port map (
    -- Clock and Reset
    clk             => clk,
    arst_n          => arst_n,
    srst            => srst,

    -- Enable
    enable_i        => bfm_enable_i,
    eof_o           => bfm_eof_o,

    -- Event Time Base (us)
    evt_time_base_i => evt_time_base_i,

    -- Synchronization Of Sequencer
    sync_request_i  => sync_request_i,
    sync_ack_o      => sync_ack_o,

    -- Output Event Stream Interface
    out_ready_i     => evt_stream_reader_out_ready_s,
    out_valid_o     => evt_stream_reader_out_valid_s,
    out_last_o      => evt_stream_reader_out_last_s,
    out_data_o      => evt_stream_reader_out_data_s
  );


  ----------------------------------------------------------
  -- Control and Interface for the Xilinx's MIPI CSI2 TX IP
  mipi_tx_u : xilinx_mipi_tx_2l
  generic map (
    BUS_BASE_ADDR      => BUS_BASE_ADDR_G,
    BUS_ADDR_WIDTH     => BUS_ADDR_WIDTH_G,
    BUS_DATA_WIDTH     => BUS_DATA_WIDTH_G,
    CLK_FREQ           => CLK_FREQ_HZ_G,
    EVT30_SUPPORT      => EVT30_SUPPORT_G,
    MIPI_LANES         => MIPI_LANES_G,        -- Number of MIPI Lanes.
    RAW_MODE_SUPPORT_G => RAW_MODE_SUPPORT_G,
    TIME_HIGH_PERIOD   => EVT_TIME_HIGH_SYNC_PERIOD_US_G,
    USE_EXT_ENABLE     => USE_EVT_ENABLE_C,
    FPGA_FAMILY_G      => FPGA_FAMILY_G
  )
  port map (
    -- Clock and Reset
    clk                      => clk,
    arst_n                   => arst_n,
    srst                     => srst,
    hs_clk                   => hs_clk,
    hs_arst_n                => hs_arst_n,
    hs_srst                  => hs_srst,

    -- Configuration Inputs
    cfg_enable_i             => bfm_enable_i,
    cfg_evt_format_i         => cfg_evt_format_s,
    cfg_evt_time_high_sync_i => evt_time_high_sync_i,

    -- Input Interface
    evt_in_ready_o           => evt_stream_reader_out_ready_s,
    evt_in_valid_i           => evt_stream_reader_out_valid_s,
    evt_in_first_i           => evt_stream_reader_out_first_s,
    evt_in_last_i            => evt_stream_reader_out_last_s,
    evt_in_data_i            => evt_stream_reader_out_data_s,

    -- I/O control
    io_ctrl_clk_en_o         => mipi_tx_ip_io_ctrl_clk_en_s,   -- MIPI TX Tristate IO Controllers for Clock Lane
    io_ctrl_d1_en_o          => mipi_tx_ip_io_ctrl_d1_en_s,    -- MIPI TX Tristate IO Controllers for D1 Lane
    io_ctrl_d0_en_o          => mipi_tx_ip_io_ctrl_d0_en_s,    -- MIPI TX Tristate IO Controllers for D0 Lane

    -- MIPI RX Flow CONTROL
    mipi_rx_ready_i          => mipi_rx_ready_i,

    -- MIPI CSI2 TX Interface
    mipi_tx_hs_clk_o         => mipi_tx_ip_hs_clk_s,
    mipi_tx_hs_d3_o          => open,
    mipi_tx_hs_d2_o          => open,
    mipi_tx_hs_d1_o          => mipi_tx_ip_hs_d1_s,
    mipi_tx_hs_d0_o          => mipi_tx_ip_hs_d0_s,
    mipi_tx_lp_clk_io        => mipi_tx_ip_lp_clk_s,
    mipi_tx_lp_d3_io         => open,
    mipi_tx_lp_d2_io         => open,
    mipi_tx_lp_d1_io         => mipi_tx_ip_lp_d1_s,
    mipi_tx_lp_d0_io         => mipi_tx_ip_lp_d0_s,

    -- MIPI CSI2 TX Interface for Verification
    mipi_tx_if_clk_o         => mipi_tx_if_clk_o,
    mipi_tx_if_rst_o         => mipi_tx_if_rst_o,
    mipi_tx_if_valid_o       => mipi_tx_if_valid_o,
    mipi_tx_if_data_o        => mipi_tx_if_data_o,

    -- AXI-Lite Slave Interface
    s_axi_aclk               => s_axi_aclk   ,
    s_axi_aresetn            => s_axi_aresetn,
    s_axi_awaddr             => s_axi_awaddr ,
    s_axi_awprot             => s_axi_awprot ,
    s_axi_awvalid            => s_axi_awvalid,
    s_axi_awready            => s_axi_awready,
    s_axi_wdata              => s_axi_wdata  ,
    s_axi_wstrb              => s_axi_wstrb  ,
    s_axi_wvalid             => s_axi_wvalid ,
    s_axi_wready             => s_axi_wready ,
    s_axi_bresp              => s_axi_bresp  ,
    s_axi_bvalid             => s_axi_bvalid ,
    s_axi_bready             => s_axi_bready ,
    s_axi_araddr             => s_axi_araddr ,
    s_axi_arprot             => s_axi_arprot ,
    s_axi_arvalid            => s_axi_arvalid,
    s_axi_arready            => s_axi_arready,
    s_axi_rdata              => s_axi_rdata  ,
    s_axi_rresp              => s_axi_rresp  ,
    s_axi_rvalid             => s_axi_rvalid ,
    s_axi_rready             => s_axi_rready
  );


  mipi_tx_lane_hs_lp_mixer_gen : if (USE_LANE_MIXER_G) generate

    --------------------------------------------------------------------
    -- Mixing Low Power and High Speed MIPI interface to be able to
    -- connect the MIPI TX to a MIPI RX core
    mipi_tx_lane_hs_lp_mixer_u : mipi_tx_lane_hs_lp_mixer
    port map (
      -- Input MIPI CSI2 TX Interface from mipi_host_if
      in_mipi_tx_hs_clk_i   => mipi_tx_hs_clk_s,      -- (P => 1, N => 0)
      in_mipi_tx_hs_d0_i    => mipi_tx_hs_d0_s,       -- (P => 1, N => 0)
      in_mipi_tx_hs_d1_i    => mipi_tx_hs_d1_s,       -- (P => 1, N => 0)
      in_mipi_tx_lp_clk_io  => mipi_tx_lp_clk_s,      -- (P => 1, N => 0)
      in_mipi_tx_lp_d0_io   => mipi_tx_lp_d0_s,       -- (P => 1, N => 0)
      in_mipi_tx_lp_d1_io   => mipi_tx_lp_d1_s,       -- (P => 1, N => 0)

      -- Output MIPI CSI2 TX Interface with High Speed interface only (LP lines are don't care)
      out_mipi_tx_hs_clk_o  => mipi_tx_lmix_hs_clk_s, -- (P => 1, N => 0)
      out_mipi_tx_hs_d0_o   => mipi_tx_lmix_hs_d0_s,  -- (P => 1, N => 0)
      out_mipi_tx_hs_d1_o   => mipi_tx_lmix_hs_d1_s,  -- (P => 1, N => 0)
      out_mipi_tx_lp_clk_io => mipi_tx_lmix_lp_clk_s, -- (P => 1, N => 0)
      out_mipi_tx_lp_d0_io  => mipi_tx_lmix_lp_d0_s,  -- (P => 1, N => 0)
      out_mipi_tx_lp_d1_io  => mipi_tx_lmix_lp_d1_s   -- (P => 1, N => 0)
    );

  end generate mipi_tx_lane_hs_lp_mixer_gen;


  mipi_tx_lane_hs_lp_mixer_gen_n : if (not USE_LANE_MIXER_G) generate

    mipi_tx_lmix_hs_clk_s <= (others => '-'); -- (P => 1, N => 0)
    mipi_tx_lmix_hs_d0_s  <= (others => '-'); -- (P => 1, N => 0)
    mipi_tx_lmix_hs_d1_s  <= (others => '-'); -- (P => 1, N => 0)
    mipi_tx_lmix_lp_clk_s <= (others => '-'); -- (P => 1, N => 0)
    mipi_tx_lmix_lp_d0_s  <= (others => '-'); -- (P => 1, N => 0)
    mipi_tx_lmix_lp_d1_s  <= (others => '-'); -- (P => 1, N => 0)

  end generate mipi_tx_lane_hs_lp_mixer_gen_n;


end architecture rtl;
