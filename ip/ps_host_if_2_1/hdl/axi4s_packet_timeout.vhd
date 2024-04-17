-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-----------------------------
-- AXI4-Stream Packet Timeout
-- Insert the data present on the insert_tdata_i input if a tlast signal is not
-- detected on the input data stream before the timeout counter reaches
-- timeout_value_i.
-- Since the input ready signal is combinatorial this pipeline stage must be
-- preceded by a skid buffer.
entity axi4s_packet_timeout is
  generic (
    AXIL_DATA_WIDTH_G  : positive := 32;
    AXIS_TDATA_WIDTH_G : positive := 64;
    AXIS_TUSER_WIDTH_G : positive := 1
  );
  port (
    clk                : in  std_logic;
    rstn               : in  std_logic;

    -- Control Signals
    clear_i            : in  std_logic;
    enable_i           : in  std_logic;
    timeout_value_i    : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    timeout_o          : out std_logic;

    -- Insert Data
    insert_tdata_i     : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    insert_tkeep_i     : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    insert_tuser_i     : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    insert_tlast_i     : in  std_logic;

    -- Input Data Stream
    s_axis_tready      : out std_logic;
    s_axis_tvalid      : in  std_logic;
    s_axis_tdata       : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    s_axis_tkeep       : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    s_axis_tuser       : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    s_axis_tlast       : in  std_logic;

    -- Output Data Stream
    m_axis_tready      : in  std_logic;
    m_axis_tvalid      : out std_logic;
    m_axis_tdata       : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    m_axis_tkeep       : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
    m_axis_tuser       : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
    m_axis_tlast       : out std_logic
  );
end axi4s_packet_timeout;

architecture rtl of axi4s_packet_timeout is

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Timeout signal
  signal timeout_q       : std_logic;

  -- Slave AXI4-Stream ready signal
  signal s_axis_tready_s : std_logic;

  -- Master AXI4-Stream registered outputs
  signal m_axis_tvalid_q : std_logic;
  signal m_axis_tdata_q  : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal m_axis_tkeep_q  : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal m_axis_tuser_q  : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal m_axis_tlast_q  : std_logic;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Slave interface ready: high if master interface ready is high or if master valid is low (meaning there is currently
  -- no valid data on the output interface), and low if there is a timeout (tlast needs to be sent)
  s_axis_tready_s <= (m_axis_tready or not m_axis_tvalid_q) and not timeout_q;
  s_axis_tready   <= s_axis_tready_s;

  -- Master AXI4-Stream registered output interface assignment
  m_axis_tvalid   <= m_axis_tvalid_q;
  m_axis_tdata    <= m_axis_tdata_q;
  m_axis_tkeep    <= m_axis_tkeep_q;
  m_axis_tuser    <= m_axis_tuser_q;
  m_axis_tlast    <= m_axis_tlast_q;

  -- Timeout output is needed to reset the packetizer counter
  timeout_o       <= timeout_q;

  ---------------
  -- Processes --
  ---------------

  -- Timeout counter: a tlast transaction must be done when the counter reaches the timeout value.
  -- The counter starts only when a valid transaction is completed.
  -- The timer is reset every time a valid tlast is received.
  timeout_counter_p : process(clk)
    variable timeout_counter_v : unsigned(AXIL_DATA_WIDTH_G-1 downto 0);
  begin
    if (rising_edge(clk)) then
      if (rstn  = '0') then
        timeout_counter_v := to_unsigned(0, timeout_counter_v'length);
        timeout_q <= '0';
      else
        if (clear_i = '1') then
          timeout_counter_v := to_unsigned(0, timeout_counter_v'length);
          timeout_q <= '0';
        else
          if (enable_i = '1') then
            if (m_axis_tready = '1' and m_axis_tvalid_q = '1') then
              -- A valid transaction is detected
              if (m_axis_tlast_q = '1') then
                -- Reset the counter if the tlast is high
                timeout_counter_v := to_unsigned(0, timeout_counter_v'length);
                -- And reset the timeout signal
                timeout_q <= '0';
              else
                -- Start the counter if it was not running or increment it
                timeout_counter_v := timeout_counter_v + to_unsigned(1, timeout_counter_v'length);
              end if;
            else
              -- No valid transaction: increment the counter if it is already running
              if (timeout_counter_v /= to_unsigned(0, timeout_counter_v'length)) then
                timeout_counter_v := timeout_counter_v + to_unsigned(1, timeout_counter_v'length);
              end if;
            end if;

            -- If the counter reaches the timeout value, a signal is generated
            if (timeout_counter_v = (unsigned(timeout_value_i) - to_unsigned(2, timeout_counter_v'length))) then
              timeout_q <= '1';
            end if;

            -- If the tlast is about to be sent, reset the timeout signal
            if (timeout_q = '1' and (m_axis_tready = '1' or m_axis_tvalid_q = '0')) then
              timeout_q <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Master interface registered outputs
  -- Accept new data when master interface ready is high or if master valid is low (meaning there is currently
  -- no valid data on the output interface)
  m_axis_p : process(clk)
  begin
    if (rising_edge(clk)) then
      if (rstn  = '0') then
        m_axis_tvalid_q   <= '0';
        m_axis_tdata_q    <= (others => '0');
        m_axis_tkeep_q    <= (others => '0');
        m_axis_tuser_q    <= (others => '0');
        m_axis_tlast_q    <= '0';
      else
        if (clear_i = '1') then
          -- Only the valid signal needs to be cleared
          m_axis_tvalid_q <= '0';
        elsif (m_axis_tready = '1' or m_axis_tvalid_q = '0') then
          -- Check if there is a tlast transaction to be sent
          if (timeout_q = '1') then
            m_axis_tvalid_q <= '1';
            m_axis_tdata_q  <= insert_tdata_i;
            m_axis_tkeep_q  <= insert_tkeep_i;
            m_axis_tuser_q  <= insert_tuser_i;
            m_axis_tlast_q  <= insert_tlast_i;
          elsif (s_axis_tvalid = '1') then
            -- Transmit valid data only to save power
            m_axis_tvalid_q <= '1';
            m_axis_tdata_q  <= s_axis_tdata;
            m_axis_tkeep_q  <= s_axis_tkeep;
            m_axis_tuser_q  <= s_axis_tuser;
            m_axis_tlast_q  <= s_axis_tlast;
          else
            m_axis_tvalid_q <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

end rtl;
