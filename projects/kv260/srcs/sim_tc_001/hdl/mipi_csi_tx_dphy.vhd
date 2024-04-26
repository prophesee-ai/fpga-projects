-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
-- Unless required by applicable law or agreed to in writing, software distributed
-- under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
-- CONDITIONS OF ANY KIND, either express or implied. See the License
-- for the specific language governing permissions and limitations under the License.
---------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library unisim;
use     unisim.vcomponents.all;

----------------------------------------------
-- MIPI DPHY TX Output Serdes Layer
entity mipi_csi_tx_dphy is
  generic (
    LANE_WIDTH_G          : positive range 1 to 4;
    FPGA_FAMILY_G         : string                                               -- "7SERIES", "ULTRASCALE_PLUS"
  );
  port (
    -- Clocks and resets
    core_rst_i            : in    std_logic;                                     -- Core reset
    core_clk_i            : in    std_logic;                                     -- Clock synchronous with the parallel data to serialize
    hs_clk_i              : in    std_logic;                                     -- HS Clock input
    hs_clk_o              : out   std_logic;                                     -- HS Clock output

    -- High speed data enable and I/O buffer tristate control
    hs_clk_en_i           : in    std_logic;                                     -- HS (High Speed) Clock Enable
    hs_data_en_i          : in    std_logic;                                     -- HS (High Speed) Data Enable
    hs_clk_tri_ctl_o      : out   std_logic;                                     -- MIPI TX Tristate IO controllers
    hs_data_tri_ctl_o     : out   std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- MIPI TX Tristate IO controllers

    -- High speed CSI interface
    hs_byte_data_i        : in    std_logic_vector((8*LANE_WIDTH_G)-1 downto 0); -- HS (High Speed) Byte Data
    hs_data_o             : out   std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- HS (High Speed) Data Lane

    -- Low power interface
    lp_clk_io             : inout std_logic_vector(1 downto 0);                  -- LP (Low Power) External Interface Signals for Clock Lane
    lp_clk_dir_i          : in    std_logic;                                     -- LP (Low Power) Data Receive/Transmit Control for Clock Lane
    lp_clk_i              : in    std_logic_vector(1 downto 0);                  -- LP (Low Power) Data Receiving Signals for Clock Lane
    lp_clk_o              : out   std_logic_vector(1 downto 0);                  -- LP (Low Power) Data Transmitting Signals for Clock Lane
    lp_dx_io              : inout std_logic_vector((2*LANE_WIDTH_G)-1 downto 0); -- LP (Low Power) External Interface Signals for Data Lane
    lp_dx_dir_i           : in    std_logic_vector(LANE_WIDTH_G-1 downto 0);     -- LP (Low Power) Data Receive/Transmit Control for Data Lane
    lp_dx_i               : in    std_logic_vector((2*LANE_WIDTH_G)-1 downto 0); -- LP (Low Power) Data Receiving Signals for Data Lane
    lp_dx_o               : out   std_logic_vector((2*LANE_WIDTH_G)-1 downto 0)  -- LP (Low Power) Data Transmitting Signals for Data Lane
  );
end entity;

architecture rtl of mipi_csi_tx_dphy is

  signal hs_data_en_n_s       : std_logic;                                  -- High speed mipi data enable active low
  signal hs_data_tri_ctl_s    : std_logic_vector(LANE_WIDTH_G-1 downto 0);  -- High speed data lane tri-state I/O buffer control

begin

  -----------------------------------------
  -- Asynchronous assignments
  -----------------------------------------
  hs_data_en_n_s   <= not (hs_data_en_i);

  -- I/O buffer tri-state control for high speed interface
  hs_clk_tri_ctl_o  <= not (hs_clk_en_i);
  hs_data_tri_ctl_o <= hs_data_tri_ctl_s;

  -- High speed clock (forwarded only)
  hs_clk_o         <= hs_clk_i;

  -- Low power tristate control
  -- Low power Clock lane tristate buffer
  lp_clk_io        <= "00"     when hs_clk_en_i = '1' else
                      lp_clk_i when lp_clk_dir_i = '1' else
                      "ZZ";
  lp_clk_o         <= lp_clk_io;

  -- FPGA family parameter check
  assert (FPGA_FAMILY_G = "7SERIES" or FPGA_FAMILY_G = "ULTRASCALE_PLUS") report "FPGA_FAMILY_G should be 7SERIES or ULTRASCALE_PLUS" severity failure;

  --------------------------------------------
  -- Low power I/O control
  -- Output SERDES primitives instantiation
  -------------------------------------------
  mipi_csi_gen : for l in 0 to LANE_WIDTH_G-1 generate

    --------------------------------------
    -- Low power data lanes
    --------------------------------------
    -- Low power Data lane tristate buffer
    lp_dx_io((2*l)+1 downto (2*l)) <= "00"                          when hs_data_en_i   = '1'  else
                                      lp_dx_i((2*l)+1 downto (2*l)) when lp_dx_dir_i(l) = '1' else
                                      "ZZ";
    lp_dx_o((2*l)+1 downto (2*l))  <= lp_dx_io((2*l)+1 downto (2*l));

    --------------------------------------
    -- High speed data lane
    --------------------------------------
    -- 7 Series FPGA Family
    serie7_gen : if (FPGA_FAMILY_G = "7SERIES") generate

      -- Instantiate the OSERDESE2 primitive for byte serialization
      oserdes_u : OSERDESE2
        generic map (
          DATA_RATE_OQ   => "DDR",
          DATA_RATE_TQ   => "BUF",
          DATA_WIDTH     => 8,
          INIT_OQ        => '1',
          INIT_TQ        => '1',
          SERDES_MODE    => "MASTER",
          TBYTE_CTL      => "FALSE",
          TBYTE_SRC      => "FALSE",
          TRISTATE_WIDTH => 1
        )
        port map (
          OFB            => open,
          OQ             => hs_data_o(l),
          SHIFTOUT1      => open,
          SHIFTOUT2      => open,
          TBYTEOUT       => open,
          TFB            => open,
          TQ             => hs_data_tri_ctl_s(l),
          CLK            => hs_clk_i,
          CLKDIV         => core_clk_i,
          D1             => hs_byte_data_i((8*l)+0),
          D2             => hs_byte_data_i((8*l)+1),
          D3             => hs_byte_data_i((8*l)+2),
          D4             => hs_byte_data_i((8*l)+3),
          D5             => hs_byte_data_i((8*l)+4),
          D6             => hs_byte_data_i((8*l)+5),
          D7             => hs_byte_data_i((8*l)+6),
          D8             => hs_byte_data_i((8*l)+7),
          OCE            => '1',
          RST            => core_rst_i,
          SHIFTIN1       => '0',
          SHIFTIN2       => '0',
          T1             => hs_data_en_n_s,
          T2             => hs_data_en_n_s,
          T3             => hs_data_en_n_s,
          T4             => hs_data_en_n_s,
          TBYTEIN        => '0',
          TCE            => '1'
        );
    end generate serie7_gen;

    -- Ultrascale+ FPGA Family
    ultrascale_plus_gen : if (FPGA_FAMILY_G = "ULTRASCALE_PLUS") generate

      -- Instantiate the OSERDESE3 primitive for byte serialization
      oserdes_u : OSERDESE3
        generic map (
          DATA_WIDTH          => 8,
          INIT                => '0',
          ODDR_MODE           => "FALSE",
          OSERDES_D_BYPASS    => "FALSE",
          OSERDES_T_BYPASS    => "FALSE",
          IS_CLK_INVERTED     => '0',
          IS_CLKDIV_INVERTED  => '0',
          IS_RST_INVERTED     => '0',
          SIM_DEVICE          => "ULTRASCALE_PLUS"
        )
        port map (
          RST                 => core_rst_i,
          CLK                 => hs_clk_i,
          CLKDIV              => core_clk_i,
          D                   => hs_byte_data_i((8*(l+1))-1 downto (8*l)),
          OQ                  => hs_data_o(l),
          T_OUT               => hs_data_tri_ctl_s(l),
          T                   => hs_data_en_n_s
        );

    end generate ultrascale_plus_gen;

  end generate mipi_csi_gen;

end rtl;
