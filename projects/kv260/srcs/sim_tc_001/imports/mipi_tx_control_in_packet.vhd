----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Vitor Schwambach (vschwambach@chronocam.com)
--
-- Create Date:    Sep. 11, 2017
-- Design Name:    mipi_tx_control_in_packet
-- Module Name:    mipi_tx_control_in_packet
-- Project Name:   ccam4_single_sisley
-- Target Devices: Lattice MachXO3
-- Tool versions:  Diamond 3.9
-- Description:    Generic MIPI TX Packetization of an Event Stream.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;


----------------------------------------------------------
-- Input FSM for the Event to MIPI TX Packet Control Block
entity mipi_tx_control_in_packet is
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
end entity mipi_tx_control_in_packet;


architecture rtl of mipi_tx_control_in_packet is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant EVT_SIZE                   : positive := ((ccam_evt_data_t'length    + 7) / 8);
  constant EVT30_SIZE                 : positive := ((ccam_evt_v3_data_t'length + 7) / 8);
  constant TIME_HIGH_PERIOD_LOG2_C    : natural  := log2(TIME_HIGH_PERIOD);
  constant EVT_SIZE_LOG2_C            : natural  := log2(EVT_SIZE);
  constant EVT30_SIZE_LOG2_C          : natural  := log2(EVT30_SIZE);


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Configuration Inputs
  signal cfg_evt_format_s        : evt_format_t;
  signal cfg_evt_size_s          : positive;
  signal cfg_frame_period_th_s   : unsigned(15 downto 0);
  signal cfg_packet_timeout_th_s : unsigned(15 downto 0);
  signal cfg_packet_size_q       : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
  signal cfg_packet_size_last_q  : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0); -- Last element of the packet
  signal cfg_packet_size_blast_q : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0); -- Before-last element of the packet

  -- Event Stream Input Interface Signals
  signal evt_in_ready_q          : std_logic;
  signal evt_in_valid_q          : std_logic;
  signal evt_in_first_q          : std_logic;
  signal evt_in_last_q           : std_logic;
  signal evt_in_frame_start_q    : std_logic;
  signal evt_in_frame_end_q      : std_logic;
  signal evt_in_data_q           : ccam_evt_data_t;

  -- MIPI TX FIFO Write Interface
  signal fifo_wr_valid_q         : std_logic;
  signal fifo_wr_first_q         : std_logic;
  signal fifo_wr_last_q          : std_logic;
  signal fifo_wr_data_q          : ccam_evt_data_t;

  -- Packet Size Output Interface
  signal packet_size_out_valid_q : std_logic;
  signal packet_size_out_first_q : std_logic;
  signal packet_size_out_last_q  : std_logic;
  signal packet_size_out_data_q  : std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- Internal Counters
  signal frame_th_count_q        : unsigned(15 downto 0);
  signal packet_th_count_q       : unsigned(15 downto 0);
  signal packet_size_q           : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- Frame and Packet Status
  signal is_frame_open_q         : std_logic;
  signal is_packet_open_q        : std_logic;

  -- Smart drop related
  signal evt_drop_q              : std_logic;

  -- Debug visibility Signals
  signal is_time_high_q          : std_logic;

begin


  --------------------------------------------------------------------
  -- Assert : fixed frame size don't support raw mode for this moment
  --------------------------------------------------------------------
  assert not(FIXED_FRAME_SIZE_G) or not(cfg_evt_format_s = RAW_DAT_FORMAT)
  report "When fixed frame size mode enable, don't support RAW_DAT_FORMAT"
  severity Failure;

  assert ((2**TIME_HIGH_PERIOD_LOG2_C) = TIME_HIGH_PERIOD)
  report "TIME_HIGH_PERIOD must be powered 2"
  severity Failure;

  assert ((2**EVT_SIZE_LOG2_C) = EVT_SIZE)
  report "EVT_SIZE must be powered 2"
  severity Failure;

  assert ((2**EVT30_SIZE_LOG2_C) = EVT30_SIZE)
  report "EVT30_SIZE must be powered 2"
  severity Failure;


  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  cfg_evt_format_s        <= to_evt_format(cfg_evt_format_i);
  cfg_evt_size_s          <= EVT30_SIZE when (cfg_evt_format_s = EVT_FORMAT_3_0) else EVT_SIZE;
  evt_in_ready_o          <= evt_in_ready_q;
  fifo_wr_valid_o         <= fifo_wr_valid_q;
  fifo_wr_first_o         <= fifo_wr_first_q;
  fifo_wr_last_o          <= fifo_wr_last_q;
  fifo_wr_data_o          <= fifo_wr_data_q;
  packet_size_out_valid_o <= packet_size_out_valid_q;
  packet_size_out_first_o <= packet_size_out_first_q;
  packet_size_out_last_o  <= packet_size_out_last_q;
  packet_size_out_data_o  <= packet_size_out_data_q;


  ----------------------------------
  -- Synchronous Processes        --
  ----------------------------------

  -- Input FSM Process for the Event to MIPI TX Packet Control Block
  mipi_tx_control_in_packet_p : process(clk, arst_n)
    variable th_evt_v                : ccam_th_evt_t;
    variable th_evt_v3_v             : ccam_evt_v3_th_evt_t;
    variable evt_in_ready_v          : std_logic;
    variable evt_in_valid_v          : std_logic;
    variable evt_in_first_v          : std_logic;
    variable evt_in_last_v           : std_logic;
    variable evt_in_frame_start_v    : std_logic;
    variable evt_in_frame_end_v      : std_logic;
    variable evt_in_data_v           : ccam_evt_data_t;
    variable fifo_wr_valid_v         : std_logic;
    variable fifo_wr_first_v         : std_logic;
    variable fifo_wr_last_v          : std_logic;
    variable fifo_wr_data_v          : ccam_evt_data_t;
    variable is_time_high_v          : std_logic;
    variable packet_size_out_valid_v : std_logic;
    variable packet_size_out_first_v : std_logic;
    variable packet_size_out_last_v  : std_logic;
    variable packet_size_out_data_v  : std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);
    variable frame_th_count_v        : unsigned(15 downto 0);
    variable packet_th_count_v       : unsigned(15 downto 0);
    variable packet_size_v           : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
    variable is_frame_open_v         : std_logic;
    variable is_packet_open_v        : std_logic;
    variable evt_drop_v              : std_logic;

    procedure reset_p is
    begin
      th_evt_v                := to_ccam_th_evt((others => '0'));
      th_evt_v3_v             := to_ccam_evt_v3_th((others => '0'));
      evt_in_ready_v          := '0';
      evt_in_valid_v          := '0';
      evt_in_first_v          := '0';
      evt_in_last_v           := '0';
      evt_in_frame_start_v    := '0';
      evt_in_frame_end_v      := '0';
      evt_in_data_v           := (others => '0');
      fifo_wr_valid_v         := '0';
      fifo_wr_first_v         := '0';
      fifo_wr_last_v          := '0';
      fifo_wr_data_v          := (others => '0');
      is_time_high_v          := '0';
      packet_size_out_valid_v := '0';
      packet_size_out_first_v := '0';
      packet_size_out_last_v  := '0';
      packet_size_out_data_v  := (others => '0');
      frame_th_count_v        := (others => '0');
      packet_th_count_v       := (others => '0');
      packet_size_v           := (others => '0');
      is_frame_open_v         := '0';
      is_packet_open_v        := '0';
      evt_drop_v              := '0';
      cfg_frame_period_th_s   <= (others => '0');
      cfg_packet_timeout_th_s <= (others => '0');
      cfg_packet_size_q       <= (others => '0');
      cfg_packet_size_last_q  <= (others => '0');
      cfg_packet_size_blast_q <= (others => '0');
      evt_in_ready_q          <= '0';
      evt_in_valid_q          <= '0';
      evt_in_first_q          <= '0';
      evt_in_last_q           <= '0';
      evt_in_frame_start_q    <= '0';
      evt_in_frame_end_q      <= '0';
      evt_in_data_q           <= (others => '0');
      fifo_wr_valid_q         <= '0';
      fifo_wr_first_q         <= '0';
      fifo_wr_last_q          <= '0';
      fifo_wr_data_q          <= (others => '0');
      packet_size_out_valid_q <= '0';
      packet_size_out_first_q <= '0';
      packet_size_out_last_q  <= '0';
      packet_size_out_data_q  <= (others => '0');
      frame_th_count_q        <= (others => '0');
      packet_th_count_q       <= (others => '0');
      packet_size_q           <= (others => '0');
      is_frame_open_q         <= '0';
      is_packet_open_q        <= '0';
      evt_drop_q              <= '0';
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Compute Derived Configuration Parameters (Will be updated on the next clock cycle)
        cfg_packet_timeout_th_s <= to_unsigned(to_integer(unsigned(cfg_packet_timeout_us_i) / TIME_HIGH_PERIOD), cfg_packet_timeout_us_i'length);
        cfg_packet_size_q       <= to_unsigned(minimum(to_integer(unsigned(cfg_packet_size_i)), MIPI_MAX_PACKET_SIZE), cfg_packet_size_q'length);
        cfg_packet_size_last_q  <= to_unsigned(minimum(to_integer(unsigned(cfg_packet_size_i)), MIPI_MAX_PACKET_SIZE) - cfg_evt_size_s, cfg_packet_size_last_q'length);
        cfg_packet_size_blast_q <= to_unsigned(minimum(to_integer(unsigned(cfg_packet_size_i)), MIPI_MAX_PACKET_SIZE) - (2 * cfg_evt_size_s), cfg_packet_size_last_q'length);

        -- Reset variables to avoid register inference
        th_evt_v                := to_ccam_th_evt((others => '0'));
        th_evt_v3_v             := to_ccam_evt_v3_th((others => '0'));
        is_time_high_v          := '0';

        -- Load variables from signals
        evt_in_ready_v          := evt_in_ready_q;
        evt_in_valid_v          := evt_in_valid_q;
        evt_in_first_v          := evt_in_first_q;
        evt_in_last_v           := evt_in_last_q;
        evt_in_frame_start_v    := evt_in_frame_start_q;
        evt_in_frame_end_v      := evt_in_frame_end_q;
        evt_in_data_v           := evt_in_data_q;
        fifo_wr_valid_v         := fifo_wr_valid_q;
        fifo_wr_first_v         := fifo_wr_first_q;
        fifo_wr_last_v          := fifo_wr_last_q;
        fifo_wr_data_v          := fifo_wr_data_q;
        packet_size_out_valid_v := packet_size_out_valid_q;
        packet_size_out_first_v := packet_size_out_first_q;
        packet_size_out_last_v  := packet_size_out_last_q;
        packet_size_out_data_v  := packet_size_out_data_q;
        frame_th_count_v        := frame_th_count_q;
        packet_th_count_v       := packet_th_count_q;
        packet_size_v           := packet_size_q;
        is_frame_open_v         := is_frame_open_q;
        is_packet_open_v        := is_packet_open_q;
        evt_drop_v              := '0';

        -- Compute whether next event should be dropped or not
        if (FIXED_FRAME_SIZE_G and (packet_size_v > cfg_packet_size_blast_q)) then
          evt_drop_v              := '1';
        end if;

        -- Ensure that the event input is not overwritten
        assert (not (evt_in_ready_q = '1' and evt_in_valid_i = '1' and evt_in_valid_v = '1')) report "Error: event input has been overwritten." severity failure;

        -- Check if event input should be sampled on this cycle, and sample it if so.
        if (evt_in_ready_v = '1' and evt_in_valid_i = '1') then
          evt_in_valid_v       := evt_in_valid_i;
          evt_in_first_v       := evt_in_first_i;
          evt_in_last_v        := evt_in_last_i;
          evt_in_frame_start_v := evt_in_frame_start_i;
          evt_in_frame_end_v   := evt_in_frame_end_i;
          evt_in_data_v        := evt_in_data_i;
        end if;

        -- Check if packet size output has been sampled, and deassert valid bit if so.
        if (packet_size_out_ready_i = '1' and packet_size_out_valid_v = '1') then
          packet_size_out_valid_v := '0';
        end if;

        -- Check if fifo write output has been sampled, and deassert valid bit if so.
        if (fifo_wr_ready_i = '1' and fifo_wr_valid_v = '1') then
          fifo_wr_valid_v := '0';
        end if;

        -- If we have received a new event, and we have place on both the tx_fifo output and the packet size fifo output,
        -- process the received event.
        if (EVT30_SUPPORT or cfg_evt_format_s /= EVT_FORMAT_3_0) then
          if (evt_in_valid_v = '1' and fifo_wr_valid_v = '0' and packet_size_out_valid_v = '0') then

            -- Check the type of the event to process, is it a 3.0 event?
            if (EVT30_SUPPORT and cfg_evt_format_s = EVT_FORMAT_3_0) then
              th_evt_v3_v := to_ccam_evt_v3_th(ccam_evt_data_to_ccam_evt_v3_data(evt_in_data_v));

              -- Check the event type is TIME HIGH
              if (th_evt_v3_v.type_f = EVT_V3_TIME_HIGH) then
                is_time_high_v  := '1';
              else
                is_time_high_v  := '0';
              end if;

            -- Or else, is it a 2.0 event?
            else

              -- Check the type of the event to process
              th_evt_v := to_ccam_th_evt(evt_in_data_v);

              -- Check the event type is TIME HIGH
              if (th_evt_v.type_f = EVT_TIME_HIGH) then
                is_time_high_v  := '1';
              else
                is_time_high_v  := '0';
              end if;
            end if;

            -- If the event is a time high event and not raw input
            if (is_time_high_v = '1' and not(RAW_MODE_SUPPORT_G and cfg_evt_format_s = RAW_DAT_FORMAT)) then

              -- If the packet timeout has been reached (max. number of Time High events in the current packet has been reached),
              -- close and send the packet with the events in it.
              -- Note that the Time High event itself that triggered the generation of the timeout is left out of the packet and
              -- sent in the next packet.
              if (packet_th_count_v = cfg_packet_timeout_th_s) then

                -- Submit new packet info on the packet size fifo.
                packet_size_out_valid_v := '1';
                packet_size_out_first_v := not is_frame_open_v;
                packet_size_out_last_v  := '0';
                packet_size_out_data_v  := std_logic_vector(packet_size_v);

                -- Update the frame and packet status
                is_frame_open_v         := '1';

                -- Check if it's the end of the current frame
                if (evt_in_frame_end_v = '1') then
                  -- If it's the frame end, we need to send a new packet with a single Time High event in it, but we can't
                  -- do it on this cycle, because we are already submitting the information about the size of the last packet.
                  -- Therefore we retain the Time High event to be processed again on the next cycle.
                  packet_th_count_v       := to_unsigned(0, packet_th_count_v'length);
                  packet_size_v           := to_unsigned(0, packet_size_v'length);
                  is_packet_open_v        := '0';
                else
                  -- Transfer event to FIFO Write Output
                  fifo_wr_valid_v         := evt_in_valid_v;
                  fifo_wr_first_v         := not is_packet_open_v;
                  fifo_wr_last_v          := '0';
                  fifo_wr_data_v          := evt_in_data_v;

                  -- Releases the incoming event
                  evt_in_valid_v          := '0';

                  -- Reset the internal counters.
                  packet_th_count_v       := to_unsigned(1, packet_th_count_v'length);
                  packet_size_v           := to_unsigned(cfg_evt_size_s, packet_size_v'length);
                  is_packet_open_v        := '1';
                end if;

              -- Otherwise, if either the frame end or the target size of the packet have been reached
              -- (max. number of Time High events in the current packet has been reached),
              -- close and send the packet with the events in it.
              elsif (evt_in_frame_end_v = '1' or ((packet_size_q >= cfg_packet_size_last_q) and not(FIXED_FRAME_SIZE_G))) then

                -- Update packet size to include incoming event.
                if (evt_drop_v = '0') then
                  packet_size_v           := packet_size_v + to_unsigned(cfg_evt_size_s, packet_size_v'length);
                end if;

                -- Submit new packet info on the packet size fifo.
                packet_size_out_valid_v := '1';
                packet_size_out_first_v := not is_frame_open_v;
                packet_size_out_last_v  := evt_in_frame_end_v;
                packet_size_out_data_v  := std_logic_vector(packet_size_v);

                -- Transfer event to FIFO Write Output
                if (evt_drop_v = '0') then
                  fifo_wr_valid_v         := evt_in_valid_v;
                else
                  fifo_wr_valid_v         := '0';
                end if;
                fifo_wr_first_v         := not is_packet_open_v;
                fifo_wr_last_v          := '1';
                fifo_wr_data_v          := evt_in_data_v;

                -- Releases the incoming event
                evt_in_valid_v          := '0';

                -- Reset the internal counters.
                packet_th_count_v       := to_unsigned(0, packet_th_count_v'length);
                packet_size_v           := to_unsigned(0, packet_size_v'length);
                is_packet_open_v        := '0';
                is_frame_open_v         := not evt_in_frame_end_v;

              -- Otherwise, if it's neither the frame end nor the packet size or timeout have been reached,
              -- then simply increment the packet time high counters, as well as the packet size and
              -- send the incoming event to the FIFO.
              else
                -- Update the internal counters.
                if (evt_drop_v = '0') then
                  packet_size_v           := packet_size_v + to_unsigned(cfg_evt_size_s, packet_size_v'length);
                end if;
                packet_th_count_v       := packet_th_count_v + to_unsigned(1, packet_th_count_v'length);

                -- Transfer event to FIFO Write Output
                if (evt_drop_v = '0') then
                  fifo_wr_valid_v         := evt_in_valid_v;
                else
                  fifo_wr_valid_v         := '0';
                end if;
                fifo_wr_first_v         := not is_packet_open_v;
                fifo_wr_last_v          := '0';
                fifo_wr_data_v          := evt_in_data_v;

                -- Releases the incoming event
                evt_in_valid_v          := '0';

                -- Update the packet state
                is_packet_open_v        := '1';
              end if;

            -- If the event received was not a Time High event, then a timeout cannot occur.
            -- Thus, simply check for the frame end and the packet size and act accordingly.
            else

              -- If the end of the current frame has been reached or if the packet size has been reached,
              -- close the current packet and send the packet with the events in it.
              -- We check the size of the packet before incrementing the respective variable against the
              -- target packet size minus one so as to reduce the critical path for synthesis.
              if (evt_in_frame_end_v = '1' or ((not FIXED_FRAME_SIZE_G) and packet_size_q >= cfg_packet_size_last_q) or
                  ((not FIXED_FRAME_SIZE_G) and RAW_MODE_SUPPORT_G and cfg_evt_format_s = RAW_DAT_FORMAT and packet_th_count_v >= cfg_packet_timeout_th_s)) then

                -- When is raw data and end of frame, remove last data
                if (not(((RAW_MODE_SUPPORT_G and cfg_evt_format_s = RAW_DAT_FORMAT) or FIXED_FRAME_SIZE_G) and evt_in_frame_end_v = '1')) then

                  -- Transfer event to FIFO Write Output
                  if (evt_drop_v = '0') then

                    -- Update packet size to include incoming event.
                    packet_size_v           := packet_size_v + to_unsigned(cfg_evt_size_s, packet_size_v'length);
                    fifo_wr_valid_v         := evt_in_valid_v;
                  end if;

                  fifo_wr_first_v         := not is_packet_open_v;
                  fifo_wr_last_v          := '1';
                  fifo_wr_data_v          := evt_in_data_v;
                end if;

                -- Submit new packet info on the packet size fifo.
                packet_size_out_valid_v := is_packet_open_v or not(evt_in_frame_end_v);
                packet_size_out_first_v := not is_frame_open_v;
                packet_size_out_last_v  := evt_in_frame_end_v;
                packet_size_out_data_v  := std_logic_vector(packet_size_v);

                -- Releases the incoming event
                evt_in_valid_v          := '0';

                -- Reset the internal counters
                packet_th_count_v       := to_unsigned(0, packet_th_count_v'length);
                packet_size_v           := to_unsigned(0, packet_size_v'length);
                is_packet_open_v        := '0';
                is_frame_open_v         := not evt_in_frame_end_v;

              else

                -- Transfer event to FIFO Write Output
                if (evt_drop_v = '0') then

                  -- Update packet size to include incoming event.
                  packet_size_v           := packet_size_v + to_unsigned(cfg_evt_size_s, packet_size_v'length);
                  fifo_wr_valid_v         := '1';
                end if;
                fifo_wr_first_v         := not is_packet_open_v;
                fifo_wr_last_v          := '0';
                fifo_wr_data_v          := evt_in_data_v;

                -- Releases the incoming event
                evt_in_valid_v          := '0';

                -- Update the packet state
                is_packet_open_v        := '1';
              end if;
            end if;
          end if;
        end if;

        -- If Packet Timeout is Disabled, Reset the Packet Timeout Variable
        -- When fixed frame size mode, always use timeout mode
        if (cfg_enable_packet_timeout_i = '0' and not(FIXED_FRAME_SIZE_G)) then
          packet_th_count_v := (others => '0');

        -- When input is raw data, latch is_time_high_v
        elsif (RAW_MODE_SUPPORT_G and cfg_evt_format_s = RAW_DAT_FORMAT) then
          if cfg_evt_time_high_sync_i = '1' then
            packet_th_count_v       := packet_th_count_v + to_unsigned(1, packet_th_count_v'length);
          end if;
        end if;

        -- Updates ready signals
        evt_in_ready_v          := (not evt_in_valid_v) and cfg_enable_i;

        -- Store variables into signals
        evt_in_ready_q          <= evt_in_ready_v;
        evt_in_valid_q          <= evt_in_valid_v;
        evt_in_first_q          <= evt_in_first_v;
        evt_in_last_q           <= evt_in_last_v;
        evt_in_frame_start_q    <= evt_in_frame_start_v;
        evt_in_frame_end_q      <= evt_in_frame_start_v;
        evt_in_data_q           <= evt_in_data_v;
        fifo_wr_valid_q         <= fifo_wr_valid_v;
        fifo_wr_first_q         <= fifo_wr_first_v;
        fifo_wr_last_q          <= fifo_wr_last_v;
        fifo_wr_data_q          <= fifo_wr_data_v;
        packet_size_out_valid_q <= packet_size_out_valid_v;
        packet_size_out_first_q <= packet_size_out_first_v;
        packet_size_out_last_q  <= packet_size_out_last_v;
        evt_in_frame_start_q    <= evt_in_frame_start_v;
        evt_in_frame_end_q      <= evt_in_frame_end_v;
        packet_size_out_data_q  <= packet_size_out_data_v;
        frame_th_count_q        <= frame_th_count_v;
        packet_th_count_q       <= packet_th_count_v;
        packet_size_q           <= packet_size_v;
        is_frame_open_q         <= is_frame_open_v;
        is_packet_open_q        <= is_packet_open_v;

        -- Debug visibility signals
        evt_drop_q              <= evt_drop_v;
        is_time_high_q          <= is_time_high_v;

      end if;
    end if;
  end process mipi_tx_control_in_packet_p;


end rtl;
