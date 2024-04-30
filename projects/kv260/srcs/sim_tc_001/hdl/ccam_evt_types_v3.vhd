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

library work;
use work.ccam_utils.all;
use work.ccam_evt_types.all;

package ccam_evt_types_v3 is

  constant IMAGE_V3_MAX_WIDTH                        : integer := 2048;        -- event support max image width 2**11
  constant IMAGE_V3_MAX_HEIGHT                       : integer := 2048;        -- event support max image height 2**11

  constant CCAM_EVT_V3_DATA_BITS                     : integer := 16;
  constant CCAM_EVT_V3_TYPE_BITS                     : integer := 4;
  constant CCAM_EVT_V3_PAYLOAD_DATA_BITS             : integer := CCAM_EVT_V3_DATA_BITS - CCAM_EVT_V3_TYPE_BITS;
  constant CCAM_EVT_V3_X_BITS                        : integer := 11;
  constant CCAM_EVT_V3_Y_BITS                        : integer := 11;
  constant CCAM_EVT_V3_VECT_12_BITS                  : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_VECT_8_BITS                   : integer := 8;
  constant CCAM_EVT_V3_SYSTEM_TYPE_BITS              : integer := 1;
  constant CCAM_EVT_V3_POLARITY_BITS                 : integer := 1;
  constant CCAM_EVT_V3_CONTINUED_12_DATA_BITS        : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_CONTINUED_4_DATA_BITS         : integer := 4;
  constant CCAM_EVT_V3_ADDR_BITS                     : integer := CCAM_EVT_V3_Y_BITS + CCAM_EVT_V3_X_BITS;
  constant CCAM_EVT_V3_TIME_LOW_BITS                 : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_TIME_HIGH_BITS                : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_TIME_BITS                     : integer := CCAM_EVT_V3_TIME_HIGH_BITS + CCAM_EVT_V3_TIME_LOW_BITS;
  constant CCAM_EVT_V3_SUBTYPE_BITS                  : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_VECT_8_UNUSED_BITS            : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS - CCAM_EVT_V3_VECT_8_BITS;
  constant CCAM_EVT_V3_OTHER_SUBTYPE_BITS            : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_IMU_DATA_BITS                 : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS;
  constant CCAM_EVT_V3_CONTINUED_4_UNUSED_BITS       : integer := CCAM_EVT_V3_PAYLOAD_DATA_BITS - CCAM_EVT_V3_CONTINUED_4_DATA_BITS;

  constant CCAM_EVT_V3_DATA_LSB                      : integer := 0;
  constant CCAM_EVT_V3_DATA_MSB                      : integer := CCAM_EVT_V3_DATA_LSB + CCAM_EVT_V3_DATA_BITS - 1;
  constant CCAM_EVT_V3_DATA_HIGH_LSB                 : integer := CCAM_EVT_V3_DATA_MSB + 1;
  constant CCAM_EVT_V3_DATA_HIGH_MSB                 : integer := CCAM_EVT_V3_DATA_HIGH_LSB + CCAM_EVT_V3_DATA_BITS - 1;

  constant CCAM_EVT_V3_TYPE_MSB                      : integer := CCAM_EVT_V3_DATA_BITS - 1;
  constant CCAM_EVT_V3_TYPE_LSB                      : integer := CCAM_EVT_V3_TYPE_MSB - CCAM_EVT_V3_TYPE_BITS + 1;
  constant CCAM_EVT_V3_RESERVED_MSB                  : integer := CCAM_EVT_V3_TYPE_LSB - 1;
  constant CCAM_EVT_V3_RESERVED_LSB                  : integer := 0;

  -- constant CCAM_TD_EVT_Y_LSB                      : integer := 0;
  -- constant CCAM_TD_EVT_Y_MSB                      : integer := CCAM_TD_EVT_Y_LSB + CCAM_EVT_Y_BITS - 1;
  -- constant CCAM_TD_EVT_X_LSB                      : integer := CCAM_TD_EVT_Y_MSB + 1;
  -- constant CCAM_TD_EVT_X_MSB                      : integer := CCAM_TD_EVT_X_LSB + CCAM_EVT_X_BITS - 1;
  -- constant CCAM_TD_EVT_TIME_LOW_LSB               : integer := CCAM_EVT_TIME_LOW_LSB;
  -- constant CCAM_TD_EVT_TIME_LOW_MSB               : integer := CCAM_EVT_TIME_LOW_MSB;
  -- constant CCAM_TD_EVT_TYPE_LSB                   : integer := CCAM_EVT_TYPE_LSB;
  -- constant CCAM_TD_EVT_TYPE_MSB                   : integer := CCAM_EVT_TYPE_MSB;

  constant CCAM_EVT_V3_TIME_LOW_LSB                  : integer := 0;
  constant CCAM_EVT_V3_TIME_LOW_MSB                  : integer := CCAM_EVT_V3_TIME_LOW_LSB + CCAM_EVT_V3_TIME_LOW_BITS - 1;

  constant CCAM_EVT_V3_TIME_HIGH_LSB                 : integer := 0;
  constant CCAM_EVT_V3_TIME_HIGH_MSB                 : integer := CCAM_EVT_V3_TIME_HIGH_LSB + CCAM_EVT_V3_TIME_HIGH_BITS - 1;

  constant CCAM_V3_TIME_LOW_LSB                      : integer := 0;
  constant CCAM_V3_TIME_LOW_MSB                      : integer := CCAM_V3_TIME_LOW_LSB + CCAM_EVT_V3_TIME_LOW_BITS - 1;
  constant CCAM_V3_TIME_HIGH_LSB                     : integer := CCAM_V3_TIME_LOW_MSB + 1;
  constant CCAM_V3_TIME_HIGH_MSB                     : integer := CCAM_V3_TIME_HIGH_LSB + CCAM_EVT_V3_TIME_HIGH_BITS - 1;

  -- constant CCAM_DISP_LOW_EVT_DISP_LSB             : integer := 0;
  -- constant CCAM_DISP_LOW_EVT_DISP_MSB             : integer := CCAM_DISP_LOW_EVT_DISP_LSB + CCAM_EVT_DISP_BITS - 1;
  -- constant CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB        : integer := CCAM_EVT_TYPE_LSB - 1;
  -- constant CCAM_DISP_LOW_EVT_ORIG_TYPE_LSB        : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB - CCAM_EVT_TYPE_BITS + 1;
  -- constant CCAM_DISP_LOW_EVT_CONT_TYPE_LSB        : integer := CCAM_EVT_TYPE_LSB;
  -- constant CCAM_DISP_LOW_EVT_CONT_TYPE_MSB        : integer := CCAM_EVT_TYPE_MSB;

  -- constant CCAM_DISP_HIGH_EVT_Y_LSB               : integer := CCAM_TD_EVT_Y_LSB;
  -- constant CCAM_DISP_HIGH_EVT_Y_MSB               : integer := CCAM_TD_EVT_Y_MSB;
  -- constant CCAM_DISP_HIGH_EVT_X_LSB               : integer := CCAM_TD_EVT_X_LSB;
  -- constant CCAM_DISP_HIGH_EVT_X_MSB               : integer := CCAM_TD_EVT_X_MSB;
  -- constant CCAM_DISP_HIGH_EVT_TIME_LOW_LSB        : integer := CCAM_EVT_TIME_LOW_LSB;
  -- constant CCAM_DISP_HIGH_EVT_TIME_LOW_MSB        : integer := CCAM_EVT_TIME_LOW_MSB;
  -- constant CCAM_DISP_HIGH_EVT_TYPE_LSB            : integer := CCAM_EVT_TYPE_LSB;
  -- constant CCAM_DISP_HIGH_EVT_TYPE_MSB            : integer := CCAM_EVT_TYPE_MSB;

  -- constant CCAM_DISP_EVT_DISP_LSB                 : integer := CCAM_DISP_LOW_EVT_DISP_LSB;
  -- constant CCAM_DISP_EVT_DISP_MSB                 : integer := CCAM_DISP_LOW_EVT_DISP_MSB;
  -- constant CCAM_DISP_EVT_ORIG_TYPE_MSB            : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_MSB;
  -- constant CCAM_DISP_EVT_ORIG_TYPE_LSB            : integer := CCAM_DISP_LOW_EVT_ORIG_TYPE_LSB;
  -- constant CCAM_DISP_EVT_CONT_TYPE_MSB            : integer := CCAM_DISP_LOW_EVT_CONT_TYPE_MSB;
  -- constant CCAM_DISP_EVT_CONT_TYPE_LSB            : integer := CCAM_DISP_LOW_EVT_CONT_TYPE_LSB;

  -- constant CCAM_DISP_EVT_Y_LSB                    : integer := (CCAM_EVT_DATA_HIGH_LSB);
  -- constant CCAM_DISP_EVT_Y_MSB                    : integer := ((CCAM_DISP_EVT_Y_LSB) + (CCAM_EVT_Y_BITS) - 1);
  -- constant CCAM_DISP_EVT_X_LSB                    : integer := ((CCAM_DISP_EVT_Y_MSB) + 1);
  -- constant CCAM_DISP_EVT_X_MSB                    : integer := ((CCAM_DISP_EVT_X_LSB) + (CCAM_EVT_X_BITS) - 1);
  -- constant CCAM_DISP_EVT_TIME_LOW_LSB             : integer := ((CCAM_DISP_EVT_X_MSB) + 1);
  -- constant CCAM_DISP_EVT_TIME_LOW_MSB             : integer := ((CCAM_DISP_EVT_TIME_LOW_LSB) + (CCAM_EVT_TIME_LOW_BITS) - 1);
  -- constant CCAM_DISP_EVT_TYPE_MSB                 : integer := (CCAM_EVT_DATA_HIGH_MSB);
  -- constant CCAM_DISP_EVT_TYPE_LSB                 : integer := ((CCAM_DISP_EVT_TYPE_MSB) - (CCAM_EVT_TYPE_BITS) + 1);

  -- constant CCAM_OTHER_EVT_SUBTYPE_LSB             : integer := 0;
  -- constant CCAM_OTHER_EVT_SUBTYPE_MSB             : integer := ((CCAM_OTHER_EVT_SUBTYPE_LSB) + (CCAM_EVT_SUBTYPE_BITS) - 1);
  -- constant CCAM_OTHER_EVT_CLASS_LSB               : integer := ((CCAM_OTHER_EVT_SUBTYPE_MSB) + 1);
  -- constant CCAM_OTHER_EVT_CLASS_MSB               : integer := ((CCAM_OTHER_EVT_CLASS_LSB) + (CCAM_OTHER_CLASS_BITS) - 1);
  -- constant CCAM_OTHER_EVT_UNUSED_LSB              : integer := ((CCAM_OTHER_EVT_CLASS_MSB) + 1);
  -- constant CCAM_OTHER_EVT_UNUSED_MSB              : integer := ((CCAM_OTHER_EVT_UNUSED_LSB) + (CCAM_OTHER_UNUSED_BITS) - 1);
  -- constant CCAM_OTHER_EVT_TIME_LOW_LSB            : integer := ((CCAM_OTHER_EVT_UNUSED_MSB) + 1);
  -- constant CCAM_OTHER_EVT_TIME_LOW_MSB            : integer := ((CCAM_OTHER_EVT_TIME_LOW_LSB) + (CCAM_EVT_TIME_LOW_BITS) - 1);

  -- constant CCAM_CONTINUED_EVT_DATA_LSB            : integer := 0;
  -- constant CCAM_CONTINUED_EVT_DATA_MSB            : integer := ((CCAM_CONTINUED_EVT_DATA_LSB) + (CCAM_CONTINUED_EVT_DATA_BITS) - 1);

  -- constant CCAM_SYNC_EVT_Y_LSB                    : integer := 0;
  -- constant CCAM_SYNC_EVT_Y_MSB                    : integer := ((CCAM_SYNC_EVT_Y_LSB) + (CCAM_EVT_Y_BITS) - 1);

  -- -- CCAM2 Event Types
  -- constant EVT_TYPE_BITS                           : positive := 4;
  -- constant TIME_HIGH_EVT_TYPE                      : std_logic_vector(EVT_TYPE_BITS-1 downto 0) := std_logic_vector(to_unsigned(8, EVT_TYPE_BITS));
  -- constant EXT_TRIGGER_EVT_TYPE                    : std_logic_vector(EVT_TYPE_BITS-1 downto 0) := std_logic_vector(to_unsigned(10, EVT_TYPE_BITS));

  -- External Trigger Monitoring Event Field Bit Ranges
  constant CCAM_EVT_V3_EXT_TRIGGER_TYPE_BITS      : positive := CCAM_EVT_V3_TYPE_BITS;
  constant CCAM_EVT_V3_EXT_TRIGGER_ID_BITS        : positive := 4;
  constant CCAM_EVT_V3_EXT_TRIGGER_UNUSED0_BITS   : positive := 7;
  constant CCAM_EVT_V3_EXT_TRIGGER_VALUE_BITS     : positive := 1;

  subtype ccam_evt_v3_data_t                     is std_logic_vector(CCAM_EVT_V3_DATA_BITS-1 downto 0);
  type    ccam_evt_v3_data_vector_t              is array(natural range <>) of ccam_evt_v3_data_t;

  subtype ccam_evt_v3_type_t                     is unsigned(CCAM_EVT_V3_TYPE_BITS-1 downto 0);
  subtype ccam_evt_v3_type_data_t                is std_logic_vector(CCAM_EVT_V3_TYPE_BITS-1 downto 0);
  type    ccam_evt_v3_type_vector_t              is array(natural range <>) of ccam_evt_v3_type_t;

  constant EVT_V3_TD_Y                            : ccam_evt_v3_type_t := to_unsigned( 0, ccam_evt_v3_type_t'length); -- Identifies a TD event and its y coordinate.
  constant EVT_V3_EM_Y                            : ccam_evt_v3_type_t := to_unsigned( 1, ccam_evt_v3_type_t'length); -- Identifies a EM event (aka. APS event) and its y coordinate.)
  constant EVT_V3_X_POS                           : ccam_evt_v3_type_t := to_unsigned( 2, ccam_evt_v3_type_t'length); -- Marks a valid single event and identifies its polarity and X coordinate.
  constant EVT_V3_X_BASE                          : ccam_evt_v3_type_t := to_unsigned( 3, ccam_evt_v3_type_t'length); -- Transmits the base address for a subsequent vector event and identifies its polarity and base X coordinate.
  constant EVT_V3_VECT_12                         : ccam_evt_v3_type_t := to_unsigned( 4, ccam_evt_v3_type_t'length); -- Vector event with 12 valid bits.
  constant EVT_V3_VECT_8                          : ccam_evt_v3_type_t := to_unsigned( 5, ccam_evt_v3_type_t'length); -- Vector event with 8 valid bits.
  constant EVT_V3_TIME_LOW                        : ccam_evt_v3_type_t := to_unsigned( 6, ccam_evt_v3_type_t'length); -- Encodes the lower 12b of the timebase range 11 to 0.
  constant EVT_V3_CONTINUED_4                     : ccam_evt_v3_type_t := to_unsigned( 7, ccam_evt_v3_type_t'length); -- Continued event which can be used to aggregate additional data to previous events.
  constant EVT_V3_TIME_HIGH                       : ccam_evt_v3_type_t := to_unsigned( 8, ccam_evt_v3_type_t'length); -- Encodes the higher portion of the timebase range 23 to 12.
  constant EVT_V3_EXT_TRIGGER                     : ccam_evt_v3_type_t := to_unsigned(10, ccam_evt_v3_type_t'length); -- The External Trigger Event  is transmitted to indicate an edge (change of electrical state) was detected on an external trigger signal.
  constant EVT_V3_IMU_EVT                         : ccam_evt_v3_type_t := to_unsigned(13, ccam_evt_v3_type_t'length); -- IMU Event
  constant EVT_V3_OTHER                           : ccam_evt_v3_type_t := to_unsigned(14, ccam_evt_v3_type_t'length); -- To be used for extensions in the event types
  constant EVT_V3_CONTINUED_12                    : ccam_evt_v3_type_t := to_unsigned(15, ccam_evt_v3_type_t'length); -- Continued event which can be used to aggregate additional data to previous events.

  subtype ccam_evt_v3_time_t                     is unsigned(CCAM_EVT_V3_TIME_BITS-1 downto 0);
  subtype ccam_evt_v3_time_data_t                is std_logic_vector(CCAM_EVT_V3_TIME_BITS-1 downto 0);
  subtype ccam_evt_v3_th_t                       is unsigned(CCAM_EVT_V3_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_v3_th_data_t                  is std_logic_vector(CCAM_EVT_V3_TIME_HIGH_BITS-1 downto 0);
  subtype ccam_evt_v3_tl_t                       is unsigned(CCAM_EVT_V3_TIME_LOW_BITS-1 downto 0);
  subtype ccam_evt_v3_tl_data_t                  is std_logic_vector(CCAM_EVT_V3_TIME_LOW_BITS-1 downto 0);

  subtype ccam_evt_v3_x_t                        is unsigned(CCAM_EVT_V3_X_BITS-1 downto 0);
  subtype ccam_evt_v3_x_data_t                   is std_logic_vector(CCAM_EVT_V3_X_BITS-1 downto 0);
  subtype ccam_evt_v3_y_t                        is unsigned(CCAM_EVT_V3_Y_BITS-1 downto 0);
  subtype ccam_evt_v3_y_data_t                   is std_logic_vector(CCAM_EVT_V3_Y_BITS-1 downto 0);
  subtype ccam_evt_v3_vect_12_valid_t            is std_logic_vector(CCAM_EVT_V3_VECT_12_BITS-1 downto 0);
  subtype ccam_evt_v3_vect_8_valid_t             is std_logic_vector(CCAM_EVT_V3_VECT_8_BITS-1 downto 0);

  subtype ccam_evt_v3_trigger_id_t               is unsigned(CCAM_EVT_V3_EXT_TRIGGER_ID_BITS-1 downto 0);
  subtype ccam_evt_v3_trigger_unused0_t          is std_logic_vector(CCAM_EVT_V3_EXT_TRIGGER_UNUSED0_BITS-1 downto 0);
  subtype ccam_evt_v3_trigger_value_t            is std_logic;

  subtype ccam_evt_v3_imu_data_t                 is std_logic_vector(CCAM_EVT_V3_IMU_DATA_BITS-1 downto 0);

  subtype ccam_evt_v3_subtype_t                  is unsigned(CCAM_EVT_V3_OTHER_SUBTYPE_BITS-1 downto 0);
  type    ccam_evt_v3_subtype_vector_t           is array(natural range <>) of ccam_evt_v3_subtype_t;
  subtype ccam_evt_v3_subtype_data_t             is std_logic_vector(CCAM_EVT_V3_OTHER_SUBTYPE_BITS-1 downto 0);

  subtype ccam_evt_v3_continued_4_data_t         is std_logic_vector(CCAM_EVT_V3_CONTINUED_4_DATA_BITS-1 downto 0);

  subtype ccam_evt_v3_continued_12_data_t        is std_logic_vector(CCAM_EVT_V3_CONTINUED_12_DATA_BITS-1 downto 0);


  -- Monitoring Events Subtypes as Listed in:
  -- http://confluence.chronocam.com/display/SYSDEV/System+Monitoring+Events+2.0
  constant V3_MASTER_SYSTEM_TEMPERATURE           : ccam_evt_v3_subtype_t := x"000"; -- Monitors current FPGA system temperature value periodically. Implemented as of version 1.1.1
  constant V3_MASTER_SYSTEM_VOLTAGE               : ccam_evt_v3_subtype_t := x"001"; -- Monitors current FPGA power supply voltage levels periodically.   Implemented as of version 1.1.1
  constant V3_MASTER_SYSTEM_IN_EVENT_COUNT        : ccam_evt_v3_subtype_t := x"002"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant V3_MASTER_SYSTEM_IN_EVENT_SEQ_ERROR    : ccam_evt_v3_subtype_t := x"003"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant V3_MASTER_SYSTEM_IN_EVENT_TIME_ERROR   : ccam_evt_v3_subtype_t := x"004"; -- Alerts of an event timestamp disruption, if enabled.
  constant V3_MASTER_SYSTEM_OUT_EVENT_COUNT       : ccam_evt_v3_subtype_t := x"005"; -- Monitors the number of events of each type received by the FPGA on a given time period.
  constant V3_MASTER_SYSTEM_OUT_EVENT_SEQ_ERROR   : ccam_evt_v3_subtype_t := x"006"; -- Alerts of a sequence rupture, if sequence checking is enabled.
  constant V3_MASTER_SYSTEM_OUT_EVENT_TIME_ERROR  : ccam_evt_v3_subtype_t := x"007"; -- Alerts of an event timestamp disruption, if enabled.
  constant V3_MASTER_ATIS_BIAS_PROG_ERROR         : ccam_evt_v3_subtype_t := x"008"; -- Alerts of a bias programming error.
  constant V3_MASTER_ATIS_ILLUMINATION            : ccam_evt_v3_subtype_t := x"009"; -- Monitors the global illumination periodically.    Implemented as of version 1.1.1
  constant V3_MASTER_ATIS_TD_IDLE_TIME            : ccam_evt_v3_subtype_t := x"00A"; -- Monitors the time interval between two TD events, if over a given threshold.    Implemented as of version 1.1.1
  constant V3_MASTER_ATIS_APS_IDLE_TIME           : ccam_evt_v3_subtype_t := x"00B"; -- Monitors the time interval between two APS events, if over a given threshold.   Implemented as of version 1.1.1
  constant V3_MASTER_ATIS_TD_IDLE_TIMEOUT         : ccam_evt_v3_subtype_t := x"00C"; -- Alerts if no TD event has been received for a set amount of time.   Implemented as of version 1.1.1
  constant V3_MASTER_ATIS_APS_IDLE_TIMEOUT        : ccam_evt_v3_subtype_t := x"00D"; -- Alerts if no APS event has been received for a set amount of time.    Implemented as of version 1.1.1
  constant V3_MASTER_ATIS_REFRACTORY_CLOCK        : ccam_evt_v3_subtype_t := x"00E"; -- Monitors the refractory clock period.
  constant V3_EPOCH_START                         : ccam_evt_v3_subtype_t := x"010";
  constant V3_EPOCH_END                           : ccam_evt_v3_subtype_t := x"011";
  constant V3_EPOCH_LINE_START                    : ccam_evt_v3_subtype_t := x"012";
  constant V3_EPOCH_LINE_END                      : ccam_evt_v3_subtype_t := x"013";
  constant V3_MASTER_IN_TD_EVENT_COUNT            : ccam_evt_v3_subtype_t := x"014"; -- Monitors the number of incoming TD events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.
  constant V3_MASTER_IN_APS_EVENT_COUNT           : ccam_evt_v3_subtype_t := x"015"; -- Monitors the number of incoming APS events from the sensor during a given period of time. This number represents the totality of raw sensor events without any drops.constant V3_MASTER_START_OF_FRAME              : ccam_evt_v3_subtype_t := x"018"; -- Marks the start of a Frame in MIPI transmissions.   To be implemented in Moorea
  constant V3_MASTER_RATE_CONTROL_TD_EVENT_COUNT  : ccam_evt_v3_subtype_t := x"016"; -- Monitors the number of TD events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.constant V3_MASTER_END_OF_FRAME                : ccam_evt_v3_subtype_t := x"019"; -- Marks the end of a Frame in MIPI transmissions.   To be implemented in Moorea
  constant V3_MASTER_RATE_CONTROL_APS_EVENT_COUNT : ccam_evt_v3_subtype_t := x"017"; -- Monitors the number of APS events that are output by the Event Rate Control block at a given period of time. Some events might have been dropped at this point.constant V3_MASTER_SYSTEM_TB_END_OF_TASK       : ccam_evt_v3_subtype_t := x"0FD"; -- Marks the end of a Test Task
  constant V3_MASTER_START_OF_FRAME               : ccam_evt_v3_subtype_t := x"018"; -- Marks the start of a Frame in MIPI transmissions.
  constant V3_MASTER_END_OF_FRAME                 : ccam_evt_v3_subtype_t := x"019"; -- Marks the end of a Frame in MIPI transmissions.
  constant V3_MASTER_MIPI_PADDING                 : ccam_evt_v3_subtype_t := x"01A"; -- Marks the end of a Frame in MIPI transmissions.   To be implemented in Moorea
  constant V3_MASTER_SYSTEM_TB_END_OF_TASK        : ccam_evt_v3_subtype_t := x"0FD"; -- Marks the end of a Test Task
  constant V3_MASTER_USB_PACKET_INFO              : ccam_evt_v3_subtype_t := x"0FE"; -- Software Generated Event with USB Packet Info (Arrival Time, Size, etc.)    Software implemented.
  constant V3_MASTER_DUMMY_EVENT                  : ccam_evt_v3_subtype_t := x"0FF"; -- General Purpose Dummy Event.    To be implemented in Moorea
  constant V3_MASTER_DATA_INTEGRITY_MARKER        : ccam_evt_v3_subtype_t := x"314"; -- Data integrity marker
  constant V3_MASTER_TL_DROP_EVENT                : ccam_evt_v3_subtype_t := x"ED6"; -- Alerts of events dropped due to a previous corrupted TIME LOW event
  constant V3_MASTER_TH_DROP_EVENT                : ccam_evt_v3_subtype_t := x"ED8"; -- Alerts of events dropped due to a previous corrupted TIME HIGH event
  constant V3_MASTER_EVT_DROP_EVENT               : ccam_evt_v3_subtype_t := x"EDA"; -- Alerts of events dropped due to a previous corrupted TIME HIGH event

  -- subtype ccam_system_id_t is std_logic_vector(1 downto 0);
  -- constant CCAM_LEFT_SYSTEM_ID                    : ccam_system_id_t := std_logic_vector(to_unsigned(0, ccam_system_id_t'length));
  -- constant CCAM_RIGHT_SYSTEM_ID                   : ccam_system_id_t := std_logic_vector(to_unsigned(1, ccam_system_id_t'length));
  -- constant CCAM_STEREO_SYSTEM_ID                  : ccam_system_id_t := std_logic_vector(to_unsigned(2, ccam_system_id_t'length));

  type ccam_evt_v3_t is record
    type_f     : ccam_evt_v3_type_t;
    reserved_f : unsigned(CCAM_EVT_V3_RESERVED_MSB downto CCAM_EVT_V3_RESERVED_LSB);
  end record ccam_evt_v3_t;

  type ccam_evt_v3_td_y_t is record
    type_f      : ccam_evt_v3_type_t;
    system_t_f  : std_logic;
    y_f         : ccam_evt_v3_y_t;
  end record ccam_evt_v3_td_y_t;

  type ccam_evt_v3_em_y_t is record
    type_f      : ccam_evt_v3_type_t;
    system_t_f  : std_logic;
    y_f         : ccam_evt_v3_y_t;
  end record ccam_evt_v3_em_y_t;

  type ccam_evt_v3_x_pos_t is record
    type_f : ccam_evt_v3_type_t;
    pol_f  : std_logic;
    x_f    : ccam_evt_v3_x_t;
  end record ccam_evt_v3_x_pos_t;

  type ccam_evt_v3_x_base_t is record
    type_f : ccam_evt_v3_type_t;
    pol_f  : std_logic;
    x_f    : ccam_evt_v3_x_t;
  end record ccam_evt_v3_x_base_t;

  type ccam_evt_v3_vect_12_t is record
    type_f    : ccam_evt_v3_type_t;
    valid_f   : ccam_evt_v3_vect_12_valid_t;
  end record ccam_evt_v3_vect_12_t;

  type ccam_evt_v3_vect_8_t is record
    type_f    : ccam_evt_v3_type_t;
    unused_f  : std_logic_vector(CCAM_EVT_V3_VECT_8_UNUSED_BITS-1 downto 0);
    valid_f   : ccam_evt_v3_vect_8_valid_t;
  end record ccam_evt_v3_vect_8_t;

  type ccam_evt_v3_tl_evt_t is record
    type_f     : ccam_evt_v3_type_t;
    time_low_f : ccam_evt_v3_tl_t;
  end record ccam_evt_v3_tl_evt_t;

  type ccam_evt_v3_continued_4_t is record
    type_f    : ccam_evt_v3_type_t;
    unused_f  : std_logic_vector(CCAM_EVT_V3_CONTINUED_4_UNUSED_BITS-1 downto 0);
    data_f    : ccam_evt_v3_continued_4_data_t;
  end record ccam_evt_v3_continued_4_t;

  type ccam_evt_v3_th_evt_t is record
    type_f        : ccam_evt_v3_type_t;
    time_high_f   : ccam_evt_v3_th_t;
  end record ccam_evt_v3_th_evt_t;

  type ccam_evt_v3_ext_trigger_t is record
    type_f    : ccam_evt_v3_type_t;
    id_f      : ccam_evt_v3_trigger_id_t;
    unused_f  : std_logic_vector(CCAM_EVT_V3_EXT_TRIGGER_UNUSED0_BITS-1 downto 0);
    value_f   : std_logic;
  end record ccam_evt_v3_ext_trigger_t;

  type ccam_evt_v3_imu_t is record
    type_f : ccam_evt_v3_type_t;
    data_f : ccam_evt_v3_imu_data_t;
  end record ccam_evt_v3_imu_t;

  type ccam_evt_v3_other_t is record
    type_f    : ccam_evt_v3_type_t;
    subtype_f : ccam_evt_v3_subtype_t;
  end record ccam_evt_v3_other_t;

  type ccam_evt_v3_continued_12_t is record
    type_f    : ccam_evt_v3_type_t;
    data_f    : ccam_evt_v3_continued_12_data_t;
  end record ccam_evt_v3_continued_12_t;

  function ccam_evt_v3_to_ccam_evt_data(evt_v: ccam_evt_v3_t) return ccam_evt_data_t;
  function ccam_evt_v3_data_to_ccam_evt_data(evt_v: ccam_evt_v3_data_t) return ccam_evt_data_t;

  function ccam_evt_data_to_ccam_evt_v3(evt_data_v: ccam_evt_data_t) return ccam_evt_v3_t;
  function ccam_evt_data_to_ccam_evt_v3_data(evt_data_v: ccam_evt_data_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_t;
  function to_ccam_evt_v3_data(evt_v: ccam_evt_v3_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_td_y(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_td_y_t;
  function to_ccam_evt_v3_data(td_y_v: ccam_evt_v3_td_y_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_em_y(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_em_y_t;
  function to_ccam_evt_v3_data(em_y_v: ccam_evt_v3_em_y_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_x_pos(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_x_pos_t;
  function to_ccam_evt_v3_data(x_pos_v : ccam_evt_v3_x_pos_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_x_base(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_x_base_t;
  function to_ccam_evt_v3_data(x_base_v : ccam_evt_v3_x_base_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_vect_12(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_vect_12_t;
  function to_ccam_evt_v3_data(vect_12_v : ccam_evt_v3_vect_12_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_vect_8(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_vect_8_t;
  function to_ccam_evt_v3_data(vect_8_v : ccam_evt_v3_vect_8_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_tl(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_tl_evt_t;
  function to_ccam_evt_v3_data(time_low_v : ccam_evt_v3_tl_evt_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_continued_4(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_continued_4_t;
  function to_ccam_evt_v3_data(continued_4_v : ccam_evt_v3_continued_4_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_th(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_th_evt_t;
  function to_ccam_evt_v3_data(time_high_v : ccam_evt_v3_th_evt_t) return ccam_evt_v3_data_t;
  function to_ccam_evt_data(time_high_v : ccam_evt_v3_th_evt_t) return ccam_evt_data_t;

  function to_ccam_evt_v3_ext_trigger(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_ext_trigger_t;
  function to_ccam_evt_v3_data(ext_trigger_v: ccam_evt_v3_ext_trigger_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_imu(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_imu_t;
  function to_ccam_evt_v3_data(imu_evt_v : ccam_evt_v3_imu_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_other(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_other_t;
  function to_ccam_evt_v3_data(other_v : ccam_evt_v3_other_t) return ccam_evt_v3_data_t;

  function to_ccam_evt_v3_continued_12(evt_data_v : ccam_evt_v3_data_t) return ccam_evt_v3_continued_12_t;
  function to_ccam_evt_v3_data(continued_12_v : ccam_evt_v3_continued_12_t) return ccam_evt_v3_data_t;


  -- Event Interface Marker Flag Number
  constant CCAM_EVT_V3_MARKER_NUM       : positive := 4;

  subtype ccam_evt_v3_marker_t         is std_logic_vector(CCAM_EVT_V3_MARKER_NUM-1 downto 0);

  function evt_v3_marker_encode(data : ccam_evt_v3_data_t) return ccam_evt_v3_marker_t;

end ccam_evt_types_v3;

package body ccam_evt_types_v3 is

  ----------------
  -- Generic Event

  function ccam_evt_v3_to_ccam_evt_data(evt_v: ccam_evt_v3_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => '0');
    i_v := 0;
    pack(evt_data_v, i_v, evt_v.reserved_f);
    pack(evt_data_v, i_v, evt_v.type_f);
    return evt_data_v;
  end function ccam_evt_v3_to_ccam_evt_data;

  function ccam_evt_v3_data_to_ccam_evt_data(evt_v: ccam_evt_v3_data_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v              := (others => '0');
    evt_data_v(evt_v'range) := evt_v;
    return evt_data_v;
  end function ccam_evt_v3_data_to_ccam_evt_data;

  function ccam_evt_data_to_ccam_evt_v3(evt_data_v: ccam_evt_data_t) return ccam_evt_v3_t is
    variable evt_v : ccam_evt_v3_t;
    variable i_v   : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, evt_v.reserved_f);
    unpack(evt_data_v, i_v, evt_v.type_f);
    return evt_v;
  end function ccam_evt_data_to_ccam_evt_v3;

  function ccam_evt_data_to_ccam_evt_v3_data(evt_data_v: ccam_evt_data_t) return ccam_evt_v3_data_t is
    variable evt_v3_data_v : ccam_evt_v3_data_t;
    variable i_v           : integer;
  begin
    evt_v3_data_v := evt_data_v(evt_v3_data_v'range);
    return evt_v3_data_v;
  end function ccam_evt_data_to_ccam_evt_v3_data;

  function to_ccam_evt_v3(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_t is
    variable evt_v : ccam_evt_v3_t;
    variable i_v   : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, evt_v.reserved_f);
    unpack(evt_data_v, i_v, evt_v.type_f);
    return evt_v;
  end function to_ccam_evt_v3;

  function to_ccam_evt_v3_data(evt_v: ccam_evt_v3_t) return ccam_evt_v3_data_t is
    variable evt_v3_data_v : ccam_evt_v3_data_t;
    variable i_v           : integer;
  begin
    evt_v3_data_v := (others => '0');
    i_v := 0;
    pack(evt_v3_data_v, i_v, evt_v.reserved_f);
    pack(evt_v3_data_v, i_v, evt_v.type_f);
    return evt_v3_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- TD Y

  function to_ccam_evt_v3_td_y(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_td_y_t is
    variable td_y_v   : ccam_evt_v3_td_y_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, td_y_v.y_f);
    unpack(evt_data_v, i_v, td_y_v.system_t_f);
    unpack(evt_data_v, i_v, td_y_v.type_f);
    return td_y_v;
  end function to_ccam_evt_v3_td_y;

  function to_ccam_evt_v3_data(td_y_v : ccam_evt_v3_td_y_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, td_y_v.y_f);
    pack(evt_data_v, i_v, td_y_v.system_t_f);
    pack(evt_data_v, i_v, td_y_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- EM Y

  function to_ccam_evt_v3_em_y(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_em_y_t is
    variable em_y_v   : ccam_evt_v3_em_y_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, em_y_v.y_f);
    unpack(evt_data_v, i_v, em_y_v.system_t_f);
    unpack(evt_data_v, i_v, em_y_v.type_f);
    return em_y_v;
  end function to_ccam_evt_v3_em_y;

  function to_ccam_evt_v3_data(em_y_v : ccam_evt_v3_em_y_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, em_y_v.y_f);
    pack(evt_data_v, i_v, em_y_v.system_t_f);
    pack(evt_data_v, i_v, em_y_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- X POS

  function to_ccam_evt_v3_x_pos(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_x_pos_t is
    variable x_pos_v   : ccam_evt_v3_x_pos_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, x_pos_v.x_f);
    unpack(evt_data_v, i_v, x_pos_v.pol_f);
    unpack(evt_data_v, i_v, x_pos_v.type_f);
    return x_pos_v;
  end function to_ccam_evt_v3_x_pos;

  function to_ccam_evt_v3_data(x_pos_v : ccam_evt_v3_x_pos_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, x_pos_v.x_f);
    pack(evt_data_v, i_v, x_pos_v.pol_f);
    pack(evt_data_v, i_v, x_pos_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- X Base

  function to_ccam_evt_v3_x_base(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_x_base_t is
    variable x_base_v   : ccam_evt_v3_x_base_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, x_base_v.x_f);
    unpack(evt_data_v, i_v, x_base_v.pol_f);
    unpack(evt_data_v, i_v, x_base_v.type_f);
    return x_base_v;
  end function to_ccam_evt_v3_x_base;

  function to_ccam_evt_v3_data(x_base_v : ccam_evt_v3_x_base_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, x_base_v.x_f);
    pack(evt_data_v, i_v, x_base_v.pol_f);
    pack(evt_data_v, i_v, x_base_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- VECT 12

  function to_ccam_evt_v3_vect_12(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_vect_12_t is
    variable vect_12_v   : ccam_evt_v3_vect_12_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, vect_12_v.valid_f);
    unpack(evt_data_v, i_v, vect_12_v.type_f);
    return vect_12_v;
  end function to_ccam_evt_v3_vect_12;

  function to_ccam_evt_v3_data(vect_12_v : ccam_evt_v3_vect_12_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, vect_12_v.valid_f);
    pack(evt_data_v, i_v, vect_12_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- VECT 8

  function to_ccam_evt_v3_vect_8(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_vect_8_t is
    variable vect_8_v   : ccam_evt_v3_vect_8_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, vect_8_v.valid_f);
    unpack(evt_data_v, i_v, vect_8_v.unused_f);
    unpack(evt_data_v, i_v, vect_8_v.type_f);
    return vect_8_v;
  end function to_ccam_evt_v3_vect_8;

  function to_ccam_evt_v3_data(vect_8_v : ccam_evt_v3_vect_8_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, vect_8_v.valid_f);
    pack(evt_data_v, i_v, vect_8_v.unused_f);
    pack(evt_data_v, i_v, vect_8_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- Time Low

  function to_ccam_evt_v3_tl(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_tl_evt_t is
    variable time_low_v : ccam_evt_v3_tl_evt_t;
    variable i_v        : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, time_low_v.time_low_f);
    unpack(evt_data_v, i_v, time_low_v.type_f);
    return time_low_v;
  end function to_ccam_evt_v3_tl;

  function to_ccam_evt_v3_data(time_low_v : ccam_evt_v3_tl_evt_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, time_low_v.time_low_f);
    pack(evt_data_v, i_v, time_low_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  ---------------
  -- Continued 4

  function to_ccam_evt_v3_continued_4(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_continued_4_t is
    variable continued_4_v   : ccam_evt_v3_continued_4_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, continued_4_v.data_f);
    unpack(evt_data_v, i_v, continued_4_v.unused_f);
    unpack(evt_data_v, i_v, continued_4_v.type_f);
    return continued_4_v;
  end function to_ccam_evt_v3_continued_4;

  function to_ccam_evt_v3_data(continued_4_v : ccam_evt_v3_continued_4_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, continued_4_v.data_f);
    pack(evt_data_v, i_v, continued_4_v.unused_f);
    pack(evt_data_v, i_v, continued_4_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -------------
  -- Time High

  function to_ccam_evt_v3_th(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_th_evt_t is
    variable time_high_v : ccam_evt_v3_th_evt_t;
    variable i_v         : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, time_high_v.time_high_f);
    unpack(evt_data_v, i_v, time_high_v.type_f);
    return time_high_v;
  end function to_ccam_evt_v3_th;

  function to_ccam_evt_v3_data(time_high_v : ccam_evt_v3_th_evt_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, time_high_v.time_high_f);
    pack(evt_data_v, i_v, time_high_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;

  function to_ccam_evt_data(time_high_v : ccam_evt_v3_th_evt_t) return ccam_evt_data_t is
    variable evt_data_v : ccam_evt_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => '0');
    i_v := 0;
    pack(evt_data_v, i_v, time_high_v.time_high_f);
    pack(evt_data_v, i_v, time_high_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_data;


  ----------------
  -- Ext Trigger

  function to_ccam_evt_v3_ext_trigger(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_ext_trigger_t is
    variable ext_trigger_v   : ccam_evt_v3_ext_trigger_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, ext_trigger_v.value_f);
    unpack(evt_data_v, i_v, ext_trigger_v.unused_f);
    unpack(evt_data_v, i_v, ext_trigger_v.id_f);
    unpack(evt_data_v, i_v, ext_trigger_v.type_f);
    return ext_trigger_v;
  end function to_ccam_evt_v3_ext_trigger;

  function to_ccam_evt_v3_data(ext_trigger_v : ccam_evt_v3_ext_trigger_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, ext_trigger_v.value_f);
    pack(evt_data_v, i_v, ext_trigger_v.unused_f);
    pack(evt_data_v, i_v, ext_trigger_v.id_f);
    pack(evt_data_v, i_v, ext_trigger_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  ------------
  -- IMU Event

  function to_ccam_evt_v3_imu(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_imu_t is
    variable imu_evt_v : ccam_evt_v3_imu_t;
    variable i_v       : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, imu_evt_v.data_f);
    unpack(evt_data_v, i_v, imu_evt_v.type_f);
    return imu_evt_v;
  end function to_ccam_evt_v3_imu;

  function to_ccam_evt_v3_data(imu_evt_v : ccam_evt_v3_imu_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, imu_evt_v.data_f);
    pack(evt_data_v, i_v, imu_evt_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  -----------
  -- Other

  function to_ccam_evt_v3_other(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_other_t is
    variable other_v   : ccam_evt_v3_other_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, other_v.subtype_f);
    unpack(evt_data_v, i_v, other_v.type_f);
    return other_v;
  end function to_ccam_evt_v3_other;

  function to_ccam_evt_v3_data(other_v : ccam_evt_v3_other_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, other_v.subtype_f);
    pack(evt_data_v, i_v, other_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  ----------------
  -- Continued 12

  function to_ccam_evt_v3_continued_12(evt_data_v: ccam_evt_v3_data_t) return ccam_evt_v3_continued_12_t is
    variable continued_12_v   : ccam_evt_v3_continued_12_t;
    variable i_v      : integer;
  begin
    i_v := 0;
    unpack(evt_data_v, i_v, continued_12_v.data_f);
    unpack(evt_data_v, i_v, continued_12_v.type_f);
    return continued_12_v;
  end function to_ccam_evt_v3_continued_12;

  function to_ccam_evt_v3_data(continued_12_v : ccam_evt_v3_continued_12_t) return ccam_evt_v3_data_t is
    variable evt_data_v : ccam_evt_v3_data_t;
    variable i_v        : integer;
  begin
    evt_data_v := (others => 'U');
    i_v := 0;
    pack(evt_data_v, i_v, continued_12_v.data_f);
    pack(evt_data_v, i_v, continued_12_v.type_f);
    return evt_data_v;
  end function to_ccam_evt_v3_data;


  ------------------------------------------
  -- Encode the Marker for different Events
  function evt_v3_marker_encode(data : ccam_evt_v3_data_t) return ccam_evt_v3_marker_t is
    variable evt_td_y   : ccam_evt_v3_td_y_t    := to_ccam_evt_v3_td_y(data);
    variable evt_em_y   : ccam_evt_v3_em_y_t    := to_ccam_evt_v3_em_y(data);
    variable evt_other  : ccam_evt_v3_other_t   := to_ccam_evt_v3_other(data);
    variable marker     : ccam_evt_v3_marker_t  := (others => '0');
  begin

    case evt_td_y.type_f is
      when EVT_V3_TD_Y | EVT_V3_EM_Y | EVT_V3_X_POS | EVT_V3_X_BASE | EVT_V3_VECT_12 | EVT_V3_VECT_8 =>
        marker(0)   := '1';
      when EVT_V3_EXT_TRIGGER =>
        marker(1)   := '1';
      when EVT_V3_IMU_EVT =>
        marker(2)   := '1';
      when EVT_V3_TIME_LOW | EVT_V3_TIME_HIGH =>
        marker      := (others => '1');
      when EVT_V3_OTHER =>
        case evt_other.subtype_f is
          when V3_MASTER_SYSTEM_TB_END_OF_TASK =>
            marker := (others => '1');
          -- Need to add other subtypes
          when others =>
            marker(3) := '1';
        end case;
      -- Other types use last flag
      when others =>
        marker      := (others => '0');
    end case;

    return marker;

  end function evt_v3_marker_encode;



end ccam_evt_types_v3;
