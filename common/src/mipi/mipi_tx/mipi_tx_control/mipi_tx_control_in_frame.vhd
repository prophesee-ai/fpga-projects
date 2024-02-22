----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Vitor Schwambach (vschwambach@chronocam.com)
--
-- Create Date:    Sep. 11, 2017
-- Design Name:    mipi_tx_control_in_frame
-- Module Name:    mipi_tx_control_in_frame
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
-- Input FSM for the Event to MIPI TX Frame Control Block
-- that Manages the MIPI Frame Start/End Frontiers and the
-- insertion of the relative monitoring events.
entity mipi_tx_control_in_frame is
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
end entity mipi_tx_control_in_frame;


architecture rtl of mipi_tx_control_in_frame is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant EVT_SIZE              : positive := ((CCAM_EVT_DATA_BITS + 7) / 8);
  constant EVT30_SIZE            : positive := ((CCAM_EVT_V3_DATA_BITS + 7) / 8);
  constant FRAME_SIZE_DATA_WIDTH : positive := CCAM_CONTINUED_EVT_DATA_BITS;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Configuration Inputs
  signal cfg_evt_format_s        : evt_format_t;
  signal cfg_frame_period_th_q   : unsigned(15 downto 0);

  -- Event Stream Input Interface Signals
  signal evt_in_ready_q          : std_logic;
  signal evt_in_valid_q          : std_logic;
  signal evt_in_first_q          : std_logic;
  signal evt_in_last_q           : std_logic;
  signal evt_in_data_q           : ccam_evt_data_t;

  -- Event Stream Output Interface Signals
  signal evt_out_valid_q         : std_logic;
  signal evt_out_first_q         : std_logic;
  signal evt_out_last_q          : std_logic;
  signal evt_out_frame_start_q   : std_logic;
  signal evt_out_frame_end_q     : std_logic;
  signal evt_out_data_q          : ccam_evt_data_t;

  -- Internal Counters
  signal evt_count_ltdl_q        : unsigned(CCAM_CONTINUED_EVT_DATA_BITS-CCAM_EVT_TYPE_BITS-1 downto 0);
  signal evt_count_ltdh_q        : unsigned(CCAM_CONTINUED_EVT_DATA_BITS-CCAM_EVT_TYPE_BITS-1 downto 0);
  signal frame_th_count_q        : unsigned(15 downto 0);
  signal frame_size_q            : unsigned(FRAME_SIZE_DATA_WIDTH-1 downto 0);

  -- Frame Status
  signal is_frame_open_q         : std_logic;

  -- Internal Time Base Reconstruction
  signal next_th_evt_time_q      : ccam_evt_time_t;
  signal last_tl_evt_time_q      : ccam_evt_v3_tl_t;

  -- FSM State Declarations
  type state_t is (RESET, IDLE, SEND_EVT, SEND_TH_EVT, WAIT_TH_EVT, SEND_END_EVT_COUNT,
                   SEND_END_EVT_COUNT_LTDL, SEND_END_EVT_COUNT_LTDH,
                   SEND_EVT30, SEND_TH_EVT30,SEND_END_EVT_0, SEND_END_EVT_1,
                   SEND_END_EVT30_0, SEND_END_EVT30_1, SEND_END_EVT30_2,
                   SEND_END_EVT30_3, SEND_END_EVT30_4, WAIT_READY);
  signal state_q : state_t;

begin


  -- Assert : fixed frame size don't support raw mode for this moment
  --------------------------------------------------------------------
  assert not(FIXED_FRAME_SIZE_G) or not(cfg_evt_format_s = RAW_DAT_FORMAT)
  report "When fixed frame size mode enable, don't support RAW_DAT_FORMAT"
  severity Failure;


  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Configuration Inputs
  cfg_evt_format_s      <= to_evt_format(cfg_evt_format_i);

  -- Event Stream Input Interface Signals
  evt_in_ready_o        <= evt_in_ready_q;

  -- Event Stream Output Interface Signals
  evt_out_valid_o       <= evt_out_valid_q;
  evt_out_first_o       <= evt_out_first_q;
  evt_out_last_o        <= evt_out_last_q;
  evt_out_frame_start_o <= evt_out_frame_start_q;
  evt_out_frame_end_o   <= evt_out_frame_end_q;
  evt_out_data_o        <= evt_out_data_q;


  ----------------------------------
  -- Synchronous Processes        --
  ----------------------------------

  -- Input FSM Process for the Event to MIPI TX Packet Control Block
  mipi_tx_control_in_frame_p : process(clk, arst_n)
    variable th_evt_v              : ccam_th_evt_t;
    variable th_evt_v3_v           : ccam_evt_v3_th_evt_t;
    variable tl_evt_v3_v           : ccam_evt_v3_tl_evt_t;
    variable other_evt_v           : ccam_other_evt_t;
    variable other_evt_v3_v        : ccam_evt_v3_other_t;
    variable continued_evt_v       : ccam_continued_evt_t;
    variable cont12_evt_v3_v       : ccam_evt_v3_continued_12_t;
    variable cont4_evt_v3_v        : ccam_evt_v3_continued_4_t;
    variable evt_in_ready_v        : std_logic;
    variable evt_in_valid_v        : std_logic;
    variable evt_in_first_v        : std_logic;
    variable evt_in_last_v         : std_logic;
    variable evt_in_data_v         : ccam_evt_data_t;
    variable evt_out_ready_v       : std_logic;
    variable evt_out_valid_v       : std_logic;
    variable evt_out_first_v       : std_logic;
    variable evt_out_last_v        : std_logic;
    variable evt_out_frame_start_v : std_logic;
    variable evt_out_frame_end_v   : std_logic;
    variable evt_out_data_v        : ccam_evt_data_t;
    variable evt_count_ltdl_v      : unsigned(CCAM_CONTINUED_EVT_DATA_BITS-CCAM_EVT_TYPE_BITS-1 downto 0);
    variable evt_count_ltdh_v      : unsigned(CCAM_CONTINUED_EVT_DATA_BITS-CCAM_EVT_TYPE_BITS-1 downto 0);
    variable frame_th_count_v      : unsigned(15 downto 0);
    variable frame_size_v          : unsigned(FRAME_SIZE_DATA_WIDTH-1 downto 0);
    variable is_frame_open_v       : std_logic;
    variable next_th_evt_time_v    : ccam_evt_time_t;
    variable state_v               : state_t;

    procedure reset_p is
    begin
      th_evt_v              := to_ccam_th_evt((others => '0'));
      th_evt_v3_v           := to_ccam_evt_v3_th((others => '0'));
      tl_evt_v3_v           := to_ccam_evt_v3_tl((others => '0'));
      other_evt_v           := to_ccam_other_evt((others => '0'));
      other_evt_v3_v        := to_ccam_evt_v3_other((others => '0'));
      continued_evt_v       := to_ccam_continued_evt((others => '0'));
      cont12_evt_v3_v       := to_ccam_evt_v3_continued_12((others => '0'));
      cont4_evt_v3_v        := to_ccam_evt_v3_continued_4((others => '0'));
      evt_in_ready_v        := '0';
      evt_in_valid_v        := '0';
      evt_in_first_v        := '0';
      evt_in_last_v         := '0';
      evt_in_data_v         := (others => '0');
      evt_out_ready_v       := '0';
      evt_out_valid_v       := '0';
      evt_out_first_v       := '0';
      evt_out_last_v        := '0';
      evt_out_frame_start_v := '0';
      evt_out_frame_end_v   := '0';
      evt_out_data_v        := (others => '0');
      evt_count_ltdl_v      := (others => '0');
      evt_count_ltdh_v      := (others => '0');
      frame_th_count_v      := (others => '0');
      frame_size_v          := (others => '0');
      is_frame_open_v       := '0';
      next_th_evt_time_v    := (others => '0');
      state_v               := RESET;
      cfg_frame_period_th_q <= (others => '1');
      evt_in_ready_q        <= '0';
      evt_in_valid_q        <= '0';
      evt_in_first_q        <= '0';
      evt_in_last_q         <= '0';
      evt_in_data_q         <= (others => '0');
      evt_out_valid_q       <= '0';
      evt_out_first_q       <= '0';
      evt_out_last_q        <= '0';
      evt_out_frame_start_q <= '0';
      evt_out_frame_end_q   <= '0';
      evt_out_data_q        <= (others => '0');
      evt_count_ltdl_q      <= (others => '0');
      evt_count_ltdh_q      <= (others => '0');
      frame_th_count_q      <= (others => '0');
      frame_size_q          <= (others => '0');
      is_frame_open_q       <= '0';
      next_th_evt_time_q    <= (others => '0');
      last_tl_evt_time_q    <= (others => '0');
      state_q               <= RESET;
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Compute Derived Configuration Parameters (Will be updated on the next clock cycle)
        cfg_frame_period_th_q <= to_unsigned(to_integer(unsigned(cfg_frame_period_us_i) / TIME_HIGH_PERIOD), cfg_frame_period_th_q'length);

        -- Reset variables to avoid register inference
        th_evt_v              := to_ccam_th_evt((others => '0'));
        th_evt_v3_v           := to_ccam_evt_v3_th((others => '0'));
        tl_evt_v3_v           := to_ccam_evt_v3_tl((others => '0'));
        other_evt_v           := to_ccam_other_evt((others => '0'));
        other_evt_v3_v        := to_ccam_evt_v3_other((others => '0'));
        continued_evt_v       := to_ccam_continued_evt((others => '0'));
        cont12_evt_v3_v       := to_ccam_evt_v3_continued_12((others => '0'));
        cont4_evt_v3_v        := to_ccam_evt_v3_continued_4((others => '0'));

        -- Load variables from signals or inputs
        evt_in_ready_v        := evt_in_ready_q;
        evt_in_valid_v        := evt_in_valid_q;
        evt_in_first_v        := evt_in_first_q;
        evt_in_last_v         := evt_in_last_q;
        evt_in_data_v         := evt_in_data_q;
        evt_out_ready_v       := evt_out_ready_i;
        evt_out_valid_v       := evt_out_valid_q;
        evt_out_first_v       := evt_out_first_q;
        evt_out_last_v        := evt_out_last_q;
        evt_out_frame_start_v := evt_out_frame_start_q;
        evt_out_frame_end_v   := evt_out_frame_end_q;
        evt_out_data_v        := evt_out_data_q;
        evt_count_ltdl_v      := evt_count_ltdl_q;
        evt_count_ltdh_v      := evt_count_ltdh_q;
        frame_th_count_v      := frame_th_count_q;
        frame_size_v          := frame_size_q;
        is_frame_open_v       := is_frame_open_q;
        next_th_evt_time_v    := next_th_evt_time_q;
        state_v               := state_q;

        -- Ensure that the event input is not overwritten
        assert (not (evt_in_ready_q = '1' and evt_in_valid_i = '1' and evt_in_valid_v = '1')) report "Error: event input has been overwritten." severity failure;

        -- Check if event input should be sampled on this cycle, and sample it if so.
        if (evt_in_ready_v = '1' and evt_in_valid_i = '1') then
          evt_in_valid_v := evt_in_valid_i;
          evt_in_first_v := evt_in_first_i;
          evt_in_last_v  := evt_in_last_i;
          evt_in_data_v  := evt_in_data_i;
        end if;

        -- Check if event output has been sampled, and deassert valid bit if so.
        if (evt_out_ready_v = '1' and evt_out_valid_v = '1') then
          evt_out_valid_v := '0';
        end if;

        -- Determine the next state.
        case (state_v) is

        -- When in the IDLE state or if we've just send an event
        when IDLE | SEND_EVT | SEND_EVT30 | SEND_TH_EVT | SEND_TH_EVT30 | WAIT_READY =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- If we have received a new event, and we have place on both the tx_fifo output and the packet size fifo output,
            -- process the received event.
            if (evt_in_valid_v = '1') then

              -- When in Event 2.0 Format
              if (cfg_evt_format_s = EVT_FORMAT_2_0) then

                -- Check the type of the event to process
                th_evt_v    := to_ccam_th_evt(evt_in_data_v);

                -- If the event is a time high event
                if (th_evt_v.type_f = EVT_TIME_HIGH) then

                  -- If the number of Time High events in the current frame has been reached,
                  -- close the frame and send the packet with the events in it.
                  -- Note that the Time High event itself is left out of the packet and sent in the next packet.
                  if (frame_th_count_v >= cfg_frame_period_th_q) then
                    if FIXED_FRAME_SIZE_G then
                      state_v := SEND_END_EVT_1;
                    else
                      state_v := SEND_END_EVT_COUNT;
                    end if;

                  -- Otherwise, if the frame timeout has not been reached, then simply increment the
                  -- frame time high counters, as well as the frame size.
                  else
                    state_v := SEND_TH_EVT;
                  end if;

                -- If the event received was not a Time High event, then a timeout cannot occur in this implementation.
                -- Then simply increment the frame size and forward the incoming event.
                else
                  state_v := SEND_EVT;
                end if;

              -- When in Event 3.0 Format
              elsif (EVT30_SUPPORT and cfg_evt_format_s = EVT_FORMAT_3_0) then

                -- Check the type of the event to process
                th_evt_v3_v := to_ccam_evt_v3_th(ccam_evt_data_to_ccam_evt_v3_data(evt_in_data_v));

                -- If the event is a time high event
                if (th_evt_v3_v.type_f = EVT_V3_TIME_HIGH) then

                  -- If the number of Time High events in the current frame has been reached,
                  -- close the frame and send the packet with the events in it.
                  -- Note that the Time High event itself is left out of the packet and sent in the next packet.
                  if (frame_th_count_v >= cfg_frame_period_th_q) then
                    if FIXED_FRAME_SIZE_G then
                      state_v := SEND_END_EVT30_4;
                    else
                      state_v := SEND_END_EVT30_0;
                    end if;

                  -- Otherwise, if the frame timeout has not been reached, then simply increment the
                  -- frame time high counters, as well as the frame size.
                  else
                    state_v := SEND_TH_EVT30;
                  end if;

                -- If the event received was not a Time High event, then a timeout cannot occur in this implementation.
                -- Then simply increment the frame size and forward the incoming event.
                else
                  state_v := SEND_EVT30;
                end if;
              else
                state_v := IDLE;
              end if;
            else
              state_v := IDLE;
            end if;

            -- When input is raw data and support it
            if ((cfg_evt_format_s = RAW_DAT_FORMAT) and RAW_MODE_SUPPORT_G and not(FIXED_FRAME_SIZE_G)) then
              -- When frame period arrive, insert end of frame cycle
              if (frame_th_count_v >= cfg_frame_period_th_q) then
                state_v := SEND_END_EVT_1;
              -- When there is input data, send it
              elsif (evt_in_valid_v = '1') then
                state_v := SEND_EVT;
              else
                state_v := IDLE;
              end if;
            end if;
          else
            state_v := WAIT_READY;
          end if;

        -- Send the SYSTEM_OUT_EVENT_COUNT event
        when SEND_END_EVT_COUNT =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then
            -- Proceed to send the second word of the SYSTEM_OUT_EVENT_COUNT event with the LEFT_TD_LOW events.
            state_v := SEND_END_EVT_COUNT_LTDL;
          end if;

        -- Send the SYSTEM_OUT_EVENT_COUNT event with the LEFT_TD_LOW count
        when SEND_END_EVT_COUNT_LTDL =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then
            -- Proceed to send the second word of the SYSTEM_OUT_EVENT_COUNT event with the LEFT_TD_LOW events.
            state_v := SEND_END_EVT_COUNT_LTDH;
          end if;

        -- Send the SYSTEM_OUT_EVENT_COUNT event with the LEFT_TD_HIGH event count
        when SEND_END_EVT_COUNT_LTDH =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then
            -- Proceed to send the first word of the FRAME_END event.
            state_v := SEND_END_EVT_0;
          end if;

        -- When we've sent the first word of the FRAME_END event
        when SEND_END_EVT_0 =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then
            -- Proceed to send the second word of the FRAME_END event with the frame size.
            state_v := SEND_END_EVT_1;
          end if;

        -- If we've just sent the second word of the FRAME_END event with the frame size.
        when SEND_END_EVT_1 =>

          -- We have a pending Time High event that still needs to be sent.
          if (evt_out_valid_v = '0') then
             -- When input is raw data and support it
             if (cfg_evt_format_s = RAW_DAT_FORMAT) and RAW_MODE_SUPPORT_G then
               -- When there is input data, send it
               if (evt_in_valid_v = '1') then
                 state_v := SEND_EVT;
               else
                 state_v := IDLE;
               end if;
             else
              state_v := SEND_TH_EVT;
            end if;
          end if;

        -- When we've sent the first word of the 3.0 FRAME_END event
        when SEND_END_EVT30_0 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then
              -- Proceed to send the second word of the 3.0 FRAME_END event with the frame size.
              state_v := SEND_END_EVT30_1;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            state_v := RESET;
          end if;

        -- When we've sent the second word of the 3.0 FRAME_END event
        when SEND_END_EVT30_1 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then
              -- Proceed to send the third word of the 3.0 FRAME_END event with the frame size.
              state_v := SEND_END_EVT30_2;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            state_v := RESET;
          end if;

        -- When we've sent the third word of the 3.0 FRAME_END event
        when SEND_END_EVT30_2 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then
              -- Proceed to send the fourth word of the 3.0 FRAME_END event with the frame size.
              state_v := SEND_END_EVT30_3;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            state_v := RESET;
          end if;

        -- When we've sent the fourth word of the 3.0 FRAME_END event
        when SEND_END_EVT30_3 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then
              -- Proceed to send the fifth and last word of the 3.0 FRAME_END event with the frame size.
              state_v := SEND_END_EVT30_4;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            state_v := RESET;
          end if;

        -- If we've just sent the fifth and last word of the FRAME_END event with the frame size.
        when SEND_END_EVT30_4 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- We have a pending Time High event that still needs to be sent.
            if (evt_out_valid_v = '0') then
              state_v := SEND_TH_EVT30;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            state_v := RESET;
          end if;

        -- When in a RESET state or any unknown state, perform a reset
        when others =>
          state_v := RESET;
        end case;


        -- Processes the state.
        case (state_v) is

        when IDLE | WAIT_READY =>
          -- Do nothing.

        when SEND_EVT =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v          := frame_size_v + EVT_SIZE;

            -- Check the type of the event to process and increment the event counters according to the event's type
            th_evt_v := to_ccam_th_evt(evt_in_data_v);
            case (th_evt_v.type_f) is
            when LEFT_TD_LOW =>
              evt_count_ltdl_v := evt_count_ltdl_v + 1;
            when LEFT_TD_HIGH =>
              evt_count_ltdh_v := evt_count_ltdh_v + 1;
            when others =>
              -- Do nothing.
            end case;

            -- Transfer event to Event Stream Output
            evt_out_valid_v       := evt_in_valid_v;
            evt_out_first_v       := evt_in_first_v;
            evt_out_last_v        := evt_in_last_v;
            evt_out_frame_start_v := not is_frame_open_v;
            evt_out_frame_end_v   := '0';
            evt_out_data_v        := evt_in_data_v;

            -- Opens the frame if it's not already open
            is_frame_open_v       := '1';

            -- Releases the incoming event
            evt_in_valid_v        := '0';
          end if;

        when SEND_EVT30 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Check the type of the event to process
              tl_evt_v3_v := to_ccam_evt_v3_tl(ccam_evt_data_to_ccam_evt_v3_data(evt_in_data_v));

              -- If the event is a time low event
              if (tl_evt_v3_v.type_f = EVT_V3_TIME_LOW) then
                last_tl_evt_time_q <= tl_evt_v3_v.time_low_f;
              end if;

              -- Increment the frame size
              frame_size_v          := frame_size_v + EVT30_SIZE;

              -- Transfer event to Event Stream Output
              evt_out_valid_v       := evt_in_valid_v;
              evt_out_first_v       := evt_in_first_v;
              evt_out_last_v        := evt_in_last_v;
              evt_out_frame_start_v := not is_frame_open_v;
              evt_out_frame_end_v   := '0';
              evt_out_data_v        := evt_in_data_v;

              -- Opens the frame if it's not already open
              is_frame_open_v       := '1';

              -- Releases the incoming event
              evt_in_valid_v        := '0';
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_TH_EVT =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size and frame time high counters.
            frame_size_v          := frame_size_v + EVT_SIZE;
            frame_th_count_v      := frame_th_count_v + to_unsigned(1, frame_th_count_v'length);

            -- Transfer event to Event Stream Output
            evt_out_valid_v       := evt_in_valid_v;
            evt_out_first_v       := evt_in_first_v;
            evt_out_last_v        := evt_in_last_v;
            evt_out_frame_start_v := not is_frame_open_v;
            evt_out_frame_end_v   := '0';
            evt_out_data_v        := evt_in_data_v;

            -- Opens the frame if it's not already open
            is_frame_open_v       := '1';

            -- Releases the incoming event
            evt_in_valid_v        := '0';

            -- Update internal time base
            th_evt_v              := to_ccam_th_evt(evt_in_data_v);
            if (next_th_evt_time_v(CCAM_TIME_HIGH_MSB downto CCAM_TIME_HIGH_LSB) = th_evt_v.time_high_f) then
              next_th_evt_time_v(CCAM_EVT_TIME_BITS-1 downto 0) := next_th_evt_time_v(CCAM_EVT_TIME_BITS-1 downto 0) + to_unsigned(TIME_HIGH_PERIOD, CCAM_EVT_TIME_BITS);
            else
              next_th_evt_time_v(CCAM_TIME_HIGH_MSB downto CCAM_TIME_HIGH_LSB) := th_evt_v.time_high_f;
              next_th_evt_time_v(CCAM_TIME_LOW_MSB  downto CCAM_TIME_LOW_LSB ) := (others => '0');
            end if;
          end if;

        when SEND_TH_EVT30 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Increment the frame size and frame time high counters.
              frame_size_v          := frame_size_v + EVT30_SIZE;
              frame_th_count_v      := frame_th_count_v + to_unsigned(1, frame_th_count_v'length);

              -- Transfer event to Event Stream Output
              evt_out_valid_v       := evt_in_valid_v;
              evt_out_first_v       := evt_in_first_v;
              evt_out_last_v        := evt_in_last_v;
              evt_out_frame_start_v := not is_frame_open_v;
              evt_out_frame_end_v   := '0';
              evt_out_data_v        := evt_in_data_v;

              -- Opens the frame if it's not already open
              is_frame_open_v       := '1';

              -- Releases the incoming event
              evt_in_valid_v        := '0';

              -- Update internal time base
              th_evt_v3_v := to_ccam_evt_v3_th(ccam_evt_data_to_ccam_evt_v3_data(evt_in_data_v));
              if (next_th_evt_time_v(CCAM_V3_TIME_HIGH_MSB downto CCAM_V3_TIME_HIGH_LSB) = th_evt_v3_v.time_high_f) then
                next_th_evt_time_v(CCAM_EVT_V3_TIME_BITS-1 downto 0) := next_th_evt_time_v(CCAM_EVT_V3_TIME_BITS-1 downto 0) + to_unsigned(TIME_HIGH_PERIOD, CCAM_EVT_V3_TIME_BITS);
              else
                next_th_evt_time_v(CCAM_V3_TIME_HIGH_MSB downto CCAM_V3_TIME_HIGH_LSB) := th_evt_v3_v.time_high_f;
                next_th_evt_time_v(CCAM_V3_TIME_LOW_MSB  downto CCAM_V3_TIME_LOW_LSB ) := (others => '0');
              end if;
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_END_EVT_COUNT =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v          := frame_size_v + EVT_SIZE;

            -- Transfer event to Event Stream Output
            evt_out_valid_v       := '1';
            evt_out_first_v       := '1';
            evt_out_last_v        := '0';
            evt_out_frame_start_v := not is_frame_open_v;
            evt_out_frame_end_v   := '0';

            other_evt_v.type_f    := OTHER;
            other_evt_v.time_f    := next_th_evt_time_v(CCAM_TIME_LOW_MSB downto CCAM_TIME_LOW_LSB) - to_unsigned(1, CCAM_EVT_TIME_LOW_BITS);
            other_evt_v.class_f   := '0';
            other_evt_v.subtype_f := MASTER_SYSTEM_OUT_EVENT_COUNT;
            evt_out_data_v        := to_ccam_evt_data(other_evt_v);

            -- Opens the frame if it's not already open
            is_frame_open_v       := '1';
          end if;

        when SEND_END_EVT_COUNT_LTDL =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v           := frame_size_v + EVT_SIZE;

            -- Transfer event to Event Stream Output
            evt_out_valid_v        := '1';
            evt_out_first_v        := '0';
            evt_out_last_v         := '0';
            evt_out_frame_start_v  := '0';
            evt_out_frame_end_v    := '0';

            continued_evt_v.type_f := CONTINUED;
            continued_evt_v.data_f := std_logic_vector(LEFT_TD_LOW) & std_logic_vector(evt_count_ltdl_v);
            evt_out_data_v         := to_ccam_evt_data(continued_evt_v);

            -- Reset counters
            evt_count_ltdl_v       := (others => '0');
          end if;

        when SEND_END_EVT_COUNT_LTDH =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v           := frame_size_v + EVT_SIZE;

            -- Transfer event to Event Stream Output
            evt_out_valid_v        := '1';
            evt_out_first_v        := '0';
            evt_out_last_v         := '1';
            evt_out_frame_start_v  := '0';
            evt_out_frame_end_v    := '0';

            continued_evt_v.type_f := CONTINUED;
            continued_evt_v.data_f := std_logic_vector(LEFT_TD_HIGH) & std_logic_vector(evt_count_ltdh_v);
            evt_out_data_v         := to_ccam_evt_data(continued_evt_v);

            -- Reset counters
            evt_count_ltdh_v       := (others => '0');
          end if;

        when SEND_END_EVT_0 =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v          := frame_size_v + EVT_SIZE;

            -- Transfer event to Event Stream Output
            evt_out_valid_v       := '1';
            evt_out_first_v       := '1';
            evt_out_last_v        := '0';
            evt_out_frame_start_v := not is_frame_open_v;
            evt_out_frame_end_v   := '0';

            other_evt_v.type_f    := OTHER;
            other_evt_v.time_f    := next_th_evt_time_v(CCAM_TIME_LOW_MSB downto CCAM_TIME_LOW_LSB) - to_unsigned(1, CCAM_EVT_TIME_LOW_BITS);
            other_evt_v.class_f   := '0';
            other_evt_v.subtype_f := MASTER_END_OF_FRAME;
            evt_out_data_v        := to_ccam_evt_data(other_evt_v);

            -- Opens the frame if it's not already open
            is_frame_open_v       := '1';
          end if;

        when SEND_END_EVT_1 =>

          -- Check if we have space to write events out and continue processing if so.
          if (evt_out_valid_v = '0') then

            -- Increment the frame size
            frame_size_v           := frame_size_v + EVT_SIZE;

            -- Transfer event to Event Stream Output
            evt_out_valid_v        := '1';
            evt_out_first_v        := '0';
            evt_out_last_v         := '1';
            evt_out_frame_start_v  := '0';
            evt_out_frame_end_v    := '1';

            continued_evt_v.type_f := CONTINUED;
            continued_evt_v.data_f := std_logic_vector(frame_size_v);
            evt_out_data_v         := to_ccam_evt_data(continued_evt_v);

            -- Closes the frame if it's not already closed and reset counters
            is_frame_open_v        := '0';
            frame_th_count_v       := (others => '0');
            frame_size_v           := (others => '0');
          end if;

        when SEND_END_EVT30_0 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Transfer event to Event Stream Output
              evt_out_valid_v        := '1';
              evt_out_first_v        := '1';
              evt_out_last_v         := '0';
              evt_out_frame_start_v  := not is_frame_open_v;
              evt_out_frame_end_v    := '0';

              tl_evt_v3_v.type_f     := EVT_V3_TIME_LOW;
              tl_evt_v3_v.time_low_f := next_th_evt_time_v(CCAM_V3_TIME_LOW_MSB downto CCAM_V3_TIME_LOW_LSB) - to_unsigned(1, CCAM_EVT_V3_TIME_LOW_BITS);
              evt_out_data_v         := ccam_evt_v3_data_to_ccam_evt_data(to_ccam_evt_v3_data(tl_evt_v3_v));

              -- Check if the time low we want to send is not the same as the last,
              -- in which case, we don't send it again.
              if (last_tl_evt_time_q = tl_evt_v3_v.time_low_f) then
                evt_out_valid_v        := '0';
              end if;

              -- Increment the frame size only if the TIME_LOW should be sent
              -- If the TIME_LOW is the same as the previous, the TIME_LOW will not be sent again, so the
              -- frame size remains unchanged
              if (last_tl_evt_time_q /= tl_evt_v3_v.time_low_f) then
                frame_size_v         := frame_size_v + EVT30_SIZE;
              end if;

              -- Opens the frame if it's not already open
              is_frame_open_v        := '1';
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_END_EVT30_1 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Increment the frame size
              frame_size_v             := frame_size_v + (4 * EVT30_SIZE);

              -- Transfer event to Event Stream Output
              evt_out_valid_v          := '1';
              evt_out_first_v          := '0';
              evt_out_last_v           := '0';
              evt_out_frame_start_v    := '0';
              evt_out_frame_end_v      := '0';

              other_evt_v3_v.type_f    := EVT_V3_OTHER;
              other_evt_v3_v.subtype_f := V3_MASTER_END_OF_FRAME;
              evt_out_data_v           := ccam_evt_v3_data_to_ccam_evt_data(to_ccam_evt_v3_data(other_evt_v3_v));
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_END_EVT30_2 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Construct CONT_12 event with second portion of the frame_size_v field
              cont12_evt_v3_v.type_f   := EVT_V3_CONTINUED_12;
              cont12_evt_v3_v.data_f   := std_logic_vector(frame_size_v(11 downto 0));

              -- Transfer event to Event Stream Output
              evt_out_valid_v          := '1';
              evt_out_first_v          := '0';
              evt_out_last_v           := '0';
              evt_out_frame_start_v    := '0';
              evt_out_frame_end_v      := '0';
              evt_out_data_v           := ccam_evt_v3_data_to_ccam_evt_data(to_ccam_evt_v3_data(cont12_evt_v3_v));
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_END_EVT30_3 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Construct CONT_12 event with second portion of the frame_size_v field
              cont12_evt_v3_v.type_f   := EVT_V3_CONTINUED_12;
              cont12_evt_v3_v.data_f   := std_logic_vector(frame_size_v(23 downto 12));

              -- Transfer event to Event Stream Output
              evt_out_valid_v          := '1';
              evt_out_first_v          := '0';
              evt_out_last_v           := '0';
              evt_out_frame_start_v    := '0';
              evt_out_frame_end_v      := '0';
              evt_out_data_v           := ccam_evt_v3_data_to_ccam_evt_data(to_ccam_evt_v3_data(cont12_evt_v3_v));
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        when SEND_END_EVT30_4 =>

          -- If Event 3.0 is supported, continue
          if (EVT30_SUPPORT) then

            -- Check if we have space to write events out and continue processing if so.
            if (evt_out_valid_v = '0') then

              -- Construct CONT_4 event with last portion of the frame_size_v field
              cont4_evt_v3_v.type_f := EVT_V3_CONTINUED_4;
              cont4_evt_v3_v.data_f := std_logic_vector(frame_size_v(27 downto 24));

              -- Transfer event to Event Stream Output
              evt_out_valid_v       := '1';
              evt_out_first_v       := '0';
              evt_out_last_v        := '1';
              evt_out_frame_start_v := '0';
              evt_out_frame_end_v   := '1';
              evt_out_data_v        := ccam_evt_v3_data_to_ccam_evt_data(to_ccam_evt_v3_data(cont4_evt_v3_v));

              -- Closes the frame if it's not already closed and reset counters
              is_frame_open_v       := '0';
              frame_th_count_v      := (others => '0');
              frame_size_v          := (others => '0');
            end if;

          -- If Event 3.0 is not supported, perform a reset
          else
            reset_p;
          end if;

        -- Reset
        when others =>
          reset_p;
          state_v               := IDLE;
          state_q               <= IDLE;
        end case;

        if (cfg_evt_format_i = RAW_DAT_FORMAT_DATA) and (cfg_evt_time_high_sync_i = '1') and RAW_MODE_SUPPORT_G then
          frame_th_count_v      := frame_th_count_v + to_unsigned(1, frame_th_count_v'length);
        end if;

        -- Updates ready signals
        evt_in_ready_v        := not(evt_in_valid_v) and cfg_enable_i;

        -- Store variables into signals
        evt_in_ready_q        <= evt_in_ready_v;
        evt_in_valid_q        <= evt_in_valid_v;
        evt_in_first_q        <= evt_in_first_v;
        evt_in_last_q         <= evt_in_last_v;
        evt_in_data_q         <= evt_in_data_v;
        evt_out_valid_q       <= evt_out_valid_v;
        evt_out_first_q       <= evt_out_first_v;
        evt_out_last_q        <= evt_out_last_v;
        evt_out_frame_start_q <= evt_out_frame_start_v;
        evt_out_frame_end_q   <= evt_out_frame_end_v;
        evt_out_data_q        <= evt_out_data_v;
        evt_count_ltdl_q      <= evt_count_ltdl_v;
        evt_count_ltdh_q      <= evt_count_ltdh_v;
        frame_th_count_q      <= frame_th_count_v;
        frame_size_q          <= frame_size_v;
        is_frame_open_q       <= is_frame_open_v;
        next_th_evt_time_q    <= next_th_evt_time_v;
        state_q               <= state_v;
      end if;
    end if;
  end process mipi_tx_control_in_frame_p;


end rtl;
