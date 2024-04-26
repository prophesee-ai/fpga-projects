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

-----------------------------
-- AXI4-Stream Packetizer
-- Delimit packets by inserting a tlast. The size of the packets is defined by
-- packet_length_i. If timeout_i is high, the data counter for the packets is reset.
-- Note that any incoming tlast will be ignored.
-- It is also possible to replace incoming data with a raw counter patten.
entity axi4s_packetizer is
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
    packet_length_i    : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    pattern_enable_i   : in  std_logic;
    timeout_i          : in  std_logic;

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
end axi4s_packetizer;

architecture rtl of axi4s_packetizer is

  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Master AXI4-Stream registered outputs
  signal m_axis_tvalid_q     : std_logic;
  signal m_axis_tdata_q      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal m_axis_tkeep_q      : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal m_axis_tuser_q      : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal m_axis_tlast_q      : std_logic;

  -- Master AXI4-Stream registers input multiplexer
  signal m_axis_tvalid_mux_s : std_logic;
  signal m_axis_tdata_mux_s  : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal m_axis_tkeep_mux_s  : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal m_axis_tuser_mux_s  : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal m_axis_tlast_mux_s  : std_logic;

  -- Slave AXI4-Stream ready internal signal and registered output
  signal s_axis_tready_s     : std_logic;
  signal s_axis_tready_q     : std_logic;

  -- Internal skid buffer
  signal buffer_valid_q      : std_logic;
  signal buffer_data_q       : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal buffer_keep_q       : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal buffer_user_q       : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal buffer_last_q       : std_logic;

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  -- Slave interface ready: high if master interface ready is high or if master valid is low (meaning there is currently
  -- no valid data on the output interface)
  s_axis_tready_s     <= m_axis_tready or not m_axis_tvalid_q;

  -- If the pattern counter is enabled, the ready is forced high to avoid sending back-pressure to the MIPI IP
--  s_axis_tready_s     <= '1' when (pattern_enable_i = '1') else (m_axis_tready or not m_axis_tvalid_q);

  -- Slave AXI4-Stream registered ready
  s_axis_tready       <= s_axis_tready_q;

  -- Master AXI4-Stream registers input: if there is valid data in the skid buffer, get it
  -- Otherwise get data from the input interface
  m_axis_tvalid_mux_s <= buffer_valid_q or s_axis_tvalid;
  m_axis_tdata_mux_s  <= buffer_data_q when (buffer_valid_q = '1') else s_axis_tdata;
  m_axis_tkeep_mux_s  <= buffer_keep_q when (buffer_valid_q = '1') else s_axis_tkeep;
  m_axis_tuser_mux_s  <= buffer_user_q when (buffer_valid_q = '1') else s_axis_tuser;
  m_axis_tlast_mux_s  <= buffer_last_q when (buffer_valid_q = '1') else s_axis_tlast;

  -- Master AXI4-Stream registered output interface assignment
  m_axis_tvalid       <= m_axis_tvalid_q;
  m_axis_tdata        <= m_axis_tdata_q;
  m_axis_tkeep        <= m_axis_tkeep_q;
  m_axis_tuser        <= m_axis_tuser_q;
  m_axis_tlast        <= m_axis_tlast_q;

  ---------------
  -- Processes --
  ---------------

  -- Slave interface ready register
  -- Because this signal is registered, we need a skid buffer. If this signal was only combinatorial we could get rid of
  -- the skid buffer but we could face timing closure problems.
  s_axis_tready_p : process(clk)
  begin
    if (rising_edge(clk)) then
      if (rstn  = '0') then
        s_axis_tready_q <= '0';
      else
        if (clear_i = '1') then
          s_axis_tready_q <= '0';
        else
          s_axis_tready_q <= s_axis_tready_s;
        end if;
      end if;
    end if;
  end process;

  -- Master interface registered outputs
  -- Accept new data when master interface ready is high or if master valid is low (meaning there is currently
  -- no valid data on the output interface): this is the slave interface ready signal
  packetizer_p : process(clk)
    -- Packet counter: a tlast must be inserted everytime the counter reaches the packet length
    variable packet_counter_v  : unsigned(AXIL_DATA_WIDTH_G-1 downto 0);
    -- Pattern counter: when pattern is enabled, incoming data is replaced by the counter
    variable pattern_counter_v : unsigned(AXIS_TDATA_WIDTH_G-1 downto 0);
  begin
    if (rising_edge(clk)) then
      if (rstn  = '0') then
        packet_counter_v  := to_unsigned(0, packet_counter_v'length);
        pattern_counter_v := to_unsigned(0, pattern_counter_v'length);

        m_axis_tvalid_q   <= '0';
        m_axis_tdata_q    <= (others => '0');
        m_axis_tkeep_q    <= (others => '0');
        m_axis_tuser_q    <= (others => '0');
        m_axis_tlast_q    <= '0';
      else
        -- When a timeout is generated by the tlast timer, the packet_counter_v is reset
        if (timeout_i = '1') then
          packet_counter_v  := to_unsigned(0, packet_counter_v'length);
        end if;

        if (clear_i = '1') then
          packet_counter_v  := to_unsigned(0, packet_counter_v'length);
          pattern_counter_v := to_unsigned(0, pattern_counter_v'length);

          -- Only the valid signal needs to be cleared
          m_axis_tvalid_q <= '0';
        elsif (s_axis_tready_s = '1') then
          if (m_axis_tvalid_mux_s = '1') then
            -- Increment the packet counter everytime there is valid data on the input interface
            packet_counter_v := packet_counter_v + to_unsigned(1, packet_counter_v'length);

            -- If the counter reaches the packet length a tlast should be generated and the counter is reset.
            -- The incoming tlast will be ignored
            if (packet_counter_v = unsigned(packet_length_i)) then
              packet_counter_v := to_unsigned(0, packet_counter_v'length);
              m_axis_tlast_q <= '1';
            else
              m_axis_tlast_q <= '0';
            end if;

            -- If pattern_enable_i is set, replace incoming data with a counter
            if (pattern_enable_i = '1') then
              m_axis_tdata_q <= std_logic_vector(pattern_counter_v);
              m_axis_tkeep_q <= (others => '1');
              m_axis_tuser_q <= (others => '0');

              -- Increment the counter and let it overflow
              pattern_counter_v := pattern_counter_v + to_unsigned(1, pattern_counter_v'length);
            else
              m_axis_tdata_q <= m_axis_tdata_mux_s;
              m_axis_tkeep_q <= m_axis_tkeep_mux_s;
              m_axis_tuser_q <= m_axis_tuser_mux_s;
            end if;

            -- tvalid is high
            m_axis_tvalid_q <= '1';
          else
            m_axis_tvalid_q <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Skid buffer
  -- Store valid data from the slave interface while the master interface is not ready
  -- Invalid data is not stored to save power
  skid_buffer_p : process(clk)
  begin
    if (rising_edge(clk)) then
      if (rstn  = '0') then
        buffer_valid_q  <= '0';
        buffer_data_q   <= (others => '0');
        buffer_keep_q   <= (others => '0');
        buffer_user_q   <= (others => '0');
        buffer_last_q   <= '0';
      else
        if (clear_i = '1') then
          -- Only the valid signal needs to be cleared
          buffer_valid_q <= '0';
        elsif (s_axis_tready_s = '0') then
          if (s_axis_tready_q = '1' and s_axis_tvalid = '1') then
            buffer_valid_q <= '1';
            buffer_data_q  <= s_axis_tdata;
            buffer_keep_q  <= s_axis_tkeep;
            buffer_user_q  <= s_axis_tuser;
            buffer_last_q  <= s_axis_tlast;
          end if;
        else
          buffer_valid_q <= '0';
        end if;
      end if;
    end if;
  end process;

end rtl;
