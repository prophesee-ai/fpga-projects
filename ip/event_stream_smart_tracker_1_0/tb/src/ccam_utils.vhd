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
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library std;
use std.textio.all;


package ccam_utils is


  -------------------------------------------------------------------------------
  -- Vector Types Declaration
  -------------------------------------------------------------------------------

  type boolean_vector_t is array(natural range <>) of boolean;
  type integer_vector_t is array(natural range <>) of integer;
  type natural_vector_t is array(natural range <>) of natural;
  type bits5_vector_t   is array(natural range <>) of std_logic_vector(4 downto 0);

  -------------------------------------------------------------------------------
  -- Function and_reduce - returns '0' if any bit of arg is '0', or
  --                               '1' if all bits of arg are '1'.
  -------------------------------------------------------------------------------
  function and_reduce(arg: unsigned) return UX01;

  -------------------------------------------------------------------------------
  -- Function or_reduce - returns '0' if all bits of arg are '0', or
  --                              '1' if any bit of arg is '1'.
  -------------------------------------------------------------------------------
  function or_reduce(arg: unsigned) return UX01;

  -------------------------------------------------------------------------------
  -- Function log2 -- returns number of bits needed to encode x choices
  --   x = 0  returns 0
  --   x = 1  returns 0
  --   x = 2  returns 1
  --   x = 4  returns 2, etc.
  -------------------------------------------------------------------------------
  function log2(x : natural) return integer;

  --------------------------------------------------------------------------------
  -- Function clog2 - returns the integer ceiling of the base 2 logarithm of x,
  --                  i.e., the least integer greater than or equal to log2(x).
  --------------------------------------------------------------------------------
  function clog2(x : positive) return natural;

  --------------------------------------------------------------------------------
  -- Function nhighs -- return number of '1' in the vector
  --------------------------------------------------------------------------------
  function nhighs(x : std_logic_vector) return natural;

  -------------------------------------------------------------------------------
  -- Function nbits -- returns number of bits needed to encode a value x
  --   x = 0  returns 1
  --   x = 1  returns 1
  --   x = 2  returns 2
  --   x = 3  returns 2
  --   x = 4  returns 3, etc.
  -------------------------------------------------------------------------------
  function nbits(x : natural) return integer;
  function nbits_from_value(x : integer) return integer;

  --------------------------------------------------------------------------------
  -- Function to_std_logic - returns a std_logic value '0' for an integer value 0,
  --                         or a std_logic value '1' for other integer values.
  --------------------------------------------------------------------------------
  function to_std_logic(i : in integer) return std_logic;

  --------------------------------------------------------------------------------------
  -- Function to_std_logic - returns a std_logic value '1' for a boolean value 'true',
  --                         or a std_logic value '0' for other a boolean value 'false'.
  --------------------------------------------------------------------------------------
  function to_std_logic(i : boolean) return std_logic;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two integers.
  --------------------------------------------------------------------------------
  function minimum(a : in integer; b : in integer) return integer;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two unsigned numbers.
  --------------------------------------------------------------------------------
  function minimum(a : in unsigned; b : in unsigned) return unsigned;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two signed numbers.
  --------------------------------------------------------------------------------
  function minimum(a : in signed; b : in signed) return signed;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two integers.
  --------------------------------------------------------------------------------
  function maximum(a : in integer; b : in integer) return integer;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two unsigned numbers.
  --------------------------------------------------------------------------------
  function maximum(a : in unsigned; b : in unsigned) return unsigned;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two signed numbers.
  --------------------------------------------------------------------------------
  function maximum(a : in signed; b : in signed) return signed;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in integer; b : in integer) return integer;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in string; b : in string) return string;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in boolean; b : in boolean) return boolean;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in std_logic; b : in std_logic) return std_logic;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in std_logic_vector; b : in std_logic_vector) return std_logic_vector;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in boolean_vector_t; b : in boolean_vector_t) return boolean_vector_t;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in natural_vector_t; b : in natural_vector_t) return natural_vector_t;

  --------------------------------------------------------------------------------
  -- Function to_hcharacter - Convert std_logic_vector to hex char
  --------------------------------------------------------------------------------
  function to_hcharacter(vector : std_logic_vector(3 downto 0)) return character;

  --------------------------------------------------------------------------------
  -- Function to_hstring - Convert std_logic_vector to hex string
  --------------------------------------------------------------------------------
  function to_hstring(vector : std_logic_vector) return string;

  -----------------------------------------------------------------------------------
  -- Function get_evt_file_type - Return events file type based on events file name
  -----------------------------------------------------------------------------------
  function get_evt_file_type(name : in string) return string;

  -------------------------------------------------------------------------------
  -- Function nbits_from_choices -- returns number of bits needed to encode a number of choices
  --   x = 0  returns 1
  --   x = 1  returns 1
  --   x = 2  returns 1
  --   x = 3  returns 2
  --   x = 4  returns 2
  --   x = 5  returns 3
  --   x = 6  returns 3
  --   x = 7  returns 3
  --   x = 8  returns 3
  --   x = 9  returns 4
  --   x = 10 returns 4
  --   x = 11 returns 4
  --   x = 12 returns 4
  --   x = 13 returns 4
  --   x = 14 returns 4
  --   x = 15 returns 4
  --   x = 16 returns 4
  --   x = 17 returns 5, etc.
  -------------------------------------------------------------------------------
  function nbits_from_choices(x : integer) return integer;

  --------------------------------------------------------------------------------
  -- Function repeat - concatenate N times an element. Equivalent of Verilog {N{wire}}
  --------------------------------------------------------------------------------
  function repeat(n : in natural; v : in std_logic_vector) return std_logic_vector;
  function repeat(n : in natural; b : in std_logic       ) return std_logic_vector;

  --------------------------------------------------------------------------------
  -- Function string_format
  --------------------------------------------------------------------------------
  function string_format (
    value : natural; --- the numeric value
    width : positive; -- number of characters
    leading : character := ' '
  ) return string; --- guarantees to return "width" chars

  -----------------------------------------------------------------------
  --        Record conversion functions
  -----------------------------------------------------------------------

  --------------------
  -- Packing Functions

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in std_logic_vector);

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in std_logic);

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in unsigned);

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in signed);

  ----------------------
  -- Unpacking Functions

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out std_logic_vector);

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out std_logic);

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out unsigned);

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out signed);

  --------------------------------------------------------------------------------
  -- Function cnt_ones - count number of ones in std_logic_vector.
  --------------------------------------------------------------------------------
  function cnt_ones(a : in std_logic_vector) return integer;

  --------------------------------------------------------------------------------
  -- Function is_before - checks if a given timestamp a is before b
  --------------------------------------------------------------------------------
  function is_before(a : in std_logic_vector; b : in std_logic_vector) return boolean;
  function is_before(a : in std_logic_vector; b : in unsigned) return boolean;
  function is_before(a : in unsigned; b : in std_logic_vector) return boolean;
  function is_before(a : in unsigned; b : in unsigned) return boolean;

  --------------------------------------------------------------------------------
  -- Function is_after - checks if a given timestamp a is after b
  --------------------------------------------------------------------------------
  function is_after(a : in std_logic_vector; b : in std_logic_vector) return boolean;
  function is_after(a : in std_logic_vector; b : in unsigned) return boolean;
  function is_after(a : in unsigned; b : in std_logic_vector) return boolean;
  function is_after(a : in unsigned; b : in unsigned) return boolean;

end ccam_utils;


package body ccam_utils is

  -------------------------------------------------------------------------------
  -- Function and_reduce - returns '0' if any bit of arg is '0', or
  --                               '1' if all bits of arg are '1'.
  -------------------------------------------------------------------------------
  function and_reduce(arg: unsigned) return UX01 is
  begin
    return and_reduce(std_logic_vector(arg));
  end and_reduce;

  -------------------------------------------------------------------------------
  -- Function or_reduce - returns '0' if all bits of arg are '0', or
  --                              '1' if any bit of arg is '1'.
  -------------------------------------------------------------------------------
  function or_reduce(arg: unsigned) return UX01 is
  begin
    return or_reduce(std_logic_vector(arg));
  end or_reduce;

  -------------------------------------------------------------------------------
  -- Function log2 -- returns number of bits needed to encode x choices
  --   x = 0  returns 0
  --   x = 1  returns 0
  --   x = 2  returns 1
  --   x = 4  returns 2, etc.
  -------------------------------------------------------------------------------
  function log2(x : natural) return integer is
    variable i  : integer := 0;
    variable val: integer := 1;
  begin
    if x = 0 then return 0;
    else
      for j in 0 to 29 loop -- for loop for XST
        if val >= x then null;
        else
          i := i+1;
          val := val*2;
        end if;
      end loop;
    -- Fix per CR520627  XST was ignoring this anyway and printing a
    -- Warning in SRP file. This will get rid of the warning and not
    -- impact simulation.
    -- synthesis translate_off
      assert val >= x
        report "Function log2 received argument larger" &
               " than its capability of 2^30. "
        severity failure;
    -- synthesis translate_on
      return i;
    end if;
  end function log2;

  --------------------------------------------------------------------------------
  -- Function clog2 - returns the integer ceiling of the base 2 logarithm of x,
  --                  i.e., the least integer greater than or equal to log2(x).
  --------------------------------------------------------------------------------
  function clog2(x : positive) return natural is
    variable r  : natural := 0;
    variable rp : natural := 1; -- rp tracks the value 2**r
  begin
    while rp < x loop -- Termination condition T: x <= 2**r
      -- Loop invariant L: 2**(r-1) < x
      r := r + 1;
      if rp > integer'high - rp then exit; end if;  -- If doubling rp overflows
        -- the integer range, the doubled value would exceed x, so safe to exit.
      rp := rp + rp;
    end loop;
    -- L and T  <->  2**(r-1) < x <= 2**r  <->  (r-1) < log2(x) <= r
    return r; --
  end clog2;

  -------------------------------------------------------------------------------
  -- Function nbits -- returns number of bits needed to encode a value x
  --   x = 0  returns 1
  --   x = 1  returns 1
  --   x = 2  returns 2
  --   x = 3  returns 2
  --   x = 4  returns 3, etc.
  -------------------------------------------------------------------------------
  function nbits(x : natural) return integer is
    variable i  : integer := 1;
  begin
    while (2**i) <= x loop
      i := i + 1;
    end loop;
    -- Fix per CR520627  XST was ignoring this anyway and printing a
    -- Warning in SRP file. This will get rid of the warning and not
    -- impact simulation.
-- synthesis translate_off
    assert i <= 31
    report "Function nbits received argument larger" &
    " than its capability of 2^31-1. " & "nbits is " & integer'image(i) & "; x is " &  integer'image(x)
    severity failure;
-- synthesis translate_on
    return i;
  end function nbits;

  function nbits_from_value(x : integer) return integer is
    variable result : integer := 0;
  begin
    result := integer(ceil(log2(real(x+1))));
    return result;
  end function nbits_from_value;

  --------------------------------------------------------------------------------
  -- Function to_std_logic - returns a std_logic value '0' for an integer value 0,
  --                         or a std_logic value '1' for other integer values.
  --------------------------------------------------------------------------------
  function to_std_logic(i : in integer) return std_logic is
  begin
    if i = 0 then
      return '0';
    else
      return '1';
    end if;
  end function;

  --------------------------------------------------------------------------------------
  -- Function to_std_logic - returns a std_logic value '1' for a boolean value 'true',
  --                         or a std_logic value '0' for other a boolean value 'false'.
  --------------------------------------------------------------------------------------
  function to_std_logic(i : boolean) return std_logic is
  begin
    if i then
      return '1';
    else
      return '0';
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two integers.
  --------------------------------------------------------------------------------
  function minimum(a : in integer; b : in integer) return integer is
  begin
    if a <= b then
      return a;
    else
      return b;
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two unsigned numbers.
  --------------------------------------------------------------------------------
  function minimum(a : in unsigned; b : in unsigned) return unsigned is
    constant SIZE_C : natural := maximum(a'length, b'length);
  begin
    if a <= b then
      return resize(a, SIZE_C);
    else
      return resize(b, SIZE_C);
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function minimum - returns the minimum of two signed numbers.
  --------------------------------------------------------------------------------
  function minimum(a : in signed; b : in signed) return signed is
    constant SIZE_C : natural := maximum(a'length, b'length);
  begin
    if a <= b then
      return resize(a, SIZE_C);
    else
      return resize(b, SIZE_C);
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two integers.
  --------------------------------------------------------------------------------
  function maximum(a : in integer; b : in integer) return integer is
  begin
    if a >= b then
      return a;
    else
      return b;
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two unsigned numbers.
  --------------------------------------------------------------------------------
  function maximum(a : in unsigned; b : in unsigned) return unsigned is
    constant SIZE_C : natural := maximum(a'length, b'length);
  begin
    if a >= b then
      return resize(a, SIZE_C);
    else
      return resize(b, SIZE_C);
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function maximum - returns the maximum of two signed numbers.
  --------------------------------------------------------------------------------
  function maximum(a : in signed; b : in signed) return signed is
    constant SIZE_C : natural := maximum(a'length, b'length);
  begin
    if a >= b then
      return resize(a, SIZE_C);
    else
      return resize(b, SIZE_C);
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in integer; b : in integer) return integer is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;


  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in string; b : in string) return string is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;


  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in boolean; b : in boolean) return boolean is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;


  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------

  function iff(cond : in boolean; a : in std_logic; b : in std_logic) return std_logic is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;


  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------

  function iff(cond : in boolean; a : in std_logic_vector; b : in std_logic_vector) return std_logic_vector is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in boolean_vector_t; b : in boolean_vector_t) return boolean_vector_t is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function iff - selects between two input values based on a condition.
  --------------------------------------------------------------------------------
  function iff(cond : in boolean; a : in natural_vector_t; b : in natural_vector_t) return natural_vector_t is
  begin
    if (cond) then
      return a;
    else
      return b;
    end if;
  end function;

  --------------------------------------------------------------------------------
  -- Function nhighs -- return number of '1' in the vector
  --------------------------------------------------------------------------------
  function nhighs(x : std_logic_vector) return natural is
    variable nb : natural := 0;
  begin
    for i in x'range loop
      if(x(i) = '1') then
        nb  := nb + 1;
      end if;
    end loop;

    return nb;
  end function nhighs;


  --------------------------------------------------------------------------------
  -- Function to_hcharacter - Convert std_logic_vector to hex char
  --------------------------------------------------------------------------------
  function to_hcharacter(vector : std_logic_vector(3 downto 0)) return character is
    variable  ret : character;
  begin
    case to_integer(unsigned(vector)) is
      when 0  =>
        ret := '0';
      when 1  =>
        ret := '1';
      when 2  =>
        ret := '2';
      when 3  =>
        ret := '3';
      when 4  =>
        ret := '4';
      when 5  =>
        ret := '5';
      when 6  =>
        ret := '6';
      when 7  =>
        ret := '7';
      when 8  =>
        ret := '8';
      when 9  =>
        ret := '9';
      when 10  =>
        ret := 'A';
      when 11  =>
        ret := 'B';
      when 12  =>
        ret := 'C';
      when 13  =>
        ret := 'D';
      when 14  =>
        ret := 'E';
      when 15  =>
        ret := 'F';
      when others  =>
        ret := '0';
    end case;

    return ret;

  end function to_hcharacter;


  --------------------------------------------------------------------------------
  -- Function to_hstring - Convert std_logic_vector to hex string
  --------------------------------------------------------------------------------
  function to_hstring(vector : std_logic_vector) return string is
    constant BYTES_NB : positive := (vector'length + 3) / 4;
    variable ret      : string(0 to BYTES_NB+1);
    variable aligned  : std_logic_vector(BYTES_NB*4-1 downto 0);
  begin
    aligned := std_logic_vector(resize(unsigned(vector), BYTES_NB*4));
    ret(0)  := '0';
    ret(1)  := 'x';
    for IDX in 0 to BYTES_NB-1 loop
      ret(IDX+2)  := to_hcharacter(vector((BYTES_NB-IDX)*4-1 downto (BYTES_NB-IDX-1)*4));
    end loop;

    return ret;

  end function to_hstring;


  -----------------------------------------------------------------------------------
  -- Function get_evt_file_type - Return events file type based on events file name
  --   Returns "EVT" if ".evt" sting is find in file name.
  --   Returns "RAW" in all other case.
  -----------------------------------------------------------------------------------
  function get_evt_file_type(name : in string) return string is
  begin
    if (name = "") then
      -- Empty Name file
      return "RAW";
    else
      if (name'length < 3) then
        -- Name too short
        return "RAW";
      else
        if (name(name'right-3 to name'right) = ".raw" or
            name(name'right-3 to name'right) = ".dat") then
          return "RAW";
        else
          return "EVT";
        end if;
      end if;
    end if;
  end function;


  -------------------------------------------------------------------------------
  -- Function nbits_from_choices -- returns number of bits needed to encode a number of choices
  --   x = 0  returns 1
  --   x = 1  returns 1
  --   x = 2  returns 1
  --   x = 3  returns 2
  --   x = 4  returns 2
  --   x = 5  returns 3
  --   x = 6  returns 3
  --   x = 7  returns 3
  --   x = 8  returns 3
  --   x = 9  returns 4
  --   x = 10 returns 4
  --   x = 11 returns 4
  --   x = 12 returns 4
  --   x = 13 returns 4
  --   x = 14 returns 4
  --   x = 15 returns 4
  --   x = 16 returns 4
  --   x = 17 returns 5, etc.
  -------------------------------------------------------------------------------
  function nbits_from_choices(x : integer) return integer is
    variable result : integer := 1;
  begin
    if x <= 0 then
      return 0;
    else
      result := integer(ceil(log2(real(x))));
      return result;
    end if;
    -- assert x <= 0
    --   report "Function nbits_from_choices cannot convert 0"
    --   severity failure;
    -- return result;
  end function nbits_from_choices;

  --------------------------------------------------------------------------------
  -- Function repeat - concatenate N times an element. Equivalent of Verilog {N{wire}}
  --------------------------------------------------------------------------------
  function repeat(n: in natural; v: in std_logic_vector) return std_logic_vector is
    constant L      : natural := v'length;
    variable result : std_logic_vector(n*L - 1 downto 0);
  begin
    for i in 0 to n-1 loop
      result((L*(i+1))-1 downto i*L) := v;
    end loop;
    return result;
  end function;

  function repeat(n: in natural; b: in std_logic) return std_logic_vector is
    variable result : std_logic_vector(n - 1 downto 0);
  begin
    for i in 0 to n-1 loop
      result(i) := b;
    end loop;
    return result;
  end function;

  function string_format (
    value : natural; --- the numeric value
    width : positive; -- number of characters
    leading : character := ' '
  ) return string is --- guarantees to return "width" chars
    constant img: string := integer'image(value);
    variable str: string(1 to width) := (others => leading);
  begin
    if img'length > width then
      report "Format width " & integer'image(width) & " is too narrow for value " & img severity warning;
      str := (others => '*');
    else
      str(width+1-img'length to width) := img;
    end if;
    return str;
  end;


  -----------------------------------------------------------------------
  --        Record conversion functions
  -----------------------------------------------------------------------

  --------------------
  -- Packing Functions

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in std_logic_vector) is
  begin
    target(idx + nd'length - 1 downto idx) := nd;
    idx                                    := idx + nd'length;
  end procedure pack;

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in std_logic) is
  begin
    target(idx) := nd;
    idx         := idx + 1;
  end procedure pack;

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in unsigned) is
  begin
    target(idx + nd'length - 1 downto idx) := std_logic_vector(nd);
    idx                                    := idx + nd'length;
  end procedure pack;

  procedure pack(target : inout std_logic_vector; idx : inout integer; nd : in signed) is
  begin
    target(idx + nd'length - 1 downto idx) := std_logic_vector(nd);
    idx                                    := idx + nd'length;
  end procedure pack;

  ----------------------
  -- Unpacking Functions

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out std_logic_vector) is
  begin
    dat := source(idx + dat'length - 1 downto idx);
    idx := idx + dat'length;
  end procedure unpack;

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out std_logic) is
  begin
    dat := source(idx);
    idx := idx + 1;
  end procedure unpack;

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out unsigned) is
  begin
    dat := unsigned(source(idx + dat'length - 1 downto idx));
    idx := idx + dat'length;
  end procedure unpack;

  procedure unpack(source : in std_logic_vector; idx : inout integer; dat : out signed) is
  begin
    dat := signed(source(idx + dat'length - 1 downto idx));
    idx := idx + dat'length;
  end procedure unpack;


  --------------------------------------------------------------------------------
  -- Function cnt_ones - count number of ones in std_logic_vector.
  --------------------------------------------------------------------------------
  function cnt_ones(a : in std_logic_vector) return integer is
    variable count_v : integer := 0;
  begin
    for i in a'low to a'high loop
      if (a(i) = '1') then
        count_v := count_v + 1;
      end if;
    end loop;
    return count_v;
  end function;

  --------------------------------------------------------------------------------
  -- Function is_before - checks if a given timestamp a is before b
  --------------------------------------------------------------------------------
  function is_before(a : in std_logic_vector; b : in std_logic_vector) return boolean is
  begin
    return is_before(unsigned(a), unsigned(b));
  end function is_before;

  function is_before(a : in std_logic_vector; b : in unsigned) return boolean is
  begin
    return is_before(unsigned(a), b);
  end function is_before;

  function is_before(a : in unsigned; b : in std_logic_vector) return boolean is
  begin
    return is_before(a, unsigned(b));
  end function is_before;

  function is_before(a : in unsigned; b : in unsigned) return boolean is
  begin
    assert (a'length = b'length)
        report "a and b operand widths must match"
        severity failure;
    return signed(b - a) > 0;
  end function is_before;

  --------------------------------------------------------------------------------
  -- Function is_after - checks if a given timestamp a is after b
  --------------------------------------------------------------------------------
  function is_after(a : in std_logic_vector; b : in std_logic_vector) return boolean is
  begin
    return is_after(unsigned(a), unsigned(b));
  end function is_after;

  function is_after(a : in std_logic_vector; b : in unsigned) return boolean is
  begin
    return is_after(unsigned(a), b);
  end function is_after;

  function is_after(a : in unsigned; b : in std_logic_vector) return boolean is
  begin
    return is_after(a, unsigned(b));
  end function is_after;

  function is_after(a : in unsigned; b : in unsigned) return boolean is
  begin
    assert (a'length = b'length)
        report "a and b operand widths must match"
        severity failure;
    return signed(a - b) > 0;
  end function is_after;

end package body ccam_utils;
