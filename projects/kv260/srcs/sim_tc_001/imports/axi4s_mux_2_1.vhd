-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_utils.all;


---------------------------------------------------------------------
-- Multiplexes one of the input streams into the output interface
-- according to the input selection signal.
-- When in_select_i is '0', data of the "in0" interface is forwarded
-- to the output interface, whereas when in_select_i is '1',
-- data of the "in1" interface are forwarded to the output interface.
entity axi4s_mux_2_1 is
  generic (
    DATA_WIDTH       : positive := 32;
    UNSEL_READY_HIGH : boolean  := false  -- If true, unselected inputs have their ready line driven high.
  );
  port (
    -- Clock and Reset
    clk         : in  std_logic;
    arst_n      : in  std_logic;
    srst        : in  std_logic;

    -- Input Selection Control
    in_select_i : in  std_logic;

    -- Input 0 Stream Interface
    in0_ready_o : out std_logic;
    in0_valid_i : in  std_logic;
    in0_first_i : in  std_logic;
    in0_last_i  : in  std_logic;
    in0_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Input 1 Stream Interface
    in1_ready_o : out std_logic;
    in1_valid_i : in  std_logic;
    in1_first_i : in  std_logic;
    in1_last_i  : in  std_logic;
    in1_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output Event Stream Interface
    out_ready_i : in  std_logic;
    out_valid_o : out std_logic;
    out_first_o : out std_logic;
    out_last_o  : out std_logic;
    out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end axi4s_mux_2_1;

architecture rtl of axi4s_mux_2_1 is

  constant UNSEL_READY_VALUE_C : std_logic := iff(UNSEL_READY_HIGH, '1', '0');

begin

  ----------------------
  -- Multiplexer Process
  mux_p : process(arst_n, srst, in_select_i, out_ready_i,
                  in0_valid_i, in0_first_i, in0_last_i, in0_data_i,
                  in1_valid_i, in1_first_i, in1_last_i, in1_data_i)
  begin
    if (arst_n = '0' or srst = '1') then
      in0_ready_o <= '0';
      in1_ready_o <= '0';
      out_valid_o <= '0';
      out_first_o <= '0';
      out_last_o  <= '0';
      out_data_o  <= (others => '0');
    elsif (in_select_i = '0') then
      in0_ready_o <= out_ready_i;
      in1_ready_o <= UNSEL_READY_VALUE_C;
      out_valid_o <= in0_valid_i;
      out_first_o <= in0_first_i;
      out_last_o  <= in0_last_i;
      out_data_o  <= in0_data_i;
    else
      in0_ready_o <= UNSEL_READY_VALUE_C;
      in1_ready_o <= out_ready_i;
      out_valid_o <= in1_valid_i;
      out_first_o <= in1_first_i;
      out_last_o  <= in1_last_i;
      out_data_o  <= in1_data_i;
    end if;
  end process;

end rtl;
