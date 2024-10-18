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
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;


------------------------
-- MIPI packet padding
entity mipi_tx_control_padding is
  generic (
    MIPI_DATA_WIDTH_G        : positive := 16;
    MIPI_MAX_PACKET_SIZE_G   : positive := 16384  -- Max. number of bytes in MIPI packet. Default 16KB.
  );
  port (
    -- Core clock and reset
    clk                           : in  std_logic;
    arst_n                        : in  std_logic;
    srst                          : in  std_logic;

    -- Configuration Interface
    cfg_enable_i                  : in  std_logic;
    cfg_bypass_i                  : in  std_logic;
    cfg_evt_format_i              : in  evt_format_data_t;
    cfg_packet_size_i             : in  std_logic_vector(13 downto 0);
    cfg_blocking_mode_i           : in  std_logic;

    -- MIPI RX Flow Control
    mipi_rx_ready_i               : in  std_logic;

    -- MIPI TX Generic IP Interface
    mipi_tx_in_ready_o            : out std_logic;
    mipi_tx_in_valid_i            : in  std_logic;
    mipi_tx_in_frame_start_i      : in  std_logic;
    mipi_tx_in_frame_end_i        : in  std_logic;
    mipi_tx_in_packet_start_i     : in  std_logic;
    mipi_tx_in_packet_end_i       : in  std_logic;
    mipi_tx_in_virtual_channel_i  : in  std_logic_vector(1 downto 0);
    mipi_tx_in_data_type_i        : in  std_logic_vector(5 downto 0);
    mipi_tx_in_word_count_i       : in  std_logic_vector(15 downto 0);
    mipi_tx_in_data_i             : in  std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);

    -- MIPI TX Generic IP Interface
    mipi_tx_out_ready_i           : in  std_logic;
    mipi_tx_out_valid_o           : out std_logic;
    mipi_tx_out_frame_start_o     : out std_logic;
    mipi_tx_out_frame_end_o       : out std_logic;
    mipi_tx_out_packet_start_o    : out std_logic;
    mipi_tx_out_packet_end_o      : out std_logic;
    mipi_tx_out_virtual_channel_o : out std_logic_vector(1 downto 0);
    mipi_tx_out_data_type_o       : out std_logic_vector(5 downto 0);
    mipi_tx_out_word_count_o      : out std_logic_vector(15 downto 0);
    mipi_tx_out_data_o            : out std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0)
  );
end entity mipi_tx_control_padding;


architecture rtl of mipi_tx_control_padding is


  ---------------------------
  -- Constant Declarations --
  ---------------------------


  ------------------------
  -- Types Declarations --
  ------------------------

  type state_t  is (IDLE_ST, SEND_ST, PADDING_ST);


  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Internal Signals
  signal state_q                       : state_t;
  signal state_padding_s               : std_logic;
  signal out_data_count_q              : unsigned(cfg_packet_size_i'range);
  signal cfg_data_size_s               : unsigned(clog2(MIPI_DATA_WIDTH_G/8) downto 0);
  signal cfg_evt_cycles_s              : unsigned(clog2(CCAM_EVT_DATA_BITS/MIPI_DATA_WIDTH_G) downto 0);
  signal evt20_data_q                  : ccam_evt_data_t;
  signal evt_padding_data_s            : ccam_evt_data_t;
  signal evt20_padding_evt_s           : ccam_other_evt_t;
  signal evt20_padding_data_s          : ccam_evt_data_t;
  signal evt20_padding_time_low_s      : ccam_evt_time_low_t;
  signal evt20_th_index_q              : unsigned(1 downto 0);
  signal evt_cycle_index_q             : unsigned(0 downto 0);
  signal evt30_padding_evt_s           : ccam_evt_v3_other_t;
  signal evt30_padding_data_s          : ccam_evt_v3_data_t;

  -- MIPI TX Input Interface
  signal mipi_tx_in_ready_q            : std_logic;
  signal mipi_tx_in_valid_q            : std_logic;
  signal mipi_tx_in_data_valid_q       : std_logic;
  signal mipi_tx_in_frame_start_q      : std_logic;
  signal mipi_tx_in_frame_end_q        : std_logic;
  signal mipi_tx_in_packet_start_q     : std_logic;
  signal mipi_tx_in_packet_end_q       : std_logic;
  signal mipi_tx_in_virtual_channel_q  : std_logic_vector(1 downto 0);
  signal mipi_tx_in_data_type_q        : std_logic_vector(5 downto 0);
  signal mipi_tx_in_word_count_q       : std_logic_vector(15 downto 0);
  signal mipi_tx_in_data_q             : std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);

  -- MIPI TX Output Interface
  signal mipi_tx_out_valid_q           : std_logic;
  signal mipi_tx_out_frame_start_q     : std_logic;
  signal mipi_tx_out_frame_end_q       : std_logic;
  signal mipi_tx_out_packet_start_q    : std_logic;
  signal mipi_tx_out_packet_end_q      : std_logic;
  signal mipi_tx_out_virtual_channel_q : std_logic_vector(1 downto 0);
  signal mipi_tx_out_data_type_q       : std_logic_vector(5 downto 0);
  signal mipi_tx_out_word_count_q      : std_logic_vector(15 downto 0);
  signal mipi_tx_out_data_q            : std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);

begin

  ----------------
  -- Assertions --
  ----------------

  assert (CCAM_EVT_DATA_BITS / MIPI_DATA_WIDTH_G * MIPI_DATA_WIDTH_G) = CCAM_EVT_DATA_BITS
  report "CCAM_EVT_DATA_BITS should be multiple of MIPI_DATA_WIDTH_G !"
  severity Failure;

  assert (CCAM_EVT_V3_DATA_BITS / MIPI_DATA_WIDTH_G * MIPI_DATA_WIDTH_G) = CCAM_EVT_V3_DATA_BITS
  report "CCAM_EVT_V3_DATA_BITS should be multiple of MIPI_DATA_WIDTH_G !"
  severity Failure;


  ------------------------------
  -- Asynchronous Assignments --
  ------------------------------

  -- Internal Signals
  state_padding_s               <= '1' when (state_q = PADDING_ST) else '0';
  cfg_data_size_s               <= to_unsigned(MIPI_DATA_WIDTH_G/8, cfg_data_size_s'length);

  cfg_evt_cycles_s              <= to_unsigned(CCAM_EVT_V3_DATA_BITS/MIPI_DATA_WIDTH_G, cfg_evt_cycles_s'length) when (cfg_evt_format_i = EVT_FORMAT_DATA_3_0) else
                                   to_unsigned(CCAM_EVT_DATA_BITS/MIPI_DATA_WIDTH_G, cfg_evt_cycles_s'length);

  evt20_padding_time_low_s      <= evt20_th_index_q & "1111";

  evt20_padding_evt_s           <= (type_f    => OTHER,
                                    time_f    => evt20_padding_time_low_s,
                                    unused_f  => (others =>'0'),
                                    class_f   => '0',
                                    subtype_f => MASTER_MIPI_PADDING);
  evt20_padding_data_s          <= to_ccam_evt_data(evt20_padding_evt_s);

  evt30_padding_evt_s           <= (type_f    => EVT_V3_OTHER,
                                    subtype_f => V3_MASTER_MIPI_PADDING);
  evt30_padding_data_s          <= to_ccam_evt_v3_data(evt30_padding_evt_s);


  evt_padding_data_s            <= ccam_evt_v3_data_to_ccam_evt_data(evt30_padding_data_s) when (cfg_evt_format_i = EVT_FORMAT_DATA_3_0) else
                                   evt20_padding_data_s;

  -- MIPI TX Generic Input Interface
  mipi_tx_in_ready_o            <= mipi_tx_in_ready_q;

  -- MIPI TX Generic Outuput Interface
  mipi_tx_out_valid_o           <= mipi_tx_out_valid_q;
  mipi_tx_out_frame_start_o     <= mipi_tx_out_frame_start_q;
  mipi_tx_out_frame_end_o       <= mipi_tx_out_frame_end_q;
  mipi_tx_out_packet_start_o    <= mipi_tx_out_packet_start_q;
  mipi_tx_out_packet_end_o      <= mipi_tx_out_packet_end_q;
  mipi_tx_out_virtual_channel_o <= mipi_tx_out_virtual_channel_q;
  mipi_tx_out_data_type_o       <= mipi_tx_out_data_type_q;
  mipi_tx_out_word_count_o      <= mipi_tx_out_word_count_q;
  mipi_tx_out_data_o            <= mipi_tx_out_data_q;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------


  padding_p : process (clk, arst_n)
    variable state_v                       : state_t;
    variable out_data_count_v              : unsigned(cfg_packet_size_i'range);
    variable evt20_data_v                  : ccam_evt_data_t;
    variable evt20_th_index_v              : unsigned(1 downto 0);
    variable evt_cycle_index_v             : unsigned(0 downto 0);
    variable mipi_tx_in_ready_v            : std_logic;
    variable mipi_tx_in_valid_v            : std_logic;
    variable mipi_tx_in_data_valid_v       : std_logic;
    variable mipi_tx_in_frame_start_v      : std_logic;
    variable mipi_tx_in_frame_end_v        : std_logic;
    variable mipi_tx_in_packet_start_v     : std_logic;
    variable mipi_tx_in_packet_end_v       : std_logic;
    variable mipi_tx_in_virtual_channel_v  : std_logic_vector(1 downto 0);
    variable mipi_tx_in_data_type_v        : std_logic_vector(5 downto 0);
    variable mipi_tx_in_word_count_v       : std_logic_vector(15 downto 0);
    variable mipi_tx_in_data_v             : std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);
    variable mipi_tx_out_ready_v           : std_logic;
    variable mipi_tx_out_valid_v           : std_logic;
    variable mipi_tx_out_frame_start_v     : std_logic;
    variable mipi_tx_out_frame_end_v       : std_logic;
    variable mipi_tx_out_packet_start_v    : std_logic;
    variable mipi_tx_out_packet_end_v      : std_logic;
    variable mipi_tx_out_virtual_channel_v : std_logic_vector(1 downto 0);
    variable mipi_tx_out_data_type_v       : std_logic_vector(5 downto 0);
    variable mipi_tx_out_word_count_v      : std_logic_vector(15 downto 0);
    variable mipi_tx_out_data_v            : std_logic_vector(MIPI_DATA_WIDTH_G-1 downto 0);

    procedure reset_p is
    begin
      state_v                       := IDLE_ST;
      out_data_count_v              := (others => '0');
      evt20_data_v                  := (others => '0');
      evt20_th_index_v              := (others => '1');
      evt_cycle_index_v             := (others => '0');
      mipi_tx_in_ready_v            := '0';
      mipi_tx_in_valid_v            := '0';
      mipi_tx_in_data_valid_v       := '0';
      mipi_tx_in_frame_start_v      := '0';
      mipi_tx_in_frame_end_v        := '0';
      mipi_tx_in_packet_start_v     := '0';
      mipi_tx_in_packet_end_v       := '0';
      mipi_tx_in_virtual_channel_v  := (others => '0');
      mipi_tx_in_data_type_v        := (others => '0');
      mipi_tx_in_word_count_v       := (others => '0');
      mipi_tx_in_data_v             := (others => '0');
      mipi_tx_out_ready_v           := '0';
      mipi_tx_out_valid_v           := '0';
      mipi_tx_out_frame_start_v     := '0';
      mipi_tx_out_frame_end_v       := '0';
      mipi_tx_out_packet_start_v    := '0';
      mipi_tx_out_packet_end_v      := '0';
      mipi_tx_out_virtual_channel_v := (others => '0');
      mipi_tx_out_data_type_v       := (others => '0');
      mipi_tx_out_word_count_v      := (others => '0');
      mipi_tx_out_data_v            := (others => '0');
      state_q                       <= IDLE_ST;
      out_data_count_q              <= (others => '0');
      evt20_data_q                  <= (others => '0');
      evt20_th_index_q              <= (others => '1');
      evt_cycle_index_q             <= (others => '0');
      mipi_tx_in_ready_q            <= '0';
      mipi_tx_in_valid_q            <= '0';
      mipi_tx_in_data_valid_q       <= '0';
      mipi_tx_in_frame_start_q      <= '0';
      mipi_tx_in_frame_end_q        <= '0';
      mipi_tx_in_packet_start_q     <= '0';
      mipi_tx_in_packet_end_q       <= '0';
      mipi_tx_in_virtual_channel_q  <= (others => '0');
      mipi_tx_in_data_type_q        <= (others => '0');
      mipi_tx_in_word_count_q       <= (others => '0');
      mipi_tx_in_data_q             <= (others => '0');
      mipi_tx_out_valid_q           <= '0';
      mipi_tx_out_frame_start_q     <= '0';
      mipi_tx_out_frame_end_q       <= '0';
      mipi_tx_out_packet_start_q    <= '0';
      mipi_tx_out_packet_end_q      <= '0';
      mipi_tx_out_virtual_channel_q <= (others => '0');
      mipi_tx_out_data_type_q       <= (others => '0');
      mipi_tx_out_word_count_q      <= (others => '0');
      mipi_tx_out_data_q            <= (others => '0');
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Load variables from registers
        state_v                       := state_q;
        out_data_count_v              := out_data_count_q;
        evt20_data_v                  := evt20_data_q;
        evt20_th_index_v              := evt20_th_index_q;
        evt_cycle_index_v             := evt_cycle_index_q;
        mipi_tx_in_ready_v            := mipi_tx_in_ready_q;
        mipi_tx_in_valid_v            := mipi_tx_in_valid_q;
        mipi_tx_in_data_valid_v       := mipi_tx_in_data_valid_q;
        mipi_tx_in_frame_start_v      := mipi_tx_in_frame_start_q;
        mipi_tx_in_frame_end_v        := mipi_tx_in_frame_end_q;
        mipi_tx_in_packet_start_v     := mipi_tx_in_packet_start_q;
        mipi_tx_in_packet_end_v       := mipi_tx_in_packet_end_q;
        mipi_tx_in_virtual_channel_v  := mipi_tx_in_virtual_channel_q;
        mipi_tx_in_data_type_v        := mipi_tx_in_data_type_q;
        mipi_tx_in_word_count_v       := mipi_tx_in_word_count_q;
        mipi_tx_in_data_v             := mipi_tx_in_data_q;
        mipi_tx_out_valid_v           := mipi_tx_out_valid_q;
        mipi_tx_out_frame_start_v     := mipi_tx_out_frame_start_q;
        mipi_tx_out_frame_end_v       := mipi_tx_out_frame_end_q;
        mipi_tx_out_packet_start_v    := mipi_tx_out_packet_start_q;
        mipi_tx_out_packet_end_v      := mipi_tx_out_packet_end_q;
        mipi_tx_out_virtual_channel_v := mipi_tx_out_virtual_channel_q;
        mipi_tx_out_data_type_v       := mipi_tx_out_data_type_q;
        mipi_tx_out_word_count_v      := mipi_tx_out_word_count_q;
        mipi_tx_out_data_v            := mipi_tx_out_data_q;

        -- Check if we need to sample input data
        if (mipi_tx_in_ready_v = '1' and mipi_tx_in_valid_i = '1') then
          mipi_tx_in_valid_v            := mipi_tx_in_valid_i;
          mipi_tx_in_data_valid_v       := mipi_tx_in_valid_i;
          mipi_tx_in_frame_start_v      := mipi_tx_in_frame_start_i;
          mipi_tx_in_frame_end_v        := mipi_tx_in_frame_end_i;
          mipi_tx_in_packet_start_v     := mipi_tx_in_packet_start_i;
          mipi_tx_in_packet_end_v       := mipi_tx_in_packet_end_i;
          mipi_tx_in_virtual_channel_v  := mipi_tx_in_virtual_channel_i;
          mipi_tx_in_data_type_v        := mipi_tx_in_data_type_i;
          mipi_tx_in_word_count_v       := mipi_tx_in_word_count_i;
          mipi_tx_in_data_v             := mipi_tx_in_data_i;
        end if;

        -- Check if we can release the output data
        if (mipi_tx_out_ready_i = '1' and mipi_tx_out_valid_v = '1') then
          mipi_tx_out_valid_v := '0';
        end if;

        -- Process FSM state
        case (state_v) is
        when IDLE_ST | SEND_ST =>
          if (state_v = SEND_ST or (cfg_enable_i = '1' and (cfg_blocking_mode_i = '0' or mipi_rx_ready_i = '1'))) then
            -- Check if we have valid data on the input and space on the output
            if (mipi_tx_in_valid_v = '1' and mipi_tx_out_valid_v = '0') then
              if (mipi_tx_in_data_valid_v = '1') then
                assert (unsigned(mipi_tx_in_word_count_i) <= unsigned(cfg_packet_size_i))
                    report "Packet overflow in MIPI TX Control Padding block"
                    severity error;
                mipi_tx_out_valid_v           := mipi_tx_in_valid_v;
                mipi_tx_out_frame_start_v     := mipi_tx_in_frame_start_v;
                mipi_tx_out_frame_end_v       := mipi_tx_in_frame_end_v;
                mipi_tx_out_packet_start_v    := mipi_tx_in_packet_start_v;
                mipi_tx_out_packet_end_v      := mipi_tx_in_packet_end_v;
                mipi_tx_out_virtual_channel_v := mipi_tx_in_virtual_channel_v;
                mipi_tx_out_data_type_v       := mipi_tx_in_data_type_v;
                mipi_tx_out_word_count_v      := std_logic_vector(resize(unsigned(cfg_packet_size_i), mipi_tx_out_word_count_v'length));
                mipi_tx_out_data_v            := mipi_tx_in_data_v;

                if (evt_cycle_index_v = cfg_evt_cycles_s-1) then
                  evt_cycle_index_v := (others => '0');
                  if (cfg_evt_format_i = EVT_FORMAT_DATA_2_0) then
                    if (mipi_tx_in_data_v(mipi_tx_in_data_v'high downto mipi_tx_in_data_v'length-CCAM_EVT_TYPE_BITS) = std_logic_vector(EVT_TIME_HIGH)) then
                      evt20_th_index_v := evt20_th_index_v + 1;
                    end if;
                  end if;
                else
                  evt_cycle_index_v := evt_cycle_index_v + 1;
                end if;

                -- Release the input data
                mipi_tx_in_data_valid_v       := '0';

                out_data_count_v              := out_data_count_v + cfg_data_size_s;

                if (mipi_tx_in_packet_end_v = '1' or mipi_tx_in_frame_end_v = '1') then
                  if (cfg_bypass_i = '0' and out_data_count_v < unsigned(cfg_packet_size_i)) then
                    mipi_tx_out_frame_end_v       := '0';
                    mipi_tx_out_packet_end_v      := '0';
                    state_v                       := PADDING_ST;
                  else
                    mipi_tx_in_valid_v            := '0';  -- Release the input data
                    state_v                       := IDLE_ST;
                    mipi_tx_in_valid_v            := '0';
                    out_data_count_v              := (others => '0');
                    evt_cycle_index_v             := (others => '0');
                  end if;
                else
                  mipi_tx_in_valid_v            := '0';
                  state_v                       := SEND_ST;
                end if;
              end if;
            end if;
          end if;

        when PADDING_ST =>
          -- Check if we have valid data on the input and space on the output
          if (mipi_tx_in_valid_v = '1' and mipi_tx_out_valid_v = '0') then
            mipi_tx_out_valid_v           := '1';
            mipi_tx_out_frame_start_v     := '0';
            mipi_tx_out_packet_start_v    := '0';
            mipi_tx_out_virtual_channel_v := mipi_tx_in_virtual_channel_v;
            mipi_tx_out_data_type_v       := mipi_tx_in_data_type_v;
            mipi_tx_out_word_count_v      := std_logic_vector(resize(unsigned(cfg_packet_size_i), mipi_tx_out_word_count_v'length));
            mipi_tx_out_data_v            := evt_padding_data_s((to_integer(evt_cycle_index_v)+1)*MIPI_DATA_WIDTH_G-1 downto to_integer(evt_cycle_index_v)*MIPI_DATA_WIDTH_G);
            out_data_count_v              := out_data_count_v + cfg_data_size_s;

            if (evt_cycle_index_v = cfg_evt_cycles_s-1) then
              evt_cycle_index_v := (others => '0');
            else
              evt_cycle_index_v := evt_cycle_index_v + 1;
            end if;

            if (out_data_count_v < unsigned(cfg_packet_size_i)) then
              mipi_tx_out_frame_end_v       := '0';
              mipi_tx_out_packet_end_v      := '0';
              state_v                       := PADDING_ST;
            else
              mipi_tx_out_frame_end_v       := mipi_tx_in_frame_end_v;
              mipi_tx_out_packet_end_v      := mipi_tx_in_packet_end_v;
              mipi_tx_in_valid_v            := '0';  -- Release the input data
              state_v                       := IDLE_ST;
              mipi_tx_in_valid_v            := '0';
              out_data_count_v              := (others => '0');
              evt_cycle_index_v             := (others => '0');
            end if;
          end if;

        when others =>
          reset_p;
        end case;

        -- Determine whether or not we can accept new input data the next cycle
        mipi_tx_in_ready_v := not(mipi_tx_in_valid_v or mipi_tx_in_data_valid_v);

        -- Store variables into registers
        state_q                       <= state_v;
        out_data_count_q              <= out_data_count_v;
        evt20_data_q                  <= evt20_data_v;
        evt20_th_index_q              <= evt20_th_index_v;
        evt_cycle_index_q             <= evt_cycle_index_v;
        mipi_tx_in_ready_q            <= mipi_tx_in_ready_v;
        mipi_tx_in_valid_q            <= mipi_tx_in_valid_v;
        mipi_tx_in_data_valid_q       <= mipi_tx_in_data_valid_v;
        mipi_tx_in_frame_start_q      <= mipi_tx_in_frame_start_v;
        mipi_tx_in_frame_end_q        <= mipi_tx_in_frame_end_v;
        mipi_tx_in_packet_start_q     <= mipi_tx_in_packet_start_v;
        mipi_tx_in_packet_end_q       <= mipi_tx_in_packet_end_v;
        mipi_tx_in_virtual_channel_q  <= mipi_tx_in_virtual_channel_v;
        mipi_tx_in_data_type_q        <= mipi_tx_in_data_type_v;
        mipi_tx_in_word_count_q       <= mipi_tx_in_word_count_v;
        mipi_tx_in_data_q             <= mipi_tx_in_data_v;
        mipi_tx_out_valid_q           <= mipi_tx_out_valid_v;
        mipi_tx_out_frame_start_q     <= mipi_tx_out_frame_start_v;
        mipi_tx_out_frame_end_q       <= mipi_tx_out_frame_end_v;
        mipi_tx_out_packet_start_q    <= mipi_tx_out_packet_start_v;
        mipi_tx_out_packet_end_q      <= mipi_tx_out_packet_end_v;
        mipi_tx_out_virtual_channel_q <= mipi_tx_out_virtual_channel_v;
        mipi_tx_out_data_type_q       <= mipi_tx_out_data_type_v;
        mipi_tx_out_word_count_q      <= mipi_tx_out_word_count_v;
        mipi_tx_out_data_q            <= mipi_tx_out_data_v;
      end if;
    end if;
  end process padding_p;


end architecture rtl;
