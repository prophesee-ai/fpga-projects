-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------
-- AXI4-Stream Pipeline Stage
entity axi4_pipeline_stage is
  generic (
    PIPELINE_STAGES : integer   := 1;
    DATA_WIDTH      : positive  := 32
  );
  port (
    clk         : in  std_logic;
    rst         : in  std_logic;

    -- Input interface
    in_ready_o  : out std_logic;
    in_valid_i  : in  std_logic;
    in_first_i  : in  std_logic;
    in_last_i   : in  std_logic;
    in_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output interface
    out_ready_i : in  std_logic;
    out_valid_o : out std_logic;
    out_first_o : out std_logic;
    out_last_o  : out std_logic;
    out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity axi4_pipeline_stage;

architecture rtl of axi4_pipeline_stage is

  constant PIPELINE_STAGES_C : positive := PIPELINE_STAGES + 1; -- First stage is skid-buffer only

  signal in_ready_s : std_logic;

  type valid_t is array (PIPELINE_STAGES_C-1 downto 0) of std_logic;
  type first_t is array (PIPELINE_STAGES_C-1 downto 0) of std_logic;
  type last_t  is array (PIPELINE_STAGES_C-1 downto 0) of std_logic;
  type data_t  is array (PIPELINE_STAGES_C-1 downto 0) of std_logic_vector(DATA_WIDTH-1 downto 0);

  signal pipe_valid_s : valid_t;
  signal pipe_first_s : last_t;
  signal pipe_last_s  : last_t;
  signal pipe_data_s  : data_t;

begin

  -- Check number of pipeline stages
  assert (PIPELINE_STAGES_C >= 2)
      report "Minimum number of pipeline stages not met."
      severity failure;

  -- Asynchronous signal assignments
  in_ready_o  <= in_ready_s;
  out_valid_o <= pipe_valid_s(pipe_valid_s'high);
  out_first_o <= pipe_first_s(pipe_first_s'high);
  out_last_o  <= pipe_last_s(pipe_last_s'high);
  out_data_o  <= pipe_data_s(pipe_data_s'high);


  axi4_pipeline_stage_p : process(clk)
    variable pipe_valid_v : valid_t;
    variable pipe_first_v : first_t;
    variable pipe_last_v  : last_t;
    variable pipe_data_v  : data_t;
  begin
    if (rising_edge(clk)) then
      if (rst  = '1') then
        for i in PIPELINE_STAGES_C-1 downto 0 loop --pipe_valid_s'range loop
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
        for i in PIPELINE_STAGES_C-1 downto 0 loop -- pipe_valid_s'range loop
          pipe_valid_s(i) <= pipe_valid_v(i);
          pipe_first_s(i) <= pipe_first_v(i);
          pipe_last_s(i)  <= pipe_last_v(i);
          pipe_data_s(i)  <= pipe_data_v(i);
        end loop;

        in_ready_s <= not pipe_valid_v(pipe_valid_v'low);

      end if;
    end if;
  end process axi4_pipeline_stage_p;

end rtl;
