-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.math_real.all;
use     ieee.std_logic_textio.all;

library std;
use     std.textio.all;
use     std.env.all;

library work;
use     work.ccam_utils.all;

--------------------------------------------------
-- Reads a reference events stream from a file and
-- compares it with the stream on its AXI4-Stream
-- input port.
-- Ready line toggles with the READY_RATIO_G.
entity evt_record_generic is
  generic (
    CHECKER_NAME_G   : string     := "Checker";
    PATTERN_FILE_G   : string     := "ref_file.pat";
    READY_RATIO_G    : real       := 1.0;
    DATA_WIDTH_G     : positive   := 64;
    MSG_EVT_NB_MOD_G : positive   := 100000
  );
  port (
    -- Clock
    clk              : in  std_logic;

    -- Control
    stat_error_o     : out std_logic;
    stat_end_o       : out std_logic;

    -- Stream
    in_ready_o       : out std_logic;
    in_valid_i       : in  std_logic;
    in_data_i        : in  std_logic_vector(DATA_WIDTH_G-1 downto 0)
  );
end entity evt_record_generic;

architecture sim of evt_record_generic is

  ---------------------------
  -- Function Declarations --
  ---------------------------


  -----------------------------------------------------------------------------
  -- Function that prints the event number status
  -----------------------------------------------------------------------------
  procedure print_evt_nb_status(evt_nb_v : positive) is
    variable  msg_v : line;
  begin
    if (evt_nb_v mod MSG_EVT_NB_MOD_G = 0) then
      if (evt_nb_v >= 1000000000) then
        write(msg_v, CHECKER_NAME_G & string'(": Reaching ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events checked"));
      elsif (evt_nb_v >= 1000000) then
        write(msg_v, CHECKER_NAME_G & string'(": Reaching ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events checked"));
      elsif (evt_nb_v >= 1000) then
        write(msg_v, CHECKER_NAME_G & string'(": Reaching ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events checked"));
      else
        write(msg_v, CHECKER_NAME_G & string'(": Reaching ") & string_format(evt_nb_v, 3, ' ') & string'("      events checked"));
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
      write(msg_v, CHECKER_NAME_G & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events checked"));
    elsif (evt_nb_v >= 1000000) then
      write(msg_v, CHECKER_NAME_G & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events checked"));
    elsif (evt_nb_v >= 1000) then
      write(msg_v, CHECKER_NAME_G & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events checked"));
    else
      write(msg_v, CHECKER_NAME_G & string'(": Reached end of test. Total of ") & string_format(evt_nb_v, 3, ' ') & string'("      events checked"));
    end if;
    writeline(output, msg_v);
  end procedure print_evt_nb_end_status;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal ready_s  : std_logic;
  signal l_idx_s  : positive;
  signal evt_nb_s : natural;


begin

  --------------------------------------
  -- Asynchronous Signal Declarations --
  --------------------------------------

  -- Output
  in_ready_o   <= ready_s;


  ---------------
  -- Processes --
  ---------------

  -- Main process
  main : process
    variable  seed1    : positive := 123;
    variable  seed2    : positive := 456;
    variable  rand     : real;
    file      pattern  : text open read_mode is PATTERN_FILE_G;
    variable  l        : line;
    variable  l2       : line;
    variable  char_v   : character;
    variable  data_v   : std_logic_vector(DATA_WIDTH_G-1 downto 0);
    variable  msg_v    : line;
    variable  l_idx_v  : positive;
    variable  evt_nb_v : natural;
  begin
    ready_s           <= '0';
    stat_end_o        <= '0';
    stat_error_o      <= '0';
    l_idx_v           := 1;
    l_idx_s           <= l_idx_v;
    evt_nb_v          := 0;
    evt_nb_s          <= evt_nb_v;
    wait until rising_edge(clk);

    while (not endfile(pattern)) loop
      if (    (in_valid_i = '1')
          and (ready_s = '1')) then
        readline(pattern, l);
        l2 := new string'(l.all);
        read(l2, char_v);
        deallocate(l2);
        if (char_v = '#' or char_v = '%') then
          l_idx_v := l_idx_v + 1;
          l_idx_s <= l_idx_v;
          next;
        end if;
        hread(l, data_v);
        if (in_data_i(data_v'range) /= data_v) then
          stat_error_o   <= '1';
          write(msg_v, CHECKER_NAME_G & string'(": Event check error, line "));
          write(msg_v, l_idx_v);
          write(msg_v, string'(":" & LF & "        Received: 0x"));
          hwrite(msg_v, in_data_i(data_v'range));
          write(msg_v, string'(LF & "        Expected: 0x"));
          hwrite(msg_v, data_v);
          writeline(output, msg_v);
        end if;
        l_idx_v := l_idx_v + 1;
        l_idx_s <= l_idx_v;

        evt_nb_v := evt_nb_v + 1;
        evt_nb_s <= evt_nb_v;

        print_evt_nb_status(evt_nb_v);

      end if;

      UNIFORM(seed1, seed2, rand);
      if (rand <= READY_RATIO_G) then
        ready_s   <= '1';
      else
        ready_s   <= '0';
      end if;

      wait until rising_edge(clk);
    end loop;

    print_evt_nb_end_status(evt_nb_v);

    ready_s    <= '1';
    stat_end_o <= '1';

    wait;
  end process;

end architecture sim;
