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

----------------------------
-- AXI4-Stream TKEEP Handler
entity axis_tkeep_handler is
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
end axis_tkeep_handler;

architecture rtl of axis_tkeep_handler is

  ----------------------------
  -- Component Declarations --
  ----------------------------

  ----------------------------
  -- AXI4-Stream TKEEP Handler
  component axis_tkeep_handler_core is
    generic (
      AXIS_TDATA_WIDTH_G : positive := 64;
      AXIS_TUSER_WIDTH_G : positive := 1
    );
    port (
      clk               : in  std_logic;
      rstn              : in  std_logic;

      -- Control Signals
      enable_i          : in  std_logic;
      bypass_i          : in  std_logic;
      buffer_clear_i    : in  std_logic;
      word_order_i      : in  std_logic;

      -- Input Data Stream
      in_ready_o        : out std_logic;
      in_valid_i        : in  std_logic;
      in_data_i         : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
      in_keep_i         : in  std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
      in_user_i         : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
      in_last_i         : in  std_logic;

      -- Output Data Stream
      out_ready_i       : in  std_logic;
      out_valid_o       : out std_logic;
      out_data_o        : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
      out_keep_o        : out std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);
      out_user_o        : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);
      out_last_o        : out std_logic
    );
  end component axis_tkeep_handler_core;

  ------------------------------------------
  -- AXI4-Stream TKEEP Handler Register Bank
  component axis_tkeep_handler_reg_bank is
    generic (
      -- AXI generics
      AXIL_DATA_WIDTH_G       : integer  := 32;
      AXIL_ADDR_WIDTH_G       : integer  := 4
    );
    port (
      -- CONTROL Register
      cfg_control_enable_o       : out std_logic_vector(0 downto 0);
      cfg_control_global_reset_o : out std_logic_vector(0 downto 0);
      cfg_control_clear_o        : out std_logic_vector(0 downto 0);
      -- CONFIG Register
      cfg_config_bypass_o        : out std_logic_vector(0 downto 0);
      cfg_config_word_order_o    : out std_logic_vector(0 downto 0);

      -- Slave AXI4-Lite Interface
      s_axi_aclk              : in  std_logic;
      s_axi_aresetn           : in  std_logic;
      s_axi_awaddr            : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_awprot            : in  std_logic_vector(2 downto 0);
      s_axi_awvalid           : in  std_logic;
      s_axi_awready           : out std_logic;
      s_axi_wdata             : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      s_axi_wstrb             : in  std_logic_vector((AXIL_DATA_WIDTH_G/8)-1 downto 0);
      s_axi_wvalid            : in  std_logic;
      s_axi_wready            : out std_logic;
      s_axi_bresp             : out std_logic_vector(1 downto 0);
      s_axi_bvalid            : out std_logic;
      s_axi_bready            : in  std_logic;
      s_axi_araddr            : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
      s_axi_arprot            : in  std_logic_vector(2 downto 0);
      s_axi_arvalid           : in  std_logic;
      s_axi_arready           : out std_logic;
      s_axi_rdata             : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
      s_axi_rresp             : out std_logic_vector(1 downto 0);
      s_axi_rvalid            : out std_logic;
      s_axi_rready            : in  std_logic
    );
  end component axis_tkeep_handler_reg_bank;


  ----------------------------------
  -- Internal Signal Declarations --
  ----------------------------------

  -- Reset
  signal rstn_s                        : std_logic;

  -- Register Bank Signals
  signal cfg_control_enable_s       : std_logic_vector(0 downto 0);
  signal cfg_control_global_reset_s : std_logic_vector(0 downto 0);
  signal cfg_control_clear_s        : std_logic_vector(0 downto 0);
  signal cfg_config_bypass_s        : std_logic_vector(0 downto 0);
  signal cfg_config_word_order_s    : std_logic_vector(0 downto 0);

begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------

  rstn_s <= aresetn and not cfg_control_global_reset_s(0);

  -----------------------------------------
  -- Component Instantiation and Mapping --
  -----------------------------------------

  axis_tkeep_handler_reg_bank_u : axis_tkeep_handler_reg_bank
  generic map (
    -- AXI generics
    AXIL_DATA_WIDTH_G          => AXIL_DATA_WIDTH_G,
    AXIL_ADDR_WIDTH_G          => AXIL_ADDR_WIDTH_G
  )
  port map(
    -- CONTROL Register
    cfg_control_enable_o       => cfg_control_enable_s,
    cfg_control_global_reset_o => cfg_control_global_reset_s,
    cfg_control_clear_o        => cfg_control_clear_s,
    -- CONFIG Register
    cfg_config_bypass_o        => cfg_config_bypass_s,
    cfg_config_word_order_o    => cfg_config_word_order_s,

    -- AXI LITE port in/out signals
    s_axi_aclk                 => aclk,
    s_axi_aresetn              => rstn_s,
    s_axi_awaddr               => s_axi_awaddr,
    s_axi_awprot               => s_axi_awprot,
    s_axi_awvalid              => s_axi_awvalid,
    s_axi_awready              => s_axi_awready,
    s_axi_wdata                => s_axi_wdata,
    s_axi_wstrb                => s_axi_wstrb,
    s_axi_wvalid               => s_axi_wvalid,
    s_axi_wready               => s_axi_wready,
    s_axi_bresp                => s_axi_bresp,
    s_axi_bvalid               => s_axi_bvalid,
    s_axi_bready               => s_axi_bready,
    s_axi_araddr               => s_axi_araddr,
    s_axi_arprot               => s_axi_arprot,
    s_axi_arvalid              => s_axi_arvalid,
    s_axi_arready              => s_axi_arready,
    s_axi_rdata                => s_axi_rdata,
    s_axi_rresp                => s_axi_rresp,
    s_axi_rvalid               => s_axi_rvalid,
    s_axi_rready               => s_axi_rready
  );

  axis_tkeep_handler_core_u : axis_tkeep_handler_core
  generic map (
    AXIS_TDATA_WIDTH_G => AXIS_TDATA_WIDTH_G
  )
  port map (
    clk               => aclk,
    rstn              => rstn_s,

    -- Control Signals
    enable_i          => cfg_control_enable_s(0),
    bypass_i          => cfg_config_bypass_s(0),
    buffer_clear_i    => cfg_control_clear_s(0),
    word_order_i      => cfg_config_word_order_s(0),

    -- Input Data Stream
    in_ready_o        => s_axis_tready,
    in_valid_i        => s_axis_tvalid,
    in_data_i         => s_axis_tdata,
    in_keep_i         => s_axis_tkeep,
    in_user_i         => s_axis_tuser,
    in_last_i         => s_axis_tlast,
    -- Output Data Stream
    out_ready_i       => m_axis_tready,
    out_valid_o       => m_axis_tvalid,
    out_data_o        => m_axis_tdata,
    out_keep_o        => m_axis_tkeep,
    out_user_o        => m_axis_tuser,
    out_last_o        => m_axis_tlast
  );

end rtl;
