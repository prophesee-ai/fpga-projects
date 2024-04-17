-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_types.all;
use work.ccam_utils.all;


--------------------------------------
-- Events to MIPI Packet Control Block
-- for a MIPI CSI2 TX IP
entity lattice_mipi_tx_packet_if is
  generic (
    MIPI_DATA_WIDTH   : positive := 16;
    CLK_FREQ          : positive := 100000000;
    USE_FRAME_COUNT_G : boolean  := false
  );
  port (

    -- Core clock and reset
    clk                     : in  std_logic;
    arst_n                  : in  std_logic;
    srst                    : in  std_logic;

    -- Configuration Interface
    cfg_enable_i            : in  std_logic;
    cfg_start_time_i        : in  std_logic_vector(15 downto 0);
    cfg_start_frame_time_i  : in  std_logic_vector(15 downto 0);
    cfg_end_frame_time_i    : in  std_logic_vector(15 downto 0);
    cfg_inter_frame_time_i  : in  std_logic_vector(15 downto 0);
    cfg_inter_packet_time_i : in  std_logic_vector(15 downto 0);

    -- MIPI TX Generic IP Input Interface
    txi_ready_o             : out std_logic;
    txi_valid_i             : in  std_logic;
    txi_frame_start_i       : in  std_logic;
    txi_frame_end_i         : in  std_logic;
    txi_packet_start_i      : in  std_logic;
    txi_packet_end_i        : in  std_logic;
    txi_virtual_channel_i   : in  std_logic_vector(1 downto 0);
    txi_data_type_i         : in  std_logic_vector(5 downto 0);
    txi_word_count_i        : in  std_logic_vector(15 downto 0);
    txi_data_i              : in  std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0);

    -- Lattice's MIPI IP Parallel Interface
    txo_short_en_o          : out std_logic; -- Frame Valid input for parallel interface
    txo_long_en_o           : out std_logic; -- Line Valid input for parallel interface
    txo_crc_rst_o           : out std_logic; -- Reset the CRC data calculation
    txo_data_o              : out std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0); -- Pixel data bus for parallel interface
    txo_vc_o                : out std_logic_vector(1 downto 0); -- 2-bit Virtual Channel Number
    txo_dt_o                : out std_logic_vector(5 downto 0); -- 6-bit Data Type
    txo_wc_o                : out std_logic_vector(15 downto 0) -- 16-bit Word Count in byte packets.  16'h05A0 = 16'd1440 bytes = 1440 * (8-bits per byte) / (24-bits per pixel for RGB888) = 480 pixels
  );
end entity lattice_mipi_tx_packet_if;

architecture rtl of lattice_mipi_tx_packet_if is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant EVT_SIZE             : positive := ((ccam_evt_data_t'length + 7) / 8);
  constant FRAME_START_TYPE     : std_logic_vector(5 downto 0) := "000000";
  constant FRAME_END_TYPE       : std_logic_vector(5 downto 0) := "000001";
  constant CLK_CYCLES_PER_US    : integer := CLK_FREQ / 1000000;
  constant MAX_FRAME_COUNT_C    : unsigned(15 downto 0) := to_unsigned(iff(USE_FRAME_COUNT_G, 65535, 0), 16);
  constant INIT_FRAME_COUNT_C   : unsigned(15 downto 0) := to_unsigned(iff(USE_FRAME_COUNT_G, 1, 0), 16);


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- MIPI TX Generic IP Input Interface
  signal txi_ready_q               : std_logic;
  signal txi_valid_q               : std_logic;
  signal txi_frame_start_q         : std_logic;
  signal txi_frame_end_q           : std_logic;
  signal txi_packet_start_q        : std_logic;
  signal txi_packet_end_q          : std_logic;
  signal txi_virtual_channel_q     : std_logic_vector(1 downto 0);
  signal txi_data_type_q           : std_logic_vector(5 downto 0);
  signal txi_word_count_q          : std_logic_vector(15 downto 0);
  signal txi_data_q                : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0);
  signal txi_data_valid_q          : std_logic;

  -- Lattice's MIPI IP Parallel Interface
  signal txo_short_en_q            : std_logic := '0';
  signal txo_long_en_q             : std_logic := '0';
  signal txo_crc_rst_q             : std_logic := '0';
  signal txo_data_q                : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0) := (others => '0');
  signal txo_vc_q                  : std_logic_vector(1 downto 0) := (others => '0');
  signal txo_dt_q                  : std_logic_vector(5 downto 0) := (others => '0');
  signal txo_wc_q                  : std_logic_vector(15 downto 0) := (others => '0');

  -- Configurable Internal Timers
  signal start_timer_q             : unsigned(15 downto 0);
  signal start_timer_done_q        : std_logic;
  signal start_frame_timer_q       : unsigned(15 downto 0);
  signal start_frame_timer_done_q  : std_logic;
  signal end_frame_timer_q         : unsigned(15 downto 0);
  signal end_frame_timer_done_q    : std_logic;
  signal inter_frame_timer_q       : unsigned(15 downto 0);
  signal inter_frame_timer_done_q  : std_logic;
  signal inter_packet_timer_q      : unsigned(15 downto 0);
  signal inter_packet_timer_done_q : std_logic;

  -- Frame Count
  signal frame_count_q             : unsigned(15 downto 0);

  -- State Signals
  type state_t is (RESET, RUN);
  signal state_q                   : state_t;

begin

  -- -----------------------------------
  -- Asynchronous Signal Assignments --
  -- -----------------------------------

  -- MIPI TX Generic IP Input Interface
  txi_ready_o    <= txi_ready_q;

  -- Lattice's MIPI IP Parallel Interface
  txo_short_en_o <= txo_short_en_q;
  txo_long_en_o  <= txo_long_en_q;
  txo_crc_rst_o  <= txo_crc_rst_q;
  txo_data_o     <= txo_data_q;
  txo_vc_o       <= txo_vc_q;
  txo_dt_o       <= txo_dt_q;
  txo_wc_o       <= txo_wc_q;


  -- --------------------------------
  -- Synchronous Processes        --
  -- --------------------------------

  -- Output FSM Process for the Event to MIPI TX Packet Control Block
  evt_mipi_tx_packet_control_out_p : process(clk, arst_n)
    variable txi_ready_v           : std_logic;
    variable txi_valid_v           : std_logic;
    variable txi_frame_start_v     : std_logic;
    variable txi_frame_end_v       : std_logic;
    variable txi_packet_start_v    : std_logic;
    variable txi_packet_end_v      : std_logic;
    variable txi_virtual_channel_v : std_logic_vector(1 downto 0);
    variable txi_data_type_v       : std_logic_vector(5 downto 0);
    variable txi_word_count_v      : std_logic_vector(15 downto 0);
    variable txi_data_v            : std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0);
    variable txi_data_valid_v      : std_logic;
    variable txo_short_en_v        : std_logic;
    variable txo_long_en_v         : std_logic;
    variable txo_crc_rst_v         : std_logic;
    variable txo_data_v            : std_logic_vector(MIPI_DATA_WIDTH - 1 downto 0);
    variable txo_vc_v              : std_logic_vector(1 downto 0);
    variable txo_dt_v              : std_logic_vector(5 downto 0);
    variable txo_wc_v              : std_logic_vector(15 downto 0);
    variable all_timers_done_v     : std_logic;
    variable next_state_v          : state_t;
    variable frame_count_v         : unsigned(15 downto 0);

    procedure reset_p is
    begin
      txi_ready_v               := '0';
      txi_valid_v               := '0';
      txi_frame_start_v         := '0';
      txi_frame_end_v           := '0';
      txi_packet_start_v        := '0';
      txi_packet_end_v          := '0';
      txi_virtual_channel_v     := (others => '0');
      txi_data_type_v           := (others => '0');
      txi_word_count_v          := (others => '0');
      txi_data_v                := (others => '0');
      txi_data_valid_v          := '0';
      txo_short_en_v            := '0';
      txo_long_en_v             := '0';
      txo_crc_rst_v             := '0';
      txo_data_v                := (others => '0');
      txo_vc_v                  := (others => '0');
      txo_dt_v                  := (others => '0');
      txo_wc_v                  := (others => '0');
      frame_count_v             := INIT_FRAME_COUNT_C;
      all_timers_done_v         := '0';
      next_state_v              := RESET;
      txi_ready_q               <= '0';
      txi_valid_q               <= '0';
      txi_frame_start_q         <= '0';
      txi_frame_end_q           <= '0';
      txi_packet_start_q        <= '0';
      txi_packet_end_q          <= '0';
      txi_virtual_channel_q     <= (others => '0');
      txi_data_type_q           <= (others => '0');
      txi_word_count_q          <= (others => '0');
      txi_data_q                <= (others => '0');
      txi_data_valid_q          <= '0';
      txo_short_en_q            <= '0';
      txo_long_en_q             <= '0';
      txo_crc_rst_q             <= '0';
      txo_data_q                <= (others => '0');
      txo_vc_q                  <= (others => '0');
      txo_dt_q                  <= (others => '0');
      txo_wc_q                  <= (others => '0');
      frame_count_q             <= INIT_FRAME_COUNT_C;
      start_timer_q             <= (others => '0');
      start_timer_done_q        <= '0';
      start_frame_timer_q       <= (others => '0');
      start_frame_timer_done_q  <= '0';
      end_frame_timer_q         <= (others => '0');
      end_frame_timer_done_q    <= '0';
      inter_frame_timer_q       <= (others => '0');
      inter_frame_timer_done_q  <= '0';
      inter_packet_timer_q      <= (others => '0');
      inter_packet_timer_done_q <= '0';
      state_q                   <= RESET;
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Reset variables to ensure no flip-flops are inferred
        all_timers_done_v     := '0';

        -- Load variables from signals
        txi_ready_v           := txi_ready_q;
        txi_valid_v           := txi_valid_q;
        txi_frame_start_v     := txi_frame_start_q;
        txi_frame_end_v       := txi_frame_end_q;
        txi_packet_start_v    := txi_packet_start_q;
        txi_packet_end_v      := txi_packet_end_q;
        txi_virtual_channel_v := txi_virtual_channel_q;
        txi_data_type_v       := txi_data_type_q;
        txi_word_count_v      := txi_word_count_q;
        txi_data_v            := txi_data_q;
        txi_data_valid_v      := txi_data_valid_q;
        txo_short_en_v        := txo_short_en_q;
        txo_long_en_v         := txo_long_en_q;
        txo_crc_rst_v         := txo_crc_rst_q;
        txo_data_v            := txo_data_q;
        txo_vc_v              := txo_vc_q;
        txo_dt_v              := txo_dt_q;
        txo_wc_v              := txo_wc_q;
        frame_count_v         := frame_count_q;

        -- Ensure that the FIFO Read input is not overwritten
        assert (not (txi_ready_q = '1' and txi_valid_i = '1' and txi_valid_v = '1')) report "Error: MIPI TX Input Data has been overwritten." severity failure;

        -- Check if event input should be sampled on this cycle, and sample it if so.
        if (txi_ready_v = '1' and txi_valid_i = '1') then
          txi_valid_v           := txi_valid_i;
          txi_frame_start_v     := txi_frame_start_i;
          txi_frame_end_v       := txi_frame_end_i;
          txi_packet_start_v    := txi_packet_start_i;
          txi_packet_end_v      := txi_packet_end_i;
          txi_virtual_channel_v := txi_virtual_channel_i;
          txi_data_type_v       := txi_data_type_i;
          txi_word_count_v      := txi_word_count_i;
          txi_data_v            := txi_data_i;
          txi_data_valid_v      := txi_valid_i;
        end if;

        -- Start Timer
        if (start_timer_q /= (start_timer_q'range => '0')) then
          start_timer_q             <= start_timer_q - to_unsigned(1, 1);
          start_timer_done_q        <= '0';
        else
          start_timer_q             <= (start_timer_q'range => '0');
          start_timer_done_q        <= '1';
        end if;

        -- Start Frame Timer
        if (start_frame_timer_q /= (start_frame_timer_q'range => '0')) then
          start_frame_timer_q       <= start_frame_timer_q - to_unsigned(1, 1);
          start_frame_timer_done_q  <= '0';
        else
          start_frame_timer_q       <= (start_frame_timer_q'range => '0');
          start_frame_timer_done_q  <= '1';
        end if;

        -- End Frame Timer
        if (end_frame_timer_q /= (end_frame_timer_q'range => '0')) then
          end_frame_timer_q         <= end_frame_timer_q - to_unsigned(1, 1);
          end_frame_timer_done_q    <= '0';
        else
          end_frame_timer_q         <= (end_frame_timer_q'range => '0');
          end_frame_timer_done_q    <= '1';
        end if;

        -- Inter Frame Timer
        if (inter_frame_timer_q /= (inter_frame_timer_q'range => '0')) then
          inter_frame_timer_q       <= inter_frame_timer_q - to_unsigned(1, 1);
          inter_frame_timer_done_q  <= '0';
        else
          inter_frame_timer_q       <= (inter_frame_timer_q'range => '0');
          inter_frame_timer_done_q  <= '1';
        end if;

        -- Inter Packet Timer
        if (inter_packet_timer_q /= (inter_packet_timer_q'range => '0')) then
          inter_packet_timer_q      <= inter_packet_timer_q - to_unsigned(1, 1);
          inter_packet_timer_done_q <= '0';
        else
          inter_packet_timer_q      <= (inter_packet_timer_q'range => '0');
          inter_packet_timer_done_q <= '1';
        end if;

        -- Check whether all timers are done.
        if (start_timer_done_q = '1' and start_frame_timer_done_q = '1' and end_frame_timer_done_q = '1' and inter_frame_timer_done_q = '1' and inter_packet_timer_done_q = '1') then
          all_timers_done_v := '1';
        else
          all_timers_done_v := '0';
        end if;

        -- Determine the FSM state
        case (next_state_v) is

          -- Run core processing logic
          when RUN =>

            -- If we have received enough information, do the core processing.
            if (txi_valid_v = '1' and all_timers_done_v = '1') then

              -- Check if we should open a frame
              if (txi_frame_start_v = '1' and txo_short_en_v = '0') then
                txo_short_en_v            := '1';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                txo_vc_v                  := (others => '0');
                txo_dt_v                  := FRAME_START_TYPE;
                txo_wc_v                  := std_logic_vector(frame_count_v);
                txo_data_v                := (others => '0');

              -- Check if we should open a frame
              elsif (txi_frame_start_v = '1' and txo_short_en_v = '1') then
                txo_short_en_v            := '0';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                txi_frame_start_v         := '0';
                start_frame_timer_q       <= unsigned(cfg_start_frame_time_i);
                start_frame_timer_done_q  <= '0';

              -- Otherwise, check if we should open a new packet
              elsif (txi_packet_start_v = '1') then
                txo_short_en_v            := '0';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                txi_packet_start_v        := '0';
                txo_vc_v                  := txi_virtual_channel_v;
                txo_dt_v                  := txi_data_type_v;
                txo_wc_v                  := txi_word_count_v;

              -- Otherwise, check if we have data to transmit.
              elsif (txi_data_valid_v = '1') then
                txo_short_en_v            := '0';
                txo_long_en_v             := '1';
                txo_crc_rst_v             := '0';
                txo_data_v                := txi_data_v;
                txi_data_valid_v          := '0';

              -- Otherwise, check if we need to close current packet.
              elsif (txi_packet_end_v = '1') then
                txo_short_en_v            := '0';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '0';
                txi_packet_end_v          := '0';
                if (txi_frame_end_v = '1') then
                  end_frame_timer_q         <= unsigned(cfg_end_frame_time_i);
                  end_frame_timer_done_q    <= '0';
                else
                  inter_packet_timer_q      <= unsigned(cfg_inter_packet_time_i);
                  inter_packet_timer_done_q <= '0';
                end if;

              -- Otherwise, check if we need to close current frame.
              elsif (txi_frame_end_v = '1' and txo_short_en_v = '0') then
                txo_short_en_v            := '1';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                txo_vc_v                  := (others => '0');
                txo_dt_v                  := FRAME_END_TYPE;
                txo_wc_v                  := std_logic_vector(frame_count_v);
                txo_data_v                := (others => '0');

                -- Increment frame_count_v
                if (USE_FRAME_COUNT_G) then
                  if (frame_count_v >= MAX_FRAME_COUNT_C) then
                    frame_count_v := INIT_FRAME_COUNT_C;
                  else
                    frame_count_v := frame_count_v + 1;
                  end if;
                end if;

              -- Manage the end of the frame, waiting before starting a new frame.
              elsif (txi_frame_end_v = '1' and txo_short_en_v = '1') then
                txo_short_en_v            := '0';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                txi_frame_end_v           := '0';
                inter_frame_timer_q       <= unsigned(cfg_inter_frame_time_i);
                inter_frame_timer_done_q  <= '0';

              -- Should never reach this condition. If it's the case then reset the block.
              else
                assert (false) report "ERROR: Input packet still has untreated commands which have not been treated." severity failure;
                txo_short_en_v            := '0';
                txo_long_en_v             := '0';
                txo_crc_rst_v             := '1';
                next_state_v              := RESET;
              end if;

              -- If all actions in the current transaction have been completed,
              -- then we can release the transaction in order to accept new data.
              if (txi_frame_start_v = '0' and txi_frame_end_v = '0' and txi_packet_start_v = '0' and txi_packet_end_v = '0' and txi_data_valid_v = '0') then
                txi_valid_v               := '0';
              end if;

            -- If we have started transmitting the current packet, we must have new data every cycle,
            -- otherwise we break the protocol, in which case we reset.
            elsif (txo_long_en_v = '1' and txi_data_valid_v = '0') then
              assert (false) report "ERROR: Detected gap in long packet transmission." severity failure;
              next_state_v := RESET;
            end if;

          -- Reset and unknown states
          when others =>
            txi_ready_v               := '0';
            txi_valid_v               := '0';
            txi_frame_start_v         := '0';
            txi_frame_end_v           := '0';
            txi_packet_start_v        := '0';
            txi_packet_end_v          := '0';
            txi_virtual_channel_v     := (others => '0');
            txi_data_type_v           := (others => '0');
            txi_word_count_v          := (others => '0');
            txi_data_v                := (others => '0');
            txi_data_valid_v          := '0';
            txo_short_en_v            := '0';
            txo_long_en_v             := '0';
            txo_crc_rst_v             := '0';
            txo_data_v                := (others => '0');
            txo_vc_v                  := (others => '0');
            txo_dt_v                  := (others => '0');
            txo_wc_v                  := (others => '0');
            start_timer_q             <= unsigned(cfg_start_time_i);
            start_timer_done_q        <= '0';
            start_frame_timer_q       <= (others => '0');
            start_frame_timer_done_q  <= '0';
            end_frame_timer_q         <= (others => '0');
            end_frame_timer_done_q    <= '0';
            inter_frame_timer_q       <= (others => '0');
            inter_frame_timer_done_q  <= '0';
            inter_packet_timer_q      <= (others => '0');
            inter_packet_timer_done_q <= '0';
            next_state_v              := RUN;
        end case;

        -- Updates ready signals
        txi_ready_v := (not txi_valid_v) and cfg_enable_i;

        -- Store variables into signals
        txi_ready_q           <= txi_ready_v;
        txi_valid_q           <= txi_valid_v;
        txi_frame_start_q     <= txi_frame_start_v;
        txi_frame_end_q       <= txi_frame_end_v;
        txi_packet_start_q    <= txi_packet_start_v;
        txi_packet_end_q      <= txi_packet_end_v;
        txi_virtual_channel_q <= txi_virtual_channel_v;
        txi_data_type_q       <= txi_data_type_v;
        txi_word_count_q      <= txi_word_count_v;
        txi_data_q            <= txi_data_v;
        txi_data_valid_q      <= txi_data_valid_v;
        txo_short_en_q        <= txo_short_en_v;
        txo_long_en_q         <= txo_long_en_v;
        txo_crc_rst_q         <= txo_crc_rst_v;
        txo_data_q            <= txo_data_v;
        txo_vc_q              <= txo_vc_v;
        txo_dt_q              <= txo_dt_v;
        txo_wc_q              <= txo_wc_v;
        frame_count_q         <= frame_count_v;
        state_q               <= next_state_v;
      end if;
    end if;
  end process evt_mipi_tx_packet_control_out_p;

end rtl;
