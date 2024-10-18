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
use work.ccam_utils.all;
use work.ccam_evt_types_v3.all;
use work.evt_verification_pkg;


--------------------------
-- Event 3.0 Stream Reader
entity evt30_stream_reader is
  generic (
    EVT_TIME_HIGH_SYNC_PERIOD_US : integer                      := 16;
    FILE_PATH                    : string                       := "file.dat";
    FILTER_TYPES                 : boolean                      := true;
    FILTER_SUBTYPES              : boolean                      := false;
    FILTER_TRIGGER_IDS           : boolean                      := false;
    INSERT_EOT                   : boolean                      := false;                            -- Insert end of task event
    NEEDED_TYPES                 : ccam_evt_v3_type_vector_t    := (-1 downto 0 => (others => '0'));
    NEEDED_SUBTYPES              : ccam_evt_v3_subtype_vector_t := (-1 downto 0 => (others => '0'));
    NEEDED_TRIGGER_IDS           : natural_vector_t             := (-1 downto 0 => 0);
    USE_TIME_BASE_INPUT          : boolean                      := false;
    WHOIAM                       : string                       := "file_reader"
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
    evt_time_base_i : in  ccam_evt_v3_time_data_t;

    -- Synchronization Of Sequencer
    sync_request_i  : in  std_logic;
    sync_ack_o      : out std_logic;

    -- Output Event Stream Interface
    out_ready_i     : in  std_logic;
    out_valid_o     : out std_logic;
    out_last_o      : out std_logic;
    out_data_o      : out ccam_evt_v3_data_t
  );
end entity evt30_stream_reader;

architecture rtl of evt30_stream_reader is

  ----------------------------
  -- Component Declarations --
  ----------------------------

  ---------------------------------------------------
  -- File Stream Reader
  -- Reads a file and produces an output data stream.
  component file_stream_reader is
    generic (
      DATA_WIDTH     : positive := 32;
      FILE_PATH      : string   := "file.dat"
    );
    port (
      -- Clock and Reset
      clk         : in  std_logic;
      rst         : in  std_logic;

      -- Enable
      enable_i    : in  std_logic;

      -- End of File
      eof_o       : out std_logic;

      -- Output Data Stream
      out_ready_i : in  std_logic;
      out_valid_o : out std_logic;
      out_last_o  : out std_logic;
      out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component file_stream_reader;


  ----------------------------------------------------------------------
  -- Sequences events so that they are only issued at the expected time.
  component evt30_sequencer is
    generic (
      FILTER_TYPES       : boolean                      := true;
      FILTER_SUBTYPES    : boolean                      := false;
      FILTER_TRIGGER_IDS : boolean                      := false;
      INSERT_EOT         : boolean                      := false;                            -- Insert end of task event
      NEEDED_TYPES       : ccam_evt_v3_type_vector_t    := (-1 downto 0 => (others => '0'));
      NEEDED_SUBTYPES    : ccam_evt_v3_subtype_vector_t := (-1 downto 0 => (others => '0'));
      NEEDED_TRIGGER_IDS : natural_vector_t             := (-1 downto 0 => 0)
    );
    port (
      -- Clock and Reset
      clk                    : in  std_logic;
      arst_n                 : in  std_logic;
      srst                   : in  std_logic;

      -- Enable
      enable_i               : in  std_logic;

      -- Synchronization Of Sequencer
      sync_request_i         : in  std_logic;
      sync_ack_o             : out std_logic;

      -- End of File
      reference_eof_i        : in  std_logic;

      -- Event Time Base (in us)
      evt_time_base_i        : in  ccam_evt_v3_time_data_t;
      cfg_time_high_period_i : in  ccam_evt_v3_time_data_t;

      -- Input Event Stream Interface
      in_ready_o             : out std_logic;
      in_valid_i             : in  std_logic;
      in_last_i              : in  std_logic;
      in_data_i              : in  ccam_evt_v3_data_t;

      -- Output Event Stream Interface
      out_ready_i            : in  std_logic;
      out_valid_o            : out std_logic;
      out_last_o             : out std_logic;
      out_data_o             : out ccam_evt_v3_data_t
    );
  end component evt30_sequencer;


  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Reset Signal
  signal rst_s                  : std_logic;

  -- File Data Stream Signals
  signal file_eof_s             : std_logic;
  signal file_ready_s           : std_logic;
  signal file_valid_s           : std_logic;
  signal file_last_s            : std_logic;
  signal file_data_s            : ccam_evt_v3_data_t;

  -- Time Base Signals
  signal evt_time_base_s        : ccam_evt_v3_time_data_t;

  -- Event Sequencer Signals
  signal evt_sequencer_enable_s : std_logic;

begin

  ---------------------------------
  -- Asynchronous Signal Mapping --
  ---------------------------------

  -- Reset Signals
  rst_s                  <= srst or (not arst_n);

  -- Mapping Signals to Output Ports
  eof_o                  <= file_eof_s;

  -- Event Time Base Signals
  evt_time_base_s        <= evt_time_base_i when USE_TIME_BASE_INPUT else
                            evt_verification_pkg.evt_verification_time_base_s(CCAM_EVT_V3_TIME_BITS-1 downto 0);

  -- Event Sequencer Signals
  evt_sequencer_enable_s <= enable_i when USE_TIME_BASE_INPUT else
                            enable_i and evt_verification_pkg.evt_verification_time_base_enable_s;


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ---------------------------------------------------
  -- File Stream Reader
  -- Reads a file and produces an output data stream.
  file_stream_reader_u : file_stream_reader
  generic map (
    DATA_WIDTH => CCAM_EVT_V3_DATA_BITS,
    FILE_PATH  => FILE_PATH
  )
  port map (
    -- Clock and Reset
    clk         => clk,
    rst         => rst_s,

    -- Enable
    enable_i    => enable_i,

    -- End of File
    eof_o       => file_eof_s,

    -- Output Data Stream
    out_ready_i => file_ready_s,
    out_valid_o => file_valid_s,
    out_last_o  => file_last_s,
    out_data_o  => file_data_s
  );


  ----------------------------------------------------------------------
  -- Sequences events so that they are only issued at the expected time.
  evt30_sequencer_u : evt30_sequencer
  generic map (
    FILTER_TYPES       => FILTER_TYPES,
    FILTER_SUBTYPES    => FILTER_SUBTYPES,
    FILTER_TRIGGER_IDS => FILTER_TRIGGER_IDS,
    INSERT_EOT         => INSERT_EOT,
    NEEDED_TYPES       => NEEDED_TYPES,
    NEEDED_SUBTYPES    => NEEDED_SUBTYPES,
    NEEDED_TRIGGER_IDS => NEEDED_TRIGGER_IDS
  )
  port map (
    -- Clock and Reset
    clk                    => clk,
    arst_n                 => arst_n,
    srst                   => srst,

    -- Enable
    enable_i               => evt_sequencer_enable_s,

    -- SynchronizationOf Sequencer
    sync_request_i         => sync_request_i,
    sync_ack_o             => sync_ack_o,

    -- End of File
    reference_eof_i        => file_eof_s,

    -- Event Time Base(in us)
    evt_time_base_i        => evt_time_base_s,
    cfg_time_high_period_i => std_logic_vector(to_unsigned(EVT_TIME_HIGH_SYNC_PERIOD_US, ccam_evt_v3_time_data_t'length)),

    -- Input Event Stream Interface
    in_ready_o             => file_ready_s,
    in_valid_i             => file_valid_s,
    in_last_i              => file_last_s,
    in_data_i              => file_data_s,

    -- Output Event Stream Interface
    out_ready_i            => out_ready_i,
    out_valid_o            => out_valid_o,
    out_last_o             => out_last_o,
    out_data_o             => out_data_o
  );


end architecture rtl;
