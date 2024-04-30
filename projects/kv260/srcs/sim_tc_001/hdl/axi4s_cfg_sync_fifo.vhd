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
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;


--------------------------------------------
-- Configurable AXI4-Stream Synchronous FIFO
entity axi4s_cfg_sync_fifo is
  generic (
    DATA_WIDTH  : positive                     := 32;     -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
    MEMORY_TYPE : string                       := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    DEPTH       : positive range 16 to 4194304 := 2048
  );
  port (
    -- Clock and Reset
    clk              : in  std_logic;
    arst_n           : in  std_logic;
    srst             : in  std_logic;

    -- Configuration Interface
    cfg_half_width_i : in  std_logic;

    -- Input Interface
    in_ready_o       : out std_logic;
    in_valid_i       : in  std_logic;
    in_first_i       : in  std_logic;
    in_last_i        : in  std_logic;
    in_data_i        : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output Interface
    out_ready_i      : in  std_logic;
    out_valid_o      : out std_logic;
    out_first_o      : out std_logic;
    out_last_o       : out std_logic;
    out_data_o       : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity axi4s_cfg_sync_fifo;

architecture rtl of axi4s_cfg_sync_fifo is


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ---------------------------------------------------------------------
  -- Forks an input event stream into a number of output interfaces.
  component axi4s_fork_1_2 is
    generic (
      DATA_WIDTH   : positive := 32
    );
    port (
      -- Core clock and reset
      clk          : in  std_logic;
      arst_n       : in  std_logic;
      srst         : in  std_logic;
      
      -- Input event stream interface
      in_ready_o   : out std_logic;
      in_valid_i   : in  std_logic;
      in_first_i   : in  std_logic;
      in_last_i    : in  std_logic;
      in_data_i    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      
      -- Output 0 event stream interface
      out0_ready_i : in  std_logic;
      out0_valid_o : out std_logic;
      out0_first_o : out std_logic;
      out0_last_o  : out std_logic;
      out0_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      -- Output 1 event stream interface
      out1_ready_i : in  std_logic;
      out1_valid_o : out std_logic;
      out1_first_o : out std_logic;
      out1_last_o  : out std_logic;
      out1_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component axi4s_fork_1_2;


  ---------------------------------------------------------------------
  -- Multiplexes one of the input streams into the output interface
  -- according to the input selection signal.
  -- When in_select_i is '0', data of the "in0" interface is forwarded
  -- to the output interface, whereas when in_select_i is '1',
  -- data of the "in1" interface are forwarded to the output interface.
  component axi4s_mux_2_1 is
    generic (
      DATA_WIDTH   : positive := 32
    );
    port (
      -- Core clock and reset
      clk          : in  std_logic;
      arst_n       : in  std_logic;
      srst         : in  std_logic;
      
      -- Input selection control
      in_select_i  : in  std_logic;
      
      -- Input 0 stream interface
      in0_ready_o  : out std_logic;
      in0_valid_i  : in  std_logic;
      in0_first_i  : in  std_logic;
      in0_last_i   : in  std_logic;
      in0_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      
      -- Input 1 stream interface
      in1_ready_o  : out std_logic;
      in1_valid_i  : in  std_logic;
      in1_first_i  : in  std_logic;
      in1_last_i   : in  std_logic;
      in1_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
      
      -- Output event stream interface
      out_ready_i  : in  std_logic;
      out_valid_o  : out std_logic;
      out_first_o  : out std_logic;
      out_last_o   : out std_logic;
      out_data_o   : out std_logic_vector(DATA_WIDTH-1 downto 0)      
    );
  end component axi4s_mux_2_1;


  ---------------------------------------------------------------------
  -- Demultiplexes an input event stream into either one of the
  -- output interfaces according to the output selection signal.
  -- When out_select_i is '0', output events are sent via the "out0"
  -- interface, while when out_select_i is '1', output events are sent
  -- via the "out1" interface.
  component axi4s_demux_1_2 is
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
      
      -- Output 0 event stream interface
      out0_ready_i : in  std_logic;
      out0_valid_o : out std_logic;
      out0_first_o : out std_logic;
      out0_last_o  : out std_logic;
      out0_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
      
      -- Output 1 event stream interface
      out1_ready_i : in  std_logic;
      out1_valid_o : out std_logic;
      out1_first_o : out std_logic;
      out1_last_o  : out std_logic;
      out1_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)      
    );
  end component axi4s_demux_1_2;


  -------------------------------
  -- AXI4-Stream Synchronous FIFO
  component axi4s_sync_fifo is
    generic (
      DATA_WIDTH  : positive                     := 32;     -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
      MEMORY_TYPE : string                       := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.
      DEPTH       : positive range 16 to 4194304 := 2048
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
      in_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
  
      -- Output Interface
      out_ready_i : in  std_logic;
      out_valid_o : out std_logic;
      out_first_o : out std_logic;
      out_last_o  : out std_logic;
      out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component axi4s_sync_fifo;


  -------------------------------------------------------------------
  -- Merges LSB and MSB Stream into a Single Output Stream, according
  -- to event type.
  component axi4s_cfg_fifo_merge_2_1 is
    generic (
      IN_DATA_WIDTH  : positive := 16;
      OUT_DATA_WIDTH : positive := 32
    );
    port (
      -- Clock and Reset
      clk              : in  std_logic;
      arst_n           : in  std_logic;
      srst             : in  std_logic;
      
      -- Configuration Interface
      cfg_in_sel_i     : in  std_logic_vector(1 downto 0);
      
      -- Input Event Stream MSB Data Interface
      in_msb_ready_o   : out std_logic;
      in_msb_valid_i   : in  std_logic;
      in_msb_first_i   : in  std_logic;
      in_msb_last_i    : in  std_logic;
      in_msb_data_i    : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);
      
      -- Input Event Stream LSB Data Interface
      in_lsb_ready_o   : out std_logic;
      in_lsb_valid_i   : in  std_logic;
      in_lsb_first_i   : in  std_logic;
      in_lsb_last_i    : in  std_logic;
      in_lsb_data_i    : in  std_logic_vector(IN_DATA_WIDTH-1 downto 0);
      
      -- Output Event Stream Data Interface
      out_ready_i      : in  std_logic;
      out_valid_o      : out std_logic;
      out_first_o      : out std_logic;
      out_last_o       : out std_logic;
      out_data_o       : out std_logic_vector(OUT_DATA_WIDTH-1 downto 0)
    );
  end component axi4s_cfg_fifo_merge_2_1;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Clock and Reset Signals
  signal rst_s                           : std_logic;

  -- Input Stream Fork Block Signals - Output Interface 0
  signal in_fork_out0_ready_s            : std_logic;
  signal in_fork_out0_valid_s            : std_logic;
  signal in_fork_out0_first_s            : std_logic;
  signal in_fork_out0_last_s             : std_logic;
  signal in_fork_out0_data_s             : std_logic_vector(DATA_WIDTH-1 downto 0);

  -- Input Stream Fork Block Signals - Output Interface 1
  signal in_fork_out1_ready_s            : std_logic;
  signal in_fork_out1_valid_s            : std_logic;
  signal in_fork_out1_first_s            : std_logic;
  signal in_fork_out1_last_s             : std_logic;
  signal in_fork_out1_data_s             : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  -- MSB FIFO Signals - Input Interface
  signal msb_fifo_in_ready_s             : std_logic;
  signal msb_fifo_in_valid_s             : std_logic;
  signal msb_fifo_in_first_s             : std_logic;
  signal msb_fifo_in_last_s              : std_logic;
  signal msb_fifo_in_data_s              : std_logic_vector((DATA_WIDTH/2)-1 downto 0);

  -- MSB FIFO Signals - Output Interface
  signal msb_fifo_out_ready_s            : std_logic;
  signal msb_fifo_out_valid_s            : std_logic;
  signal msb_fifo_out_first_s            : std_logic;
  signal msb_fifo_out_last_s             : std_logic;
  signal msb_fifo_out_data_s             : std_logic_vector((DATA_WIDTH/2)-1 downto 0);

  -- MSB FIFO Output Demux Signals - Configuration Interface
  signal msb_fifo_out_demux_out_select_s : std_logic;

  -- MSB FIFO Output Demux Signals - Output Interface 0
  signal msb_fifo_out_demux_out0_ready_s : std_logic;
  signal msb_fifo_out_demux_out0_valid_s : std_logic;
  signal msb_fifo_out_demux_out0_first_s : std_logic;
  signal msb_fifo_out_demux_out0_last_s  : std_logic;
  signal msb_fifo_out_demux_out0_data_s  : std_logic_vector((DATA_WIDTH/2)-1 downto 0);

  -- MSB FIFO Output Demux Signals - Output Interface 1
  signal msb_fifo_out_demux_out1_ready_s : std_logic;
  signal msb_fifo_out_demux_out1_valid_s : std_logic;
  signal msb_fifo_out_demux_out1_first_s : std_logic;
  signal msb_fifo_out_demux_out1_last_s  : std_logic;
  signal msb_fifo_out_demux_out1_data_s  : std_logic_vector((DATA_WIDTH/2)-1 downto 0);

  -- LSB FIFO Input Mux Signals - Configuration Interface
  signal lsb_fifo_in_mux_in_select_s     : std_logic;
  
  -- LSB FIFO Input Mux Signals - Input Interface
  signal lsb_fifo_in_mux_in_ready_s      : std_logic;
  signal lsb_fifo_in_mux_in_valid_s      : std_logic;
  signal lsb_fifo_in_mux_in_first_s      : std_logic;
  signal lsb_fifo_in_mux_in_last_s       : std_logic;
  signal lsb_fifo_in_mux_in_data_s       : std_logic_vector((DATA_WIDTH/2)-1 downto 0); 

  -- LSB FIFO Input Mux Signals - Output Interface
  signal lsb_fifo_in_mux_out_ready_s     : std_logic;
  signal lsb_fifo_in_mux_out_valid_s     : std_logic;
  signal lsb_fifo_in_mux_out_first_s     : std_logic;
  signal lsb_fifo_in_mux_out_last_s      : std_logic;
  signal lsb_fifo_in_mux_out_data_s      : std_logic_vector((DATA_WIDTH/2)-1 downto 0); 

  -- LSB FIFO Signals - Output Interface
  signal lsb_fifo_out_ready_s            : std_logic;
  signal lsb_fifo_out_valid_s            : std_logic;
  signal lsb_fifo_out_first_s            : std_logic;
  signal lsb_fifo_out_last_s             : std_logic;
  signal lsb_fifo_out_data_s             : std_logic_vector((DATA_WIDTH/2)-1 downto 0);
  
  -- MSB/LSB Merge Signals -- Configuration Interface 
  signal merge_cfg_in_sel_s              : std_logic_vector(1 downto 0);


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Derived Clocks and Resets
  rst_s                            <= (not arst_n) or srst;

  -- MSB FIFO Output Demux Signals - Configuration Interface
  msb_fifo_out_demux_out_select_s  <= '1' when (cfg_half_width_i = '1') else '0';
  
  -- LSB FIFO Input Mux Signals - Configuration Interface
  lsb_fifo_in_mux_in_select_s      <= '1' when (cfg_half_width_i = '1') else '0';
  
  -- MSB/LSB Merge Signals -- Configuration Interface
  merge_cfg_in_sel_s               <= "01" when (cfg_half_width_i = '1') else "11";
  
  -- Mapping Input Stream Fork Block's Output Interface 1
  -- to MSB FIFO Input Mux's Input Interface
  in_fork_out1_ready_s             <= msb_fifo_in_ready_s;
  msb_fifo_in_valid_s              <= in_fork_out1_valid_s;
  msb_fifo_in_first_s              <= in_fork_out1_first_s;
  msb_fifo_in_last_s               <= in_fork_out1_last_s;
  msb_fifo_in_data_s               <= in_fork_out1_data_s((DATA_WIDTH/2)-1 downto 0) when (cfg_half_width_i = '1') else in_fork_out1_data_s(DATA_WIDTH-1 downto DATA_WIDTH/2);

  -- Mapping Input Stream Fork Block's Output Interface 0
  -- to LSB FIFO Input Mux's Input Interface
  in_fork_out0_ready_s             <= '1' when (cfg_half_width_i = '1') else lsb_fifo_in_mux_in_ready_s;
  lsb_fifo_in_mux_in_valid_s       <= in_fork_out0_valid_s;
  lsb_fifo_in_mux_in_first_s       <= in_fork_out0_first_s;
  lsb_fifo_in_mux_in_last_s        <= in_fork_out0_last_s;
  lsb_fifo_in_mux_in_data_s        <= in_fork_out0_data_s((DATA_WIDTH/2)-1 downto 0);


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ---------------------------------------------------------------------
  -- Forks an input event stream into a number of output interfaces.
  in_fork_u : axi4s_fork_1_2
  generic map (
    DATA_WIDTH => DATA_WIDTH
  )
  port map (
    -- Core clock and reset
    clk          => clk,
    arst_n       => arst_n,
    srst         => srst,
    
    -- Input event stream interface
    in_ready_o   => in_ready_o,
    in_valid_i   => in_valid_i,
    in_first_i   => in_first_i,
    in_last_i    => in_last_i,
    in_data_i    => in_data_i,
    
    -- Output 0 event stream interface
    out0_ready_i => in_fork_out0_ready_s,
    out0_valid_o => in_fork_out0_valid_s,
    out0_first_o => in_fork_out0_first_s,
    out0_last_o  => in_fork_out0_last_s,
    out0_data_o  => in_fork_out0_data_s,
    
    -- Output 1 event stream interface
    out1_ready_i => in_fork_out1_ready_s,
    out1_valid_o => in_fork_out1_valid_s,
    out1_first_o => in_fork_out1_first_s,
    out1_last_o  => in_fork_out1_last_s,
    out1_data_o  => in_fork_out1_data_s
  );


  ----------------------------------------
  -- AXI4-Stream MSB Data Synchronous FIFO
  msb_fifo_u : axi4s_sync_fifo
  generic map (
    DATA_WIDTH  => DATA_WIDTH/2, -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
    MEMORY_TYPE => MEMORY_TYPE,  -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    DEPTH       => DEPTH
  )
  port map (
    -- Clock and Reset
    clk         => clk,
    arst_n      => arst_n,
    srst        => srst,

    -- Input Interface
    in_ready_o  => msb_fifo_in_ready_s,
    in_valid_i  => msb_fifo_in_valid_s,
    in_first_i  => msb_fifo_in_first_s,
    in_last_i   => msb_fifo_in_last_s,
    in_data_i   => msb_fifo_in_data_s,

    -- Output Interface
    out_ready_i => msb_fifo_out_ready_s,
    out_valid_o => msb_fifo_out_valid_s,
    out_first_o => msb_fifo_out_first_s,
    out_last_o  => msb_fifo_out_last_s,
    out_data_o  => msb_fifo_out_data_s
  );


  ---------------------------------------------------------------------
  -- Demultiplexes an input event stream into either one of the
  -- output interfaces according to the output selection signal.
  -- When out_select_i is '0', output events are sent via the "out0"
  -- interface, while when out_select_i is '1', output events are sent
  -- via the "out1" interface.
  msb_fifo_out_demux_u : axi4s_demux_1_2
  generic map (
    DATA_WIDTH => DATA_WIDTH/2
  )
  port map (
    -- Core clock and reset
    clk          => clk,
    arst_n       => arst_n,
    srst         => srst,

    -- Output selection control
    out_select_i => msb_fifo_out_demux_out_select_s,

    -- Input event stream interface
    in_ready_o   => msb_fifo_out_ready_s,
    in_valid_i   => msb_fifo_out_valid_s,
    in_first_i   => msb_fifo_out_first_s,
    in_last_i    => msb_fifo_out_last_s,
    in_data_i    => msb_fifo_out_data_s,

    -- Output 0 event stream interface
    out0_ready_i => msb_fifo_out_demux_out0_ready_s,
    out0_valid_o => msb_fifo_out_demux_out0_valid_s,
    out0_first_o => msb_fifo_out_demux_out0_first_s,
    out0_last_o  => msb_fifo_out_demux_out0_last_s,
    out0_data_o  => msb_fifo_out_demux_out0_data_s,

    -- Output 1 event stream interface
    out1_ready_i => msb_fifo_out_demux_out1_ready_s,
    out1_valid_o => msb_fifo_out_demux_out1_valid_s,
    out1_first_o => msb_fifo_out_demux_out1_first_s,
    out1_last_o  => msb_fifo_out_demux_out1_last_s,
    out1_data_o  => msb_fifo_out_demux_out1_data_s
  );


  ---------------------------------------------------------------------
  -- Multiplexes one of the input streams into the output interface
  -- according to the input selection signal.
  -- When in_select_i is '0', data of the "in0" interface is forwarded
  -- to the output interface, whereas when in_select_i is '1',
  -- data of the "in1" interface are forwarded to the output interface.
  lsb_fifo_in_mux_u : axi4s_mux_2_1
  generic map (
    DATA_WIDTH => DATA_WIDTH/2
  )
  port map (
    -- Core clock and reset
    clk          => clk,
    arst_n       => arst_n,
    srst         => srst,

    -- Input selection control
    in_select_i  => lsb_fifo_in_mux_in_select_s,

    -- Input 0 stream interface
    in0_ready_o  => lsb_fifo_in_mux_in_ready_s,
    in0_valid_i  => lsb_fifo_in_mux_in_valid_s,
    in0_first_i  => lsb_fifo_in_mux_in_first_s,
    in0_last_i   => lsb_fifo_in_mux_in_last_s,
    in0_data_i   => lsb_fifo_in_mux_in_data_s,

    -- Input 1 stream interface
    in1_ready_o  => msb_fifo_out_demux_out1_ready_s,
    in1_valid_i  => msb_fifo_out_demux_out1_valid_s,
    in1_first_i  => msb_fifo_out_demux_out1_first_s,
    in1_last_i   => msb_fifo_out_demux_out1_last_s,
    in1_data_i   => msb_fifo_out_demux_out1_data_s,

    -- Output event stream interface
    out_ready_i  => lsb_fifo_in_mux_out_ready_s,
    out_valid_o  => lsb_fifo_in_mux_out_valid_s,
    out_first_o  => lsb_fifo_in_mux_out_first_s,
    out_last_o   => lsb_fifo_in_mux_out_last_s,
    out_data_o   => lsb_fifo_in_mux_out_data_s
  );


  ----------------------------------------
  -- AXI4-Stream LSB Data Synchronous FIFO
  lsb_fifo_u : axi4s_sync_fifo
  generic map (
    DATA_WIDTH  => DATA_WIDTH/2, -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
    MEMORY_TYPE => MEMORY_TYPE,  -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    DEPTH       => DEPTH
  )
  port map (
    -- Clock and Reset
    clk         => clk,
    arst_n      => arst_n,
    srst        => srst,

    -- Input Interface
    in_ready_o  => lsb_fifo_in_mux_out_ready_s,
    in_valid_i  => lsb_fifo_in_mux_out_valid_s,
    in_first_i  => lsb_fifo_in_mux_out_first_s,
    in_last_i   => lsb_fifo_in_mux_out_last_s,
    in_data_i   => lsb_fifo_in_mux_out_data_s,

    -- Output Interface
    out_ready_i => lsb_fifo_out_ready_s,
    out_valid_o => lsb_fifo_out_valid_s,
    out_first_o => lsb_fifo_out_first_s,
    out_last_o  => lsb_fifo_out_last_s,
    out_data_o  => lsb_fifo_out_data_s
  );


  -------------------------------------------------------------------
  -- Merges LSB and MSB Stream into a Single Output Stream, according
  -- to event type.
  merge_u :axi4s_cfg_fifo_merge_2_1
  generic map (
    IN_DATA_WIDTH  => DATA_WIDTH/2,
    OUT_DATA_WIDTH => DATA_WIDTH
  )
  port map (
    -- Clock and Reset
    clk            => clk,
    arst_n         => arst_n,
    srst           => srst,

    -- Configuration Interface
    cfg_in_sel_i   => merge_cfg_in_sel_s,

    -- Input Event Stream MSB Data Interface
    in_msb_ready_o => msb_fifo_out_demux_out0_ready_s,
    in_msb_valid_i => msb_fifo_out_demux_out0_valid_s,
    in_msb_first_i => msb_fifo_out_demux_out0_first_s,
    in_msb_last_i  => msb_fifo_out_demux_out0_last_s,
    in_msb_data_i  => msb_fifo_out_demux_out0_data_s,

    -- Input Event Stream LSB Data Interface
    in_lsb_ready_o => lsb_fifo_out_ready_s,
    in_lsb_valid_i => lsb_fifo_out_valid_s,
    in_lsb_first_i => lsb_fifo_out_first_s,
    in_lsb_last_i  => lsb_fifo_out_last_s,
    in_lsb_data_i  => lsb_fifo_out_data_s,

    -- Output Event Stream Data Interface
    out_ready_i    => out_ready_i,
    out_valid_o    => out_valid_o,
    out_first_o    => out_first_o,
    out_last_o     => out_last_o,
    out_data_o     => out_data_o
  );

end rtl;
