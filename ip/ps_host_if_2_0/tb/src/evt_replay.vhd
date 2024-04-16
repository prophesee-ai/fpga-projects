----------------------------------------------------------------------------------
-- Company:        Chronocam
-- Engineer:       Long XU (lxu@chronocam.com)
--
-- Create Date:    May. 19, 2017
-- Design Name:    evt_replay
-- Module Name:    evt_replay
-- Project Name:   common
-- Target Devices: Artix 7
-- Tool versions:  Xilinx Vivado 2016.4
-- Description:    Reads an events stream from a file and replays it
--                 on its AXI4-Stream output port.
--                 Valid line toggles with the VALID_RATIO.

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
use ieee.math_real.all;
use ieee.std_logic_textio.all;
use std.textio.all;

library work;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;


-----------------------------------------------------
-- Reads an events stream from a file and replays it
-- on its AXI4-Stream output port.
-- Valid line toggles with the VALID_RATIO.
entity evt_replay is
  generic (
    READER_NAME    : string               := "Reader";
    PATTERN_FILE   : string               := "input_file.pat";
    VALID_RATIO    : real                 := 1.0;
    EVT_FORMAT     : integer range 0 to 3 := 1;
    MSG_EVT_NB_MOD : positive             := 100000;
    DATA_WIDTH     : positive             := 32;
    EN_TLAST       : boolean              := true
  );
  port (
    -- Clock
    clk     : in  std_logic;

    -- Control
    start_i : in  std_logic;
    end_o   : out std_logic;

    -- Stream
    ready_i : in  std_logic;
    valid_o : out std_logic;
    last_o  : out std_logic;
    data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity evt_replay;



architecture sim of evt_replay is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant FILE_EVT_DATA_WIDTH : positive := iff(EVT_FORMAT = 3, 16, iff(EVT_FORMAT = 0, DATA_WIDTH, 32));


  ---------------------------
  -- Function Declarations --
  ---------------------------


  -----------------------------------------------------------------------------
  -- Function that prints the event number status
  -----------------------------------------------------------------------------
  procedure print_evt_nb_status(evt_nb_v : positive) is
    variable  msg_v : line;
  begin
    if (evt_nb_v mod MSG_EVT_NB_MOD = 0) then
      if (evt_nb_v >= 1000000000) then
        write(msg_v, READER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events read"));
      elsif (evt_nb_v >= 1000000) then
        write(msg_v, READER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events read"));
      elsif (evt_nb_v >= 1000) then
        write(msg_v, READER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events read"));
      else
        write(msg_v, READER_NAME & string'(": Reaching ") & string_format(evt_nb_v, 3, ' ') & string'("      events read"));
      end if;
      writeline(output, msg_v);
    end if;
  end procedure print_evt_nb_status;


  -----------------------------------------------------------------------------
  -- Function that prints the event number status at the end of the test
  -----------------------------------------------------------------------------
  procedure print_evt_nb_end_status(evt_nb_v : positive) is
    variable  msg_v : line;
  begin
    if (evt_nb_v >= 1000000000) then
      write(msg_v, READER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events read"));
    elsif (evt_nb_v >= 1000000) then
      write(msg_v, READER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events read"));
    elsif (evt_nb_v >= 1000) then
      write(msg_v, READER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events read"));
    else
      write(msg_v, READER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v, 3, ' ') & string'("      events read"));
    end if;
    writeline(output, msg_v);
  end procedure print_evt_nb_end_status;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal valid_s  : std_logic;
  signal last_s   : std_logic;
  signal data_s   : std_logic_vector(data_o'range);
  signal evt_nb_s : natural;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Output
  valid_o <= valid_s;
  last_o  <= last_s;
  data_o  <= data_s;


  ---------------
  -- Processes --
  ---------------

  -- Main Process
  main : process
    variable  seed1        : positive  := 123;
    variable  seed2        : positive  := 456;
    variable  rand         : real;
    file      pattern      : text  open read_mode is PATTERN_FILE;
    variable  l            : line;
    variable  l2           : line;
    variable  char_v       : character;
    variable  data_read_v  : std_logic_vector(FILE_EVT_DATA_WIDTH-1 downto 0);
    variable  next_data_v  : std_logic_vector(data_o'range) := (others => 'U');
    variable  data_v       : std_logic_vector(data_o'range) := (others => 'U');
    variable  evt_nb_v     : natural;
  begin
    valid_s   <= '0';
    last_s    <= '0';
    data_s    <= (others => '0');
    end_o     <= '0';
    evt_nb_v  := 0;
    evt_nb_s  <= evt_nb_v;
    while (start_i /= '1') loop
      wait until rising_edge(clk);
    end loop;
    wait until rising_edge(clk);

    while (not endfile(pattern)) loop
      readline(pattern, l);
      l2 := new string'(l.all);
      read(l2, char_v);
      deallocate(l2);
      if (char_v /= '#' and char_v /= '%') then
        hread(l, data_read_v);
        next_data_v := (others => '0');
        next_data_v(data_read_v'range) := data_read_v;
        exit;
      end if;
    end loop;

    while (not endfile(pattern) or next_data_v /= (next_data_v'range => 'U')) loop
      if (    (valid_s = '0')
          or  (ready_i = '1')) then
        UNIFORM(seed1, seed2, rand);
        if (rand <= VALID_RATIO) then
          data_v := next_data_v;
          if (not endfile(pattern)) then
            readline(pattern, l);
            l2 := new string'(l.all);
            read(l2, char_v);
            deallocate(l2);
            if (char_v = '#' or char_v = '%') then
              next;
            end if;
            hread(l, data_read_v);
            next_data_v := (others => '0');
            next_data_v(data_read_v'range) := data_read_v;
          else
            next_data_v := (next_data_v' range => 'U');
          end if;
          data_s    <= data_v;
          if (EN_TLAST) then
            case (EVT_FORMAT) is
            when 1 | 2 =>
              if (to_ccam_evt(next_data_v).type_f = CONTINUED) then
                last_s    <= '0';
              else
                last_s    <= '1';
              end if;
            when 3 =>
              case (ccam_evt_data_to_ccam_evt_v3(next_data_v).type_f) is
              when EVT_V3_CONTINUED_4 | EVT_V3_CONTINUED_12 =>
                last_s    <= '0';
              when others =>
                last_s    <= '1';
              end case;
            when others =>
              last_s    <= '0';
            end case;
          end if;
          valid_s   <= '1';

          evt_nb_v  := evt_nb_v + 1;
          evt_nb_s  <= evt_nb_v;

          print_evt_nb_status(evt_nb_v);
        else
          valid_s   <= '0';
        end if;
      end if;

      wait until rising_edge(clk);
    end loop;

    print_evt_nb_end_status(evt_nb_v);

    while (ready_i = '0') loop
      wait until rising_edge(clk);
    end loop;

    valid_s   <= '0';
    end_o     <= '1';

    wait;
  end process;

end architecture sim;
