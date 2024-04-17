-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;
use work.evt_verification_pkg;


----------------------
-- Event Stream Reader
entity evt_stream_reader is
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
end entity evt_stream_reader;

architecture rtl of evt_stream_reader is


  ----------------------------
  -- Component Declarations --
  ----------------------------

  ---------------------
  -- File Stream Reader
  component file_stream_reader is
    generic (
      DATA_WIDTH     : positive := 32;
      FILE_PATH      : string   := "file.dat";
      WHOIAM         : string   := "file_reader"
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


  ----------------------
  -- Event Stream Reader
  component evt20_stream_reader is
    generic (
      EVT_TIME_HIGH_SYNC_PERIOD_US : integer                   := 128;
      FILE_PATH                    : string                    := "file.dat";
      FILTER_TYPES                 : boolean                   := true;
      FILTER_SUBTYPES              : boolean                   := false;
      FILTER_TRIGGER_IDS           : boolean                   := false;
      INSERT_EOT                   : boolean                   := false;                            -- Insert end of task event
      NEEDED_TYPES                 : ccam_evt_type_vector_t    := (-1 downto 0 => (others => '0'));
      NEEDED_SUBTYPES              : ccam_evt_subtype_vector_t := (-1 downto 0 => (others => '0'));
      NEEDED_TRIGGER_IDS           : natural_vector_t          := (-1 downto 0 => 0);
      USE_TIME_BASE_INPUT          : boolean                   := false;
      WHOIAM                       : string                    := "Evt. Stream Reader"
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
  end component evt20_stream_reader;


  --------------------------
  -- Event 3.0 Stream Reader
  component evt30_stream_reader is
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
  end component evt30_stream_reader;


  -------------------------
  -- Signal Declarations --
  -------------------------


begin

  -----------------------------------
  -- Generate RAW Stream Reader
  raw_stream_reader_gen : if (EVT_FORMAT = RAW_DAT_FORMAT) generate
    signal sync_ack_q : std_logic;
  begin

    sync_ack_o <= sync_ack_q;

    ---------------------------------------------------
    -- Input File Stream Reader
    -- Reads a file and produces an output data stream.
    file_stream_reader_u : file_stream_reader
    generic map (
      DATA_WIDTH    => CCAM_EVT_DATA_BITS,
      FILE_PATH     => FILE_PATH,
      WHOIAM        => WHOIAM
    )
    port map (
      -- Clock and Reset
      clk           => clk,
      rst           => srst,

      -- Enable
      enable_i      => enable_i,

      -- End of File
      eof_o         => eof_o,

      -- Output Data Stream
      out_ready_i   => out_ready_i,
      out_valid_o   => out_valid_o,
      out_last_o    => out_last_o,
      out_data_o    => out_data_o
    );

    -- Synchronization Of Sequencer
    raw_sequencer_p : process(clk)
    begin
      if (rising_edge(clk)) then
        if (srst  = '1') then
          sync_ack_q <= '0';
        else
          if (sync_request_i = '1' and sync_ack_q = '0') then
            sync_ack_q <= '1';
          else
            sync_ack_q   <= '0';
          end if;
        end if;
      end if;
    end process raw_sequencer_p;

  end generate raw_stream_reader_gen;


  -----------------------------------
  -- Generate Event 2.0 Stream Reader
  evt20_stream_reader_gen : if (EVT_FORMAT = EVT_FORMAT_2_0) generate

    ----------------------
    -- Event Stream Reader
    evt20_stream_reader_u : evt20_stream_reader
    generic map (
      EVT_TIME_HIGH_SYNC_PERIOD_US => EVT_TIME_HIGH_SYNC_PERIOD_US,
      FILE_PATH                    => FILE_PATH,
      FILTER_TYPES                 => FILTER_TYPES,
      FILTER_SUBTYPES              => FILTER_SUBTYPES,
      FILTER_TRIGGER_IDS           => FILTER_TRIGGER_IDS,
      INSERT_EOT                   => INSERT_EOT,
      NEEDED_TYPES                 => NEEDED_TYPES,
      NEEDED_SUBTYPES              => NEEDED_SUBTYPES,
      NEEDED_TRIGGER_IDS           => NEEDED_TRIGGER_IDS,
      USE_TIME_BASE_INPUT          => USE_TIME_BASE_INPUT,
      WHOIAM                       => WHOIAM
    )
    port map (
      -- Clock
      clk             => clk,
      arst_n          => arst_n,
      srst            => srst,
  
      -- Enable
      enable_i        => enable_i,
      eof_o           => eof_o,
  
      -- Event Time Base (us)
      evt_time_base_i => evt_time_base_i,
  
      -- Synchronization Of Sequencer
      sync_request_i  => sync_request_i,
      sync_ack_o      => sync_ack_o,
  
      -- Output Event Stream Interface
      out_ready_i     => out_ready_i,
      out_valid_o     => out_valid_o,
      out_last_o      => out_last_o,
      out_data_o      => out_data_o
    );

  end generate evt20_stream_reader_gen;


  -----------------------------------
  -- Generate Event 3.0 Stream Reader
  evt30_stream_reader_gen : if (EVT_FORMAT = EVT_FORMAT_3_0) generate
    signal out_data_s      : ccam_evt_v3_data_t;
    signal evt_time_base_s : ccam_evt_v3_time_data_t;
  begin
    
    out_data_o      <= ccam_evt_v3_data_to_ccam_evt_data(out_data_s);
    evt_time_base_s <= std_logic_vector(resize(unsigned(evt_time_base_i), evt_time_base_s'length));

    --------------------------
    -- Event 3.0 Stream Reader
    evt30_stream_reader_u : evt30_stream_reader
    generic map (
      EVT_TIME_HIGH_SYNC_PERIOD_US => EVT_TIME_HIGH_SYNC_PERIOD_US,
      FILE_PATH                    => FILE_PATH,
      FILTER_TYPES                 => FILTER_TYPES,
      FILTER_SUBTYPES              => FILTER_SUBTYPES,
      FILTER_TRIGGER_IDS           => FILTER_TRIGGER_IDS,
      INSERT_EOT                   => INSERT_EOT,
      NEEDED_TYPES                 => NEEDED_V3_TYPES,
      NEEDED_SUBTYPES              => NEEDED_V3_SUBTYPES,
      NEEDED_TRIGGER_IDS           => NEEDED_TRIGGER_IDS,
      USE_TIME_BASE_INPUT          => USE_TIME_BASE_INPUT,
      WHOIAM                       => WHOIAM
    )
    port map (
      -- Clock
      clk             => clk,
      arst_n          => arst_n,
      srst            => srst,
  
      -- Enable
      enable_i        => enable_i,
      eof_o           => eof_o,
  
      -- Event Time Base (us)
      evt_time_base_i => evt_time_base_s,
  
      -- Synchronization Of Sequencer
      sync_request_i  => sync_request_i,
      sync_ack_o      => sync_ack_o,
  
      -- Output Event Stream Interface
      out_ready_i     => out_ready_i,
      out_valid_o     => out_valid_o,
      out_last_o      => out_last_o,
      out_data_o      => out_data_s
    );

  end generate evt30_stream_reader_gen;

end architecture rtl;
