----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
--
-- Create Date:    Nov. 22 2023
-- Design Name:    evt21_smart_drop
-- Module Name:    evt21_smart_drop
-- Project Name:   psee_generic
-- Target Devices: Zynq US
-- Tool versions:  Xilinx Vivado 2022.2
-- Description:    EVT 2.1 event stream smart dropper, without back pressure
--                 propagation to previous AXI Stream interface.
--                 This module heritates from 2.0 smart dropped adding more options
----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.ccam_utils_pkg.all;
use work.ccam_evt_type_v2_1_pkg.all;


---------------------------------------------------------------
-- EVT 2.1 smart event stream dropper
entity evt21_smart_drop is
  port (
    -- Clock and Reset
    clk                         : in std_logic;
    arst_n                      : in std_logic;
    srst                        : in std_logic;

    -- Configuration Interface
    cfg_enable_i                : in  std_logic_vector(0 downto 0);
    cfg_bypass_i                : in  std_logic_vector(0 downto 0);
    cfg_gen_other_evt_i         : in  std_logic_vector(0 downto 0); 
    cfg_reduce_flag_i           : in  std_logic;         -- first stage full flag, don't drop TH
    cfg_drop_flag_i             : in  std_logic;         -- second stage full flag, drop all   

    -- Debug Counter
    stat_evt_drop_flag_o        : out std_logic_vector(0 downto 0); -- Indicate event dropped
    stat_evt_drop_flag_clear_i  : in  std_logic;   
    stat_th_drop_cnt_o          : out std_logic_vector(31 downto 0);
    stat_tl_drop_cnt_o          : out std_logic_vector(31 downto 0);
    stat_evt_drop_cnt_o         : out std_logic_vector(31 downto 0);

    -- Input Interfaces
    in_ready_o                  : out std_logic;
    in_valid_i                  : in  std_logic;
    in_last_i                   : in  std_logic;
    in_data_i                   : in  std_logic_vector(63 downto 0);

    -- Output Interface
    out_ready_i                 : in  std_logic;
    out_valid_o                 : out std_logic;
    out_last_o                  : out std_logic;
    out_data_o                  : out std_logic_vector(63 downto 0)
  );
end evt21_smart_drop;


architecture rtl of evt21_smart_drop is

  ------------------------------------
  -- Internal Constant Declarations --
  ------------------------------------
  constant DROP_ALL_FLAG_C  : std_logic_vector(1 downto 0)  := "11";
  constant REDUCE_FLAG_C    : std_logic_vector(1 downto 0)  := "01";
  constant GOBACK_FLAG_C    : std_logic_vector(1 downto 0)  := "00";


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------
  type state_t is (SEND_ST, REDUCE_EVT_ST, DROP_ALL_ST, RECOVERY_ST);

  signal cfg_fifo_full_flag_s        : std_logic_vector(1 downto 0);         -- bit0 : first stage full flag, don't drop TH; bit1 : second stage full flag, drop all
  signal in_ready_q                  : std_logic;
  signal in_valid_q                  : std_logic;
  signal in_last_q                   : std_logic;
  signal in_data_q                   : ccam_evt_v2_1_data_t;
  signal out_valid_q                 : std_logic;
  signal out_last_q                  : std_logic;
  signal out_data_q                  : ccam_evt_v2_1_data_t;
  signal state_q                     : state_t;
  signal drop_evt_s                  : ccam_other_evt_v2_1_t;
  signal last_time_low_q             : ccam_evt_v2_1_time_low_t;
  signal last_time_high_q            : ccam_evt_v2_1_time_high_t;

  -- Debug Counter
  signal stat_evt_drop_flag_q        : std_logic;
  signal stat_th_drop_cnt_q          : unsigned(31 downto 0);
  signal stat_evt_drop_cnt_q         : unsigned(31 downto 0);

begin

  -- AXI4 Stream output forward
  out_valid_o           <= out_valid_q;
  out_last_o            <= out_last_q;
  out_data_o            <= out_data_q;
  in_ready_o            <= in_ready_q;

  -- Drop event to be inserted in the output event stream
  drop_evt_s.type_f     <= EVT_2_1_OTHERS;
  drop_evt_s.time_f     <= last_time_low_q;
  drop_evt_s.unused_f   <= (others => '0');
  drop_evt_s.class_f    <= '0';
  drop_evt_s.subtype_f  <= MASTER_EVT_DROP_EVENT;
  drop_evt_s.cont_type_f<= EVT_2_1_CONTINUED;
  drop_evt_s.cont_data_f<= (others => '0');
  
  -- Debug Counter
  stat_evt_drop_flag_o(0)  <= stat_evt_drop_flag_q;
  stat_th_drop_cnt_o       <= std_logic_vector(stat_th_drop_cnt_q);
  stat_tl_drop_cnt_o       <= (others => '0');
  stat_evt_drop_cnt_o      <= std_logic_vector(stat_evt_drop_cnt_q);

  cfg_fifo_full_flag_s  <= DROP_ALL_FLAG_C when cfg_drop_flag_i = '1'   else
                           REDUCE_FLAG_C   when cfg_reduce_flag_i = '1' else
                           GOBACK_FLAG_C ;


  -- EVT 2.1 smart drop process
  evt21_stream_p : process(arst_n, clk) is
    variable in_ready_v   : std_logic;
    variable in_valid_v   : std_logic;
    variable in_last_v    : std_logic;
    variable in_data_v    : ccam_evt_v2_1_data_t;
    variable out_valid_v  : std_logic;
    variable out_last_v   : std_logic;
    variable out_data_v   : ccam_evt_v2_1_data_t;
    variable evt_v        : ccam_evt_v2_1_t;
    variable evt_th_v     : ccam_th_evt_v2_1_t;
    variable state_v      : state_t;

    procedure reset_p is
    begin
      out_valid_v          := '0';
      out_data_v           := (others => '0');
      out_last_v           := '0';
      out_valid_q          <= '0';
      out_last_q           <= '0';
      out_data_q           <= (others => '0');
      in_ready_q           <= '0';
      in_ready_v           := '0';
      in_valid_v           := '0';
      in_last_v            := '0';
      in_data_v            := (others => '0');
      in_valid_q           <= '0';
      in_last_q            <= '0';
      in_data_q            <= (others => '0');
      evt_v                := to_ccam_evt_v2_1((others => '0'));
      evt_th_v             := to_ccam_th_evt_v2_1((others => '0'));
      last_time_low_q      <= (others => '0');
      last_time_high_q     <= (others => '1');
      stat_evt_drop_flag_q <= '0';
      stat_th_drop_cnt_q   <= to_unsigned(0, stat_th_drop_cnt_q'length);
      stat_evt_drop_cnt_q  <= to_unsigned(0, stat_evt_drop_cnt_q'length);
      state_v              := SEND_ST;
      state_q              <= SEND_ST;
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

        -- Converts the incoming event data into a generic event records
        evt_v    := to_ccam_evt_v2_1(in_data_v);
        evt_th_v := to_ccam_th_evt_v2_1(in_data_v);

        if out_valid_v = '0' and in_valid_v = '1' then
          -- New incoming upstream data and OUT buffer in empty
          out_data_v  := in_data_v;
          out_last_v  := in_last_v;
          out_valid_v := '1';
          in_valid_v  := '0';
          
          if cfg_bypass_i(0) = '0' then
            case state_v is
              when DROP_ALL_ST | REDUCE_EVT_ST  =>
                -- When fifo is not almost full and input event is TH, stop dropping
                if cfg_fifo_full_flag_s = GOBACK_FLAG_C and evt_v.type_f = EVT_2_1_TIME_HIGH then
                  state_v   := RECOVERY_ST;
                -- When fifo is not full, return to send only TH event
                elsif cfg_fifo_full_flag_s = REDUCE_FLAG_C then
                  state_v   := REDUCE_EVT_ST;
                -- When fifo is full, drop all
                elsif cfg_fifo_full_flag_s = DROP_ALL_FLAG_C then
                  state_v   := DROP_ALL_ST;
                end if;
                stat_evt_drop_flag_q <= '1';
              when RECOVERY_ST  =>
                -- finish sending the drop recovery event, go to send event
                state_v   := SEND_ST;
              when SEND_ST  =>
                -- Only TH, TL, TD and EM event can start dropping state
                if evt_v.type_f = EVT_2_1_TIME_HIGH or
                   evt_v.type_f = EVT_2_1_LEFT_TD_LOW  or
                   evt_v.type_f = EVT_2_1_LEFT_TD_HIGH or
                   evt_v.type_f = EVT_2_1_LEFT_APS_END or
                   evt_v.type_f = EVT_2_1_LEFT_APS_START then
                  -- When fifo is almost full, forward only TH event
                  if cfg_fifo_full_flag_s = REDUCE_FLAG_C then
                    state_v   := REDUCE_EVT_ST;
                  -- When fifo is full, drop all event
                  elsif cfg_fifo_full_flag_s = DROP_ALL_FLAG_C then
                    state_v   := DROP_ALL_ST;
                  end if;
                end if;
              when others =>
                state_v   := SEND_ST;
            end case;

            -- Dropping logic
            case state_v is
              when RECOVERY_ST    =>
                if cfg_gen_other_evt_i(0) = '1' then
                  out_last_v  := '1';
                  -- Insert the drop recovery event
                  out_data_v  := to_ccam_evt_v2_1_data(drop_evt_s);
                  -- When insert drop recovery event, the input event will be still in the buffer and send it in the next cycle
                  in_valid_v  := '1';
                end if;

              when REDUCE_EVT_ST  =>
                -- Only TIME HIGH events are valid
                if evt_v.type_f /= EVT_2_1_TIME_HIGH then
                  out_valid_v := '0';
                end if;

                if evt_v.type_f = EVT_2_1_TIME_HIGH and last_time_high_q /= evt_th_v.time_high_f then
                  last_time_low_q   <= (others =>'0');
                elsif evt_v.type_f = EVT_2_1_TIME_HIGH then
                  last_time_low_q   <= (last_time_low_q(last_time_low_q'high downto 4) + 1) & (3 downto 0 => '0');
                end if;

                if evt_v.type_f = EVT_2_1_TIME_HIGH then
                  last_time_high_q  <= evt_th_v.time_high_f;
                end if;

              when DROP_ALL_ST    =>
                -- Drop all event input
                out_valid_v := '0';

              when others         =>
                -- When in SEND_ST, don't touch the stream, just forward it
                if evt_v.type_f = EVT_2_1_TIME_HIGH and last_time_high_q /= evt_th_v.time_high_f then
                  last_time_low_q   <= (others =>'0');
                elsif evt_v.type_f = EVT_2_1_TIME_HIGH then
                  last_time_low_q   <= (last_time_low_q(last_time_low_q'high downto 4) + 1) & (3 downto 0 => '0');
                elsif evt_v.type_f /= EVT_2_1_CONTINUED then
                  last_time_low_q   <= evt_v.time_f;
                end if;

                if evt_v.type_f = EVT_2_1_TIME_HIGH then
                  last_time_high_q  <= evt_th_v.time_high_f;
                end if;

            end case;

            if out_valid_v = '0' then
              stat_evt_drop_cnt_q   <= stat_evt_drop_cnt_q + to_unsigned(1, stat_evt_drop_cnt_q'length);
              if evt_v.type_f = EVT_2_1_TIME_HIGH then
                stat_th_drop_cnt_q    <= stat_th_drop_cnt_q + to_unsigned(1, stat_th_drop_cnt_q'length);
              end if;
            end if;

          end if;
        end if;

        -- Disable Updstream port if block is not enable
        in_ready_v := not in_valid_v and cfg_enable_i(0);

        -- Reset the flag
        if cfg_enable_i(0) = '0' or stat_evt_drop_flag_clear_i = '1' then
          stat_evt_drop_flag_q  <= '0';
        end if;

        -- Update registers from variables
        out_valid_q <= out_valid_v;
        out_last_q  <= out_last_v;
        out_data_q  <= out_data_v;
        in_ready_q  <= in_ready_v;

        -- Assign varaibles to signals for debug purpose
        in_valid_q  <= in_valid_v;
        in_data_q   <= in_data_v;
        in_last_q   <= in_last_v;

        state_q      <= state_v;

      end if;
    end if;
  end process;

end rtl;
