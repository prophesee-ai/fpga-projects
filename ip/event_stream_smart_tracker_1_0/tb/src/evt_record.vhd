-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
use std.env.all;

library work;
use work.ccam_utils.all;


--------------------------------------------------
-- Reads a reference events stream from a file and
-- compares it with the stream on its AXI4-Stream
-- input port.
-- Ready line toggles with the READY_RATIO.
entity evt_record is
  generic (
    CHECKER_NAME        : string               := "Checker";
    DISPLAY_ITERATION_G : natural              := 1000;
    PATTERN_FILE        : string               := "ref_file.pat";
    READY_RATIO         : real                 := 1.0;
    EVT_FORMAT          : integer range 0 to 3 := 1;
    MSG_EVT_NB_MOD      : positive             := 100000;
    DATA_WIDTH          : positive             := 32
  );
  port (
    -- Clock
    clk     : in  std_logic;

    -- Control
    error_o : out std_logic;
    end_o   : out std_logic;

    -- Stream
    ready_o : out std_logic;
    valid_i : in  std_logic;
    mask_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '1');
    data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity evt_record;

architecture sim of evt_record is

  ---------------------------
  -- Constant Declarations --
  ---------------------------
  constant PATTERN_FILE_C         : string   := iff(PATTERN_FILE="NULL", "", PATTERN_FILE);
  constant FILE_TYPE_C            : string   := get_evt_file_type(PATTERN_FILE_C);
  constant RAW_FILE_MODE_C        : boolean  := iff(FILE_TYPE_C = "RAW", true, false);
  constant FILE_EVT_DATA_WIDTH_C  : positive := iff(EVT_FORMAT = 3, 16, iff(EVT_FORMAT = 0, DATA_WIDTH, 32));


  -----------------------
  -- Type Declarations --
  -----------------------
  type character_file is file of character;


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
        write(msg_v, CHECKER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events checked"));
      elsif (evt_nb_v >= 1000000) then
        write(msg_v, CHECKER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events checked"));
      elsif (evt_nb_v >= 1000) then
        write(msg_v, CHECKER_NAME & string'(": Reaching ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events checked"));
      else
        write(msg_v, CHECKER_NAME & string'(": Reaching ") & string_format(evt_nb_v, 3, ' ') & string'("      events checked"));
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
      write(msg_v, CHECKER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000000) mod 1000, 3, '0') & string'("G events checked"));
    elsif (evt_nb_v >= 1000000) then
      write(msg_v, CHECKER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000000, 3, ' ') & string'(".") & string_format((evt_nb_v/1000) mod 1000, 3, '0') & string'("M events checked"));
    elsif (evt_nb_v >= 1000) then
      write(msg_v, CHECKER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v/1000, 3, ' ') & string'(".") & string_format(evt_nb_v mod 1000, 3, '0') & string'("K events checked"));
    else
      write(msg_v, CHECKER_NAME & string'(": Reached end of test. Total of ") & string_format(evt_nb_v, 3, ' ') & string'("      events checked"));
    end if;
    writeline(output, msg_v);
  end procedure print_evt_nb_end_status;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal ready_s  : std_logic;
  signal l_idx_s  : positive;
  signal evt_nb_s : natural;
  signal ref_data_q : std_logic_vector(FILE_EVT_DATA_WIDTH_C-1 downto 0);


begin

  --------------------------------------
  -- Asynchronous Signal Declarations --
  --------------------------------------

  -- Output
  ready_o   <= ready_s;


  ---------------
  -- Processes --
  ---------------

  hex_file_gen : if (not RAW_FILE_MODE_C) generate

    -- Main process
    main : process
      variable  seed1    : positive := 123;
      variable  seed2    : positive := 456;
      variable  rand     : real;
      file      pattern  : text open read_mode is PATTERN_FILE_C;
      variable  l        : line;
      variable  l2       : line;
      variable  char_v   : character;
      variable  data_v   : std_logic_vector(FILE_EVT_DATA_WIDTH_C-1 downto 0);
      variable  msg_v    : line;
      variable  l_idx_v  : positive;
      variable  evt_nb_v : natural;
    begin
      ready_s           <= '0';
      end_o             <= '0';
      error_o           <= '0';
      l_idx_v           := 1;
      l_idx_s           <= l_idx_v;
      evt_nb_v          := 0;
      evt_nb_s          <= evt_nb_v;
      ref_data_q        <= (others => '0');
      wait until rising_edge(clk);

      while (not endfile(pattern)) loop
        if (    (valid_i = '1')
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
          ref_data_q <= data_v;
          if ((data_i(data_v'range) and mask_i(data_v'range)) /= (data_v and mask_i(data_v'range))) then
            error_o   <= '1';
            write(msg_v, CHECKER_NAME & string'(": Event check error, line "));
            write(msg_v, l_idx_v);
            write(msg_v, string'(":" & LF & "        Received: 0x"));
            hwrite(msg_v, data_i(data_v'range));
            write(msg_v, string'(LF & "        Expected: 0x"));
            hwrite(msg_v, data_v);
            writeline(output, msg_v);
          elsif l_idx_v mod DISPLAY_ITERATION_G = 0 then
            write(msg_v, CHECKER_NAME & " " & integer'image(l_idx_v) & " " & string'("Events check OK"));
            writeline(output, msg_v);
          end if;
          l_idx_v := l_idx_v + 1;
          l_idx_s <= l_idx_v;

          evt_nb_v := evt_nb_v + 1;
          evt_nb_s <= evt_nb_v;

          print_evt_nb_status(evt_nb_v);

        end if;

        UNIFORM(seed1, seed2, rand);
        if (rand <= READY_RATIO) then
          ready_s   <= '1';
        else
          ready_s   <= '0';
        end if;

        wait until rising_edge(clk);
      end loop;

      print_evt_nb_end_status(evt_nb_v);

      ready_s   <= '1';
      end_o     <= '1';

      wait;
    end process;

  end generate hex_file_gen;


  binary_file_gen : if (RAW_FILE_MODE_C) generate

    -- Main process
    main : process
      variable  seed1    : positive := 123;
      variable  seed2    : positive := 456;
      variable  rand     : real;

      file     file_v                : character_file;
      variable file_path_v           : string(PATTERN_FILE_C'low to PATTERN_FILE_C'high) := PATTERN_FILE_C;
      variable file_status_v         : file_open_status;
      variable char_v                : character;

      variable  data_v   : std_logic_vector(FILE_EVT_DATA_WIDTH_C-1 downto 0);
      variable  msg_v    : line;
      variable  l_idx_v  : positive;
      variable  evt_nb_v : natural;
    begin
      ready_s           <= '0';
      end_o             <= '0';
      error_o           <= '0';
      l_idx_v           := 1;
      l_idx_s           <= l_idx_v;
      evt_nb_v          := 0;
      evt_nb_s          <= evt_nb_v;

      file_open(file_status_v, file_v, file_path_v, READ_MODE);
      if (file_status_v /= OPEN_OK) then
        if (file_path_v = "") then
          write(msg_v, CHECKER_NAME & string'(": File name is empty. No data will be processed."));
          writeline(output, msg_v);
          wait;
        else
          write(msg_v, CHECKER_NAME & string'(": File '") & file_path_v & string'("' not found."));
          writeline(output, msg_v);
          report "End of Simulation." severity failure;
        end if;
      else
        write(msg_v, CHECKER_NAME & string'(": Raw file '") & file_path_v & string'("' opened successfully."));
        writeline(output, msg_v);
      end if;

      wait until rising_edge(clk);

      while (not endfile(file_v)) loop
        if (    (valid_i = '1')
            and (ready_s = '1')) then
          for i in 0 to (FILE_EVT_DATA_WIDTH_C/8)-1 loop
            if not(endfile(file_v)) then
              -- Raw Data File
              read(file_v, char_v);
              data_v(FILE_EVT_DATA_WIDTH_C-9 downto 0                      ) := data_v(FILE_EVT_DATA_WIDTH_C-1 downto 8);
              data_v(FILE_EVT_DATA_WIDTH_C-1 downto FILE_EVT_DATA_WIDTH_C-8) := std_logic_vector(to_unsigned(character'pos(char_v), 8));
            else
              data_v  := (others => '0');
            end if;
            ref_data_q <= data_v;
          end loop;
          if (data_i(data_v'range) /= data_v) then
            error_o   <= '1';
            write(msg_v, CHECKER_NAME & string'(": Event check error, line "));
            write(msg_v, l_idx_v);
            write(msg_v, string'(":" & LF & "        Received: 0x"));
            hwrite(msg_v, data_i(data_v'range));
            write(msg_v, string'(LF & "        Expected: 0x"));
            hwrite(msg_v, data_v);
            writeline(output, msg_v);
          elsif l_idx_v mod DISPLAY_ITERATION_G = 0 then
            write(msg_v, CHECKER_NAME & " " & integer'image(l_idx_v) & " " & string'("Events check OK"));
            writeline(output, msg_v);
          end if;
          l_idx_v := l_idx_v + 1;
          l_idx_s <= l_idx_v;

          evt_nb_v := evt_nb_v + 1;
          evt_nb_s <= evt_nb_v;

          print_evt_nb_status(evt_nb_v);

        end if;

        UNIFORM(seed1, seed2, rand);
        if (rand <= READY_RATIO) then
          ready_s   <= '1';
        else
          ready_s   <= '0';
        end if;

        wait until rising_edge(clk);
      end loop;

      print_evt_nb_end_status(evt_nb_v);

      ready_s   <= '1';
      end_o     <= '1';

      wait;
    end process;

  end generate binary_file_gen;


end architecture sim;
