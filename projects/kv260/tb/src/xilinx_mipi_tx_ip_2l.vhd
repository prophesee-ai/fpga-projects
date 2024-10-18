-- Copyright (c) Prophesee S.A.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


------------------------------------
-- Xilinx MIPI CSI2 TX IP - 2 lanes
entity xilinx_mipi_tx_ip_2l is
  generic (
    DATA_WIDTH             : positive := 16;     -- Pixel Bus Width.  Example: RGB888 = 8-bits Red, 8-bits Green, 8-bits Blue = 24 bits/pixel
    DATA_TYPE              : integer  := 16#30#; -- 6-bit MIPI CSI2 Data Type.  Example: DT = 6'h2B = RAW10; DT = 6'h30 = USER DEFINED.
    TEST_MODE              : boolean  := false;  -- Adds a color bar pattern generator for testing purposes.  Operates from input clock and reset_n inputs.
    CRC16                  : boolean  := true;   -- Appends 16-bit checksum to the end of long packet transfers.  0 = off, 1 = on.  Turning off will append 16'hFFFF to end of long packet.  Turning off will reduce resource utilization.
    RESERVED               : boolean  := false;  -- RESERVED = 0 at all times.
    FPGA_FAMILY_G          : string              -- "7SERIES", "ULTRASCALE_PLUS"
  );
  port (
    -- Core clock and reset
    clk                    : in    std_logic;
    arst_n                 : in    std_logic;
    srst                   : in    std_logic;
    hs_clk                 : in    std_logic;                               -- HS Clock
    hs_arst_n              : in    std_logic;
    hs_srst                : in    std_logic;

    -- MIPI Parallel Interface
    txi_short_en_i         : in    std_logic;                               -- Short Packet Enable for Frame Start and Frame End
    txi_long_en_i          : in    std_logic;                               -- Long Packet Enable for Data Payload Packets
    txi_crc_rst_i          : in    std_logic;                               -- Reset the CRC data calculation
    txi_data_i             : in    std_logic_vector(DATA_WIDTH-1 downto 0); -- Long Packet Input Data Interface
    txi_vc_i               : in    std_logic_vector(1 downto 0);            -- 2-bit Long Packet Virtual Channel Number
    txi_dt_i               : in    std_logic_vector(5 downto 0);            -- 6-bit Long Packet Data Type
    txi_wc_i               : in    std_logic_vector(15 downto 0);           -- 16-bit Long Packet Word Count in Bytes.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels

    -- I/O control
    io_ctrl_clk_en_o       : out   std_logic;                               -- MIPI TX Tristate IO Controllers for Clock Lane
    io_ctrl_d1_en_o        : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D1 Lane
    io_ctrl_d0_en_o        : out   std_logic;                               -- MIPI TX Tristate IO Controllers for D0 Lane

    -- MIPI CSI2 TX Interface
    mipi_tx_hs_clk_o       : out   std_logic;
    mipi_tx_hs_d3_o        : out   std_logic;
    mipi_tx_hs_d2_o        : out   std_logic;
    mipi_tx_hs_d1_o        : out   std_logic;
    mipi_tx_hs_d0_o        : out   std_logic;
    mipi_tx_lp_clk_io      : inout std_logic_vector(1 downto 0);
    mipi_tx_lp_d3_io       : inout std_logic_vector(1 downto 0);
    mipi_tx_lp_d2_io       : inout std_logic_vector(1 downto 0);
    mipi_tx_lp_d1_io       : inout std_logic_vector(1 downto 0);
    mipi_tx_lp_d0_io       : inout std_logic_vector(1 downto 0)
  );
end xilinx_mipi_tx_ip_2l;

architecture rtl of xilinx_mipi_tx_ip_2l is


  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant LANE_WIDTH_C        : integer                       := 2;
  constant CRC_POLY_C          : std_logic_vector(15 downto 0) := "1000010000001000";
  constant LP_HS_DEFAULT_DLY_C : std_logic_vector(15 downto 0) := x"0006";
  constant FRAME_START_TYPE_C  : std_logic_vector(5 downto 0)  := "000000";
  constant FRAME_END_TYPE_C    : std_logic_vector(5 downto 0)  := "000001";
  constant LP_DIR_OUTPUT_C     : std_logic                     := '1';

  -- MIPI CSI TX Delay parameters
  constant LP01CLK_DLY         : natural range 0 to 65535 := 16#0007#;
  constant LP00CLK_DLY         : natural range 0 to 65535 := 16#0006#;
  constant HS00CLK_DLY         : natural range 0 to 65535 := 16#0018#;
  constant HSXXCLK_DLY         : natural range 0 to 65535 := 16#0002#;
  constant CLK2DATA_DLY        : natural range 0 to 65535 := 16#0002#;
  constant LP01DATA_DLY        : natural range 0 to 65535 := 16#0006#;
  constant LP00DATA_DLY        : natural range 0 to 65535 := 16#0006#;
  constant HS00DATA_DLY        : natural range 0 to 65535 := 16#0009#;
  constant HSXXDATA_DLY        : natural range 0 to 65535 := 16#0000#;
  constant HSTRAILDATA_DLY     : natural range 0 to 65535 := 16#000A#;
  constant HS00DATAEND_DLY     : natural range 0 to 65535 := 16#0000#;
  constant LP00DATAEND_DLY     : natural range 0 to 65535 := 16#0001#;
  constant CLK2DATAEND_DLY     : natural range 0 to 65535 := 16#000F#;
  constant HS00CLKEND_DLY      : natural range 0 to 65535 := 16#0009#;
  constant LP00CLKEND_DLY      : natural range 0 to 65535 := 16#0001#;


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ----------------------------------------------
  -- MIPI CSI-2 TX Packetheader
  component mipi_csi_tx_packetheader is
    generic (
      LANE_WIDTH_G      : positive range 1 to 4
    );
    port (
      -- Core clock and reset
      clk               : in  std_logic;
      arst_n            : in  std_logic;
      srst              : in  std_logic;

      -- Input configuration interface
      cfg_short_en_i    : in  std_logic;
      cfg_long_en_i     : in  std_logic;
      cfg_byte_data_i   : in  std_logic_vector(31 downto 0);
      cfg_virt_chan_i   : in  std_logic_vector( 1 downto 0);
      cfg_data_type_i   : in  std_logic_vector( 5 downto 0);
      cfg_word_cnt_i    : in  std_logic_vector(15 downto 0);
      cfg_chksum_rdy_i  : in  std_logic;
      cfg_chksum_i      : in  std_logic_vector(15 downto 0);

      -- Packet header interface
      ph_eotp_i        : in  std_logic;
      ph_bytepkt_en_o  : out std_logic;
      ph_bytepkt_o     : out std_logic_vector(31 downto 0)
    );
  end component mipi_csi_tx_packetheader;


  ----------------------------------------------
  -- MIPI CSI-2 TX CRC16 2 Lanes
  component crc16_2lane is
    generic(
      CRC_POLY_G     : std_logic_vector(15 downto 0)
    );
    port (
      -- Core clock and reset
      clk            : in  std_logic;
      arst_n         : in  std_logic;
      srst           : in  std_logic;

      -- Input interface
      cfg_enable_i   : in  std_logic;
      in_data_i      : in  std_logic_vector(15 downto 0);

      -- Output interface
      out_ready_o    : out std_logic;
      out_crc_o      : out std_logic_vector(15 downto 0)
    );
  end component crc16_2lane;


  ----------------------------------------------
  -- MIPI CSI-2 TX delay control
  component mipi_csi_tx_delay_ctrl is
    generic (
      LP01CLK_DLY_G       : natural range 0 to 65535;
      LP00CLK_DLY_G       : natural range 0 to 65535;
      HS00CLK_DLY_G       : natural range 0 to 65535;
      HSXXCLK_DLY_G       : natural range 0 to 65535;
      CLK2DATA_DLY_G      : natural range 0 to 65535;
      LP01DATA_DLY_G      : natural range 0 to 65535;
      LP00DATA_DLY_G      : natural range 0 to 65535;
      HS00DATA_DLY_G      : natural range 0 to 65535;
      HSXXDATA_DLY_G      : natural range 0 to 65535;
      HSTRAILDATA_DLY_G   : natural range 0 to 65535;
      HS00DATAEND_DLY_G   : natural range 0 to 65535;
      LP00DATAEND_DLY_G   : natural range 0 to 65535;
      CLK2DATAEND_DLY_G   : natural range 0 to 65535;
      HS00CLKEND_DLY_G    : natural range 0 to 65535;
      LP00CLKEND_DLY_G    : natural range 0 to 65535
    );
    port (
      -- Core clock and reset
      clk                 : in  std_logic;
      arst_n              : in  std_logic;
      srst                : in  std_logic;

      -- Input bytes per lane
      in_hs_en_i          : in  std_logic;
      in_byte_l3_i        : in  std_logic_vector(7 downto 0);
      in_byte_l2_i        : in  std_logic_vector(7 downto 0);
      in_byte_l1_i        : in  std_logic_vector(7 downto 0);
      in_byte_l0_i        : in  std_logic_vector(7 downto 0);

      -- Output bytes per lane
      out_hsxx_clk_en_o   : out std_logic;
      out_hs_clk_en_o     : out std_logic;
      out_hs_data_en_o    : out std_logic;
      out_lp_clk_o        : out std_logic_vector(1 downto 0);
      out_lp_data_o       : out std_logic_vector(1 downto 0);
      out_byte_l3_o       : out std_logic_vector(7 downto 0);
      out_byte_l2_o       : out std_logic_vector(7 downto 0);
      out_byte_l1_o       : out std_logic_vector(7 downto 0);
      out_byte_l0_o       : out std_logic_vector(7 downto 0)
    );
  end component mipi_csi_tx_delay_ctrl;


  ----------------------------------------------
  -- MIPI DPHY TX Output Serdes Layer
  component mipi_csi_tx_dphy is
    generic (
      LANE_WIDTH_G          : positive range 1 to 4;
      FPGA_FAMILY_G         : string                                               -- "7SERIES", "ULTRASCALE_PLUS"
    );
    port (
      -- Clocks and resets
      core_rst_i            : in    std_logic;                                     -- Core reset
      core_clk_i            : in    std_logic;                                     -- Clock synchronous with the parallel data to serialize
      hs_clk_i              : in    std_logic;                                     -- HS Clock input
      hs_clk_o              : out   std_logic;                                     -- HS Clock output

      -- High speed data enable and I/O buffer tristate control
      hs_clk_en_i           : in    std_logic;                                     -- HS (High Speed) Clock Enable
      hs_data_en_i          : in    std_logic;                                     -- HS (High Speed) Data Enable
      hs_clk_tri_ctl_o      : out   std_logic;                                     -- MIPI TX Tristate IO controllers
      hs_data_tri_ctl_o     : out   std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- MIPI TX Tristate IO controllers

      -- High speed CSI interface
      hs_byte_data_i        : in    std_logic_vector((8*LANE_WIDTH_G)-1 downto 0); -- HS (High Speed) Byte Data
      hs_data_o             : out   std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- HS (High Speed) Data Lane

      -- Low power interface
      lp_clk_io             : inout std_logic_vector(1 downto 0);                  -- LP (Low Power) External Interface Signals for Clock Lane
      lp_clk_dir_i          : in    std_logic;                                     -- LP (Low Power) Data Receive/Transmit Control for Clock Lane
      lp_clk_i              : in    std_logic_vector(1 downto 0);                  -- LP (Low Power) Data Receiving Signals for Clock Lane
      lp_clk_o              : out   std_logic_vector(1 downto 0);                  -- LP (Low Power) Data Transmitting Signals for Clock Lane
      lp_dx_io              : inout std_logic_vector((2*LANE_WIDTH_G)-1 downto 0); -- LP (Low Power) External Interface Signals for Data Lane
      lp_dx_dir_i           : in    std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- LP (Low Power) Data Receive/Transmit Control for Data Lane
      lp_dx_i               : in    std_logic_vector((2*LANE_WIDTH_G)-1 downto 0); -- LP (Low Power) Data Receiving Signals for Data Lane
      lp_dx_o               : out   std_logic_vector((2*LANE_WIDTH_G)-1 downto 0)  -- LP (Low Power) Data Transmitting Signals for Data Lane
    );
  end component;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Clock and Reset Signals
  signal rst_s                         : std_logic;
  signal rst_n_s                       : std_logic;
  signal hs_rst_s                      : std_logic;
  signal hs_rst_n_s                    : std_logic;

  -- MIPI IP Parallel Interface
  signal txi_data_s                    : std_logic_vector(31 downto 0); -- Long Packet Input Data Interface

  -- Packet Header IP Signals
  signal packet_header_bytepkt_en_s    : std_logic;
  signal packet_header_bytepkt_s       : std_logic_vector(31 downto 0);

  -- CRC16 IP Signals
  signal crc16_rst_s                   : std_logic;
  signal crc16_chksum_rdy_s            : std_logic;
  signal crc16_chksum_s                : std_logic_vector(15 downto 0);

  -- LP/HS Delay Control IP
  signal delay_ctrl_hsxx_clk_en_s      : std_logic;
  signal delay_ctrl_hs_clk_en_s        : std_logic;
  signal delay_ctrl_hs_data_en_s       : std_logic;
  signal delay_ctrl_lp_clk_s           : std_logic_vector(1 downto 0);
  signal delay_ctrl_lp_data_s          : std_logic_vector(1 downto 0);
  signal delay_ctrl_byte_out_s         : std_logic_vector(31 downto 0);

  -- DPHY Control Signals
  signal dphy_tx_mipi_hs_clk_tri_ctl_s : std_logic; -- MIPI TX Tristate IO controllers
  signal dphy_tx_mipi_hs_d1_tri_ctl_s  : std_logic; -- MIPI TX Tristate IO controllers
  signal dphy_tx_mipi_hs_d0_tri_ctl_s  : std_logic; -- MIPI TX Tristate IO controllers
  signal dphy_tx_lp_dx_dir_s           : std_logic_vector((LANE_WIDTH_C)-1 downto 0);
  signal dphy_tx_lp_dx_i_s             : std_logic_vector((2*LANE_WIDTH_C)-1 downto 0);


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Clock and Reset Signals
  rst_s       <= (not arst_n) or srst;
  rst_n_s     <= not rst_s;
  hs_rst_s    <= (not hs_arst_n) or hs_srst;
  hs_rst_n_s  <= not hs_rst_s;

  -- MIPI Parallel Interface
  txi_data_s(DATA_WIDTH-1    downto 0         ) <= txi_data_i;
  txi_data_s(txi_data_s'high downto DATA_WIDTH) <= (others => '0');

  -- CRC16 IP Signals
  crc16_rst_s <= rst_s or txi_crc_rst_i;

  -- MIPI CSI2 TX IP - DPHY TX IP
  mipi_tx_hs_d3_o     <= '0';
  mipi_tx_hs_d2_o     <= '0';
  mipi_tx_lp_d3_io    <= (others => '0');
  mipi_tx_lp_d2_io    <= (others => '0');
  dphy_tx_lp_dx_dir_s <= (others => LP_DIR_OUTPUT_C);
  dphy_tx_lp_dx_i_s   <= delay_ctrl_lp_data_s & delay_ctrl_lp_data_s;

  -- I/O Control
  io_ctrl_clk_en_o    <= not dphy_tx_mipi_hs_clk_tri_ctl_s; -- MIPI TX Tristate IO controllers
  io_ctrl_d1_en_o     <= not dphy_tx_mipi_hs_d1_tri_ctl_s;  -- MIPI TX Tristate IO controllers
  io_ctrl_d0_en_o     <= not dphy_tx_mipi_hs_d0_tri_ctl_s;  -- MIPI TX Tristate IO controllers


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ----------------------------------------------
  -- MIPI CSI-2 TX Packetheader
  packetheader_u : mipi_csi_tx_packetheader
    generic map (
      LANE_WIDTH_G      => LANE_WIDTH_C
    )
    port map (
      -- Core clock and reset
      clk               => clk,
      arst_n            => arst_n,
      srst              => srst,

      -- Input configuration interface
      cfg_short_en_i    => txi_short_en_i,
      cfg_long_en_i     => txi_long_en_i,
      cfg_byte_data_i   => txi_data_s,
      cfg_virt_chan_i   => txi_vc_i,
      cfg_data_type_i   => txi_dt_i,
      cfg_word_cnt_i    => txi_wc_i,
      cfg_chksum_rdy_i  => crc16_chksum_rdy_s,
      cfg_chksum_i      => crc16_chksum_s,

      -- Packet header interface
      ph_eotp_i        => '0',
      ph_bytepkt_en_o  => packet_header_bytepkt_en_s,
      ph_bytepkt_o     => packet_header_bytepkt_s
    );


  ----------------------------------------------
  -- MIPI CSI-2 TX CRC16 2 Lanes
  crc16_u : crc16_2lane
    generic map (
      CRC_POLY_G          => CRC_POLY_C
    )
    port map (
      -- Core clock and reset
      clk                 => clk,
      arst_n              => arst_n,
      srst                => crc16_rst_s,

      -- Input interface
      cfg_enable_i        => txi_long_en_i,
      in_data_i           => txi_data_i,

      -- Output interface
      out_ready_o         => crc16_chksum_rdy_s,
      out_crc_o           => crc16_chksum_s
    );

  ----------------------------------------------
  -- MIPI CSI-2 TX delay control
  delay_ctrl_u : mipi_csi_tx_delay_ctrl
    generic map (
      LP01CLK_DLY_G       => LP01CLK_DLY,
      LP00CLK_DLY_G       => LP00CLK_DLY,
      HS00CLK_DLY_G       => HS00CLK_DLY,
      HSXXCLK_DLY_G       => HSXXCLK_DLY,
      CLK2DATA_DLY_G      => CLK2DATA_DLY,
      LP01DATA_DLY_G      => LP01DATA_DLY,
      LP00DATA_DLY_G      => LP00DATA_DLY,
      HS00DATA_DLY_G      => HS00DATA_DLY,
      HSXXDATA_DLY_G      => HSXXDATA_DLY,
      HSTRAILDATA_DLY_G   => HSTRAILDATA_DLY,
      HS00DATAEND_DLY_G   => HS00DATAEND_DLY,
      LP00DATAEND_DLY_G   => LP00DATAEND_DLY,
      CLK2DATAEND_DLY_G   => CLK2DATAEND_DLY,
      HS00CLKEND_DLY_G    => HS00CLKEND_DLY,
      LP00CLKEND_DLY_G    => LP00CLKEND_DLY
    )
    port map (
      -- Core clock and reset
      clk                 => clk,
      arst_n              => arst_n,
      srst                => srst,

      -- Input bytes per lane
      in_hs_en_i          => packet_header_bytepkt_en_s,
      in_byte_l3_i        => packet_header_bytepkt_s(31 downto 24),
      in_byte_l2_i        => packet_header_bytepkt_s(23 downto 16),
      in_byte_l1_i        => packet_header_bytepkt_s(15 downto  8),
      in_byte_l0_i        => packet_header_bytepkt_s( 7 downto  0),

      -- Output bytes per lane
      out_hsxx_clk_en_o   => delay_ctrl_hsxx_clk_en_s,
      out_hs_clk_en_o     => delay_ctrl_hs_clk_en_s,
      out_hs_data_en_o    => delay_ctrl_hs_data_en_s,
      out_lp_clk_o        => delay_ctrl_lp_clk_s,
      out_lp_data_o       => delay_ctrl_lp_data_s,
      out_byte_l3_o       => delay_ctrl_byte_out_s(31 downto 24),
      out_byte_l2_o       => delay_ctrl_byte_out_s(23 downto 16),
      out_byte_l1_o       => delay_ctrl_byte_out_s(15 downto  8),
      out_byte_l0_o       => delay_ctrl_byte_out_s( 7 downto  0)
    );


  ----------------------------------------------
  -- MIPI DPHY TX Output Serdes Layer
  mipi_csi_tx_dphy_u : mipi_csi_tx_dphy
    generic map (
      LANE_WIDTH_G          => LANE_WIDTH_C,
      FPGA_FAMILY_G         => FPGA_FAMILY_G
    )
    port map (
      -- Clocks and resets
      core_rst_i            => rst_s,
      core_clk_i            => clk,
      hs_clk_i              => hs_clk,
      hs_clk_o              => mipi_tx_hs_clk_o,

      -- High speed data enable and I/O buffer tristate control
      hs_clk_en_i           => delay_ctrl_hs_clk_en_s,
      hs_data_en_i          => delay_ctrl_hs_data_en_s,
      hs_clk_tri_ctl_o      => dphy_tx_mipi_hs_clk_tri_ctl_s,
      hs_data_tri_ctl_o(0)  => dphy_tx_mipi_hs_d0_tri_ctl_s,
      hs_data_tri_ctl_o(1)  => dphy_tx_mipi_hs_d1_tri_ctl_s,

      -- High speed CSI interface
      hs_byte_data_i        => delay_ctrl_byte_out_s((8*LANE_WIDTH_C)-1 downto 0),
      hs_data_o(0)          => mipi_tx_hs_d0_o,
      hs_data_o(1)          => mipi_tx_hs_d1_o,

      -- Low power interface
      lp_clk_io             => mipi_tx_lp_clk_io,
      lp_clk_dir_i          => '1',
      lp_clk_i              => delay_ctrl_lp_clk_s,
      lp_clk_o              => open,
      lp_dx_dir_i           => dphy_tx_lp_dx_dir_s,
      lp_dx_i               => dphy_tx_lp_dx_i_s,
      lp_dx_o               => open,
      lp_dx_io(3 downto 2)  => mipi_tx_lp_d1_io,
      lp_dx_io(1 downto 0)  => mipi_tx_lp_d0_io
    );

end rtl;
