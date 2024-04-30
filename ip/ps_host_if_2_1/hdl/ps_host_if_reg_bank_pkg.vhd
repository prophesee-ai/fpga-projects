-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
-- Unless required by applicable law or agreed to in writing, software distributed
-- under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License
-- for the specific language governing permissions and limitations under the License.
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


---------------------------------------
-- PS HOST IF Register Bank Package
package ps_host_if_reg_bank_pkg is


  --------------------------------------
  -- Global Register Bank Definitions --
  --------------------------------------

  constant REGISTER_BANK_NAME                                 : string     := "PS_HOST_IF";
  constant PS_HOST_IF_BASE_ADDR                               : natural    := 16#00000000#;
  constant PS_HOST_IF_LAST_ADDR                               : natural    := 16#00000017#;
  constant PS_HOST_IF_SIZE                                    : natural    := 16#00000020#;



  -------------------------------------
  -- Register and Fields Definitions --
  -------------------------------------
  -- VERSION Register
  constant VERSION_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, 32));
  constant VERSION_WIDTH                                      : natural    := 32;
  constant VERSION_MINOR_WIDTH                                : natural    := 16;
  constant VERSION_MINOR_MSB                                  : natural    := 15;
  constant VERSION_MINOR_LSB                                  : natural    := 0;
  constant VERSION_MAJOR_WIDTH                                : natural    := 16;
  constant VERSION_MAJOR_MSB                                  : natural    := 31;
  constant VERSION_MAJOR_LSB                                  : natural    := 16;
  -- CONTROL Register
  constant CONTROL_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000004#, 32));
  constant CONTROL_WIDTH                                      : natural    := 32;
  constant CONTROL_DEFAULT                                    : std_logic_vector(CONTROL_WIDTH-1 downto 0) := "00000000000000000000000000000000";
  constant CONTROL_ENABLE_COUNTER_PATTERN_WIDTH               : natural    := 1;
  constant CONTROL_ENABLE_COUNTER_PATTERN_MSB                 : natural    := 0;
  constant CONTROL_ENABLE_COUNTER_PATTERN_LSB                 : natural    := 0;
  constant CONTROL_ENABLE_COUNTER_PATTERN_DEFAULT             : std_logic_vector(CONTROL_ENABLE_COUNTER_PATTERN_WIDTH-1 downto 0) := "0";
  constant CONTROL_ENABLE_TLAST_TIMEOUT_WIDTH                 : natural    := 1;
  constant CONTROL_ENABLE_TLAST_TIMEOUT_MSB                   : natural    := 1;
  constant CONTROL_ENABLE_TLAST_TIMEOUT_LSB                   : natural    := 1;
  constant CONTROL_ENABLE_TLAST_TIMEOUT_DEFAULT               : std_logic_vector(CONTROL_ENABLE_TLAST_TIMEOUT_WIDTH-1 downto 0) := "0";
  constant CONTROL_CLEAR_WIDTH                                : natural    := 1;
  constant CONTROL_CLEAR_MSB                                  : natural    := 2;
  constant CONTROL_CLEAR_LSB                                  : natural    := 2;
  constant CONTROL_CLEAR_DEFAULT                              : std_logic_vector(CONTROL_CLEAR_WIDTH-1 downto 0) := "0";
  -- PACKET_LENGTH Register
  constant PACKET_LENGTH_ADDR                                 : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000008#, 32));
  constant PACKET_LENGTH_WIDTH                                : natural    := 32;
  constant PACKET_LENGTH_DEFAULT                              : std_logic_vector(PACKET_LENGTH_WIDTH-1 downto 0) := "00000000000000000000010000000000";
  constant PACKET_LENGTH_VALUE_WIDTH                          : natural    := 32;
  constant PACKET_LENGTH_VALUE_MSB                            : natural    := 31;
  constant PACKET_LENGTH_VALUE_LSB                            : natural    := 0;
  constant PACKET_LENGTH_VALUE_DEFAULT                        : std_logic_vector(PACKET_LENGTH_VALUE_WIDTH-1 downto 0) := "00000000000000000000010000000000";
  -- TLAST_TIMEOUT Register
  constant TLAST_TIMEOUT_ADDR                                 : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#0000000C#, 32));
  constant TLAST_TIMEOUT_WIDTH                                : natural    := 32;
  constant TLAST_TIMEOUT_DEFAULT                              : std_logic_vector(TLAST_TIMEOUT_WIDTH-1 downto 0) := "00000000001000011101001011011010";
  constant TLAST_TIMEOUT_VALUE_WIDTH                          : natural    := 32;
  constant TLAST_TIMEOUT_VALUE_MSB                            : natural    := 31;
  constant TLAST_TIMEOUT_VALUE_LSB                            : natural    := 0;
  constant TLAST_TIMEOUT_VALUE_DEFAULT                        : std_logic_vector(TLAST_TIMEOUT_VALUE_WIDTH-1 downto 0) := "00000000001000011101001011011010";
  -- TLAST_TIMEOUT_EVT_MSB Register
  constant TLAST_TIMEOUT_EVT_MSB_ADDR                         : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000010#, 32));
  constant TLAST_TIMEOUT_EVT_MSB_WIDTH                        : natural    := 32;
  constant TLAST_TIMEOUT_EVT_MSB_DEFAULT                      : std_logic_vector(TLAST_TIMEOUT_EVT_MSB_WIDTH-1 downto 0) := "11100000000000000000000000000011";
  constant TLAST_TIMEOUT_EVT_MSB_VALUE_WIDTH                  : natural    := 32;
  constant TLAST_TIMEOUT_EVT_MSB_VALUE_MSB                    : natural    := 31;
  constant TLAST_TIMEOUT_EVT_MSB_VALUE_LSB                    : natural    := 0;
  constant TLAST_TIMEOUT_EVT_MSB_VALUE_DEFAULT                : std_logic_vector(TLAST_TIMEOUT_EVT_MSB_VALUE_WIDTH-1 downto 0) := "11100000000000000000000000000011";
  -- TLAST_TIMEOUT_EVT_LSB Register
  constant TLAST_TIMEOUT_EVT_LSB_ADDR                         : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000014#, 32));
  constant TLAST_TIMEOUT_EVT_LSB_WIDTH                        : natural    := 32;
  constant TLAST_TIMEOUT_EVT_LSB_DEFAULT                      : std_logic_vector(TLAST_TIMEOUT_EVT_LSB_WIDTH-1 downto 0) := "00000000000000000000000000000000";
  constant TLAST_TIMEOUT_EVT_LSB_VALUE_WIDTH                  : natural    := 32;
  constant TLAST_TIMEOUT_EVT_LSB_VALUE_MSB                    : natural    := 31;
  constant TLAST_TIMEOUT_EVT_LSB_VALUE_LSB                    : natural    := 0;
  constant TLAST_TIMEOUT_EVT_LSB_VALUE_DEFAULT                : std_logic_vector(TLAST_TIMEOUT_EVT_LSB_VALUE_WIDTH-1 downto 0) := "00000000000000000000000000000000";


end ps_host_if_reg_bank_pkg;


---------------------
-- Empty Package Body
package body ps_host_if_reg_bank_pkg is
end package body;
