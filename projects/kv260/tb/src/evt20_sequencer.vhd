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
use work.ccam_evt_types.all;
use work.ccam_utils.all;
--synthesis translate_off
use work.evt_verification_pkg;
--synthesis translate_on


----------------------------------------------------------------------
-- Sequences events so that they are only issued at the expected time.
entity evt20_sequencer is
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
end evt20_sequencer;

architecture rtl of evt20_sequencer is

  ------------------------------------
  -- Internal Constant Declarations --
  ------------------------------------

  constant SIM_SYNC_EVENT_C       : ccam_other_evt_t  := (type_f    => OTHER,
                                                          time_f    => (others => '0'),
                                                          unused_f  => (others => '0'),
                                                          class_f   => '1',
                                                          subtype_f => MASTER_SYSTEM_TB_END_OF_TASK);

  constant SIM_SYNC_EVENT_DATA_C  : ccam_evt_data_t   := to_ccam_evt_data(SIM_SYNC_EVENT_C);


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input Event Stream Interface Signals
  signal in_ready_q           : std_logic;
  signal in_valid_q           : std_logic;
  signal in_last_q            : std_logic;
  signal in_data_q            : ccam_evt_data_t;
  signal in_vector_q          : std_logic_vector(31 downto 0);

  -- Output Event Stream Interface Signals
  signal out_valid_q          : std_logic;
  signal out_last_q           : std_logic;
  signal out_data_q           : ccam_evt_data_t;
  signal out_vector_q         : std_logic_vector(31 downto 0);

  signal sync_request_q       : std_logic;
  signal sync_ack_q           : std_logic;

  signal drop_cont_evt_q      : std_logic;

  -- End of File
  signal reference_eof_q      : std_logic;

  -- Time Base Signals
  signal evt_time_q           : ccam_evt_time_t;
  signal next_evt_time_high_q : ccam_evt_time_t;


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Input Event Stream Interface
  in_ready_o    <= in_ready_q;

  -- Output Event Stream Interface
  out_valid_o   <= out_valid_q;
  out_last_o    <= out_last_q;
  out_data_o    <= out_data_q;
  out_vector_o  <= out_vector_q;

  -- Synchronization Of Sequencer
  sync_ack_o  <= sync_ack_q;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  ---------------------------------------------------------------------
  -- Sequences events so that they are only issued at the expected time
  evt20_sequencer_p : process(clk)
    variable ccam_evt_v           : ccam_evt_t;
    variable ccam_evt_last_v      : ccam_evt_t;
    variable ccam_other_evt_v     : ccam_other_evt_t;
    variable ccam_trigger_evt_v   : ccam_ext_trigger_evt_t;
    variable evt_time_v           : ccam_evt_time_t;
    variable next_evt_time_high_v : ccam_evt_time_t;
    variable in_ready_v           : std_logic;
    variable in_valid_v           : std_logic;
    variable in_last_v            : std_logic;
    variable in_data_v            : ccam_evt_data_t;
    variable in_vector_v          : std_logic_vector(31 downto 0);
    variable out_valid_v          : std_logic;
    variable out_last_v           : std_logic;
    variable out_data_v           : ccam_evt_data_t;
    variable out_vector_v         : std_logic_vector(31 downto 0);
    variable is_needed_v          : boolean;
    variable is_type_needed_v     : boolean;
    variable is_subtype_needed_v  : boolean;
    variable is_trigger_needed_v  : boolean;
    variable sync_request_v       : std_logic;

    procedure reset_p is
    begin
      ccam_evt_v           := to_ccam_evt((ccam_evt_data_t'range => '0'));
      ccam_evt_last_v      := to_ccam_evt((ccam_evt_data_t'range => '0'));
      ccam_other_evt_v     := to_ccam_other_evt((ccam_evt_data_t'range => '0'));
      ccam_trigger_evt_v   := to_ccam_ext_trigger_evt((ccam_evt_data_t'range => '0'));
      evt_time_v           := (others => '0');
      next_evt_time_high_v := (others => '0');
      in_ready_v           := '0';
      in_valid_v           := '0';
      in_last_v            := '0';
      in_data_v            := (others => '0');
      in_vector_v          := (others => '0');
      out_valid_v          := '0';
      out_last_v           := '0';
      out_data_v           := (others => '0');
      out_vector_v         := (others => '0');
      is_needed_v          := false;
      is_type_needed_v     := false;
      is_subtype_needed_v  := false;
      is_trigger_needed_v  := false;
      sync_request_v       := '0';
      in_ready_q           <= '0';
      in_valid_q           <= '0';
      in_last_q            <= '0';
      in_data_q            <= (others => '0');
      in_vector_q          <= (others => '0');
      out_valid_q          <= '0';
      out_last_q           <= '0';
      out_data_q           <= (others => '0');
      out_vector_q         <= (others => '0');
      sync_request_q       <= '0';
      sync_ack_q           <= '0';
      drop_cont_evt_q      <= '0';
      reference_eof_q      <= '0';
      evt_time_q           <= (others => '0');
      next_evt_time_high_q <= (others => '0');
    end procedure reset_p;
  begin
    if (rising_edge(clk)) then
      if (rst  = '1') then
        reset_p;
      else

        ---------------
        -- Load Data --
        ---------------

        -- Set default data to avoid inferring registers.
        ccam_evt_v           := to_ccam_evt((ccam_evt_data_t'range => '0'));
        ccam_evt_last_v      := to_ccam_evt((ccam_evt_data_t'range => '0'));
        ccam_other_evt_v     := to_ccam_other_evt((ccam_evt_data_t'range => '0'));
        ccam_trigger_evt_v   := to_ccam_ext_trigger_evt((ccam_evt_data_t'range => '0'));
        is_needed_v          := false;
        is_type_needed_v     := false;
        is_subtype_needed_v  := false;
        is_trigger_needed_v  := false;

        -- Load signals into local variables
        in_ready_v           := in_ready_q;
        in_valid_v           := in_valid_q;
        in_last_v            := in_last_q;
        in_data_v            := in_data_q;
        in_vector_v          := in_vector_q;
        out_valid_v          := out_valid_q;
        out_last_v           := out_last_q;
        out_data_v           := out_data_q;
        out_vector_v         := out_vector_q;
        sync_request_v       := sync_request_q;
        evt_time_v           := evt_time_q;
        next_evt_time_high_v := next_evt_time_high_q;

        -- Assert that we do not have a conflict between incoming data overwriting the pending data
        assert (not (in_ready_v = '1' and in_valid_i = '1' and in_valid_v = '1')) report "Illegal condition found where input is ready while there is pending data." severity failure;

        -- Register the sync_request incoming signal
        if (sync_request_i = '1' and sync_ack_q = '0') then
          sync_request_v := '1';
        end if;

        -- Reset the sync acknowledge when the request is deasserted
        if (sync_request_i = '0') then
          sync_ack_q <= '0';
        end if;

        -------------------
        -- Process Input --
        -------------------

        -- Check if there is new data to be sampled
        if (in_ready_v = '1' and in_valid_i = '1') then
          -- Sample incoming data
          in_valid_v    := in_valid_i;
          in_last_v     := in_last_i;
          in_data_v     := in_data_i;
          in_vector_v   := in_vector_i;
        end if;

        --------------------
        -- Process Output --
        --------------------

        -- Check if output data has been acknowdledge and mark output as free
        if (out_ready_i = '1') then
          out_valid_v := '0';
        end if;

        --------------------------------------
        -- Process Internal Pipeline Stages --
        --------------------------------------

        if (enable_i = '1' and in_valid_v = '1' and out_valid_v = '0') then
          ccam_evt_v := to_ccam_evt(in_data_v);

          case (ccam_evt_v.type_f) is

          when EVT_TIME_HIGH =>
            -- Check that the newly arrived EVT_TIME_HIGH is in line with the expected value of the time high, otherwise force an update of the next_evt_time_high.
            if (next_evt_time_high_v(CCAM_TIME_HIGH_MSB downto CCAM_TIME_HIGH_LSB) /= unsigned(in_data_v(CCAM_EVT_TIME_HIGH_MSB downto CCAM_EVT_TIME_HIGH_LSB))) then
              next_evt_time_high_v(CCAM_TIME_HIGH_MSB downto CCAM_TIME_HIGH_LSB) := unsigned(in_data_v(CCAM_EVT_TIME_HIGH_MSB downto CCAM_EVT_TIME_HIGH_LSB));
              next_evt_time_high_v(CCAM_TIME_LOW_MSB  downto CCAM_TIME_LOW_LSB ) := (others => '0');
            end if;

            -- Update the event time
            evt_time_v := next_evt_time_high_v;

            -- Check if the event should be sent based on the current time base
            if (signed(unsigned(evt_time_base_i) - evt_time_v) >= to_signed(0, evt_time_v'length)) then
              out_valid_v          := '1';
              out_last_v           := in_last_v;
              out_data_v           := in_data_v;
              out_vector_v         := in_vector_v;
              in_valid_v           := '0';
              next_evt_time_high_v := next_evt_time_high_v + unsigned(cfg_time_high_period_i);
            elsif (sync_request_v = '1' and sync_ack_q = '0' and INSERT_EOT) then
              sync_ack_q           <= '1';
              sync_request_v       := '0';
              out_valid_v          := '1';
              out_last_v           := '1';
              out_data_v           := SIM_SYNC_EVENT_DATA_C;
            end if;

            drop_cont_evt_q      <= '1';

          when others =>
            -- Discard event.
            in_valid_v  := '0';

            -- Filter events by type
            is_type_needed_v := false;
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
            if (FILTER_SUBTYPES and ccam_evt_v.type_f = OTHER) then
              ccam_other_evt_v := to_ccam_other_evt(in_data_v);
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
            if (FILTER_TRIGGER_IDS and ccam_evt_v.type_f = EXT_TRIGGER) then
              ccam_trigger_evt_v := to_ccam_ext_trigger_evt(in_data_v);
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

            if (ccam_evt_last_v.type_f = IMU_EVT) then
              drop_cont_evt_q <= '1';
            end if;

            -- If the event is not to be discarded, process it
            if (is_needed_v) then
              -- CONTINUED event has no timestamp, we always send it when the previous event was sent
              if (ccam_evt_v.type_f = CONTINUED) then
                if (drop_cont_evt_q = '0') then
                  out_valid_v     := '1';
                  out_last_v      := in_last_v;
                  out_data_v      := in_data_v;
                  out_vector_v    := in_vector_v;
                  in_valid_v      := '0';
                  drop_cont_evt_q <= '0';
                else
                  drop_cont_evt_q <= '1';
                end if;
              else
                evt_time_v(CCAM_TIME_LOW_MSB downto CCAM_TIME_LOW_LSB) := unsigned(in_data_v(CCAM_EVT_TIME_LOW_MSB downto CCAM_EVT_TIME_LOW_LSB));
                if ((signed(unsigned(evt_time_base_i) - evt_time_v) >= to_signed(0, evt_time_v'length))) then
                  out_valid_v     := '1';
                  out_last_v      := in_last_v;
                  out_data_v      := in_data_v;
                  out_vector_v    := in_vector_v;
                  in_valid_v      := '0';
                  drop_cont_evt_q <= '0';
                elsif (sync_request_v = '1' and sync_ack_q = '0' and INSERT_EOT) then
                  sync_ack_q      <= '1';
                  sync_request_v  := '0';
                  out_valid_v     := '1';
                  out_last_v      := '1';
                  out_data_v      := SIM_SYNC_EVENT_DATA_C;
                  in_valid_v      := '1';
                  drop_cont_evt_q <= '1';
                else
                  in_valid_v      := '1';
                  drop_cont_evt_q <= '0';
                end if;
              end if;
            else
              drop_cont_evt_q <= '1';
            end if;
          end case;

          -- Last event updated
          if (ccam_evt_v.type_f /= CONTINUED) then
            ccam_evt_last_v := ccam_evt_v;
          end if;
        elsif (reference_eof_i = '1' and reference_eof_q = '0' and out_valid_v = '0' and INSERT_EOT) then
          reference_eof_q <= reference_eof_i;
          out_valid_v     := '1';
          out_last_v      := '1';
          out_data_v      := SIM_SYNC_EVENT_DATA_C;
          drop_cont_evt_q <= '1';
        elsif (sync_request_v = '1' and sync_ack_q = '0' and out_valid_v = '0') then
          sync_ack_q      <= '1';
          sync_request_v  := '0';
          if (INSERT_EOT) then
            out_valid_v     := '1';
          else
            out_valid_v     := '0';
          end if;
          out_last_v      := '1';
          out_data_v      := SIM_SYNC_EVENT_DATA_C;
          drop_cont_evt_q <= '1';
        end if;

        -- Determine if we will be ready to sample a new input data beat on the next cycle.
        --synthesis translate_off
        if (evt_time_base_i /= (ccam_evt_time_data_t'range => '0') or (evt_verification_pkg.evt_verification_time_base_halt_s = '0')) then
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
        in_ready_q           <= in_ready_v;
        in_valid_q           <= in_valid_v;
        in_last_q            <= in_last_v;
        in_data_q            <= in_data_v;
        in_vector_q          <= in_vector_v;
        out_valid_q          <= out_valid_v;
        out_last_q           <= out_last_v;
        out_data_q           <= out_data_v;
        out_vector_q         <= out_vector_v;
        sync_request_q       <= sync_request_v;
        evt_time_q           <= evt_time_v;
        next_evt_time_high_q <= next_evt_time_high_v;
      end if;
    end if;
  end process evt20_sequencer_p;

end rtl;
