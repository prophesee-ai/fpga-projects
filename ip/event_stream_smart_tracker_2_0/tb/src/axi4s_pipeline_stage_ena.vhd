-- Copyright (c) Prophesee S.A.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--------------------------------------------------
-- AXI4-Stream Pipeline Stage with enable control
entity axi4s_pipeline_stage_ena is
  generic (
    PIPELINE_STAGES_G : positive := 2;
    DATA_WIDTH_G      : positive := 32
  );
  port (
    clk               : in  std_logic;
    rst               : in  std_logic;

    -- Control enable
    cfg_enable_i      : in std_logic;

    -- Input interface
    in_ready_o        : out std_logic;
    in_valid_i        : in  std_logic;
    in_first_i        : in  std_logic;
    in_last_i         : in  std_logic;
    in_data_i         : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

    -- Output interface
    out_ready_i       : in  std_logic;
    out_valid_o       : out std_logic;
    out_first_o       : out std_logic;
    out_last_o        : out std_logic;
    out_data_o        : out std_logic_vector(DATA_WIDTH_G-1 downto 0)
  );
end axi4s_pipeline_stage_ena;

architecture rtl of axi4s_pipeline_stage_ena is


  signal in_ready_s : std_logic;

  type valid_t is array (PIPELINE_STAGES_G-1 downto 0) of std_logic;
  type first_t is array (PIPELINE_STAGES_G-1 downto 0) of std_logic;
  type last_t  is array (PIPELINE_STAGES_G-1 downto 0) of std_logic;
  type data_t  is array (PIPELINE_STAGES_G-1 downto 0) of std_logic_vector(DATA_WIDTH_G-1 downto 0);

  signal pipe_valid_s : valid_t;
  signal pipe_first_s : last_t;
  signal pipe_last_s  : last_t;
  signal pipe_data_s  : data_t;

begin

  -- Asynchronous signal assignments
  in_ready_o  <= in_ready_s;
  out_valid_o <= pipe_valid_s(pipe_valid_s'high);
  out_first_o <= pipe_first_s(pipe_first_s'high);
  out_last_o  <= pipe_last_s(pipe_last_s'high);
  out_data_o  <= pipe_data_s(pipe_data_s'high);


  axi4s_pipeline_stage_ena_p : process(clk)
    variable pipe_valid_v : valid_t;
    variable pipe_first_v : first_t;
    variable pipe_last_v  : last_t;
    variable pipe_data_v  : data_t;
  begin
    if (rising_edge(clk)) then
      if (rst  = '1') then
        for i in PIPELINE_STAGES_G-1 downto 0 loop --pipe_valid_s'range loop
          pipe_valid_v(i) := '0';
          pipe_first_v(i) := '0';
          pipe_last_v(i)  := '0';
          pipe_data_v(i)  := (others => '0');
          pipe_valid_s(i) <= '0';
          pipe_first_s(i) <= '0';
          pipe_last_s(i)  <= '0';
          pipe_data_s(i)  <= (others => '0');
        end loop;

        in_ready_s <= '0';
      else

        ---------------
        -- Load Data --
        ---------------

        -- Load signals into local variables
        for i in pipe_valid_s'high downto pipe_valid_s'low loop
          pipe_valid_v(i) := pipe_valid_s(i);
          pipe_first_v(i) := pipe_first_s(i);
          pipe_last_v(i)  := pipe_last_s(i);
          pipe_data_v(i)  := pipe_data_s(i);
        end loop;

        --------------------
        -- Process Output --
        --------------------

        -- Check if output data has been acknowdledge and mark output as free
        if (out_ready_i = '1') then
          pipe_valid_v(pipe_valid_v'high) := '0';
        end if;

        -------------------
        -- Process Input --
        -------------------

        -- Assert that we do not have a conflict between incoming data overwriting the pending data
        assert (not (in_ready_s = '1' and in_valid_i = '1' and pipe_valid_v(0) = '1')) report "Illegal condition found in the pipeline stage where input is ready while there is pending data." severity failure;

        -- Check if there is new data to be sampled
        if (in_ready_s = '1' and in_valid_i = '1') then
          -- Sample incoming data
          pipe_valid_v(pipe_valid_v'low) := in_valid_i;
          pipe_first_v(pipe_valid_v'low) := in_first_i;
          pipe_last_v(pipe_valid_v'low)  := in_last_i;
          pipe_data_v(pipe_valid_v'low)  := in_data_i;
        end if;

        --------------------------------------
        -- Process Internal Pipeline Stages --
        --------------------------------------
        for i in pipe_valid_s'high-1 downto pipe_valid_s'low loop
          if (pipe_valid_v(i+1) = '0' and pipe_valid_v(i) = '1') then
            pipe_valid_v(i+1) := pipe_valid_v(i);
            pipe_first_v(i+1) := pipe_first_v(i);
            pipe_last_v(i+1)  := pipe_last_v(i);
            pipe_data_v(i+1)  := pipe_data_v(i);  --std_logic_vector(unsigned(pipe_data_v(i)) + 1);
            pipe_valid_v(i)   := '0';
          end if;
        end loop;

        ----------------
        -- Store Data --
        ----------------

        -- Store variables into signals
        for i in PIPELINE_STAGES_G-1 downto 0 loop -- pipe_valid_s'range loop
          pipe_valid_s(i) <= pipe_valid_v(i);
          pipe_first_s(i) <= pipe_first_v(i);
          pipe_last_s(i)  <= pipe_last_v(i);
          pipe_data_s(i)  <= pipe_data_v(i);
        end loop;

        in_ready_s <= not pipe_valid_v(pipe_valid_v'low) and cfg_enable_i;

      end if;
    end if;
  end process axi4s_pipeline_stage_ena_p;

end rtl;
