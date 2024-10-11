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


---------------------------------------------------------------------
-- Demultiplexes an input event stream into either one of the
-- output interfaces according to the output selection signal.
-- When out_select_i is '0', output events are sent via the "out0"
-- interface, while when out_select_i is '1', output events are sent
-- via the "out1" interface.
entity axi4s_demux_1_2_keep is
  generic (
    DATA_WIDTH   : positive := 32
  );
  port (
    -- Core clock and reset
    clk          : in  std_logic;
    arst_n       : in  std_logic;
    srst         : in  std_logic;
    
    -- Output selection control
    out_select_i  : in  std_logic;
    
    -- Input event stream interface
    in_ready_o   : out std_logic;
    in_valid_i   : in  std_logic;
    in_first_i   : in  std_logic;
    in_last_i    : in  std_logic;
    in_data_i    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    in_keep_i    : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    
    -- Output 0 event stream interface
    out0_ready_i : in  std_logic;
    out0_valid_o : out std_logic;
    out0_first_o : out std_logic;
    out0_last_o  : out std_logic;
    out0_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out0_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    
    -- Output 1 event stream interface
    out1_ready_i : in  std_logic;
    out1_valid_o : out std_logic;
    out1_first_o : out std_logic;
    out1_last_o  : out std_logic;
    out1_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out1_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0)
  );
end axi4s_demux_1_2_keep;

architecture rtl of axi4s_demux_1_2_keep is
begin

  ------------------------
  -- Demultiplexer Process
  demux_p : process(arst_n, srst, out_select_i, in_valid_i, in_first_i, in_last_i, in_data_i, in_keep_i, out0_ready_i, out1_ready_i)
  begin
    if (arst_n = '0' or srst = '1') then
      in_ready_o   <= '0';
      out0_valid_o <= '0';
      out0_first_o <= '0';
      out0_last_o  <= '0';
      out0_data_o  <= (others => '0');
      out0_keep_o  <= (others => '0');
      out1_valid_o <= '0';
      out1_first_o <= '0';
      out1_last_o  <= '0';
      out1_data_o  <= (others => '0');
      out1_keep_o  <= (others => '0');
    elsif (out_select_i = '0') then
      in_ready_o   <= out0_ready_i;
      out0_valid_o <= in_valid_i;
      out0_first_o <= in_first_i;
      out0_last_o  <= in_last_i;
      out0_data_o  <= in_data_i;
      out0_keep_o  <= in_keep_i;
      out1_valid_o <= '0';
      out1_first_o <= '0';
      out1_last_o  <= '0';
      out1_data_o  <= (others => '0');
      out1_keep_o  <= (others => '0');
    else
      in_ready_o   <= out1_ready_i;
      out0_valid_o <= '0';
      out0_first_o <= '0';
      out0_last_o  <= '0';
      out0_data_o  <= (others => '0');
      out0_keep_o  <= (others => '0');
      out1_valid_o <= in_valid_i;
      out1_first_o <= in_first_i;
      out1_last_o  <= in_last_i;
      out1_data_o  <= in_data_i;
      out1_keep_o  <= in_keep_i;
    end if;
  end process;


end rtl;
