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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ps_host_if_reg_bank_pkg.all;

-------------------------
-- Zynq PS Host Interface
entity ps_host_if is
  generic (
    AXIL_ADDR_WIDTH_G  : positive := 32;
    AXIL_DATA_WIDTH_G  : positive := 32;
    AXIS_TDATA_WIDTH_G : positive := 64;
    AXIS_TUSER_WIDTH_G : positive := 1
  );
  port (
    -- Clock and Reset
    aclk               : in  std_logic;
    aresetn            : in  std_logic;

    -- Slave AXI4-Lite Interface for Registers Configuration
    s_axi_araddr       : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_arprot       : in  std_logic_vector(2 downto 0);
    s_axi_arready      : out std_logic;
    s_axi_arvalid      : in  std_logic;
    s_axi_awaddr       : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_awprot       : in  std_logic_vector(2 downto 0);
    s_axi_awready      : out std_logic;
    s_axi_awvalid      : in  std_logic;
    s_axi_bready       : in  std_logic;
    s_axi_bresp        : out std_logic_vector(1 downto 0);
    s_axi_bvalid       : out std_logic;
    s_axi_rdata        : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_rready       : in  std_logic;
    s_axi_rresp        : out std_logic_vector(1 downto 0);
    s_axi_rvalid       : out std_logic;
    s_axi_wdata        : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_wready       : out std_logic;
    s_axi_wstrb        : in  std_logic_vector(3 downto 0);
    s_axi_wvalid       : in  std_logic;

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
end entity ps_host_if;


architecture rtl of ps_host_if is

  ----------------------------
  -- Component Declarations --
  ----------------------------

  -------------------------
  -- AXI4-Stream Packetizer
  component axi4s_packetizer is
    generic (
      AXIL_DATA_WIDTH_G  : positive := 32;
      AXIS_TDATA_WIDTH_G : positive := 64;
      AXIS_TUSER_WIDTH_G : positive := 1
    );
    port(
      -- Clock, reset
      clk                : in  std_logic;
      rstn               : in  std_logic;

      -- Control registers
      enable_i           : in  std_logic;
      clear_i            : in  std_logic;
      packet_length_i    : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      pattern_enable_i   : in  std_logic;
      timeout_i          : in  std_logic;

      -- Input Event Stream
      s_axis_tready      : out std_logic;
      s_axis_tvalid      : in  std_logic;
      s_axis_tdata       : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
      s_axis_tkeep       : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
      s_axis_tuser       : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
      s_axis_tlast       : in  std_logic;

      -- Output Event Stream
      m_axis_tready      : in  std_logic;
      m_axis_tvalid      : out std_logic;
      m_axis_tdata       : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
      m_axis_tkeep       : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
      m_axis_tuser       : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
      m_axis_tlast       : out std_logic
    );
  end component axi4s_packetizer;

  -----------------------------
  -- AXI4-Stream Packet Timeout
  component axi4s_packet_timeout is
    generic (
      AXIL_DATA_WIDTH_G  : positive := 32;
      AXIS_TDATA_WIDTH_G : positive := 64;
      AXIS_TUSER_WIDTH_G : positive := 1
    );
    port (
      -- Clock, reset
      clk                : in  std_logic;
      rstn               : in  std_logic;

      -- Control Signals
      enable_i           : in  std_logic;
      clear_i            : in  std_logic;
      timeout_enable_i   : in  std_logic;
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
 end component axi4s_packet_timeout;

  ---------------------------
  -- PS HOST IF Register Bank
  component ps_host_if_reg_bank is
    generic (
      -- AXI generics - AXI4-Lite supports a data bus width of 32-bit or 64-bit
      AXIL_DATA_WIDTH_G             : integer := 32;
      AXIL_ADDR_WIDTH_G             : integer := 32
    );
    port (
      -- CONTROL Register
      cfg_control_enable_o          : out std_logic_vector(0 downto 0);
      cfg_control_global_reset_o    : out std_logic_vector(0 downto 0);
      cfg_control_clear_o           : out std_logic_vector(0 downto 0);
      -- CONFIG Register
      cfg_config_test_pattern_o     : out std_logic_vector(0 downto 0);
      cfg_config_timeout_enable_o   : out std_logic_vector(0 downto 0);
      -- PACKET_LENGTH Register
      cfg_packet_length_value_o     : out std_logic_vector(31 downto 0);
      -- TIMEOUT Register
      cfg_timeout_value_o           : out std_logic_vector(31 downto 0);
      -- TIMEOUT_EVENT_MSB Register
      cfg_timeout_event_msb_value_o : out std_logic_vector(31 downto 0);
      -- TIMEOUT_EVENT_LSB Register
      cfg_timeout_event_lsb_value_o : out std_logic_vector(31 downto 0);

      -- Slave AXI4-Lite Interface
      s_axi_aclk                    : in  std_logic;
      s_axi_aresetn                 : in  std_logic;
      s_axi_awaddr                  : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_awprot                  : in  std_logic_vector(2 downto 0);  -- NOT USED
      s_axi_awvalid                 : in  std_logic;
      s_axi_awready                 : out std_logic;
      s_axi_wdata                   : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);  -- NOT USED
      s_axi_wstrb                   : in  std_logic_vector((AXIL_DATA_WIDTH_G/8)-1 downto 0);  -- NOT USED
      s_axi_wvalid                  : in  std_logic;
      s_axi_wready                  : out std_logic;
      s_axi_bresp                   : out std_logic_vector(1 downto 0);
      s_axi_bvalid                  : out std_logic;
      s_axi_bready                  : in  std_logic;
      s_axi_araddr                  : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_arprot                  : in  std_logic_vector(2 downto 0);  -- NOT USED
      s_axi_arvalid                 : in  std_logic;
      s_axi_arready                 : out std_logic;
      s_axi_rdata                   : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      s_axi_rresp                   : out std_logic_vector(1 downto 0);
      s_axi_rvalid                  : out std_logic;
      s_axi_rready                  : in  std_logic
    );
  end component ps_host_if_reg_bank;

  -------------------------
  -- Signal Declarations --
  -------------------------

  -- Reset
  signal rstn_s                        : std_logic;

  -- tlast timeout
  signal tlast_timeout_s               : std_logic;

  -- AXI4-Stream DMA Packetizer Signals
  signal dma_packetizer_out_tready_s   : std_logic;
  signal dma_packetizer_out_tvalid_s   : std_logic;
  signal dma_packetizer_out_tdata_s    : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
  signal dma_packetizer_out_tkeep_s    : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
  signal dma_packetizer_out_tuser_s    : std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
  signal dma_packetizer_out_tlast_s    : std_logic;

  -- Register Bank Signals
  signal cfg_control_enable_s          : std_logic_vector(0 downto 0);
  signal cfg_control_global_reset_s    : std_logic_vector(0 downto 0);
  signal cfg_control_clear_s           : std_logic_vector(0 downto 0);
  signal cfg_config_test_pattern_s     : std_logic_vector(0 downto 0);
  signal cfg_config_timeout_enable_s   : std_logic_vector(0 downto 0);
  signal cfg_packet_length_value_s     : std_logic_vector(31 downto 0);
  signal cfg_timeout_value_s           : std_logic_vector(31 downto 0);
  signal cfg_timeout_event_msb_value_s : std_logic_vector(31 downto 0);
  signal cfg_timeout_event_lsb_value_s : std_logic_vector(31 downto 0);

  signal insert_tdata_s                : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  rstn_s <= aresetn and not cfg_control_global_reset_s(0);

  -- This needs to be modified in case AXIS_TDATA_WIDTH_G is different from AXIL_DATA_WIDTH_G*2
  assert (AXIS_TDATA_WIDTH_G = AXIL_DATA_WIDTH_G*2) report "ps_host_if currently only support AXIS_TDATA_WIDTH_G = AXIL_DATA_WIDTH_G*2" severity error;
  insert_tdata_s <= cfg_timeout_event_msb_value_s & cfg_timeout_event_lsb_value_s;

  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------

  ---------------
  -- Register Map
  ps_host_if_reg_bank_u : ps_host_if_reg_bank
  generic map (
    AXIL_DATA_WIDTH_G             => AXIL_DATA_WIDTH_G,
    AXIL_ADDR_WIDTH_G             => AXIL_ADDR_WIDTH_G
  )
  port map (
    -- CONTROL Register
    cfg_control_enable_o          => cfg_control_enable_s,
    cfg_control_global_reset_o    => cfg_control_global_reset_s,
    cfg_control_clear_o           => cfg_control_clear_s,
    -- CONFIG Register
    cfg_config_test_pattern_o     => cfg_config_test_pattern_s,
    cfg_config_timeout_enable_o   => cfg_config_timeout_enable_s,
    -- PACKET_LENGTH Register
    cfg_packet_length_value_o     => cfg_packet_length_value_s,
    -- TIMEOUT Register
    cfg_timeout_value_o           => cfg_timeout_value_s,
    -- TIMEOUT_EVENT_MSB Register
    cfg_timeout_event_msb_value_o => cfg_timeout_event_msb_value_s,
    -- TIMEOUT_EVENT_LSB Register
    cfg_timeout_event_lsb_value_o => cfg_timeout_event_lsb_value_s,

    -- Slave AXI4-Lite Interface
    s_axi_aclk                    => aclk,
    s_axi_aresetn                 => rstn_s,
    s_axi_awaddr                  => s_axi_awaddr,
    s_axi_awprot                  => s_axi_awprot,
    s_axi_awvalid                 => s_axi_awvalid,
    s_axi_awready                 => s_axi_awready,
    s_axi_wdata                   => s_axi_wdata,
    s_axi_wstrb                   => s_axi_wstrb,
    s_axi_wvalid                  => s_axi_wvalid,
    s_axi_wready                  => s_axi_wready,
    s_axi_bresp                   => s_axi_bresp,
    s_axi_bvalid                  => s_axi_bvalid,
    s_axi_bready                  => s_axi_bready,
    s_axi_araddr                  => s_axi_araddr,
    s_axi_arprot                  => s_axi_arprot,
    s_axi_arvalid                 => s_axi_arvalid,
    s_axi_arready                 => s_axi_arready,
    s_axi_rdata                   => s_axi_rdata,
    s_axi_rresp                   => s_axi_rresp,
    s_axi_rvalid                  => s_axi_rvalid,
    s_axi_rready                  => s_axi_rready
  );

   -------------------------
  -- AXI4-Stream Packetizer
  axi4s_packetizer_s : axi4s_packetizer
  generic map (
    AXIL_DATA_WIDTH_G  => AXIL_DATA_WIDTH_G,
    AXIS_TDATA_WIDTH_G => AXIS_TDATA_WIDTH_G,
    AXIS_TUSER_WIDTH_G => AXIS_TUSER_WIDTH_G
  )
  port map (
    -- Clock, reset
    clk                => aclk,
    rstn               => rstn_s,

    -- Control Signals
    enable_i           => cfg_control_enable_s(0),
    clear_i            => cfg_control_clear_s(0),
    packet_length_i    => cfg_packet_length_value_s,
    pattern_enable_i   => cfg_config_test_pattern_s(0),
    timeout_i          => tlast_timeout_s,

    -- Input Event Stream
    s_axis_tready      => s_axis_tready,
    s_axis_tvalid      => s_axis_tvalid,
    s_axis_tdata       => s_axis_tdata,
    s_axis_tkeep       => s_axis_tkeep,
    s_axis_tuser       => s_axis_tuser,
    s_axis_tlast       => s_axis_tlast,

    -- Output Event Stream
    m_axis_tready      => dma_packetizer_out_tready_s,
    m_axis_tvalid      => dma_packetizer_out_tvalid_s,
    m_axis_tdata       => dma_packetizer_out_tdata_s,
    m_axis_tkeep       => dma_packetizer_out_tkeep_s,
    m_axis_tuser       => dma_packetizer_out_tuser_s,
    m_axis_tlast       => dma_packetizer_out_tlast_s
  );

  -----------------------------
  -- AXI4-Stream Packet Timeout
  axi4s_packet_timeout_u : axi4s_packet_timeout
  generic map (
    AXIL_DATA_WIDTH_G  => AXIL_DATA_WIDTH_G,
    AXIS_TDATA_WIDTH_G => AXIS_TDATA_WIDTH_G,
    AXIS_TUSER_WIDTH_G => AXIS_TUSER_WIDTH_G
  )
  port map (
    -- Clock, reset
    clk                => aclk,
    rstn               => rstn_s,

    -- Control Signals
    enable_i           => cfg_control_enable_s(0),
    clear_i            => cfg_control_clear_s(0),
    timeout_enable_i   => cfg_config_timeout_enable_s(0),
    timeout_value_i    => cfg_timeout_value_s,
    timeout_o          => tlast_timeout_s,

    -- Insert Data
    insert_tdata_i     => insert_tdata_s,
    insert_tkeep_i     => (others => '1'),
    insert_tuser_i     => (others => '0'),
    insert_tlast_i     => '1',

    -- Input Data Stream
    s_axis_tready      => dma_packetizer_out_tready_s,
    s_axis_tvalid      => dma_packetizer_out_tvalid_s,
    s_axis_tdata       => dma_packetizer_out_tdata_s,
    s_axis_tkeep       => dma_packetizer_out_tkeep_s,
    s_axis_tuser       => dma_packetizer_out_tuser_s,
    s_axis_tlast       => dma_packetizer_out_tlast_s,

    -- Output Data Stream
    m_axis_tready      => m_axis_tready,
    m_axis_tvalid      => m_axis_tvalid,
    m_axis_tdata       => m_axis_tdata,
    m_axis_tkeep       => m_axis_tkeep,
    m_axis_tuser       => m_axis_tuser,
    m_axis_tlast       => m_axis_tlast
  );

end architecture rtl;
