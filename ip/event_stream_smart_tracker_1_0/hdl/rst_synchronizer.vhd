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

---------------------
-- Reset Synchronizer for std_logic data clock-domain crossings.
entity rst_synchronizer is
  generic (
    SYNC_DEPTH       : positive := 2; -- Synchronizer depth, the number of
                                      -- registers in the chain
    POST_SYNC_DEPTH  : natural  := 2  -- Post synchronization register chain depth
  );
  port (
    clk   : in  std_logic;            -- Destination clock
    rst   : in  std_logic;            -- Asynchronous reset, active high    
    rst_o : out std_logic
  );
end rst_synchronizer;

architecture rtl of rst_synchronizer is
  
  ---------------------------
  -- Constant Declarations --
  ---------------------------
  
  constant DATA_RESET_VALUE : std_logic := '1';
  constant DATA_VALUE       : std_logic := '0';

  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Synchronization flip-flops array
  --type data_sync_t is array (SYNC_DEPTH-1 downto 0) of std_logic_vector(0 downto 0);
  --signal data_sync_s      : data_sync_t      := (others => std_logic_vector(to_unsigned(DATA_RESET_VALUE, 1)));
  signal data_sync_s      : std_logic_vector(SYNC_DEPTH-1 downto 0) := (others => DATA_RESET_VALUE);
  
  --type data_post_sync_t is array (POST_SYNC_DEPTH-1 downto 0) of std_logic_vector(0 downto 0);
  --signal data_post_sync_s : data_post_sync_t := (others => std_logic_vector(to_unsigned(DATA_RESET_VALUE, 1)));
  signal data_post_sync_s     : std_logic_vector(POST_SYNC_DEPTH-1 downto 0) := (others => DATA_RESET_VALUE);
  
  -- Post sync data reset signal
  --type data_post_sync_rst_t is array (POST_SYNC_DEPTH downto 0) of std_logic_vector(0 downto 0);
  --signal data_post_sync_rst_s : data_post_sync_rst_t := (others => std_logic_vector(to_unsigned(DATA_RESET_VALUE, 1)));
  signal data_post_sync_rst_s     : std_logic_vector(POST_SYNC_DEPTH downto 0) := (others => DATA_RESET_VALUE);


  --------------------------------------
  -- Synthesis Attribute Declarations --
  --------------------------------------

  -- Synplify Pro: disable shift-register LUT (SRL) extraction
  attribute syn_srlstyle : string;
  attribute syn_srlstyle of data_sync_s : signal is "registers";
  
  -- Synplify Pro: disable interface changes to this block
  attribute syn_hier: string;
  attribute syn_hier of rtl : architecture is "firm";

  -- Xilinx XST: disable shift-register LUT (SRL) extraction
  attribute shreg_extract : string;
  attribute shreg_extract of data_sync_s  : signal is "no";

  -- Disable X propagation during timing simulation. In the event of 
  -- a timing violation, the previous value is retained on the output instead 
  -- of going unknown (see Xilinx UG625)
  attribute ASYNC_REG : string;
  attribute ASYNC_REG of data_sync_s : signal is "TRUE";

begin


  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------
  
  -- Output mapping from data sync registers
  gen_rst_o_from_data_sync_s : if (POST_SYNC_DEPTH <= 0) generate
  begin
    --rst_o <= data_sync_s(data_sync_s'low)(0);
    rst_o <= data_sync_s(data_sync_s'low);
  end generate gen_rst_o_from_data_sync_s;

  -- Output mapping from data post sync registers
  gen_rst_o_from_data_post_sync_s : if (POST_SYNC_DEPTH > 0) generate
  begin
    --rst_o <= data_post_sync_s(data_post_sync_s'low)(0);
    rst_o <= data_post_sync_s(data_post_sync_s'low);
  end generate gen_rst_o_from_data_post_sync_s;
  
  -- Map reset for post data sync register
  data_post_sync_rst_s(data_post_sync_rst_s'high) <= data_sync_s(data_sync_s'low);
  data_post_sync_rst_s(data_post_sync_s'range)    <= data_post_sync_s;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  -----------------------
  -- Synchronizer Process
  synchronizer_p : process(clk, rst)
  begin
    if (rst = DATA_RESET_VALUE) then
      data_sync_s <= (others => DATA_RESET_VALUE);
    elsif (rising_edge(clk)) then
      for i in data_sync_s'range loop
        if (i = data_sync_s'high) then
          data_sync_s(i) <= DATA_VALUE;
        else
          data_sync_s(i) <= data_sync_s(i+1);
        end if;
      end loop;
    end if;
  end process;


  ----------------------------
  -- Post Synchronizer Process
  gen_post_synchronizer_p_from_data_post_sync_s : if (POST_SYNC_DEPTH > 0) generate
  begin
    gen_inner_post_synchronizer_p_from_data_post_sync_s : for i in POST_SYNC_DEPTH-1 downto 0 generate
    begin
      post_synchronizer_p : process(clk, data_post_sync_rst_s(i+1))
      begin
        if (data_post_sync_rst_s(i+1) = DATA_RESET_VALUE) then
          data_post_sync_s(i) <= DATA_RESET_VALUE;
        elsif (rising_edge(clk)) then
          if (i = data_post_sync_s'high) then
            data_post_sync_s(i) <= data_sync_s(data_sync_s'high);
          else
            data_post_sync_s(i) <= data_post_sync_s(i+1);
          end if;
        end if;
      end process post_synchronizer_p;
    end generate gen_inner_post_synchronizer_p_from_data_post_sync_s;
  end generate gen_post_synchronizer_p_from_data_post_sync_s;
  
end rtl;
