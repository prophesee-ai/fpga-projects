----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
--
-- Create Date:    Dec. 11 2023
-- Design Name:    axi4s_demux_1_2
-- Module Name:    axi4s_demux_1_2
-- Project Name:   psee_generic
-- Target Devices: Zynq US
-- Tool versions:  Xilinx Vivado 2022.2
-- Description:    Data width variable demux of Axi4Stream with first and keep signals (heritates from original 1 to 2 demux)
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


---------------------------------------------------------------------
-- Demultiplexes an input event stream into either one of the
-- output interfaces according to the output selection signal.
-- When out_select_i is '0', output events are sent via the "out0"
-- interface, while when out_select_i is '1', output events are sent
-- via the "out1" interface.
entity axi4s_demux_1_2_keep is
  generic (
    DATA_WIDTH   : positive := 32
  );
  port (
    -- Core clock and reset
    clk          : in  std_logic;
    arst_n       : in  std_logic;
    srst         : in  std_logic;
    
    -- Output selection control
    out_select_i  : in  std_logic;
    
    -- Input event stream interface
    in_ready_o   : out std_logic;
    in_valid_i   : in  std_logic;
    in_first_i   : in  std_logic;
    in_last_i    : in  std_logic;
    in_data_i    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    in_keep_i    : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);
    
    -- Output 0 event stream interface
    out0_ready_i : in  std_logic;
    out0_valid_o : out std_logic;
    out0_first_o : out std_logic;
    out0_last_o  : out std_logic;
    out0_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out0_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);
    
    -- Output 1 event stream interface
    out1_ready_i : in  std_logic;
    out1_valid_o : out std_logic;
    out1_first_o : out std_logic;
    out1_last_o  : out std_logic;
    out1_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out1_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0)
  );
end axi4s_demux_1_2_keep;

architecture rtl of axi4s_demux_1_2_keep is
begin

  ------------------------
  -- Demultiplexer Process
  demux_p : process(arst_n, srst, out_select_i, in_valid_i, in_first_i, in_last_i, in_data_i, in_keep_i, out0_ready_i, out1_ready_i)
  begin
    if (arst_n = '0' or srst = '1') then
      in_ready_o   <= '0';
      out0_valid_o <= '0';
      out0_first_o <= '0';
      out0_last_o  <= '0';
      out0_data_o  <= (others => '0');
      out0_keep_o  <= (others => '0');
      out1_valid_o <= '0';
      out1_first_o <= '0';
      out1_last_o  <= '0';
      out1_data_o  <= (others => '0');
      out1_keep_o  <= (others => '0');
    elsif (out_select_i = '0') then
      in_ready_o   <= out0_ready_i;
      out0_valid_o <= in_valid_i;
      out0_first_o <= in_first_i;
      out0_last_o  <= in_last_i;
      out0_data_o  <= in_data_i;
      out0_keep_o  <= in_keep_i;
      out1_valid_o <= '0';
      out1_first_o <= '0';
      out1_last_o  <= '0';
      out1_data_o  <= (others => '0');
      out1_keep_o  <= (others => '0');
    else
      in_ready_o   <= out1_ready_i;
      out0_valid_o <= '0';
      out0_first_o <= '0';
      out0_last_o  <= '0';
      out0_data_o  <= (others => '0');
      out0_keep_o  <= (others => '0');
      out1_valid_o <= in_valid_i;
      out1_first_o <= in_first_i;
      out1_last_o  <= in_last_i;
      out1_data_o  <= in_data_i;
      out1_keep_o  <= in_keep_i;
    end if;
  end process;


end rtl;
