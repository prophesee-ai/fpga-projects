----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Vitor Schwambach (vschwambach@chronocam.com)
-- 
-- Create Date:    Feb. 21, 2017
-- Design Name:    axi4s_fork_1_2
-- Module Name:    axi4s_fork_1_2
-- Project Name:   epoch_stereo
-- Target Devices: Artix 7
-- Tool versions:  Xilinx Vivado 2016.4
-- Description:    Forks an input event stream into a number of output interfaces.
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
use ieee.numeric_std.all;


---------------------------------------------------------------------
-- Forks an input event stream into a number of output interfaces.
entity axi4s_fork_1_2 is
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
end axi4s_fork_1_2;

architecture rtl of axi4s_fork_1_2 is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant NUM_OUTPUTS : integer := 2;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Input event stream interface
  signal in_ready_q  : std_logic;
  signal in_valid_q  : std_logic;
  signal in_first_q  : std_logic;
  signal in_last_q   : std_logic;
  signal in_data_q   : std_logic_vector(DATA_WIDTH-1 downto 0);

  -- Output event stream interface data
  signal out_ready_q : std_logic_vector(NUM_OUTPUTS-1 downto 0);
  signal out_valid_q : std_logic_vector(NUM_OUTPUTS-1 downto 0);
  signal out_first_q : std_logic;
  signal out_last_q  : std_logic;
  signal out_data_q  : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

  --------------------------------------
  -- Asynchronous Signal Declarations --
  --------------------------------------

  in_ready_o  <= in_ready_q;

  out_ready_q <= (out1_ready_i & out0_ready_i);

  out0_valid_o <= out_valid_q(0);
  out0_first_o <= out_first_q;
  out0_last_o  <= out_last_q;
  out0_data_o  <= out_data_q;

  out1_valid_o <= out_valid_q(1);
  out1_first_o <= out_first_q;
  out1_last_o  <= out_last_q;
  out1_data_o  <= out_data_q;
  
  
  ---------------------------
  -- Synchronous Processes --
  ---------------------------
  
  -- Fork Process
  fork_p : process(clk, arst_n)
    variable in_ready_v  : std_logic;
    variable in_valid_v  : std_logic;
    variable in_first_v  : std_logic;
    variable in_last_v   : std_logic;
    variable in_data_v   : std_logic_vector(DATA_WIDTH-1 downto 0);
    variable out_ready_v : std_logic_vector(NUM_OUTPUTS-1 downto 0);
    variable out_valid_v : std_logic_vector(NUM_OUTPUTS-1 downto 0);
    variable out_first_v : std_logic;
    variable out_last_v  : std_logic;
    variable out_data_v  : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    procedure reset_p is
    begin
      in_ready_v  := '0';
      in_valid_v  := '0';
      in_first_v  := '0';
      in_last_v   := '0';
      in_data_v   := (others => '0');
      out_ready_v := (others => '0');
      out_valid_v := (others => '0');
      out_first_v := '0';
      out_last_v  := '0';
      out_data_v  := (others => '0');
      in_ready_q  <= '0';
      in_valid_q  <= '0';
      in_first_q  <= '0';
      in_last_q   <= '0';
      in_data_q   <= (others => '0');
      out_valid_q <= (others => '0');
      out_first_q <= '0';
      out_last_q  <= '0';
      out_data_q  <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Load variables from signals
        in_ready_v  := in_ready_q;
        in_valid_v  := in_valid_q;
        in_first_v  := in_first_q;
        in_last_v   := in_last_q;
        in_data_v   := in_data_q;
        out_ready_v := out_ready_q;
        out_valid_v := out_valid_q;
        out_first_v := out_first_q;
        out_last_v  := out_last_q;
        out_data_v  := out_data_q;

        -- Checks if inputs should be sampled
        if (in_ready_v = '1' and in_valid_i = '1') then
          assert (in_valid_v = '0') report "Error: data on the output will be overwritten and lost!" severity failure;
          in_valid_v := in_valid_i;
          in_first_v := in_first_i;
          in_last_v  := in_last_i;
          in_data_v  := in_data_i;
        end if;

        -- Checks which outputs have been acknowledged and clears their valid bits.
        out_valid_v := out_valid_v and not out_ready_v;

        -- If we have available data at the input and we have a free space at the output, transfer data to output
        if (in_valid_v = '1' and out_valid_v = (out_valid_v'range => '0')) then
          out_valid_v := (out_valid_v'range => '1');
          out_first_v := in_first_v;
          out_last_v  := in_last_v;
          out_data_v  := in_data_v;
          
          -- Release the input data
          in_valid_v  := '0';
        end if;

        -- Determines if we can sample the input on the next cycle
        in_ready_v  := not in_valid_v;

        -- Store variables to signals
        in_ready_q  <= in_ready_v;
        in_valid_q  <= in_valid_v;
        in_first_q  <= in_first_v;
        in_last_q   <= in_last_v;
        in_data_q   <= in_data_v;
        out_valid_q <= out_valid_v;
        out_first_q <= out_first_v;
        out_last_q  <= out_last_v;
        out_data_q  <= out_data_v;
      end if;
    end if;
  end process;


end rtl;
