-- Copyright (c) Prophesee S.A.
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

----------------------------------------------
-- MIPI CSI-2 TX delay control
entity mipi_csi_tx_delay_ctrl is
  generic (
    LP01CLK_DLY_G       : natural range 0 to 65535;
    LP00CLK_DLY_G       : natural range 0 to 65535;
    HS00CLK_DLY_G       : natural range 0 to 65535;
    HSXXCLK_DLY_G       : natural range 0 to 65535;
    CLK2DATA_DLY_G      : natural range 0 to 65535;
    LP01DATA_DLY_G      : natural range 0 to 65535;
    LP00DATA_DLY_G      : natural range 0 to 65535;
    HS00DATA_DLY_G      : natural range 0 to 65535;
    HSXXDATA_DLY_G      : natural range 0 to 65535;
    HSTRAILDATA_DLY_G   : natural range 0 to 65535;
    HS00DATAEND_DLY_G   : natural range 0 to 65535;
    LP00DATAEND_DLY_G   : natural range 0 to 65535;
    CLK2DATAEND_DLY_G   : natural range 0 to 65535;
    HS00CLKEND_DLY_G    : natural range 0 to 65535;
    LP00CLKEND_DLY_G    : natural range 0 to 65535
  );
  port (
    -- Core clock and reset
    clk                 : in  std_logic;
    arst_n              : in  std_logic;
    srst                : in  std_logic;

    -- Input bytes per lane
    in_hs_en_i          : in  std_logic;
    in_byte_l3_i        : in  std_logic_vector(7 downto 0);
    in_byte_l2_i        : in  std_logic_vector(7 downto 0);
    in_byte_l1_i        : in  std_logic_vector(7 downto 0);
    in_byte_l0_i        : in  std_logic_vector(7 downto 0);

    -- Output bytes per lane
    out_hsxx_clk_en_o   : out std_logic;
    out_hs_clk_en_o     : out std_logic;
    out_hs_data_en_o    : out std_logic;
    out_lp_clk_o        : out std_logic_vector(1 downto 0);
    out_lp_data_o       : out std_logic_vector(1 downto 0);
    out_byte_l3_o       : out std_logic_vector(7 downto 0);
    out_byte_l2_o       : out std_logic_vector(7 downto 0);
    out_byte_l1_o       : out std_logic_vector(7 downto 0);
    out_byte_l0_o       : out std_logic_vector(7 downto 0)
  );
end entity;

architecture rtl of mipi_csi_tx_delay_ctrl is

  -- Constants
  -- Beginning timing numbers based on when in_hs_en_i is high
  constant LP01_CLK_C         : natural := LP01CLK_DLY_G; --Time spent in LP01 state
  constant LP00_CLK_C         : natural := LP01CLK_DLY_G+LP00CLK_DLY_G; --Time spent in LP00, HS disable state
  constant HS00_CLK_C         : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G; --Time spent in HS00 state
  constant HSXX_CLK_C         : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G; --Time between HS00 and clock actually coming out. I think should be 0.
  constant CLK2DATA_C         : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G+CLK2DATA_DLY_G; --Time between clock enable and data LP11 to LP01 transition.
  constant LP01_DATA_C        : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G+CLK2DATA_DLY_G+LP01DATA_DLY_G; --Time data line stays in LP01
  constant LP00_DATA_C        : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G+CLK2DATA_DLY_G+LP01DATA_DLY_G+LP00DATA_DLY_G;  --Time data line spends in LP00, HS disable state
  constant HS00_DATA_C        : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G+CLK2DATA_DLY_G+LP01DATA_DLY_G+LP00DATA_DLY_G+HS00DATA_DLY_G; --Time data line spends in HS00 state
  constant HSXX_DATA_C        : natural := LP01CLK_DLY_G+LP00CLK_DLY_G+HS00CLK_DLY_G+HSXXCLK_DLY_G+CLK2DATA_DLY_G+LP01DATA_DLY_G+LP00DATA_DLY_G+HS00DATA_DLY_G+HSXXDATA_DLY_G; --Time between HS00 and data actually coming out. I think should be 0.

  -- Ending timing numbers based on when in_hs_en_i is low
  constant HSTRAIL_DATA_END_C : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G; --Minimum time in HSTrail state.
  constant HS00_DATA_END_C    : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G; --Time spent in HS00 state after trail.
  constant LP00_DATA_END_C    : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G; --Time spend in LP00 state, HS disable
  constant LP11_DATA_END_C    : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G; --Time spend in LP01 state, HS disable
  constant DATA2CLK_C         : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G+CLK2DATAEND_DLY_G; --Time between LP11 in data line and clock stop.
  constant HS00_CLK_END_C     : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G+CLK2DATAEND_DLY_G+HS00CLKEND_DLY_G;  --Time clock line spends in HS00 state before disable HS mode.
  constant LP00_CLK_END_C     : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G+CLK2DATAEND_DLY_G+HS00CLKEND_DLY_G+LP00CLKEND_DLY_G; --Time clock line spends in LP00, disable HS mode.
  constant LP11_CLK_END_C     : natural := HSXX_DATA_C+HSTRAILDATA_DLY_G+HS00DATAEND_DLY_G+LP00DATAEND_DLY_G+CLK2DATAEND_DLY_G+HS00CLKEND_DLY_G+LP00CLKEND_DLY_G; --Time clock line spends in LP01 mode before going to LP11 mode.

  -- Max counter value
  constant CNT_MAX_VAL_C      : natural range 0 to 65535 := 16#FFFF#;

  -- Low power states
  constant LP00_C             : std_logic_vector(1 downto 0) := "00";
  constant LP01_C             : std_logic_vector(1 downto 0) := "01";
  constant LP11_C             : std_logic_vector(1 downto 0) := "11";

  -- Type declaration
  type hold_data_t is array (natural range <>) of std_logic_vector(31 downto 0);

  -- Signals
  signal hold_data_q          : hold_data_t(HSXX_DATA_C downto 0);
  signal hold_data_out_s      : std_logic_vector(31 downto 0);
  signal hold_data_b1_s       : std_logic_vector(31 downto 0);
  signal hold_data_b0_s       : std_logic_vector(31 downto 0);
  signal cnt_hs_en_high_q     : unsigned(15 downto 0);
  signal cnt_hs_en_low_q      : unsigned(15 downto 0);
  signal cnt_hs_extended_q    : unsigned(15 downto 0);
  signal cnt_trail_en_q       : unsigned(15 downto 0);
  signal in_hs_en_q           : std_logic;
  signal hs_trail_en_q        : std_logic;
  signal hs_trail_en_r1_q     : std_logic;
  signal hs_is_long_packet_q  : std_logic;
  signal out_hsxx_clk_en_q    : std_logic;
  signal out_hs_clk_en_q      : std_logic;
  signal out_hs_data_en_q     : std_logic;
  signal out_lp_clk_q         : std_logic_vector(1 downto 0);
  signal out_lp_data_q        : std_logic_vector(1 downto 0);

begin

  ----------------------------------------------
  -- Outputs assignments
  ----------------------------------------------
  out_byte_l3_o     <= hold_data_out_s(31 downto 24);
  out_byte_l2_o     <= hold_data_out_s(23 downto 16);
  out_byte_l1_o     <= hold_data_out_s(15 downto  8);
  out_byte_l0_o     <= hold_data_out_s( 7 downto  0);
  out_hs_clk_en_o   <=  out_hs_clk_en_q;
  out_hsxx_clk_en_o <=  out_hsxx_clk_en_q;
  out_hs_data_en_o  <=  out_hs_data_en_q;
  out_lp_clk_o      <=  out_lp_clk_q;
  out_lp_data_o     <=  out_lp_data_q;

  ----------------------------------------------
  -- Asynchronous assignments
  ---------------------------------------------
  -- Output data
  hold_data_out_s <= hold_data_q(HSXX_DATA_C);

  -- Hold data bit 1 combinational
  hold_data_b1_s <= not( hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) & hold_data_q(1)(31) &
                         hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) & hold_data_q(1)(23) &
                         hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) & hold_data_q(1)(15) &
                         hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) & hold_data_q(1)( 7) );

  -- Hold data bit 1 combinational
  hold_data_b0_s <= not( hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) & hold_data_q(0)(31) &
                         hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) & hold_data_q(0)(23) &
                         hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) & hold_data_q(0)(15) &
                         hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) & hold_data_q(0)( 7) );

  -- Register stage
  reg_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      in_hs_en_q       <= '0';
      hs_trail_en_r1_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        in_hs_en_q       <= in_hs_en_i;
        hs_trail_en_r1_q <= hs_trail_en_q;
      end if;
    end if;
  end process reg_p;

  -- Shift register index 2 until last
  gen_shift_reg_from_b2 : for i in 2 to HSXX_DATA_C generate
    hold_data_p : process(arst_n, clk)
      procedure reset_registers_p is
      begin
        hold_data_q(i) <= (others => '0');
      end procedure;
    begin
      if rising_edge(clk) then
        if (srst = '1') then
          reset_registers_p;
        else
          if (in_hs_en_i = '1' and in_hs_en_q = '0') then
            hold_data_q(i) <= (others => '0');
          else
            hold_data_q(i) <= hold_data_q(i-1);
          end if;
        end if;
      end if;
    end process hold_data_p;
  end generate gen_shift_reg_from_b2;

  -- Hold data bit 1
  hold_data_1_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      hold_data_q(1) <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (in_hs_en_i = '1') then
          if (in_hs_en_q = '0') then
            hold_data_q(1) <= (others => '0');
          else
            hold_data_q(1) <= hold_data_q(0);
          end if;
        elsif (hs_is_long_packet_q = '1') then
          if (in_hs_en_q = '1') then
            hold_data_q(1) <= hold_data_b1_s;
          elsif (hs_trail_en_q = '1') then
            hold_data_q(1) <= hold_data_q(0);
          else
            hold_data_q(1) <= (others => '0');
          end if;
        else
          hold_data_q(1) <= hold_data_q(0);
        end if;
      end if;
    end if;
  end process hold_data_1_p;

  -- Hold data bit 0
  hold_data_0_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      hold_data_q(0) <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (in_hs_en_i = '1') then
          hold_data_q(0) <= in_byte_l3_i & in_byte_l2_i & in_byte_l1_i & in_byte_l0_i;
        elsif (hs_is_long_packet_q = '1') then
          if (in_hs_en_i = '0' and in_hs_en_q = '1') then
            hold_data_q(0) <= hold_data_b1_s;
          elsif (hs_trail_en_q = '1') then
            hold_data_q(0) <= hold_data_q(0);
          else
            hold_data_q(0) <= (others => '0');
          end if;
        else
          if (in_hs_en_i = '0' and in_hs_en_q = '1') then
            hold_data_q(0) <= hold_data_b0_s;
          elsif (hs_trail_en_q = '1') then
            hold_data_q(0) <= hold_data_q(0);
          else
            hold_data_q(0) <= (others => '0');
          end if;
        end if;
      end if;
    end if;
  end process hold_data_0_p;

  -- Counters of start/end states on CSI
  cnt_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      cnt_hs_en_high_q    <= (others => '0');
      cnt_hs_en_low_q     <= (others => '1');
      cnt_trail_en_q      <= to_unsigned(HSTRAILDATA_DLY_G, cnt_trail_en_q'length);
      cnt_hs_extended_q   <= to_unsigned(HSXX_DATA_C, cnt_hs_extended_q'length);
      hs_trail_en_q       <= '0';
      hs_is_long_packet_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        -- HS extended counter
        if (in_hs_en_i = '1' and in_hs_en_q = '0') then
          cnt_hs_extended_q <= to_unsigned(0, cnt_hs_extended_q'length);
        else
          if (cnt_hs_extended_q < to_unsigned(HSXX_DATA_C, cnt_hs_extended_q'length)) then
            cnt_hs_extended_q <= cnt_hs_extended_q + to_unsigned(1, cnt_hs_extended_q'length);
          end if;
        end if;

        -- HS enable high counter
        if (in_hs_en_i = '1' or cnt_hs_extended_q /= to_unsigned(HSXX_DATA_C, cnt_hs_extended_q'length)) then
          if (cnt_hs_en_high_q < to_unsigned(CNT_MAX_VAL_C, cnt_hs_en_high_q'length)) then
            cnt_hs_en_high_q <= cnt_hs_en_high_q + to_unsigned(1, cnt_hs_en_high_q'length);
          end if;
        else
          cnt_hs_en_high_q <= to_unsigned(0, cnt_hs_en_high_q'length);
        end if;

        -- HS enable low counter
        if (in_hs_en_i = '0' and cnt_hs_extended_q /= to_unsigned(0, cnt_hs_extended_q'length)) then
          if (cnt_hs_en_low_q < to_unsigned(CNT_MAX_VAL_C, cnt_hs_en_low_q'length)) then
            cnt_hs_en_low_q <= cnt_hs_en_low_q + to_unsigned(1, cnt_hs_en_low_q'length);
          end if;
        else
          cnt_hs_en_low_q <= to_unsigned(0, cnt_hs_en_low_q'length);
        end if;

        -- Trail delay enable counter
        if (in_hs_en_i = '1') then
          cnt_trail_en_q <= to_unsigned(HSTRAILDATA_DLY_G, cnt_trail_en_q'length);
        else
          if (in_hs_en_q = '1') then
            cnt_trail_en_q <= to_unsigned(0, cnt_trail_en_q'length);
          else
            if (cnt_trail_en_q /= to_unsigned(HSTRAILDATA_DLY_G, cnt_trail_en_q'length)) then
              cnt_trail_en_q <= cnt_trail_en_q + to_unsigned(1, cnt_trail_en_q'length);
            end if;
          end if;
        end if;

        -- HS trail enable counter
        if (in_hs_en_i = '1') then
          hs_trail_en_q <= '0';
        else
          if (in_hs_en_q = '1') then
            hs_trail_en_q <= '1';
          else
            if (cnt_trail_en_q = to_unsigned(HSTRAILDATA_DLY_G, cnt_trail_en_q'length) and cnt_hs_en_low_q = to_unsigned(HSTRAIL_DATA_END_C, cnt_hs_en_low_q'length)) then
              hs_trail_en_q <= '0';
            end if;
          end if;
        end if;

        -- Long packet status
        if (in_hs_en_i = '1' and cnt_hs_en_high_q = to_unsigned(3, cnt_hs_en_high_q'length)) then
          hs_is_long_packet_q <= '1';
        else
          if (in_hs_en_i = '0') then
            hs_is_long_packet_q <= '0';
          end if;
        end if;

      end if;
    end if;
  end process cnt_p;

  -- HS clock enable
  hs_clk_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_hs_clk_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_hs_en_high_q = to_unsigned(LP00_CLK_C, cnt_hs_en_high_q'length)) then
          out_hs_clk_en_q <= '1';
        elsif (cnt_hs_en_low_q = to_unsigned(HS00_CLK_END_C, cnt_hs_en_low_q'length)) then
          out_hs_clk_en_q <= '0';
        end if;
      end if;
    end if;
  end process;

  -- HS data clock enable
  hsxx_clk_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_hsxx_clk_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_hs_en_high_q >= to_unsigned(HS00_CLK_C, cnt_hs_en_high_q'length)) then
          out_hsxx_clk_en_q <= '1';
        elsif (cnt_hs_en_low_q >= to_unsigned(DATA2CLK_C, cnt_hs_en_low_q'length)) then
          out_hsxx_clk_en_q <= '0';
        end if;
      end if;
    end if;
  end process;

  -- HS data enable
  hs_data_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_hs_data_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_hs_en_high_q >= to_unsigned(LP00_DATA_C, cnt_hs_en_high_q'length)) then
          out_hs_data_en_q <= '1';
        elsif (cnt_hs_en_low_q >= to_unsigned(HSTRAIL_DATA_END_C, cnt_hs_en_low_q'length)) then
          out_hs_data_en_q <= '0';
        end if;
      end if;
    end if;
  end process;

  -- LP clock
  lp_clk_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_lp_clk_q <= LP11_C;
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_hs_en_high_q = to_unsigned(1, cnt_hs_en_high_q'length)) then
          out_lp_clk_q <= LP01_C;
        elsif (cnt_hs_en_high_q >= to_unsigned(LP01_CLK_C, cnt_hs_en_high_q'length)) then
          out_lp_clk_q <= LP00_C;
        elsif (cnt_hs_en_low_q >= to_unsigned(LP11_CLK_END_C, cnt_hs_en_low_q'length)) then
          out_lp_clk_q <= LP11_C;
        end if;
      end if;
    end if;
  end process;

  -- LP data
  lp_data_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      out_lp_data_q <= LP11_C;
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_hs_en_high_q = to_unsigned(CLK2DATA_C, cnt_hs_en_high_q'length)) then
          out_lp_data_q <= LP01_C;
        elsif (cnt_hs_en_high_q = to_unsigned(LP01_DATA_C, cnt_hs_en_high_q'length)) then
          out_lp_data_q <= LP00_C;
        elsif (cnt_hs_en_low_q = to_unsigned(LP11_DATA_END_C, cnt_hs_en_low_q'length)) then
          out_lp_data_q <= LP11_C;
        end if;
      end if;
    end if;
  end process;

end rtl;
