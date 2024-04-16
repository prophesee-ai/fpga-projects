----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Long XU (lxu@chronocam.com)
--
-- Create Date:    juin 30, 2017
-- Design Name:    evt_verification_pkg
-- Module Name:    evt_verification_pkg
-- Project Name:   evt_verification_pkg
-- Target Devices:
-- Tool versions:  Xilinx Vivado 2016.4
-- Description:
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

use work.ccam_evt_types.all;



package evt_verification_pkg is

  signal      evt_verification_time_base_s        : ccam_evt_time_data_t;
  signal      evt_verification_time_high_sync_s   : std_logic;

  signal      evt_verification_time_base_enable_s : std_logic;

  signal      evt_verification_time_base_halt_s   : std_logic := '0';

  type        ccam_evt_type_array_t               is array (natural range<>) of ccam_evt_type_t;

end package evt_verification_pkg;



