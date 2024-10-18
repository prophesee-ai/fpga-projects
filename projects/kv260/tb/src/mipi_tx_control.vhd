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

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_utils.all;


--------------------------------------
-- Events to MIPI Packet Control Block
-- for a MIPI CSI2 TX IP
entity mipi_tx_control is
  generic (
    RAW_MODE_SUPPORT_G          : boolean  := true;
    FIXED_FRAME_SIZE_G          : boolean  := false;
    EVT30_SUPPORT               : boolean  := true;
    MIPI_PADDING_ENABLE_G       : boolean  := false;
    MIPI_DATA_WIDTH             : positive := 16;
    MIPI_MAX_PACKET_SIZE        : positive := 16384; -- Max. number of bytes in MIPI packet. Default 16KB.
    TIME_HIGH_PERIOD            : positive := 16
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
end entity mipi_tx_control;


architecture rtl of mipi_tx_control is


  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant MIPI_TX_CONTROL_FIFO_BYPASS : boolean  := false;

  constant PACKET_SIZE_DATA_WIDTH      : positive := clog2(MIPI_MAX_PACKET_SIZE);
  constant PACKET_SIZE_FIFO_DATA_WIDTH : positive := PACKET_SIZE_DATA_WIDTH;
  constant PACKET_SIZE_FIFO_DATA_DEPTH : positive := 32;


  -----------------------
  -- Design Components --
  -----------------------


  ----------------------------------------------------------
  -- Input FSM for the Event to MIPI TX Frame Control Block
  -- that Manages the MIPI Frame Start/End Frontiers and the
  -- insertion of the relative monitoring events.
  component mipi_tx_control_in_frame is
    generic (
      RAW_MODE_SUPPORT_G        : boolean  := true;
      FIXED_FRAME_SIZE_G        : boolean  := false;
      EVT30_SUPPORT             : boolean  := true;
      MIPI_DATA_WIDTH           : positive := 16;
      TIME_HIGH_PERIOD          : positive := 16
    );
    port (
      -- Core clock and reset
      clk                       : in  std_logic;
      arst_n                    : in  std_logic;
      srst                      : in  std_logic;

      -- Configuration Interface
      cfg_enable_i              : in  std_logic;
      cfg_evt_format_i          : in  evt_format_data_t;
      cfg_frame_period_us_i     : in  std_logic_vector(15 downto 0);
      cfg_evt_time_high_sync_i  : in  std_logic;

      -- Event Input Interface
      evt_in_ready_o            : out std_logic;
      evt_in_valid_i            : in  std_logic;
      evt_in_first_i            : in  std_logic;
      evt_in_last_i             : in  std_logic;
      evt_in_data_i             : in  ccam_evt_data_t;

      -- Event Output Interface
      evt_out_ready_i           : in  std_logic;
      evt_out_valid_o           : out std_logic;
      evt_out_first_o           : out std_logic;
      evt_out_last_o            : out std_logic;
      evt_out_frame_start_o     : out std_logic;
      evt_out_frame_end_o       : out std_logic;
      evt_out_data_o            : out ccam_evt_data_t
    );
  end component mipi_tx_control_in_frame;


  ----------------------------------------------------------
  -- Input FSM for the Event to MIPI TX Packet Control Block
  component mipi_tx_control_in_packet is
    generic (
      RAW_MODE_SUPPORT_G     : boolean  := true;
      FIXED_FRAME_SIZE_G     : boolean  := false;
      EVT30_SUPPORT          : boolean  := true;
      MIPI_DATA_WIDTH        : positive := 16;
      MIPI_MAX_PACKET_SIZE   : positive := 16384; -- Max. number of bytes in MIPI packet. Default 16KB.
      PACKET_SIZE_DATA_WIDTH : positive := 14;
      TIME_HIGH_PERIOD       : positive := 16
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
      cfg_packet_timeout_us_i     : in  std_logic_vector(15 downto 0);
      cfg_packet_size_i           : in  std_logic_vector(13 downto 0);
      cfg_evt_time_high_sync_i    : in  std_logic;

      -- Event Input Interface
      evt_in_ready_o              : out std_logic;
      evt_in_valid_i              : in  std_logic;
      evt_in_first_i              : in  std_logic;
      evt_in_last_i               : in  std_logic;
      evt_in_frame_start_i        : in  std_logic;
      evt_in_frame_end_i          : in  std_logic;
      evt_in_data_i               : in  ccam_evt_data_t;

      -- MIPI TX FIFO Write Interface
      fifo_wr_ready_i             : in  std_logic;
      fifo_wr_valid_o             : out std_logic;
      fifo_wr_first_o             : out std_logic;
      fifo_wr_last_o              : out std_logic;
      fifo_wr_data_o              : out ccam_evt_data_t;

      -- Packet Size Output Interface
      packet_size_out_ready_i     : in  std_logic;
      packet_size_out_valid_o     : out std_logic;
      packet_size_out_first_o     : out std_logic;
      packet_size_out_last_o      : out std_logic;
      packet_size_out_data_o      : out std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0)
    );
  end component mipi_tx_control_in_packet;


  -----------------------------
  -- MIPI TX Control FIFO Block
  component mipi_tx_control_fifo is
    generic (
      DATA_WIDTH        : integer := 8;    -- FIFO Data Width
      DATA_DEPTH        : integer := 32;   -- FIFO Data Depth (<= 32)
      BYPASS_FIFO       : boolean := false -- Bypasses the FIFO and instantiates a pipeline stage instead
    );
    port (
      -- Core Clock and Reset
      clk                : in  std_logic;
      arst_n             : in  std_logic;
      srst               : in  std_logic;

      -- Input Interface
      in_ready_o         : out std_logic;
      in_valid_i         : in  std_logic;
      in_last_i          : in  std_logic;
      in_first_i         : in  std_logic;
      in_data_i          : in  std_logic_vector(DATA_WIDTH-1 downto 0);

      -- Output Interface
      out_ready_i        : in  std_logic;
      out_valid_o        : out std_logic;
      out_last_o         : out std_logic;
      out_first_o        : out std_logic;
      out_data_o         : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component mipi_tx_control_fifo;


  -----------------------------------------------------------
  -- Output FSM for the Event to MIPI TX Packet Control Block
  component mipi_tx_control_out is
    generic (
      EVT30_SUPPORT          : boolean  := true;
      MIPI_DATA_WIDTH        : positive := 16;
      MIPI_MAX_PACKET_SIZE   : positive := 16384; -- Max. number of bytes in MIPI packet. Default 16KB.
      PACKET_SIZE_DATA_WIDTH : positive := 16;
      TIME_HIGH_PERIOD       : positive := 16
    );
    port (
      -- Core clock and reset
      clk                       : in  std_logic;
      arst_n                    : in  std_logic;
      srst                      : in  std_logic;

      -- Configuration Interface
      cfg_enable_i              : in  std_logic;
      cfg_evt_format_i          : in  evt_format_data_t;
      cfg_virtual_channel_i     : in  std_logic_vector(1 downto 0);
      cfg_data_type_i           : in  std_logic_vector(5 downto 0);
      cfg_blocking_mode_i       : in  std_logic;

      -- MIPI TX FIFO Read Interface
      fifo_rd_ready_o           : out std_logic;
      fifo_rd_valid_i           : in  std_logic;
      fifo_rd_first_i           : in  std_logic;
      fifo_rd_last_i            : in  std_logic;
      fifo_rd_data_i            : in  ccam_evt_data_t;

      -- Packet Size Input Interface
      packet_size_in_ready_o    : out std_logic;
      packet_size_in_valid_i    : in  std_logic;
      packet_size_in_first_i    : in  std_logic;
      packet_size_in_last_i     : in  std_logic;
      packet_size_in_data_i     : in  std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);

      -- MIPI RX Flow Control
      mipi_rx_ready_i           : in  std_logic;

      -- MIPI TX Generic IP Interface
      mipi_tx_ready_i           : in  std_logic;
      mipi_tx_valid_o           : out std_logic;
      mipi_tx_frame_start_o     : out std_logic;
      mipi_tx_frame_end_o       : out std_logic;
      mipi_tx_packet_start_o    : out std_logic;
      mipi_tx_packet_end_o      : out std_logic;
      mipi_tx_virtual_channel_o : out std_logic_vector(1 downto 0);
      mipi_tx_data_type_o       : out std_logic_vector(5 downto 0);
      mipi_tx_word_count_o      : out std_logic_vector(15 downto 0);
      mipi_tx_data_o            : out std_logic_vector(MIPI_DATA_WIDTH-1 downto 0)
    );
  end component mipi_tx_control_out;


  ------------------------
  -- MIPI packet padding
  component mipi_tx_control_padding is
    generic (
      MIPI_DATA_WIDTH_G      : positive := 16;
      MIPI_MAX_PACKET_SIZE_G : positive := 16384  -- Max. number of bytes in MIPI packet. Default 16KB.
    );
    port (
      -- Core clock and reset
      clk                           : in  std_logic;
      arst_n                        : in  std_logic;
      srst                          : in  std_logic;

      -- Configuration Interface
      cfg_enable_i                  : in  std_logic;
      cfg_bypass_i                  : in  std_logic;
      cfg_evt_format_i              : in  evt_format_data_t;
      cfg_packet_size_i             : in  std_logic_vector(13 downto 0);
      cfg_blocking_mode_i           : in  std_logic;

      -- MIPI RX Flow Control
      mipi_rx_ready_i               : in  std_logic;

      -- MIPI TX Generic IP Interface
      mipi_tx_in_ready_o            : out std_logic;
      mipi_tx_in_valid_i            : in  std_logic;
      mipi_tx_in_frame_start_i      : in  std_logic;
      mipi_tx_in_frame_end_i        : in  std_logic;
      mipi_tx_in_packet_start_i     : in  std_logic;
      mipi_tx_in_packet_end_i       : in  std_logic;
      mipi_tx_in_virtual_channel_i  : in  std_logic_vector(1 downto 0);
      mipi_tx_in_data_type_i        : in  std_logic_vector(5 downto 0);
      mipi_tx_in_word_count_i       : in  std_logic_vector(15 downto 0);
      mipi_tx_in_data_i             : in  std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);

      -- MIPI TX Generic IP Interface
      mipi_tx_out_ready_i           : in  std_logic;
      mipi_tx_out_valid_o           : out std_logic;
      mipi_tx_out_frame_start_o     : out std_logic;
      mipi_tx_out_frame_end_o       : out std_logic;
      mipi_tx_out_packet_start_o    : out std_logic;
      mipi_tx_out_packet_end_o      : out std_logic;
      mipi_tx_out_virtual_channel_o : out std_logic_vector(1 downto 0);
      mipi_tx_out_data_type_o       : out std_logic_vector(5 downto 0);
      mipi_tx_out_word_count_o      : out std_logic_vector(15 downto 0);
      mipi_tx_out_data_o            : out std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0)
    );
  end component mipi_tx_control_padding;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Control Signals
  signal cfg_enable_packet_timeout_s             : std_logic;

  -- Input FSM for the Event to MIPI TX Packet Control Block: Frame Size Output Interface
  signal control_in_frame_out_ready_s            : std_logic;
  signal control_in_frame_out_valid_s            : std_logic;
  signal control_in_frame_out_first_s            : std_logic;
  signal control_in_frame_out_last_s             : std_logic;
  signal control_in_frame_out_frame_start_s      : std_logic;
  signal control_in_frame_out_frame_end_s        : std_logic;
  signal control_in_frame_out_data_s             : ccam_evt_data_t;

  -- Input FSM for the Event to MIPI TX Packet Control Block: Packet Size Output Interface
  signal control_in_packet_size_out_ready_s      : std_logic;
  signal control_in_packet_size_out_valid_s      : std_logic;
  signal control_in_packet_size_out_first_s      : std_logic;
  signal control_in_packet_size_out_last_s       : std_logic;
  signal control_in_packet_size_out_data_s       : std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- Packet Size FIFO Data Output
  signal packet_size_fifo_out_ready_s            : std_logic;
  signal packet_size_fifo_out_valid_s            : std_logic;
  signal packet_size_fifo_out_first_s            : std_logic;
  signal packet_size_fifo_out_last_s             : std_logic;
  signal packet_size_fifo_out_data_s             : std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- MIPI TX Control Out Block Signals
  signal mipi_tx_control_out_cfg_blocking_mode_s : std_logic;

  -- MIPI TX Generic IP Interface
  signal mipi_tx_padding_out_ready_s             : std_logic;
  signal mipi_tx_padding_out_valid_s             : std_logic;
  signal mipi_tx_padding_out_frame_start_s       : std_logic;
  signal mipi_tx_padding_out_frame_end_s         : std_logic;
  signal mipi_tx_padding_out_packet_start_s      : std_logic;
  signal mipi_tx_padding_out_packet_end_s        : std_logic;
  signal mipi_tx_padding_out_virtual_channel_s   : std_logic_vector(1 downto 0);
  signal mipi_tx_padding_out_data_type_s         : std_logic_vector(5 downto 0);
  signal mipi_tx_padding_out_word_count_s        : std_logic_vector(15 downto 0);
  signal mipi_tx_padding_out_data_s              : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0);


  --------------------------
  -- Synthesis Attributes --
  --------------------------

  attribute mark_debug : string;
  attribute mark_debug of control_in_packet_size_out_ready_s    : signal is "true";
  attribute mark_debug of control_in_packet_size_out_valid_s    : signal is "true";
  attribute mark_debug of control_in_packet_size_out_first_s    : signal is "true";
  attribute mark_debug of control_in_packet_size_out_last_s     : signal is "true";
  attribute mark_debug of control_in_packet_size_out_data_s     : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_ready_s           : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_valid_s           : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_frame_start_s     : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_frame_end_s       : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_packet_start_s    : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_packet_end_s      : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_virtual_channel_s : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_data_type_s       : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_word_count_s      : signal is "true";
  attribute mark_debug of mipi_tx_padding_out_data_s            : signal is "true";
  attribute mark_debug of mipi_tx_ready_i                       : signal is "true";
  attribute mark_debug of mipi_tx_valid_o                       : signal is "true";
  attribute mark_debug of mipi_tx_frame_start_o                 : signal is "true";
  attribute mark_debug of mipi_tx_frame_end_o                   : signal is "true";
  attribute mark_debug of mipi_tx_packet_start_o                : signal is "true";
  attribute mark_debug of mipi_tx_packet_end_o                  : signal is "true";
  attribute mark_debug of mipi_tx_virtual_channel_o             : signal is "true";
  attribute mark_debug of mipi_tx_data_type_o                   : signal is "true";
  attribute mark_debug of mipi_tx_word_count_o                  : signal is "true";
  attribute mark_debug of mipi_tx_data_o                        : signal is "true";

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Control Signals
  -- Force packet timeout when in Fixed Frame Size configuration
  cfg_enable_packet_timeout_s <= '1' when (FIXED_FRAME_SIZE_G) else cfg_enable_packet_timeout_i;


  ------------------------------
  -- Component instantiations --
  ------------------------------


  ----------------------------------------------------------
  -- Input FSM for the Event to MIPI TX Frame Control Block
  -- that Manages the MIPI Frame Start/End Frontiers and the
  -- insertion of the relative monitoring events.
  mipi_tx_control_in_frame_u : mipi_tx_control_in_frame
  generic map (
    RAW_MODE_SUPPORT_G        => RAW_MODE_SUPPORT_G,
    FIXED_FRAME_SIZE_G        => FIXED_FRAME_SIZE_G,
    EVT30_SUPPORT             => EVT30_SUPPORT,
    MIPI_DATA_WIDTH           => MIPI_DATA_WIDTH,
    TIME_HIGH_PERIOD          => TIME_HIGH_PERIOD
  )
  port map (
    -- Clock and reset
    clk                       => clk,
    arst_n                    => arst_n,
    srst                      => srst,

    -- Configuration Interface
    cfg_enable_i              => cfg_enable_i,
    cfg_evt_format_i          => cfg_evt_format_i,
    cfg_frame_period_us_i     => cfg_frame_period_us_i,
    cfg_evt_time_high_sync_i  => cfg_evt_time_high_sync_i,

    -- Event Input Interface
    evt_in_ready_o            => evt_in_ready_o,
    evt_in_valid_i            => evt_in_valid_i,
    evt_in_first_i            => evt_in_first_i,
    evt_in_last_i             => evt_in_last_i,
    evt_in_data_i             => evt_in_data_i,

    -- Event Output Interface
    evt_out_ready_i           => control_in_frame_out_ready_s,
    evt_out_valid_o           => control_in_frame_out_valid_s,
    evt_out_first_o           => control_in_frame_out_first_s,
    evt_out_last_o            => control_in_frame_out_last_s,
    evt_out_frame_start_o     => control_in_frame_out_frame_start_s,
    evt_out_frame_end_o       => control_in_frame_out_frame_end_s,
    evt_out_data_o            => control_in_frame_out_data_s
  );


  ----------------------------------------------------------
  -- Input FSM for the Event to MIPI TX Packet Control Block
  mipi_tx_control_in_packet_u : mipi_tx_control_in_packet
  generic map (
    RAW_MODE_SUPPORT_G          => RAW_MODE_SUPPORT_G,
    FIXED_FRAME_SIZE_G          => FIXED_FRAME_SIZE_G,
    EVT30_SUPPORT               => EVT30_SUPPORT,
    MIPI_DATA_WIDTH             => MIPI_DATA_WIDTH,
    MIPI_MAX_PACKET_SIZE        => MIPI_MAX_PACKET_SIZE, -- Max. number of bytes in MIPI packet. Default 16KB.
    PACKET_SIZE_DATA_WIDTH      => PACKET_SIZE_DATA_WIDTH,
    TIME_HIGH_PERIOD            => TIME_HIGH_PERIOD
  )
  port map (
    -- Clock and reset
    clk                         => clk,
    arst_n                      => arst_n,
    srst                        => srst,

    -- Configuration Interface
    cfg_enable_i                => cfg_enable_i,
    cfg_enable_packet_timeout_i => cfg_enable_packet_timeout_s,
    cfg_evt_format_i            => cfg_evt_format_i,
    cfg_packet_timeout_us_i     => cfg_packet_timeout_us_i,
    cfg_packet_size_i           => cfg_packet_size_i,
    cfg_evt_time_high_sync_i    => cfg_evt_time_high_sync_i,

    -- Event Input Interface
    evt_in_ready_o              => control_in_frame_out_ready_s,
    evt_in_valid_i              => control_in_frame_out_valid_s,
    evt_in_first_i              => control_in_frame_out_first_s,
    evt_in_last_i               => control_in_frame_out_last_s,
    evt_in_frame_start_i        => control_in_frame_out_frame_start_s,
    evt_in_frame_end_i          => control_in_frame_out_frame_end_s,
    evt_in_data_i               => control_in_frame_out_data_s,

    -- MIPI TX FIFO Write Interface
    fifo_wr_ready_i             => fifo_wr_ready_i,
    fifo_wr_valid_o             => fifo_wr_valid_o,
    fifo_wr_first_o             => fifo_wr_first_o,
    fifo_wr_last_o              => fifo_wr_last_o,
    fifo_wr_data_o              => fifo_wr_data_o,

    -- Packet Size Output Interface
    packet_size_out_ready_i     => control_in_packet_size_out_ready_s,
    packet_size_out_valid_o     => control_in_packet_size_out_valid_s,
    packet_size_out_first_o     => control_in_packet_size_out_first_s,
    packet_size_out_last_o      => control_in_packet_size_out_last_s,
    packet_size_out_data_o      => control_in_packet_size_out_data_s
  );


  -----------------------------
  -- MIPI TX Control FIFO Block
  mipi_tx_control_fifo_u : mipi_tx_control_fifo
  generic map (
    DATA_WIDTH        => PACKET_SIZE_FIFO_DATA_WIDTH,
    DATA_DEPTH        => PACKET_SIZE_FIFO_DATA_DEPTH,
    BYPASS_FIFO       => MIPI_TX_CONTROL_FIFO_BYPASS
  )
  port map (
    -- Clock and Reset
    clk                => clk,
    arst_n             => arst_n,
    srst               => srst,

    -- Input Interface
    in_ready_o         => control_in_packet_size_out_ready_s,
    in_valid_i         => control_in_packet_size_out_valid_s,
    in_first_i         => control_in_packet_size_out_first_s,
    in_last_i          => control_in_packet_size_out_last_s,
    in_data_i          => control_in_packet_size_out_data_s,

    -- Output Interface
    out_ready_i        => packet_size_fifo_out_ready_s,
    out_valid_o        => packet_size_fifo_out_valid_s,
    out_first_o        => packet_size_fifo_out_first_s,
    out_last_o         => packet_size_fifo_out_last_s,
    out_data_o         => packet_size_fifo_out_data_s
  );


  -----------------------------------------------------------
  -- Output FSM for the Event to MIPI TX Packet Control Block
  mipi_tx_control_out_u : mipi_tx_control_out
  generic map (
    EVT30_SUPPORT          => EVT30_SUPPORT,
    MIPI_DATA_WIDTH        => MIPI_DATA_WIDTH,
    MIPI_MAX_PACKET_SIZE   => MIPI_MAX_PACKET_SIZE, -- Max. number of bytes in MIPI packet. Default 16KB.
    PACKET_SIZE_DATA_WIDTH => PACKET_SIZE_DATA_WIDTH,
    TIME_HIGH_PERIOD       => TIME_HIGH_PERIOD
  )
  port map (
    -- Core clock and reset
    clk                       => clk,
    arst_n                    => arst_n,
    srst                      => srst,

    -- Configuration Interface
    cfg_enable_i              => cfg_enable_i,
    cfg_evt_format_i          => cfg_evt_format_i,
    cfg_virtual_channel_i     => cfg_virtual_channel_i,
    cfg_data_type_i           => cfg_data_type_i,
    cfg_blocking_mode_i       => mipi_tx_control_out_cfg_blocking_mode_s,

    -- MIPI TX FIFO Read Interface
    fifo_rd_ready_o           => fifo_rd_ready_o,
    fifo_rd_valid_i           => fifo_rd_valid_i,
    fifo_rd_first_i           => fifo_rd_first_i,
    fifo_rd_last_i            => fifo_rd_last_i,
    fifo_rd_data_i            => fifo_rd_data_i,

    -- Packet Size Output Interface
    packet_size_in_ready_o    => packet_size_fifo_out_ready_s,
    packet_size_in_valid_i    => packet_size_fifo_out_valid_s,
    packet_size_in_first_i    => packet_size_fifo_out_first_s,
    packet_size_in_last_i     => packet_size_fifo_out_last_s,
    packet_size_in_data_i     => packet_size_fifo_out_data_s,

    -- MIPI RX Flow Control
    mipi_rx_ready_i           => mipi_rx_ready_i,

    -- MIPI TX Generic IP Interface
    mipi_tx_ready_i           => mipi_tx_padding_out_ready_s,
    mipi_tx_valid_o           => mipi_tx_padding_out_valid_s,
    mipi_tx_frame_start_o     => mipi_tx_padding_out_frame_start_s,
    mipi_tx_frame_end_o       => mipi_tx_padding_out_frame_end_s,
    mipi_tx_packet_start_o    => mipi_tx_padding_out_packet_start_s,
    mipi_tx_packet_end_o      => mipi_tx_padding_out_packet_end_s,
    mipi_tx_virtual_channel_o => mipi_tx_padding_out_virtual_channel_s,
    mipi_tx_data_type_o       => mipi_tx_padding_out_data_type_s,
    mipi_tx_word_count_o      => mipi_tx_padding_out_word_count_s,
    mipi_tx_data_o            => mipi_tx_padding_out_data_s
  );


  padding_gen : if MIPI_PADDING_ENABLE_G generate
    signal cfg_padding_bypass_s : std_logic;
  begin

    mipi_tx_control_out_cfg_blocking_mode_s <= '0';

    cfg_padding_bypass_s  <= '0'  when FIXED_FRAME_SIZE_G else
                             cfg_padding_bypass_i;

    mipi_tx_control_padding_u : mipi_tx_control_padding
    generic map (
      MIPI_DATA_WIDTH_G        => MIPI_DATA_WIDTH,
      MIPI_MAX_PACKET_SIZE_G   => MIPI_MAX_PACKET_SIZE
    )
    port map (
      -- Core clock and reset
      clk                           => clk,
      arst_n                        => arst_n,
      srst                          => srst,

      -- Configuration Interface
      cfg_enable_i                  => cfg_enable_i,
      cfg_bypass_i                  => cfg_padding_bypass_s,
      cfg_evt_format_i              => cfg_evt_format_i,
      cfg_packet_size_i             => cfg_packet_size_i,
      cfg_blocking_mode_i           => cfg_blocking_mode_i,

      -- MIPI RX Flow Control
      mipi_rx_ready_i               => mipi_rx_ready_i,

      -- MIPI TX Generic IP Interface
      mipi_tx_in_ready_o            => mipi_tx_padding_out_ready_s,
      mipi_tx_in_valid_i            => mipi_tx_padding_out_valid_s,
      mipi_tx_in_frame_start_i      => mipi_tx_padding_out_frame_start_s,
      mipi_tx_in_frame_end_i        => mipi_tx_padding_out_frame_end_s,
      mipi_tx_in_packet_start_i     => mipi_tx_padding_out_packet_start_s,
      mipi_tx_in_packet_end_i       => mipi_tx_padding_out_packet_end_s,
      mipi_tx_in_virtual_channel_i  => mipi_tx_padding_out_virtual_channel_s,
      mipi_tx_in_data_type_i        => mipi_tx_padding_out_data_type_s,
      mipi_tx_in_word_count_i       => mipi_tx_padding_out_word_count_s,
      mipi_tx_in_data_i             => mipi_tx_padding_out_data_s,

      -- MIPI TX Generic IP Interface
      mipi_tx_out_ready_i           => mipi_tx_ready_i,
      mipi_tx_out_valid_o           => mipi_tx_valid_o,
      mipi_tx_out_frame_start_o     => mipi_tx_frame_start_o,
      mipi_tx_out_frame_end_o       => mipi_tx_frame_end_o,
      mipi_tx_out_packet_start_o    => mipi_tx_packet_start_o,
      mipi_tx_out_packet_end_o      => mipi_tx_packet_end_o,
      mipi_tx_out_virtual_channel_o => mipi_tx_virtual_channel_o,
      mipi_tx_out_data_type_o       => mipi_tx_data_type_o,
      mipi_tx_out_word_count_o      => mipi_tx_word_count_o,
      mipi_tx_out_data_o            => mipi_tx_data_o
    );
  end generate padding_gen;


  no_padding_gen : if not(MIPI_PADDING_ENABLE_G) generate

    mipi_tx_control_out_cfg_blocking_mode_s <= cfg_blocking_mode_i;

    mipi_tx_padding_out_ready_s   <= mipi_tx_ready_i;
    mipi_tx_valid_o               <= mipi_tx_padding_out_valid_s;
    mipi_tx_frame_start_o         <= mipi_tx_padding_out_frame_start_s;
    mipi_tx_frame_end_o           <= mipi_tx_padding_out_frame_end_s;
    mipi_tx_packet_start_o        <= mipi_tx_padding_out_packet_start_s;
    mipi_tx_packet_end_o          <= mipi_tx_padding_out_packet_end_s;
    mipi_tx_virtual_channel_o     <= mipi_tx_padding_out_virtual_channel_s;
    mipi_tx_data_type_o           <= mipi_tx_padding_out_data_type_s;
    mipi_tx_word_count_o          <= mipi_tx_padding_out_word_count_s;
    mipi_tx_data_o                <= mipi_tx_padding_out_data_s;
  end generate no_padding_gen;

end rtl;
