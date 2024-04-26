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

library work;
use work.ccam_utils.all;


-------------------------------------------------------------------
-- Merges LSB and MSB Stream into a Single Output Stream, according
-- to event format.
entity axi4s_cfg_fifo_merge_2_1 is
  generic (
    IN_DATA_WIDTH  : positive := 16;
    OUT_DATA_WIDTH : positive := 32
  );
  port (
    -- Clock and Reset
    clk            : in  std_logic;
    arst_n         : in  std_logic;
    srst           : in  std_logic;
    
    -- Configuration Interface
    cfg_in_sel_i   : in  std_logic_vector(1 downto 0);
    
    -- Input Event Stream MSB Data Interface
    in_msb_ready_o : out std_logic;
    in_msb_valid_i : in  std_logic;
    in_msb_first_i : in  std_logic;
    in_msb_last_i  : in  std_logic;
    in_msb_data_i  : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);
    
    -- Input Event Stream LSB Data Interface
    in_lsb_ready_o : out std_logic;
    in_lsb_valid_i : in  std_logic;
    in_lsb_first_i : in  std_logic;
    in_lsb_last_i  : in  std_logic;
    in_lsb_data_i  : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);
    
    -- Output Event Stream Data Interface
    out_ready_i    : in  std_logic;
    out_valid_o    : out std_logic;
    out_first_o    : out std_logic;
    out_last_o     : out std_logic;
    out_data_o     : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
  );
end entity axi4s_cfg_fifo_merge_2_1;

architecture rtl of axi4s_cfg_fifo_merge_2_1 is


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input Event Stream MSB Data Interface
  signal in_msb_ready_q : std_logic;
  signal in_msb_valid_q : std_logic;
  signal in_msb_first_q : std_logic;
  signal in_msb_last_q  : std_logic;
  signal in_msb_data_q  : std_logic_vector(IN_DATA_WIDTH-1 downto 0);

  -- Input Event Stream LSB Data Interface
  signal in_lsb_ready_q : std_logic;
  signal in_lsb_valid_q : std_logic;
  signal in_lsb_first_q : std_logic;
  signal in_lsb_last_q  : std_logic;
  signal in_lsb_data_q  : std_logic_vector(IN_DATA_WIDTH-1 downto 0);

  -- Output Event Stream Data Interface
  signal out_valid_q    : std_logic;
  signal out_first_q    : std_logic;
  signal out_last_q     : std_logic;
  signal out_data_q     : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);

begin
  
  ----------------
  -- Assertions --
  ----------------
  
  assert (OUT_DATA_WIDTH = (IN_DATA_WIDTH * 2))
      report "ERROR: OUT_DATA_WIDTH must be 2x the IN_DATA_WIDTH."
      severity failure;


  ------------------------------
  -- Asynchronous Assignments --
  ------------------------------

  -- Input Event Stream MSB Data Interface
  in_msb_ready_o <= in_msb_ready_q;

  -- Input Event Stream LSB Data Interface
  in_lsb_ready_o <= in_lsb_ready_q;

  -- Output Event Stream Data Interface
  out_valid_o    <= out_valid_q;
  out_first_o    <= out_first_q;
  out_last_o     <= out_last_q;
  out_data_o     <= out_data_q;


  ---------------------------
  -- Synchronous Processes --
  ---------------------------

  -- Merge Process
  merge_p : process (clk, arst_n)
    variable in_msb_ready_v : std_logic;
    variable in_msb_valid_v : std_logic;
    variable in_msb_first_v : std_logic;
    variable in_msb_last_v  : std_logic;
    variable in_msb_data_v  : std_logic_vector(IN_DATA_WIDTH-1 downto 0);
    variable in_lsb_ready_v : std_logic;
    variable in_lsb_valid_v : std_logic;
    variable in_lsb_first_v : std_logic;
    variable in_lsb_last_v  : std_logic;
    variable in_lsb_data_v  : std_logic_vector(IN_DATA_WIDTH-1 downto 0);
    variable out_valid_v    : std_logic;
    variable out_first_v    : std_logic;
    variable out_last_v     : std_logic;
    variable out_data_v     : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
    
    procedure reset_p is
    begin
      in_msb_ready_q <= '0';
      in_msb_valid_q <= '0';
      in_msb_first_q <= '0';
      in_msb_last_q  <= '0';
      in_msb_data_q  <= (others => '0');
      in_lsb_ready_q <= '0';
      in_lsb_valid_q <= '0';
      in_lsb_first_q <= '0';
      in_lsb_last_q  <= '0';
      in_lsb_data_q  <= (others => '0');
      out_valid_q    <= '0';
      out_first_q    <= '0';
      out_last_q     <= '0';
      out_data_q     <= (others => '0');
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Load variables from signals
        in_msb_ready_v := in_msb_ready_q;
        in_msb_valid_v := in_msb_valid_q;
        in_msb_first_v := in_msb_first_q;
        in_msb_last_v  := in_msb_last_q;
        in_msb_data_v  := in_msb_data_q;
        in_lsb_ready_v := in_lsb_ready_q;
        in_lsb_valid_v := in_lsb_valid_q;
        in_lsb_first_v := in_lsb_first_q;
        in_lsb_last_v  := in_lsb_last_q;
        in_lsb_data_v  := in_lsb_data_q;
        out_valid_v    := out_valid_q;
        out_first_v    := out_first_q;
        out_last_v     := out_last_q;
        out_data_v     := out_data_q;

        -- If input MSB data interface is valid and the interface is ready, sample the data.
        if (in_msb_valid_i = '1' and in_msb_ready_v = '1') then
          in_msb_valid_v := in_msb_valid_i;
          in_msb_first_v := in_msb_first_i;
          in_msb_last_v  := in_msb_last_i;
          in_msb_data_v  := in_msb_data_i;
        end if;

        -- If input MSB interface is not selected, then discard the data right away.
        if (cfg_in_sel_i(1) = '0') then
          in_msb_valid_v := '0';
        end if;

        -- If input LSB data interface is valid and the interface is ready, sample the data.
        if (in_lsb_valid_i = '1' and in_lsb_ready_v = '1') then
          in_lsb_valid_v := in_lsb_valid_i;
          in_lsb_first_v := in_lsb_first_i;
          in_lsb_last_v  := in_lsb_last_i;
          in_lsb_data_v  := in_lsb_data_i;
        end if;

        -- If input LSB interface is not selected, then discard the data right away.
        if (cfg_in_sel_i(0) = '0') then
          in_lsb_valid_v := '0';
        end if;

        -- If output data has been sampled, release the output data.
        if (out_valid_v = '1' and out_ready_i = '1') then
          out_valid_v := '0';
        end if;
        
        -- If there is space in the output buffer and we have new data available, copy data to the output
        if (out_valid_v = '0' and
            cfg_in_sel_i /= (cfg_in_sel_i'range => '0')     and
            (cfg_in_sel_i(1) = '0' or in_msb_valid_v = '1') and
            (cfg_in_sel_i(0) = '0' or in_lsb_valid_v = '1')) then

          -- Set Output Data I/F valid, and initialize data to all zeros
          out_valid_v := '1';
          out_first_v := '0';
          out_last_v  := '0';
          out_data_v  := (others => '0');

          -- If the MSB Data I/F is selected, copy its data to the output
          if (cfg_in_sel_i(1) = '1') then
            out_first_v := out_first_v or in_msb_first_v;
            out_last_v  := out_last_v  or in_msb_last_v;
            out_data_v((2*IN_DATA_WIDTH)-1 downto IN_DATA_WIDTH) := in_msb_data_v;
          end if;

          -- If the LSB Data I/F is selected, copy its data to the output
          if (cfg_in_sel_i(0) = '1') then
            out_first_v := out_first_v or in_lsb_first_v;
            out_last_v  := out_last_v  or in_lsb_last_v;
            out_data_v(IN_DATA_WIDTH-1 downto 0) := in_lsb_data_v;
          end if;

          -- Release data from skid buffers
          in_msb_valid_v := '0';
          in_lsb_valid_v := '0';
        end if;

        -- Determine if the input interfaces can receive new data the next cycle
        in_msb_ready_v := (not cfg_in_sel_i(1)) or (not in_msb_valid_v);
        in_lsb_ready_v := (not cfg_in_sel_i(0)) or (not in_lsb_valid_v);

        -- Store variables into signals
        in_msb_ready_q <= in_msb_ready_v;
        in_msb_valid_q <= in_msb_valid_v;
        in_msb_first_q <= in_msb_first_v;
        in_msb_last_q  <= in_msb_last_v;
        in_msb_data_q  <= in_msb_data_v;
        in_lsb_ready_q <= in_lsb_ready_v;
        in_lsb_valid_q <= in_lsb_valid_v;
        in_lsb_first_q <= in_lsb_first_v;
        in_lsb_last_q  <= in_lsb_last_v;
        in_lsb_data_q  <= in_lsb_data_v;
        out_valid_q    <= out_valid_v;
        out_first_q    <= out_first_v;
        out_last_q     <= out_last_v;
        out_data_q     <= out_data_v;
      end if;
    end if;
  end process merge_p;

end rtl;
