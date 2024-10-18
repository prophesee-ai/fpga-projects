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
use     ieee.std_logic_1164.all;


--------------------------------------------------------------------
-- Mixing Low Power and High Speed MIPI interface to be able to
-- connect the MIPI TX to a MIPI RX core
entity mipi_tx_lane_hs_lp_mixer is
  port (
    -- Input MIPI CSI2 TX Interface from mipi_host_if
    in_mipi_tx_hs_clk_i   : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    in_mipi_tx_hs_d0_i    : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    in_mipi_tx_hs_d1_i    : in    std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    in_mipi_tx_lp_clk_io  : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    in_mipi_tx_lp_d0_io   : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    in_mipi_tx_lp_d1_io   : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)

    -- Output MIPI CSI2 TX Interface with High Speed interface only (LP lines are don't care)
    out_mipi_tx_hs_clk_o  : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    out_mipi_tx_hs_d0_o   : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    out_mipi_tx_hs_d1_o   : out   std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    out_mipi_tx_lp_clk_io : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    out_mipi_tx_lp_d0_io  : inout std_logic_vector(1 downto 0); -- (P => 1, N => 0)
    out_mipi_tx_lp_d1_io  : inout std_logic_vector(1 downto 0)  -- (P => 1, N => 0)
  );
end entity mipi_tx_lane_hs_lp_mixer;

architecture rtl of mipi_tx_lane_hs_lp_mixer is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant LP_11_MODE_C : std_logic_vector(1 downto 0) := "11";
  constant LP_01_MODE_C : std_logic_vector(1 downto 0) := "01";
  constant LP_00_MODE_C : std_logic_vector(1 downto 0) := "00";


  -------------------------
  -- Signal Declarations --
  -------------------------


begin


  ---------------------
  -- I/O Assignments --
  ---------------------

  -- Put input LP lines in high-impedance, so they are in input mode
  in_mipi_tx_lp_clk_io  <= (others => 'Z');
  in_mipi_tx_lp_d1_io   <= (others => 'Z');
  in_mipi_tx_lp_d0_io   <= (others => 'Z');

  -- Output MIPI CSI2 TX Interface Low-Power lines are in high-impedance, since not used
  out_mipi_tx_lp_clk_io <= (others => 'Z');
  out_mipi_tx_lp_d0_io  <= (others => 'Z');
  out_mipi_tx_lp_d1_io  <= (others => 'Z');


  -------------------------------------------------------------------------------------
  -- Logic layer implemented to be able to connect the MIPI HS + MIPI LP interfaces
  -- on TX side to MIPI HS interface only on MIPI RX side
  -------------------------------------------------------------------------------------

  -- MIPI High-Speed Clock line
  out_mipi_tx_hs_clk_o <= "11"                 when (in_mipi_tx_lp_clk_io = LP_11_MODE_C) else
                          "01"                 when (in_mipi_tx_lp_clk_io = LP_01_MODE_C) else
                           in_mipi_tx_hs_clk_i;

  -- MIPI High-Speed Data line 0
  out_mipi_tx_hs_d0_o  <= "11"                 when (in_mipi_tx_lp_d0_io = LP_11_MODE_C) else
                          in_mipi_tx_hs_d0_i   when (in_mipi_tx_lp_d0_io = LP_00_MODE_C) else
                          in_mipi_tx_lp_d0_io;

  -- MIPI High-Speed Data line 1
  out_mipi_tx_hs_d1_o  <= "11"                 when (in_mipi_tx_lp_d1_io = LP_11_MODE_C) else
                          in_mipi_tx_hs_d1_i   when (in_mipi_tx_lp_d1_io = LP_00_MODE_C) else
                          in_mipi_tx_lp_d1_io;

  -- Output MIPI CSI2 TX Interface Low-Power lines forced to weak low state when in high impedance
  out_mipi_tx_hs_clk_o <= "LL";
  out_mipi_tx_hs_d0_o  <= "LL";
  out_mipi_tx_hs_d1_o  <= "LL";

end rtl;
