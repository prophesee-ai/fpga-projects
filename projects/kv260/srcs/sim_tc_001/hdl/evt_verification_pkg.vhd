-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

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



