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
-- MIPI TX Register Bank Package
package mipi_tx_reg_bank_pkg is


  --------------------------------------
  -- Global Register Bank Definitions --
  --------------------------------------

  constant REGISTER_BANK_NAME                                 : string     := "MIPI_TX"; 
  constant MIPI_TX_BASE_ADDR                                  : natural    := 16#00000000#; 
  constant MIPI_TX_LAST_ADDR                                  : natural    := 16#0000002B#; 
  constant MIPI_TX_SIZE                                       : natural    := 16#00000100#; 



  -------------------------------------
  -- Register and Fields Definitions --
  -------------------------------------
  -- CONTROL Register
  constant CONTROL_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, 32)); 
  constant CONTROL_WIDTH                                      : natural    := 32; 
  constant CONTROL_DEFAULT                                    : std_logic_vector(CONTROL_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#0000000C#, CONTROL_WIDTH)); 
  constant CONTROL_ENABLE_WIDTH                               : natural    := 1; 
  constant CONTROL_ENABLE_MSB                                 : natural    := 0; 
  constant CONTROL_ENABLE_LSB                                 : natural    := 0; 
  constant CONTROL_ENABLE_DEFAULT                             : std_logic_vector(CONTROL_ENABLE_WIDTH-1 downto 0) := "0"; 
  constant CONTROL_ENABLE_PACKET_TIMEOUT_WIDTH                : natural    := 1; 
  constant CONTROL_ENABLE_PACKET_TIMEOUT_MSB                  : natural    := 1; 
  constant CONTROL_ENABLE_PACKET_TIMEOUT_LSB                  : natural    := 1; 
  constant CONTROL_ENABLE_PACKET_TIMEOUT_DEFAULT              : std_logic_vector(CONTROL_ENABLE_PACKET_TIMEOUT_WIDTH-1 downto 0) := "0"; 
  constant CONTROL_BLOCKING_MODE_WIDTH                        : natural    := 1; 
  constant CONTROL_BLOCKING_MODE_MSB                          : natural    := 2; 
  constant CONTROL_BLOCKING_MODE_LSB                          : natural    := 2; 
  constant CONTROL_BLOCKING_MODE_DEFAULT                      : std_logic_vector(CONTROL_BLOCKING_MODE_WIDTH-1 downto 0) := "1"; 
  constant CONTROL_PADDING_BYPASS_WIDTH                       : natural    := 1; 
  constant CONTROL_PADDING_BYPASS_MSB                         : natural    := 3; 
  constant CONTROL_PADDING_BYPASS_LSB                         : natural    := 3; 
  constant CONTROL_PADDING_BYPASS_DEFAULT                     : std_logic_vector(CONTROL_PADDING_BYPASS_WIDTH-1 downto 0) := "1"; 
  -- DATA_IDENTIFIER Register
  constant DATA_IDENTIFIER_ADDR                               : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000004#, 32)); 
  constant DATA_IDENTIFIER_WIDTH                              : natural    := 32; 
  constant DATA_IDENTIFIER_DEFAULT                            : std_logic_vector(DATA_IDENTIFIER_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000030#, DATA_IDENTIFIER_WIDTH)); 
  constant DATA_IDENTIFIER_DATA_TYPE_WIDTH                    : natural    := 6; 
  constant DATA_IDENTIFIER_DATA_TYPE_MSB                      : natural    := 5; 
  constant DATA_IDENTIFIER_DATA_TYPE_LSB                      : natural    := 0; 
  constant DATA_IDENTIFIER_DATA_TYPE_DEFAULT                  : std_logic_vector(DATA_IDENTIFIER_DATA_TYPE_WIDTH-1 downto 0) := "110000"; 
  constant DATA_IDENTIFIER_VIRTUAL_CHANNEL_WIDTH              : natural    := 2; 
  constant DATA_IDENTIFIER_VIRTUAL_CHANNEL_MSB                : natural    := 7; 
  constant DATA_IDENTIFIER_VIRTUAL_CHANNEL_LSB                : natural    := 6; 
  constant DATA_IDENTIFIER_VIRTUAL_CHANNEL_DEFAULT            : std_logic_vector(DATA_IDENTIFIER_VIRTUAL_CHANNEL_WIDTH-1 downto 0) := "00"; 
  -- FRAME_PERIOD Register
  constant FRAME_PERIOD_ADDR                                  : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000008#, 32)); 
  constant FRAME_PERIOD_WIDTH                                 : natural    := 32; 
  constant FRAME_PERIOD_DEFAULT                               : std_logic_vector(FRAME_PERIOD_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#000003F0#, FRAME_PERIOD_WIDTH)); 
  constant FRAME_PERIOD_VALUE_US_WIDTH                        : natural    := 16; 
  constant FRAME_PERIOD_VALUE_US_MSB                          : natural    := 15; 
  constant FRAME_PERIOD_VALUE_US_LSB                          : natural    := 0; 
  constant FRAME_PERIOD_VALUE_US_DEFAULT                      : std_logic_vector(FRAME_PERIOD_VALUE_US_WIDTH-1 downto 0) := "0000001111110000"; 
  -- PACKET_TIMEOUT Register
  constant PACKET_TIMEOUT_ADDR                                : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#0000000C#, 32)); 
  constant PACKET_TIMEOUT_WIDTH                               : natural    := 32; 
  constant PACKET_TIMEOUT_DEFAULT                             : std_logic_vector(PACKET_TIMEOUT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#000001F8#, PACKET_TIMEOUT_WIDTH)); 
  constant PACKET_TIMEOUT_VALUE_US_WIDTH                      : natural    := 16; 
  constant PACKET_TIMEOUT_VALUE_US_MSB                        : natural    := 15; 
  constant PACKET_TIMEOUT_VALUE_US_LSB                        : natural    := 0; 
  constant PACKET_TIMEOUT_VALUE_US_DEFAULT                    : std_logic_vector(PACKET_TIMEOUT_VALUE_US_WIDTH-1 downto 0) := "0000000111111000"; 
  -- PACKET_SIZE Register
  constant PACKET_SIZE_ADDR                                   : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000010#, 32)); 
  constant PACKET_SIZE_WIDTH                                  : natural    := 32; 
  constant PACKET_SIZE_DEFAULT                                : std_logic_vector(PACKET_SIZE_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00002000#, PACKET_SIZE_WIDTH)); 
  constant PACKET_SIZE_VALUE_WIDTH                            : natural    := 14; 
  constant PACKET_SIZE_VALUE_MSB                              : natural    := 13; 
  constant PACKET_SIZE_VALUE_LSB                              : natural    := 0; 
  constant PACKET_SIZE_VALUE_DEFAULT                          : std_logic_vector(PACKET_SIZE_VALUE_WIDTH-1 downto 0) := "10000000000000"; 
  -- START_TIME Register
  constant START_TIME_ADDR                                    : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000014#, 32)); 
  constant START_TIME_WIDTH                                   : natural    := 32; 
  constant START_TIME_DEFAULT                                 : std_logic_vector(START_TIME_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000050#, START_TIME_WIDTH)); 
  constant START_TIME_VALUE_WIDTH                             : natural    := 16; 
  constant START_TIME_VALUE_MSB                               : natural    := 15; 
  constant START_TIME_VALUE_LSB                               : natural    := 0; 
  constant START_TIME_VALUE_DEFAULT                           : std_logic_vector(START_TIME_VALUE_WIDTH-1 downto 0) := "0000000001010000"; 
  -- START_FRAME_TIME Register
  constant START_FRAME_TIME_ADDR                              : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000018#, 32)); 
  constant START_FRAME_TIME_WIDTH                             : natural    := 32; 
  constant START_FRAME_TIME_DEFAULT                           : std_logic_vector(START_FRAME_TIME_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000050#, START_FRAME_TIME_WIDTH)); 
  constant START_FRAME_TIME_VALUE_WIDTH                       : natural    := 16; 
  constant START_FRAME_TIME_VALUE_MSB                         : natural    := 15; 
  constant START_FRAME_TIME_VALUE_LSB                         : natural    := 0; 
  constant START_FRAME_TIME_VALUE_DEFAULT                     : std_logic_vector(START_FRAME_TIME_VALUE_WIDTH-1 downto 0) := "0000000001010000"; 
  -- END_FRAME_TIME Register
  constant END_FRAME_TIME_ADDR                                : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#0000001C#, 32)); 
  constant END_FRAME_TIME_WIDTH                               : natural    := 32; 
  constant END_FRAME_TIME_DEFAULT                             : std_logic_vector(END_FRAME_TIME_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000050#, END_FRAME_TIME_WIDTH)); 
  constant END_FRAME_TIME_VALUE_WIDTH                         : natural    := 16; 
  constant END_FRAME_TIME_VALUE_MSB                           : natural    := 15; 
  constant END_FRAME_TIME_VALUE_LSB                           : natural    := 0; 
  constant END_FRAME_TIME_VALUE_DEFAULT                       : std_logic_vector(END_FRAME_TIME_VALUE_WIDTH-1 downto 0) := "0000000001010000"; 
  -- INTER_FRAME_TIME Register
  constant INTER_FRAME_TIME_ADDR                              : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000020#, 32)); 
  constant INTER_FRAME_TIME_WIDTH                             : natural    := 32; 
  constant INTER_FRAME_TIME_DEFAULT                           : std_logic_vector(INTER_FRAME_TIME_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000050#, INTER_FRAME_TIME_WIDTH)); 
  constant INTER_FRAME_TIME_VALUE_WIDTH                       : natural    := 16; 
  constant INTER_FRAME_TIME_VALUE_MSB                         : natural    := 15; 
  constant INTER_FRAME_TIME_VALUE_LSB                         : natural    := 0; 
  constant INTER_FRAME_TIME_VALUE_DEFAULT                     : std_logic_vector(INTER_FRAME_TIME_VALUE_WIDTH-1 downto 0) := "0000000001010000"; 
  -- INTER_PACKET_TIME Register
  constant INTER_PACKET_TIME_ADDR                             : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000024#, 32)); 
  constant INTER_PACKET_TIME_WIDTH                            : natural    := 32; 
  constant INTER_PACKET_TIME_DEFAULT                          : std_logic_vector(INTER_PACKET_TIME_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000050#, INTER_PACKET_TIME_WIDTH)); 
  constant INTER_PACKET_TIME_VALUE_WIDTH                      : natural    := 16; 
  constant INTER_PACKET_TIME_VALUE_MSB                        : natural    := 15; 
  constant INTER_PACKET_TIME_VALUE_LSB                        : natural    := 0; 
  constant INTER_PACKET_TIME_VALUE_DEFAULT                    : std_logic_vector(INTER_PACKET_TIME_VALUE_WIDTH-1 downto 0) := "0000000001010000"; 
  -- FEATURES Register
  constant FEATURES_ADDR                                      : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000028#, 32)); 
  constant FEATURES_WIDTH                                     : natural    := 32; 
  constant FEATURES_DEFAULT                                   : std_logic_vector(FEATURES_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, FEATURES_WIDTH)); 
  constant FEATURES_PADDING_PRESENT_WIDTH                     : natural    := 1; 
  constant FEATURES_PADDING_PRESENT_MSB                       : natural    := 0; 
  constant FEATURES_PADDING_PRESENT_LSB                       : natural    := 0; 
  constant FEATURES_FIXED_FRAME_PRESENT_WIDTH                 : natural    := 1; 
  constant FEATURES_FIXED_FRAME_PRESENT_MSB                   : natural    := 1; 
  constant FEATURES_FIXED_FRAME_PRESENT_LSB                   : natural    := 1; 

  
end mipi_tx_reg_bank_pkg;


---------------------
-- Empty Package Body
package body mipi_tx_reg_bank_pkg is
end package body;
