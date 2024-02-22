----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Vitor Schwambach (vschwambach@prophesee.ai)
--
-- Create Date:    Sep. 28, 2018
-- Design Name:    ccam_evt_formats
-- Module Name:    ccam_evt_formats
-- Project Name:   
-- Target Devices: 
-- Tool versions:  
-- Description:    Package for global event type definitions.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_utils.all;


---------------------------------------------
-- Package for global event type definitions.
package ccam_evt_formats is

  subtype evt_format_t      is unsigned(1 downto 0);
  subtype evt_format_data_t is std_logic_vector(1 downto 0);

  type evt_format_array_t       is array(natural range <>) of evt_format_t;
  type evt_format_data_array_t  is array(natural range <>) of evt_format_data_t;
  
  function to_evt_format(format_p : integer) return evt_format_t;
  function to_evt_format(format_p : evt_format_data_t) return evt_format_t;
  
  function to_evt_format_data(format_p : integer) return evt_format_data_t;
  function to_evt_format_data(format_p : evt_format_t) return evt_format_data_t;

  constant RAW_DAT_FORMAT : evt_format_t := to_evt_format(0);
  constant EVT_FORMAT_1_0 : evt_format_t := to_evt_format(1);
  constant EVT_FORMAT_2_0 : evt_format_t := to_evt_format(2);
  constant EVT_FORMAT_3_0 : evt_format_t := to_evt_format(3);

  constant RAW_DAT_FORMAT_DATA : evt_format_data_t := to_evt_format_data(RAW_DAT_FORMAT);
  constant EVT_FORMAT_DATA_1_0 : evt_format_data_t := to_evt_format_data(EVT_FORMAT_1_0);
  constant EVT_FORMAT_DATA_2_0 : evt_format_data_t := to_evt_format_data(EVT_FORMAT_2_0);
  constant EVT_FORMAT_DATA_3_0 : evt_format_data_t := to_evt_format_data(EVT_FORMAT_3_0);
  
end ccam_evt_formats;

package body ccam_evt_formats is

  function to_evt_format(format_p : integer) return evt_format_t is
    variable format_v : evt_format_t;
  begin
    format_v := to_unsigned(format_p, evt_format_t'length);
  	return format_v;
  end function to_evt_format;

  function to_evt_format(format_p : evt_format_data_t) return evt_format_t is
    variable format_v : evt_format_t;
  begin
    format_v := unsigned(format_p);
  	return format_v;
  end function to_evt_format;

  function to_evt_format_data(format_p : integer) return evt_format_data_t is
    variable format_v : evt_format_data_t;
  begin
    format_v := std_logic_vector(to_unsigned(format_p, evt_format_data_t'length));
  	return format_v;
  end function to_evt_format_data;

  function to_evt_format_data(format_p : evt_format_t) return evt_format_data_t is
    variable format_v : evt_format_data_t;
  begin
    format_v := std_logic_vector(format_p);
  	return format_v;
  end function to_evt_format_data;

end ccam_evt_formats;
