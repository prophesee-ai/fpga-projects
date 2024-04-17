-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library xpm;
use xpm.vcomponents.all;

library work;
use work.ccam_utils_pkg.all;


-------------------------------
-- AXI4-Stream Asynchronous FIFO
entity axi4s_fifo_xpm is
  generic (
    DATA_WIDTH_G          : positive                     := 32;     -- FIFO_WIDTH = DATA_WIDTH_G + 2 (for first and last bits)
    MEMORY_TYPE_G         : string                       := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    PROG_FULL_THRESH_G    : positive range  5 to 4194304 := 2048;   -- max value is DEPTH_G-5
    DEPTH_G               : positive range 16 to 4194304 := 2048
  );
  port (
    -- Clock and Reset
    clk                 : in  std_logic;
    srst                : in  std_logic;

    -- Control Interface
    in_almost_full_o    : out std_logic;
    in_prog_full_o      : out std_logic;

    -- Input Interface
    in_ready_o          : out std_logic;
    in_valid_i          : in  std_logic;
    in_first_i          : in  std_logic;
    in_last_i           : in  std_logic;
    in_data_i           : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

    -- Output Interface
    out_ready_i         : in  std_logic;
    out_valid_o         : out std_logic;
    out_first_o         : out std_logic;
    out_last_o          : out std_logic;
    out_data_o          : out std_logic_vector(DATA_WIDTH_G-1 downto 0)
  );
end entity axi4s_fifo_xpm;

architecture rtl of axi4s_fifo_xpm is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant FIFO_DATA_WIDTH_C       : positive := DATA_WIDTH_G + 2;  -- DATA_WIDTH_G bits for data + 1 bit for fist + 1 bit for last
  constant FIFO_DATA_COUNT_WIDTH_C : positive := 1;               -- Minimum: 1


  ----------------------------
  -- Component Declarations --
  ----------------------------


  ---------------------
  -- Reset Synchronizer
  component rst_synchronizer is
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
  end component rst_synchronizer;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input Interface Signals
  signal in_ready_s           : std_logic;
  signal in_sample_s          : std_logic;
  signal in_data_s            : std_logic_vector(DATA_WIDTH_G+1 downto 0);

  -- Output Interface Signals
  signal out_sample_s         : std_logic;
  signal out_valid_s          : std_logic;
  signal out_data_s           : std_logic_vector(DATA_WIDTH_G+1 downto 0);

  -- FIFO Signals
  signal fifo_almost_empty_s  : std_logic;                                          -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                                                                    -- only one more read can be performed before the FIFO goes to empty.
  signal fifo_almost_full_s   : std_logic;                                          -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                                                                    -- only one more write can be performed before the FIFO is full.
  signal fifo_data_valid_s    : std_logic;                                          -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                                                                    -- that valid data is available on the output bus (dout).
  signal fifo_dbiterr_s       : std_logic;                                          -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                                                                    -- detected a double-bit error and data in the FIFO core is corrupted.
  signal fifo_dout_s          : std_logic_vector(FIFO_DATA_WIDTH_C-1 downto 0);       -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                                                                    -- when reading the FIFO.
  signal fifo_empty_s         : std_logic;                                          -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                                                                    -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                                                                    -- initiating a read while empty is not destructive to the FIFO.
  signal fifo_full_s          : std_logic;                                          -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                                                                    -- FIFO is full. Write requests are ignored when the FIFO is full,
                                                                                    -- initiating a write when the FIFO is full is not destructive to the
                                                                                    -- contents of the FIFO.
  signal fifo_overflow_s      : std_logic;                                          -- 1-bit output: Overflow: This signal indicates that a write request
                                                                                    -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                                                                    -- full. Overflowing the FIFO is not destructive to the contents of the
                                                                                    -- FIFO.
  signal fifo_prog_empty_s    : std_logic;                                          -- 1-bit output: Programmable Empty: This signal is asserted when the
                                                                                    -- number of words in the FIFO is less than or equal to the programmable
                                                                                    -- empty threshold value. It is de-asserted when the number of words in
                                                                                    -- the FIFO exceeds the programmable empty threshold value.
  signal fifo_prog_full_s     : std_logic;                                          -- 1-bit output: Programmable Full: This signal is asserted when the
                                                                                    -- number of words in the FIFO is greater than or equal to the
                                                                                    -- programmable full threshold value. It is de-asserted when the number
                                                                                    -- of words in the FIFO is less than the programmable full threshold
                                                                                    -- value.
  signal fifo_rd_data_count_s : std_logic_vector(FIFO_DATA_COUNT_WIDTH_C-1 downto 0); -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                                                                    -- the number of words read from the FIFO.
  signal fifo_rd_rst_busy_s   : std_logic;                                          -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                                                                    -- read domain is currently in a reset state.
  signal fifo_sbiterr_s       : std_logic;                                          -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                                                                    -- detected and fixed a single-bit error.
  signal fifo_underflow_s     : std_logic;                                          -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                                                                    -- during the previous clock cycle was rejected because the FIFO is
                                                                                    -- empty. Under flowing the FIFO is not destructive to the FIFO.
  signal fifo_wr_ack_s        : std_logic;                                          -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                                                                    -- request (wr_en) during the prior clock cycle is succeeded.
  signal fifo_wr_data_count_s : std_logic_vector(FIFO_DATA_COUNT_WIDTH_C-1 downto 0); -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                                                                    -- the number of words written into the FIFO.
  signal fifo_wr_rst_busy_s   : std_logic;                                          -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                                                                    -- write domain is currently in a reset state.
  signal fifo_din_s           : std_logic_vector(FIFO_DATA_WIDTH_C-1 downto 0);       -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                                                                    -- writing the FIFO.
  signal fifo_injectdbiterr_s : std_logic;                                          -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                                                                    -- the ECC feature is used on block RAMs or UltraRAM macros.
  signal fifo_injectsbiterr_s : std_logic;                                          -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                                                                    -- the ECC feature is used on block RAMs or UltraRAM macros.
  signal fifo_rd_en_s         : std_logic;                                          -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                                                                    -- signal causes data (on dout) to be read from the FIFO. Must be held
                                                                                    -- active-low when rd_rst_busy is active high. .
  signal fifo_rst_sync_s      : std_logic;
  signal fifo_sleep_s         : std_logic;                                          -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                                                                    -- block is in power saving mode.
  signal fifo_wr_en_s         : std_logic;                                          -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                                                                    -- signal causes data (on din) to be written to the FIFO Must be held
                                                                                    -- active-low when rst or wr_rst_busy or rd_rst_busy is active high

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Map Input Interface
  in_data_s(DATA_WIDTH_G+1)           <= in_last_i;
  in_data_s(DATA_WIDTH_G)             <= in_first_i;
  in_data_s(DATA_WIDTH_G-1 downto 0)  <= in_data_i;
  in_ready_s                          <= not (fifo_full_s or srst or fifo_wr_rst_busy_s);
  in_sample_s                         <= in_ready_s and in_valid_i;
  in_ready_o                          <= in_ready_s;

  -- Determine when the FIFO data should be read
  out_sample_s                        <= out_ready_i and out_valid_s and (not (srst or fifo_rd_rst_busy_s));
  out_valid_o                         <= out_valid_s;
  out_data_o                          <= out_data_s(DATA_WIDTH_G-1 downto 0);
  out_first_o                         <= out_data_s(DATA_WIDTH_G);
  out_last_o                          <= out_data_s(DATA_WIDTH_G+1);

  -- Map FIFO Signals
  out_valid_s                         <= fifo_data_valid_s;
  out_data_s                          <= fifo_dout_s;
  fifo_din_s                          <= in_data_s;
  fifo_injectdbiterr_s                <= '0';
  fifo_injectsbiterr_s                <= '0';
  fifo_rd_en_s                        <= out_sample_s;
  fifo_sleep_s                        <= '0';
  fifo_wr_en_s                        <= in_sample_s;


  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------


  ---------------------
  -- Reset Synchronizer
  fifo_rst_sync_u : rst_synchronizer
  generic map (
    SYNC_DEPTH       => 2,   -- Synchronizer depth, the number of
                             -- registers in the chain
    POST_SYNC_DEPTH  => 2    -- Post synchronization register chain depth
  )
  port map (
    clk   => clk,         -- Destination clock
    rst   => srst,           -- Asynchronous reset, active high
    rst_o => fifo_rst_sync_s
  );


  -- XPM_FIFO instantiation template for Asynchronous FIFO configurations
  -- Refer to the targeted device family architecture libraries guide for XPM_FIFO documentation
  -- =======================================================================================================================

  -- Parameter usage table, organized as follows:
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | Parameter name       | Data type          | Restrictions, if applicable                                             |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Description                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | CDC_SYNC_STAGES      | Integer            | Range: 2 - 8. Default value = 2.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies the number of synchronization stages on the CDC path                                                      |
  -- |                                                                                                                     |
  -- |  Must be < 5 if FIFO_WRITE_DEPTH = 16                                                                               |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | DOUT_RESET_VALUE     | String             | Default value = 0.                                                      |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Reset value of read data path.                                                                                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | ECC_MODE             | String             | Allowed values: no_ecc, en_ecc. Default value = no_ecc.                 |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- |                                                                                                                     |
  -- |  "no_ecc" - Disables ECC                                                                                            |
  -- |   "en_ecc" - Enables both ECC Encoder and Decoder                                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | FIFO_MEMORY_TYPE     | String             | Allowed values: auto, block, distributed. Default value = auto.         |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Designate the fifo memory primitive (resource type) to use-                                                         |
  -- |                                                                                                                     |
  -- |  "auto"- Allow Vivado Synthesis to choose                                                                           |
  -- |   "block"- Block RAM FIFO                                                                                           |
  -- |   "distributed"- Distributed RAM FIFO                                                                               |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | FIFO_READ_LATENCY    | Integer            | Range: 0 - 10. Default value = 1.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Number of output register stages in the read data path.                                                             |
  -- |                                                                                                                     |
  -- |  If READ_MODE = "fwft", then the only applicable value is 0.                                                        |
  -- | .                                                                                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | FIFO_WRITE_DEPTH     | Integer            | Range: 16 - 4194304. Default value = 2048.                              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Defines the FIFO Write Depth, must be power of two                                                                  |
  -- |                                                                                                                     |
  -- |  In standard READ_MODE, the effective depth = FIFO_WRITE_DEPTH-1                                                    |
  -- |   In First-Word-Fall-Through READ_MODE, the effective depth = FIFO_WRITE_DEPTH+1                                    |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | FULL_RESET_VALUE     | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Sets full, almost_full and prog_full to FULL_RESET_VALUE during reset                                               |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | PROG_EMPTY_THRESH    | Integer            | Range: 3 - 4194301. Default value = 10.                                 |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies the minimum number of read words in the FIFO at or below which prog_empty is asserted.                    |
  -- |                                                                                                                     |
  -- |   Min_Value = 3 + (READ_MODE_VAL*2)                                                                                 |
  -- |   Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2)                                                              |
  -- |                                                                                                                     |
  -- | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
  -- | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
  -- | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | PROG_FULL_THRESH     | Integer            | Range: 5 - 4194301. Default value = 10.                                 |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies the maximum number of write words in the FIFO at or above which prog_full is asserted.                    |
  -- |                                                                                                                     |
  -- |  Min_Value = 3 + (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))+CDC_SYNC_STAGES                               |
  -- |   Max_Value = (FIFO_WRITE_DEPTH-3) - (READ_MODE_VAL*2*(FIFO_WRITE_DEPTH/FIFO_READ_DEPTH))                           |
  -- |                                                                                                                     |
  -- | If READ_MODE = "std", then READ_MODE_VAL = 0; Otherwise READ_MODE_VAL = 1                                           |
  -- | NOTE: The default threshold value is dependent on default FIFO_WRITE_DEPTH value. If FIFO_WRITE_DEPTH value is      |
  -- | changed, ensure the threshold value is within the valid range though the programmable flags are not used.           |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | RD_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies the width of rd_data_count                                                                                |
  -- |                                                                                                                     |
  -- |  FIFO_READ_DEPTH = FIFO_WRITE_DEPTH*WRITE_DATA_WIDTH/READ_DATA_WIDTH                                                |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | READ_DATA_WIDTH      | Integer            | Range: 1 - 4096. Default value = 32.                                    |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Defines the width of the read data port, dout                                                                       |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | READ_MODE            | String             | Allowed values: std, fwft. Default value = std.                         |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- |                                                                                                                     |
  -- |  "std"- standard read mode                                                                                          |
  -- |   "fwft"- First-Word-Fall-Through read mode                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | RELATED_CLOCKS       | Integer            | Range: 0 - 1. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies if the wr_clk and rd_clk are related having the same source but different clock ratios                    |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | USE_ADV_FEATURES     | String             | Default value = 0707.                                                   |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Enables data_valid, almost_empty, rd_data_count, prog_empty, underflow, wr_ack, almost_full, wr_data_count,         |
  -- | prog_full, overflow features.                                                                                       |
  -- |                                                                                                                     |
  -- |  Setting USE_ADV_FEATURES[0]  to 1 enables overflow flag;     Default value of this bit is 1                        |
  -- |   Setting USE_ADV_FEATURES[1]  to 1 enables prog_full flag;    Default value of this bit is 1                       |
  -- |   Setting USE_ADV_FEATURES[2]  to 1 enables wr_data_count;     Default value of this bit is 1                       |
  -- |   Setting USE_ADV_FEATURES[3]  to 1 enables almost_full flag;  Default value of this bit is 0                       |
  -- |   Setting USE_ADV_FEATURES[4]  to 1 enables wr_ack flag;       Default value of this bit is 0                       |
  -- |   Setting USE_ADV_FEATURES[8]  to 1 enables underflow flag;    Default value of this bit is 1                       |
  -- |   Setting USE_ADV_FEATURES[9]  to 1 enables prog_empty flag;   Default value of this bit is 1                       |
  -- |   Setting USE_ADV_FEATURES[10] to 1 enables rd_data_count;     Default value of this bit is 1                       |
  -- |   Setting USE_ADV_FEATURES[11] to 1 enables almost_empty flag; Default value of this bit is 0                       |
  -- |   Setting USE_ADV_FEATURES[12] to 1 enables data_valid flag;   Default value of this bit is 0                       |
  -- | .                                                                                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | WAKEUP_TIME          | Integer            | Range: 0 - 2. Default value = 0.                                        |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- |                                                                                                                     |
  -- |  0 - Disable sleep                                                                                                  |
  -- |   2 - Use Sleep Pin                                                                                                 |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | WRITE_DATA_WIDTH     | Integer            | Range: 1 - 4096. Default value = 32.                                    |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Defines the width of the write data port, din                                                                       |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | WR_DATA_COUNT_WIDTH  | Integer            | Range: 1 - 23. Default value = 1.                                       |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Specifies the width of wr_data_count                                                                                |
  -- +---------------------------------------------------------------------------------------------------------------------+

  -- Port usage table, organized as follows:
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | Port name      | Direction | Size, in bits                         | Domain  | Sense       | Handling if unused     |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Description                                                                                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | almost_empty   | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Almost Empty : When asserted, this signal indicates that only one more read can be performed before the FIFO goes to|
  -- | empty.                                                                                                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | almost_full    | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Almost Full: When asserted, this signal indicates that only one more write can be performed before the FIFO is full.|
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | data_valid     | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read Data Valid: When asserted, this signal indicates that valid data is available on the output bus (dout).        |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | dbiterr        | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Double Bit Error: Indicates that the ECC decoder detected a double-bit error and data in the FIFO core is corrupted.|
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | din            | Input     | WRITE_DATA_WIDTH                      | wr_clk  | NA          | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write Data: The input data bus used when writing the FIFO.                                                          |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | dout           | Output    | READ_DATA_WIDTH                       | rd_clk  | NA          | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read Data: The output data bus is driven when reading the FIFO.                                                     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | empty          | Output    | 1                                     | rd_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Empty Flag: When asserted, this signal indicates that the FIFO is empty.                                            |
  -- | Read requests are ignored when the FIFO is empty, initiating a read while empty is not destructive to the FIFO.     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | full           | Output    | 1                                     | wr_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Full Flag: When asserted, this signal indicates that the FIFO is full.                                              |
  -- | Write requests are ignored when the FIFO is full, initiating a write when the FIFO is full is not destructive       |
  -- | to the contents of the FIFO.                                                                                        |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | injectdbiterr  | Input     | 1                                     | wr_clk  | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Double Bit Error Injection: Injects a double bit error if the ECC feature is used on block RAMs or                  |
  -- | UltraRAM macros.                                                                                                    |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | injectsbiterr  | Input     | 1                                     | wr_clk  | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Single Bit Error Injection: Injects a single bit error if the ECC feature is used on block RAMs or                  |
  -- | UltraRAM macros.                                                                                                    |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | overflow       | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Overflow: This signal indicates that a write request (wren) during the prior clock cycle was rejected,              |
  -- | because the FIFO is full. Overflowing the FIFO is not destructive to the contents of the FIFO.                      |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | prog_empty     | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Programmable Empty: This signal is asserted when the number of words in the FIFO is less than or equal              |
  -- | to the programmable empty threshold value.                                                                          |
  -- | It is de-asserted when the number of words in the FIFO exceeds the programmable empty threshold value.              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | prog_full      | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Programmable Full: This signal is asserted when the number of words in the FIFO is greater than or equal            |
  -- | to the programmable full threshold value.                                                                           |
  -- | It is de-asserted when the number of words in the FIFO is less than the programmable full threshold value.          |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rd_clk         | Input     | 1                                     | NA      | Rising edge | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read clock: Used for read operation. rd_clk must be a free running clock.                                           |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rd_data_count  | Output    | RD_DATA_COUNT_WIDTH                   | rd_clk  | NA          | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read Data Count: This bus indicates the number of words read from the FIFO.                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rd_en          | Input     | 1                                     | rd_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read Enable: If the FIFO is not empty, asserting this signal causes data (on dout) to be read from the FIFO.        |
  -- |                                                                                                                     |
  -- |  Must be held active-low when rd_rst_busy is active high.                                                           |
  -- | .                                                                                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rd_rst_busy    | Output    | 1                                     | rd_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Read Reset Busy: Active-High indicator that the FIFO read domain is currently in a reset state.                     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | rst            | Input     | 1                                     | wr_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Reset: Must be synchronous to wr_clk. Must be applied only when wr_clk is stable and free-running.                  |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | sbiterr        | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Single Bit Error: Indicates that the ECC decoder detected and fixed a single-bit error.                             |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | sleep          | Input     | 1                                     | NA      | Active-high | Tie to 1'b0            |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Dynamic power saving: If sleep is High, the memory/fifo block is in power saving mode.                              |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | underflow      | Output    | 1                                     | rd_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Underflow: Indicates that the read request (rd_en) during the previous clock cycle was rejected                     |
  -- | because the FIFO is empty. Under flowing the FIFO is not destructive to the FIFO.                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | wr_ack         | Output    | 1                                     | wr_clk  | Active-high | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write Acknowledge: This signal indicates that a write request (wr_en) during the prior clock cycle is succeeded.    |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | wr_clk         | Input     | 1                                     | NA      | Rising edge | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write clock: Used for write operation. wr_clk must be a free running clock.                                         |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | wr_data_count  | Output    | WR_DATA_COUNT_WIDTH                   | wr_clk  | NA          | DoNotCare              |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write Data Count: This bus indicates the number of words written into the FIFO.                                     |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | wr_en          | Input     | 1                                     | wr_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write Enable: If the FIFO is not full, asserting this signal causes data (on din) to be written to the FIFO.        |
  -- |                                                                                                                     |
  -- |  Must be held active-low when rst or wr_rst_busy is active high.                                                    |
  -- | .                                                                                                                   |
  -- +---------------------------------------------------------------------------------------------------------------------+
  -- | wr_rst_busy    | Output    | 1                                     | wr_clk  | Active-high | Required               |
  -- |---------------------------------------------------------------------------------------------------------------------|
  -- | Write Reset Busy: Active-High indicator that the FIFO write domain is currently in a reset state.                   |
  -- +---------------------------------------------------------------------------------------------------------------------+




  ---------------------------------------------
  -- xpm_fifo_sync: Synchronous FIFO
  -- Xilinx Parameterized Macro, version 2018.2
  fifo_u : xpm_fifo_sync
  generic map (
    DOUT_RESET_VALUE    => "0",                     -- String
    ECC_MODE            => "no_ecc",                -- String
    FIFO_MEMORY_TYPE    => MEMORY_TYPE_G,           -- String
    FIFO_READ_LATENCY   => 0,                       -- Decimal
    FIFO_WRITE_DEPTH    => DEPTH_G,                 -- Decimal
    FULL_RESET_VALUE    => 0,                       -- Decimal
    PROG_EMPTY_THRESH   => 5,                       -- Decimal
    PROG_FULL_THRESH    => PROG_FULL_THRESH_G,      -- Decimal
    RD_DATA_COUNT_WIDTH => FIFO_DATA_COUNT_WIDTH_C, -- Decimal
    READ_DATA_WIDTH     => FIFO_DATA_WIDTH_C,       -- Decimal
    READ_MODE           => "fwft",                  -- String
    USE_ADV_FEATURES    => "1002",                  -- String
    WAKEUP_TIME         => 0,                       -- Decimal
    WRITE_DATA_WIDTH    => FIFO_DATA_WIDTH_C,       -- Decimal
    WR_DATA_COUNT_WIDTH => FIFO_DATA_COUNT_WIDTH_C  -- Decimal
  )
  port map (
    almost_empty  => fifo_almost_empty_s,  -- 1-bit output: Almost Empty : When asserted, this signal indicates that
                                           -- only one more read can be performed before the FIFO goes to empty.
    almost_full   => in_almost_full_o,     -- 1-bit output: Almost Full: When asserted, this signal indicates that
                                           -- only one more write can be performed before the FIFO is full.
    data_valid    => fifo_data_valid_s,    -- 1-bit output: Read Data Valid: When asserted, this signal indicates
                                           -- that valid data is available on the output bus (dout).
    dbiterr       => fifo_dbiterr_s,       -- 1-bit output: Double Bit Error: Indicates that the ECC decoder
                                           -- detected a double-bit error and data in the FIFO core is corrupted.
    dout          => fifo_dout_s,          -- READ_DATA_WIDTH-bit output: Read Data: The output data bus is driven
                                           -- when reading the FIFO.
    empty         => fifo_empty_s,         -- 1-bit output: Empty Flag: When asserted, this signal indicates that
                                           -- the FIFO is empty. Read requests are ignored when the FIFO is empty,
                                           -- initiating a read while empty is not destructive to the FIFO.
    full          => fifo_full_s,          -- 1-bit output: Full Flag: When asserted, this signal indicates that the
                                           -- FIFO is full. Write requests are ignored when the FIFO is full,
                                           -- initiating a write when the FIFO is full is not destructive to the
                                           -- contents of the FIFO.
    overflow      => fifo_overflow_s,      -- 1-bit output: Overflow: This signal indicates that a write request
                                           -- (wren) during the prior clock cycle was rejected, because the FIFO is
                                           -- full. Overflowing the FIFO is not destructive to the contents of the
                                           -- FIFO.
    prog_empty    => fifo_prog_empty_s,    -- 1-bit output: Programmable Empty: This signal is asserted when the
                                           -- number of words in the FIFO is less than or equal to the programmable
                                           -- empty threshold value. It is de-asserted when the number of words in
                                           -- the FIFO exceeds the programmable empty threshold value.
    prog_full     => in_prog_full_o,       -- 1-bit output: Programmable Full: This signal is asserted when the
                                           -- number of words in the FIFO is greater than or equal to the
                                           -- programmable full threshold value. It is de-asserted when the number
                                           -- of words in the FIFO is less than the programmable full threshold
                                           -- value.
    rd_data_count => fifo_rd_data_count_s, -- RD_DATA_COUNT_WIDTH-bit output: Read Data Count: This bus indicates
                                           -- the number of words read from the FIFO.
    rd_rst_busy   => fifo_rd_rst_busy_s,   -- 1-bit output: Read Reset Busy: Active-High indicator that the FIFO
                                           -- read domain is currently in a reset state.
    sbiterr       => fifo_sbiterr_s,       -- 1-bit output: Single Bit Error: Indicates that the ECC decoder
                                           -- detected and fixed a single-bit error.
    underflow     => fifo_underflow_s,     -- 1-bit output: Underflow: Indicates that the read request (rd_en)
                                           -- during the previous clock cycle was rejected because the FIFO is
                                           -- empty. Under flowing the FIFO is not destructive to the FIFO.
    wr_ack        => fifo_wr_ack_s,        -- 1-bit output: Write Acknowledge: This signal indicates that a write
                                           -- request (wr_en) during the prior clock cycle is succeeded.
    wr_data_count => fifo_wr_data_count_s, -- WR_DATA_COUNT_WIDTH-bit output: Write Data Count: This bus indicates
                                           -- the number of words written into the FIFO.
    wr_rst_busy   => fifo_wr_rst_busy_s,   -- 1-bit output: Write Reset Busy: Active-High indicator that the FIFO
                                           -- write domain is currently in a reset state.
    din           => fifo_din_s,           -- WRITE_DATA_WIDTH-bit input: Write Data: The input data bus used when
                                           -- writing the FIFO.
    injectdbiterr => fifo_injectdbiterr_s, -- 1-bit input: Double Bit Error Injection: Injects a double bit error if
                                           -- the ECC feature is used on block RAMs or UltraRAM macros.
    injectsbiterr => fifo_injectsbiterr_s, -- 1-bit input: Single Bit Error Injection: Injects a single bit error if
                                           -- the ECC feature is used on block RAMs or UltraRAM macros.
    rd_en         => fifo_rd_en_s,         -- 1-bit input: Read Enable: If the FIFO is not empty, asserting this
                                           -- signal causes data (on dout) to be read from the FIFO. Must be held
                                           -- active-low when rd_rst_busy is active high. .
    rst           => fifo_rst_sync_s,      -- 1-bit input: Reset: Must be synchronous to wr_clk. Must be applied
                                           -- only when wr_clk is stable and free-running.
    sleep         => fifo_sleep_s,         -- 1-bit input: Dynamic power saving- If sleep is High, the memory/fifo
                                           -- block is in power saving mode.
    wr_clk        => clk,                  -- 1-bit input: Write clock: Used for write operation. wr_clk must be a
                                           -- free running clock.
    wr_en         => fifo_wr_en_s          -- 1-bit input: Write Enable: If the FIFO is not full, asserting this
                                           -- signal causes data (on din) to be written to the FIFO Must be held
                                           -- active-low when rst or wr_rst_busy or rd_rst_busy is active high
  );


end rtl;
