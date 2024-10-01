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
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library work;
use     work.ccam_utils.all;

----------------------------
-- AXI4 Stream TLAST checker
entity axi4s_tlast_checker is
  generic (
    DATA_WIDTH_G       : positive := 32;
    LITTLE_ENDIAN_G    : boolean  := false;
    TLAST_CHECK_EN_G   : boolean  := true;
    TKEEP_CHECK_EN_G   : boolean  := true
  );
  port (
    -- Clock and Reset
    clk                 : in std_logic;
    arst_n              : in std_logic;
    srst                : in std_logic;

    -- Configuration Inputs
    cfg_config_i        : in std_logic_vector(31 downto 0);
    cfg_packet_length_i : in std_logic_vector(31 downto 0);
    cfg_timeout_i       : in std_logic_vector(31 downto 0);
    cfg_timeout_evt_i   : in std_logic_vector(DATA_WIDTH_G-1 downto 0);

    -- AXI4-Stream Slave Interface
    in_ready_i          : in std_logic;
    in_valid_i          : in std_logic;
    in_last_i           : in std_logic;
    in_keep_i           : in std_logic_vector(((DATA_WIDTH_G+7)/8)-1 downto 0);
    in_data_i           : in std_logic_vector(DATA_WIDTH_G-1 downto 0)
  );
end entity axi4s_tlast_checker;

architecture tb of axi4s_tlast_checker is

  signal evts_per_cycle_s : unsigned(cfg_packet_length_i'range);
  signal evts_cnt_q       : unsigned(cfg_packet_length_i'range);
  signal tkeep_ref_q      : std_logic_vector(in_keep_i'range);
  signal timeout_cnt_q    : unsigned(cfg_timeout_i'range);
  signal timeout_enable_s : std_logic;
  signal valid_data_s     : std_logic;
  signal valid_tlast_s    : std_logic;
  signal error_q          : std_logic;

begin

  ------------------------------
  -- Asynchronous Assignments --
  ------------------------------

  evts_per_cycle_s <= to_unsigned(1, evts_per_cycle_s'length);

  timeout_enable_s <= cfg_config_i(2);

  -- Signals to better identify valid transactions on the AXI4-Stream bus
  valid_data_s     <= in_valid_i and in_ready_i;
  valid_tlast_s    <= in_valid_i and in_ready_i and in_last_i;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  tlast_checker_p : process(clk, arst_n)
    variable evts_cnt_v    : unsigned(evts_cnt_q'range);
    variable tkeep_ref_v   : std_logic_vector(in_keep_i'range);
    variable tkeep_nbits_v : natural;

    procedure reset_p is
    begin
      evts_cnt_v    := (others => '0');
      tkeep_ref_v   := (others => '1');
      tkeep_nbits_v := in_keep_i'length;
      evts_cnt_q    <= (others => '0');
      tkeep_ref_q   <= (others => '1');
      timeout_cnt_q <= (others => '0');
      error_q       <= '0';
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_p;
      elsif (timeout_enable_s = '0') then
        -- Ignore the timeout
        evts_cnt_v    := evts_cnt_q;
        tkeep_ref_v   := (others => '1');
        tkeep_nbits_v := in_keep_i'length;

        -- Wait until output data is handshaked
        if (valid_data_s = '1') then

          -- Increment the counter
          evts_cnt_v := evts_cnt_v + evts_per_cycle_s;

          -- Check if we've reached the end of the packet
          if (evts_cnt_v >= unsigned(cfg_packet_length_i)) then

            -- If the end of packet is reached, the tlast should be asserted
            if (TLAST_CHECK_EN_G and in_last_i /= '1') then
              report "[AXI4S TLAST Checker] TLAST is not asserted correctly, reading '0' but should be '1'!"
                  severity failure;
            end if;

            if (TKEEP_CHECK_EN_G) then
              if (evts_cnt_v > unsigned(cfg_packet_length_i)) then
                tkeep_nbits_v := in_keep_i'length - (((to_integer(evts_cnt_v) - to_integer(unsigned(cfg_packet_length_i))) * in_keep_i'length) / to_integer(evts_per_cycle_s));
              end if;
              --tkeep_ref_v   := std_logic_vector(to_unsigned(((2 ** tkeep_nbits_v) - 1), tkeep_ref_v'length));
              tkeep_ref_v := (others => '0');
              if (LITTLE_ENDIAN_G) then
                tkeep_ref_v(tkeep_nbits_v-1 downto 0) := (others => '1');
              else
                tkeep_ref_v(tkeep_ref_v'high downto tkeep_ref_v'length-tkeep_nbits_v) := (others => '1');
              end if;
              if (in_keep_i /= tkeep_ref_v) then
                report "[AXI4S DMA TKEEP Checker] TKEEP bits mismatch with respect to expected!" & lf &
                       "    Packet Size is: cfg_packet_length_i = " & integer'image(to_integer(unsigned(cfg_packet_length_i))) & lf &
                       "    Current Packet Count is: evts_cnt_v = " & integer'image(to_integer(evts_cnt_v)) & lf &
                       "    Expected: tkeep_ref_v = " & work.ccam_utils.to_hstring(tkeep_ref_v) & lf &
                       "    Received: in_keep_i   = " & work.ccam_utils.to_hstring(in_keep_i)
                  severity failure;
              end if;
            end if;

            -- Reset the counter
            evts_cnt_v := (others => '0');
          else
            -- If not at the end of the packet, the tlast should be zero
            if (TLAST_CHECK_EN_G and in_last_i = '1') then
              report "[AXI4S TLAST Checker] TLAST is not asserted correctly, reading '1' but should be '0'!"
                severity failure;
            end if;

            if (TKEEP_CHECK_EN_G and in_keep_i /= (in_keep_i'range => '1')) then
              report "[AXI4S DMA TKEEP Checker] All TKEEP bits are not asserted high !" severity failure;
            end if;
          end if;
        end if;

        evts_cnt_q  <= evts_cnt_v;
        tkeep_ref_q <= tkeep_ref_v;
      else
        -- Timeout is enabled: a tlast will be generated at regular intervals
        if (valid_data_s = '1') then
          if (valid_tlast_s = '1') then
            -- TLAST detected, reset the timeout counter
            timeout_cnt_q <= to_unsigned(0, timeout_cnt_q'length);
          else
            -- Regular data, increment the counter
            timeout_cnt_q <= timeout_cnt_q + to_unsigned(1, timeout_cnt_q'length);
          end if;
        else
          -- No data, increment the counter if it has been started already
          if (timeout_cnt_q /= 0) then
            timeout_cnt_q <= timeout_cnt_q + to_unsigned(1, timeout_cnt_q'length);
          end if;
        end if;

        -- If the counter reaches the timeout value, a TLAST should have been generated
        if (timeout_cnt_q = to_unsigned(to_integer(unsigned(cfg_timeout_i)) - 1, timeout_cnt_q'length)) then
          if (in_last_i = '0') then
            error_q <= '1';
            report "[AXI4S TLAST Checker] TLAST is not asserted correctly, reading '0' but should be '1'!"
              severity failure;
          end if;
          if (in_data_i /= cfg_timeout_evt_i) then
            report "[AXI4S TLAST Checker] Timeout event incorrect"
              severity failure;
          end if;
        end if;
      end if;
    end if;
  end process tlast_checker_p;

end tb;
