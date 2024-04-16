----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Vitor Schwambach (vschwambach@prophesee.ai)
--
-- Create Date:    Jun. 27, 2019
-- Design Name:    clk_rst_gen
-- Module Name:    clk_rst_gen
-- Project Name:   psee_evk_mb_moorea
-- Target Devices:
-- Tool versions:  Xilinx Vivado 2018.2
-- Description:    Clock and Reset Generator
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
use ieee.math_real.all;


----------------------------
-- Clock and Reset Generator
entity clk_rst_gen is
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
end entity clk_rst_gen;


architecture sim of clk_rst_gen is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant CLK_PERIOD_C     : time := 1.0sec / real(CLK_FREQ_HZ_G);
  constant CLK_START_TIME_C : time := CLK_PERIOD_C * (real(CLK_PHASE_SHIFT_DEGREES_G) / 360.0);


  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Clock and Reset Signals
  signal clk_s : std_logic;
  signal rst_s : std_logic;


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  clk_o    <= clk_s;
  arst_n_o <= not(rst_s);
  srst_o   <= rst_s;


  ---------------
  -- Processes --
  ---------------

  --------------------------------------------------------------------------
  -- Clock process definitions (clock with 50% duty cycle is generated here)
  clk_p : process
  begin
    clk_s <= '0';
    wait for CLK_START_TIME_C;    -- Implements phase shift by delaying the start of the clock toggling
    loop
      clk_s <= '0';
      wait for (CLK_PERIOD_C/2);  -- for 50% of ext_clk_period signal is '0'.
      clk_s <= '1';
      wait for (CLK_PERIOD_C/2);  -- for next 50% of ext_clk_period signal is '1'.
    end loop;
  end process clk_p;


  -------------------
  -- Reset Generation
  rst_p : process
  begin
    -- Reset default value
    rst_s <= '0';

    -- Manage reset assertion 
    for i in 0 to RST_ASSERT_DELAY_CYCLES_G-1 loop
      wait until rising_edge(clk_s);
    end loop;
    rst_s <= '1';

    -- Manage reset de-assertion
    for i in 0 to RST_DEASSERT_DELAY_CYCLES_G-1 loop
      wait until rising_edge(clk_s);
    end loop;
    rst_s <= '0';

    wait;
  end process;

end architecture sim;
