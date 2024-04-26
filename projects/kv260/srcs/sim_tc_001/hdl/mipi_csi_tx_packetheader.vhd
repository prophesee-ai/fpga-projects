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
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library xpm;
use     xpm.vcomponents.all;

----------------------------------------------
-- MIPI CSI-2 TX Packetheader
entity mipi_csi_tx_packetheader is
  generic (
    LANE_WIDTH_G      : positive range 1 to 4
  );
  port (
    -- Core clock and reset
    clk               : in  std_logic;
    arst_n            : in  std_logic;
    srst              : in  std_logic;

    -- Input configuration interface
    cfg_short_en_i    : in  std_logic;
    cfg_long_en_i     : in  std_logic;
    cfg_byte_data_i   : in  std_logic_vector(31 downto 0);
    cfg_virt_chan_i   : in  std_logic_vector( 1 downto 0);
    cfg_data_type_i   : in  std_logic_vector( 5 downto 0);
    cfg_word_cnt_i    : in  std_logic_vector(15 downto 0);
    cfg_chksum_rdy_i  : in  std_logic;
    cfg_chksum_i      : in  std_logic_vector(15 downto 0);

    -- Packet header interface
    ph_eotp_i        : in  std_logic;
    ph_bytepkt_en_o  : out std_logic;
    ph_bytepkt_o     : out std_logic_vector(31 downto 0)
  );
end entity;

architecture rtl of mipi_csi_tx_packetheader is

  -- Constants
  constant BYTEPKT_6B_C                   : std_logic_vector( 5 downto 0) := "001000";
  constant BYTEPKT_PH_DATA_C              : std_logic_vector(31 downto 0) := x"B8B8_B8B8";
  constant BYTEPKT_CHKSUM_DATA_C          : std_logic_vector(31 downto 0) := x"010F_0F0F";
  constant XPM_FIFO_DOUT_RESET_VALUE_C    : string  := "0";
  constant XPM_FIFO_ECC_MODE_C            : string  := "no_ecc";
  constant XPM_FIFO_MEMORY_TYPE_C         : string  := "auto";
  constant XPM_FIFO_READ_LATENCY_C        : natural := 4;
  constant XPM_FIFO_DEPTH_C               : natural := 512;
  constant XPM_FIFO_FULL_RESET_VALUE_C    : natural := 0;
  constant XPM_FIFO_PROG_EMPTY_THRESH_C   : natural := 5;
  constant XPM_FIFO_PROG_FULL_THRESH_C    : natural := 5;
  constant XPM_FIFO_DATA_COUNT_WIDTH_C    : natural := 1;
  constant XPM_FIFO_DATA_WIDTH_C          : natural := 32;
  constant XPM_FIFO_READ_MODE_C           : string  := "std";
  constant XPM_FIFO_USE_ADV_FEATURES_C    : string := "0000";
  constant XPM_FIFO_WAKEUP_TIME_C         : natural := 0;

  -- Signals
  signal short_pkt_en_q                   : std_logic;
  signal long_pkt_en_q                    : std_logic;
  signal long_pkt_en_r1_q                 : std_logic;
  signal long_pkt_en_r2_q                 : std_logic;
  signal long_pkt_indicator_q             : std_logic;
  signal byte_data_r1_q                   : std_logic_vector(31 downto 0);
  signal byte_data_r2_q                   : std_logic_vector(31 downto 0);
  signal byte_data_q                      : std_logic_vector(31 downto 0);
  signal vc_q                             : std_logic_vector( 1 downto 0);
  signal dt_q                             : std_logic_vector( 5 downto 0);
  signal wc_q                             : std_logic_vector(15 downto 0);
  signal wc_2l_s                          : std_logic_vector(15 downto 0);
  signal wc_4l_s                          : std_logic_vector(15 downto 0);
  signal ph_s                             : std_logic_vector(23 downto 0);
  signal ecc_q                            : std_logic_vector(7 downto 0);
  signal ph_en_q                          : std_logic;
  signal hs_sync_en_q                     : std_logic;
  signal data_id_en_q                     : std_logic;
  signal wc_0_en_q                        : std_logic;
  signal wc_1_en_q                        : std_logic;
  signal ecc_en_q                         : std_logic;
  signal cnt_ph_q                         : unsigned(3 downto 0);
  signal long_pkt_cnt_en_q                : std_logic;
  signal cnt_long_pkt_q                   : unsigned(15 downto 0);
  signal chksum_en_q                      : std_logic;
  signal chksum_en_r_q                    : std_logic;
  signal chksum_q                         : std_logic_vector(15 downto 0);
  signal eotp_en_q                        : std_logic_vector(3 downto 0);
  signal byte_data_fifo_s                 : std_logic_vector(31 downto 0);
  signal ph_bytepkt_q                     : std_logic_vector(31 downto 0);
  signal ph_bytepkt_en_q                  : std_logic;
  signal bytepkt_en_q                     : std_logic;
  signal long_pkt_ofst_q                  : std_logic;
  signal fifo_wr_en_s                     : std_logic;
  signal fifo_rd_en_s                     : std_logic;
  signal fifo_wr_data_s                   : std_logic_vector(31 downto 0);

  -- Output byte_clk_en re-generation
  signal bytepkt_en_r1_q                  : std_logic;
  signal bytepkt_en_r2_q                  : std_logic;
  signal wc_end_flag_s                    : std_logic;
  signal fifo_wr_rst_s                    : std_logic;
  signal fifo_rd_rst_s                    : std_logic;

  -- Xilinx FIFO adaptation (additional pipeline stage)
  signal short_en_r1_q                    : std_logic;
  signal long_en_r1_q                     : std_logic;
  signal long_en_1_r1_q                   : std_logic;
  signal long_en_2_r1_q                   : std_logic;
  signal short_en_r2_q                    : std_logic;
  signal long_en_r2_q                     : std_logic;
  signal long_en_1_r2_q                   : std_logic;
  signal long_en_2_r2_q                   : std_logic;
  signal ph_en_r1_q                       : std_logic;
  signal hs_sync_en_r1_q                  : std_logic;
  signal data_id_en_r1_q                  : std_logic;
  signal wc_0_en_r1_q                     : std_logic;
  signal wc_1_en_r1_q                     : std_logic;
  signal ecc_en_r1_q                      : std_logic;
  signal ph_en_r2_q                       : std_logic;
  signal hs_sync_en_r2_q                  : std_logic;
  signal data_id_en_r2_q                  : std_logic;
  signal wc_0_en_r2_q                     : std_logic;
  signal wc_1_en_r2_q                     : std_logic;
  signal ecc_en_r2_q                      : std_logic;
  signal ph_cnt_r1_q                      : unsigned(3 downto 0);
  signal ph_cnt_r2_q                      : unsigned(3 downto 0);
  signal cnt_lpkt_en_r1_q                 : std_logic;
  signal cnt_lpkt_en_r2_q                 : std_logic;
  signal chksum_en_r1_q                   : std_logic;
  signal chksum_en_r2_q                   : std_logic;
  signal eotp_en_r1_q                     : std_logic_vector(3 downto 0);
  signal eotp_en_r2_q                     : std_logic_vector(3 downto 0);
  signal fifo_rst_s                       : std_logic;

begin

  --------------------------------------------------
  -- Asynchronous assignment
  --------------------------------------------------
  ph_bytepkt_o    <= ph_bytepkt_q;
  ph_bytepkt_en_o <= ph_bytepkt_en_q;

  -- Packet header concatenation
  ph_s            <= wc_q & vc_q & dt_q;

  -- FIFO write enable
  fifo_wr_en_s    <= long_pkt_en_r2_q when (LANE_WIDTH_G = 1) else
                     long_pkt_en_q    when (LANE_WIDTH_G = 2) else
                     cfg_long_en_i    when (LANE_WIDTH_G = 4) else
                     '0';

  -- FIFO read enable
  fifo_rd_en_s    <= bytepkt_en_r1_q;

  -- FIFO write data
  fifo_wr_data_s  <= byte_data_r2_q  when (LANE_WIDTH_G = 1) else
                     byte_data_q     when (LANE_WIDTH_G = 2) else
                     cfg_byte_data_i when (LANE_WIDTH_G = 4) else
                     (others => '0');

  -- FIFO instantiation
  fifo_wr_rst_s   <= bytepkt_en_q and not(bytepkt_en_r1_q);
  fifo_rd_rst_s   <= bytepkt_en_q and not(bytepkt_en_r1_q);
  fifo_rst_s      <= fifo_wr_rst_s or fifo_rd_rst_s;

  -- Flags assignment
  wc_2l_s         <= std_logic_vector( resize( unsigned(wc_q(wc_q'high downto 1)), wc_2l_s'length) );
  wc_4l_s         <= std_logic_vector( resize( unsigned(wc_q(wc_q'high downto 2)), wc_4l_s'length) );

  wc_end_flag_s   <= '1' when (long_pkt_indicator_q = '1' and
                               ((LANE_WIDTH_G = 1 and cnt_long_pkt_q = unsigned(wc_q)    - to_unsigned(1, cnt_long_pkt_q'length))   or
                                (LANE_WIDTH_G = 2 and cnt_long_pkt_q = unsigned(wc_2l_s) - to_unsigned(1, cnt_long_pkt_q'length))   or
                                (LANE_WIDTH_G = 4 and cnt_long_pkt_q = unsigned(wc_4l_s) - to_unsigned(1, cnt_long_pkt_q'length)))) else
                     '0';

  --------------------------------------------------
  -- Synchronous FIFO instantiation
  --------------------------------------------------
  ph_dly_fifo_u : xpm_fifo_sync
    generic map (
      DOUT_RESET_VALUE    => XPM_FIFO_DOUT_RESET_VALUE_C,
      ECC_MODE            => XPM_FIFO_ECC_MODE_C,
      FIFO_MEMORY_TYPE    => XPM_FIFO_MEMORY_TYPE_C,
      FIFO_READ_LATENCY   => XPM_FIFO_READ_LATENCY_C,
      FIFO_WRITE_DEPTH    => XPM_FIFO_DEPTH_C,
      FULL_RESET_VALUE    => XPM_FIFO_FULL_RESET_VALUE_C,
      PROG_EMPTY_THRESH   => XPM_FIFO_PROG_EMPTY_THRESH_C,
      PROG_FULL_THRESH    => XPM_FIFO_PROG_FULL_THRESH_C,
      RD_DATA_COUNT_WIDTH => XPM_FIFO_DATA_COUNT_WIDTH_C,
      READ_DATA_WIDTH     => XPM_FIFO_DATA_WIDTH_C,
      READ_MODE           => XPM_FIFO_READ_MODE_C,
      USE_ADV_FEATURES    => XPM_FIFO_USE_ADV_FEATURES_C,
      WAKEUP_TIME         => XPM_FIFO_WAKEUP_TIME_C,
      WRITE_DATA_WIDTH    => XPM_FIFO_DATA_WIDTH_C,
      WR_DATA_COUNT_WIDTH => XPM_FIFO_DATA_COUNT_WIDTH_C
    )
    port map (
      wr_clk              => clk,
      rst                 => fifo_rst_s,
      sleep               => '0',
      injectdbiterr       => '0',
      injectsbiterr       => '0',
      wr_en               => fifo_wr_en_s,
      din                 => fifo_wr_data_s,
      dout                => byte_data_fifo_s,
      rd_en               => fifo_rd_en_s
    );

  -- Register stage to compensate the FIFO read latency
  reg_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      short_en_r1_q    <= '0';
      long_en_r1_q     <= '0';
      long_en_1_r1_q   <= '0';
      long_en_2_r1_q   <= '0';
      ph_cnt_r1_q      <= (others => '0');
      ph_en_r1_q       <= '0';
      hs_sync_en_r1_q  <= '0';
      data_id_en_r1_q  <= '0';
      wc_0_en_r1_q     <= '0';
      wc_1_en_r1_q     <= '0';
      ecc_en_r1_q      <= '0';
      cnt_lpkt_en_r1_q <= '0';
      chksum_en_r1_q   <= '0';
      eotp_en_r1_q     <= (others => '0');
      short_en_r2_q    <= '0';
      long_en_r2_q     <= '0';
      long_en_1_r2_q   <= '0';
      long_en_2_r2_q   <= '0';
      ph_cnt_r2_q      <= (others => '0');
      ph_en_r2_q       <= '0';
      hs_sync_en_r2_q  <= '0';
      data_id_en_r2_q  <= '0';
      wc_0_en_r2_q     <= '0';
      wc_1_en_r2_q     <= '0';
      ecc_en_r2_q      <= '0';
      cnt_lpkt_en_r2_q <= '0';
      bytepkt_en_r2_q  <= '0';
      chksum_en_r2_q   <= '0';
      eotp_en_r2_q     <= (others => '0');
      ph_bytepkt_en_q  <= '0';
      short_pkt_en_q   <= '0';
      long_pkt_en_q    <= '0';
      long_pkt_en_r1_q <= '0';
      long_pkt_en_r2_q <= '0';
      byte_data_q      <= (others => '0');
      byte_data_r1_q   <= (others => '0');
      byte_data_r2_q   <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        short_pkt_en_q   <= cfg_short_en_i;
        long_pkt_en_q    <= cfg_long_en_i;
        byte_data_q      <= cfg_byte_data_i;

        -- Stage 1
        short_en_r1_q    <= short_pkt_en_q;
        long_en_r1_q     <= long_pkt_en_q;
        long_en_1_r1_q   <= long_pkt_en_r1_q;
        long_en_2_r1_q   <= long_pkt_en_r2_q;
        ph_cnt_r1_q      <= cnt_ph_q;
        ph_en_r1_q       <= ph_en_q;
        hs_sync_en_r1_q  <= hs_sync_en_q;
        data_id_en_r1_q  <= data_id_en_q;
        wc_0_en_r1_q     <= wc_0_en_q;
        wc_1_en_r1_q     <= wc_1_en_q;
        ecc_en_r1_q      <= ecc_en_q;
        cnt_lpkt_en_r1_q <= long_pkt_cnt_en_q;
        chksum_en_r1_q   <= chksum_en_q;
        eotp_en_r1_q     <= eotp_en_q;
        long_pkt_en_r1_q <= long_pkt_en_q;
        byte_data_r1_q   <= byte_data_q;

        -- Stage 2
        short_en_r2_q    <= short_en_r1_q;
        long_en_r2_q     <= long_en_r1_q;
        long_en_1_r2_q   <= long_en_1_r1_q;
        long_en_2_r2_q   <= long_en_2_r1_q;
        ph_cnt_r2_q      <= ph_cnt_r1_q;
        ph_en_r2_q       <= ph_en_r1_q;
        hs_sync_en_r2_q  <= hs_sync_en_r1_q;
        data_id_en_r2_q  <= data_id_en_r1_q;
        wc_0_en_r2_q     <= wc_0_en_r1_q;
        wc_1_en_r2_q     <= wc_1_en_r1_q;
        ecc_en_r2_q      <= ecc_en_r1_q;
        cnt_lpkt_en_r2_q <= cnt_lpkt_en_r1_q;
        chksum_en_r2_q   <= chksum_en_r1_q;
        eotp_en_r2_q     <= eotp_en_r1_q;
        long_pkt_en_r2_q <= long_pkt_en_r1_q;
        bytepkt_en_r2_q  <= bytepkt_en_r1_q;
        byte_data_r2_q   <= byte_data_r1_q;

        -- Additional stage
        ph_bytepkt_en_q  <= bytepkt_en_r2_q;
      end if;
    end if;
  end process reg_p;

  -- Locks input data to register on byte_en transition
  lock_on_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      long_pkt_indicator_q <= '0';
      vc_q                 <= (others => '0');
      dt_q                 <= (others => '0');
      wc_q                 <= (others => '0');
      chksum_q             <= (others => '1');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cfg_short_en_i = '1' and short_pkt_en_q = '0') then
          long_pkt_indicator_q <= '0';
        elsif (cfg_long_en_i = '1' and long_pkt_en_q = '0') then
          long_pkt_indicator_q <= '1';
        end if;

        if ((cfg_short_en_i = '1' and short_pkt_en_q = '0') or (cfg_long_en_i = '1' and long_pkt_en_q = '0')) then
          vc_q <= cfg_virt_chan_i;
          dt_q <= cfg_data_type_i;
          wc_q <= cfg_word_cnt_i;
        end if;

        if (cfg_chksum_rdy_i = '1') then
          chksum_q <= cfg_chksum_i;
        end if;
      end if;
    end if;
  end process lock_on_en_p;

  -- Calculate ECC
  ecc_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      ecc_q <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        ecc_q(7 downto 6) <= (others => '0');

        if (short_pkt_en_q = '1' or long_pkt_en_q = '1') then
          ecc_q(5)   <= ph_s(10) xor ph_s(11) xor ph_s(12) xor ph_s(13) xor ph_s(14) xor ph_s(15) xor ph_s(16) xor ph_s(17) xor ph_s(18) xor ph_s(19) xor ph_s(21) xor ph_s(22) xor ph_s(23);
          ecc_q(4)   <= ph_s(4)  xor ph_s(5)  xor ph_s(6)  xor ph_s(7)  xor ph_s(8)  xor ph_s(9)  xor ph_s(16) xor ph_s(17) xor ph_s(18) xor ph_s(19) xor ph_s(20) xor ph_s(22) xor ph_s(23);
          ecc_q(3)   <= ph_s(1)  xor ph_s(2)  xor ph_s(3)  xor ph_s(7)  xor ph_s(8)  xor ph_s(9)  xor ph_s(13) xor ph_s(14) xor ph_s(15) xor ph_s(19) xor ph_s(20) xor ph_s(21) xor ph_s(23);
          ecc_q(2)   <= ph_s(0)  xor ph_s(2)  xor ph_s(3)  xor ph_s(5)  xor ph_s(6)  xor ph_s(9)  xor ph_s(11) xor ph_s(12) xor ph_s(15) xor ph_s(18) xor ph_s(20) xor ph_s(21) xor ph_s(22);
          ecc_q(1)   <= ph_s(0)  xor ph_s(1)  xor ph_s(3)  xor ph_s(4)  xor ph_s(6)  xor ph_s(8)  xor ph_s(10) xor ph_s(12) xor ph_s(14) xor ph_s(17) xor ph_s(20) xor ph_s(21) xor ph_s(22) xor ph_s(23);
          ecc_q(0)   <= ph_s(0)  xor ph_s(1)  xor ph_s(2)  xor ph_s(4)  xor ph_s(5)  xor ph_s(7)  xor ph_s(10) xor ph_s(11) xor ph_s(13) xor ph_s(16) xor ph_s(20) xor ph_s(21) xor ph_s(22) xor ph_s(23);
        end if;

      end if;
    end if;
  end process ecc_p;

  -- Paketheader enable
  ph_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      ph_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if ( (cfg_short_en_i = '1' and short_pkt_en_q = '0') or (cfg_long_en_i = '1' and long_pkt_en_q = '0') ) then
          ph_en_q <= '1';
        elsif (cnt_ph_q = to_unsigned(6, cnt_ph_q'length)) then
          ph_en_q <= '0';
        end if;
      end if;
    end if;
  end process ph_en_p;

  -- Paketheader data positioning counter
  cnt_ph_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      cnt_ph_q <= to_unsigned(0, cnt_ph_q'length);
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (ph_en_q = '1') then
          cnt_ph_q <= cnt_ph_q + to_unsigned(1, cnt_ph_q'length);
        else
          cnt_ph_q <= to_unsigned(0, cnt_ph_q'length);
        end if;
      end if;
    end if;
  end process cnt_ph_p;

  -- HS sync enable
  hs_sync_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      hs_sync_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_ph_q = to_unsigned(1, cnt_ph_q'length)) then
          hs_sync_en_q <= '1';
        else
          hs_sync_en_q <= '0';
        end if;
      end if;
    end if;
  end process hs_sync_en_p;

  -- Data ID enable
  data_id_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      data_id_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cnt_ph_q = to_unsigned(2, cnt_ph_q'length)) then
          data_id_en_q <= '1';
        else
          data_id_en_q <= '0';
        end if;
      end if;
    end if;
  end process data_id_en_p;

  -- Word count 0 enable
  wc_0_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      wc_0_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (LANE_WIDTH_G = 1) then
          -- One lane
          if (cnt_ph_q = to_unsigned(3, cnt_ph_q'length)) then
            wc_0_en_q <= '1';
          else
            wc_0_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 2) then
          -- Two lanes
          if (cnt_ph_q = to_unsigned(2, cnt_ph_q'length)) then
            wc_0_en_q <= '1';
          else
            wc_0_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 4) then
          -- Four lanes
          if (cnt_ph_q = to_unsigned(2, cnt_ph_q'length)) then
            wc_0_en_q <= '1';
          else
            wc_0_en_q <= '0';
          end if;
        else
          wc_0_en_q <= '0';
        end if;
      end if;
    end if;
  end process wc_0_en_p;

  -- Word count 1 enable
  wc_1_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      wc_1_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (LANE_WIDTH_G = 1) then
          -- One lane
          if (cnt_ph_q = to_unsigned(4, cnt_ph_q'length)) then
            wc_1_en_q <= '1';
          else
            wc_1_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 2) then
          -- Two lanes
          if (cnt_ph_q = to_unsigned(3, cnt_ph_q'length)) then
            wc_1_en_q <= '1';
          else
            wc_1_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 4) then
          -- Four lanes
          if (cnt_ph_q = to_unsigned(2, cnt_ph_q'length)) then
            wc_1_en_q <= '1';
          else
            wc_1_en_q <= '0';
          end if;
        else
          wc_1_en_q <= '0';
        end if;
      end if;
    end if;
  end process wc_1_en_p;

  -- ECC enable
  ecc_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      ecc_en_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (LANE_WIDTH_G = 1) then
          -- One lane
          if (cnt_ph_q = to_unsigned(5, cnt_ph_q'length)) then
            ecc_en_q <= '1';
          else
            ecc_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 2) then
          -- Two lanes
          if (cnt_ph_q = to_unsigned(3, cnt_ph_q'length)) then
            ecc_en_q <= '1';
          else
            ecc_en_q <= '0';
          end if;
        elsif (LANE_WIDTH_G = 4) then
          -- Four lanes
          if (cnt_ph_q = to_unsigned(2, cnt_ph_q'length)) then
            ecc_en_q <= '1';
          else
            ecc_en_q <= '0';
          end if;
        else
          ecc_en_q <= '0';
        end if;
      end if;
    end if;
  end process ecc_en_p;

  -- Long packet offset enable
  long_pkt_offs_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      long_pkt_ofst_q <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (cfg_long_en_i = '1' and long_pkt_en_q = '0' and cfg_word_cnt_i(0) = '1') then
          long_pkt_ofst_q <= '1';
        elsif (short_pkt_en_q = '1') then
          long_pkt_ofst_q <= '0';
        end if;
      end if;
    end if;
  end process long_pkt_offs_en_p;

  -- Long packet counter enable
  long_pkt_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      long_pkt_cnt_en_q  <= '0';
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (LANE_WIDTH_G = 4 and cnt_ph_q = to_unsigned(3, cnt_ph_q'length) and long_pkt_indicator_q = '1') then
          -- Four lanes
          long_pkt_cnt_en_q <= '1';
        elsif (LANE_WIDTH_G = 2 and cnt_ph_q = to_unsigned(4, cnt_ph_q'length) and long_pkt_indicator_q = '1') then
          -- Two lanes
          long_pkt_cnt_en_q <= '1';
        elsif (LANE_WIDTH_G = 1 and cnt_ph_q = to_unsigned(6, cnt_ph_q'length) and long_pkt_indicator_q = '1') then
          -- One lane
          long_pkt_cnt_en_q <= '1';
        elsif (wc_end_flag_s = '1') then
          long_pkt_cnt_en_q <= '0';
        end if;
      end if;
    end if;
  end process long_pkt_en_p;

  -- Long packet counter
  long_pkt_cnt_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      cnt_long_pkt_q <= to_unsigned(0, cnt_long_pkt_q'length);
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        if (long_pkt_cnt_en_q = '1') then
          cnt_long_pkt_q <= cnt_long_pkt_q + to_unsigned(1, cnt_long_pkt_q'length);
        else
          cnt_long_pkt_q <= to_unsigned(0, cnt_long_pkt_q'length);
        end if;
      end if;
    end if;
  end process long_pkt_cnt_p;

  -- Eotp enable
  eotp_en_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      chksum_en_q   <= '0';
      chksum_en_r_q <= '0';
      eotp_en_q     <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        chksum_en_q   <= wc_end_flag_s;
        chksum_en_r_q <= chksum_en_q;

        if (LANE_WIDTH_G = 1) then
          -- One lane
          if (ph_eotp_i = '1' and (chksum_en_r_q = '1' or (ecc_en_q = '1' and long_pkt_indicator_q = '0'))) then
            eotp_en_q(0) <= '1';
          else
            eotp_en_q(0) <= '0';
          end if;
        elsif (LANE_WIDTH_G = 2) then
          -- Two lanes
          if (ph_eotp_i = '1' and (chksum_en_q = '1' or (ecc_en_q = '1' and long_pkt_indicator_q = '0'))) then
            eotp_en_q(0) <= '1';
          else
            eotp_en_q(0) <= '0';
          end if;
        elsif (LANE_WIDTH_G = 4) then
          -- Four lanes
          if (ph_eotp_i = '1' and (wc_end_flag_s = '1' or (ecc_en_q = '1' and long_pkt_indicator_q = '0'))) then
            eotp_en_q(0) <= '1';
          else
            eotp_en_q(0) <= '0';
          end if;
        end if;

        eotp_en_q(1) <= eotp_en_q(0);

        if (LANE_WIDTH_G = 1 and eotp_en_q(1) = '1') then
          eotp_en_q(2) <= '1';
        else
          eotp_en_q(2) <= '0';
        end if;

        eotp_en_q(3) <= eotp_en_q(2);
      end if;
    end if;
  end process eotp_en_p;

  -- Put the packet header and data on the bus
  bus_pkt_p : process(arst_n, clk)
    procedure reset_registers_p is
    begin
      bytepkt_en_r1_q <= '0';
      bytepkt_en_q    <= '0';
      ph_bytepkt_q    <= (others => '0');
    end procedure;
  begin
    if (arst_n = '0') then
      reset_registers_p;
    elsif rising_edge(clk) then
      if (srst = '1') then
        reset_registers_p;
      else
        bytepkt_en_r1_q <= hs_sync_en_q or data_id_en_q or wc_0_en_q or wc_1_en_q or ecc_en_q or long_pkt_cnt_en_q or chksum_en_q or chksum_en_r_q or eotp_en_q(0) or eotp_en_q(1) or eotp_en_q(2) or eotp_en_q(3);
        bytepkt_en_q    <= bytepkt_en_r1_q;

        if (LANE_WIDTH_G = 2) then
          -- 2 MIPI Lane
          if (hs_sync_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize ( unsigned(BYTEPKT_PH_DATA_C(15 downto 0)), ph_bytepkt_q'length) );
          elsif (data_id_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(wc_q(7 downto 0) & vc_q & dt_q), ph_bytepkt_q'length) );
          elsif (wc_1_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(ecc_q & wc_q(15 downto 8)), ph_bytepkt_q'length) );
          elsif (cnt_lpkt_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(byte_data_fifo_s(15 downto 0)), ph_bytepkt_q'length) );
          elsif (chksum_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(chksum_q), ph_bytepkt_q'length) );
          elsif (eotp_en_r2_q(0) = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(BYTEPKT_CHKSUM_DATA_C(7 downto 0) & vc_q & BYTEPKT_6B_C), ph_bytepkt_q'length) );
          elsif (eotp_en_r2_q(1) = '1') then
            ph_bytepkt_q <= std_logic_vector( resize(unsigned(BYTEPKT_CHKSUM_DATA_C(BYTEPKT_CHKSUM_DATA_C'high downto 16)), ph_bytepkt_q'length) );
          else
            ph_bytepkt_q <= (others => '0');
          end if;

        elsif (LANE_WIDTH_G = 4) then
          -- 4 MIPI Lane
          if (hs_sync_en_r2_q = '1') then
            ph_bytepkt_q <= BYTEPKT_PH_DATA_C;
          elsif (data_id_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(ecc_q & wc_q(15 downto 0) & vc_q & dt_q), ph_bytepkt_q'length) );
          elsif (cnt_lpkt_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(byte_data_fifo_s(31 downto 0)), ph_bytepkt_q'length) );
          elsif (eotp_en_r2_q(0) = '1') then
            if (chksum_en_r2_q = '0') then
              ph_bytepkt_q <= std_logic_vector( resize( unsigned(BYTEPKT_CHKSUM_DATA_C(BYTEPKT_CHKSUM_DATA_C'high downto 8) & vc_q & BYTEPKT_6B_C), ph_bytepkt_q'length) );
            else
              ph_bytepkt_q <= std_logic_vector( resize( unsigned(BYTEPKT_CHKSUM_DATA_C(7 downto 0) & vc_q & BYTEPKT_6B_C & chksum_q), ph_bytepkt_q'length) );
            end if;
          elsif (eotp_en_r2_q(0) = '0' and chksum_en_r2_q = '1') then
            ph_bytepkt_q <= std_logic_vector( resize( unsigned(chksum_q), ph_bytepkt_q'length) );
          elsif (eotp_en_r2_q(1) = '1') then
            if (chksum_en_r2_q = '0') then
              ph_bytepkt_q <= (others => '1');
            else
              ph_bytepkt_q <= std_logic_vector( resize(unsigned(BYTEPKT_CHKSUM_DATA_C(BYTEPKT_CHKSUM_DATA_C'high downto 16)), ph_bytepkt_q'length) );
            end if;
            ph_bytepkt_q <= x"FFFF" & BYTEPKT_CHKSUM_DATA_C(BYTEPKT_CHKSUM_DATA_C'high downto 16);
          else
            ph_bytepkt_q <= (others => '0');
          end if;

        end if;

      end if;
    end if;
  end process bus_pkt_p;

end rtl;
