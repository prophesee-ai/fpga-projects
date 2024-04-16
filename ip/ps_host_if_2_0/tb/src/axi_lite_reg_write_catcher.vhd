----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Ny Onintsoa ANDRIAMANANJARA
-- Create Date:    24.06.2019
-- Design Name:    axil_reg_catcher
-- Module Name:    axil_reg_catcher.vhd
-- Target Devices: All compatible
-- Tool versions:  2018.2
-- Description:    AXI4 Lite control register value catcher
----------------------------------------------------------------------------------
library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;


----------------------------------------------
-- AXI4 write register catcher
entity axi_lite_reg_write_catcher is
  generic(
    BUS_ADDR_WIDTH_G             : positive := 32;
    BUS_DATA_WIDTH_G             : positive := 32;
    REG_ADDR_G                   : natural  := 0;
    REG_DEFAULT_VALUE_G          : natural  := 0
  );
  port(
    -- Clock, reset
    clk                          : in  std_logic;
    rst                          : in  std_logic;

    -- AXI4 Lite slave write interface
    axil_s_awready_i             : in  std_logic;
    axil_s_awvalid_i             : in  std_logic;
    axil_s_awaddr_i              : in  std_logic_vector(BUS_ADDR_WIDTH_G-1 downto 0);
    axil_s_wready_i              : in  std_logic;
    axil_s_wvalid_i              : in  std_logic;
    axil_s_wstrb_i               : in  std_logic_vector((BUS_DATA_WIDTH_G/8)-1 downto 0);
    axil_s_wdata_i               : in  std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);

    -- Output register value
    out_valid_flag_o						 : out std_logic;
    out_value_o                  : out std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0)
  );
end entity axi_lite_reg_write_catcher;

architecture sim of axi_lite_reg_write_catcher is

  signal out_value_s             : std_logic_vector(BUS_DATA_WIDTH_G-1 downto 0);

begin

  -- Output assignment
  out_value_o <= out_value_s;

  -- AXI4 Lite write data catcher
  axil_reg_catcher_p : process
  begin
    out_value_s <= std_logic_vector(to_unsigned(REG_DEFAULT_VALUE_G, out_value_s'length));
    out_valid_flag_o <= '0';

    -- Wait for reset to complete
    while(rst /= '1') loop
      wait until rst = '1';
    end loop;
    wait until rst = '0';

    -- Loop for write address check and write data interception
    loop
      -- Intercept the write address access
      while not (axil_s_awvalid_i = '1' and axil_s_awready_i = '1' and axil_s_awaddr_i = std_logic_vector(to_unsigned(REG_ADDR_G, axil_s_awaddr_i'length))) loop
        wait until (axil_s_awvalid_i = '1' and axil_s_awready_i = '1' and axil_s_awaddr_i = std_logic_vector(to_unsigned(REG_ADDR_G, axil_s_awaddr_i'length)));
      end loop;

      -- Intercept the write data
      while not (axil_s_wvalid_i = '1' and axil_s_wready_i = '1') loop
        wait until (axil_s_wvalid_i = '1' and axil_s_wready_i = '1');
      end loop;
      
      out_valid_flag_o <= '1';

      -- Update the output value
      for i in 0 to axil_s_wstrb_i'high loop
        if (axil_s_wstrb_i(i) = '1') then
          out_value_s((8*(i+1))-1 downto (8*i)) <= axil_s_wdata_i((8*(i+1))-1 downto (8*i));
        else
          out_value_s((8*(i+1))-1 downto (8*i)) <= (others => '0');
        end if;
      end loop;

      wait until rising_edge(clk);

    end loop;
  end process axil_reg_catcher_p;

end sim;
