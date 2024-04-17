-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


----------------------
-- Clock and Reset BFM
entity clk_rst_bfm is
  generic (
    CORE_CLK_FREQ_HZ_G    : positive := 100e6 -- Default 100 MHz frequency
  );
  port (
    -- Core Clock and Reset
    core_clk_o            : out std_logic;
    core_arst_n_o         : out std_logic;
    core_srst_o           : out std_logic;

    -- MIPI TX HS Clock and Reset
    mipi_tx_hs_clk_o      : out std_logic;
    mipi_tx_hs_arst_n_o   : out std_logic;
    mipi_tx_hs_srst_o     : out std_logic;
    mipi_tx_hs_clk90_o    : out std_logic;

    -- MIPI RX DPHY Clock and Reset
    mipi_rx_dphy_clk_o    : out std_logic;
    mipi_rx_dphy_arst_n_o : out std_logic;
    mipi_rx_dphy_srst_o   : out std_logic
  );
end entity clk_rst_bfm;


architecture sim of clk_rst_bfm is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  -- Core Clock and Reset Properties
  constant CORE_CLK_PHASE_SHIFT_DEGREES_C           : natural  := 0;
  constant CORE_RST_ASSERT_DELAY_CYCLES_C           : natural  := 0;
  constant CORE_RST_DEASSERT_DELAY_CYCLES_C         : natural  := 100;

  -- MIPI TX HS Clock and Reset Properties
  constant MIPI_TX_HS_CLK_FREQ_HZ_C                 : positive := 4 * CORE_CLK_FREQ_HZ_G;
  constant MIPI_TX_HS_CLK_PHASE_SHIFT_DEGREES_C     : natural  := CORE_CLK_PHASE_SHIFT_DEGREES_C;
  constant MIPI_TX_HS_RST_ASSERT_DELAY_CYCLES_C     : natural  := CORE_RST_ASSERT_DELAY_CYCLES_C * 4;
  constant MIPI_TX_HS_RST_DEASSERT_DELAY_CYCLES_C   : natural  := CORE_RST_DEASSERT_DELAY_CYCLES_C * 4;

  -- MIPI TX HS 90° Clock and Reset Properties
  constant MIPI_TX_HS90_CLK_FREQ_HZ_C               : positive := MIPI_TX_HS_CLK_FREQ_HZ_C;
  constant MIPI_TX_HS90_CLK_PHASE_SHIFT_DEGREES_C   : natural  := MIPI_TX_HS_CLK_PHASE_SHIFT_DEGREES_C + 90;
  constant MIPI_TX_HS90_RST_ASSERT_DELAY_CYCLES_C   : natural  := MIPI_TX_HS_RST_ASSERT_DELAY_CYCLES_C;
  constant MIPI_TX_HS90_RST_DEASSERT_DELAY_CYCLES_C : natural  := MIPI_TX_HS_RST_DEASSERT_DELAY_CYCLES_C;

  -- MIPI RX DPHY Clock and Reset
  constant MIPI_RX_DPHY_CLK_FREQ_HZ_C               : positive := 200e6; -- Fixed 200 MHz frequency
  constant MIPI_RX_DPHY_CLK_PHASE_SHIFT_DEGREES_C   : natural  := CORE_CLK_PHASE_SHIFT_DEGREES_C;
  constant MIPI_RX_DPHY_RST_ASSERT_DELAY_CYCLES_C   : natural  := CORE_RST_ASSERT_DELAY_CYCLES_C * 2;
  constant MIPI_RX_DPHY_RST_DEASSERT_DELAY_CYCLES_C : natural  := CORE_RST_DEASSERT_DELAY_CYCLES_C * 2;


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ----------------------------
  -- Clock and Reset Generator
  component clk_rst_gen is
    generic (
      CLK_FREQ_HZ_G               : positive := 100000000;
      CLK_PHASE_SHIFT_DEGREES_G   : natural  := 0;
      RST_ASSERT_DELAY_CYCLES_G   : natural  := 0;
      RST_DEASSERT_DELAY_CYCLES_G : natural  := 100
    );
    port (
      -- Clock and Reset Outputs
      clk_o    : out std_logic;
      arst_n_o : out std_logic;
      srst_o   : out std_logic
    );
  end component clk_rst_gen;


  -------------------------
  -- Signal Declarations --
  -------------------------


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ---------------------------------
  -- Core Clock and Reset Generator
  core_clk_rst_gen_u : clk_rst_gen
  generic map (
    CLK_FREQ_HZ_G               => CORE_CLK_FREQ_HZ_G,
    CLK_PHASE_SHIFT_DEGREES_G   => CORE_CLK_PHASE_SHIFT_DEGREES_C,
    RST_ASSERT_DELAY_CYCLES_G   => CORE_RST_ASSERT_DELAY_CYCLES_C,
    RST_DEASSERT_DELAY_CYCLES_G => CORE_RST_DEASSERT_DELAY_CYCLES_C
  )
  port map (
    -- Clock and Reset Outputs
    clk_o    => core_clk_o,
    arst_n_o => core_arst_n_o,
    srst_o   => core_srst_o
  );


  ---------------------------------------
  -- MIPI TX HS Clock and Reset Generator
  mipi_tx_hs_clk_rst_gen_u : clk_rst_gen
  generic map (
    CLK_FREQ_HZ_G               => MIPI_TX_HS_CLK_FREQ_HZ_C,
    CLK_PHASE_SHIFT_DEGREES_G   => MIPI_TX_HS_CLK_PHASE_SHIFT_DEGREES_C,
    RST_ASSERT_DELAY_CYCLES_G   => MIPI_TX_HS_RST_ASSERT_DELAY_CYCLES_C,
    RST_DEASSERT_DELAY_CYCLES_G => MIPI_TX_HS_RST_DEASSERT_DELAY_CYCLES_C
  )
  port map (
    -- Clock and Reset Outputs
    clk_o    => mipi_tx_hs_clk_o,
    arst_n_o => mipi_tx_hs_arst_n_o,
    srst_o   => mipi_tx_hs_srst_o
  );


  -------------------------------------------
  -- MIPI TX HS 90° Clock and Reset Generator
  mipi_tx_hs90_clk_rst_gen_u : clk_rst_gen
  generic map (
    CLK_FREQ_HZ_G               => MIPI_TX_HS90_CLK_FREQ_HZ_C,
    CLK_PHASE_SHIFT_DEGREES_G   => MIPI_TX_HS90_CLK_PHASE_SHIFT_DEGREES_C,
    RST_ASSERT_DELAY_CYCLES_G   => MIPI_TX_HS90_RST_ASSERT_DELAY_CYCLES_C,
    RST_DEASSERT_DELAY_CYCLES_G => MIPI_TX_HS90_RST_DEASSERT_DELAY_CYCLES_C
  )
  port map (
    -- Clock and Reset Outputs
    clk_o    => mipi_tx_hs_clk90_o,
    arst_n_o => open,
    srst_o   => open
  );


  -----------------------------------------
  -- MIPI RX DPHY Clock and Reset Generator
  mipi_rx_dphy_clk_rst_gen_u : clk_rst_gen
  generic map (
    CLK_FREQ_HZ_G               => MIPI_RX_DPHY_CLK_FREQ_HZ_C,
    CLK_PHASE_SHIFT_DEGREES_G   => MIPI_RX_DPHY_CLK_PHASE_SHIFT_DEGREES_C,
    RST_ASSERT_DELAY_CYCLES_G   => MIPI_RX_DPHY_RST_ASSERT_DELAY_CYCLES_C,
    RST_DEASSERT_DELAY_CYCLES_G => MIPI_RX_DPHY_RST_DEASSERT_DELAY_CYCLES_C
  )
  port map (
    -- Clock and Reset Outputs
    clk_o    => mipi_rx_dphy_clk_o,
    arst_n_o => mipi_rx_dphy_arst_n_o,
    srst_o   => mipi_rx_dphy_srst_o
  );

end architecture sim;
