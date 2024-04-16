----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Vitor Schwambach (vschwambach@chronocam.com)
--
-- Create Date:    Mar 29, 2017
-- Design Name:    evt30_sequencer
-- Module Name:    evt30_sequencer
-- Project Name:   ccam2_tep
-- Target Devices: Kintex UltraScale
-- Tool versions:  Xilinx Vivado 2016.4
-- Description:    Sequences events so that they are only issued at
--                 the expected time.
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
use work.ccam_utils.all;
use work.ccam_evt_types_v3.all;
--synthesis translate_off
use work.evt_verification_pkg;
--synthesis translate_on

----------------------------------------------------------------------
-- Sequences events so that they are only issued at the expected time.
entity evt30_sequencer is
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
end evt30_sequencer;

architecture rtl of evt30_sequencer is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant SIM_SYNC_EVENT      : ccam_evt_v3_other_t := (type_f => EVT_V3_OTHER, subtype_f => V3_MASTER_SYSTEM_TB_END_OF_TASK);
  constant SIM_SYNC_EVENT_DATA : ccam_evt_v3_data_t  := to_ccam_evt_v3_data(SIM_SYNC_EVENT);


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input Event Stream Interface Signals
  signal in_ready_q      : std_logic;
  signal in_valid_q      : std_logic;
  signal in_last_q       : std_logic;
  signal in_data_q       : ccam_evt_v3_data_t;

  -- Output Event Stream Interface Signals
  signal out_valid_q     : std_logic;
  signal out_last_q      : std_logic;
  signal out_data_q      : ccam_evt_v3_data_t;

  -- Synchronization Signals
  signal sync_ack_q      : std_logic;

  -- End of File
  signal reference_eof_q : std_logic;

  -- Signal if we should drop next continued event
  signal drop_cont_evt_q : std_logic;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Input Event Stream Interface Signals
  in_ready_o  <= in_ready_q;

  -- Output Event Stream Interface Signals
  out_valid_o <= out_valid_q;
  out_last_o  <= out_last_q;
  out_data_o  <= out_data_q;

  -- Synchronization Signals
  sync_ack_o  <= sync_ack_q;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  evt30_sequencer_p : process(clk, arst_n)
    variable ccam_evt_v           : ccam_evt_v3_t;
    variable ccam_other_evt_v     : ccam_evt_v3_other_t;
    variable ccam_trigger_evt_v   : ccam_evt_v3_ext_trigger_t;
    variable evt_time_v           : ccam_evt_v3_time_t;
    variable next_evt_time_high_v : ccam_evt_v3_time_t;
    variable in_ready_v           : std_logic;
    variable in_valid_v           : std_logic;
    variable in_last_v            : std_logic;
    variable in_data_v            : ccam_evt_v3_data_t;
    variable out_valid_v          : std_logic;
    variable out_last_v           : std_logic;
    variable out_data_v           : ccam_evt_v3_data_t;
    variable is_needed_v          : boolean;
    variable is_type_needed_v     : boolean;
    variable is_subtype_needed_v  : boolean;
    variable is_trigger_needed_v  : boolean;

    procedure reset_p is
    begin
      ccam_evt_v           := to_ccam_evt_v3((ccam_evt_v3_data_t'range => '0'));
      ccam_other_evt_v     := to_ccam_evt_v3_other((ccam_evt_v3_data_t'range => '0'));
      ccam_trigger_evt_v   := to_ccam_evt_v3_ext_trigger((ccam_evt_v3_data_t'range => '0'));
      evt_time_v           := (others => '0');
      next_evt_time_high_v := (others => '0');
      in_ready_v           := '0';
      in_valid_v           := '0';
      in_last_v            := '0';
      in_data_v            := (others => '0');
      out_valid_v          := '0';
      out_last_v           := '0';
      out_data_v           := (others => '0');
      is_needed_v          := false;
      is_type_needed_v     := false;
      is_subtype_needed_v  := false;
      is_trigger_needed_v  := false;
      in_ready_q           <= '0';
      in_valid_q           <= '0';
      in_last_q            <= '0';
      in_data_q            <= (others => '0');
      out_valid_q          <= '0';
      out_last_q           <= '0';
      out_data_q           <= (others => '0');
      sync_ack_q           <= '0';
      reference_eof_q      <= '0';
      drop_cont_evt_q      <= '0';
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        ---------------
        -- Load Data --
        ---------------

        -- Set default data to avoid inferring registers.
        ccam_evt_v          := to_ccam_evt_v3((ccam_evt_v3_data_t'range => '0'));
        ccam_other_evt_v    := to_ccam_evt_v3_other((ccam_evt_v3_data_t'range => '0'));
        ccam_trigger_evt_v  := to_ccam_evt_v3_ext_trigger((ccam_evt_v3_data_t'range => '0'));
        is_needed_v         := false;
        is_type_needed_v    := false;
        is_subtype_needed_v := false;
        is_trigger_needed_v := false;

        -- Load signals into local variables
        in_ready_v          := in_ready_q;
        in_valid_v          := in_valid_q;
        in_last_v           := in_last_q;
        in_data_v           := in_data_q;
        out_valid_v         := out_valid_q;
        out_last_v          := out_last_q;
        out_data_v          := out_data_q;

        -- Assert that we do not have a conflict between incoming data overwriting the pending data
        assert (not (in_ready_v = '1' and in_valid_i = '1' and in_valid_v = '1')) report "Illegal condition found where input is ready while there is pending data." severity failure;

        -------------------
        -- Process Input --
        -------------------

        -- Check if there is new data to be sampled
        if (in_ready_v = '1' and in_valid_i = '1') then

          -- Check whether we should keep the incoming event or discard it.
          in_valid_v := '0';
          ccam_evt_v := to_ccam_evt_v3(in_data_i);
          is_needed_v := false;

          -- Filter events by type
          if (not FILTER_TYPES) then
            is_type_needed_v := true;
          else
            for i in NEEDED_TYPES'range loop
              if (ccam_evt_v.type_f = NEEDED_TYPES(i)) then
                is_type_needed_v := true;
                exit;
              end if;
            end loop;
          end if;

          -- Filter OTHER events by subtype
          is_subtype_needed_v := false;
          if (FILTER_SUBTYPES and ccam_evt_v.type_f = EVT_V3_OTHER) then
            ccam_other_evt_v := to_ccam_evt_v3_other(in_data_i);
            for i in NEEDED_SUBTYPES'range loop
              if (ccam_other_evt_v.subtype_f = NEEDED_SUBTYPES(i)) then
                is_subtype_needed_v := true;
                exit;
              end if;
            end loop;
          else
            is_subtype_needed_v := true;
          end if;

          -- Filter EXT_TRIGGER events by ID
          is_trigger_needed_v := false;
          if (FILTER_TRIGGER_IDS and ccam_evt_v.type_f = EVT_V3_EXT_TRIGGER) then
            ccam_trigger_evt_v := to_ccam_evt_v3_ext_trigger(in_data_i);
            for i in NEEDED_TRIGGER_IDS'range loop
              if (ccam_trigger_evt_v.id_f = NEEDED_SUBTYPES(i)) then
                is_trigger_needed_v := true;
                exit;
              end if;
            end loop;
          else
            is_trigger_needed_v := true;
          end if;

          -- Check if event should be kept or discarded
          is_needed_v := is_type_needed_v and is_subtype_needed_v and is_trigger_needed_v;

          --if (ccam_evt_v.type_f = EVT_V3_IMU_EVT) then
          --  is_needed_v := false;
          --end if;

          -- If the event is not to be discarded, process it
          if (is_needed_v) then
            case (ccam_evt_v.type_f) is
            when EVT_V3_CONTINUED_4 | EVT_V3_CONTINUED_12 =>
              if (drop_cont_evt_q = '0') then
                -- Sample incoming data
                in_valid_v  := in_valid_i;
                in_last_v   := in_last_i;
                in_data_v   := in_data_i;
                is_needed_v := true;
              else
                is_needed_v := false;
              end if;

            when EVT_V3_OTHER =>
              -- Sample incoming data
              in_valid_v  := in_valid_i;
              in_last_v   := in_last_i;
              in_data_v   := in_data_i;
              is_needed_v := true;

            when others =>
              -- Sample incoming data
              in_valid_v  := in_valid_i;
              in_last_v   := in_last_i;
              in_data_v   := in_data_i;
              is_needed_v := true;
            end case;
          end if;

          if (is_needed_v) then
            drop_cont_evt_q <= '0';
          else
            drop_cont_evt_q <= '1';
          end if;
        end if;

        --------------------
        -- Process Output --
        --------------------

        -- Check if output data has been acknowdledge and mark output as free
        if (out_ready_i = '1') then
          out_valid_v := '0';
        end if;

        -- Reset the sync acknowledge when the request is deasserted
        if (sync_request_i = '0') then
          sync_ack_q <= '0';
        end if;


        --------------------------------------
        -- Process Internal Pipeline Stages --
        --------------------------------------

        -- Check if we have space left on the output stage and we have an input event pending
        if (out_valid_v = '0' and in_valid_v = '1') then
          ccam_evt_v := to_ccam_evt_v3(in_data_v);

          case (ccam_evt_v.type_f) is

          when EVT_V3_TIME_HIGH =>

            -- Update the event time
            evt_time_v(CCAM_V3_TIME_HIGH_MSB downto CCAM_V3_TIME_HIGH_LSB) := unsigned(in_data_v(CCAM_EVT_V3_TIME_HIGH_MSB downto CCAM_EVT_V3_TIME_HIGH_LSB));

            -- Check that the newly arrived EVT_TIME_HIGH is in line with the expected value of the time high, otherwise force an update of the next_evt_time_high.
            if (next_evt_time_high_v(CCAM_V3_TIME_HIGH_MSB downto CCAM_V3_TIME_HIGH_LSB) /= unsigned(in_data_v(CCAM_EVT_V3_TIME_HIGH_MSB downto CCAM_EVT_V3_TIME_HIGH_LSB))) then
              next_evt_time_high_v(CCAM_V3_TIME_HIGH_MSB downto CCAM_V3_TIME_HIGH_LSB) := unsigned(in_data_v(CCAM_EVT_V3_TIME_HIGH_MSB downto CCAM_EVT_V3_TIME_HIGH_LSB));
              next_evt_time_high_v(CCAM_V3_TIME_LOW_MSB downto CCAM_V3_TIME_LOW_LSB)   := (others => '0');
            end if;

            -- Check if the event should be sent based on the current time base
            if (signed(unsigned(evt_time_base_i) - next_evt_time_high_v) >= to_signed(0, evt_time_v'length)) then
              out_valid_v          := '1';
              out_last_v           := in_last_v;
              out_data_v           := in_data_v;
              in_valid_v           := '0';
              next_evt_time_high_v := next_evt_time_high_v + unsigned(cfg_time_high_period_i);
            end if;

          when EVT_V3_TIME_LOW =>

            evt_time_v(CCAM_V3_TIME_LOW_MSB downto CCAM_V3_TIME_LOW_LSB) := unsigned(in_data_v(CCAM_V3_TIME_LOW_MSB downto CCAM_V3_TIME_LOW_LSB));

            -- If the event's timestamp is after the current time stamp or if it's a CONTINUED event, send the event
            -- As the CONTINUED event has no timestamp, we always send it.
            if (signed(unsigned(evt_time_base_i) - evt_time_v) >= to_signed(0, evt_time_v'length)) then
              out_valid_v := '1';
              out_last_v  := in_last_v;
              out_data_v  := in_data_v;
              in_valid_v  := '0';
            end if;

          when others =>

            -- If the event's timestamp is after the current time stamp or if it's a CONTINUED event, send the event
            -- As the CONTINUED event has no timestamp, we always send it.
            if (signed(unsigned(evt_time_base_i) - evt_time_v) >= to_signed(0, evt_time_v'length)) then
              out_valid_v := '1';
              out_last_v  := in_last_v;
              out_data_v  := in_data_v;
              in_valid_v  := '0';
            end if;
          end case;
        end if;

        -- If there is still space on the output and we have a valid event, it's because it couldn't be sent, so
        -- it's timestamp is in the future. In this case, we proceed with the acknowledge of the synchronization request.
        if (INSERT_EOT and out_valid_v = '0' and (in_valid_v = '1'
          --synthesis translate_off
            or evt_verification_pkg.evt_verification_time_base_halt_s = '1'
          --synthesis translate_on
            ) and sync_request_i = '1' and sync_ack_q = '0') then
          sync_ack_q      <= '1';
          out_valid_v     := '1';
          out_last_v      := '1';
          out_data_v      := SIM_SYNC_EVENT_DATA;
        end if;

        -- If we reached the end of the file, there is still space on the output and we don't have any valid events anymore,
        -- we send the last synchronization event to signal the end of the file.
        if (INSERT_EOT and out_valid_v = '0' and in_valid_v = '0' and reference_eof_i = '1' and reference_eof_q = '0') then
          reference_eof_q <= reference_eof_i;
          out_valid_v     := '1';
          out_last_v      := '1';
          out_data_v      := SIM_SYNC_EVENT_DATA;
        end if;

        if ((not INSERT_EOT) and (sync_request_i = '1')) then
          sync_ack_q      <= '1';
        end if;

        -- Determine if we will be ready to sample a new input data beat on the next cycle.
        --synthesis translate_off
        if (evt_time_base_i /= (ccam_evt_v3_time_data_t'range => '0') or (evt_verification_pkg.evt_verification_time_base_halt_s = '0')) then
        --synthesis translate_on
            in_ready_v := enable_i and not in_valid_v;
        --synthesis translate_off
        else
          in_ready_v := '0';
        end if;
        --synthesis translate_on

        ----------------
        -- Store Data --
        ----------------

        -- Store variables into signals
        in_ready_q  <= in_ready_v;
        in_valid_q  <= in_valid_v;
        in_last_q   <= in_last_v;
        in_data_q   <= in_data_v;
        out_valid_q <= out_valid_v;
        out_last_q  <= out_last_v;
        out_data_q  <= out_data_v;
      end if;
    end if;
  end process evt30_sequencer_p;

end rtl;
