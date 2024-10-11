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
use work.ccam_utils_pkg.all;
use work.ccam_evt_type_v2_1_pkg.all;


entity evt21_ts_checker is
  generic (
    TIME_HIGH_PERIOD_US   : positive := 16
  );
  port (
    -- Clock and Reset
    clk                   : in std_logic;
    arst_n                : in std_logic;
    srst                  : in std_logic;
    
    -- Configuration Interface
    cfg_enable_i             : in  std_logic_vector(0 downto 0);
    cfg_bypass_i             : in  std_logic_vector(0 downto 0);
    cfg_ts_threshold_i       : in  std_logic_vector(27 downto 0);
    cfg_enable_drop_evt_i    : in  std_logic_vector(0 downto 0);
    cfg_gen_other_evt_i      : in  std_logic_vector(0 downto 0);
    cfg_gen_tlast_on_other_i : in  std_logic_vector(0 downto 0);
    stat_th_detect_cnt_o     : out std_logic_vector(15 downto 0);
    stat_th_corrupt_cnt_o    : out std_logic_vector(15 downto 0);
    stat_th_error_cnt_o      : out std_logic_vector(15 downto 0);
    
    -- Input Interfaces
    in_ready_o            : out std_logic;
    in_valid_i            : in  std_logic;
    in_last_i             : in  std_logic;
    in_data_i             : in  std_logic_vector(63 downto 0);
    
    -- Output Interface
    out_ready_i           : in  std_logic;
    out_valid_o           : out std_logic;
    out_last_o            : out std_logic;
    out_data_o            : out std_logic_vector(63 downto 0)
  );
end evt21_ts_checker;


architecture rtl of evt21_ts_checker is

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------
  type state_t is (RESET_ST, RUNNING_ST, SEND_EVT_ST, DROP_EVT_ST);

  signal in_ready_q    : std_logic;
  signal in_valid_q    : std_logic;
  signal in_last_q     : std_logic;
  signal in_data_q     : ccam_evt_v2_1_data_t;
  signal out_valid_q   : std_logic;
  signal out_last_q    : std_logic;
  signal out_data_q    : ccam_evt_v2_1_data_t;

  -- Time high data signals
  signal th_old_q      : ccam_evt_v2_1_time_high_t;
  signal th_last_q     : ccam_evt_v2_1_time_high_t;
  signal th_detect_q   : std_logic;

  signal detect_cnt_q  : unsigned(15 downto 0);
  signal corrupt_cnt_q : unsigned(15 downto 0);
  signal error_cnt_q   : unsigned(15 downto 0);

  signal th_diff_q     : signed(CCAM_EVT_2_1_TIME_HIGH_BITS-1 downto 0);
  signal state_q       : state_t;

  signal cfg_th_threshold_data_s : ccam_evt_v2_1_time_high_data_t;
  signal cfg_th_threshold_s      : ccam_evt_v2_1_time_high_data_t;
  
  signal last_time_low_q : ccam_evt_v2_1_time_low_t;


begin

  -- AXI4 Stream output forward
  out_valid_o <= out_valid_q;
  out_last_o  <= out_last_q;
  out_data_o  <= out_data_q;
  in_ready_o  <= in_ready_q;

  -- Extract Time High threshold from the timestamp threshold config
  cfg_th_threshold_data_s <= cfg_ts_threshold_i(CCAM_EVT_2_1_TIME_HIGH_SHIFTED_MSB downto CCAM_EVT_2_1_TIME_HIGH_SHIFTED_LSB);
  
  -- Init Time High threshold. Value is always 1 (one step Time High = 64 us) when timestamp threshold config is lower than 64 us
  cfg_th_threshold_s <= std_logic_vector(to_unsigned(1, CCAM_EVT_2_1_TIME_HIGH_BITS)) when unsigned(cfg_th_threshold_data_s) < TIME_HIGH_PERIOD_US*4 else ("000000" & cfg_th_threshold_data_s(27 downto 6)); 

  stat_th_detect_cnt_o  <= std_logic_vector(detect_cnt_q);
  stat_th_corrupt_cnt_o <= std_logic_vector(corrupt_cnt_q);
  stat_th_error_cnt_o   <= std_logic_vector(error_cnt_q);


  evt_th_jump_detector_p : process(arst_n, clk) is
    variable in_ready_v   : std_logic;
    variable in_valid_v   : std_logic;
    variable in_last_v    : std_logic;
    variable in_data_v    : ccam_evt_v2_1_data_t;
    variable out_valid_v  : std_logic;
    variable out_last_v   : std_logic;
    variable out_data_v   : ccam_evt_v2_1_data_t;
    variable evt_v        : ccam_evt_v2_1_t;
    variable th_evt_v     : ccam_th_evt_v2_1_t;
    variable other_evt_v  : ccam_other_evt_v2_1_t;
    variable tl_val_v     : ccam_evt_v2_1_time_low_t;
    variable th_val_v     : ccam_evt_v2_1_time_high_t;
    variable th_diff_v    : signed(CCAM_EVT_2_1_TIME_HIGH_BITS-1 downto 0);
    variable state_v      : state_t;

    procedure reset_p is
    begin
      out_valid_v   := '0';
      out_data_v    := (others => '0');
      out_last_v    := '0';
      out_valid_q   <= '0';
      out_last_q    <= '0';
      out_data_q    <= (others => '0');
      in_ready_q    <= '0';
      in_ready_v    := '0';
      in_valid_v    := '0';
      in_last_v     := '0';
      in_data_v     := (others => '0');
      in_valid_q    <= '0';
      in_last_q     <= '0';
      in_data_q     <= (others => '0');
      evt_v         := to_ccam_evt_v2_1((others => '0'));
      th_evt_v      := to_ccam_th_evt_v2_1((others => '0'));
      other_evt_v   := to_ccam_other_evt_v2_1((others => '0'));
      th_val_v      := (others => '0');
      tl_val_v      := (others => '0');
      th_last_q     <= (others => '0');
      th_old_q      <= (others => '0');
      detect_cnt_q  <= (others => '0');
      corrupt_cnt_q <= (others => '0');
      error_cnt_q   <= (others => '0');
      last_time_low_q <= (others => '0');
      th_detect_q   <= '0';
      state_v       := RESET_ST;

    end procedure;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_p;
      else
        -- Update variables
        out_valid_v := out_valid_q;
        out_last_v  := out_last_q;
        out_data_v  := out_data_q;
        in_ready_v  := in_ready_q;
        in_valid_v  := in_valid_q;
        in_data_v   := in_data_q;
        in_last_v   := in_last_q;
        th_val_v    := th_last_q;
        th_diff_v   := th_diff_q;
        state_v     := state_q;

        if out_ready_i = '1' then
          -- OUT buffer sent to downstream slave
          out_valid_v := '0';
        end if;

        if in_valid_i = '1' and in_ready_v = '1' then
          -- New data send by upstream port will be acknowledged
          in_data_v  := in_data_i;
          in_last_v  := in_last_i;
          in_valid_v := '1';
        end if;

        -- Converts the incoming event data into a CCAM event record
        evt_v    := to_ccam_evt_v2_1(in_data_v);

        -- Converts the incoming event data into a TIME HIGH event record
        th_evt_v := to_ccam_th_evt_v2_1(in_data_v);
            
        if out_valid_v = '0' and in_valid_v = '1' then
          -- New incoming upstream data and OUT buffer in empty
          out_data_v  := in_data_v;
          out_last_v  := in_last_v;
          out_valid_v := '1';
          in_valid_v  := '0';

          
          if evt_v.type_f = EVT_2_1_TIME_HIGH then
            -- TIME HIGH event
            th_val_v := th_evt_v.time_high_f;  -- Update current TIME HIGH value 
            
            if(th_detect_q = '0') then
              -- First Time High in pipeline, update now the th_next variable
              th_last_q <= th_val_v;
              -- Update TH_detect flag
              th_detect_q <= '1';
            end if;                            
              

            if state_v = DROP_EVT_ST then
              -- TIME HIGH under investigation
              if (th_val_v = th_old_q) or (th_val_v = th_old_q + 1) then
                -- Previous TIME HIGH value was corrupted
                -- Back to correct TIME HIGH in the same or next frame => stop dropping event
                corrupt_cnt_q <= corrupt_cnt_q + 1;
                state_v       := RUNNING_ST;

              elsif (th_val_v = th_last_q) or (th_val_v = th_last_q + 1) then
                -- Jump valid and confirmed in the same or next frame => stop dropping event
                state_v       := RUNNING_ST;
              else
                -- Other unknown TIME HIGH relationship
                error_cnt_q   <= error_cnt_q + 1;
                state_v       := DROP_EVT_ST;
              end if;
            else
              if (state_v = RESET_ST) then
                state_v := RUNNING_ST;
              else
                -- Update diff btw current and last valid TIME HIGH values
                th_diff_v := signed(th_val_v) - signed(th_last_q);

                if (th_diff_v > signed(cfg_th_threshold_s) or th_diff_v < 0) and (cfg_bypass_i(0) = '0') and (th_detect_q = '1') then
                  -- TIME HIGH over setup threshold => jump detected, update detection counter, start dropping event, save previous time high value
                  -- TIME HIGH back in time from last valid value
                  if cfg_gen_other_evt_i(0) = '1' then
                    other_evt_v.type_f     := EVT_2_1_OTHERS;
                    other_evt_v.time_f     := last_time_low_q;
                    other_evt_v.subtype_f  := MASTER_TH_DROP_EVENT;
                    other_evt_v.unused_f   := (others => '0');
                    other_evt_v.class_f    := '0';
                    other_evt_v.cont_type_f:= EVT_2_1_CONTINUED;
                    other_evt_v.cont_data_f:= (others => '0');              
                    
                    out_valid_v           := '1';
                    if cfg_gen_tlast_on_other_i(0) = '1' then
                      out_last_v            := '1';
                    end if;
                    out_data_v            := to_ccam_evt_v2_1_data(other_evt_v);
                    state_v               := SEND_EVT_ST;
                  elsif cfg_enable_drop_evt_i(0) = '1' then
                    state_v     := DROP_EVT_ST;
                  else
                    state_v     := RUNNING_ST;
                  end if;
                    
                  th_old_q              <= th_last_q;
                  detect_cnt_q          <= detect_cnt_q + 1;

                end if;
              end if;
            end if;
          elsif evt_v.type_f /= EVT_2_1_CONTINUED then
            -- Sample last event time low for special event
            tl_val_v := evt_v.time_f;
          end if;
          
          if cfg_bypass_i(0) = '0' then
            if state_v = SEND_EVT_ST then
              -- Send special event
              out_valid_v := '1';
              
              if cfg_enable_drop_evt_i(0) = '1' then
                state_v     := DROP_EVT_ST;
              else
                state_v     := RUNNING_ST;
              end if;

            elsif state_v = DROP_EVT_ST then
              -- Drop upstream data
              out_valid_v := '0';
            else
              out_valid_v := '1';
            end if;
          end if;
        end if;

        -- Disable Updstream port if block is not enable
        in_ready_v := not in_valid_v and cfg_enable_i(0);

        -- Update registers from variables
        out_valid_q <= out_valid_v;
        out_last_q  <= out_last_v;
        out_data_q  <= out_data_v;
        in_ready_q  <= in_ready_v;

        -- Assign varaibles to signals for debug purpose
        in_valid_q      <= in_valid_v;
        in_data_q       <= in_data_v;
        in_last_q       <= in_last_v;
        th_last_q       <= th_val_v;
        th_diff_q       <= th_diff_v;
        state_q         <= state_v;
        last_time_low_q <= tl_val_v;

      end if;
    end if;
  end process;

end rtl;
