-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_utils.all;
use work.ccam_evt_types.all;
use work.ccam_evt_type_v2_1.all;
use work.evt_verification_pkg;


----------------------
-- Event Stream Reader
entity evt20_stream_reader is
  generic (
    EVT_TIME_HIGH_SYNC_PERIOD_US : integer                   := 128;
    EVT2_1_EN_G                  : boolean                   := false;
    INVERT_EVT21_SEQ_G           : boolean                   := false;
    FILE_PATH                    : string                    := "file.dat";
    FILTER_TYPES                 : boolean                   := true;
    FILTER_SUBTYPES              : boolean                   := false;
    FILTER_TRIGGER_IDS           : boolean                   := false;
    INSERT_EOT                   : boolean                   := false;                            -- Insert end of task event
    NEEDED_TYPES                 : ccam_evt_type_vector_t    := (-1 downto 0 => (others => '0'));
    NEEDED_SUBTYPES              : ccam_evt_subtype_vector_t := (-1 downto 0 => (others => '0'));
    NEEDED_TRIGGER_IDS           : natural_vector_t          := (-1 downto 0 => 0);
    OUT_DATA_WIDTH_G             : positive                  := CCAM_EVT_DATA_BITS;
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
    out_data_o      : out std_logic_vector(OUT_DATA_WIDTH_G-1 downto 0)
  );
end entity evt20_stream_reader;


architecture rtl of evt20_stream_reader is

  ----------------------------
  -- Constants Declarations --
  ----------------------------

  constant READ_DATA_WIDTH_C  : positive  := iff(EVT2_1_EN_G, 64, CCAM_EVT_DATA_BITS);


  ----------------------------
  -- Component Declarations --
  ----------------------------

  ---------------------------------------------------
  -- File Stream Reader
  -- Reads a file and produces an output data stream.
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


  ----------------------------------------------------------------------
  -- Sequences events so that they are only issued at the expected time.
  component evt20_sequencer is
    generic (
      FILTER_TYPES       : boolean                   := true;
      FILTER_SUBTYPES    : boolean                   := false;
      FILTER_TRIGGER_IDS : boolean                   := false;
      INSERT_EOT         : boolean                   := false;                            -- Insert end of task event
      NEEDED_TYPES       : ccam_evt_type_vector_t    := (-1 downto 0 => (others => '0'));
      NEEDED_SUBTYPES    : ccam_evt_subtype_vector_t := (-1 downto 0 => (others => '0'));
      NEEDED_TRIGGER_IDS : natural_vector_t          := (-1 downto 0 => 0)
    );
    port (
      -- Clock and Reset
      clk                    : in  std_logic;
      rst                    : in  std_logic;

      -- Enable
      enable_i               : in  std_logic;

      -- Synchronization Of Sequencer
      sync_request_i         : in  std_logic;
      sync_ack_o             : out std_logic;

      -- End of File
      reference_eof_i        : in  std_logic;

      -- Event Time Base (in us)
      evt_time_base_i        : in  ccam_evt_time_data_t;
      cfg_time_high_period_i : in  ccam_evt_time_data_t;

      -- Input Event Stream Interface
      in_ready_o             : out std_logic;
      in_valid_i             : in  std_logic;
      in_last_i              : in  std_logic;
      in_data_i              : in  ccam_evt_data_t;
      in_vector_i            : in  std_logic_vector(31 downto 0)  := (others =>'0');  -- evt2.1 compatible 32 bit vector

      -- Output Event Stream Interface
      out_ready_i            : in  std_logic;
      out_valid_o            : out std_logic;
      out_last_o             : out std_logic;
      out_data_o             : out ccam_evt_data_t;
      out_vector_o           : out std_logic_vector(31 downto 0)                      -- evt2.1 compatible 32 bit vector
    );
  end component evt20_sequencer;


  -----------------------------
  -- AXI4-Stream serializer
  component axis_serializer is
    generic (
      IN_DATA_WIDTH  : positive := 32;
      OUT_DATA_WIDTH : positive := 8;
      LITTLE_ENDIAN  : boolean  := true
    );
    port (
      -- Clock and Reset
      clk         : in  std_logic;
      arst_n      : in  std_logic;
      srst        : in  std_logic;

      -- Input Interface
      in_ready_o  : out std_logic;
      in_valid_i  : in  std_logic;
      in_first_i  : in  std_logic;
      in_last_i   : in  std_logic;
      in_data_i   : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);

      -- Output Interface
      out_ready_i : in  std_logic;
      out_valid_o : out std_logic;
      out_first_o : out std_logic;
      out_last_o  : out std_logic;
      out_data_o  : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component axis_serializer;


  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Input Event Stream Reader
  signal in_evt20_stream_reader_out_ready_s : std_logic;
  signal in_evt20_stream_reader_out_valid_s : std_logic;
  signal in_evt20_stream_reader_out_last_s  : std_logic;
  signal in_evt20_stream_reader_out_data_s  : std_logic_vector(READ_DATA_WIDTH_C-1 downto 0);

  signal in_evt20_sequencer_in_data_s       : ccam_evt_data_t;
  signal in_evt20_sequencer_in_vector_s     : std_logic_vector(31 downto 0);

  signal in_evt20_sequencer_out_ready_s     : std_logic;
  signal in_evt20_sequencer_out_valid_s     : std_logic;
  signal in_evt20_sequencer_out_last_s      : std_logic;
  signal in_evt20_sequencer_out_data_s      : ccam_evt_data_t;
  signal in_evt20_sequencer_out_vector_s    : std_logic_vector(31 downto 0);

  signal in_evt20_serializer_in_data_s      : std_logic_vector(READ_DATA_WIDTH_C-1 downto 0);

  -- End of File
  signal in_evt20_stream_reader_out_eof_s   : std_logic;

  signal evt_time_base_s                    : ccam_evt_time_data_t;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  eof_o           <= in_evt20_stream_reader_out_eof_s;

  evt_time_base_s <= std_logic_vector(resize(unsigned(evt_time_base_i), evt_time_base_s'length)) when (USE_TIME_BASE_INPUT) else
                     evt_verification_pkg.evt_verification_time_base_s;


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ---------------------------------------------------
  -- Input File Stream Reader
  -- Reads a file and produces an output data stream.
  file_stream_reader_u : file_stream_reader
  generic map (
    DATA_WIDTH    => READ_DATA_WIDTH_C,
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
    eof_o         => in_evt20_stream_reader_out_eof_s,

    -- Output Data Stream
    out_ready_i   => in_evt20_stream_reader_out_ready_s,
    out_valid_o   => in_evt20_stream_reader_out_valid_s,
    out_last_o    => in_evt20_stream_reader_out_last_s,
    out_data_o    => in_evt20_stream_reader_out_data_s
  );


  ----------------------------------------------------------------------
  -- Sequences events so that they are only issued at the expected time.
  evt20_sequencer_u : evt20_sequencer
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
    rst                    => srst,

    -- Enable
    enable_i               => evt_verification_pkg.evt_verification_time_base_enable_s,

    -- End of File
    reference_eof_i        => in_evt20_stream_reader_out_eof_s,

    -- Synchronization Of Sequencer
    sync_request_i         => sync_request_i,
    sync_ack_o             => sync_ack_o,

    -- Event Time Base (in us)
    evt_time_base_i        => evt_time_base_s,
    cfg_time_high_period_i => std_logic_vector(to_unsigned(EVT_TIME_HIGH_SYNC_PERIOD_US, ccam_evt_time_data_t'length)),

    -- Input Event Stream Interface
    in_ready_o             => in_evt20_stream_reader_out_ready_s,
    in_valid_i             => in_evt20_stream_reader_out_valid_s,
    in_last_i              => in_evt20_stream_reader_out_last_s,
    in_data_i              => in_evt20_sequencer_in_data_s,
    in_vector_i            => in_evt20_sequencer_in_vector_s,

    -- Output Event Stream Interface
    out_ready_i            => in_evt20_sequencer_out_ready_s,
    out_valid_o            => in_evt20_sequencer_out_valid_s,
    out_last_o             => in_evt20_sequencer_out_last_s,
    out_data_o             => in_evt20_sequencer_out_data_s,
    out_vector_o           => in_evt20_sequencer_out_vector_s
  );


  evt2_0_mode_gen : if (not EVT2_1_EN_G) generate

    -- Mapping File Reader Output to Sequencer Input
    in_evt20_sequencer_in_data_s   <= in_evt20_stream_reader_out_data_s(in_evt20_sequencer_in_data_s'range);
    in_evt20_sequencer_in_vector_s <= (others => '-');

    -- Setting Serializer Input as Don't Care as it is unused
    in_evt20_serializer_in_data_s  <= (others => '-');

    -- Mapping the Sequencer Output directly to the Output Data Interface
    in_evt20_sequencer_out_ready_s <= out_ready_i;
    out_valid_o                    <= in_evt20_sequencer_out_valid_s;
    out_last_o                     <= in_evt20_sequencer_out_last_s;
    out_data_o                     <= in_evt20_sequencer_out_data_s;

  end generate evt2_0_mode_gen;


  evt2_1_mode_gen : if (EVT2_1_EN_G) generate

    not_inv_seq_gen : if (not INVERT_EVT21_SEQ_G) generate
      -- Mapping File Reader Output to Sequencer Input
      in_evt20_sequencer_in_data_s   <= in_evt20_stream_reader_out_data_s(in_evt20_sequencer_in_data_s'range);
      in_evt20_sequencer_in_vector_s <= in_evt20_stream_reader_out_data_s(in_evt20_sequencer_in_vector_s'high + in_evt20_sequencer_in_data_s'length downto in_evt20_sequencer_in_data_s'length);
    end generate;

    inv_seq_gen : if (INVERT_EVT21_SEQ_G) generate
      in_evt20_sequencer_in_data_s   <= in_evt20_stream_reader_out_data_s(in_evt20_sequencer_in_vector_s'high + in_evt20_sequencer_in_data_s'length downto in_evt20_sequencer_in_data_s'length);
      in_evt20_sequencer_in_vector_s <= in_evt20_stream_reader_out_data_s(in_evt20_sequencer_in_data_s'range);
    end generate;

    -- Mapping Sequencer Output to Serializer Input
    in_evt20_serializer_in_data_s(in_evt20_sequencer_out_data_s'high + in_evt20_sequencer_out_vector_s'length downto in_evt20_sequencer_out_vector_s'length)  <= in_evt20_sequencer_out_data_s;
    in_evt20_serializer_in_data_s(in_evt20_sequencer_out_vector_s'range)                                                                                      <= in_evt20_sequencer_out_vector_s;


    -----------------------------
    -- AXI4-Stream serializer
    axis_serializer_u : axis_serializer
    generic map (
      IN_DATA_WIDTH  => READ_DATA_WIDTH_C,
      OUT_DATA_WIDTH => OUT_DATA_WIDTH_G,
      LITTLE_ENDIAN  => false
    )
    port map (
      -- Clock and Reset
      clk         => clk,
      arst_n      => arst_n,
      srst        => srst,

      -- Input Interface
      in_ready_o  => in_evt20_sequencer_out_ready_s,
      in_valid_i  => in_evt20_sequencer_out_valid_s,
      in_first_i  => '0',
      in_last_i   => in_evt20_sequencer_out_last_s,
      in_data_i   => in_evt20_serializer_in_data_s,

      -- Output Interface
      out_ready_i => out_ready_i,
      out_valid_o => out_valid_o,
      out_first_o => open,
      out_last_o  => out_last_o,
      out_data_o  => out_data_o
    );

  end generate evt2_1_mode_gen;


end architecture rtl;
