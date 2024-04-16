----------------------------------------------------------------------------------
--
-- Copyright (c) 2017-2018 CHRONOCAM ALL RIGHTS RESERVED
--
-- Project Name: Moorea
-- Description: Event Type 2.1 description
--
-- Release version: $$release$$
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--synthesis translate_off
use ieee.std_logic_textio.all;
--synthesis translate_on

--synthesis translate_off
library std;
use std.textio.all;
--synthesis translate_on

library work;
use work.ccam_utils_pkg.all;


package ccam_evt_type_v2_1_pkg is

  -- Generic part
  --------------------
  -- Complete EVT 2.1 64 bits
  constant CCAM_EVT_2_1_BITS            : integer := 64;
  constant CCAM_EVT_2_1_LSB             : integer := 0;
  constant CCAM_EVT_2_1_MSB             : integer := CCAM_EVT_2_1_LSB + CCAM_EVT_2_1_BITS - 1;

  subtype CCAM_EVT_2_1_RANGE is integer range CCAM_EVT_2_1_MSB downto CCAM_EVT_2_1_LSB;

  -- Type 4 bits
  constant CCAM_EVT_2_1_TYPE_BITS      : integer := 4;
  constant CCAM_EVT_2_1_TYPE_LSB       : integer := 60;
  constant CCAM_EVT_2_1_TYPE_MSB       : integer := CCAM_EVT_2_1_TYPE_LSB + CCAM_EVT_2_1_TYPE_BITS - 1;
  subtype CCAM_EVT_2_1_TYPE_RANGE is integer range CCAM_EVT_2_1_TYPE_MSB downto CCAM_EVT_2_1_TYPE_LSB;

  -- Type's values
  constant CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_LOW     : std_logic_vector(3 downto 0) := x"0";
  constant CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_HIGH    : std_logic_vector(3 downto 0) := x"1";
  constant CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_END    : std_logic_vector(3 downto 0) := x"2";
  constant CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_START  : std_logic_vector(3 downto 0) := x"3";
  constant CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_LOW    : std_logic_vector(3 downto 0) := x"4";
  constant CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_HIGH   : std_logic_vector(3 downto 0) := x"5";
  constant CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_END   : std_logic_vector(3 downto 0) := x"6";
  constant CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_START : std_logic_vector(3 downto 0) := x"7";
  constant CCAM_EVT_2_1_TYPE_VALUE_EVT_TIME_HIGH   : std_logic_vector(3 downto 0) := x"8";
  constant CCAM_EVT_2_1_TYPE_VALUE_STEREO_DISP     : std_logic_vector(3 downto 0) := x"9";
  constant CCAM_EVT_2_1_TYPE_VALUE_EXT_TRIGGER     : std_logic_vector(3 downto 0) := x"A";
  constant CCAM_EVT_2_1_TYPE_VALUE_GRAY_LEVEL      : std_logic_vector(3 downto 0) := x"B";
  constant CCAM_EVT_2_1_TYPE_VALUE_OPT_FLOW        : std_logic_vector(3 downto 0) := x"C";
  constant CCAM_EVT_2_1_TYPE_VALUE_ORIENTATION     : std_logic_vector(3 downto 0) := x"D";
  constant CCAM_EVT_2_1_TYPE_VALUE_OTHERS          : std_logic_vector(3 downto 0) := x"E";
  constant CCAM_EVT_2_1_TYPE_VALUE_CONTINUED       : std_logic_vector(3 downto 0) := x"F";

  -- Subtype 28bits
  constant CCAM_EVT_2_1_SUBTYPE_BITS  : integer := 28;
  constant CCAM_EVT_2_1_SUBTYPE_LSB   : integer := 32;
  constant CCAM_EVT_2_1_SUBTYPE_MSB   : integer := CCAM_EVT_2_1_SUBTYPE_LSB + CCAM_EVT_2_1_SUBTYPE_BITS - 1;
  subtype CCAM_EVT_2_1_SUBTYPE_RANGE is integer range CCAM_EVT_2_1_SUBTYPE_MSB downto CCAM_EVT_2_1_SUBTYPE_LSB;

  -- Rought Data 32bits
  constant CCAM_EVT_2_1_DATA_BITS  : integer := 32;
  constant CCAM_EVT_2_1_DATA_LSB   : integer := 0;
  constant CCAM_EVT_2_1_DATA_MSB   : integer := CCAM_EVT_2_1_DATA_LSB + CCAM_EVT_2_1_DATA_BITS - 1;
  subtype CCAM_EVT_2_1_DATA_RANGE is integer range CCAM_EVT_2_1_DATA_MSB downto CCAM_EVT_2_1_DATA_LSB;

  -- TD/EM - Specifics
  --------------------
  -- time low
  constant CCAM_EVT_2_1_TDEM_TIME_LOW_BITS : integer := 6;
  constant CCAM_EVT_2_1_TDEM_TIME_LOW_LSB  : integer := 54;
  constant CCAM_EVT_2_1_TDEM_TIME_LOW_MSB  : integer := CCAM_EVT_2_1_TDEM_TIME_LOW_LSB + CCAM_EVT_2_1_TDEM_TIME_LOW_BITS - 1;
  subtype CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE is integer range CCAM_EVT_2_1_TDEM_TIME_LOW_MSB downto CCAM_EVT_2_1_TDEM_TIME_LOW_LSB;

  -- y
  constant CCAM_EVT_2_1_TDEM_Y_BITS : integer := 11;
  constant CCAM_EVT_2_1_TDEM_Y_LSB  : integer := 32;
  constant CCAM_EVT_2_1_TDEM_Y_MSB  : integer := CCAM_EVT_2_1_TDEM_Y_LSB + CCAM_EVT_2_1_TDEM_Y_BITS - 1;
  subtype CCAM_EVT_2_1_TDEM_Y_RANGE is integer range CCAM_EVT_2_1_TDEM_Y_MSB downto CCAM_EVT_2_1_TDEM_Y_LSB;

  -- x
  constant CCAM_EVT_2_1_TDEM_X_BITS : integer := 11;
  constant CCAM_EVT_2_1_TDEM_X_LSB  : integer := 43;
  constant CCAM_EVT_2_1_TDEM_X_MSB  : integer := CCAM_EVT_2_1_TDEM_X_LSB + CCAM_EVT_2_1_TDEM_X_BITS - 1;
  subtype CCAM_EVT_2_1_TDEM_X_RANGE is integer range CCAM_EVT_2_1_TDEM_X_MSB downto CCAM_EVT_2_1_TDEM_X_LSB;

  -- vx
  constant CCAM_EVT_2_1_TDEM_VX_BITS : integer := 32;
  constant CCAM_EVT_2_1_TDEM_VX_LSB  : integer := 0;
  constant CCAM_EVT_2_1_TDEM_VX_MSB  : integer := CCAM_EVT_2_1_TDEM_VX_LSB + CCAM_EVT_2_1_TDEM_VX_BITS - 1;
  subtype CCAM_EVT_2_1_TDEM_VX_RANGE is integer range CCAM_EVT_2_1_TDEM_VX_MSB downto CCAM_EVT_2_1_TDEM_VX_LSB;

  -- OTHERS - Specifics
  --------------------
  -- time low
  constant CCAM_EVT_2_1_OTHERS_TIME_LOW_BITS : integer := 6;
  constant CCAM_EVT_2_1_OTHERS_TIME_LOW_LSB  : integer := 54;
  constant CCAM_EVT_2_1_OTHERS_TIME_LOW_MSB  : integer := CCAM_EVT_2_1_OTHERS_TIME_LOW_LSB + CCAM_EVT_2_1_OTHERS_TIME_LOW_BITS - 1;
  subtype  CCAM_EVT_2_1_OTHERS_TIME_LOW_RANGE is integer range CCAM_EVT_2_1_OTHERS_TIME_LOW_MSB downto CCAM_EVT_2_1_OTHERS_TIME_LOW_LSB;

  -- generated here bit
  constant CCAM_EVT_2_1_OTHERS_GEN_HERE_BITS : integer := 1;
  constant CCAM_EVT_2_1_OTHERS_GEN_HERE_LSB  : integer := 53;
  constant CCAM_EVT_2_1_OTHERS_GEN_HERE_MSB  : integer := CCAM_EVT_2_1_OTHERS_GEN_HERE_LSB + CCAM_EVT_2_1_OTHERS_GEN_HERE_BITS - 1;
  subtype CCAM_EVT_2_1_OTHERS_GEN_HERE_RANGE is integer range CCAM_EVT_2_1_OTHERS_GEN_HERE_MSB downto CCAM_EVT_2_1_OTHERS_GEN_HERE_LSB;

  -- unused
  constant CCAM_EVT_2_1_OTHERS_UNUSED_BITS : integer := 5;
  constant CCAM_EVT_2_1_OTHERS_UNUSED_LSB  : integer := 49;
  constant CCAM_EVT_2_1_OTHERS_UNUSED_MSB  : integer := CCAM_EVT_2_1_OTHERS_UNUSED_LSB + CCAM_EVT_2_1_OTHERS_UNUSED_BITS - 1;
  subtype CCAM_EVT_2_1_OTHERS_UNUSED_RANGE is integer range CCAM_EVT_2_1_OTHERS_UNUSED_MSB downto CCAM_EVT_2_1_OTHERS_UNUSED_LSB;

  -- Class (0: Monitor, 1: TBD)
  constant CCAM_EVT_2_1_OTHERS_CLASS_BITS : integer := 1;
  constant CCAM_EVT_2_1_OTHERS_CLASS_LSB : integer := 48;
  constant CCAM_EVT_2_1_OTHERS_CLASS_MSB : integer := CCAM_EVT_2_1_OTHERS_CLASS_LSB + CCAM_EVT_2_1_OTHERS_CLASS_BITS - 1;
  subtype CCAM_EVT_2_1_OTHERS_CLASS_RANGE is integer range CCAM_EVT_2_1_OTHERS_CLASS_MSB downto CCAM_EVT_2_1_OTHERS_CLASS_LSB;

  -- Monitor Event Values
  constant CCAM_EVT_2_1_OTHERS_MONITOR_VALUE_IN_TD_EVENT_COUNT            : std_logic_vector(15 downto 0) := x"0014";
  constant CCAM_EVT_2_1_OTHERS_MONITOR_VALUE_IN_APS_EVENT_COUNT           : std_logic_vector(15 downto 0) := x"0015";
  constant CCAM_EVT_2_1_OTHERS_MONITOR_VALUE_RATE_CONTROL_TD_EVENT_COUNT  : std_logic_vector(15 downto 0) := x"0016";
  constant CCAM_EVT_2_1_OTHERS_MONITOR_VALUE_RATE_CONTROL_APS_EVENT_COUNT : std_logic_vector(15 downto 0) := x"0017";

  -- Subtype
  constant CCAM_EVT_2_1_OTHERS_SUBTYPE_BITS : integer := 16;
  constant CCAM_EVT_2_1_OTHERS_SUBTYPE_LSB : integer := 32;
  constant CCAM_EVT_2_1_OTHERS_SUBTYPE_MSB : integer := CCAM_EVT_2_1_OTHERS_SUBTYPE_LSB + CCAM_EVT_2_1_OTHERS_SUBTYPE_BITS - 1;
  subtype CCAM_EVT_2_1_OTHERS_SUBTYPE_RANGE is integer range CCAM_EVT_2_1_OTHERS_SUBTYPE_MSB downto CCAM_EVT_2_1_OTHERS_SUBTYPE_LSB;

  -- Continued
  constant CCAM_EVT_2_1_OTHERS_CONTINUED_BITS : integer := 4;
  constant CCAM_EVT_2_1_OTHERS_CONTINUED_LSB : integer := 28;
  constant CCAM_EVT_2_1_OTHERS_CONTINUED_MSB : integer := CCAM_EVT_2_1_OTHERS_CONTINUED_LSB + CCAM_EVT_2_1_OTHERS_CONTINUED_BITS - 1;
  subtype CCAM_EVT_2_1_OTHERS_CONTINUED_RANGE is integer range CCAM_EVT_2_1_OTHERS_CONTINUED_MSB downto CCAM_EVT_2_1_OTHERS_CONTINUED_LSB;

  -- OTHERS - Specifics
  -- Data 28bits
  constant CCAM_EVT_2_1_CONTINUED_DATA_BITS  : integer := 28;
  constant CCAM_EVT_2_1_CONTINUED_DATA_LSB   : integer := 32;
  constant CCAM_EVT_2_1_CONTINUED_DATA_MSB   : integer := CCAM_EVT_2_1_CONTINUED_DATA_LSB + CCAM_EVT_2_1_CONTINUED_DATA_BITS - 1;
  subtype CCAM_EVT_2_1_CONTINUED_DATA_RANGE is integer range CCAM_EVT_2_1_CONTINUED_DATA_MSB downto CCAM_EVT_2_1_CONTINUED_DATA_LSB;
  -- Continued
  constant CCAM_EVT_2_1_CONTINUED_CONTINUED_BITS : integer := 4;
  constant CCAM_EVT_2_1_CONTINUED_CONTINUED_LSB : integer := 28;
  constant CCAM_EVT_2_1_CONTINUED_CONTINUED_MSB : integer := CCAM_EVT_2_1_CONTINUED_CONTINUED_LSB + CCAM_EVT_2_1_CONTINUED_CONTINUED_BITS - 1;
  subtype CCAM_EVT_2_1_CONTINUED_CONTINUED_RANGE is integer range CCAM_EVT_2_1_CONTINUED_CONTINUED_MSB downto CCAM_EVT_2_1_CONTINUED_CONTINUED_LSB;

  -- EXT TIGGER
  --------------------
  -- time low
  constant CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_BITS : integer := 6;
  constant CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_LSB  : integer := 54;
  constant CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_MSB  : integer := CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_LSB + CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_BITS - 1;
  subtype  CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_RANGE is integer range CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_MSB downto CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_LSB;

  -- unused1
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_BITS  : integer := 9;
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_LSB   : integer := 45;
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_MSB   : integer := CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_LSB + CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_BITS - 1;
  subtype  CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_RANGE is integer range CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_MSB downto CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_LSB;

  -- ID
  constant CCAM_EVT_2_1_EXT_TRIGGER_ID_BITS  : integer := 5;
  constant CCAM_EVT_2_1_EXT_TRIGGER_ID_LSB   : integer := 40;
  constant CCAM_EVT_2_1_EXT_TRIGGER_ID_MSB   : integer := CCAM_EVT_2_1_EXT_TRIGGER_ID_LSB + CCAM_EVT_2_1_EXT_TRIGGER_ID_BITS - 1;
  subtype  CCAM_EVT_2_1_EXT_TRIGGER_ID_RANGE is integer range CCAM_EVT_2_1_EXT_TRIGGER_ID_MSB downto CCAM_EVT_2_1_EXT_TRIGGER_ID_LSB;

  -- unused0
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_BITS  : integer := 7;
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_LSB   : integer := 33;
  constant CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_MSB   : integer := CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_LSB + CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_BITS - 1;
  subtype  CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_RANGE is integer range CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_MSB downto CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_LSB;

  -- polarity
  constant CCAM_EVT_2_1_EXT_TRIGGER_POL_BITS  : integer := 1;
  constant CCAM_EVT_2_1_EXT_TRIGGER_POL_LSB   : integer := 32;
  constant CCAM_EVT_2_1_EXT_TRIGGER_POL_MSB   : integer := CCAM_EVT_2_1_EXT_TRIGGER_POL_LSB + CCAM_EVT_2_1_EXT_TRIGGER_POL_BITS - 1;
  subtype  CCAM_EVT_2_1_EXT_TRIGGER_POL_RANGE is integer range CCAM_EVT_2_1_EXT_TRIGGER_POL_MSB downto CCAM_EVT_2_1_EXT_TRIGGER_POL_LSB;

  -- TIME HIGH - Specifics
  ------------------------
  constant CCAM_EVT_2_1_TIME_HIGH_BITS     : integer := 28;
  constant CCAM_EVT_2_1_TIME_HIGH_LSB      : integer := 32;
  constant CCAM_EVT_2_1_TIME_HIGH_MSB      : integer := CCAM_EVT_2_1_TIME_HIGH_LSB + CCAM_EVT_2_1_TIME_HIGH_BITS - 1;
  subtype CCAM_EVT_2_1_TIME_HIGH_RANGE is integer range CCAM_EVT_2_1_TIME_HIGH_MSB downto CCAM_EVT_2_1_TIME_HIGH_LSB;

  -- useful function
  function is_td_event(evt_type         : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean;
  function is_em_event(evt_type         : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean;
  function is_monitoring_event(evt_type : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean;

--synthesis translate_off
  function evt_2_1_to_ascii(event: std_logic_vector) return string;
--synthesis translate_on

  -- Subtypes
  constant CCAM_EVT_2_1_TIME_LOW_BITS             : integer := 6;
  constant CCAM_EVT_2_1_TIME_BITS                 : integer := CCAM_EVT_2_1_TIME_HIGH_BITS + CCAM_EVT_2_1_TIME_LOW_BITS;

  constant CCAM_EVT_2_1_TIME_LOW_MSB              : integer := CCAM_EVT_2_1_TYPE_LSB - 1;
  constant CCAM_EVT_2_1_TIME_LOW_LSB              : integer := CCAM_EVT_2_1_TIME_LOW_MSB - CCAM_EVT_2_1_TIME_LOW_BITS + 1;
  constant CCAM_EVT_2_1_RESERVED_BITS             : integer := 32;
  constant CCAM_EVT_2_1_RESERVED_LSB              : integer := 0;
  constant CCAM_EVT_2_1_RESERVED_MSB              : integer := CCAM_EVT_2_1_RESERVED_LSB + CCAM_EVT_2_1_RESERVED_BITS - 1;
 
  constant CCAM_EVT_2_1_RESERVED_HEADER_BITS      : integer := 22;
  
  constant CCAM_EVT_2_1_TIME_LOW_DATA_LSB         : integer := 0;
  constant CCAM_EVT_2_1_TIME_LOW_DATA_MSB         : integer := CCAM_EVT_2_1_TIME_LOW_DATA_LSB + CCAM_EVT_2_1_TIME_LOW_BITS - 1;
  constant CCAM_EVT_2_1_TIME_HIGH_DATA_LSB        : integer := CCAM_EVT_2_1_TIME_LOW_DATA_MSB + 1;
  constant CCAM_EVT_2_1_TIME_HIGH_DATA_MSB        : integer := CCAM_EVT_2_1_TIME_HIGH_DATA_LSB + CCAM_EVT_2_1_TIME_HIGH_BITS - 1;
 
  constant CCAM_EVT_2_1_TIME_HIGH_SHIFTED_LSB     : integer := CCAM_EVT_2_1_TIME_HIGH_LSB - CCAM_EVT_2_1_RESERVED_BITS;
  constant CCAM_EVT_2_1_TIME_HIGH_SHIFTED_MSB     : integer := CCAM_EVT_2_1_TIME_HIGH_MSB - CCAM_EVT_2_1_RESERVED_BITS;
  
  constant CCAM_EVT_2_1_TIME_LOW_SHIFTED_LSB      : integer := 0;
  constant CCAM_EVT_2_1_TIME_LOW_SHIFTED_MSB      : integer := CCAM_EVT_2_1_TIME_LOW_BITS - 1;

  subtype ccam_evt_v2_1_time_t                     is unsigned(CCAM_EVT_2_1_TIME_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_data_t                is std_logic_vector(CCAM_EVT_2_1_TIME_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_high_t                is unsigned(CCAM_EVT_2_1_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_high_data_t           is std_logic_vector(CCAM_EVT_2_1_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_high_unused_t         is unsigned(CCAM_EVT_2_1_DATA_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_high_unused_data_t    is std_logic_vector(CCAM_EVT_2_1_DATA_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_low_t                 is unsigned(CCAM_EVT_2_1_TIME_LOW_BITS-1 downto 0);
  subtype ccam_evt_v2_1_time_low_data_t            is std_logic_vector(CCAM_EVT_2_1_TIME_LOW_BITS-1 downto 0);

  subtype ccam_evt_v2_1_x_t                        is unsigned(CCAM_EVT_2_1_TDEM_X_BITS-1 downto 0);
  subtype ccam_evt_v2_1_x_data_t                   is std_logic_vector(CCAM_EVT_2_1_TDEM_X_BITS-1 downto 0);
  subtype ccam_evt_v2_1_y_t                        is unsigned(CCAM_EVT_2_1_TDEM_Y_BITS-1 downto 0);
  subtype ccam_evt_v2_1_y_data_t                   is std_logic_vector(CCAM_EVT_2_1_TDEM_Y_BITS-1 downto 0);
  subtype ccam_evt_v2_1_vx_t                       is unsigned(CCAM_EVT_2_1_TDEM_VX_BITS-1 downto 0);
  subtype ccam_evt_v2_1_vx_data_t                  is std_logic_vector(CCAM_EVT_2_1_TDEM_VX_BITS-1 downto 0);

  subtype ccam_evt_v2_1_trigger_unused1_t          is std_logic_vector(CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_BITS-1 downto 0);
  subtype ccam_evt_v2_1_trigger_id_t               is unsigned(CCAM_EVT_2_1_EXT_TRIGGER_ID_BITS-1 downto 0);
  subtype ccam_evt_v2_1_trigger_unused0_t          is std_logic_vector(CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_BITS-1 downto 0);
  subtype ccam_evt_v2_1_trigger_value_t            is std_logic;

  subtype ccam_evt_v2_1_other_class_t              is std_logic;

  subtype ccam_evt_v2_1_other_subtype_t            is unsigned(CCAM_EVT_2_1_OTHERS_SUBTYPE_BITS-1 downto 0);
  subtype ccam_evt_v2_1_other_subtype_data_t       is std_logic_vector(CCAM_EVT_2_1_OTHERS_SUBTYPE_BITS-1 downto 0);
  
  type    ccam_evt_v2_1_other_subtype_vector_t     is array(natural range <>) of ccam_evt_v2_1_other_subtype_t;
  
  -- Monitoring Events Subtypes as Listed in:
  -- http://confluence.chronocam.com/display/SYSDEV/System+Monitoring+Events+2.0
  constant MASTER_SYSTEM_TEMPERATURE           : ccam_evt_v2_1_other_subtype_t := x"0000"; -- Monitors current FPGA system temperature value periodically. Implemented as of version 1.1.1
  constant MASTER_SYSTEM_VOLTAGE               : ccam_evt_v2_1_other_subtype_t := x"0001"; -- Monitors current FPGA power supply voltage levels periodically.   Implemented as of version 1.1.1
  constant MASTER_SYSTEM_IN_EVENT_COUNT        : ccam_evt_v2_1_other_subtype_t := x"0002"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant MASTER_SYSTEM_IN_EVENT_SEQ_ERROR    : ccam_evt_v2_1_other_subtype_t := x"0003"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant MASTER_SYSTEM_IN_EVENT_TIME_ERROR   : ccam_evt_v2_1_other_subtype_t := x"0004"; -- Alerts of an event timestamp disruption, if enabled.
  constant MASTER_SYSTEM_OUT_EVENT_COUNT       : ccam_evt_v2_1_other_subtype_t := x"0005"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant MASTER_SYSTEM_OUT_EVENT_SEQ_ERROR   : ccam_evt_v2_1_other_subtype_t := x"0006"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant MASTER_SYSTEM_OUT_EVENT_TIME_ERROR  : ccam_evt_v2_1_other_subtype_t := x"0007"; -- Alerts of an event timestamp disruption, if enabled.
  constant MASTER_ATIS_BIAS_PROG_ERROR         : ccam_evt_v2_1_other_subtype_t := x"0008"; -- Alerts of a bias programming error.
  constant MASTER_ATIS_ILLUMINATION            : ccam_evt_v2_1_other_subtype_t := x"0009"; -- Monitors the global illumination periodically.    Implemented as of version 1.1.1
  constant MASTER_ATIS_TD_IDLE_TIME            : ccam_evt_v2_1_other_subtype_t := x"000A"; -- Monitors the time interval between two TD events, if over a given threshold.    Implemented as of version 1.1.1
  constant MASTER_ATIS_APS_IDLE_TIME           : ccam_evt_v2_1_other_subtype_t := x"000B"; -- Monitors the time interval between two APS events, if over a given threshold.   Implemented as of version 1.1.1
  constant MASTER_ATIS_TD_IDLE_TIMEOUT         : ccam_evt_v2_1_other_subtype_t := x"000C"; -- Alerts if no TD event has been received for a set amount of time.   Implemented as of version 1.1.1
  constant MASTER_ATIS_APS_IDLE_TIMEOUT        : ccam_evt_v2_1_other_subtype_t := x"000D"; -- Alerts if no APS event has been received for a set amount of time.    Implemented as of version 1.1.1
  constant MASTER_ATIS_REFRACTORY_CLOCK        : ccam_evt_v2_1_other_subtype_t := x"000E"; -- Monitors the refractory clock period.
  constant EPOCH_START                         : ccam_evt_v2_1_other_subtype_t := x"0010";
  constant EPOCH_END                           : ccam_evt_v2_1_other_subtype_t := x"0011";
  constant EPOCH_LINE_START                    : ccam_evt_v2_1_other_subtype_t := x"0012";
  constant EPOCH_LINE_END                      : ccam_evt_v2_1_other_subtype_t := x"0013";
  constant MASTER_IN_TD_EVENT_COUNT            : ccam_evt_v2_1_other_subtype_t := x"0014"; -- Monitors the number of incoming TD events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.
  constant MASTER_IN_APS_EVENT_COUNT           : ccam_evt_v2_1_other_subtype_t := x"0015"; -- Monitors the number of incoming APS events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.
  constant MASTER_RATE_CONTROL_TD_EVENT_COUNT  : ccam_evt_v2_1_other_subtype_t := x"0016"; -- Monitors the number of TD events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.
  constant MASTER_RATE_CONTROL_APS_EVENT_COUNT : ccam_evt_v2_1_other_subtype_t := x"0017"; -- Monitors the number of APS events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.
  constant MASTER_START_OF_FRAME               : ccam_evt_v2_1_other_subtype_t := x"0018"; -- Marks the start of a Frame in MIPI transmissions.
  constant MASTER_END_OF_FRAME                 : ccam_evt_v2_1_other_subtype_t := x"0019"; -- Marks the end of a Frame in MIPI transmissions.
  constant MASTER_MIPI_PADDING                 : ccam_evt_v2_1_other_subtype_t := x"001A"; -- Master MIPI TX Padding Data
  constant MASTER_GPAFK_PERIOD                 : ccam_evt_v2_1_other_subtype_t := x"0044"; -- Master GPAFK Period Stats
  constant MASTER_GPAFK_TIMESPAN               : ccam_evt_v2_1_other_subtype_t := x"0045"; -- Master GPAFK Timespan Stats
  constant MASTER_GPAFK_IN_TD_EVT_COUNT        : ccam_evt_v2_1_other_subtype_t := x"0046"; -- Master GPAFK Input TD Event Count Stats
  constant MASTER_GPAFK_OUT_TD_EVT_COUNT       : ccam_evt_v2_1_other_subtype_t := x"0047"; -- Master GPAFK Output TD Event Count Stats
  constant MASTER_SYSTEM_TB_END_OF_TASK        : ccam_evt_v2_1_other_subtype_t := x"00FD"; -- Marks the end of a Test Task
  constant MASTER_USB_PACKET_INFO              : ccam_evt_v2_1_other_subtype_t := x"00FE"; -- Software Generated Event with USB Packet Info (Arrival Time, Size, etc.)    Software implemented.
  constant MASTER_DUMMY_EVENT                  : ccam_evt_v2_1_other_subtype_t := x"00FF"; -- General Purpose Dummy Event.    To be implemented in Moorea
  constant MASTER_DATA_INTEGRITY_MARKER        : ccam_evt_v2_1_other_subtype_t := x"0314"; -- Data integrity marker
  constant MASTER_TH_DROP_EVENT                : ccam_evt_v2_1_other_subtype_t := x"0ED8"; -- Alerts of events dropped due to a previous corrupted TIME HIGH event
  constant MASTER_EVT_DROP_EVENT               : ccam_evt_v2_1_other_subtype_t := x"0EDA"; -- Alerts of events dropped
  constant SLAVE_SYSTEM_TEMPERATURE            : ccam_evt_v2_1_other_subtype_t := x"4000"; -- Monitors current FPGA system temperature value periodically.   Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_SYSTEM_VOLTAGE                : ccam_evt_v2_1_other_subtype_t := x"4001"; -- Monitors current FPGA power supply voltage levels periodically.  Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_SYSTEM_IN_EVENT_COUNT         : ccam_evt_v2_1_other_subtype_t := x"4002"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant SLAVE_SYSTEM_IN_EVENT_SEQ_ERROR     : ccam_evt_v2_1_other_subtype_t := x"4003"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant SLAVE_SYSTEM_IN_EVENT_TIME_ERROR    : ccam_evt_v2_1_other_subtype_t := x"4004"; -- Alerts of an event timestamp disruption, if enabled.
  constant SLAVE_SYSTEM_OUT_EVENT_COUNT        : ccam_evt_v2_1_other_subtype_t := x"4005"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant SLAVE_SYSTEM_OUT_EVENT_SEQ_ERROR    : ccam_evt_v2_1_other_subtype_t := x"4006"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant SLAVE_SYSTEM_OUT_EVENT_TIME_ERROR   : ccam_evt_v2_1_other_subtype_t := x"4007"; -- Alerts of an event timestamp disruption, if enabled.
  constant SLAVE_ATIS_BIAS_PROG_ERROR          : ccam_evt_v2_1_other_subtype_t := x"4008"; -- Alerts of a bias programming error.
  constant SLAVE_ATIS_ILLUMINATION             : ccam_evt_v2_1_other_subtype_t := x"4009"; -- Monitors the global illumination periodically. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_TD_IDLE_TIME             : ccam_evt_v2_1_other_subtype_t := x"400A"; -- Monitors the time interval between two TD events, if over a given threshold. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_APS_IDLE_TIME            : ccam_evt_v2_1_other_subtype_t := x"400B"; -- Monitors the time interval between two APS events, if over a given threshold.
  constant SLAVE_ATIS_TD_IDLE_TIMEOUT          : ccam_evt_v2_1_other_subtype_t := x"400C"; -- Alerts if no TD event has been received for a set amount of time. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_APS_IDLE_TIMEOUT         : ccam_evt_v2_1_other_subtype_t := x"400D"; -- Alerts if no APS event has been received for a set amount of time. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant STEREO_SYSTEM_TEMPERATURE           : ccam_evt_v2_1_other_subtype_t := x"8000"; -- Monitors current FPGA system temperature value periodically. Implemented as of version 1.1.1
  constant STEREO_SYSTEM_VOLTAGE               : ccam_evt_v2_1_other_subtype_t := x"8001"; -- Monitors current FPGA power supply voltage levels periodically.

  subtype ccam_continued_evt_v2_1_data_t           is std_logic_vector(CCAM_EVT_2_1_CONTINUED_DATA_BITS-1 downto 0);

  -- Types and Subtypes definitions for EVT 2.1
  subtype ccam_evt_v2_1_data_t                     is std_logic_vector(CCAM_EVT_2_1_BITS-1 downto 0);
  type    ccam_evt_v2_1_data_vector_t              is array(natural range <>) of ccam_evt_v2_1_data_t;

  subtype ccam_evt_v2_1_type_t                     is unsigned(CCAM_EVT_2_1_TYPE_BITS-1 downto 0);
  subtype ccam_evt_v2_1_type_data_t                is std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0);
  type    ccam_evt_v2_1_type_vector_t              is array(natural range <>) of ccam_evt_v2_1_type_t;

  constant EVT_2_1_LEFT_TD_LOW                     : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_LOW);
  constant EVT_2_1_LEFT_TD_HIGH                    : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_HIGH);
  constant EVT_2_1_LEFT_APS_END                    : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_END);
  constant EVT_2_1_LEFT_APS_START                  : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_START);
  constant EVT_2_1_RIGHT_TD_LOW                    : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_LOW);
  constant EVT_2_1_RIGHT_TD_HIGH                   : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_HIGH);
  constant EVT_2_1_RIGHT_APS_END                   : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_END);
  constant EVT_2_1_RIGHT_APS_START                 : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_START);
  constant EVT_2_1_TIME_HIGH                       : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_EVT_TIME_HIGH);
  constant EVT_2_1_STEREO_DISP                     : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_STEREO_DISP);
  constant EVT_2_1_EXT_TRIGGER                     : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_EXT_TRIGGER);
  constant EVT_2_1_GRAY_LEVEL                      : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_GRAY_LEVEL);
  constant EVT_2_1_OPT_FLOW                        : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_OPT_FLOW);
  constant EVT_2_1_ORIENTATION                     : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_ORIENTATION);
  constant EVT_2_1_OTHERS                          : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_OTHERS);
  constant EVT_2_1_CONTINUED                       : ccam_evt_v2_1_type_t := unsigned(CCAM_EVT_2_1_TYPE_VALUE_CONTINUED);

  type ccam_evt_v2_1_t is record
    type_f     : ccam_evt_v2_1_type_t;
    time_f     : ccam_evt_v2_1_time_low_t;
    reserved_head_f : unsigned(CCAM_EVT_2_1_RESERVED_HEADER_BITS -1 downto 0);
    reserved_data_f : unsigned(CCAM_EVT_2_1_RESERVED_MSB downto CCAM_EVT_2_1_RESERVED_LSB);
  end record ccam_evt_v2_1_t;

  type ccam_td_evt_v2_1_t is record
    type_f : ccam_evt_v2_1_type_t;
    time_f : ccam_evt_v2_1_time_low_t;
    x_f    : ccam_evt_v2_1_x_t;
    y_f    : ccam_evt_v2_1_y_t;
    vx_f   : ccam_evt_v2_1_vx_t;
  end record ccam_td_evt_v2_1_t;

  type ccam_th_evt_v2_1_t is record
    type_f      : ccam_evt_v2_1_type_t;
    time_high_f : ccam_evt_v2_1_time_high_t;
    unused_f    : ccam_evt_v2_1_time_high_unused_t;
  end record ccam_th_evt_v2_1_t;

  type ccam_ext_trigger_evt_v2_1_t is record
    type_f     : ccam_evt_v2_1_type_t;
    time_f     : ccam_evt_v2_1_time_low_t;
    unused1_f  : ccam_evt_v2_1_trigger_unused1_t;
    id_f       : ccam_evt_v2_1_trigger_id_t;
    unused0_f  : ccam_evt_v2_1_trigger_unused0_t;
    value_f    : ccam_evt_v2_1_trigger_value_t;
    cont_type_f : ccam_evt_v2_1_type_t;
    cont_data_f : ccam_continued_evt_v2_1_data_t;
  end record ccam_ext_trigger_evt_v2_1_t;

  type ccam_other_evt_v2_1_t is record
    type_f      : ccam_evt_v2_1_type_t;
    time_f      : ccam_evt_v2_1_time_low_t;
    unused_f    : unsigned(CCAM_EVT_2_1_OTHERS_UNUSED_MSB downto CCAM_EVT_2_1_OTHERS_UNUSED_LSB);
    class_f     : ccam_evt_v2_1_other_class_t;
    subtype_f   : ccam_evt_v2_1_other_subtype_t;
    cont_type_f : ccam_evt_v2_1_type_t;
    cont_data_f : ccam_continued_evt_v2_1_data_t;
  end record ccam_other_evt_v2_1_t;

  -- Conversion functions
  function to_ccam_evt_v2_1(evt_data_v: ccam_evt_v2_1_data_t) return ccam_evt_v2_1_t;
  function to_ccam_evt_v2_1_data(evt_v: ccam_evt_v2_1_t) return ccam_evt_v2_1_data_t;

  function to_ccam_td_evt_v2_1(evt_data_v: ccam_evt_v2_1_data_t) return ccam_td_evt_v2_1_t;
  function to_ccam_evt_v2_1_data(td_evt_v: ccam_td_evt_v2_1_t) return ccam_evt_v2_1_data_t;

  function to_ccam_th_evt_v2_1(evt_data_v: ccam_evt_v2_1_data_t) return ccam_th_evt_v2_1_t;
  function to_ccam_evt_v2_1_data(th_evt_v: ccam_th_evt_v2_1_t) return ccam_evt_v2_1_data_t;

  function to_ccam_ext_trigger_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_ext_trigger_evt_v2_1_t;
  function to_ccam_evt_v2_1_data(ext_trigger_evt_v : ccam_ext_trigger_evt_v2_1_t) return ccam_evt_v2_1_data_t;

  function to_ccam_other_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_other_evt_v2_1_t;
  function to_ccam_evt_v2_1_data(other_evt_v : ccam_other_evt_v2_1_t) return ccam_evt_v2_1_data_t;

end ccam_evt_type_v2_1_pkg;

package body ccam_evt_type_v2_1_pkg is

  -- Convert ccam_evt_v2_1_t type to ccam_evt_v2_1_data_t type
  function to_ccam_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_evt_v2_1_t is
    variable evt_v : ccam_evt_v2_1_t;
    variable i_v   : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, evt_v.reserved_data_f);
    unpack(evt_data_v, i_v, evt_v.reserved_head_f);
    unpack(evt_data_v, i_v, evt_v.time_f);
    unpack(evt_data_v, i_v, evt_v.type_f);
    return evt_v;
  end function to_ccam_evt_v2_1;

  -- Convert ccam_evt_v2_1_t type to ccam_evt_v2_1_data_t type
  function to_ccam_evt_v2_1_data(evt_v : ccam_evt_v2_1_t) return ccam_evt_v2_1_data_t is
    variable evt_data_v : ccam_evt_v2_1_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, evt_v.reserved_data_f);
    pack(evt_data_v, i_v, evt_v.reserved_head_f);
    pack(evt_data_v, i_v, evt_v.time_f);
    pack(evt_data_v, i_v, evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v2_1_data;

  -----------
  -- TD Event

  function to_ccam_td_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_td_evt_v2_1_t is
    variable td_evt_v : ccam_td_evt_v2_1_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, td_evt_v.vx_f);
    unpack(evt_data_v, i_v, td_evt_v.y_f);
    unpack(evt_data_v, i_v, td_evt_v.x_f);
    unpack(evt_data_v, i_v, td_evt_v.time_f);
    unpack(evt_data_v, i_v, td_evt_v.type_f);
    return td_evt_v;
  end function to_ccam_td_evt_v2_1;

  function to_ccam_evt_v2_1_data(td_evt_v : ccam_td_evt_v2_1_t) return ccam_evt_v2_1_data_t is
    variable evt_data_v : ccam_evt_v2_1_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, td_evt_v.vx_f);
    pack(evt_data_v, i_v, td_evt_v.y_f);
    pack(evt_data_v, i_v, td_evt_v.x_f);
    pack(evt_data_v, i_v, td_evt_v.time_f);
    pack(evt_data_v, i_v, td_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v2_1_data;

  -----------------------
  -- Time High (TH) Event

  function to_ccam_th_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_th_evt_v2_1_t is
    variable th_evt_v : ccam_th_evt_v2_1_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, th_evt_v.unused_f);
    unpack(evt_data_v, i_v, th_evt_v.time_high_f);
    unpack(evt_data_v, i_v, th_evt_v.type_f);
    return th_evt_v;
  end function to_ccam_th_evt_v2_1;

  function to_ccam_evt_v2_1_data(th_evt_v : ccam_th_evt_v2_1_t) return ccam_evt_v2_1_data_t is
    variable evt_data_v : ccam_evt_v2_1_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, th_evt_v.unused_f);
    pack(evt_data_v, i_v, th_evt_v.time_high_f);
    pack(evt_data_v, i_v, th_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v2_1_data;


  --------------------
  -- EXT Trigger Event

  function to_ccam_ext_trigger_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_ext_trigger_evt_v2_1_t is
    variable ext_trigger_evt_v  : ccam_ext_trigger_evt_v2_1_t;
    variable i_v                : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, ext_trigger_evt_v.cont_data_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.cont_type_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.value_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.unused0_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.id_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.unused1_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.time_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.type_f);
    return ext_trigger_evt_v;
  end function to_ccam_ext_trigger_evt_v2_1;

  function to_ccam_evt_v2_1_data(ext_trigger_evt_v : ccam_ext_trigger_evt_v2_1_t) return ccam_evt_v2_1_data_t is
    variable evt_data_v : ccam_evt_v2_1_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, ext_trigger_evt_v.cont_data_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.cont_type_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.value_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.unused0_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.id_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.unused1_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.time_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v2_1_data;


  --------------
  -- Other Event

  function to_ccam_other_evt_v2_1(evt_data_v : ccam_evt_v2_1_data_t) return ccam_other_evt_v2_1_t is
    variable other_evt_v : ccam_other_evt_v2_1_t;
    variable i_v         : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, other_evt_v.cont_data_f);
    unpack(evt_data_v, i_v, other_evt_v.cont_type_f);
    unpack(evt_data_v, i_v, other_evt_v.subtype_f);
    unpack(evt_data_v, i_v, other_evt_v.class_f);
    unpack(evt_data_v, i_v, other_evt_v.unused_f);
    unpack(evt_data_v, i_v, other_evt_v.time_f);
    unpack(evt_data_v, i_v, other_evt_v.type_f);
    other_evt_v.unused_f := (others => '0');
    return other_evt_v;
  end function to_ccam_other_evt_v2_1;

  function to_ccam_evt_v2_1_data(other_evt_v : ccam_other_evt_v2_1_t) return ccam_evt_v2_1_data_t is
    variable other_evt_local_v : ccam_other_evt_v2_1_t;
    variable evt_data_v        : ccam_evt_v2_1_data_t;
    variable i_v               : integer;
  begin
    evt_data_v := (others => 'U');
    other_evt_local_v := other_evt_v;
    other_evt_local_v.unused_f := (others => '0');
    i_v := 0;
    pack(evt_data_v, i_v, other_evt_v.cont_data_f);
    pack(evt_data_v, i_v, other_evt_v.cont_type_f);
    pack(evt_data_v, i_v, other_evt_v.subtype_f);
    pack(evt_data_v, i_v, other_evt_v.class_f);
    pack(evt_data_v, i_v, other_evt_v.unused_f);
    pack(evt_data_v, i_v, other_evt_v.time_f);
    pack(evt_data_v, i_v, other_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v2_1_data;

  -------------------
  -- TD event test
  function is_td_event(evt_type : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean is
    variable return_v : boolean := false;
  begin
    if ((evt_type = CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_LOW  ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_HIGH ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_LOW ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_HIGH)) then
      return_v := true;
    else
      return_v := false;
    end if;
    return return_v;
  end function is_td_event;

  -- EM event test
  function is_em_event(evt_type : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean is
    variable return_v : boolean := false;
  begin
    if ((evt_type = CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_END   ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_START ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_END  ) or
        (evt_type = CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_START)) then
      return_v := true;
    else
      return_v := false;
    end if;
    return return_v;
  end function is_em_event;

  -- monitoring event test
  function is_monitoring_event(evt_type : std_logic_vector(CCAM_EVT_2_1_TYPE_BITS-1 downto 0)) return boolean is
    variable return_v : boolean := false;
  begin
    if (evt_type = CCAM_EVT_2_1_TYPE_VALUE_OTHERS) then
      return_v := true;
    else
      return_v := false;
    end if;
    return return_v;
  end function is_monitoring_event;

--synthesis translate_off
  function evt_2_1_to_ascii(event: std_logic_vector) return string is
    variable msg : line;
    variable output : string(1 to 300) := (others => ' ');
    begin

      write(msg,string'("EVT 2.1"));
      write(msg,string'(" | TYPE: "));
      case event(CCAM_EVT_2_1_TYPE_RANGE) is
        when CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_LOW     =>
          write(msg,string'("LEFT_TD_LOW"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_LEFT_TD_HIGH    =>
          write(msg,string'("LEFT_TD_HIGH"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_END    =>
          write(msg,string'("LEFT_APS_END"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_LEFT_APS_START  =>
          write(msg,string'("LEFT_APS_START"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_LOW    =>
          write(msg,string'("RIGHT_TD_LOW"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_RIGHT_TD_HIGH   =>
          write(msg,string'("RIGHT_TD_HIGH"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_END   =>
          write(msg,string'("RIGHT_EM_END"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_RIGHT_APS_START =>
          write(msg,string'("RIGHT_EM_START"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_TIME_LOW_RANGE))));
          write(msg,string'(" | Y: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_Y_RANGE))));
          write(msg,string'(" | X: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TDEM_X_RANGE))));
          write(msg,string'(" | VX: "));
          hwrite(msg,event(CCAM_EVT_2_1_TDEM_VX_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_EVT_TIME_HIGH   =>
          write(msg,string'("EVT_TIME_HIGH"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_TIME_HIGH_RANGE))));

        when CCAM_EVT_2_1_TYPE_VALUE_STEREO_DISP     =>
          write(msg,string'("STEREO_DISP"));

        when CCAM_EVT_2_1_TYPE_VALUE_EXT_TRIGGER     =>
          write(msg,string'("EXT_TRIGGER"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_EXT_TRIGGER_TIME_LOW_RANGE))));
          write(msg,string'(" | UNUSED1: "));
          write(msg,event(CCAM_EVT_2_1_EXT_TRIGGER_UNUSED1_RANGE));
          write(msg,string'(" | ID: "));
          write(msg,event(CCAM_EVT_2_1_EXT_TRIGGER_ID_RANGE));
          write(msg,string'(" | UNUSED0: "));
          write(msg,event(CCAM_EVT_2_1_EXT_TRIGGER_UNUSED0_RANGE));
          write(msg,string'(" | POLARITY: "));
          write(msg,event(CCAM_EVT_2_1_EXT_TRIGGER_POL_RANGE));

        when CCAM_EVT_2_1_TYPE_VALUE_GRAY_LEVEL      =>
          write(msg,string'("GRAY_LEVEL"));

        when CCAM_EVT_2_1_TYPE_VALUE_OPT_FLOW        =>
          write(msg,string'("OPT_FLOW"));

        when CCAM_EVT_2_1_TYPE_VALUE_ORIENTATION     =>
          write(msg,string'("ORIENTATION"));

        when CCAM_EVT_2_1_TYPE_VALUE_OTHERS          =>
          write(msg,string'("OTHERS"));
          write(msg,string'(" | TS: "));
          write(msg,to_integer(unsigned(event(CCAM_EVT_2_1_OTHERS_TIME_LOW_RANGE))));
          write(msg,string'(" | UNUSED: "));
          write(msg,event(CCAM_EVT_2_1_OTHERS_UNUSED_RANGE ));
          write(msg,string'(" | CLASS: "));
          write(msg,event(CCAM_EVT_2_1_OTHERS_CLASS_RANGE ));
          write(msg,string'(" | SUBTYPE: "));
          write(msg,event(CCAM_EVT_2_1_OTHERS_SUBTYPE_RANGE));
          if (event(CCAM_EVT_2_1_OTHERS_CONTINUED_RANGE) = CCAM_EVT_2_1_TYPE_VALUE_CONTINUED) then
            write(msg,string'(" | CONTINUED: YES"));
          else
            write(msg,string'(" | CONTINUED: NO"));
          end if;

        when CCAM_EVT_2_1_TYPE_VALUE_CONTINUED       =>
          write(msg,string'("CONTINUED"));

        when others =>
          null;
      end case;

      output(1 to msg'length) := msg.all;
      return output;
  end function evt_2_1_to_ascii;
--synthesis translate_on

end ccam_evt_type_v2_1_pkg;
