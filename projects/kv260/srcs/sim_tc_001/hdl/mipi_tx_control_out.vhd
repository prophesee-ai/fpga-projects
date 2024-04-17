-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ccam_evt_formats.all;
use work.ccam_evt_types.all;
use work.ccam_evt_types_v3.all;
use work.ccam_utils.all;


-----------------------------------------------------------
-- Output FSM for the Event to MIPI TX Packet Control Block
entity mipi_tx_control_out is
  generic (
    EVT30_SUPPORT          : boolean  := true;
    MIPI_DATA_WIDTH        : positive := 16;
    MIPI_MAX_PACKET_SIZE   : positive := 16384; -- Max. number of bytes in MIPI packet. Default 16KB.
    PACKET_SIZE_DATA_WIDTH : positive := 16;
    TIME_HIGH_PERIOD       : positive := 16
  );
  port (
    -- Core clock and reset
    clk                       : in  std_logic;
    arst_n                    : in  std_logic;
    srst                      : in  std_logic;

    -- Configuration Interface
    cfg_enable_i              : in  std_logic;
    cfg_evt_format_i          : in  evt_format_data_t;
    cfg_virtual_channel_i     : in  std_logic_vector(1 downto 0);
    cfg_data_type_i           : in  std_logic_vector(5 downto 0);
    cfg_blocking_mode_i       : in  std_logic;

    -- MIPI TX FIFO Read Interface
    fifo_rd_ready_o           : out std_logic;
    fifo_rd_valid_i           : in  std_logic;
    fifo_rd_first_i           : in  std_logic;
    fifo_rd_last_i            : in  std_logic;
    fifo_rd_data_i            : in  ccam_evt_data_t;

    -- Packet Size Input Interface
    packet_size_in_ready_o    : out std_logic;
    packet_size_in_valid_i    : in  std_logic;
    packet_size_in_first_i    : in  std_logic;
    packet_size_in_last_i     : in  std_logic;
    packet_size_in_data_i     : in  std_logic_vector(PACKET_SIZE_DATA_WIDTH-1 downto 0);

    -- MIPI RX Flow Control
    mipi_rx_ready_i           : in  std_logic;

    -- MIPI TX Generic IP Interface
    mipi_tx_ready_i           : in  std_logic;
    mipi_tx_valid_o           : out std_logic;
    mipi_tx_frame_start_o     : out std_logic;
    mipi_tx_frame_end_o       : out std_logic;
    mipi_tx_packet_start_o    : out std_logic;
    mipi_tx_packet_end_o      : out std_logic;
    mipi_tx_virtual_channel_o : out std_logic_vector(1 downto 0);
    mipi_tx_data_type_o       : out std_logic_vector(5 downto 0);
    mipi_tx_word_count_o      : out std_logic_vector(15 downto 0);
    mipi_tx_data_o            : out std_logic_vector(MIPI_DATA_WIDTH-1 downto 0)
  );
end entity mipi_tx_control_out;


architecture rtl of mipi_tx_control_out is

  ---------------------------
  -- Constant Declarations --
  ---------------------------

  constant EVT_SIZE            : positive := ((ccam_evt_data_t'length    + 7) / 8);
  constant EVT30_SIZE          : positive := ((ccam_evt_v3_data_t'length + 7) / 8);
  constant MIPI_DATA_SIZE      : positive := ((MIPI_DATA_WIDTH + 7) / 8);
  constant TX_DATA_PER_EVT     : positive := EVT_SIZE / MIPI_DATA_SIZE;
  constant TX_DATA_PER_EVT30   : positive := EVT30_SIZE / MIPI_DATA_SIZE;
  constant MAX_TX_DATA_PER_EVT : positive := maximum(TX_DATA_PER_EVT, TX_DATA_PER_EVT30);


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Configuration Interface
  signal cfg_evt_format_s          : evt_format_t;
  signal cfg_tx_data_per_evt_s     : positive;

  -- MIPI TX FIFO Read Interface
  signal fifo_rd_ready_q           : std_logic;
  signal fifo_rd_valid_q           : std_logic;
  signal fifo_rd_first_q           : std_logic;
  signal fifo_rd_last_q            : std_logic;
  signal fifo_rd_data_q            : ccam_evt_data_t;
  signal fifo_rd_data_count_q      : integer range 0 to MAX_TX_DATA_PER_EVT;

  -- Packet Size Input Interface
  signal packet_size_in_ready_q    : std_logic;
  signal packet_size_in_valid_q    : std_logic;
  signal packet_size_in_first_q    : std_logic;
  signal packet_size_in_last_q     : std_logic;
  signal packet_size_in_data_q     : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- MIPI TX Generic IP Interface
  signal mipi_tx_valid_q           : std_logic;
  signal mipi_tx_frame_start_q     : std_logic;
  signal mipi_tx_frame_end_q       : std_logic;
  signal mipi_tx_packet_start_q    : std_logic;
  signal mipi_tx_packet_end_q      : std_logic;
  signal mipi_tx_virtual_channel_q : std_logic_vector(1 downto 0);
  signal mipi_tx_data_type_q       : std_logic_vector(5 downto 0);
  signal mipi_tx_word_count_q      : std_logic_vector(15 downto 0);
  signal mipi_tx_data_q            : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0);

  -- Internal Counters
  signal packet_size_q             : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
  signal packet_data_count_q       : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);

  -- Frame and Packet Status
  signal is_frame_open_q           : std_logic;
  signal is_packet_open_q          : std_logic;

  -- State Signals
  type state_t is (RESET, WAIT_FRAME_START, WAIT_PACKET_START, SEND_PACKET_DATA);
  signal state_q : state_t;

    -- Debug
  attribute mark_debug : string;
  attribute mark_debug of fifo_rd_ready_q  : signal is "true";

begin


  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Configuration Interface
  cfg_evt_format_s          <= to_evt_format(cfg_evt_format_i);
  cfg_tx_data_per_evt_s     <= TX_DATA_PER_EVT30 when (EVT30_SUPPORT and cfg_evt_format_s = EVT_FORMAT_3_0) else TX_DATA_PER_EVT;

  fifo_rd_ready_o           <= fifo_rd_ready_q;
  packet_size_in_ready_o    <= packet_size_in_ready_q;
  mipi_tx_valid_o           <= mipi_tx_valid_q;
  mipi_tx_frame_start_o     <= mipi_tx_frame_start_q;
  mipi_tx_frame_end_o       <= mipi_tx_frame_end_q;
  mipi_tx_packet_start_o    <= mipi_tx_packet_start_q;
  mipi_tx_packet_end_o      <= mipi_tx_packet_end_q;
  mipi_tx_virtual_channel_o <= mipi_tx_virtual_channel_q;
  mipi_tx_data_type_o       <= mipi_tx_data_type_q;
  mipi_tx_word_count_o      <= mipi_tx_word_count_q;
  mipi_tx_data_o            <= mipi_tx_data_q;


  ----------------------------------
  -- Synchronous Processes        --
  ----------------------------------

  -- Output FSM Process for the Event to MIPI TX Packet Control Block
  mipi_tx_control_out_p : process(clk, arst_n)
    variable fifo_rd_ready_v           : std_logic;
    variable fifo_rd_valid_v           : std_logic;
    variable fifo_rd_first_v           : std_logic;
    variable fifo_rd_last_v            : std_logic;
    variable fifo_rd_data_v            : ccam_evt_data_t;
    variable fifo_rd_data_count_v      : integer range 0 to MAX_TX_DATA_PER_EVT;
    variable packet_size_in_ready_v    : std_logic;
    variable packet_size_in_valid_v    : std_logic;
    variable packet_size_in_first_v    : std_logic;
    variable packet_size_in_last_v     : std_logic;
    variable packet_size_in_data_v     : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
    variable mipi_tx_valid_v           : std_logic;
    variable mipi_tx_frame_start_v     : std_logic;
    variable mipi_tx_frame_end_v       : std_logic;
    variable mipi_tx_packet_start_v    : std_logic;
    variable mipi_tx_packet_end_v      : std_logic;
    variable mipi_tx_virtual_channel_v : std_logic_vector(1 downto 0);
    variable mipi_tx_data_type_v       : std_logic_vector(5 downto 0);
    variable mipi_tx_word_count_v      : std_logic_vector(15 downto 0);
    variable mipi_tx_data_v            : std_logic_vector(MIPI_DATA_WIDTH-1 downto 0);
    variable packet_size_v             : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
    variable packet_data_count_v       : unsigned(PACKET_SIZE_DATA_WIDTH-1 downto 0);
    variable is_frame_open_v           : std_logic;
    variable is_packet_open_v          : std_logic;
    variable next_state_v              : state_t;

    procedure reset_p is
    begin
      fifo_rd_ready_v           := '0';
      fifo_rd_valid_v           := '0';
      fifo_rd_first_v           := '0';
      fifo_rd_last_v            := '0';
      fifo_rd_data_v            := (others => '0');
      fifo_rd_data_count_v      := 0;
      packet_size_in_ready_v    := '0';
      packet_size_in_valid_v    := '0';
      packet_size_in_first_v    := '0';
      packet_size_in_last_v     := '0';
      packet_size_in_data_v     := (others => '0');
      mipi_tx_valid_v           := '0';
      mipi_tx_frame_start_v     := '0';
      mipi_tx_frame_end_v       := '0';
      mipi_tx_packet_start_v    := '0';
      mipi_tx_packet_end_v      := '0';
      mipi_tx_virtual_channel_v := (others => '0');
      mipi_tx_data_type_v       := (others => '0');
      mipi_tx_word_count_v      := (others => '0');
      mipi_tx_data_v            := (others => '0');
      packet_size_v             := (others => '0');
      packet_data_count_v       := (others => '0');
      is_frame_open_v           := '0';
      is_packet_open_v          := '0';
      next_state_v              := WAIT_FRAME_START;
      fifo_rd_ready_q           <= '0';
      fifo_rd_valid_q           <= '0';
      fifo_rd_first_q           <= '0';
      fifo_rd_last_q            <= '0';
      fifo_rd_data_q            <= (others => '0');
      fifo_rd_data_count_q      <= 0;
      packet_size_in_ready_q    <= '0';
      packet_size_in_valid_q    <= '0';
      packet_size_in_first_q    <= '0';
      packet_size_in_last_q     <= '0';
      packet_size_in_data_q     <= (others => '0');
      mipi_tx_valid_q           <= '0';
      mipi_tx_frame_start_q     <= '0';
      mipi_tx_frame_end_q       <= '0';
      mipi_tx_packet_start_q    <= '0';
      mipi_tx_packet_end_q      <= '0';
      mipi_tx_virtual_channel_q <= (others => '0');
      mipi_tx_data_type_q       <= (others => '0');
      mipi_tx_word_count_q      <= (others => '0');
      mipi_tx_data_q            <= (others => '0');
      packet_size_q             <= (others => '0');
      packet_data_count_q       <= (others => '0');
      is_frame_open_q           <= '0';
      is_packet_open_q          <= '0';
      state_q                   <= WAIT_FRAME_START;
    end procedure reset_p;
  begin
    if (arst_n = '0') then
      reset_p;
    elsif (rising_edge(clk)) then
      if (srst = '1') then
        reset_p;
      else

        -- Load variables from signals
        fifo_rd_ready_v           := fifo_rd_ready_q;
        fifo_rd_valid_v           := fifo_rd_valid_q;
        fifo_rd_first_v           := fifo_rd_first_q;
        fifo_rd_last_v            := fifo_rd_last_q;
        fifo_rd_data_v            := fifo_rd_data_q;
        fifo_rd_data_count_v      := fifo_rd_data_count_q;
        packet_size_in_ready_v    := packet_size_in_ready_q;
        packet_size_in_valid_v    := packet_size_in_valid_q;
        packet_size_in_first_v    := packet_size_in_first_q;
        packet_size_in_last_v     := packet_size_in_last_q;
        packet_size_in_data_v     := packet_size_in_data_q;
        mipi_tx_valid_v           := mipi_tx_valid_q;
        mipi_tx_frame_start_v     := mipi_tx_frame_start_q;
        mipi_tx_frame_end_v       := mipi_tx_frame_end_q;
        mipi_tx_packet_start_v    := mipi_tx_packet_start_q;
        mipi_tx_packet_end_v      := mipi_tx_packet_end_q;
        mipi_tx_virtual_channel_v := mipi_tx_virtual_channel_q;
        mipi_tx_data_type_v       := mipi_tx_data_type_q;
        mipi_tx_word_count_v      := mipi_tx_word_count_q;
        mipi_tx_data_v            := mipi_tx_data_q;
        packet_size_v             := packet_size_q;
        packet_data_count_v       := packet_data_count_q;
        is_frame_open_v           := is_frame_open_q;
        is_packet_open_v          := is_packet_open_q;
        next_state_v              := state_q;

        -- Ensure that the FIFO Read input is not overwritten
        assert (not(fifo_rd_ready_q = '1' and fifo_rd_valid_i = '1' and fifo_rd_valid_v = '1')) report "Error: FIFO Read input has been overwritten." severity failure;

        -- Check if event input should be sampled on this cycle, and sample it if so.
        if (fifo_rd_ready_v = '1' and fifo_rd_valid_i = '1') then
          fifo_rd_valid_v      := fifo_rd_valid_i;
          fifo_rd_first_v      := fifo_rd_first_i;
          fifo_rd_last_v       := fifo_rd_last_i;
          fifo_rd_data_v       := fifo_rd_data_i;
          fifo_rd_data_count_v := cfg_tx_data_per_evt_s - 1;
        end if;

        -- Ensure that the Packet Size input is not overwritten
        assert (not(packet_size_in_ready_q = '1' and packet_size_in_valid_i = '1' and packet_size_in_valid_v = '1')) report "Error: Packet Size input has been overwritten." severity failure;

        -- Check if event input should be sampled on this cycle, and sample it if so.
        if (packet_size_in_ready_v = '1' and packet_size_in_valid_i = '1') then
          packet_size_in_valid_v := packet_size_in_valid_i;
          packet_size_in_first_v := packet_size_in_first_i;
          packet_size_in_last_v  := packet_size_in_last_i;
          packet_size_in_data_v  := unsigned(packet_size_in_data_i);
        end if;

        -- Check if MIPI TX Interface output has been sampled, and deassert valid bit if so.
        if (mipi_tx_ready_i = '1' and mipi_tx_valid_v = '1') then
          mipi_tx_valid_v := '0';
        end if;

        -- Process the current state
        case (next_state_v) is

          -- In case we've closed the last frame and are waiting for a new frame start
        when WAIT_FRAME_START =>

          -- If we have received enough information, do the core processing
          if (packet_size_in_valid_v = '1' and fifo_rd_valid_v = '1' and mipi_tx_valid_v = '0') then
            if ((cfg_blocking_mode_i = '1' and mipi_rx_ready_i = '1') or (cfg_blocking_mode_i = '0')) then

              assert (packet_size_in_first_v = '1') report "ERROR: Frame start expected, but packet_size_in.first is false.";

              mipi_tx_valid_v           := '1';
              mipi_tx_frame_start_v     := packet_size_in_first_v;                  -- Should open new frame
              packet_size_in_first_v    := '0';                                     -- Reset new frame bit
              mipi_tx_packet_start_v    := '1';                                     -- Open new packet
              mipi_tx_virtual_channel_v := cfg_virtual_channel_i;           -- Sets the MIPI TX Virtual Channel for the Packet
              mipi_tx_data_type_v       := cfg_data_type_i;                 -- Sets the MIPI TX Data Type for the Packet
              mipi_tx_word_count_v      := std_logic_vector(resize(packet_size_in_data_v, mipi_tx_word_count_v'length)); -- Sets the Size of the Packet in Bytes

              -- Transmits data coming from FIFO Read channel, shifts remaining portions of data and update data counter
              mipi_tx_data_v            := fifo_rd_data_v(mipi_tx_data_v'range);
              fifo_rd_data_v(fifo_rd_data_v'high-mipi_tx_data_v'length downto 0) := fifo_rd_data_v(fifo_rd_data_v'high downto mipi_tx_data_v'length);
              fifo_rd_data_v(fifo_rd_data_v'high downto fifo_rd_data_v'length-mipi_tx_data_v'length) := (others => '0');
              if (fifo_rd_data_count_v = 0) then
                fifo_rd_valid_v           := '0';                           -- Releases FIFO Read data
              else
                fifo_rd_data_count_v      := fifo_rd_data_count_v - 1;
              end if;

              packet_size_v             := packet_size_in_data_v;         -- Updates new packet size
              packet_data_count_v       := to_unsigned(MIPI_DATA_SIZE, packet_data_count_v'length); -- Starts the counter with the first event transmitted

              -- If we've reached the end of the packet
              if (fifo_rd_data_count_v = 0 and packet_data_count_v = packet_size_v) then
                mipi_tx_frame_end_v       := packet_size_in_last_v;       -- If it's the last packet in the frame, close the frame.
                mipi_tx_packet_end_v      := '1';                         -- Closes the packet
                packet_size_in_valid_v    := '0';                         -- Releases the packet size information
                if (packet_size_in_last_v = '1') then
                  next_state_v              := WAIT_FRAME_START;          -- If it was the last packet in the frame, go back to waiting for a new frame start.
                else
                  next_state_v              := WAIT_PACKET_START;         -- If not the last packet in the frame, waits for a new packet start.
                end if;

              -- If it's not the end of the packet yet, keep on transmitting data in the current packet.
              else
                mipi_tx_frame_end_v       := '0';
                mipi_tx_packet_end_v      := '0';
                next_state_v              := SEND_PACKET_DATA;
              end if;
            end if;
          end if;

        when WAIT_PACKET_START =>

          -- If we have received enough information, do the core processing
          if (packet_size_in_valid_v = '1' and fifo_rd_valid_v = '1' and mipi_tx_valid_v = '0') then
            if ((cfg_blocking_mode_i = '1' and mipi_rx_ready_i = '1') or (cfg_blocking_mode_i = '0')) then

              assert (packet_size_in_first_v = '0') report "ERROR: Frame start not expected, but packet_size_in.first is true.";

              mipi_tx_valid_v           := '1';
              mipi_tx_frame_start_v     := packet_size_in_first_v; -- Should not open new frame
              mipi_tx_packet_start_v    := '1';                    -- Open new packet
              mipi_tx_virtual_channel_v := cfg_virtual_channel_i;  -- Sets the MIPI TX Virtual Channel for the Packet
              mipi_tx_data_type_v       := cfg_data_type_i;        -- Sets the MIPI TX Data Type for the Packet
              mipi_tx_word_count_v      := std_logic_vector(resize(packet_size_in_data_v, mipi_tx_word_count_v'length)); -- Sets the Size of the Packet in Bytes

              -- Transmits data coming from FIFO Read channel, shifts remaining portions of data and update data counter
              mipi_tx_data_v            := fifo_rd_data_v(mipi_tx_data_v'range);
              fifo_rd_data_v(fifo_rd_data_v'high-mipi_tx_data_v'length downto 0) := fifo_rd_data_v(fifo_rd_data_v'high downto mipi_tx_data_v'length);
              fifo_rd_data_v(fifo_rd_data_v'high downto fifo_rd_data_v'length-mipi_tx_data_v'length) := (others => '0');
              if (fifo_rd_data_count_v = 0) then
                fifo_rd_valid_v           := '0';                  -- Releases FIFO Read data
              else
                fifo_rd_data_count_v      := fifo_rd_data_count_v - 1;
              end if;

              packet_size_v             := packet_size_in_data_v;  -- Updates new packet size
              packet_data_count_v       := to_unsigned(MIPI_DATA_SIZE, packet_data_count_v'length); -- Starts the counter with the first event transmitted

              -- If we've reached the end of the packet
              if (fifo_rd_data_count_v = 0 and packet_data_count_v = packet_size_v) then
                mipi_tx_frame_end_v       := packet_size_in_last_v; -- If it's the last packet in the frame, close the frame.
                mipi_tx_packet_end_v      := '1';                   -- Closes the packet
                packet_size_in_valid_v    := '0';                   -- Releases the packet size information
                if (packet_size_in_last_v = '1') then
                  next_state_v              := WAIT_FRAME_START;    -- If it was the last packet in the frame, waits for a new frame start.
                else
                  next_state_v              := WAIT_PACKET_START;   -- If not the last packet in the frame, go back to waiting for a new packet start.
                end if;

              -- If it's not the end of the packet yet, keep on transmitting data in the current packet.
              else
                mipi_tx_frame_end_v       := '0';
                mipi_tx_packet_end_v      := '0';
                next_state_v              := SEND_PACKET_DATA;
              end if;
            end if;
          end if;

        when SEND_PACKET_DATA =>

          -- If we have received enough information, do the core processing
          if (packet_size_in_valid_v = '1' and fifo_rd_valid_v = '1' and mipi_tx_valid_v = '0') then

            mipi_tx_valid_v        := '1';
            mipi_tx_frame_start_v  := '0';                             -- Continue current frame
            mipi_tx_packet_start_v := '0';                             -- Continue current packet

            -- Transmits data coming from FIFO Read channel, shifts remaining portions of data and update data counter
            mipi_tx_data_v            := fifo_rd_data_v(mipi_tx_data_v'range);
            fifo_rd_data_v(fifo_rd_data_v'high-mipi_tx_data_v'length downto 0) := fifo_rd_data_v(fifo_rd_data_v'high downto mipi_tx_data_v'length);
            fifo_rd_data_v(fifo_rd_data_v'high downto fifo_rd_data_v'length-mipi_tx_data_v'length) := (others => '0');
            if (fifo_rd_data_count_v = 0) then
              fifo_rd_valid_v           := '0';                           -- Releases FIFO Read data
            else
              fifo_rd_data_count_v      := fifo_rd_data_count_v - 1;
            end if;

            packet_data_count_v    := packet_data_count_v + MIPI_DATA_SIZE;  -- Increments the packet size by the number of bytes in an event.

            -- If we've reached the end of the packet
            if (fifo_rd_data_count_v = 0 and packet_data_count_v = packet_size_v) then
              mipi_tx_frame_end_v    := packet_size_in_last_v; -- If it's the last packet in the frame, close the frame.
              mipi_tx_packet_end_v   := '1';                   -- Closes the packet
              packet_size_in_valid_v := '0';                   -- Releases the packet size information
              if (packet_size_in_last_v = '1') then
                next_state_v           := WAIT_FRAME_START;    -- If it was the last packet in the frame, waits for a new frame start.
              else
                next_state_v           := WAIT_PACKET_START;   -- If not the last packet in the frame, go back to waiting for a new packet start.
              end if;

            -- If it's not the end of the packet yet, keep on transmitting data in the current packet.
            else
              mipi_tx_frame_end_v    := '0';
              mipi_tx_packet_end_v   := '0';
              next_state_v           := SEND_PACKET_DATA;
            end if;
          end if;

        -- If we're in RESET state, or any other unknown state, reset all signals and
        -- start waiting for a new frame to start.
        when others =>
          reset_p;
          next_state_v              := WAIT_FRAME_START;
          state_q                   <= WAIT_FRAME_START;
        end case;

        -- Updates variable that indicates if frame is open
        if (mipi_tx_frame_start_v = '1') then
          is_frame_open_v := '1';
        elsif (mipi_tx_frame_end_v = '1') then
          is_frame_open_v := '0';
        end if;

        -- Updates variable that indicates if packet is open
        if (mipi_tx_packet_start_v = '1') then
          is_packet_open_v := '1';
        elsif (mipi_tx_packet_end_v = '1') then
          is_packet_open_v := '0';
        end if;

        -- Updates ready signals
        fifo_rd_ready_v        := (not fifo_rd_valid_v       ) and cfg_enable_i;
        packet_size_in_ready_v := (not packet_size_in_valid_v) and cfg_enable_i;

        -- Store variables into signals
        fifo_rd_ready_q           <= fifo_rd_ready_v;
        fifo_rd_valid_q           <= fifo_rd_valid_v;
        fifo_rd_first_q           <= fifo_rd_first_v;
        fifo_rd_last_q            <= fifo_rd_last_v;
        fifo_rd_data_q            <= fifo_rd_data_v;
        fifo_rd_data_count_q      <= fifo_rd_data_count_v;
        packet_size_in_ready_q    <= packet_size_in_ready_v;
        packet_size_in_valid_q    <= packet_size_in_valid_v;
        packet_size_in_first_q    <= packet_size_in_first_v;
        packet_size_in_last_q     <= packet_size_in_last_v;
        packet_size_in_data_q     <= packet_size_in_data_v;
        mipi_tx_valid_q           <= mipi_tx_valid_v;
        mipi_tx_frame_start_q     <= mipi_tx_frame_start_v;
        mipi_tx_frame_end_q       <= mipi_tx_frame_end_v;
        mipi_tx_packet_start_q    <= mipi_tx_packet_start_v;
        mipi_tx_packet_end_q      <= mipi_tx_packet_end_v;
        mipi_tx_virtual_channel_q <= mipi_tx_virtual_channel_v;
        mipi_tx_data_type_q       <= mipi_tx_data_type_v;
        mipi_tx_word_count_q      <= mipi_tx_word_count_v;
        mipi_tx_data_q            <= mipi_tx_data_v;
        packet_size_q             <= packet_size_v;
        packet_data_count_q       <= packet_data_count_v;
        is_frame_open_q           <= is_frame_open_v;
        is_packet_open_q          <= is_packet_open_v;
        state_q                   <= next_state_v;
      end if;
    end if;
  end process mipi_tx_control_out_p;


end rtl;
