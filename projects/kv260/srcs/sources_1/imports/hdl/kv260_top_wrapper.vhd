--Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2022.2.1 (lin64) Build 3719031 Thu Dec  8 18:35:06 MST 2022
--Date        : Tue Apr 16 16:16:10 2024
--Host        : tars-system-u20 running 64-bit Ubuntu 20.04.6 LTS
--Command     : generate_target kv260_top_wrapper.bd
--Design      : kv260_top_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity kv260_top_wrapper is
  port (
    ccam5_csi_rx_clk_n : in STD_LOGIC;
    ccam5_csi_rx_clk_p : in STD_LOGIC;
    ccam5_csi_rx_data_n : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ccam5_csi_rx_data_p : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ccam5_i2c_scl_io : inout STD_LOGIC;
    ccam5_i2c_sda_io : inout STD_LOGIC;
    fan_en_b : out STD_LOGIC_VECTOR ( 0 to 0 );
    gpio_generic_tri_o : out STD_LOGIC_VECTOR ( 1 downto 0 )
  );
end kv260_top_wrapper;

architecture STRUCTURE of kv260_top_wrapper is
  component kv260_top is
  port (
    ccam5_csi_rx_clk_n : in STD_LOGIC;
    ccam5_csi_rx_clk_p : in STD_LOGIC;
    ccam5_csi_rx_data_n : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ccam5_csi_rx_data_p : in STD_LOGIC_VECTOR ( 1 downto 0 );
    ccam5_i2c_scl_i : in STD_LOGIC;
    ccam5_i2c_scl_o : out STD_LOGIC;
    ccam5_i2c_scl_t : out STD_LOGIC;
    ccam5_i2c_sda_i : in STD_LOGIC;
    ccam5_i2c_sda_o : out STD_LOGIC;
    ccam5_i2c_sda_t : out STD_LOGIC;
    gpio_generic_tri_o : out STD_LOGIC_VECTOR ( 1 downto 0 );
    fan_en_b : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component kv260_top;
  component IOBUF is
  port (
    I : in STD_LOGIC;
    O : out STD_LOGIC;
    T : in STD_LOGIC;
    IO : inout STD_LOGIC
  );
  end component IOBUF;
  signal ccam5_i2c_scl_i : STD_LOGIC;
  signal ccam5_i2c_scl_o : STD_LOGIC;
  signal ccam5_i2c_scl_t : STD_LOGIC;
  signal ccam5_i2c_sda_i : STD_LOGIC;
  signal ccam5_i2c_sda_o : STD_LOGIC;
  signal ccam5_i2c_sda_t : STD_LOGIC;
begin
ccam5_i2c_scl_iobuf: component IOBUF
     port map (
      I => ccam5_i2c_scl_o,
      IO => ccam5_i2c_scl_io,
      O => ccam5_i2c_scl_i,
      T => ccam5_i2c_scl_t
    );
ccam5_i2c_sda_iobuf: component IOBUF
     port map (
      I => ccam5_i2c_sda_o,
      IO => ccam5_i2c_sda_io,
      O => ccam5_i2c_sda_i,
      T => ccam5_i2c_sda_t
    );
kv260_top_i: component kv260_top
     port map (
      ccam5_csi_rx_clk_n => ccam5_csi_rx_clk_n,
      ccam5_csi_rx_clk_p => ccam5_csi_rx_clk_p,
      ccam5_csi_rx_data_n(1 downto 0) => ccam5_csi_rx_data_n(1 downto 0),
      ccam5_csi_rx_data_p(1 downto 0) => ccam5_csi_rx_data_p(1 downto 0),
      ccam5_i2c_scl_i => ccam5_i2c_scl_i,
      ccam5_i2c_scl_o => ccam5_i2c_scl_o,
      ccam5_i2c_scl_t => ccam5_i2c_scl_t,
      ccam5_i2c_sda_i => ccam5_i2c_sda_i,
      ccam5_i2c_sda_o => ccam5_i2c_sda_o,
      ccam5_i2c_sda_t => ccam5_i2c_sda_t,
      fan_en_b(0) => fan_en_b(0),
      gpio_generic_tri_o(1 downto 0) => gpio_generic_tri_o(1 downto 0)
    );
end STRUCTURE;
