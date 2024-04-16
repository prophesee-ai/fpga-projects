----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Ny Onintsoa Andriamananjara (noandriamananjara@prophesee.ai)
--
-- Create Date:    Oct. 31, 2018
-- Design Name:    xilinx_mipi_tx_2l
-- Module Name:    xilinx_mipi_tx_2l
-- Project Name:   ccam4_single_sisley
-- Target Devices: Xilinx Spartan 7
-- Tool versions:  Vivado 2018.2
-- Description:    Control and Interface for the Xilinx's MIPI CSI2 TX IP.
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_utils.all;


----------------------------------------------------------
-- Control and Interface for the Xilinx's MIPI CSI2 TX IP
entity xilinx_mipi_tx_2l is
  generic (
    BUS_BASE_ADDR         : natural  := 0;
    BUS_ADDR_WIDTH        : positive := 32;
    BUS_DATA_WIDTH        : positive := 32;
    CLK_FREQ              : positive := 100000000;
    EVT30_SUPPORT         : boolean  := true;
    MIPI_PADDING_ENABLE_G : boolean  := false;
    MIPI_LANES            : positive := 2;         -- Number of MIPI Lanes.
    TIME_HIGH_PERIOD      : positive := 16;
    RAW_MODE_SUPPORT_G    : boolean  := true;
    FIXED_FRAME_SIZE_G    : boolean  := false;
    USE_EXT_ENABLE        : boolean  := false;
    USE_FRAME_COUNT_G     : boolean  := false;
    FPGA_FAMILY_G         : string                 -- "7SERIES", "ULTRASCALE_PLUS"
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

    -- MIPI RX Flow Control
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
    s_axi_awaddr             : in   std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
    s_axi_awprot             : in   std_logic_vector(2 downto 0);
    s_axi_awvalid            : in   std_logic;
    s_axi_awready            : out  std_logic;
    s_axi_wdata              : in   std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
    s_axi_wstrb              : in   std_logic_vector((BUS_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid             : in   std_logic;
    s_axi_wready             : out  std_logic;
    s_axi_bresp              : out  std_logic_vector(1 downto 0);
    s_axi_bvalid             : out  std_logic;
    s_axi_bready             : in   std_logic;
    s_axi_araddr             : in   std_logic_vector(BUS_ADDR_WIDTH-1 downto 0);
    s_axi_arprot             : in   std_logic_vector(2 downto 0);
    s_axi_arvalid            : in   std_logic;
    s_axi_arready            : out  std_logic;
    s_axi_rdata              : out  std_logic_vector(BUS_DATA_WIDTH-1 downto 0);
    s_axi_rresp              : out  std_logic_vector(1 downto 0);
    s_axi_rvalid             : out  std_logic;
    s_axi_rready             : in   std_logic
  );
end entity xilinx_mipi_tx_2l;


architecture rtl of xilinx_mipi_tx_2l is


  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant MIPI_MAX_PACKET_SIZE    : positive := 16384;                  -- Max. number of bytes in MIPI packet. Default 16KB.
  constant MIPI_TX_FIFO_DEPTH      : positive := 4096;                   -- 16KB FIFO / 4B per element => 4K Depth.
  constant MIPI_TX_FIFO_DATA_WIDTH : positive := CCAM_EVT_DATA_BITS;
  constant MIPI_TX_FIFO_USE_BRAM   : boolean  := true;
  constant MIPI_DATA_TYPE          : natural  := 16#30#;                 -- 6-bit MIPI CSI2 Data Type.  Example: DT = 6'h2B = RAW10; DT = 6'h30 = USER DEFINED.
  constant MIPI_DATA_WIDTH         : positive := 8*MIPI_LANES;           -- MIPI Input Pixel Data Width for Lattice IP.
  constant MIPI_TEST_MODE          : boolean  := false;                  -- Adds a color bar pattern generator for testing purposes.  Operates from input clock and reset_n inputs.
  constant MIPI_USE_CRC16          : boolean  := true;                   -- Appends 16-bit checksum to the end of long packet transfers.  0 = off, 1 = on.  Turning off will append 16'hFFFF to end of long packet.  Turning off will reduce resource utilization.

  constant MIPI_PADDING_ENABLE_C       : boolean   := iff(FIXED_FRAME_SIZE_G, true, MIPI_PADDING_ENABLE_G);
  constant MIPI_PADDING_PRESENT_C      : std_logic_vector(0 downto 0) := (others => to_std_logic(MIPI_PADDING_ENABLE_C));
  constant MIPI_FIXED_FRAME_PRESENT_C  : std_logic_vector(0 downto 0) := (others => to_std_logic(FIXED_FRAME_SIZE_G));


  -----------------------
  -- Design Components --
  -----------------------


  --------------------------------------
  -- Events to MIPI Packet Control Block
  -- for a MIPI CSI2 TX IP
  component mipi_tx_control is
    generic (
      EVT30_SUPPORT         : boolean  := true;
      FIXED_FRAME_SIZE_G    : boolean  := false;
      MIPI_PADDING_ENABLE_G : boolean  := false;
      MIPI_DATA_WIDTH       : positive := 16;
      MIPI_MAX_PACKET_SIZE  : positive := 16384; -- Max. number of bytes in MIPI packet. Default 16KB.
      TIME_HIGH_PERIOD      : positive := 16;
      RAW_MODE_SUPPORT_G    : boolean  := true
    );
    port (
      -- Core clock and reset
      clk                         : in  std_logic;
      arst_n                      : in  std_logic;
      srst                        : in  std_logic;

      -- Configuration Interface
      cfg_enable_i                : in  std_logic;
      cfg_enable_packet_timeout_i : in  std_logic;
      cfg_evt_format_i            : in  evt_format_data_t;
      cfg_virtual_channel_i       : in  std_logic_vector(1 downto 0);
      cfg_data_type_i             : in  std_logic_vector(5 downto 0);
      cfg_frame_period_us_i       : in  std_logic_vector(15 downto 0);
      cfg_packet_timeout_us_i     : in  std_logic_vector(15 downto 0);
      cfg_packet_size_i           : in  std_logic_vector(13 downto 0);
      cfg_evt_time_high_sync_i    : in  std_logic;
      cfg_blocking_mode_i         : in  std_logic;
      cfg_padding_bypass_i        : in  std_logic;

      -- Event Input Interface
      evt_in_ready_o              : out std_logic;
      evt_in_valid_i              : in  std_logic;
      evt_in_first_i              : in  std_logic;
      evt_in_last_i               : in  std_logic;
      evt_in_data_i               : in  ccam_evt_data_t;

      -- MIPI TX FIFO Write Interface
      fifo_wr_ready_i             : in  std_logic;
      fifo_wr_valid_o             : out std_logic;
      fifo_wr_first_o             : out std_logic;
      fifo_wr_last_o              : out std_logic;
      fifo_wr_data_o              : out ccam_evt_data_t;

      -- MIPI TX FIFO Read Interface
      fifo_rd_ready_o             : out std_logic;
      fifo_rd_valid_i             : in  std_logic;
      fifo_rd_first_i             : in  std_logic;
      fifo_rd_last_i              : in  std_logic;
      fifo_rd_data_i              : in  ccam_evt_data_t;

      -- MIPI RX Flow Control
      mipi_rx_ready_i             : in  std_logic;

      -- MIPI TX Generic IP Interface
      mipi_tx_ready_i             : in  std_logic;
      mipi_tx_valid_o             : out std_logic;
      mipi_tx_frame_start_o       : out std_logic;
      mipi_tx_frame_end_o         : out std_logic;
      mipi_tx_packet_start_o      : out std_logic;
      mipi_tx_packet_end_o        : out std_logic;
      mipi_tx_virtual_channel_o   : out std_logic_vector(1 downto 0);
      mipi_tx_data_type_o         : out std_logic_vector(5 downto 0);
      mipi_tx_word_count_o        : out std_logic_vector(15 downto 0);
      mipi_tx_data_o              : out std_logic_vector(MIPI_DATA_WIDTH-1 downto 0)
    );
  end component mipi_tx_control;


  ---------------
  -- MIPI TX FIFO
  component mipi_tx_fifo is
    generic (
      DATA_WIDTH : positive := 32;   -- Memory Data Width
      DEPTH      : positive := 4096  -- Memory Address Depth
    );
    port (
      -- Clock and Reset
      clk              : in  std_logic;
      arst_n           : in  std_logic;
      srst             : in  std_logic;

      -- Configuration Interface
      cfg_evt_format_i : in  evt_format_data_t;

      -- Input Interface
      in_ready_o       : out std_logic;
      in_valid_i       : in  std_logic;
      in_first_i       : in  std_logic;
      in_last_i        : in  std_logic;
      in_data_i        : in  std_logic_vector(DATA_WIDTH-1 downto 0);

      -- Output Interface
      out_ready_i      : in  std_logic;
      out_valid_o      : out std_logic;
      out_first_o      : out std_logic;
      out_last_o       : out std_logic;
      out_data_o       : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component mipi_tx_fifo;


  --------------------------------------
  -- Events to MIPI Packet Control Block
  -- for a MIPI CSI2 TX IP
  component lattice_mipi_tx_packet_if is
    generic (
      MIPI_DATA_WIDTH   : positive := 16;
      CLK_FREQ          : positive := 100000000;
      USE_FRAME_COUNT_G : boolean  := false
    );
    port (

      -- Core clock and reset
      clk                     : in  std_logic;
      arst_n                  : in  std_logic;
      srst                    : in  std_logic;

      -- Configuration Interface
      cfg_enable_i            : in  std_logic;
      cfg_start_time_i        : in  std_logic_vector(15 downto 0);
      cfg_start_frame_time_i  : in  std_logic_vector(15 downto 0);
      cfg_end_frame_time_i    : in  std_logic_vector(15 downto 0);
      cfg_inter_frame_time_i  : in  std_logic_vector(15 downto 0);
      cfg_inter_packet_time_i : in  std_logic_vector(15 downto 0);

      -- MIPI TX Generic IP Input Interface
      txi_ready_o             : out std_logic;
      txi_valid_i             : in  std_logic;
      txi_frame_start_i       : in  std_logic;
      txi_frame_end_i         : in  std_logic;
      txi_packet_start_i      : in  std_logic;
      txi_packet_end_i        : in  std_logic;
      txi_virtual_channel_i   : in  std_logic_vector(1 downto 0);
      txi_data_type_i         : in  std_logic_vector(5 downto 0);
      txi_word_count_i        : in  std_logic_vector(15 downto 0);
      txi_data_i              : in  std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0);

      -- Lattice's MIPI IP Parallel Interface
      txo_short_en_o          : out std_logic; -- Frame Valid input for parallel interface
      txo_long_en_o           : out std_logic; -- Line Valid input for parallel interface
      txo_crc_rst_o           : out std_logic; -- Reset the CRC data calculation
      txo_data_o              : out std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0); -- Pixel data bus for parallel interface
      txo_vc_o                : out std_logic_vector(1 downto 0); -- 2-bit Virtual Channel Number
      txo_dt_o                : out std_logic_vector(5 downto 0); -- 6-bit Data Type
      txo_wc_o                : out std_logic_vector(15 downto 0) -- 16-bit Word Count in byte packets.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels
    );
  end component lattice_mipi_tx_packet_if;


  ------------------------------------
  -- Lattice MIPI CSI2 TX IP - 2 lanes
  component xilinx_mipi_tx_ip_2l is
    generic (
      DATA_WIDTH            : positive := 16;     -- Pixel Bus Width.  Example: RGB888 = 8-bits Red, 8-bits Green, 8-bits Blue = 24 bits/pixel
      DATA_TYPE             : integer  := 16#30#; -- 6-bit MIPI CSI2 Data Type.  Example: DT = 6'h2B = RAW10; DT = 6'h30 = USER DEFINED.
      TEST_MODE             : boolean  := false;  -- Adds a color bar pattern generator for testing purposes.  Operates from input clock and reset_n inputs.
      CRC16                 : boolean  := true;   -- Appends 16-bit checksum to the end of long packet transfers.  0 = off, 1 = on.  Turning off will append 16'hFFFF to end of long packet.  Turning off will reduce resource utilization.
      RESERVED              : boolean  := false;  -- RESERVED = 0 at all times.
      FPGA_FAMILY_G         : string              -- "7SERIES", "ULTRASCALE_PLUS"
    );
    port (
      -- Core clock and reset
      clk                   : in    std_logic;
      arst_n                : in    std_logic;
      srst                  : in    std_logic;
      hs_clk                : in    std_logic; -- HS Clock
      hs_arst_n             : in    std_logic;
      hs_srst               : in    std_logic;

      -- Lattice's MIPI IP Parallel Interface
      txi_short_en_i        : in    std_logic;                               -- Short Packet Enable for Frame Start and Frame End
      txi_long_en_i         : in    std_logic;                               -- Long Packet Enable for Data Payload Packets
      txi_crc_rst_i         : in    std_logic;                               -- Reset the CRC data calculation
      txi_data_i            : in    std_logic_vector(DATA_WIDTH-1 downto 0); -- Long Packet Input Data Interface
      txi_vc_i              : in    std_logic_vector(1 downto 0);            -- 2-bit Long Packet Virtual Channel Number
      txi_dt_i              : in    std_logic_vector(5 downto 0);            -- 6-bit Long Packet Data Type
      txi_wc_i              : in    std_logic_vector(15 downto 0);           -- 16-bit Long Packet Word Count in Bytes.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels

      -- I/O control
      io_ctrl_clk_en_o      : out   std_logic;                               -- MIPI TX Tristate IO Controllers for Clock Lane
      io_ctrl_d1_en_o       : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D1 Lane
      io_ctrl_d0_en_o       : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D0 Lane

      -- MIPI CSI2 TX Interface
      mipi_tx_hs_clk_o      : out   std_logic;
      mipi_tx_hs_d3_o       : out   std_logic;
      mipi_tx_hs_d2_o       : out   std_logic;
      mipi_tx_hs_d1_o       : out   std_logic;
      mipi_tx_hs_d0_o       : out   std_logic;
      mipi_tx_lp_clk_io     : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d3_io      : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d2_io      : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d1_io      : inout std_logic_vector(1 downto 0);
      mipi_tx_lp_d0_io      : inout std_logic_vector(1 downto 0)
    );
  end component xilinx_mipi_tx_ip_2l;


  ------------------------
  -- MIPI TX Register Bank
  component mipi_tx_reg_bank is
    generic (
      -- FEATURES Register
      FEATURES_PADDING_PRESENT_DEFAULT         : std_logic_vector(1-1 downto 0) := "0";
      FEATURES_FIXED_FRAME_PRESENT_DEFAULT     : std_logic_vector(1-1 downto 0) := "0";

      -- AXI generics
      C_S_AXI_DATA_WIDTH                       : integer  := 32;
      C_S_AXI_ADDR_WIDTH                       : integer  := 32
    );
    port (
      -- CONTROL Register
      cfg_control_enable_o                     : out  std_logic_vector(1-1 downto 0);
      cfg_control_enable_packet_timeout_o      : out  std_logic_vector(1-1 downto 0);
      cfg_control_blocking_mode_o              : out  std_logic_vector(1-1 downto 0);
      cfg_control_padding_bypass_o             : out  std_logic_vector(1-1 downto 0);
      -- DATA_IDENTIFIER Register
      cfg_data_identifier_data_type_o          : out  std_logic_vector(6-1 downto 0);
      cfg_data_identifier_virtual_channel_o    : out  std_logic_vector(2-1 downto 0);
      -- FRAME_PERIOD Register
      cfg_frame_period_value_us_o              : out  std_logic_vector(16-1 downto 0);
      -- PACKET_TIMEOUT Register
      cfg_packet_timeout_value_us_o            : out  std_logic_vector(16-1 downto 0);
      -- PACKET_SIZE Register
      cfg_packet_size_value_o                  : out  std_logic_vector(14-1 downto 0);
      -- START_TIME Register
      cfg_start_time_value_o                   : out  std_logic_vector(16-1 downto 0);
      -- START_FRAME_TIME Register
      cfg_start_frame_time_value_o             : out  std_logic_vector(16-1 downto 0);
      -- END_FRAME_TIME Register
      cfg_end_frame_time_value_o               : out  std_logic_vector(16-1 downto 0);
      -- INTER_FRAME_TIME Register
      cfg_inter_frame_time_value_o             : out  std_logic_vector(16-1 downto 0);
      -- INTER_PACKET_TIME Register
      cfg_inter_packet_time_value_o            : out  std_logic_vector(16-1 downto 0);

      -- AXI LITE port in/out signals
      s_axi_aclk                               : in   std_logic;
      s_axi_aresetn                            : in   std_logic;
      s_axi_awaddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awprot                             : in   std_logic_vector(2 downto 0);
      s_axi_awvalid                            : in   std_logic;
      s_axi_awready                            : out  std_logic;
      s_axi_wdata                              : in   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb                              : in   std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
      s_axi_wvalid                             : in   std_logic;
      s_axi_wready                             : out  std_logic;
      s_axi_bresp                              : out  std_logic_vector(1 downto 0);
      s_axi_bvalid                             : out  std_logic;
      s_axi_bready                             : in   std_logic;
      s_axi_araddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arprot                             : in   std_logic_vector(2 downto 0);
      s_axi_arvalid                            : in   std_logic;
      s_axi_arready                            : out  std_logic;
      s_axi_rdata                              : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp                              : out  std_logic_vector(1 downto 0);
      s_axi_rvalid                             : out  std_logic;
      s_axi_rready                             : in   std_logic
    );
  end component mipi_tx_reg_bank;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Derived Clock and Reset Signals
  signal rst_s                                   : std_logic;

  -- Configuration Signals
  signal cfg_enable_s                            : std_logic;

  -- Configuration Interface
  signal tx_reg_bank_cfg_enable_s                : std_logic_vector(0 downto 0);
  signal tx_reg_bank_cfg_enable_packet_timeout_s : std_logic_vector(0 downto 0);
  signal tx_reg_bank_cfg_virtual_channel_s       : std_logic_vector(1 downto 0);
  signal tx_reg_bank_cfg_data_type_s             : std_logic_vector(5 downto 0);
  signal tx_reg_bank_cfg_frame_period_us_s       : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_packet_timeout_us_s     : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_packet_size_s           : std_logic_vector(13 downto 0);
  signal tx_reg_bank_cfg_start_time_s            : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_start_frame_time_s      : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_end_frame_time_s        : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_inter_frame_time_s      : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_inter_packet_time_s     : std_logic_vector(15 downto 0);
  signal tx_reg_bank_cfg_blocking_mode_s         : std_logic_vector(0 downto 0);
  signal tx_reg_bank_cfg_padding_bypass_s        : std_logic_vector(0 downto 0);

  -- Input interface
  signal tx_fifo_wr_ready_s                      : std_logic;
  signal tx_fifo_wr_valid_s                      : std_logic;
  signal tx_fifo_wr_first_s                      : std_logic;
  signal tx_fifo_wr_last_s                       : std_logic;
  signal tx_fifo_wr_data_s                       : ccam_evt_data_t;

  -- Output interface
  signal tx_fifo_rd_ready_s                      : std_logic;
  signal tx_fifo_rd_valid_s                      : std_logic;
  signal tx_fifo_rd_first_s                      : std_logic;
  signal tx_fifo_rd_last_s                       : std_logic;
  signal tx_fifo_rd_data_s                       : ccam_evt_data_t;

  -- MIPI TX Generic IP Interface
  signal tx_ctrl_mipi_tx_ready_s                 : std_logic;
  signal tx_ctrl_mipi_tx_valid_s                 : std_logic;
  signal tx_ctrl_mipi_tx_frame_start_s           : std_logic;
  signal tx_ctrl_mipi_tx_frame_end_s             : std_logic;
  signal tx_ctrl_mipi_tx_packet_start_s          : std_logic;
  signal tx_ctrl_mipi_tx_packet_end_s            : std_logic;
  signal tx_ctrl_mipi_tx_virtual_channel_s       : std_logic_vector(1 downto 0);
  signal tx_ctrl_mipi_tx_data_type_s             : std_logic_vector(5 downto 0);
  signal tx_ctrl_mipi_tx_word_count_s            : std_logic_vector(15 downto 0);
  signal tx_ctrl_mipi_tx_data_s                  : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0);

  -- MIPI Parallel Interface
  signal tx_if_out_short_en_s                    : std_logic;                                    -- Frame Valid input for parallel interface
  signal tx_if_out_long_en_s                     : std_logic;                                    -- Line Valid input for parallel interface
  signal tx_if_out_crc_rst_s                     : std_logic;                                    -- Reset the CRC data calculation
  signal tx_if_out_data_s                        : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0); -- Pixel data bus for parallel interface
  signal tx_if_out_vc_s                          : std_logic_vector(1 downto 0);                 -- 2-bit Virtual Channel Number
  signal tx_if_out_dt_s                          : std_logic_vector(5 downto 0);                 -- 6-bit Data Type
  signal tx_if_out_wc_s                          : std_logic_vector(15 downto 0);                -- 16-bit Word Count in byte packets.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Derived Clock and Reset Signals
  rst_s <= (not arst_n) or srst;

  -- Configuration Signals
  cfg_enable_s       <= cfg_enable_i when (USE_EXT_ENABLE) else
                        tx_reg_bank_cfg_enable_s(0);

  -- MIPI CSI2 TX Interface for Verification
  mipi_tx_if_clk_o   <= clk;
  mipi_tx_if_rst_o   <= rst_s;
  mipi_tx_if_valid_o <= tx_if_out_long_en_s;
  mipi_tx_if_data_o  <= tx_if_out_data_s;

  ------------------------------
  -- Component instantiations --
  ------------------------------


  --------------------------------------
  -- Events to MIPI Packet Control Block
  -- for a MIPI CSI2 TX IP
  tx_ctrl_u : mipi_tx_control
  generic map (
    EVT30_SUPPORT         => EVT30_SUPPORT,
    FIXED_FRAME_SIZE_G    => FIXED_FRAME_SIZE_G,
    MIPI_PADDING_ENABLE_G => MIPI_PADDING_ENABLE_C,
    MIPI_DATA_WIDTH       => MIPI_DATA_WIDTH,
    MIPI_MAX_PACKET_SIZE  => MIPI_MAX_PACKET_SIZE, -- Max. number of bytes in MIPI packet. Default 16KB.
    TIME_HIGH_PERIOD      => TIME_HIGH_PERIOD,
    RAW_MODE_SUPPORT_G    => RAW_MODE_SUPPORT_G
  )
  port map (
    -- Core clock and reset
    clk                           => clk,
    arst_n                        => arst_n,
    srst                          => srst,

    -- Configuration Interface
    cfg_enable_i                  => cfg_enable_s,
    cfg_enable_packet_timeout_i   => tx_reg_bank_cfg_enable_packet_timeout_s(0),
    cfg_evt_format_i              => cfg_evt_format_i,
    cfg_virtual_channel_i         => tx_reg_bank_cfg_virtual_channel_s,
    cfg_data_type_i               => tx_reg_bank_cfg_data_type_s,
    cfg_frame_period_us_i         => tx_reg_bank_cfg_frame_period_us_s,
    cfg_packet_timeout_us_i       => tx_reg_bank_cfg_packet_timeout_us_s,
    cfg_packet_size_i             => tx_reg_bank_cfg_packet_size_s,
    cfg_evt_time_high_sync_i      => cfg_evt_time_high_sync_i,
    cfg_blocking_mode_i           => tx_reg_bank_cfg_blocking_mode_s(0),
    cfg_padding_bypass_i          => tx_reg_bank_cfg_padding_bypass_s(0),

    -- Event Input Interface
    evt_in_ready_o                => evt_in_ready_o,
    evt_in_valid_i                => evt_in_valid_i,
    evt_in_first_i                => evt_in_first_i,
    evt_in_last_i                 => evt_in_last_i,
    evt_in_data_i                 => evt_in_data_i,

    -- MIPI TX FIFO Write Interface
    fifo_wr_ready_i               => tx_fifo_wr_ready_s,
    fifo_wr_valid_o               => tx_fifo_wr_valid_s,
    fifo_wr_first_o               => tx_fifo_wr_first_s,
    fifo_wr_last_o                => tx_fifo_wr_last_s,
    fifo_wr_data_o                => tx_fifo_wr_data_s,

    -- MIPI TX FIFO Read Interface
    fifo_rd_ready_o               => tx_fifo_rd_ready_s,
    fifo_rd_valid_i               => tx_fifo_rd_valid_s,
    fifo_rd_first_i               => tx_fifo_rd_first_s,
    fifo_rd_last_i                => tx_fifo_rd_last_s,
    fifo_rd_data_i                => tx_fifo_rd_data_s,

    -- MIPI RX Flow CONTROL
    mipi_rx_ready_i               => mipi_rx_ready_i,

    -- MIPI TX Generic IP Interface
    mipi_tx_ready_i               => tx_ctrl_mipi_tx_ready_s,
    mipi_tx_valid_o               => tx_ctrl_mipi_tx_valid_s,
    mipi_tx_frame_start_o         => tx_ctrl_mipi_tx_frame_start_s,
    mipi_tx_frame_end_o           => tx_ctrl_mipi_tx_frame_end_s,
    mipi_tx_packet_start_o        => tx_ctrl_mipi_tx_packet_start_s,
    mipi_tx_packet_end_o          => tx_ctrl_mipi_tx_packet_end_s,
    mipi_tx_virtual_channel_o     => tx_ctrl_mipi_tx_virtual_channel_s,
    mipi_tx_data_type_o           => tx_ctrl_mipi_tx_data_type_s,
    mipi_tx_word_count_o          => tx_ctrl_mipi_tx_word_count_s,
    mipi_tx_data_o                => tx_ctrl_mipi_tx_data_s
  );


  --------------------
  -- MIPI CSI2 TX FIFO
  tx_fifo_u : mipi_tx_fifo
  generic map (
    DATA_WIDTH => MIPI_TX_FIFO_DATA_WIDTH,
    DEPTH      => MIPI_TX_FIFO_DEPTH
  )
  port map (
    -- Core clock and reset
    clk              => clk,
    arst_n           => arst_n,
    srst             => srst,

    -- Configuration Interface
    cfg_evt_format_i => cfg_evt_format_i,

    -- Input interface
    in_ready_o       => tx_fifo_wr_ready_s,
    in_valid_i       => tx_fifo_wr_valid_s,
    in_first_i       => tx_fifo_wr_first_s,
    in_last_i        => tx_fifo_wr_last_s,
    in_data_i        => tx_fifo_wr_data_s,

    -- Output interface
    out_ready_i      => tx_fifo_rd_ready_s,
    out_valid_o      => tx_fifo_rd_valid_s,
    out_first_o      => tx_fifo_rd_first_s,
    out_last_o       => tx_fifo_rd_last_s,
    out_data_o       => tx_fifo_rd_data_s
  );


  --------------------------------------
  -- Events to MIPI Packet Control Block
  -- for a MIPI CSI2 TX IP
  tx_if_u : lattice_mipi_tx_packet_if
  generic map (
    MIPI_DATA_WIDTH   => MIPI_DATA_WIDTH,
    CLK_FREQ          => CLK_FREQ,
    USE_FRAME_COUNT_G => USE_FRAME_COUNT_G
  )
  port map (
    -- Core clock and reset
    clk                     => clk,
    arst_n                  => arst_n,
    srst                    => srst,

    -- Configuration Interface
    cfg_enable_i            => cfg_enable_s,
    cfg_start_time_i        => tx_reg_bank_cfg_start_time_s,
    cfg_start_frame_time_i  => tx_reg_bank_cfg_start_frame_time_s,
    cfg_end_frame_time_i    => tx_reg_bank_cfg_end_frame_time_s,
    cfg_inter_frame_time_i  => tx_reg_bank_cfg_inter_frame_time_s,
    cfg_inter_packet_time_i => tx_reg_bank_cfg_inter_packet_time_s,

    -- MIPI TX Generic IP Input Interface
    txi_ready_o             => tx_ctrl_mipi_tx_ready_s,
    txi_valid_i             => tx_ctrl_mipi_tx_valid_s,
    txi_frame_start_i       => tx_ctrl_mipi_tx_frame_start_s,
    txi_frame_end_i         => tx_ctrl_mipi_tx_frame_end_s,
    txi_packet_start_i      => tx_ctrl_mipi_tx_packet_start_s,
    txi_packet_end_i        => tx_ctrl_mipi_tx_packet_end_s,
    txi_virtual_channel_i   => tx_ctrl_mipi_tx_virtual_channel_s,
    txi_data_type_i         => tx_ctrl_mipi_tx_data_type_s,
    txi_word_count_i        => tx_ctrl_mipi_tx_word_count_s,
    txi_data_i              => tx_ctrl_mipi_tx_data_s,

    -- Lattice's MIPI IP Parallel Interface
    txo_short_en_o          => tx_if_out_short_en_s, -- Frame Valid input for parallel interface
    txo_long_en_o           => tx_if_out_long_en_s,  -- Line Valid input for parallel interface
    txo_crc_rst_o           => tx_if_out_crc_rst_s,  -- Reset the CRC data calculation
    txo_data_o              => tx_if_out_data_s,     -- Pixel data bus for parallel interface
    txo_vc_o                => tx_if_out_vc_s,       -- 2-bit Virtual Channel Number
    txo_dt_o                => tx_if_out_dt_s,       -- 6-bit Data Type
    txo_wc_o                => tx_if_out_wc_s        -- 16-bit Word Count in byte packets.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels
  );


  --------------------------------------
  ---- Xilinx MIPI CSI2 TX IP - 2 lanes
  tx_ip_u : xilinx_mipi_tx_ip_2l
  generic map (
    DATA_WIDTH            => MIPI_DATA_WIDTH, -- Pixel Bus Width.  Example: RGB888 = 8-bits Red, 8-bits Green, 8-bits Blue = 24 bits/pixel
    DATA_TYPE             => MIPI_DATA_TYPE,  -- 6-bit MIPI CSI2 Data Type.  Example: DT = 6'h2B = RAW10; DT = 6'h30 = USER DEFINED.
    TEST_MODE             => MIPI_TEST_MODE,  -- Adds a color bar pattern generator for testing purposes.  Operates from input clock and reset_n inputs.
    CRC16                 => MIPI_USE_CRC16,  -- Appends 16-bit checksum to the end of long packet transfers.  0 = off, 1 = on.  Turning off will append 16'hFFFF to end of long packet.  Turning off will reduce resource utilization.
    FPGA_FAMILY_G         => FPGA_FAMILY_G
  )
  port map (
    -- Core clock and reset
    clk                   => clk,
    arst_n                => arst_n,
    srst                  => srst,
    hs_clk                => hs_clk,
    hs_arst_n             => hs_arst_n,
    hs_srst               => hs_srst,

    -- Lattice's MIPI IP Parallel Interface
    txi_short_en_i        => tx_if_out_short_en_s,   -- Short Packet Enable for Frame Start and Frame End
    txi_long_en_i         => tx_if_out_long_en_s,    -- Long Packet Enable for Data Payload Packets
    txi_crc_rst_i         => tx_if_out_crc_rst_s,    -- Reset the CRC data calculation
    txi_data_i            => tx_if_out_data_s,       -- Long Packet Input Data Interface
    txi_vc_i              => tx_if_out_vc_s,         -- 2-bit Long Packet Virtual Channel Number
    txi_dt_i              => tx_if_out_dt_s,         -- 6-bit Long Packet Data Type
    txi_wc_i              => tx_if_out_wc_s,         -- 16-bit Long Packet Word Count in Bytes.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels

    -- I/O control
    io_ctrl_clk_en_o      => io_ctrl_clk_en_o,       -- MIPI TX Tristate IO Controllers for Clock Lane
    io_ctrl_d1_en_o       => io_ctrl_d1_en_o,        -- MIPI TX Tristate IO Controllers for D1 Lane
    io_ctrl_d0_en_o       => io_ctrl_d0_en_o,        -- MIPI TX Tristate IO Controllers for D0 Lane

    -- MIPI CSI2 TX interface (host_if_clk domain)
    mipi_tx_hs_clk_o      => mipi_tx_hs_clk_o,
    mipi_tx_hs_d3_o       => mipi_tx_hs_d3_o,
    mipi_tx_hs_d2_o       => mipi_tx_hs_d2_o,
    mipi_tx_hs_d1_o       => mipi_tx_hs_d1_o,
    mipi_tx_hs_d0_o       => mipi_tx_hs_d0_o,
    mipi_tx_lp_clk_io     => mipi_tx_lp_clk_io,
    mipi_tx_lp_d3_io      => mipi_tx_lp_d3_io,
    mipi_tx_lp_d2_io      => mipi_tx_lp_d2_io,
    mipi_tx_lp_d1_io      => mipi_tx_lp_d1_io,
    mipi_tx_lp_d0_io      => mipi_tx_lp_d0_io
  );


  ------------------------
  -- MIPI TX Register Bank
  mipi_tx_reg_bank_u : mipi_tx_reg_bank
  generic map(
    C_S_AXI_DATA_WIDTH => BUS_ADDR_WIDTH,
    C_S_AXI_ADDR_WIDTH => BUS_DATA_WIDTH,

    -- FEATURES Register
    FEATURES_PADDING_PRESENT_DEFAULT     => MIPI_PADDING_PRESENT_C,
    FEATURES_FIXED_FRAME_PRESENT_DEFAULT => MIPI_FIXED_FRAME_PRESENT_C
  )
  port map(
    -- Clock and Reset
    s_axi_aclk                            => s_axi_aclk,      
    s_axi_aresetn                         => s_axi_aresetn,   

    -- AXI LITE port in/out signals
    s_axi_awaddr                          => s_axi_awaddr,    
    s_axi_awprot                          => s_axi_awprot,    
    s_axi_awvalid                         => s_axi_awvalid,   
    s_axi_awready                         => s_axi_awready,   
    s_axi_wdata                           => s_axi_wdata,     
    s_axi_wstrb                           => s_axi_wstrb,     
    s_axi_wvalid                          => s_axi_wvalid,    
    s_axi_wready                          => s_axi_wready,    
    s_axi_bresp                           => s_axi_bresp,     
    s_axi_bvalid                          => s_axi_bvalid,    
    s_axi_bready                          => s_axi_bready,    
    s_axi_araddr                          => s_axi_araddr,    
    s_axi_arprot                          => s_axi_arprot,    
    s_axi_arvalid                         => s_axi_arvalid,   
    s_axi_arready                         => s_axi_arready,   
    s_axi_rdata                           => s_axi_rdata,     
    s_axi_rresp                           => s_axi_rresp,     
    s_axi_rvalid                          => s_axi_rvalid,    
    s_axi_rready                          => s_axi_rready,    

    -- Register Configuration and Status Interface

    -- CONTROL Register
    cfg_control_enable_o                  => tx_reg_bank_cfg_enable_s,
    cfg_control_enable_packet_timeout_o   => tx_reg_bank_cfg_enable_packet_timeout_s,
    cfg_control_blocking_mode_o           => tx_reg_bank_cfg_blocking_mode_s,
    cfg_control_padding_bypass_o          => tx_reg_bank_cfg_padding_bypass_s,

    -- DATA_IDENTIFIER Register
    cfg_data_identifier_data_type_o       => tx_reg_bank_cfg_data_type_s,
    cfg_data_identifier_virtual_channel_o => tx_reg_bank_cfg_virtual_channel_s,

    -- FRAME_PERIOD Register
    cfg_frame_period_value_us_o           => tx_reg_bank_cfg_frame_period_us_s,

    -- PACKET_TIMEOUT Register
    cfg_packet_timeout_value_us_o         => tx_reg_bank_cfg_packet_timeout_us_s,

    -- PACKET_SIZE Register
    cfg_packet_size_value_o               => tx_reg_bank_cfg_packet_size_s,

    -- START_TIME Register
    cfg_start_time_value_o                => tx_reg_bank_cfg_start_time_s,

    -- START_FRAME_TIME Register
    cfg_start_frame_time_value_o          => tx_reg_bank_cfg_start_frame_time_s,

    -- END_FRAME_TIME Register
    cfg_end_frame_time_value_o            => tx_reg_bank_cfg_end_frame_time_s,

    -- INTER_FRAME_TIME Register
    cfg_inter_frame_time_value_o          => tx_reg_bank_cfg_inter_frame_time_s,

    -- INTER_PACKET_TIME Register
    cfg_inter_packet_time_value_o         => tx_reg_bank_cfg_inter_packet_time_s
  );


end rtl;
