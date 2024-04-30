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
-- EVT STREAM SMART TRACKER Register Bank Package
package evt_stream_smart_tracker_reg_bank_pkg is


  --------------------------------------
  -- Global Register Bank Definitions --
  --------------------------------------

  constant REGISTER_BANK_NAME                                 : string     := "EVT_STREAM_SMART_TRACKER"; 
  constant EVT_STREAM_SMART_TRACKER_BASE_ADDR                 : natural    := 16#00000000#; 
  constant EVT_STREAM_SMART_TRACKER_LAST_ADDR                 : natural    := 16#0000002B#; 
  constant EVT_STREAM_SMART_TRACKER_SIZE                      : natural    := 16#00000100#; 



  -------------------------------------
  -- Register and Fields Definitions --
  -------------------------------------
  -- VERSION Register
  constant VERSION_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, 32)); 
  constant VERSION_WIDTH                                      : natural    := 32; 
  constant VERSION_DEFAULT                                    : std_logic_vector(VERSION_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00010000#, VERSION_WIDTH)); 
  constant VERSION_MINOR_WIDTH                                : natural    := 16; 
  constant VERSION_MINOR_MSB                                  : natural    := 15; 
  constant VERSION_MINOR_LSB                                  : natural    := 0; 
  constant VERSION_MAJOR_WIDTH                                : natural    := 16; 
  constant VERSION_MAJOR_MSB                                  : natural    := 31; 
  constant VERSION_MAJOR_LSB                                  : natural    := 16; 
  -- CONTROL Register
  constant CONTROL_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000004#, 32)); 
  constant CONTROL_WIDTH                                      : natural    := 32; 
  constant CONTROL_DEFAULT                                    : std_logic_vector(CONTROL_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000003#, CONTROL_WIDTH)); 
  constant CONTROL_ENABLE_WIDTH                               : natural    := 1; 
  constant CONTROL_ENABLE_MSB                                 : natural    := 0; 
  constant CONTROL_ENABLE_LSB                                 : natural    := 0; 
  constant CONTROL_ENABLE_DEFAULT                             : std_logic_vector(CONTROL_ENABLE_WIDTH-1 downto 0) := "1"; 
  constant CONTROL_BYPASS_WIDTH                               : natural    := 1; 
  constant CONTROL_BYPASS_MSB                                 : natural    := 1; 
  constant CONTROL_BYPASS_LSB                                 : natural    := 1; 
  constant CONTROL_BYPASS_DEFAULT                             : std_logic_vector(CONTROL_BYPASS_WIDTH-1 downto 0) := "1"; 
  constant CONTROL_CLEAR_WIDTH                                : natural    := 1; 
  constant CONTROL_CLEAR_MSB                                  : natural    := 2; 
  constant CONTROL_CLEAR_LSB                                  : natural    := 2; 
  constant CONTROL_CLEAR_DEFAULT                              : std_logic_vector(CONTROL_CLEAR_WIDTH-1 downto 0) := "0"; 
  -- SMART_DROPPER_CONTROL Register
  constant SMART_DROPPER_CONTROL_ADDR                         : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000008#, 32)); 
  constant SMART_DROPPER_CONTROL_WIDTH                        : natural    := 32; 
  constant SMART_DROPPER_CONTROL_DEFAULT                      : std_logic_vector(SMART_DROPPER_CONTROL_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, SMART_DROPPER_CONTROL_WIDTH)); 
  constant SMART_DROPPER_CONTROL_BYPASS_WIDTH                 : natural    := 1; 
  constant SMART_DROPPER_CONTROL_BYPASS_MSB                   : natural    := 0; 
  constant SMART_DROPPER_CONTROL_BYPASS_LSB                   : natural    := 0; 
  constant SMART_DROPPER_CONTROL_BYPASS_DEFAULT               : std_logic_vector(SMART_DROPPER_CONTROL_BYPASS_WIDTH-1 downto 0) := "0"; 
  constant SMART_DROPPER_CONTROL_GEN_OTHER_EVT_WIDTH          : natural    := 1; 
  constant SMART_DROPPER_CONTROL_GEN_OTHER_EVT_MSB            : natural    := 1; 
  constant SMART_DROPPER_CONTROL_GEN_OTHER_EVT_LSB            : natural    := 1; 
  constant SMART_DROPPER_CONTROL_GEN_OTHER_EVT_DEFAULT        : std_logic_vector(SMART_DROPPER_CONTROL_GEN_OTHER_EVT_WIDTH-1 downto 0) := "0"; 
  constant SMART_DROPPER_CONTROL_EVT_DROP_FLAG_WIDTH          : natural    := 1; 
  constant SMART_DROPPER_CONTROL_EVT_DROP_FLAG_MSB            : natural    := 2; 
  constant SMART_DROPPER_CONTROL_EVT_DROP_FLAG_LSB            : natural    := 2; 
  constant SMART_DROPPER_CONTROL_EVT_DROP_FLAG_DEFAULT        : std_logic_vector(SMART_DROPPER_CONTROL_EVT_DROP_FLAG_WIDTH-1 downto 0) := "0"; 
  -- SMART_DROPPER_TH_DROP_CNT Register
  constant SMART_DROPPER_TH_DROP_CNT_ADDR                     : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#0000000C#, 32)); 
  constant SMART_DROPPER_TH_DROP_CNT_WIDTH                    : natural    := 32; 
  constant SMART_DROPPER_TH_DROP_CNT_DEFAULT                  : std_logic_vector(SMART_DROPPER_TH_DROP_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, SMART_DROPPER_TH_DROP_CNT_WIDTH)); 
  constant SMART_DROPPER_TH_DROP_CNT_VALUE_WIDTH              : natural    := 32; 
  constant SMART_DROPPER_TH_DROP_CNT_VALUE_MSB                : natural    := 31; 
  constant SMART_DROPPER_TH_DROP_CNT_VALUE_LSB                : natural    := 0; 
  constant SMART_DROPPER_TH_DROP_CNT_VALUE_DEFAULT            : std_logic_vector(SMART_DROPPER_TH_DROP_CNT_VALUE_WIDTH-1 downto 0) := "00000000000000000000000000000000"; 
  -- SMART_DROPPER_TL_DROP_CNT Register
  constant SMART_DROPPER_TL_DROP_CNT_ADDR                     : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000010#, 32)); 
  constant SMART_DROPPER_TL_DROP_CNT_WIDTH                    : natural    := 32; 
  constant SMART_DROPPER_TL_DROP_CNT_DEFAULT                  : std_logic_vector(SMART_DROPPER_TL_DROP_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, SMART_DROPPER_TL_DROP_CNT_WIDTH)); 
  constant SMART_DROPPER_TL_DROP_CNT_VALUE_WIDTH              : natural    := 32; 
  constant SMART_DROPPER_TL_DROP_CNT_VALUE_MSB                : natural    := 31; 
  constant SMART_DROPPER_TL_DROP_CNT_VALUE_LSB                : natural    := 0; 
  constant SMART_DROPPER_TL_DROP_CNT_VALUE_DEFAULT            : std_logic_vector(SMART_DROPPER_TL_DROP_CNT_VALUE_WIDTH-1 downto 0) := "00000000000000000000000000000000"; 
  -- SMART_DROPPER_EVT_DROP_CNT Register
  constant SMART_DROPPER_EVT_DROP_CNT_ADDR                    : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000014#, 32)); 
  constant SMART_DROPPER_EVT_DROP_CNT_WIDTH                   : natural    := 32; 
  constant SMART_DROPPER_EVT_DROP_CNT_DEFAULT                 : std_logic_vector(SMART_DROPPER_EVT_DROP_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, SMART_DROPPER_EVT_DROP_CNT_WIDTH)); 
  constant SMART_DROPPER_EVT_DROP_CNT_VALUE_WIDTH             : natural    := 32; 
  constant SMART_DROPPER_EVT_DROP_CNT_VALUE_MSB               : natural    := 31; 
  constant SMART_DROPPER_EVT_DROP_CNT_VALUE_LSB               : natural    := 0; 
  constant SMART_DROPPER_EVT_DROP_CNT_VALUE_DEFAULT           : std_logic_vector(SMART_DROPPER_EVT_DROP_CNT_VALUE_WIDTH-1 downto 0) := "00000000000000000000000000000000"; 
  -- TH_RECOVERY_CONTROL Register
  constant TH_RECOVERY_CONTROL_ADDR                           : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000018#, 32)); 
  constant TH_RECOVERY_CONTROL_WIDTH                          : natural    := 32; 
  constant TH_RECOVERY_CONTROL_DEFAULT                        : std_logic_vector(TH_RECOVERY_CONTROL_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, TH_RECOVERY_CONTROL_WIDTH)); 
  constant TH_RECOVERY_CONTROL_BYPASS_WIDTH                   : natural    := 1; 
  constant TH_RECOVERY_CONTROL_BYPASS_MSB                     : natural    := 0; 
  constant TH_RECOVERY_CONTROL_BYPASS_LSB                     : natural    := 0; 
  constant TH_RECOVERY_CONTROL_BYPASS_DEFAULT                 : std_logic_vector(TH_RECOVERY_CONTROL_BYPASS_WIDTH-1 downto 0) := "0"; 
  constant TH_RECOVERY_CONTROL_GEN_MISSING_TH_WIDTH           : natural    := 1; 
  constant TH_RECOVERY_CONTROL_GEN_MISSING_TH_MSB             : natural    := 1; 
  constant TH_RECOVERY_CONTROL_GEN_MISSING_TH_LSB             : natural    := 1; 
  constant TH_RECOVERY_CONTROL_GEN_MISSING_TH_DEFAULT         : std_logic_vector(TH_RECOVERY_CONTROL_GEN_MISSING_TH_WIDTH-1 downto 0) := "0"; 
  constant TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_WIDTH          : natural    := 1; 
  constant TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_MSB            : natural    := 2; 
  constant TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_LSB            : natural    := 2; 
  constant TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_DEFAULT        : std_logic_vector(TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_WIDTH-1 downto 0) := "0"; 
  constant TH_RECOVERY_CONTROL_GEN_OTHER_EVT_WIDTH            : natural    := 1; 
  constant TH_RECOVERY_CONTROL_GEN_OTHER_EVT_MSB              : natural    := 3; 
  constant TH_RECOVERY_CONTROL_GEN_OTHER_EVT_LSB              : natural    := 3; 
  constant TH_RECOVERY_CONTROL_GEN_OTHER_EVT_DEFAULT          : std_logic_vector(TH_RECOVERY_CONTROL_GEN_OTHER_EVT_WIDTH-1 downto 0) := "0"; 
  constant TH_RECOVERY_CONTROL_EVT_DROP_FLAG_WIDTH            : natural    := 1; 
  constant TH_RECOVERY_CONTROL_EVT_DROP_FLAG_MSB              : natural    := 4; 
  constant TH_RECOVERY_CONTROL_EVT_DROP_FLAG_LSB              : natural    := 4; 
  constant TH_RECOVERY_CONTROL_EVT_DROP_FLAG_DEFAULT          : std_logic_vector(TH_RECOVERY_CONTROL_EVT_DROP_FLAG_WIDTH-1 downto 0) := "0"; 
  constant TH_RECOVERY_CONTROL_GEN_TH_FLAG_WIDTH              : natural    := 1; 
  constant TH_RECOVERY_CONTROL_GEN_TH_FLAG_MSB                : natural    := 5; 
  constant TH_RECOVERY_CONTROL_GEN_TH_FLAG_LSB                : natural    := 5; 
  constant TH_RECOVERY_CONTROL_GEN_TH_FLAG_DEFAULT            : std_logic_vector(TH_RECOVERY_CONTROL_GEN_TH_FLAG_WIDTH-1 downto 0) := "0"; 
  -- TS_CHECKER_CONTROL Register
  constant TS_CHECKER_CONTROL_ADDR                            : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#0000001C#, 32)); 
  constant TS_CHECKER_CONTROL_WIDTH                           : natural    := 32; 
  constant TS_CHECKER_CONTROL_DEFAULT                         : std_logic_vector(TS_CHECKER_CONTROL_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000400#, TS_CHECKER_CONTROL_WIDTH)); 
  constant TS_CHECKER_CONTROL_BYPASS_WIDTH                    : natural    := 1; 
  constant TS_CHECKER_CONTROL_BYPASS_MSB                      : natural    := 0; 
  constant TS_CHECKER_CONTROL_BYPASS_LSB                      : natural    := 0; 
  constant TS_CHECKER_CONTROL_BYPASS_DEFAULT                  : std_logic_vector(TS_CHECKER_CONTROL_BYPASS_WIDTH-1 downto 0) := "0"; 
  constant TS_CHECKER_CONTROL_ENABLE_DROP_EVT_WIDTH           : natural    := 1; 
  constant TS_CHECKER_CONTROL_ENABLE_DROP_EVT_MSB             : natural    := 1; 
  constant TS_CHECKER_CONTROL_ENABLE_DROP_EVT_LSB             : natural    := 1; 
  constant TS_CHECKER_CONTROL_ENABLE_DROP_EVT_DEFAULT         : std_logic_vector(TS_CHECKER_CONTROL_ENABLE_DROP_EVT_WIDTH-1 downto 0) := "0"; 
  constant TS_CHECKER_CONTROL_GEN_OTHER_EVT_WIDTH             : natural    := 1; 
  constant TS_CHECKER_CONTROL_GEN_OTHER_EVT_MSB               : natural    := 2; 
  constant TS_CHECKER_CONTROL_GEN_OTHER_EVT_LSB               : natural    := 2; 
  constant TS_CHECKER_CONTROL_GEN_OTHER_EVT_DEFAULT           : std_logic_vector(TS_CHECKER_CONTROL_GEN_OTHER_EVT_WIDTH-1 downto 0) := "0"; 
  constant TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_WIDTH        : natural    := 1; 
  constant TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_MSB          : natural    := 3; 
  constant TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_LSB          : natural    := 3; 
  constant TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_DEFAULT      : std_logic_vector(TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_WIDTH-1 downto 0) := "0"; 
  constant TS_CHECKER_CONTROL_THRESHOLD_WIDTH                 : natural    := 28; 
  constant TS_CHECKER_CONTROL_THRESHOLD_MSB                   : natural    := 31; 
  constant TS_CHECKER_CONTROL_THRESHOLD_LSB                   : natural    := 4; 
  constant TS_CHECKER_CONTROL_THRESHOLD_DEFAULT               : std_logic_vector(TS_CHECKER_CONTROL_THRESHOLD_WIDTH-1 downto 0) := "0000000000000000000001000000"; 
  -- TS_CHECKER_TH_DETECT_CNT Register
  constant TS_CHECKER_TH_DETECT_CNT_ADDR                      : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000020#, 32)); 
  constant TS_CHECKER_TH_DETECT_CNT_WIDTH                     : natural    := 32; 
  constant TS_CHECKER_TH_DETECT_CNT_DEFAULT                   : std_logic_vector(TS_CHECKER_TH_DETECT_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, TS_CHECKER_TH_DETECT_CNT_WIDTH)); 
  constant TS_CHECKER_TH_DETECT_CNT_VALUE_WIDTH               : natural    := 16; 
  constant TS_CHECKER_TH_DETECT_CNT_VALUE_MSB                 : natural    := 15; 
  constant TS_CHECKER_TH_DETECT_CNT_VALUE_LSB                 : natural    := 0; 
  constant TS_CHECKER_TH_DETECT_CNT_VALUE_DEFAULT             : std_logic_vector(TS_CHECKER_TH_DETECT_CNT_VALUE_WIDTH-1 downto 0) := "0000000000000000"; 
  -- TS_CHECKER_TH_CORRUPT_CNT Register
  constant TS_CHECKER_TH_CORRUPT_CNT_ADDR                     : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000024#, 32)); 
  constant TS_CHECKER_TH_CORRUPT_CNT_WIDTH                    : natural    := 32; 
  constant TS_CHECKER_TH_CORRUPT_CNT_DEFAULT                  : std_logic_vector(TS_CHECKER_TH_CORRUPT_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, TS_CHECKER_TH_CORRUPT_CNT_WIDTH)); 
  constant TS_CHECKER_TH_CORRUPT_CNT_VALUE_WIDTH              : natural    := 16; 
  constant TS_CHECKER_TH_CORRUPT_CNT_VALUE_MSB                : natural    := 15; 
  constant TS_CHECKER_TH_CORRUPT_CNT_VALUE_LSB                : natural    := 0; 
  constant TS_CHECKER_TH_CORRUPT_CNT_VALUE_DEFAULT            : std_logic_vector(TS_CHECKER_TH_CORRUPT_CNT_VALUE_WIDTH-1 downto 0) := "0000000000000000"; 
  -- TS_CHECKER_TH_ERROR_CNT Register
  constant TS_CHECKER_TH_ERROR_CNT_ADDR                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000028#, 32)); 
  constant TS_CHECKER_TH_ERROR_CNT_WIDTH                      : natural    := 32; 
  constant TS_CHECKER_TH_ERROR_CNT_DEFAULT                    : std_logic_vector(TS_CHECKER_TH_ERROR_CNT_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, TS_CHECKER_TH_ERROR_CNT_WIDTH)); 
  constant TS_CHECKER_TH_ERROR_CNT_VALUE_WIDTH                : natural    := 16; 
  constant TS_CHECKER_TH_ERROR_CNT_VALUE_MSB                  : natural    := 15; 
  constant TS_CHECKER_TH_ERROR_CNT_VALUE_LSB                  : natural    := 0; 
  constant TS_CHECKER_TH_ERROR_CNT_VALUE_DEFAULT              : std_logic_vector(TS_CHECKER_TH_ERROR_CNT_VALUE_WIDTH-1 downto 0) := "0000000000000000"; 

  
end evt_stream_smart_tracker_reg_bank_pkg;


---------------------
-- Empty Package Body
package body evt_stream_smart_tracker_reg_bank_pkg is
end package body;
