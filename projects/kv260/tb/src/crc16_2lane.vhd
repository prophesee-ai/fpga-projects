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

----------------------------------------------
-- MIPI CSI-2 TX CRC16 2 Lanes
entity crc16_2lane is
  generic(
    CRC_POLY_G    : std_logic_vector(15 downto 0)
  );
  port (
    -- Core clock and reset
    clk           : in  std_logic;
    arst_n        : in  std_logic;
    srst          : in  std_logic;

    -- Input interface
    cfg_enable_i  : in  std_logic;
    in_data_i     : in  std_logic_vector(15 downto 0);

    -- Output interface
    out_ready_o   : out std_logic;
    out_crc_o     : out std_logic_vector(15 downto 0)
  );
end entity;

architecture rtl of crc16_2lane is

  -- Registers
  signal out_crc_q             : std_logic_vector(15 downto 0);
  signal out_ready_q           : std_logic;

  -- CRC computation signals
  signal in_data_a_0_xor_ext_s : std_logic_vector(15 downto 0);
  signal in_data_b_0_xor_ext_s : std_logic_vector(15 downto 0);
  signal a_0_s                 : std_logic_vector(15 downto 0);
  signal a_1_s                 : std_logic_vector(15 downto 0);
  signal a_2_s                 : std_logic_vector(15 downto 0);
  signal a_3_s                 : std_logic_vector(15 downto 0);
  signal a_4_s                 : std_logic_vector(15 downto 0);
  signal a_5_s                 : std_logic_vector(15 downto 0);
  signal a_6_s                 : std_logic_vector(15 downto 0);
  signal a_7_s                 : std_logic_vector(15 downto 0);
  signal b_0_s                 : std_logic_vector(15 downto 0);
  signal b_1_s                 : std_logic_vector(15 downto 0);
  signal b_2_s                 : std_logic_vector(15 downto 0);
  signal b_3_s                 : std_logic_vector(15 downto 0);
  signal b_4_s                 : std_logic_vector(15 downto 0);
  signal b_5_s                 : std_logic_vector(15 downto 0);
  signal b_6_s                 : std_logic_vector(15 downto 0);
  signal b_7_s                 : std_logic_vector(15 downto 0);
  signal crc_byte0_s           : std_logic_vector(15 downto 0);

begin

  -- Outputs assignments
  out_crc_o             <= out_crc_q;
  out_ready_o           <= out_ready_q;

  -- Asynchronous assignments
  in_data_a_0_xor_ext_s <= std_logic_vector( resize(unsigned(in_data_i( 7 downto 0)), in_data_a_0_xor_ext_s'length) );
  in_data_b_0_xor_ext_s <= std_logic_vector( resize(unsigned(in_data_i(15 downto 8)), in_data_b_0_xor_ext_s'length) );

  -- CRC computation
  a_0_s     <= out_crc_q xor in_data_a_0_xor_ext_s;
  a_1_s(15) <= '1'                          when a_0_s(0) = '1' else  '0';
  a_1_s(14) <= a_0_s(15) xor CRC_POLY_G(14) when a_0_s(0) = '1' else a_0_s(15);
  a_1_s(13) <= a_0_s(14) xor CRC_POLY_G(13) when a_0_s(0) = '1' else a_0_s(14);
  a_1_s(12) <= a_0_s(13) xor CRC_POLY_G(12) when a_0_s(0) = '1' else a_0_s(13);
  a_1_s(11) <= a_0_s(12) xor CRC_POLY_G(11) when a_0_s(0) = '1' else a_0_s(12);
  a_1_s(10) <= a_0_s(11) xor CRC_POLY_G(10) when a_0_s(0) = '1' else a_0_s(11);
  a_1_s(9)  <= a_0_s(10) xor CRC_POLY_G(9 ) when a_0_s(0) = '1' else a_0_s(10);
  a_1_s(8)  <= a_0_s(9)  xor CRC_POLY_G(8 ) when a_0_s(0) = '1' else a_0_s(9 );
  a_1_s(7)  <= a_0_s(8)  xor CRC_POLY_G(7)  when a_0_s(0) = '1' else a_0_s(8 );
  a_1_s(6)  <= a_0_s(7)  xor CRC_POLY_G(6)  when a_0_s(0) = '1' else a_0_s(7) ;
  a_1_s(5)  <= a_0_s(6)  xor CRC_POLY_G(5)  when a_0_s(0) = '1' else a_0_s(6) ;
  a_1_s(4)  <= a_0_s(5)  xor CRC_POLY_G(4)  when a_0_s(0) = '1' else a_0_s(5) ;
  a_1_s(3)  <= a_0_s(4)  xor CRC_POLY_G(3)  when a_0_s(0) = '1' else a_0_s(4) ;
  a_1_s(2)  <= a_0_s(3)  xor CRC_POLY_G(2)  when a_0_s(0) = '1' else a_0_s(3) ;
  a_1_s(1)  <= a_0_s(2)  xor CRC_POLY_G(1)  when a_0_s(0) = '1' else a_0_s(2) ;
  a_1_s(0)  <= a_0_s(1)  xor CRC_POLY_G(0)  when a_0_s(0) = '1' else a_0_s(1) ;

  a_2_s(15) <= '1'                          when a_1_s(0) = '1' else '0'    ;
  a_2_s(14) <= a_1_s(15) xor CRC_POLY_G(14) when a_1_s(0) = '1' else a_1_s(15);
  a_2_s(13) <= a_1_s(14) xor CRC_POLY_G(13) when a_1_s(0) = '1' else a_1_s(14);
  a_2_s(12) <= a_1_s(13) xor CRC_POLY_G(12) when a_1_s(0) = '1' else a_1_s(13);
  a_2_s(11) <= a_1_s(12) xor CRC_POLY_G(11) when a_1_s(0) = '1' else a_1_s(12);
  a_2_s(10) <= a_1_s(11) xor CRC_POLY_G(10) when a_1_s(0) = '1' else a_1_s(11);
  a_2_s(9)  <= a_1_s(10) xor CRC_POLY_G(9 ) when a_1_s(0) = '1' else a_1_s(10);
  a_2_s(8)  <= a_1_s(9 ) xor CRC_POLY_G(8 ) when a_1_s(0) = '1' else a_1_s(9 );
  a_2_s(7)  <= a_1_s(8 ) xor CRC_POLY_G(7)  when a_1_s(0) = '1' else a_1_s(8 );
  a_2_s(6)  <= a_1_s(7)  xor CRC_POLY_G(6)  when a_1_s(0) = '1' else a_1_s(7) ;
  a_2_s(5)  <= a_1_s(6)  xor CRC_POLY_G(5)  when a_1_s(0) = '1' else a_1_s(6) ;
  a_2_s(4)  <= a_1_s(5)  xor CRC_POLY_G(4)  when a_1_s(0) = '1' else a_1_s(5) ;
  a_2_s(3)  <= a_1_s(4)  xor CRC_POLY_G(3)  when a_1_s(0) = '1' else a_1_s(4) ;
  a_2_s(2)  <= a_1_s(3)  xor CRC_POLY_G(2)  when a_1_s(0) = '1' else a_1_s(3) ;
  a_2_s(1)  <= a_1_s(2)  xor CRC_POLY_G(1)  when a_1_s(0) = '1' else a_1_s(2) ;
  a_2_s(0)  <= a_1_s(1)  xor CRC_POLY_G(0)  when a_1_s(0) = '1' else a_1_s(1) ;

  a_3_s(15) <= '1'                          when a_2_s(0) = '1' else '0'    ;
  a_3_s(14) <= a_2_s(15) xor CRC_POLY_G(14) when a_2_s(0) = '1' else a_2_s(15);
  a_3_s(13) <= a_2_s(14) xor CRC_POLY_G(13) when a_2_s(0) = '1' else a_2_s(14);
  a_3_s(12) <= a_2_s(13) xor CRC_POLY_G(12) when a_2_s(0) = '1' else a_2_s(13);
  a_3_s(11) <= a_2_s(12) xor CRC_POLY_G(11) when a_2_s(0) = '1' else a_2_s(12);
  a_3_s(10) <= a_2_s(11) xor CRC_POLY_G(10) when a_2_s(0) = '1' else a_2_s(11);
  a_3_s(9)  <= a_2_s(10) xor CRC_POLY_G(9 ) when a_2_s(0) = '1' else a_2_s(10);
  a_3_s(8)  <= a_2_s(9 ) xor CRC_POLY_G(8 ) when a_2_s(0) = '1' else a_2_s(9 );
  a_3_s(7)  <= a_2_s(8 ) xor CRC_POLY_G(7)  when a_2_s(0) = '1' else a_2_s(8 );
  a_3_s(6)  <= a_2_s(7)  xor CRC_POLY_G(6)  when a_2_s(0) = '1' else a_2_s(7) ;
  a_3_s(5)  <= a_2_s(6)  xor CRC_POLY_G(5)  when a_2_s(0) = '1' else a_2_s(6) ;
  a_3_s(4)  <= a_2_s(5)  xor CRC_POLY_G(4)  when a_2_s(0) = '1' else a_2_s(5) ;
  a_3_s(3)  <= a_2_s(4)  xor CRC_POLY_G(3)  when a_2_s(0) = '1' else a_2_s(4) ;
  a_3_s(2)  <= a_2_s(3)  xor CRC_POLY_G(2)  when a_2_s(0) = '1' else a_2_s(3) ;
  a_3_s(1)  <= a_2_s(2)  xor CRC_POLY_G(1)  when a_2_s(0) = '1' else a_2_s(2) ;
  a_3_s(0)  <= a_2_s(1)  xor CRC_POLY_G(0)  when a_2_s(0) = '1' else a_2_s(1) ;

  a_4_s(15) <= '1'                          when a_3_s(0) = '1' else '0'    ;
  a_4_s(14) <= a_3_s(15) xor CRC_POLY_G(14) when a_3_s(0) = '1' else a_3_s(15);
  a_4_s(13) <= a_3_s(14) xor CRC_POLY_G(13) when a_3_s(0) = '1' else a_3_s(14);
  a_4_s(12) <= a_3_s(13) xor CRC_POLY_G(12) when a_3_s(0) = '1' else a_3_s(13);
  a_4_s(11) <= a_3_s(12) xor CRC_POLY_G(11) when a_3_s(0) = '1' else a_3_s(12);
  a_4_s(10) <= a_3_s(11) xor CRC_POLY_G(10) when a_3_s(0) = '1' else a_3_s(11);
  a_4_s(9)  <= a_3_s(10) xor CRC_POLY_G(9 ) when a_3_s(0) = '1' else a_3_s(10);
  a_4_s(8)  <= a_3_s(9 ) xor CRC_POLY_G(8 ) when a_3_s(0) = '1' else a_3_s(9 );
  a_4_s(7)  <= a_3_s(8 ) xor CRC_POLY_G(7)  when a_3_s(0) = '1' else a_3_s(8 );
  a_4_s(6)  <= a_3_s(7)  xor CRC_POLY_G(6)  when a_3_s(0) = '1' else a_3_s(7) ;
  a_4_s(5)  <= a_3_s(6)  xor CRC_POLY_G(5)  when a_3_s(0) = '1' else a_3_s(6) ;
  a_4_s(4)  <= a_3_s(5)  xor CRC_POLY_G(4)  when a_3_s(0) = '1' else a_3_s(5) ;
  a_4_s(3)  <= a_3_s(4)  xor CRC_POLY_G(3)  when a_3_s(0) = '1' else a_3_s(4) ;
  a_4_s(2)  <= a_3_s(3)  xor CRC_POLY_G(2)  when a_3_s(0) = '1' else a_3_s(3) ;
  a_4_s(1)  <= a_3_s(2)  xor CRC_POLY_G(1)  when a_3_s(0) = '1' else a_3_s(2) ;
  a_4_s(0)  <= a_3_s(1)  xor CRC_POLY_G(0)  when a_3_s(0) = '1' else a_3_s(1) ;

  a_5_s(15) <= '1'                          when a_4_s(0) = '1' else '0'    ;
  a_5_s(14) <= a_4_s(15) xor CRC_POLY_G(14) when a_4_s(0) = '1' else a_4_s(15);
  a_5_s(13) <= a_4_s(14) xor CRC_POLY_G(13) when a_4_s(0) = '1' else a_4_s(14);
  a_5_s(12) <= a_4_s(13) xor CRC_POLY_G(12) when a_4_s(0) = '1' else a_4_s(13);
  a_5_s(11) <= a_4_s(12) xor CRC_POLY_G(11) when a_4_s(0) = '1' else a_4_s(12);
  a_5_s(10) <= a_4_s(11) xor CRC_POLY_G(10) when a_4_s(0) = '1' else a_4_s(11);
  a_5_s(9)  <= a_4_s(10) xor CRC_POLY_G(9 ) when a_4_s(0) = '1' else a_4_s(10);
  a_5_s(8)  <= a_4_s(9 ) xor CRC_POLY_G(8 ) when a_4_s(0) = '1' else a_4_s(9 );
  a_5_s(7)  <= a_4_s(8 ) xor CRC_POLY_G(7)  when a_4_s(0) = '1' else a_4_s(8 );
  a_5_s(6)  <= a_4_s(7)  xor CRC_POLY_G(6)  when a_4_s(0) = '1' else a_4_s(7) ;
  a_5_s(5)  <= a_4_s(6)  xor CRC_POLY_G(5)  when a_4_s(0) = '1' else a_4_s(6) ;
  a_5_s(4)  <= a_4_s(5)  xor CRC_POLY_G(4)  when a_4_s(0) = '1' else a_4_s(5) ;
  a_5_s(3)  <= a_4_s(4)  xor CRC_POLY_G(3)  when a_4_s(0) = '1' else a_4_s(4) ;
  a_5_s(2)  <= a_4_s(3)  xor CRC_POLY_G(2)  when a_4_s(0) = '1' else a_4_s(3) ;
  a_5_s(1)  <= a_4_s(2)  xor CRC_POLY_G(1)  when a_4_s(0) = '1' else a_4_s(2) ;
  a_5_s(0)  <= a_4_s(1)  xor CRC_POLY_G(0)  when a_4_s(0) = '1' else a_4_s(1) ;

  a_6_s(15) <= '1'                          when a_5_s(0) = '1' else '0'    ;
  a_6_s(14) <= a_5_s(15) xor CRC_POLY_G(14) when a_5_s(0) = '1' else a_5_s(15);
  a_6_s(13) <= a_5_s(14) xor CRC_POLY_G(13) when a_5_s(0) = '1' else a_5_s(14);
  a_6_s(12) <= a_5_s(13) xor CRC_POLY_G(12) when a_5_s(0) = '1' else a_5_s(13);
  a_6_s(11) <= a_5_s(12) xor CRC_POLY_G(11) when a_5_s(0) = '1' else a_5_s(12);
  a_6_s(10) <= a_5_s(11) xor CRC_POLY_G(10) when a_5_s(0) = '1' else a_5_s(11);
  a_6_s(9)  <= a_5_s(10) xor CRC_POLY_G(9 ) when a_5_s(0) = '1' else a_5_s(10);
  a_6_s(8)  <= a_5_s(9 ) xor CRC_POLY_G(8 ) when a_5_s(0) = '1' else a_5_s(9 );
  a_6_s(7)  <= a_5_s(8 ) xor CRC_POLY_G(7)  when a_5_s(0) = '1' else a_5_s(8 );
  a_6_s(6)  <= a_5_s(7)  xor CRC_POLY_G(6)  when a_5_s(0) = '1' else a_5_s(7) ;
  a_6_s(5)  <= a_5_s(6)  xor CRC_POLY_G(5)  when a_5_s(0) = '1' else a_5_s(6) ;
  a_6_s(4)  <= a_5_s(5)  xor CRC_POLY_G(4)  when a_5_s(0) = '1' else a_5_s(5) ;
  a_6_s(3)  <= a_5_s(4)  xor CRC_POLY_G(3)  when a_5_s(0) = '1' else a_5_s(4) ;
  a_6_s(2)  <= a_5_s(3)  xor CRC_POLY_G(2)  when a_5_s(0) = '1' else a_5_s(3) ;
  a_6_s(1)  <= a_5_s(2)  xor CRC_POLY_G(1)  when a_5_s(0) = '1' else a_5_s(2) ;
  a_6_s(0)  <= a_5_s(1)  xor CRC_POLY_G(0)  when a_5_s(0) = '1' else a_5_s(1) ;

  a_7_s(15) <= '1'                          when a_6_s(0) = '1' else '0'    ;
  a_7_s(14) <= a_6_s(15) xor CRC_POLY_G(14) when a_6_s(0) = '1' else a_6_s(15);
  a_7_s(13) <= a_6_s(14) xor CRC_POLY_G(13) when a_6_s(0) = '1' else a_6_s(14);
  a_7_s(12) <= a_6_s(13) xor CRC_POLY_G(12) when a_6_s(0) = '1' else a_6_s(13);
  a_7_s(11) <= a_6_s(12) xor CRC_POLY_G(11) when a_6_s(0) = '1' else a_6_s(12);
  a_7_s(10) <= a_6_s(11) xor CRC_POLY_G(10) when a_6_s(0) = '1' else a_6_s(11);
  a_7_s(9)  <= a_6_s(10) xor CRC_POLY_G(9 ) when a_6_s(0) = '1' else a_6_s(10);
  a_7_s(8)  <= a_6_s(9 ) xor CRC_POLY_G(8 ) when a_6_s(0) = '1' else a_6_s(9 );
  a_7_s(7)  <= a_6_s(8 ) xor CRC_POLY_G(7)  when a_6_s(0) = '1' else a_6_s(8 );
  a_7_s(6)  <= a_6_s(7)  xor CRC_POLY_G(6)  when a_6_s(0) = '1' else a_6_s(7) ;
  a_7_s(5)  <= a_6_s(6)  xor CRC_POLY_G(5)  when a_6_s(0) = '1' else a_6_s(6) ;
  a_7_s(4)  <= a_6_s(5)  xor CRC_POLY_G(4)  when a_6_s(0) = '1' else a_6_s(5) ;
  a_7_s(3)  <= a_6_s(4)  xor CRC_POLY_G(3)  when a_6_s(0) = '1' else a_6_s(4) ;
  a_7_s(2)  <= a_6_s(3)  xor CRC_POLY_G(2)  when a_6_s(0) = '1' else a_6_s(3) ;
  a_7_s(1)  <= a_6_s(2)  xor CRC_POLY_G(1)  when a_6_s(0) = '1' else a_6_s(2) ;
  a_7_s(0)  <= a_6_s(1)  xor CRC_POLY_G(0)  when a_6_s(0) = '1' else a_6_s(1) ;

  crc_byte0_s(15) <= '1'                          when a_7_s(0) = '1' else '0'    ;
  crc_byte0_s(14) <= a_7_s(15) xor CRC_POLY_G(14) when a_7_s(0) = '1' else a_7_s(15);
  crc_byte0_s(13) <= a_7_s(14) xor CRC_POLY_G(13) when a_7_s(0) = '1' else a_7_s(14);
  crc_byte0_s(12) <= a_7_s(13) xor CRC_POLY_G(12) when a_7_s(0) = '1' else a_7_s(13);
  crc_byte0_s(11) <= a_7_s(12) xor CRC_POLY_G(11) when a_7_s(0) = '1' else a_7_s(12);
  crc_byte0_s(10) <= a_7_s(11) xor CRC_POLY_G(10) when a_7_s(0) = '1' else a_7_s(11);
  crc_byte0_s(9)  <= a_7_s(10) xor CRC_POLY_G(9 ) when a_7_s(0) = '1' else a_7_s(10);
  crc_byte0_s(8)  <= a_7_s(9 ) xor CRC_POLY_G(8 ) when a_7_s(0) = '1' else a_7_s(9 );
  crc_byte0_s(7)  <= a_7_s(8 ) xor CRC_POLY_G(7)  when a_7_s(0) = '1' else a_7_s(8 );
  crc_byte0_s(6)  <= a_7_s(7)  xor CRC_POLY_G(6)  when a_7_s(0) = '1' else a_7_s(7) ;
  crc_byte0_s(5)  <= a_7_s(6)  xor CRC_POLY_G(5)  when a_7_s(0) = '1' else a_7_s(6) ;
  crc_byte0_s(4)  <= a_7_s(5)  xor CRC_POLY_G(4)  when a_7_s(0) = '1' else a_7_s(5) ;
  crc_byte0_s(3)  <= a_7_s(4)  xor CRC_POLY_G(3)  when a_7_s(0) = '1' else a_7_s(4) ;
  crc_byte0_s(2)  <= a_7_s(3)  xor CRC_POLY_G(2)  when a_7_s(0) = '1' else a_7_s(3) ;
  crc_byte0_s(1)  <= a_7_s(2)  xor CRC_POLY_G(1)  when a_7_s(0) = '1' else a_7_s(2) ;
  crc_byte0_s(0)  <= a_7_s(1)  xor CRC_POLY_G(0)  when a_7_s(0) = '1' else a_7_s(1) ;

  b_0_s     <= crc_byte0_s xor in_data_b_0_xor_ext_s;
  b_1_s(15) <= '1'                          when b_0_s(0) = '1' else  '0';
  b_1_s(14) <= b_0_s(15) xor CRC_POLY_G(14) when b_0_s(0) = '1' else b_0_s(15);
  b_1_s(13) <= b_0_s(14) xor CRC_POLY_G(13) when b_0_s(0) = '1' else b_0_s(14);
  b_1_s(12) <= b_0_s(13) xor CRC_POLY_G(12) when b_0_s(0) = '1' else b_0_s(13);
  b_1_s(11) <= b_0_s(12) xor CRC_POLY_G(11) when b_0_s(0) = '1' else b_0_s(12);
  b_1_s(10) <= b_0_s(11) xor CRC_POLY_G(10) when b_0_s(0) = '1' else b_0_s(11);
  b_1_s(9)  <= b_0_s(10) xor CRC_POLY_G(9 ) when b_0_s(0) = '1' else b_0_s(10);
  b_1_s(8)  <= b_0_s(9)  xor CRC_POLY_G(8 ) when b_0_s(0) = '1' else b_0_s(9 );
  b_1_s(7)  <= b_0_s(8)  xor CRC_POLY_G(7)  when b_0_s(0) = '1' else b_0_s(8 );
  b_1_s(6)  <= b_0_s(7)  xor CRC_POLY_G(6)  when b_0_s(0) = '1' else b_0_s(7) ;
  b_1_s(5)  <= b_0_s(6)  xor CRC_POLY_G(5)  when b_0_s(0) = '1' else b_0_s(6) ;
  b_1_s(4)  <= b_0_s(5)  xor CRC_POLY_G(4)  when b_0_s(0) = '1' else b_0_s(5) ;
  b_1_s(3)  <= b_0_s(4)  xor CRC_POLY_G(3)  when b_0_s(0) = '1' else b_0_s(4) ;
  b_1_s(2)  <= b_0_s(3)  xor CRC_POLY_G(2)  when b_0_s(0) = '1' else b_0_s(3) ;
  b_1_s(1)  <= b_0_s(2)  xor CRC_POLY_G(1)  when b_0_s(0) = '1' else b_0_s(2) ;
  b_1_s(0)  <= b_0_s(1)  xor CRC_POLY_G(0)  when b_0_s(0) = '1' else b_0_s(1) ;

  b_2_s(15) <= '1'                          when b_1_s(0) = '1' else '0'    ;
  b_2_s(14) <= b_1_s(15) xor CRC_POLY_G(14) when b_1_s(0) = '1' else b_1_s(15);
  b_2_s(13) <= b_1_s(14) xor CRC_POLY_G(13) when b_1_s(0) = '1' else b_1_s(14);
  b_2_s(12) <= b_1_s(13) xor CRC_POLY_G(12) when b_1_s(0) = '1' else b_1_s(13);
  b_2_s(11) <= b_1_s(12) xor CRC_POLY_G(11) when b_1_s(0) = '1' else b_1_s(12);
  b_2_s(10) <= b_1_s(11) xor CRC_POLY_G(10) when b_1_s(0) = '1' else b_1_s(11);
  b_2_s(9)  <= b_1_s(10) xor CRC_POLY_G(9 ) when b_1_s(0) = '1' else b_1_s(10);
  b_2_s(8)  <= b_1_s(9 ) xor CRC_POLY_G(8 ) when b_1_s(0) = '1' else b_1_s(9 );
  b_2_s(7)  <= b_1_s(8 ) xor CRC_POLY_G(7)  when b_1_s(0) = '1' else b_1_s(8 );
  b_2_s(6)  <= b_1_s(7)  xor CRC_POLY_G(6)  when b_1_s(0) = '1' else b_1_s(7) ;
  b_2_s(5)  <= b_1_s(6)  xor CRC_POLY_G(5)  when b_1_s(0) = '1' else b_1_s(6) ;
  b_2_s(4)  <= b_1_s(5)  xor CRC_POLY_G(4)  when b_1_s(0) = '1' else b_1_s(5) ;
  b_2_s(3)  <= b_1_s(4)  xor CRC_POLY_G(3)  when b_1_s(0) = '1' else b_1_s(4) ;
  b_2_s(2)  <= b_1_s(3)  xor CRC_POLY_G(2)  when b_1_s(0) = '1' else b_1_s(3) ;
  b_2_s(1)  <= b_1_s(2)  xor CRC_POLY_G(1)  when b_1_s(0) = '1' else b_1_s(2) ;
  b_2_s(0)  <= b_1_s(1)  xor CRC_POLY_G(0)  when b_1_s(0) = '1' else b_1_s(1) ;

  b_3_s(15) <= '1'                          when b_2_s(0) = '1' else '0'    ;
  b_3_s(14) <= b_2_s(15) xor CRC_POLY_G(14) when b_2_s(0) = '1' else b_2_s(15);
  b_3_s(13) <= b_2_s(14) xor CRC_POLY_G(13) when b_2_s(0) = '1' else b_2_s(14);
  b_3_s(12) <= b_2_s(13) xor CRC_POLY_G(12) when b_2_s(0) = '1' else b_2_s(13);
  b_3_s(11) <= b_2_s(12) xor CRC_POLY_G(11) when b_2_s(0) = '1' else b_2_s(12);
  b_3_s(10) <= b_2_s(11) xor CRC_POLY_G(10) when b_2_s(0) = '1' else b_2_s(11);
  b_3_s(9)  <= b_2_s(10) xor CRC_POLY_G(9 ) when b_2_s(0) = '1' else b_2_s(10);
  b_3_s(8)  <= b_2_s(9 ) xor CRC_POLY_G(8 ) when b_2_s(0) = '1' else b_2_s(9 );
  b_3_s(7)  <= b_2_s(8 ) xor CRC_POLY_G(7)  when b_2_s(0) = '1' else b_2_s(8 );
  b_3_s(6)  <= b_2_s(7)  xor CRC_POLY_G(6)  when b_2_s(0) = '1' else b_2_s(7) ;
  b_3_s(5)  <= b_2_s(6)  xor CRC_POLY_G(5)  when b_2_s(0) = '1' else b_2_s(6) ;
  b_3_s(4)  <= b_2_s(5)  xor CRC_POLY_G(4)  when b_2_s(0) = '1' else b_2_s(5) ;
  b_3_s(3)  <= b_2_s(4)  xor CRC_POLY_G(3)  when b_2_s(0) = '1' else b_2_s(4) ;
  b_3_s(2)  <= b_2_s(3)  xor CRC_POLY_G(2)  when b_2_s(0) = '1' else b_2_s(3) ;
  b_3_s(1)  <= b_2_s(2)  xor CRC_POLY_G(1)  when b_2_s(0) = '1' else b_2_s(2) ;
  b_3_s(0)  <= b_2_s(1)  xor CRC_POLY_G(0)  when b_2_s(0) = '1' else b_2_s(1) ;

  b_4_s(15) <= '1'                          when b_3_s(0) = '1' else '0'    ;
  b_4_s(14) <= b_3_s(15) xor CRC_POLY_G(14) when b_3_s(0) = '1' else b_3_s(15);
  b_4_s(13) <= b_3_s(14) xor CRC_POLY_G(13) when b_3_s(0) = '1' else b_3_s(14);
  b_4_s(12) <= b_3_s(13) xor CRC_POLY_G(12) when b_3_s(0) = '1' else b_3_s(13);
  b_4_s(11) <= b_3_s(12) xor CRC_POLY_G(11) when b_3_s(0) = '1' else b_3_s(12);
  b_4_s(10) <= b_3_s(11) xor CRC_POLY_G(10) when b_3_s(0) = '1' else b_3_s(11);
  b_4_s(9)  <= b_3_s(10) xor CRC_POLY_G(9 ) when b_3_s(0) = '1' else b_3_s(10);
  b_4_s(8)  <= b_3_s(9 ) xor CRC_POLY_G(8 ) when b_3_s(0) = '1' else b_3_s(9 );
  b_4_s(7)  <= b_3_s(8 ) xor CRC_POLY_G(7)  when b_3_s(0) = '1' else b_3_s(8 );
  b_4_s(6)  <= b_3_s(7)  xor CRC_POLY_G(6)  when b_3_s(0) = '1' else b_3_s(7) ;
  b_4_s(5)  <= b_3_s(6)  xor CRC_POLY_G(5)  when b_3_s(0) = '1' else b_3_s(6) ;
  b_4_s(4)  <= b_3_s(5)  xor CRC_POLY_G(4)  when b_3_s(0) = '1' else b_3_s(5) ;
  b_4_s(3)  <= b_3_s(4)  xor CRC_POLY_G(3)  when b_3_s(0) = '1' else b_3_s(4) ;
  b_4_s(2)  <= b_3_s(3)  xor CRC_POLY_G(2)  when b_3_s(0) = '1' else b_3_s(3) ;
  b_4_s(1)  <= b_3_s(2)  xor CRC_POLY_G(1)  when b_3_s(0) = '1' else b_3_s(2) ;
  b_4_s(0)  <= b_3_s(1)  xor CRC_POLY_G(0)  when b_3_s(0) = '1' else b_3_s(1) ;

  b_5_s(15) <= '1'                          when b_4_s(0) = '1' else '0'    ;
  b_5_s(14) <= b_4_s(15) xor CRC_POLY_G(14) when b_4_s(0) = '1' else b_4_s(15);
  b_5_s(13) <= b_4_s(14) xor CRC_POLY_G(13) when b_4_s(0) = '1' else b_4_s(14);
  b_5_s(12) <= b_4_s(13) xor CRC_POLY_G(12) when b_4_s(0) = '1' else b_4_s(13);
  b_5_s(11) <= b_4_s(12) xor CRC_POLY_G(11) when b_4_s(0) = '1' else b_4_s(12);
  b_5_s(10) <= b_4_s(11) xor CRC_POLY_G(10) when b_4_s(0) = '1' else b_4_s(11);
  b_5_s(9)  <= b_4_s(10) xor CRC_POLY_G(9 ) when b_4_s(0) = '1' else b_4_s(10);
  b_5_s(8)  <= b_4_s(9 ) xor CRC_POLY_G(8 ) when b_4_s(0) = '1' else b_4_s(9 );
  b_5_s(7)  <= b_4_s(8 ) xor CRC_POLY_G(7)  when b_4_s(0) = '1' else b_4_s(8 );
  b_5_s(6)  <= b_4_s(7)  xor CRC_POLY_G(6)  when b_4_s(0) = '1' else b_4_s(7) ;
  b_5_s(5)  <= b_4_s(6)  xor CRC_POLY_G(5)  when b_4_s(0) = '1' else b_4_s(6) ;
  b_5_s(4)  <= b_4_s(5)  xor CRC_POLY_G(4)  when b_4_s(0) = '1' else b_4_s(5) ;
  b_5_s(3)  <= b_4_s(4)  xor CRC_POLY_G(3)  when b_4_s(0) = '1' else b_4_s(4) ;
  b_5_s(2)  <= b_4_s(3)  xor CRC_POLY_G(2)  when b_4_s(0) = '1' else b_4_s(3) ;
  b_5_s(1)  <= b_4_s(2)  xor CRC_POLY_G(1)  when b_4_s(0) = '1' else b_4_s(2) ;
  b_5_s(0)  <= b_4_s(1)  xor CRC_POLY_G(0)  when b_4_s(0) = '1' else b_4_s(1) ;

  b_6_s(15) <= '1'                          when b_5_s(0) = '1' else '0'    ;
  b_6_s(14) <= b_5_s(15) xor CRC_POLY_G(14) when b_5_s(0) = '1' else b_5_s(15);
  b_6_s(13) <= b_5_s(14) xor CRC_POLY_G(13) when b_5_s(0) = '1' else b_5_s(14);
  b_6_s(12) <= b_5_s(13) xor CRC_POLY_G(12) when b_5_s(0) = '1' else b_5_s(13);
  b_6_s(11) <= b_5_s(12) xor CRC_POLY_G(11) when b_5_s(0) = '1' else b_5_s(12);
  b_6_s(10) <= b_5_s(11) xor CRC_POLY_G(10) when b_5_s(0) = '1' else b_5_s(11);
  b_6_s(9)  <= b_5_s(10) xor CRC_POLY_G(9 ) when b_5_s(0) = '1' else b_5_s(10);
  b_6_s(8)  <= b_5_s(9 ) xor CRC_POLY_G(8 ) when b_5_s(0) = '1' else b_5_s(9 );
  b_6_s(7)  <= b_5_s(8 ) xor CRC_POLY_G(7)  when b_5_s(0) = '1' else b_5_s(8 );
  b_6_s(6)  <= b_5_s(7)  xor CRC_POLY_G(6)  when b_5_s(0) = '1' else b_5_s(7) ;
  b_6_s(5)  <= b_5_s(6)  xor CRC_POLY_G(5)  when b_5_s(0) = '1' else b_5_s(6) ;
  b_6_s(4)  <= b_5_s(5)  xor CRC_POLY_G(4)  when b_5_s(0) = '1' else b_5_s(5) ;
  b_6_s(3)  <= b_5_s(4)  xor CRC_POLY_G(3)  when b_5_s(0) = '1' else b_5_s(4) ;
  b_6_s(2)  <= b_5_s(3)  xor CRC_POLY_G(2)  when b_5_s(0) = '1' else b_5_s(3) ;
  b_6_s(1)  <= b_5_s(2)  xor CRC_POLY_G(1)  when b_5_s(0) = '1' else b_5_s(2) ;
  b_6_s(0)  <= b_5_s(1)  xor CRC_POLY_G(0)  when b_5_s(0) = '1' else b_5_s(1) ;

  b_7_s(15) <= '1'                          when b_6_s(0) = '1' else '0'    ;
  b_7_s(14) <= b_6_s(15) xor CRC_POLY_G(14) when b_6_s(0) = '1' else b_6_s(15);
  b_7_s(13) <= b_6_s(14) xor CRC_POLY_G(13) when b_6_s(0) = '1' else b_6_s(14);
  b_7_s(12) <= b_6_s(13) xor CRC_POLY_G(12) when b_6_s(0) = '1' else b_6_s(13);
  b_7_s(11) <= b_6_s(12) xor CRC_POLY_G(11) when b_6_s(0) = '1' else b_6_s(12);
  b_7_s(10) <= b_6_s(11) xor CRC_POLY_G(10) when b_6_s(0) = '1' else b_6_s(11);
  b_7_s(9)  <= b_6_s(10) xor CRC_POLY_G(9 ) when b_6_s(0) = '1' else b_6_s(10);
  b_7_s(8)  <= b_6_s(9 ) xor CRC_POLY_G(8 ) when b_6_s(0) = '1' else b_6_s(9 );
  b_7_s(7)  <= b_6_s(8 ) xor CRC_POLY_G(7)  when b_6_s(0) = '1' else b_6_s(8 );
  b_7_s(6)  <= b_6_s(7)  xor CRC_POLY_G(6)  when b_6_s(0) = '1' else b_6_s(7) ;
  b_7_s(5)  <= b_6_s(6)  xor CRC_POLY_G(5)  when b_6_s(0) = '1' else b_6_s(6) ;
  b_7_s(4)  <= b_6_s(5)  xor CRC_POLY_G(4)  when b_6_s(0) = '1' else b_6_s(5) ;
  b_7_s(3)  <= b_6_s(4)  xor CRC_POLY_G(3)  when b_6_s(0) = '1' else b_6_s(4) ;
  b_7_s(2)  <= b_6_s(3)  xor CRC_POLY_G(2)  when b_6_s(0) = '1' else b_6_s(3) ;
  b_7_s(1)  <= b_6_s(2)  xor CRC_POLY_G(1)  when b_6_s(0) = '1' else b_6_s(2) ;
  b_7_s(0)  <= b_6_s(1)  xor CRC_POLY_G(0)  when b_6_s(0) = '1' else b_6_s(1) ;

  -- Sequential process computing the output CRC
  seq_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_crc_q   <= (others => '1');
      out_ready_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cfg_enable_i = '1') then
          if (b_7_s(0) = '1') then
            out_crc_q(15) <= '1';
            out_crc_q(14) <= b_7_s(15) xor CRC_POLY_G(14);
            out_crc_q(13) <= b_7_s(14) xor CRC_POLY_G(13);
            out_crc_q(12) <= b_7_s(13) xor CRC_POLY_G(12);
            out_crc_q(11) <= b_7_s(12) xor CRC_POLY_G(11);
            out_crc_q(10) <= b_7_s(11) xor CRC_POLY_G(10);
            out_crc_q(9)  <= b_7_s(10) xor CRC_POLY_G( 9);
            out_crc_q(8)  <= b_7_s(9 ) xor CRC_POLY_G( 8);
            out_crc_q(7)  <= b_7_s(8 ) xor CRC_POLY_G( 7);
            out_crc_q(6)  <= b_7_s(7)  xor CRC_POLY_G( 6);
            out_crc_q(5)  <= b_7_s(6)  xor CRC_POLY_G( 5);
            out_crc_q(4)  <= b_7_s(5)  xor CRC_POLY_G( 4);
            out_crc_q(3)  <= b_7_s(4)  xor CRC_POLY_G( 3);
            out_crc_q(2)  <= b_7_s(3)  xor CRC_POLY_G( 2);
            out_crc_q(1)  <= b_7_s(2)  xor CRC_POLY_G( 1);
            out_crc_q(0)  <= b_7_s(1)  xor CRC_POLY_G( 0);
          else
            out_crc_q(15) <= '0'    ;
            out_crc_q(14) <= b_7_s(15);
            out_crc_q(13) <= b_7_s(14);
            out_crc_q(12) <= b_7_s(13);
            out_crc_q(11) <= b_7_s(12);
            out_crc_q(10) <= b_7_s(11);
            out_crc_q(9)  <= b_7_s(10);
            out_crc_q(8)  <= b_7_s( 9);
            out_crc_q(7)  <= b_7_s( 8);
            out_crc_q(6)  <= b_7_s( 7);
            out_crc_q(5)  <= b_7_s( 6);
            out_crc_q(4)  <= b_7_s( 5);
            out_crc_q(3)  <= b_7_s( 4);
            out_crc_q(2)  <= b_7_s( 3);
            out_crc_q(1)  <= b_7_s( 2);
            out_crc_q(0)  <= b_7_s( 1);
          end if;

          out_ready_q   <= '1';
        end if;
      end if;
    end if;
  end process seq_p;

end rtl;
