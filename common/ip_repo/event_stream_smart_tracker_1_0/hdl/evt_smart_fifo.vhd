library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_utils_pkg.all;


------------------------------------
-- Two steps fifo almost full Fifo
entity evt_smart_fifo is 
  generic (
    MEMORY_TYPE_G               : string                       := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.
    DEPTH_G                     : positive range 32 to 4194304 := 2048;
    STEP1_ALMOST_FULL_THRESH_G  : positive range 21 to 4194304 := 2048;
    STEP2_ALMOST_FULL_THRESH_G  : positive range  5 to 4194304 := 2048;
    DATA_WIDTH_G                : positive                     := 32      -- FIFO_WIDTH = DATA_WIDTH_G + 2 (for first and last bits)
  );
  port (
    -- Clock and Reset
    clk                         : in  std_logic;
    srst                        : in  std_logic;

    -- Status Interface
    cfg_fifo_full_flag_o        : out std_logic_vector(1 downto 0);         -- bit0 : first stage full flag, don't drop TH; bit1 : second stage full flag, drop all

    -- Input Interface
    in_ready_o                  : out std_logic;
    in_valid_i                  : in  std_logic;
    in_first_i                  : in  std_logic;
    in_last_i                   : in  std_logic;
    in_data_i                   : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

    -- Output Interface
    out_ready_i                 : in  std_logic;
    out_valid_o                 : out std_logic;
    out_first_o                 : out std_logic;
    out_last_o                  : out std_logic;
    out_data_o                  : out std_logic_vector(DATA_WIDTH_G-1 downto 0)
  );
end entity evt_smart_fifo;



architecture rtl of evt_smart_fifo is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  -- Step2 FIFO depth is (STEP2_PROG_FULL_THRESH_C + STEP2_ALMOST_FULL_THRESH_G)
  -- STEP2_PROG_FULL_THRESH_C Min value is 5
  -- STEP2_FIFO_DEPTH_C Min value is 16
  -- So when STEP2_ALMOST_FULL_THRESH_G is smaller than (16 - 5), the FIFO depth is 16
  constant STEP2_FIFO_DEPTH_C        : positive  := iff(STEP2_ALMOST_FULL_THRESH_G <= 11, 16, 2**(clog2(STEP2_ALMOST_FULL_THRESH_G + 5)));
  constant STEP2_PROG_FULL_THRESH_C  : positive  := STEP2_FIFO_DEPTH_C - STEP2_ALMOST_FULL_THRESH_G;

  constant STEP1_FIFO_WANTED_C       : positive  := DEPTH_G - STEP2_FIFO_DEPTH_C;
  constant STEP1_FIFO_DEPTH_C        : positive  := iff(STEP1_FIFO_WANTED_C < 16, 16, 2**(clog2(STEP1_FIFO_WANTED_C)));
  -- Set STEP1_PROG_FULL_THRESH_C to the maximum allowed value
  constant STEP1_PROG_FULL_THRESH_C  : positive  := STEP1_ALMOST_FULL_THRESH_G - STEP2_FIFO_DEPTH_C;

  
  ----------------------------
  -- Component Declarations --
  ----------------------------

  -------------------------------
  -- AXI4-Stream Asynchronous FIFO
  component axi4s_fifo_xpm is
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
  end component axi4s_fifo_xpm;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input Interface
  signal int_ready_s                  : std_logic;
  signal int_valid_s                  : std_logic;
  signal int_first_s                  : std_logic;
  signal int_last_s                   : std_logic;
  signal int_data_s                   : std_logic_vector(DATA_WIDTH_G-1 downto 0);


begin

  assert STEP1_ALMOST_FULL_THRESH_G > STEP2_ALMOST_FULL_THRESH_G
  report "STEP1_ALMOST_FULL_THRESH_G sould be greater than STEP2_ALMOST_FULL_THRESH_G"
  severity Failure;

  assert STEP1_ALMOST_FULL_THRESH_G > STEP2_FIFO_DEPTH_C
  report "STEP2_FIFO_DEPTH is " & string'(integer'image(STEP2_FIFO_DEPTH_C)) & "; STEP1_ALMOST_FULL_THRESH should be bigger!"
  severity Failure;

  assert DEPTH_G > STEP2_FIFO_DEPTH_C
  report "STEP2_FIFO_DEPTH is " & string'(integer'image(STEP2_FIFO_DEPTH_C)) & "; DEPTH_G should be bigger!"
  severity Failure;

  assert STEP1_FIFO_DEPTH_C + STEP2_FIFO_DEPTH_C = DEPTH_G
  report "STEP2_FIFO_DEPTH is " & string'(integer'image(STEP2_FIFO_DEPTH_C)) & "; FIFO depth realign to " & string'(integer'image(STEP1_FIFO_DEPTH_C + STEP2_FIFO_DEPTH_C)) & "."
  severity Warning;


  -------------------------------
  -- AXI4-Stream Synchronous FIFO
  step2_fifo_u : axi4s_fifo_xpm
    generic map (
      DATA_WIDTH_G          => DATA_WIDTH_G,
      MEMORY_TYPE_G         => MEMORY_TYPE_G,
      PROG_FULL_THRESH_G    => STEP2_PROG_FULL_THRESH_C,
      DEPTH_G               => STEP2_FIFO_DEPTH_C
    )
    port map (
      -- Clock and Reset
      clk                   => clk,
      srst                  => srst,

      -- Control Interface
      in_almost_full_o      => open,
      in_prog_full_o        => cfg_fifo_full_flag_o(1),

      -- Input Interface
      in_ready_o            => in_ready_o,
      in_valid_i            => in_valid_i,
      in_first_i            => in_first_i,
      in_last_i             => in_last_i,
      in_data_i             => in_data_i,

      -- Output Interface
      out_ready_i           => int_ready_s,
      out_valid_o           => int_valid_s,
      out_first_o           => int_first_s,
      out_last_o            => int_last_s,
      out_data_o            => int_data_s
    );
  

  -------------------------------
  -- AXI4-Stream Synchronous FIFO
  step1_fifo_u : axi4s_fifo_xpm
    generic map (
      DATA_WIDTH_G          => DATA_WIDTH_G,
      MEMORY_TYPE_G         => MEMORY_TYPE_G,
      PROG_FULL_THRESH_G    => STEP1_PROG_FULL_THRESH_C,
      DEPTH_G               => STEP1_FIFO_DEPTH_C
    )
    port map (
      -- Clock and Reset
      clk                   => clk,
      srst                  => srst,

      -- Control Interface
      in_almost_full_o      => open,
      in_prog_full_o        => cfg_fifo_full_flag_o(0),

      -- Input Interface
      in_ready_o            => int_ready_s,
      in_valid_i            => int_valid_s,
      in_first_i            => int_first_s,
      in_last_i             => int_last_s,
      in_data_i             => int_data_s,

      -- Output Interface
      out_ready_i           => out_ready_i,
      out_valid_o           => out_valid_o,
      out_first_o           => out_first_o,
      out_last_o            => out_last_o,
      out_data_o            => out_data_o
    );
  
end architecture rtl;



