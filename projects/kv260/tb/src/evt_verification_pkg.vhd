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



