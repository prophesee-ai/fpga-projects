----------------------------------------------------------------------------------
-- Company:        Prophesee
-- Engineer:       Vitor Schwambach (vschwambach@prophesee.ai)
--
-- Create Date:    Oct. 31, 2019
-- Design Name:    mipi_tx_fifo
-- Module Name:    mipi_tx_fifo
-- Project Name:   ccam4_single_sisley
-- Target Devices: Xilinx Spartan 7
-- Tool versions:  Vivado 2018.2
-- Description:    MIPI TX FIFO
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;


---------------
-- MIPI TX FIFO
entity mipi_tx_fifo is
  generic (
    DATA_WIDTH : positive := 32;   -- Memory Data Width
    DEPTH      : positive := 4096  -- Memory Address Depth
  );
  port (
    -- Clock and Reset
    clk              : in  std_logic;
    arst_n           : in  std_logic;
    srst             : in  std_logic;

    -- Configuration Interface
    cfg_evt_format_i : in  evt_format_data_t;

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
end entity mipi_tx_fifo;

architecture rtl of mipi_tx_fifo is


  ----------------------------
  -- Component Declarations --
  ----------------------------


  --------------------------------------------
  -- Configurable AXI4-Stream Synchronous FIFO
  component axi4s_cfg_sync_fifo is
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
  end component axi4s_cfg_sync_fifo;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Configurable AXI4-Stream Synchronous FIFO Signals -- Configuration Interface
  signal fifo_cfg_half_width_s : std_logic;

begin

  ------------------------------
  -- Asynchronous Assignments --
  ------------------------------

  -- Configurable AXI4-Stream Synchronous FIFO Signals -- Configuration Interface
  fifo_cfg_half_width_s <= '1' when cfg_evt_format_i = EVT_FORMAT_DATA_3_0 else '0';


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  --------------------------------------------
  -- Configurable AXI4-Stream Synchronous FIFO
  fifo_u : axi4s_cfg_sync_fifo
  generic map (
    DATA_WIDTH  => DATA_WIDTH, -- FIFO_WIDTH = DATA_WIDTH + 2 (for first and last bits)
    MEMORY_TYPE => "block",    -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    DEPTH       => DEPTH
  )
  port map (
    -- Clock and Reset
    clk              => clk,
    arst_n           => arst_n,
    srst             => srst,

    -- Configuration Interface
    cfg_half_width_i => fifo_cfg_half_width_s,

    -- Input Interface
    in_ready_o       => in_ready_o,
    in_valid_i       => in_valid_i,
    in_first_i       => in_first_i,
    in_last_i        => in_last_i,
    in_data_i        => in_data_i,

    -- Output Interface
    out_ready_i      => out_ready_i,
    out_valid_o      => out_valid_o,
    out_first_o      => out_first_o,
    out_last_o       => out_last_o,
    out_data_o       => out_data_o
  );

end rtl;
