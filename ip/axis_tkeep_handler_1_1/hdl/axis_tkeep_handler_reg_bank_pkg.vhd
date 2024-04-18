-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


---------------------------------------
-- AXIS TKEEP HANDLER Register Bank Package
package axis_tkeep_handler_reg_bank_pkg is


  --------------------------------------
  -- Global Register Bank Definitions --
  --------------------------------------

  constant REGISTER_BANK_NAME                                 : string     := "AXIS_TKEEP_HANDLER";
  constant AXIS_TKEEP_HANDLER_BASE_ADDR                       : natural    := 16#00000000#;
  constant AXIS_TKEEP_HANDLER_LAST_ADDR                       : natural    := 16#0000000B#;
  constant AXIS_TKEEP_HANDLER_SIZE                            : natural    := 16#00000010#;



  -------------------------------------
  -- Register and Fields Definitions --
  -------------------------------------
  -- VERSION Register
  constant VERSION_ADDR                                       : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, 32));
  constant VERSION_WIDTH                                      : natural    := 32;
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
  -- CONFIG Register
  constant CONFIG_ADDR                                        : std_logic_vector(32-1 downto 0) := std_logic_vector(to_unsigned(16#00000008#, 32));
  constant CONFIG_WIDTH                                       : natural    := 32;
  constant CONFIG_DEFAULT                                     : std_logic_vector(CONFIG_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(16#00000000#, CONFIG_WIDTH));
  constant CONFIG_WORD_ORDER_WIDTH                            : natural    := 1;
  constant CONFIG_WORD_ORDER_MSB                              : natural    := 0;
  constant CONFIG_WORD_ORDER_LSB                              : natural    := 0;
  constant CONFIG_WORD_ORDER_DEFAULT                          : std_logic_vector(CONFIG_WORD_ORDER_WIDTH-1 downto 0) := "0";


end axis_tkeep_handler_reg_bank_pkg;


---------------------
-- Empty Package Body
package body axis_tkeep_handler_reg_bank_pkg is
end package body;
