----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
--
-- Create Date:    Nov. 16, 2023
-- Design Name:    evt21_th_recovery
-- Module Name:    evt21_th_recovery
-- Project Name:   psee_generic
-- Target Devices: Zynq US
-- Tool versions:  Xilinx Vivado 2022.2
-- Description:    Checks incoming Time High events and recover them if an
--                 incoherence is detected.
--                 This block's purpose is to avoid issues in event stream
--                 synchronization from different event sources.
--                 This module is heritance from evt20_th_recovery
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
use work.ccam_utils_pkg.all;
use work.ccam_evt_type_v2_1_pkg.all;


----------------------------------------------------------
-- Checks incoming Time High events and recover them if an
-- incoherence is detected.
entity evt21_th_recovery is
  generic (
    TIME_HIGH_PERIOD_US : positive := 16;
    TIME_BASE_INIT_MS   : natural  := 0
  );
  port (
    -- Clock and Reset
    clk              : in std_logic;
    arst_n           : in std_logic;
    srst             : in std_logic;

    -- Configuration Interface
    cfg_enable_i               : in  std_logic_vector(0 downto 0);
    cfg_bypass_i               : in  std_logic_vector(0 downto 0);
    cfg_gen_missing_th_i       : in  std_logic_vector(0 downto 0);
    cfg_enable_drop_evt_i      : in  std_logic_vector(0 downto 0);
    cfg_gen_other_evt_i        : in  std_logic_vector(0 downto 0);
    stat_gen_th_flag_o         : out std_logic_vector(0 downto 0);
    stat_gen_th_flag_clear_i   : in  std_logic;
    stat_evt_drop_flag_o       : out std_logic_vector(0 downto 0);
    stat_evt_drop_flag_clear_i : in  std_logic;   

    -- Input Interfaces
    in_ready_o       : out std_logic;
    in_valid_i       : in  std_logic;
    in_last_i        : in  std_logic;
    in_data_i        : in  std_logic_vector(63 downto 0);

    -- Output Interface
    out_ready_i      : in  std_logic;
    out_valid_o      : out std_logic;
    out_last_o       : out std_logic;
    out_data_o       : out std_logic_vector(63 downto 0)
  );
end evt21_th_recovery;

architecture rtl of evt21_th_recovery is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant TH_PERIOD_US : ccam_evt_v2_1_time_t := to_unsigned(TIME_HIGH_PERIOD_US, CCAM_EVT_2_1_TIME_BITS);
  constant INIT_TIME_C  : unsigned(CCAM_EVT_2_1_TIME_BITS-1 downto 0) := resize(to_unsigned(TIME_BASE_INIT_MS, CCAM_EVT_2_1_TIME_BITS) * to_unsigned(1000, 10), CCAM_EVT_2_1_TIME_BITS);

  -----------------------
  -- Type Declarations --
  -----------------------

  type state_t is (RESET, IDLE, SEND_EVT, SEND_TH, SEND_CONTINUED, GEN_TH_FROM_TH, GEN_TH_FROM_EVT, DROP_EVT, DROP_EVT_AND_NEXT);

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal in_ready_q  : std_logic;
  signal in_valid_q  : std_logic;
  signal in_last_q   : std_logic;
  signal in_data_q   : ccam_evt_v2_1_data_t;

  signal th_last_q   : ccam_evt_v2_1_time_t;
  signal th_next_q   : ccam_evt_v2_1_time_t;
  signal th_detect_q : std_logic;

  signal evt_ts_q    : ccam_evt_v2_1_time_t;
  signal stat_drop_q : std_logic;
  signal stat_gen_q  : std_logic;
  signal state_q     : state_t;

  signal out_valid_q : std_logic;
  signal out_last_q  : std_logic;
  signal out_data_q  : ccam_evt_v2_1_data_t;
  
  signal last_time_low_q : ccam_evt_v2_1_time_low_t;

  ----------------------------------------
  -- Debug attributes
  attribute mark_debug : string;
  attribute mark_debug of cfg_enable_i     : signal is "true";
  attribute mark_debug of cfg_bypass_i     : signal is "true";
  attribute mark_debug of in_ready_o       : signal is "true";
  attribute mark_debug of in_valid_i       : signal is "true";
  attribute mark_debug of in_last_i        : signal is "true";
  attribute mark_debug of in_data_i        : signal is "true";
  attribute mark_debug of out_ready_i      : signal is "true";
  attribute mark_debug of out_valid_o      : signal is "true";
  attribute mark_debug of out_last_o       : signal is "true";
  attribute mark_debug of out_data_o       : signal is "true";
  attribute mark_debug of stat_drop_q      : signal is "true";
  attribute mark_debug of stat_gen_q       : signal is "true";

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  in_ready_o  <= in_ready_q;
  out_valid_o <= out_valid_q;
  out_last_o  <= out_last_q;
  out_data_o  <= out_data_q;
  
  stat_gen_th_flag_o(0)   <= stat_gen_q;
  stat_evt_drop_flag_o(0) <= stat_drop_q;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  -- CCAM event stream handler process
  -- Reads the input events, reformats and attaches the timestamp, then outputs the event.
  evt_merge_p : process(clk, arst_n)
    variable evt_v       : ccam_evt_v2_1_t;
    variable evt_ts_v    : ccam_evt_v2_1_time_t;
    variable th_evt_v    : ccam_th_evt_v2_1_t;
    variable in_ready_v  : std_logic;
    variable in_valid_v  : std_logic;
    variable in_last_v   : std_logic;
    variable in_data_v   : ccam_evt_v2_1_data_t;
    variable th_last_v   : ccam_evt_v2_1_time_t;
    variable th_next_v   : ccam_evt_v2_1_time_t;
    variable th_diff_v   : signed(ccam_evt_v2_1_time_high_t'range);
    variable state_v     : state_t;
    variable out_valid_v : std_logic;
    variable out_last_v  : std_logic;
    variable out_data_v  : ccam_evt_v2_1_data_t;
    variable other_evt_v : ccam_other_evt_v2_1_t;

    procedure reset_p is
    begin
      evt_v       := to_ccam_evt_v2_1((others => '0'));
      evt_ts_v    := (others => '0');
      th_evt_v    := to_ccam_th_evt_v2_1((others => '0'));
      in_ready_v  := '0';
      in_valid_v  := '0';
      in_last_v   := '0';
      in_data_v   := (others => '0');
      th_last_v   := (others => '0');
      th_next_v   := (others => '0');
      th_diff_v   := (others => '0');
      state_v     := RESET;
      out_valid_v := '0';
      out_last_v  := '0';
      out_data_v  := (others => '0');
      in_ready_q  <= '0';
      in_valid_q  <= '0';
      in_last_q   <= '0';
      in_data_q   <= (others => '0');
      th_last_q   <= (others => '0');
      th_next_q   <= INIT_TIME_C;
      evt_ts_q    <= (others => '0');
      stat_drop_q <= '0';
      stat_gen_q  <= '0';
      state_q     <= RESET;
      out_valid_q <= '0';
      out_last_q  <= '0';
      out_data_q  <= (others => '0');
      last_time_low_q      <= (others => '0');   
      th_detect_q <= '0';   
      
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Reset variables to avoid latch inference
        evt_v       := to_ccam_evt_v2_1((others => '0'));
        th_evt_v    := to_ccam_th_evt_v2_1((others => '0'));
        th_diff_v   := (others => '0');

        -- Update variables
        in_ready_v  := in_ready_q;
        in_valid_v  := in_valid_q;
        in_last_v   := in_last_q;
        in_data_v   := in_data_q;
        th_last_v   := th_last_q;
        th_next_v   := th_next_q;
        evt_ts_v    := evt_ts_q;
        state_v     := state_q;
        out_valid_v := out_valid_q;
        out_last_v  := out_last_q;
        out_data_v  := out_data_q;

        -- Sample input data
        if (in_ready_v = '1' and in_valid_i = '1') then
          in_valid_v := in_valid_i;
          in_last_v  := in_last_i;
          in_data_v  := in_data_i;
        end if;

        -- Check if output data has been acknowledged and release output
        if (out_ready_i = '1') then
          out_valid_v := '0';
        end if;

        -- If the output is free and we have input events to process, process the incoming events
        if (out_valid_v = '0' and in_valid_v = '1') then

          -- Check if not bypass continue processing, otherwise, just forward the event
          if (cfg_bypass_i(0) = '0') then

            -- Converts the incoming event data into a CCAM event record
            evt_v := to_ccam_evt_v2_1(in_data_v);

            -- Check the if the event is a TIME HIGH event
            if (evt_v.type_f = EVT_2_1_TIME_HIGH) then
            
              -- Converts the incoming event data into a TIME HIGH event record
              th_evt_v := to_ccam_th_evt_v2_1(in_data_v);            
              
              if(th_detect_q = '0') then
                -- First Time High in pipeline, update now the th_next variable
                th_next_v(CCAM_EVT_2_1_TIME_HIGH_DATA_MSB downto CCAM_EVT_2_1_TIME_HIGH_DATA_LSB) := th_evt_v.time_high_f;
                -- Update TH_detect flag
                th_detect_q <= '1';
              end if;                            
              
              -- Compute the difference between the TH arriving and the predicted next TH, to find out
              -- whether we are aligned with expected, or if we've had a jump forward or backward in time
              th_diff_v := signed(unsigned(th_evt_v.time_high_f) - unsigned(th_next_v(CCAM_EVT_2_1_TIME_HIGH_DATA_MSB downto CCAM_EVT_2_1_TIME_HIGH_DATA_LSB)));
              
              -- Check if the incoming TIME HIGH event has the same value as expected, and if so proceed normally
              if (th_diff_v = 0) or (th_diff_v > 0 and cfg_gen_missing_th_i(0) = '0') or (th_diff_v < 0 and cfg_enable_drop_evt_i(0) = '0') then

                -- Forward the event to the output
                out_valid_v := in_valid_v;
                out_last_v  := in_last_v;
                out_data_v  := in_data_v;

                -- Update next time high value
                th_last_v   := th_next_v;
                th_next_v   := th_next_v + TIME_HIGH_PERIOD_US;

                -- Release the input event
                in_valid_v  := '0';

                -- Set the state
                state_v     := SEND_TH;

              -- If not, confirm that it is higher than the expected value and regenerate missing TIME_HIGH event.
              -- This process will be repeated until the expected value catches up the received value.
              elsif (th_diff_v > 0) then

                -- Generate new TIME HIGH event with the next expected TIME HIGH value
                th_evt_v.type_f      := EVT_2_1_TIME_HIGH;
                th_evt_v.time_high_f := th_next_v(CCAM_EVT_2_1_TIME_HIGH_DATA_MSB downto CCAM_EVT_2_1_TIME_HIGH_DATA_LSB);

                -- Forward the newly generated TIME HIGH event to the output, if not in bypass mode
                out_valid_v := in_valid_v;
                out_last_v  := in_last_v;
                out_data_v  := to_ccam_evt_v2_1_data(th_evt_v);

                -- Update next time high value
                th_last_v   := th_next_v;
                th_next_v   := th_next_v + TIME_HIGH_PERIOD_US;

                -- Do not release the incoming TIME HIGH event yet!

                -- Set the state
                state_v     := GEN_TH_FROM_TH;

              -- Otherwise, there was a jump backward in time, so drop the event and all subsequent events
              else
              
                -- Insert special OTHER evt if enable
                if cfg_gen_other_evt_i(0) = '1' then
                  other_evt_v.type_f    := EVT_2_1_OTHERS;
                  other_evt_v.time_f    := last_time_low_q;
                  other_evt_v.subtype_f := MASTER_TH_DROP_EVENT;
                  other_evt_v.unused_f   := (others => '0');
                  other_evt_v.class_f    := '0';
                  other_evt_v.cont_type_f:= EVT_2_1_CONTINUED;
                  other_evt_v.cont_data_f:= (others => '0');    
                  
                  -- Drop the input event
                  in_valid_v            := '0';
                  
                  out_valid_v           := '1';
                  out_last_v            := in_last_v;
                  out_data_v            := to_ccam_evt_v2_1_data(other_evt_v);
                  
                  -- Set the state
                  if (in_last_v = '1') then
                    state_v     := DROP_EVT;
                  else
                    state_v     := DROP_EVT_AND_NEXT;
                  end if;
                else
                  -- Drop the input event
                  in_valid_v  := '0';
    
                  -- Set the state
                  if (in_last_v = '1') then
                    state_v     := DROP_EVT;
                  else
                    state_v     := DROP_EVT_AND_NEXT;
                  end if;
                end if;
              end if;
              
            elsif (state_v = DROP_EVT_AND_NEXT) then

              -- Drop the input event
              in_valid_v  := '0';

              -- Set the state
              if (in_last_v = '1') then
                state_v     := DROP_EVT;
              else
                state_v     := DROP_EVT_AND_NEXT;
              end if;

            elsif (evt_v.type_f = EVT_2_1_CONTINUED) then

              -- Forward the event to the output
              out_valid_v := in_valid_v;
              out_last_v  := in_last_v;
              out_data_v  := in_data_v;

              -- Release the input event
              in_valid_v  := '0';

              -- Set the state
              state_v     := SEND_CONTINUED;

            -- Otherwise, for all other event types
            else
              
              -- Reconstruct the event's full time stamp
              evt_ts_v := th_last_v;
              evt_ts_v(CCAM_EVT_2_1_TIME_LOW_DATA_MSB downto CCAM_EVT_2_1_TIME_LOW_DATA_LSB) := unsigned(in_data_v(CCAM_EVT_2_1_TIME_LOW_MSB  downto CCAM_EVT_2_1_TIME_LOW_LSB));
              
              -- if first Time High in the pipeline is not detected yet, just forward the inputs to outputs
              if(th_detect_q = '0') then
                -- Forward the event to the output
                out_valid_v := in_valid_v;
                out_last_v  := in_last_v;
                out_data_v  := in_data_v;

                -- Release the input event
                in_valid_v  := '0';

                -- Set the state
                state_v     := SEND_EVT;
                
              else
                
                -- update time low only if not CONTINUED event
                if (evt_v.type_f /= EVT_2_1_CONTINUED) then
                  last_time_low_q <= evt_v.time_f;
                end if;
    
                -- Check if the event's time stamp is behind that of the last TIME HIGH event time stamp, and drop it if so.
                if (signed(evt_ts_v - th_last_v) < to_signed(0, ccam_evt_v2_1_time_t'length)) and cfg_enable_drop_evt_i(0) = '1' then
                
                  -- Insert special OTHER evt if enable
                  if cfg_gen_other_evt_i(0) = '1' then
                    other_evt_v.type_f    := EVT_2_1_OTHERS;
                    other_evt_v.time_f    := evt_v.time_f;
                    other_evt_v.subtype_f := MASTER_TH_DROP_EVENT;
                    other_evt_v.unused_f   := (others => '0');
                    other_evt_v.class_f    := '0';
                    other_evt_v.cont_type_f:= EVT_2_1_CONTINUED;
                    other_evt_v.cont_data_f:= (others => '0'); 
                    
                    -- Drop the input event
                    in_valid_v            := '0';
                    
                    out_valid_v           := '1';
                    out_last_v            := in_last_v;
                    out_data_v            := to_ccam_evt_v2_1_data(other_evt_v);
                    
                    -- Set the state
                    if (in_last_v = '1') then
                      state_v     := DROP_EVT;
                    else
                      state_v     := DROP_EVT_AND_NEXT;
                    end if;
                  else
                    -- Drop the input event, since it would violate the protocol timing
                    in_valid_v  := '0';
    
                    -- Set the state
                    if (in_last_v = '1') then
                      state_v     := DROP_EVT;
                    else
                      state_v     := DROP_EVT_AND_NEXT;
                    end if;
                  end if;
    
                -- Check if the event's time stamp is ahead or equal to the next TIME HIGH time stamp, and generate a new TIME HIGH event if so.
                elsif (signed(th_next_v - evt_ts_v) <= to_signed(0, ccam_evt_v2_1_time_t'length)) and cfg_gen_missing_th_i(0) = '1' then
    
                  -- Generate new TIME HIGH event with the next expected TIME HIGH value
                  th_evt_v.type_f      := EVT_2_1_TIME_HIGH;
                  th_evt_v.time_high_f := th_next_v(CCAM_EVT_2_1_TIME_HIGH_DATA_MSB downto CCAM_EVT_2_1_TIME_HIGH_DATA_LSB);
    
                  -- Forward the newly generated TIME HIGH event to the output, if not in bypass mode
                  out_valid_v := in_valid_v;
                  out_last_v  := in_last_v;
                  out_data_v  := to_ccam_evt_v2_1_data(th_evt_v);
    
                  -- Update next time high value
                  th_last_v   := th_next_v;
                  th_next_v   := th_next_v + TIME_HIGH_PERIOD_US;
    
                  -- Do not release the incoming TIME HIGH event yet!
    
                  -- Set the state
                  state_v     := GEN_TH_FROM_EVT;
    
                -- If the event's time stamp is neither behind the last TIME HIGH time stamp,
                -- nor ahead of the next TIME HIGH time stamp, then forward it.
                else
                  -- Forward the event to the output
                  out_valid_v := in_valid_v;
                  out_last_v  := in_last_v;
                  out_data_v  := in_data_v;
    
                  -- Release the input event
                  in_valid_v  := '0';
    
                  -- Set the state
                  state_v     := SEND_EVT;
                end if;
              end if;
            end if;

          -- For event stream format other than 2.1, bypass the Time High Recovery logic and
          -- forward incoming events.
          else

            -- Forward the event to the output
            out_valid_v := in_valid_v;
            out_last_v  := in_last_v;
            out_data_v  := in_data_v;

            -- Release the input event
            in_valid_v  := '0';

            -- Set the state
            state_v     := SEND_EVT;
          end if;
        else
         -- state_v := IDLE;
        end if;

        -- Derive the input interface's ready signal
        in_ready_v  := cfg_enable_i(0) and (not in_valid_v);

        -- Update variables
        in_ready_q  <= in_ready_v;
        in_valid_q  <= in_valid_v;
        in_last_q   <= in_last_v;
        in_data_q   <= in_data_v;
        th_last_q   <= th_last_v;
        th_next_q   <= th_next_v;
        evt_ts_q    <= evt_ts_v;
        state_q     <= state_v;
        out_valid_q <= out_valid_v;
        out_last_q  <= out_last_v;
        out_data_q  <= out_data_v;

        -- Status signal set when generating TH events
        if (state_v = GEN_TH_FROM_TH or state_v = GEN_TH_FROM_EVT) then
          stat_gen_q <= '1';
        else
          if stat_gen_th_flag_clear_i = '1' then
            stat_gen_q <= '0';
          end if;
        end if;

        -- Status signal set when dropping events
        if (state_v = DROP_EVT or state_v = DROP_EVT_AND_NEXT) then
          stat_drop_q <= '1';
        else
          if stat_evt_drop_flag_clear_i = '1' then
            stat_drop_q <= '0';
          end if;
        end if;
      end if;
    end if;
  end process evt_merge_p;

end rtl;
