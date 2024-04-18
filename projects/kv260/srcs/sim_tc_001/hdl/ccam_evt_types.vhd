-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_utils.all;

package ccam_evt_types is

  constant EVT_FORMAT                             : integer := 0;

  constant IMAGE_MAX_WIDTH                        : integer := 2048;        -- event support max image width 2**11
  constant IMAGE_MAX_HEIGHT                       : integer := 2048;        -- event support max image height 2**11

  constant CCAM_EVT_DATA_BITS                     : integer := 64;
  constant CCAM_EVT_DISP_BITS                     : integer := iff(EVT_FORMAT = 1, 10, 12);
  constant CCAM_EVT_Y_BITS                        : integer := iff(EVT_FORMAT = 1,  8, 11);
  constant CCAM_EVT_X_BITS                        : integer := iff(EVT_FORMAT = 1,  9, 11);
  constant CCAM_EVT_ADDR_BITS                     : integer := CCAM_EVT_Y_BITS + CCAM_EVT_X_BITS;
  constant CCAM_EVT_TIME_LOW_BITS                 : integer := iff(EVT_FORMAT = 1, 11,  6);
  constant CCAM_EVT_TIME_HIGH_BITS                : integer := 28;
  constant CCAM_EVT_TIME_BITS                     : integer := CCAM_EVT_TIME_HIGH_BITS + CCAM_EVT_TIME_LOW_BITS;
  constant CCAM_EVT_TYPE_BITS                     : integer := 4;
  constant CCAM_EVT_SUBTYPE_BITS                  : integer := 16;
  constant CCAM_OTHER_CLASS_BITS                  : integer := 1;
  constant CCAM_OTHER_UNUSED_BITS                 : integer := 5;
  constant CCAM_CONTINUED_EVT_DATA_BITS           : integer := CCAM_EVT_DATA_BITS - CCAM_EVT_TYPE_BITS;
  constant CCAM_SYNC_EVT_DATA_BITS                : integer := CCAM_EVT_Y_BITS;

  constant CCAM_EVT_DATA_LSB                      : integer := 0;
  constant CCAM_EVT_DATA_MSB                      : integer := CCAM_EVT_DATA_LSB + CCAM_EVT_DATA_BITS - 1;
  constant CCAM_EVT_DATA_HIGH_LSB                 : integer := CCAM_EVT_DATA_MSB + 1;
  constant CCAM_EVT_DATA_HIGH_MSB                 : integer := CCAM_EVT_DATA_HIGH_LSB + CCAM_EVT_DATA_BITS - 1;

  constant CCAM_EVT_TYPE_MSB                      : integer := CCAM_EVT_DATA_BITS - 1;
  constant CCAM_EVT_TYPE_LSB                      : integer := CCAM_EVT_TYPE_MSB - CCAM_EVT_TYPE_BITS + 1;
  constant CCAM_EVT_TIME_LOW_MSB                  : integer := CCAM_EVT_TYPE_LSB - 1;
  constant CCAM_EVT_TIME_LOW_LSB                  : integer := CCAM_EVT_TIME_LOW_MSB - CCAM_EVT_TIME_LOW_BITS + 1;
  constant CCAM_EVT_RESERVED_MSB                  : integer := CCAM_EVT_TIME_LOW_LSB - 1;
  constant CCAM_EVT_RESERVED_LSB                  : integer := 0;

  constant CCAM_TD_EVT_Y_LSB                      : integer := 0;
  constant CCAM_TD_EVT_Y_MSB                      : integer := CCAM_TD_EVT_Y_LSB + CCAM_EVT_Y_BITS - 1;
  constant CCAM_TD_EVT_X_LSB                      : integer := CCAM_TD_EVT_Y_MSB + 1;
  constant CCAM_TD_EVT_X_MSB                      : integer := CCAM_TD_EVT_X_LSB + CCAM_EVT_X_BITS - 1;
  constant CCAM_TD_EVT_TIME_LOW_LSB               : integer := CCAM_EVT_TIME_LOW_LSB;
  constant CCAM_TD_EVT_TIME_LOW_MSB               : integer := CCAM_EVT_TIME_LOW_MSB;
  constant CCAM_TD_EVT_TYPE_LSB                   : integer := CCAM_EVT_TYPE_LSB;
  constant CCAM_TD_EVT_TYPE_MSB                   : integer := CCAM_EVT_TYPE_MSB;

  constant CCAM_EVT_TIME_HIGH_LSB                 : integer := 0;
  constant CCAM_EVT_TIME_HIGH_MSB                 : integer := CCAM_EVT_TIME_HIGH_LSB + CCAM_EVT_TIME_HIGH_BITS - 1;

  constant CCAM_TIME_LOW_LSB                      : integer := 0;
  constant CCAM_TIME_LOW_MSB                      : integer := CCAM_TIME_LOW_LSB + CCAM_EVT_TIME_LOW_BITS - 1;
  constant CCAM_TIME_HIGH_LSB                     : integer := CCAM_TIME_LOW_MSB + 1;
  constant CCAM_TIME_HIGH_MSB                     : integer := CCAM_TIME_HIGH_LSB + CCAM_EVT_TIME_HIGH_BITS - 1;

  constant CCAM_DISP_LOW_EVT_DISP_LSB             : integer := 0;
  constant CCAM_DISP_LOW_EVT_DISP_MSB             : integer := CCAM_DISP_LOW_EVT_DISP_LSB + CCAM_EVT_DISP_BITS - 1;
  constant CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB        : integer := CCAM_EVT_TYPE_LSB - 1;
  constant CCAM_DISP_LOW_EVT_ORIG_TYPE_LSB        : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB - CCAM_EVT_TYPE_BITS + 1;
  constant CCAM_DISP_LOW_EVT_CONT_TYPE_LSB        : integer := CCAM_EVT_TYPE_LSB;
  constant CCAM_DISP_LOW_EVT_CONT_TYPE_MSB        : integer := CCAM_EVT_TYPE_MSB;
  constant CCAM_DISP_LOW_EVT_UNUSED_LSB           : integer := CCAM_DISP_LOW_EVT_DISP_MSB + 1;
  constant CCAM_DISP_LOW_EVT_UNUSED_MSB           : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_LSB - 1;
  constant CCAM_DISP_LOW_EVT_UNUSED_BITS          : integer := CCAM_DISP_LOW_EVT_UNUSED_MSB - CCAM_DISP_LOW_EVT_UNUSED_LSB + 1;

  constant CCAM_DISP_HIGH_EVT_Y_LSB               : integer := CCAM_TD_EVT_Y_LSB;
  constant CCAM_DISP_HIGH_EVT_Y_MSB               : integer := CCAM_TD_EVT_Y_MSB;
  constant CCAM_DISP_HIGH_EVT_X_LSB               : integer := CCAM_TD_EVT_X_LSB;
  constant CCAM_DISP_HIGH_EVT_X_MSB               : integer := CCAM_TD_EVT_X_MSB;
  constant CCAM_DISP_HIGH_EVT_TIME_LOW_LSB        : integer := CCAM_EVT_TIME_LOW_LSB;
  constant CCAM_DISP_HIGH_EVT_TIME_LOW_MSB        : integer := CCAM_EVT_TIME_LOW_MSB;
  constant CCAM_DISP_HIGH_EVT_TYPE_LSB            : integer := CCAM_EVT_TYPE_LSB;
  constant CCAM_DISP_HIGH_EVT_TYPE_MSB            : integer := CCAM_EVT_TYPE_MSB;

  constant CCAM_DISP_EVT_DISP_LSB                 : integer := CCAM_DISP_LOW_EVT_DISP_LSB;
  constant CCAM_DISP_EVT_DISP_MSB                 : integer := CCAM_DISP_LOW_EVT_DISP_MSB;
  constant CCAM_DISP_EVT_ORIG_TYPE_MSB            : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB;
  constant CCAM_DISP_EVT_ORIG_TYPE_LSB            : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_LSB;
  constant CCAM_DISP_EVT_CONT_TYPE_MSB            : integer := CCAM_DISP_LOW_EVT_CONT_TYPE_MSB;
  constant CCAM_DISP_EVT_CONT_TYPE_LSB            : integer := CCAM_DISP_LOW_EVT_CONT_TYPE_LSB;

  constant CCAM_DISP_EVT_Y_LSB                    : integer := (CCAM_EVT_DATA_HIGH_LSB);
  constant CCAM_DISP_EVT_Y_MSB                    : integer := ((CCAM_DISP_EVT_Y_LSB) + (CCAM_EVT_Y_BITS) - 1);
  constant CCAM_DISP_EVT_X_LSB                    : integer := ((CCAM_DISP_EVT_Y_MSB) + 1);
  constant CCAM_DISP_EVT_X_MSB                    : integer := ((CCAM_DISP_EVT_X_LSB) + (CCAM_EVT_X_BITS) - 1);
  constant CCAM_DISP_EVT_TIME_LOW_LSB             : integer := ((CCAM_DISP_EVT_X_MSB) + 1);
  constant CCAM_DISP_EVT_TIME_LOW_MSB             : integer := ((CCAM_DISP_EVT_TIME_LOW_LSB) + (CCAM_EVT_TIME_LOW_BITS) - 1);
  constant CCAM_DISP_EVT_TYPE_MSB                 : integer := (CCAM_EVT_DATA_HIGH_MSB);
  constant CCAM_DISP_EVT_TYPE_LSB                 : integer := ((CCAM_DISP_EVT_TYPE_MSB) - (CCAM_EVT_TYPE_BITS) + 1);

  constant CCAM_OTHER_EVT_SUBTYPE_LSB             : integer := 0;
  constant CCAM_OTHER_EVT_SUBTYPE_MSB             : integer := ((CCAM_OTHER_EVT_SUBTYPE_LSB) + (CCAM_EVT_SUBTYPE_BITS) - 1);
  constant CCAM_OTHER_EVT_CLASS_LSB               : integer := ((CCAM_OTHER_EVT_SUBTYPE_MSB) + 1);
  constant CCAM_OTHER_EVT_CLASS_MSB               : integer := ((CCAM_OTHER_EVT_CLASS_LSB) + (CCAM_OTHER_CLASS_BITS) - 1);
  constant CCAM_OTHER_EVT_UNUSED_LSB              : integer := ((CCAM_OTHER_EVT_CLASS_MSB) + 1);
  constant CCAM_OTHER_EVT_UNUSED_MSB              : integer := ((CCAM_OTHER_EVT_UNUSED_LSB) + (CCAM_OTHER_UNUSED_BITS) - 1);
  constant CCAM_OTHER_EVT_TIME_LOW_LSB            : integer := ((CCAM_OTHER_EVT_UNUSED_MSB) + 1);
  constant CCAM_OTHER_EVT_TIME_LOW_MSB            : integer := ((CCAM_OTHER_EVT_TIME_LOW_LSB) + (CCAM_EVT_TIME_LOW_BITS) - 1);

  constant CCAM_CONTINUED_EVT_DATA_LSB            : integer := 0;
  constant CCAM_CONTINUED_EVT_DATA_MSB            : integer := ((CCAM_CONTINUED_EVT_DATA_LSB) + (CCAM_CONTINUED_EVT_DATA_BITS) - 1);

  constant CCAM_SYNC_EVT_Y_LSB                    : integer := 0;
  constant CCAM_SYNC_EVT_Y_MSB                    : integer := ((CCAM_SYNC_EVT_Y_LSB) + (CCAM_EVT_Y_BITS) - 1);

  -- CCAM2 Event Types
  constant EVT_TYPE_BITS                           : positive := 4;
  constant TIME_HIGH_EVT_TYPE                      : std_logic_vector(EVT_TYPE_BITS-1 downto 0) := std_logic_vector(to_unsigned(8, EVT_TYPE_BITS));
  constant EXT_TRIGGER_EVT_TYPE                    : std_logic_vector(EVT_TYPE_BITS-1 downto 0) := std_logic_vector(to_unsigned(10, EVT_TYPE_BITS));

  -- External Trigger Monitoring Event Field Bit Ranges
  constant EXT_TRIGGER_TYPE_BITS                   : positive := EVT_TYPE_BITS;
  constant EXT_TRIGGER_TIME_LOW_BITS               : positive := 6;
  constant EXT_TRIGGER_UNUSED1_BITS                : positive := 9;
  constant EXT_TRIGGER_ID_BITS                     : positive := 5;
  constant EXT_TRIGGER_UNUSED0_BITS                : positive := 7;
  constant EXT_TRIGGER_VALUE_BITS                  : positive := 1;

  subtype ccam_evt_data_t           is std_logic_vector(CCAM_EVT_DATA_BITS-1 downto 0);
  type    ccam_evt_data_vector_t    is array(natural range <>) of ccam_evt_data_t;

  subtype ccam_evt_type_t           is unsigned(CCAM_EVT_TYPE_BITS-1 downto 0);
  subtype ccam_evt_type_data_t      is std_logic_vector(CCAM_EVT_TYPE_BITS-1 downto 0);
  type    ccam_evt_type_vector_t    is array(natural range <>) of ccam_evt_type_t;

  constant LEFT_TD_LOW                            : ccam_evt_type_t := to_unsigned( 0, ccam_evt_type_t'length); -- Left camera TD event, decrease in illumination (polarity '0')
  constant LEFT_TD_HIGH                           : ccam_evt_type_t := to_unsigned( 1, ccam_evt_type_t'length); -- Left camera TD event, increase in illumination (polarity '1')
  constant LEFT_APS_END                           : ccam_evt_type_t := to_unsigned( 2, ccam_evt_type_t'length); -- Left camera APS event, measurement end (polarity '0')
  constant LEFT_APS_START                         : ccam_evt_type_t := to_unsigned( 3, ccam_evt_type_t'length); -- Left camera APS event, measurement start (polarity '1')
  constant RIGHT_TD_LOW                           : ccam_evt_type_t := to_unsigned( 4, ccam_evt_type_t'length); -- Right camera TD event, decrease in illumination (polarity '0')
  constant RIGHT_TD_HIGH                          : ccam_evt_type_t := to_unsigned( 5, ccam_evt_type_t'length); -- Right camera TD event, increase in illumination (polarity '1')
  constant RIGHT_APS_END                          : ccam_evt_type_t := to_unsigned( 6, ccam_evt_type_t'length); -- Right camera APS event, measurement end (polarity '0')
  constant RIGHT_APS_START                        : ccam_evt_type_t := to_unsigned( 7, ccam_evt_type_t'length); -- Right camera APS event, measurement start (polarity '1')
  constant EVT_TIME_HIGH                          : ccam_evt_type_t := to_unsigned( 8, ccam_evt_type_t'length); -- Timer high bits, also used to synchronize different event flows in the FPGA.
  constant STEREO_DISP                            : ccam_evt_type_t := to_unsigned( 9, ccam_evt_type_t'length); -- Stereo disparity event
  constant EXT_TRIGGER                            : ccam_evt_type_t := to_unsigned(10, ccam_evt_type_t'length); -- External trigger output
  constant GRAY_LEVEL                             : ccam_evt_type_t := to_unsigned(11, ccam_evt_type_t'length); -- Gray level event containing pixel location and intensity
  constant OPT_FLOW                               : ccam_evt_type_t := to_unsigned(12, ccam_evt_type_t'length); -- Optical flow event
  constant IMU_EVT                                : ccam_evt_type_t := to_unsigned(13, ccam_evt_type_t'length); -- IMU Event
  constant OTHER                                  : ccam_evt_type_t := to_unsigned(14, ccam_evt_type_t'length); -- To be used for extensions in the event types
  constant CONTINUED                              : ccam_evt_type_t := to_unsigned(15, ccam_evt_type_t'length); -- Extra data to previous events

  subtype ccam_evt_time_t            is unsigned(CCAM_EVT_TIME_BITS-1 downto 0);
  subtype ccam_evt_time_data_t       is std_logic_vector(CCAM_EVT_TIME_BITS-1 downto 0);
  subtype ccam_evt_time_high_t       is unsigned(CCAM_EVT_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_time_high_data_t  is std_logic_vector(CCAM_EVT_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_time_low_t        is unsigned(CCAM_EVT_TIME_LOW_BITS-1 downto 0);
  subtype ccam_evt_time_low_data_t   is std_logic_vector(CCAM_EVT_TIME_LOW_BITS-1 downto 0);

  subtype ccam_evt_x_t               is unsigned(CCAM_EVT_X_BITS-1 downto 0);
  subtype ccam_evt_x_data_t          is std_logic_vector(CCAM_EVT_X_BITS-1 downto 0);
  subtype ccam_evt_y_t               is unsigned(CCAM_EVT_Y_BITS-1 downto 0);
  subtype ccam_evt_y_data_t          is std_logic_vector(CCAM_EVT_Y_BITS-1 downto 0);
  subtype ccam_evt_disp_t            is signed(CCAM_EVT_DISP_BITS-1 downto 0);
  subtype ccam_evt_disp_unused_t     is std_logic_vector(CCAM_DISP_LOW_EVT_UNUSED_BITS-1 downto 0);
  subtype ccam_evt_disp_data_t       is std_logic_vector(CCAM_EVT_DISP_BITS-1 downto 0);

  subtype ccam_evt_trigger_unused1_t is std_logic_vector(EXT_TRIGGER_UNUSED1_BITS-1 downto 0);
  subtype ccam_evt_trigger_id_t      is unsigned(EXT_TRIGGER_ID_BITS-1 downto 0);
  subtype ccam_evt_trigger_unused0_t is std_logic_vector(EXT_TRIGGER_UNUSED0_BITS-1 downto 0);
  subtype ccam_evt_trigger_value_t   is std_logic;

  subtype ccam_evt_class_t           is std_logic;

  subtype ccam_evt_subtype_t         is unsigned(CCAM_EVT_SUBTYPE_BITS-1 downto 0);
  subtype ccam_evt_subtype_data_t    is std_logic_vector(CCAM_EVT_SUBTYPE_BITS-1 downto 0);

  type    ccam_evt_subtype_vector_t  is array(natural range <>) of ccam_evt_subtype_t;

  subtype ccam_continued_evt_data_t  is std_logic_vector(CCAM_CONTINUED_EVT_DATA_BITS-1 downto 0);


  -- Monitoring Events Subtypes as Listed in:
  -- http://confluence.chronocam.com/display/SYSDEV/System+Monitoring+Events+2.0
  constant MASTER_SYSTEM_TEMPERATURE           : ccam_evt_subtype_t := x"0000"; -- Monitors current FPGA system temperature value periodically. Implemented as of version 1.1.1
  constant MASTER_SYSTEM_VOLTAGE               : ccam_evt_subtype_t := x"0001"; -- Monitors current FPGA power supply voltage levels periodically.   Implemented as of version 1.1.1
  constant MASTER_SYSTEM_IN_EVENT_COUNT        : ccam_evt_subtype_t := x"0002"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant MASTER_SYSTEM_IN_EVENT_SEQ_ERROR    : ccam_evt_subtype_t := x"0003"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant MASTER_SYSTEM_IN_EVENT_TIME_ERROR   : ccam_evt_subtype_t := x"0004"; -- Alerts of an event timestamp disruption, if enabled.
  constant MASTER_SYSTEM_OUT_EVENT_COUNT       : ccam_evt_subtype_t := x"0005"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant MASTER_SYSTEM_OUT_EVENT_SEQ_ERROR   : ccam_evt_subtype_t := x"0006"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant MASTER_SYSTEM_OUT_EVENT_TIME_ERROR  : ccam_evt_subtype_t := x"0007"; -- Alerts of an event timestamp disruption, if enabled.
  constant MASTER_ATIS_BIAS_PROG_ERROR         : ccam_evt_subtype_t := x"0008"; -- Alerts of a bias programming error.
  constant MASTER_ATIS_ILLUMINATION            : ccam_evt_subtype_t := x"0009"; -- Monitors the global illumination periodically.    Implemented as of version 1.1.1
  constant MASTER_ATIS_TD_IDLE_TIME            : ccam_evt_subtype_t := x"000A"; -- Monitors the time interval between two TD events, if over a given threshold.    Implemented as of version 1.1.1
  constant MASTER_ATIS_APS_IDLE_TIME           : ccam_evt_subtype_t := x"000B"; -- Monitors the time interval between two APS events, if over a given threshold.   Implemented as of version 1.1.1
  constant MASTER_ATIS_TD_IDLE_TIMEOUT         : ccam_evt_subtype_t := x"000C"; -- Alerts if no TD event has been received for a set amount of time.   Implemented as of version 1.1.1
  constant MASTER_ATIS_APS_IDLE_TIMEOUT        : ccam_evt_subtype_t := x"000D"; -- Alerts if no APS event has been received for a set amount of time.    Implemented as of version 1.1.1
  constant MASTER_ATIS_REFRACTORY_CLOCK        : ccam_evt_subtype_t := x"000E"; -- Monitors the refractory clock period.
  constant EPOCH_START                         : ccam_evt_subtype_t := x"0010";
  constant EPOCH_END                           : ccam_evt_subtype_t := x"0011";
  constant EPOCH_LINE_START                    : ccam_evt_subtype_t := x"0012";
  constant EPOCH_LINE_END                      : ccam_evt_subtype_t := x"0013";
  constant MASTER_IN_TD_EVENT_COUNT            : ccam_evt_subtype_t := x"0014"; -- Monitors the number of incoming TD events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.
  constant MASTER_IN_APS_EVENT_COUNT           : ccam_evt_subtype_t := x"0015"; -- Monitors the number of incoming APS events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.
  constant MASTER_RATE_CONTROL_TD_EVENT_COUNT  : ccam_evt_subtype_t := x"0016"; -- Monitors the number of TD events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.
  constant MASTER_RATE_CONTROL_APS_EVENT_COUNT : ccam_evt_subtype_t := x"0017"; -- Monitors the number of APS events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.
  constant MASTER_START_OF_FRAME               : ccam_evt_subtype_t := x"0018"; -- Marks the start of a Frame in MIPI transmissions.
  constant MASTER_END_OF_FRAME                 : ccam_evt_subtype_t := x"0019"; -- Marks the end of a Frame in MIPI transmissions.
  constant MASTER_MIPI_PADDING                 : ccam_evt_subtype_t := x"001A"; -- Master MIPI TX Padding Data
  constant MASTER_GPAFK_PERIOD                 : ccam_evt_subtype_t := x"0044"; -- Master GPAFK Period Stats
  constant MASTER_GPAFK_TIMESPAN               : ccam_evt_subtype_t := x"0045"; -- Master GPAFK Timespan Stats
  constant MASTER_GPAFK_IN_TD_EVT_COUNT        : ccam_evt_subtype_t := x"0046"; -- Master GPAFK Input TD Event Count Stats
  constant MASTER_GPAFK_OUT_TD_EVT_COUNT       : ccam_evt_subtype_t := x"0047"; -- Master GPAFK Output TD Event Count Stats
  constant MASTER_SYSTEM_TB_END_OF_TASK        : ccam_evt_subtype_t := x"00FD"; -- Marks the end of a Test Task
  constant MASTER_USB_PACKET_INFO              : ccam_evt_subtype_t := x"00FE"; -- Software Generated Event with USB Packet Info (Arrival Time, Size, etc.)    Software implemented.
  constant MASTER_DUMMY_EVENT                  : ccam_evt_subtype_t := x"00FF"; -- General Purpose Dummy Event.    To be implemented in Moorea
  constant MASTER_DATA_INTEGRITY_MARKER        : ccam_evt_subtype_t := x"0314"; -- Data integrity marker
  constant MASTER_TH_DROP_EVENT                : ccam_evt_subtype_t := x"0ED8"; -- Alerts of events dropped due to a previous corrupted TIME HIGH event
  constant MASTER_EVT_DROP_EVENT               : ccam_evt_subtype_t := x"0EDA"; -- Alerts of events dropped
  constant SLAVE_SYSTEM_TEMPERATURE            : ccam_evt_subtype_t := x"4000"; -- Monitors current FPGA system temperature value periodically.   Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_SYSTEM_VOLTAGE                : ccam_evt_subtype_t := x"4001"; -- Monitors current FPGA power supply voltage levels periodically.  Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_SYSTEM_IN_EVENT_COUNT         : ccam_evt_subtype_t := x"4002"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant SLAVE_SYSTEM_IN_EVENT_SEQ_ERROR     : ccam_evt_subtype_t := x"4003"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant SLAVE_SYSTEM_IN_EVENT_TIME_ERROR    : ccam_evt_subtype_t := x"4004"; -- Alerts of an event timestamp disruption, if enabled.
  constant SLAVE_SYSTEM_OUT_EVENT_COUNT        : ccam_evt_subtype_t := x"4005"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant SLAVE_SYSTEM_OUT_EVENT_SEQ_ERROR    : ccam_evt_subtype_t := x"4006"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant SLAVE_SYSTEM_OUT_EVENT_TIME_ERROR   : ccam_evt_subtype_t := x"4007"; -- Alerts of an event timestamp disruption, if enabled.
  constant SLAVE_ATIS_BIAS_PROG_ERROR          : ccam_evt_subtype_t := x"4008"; -- Alerts of a bias programming error.
  constant SLAVE_ATIS_ILLUMINATION             : ccam_evt_subtype_t := x"4009"; -- Monitors the global illumination periodically. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_TD_IDLE_TIME             : ccam_evt_subtype_t := x"400A"; -- Monitors the time interval between two TD events, if over a given threshold. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_APS_IDLE_TIME            : ccam_evt_subtype_t := x"400B"; -- Monitors the time interval between two APS events, if over a given threshold.
  constant SLAVE_ATIS_TD_IDLE_TIMEOUT          : ccam_evt_subtype_t := x"400C"; -- Alerts if no TD event has been received for a set amount of time. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant SLAVE_ATIS_APS_IDLE_TIMEOUT         : ccam_evt_subtype_t := x"400D"; -- Alerts if no APS event has been received for a set amount of time. Implemented as of version 1.1.1 (Not transmitted by slave system)
  constant STEREO_SYSTEM_TEMPERATURE           : ccam_evt_subtype_t := x"8000"; -- Monitors current FPGA system temperature value periodically. Implemented as of version 1.1.1
  constant STEREO_SYSTEM_VOLTAGE               : ccam_evt_subtype_t := x"8001"; -- Monitors current FPGA power supply voltage levels periodically.


  subtype ccam_system_id_t is std_logic_vector(1 downto 0);
  constant CCAM_LEFT_SYSTEM_ID                    : ccam_system_id_t := std_logic_vector(to_unsigned(0, ccam_system_id_t'length));
  constant CCAM_RIGHT_SYSTEM_ID                   : ccam_system_id_t := std_logic_vector(to_unsigned(1, ccam_system_id_t'length));
  constant CCAM_STEREO_SYSTEM_ID                  : ccam_system_id_t := std_logic_vector(to_unsigned(2, ccam_system_id_t'length));

  type ccam_evt_t is record
    type_f     : ccam_evt_type_t;
    time_f     : ccam_evt_time_low_t;
    reserved_f : unsigned(CCAM_EVT_RESERVED_MSB downto CCAM_EVT_RESERVED_LSB);
  end record ccam_evt_t;

  type ccam_td_evt_t is record
    type_f : ccam_evt_type_t;
    time_f : ccam_evt_time_low_t;
    x_f    : ccam_evt_x_t;
    y_f    : ccam_evt_y_t;
  end record ccam_td_evt_t;

  type ccam_th_evt_t is record
    type_f      : ccam_evt_type_t;
    time_high_f : ccam_evt_time_high_t;
  end record ccam_th_evt_t;

  type ccam_disp_high_evt_t is record
    type_f : ccam_evt_type_t;
    time_f : ccam_evt_time_low_t;
    x_f    : ccam_evt_x_t;
    y_f    : ccam_evt_y_t;
  end record ccam_disp_high_evt_t;

  type ccam_disp_low_evt_t is record
    type_f      : ccam_evt_type_t;
    orig_type_f : ccam_evt_type_t;
    unused_f    : ccam_evt_disp_unused_t;
    disp_f      : ccam_evt_disp_t;
  end record ccam_disp_low_evt_t;

  type ccam_other_evt_t is record
    type_f    : ccam_evt_type_t;
    time_f    : ccam_evt_time_low_t;
    unused_f  : unsigned(CCAM_OTHER_EVT_UNUSED_MSB downto CCAM_OTHER_EVT_UNUSED_LSB);
    class_f   : ccam_evt_class_t;
    subtype_f : ccam_evt_subtype_t;
  end record ccam_other_evt_t;

  type ccam_continued_evt_t is record
    type_f : ccam_evt_type_t;
    data_f : ccam_continued_evt_data_t;
  end record ccam_continued_evt_t;

  type ccam_ext_trigger_evt_t is record
    type_f    : ccam_evt_type_t;
    time_f    : ccam_evt_time_low_t;
    unused1_f : ccam_evt_trigger_unused1_t;
    id_f      : ccam_evt_trigger_id_t;
    unused0_f : ccam_evt_trigger_unused0_t;
    value_f   : ccam_evt_trigger_value_t;
  end record ccam_ext_trigger_evt_t;

  subtype ccam_sync_evt_data_t is std_logic_vector(CCAM_SYNC_EVT_DATA_BITS-1 downto 0);

  type ccam_sync_evt_t is record
    y_f : ccam_evt_y_t;
  end record ccam_sync_evt_t;

  function to_ccam_evt(evt_data_v: ccam_evt_data_t) return ccam_evt_t;
  function to_ccam_evt_data(evt_v: ccam_evt_t) return ccam_evt_data_t;

  function to_ccam_evt_data_vector(data_v: std_logic_vector) return ccam_evt_data_vector_t;
  function to_std_logic_vector(data_vector_v: ccam_evt_data_vector_t) return std_logic_vector;

  function to_ccam_td_evt(evt_data_v: ccam_evt_data_t) return ccam_td_evt_t;
  function to_ccam_evt_data(td_evt_v: ccam_td_evt_t) return ccam_evt_data_t;

  function to_ccam_th_evt(evt_data_v: ccam_evt_data_t) return ccam_th_evt_t;
  function to_ccam_evt_data(th_evt_v: ccam_th_evt_t) return ccam_evt_data_t;

  function to_ccam_ext_trigger_evt(evt_data_v : ccam_evt_data_t) return ccam_ext_trigger_evt_t;
  function to_ccam_evt_data(ext_trigger_evt_v : ccam_ext_trigger_evt_t) return ccam_evt_data_t;

  function to_ccam_other_evt(evt_data_v : ccam_evt_data_t) return ccam_other_evt_t;
  function to_ccam_evt_data(other_evt_v : ccam_other_evt_t) return ccam_evt_data_t;

  function to_ccam_continued_evt(evt_data_v : ccam_evt_data_t) return ccam_continued_evt_t;
  function to_ccam_evt_data(continued_evt_v : ccam_continued_evt_t) return ccam_evt_data_t;

  function to_ccam_sync_evt(sync_evt_data_v: ccam_sync_evt_data_t) return ccam_sync_evt_t;
  function to_ccam_sync_evt_data(sync_evt_v: ccam_sync_evt_t) return ccam_sync_evt_data_t;

  function get_subevent_continued_num(subevent : ccam_evt_subtype_t) return unsigned;

  function get_evt_continued_num(event : ccam_other_evt_t) return unsigned;

  -- Event Interface Marker Flag Number
  constant CCAM_EVT_MARKER_NUM  : positive := 48;

  subtype ccam_evt_marker_t     is std_logic_vector(CCAM_EVT_MARKER_NUM-1 downto 0);

  function evt_marker_encode(event : ccam_other_evt_t) return ccam_evt_marker_t;

end ccam_evt_types;

package body ccam_evt_types is

  ----------------
  -- Generic Event

  function to_ccam_evt(evt_data_v : ccam_evt_data_t) return ccam_evt_t is
    variable evt_v : ccam_evt_t;
    variable i_v   : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, evt_v.reserved_f);
    unpack(evt_data_v, i_v, evt_v.time_f);
    unpack(evt_data_v, i_v, evt_v.type_f);
    return evt_v;
  end function to_ccam_evt;

  function to_ccam_evt_data(evt_v : ccam_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, evt_v.reserved_f);
    pack(evt_data_v, i_v, evt_v.time_f);
    pack(evt_data_v, i_v, evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;

  --------------------
  -- Event Data Vector
  function to_ccam_evt_data_vector(data_v: std_logic_vector) return ccam_evt_data_vector_t is
    variable data_width_v  : positive := CCAM_EVT_DATA_BITS;
    variable size_v        : positive := data_v'length / data_width_v;
    variable data_vector_v : ccam_evt_data_vector_t(size_v-1 downto 0);
    variable data_msb_v    : integer;
    variable data_lsb_v    : integer;
  begin
    for i in 0 to size_v-1 loop
      data_msb_v       := (i+1)*data_width_v-1;
      data_lsb_v       := (i  )*data_width_v;
      data_vector_v(i) := data_v(data_msb_v downto data_lsb_v);
    end loop;
    return data_vector_v;
  end function to_ccam_evt_data_vector;

  function to_std_logic_vector(data_vector_v: ccam_evt_data_vector_t) return std_logic_vector is
    variable data_width_v : positive := CCAM_EVT_DATA_BITS;
    variable size_v       : positive := data_vector_v'length;
    variable data_v       : std_logic_vector(size_v*data_width_v-1 downto 0);
    variable data_msb_v   : integer;
    variable data_lsb_v   : integer;
  begin
    for i in 0 to size_v-1 loop
      data_msb_v                           := (i+1)*data_width_v-1;
      data_lsb_v                           := (i  )*data_width_v;
      data_v(data_msb_v downto data_lsb_v) := data_vector_v(i);
    end loop;
    return data_v;
  end function to_std_logic_vector;

  -----------
  -- TD Event

  function to_ccam_td_evt(evt_data_v : ccam_evt_data_t) return ccam_td_evt_t is
    variable td_evt_v : ccam_td_evt_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, td_evt_v.y_f);
    unpack(evt_data_v, i_v, td_evt_v.x_f);
    unpack(evt_data_v, i_v, td_evt_v.time_f);
    unpack(evt_data_v, i_v, td_evt_v.type_f);
    return td_evt_v;
  end function to_ccam_td_evt;

  function to_ccam_evt_data(td_evt_v : ccam_td_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, td_evt_v.y_f);
    pack(evt_data_v, i_v, td_evt_v.x_f);
    pack(evt_data_v, i_v, td_evt_v.time_f);
    pack(evt_data_v, i_v, td_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  -----------------------
  -- Time High (TH) Event

  function to_ccam_th_evt(evt_data_v : ccam_evt_data_t) return ccam_th_evt_t is
    variable th_evt_v : ccam_th_evt_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, th_evt_v.time_high_f);
    unpack(evt_data_v, i_v, th_evt_v.type_f);
    return th_evt_v;
  end function to_ccam_th_evt;

  function to_ccam_evt_data(th_evt_v : ccam_th_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, th_evt_v.time_high_f);
    pack(evt_data_v, i_v, th_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  --------------------
  -- EXT Trigger Event

  function to_ccam_ext_trigger_evt(evt_data_v : ccam_evt_data_t) return ccam_ext_trigger_evt_t is
    variable ext_trigger_evt_v  : ccam_ext_trigger_evt_t;
    variable i_v                : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, ext_trigger_evt_v.value_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.unused0_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.id_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.unused1_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.time_f);
    unpack(evt_data_v, i_v, ext_trigger_evt_v.type_f);
    return ext_trigger_evt_v;
  end function to_ccam_ext_trigger_evt;

  function to_ccam_evt_data(ext_trigger_evt_v : ccam_ext_trigger_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, ext_trigger_evt_v.value_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.unused0_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.id_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.unused1_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.time_f);
    pack(evt_data_v, i_v, ext_trigger_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  --------------
  -- Other Event

  function to_ccam_other_evt(evt_data_v : ccam_evt_data_t) return ccam_other_evt_t is
    variable other_evt_v : ccam_other_evt_t;
    variable i_v   : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, other_evt_v.subtype_f);
    unpack(evt_data_v, i_v, other_evt_v.class_f);
    unpack(evt_data_v, i_v, other_evt_v.unused_f);
    unpack(evt_data_v, i_v, other_evt_v.time_f);
    unpack(evt_data_v, i_v, other_evt_v.type_f);
    other_evt_v.unused_f := (others => '0');
    return other_evt_v;
  end function to_ccam_other_evt;

  function to_ccam_evt_data(other_evt_v : ccam_other_evt_t) return ccam_evt_data_t is
    variable other_evt_local_v : ccam_other_evt_t;
    variable evt_data_v        : ccam_evt_data_t;
    variable i_v               : integer;
  begin
    evt_data_v := (others => 'U');
    other_evt_local_v := other_evt_v;
    other_evt_local_v.unused_f := (others => '0');
    i_v := 0;
    pack(evt_data_v, i_v, other_evt_v.subtype_f);
    pack(evt_data_v, i_v, other_evt_v.class_f);
    pack(evt_data_v, i_v, other_evt_v.unused_f);
    pack(evt_data_v, i_v, other_evt_v.time_f);
    pack(evt_data_v, i_v, other_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  ------------------
  -- Continued Event

  function to_ccam_continued_evt(evt_data_v : ccam_evt_data_t) return ccam_continued_evt_t is
    variable continued_evt_v : ccam_continued_evt_t;
    variable i_v             : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, continued_evt_v.data_f);
    unpack(evt_data_v, i_v, continued_evt_v.type_f);
    return continued_evt_v;
  end function to_ccam_continued_evt;

  function to_ccam_evt_data(continued_evt_v : ccam_continued_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, continued_evt_v.data_f);
    pack(evt_data_v, i_v, continued_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  -------------
  -- Sync Event

  function to_ccam_sync_evt(sync_evt_data_v : ccam_sync_evt_data_t) return ccam_sync_evt_t is
    variable sync_evt_v : ccam_sync_evt_t;
    variable i_v        : integer;
  begin
    i_v := 0;
    unpack(sync_evt_data_v, i_v, sync_evt_v.y_f);
    return sync_evt_v;
  end function to_ccam_sync_evt;

  function to_ccam_sync_evt_data(sync_evt_v : ccam_sync_evt_t) return ccam_sync_evt_data_t is
    variable sync_evt_data_v : ccam_sync_evt_data_t;
    variable i_v             : integer;
  begin
    sync_evt_data_v := (others => 'U');
    i_v := 0;
    pack(sync_evt_data_v, i_v, sync_evt_v.y_f);
    return sync_evt_data_v;
  end function to_ccam_sync_evt_data;


  -------------------------------------------
  -- Get Sub type Event Continue Word Number

  function get_subevent_continued_num(subevent : ccam_evt_subtype_t) return unsigned is
    variable number  : unsigned(3 downto 0);
  begin
    case subevent is
      when MASTER_SYSTEM_TEMPERATURE          =>
        number  := to_unsigned(4, number'length);
      when MASTER_SYSTEM_VOLTAGE              =>
        number  := to_unsigned(1, number'length);
      when MASTER_SYSTEM_IN_EVENT_COUNT       =>
        number  := to_unsigned(1, number'length);
      when MASTER_SYSTEM_IN_EVENT_SEQ_ERROR   =>
        number  := to_unsigned(2, number'length);
      when MASTER_SYSTEM_IN_EVENT_TIME_ERROR  =>
        number  := to_unsigned(4, number'length);
      when MASTER_SYSTEM_OUT_EVENT_COUNT      =>
        number  := to_unsigned(1, number'length);
      when MASTER_SYSTEM_OUT_EVENT_SEQ_ERROR  =>
        number  := to_unsigned(2, number'length);
      when MASTER_SYSTEM_OUT_EVENT_TIME_ERROR =>
        number  := to_unsigned(4, number'length);
      when MASTER_ATIS_ILLUMINATION | SLAVE_ATIS_ILLUMINATION | MASTER_ATIS_REFRACTORY_CLOCK =>
        number  := to_unsigned(1, number'length);
      when MASTER_ATIS_TD_IDLE_TIME           =>
        number  := to_unsigned(1, number'length);
      when MASTER_ATIS_APS_IDLE_TIME          =>
        number  := to_unsigned(1, number'length);
      when MASTER_ATIS_TD_IDLE_TIMEOUT        =>
        number  := to_unsigned(1, number'length);
      when MASTER_ATIS_APS_IDLE_TIMEOUT       =>
        number  := to_unsigned(1, number'length);
      when MASTER_START_OF_FRAME              =>
        number  := to_unsigned(1, number'length);
      when MASTER_END_OF_FRAME                =>
        number  := to_unsigned(0, number'length);
      when MASTER_SYSTEM_TB_END_OF_TASK       =>
        number  := to_unsigned(0, number'length);
      -- when MASTER_ATIS_BIAS_PROG_ERROR        =>
      -- when EPOCH_START                        =>
      -- when EPOCH_END                          =>
      -- when EPOCH_LINE_START                   =>
      -- when EPOCH_LINE_END                     =>
      -- when MASTER_USB_PACKET_INFO             =>
      -- when MASTER_DUMMY_EVENT                 =>
      -- when SLAVE_SYSTEM_TEMPERATURE           =>
      -- when SLAVE_SYSTEM_VOLTAGE               =>
      -- when SLAVE_SYSTEM_IN_EVENT_COUNT        =>
      -- when SLAVE_SYSTEM_IN_EVENT_SEQ_ERROR    =>
      -- when SLAVE_SYSTEM_IN_EVENT_TIME_ERROR   =>
      -- when SLAVE_SYSTEM_OUT_EVENT_COUNT       =>
      -- when SLAVE_SYSTEM_OUT_EVENT_SEQ_ERROR   =>
      -- when SLAVE_SYSTEM_OUT_EVENT_TIME_ERROR  =>
      -- when SLAVE_ATIS_BIAS_PROG_ERROR         =>
      -- when SLAVE_ATIS_TD_IDLE_TIME            =>
      -- when SLAVE_ATIS_APS_IDLE_TIME           =>
      -- when SLAVE_ATIS_TD_IDLE_TIMEOUT         =>
      -- when SLAVE_ATIS_APS_IDLE_TIMEOUT        =>
      -- when STEREO_SYSTEM_TEMPERATURE          =>
      -- when STEREO_SYSTEM_VOLTAGE              =>
      when others =>
        number  := to_unsigned(0, number'length);
    end case;

    return number;
  end function get_subevent_continued_num;


  -------------------------------------------
  -- Get Sub type Event Continue Word Number

  function get_evt_continued_num(event : ccam_other_evt_t) return unsigned is
    variable number  : unsigned(3 downto 0);
  begin
    case event.type_f is
      when STEREO_DISP | GRAY_LEVEL | OPT_FLOW =>
        number  := to_unsigned(1, number'length);
      when IMU_EVT =>
        number  := to_unsigned(5, number'length);
      when OTHER =>
        number  := get_subevent_continued_num(event.subtype_f);
      when others =>
        number  := to_unsigned(0, number'length);
    end case;

    return number;
  end function get_evt_continued_num;


  ------------------------------------------
  -- Encode the Marker for different Events
  function evt_marker_encode(event : ccam_other_evt_t) return ccam_evt_marker_t is
    variable marker : ccam_evt_marker_t := (others => '0');
  begin
    case event.type_f is
      when EVT_TIME_HIGH  =>
        marker      := (others => '1');
      when LEFT_TD_LOW | LEFT_TD_HIGH =>
        marker      := (others => '0');
        marker(0)   := '1';
        assert marker'length >= 1
        report "marker number is less than needed!"
        severity FAILURE;

      when LEFT_APS_END | LEFT_APS_START =>
        marker      := (others => '0');
        marker(1)   := '1';
        assert marker'length >= 2
        report "marker number is less than needed!"
        severity FAILURE;

      when RIGHT_TD_LOW | RIGHT_TD_HIGH =>
        marker      := (others => '0');
        marker(2)   := '1';
        assert marker'length >= 3
        report "marker number is less than needed!"
        severity FAILURE;

      when RIGHT_APS_END | RIGHT_APS_START =>
        marker      := (others => '0');
        marker(3)   := '1';
        assert marker'length >= 4
        report "marker number is less than needed!"
        severity FAILURE;

      when STEREO_DISP    =>
        marker      := (others => '0');
        marker(4)   := '1';
        assert marker'length >= 5
        report "marker number is less than needed!"
        severity FAILURE;

      when EXT_TRIGGER    =>
        marker      := (others => '0');
        marker(5)   := '1';
        assert marker'length >= 6
        report "marker number is less than needed!"
        severity FAILURE;

      when GRAY_LEVEL     =>
        marker      := (others => '0');
        marker(6)   := '1';
        assert marker'length >= 7
        report "marker number is less than needed!"
        severity FAILURE;

      when OPT_FLOW       =>
        marker      := (others => '0');
        marker(7)   := '1';
        assert marker'length >= 8
        report "marker number is less than needed!"
        severity FAILURE;

      when IMU_EVT        =>
        marker      := (others => '0');
        marker(8)   := '1';
        assert marker'length >= 9
        report "marker number is less than needed!"
        severity FAILURE;

      when OTHER          =>
        case event.subtype_f is
          when MASTER_SYSTEM_TB_END_OF_TASK       =>
            marker      := (others => '1');
          when MASTER_SYSTEM_TEMPERATURE          =>
            marker      := (others => '0');
            marker(9)   := '1';
            assert marker'length >= 10
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_VOLTAGE              =>
            marker      := (others => '0');
            marker(10)  := '1';
            assert marker'length >= 11
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_IN_EVENT_COUNT       =>
            marker      := (others => '0');
            marker(11)  := '1';
            assert marker'length >= 12
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_IN_EVENT_SEQ_ERROR   =>
            marker      := (others => '0');
            marker(12)  := '1';
            assert marker'length >= 13
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_IN_EVENT_TIME_ERROR  =>
            marker      := (others => '0');
            marker(13)  := '1';
            assert marker'length >= 14
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_OUT_EVENT_COUNT      =>
            marker      := (others => '0');
            marker(14)  := '1';
            assert marker'length >= 15
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_OUT_EVENT_SEQ_ERROR  =>
            marker      := (others => '0');
            marker(15)  := '1';
            assert marker'length >= 16
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_SYSTEM_OUT_EVENT_TIME_ERROR =>
            marker      := (others => '0');
            marker(16)  := '1';
            assert marker'length >= 17
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_BIAS_PROG_ERROR        =>
            marker      := (others => '0');
            marker(17)  := '1';
            assert marker'length >= 18
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_ILLUMINATION           =>
            marker      := (others => '0');
            marker(18)  := '1';
            assert marker'length >= 19
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_TD_IDLE_TIME           =>
            marker      := (others => '0');
            marker(19)  := '1';
            assert marker'length >= 20
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_APS_IDLE_TIME          =>
            marker      := (others => '0');
            marker(20)  := '1';
            assert marker'length >= 21
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_TD_IDLE_TIMEOUT        =>
            marker      := (others => '0');
            marker(21)  := '1';
            assert marker'length >= 22
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_APS_IDLE_TIMEOUT       =>
            marker      := (others => '0');
            marker(22)  := '1';
            assert marker'length >= 23
            report "marker number is less than needed!"
            severity FAILURE;

          when EPOCH_START                        =>
            marker      := (others => '0');
            marker(23)  := '1';
            assert marker'length >= 24
            report "marker number is less than needed!"
            severity FAILURE;

          when EPOCH_END                          =>
            marker      := (others => '0');
            marker(24)  := '1';
            assert marker'length >= 25
            report "marker number is less than needed!"
            severity FAILURE;

          when EPOCH_LINE_START                   =>
            marker      := (others => '0');
            marker(25)  := '1';
            assert marker'length >= 26
            report "marker number is less than needed!"
            severity FAILURE;

          when EPOCH_LINE_END                     =>
            marker      := (others => '0');
            marker(26)  := '1';
            assert marker'length >= 27
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_START_OF_FRAME              =>
            marker      := (others => '0');
            marker(27)  := '1';
            assert marker'length >= 28
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_END_OF_FRAME                =>
            marker      := (others => '0');
            marker(28)  := '1';
            assert marker'length >= 29
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_USB_PACKET_INFO             =>
            marker      := (others => '0');
            marker(29)  := '1';
            assert marker'length >= 30
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_DUMMY_EVENT                 =>
            marker      := (others => '0');
            marker(30)  := '1';
            assert marker'length >= 31
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_TEMPERATURE           =>
            marker      := (others => '0');
            marker(31)  := '1';
            assert marker'length >= 32
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_VOLTAGE               =>
            marker      := (others => '0');
            marker(32)  := '1';
            assert marker'length >= 33
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_IN_EVENT_COUNT        =>
            marker      := (others => '0');
            marker(33)  := '1';
            assert marker'length >= 34
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_IN_EVENT_SEQ_ERROR    =>
            marker      := (others => '0');
            marker(34)  := '1';
            assert marker'length >= 35
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_IN_EVENT_TIME_ERROR   =>
            marker      := (others => '0');
            marker(35)  := '1';
            assert marker'length >= 36
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_OUT_EVENT_COUNT       =>
            marker      := (others => '0');
            marker(36)  := '1';
            assert marker'length >= 37
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_OUT_EVENT_SEQ_ERROR   =>
            marker      := (others => '0');
            marker(37)  := '1';
            assert marker'length >= 38
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_SYSTEM_OUT_EVENT_TIME_ERROR  =>
            marker      := (others => '0');
            marker(38)  := '1';
            assert marker'length >= 39
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_BIAS_PROG_ERROR         =>
            marker      := (others => '0');
            marker(39)  := '1';
            assert marker'length >= 40
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_ILLUMINATION            =>
            marker      := (others => '0');
            marker(40)  := '1';
            assert marker'length >= 41
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_TD_IDLE_TIME            =>
            marker      := (others => '0');
            marker(41)  := '1';
            assert marker'length >= 42
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_APS_IDLE_TIME           =>
            marker      := (others => '0');
            marker(42)  := '1';
            assert marker'length >= 43
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_TD_IDLE_TIMEOUT         =>
            marker      := (others => '0');
            marker(43)  := '1';
            assert marker'length >= 44
            report "marker number is less than needed!"
            severity FAILURE;

          when SLAVE_ATIS_APS_IDLE_TIMEOUT        =>
            marker      := (others => '0');
            marker(44)  := '1';
            assert marker'length >= 45
            report "marker number is less than needed!"
            severity FAILURE;

          when STEREO_SYSTEM_TEMPERATURE          =>
            marker      := (others => '0');
            marker(45)  := '1';
            assert marker'length >= 46
            report "marker number is less than needed!"
            severity FAILURE;

          when STEREO_SYSTEM_VOLTAGE              =>
            marker      := (others => '0');
            marker(46)  := '1';
            assert marker'length >= 47
            report "marker number is less than needed!"
            severity FAILURE;

          when MASTER_ATIS_REFRACTORY_CLOCK       =>
            marker      := (others => '0');
            marker(47)  := '1';
            assert marker'length >= 48
            report "marker number is less than needed!"
            severity FAILURE;

          when others =>
            marker      := (others => '0');
        end case;
      when others =>
        marker      := (others => '0');
    end case;

    return marker;

  end function evt_marker_encode;

end ccam_evt_types;
