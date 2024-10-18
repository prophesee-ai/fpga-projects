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

use work.ccam_utils;


------------------------
-- AXI-Stream Serializer
entity axis_serializer is
  generic (
    IN_DATA_WIDTH  : positive := 32;
    OUT_DATA_WIDTH : positive := 8;
    LITTLE_ENDIAN  : boolean  := true
  );
  port (
    -- Clock and Reset
    clk         : in  std_logic;
    arst_n      : in  std_logic;
    srst        : in  std_logic;

    -- Input Interface
    in_ready_o  : out std_logic;
    in_valid_i  : in  std_logic;
    in_first_i  : in  std_logic;
    in_last_i   : in  std_logic;
    in_data_i   : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);

    -- Output Interface
    out_ready_i : in  std_logic;
    out_valid_o : out std_logic;
    out_first_o : out std_logic;
    out_last_o  : out std_logic;
    out_data_o  : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
  );
end entity axis_serializer;



architecture rtl of axis_serializer is

  ----------------------------
  -- Component Declarations --
  ----------------------------

  ------------------------------------------------------------
  -- AXI-Stream Ready Pipeline
  -- Add a one-stage pipeline to an AXI-Stream input interface
  component axis_ready_pipe is
    generic (
      DATA_WIDTH    : positive := 8
    );
    port (
      -- Clock
      clk           : in  std_logic;
      arst_n        : in  std_logic := '1';
      srst          : in  std_logic := '0';

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
  end component axis_ready_pipe;


  -----------------------------
  -- AXI4-Stream Pipeline Stage
  component axi4_pipeline_stage is
    generic (
      DATA_WIDTH : positive := 32
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
  end component axi4_pipeline_stage;




  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant DIVIDE_CYCLES        : natural   := (IN_DATA_WIDTH/OUT_DATA_WIDTH) - 1;
  constant DIVIDE_CYCLES_WIDTH  : natural   := ccam_utils.nbits(DIVIDE_CYCLES);


  ------------------------
  -- Types Declarations --
  ------------------------



  -------------------------
  -- Signal Declarations --
  -------------------------

  signal in_ready_s           : std_logic;
  signal in_valid_s           : std_logic;
  signal in_first_s           : std_logic;
  signal in_last_s            : std_logic;
  signal in_data_s            : std_logic_vector(IN_DATA_WIDTH-1 downto 0);

  signal cycles_counter_q     : unsigned(DIVIDE_CYCLES_WIDTH-1 downto 0)  := (others =>'0');

  signal first_cycle_s        : std_logic;
  signal last_cycle_s         : std_logic;

  signal ser_ready_s          : std_logic;
  signal ser_valid_s          : std_logic;
  signal ser_first_s          : std_logic;
  signal ser_last_s           : std_logic;
  signal ser_data_s           : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
  signal little_endian_data_s : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);
  signal big_endian_data_s    : std_logic_vector(OUT_DATA_WIDTH-1 downto 0);



begin

  assert (( IN_DATA_WIDTH mod OUT_DATA_WIDTH) = 0)
  report "IN_DATA_WIDTH need to be divided by OUT_DATA_WIDTH" &
         "IN_DATA_WIDTH : " & integer'image(IN_DATA_WIDTH) &
         "; OUT_DATA_WIDTH : " & integer'image(OUT_DATA_WIDTH)
  severity failure;

  ------------------------------------------------------------
  -- AXI-Stream Ready Pipeline
  -- Add a one-stage pipeline to an AXI-Stream input interface
  axis_ready_pipe_u : axis_ready_pipe
  generic map (
    DATA_WIDTH    => IN_DATA_WIDTH
  )
  port map (
    -- Clock
    clk           => clk,
    arst_n        => arst_n,
    srst          => srst,

    -- Data Input
    in_ready_o    => in_ready_o,
    in_valid_i    => in_valid_i,
    in_data_i     => in_data_i,
    in_first_i    => in_first_i,
    in_last_i     => in_last_i,

    -- Data Output
    out_ready_i   => in_ready_s,
    out_valid_o   => in_valid_s,
    out_data_o    => in_data_s,
    out_first_o   => in_first_s,
    out_last_o    => in_last_s
  );


  ----------------------
  -- Data Deserializing
  des_counter_p : process(arst_n, clk)
  begin
    if (arst_n = '0') then
      cycles_counter_q    <= (others => '0');
    elsif rising_edge(clk) then
      if (srst = '1') then
        cycles_counter_q    <= (others => '0');
      else
        if ((in_ready_s and in_valid_s) = '1') then
          cycles_counter_q    <= (others => '0');
        elsif ((ser_ready_s and ser_valid_s) = '1') then
          cycles_counter_q    <= cycles_counter_q + 1;
        end if;
      end if;
    end if;
  end process des_counter_p;

  first_cycle_s         <= '1'  when cycles_counter_q = 0             else '0';
  last_cycle_s          <= '1'  when cycles_counter_q = DIVIDE_CYCLES else '0';

  in_ready_s            <= ser_ready_s  and last_cycle_s;
  ser_valid_s           <= in_valid_s;
  ser_first_s           <= in_first_s   and first_cycle_s;
  ser_last_s            <= in_last_s    and last_cycle_s;
  ser_data_s            <= little_endian_data_s when LITTLE_ENDIAN  else big_endian_data_s;
  little_endian_data_s  <= in_data_s((to_integer(cycles_counter_q)+1)*OUT_DATA_WIDTH-1 downto to_integer(cycles_counter_q)*OUT_DATA_WIDTH);
  big_endian_data_s     <= in_data_s((DIVIDE_CYCLES-to_integer(cycles_counter_q)+1)*OUT_DATA_WIDTH-1 downto (DIVIDE_CYCLES-to_integer(cycles_counter_q))*OUT_DATA_WIDTH);


  -- AXI4-Stream Pipeline Stage
  -- Buffers the Output of the Deserialization Process
  axi4_pipeline_stage_u : axi4_pipeline_stage
  generic map (
    DATA_WIDTH  => OUT_DATA_WIDTH
  )
  port map (
    clk         => clk,
    rst         => srst,

    -- Input interface
    in_ready_o  => ser_ready_s,
    in_valid_i  => ser_valid_s,
    in_first_i  => ser_first_s,
    in_last_i   => ser_last_s,
    in_data_i   => ser_data_s,

    -- Output interface
    out_ready_i => out_ready_i,
    out_valid_o => out_valid_o,
    out_first_o => out_first_o,
    out_last_o  => out_last_o,
    out_data_o  => out_data_o
  );


end architecture rtl;
