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
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

library work;
use work.ccam_utils.all;


---------------------------------------------------
-- File Stream Reader
-- Reads a file and produces an output data stream.
entity file_stream_reader is
  generic (
    DATA_WIDTH     : positive := 32;
    FILE_PATH      : string   := "file.dat";
    WHOIAM         : string   := "file_reader"
  );
  port (
    -- Clock and Reset
    clk         : in  std_logic;
    rst         : in  std_logic;

    -- Enable
    enable_i    : in  std_logic;

    -- End of File
    eof_o       : out std_logic;

    -- Output Data Stream
    out_ready_i : in  std_logic;
    out_valid_o : out std_logic;
    out_last_o  : out std_logic;
    out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end file_stream_reader;

architecture rtl of file_stream_reader is

  ------------------------------------
  -- Internal Constant Declarations --
  ------------------------------------
  constant FILE_PATH_C   : string  := iff(FILE_PATH="NULL", "", FILE_PATH);
  constant FILE_TYPE     : string  := get_evt_file_type(FILE_PATH_C); 
  constant RAW_FILE_MODE : boolean := iff(FILE_TYPE = "EVT", False, True);

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  signal eof_s       : std_logic;

  signal out_valid_s : std_logic;
  signal out_last_s  : std_logic;
  signal out_data_s  : std_logic_vector(DATA_WIDTH-1 downto 0);

  type character_file is file of character;

  type file_state_t is (START_OF_FILE, FILE_OPENED, END_OF_FILE);
  signal file_state_s : file_state_t;

begin

  --------------------------------------
  -- Asynchronous Signal Assignements --
  --------------------------------------

  out_valid_o <= out_valid_s;
  out_last_o  <= out_last_s;
  out_data_o  <= out_data_s;

  eof_o   <= eof_s;


  binary_file_g : if RAW_FILE_MODE generate

    ------------------------------
    -- Event Stream Reader Process
    file_stream_reader_p : process(clk)
      variable out_valid_v : std_logic;
      variable out_last_v  : std_logic;
      variable out_data_v  : std_logic_vector(DATA_WIDTH-1 downto 0);
      -- Auxiliary variables for reading files
      file     file_v                : character_file;
      variable file_path_v           : string(FILE_PATH_C'low to FILE_PATH_C'high) := FILE_PATH_C;
      variable file_status_v         : file_open_status;
      variable file_state_v          : file_state_t;
      variable char_v                : character;
      variable print_line_v          : line;

    begin
      if (rising_edge(clk)) then
        if (rst = '1') then
          out_valid_v  := '0';
          out_last_v   := '0';
          out_data_v   := (others => '0');
          out_valid_s  <= '0';
          out_last_s   <= '0';
          out_data_s   <= (others => '0');
          file_state_v := START_OF_FILE;
          file_state_s <= START_OF_FILE;
          eof_s        <= '0';
        elsif (enable_i = '1') then

          -- Load variables from signals
          out_valid_v  := out_valid_s;
          out_last_v   := out_last_s;
          out_data_v   := out_data_s;
          file_state_v := file_state_s;

          -- Check if output has been sampled, and release it if so.
          if (out_ready_i = '1' and out_valid_v = '1') then
            out_valid_v := '0';
          end if;

          -- If the file has not yet been opened, open file.
          if (file_state_v = START_OF_FILE) then
            file_open(file_status_v, file_v, file_path_v, READ_MODE);

            if (file_status_v /= OPEN_OK) then
              if (file_path_v = "") then
                write(print_line_v, WHOIAM & string'(": File name is empty. No data will be processed."));
                writeline(output, print_line_v);
                file_state_v := END_OF_FILE;
              else
                write(print_line_v, WHOIAM & string'(": File '") & file_path_v & string'("' not found."));
                writeline(output, print_line_v);
                report "End of Simulation." severity failure;
              end if;
            else
              write(print_line_v, WHOIAM & string'(": Raw file '") & file_path_v & string'("' opened successfully."));
              writeline(output, print_line_v);
              file_state_v := FILE_OPENED;
            end if;
          end if;

          -- If the output is available and there is still data in the file, output the data.
          if (out_valid_v = '0' and (file_state_v = FILE_OPENED) and (not endfile(file_v))) then
            out_valid_v := '1';
            out_last_v  := '1';
            out_data_v  := (others => '0');
            for i in 0 to (DATA_WIDTH/8)-1 loop
              if not(endfile(file_v)) then
                -- Raw Data File
                read(file_v, char_v);
                out_data_v(DATA_WIDTH-9 downto 0           ) := out_data_v(DATA_WIDTH-1 downto 8);
                out_data_v(DATA_WIDTH-1 downto DATA_WIDTH-8) := std_logic_vector(to_unsigned(character'pos(char_v), 8));
              else
                out_valid_v := '0';
                out_last_v  := '0';
                out_data_v  := (others => '0');
              end if;
            end loop;
          end if;

          -- If there is no more data, close file.
          if (file_state_v = FILE_OPENED and endfile(file_v)) then
            write(print_line_v, WHOIAM & string'(": Reached end of file: '") & file_path_v & string'("'"));
            writeline(output, print_line_v);
            file_close(file_v);
            file_state_v := END_OF_FILE;
          end if;

          -- The End of File
          if (file_state_v = END_OF_FILE) then
            eof_s      <= '1';
          end if;

          -- Store variables into signals
          out_valid_s  <= out_valid_v;
          out_last_s   <= out_last_v;
          out_data_s   <= out_data_v;
          file_state_s <= file_state_v;
        end if;
      end if;
    end process file_stream_reader_p;


  end generate binary_file_g;


  hex_file_g : if not(RAW_FILE_MODE) generate

    ------------------------------
    -- Event Stream Reader Process
    file_stream_reader_p : process(clk)
      variable out_valid_v : std_logic;
      variable out_last_v  : std_logic;
      variable out_data_v  : std_logic_vector(DATA_WIDTH-1 downto 0);
      -- Auxiliary variables for reading files
      file     hex_file_v            : text;
      variable file_path_v           : string(FILE_PATH_C'low to FILE_PATH_C'high) := FILE_PATH_C;
      variable file_state_v          : file_state_t;
      variable file_status_v         : file_open_status;
      variable print_line_v          : line;
      variable newline_v             : line;

    begin
      if (rising_edge(clk)) then
        if (rst = '1') then
          out_valid_v  := '0';
          out_last_v   := '0';
          out_data_v   := (others => '0');
          out_valid_s  <= '0';
          out_last_s   <= '0';
          out_data_s   <= (others => '0');
          file_state_v := START_OF_FILE;
          file_state_s <= START_OF_FILE;
          eof_s        <= '0';
        elsif (enable_i = '1') then

          -- Load variables from signals
          out_valid_v  := out_valid_s;
          out_last_v   := out_last_s;
          out_data_v   := out_data_s;
          file_state_v := file_state_s;

          -- Check if output has been sampled, and release it if so.
          if (out_ready_i = '1' and out_valid_v = '1') then
            out_valid_v := '0';
          end if;

          -- If the file has not yet been opened, open file.
          if (file_state_v = START_OF_FILE) then
            file_open(file_status_v, hex_file_v, file_path_v, READ_MODE);
            
            if (file_status_v /= OPEN_OK) then
              if (file_path_v = "") then
                write(print_line_v, WHOIAM & string'(": File name is empty. No data will be processed."));
                writeline(output, print_line_v);
                file_state_v := END_OF_FILE;
              else
                write(print_line_v, WHOIAM & string'(": File '") & file_path_v & string'("' not found."));
                writeline(output, print_line_v);
                report "End of Simulation." severity failure;
              end if;
            else
              write(print_line_v, WHOIAM & string'(": Events file '") & file_path_v & string'("' opened successfully."));
              writeline(output, print_line_v);
              file_state_v := FILE_OPENED;
            end if;
          end if;

          -- If the output is available and there is still data in the file, output the data.
          if (out_valid_v = '0' and (file_state_v = FILE_OPENED) and (not endfile(hex_file_v))) then
            out_valid_v := '1';
            out_last_v  := '1';
            out_data_v  := (others => '0');
            -- Hex Data File
            readline(hex_file_v, newline_v);
            hread(newline_v, out_data_v);
          end if;

          -- If there is no more data, close file.
          if (file_state_v = FILE_OPENED and endfile(hex_file_v)) then
            write(print_line_v, WHOIAM & string'(": Reached end of file: '") & file_path_v & string'("'"));
            writeline(output, print_line_v);
            file_close(hex_file_v);
            file_state_v := END_OF_FILE;
          end if;

          -- The End of File
          if (file_state_v = END_OF_FILE) then
            eof_s      <= '1';
          end if;

          -- Store variables into signals
          out_valid_s  <= out_valid_v;
          out_last_s   <= out_last_v;
          out_data_s   <= out_data_v;
          file_state_s <= file_state_v;
        end if;
      end if;
    end process file_stream_reader_p;

  end generate hex_file_g;

end rtl;
