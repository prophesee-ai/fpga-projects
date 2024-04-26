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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


------------------------------------------------------------
-- AXI-Stream Ready Pipeline
-- Add a one-stage pipeline to an AXI-Stream input interface
entity axis_ready_pipe is
  generic (
    DATA_WIDTH    : positive := 8
  );
  port (
    -- Clock
    clk           : in  std_logic;
    arst_n        : in  std_logic;
    srst          : in  std_logic;

    -- Data Input
    in_ready_o    : out std_logic;
    in_valid_i    : in  std_logic;
    in_data_i     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    in_first_i    : in  std_logic;
    in_last_i     : in  std_logic;

    -- Data Output
    out_ready_i   : in  std_logic;
    out_valid_o   : out std_logic;
    out_data_o    : out std_logic_vector(DATA_WIDTH-1 downto 0);
    out_first_o   : out std_logic;
    out_last_o    : out std_logic
  );
end entity axis_ready_pipe;



architecture rtl of axis_ready_pipe is

  -------------------------
  -- Signal Declarations --
  -------------------------

  signal      in_ready_p      : std_logic;
  signal      in_valid_p      : std_logic;
  signal      in_first_p      : std_logic;
  signal      in_last_p       : std_logic;
  signal      in_data_p       : std_logic_vector(DATA_WIDTH-1 downto 0);

  signal      out_ready_s     : std_logic;
  signal      out_valid_s     : std_logic;
  signal      out_first_s     : std_logic;
  signal      out_last_s      : std_logic;
  signal      out_data_s      : std_logic_vector(DATA_WIDTH-1 downto 0);



begin

  in_ready_o      <= in_ready_p;

  enable_pipe : process(clk, arst_n)
  begin
    if (arst_n = '0') then
      in_ready_p    <= '0';
      in_valid_p    <= '0';
      in_first_p    <= '0';
      in_last_p     <= '0';
      in_data_p     <= (others => '0');
    elsif rising_edge(clk) then
      if (srst = '1') then
        in_ready_p    <= '0';
        in_valid_p    <= '0';
        in_first_p    <= '0';
        in_last_p     <= '0';
        in_data_p     <= (others => '0');
      else
        in_ready_p    <= out_ready_s or not(out_valid_s);
        if (out_ready_s = '1') then
          in_valid_p    <= '0';
        -- Only when the pipe_enable is 0 and the in_ready_p is 1, the in_reg_valid has the possibility to be '1';
        -- When pipe_enable becomes 1, the in_reg_ready is still 0, the in_reg_valid will be reset to 0;
        -- Data in reg will be transmit;
        -- The next cycle, in_reg_ready becomes 1, pipe_enable is 1 but in_reg_valid is 0;
        -- We have never the case in_reg_ready is 1, pipe_enable is 1, in_reg_valid is 1 and in_valid is 1;
        -- Never lose the input data
        elsif (in_ready_p = '1') then
          in_valid_p    <= in_valid_i;
          in_first_p    <= in_first_i;
          in_last_p     <= in_last_i;
          in_data_p     <= in_data_i;
        end if;
      end if;
    end if;
  end process enable_pipe;

  out_valid_s     <=        in_valid_i or in_valid_p;

  out_first_s     <=        in_first_i   when in_valid_p = '0'
                      else  in_first_p;

  out_last_s      <=        in_last_i   when in_valid_p = '0'
                      else  in_last_p;

  out_data_s      <=        in_data_i   when in_valid_p = '0'
                      else  in_data_p;

  out_ready_s     <= out_ready_i;
  out_valid_o     <= out_valid_s;
  out_data_o      <= out_data_s;
  out_first_o     <= out_first_s;
  out_last_o      <= out_last_s;



end architecture rtl;



