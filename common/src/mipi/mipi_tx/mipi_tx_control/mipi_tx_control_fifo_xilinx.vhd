----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Ludovic Chotard (lchotard@chronocam.com)
--
-- Create Date:    Dec. 28, 2017
-- Design Name:    mipi_tx_control_fifo
-- Module Name:    mipi_tx_control_fifo
-- Project Name:   ccam4_single_sisley
-- Target Devices: Lattice Machox3L
-- Tool versions:  Lattice Diamond 3.9.0
-- Description:    MIPI TX Control FIFO Block
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.ccam_evt_types.all;
use work.ccam_utils.all;


-----------------------------
-- MIPI TX Control FIFO Block
entity mipi_tx_control_fifo is
  generic (
    DATA_WIDTH        : integer := 8;    -- FIFO Data Width
    DATA_DEPTH        : integer := 32;   -- FIFO Data Depth (<= 32)
    BYPASS_FIFO       : boolean := false -- Bypasses the FIFO and instantiates a pipeline stage instead
  );
  port (
    -- Clock and Reset
    clk                : in  std_logic;
    arst_n             : in  std_logic;
    srst               : in  std_logic;

    -- Input Interface
    in_ready_o         : out std_logic;
    in_valid_i         : in  std_logic;
    in_last_i          : in  std_logic;
    in_first_i         : in  std_logic;
    in_data_i          : in  std_logic_vector(DATA_WIDTH-1 downto 0);

    -- Output Interface
    out_ready_i        : in  std_logic;
    out_valid_o        : out std_logic;
    out_last_o         : out std_logic;
    out_first_o        : out std_logic;
    out_data_o         : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end mipi_tx_control_fifo;


architecture rtl of mipi_tx_control_fifo is
  
  
  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant MEMORY_TYPE : string := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.


  ----------------------------
  -- Component Declarations --
  ----------------------------


  -----------------------------
  -- AXI4-Stream Pipeline Stage
  component axi4_pipeline_stage is
    generic (
      DATA_WIDTH : positive := 32
    );
    port (
      -- Clock and Reset
      clk         : in  std_logic;
      rst         : in  std_logic;
      
      -- Input Interface
      in_ready_o  : out std_logic;
      in_valid_i  : in  std_logic;
      in_last_i   : in  std_logic;
      in_first_i  : in  std_logic;
      in_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
  
      -- Output Interface
      out_ready_i : in  std_logic;
      out_valid_o : out std_logic;
      out_last_o  : out std_logic;
      out_first_o : out std_logic;
      out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component axi4_pipeline_stage;


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


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Derived Clock and Reset Signals
  signal rst_s : std_logic;


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Derived Clock and Reset Signals
  rst_s  <= not(arst_n) or srst;


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------

  ----------------------------------------------------------------------------------------------
  -- Generate the instantiation of the internal FIFO components in case the FIFO is not bypassed
  no_bypass_fifo_gen : if (BYPASS_FIFO = false) generate

    ---------------------------------------
    -- MIPI TX Control FIFO IP from Xilinx
    mipi_tx_control_fifo_ip_u : axi4s_sync_fifo
    generic map (
      DATA_WIDTH  => DATA_WIDTH,     -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
      MEMORY_TYPE => MEMORY_TYPE, -- Allowed values: auto, block, distributed, ultra. Default value = auto.
      DEPTH       => DATA_DEPTH
    )
    port map (
      -- Clock and Reset
      clk         => clk,
      arst_n      => arst_n,
      srst        => srst,
  
      -- Input Interface
      in_ready_o  => in_ready_o,
      in_valid_i  => in_valid_i,
      in_first_i  => in_first_i,
      in_last_i   => in_last_i,
      in_data_i   => in_data_i,
  
      -- Output Interface
      out_ready_i => out_ready_i,
      out_valid_o => out_valid_o,
      out_first_o => out_first_o,
      out_last_o  => out_last_o,
      out_data_o  => out_data_o
    );

  end generate no_bypass_fifo_gen;


  --------------------------------------------------------------------------------
  -- Generate the instantiation of the pipeline stage in case the FIFO is bypassed
  bypass_fifo_gen : if (BYPASS_FIFO = true) generate

    -----------------------------
    -- AXI4-Stream Pipeline Stage
    axi4_pipeline_stage_u : axi4_pipeline_stage
    generic map (
      DATA_WIDTH  => DATA_WIDTH
    )
    port map (
      -- Clock and Reset
      clk         => clk,
      rst         => rst_s,
      
      -- Input Interface
      in_ready_o  => in_ready_o,
      in_valid_i  => in_valid_i,
      in_last_i   => in_last_i,
      in_first_i  => in_first_i,
      in_data_i   => in_data_i,

      -- Output Interface
      out_ready_i => out_ready_i,
      out_valid_o => out_valid_o,
      out_last_o  => out_last_o,
      out_first_o => out_first_o,
      out_data_o  => out_data_o
    );

  end generate bypass_fifo_gen;

end rtl;
