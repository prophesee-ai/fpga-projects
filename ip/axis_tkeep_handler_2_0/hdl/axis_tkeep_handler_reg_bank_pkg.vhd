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

---------------------------------------
-- AXIS TKEEP HANDLER Register Bank Package
package axis_tkeep_handler_reg_bank_pkg is

  --------------------------------------
  -- Global Register Bank Definitions --
  --------------------------------------

  constant AXIL_ADDR_WIDTH              : integer := 32;

  -------------------------------------
  -- Register and Fields Definitions --
  -------------------------------------

  -- CONTROL Register
  constant CONTROL_ADDR                 : std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, AXIL_ADDR_WIDTH));
  constant CONTROL_ENABLE_WIDTH         : natural := 1;
  constant CONTROL_ENABLE_MSB           : natural := 0;
  constant CONTROL_ENABLE_LSB           : natural := 0;
  constant CONTROL_ENABLE_DEFAULT       : std_logic_vector(CONTROL_ENABLE_WIDTH-1 downto 0) := "0";
  constant CONTROL_GLOBAL_RESET_WIDTH   : natural := 1;
  constant CONTROL_GLOBAL_RESET_MSB     : natural := 1;
  constant CONTROL_GLOBAL_RESET_LSB     : natural := 1;
  constant CONTROL_GLOBAL_RESET_DEFAULT : std_logic_vector(CONTROL_GLOBAL_RESET_WIDTH-1 downto 0) := "0";
  constant CONTROL_CLEAR_WIDTH          : natural := 1;
  constant CONTROL_CLEAR_MSB            : natural := 2;
  constant CONTROL_CLEAR_LSB            : natural := 2;
  constant CONTROL_CLEAR_DEFAULT        : std_logic_vector(CONTROL_CLEAR_WIDTH-1 downto 0) := "0";
  -- CONFIG Register
  constant CONFIG_ADDR                  : std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000004#, AXIL_ADDR_WIDTH));
  constant CONFIG_BYPASS_WIDTH          : natural := 1;
  constant CONFIG_BYPASS_MSB            : natural := 0;
  constant CONFIG_BYPASS_LSB            : natural := 0;
  constant CONFIG_BYPASS_DEFAULT        : std_logic_vector(CONFIG_BYPASS_WIDTH-1 downto 0) := "0";
  constant CONFIG_RESERVED_WIDTH        : natural := 1;
  constant CONFIG_RESERVED_MSB          : natural := 1;
  constant CONFIG_RESERVED_LSB          : natural := 1;
  constant CONFIG_WORD_ORDER_WIDTH      : natural := 1;
  constant CONFIG_WORD_ORDER_MSB        : natural := 2;
  constant CONFIG_WORD_ORDER_LSB        : natural := 2;
  constant CONFIG_WORD_ORDER_DEFAULT    : std_logic_vector(CONFIG_WORD_ORDER_WIDTH-1 downto 0) := "0";
  -- VERSION Register
  constant VERSION_ADDR                 : std_logic_vector(AXIL_ADDR_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000010#, AXIL_ADDR_WIDTH));
  constant VERSION_MINOR_WIDTH          : natural := 16;
  constant VERSION_MINOR_MSB            : natural := 15;
  constant VERSION_MINOR_LSB            : natural := 0;
  constant VERSION_MAJOR_WIDTH          : natural := 16;
  constant VERSION_MAJOR_MSB            : natural := 31;
  constant VERSION_MAJOR_LSB            : natural := 16;

end axis_tkeep_handler_reg_bank_pkg;

---------------------
-- Empty Package Body
package body axis_tkeep_handler_reg_bank_pkg is
end package body;
