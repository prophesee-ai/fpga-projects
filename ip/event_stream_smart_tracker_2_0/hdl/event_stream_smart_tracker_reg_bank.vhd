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
use ieee.math_real.all;

library work;
use work.evt_stream_smart_tracker_reg_bank_pkg.all;

-------------------------------
-- EVT STREAM SMART TRACKER Register Bank
-------------------------------
entity evt_stream_smart_tracker_reg_bank is
  generic (
    -- VERSION Register
    VERSION_VERSION_MINOR_DEFAULT               : std_logic_vector(15 downto 0) := "0000000000000000";
    VERSION_VERSION_MAJOR_DEFAULT               : std_logic_vector(15 downto 0) := "0000000000000010";
    -- AXI generics - AXI4-Lite supports a data bus width of 32-bit or 64-bit
    AXIL_DATA_WIDTH_G                           : integer := 32;
    AXIL_ADDR_WIDTH_G                           : integer := 32
  );
  port (
    -- CONTROL Register
    cfg_control_enable_o                        : out std_logic_vector(0 downto 0);
    cfg_control_global_reset_o                  : out std_logic_vector(0 downto 0);
    cfg_control_clear_o                         : out std_logic_vector(0 downto 0);
    -- CONFIG Register
    cfg_config_bypass_o                         : out std_logic_vector(0 downto 0);
    -- STATUS Register
    stat_status_evt_drop_flag_i                 : in  std_logic_vector(0 downto 0);
    stat_status_evt_drop_flag_clear_o        : out  std_logic;
    stat_status_evt_th_drop_flag_i              : in  std_logic_vector(0 downto 0);
    stat_status_evt_th_drop_flag_clear_o     : out  std_logic;
    stat_status_gen_th_flag_i                   : in  std_logic_vector(0 downto 0);
    stat_status_gen_th_flag_clear_o          : out  std_logic;
    -- SMART_DROPPER_CONTROL Register
    cfg_smart_dropper_control_bypass_o          : out std_logic_vector(0 downto 0);
    cfg_smart_dropper_control_gen_other_evt_o   : out std_logic_vector(0 downto 0);
    -- SMART_DROPPER_TH_DROP_CNT Register
    stat_smart_dropper_th_drop_cnt_value_i      : in  std_logic_vector(31 downto 0);
    -- SMART_DROPPER_TL_DROP_CNT Register
    stat_smart_dropper_tl_drop_cnt_value_i      : in  std_logic_vector(31 downto 0);
    -- SMART_DROPPER_EVT_DROP_CNT Register
    stat_smart_dropper_evt_drop_cnt_value_i     : in  std_logic_vector(31 downto 0);
    -- TH_RECOVERY_CONTROL Register
    cfg_th_recovery_control_bypass_o            : out std_logic_vector(0 downto 0);
    cfg_th_recovery_control_gen_missing_th_o    : out std_logic_vector(0 downto 0);
    cfg_th_recovery_control_enable_drop_evt_o   : out std_logic_vector(0 downto 0);
    cfg_th_recovery_control_gen_other_evt_o     : out std_logic_vector(0 downto 0);
    -- TS_CHECKER_CONTROL Register
    cfg_ts_checker_control_bypass_o             : out std_logic_vector(0 downto 0);
    cfg_ts_checker_control_enable_drop_evt_o    : out std_logic_vector(0 downto 0);
    cfg_ts_checker_control_gen_other_evt_o      : out std_logic_vector(0 downto 0);
    cfg_ts_checker_control_gen_tlast_on_other_o : out std_logic_vector(0 downto 0);
    cfg_ts_checker_control_threshold_o          : out std_logic_vector(27 downto 0);
    -- TS_CHECKER_TH_DETECT_CNT Register
    stat_ts_checker_th_detect_cnt_value_i       : in  std_logic_vector(15 downto 0);
    -- TS_CHECKER_TH_CORRUPT_CNT Register
    stat_ts_checker_th_corrupt_cnt_value_i      : in  std_logic_vector(15 downto 0);
    -- TS_CHECKER_TH_ERROR_CNT Register
    stat_ts_checker_th_error_cnt_value_i        : in  std_logic_vector(15 downto 0);

    -- Slave AXI4-Lite Interface
    s_axi_aclk                                  : in  std_logic;
    s_axi_aresetn                               : in  std_logic;
    s_axi_awaddr                                : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_awprot                                : in  std_logic_vector(2 downto 0);  -- NOT USED
    s_axi_awvalid                               : in  std_logic;
    s_axi_awready                               : out std_logic;
    s_axi_wdata                                 : in  std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);  -- NOT USED
    s_axi_wstrb                                 : in  std_logic_vector((AXIL_DATA_WIDTH_G/8)-1 downto 0);  -- NOT USED
    s_axi_wvalid                                : in  std_logic;
    s_axi_wready                                : out std_logic;
    s_axi_bresp                                 : out std_logic_vector(1 downto 0);
    s_axi_bvalid                                : out std_logic;
    s_axi_bready                                : in  std_logic;
    s_axi_araddr                                : in  std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
    s_axi_arprot                                : in  std_logic_vector(2 downto 0);  -- NOT USED
    s_axi_arvalid                               : in  std_logic;
    s_axi_arready                               : out std_logic;
    s_axi_rdata                                 : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
    s_axi_rresp                                 : out std_logic_vector(1 downto 0);
    s_axi_rvalid                                : out std_logic;
    s_axi_rready                                : in  std_logic
  );
end evt_stream_smart_tracker_reg_bank;

architecture arch_imp of evt_stream_smart_tracker_reg_bank is

  -- Constant declarations
  constant REGISTER_NUMBER_C                         : integer := 13;
  constant OPT_MEM_ADDR_BITS_C                       : integer := integer(ceil(log2(real(REGISTER_NUMBER_C))));
  constant ADDR_LSB_C                                : integer := (AXIL_DATA_WIDTH_G/32) + 1;
  constant ADDR_MSB_C                                : integer := ADDR_LSB_C + OPT_MEM_ADDR_BITS_C - 1;

  -- AXI4LITE signals
  signal axi_awaddr                                  : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal axi_awready                                 : std_logic;
  signal axi_wready                                  : std_logic;
  signal axi_bresp                                   : std_logic_vector(1 downto 0);
  signal axi_bvalid                                  : std_logic;
  signal axi_araddr                                  : std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
  signal axi_arready                                 : std_logic;
  signal axi_rdata                                   : std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
  signal axi_rresp                                   : std_logic_vector(1 downto 0);
  signal axi_rvalid                                  : std_logic;

  -- Common signals
  signal awaddr_valid                                : std_logic;

  -- Signals for user logic register space
  -- CONTROL Register
  signal cfg_control_enable_q                        : std_logic_vector(0 downto 0);
  signal cfg_control_global_reset_q                  : std_logic_vector(0 downto 0);
  signal cfg_control_clear_q                         : std_logic_vector(0 downto 0);

  -- CONFIG Register
  signal cfg_config_bypass_q                         : std_logic_vector(0 downto 0);

  -- STATUS Register
  signal stat_status_evt_drop_flag_q                 : std_logic_vector(0 downto 0);
  signal stat_status_evt_drop_flag_clear_q        : std_logic;
  signal stat_status_evt_th_drop_flag_q              : std_logic_vector(0 downto 0);
  signal stat_status_evt_th_drop_flag_clear_q     : std_logic;
  signal stat_status_gen_th_flag_q                   : std_logic_vector(0 downto 0);
  signal stat_status_gen_th_flag_clear_q          : std_logic;

  -- VERSION Register
  signal cfg_version_version_minor_q                 : std_logic_vector(15 downto 0);
  signal cfg_version_version_major_q                 : std_logic_vector(15 downto 0);

  -- SMART_DROPPER_CONTROL Register
  signal cfg_smart_dropper_control_bypass_q          : std_logic_vector(0 downto 0);
  signal cfg_smart_dropper_control_gen_other_evt_q   : std_logic_vector(0 downto 0);

  -- SMART_DROPPER_TH_DROP_CNT Register
  signal stat_smart_dropper_th_drop_cnt_value_q      : std_logic_vector(31 downto 0);

  -- SMART_DROPPER_TL_DROP_CNT Register
  signal stat_smart_dropper_tl_drop_cnt_value_q      : std_logic_vector(31 downto 0);

  -- SMART_DROPPER_EVT_DROP_CNT Register
  signal stat_smart_dropper_evt_drop_cnt_value_q     : std_logic_vector(31 downto 0);

  -- TH_RECOVERY_CONTROL Register
  signal cfg_th_recovery_control_bypass_q            : std_logic_vector(0 downto 0);
  signal cfg_th_recovery_control_gen_missing_th_q    : std_logic_vector(0 downto 0);
  signal cfg_th_recovery_control_enable_drop_evt_q   : std_logic_vector(0 downto 0);
  signal cfg_th_recovery_control_gen_other_evt_q     : std_logic_vector(0 downto 0);

  -- TS_CHECKER_CONTROL Register
  signal cfg_ts_checker_control_bypass_q             : std_logic_vector(0 downto 0);
  signal cfg_ts_checker_control_enable_drop_evt_q    : std_logic_vector(0 downto 0);
  signal cfg_ts_checker_control_gen_other_evt_q      : std_logic_vector(0 downto 0);
  signal cfg_ts_checker_control_gen_tlast_on_other_q : std_logic_vector(0 downto 0);
  signal cfg_ts_checker_control_threshold_q          : std_logic_vector(27 downto 0);

  -- TS_CHECKER_TH_DETECT_CNT Register
  signal stat_ts_checker_th_detect_cnt_value_q       : std_logic_vector(15 downto 0);

  -- TS_CHECKER_TH_CORRUPT_CNT Register
  signal stat_ts_checker_th_corrupt_cnt_value_q      : std_logic_vector(15 downto 0);

  -- TS_CHECKER_TH_ERROR_CNT Register
  signal stat_ts_checker_th_error_cnt_value_q        : std_logic_vector(15 downto 0);

begin

  -- AXI4-Lite output signals assignements
  s_axi_awready                               <= axi_awready;
  s_axi_wready                                <= axi_wready;  -- axi_wready is identical to axi_awready, we could remove it
  s_axi_bresp                                 <= axi_bresp;
  s_axi_bvalid                                <= axi_bvalid;
  s_axi_arready                               <= axi_arready;
  s_axi_rdata                                 <= axi_rdata;
  s_axi_rresp                                 <= axi_rresp;
  s_axi_rvalid                                <= axi_rvalid;

  -- Registers output signals assignements
  cfg_control_enable_o                        <= cfg_control_enable_q;
  cfg_control_global_reset_o                  <= cfg_control_global_reset_q;
  cfg_control_clear_o                         <= cfg_control_clear_q;
  cfg_config_bypass_o                         <= cfg_config_bypass_q;
  stat_status_evt_drop_flag_clear_o           <= stat_status_evt_drop_flag_clear_q;
  stat_status_evt_th_drop_flag_clear_o        <= stat_status_evt_th_drop_flag_clear_q;
  stat_status_gen_th_flag_clear_o             <= stat_status_gen_th_flag_clear_q;
  cfg_smart_dropper_control_bypass_o          <= cfg_smart_dropper_control_bypass_q;
  cfg_smart_dropper_control_gen_other_evt_o   <= cfg_smart_dropper_control_gen_other_evt_q;
  cfg_th_recovery_control_bypass_o            <= cfg_th_recovery_control_bypass_q;
  cfg_th_recovery_control_gen_missing_th_o    <= cfg_th_recovery_control_gen_missing_th_q;
  cfg_th_recovery_control_enable_drop_evt_o   <= cfg_th_recovery_control_enable_drop_evt_q;
  cfg_th_recovery_control_gen_other_evt_o     <= cfg_th_recovery_control_gen_other_evt_q;
  cfg_ts_checker_control_bypass_o             <= cfg_ts_checker_control_bypass_q;
  cfg_ts_checker_control_enable_drop_evt_o    <= cfg_ts_checker_control_enable_drop_evt_q;
  cfg_ts_checker_control_gen_other_evt_o      <= cfg_ts_checker_control_gen_other_evt_q;
  cfg_ts_checker_control_gen_tlast_on_other_o <= cfg_ts_checker_control_gen_tlast_on_other_q;
  cfg_ts_checker_control_threshold_o          <= cfg_ts_checker_control_threshold_q;

  ---------------------------
  -- Write address channel --
  ---------------------------

  -- axi_awready: Write address ready
  -- This signal indicates that the slave is ready to accept an address and associated control signals.
  -- It is asserted for one clock cycle when both s_axi_awvalid and s_axi_wvalid are asserted.
  -- It is de-asserted when reset is low.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      -- The reset signal can be asserted asynchronously, but deassertion must be synchronous with a rising edge of s_axi_aclk
      if s_axi_aresetn = '0' then
        axi_awready <= '0';
      else
        if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          -- Slave is ready to accept write address when there is a valid write address and write data
          -- on the write address and data bus. This design expects no outstanding transactions.
          axi_awready <= '1';
        else
          axi_awready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- axi_awaddr: Write address
  -- The write address gives the address of the first transfer in a write transaction (no burst in AXI4-LITE).
  -- This process is used to latch the address when both s_axi_awvalid and s_axi_wvalid are valid.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_awaddr <= (others => '0');
      else
        if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          axi_awaddr <= s_axi_awaddr;
        end if;
      end if;
    end if;
  end process;

  ------------------------
  -- Write data channel --
  ------------------------

  -- axi_wready: Write ready
  -- This signal indicates that the slave can accept the write data.
  -- It is asserted for one s_axi_aclk clock cycle when both s_axi_awvalid and s_axi_wvalid are asserted.
  -- It is de-asserted when reset is low.
  -- Slave is ready to accept write data when there is a valid write address and write data
  -- on the write address and data bus. This design expects no outstanding transactions.
  -- Note: aw_en = '1' has been replaced by (s_axi_bvalid = '0' or s_axi_bready = '1'), see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- write ready
        axi_wready <= '0';
      else
        if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and (axi_bvalid = '0' or s_axi_bready = '1')) then
          axi_wready <= '1';
        else
          axi_wready <= '0';
        end if;
      end if;
    end if;
  end process;

  -- Memory mapped register select and write logic
  -- The write data is accepted and written to memory mapped registers when
  -- axi_awready, s_axi_awvalid, axi_wready and s_axi_wvalid are asserted.
  -- Write strobes are used to select byte enables of slave registers while writing.
  -- These registers are cleared when reset (active low) is applied.
  -- Slave register write enable is asserted when valid address and data are available
  -- and the slave is ready to accept the write address and write data.
  -- Note: s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' have been removed, see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- Clear registers (values by default)
        cfg_control_enable_q                        <= CONTROL_ENABLE_DEFAULT;
        cfg_control_global_reset_q                  <= CONTROL_GLOBAL_RESET_DEFAULT;
        cfg_control_clear_q                         <= CONTROL_CLEAR_DEFAULT;
        cfg_config_bypass_q                         <= CONFIG_BYPASS_DEFAULT;
        stat_status_evt_drop_flag_q                 <= STATUS_EVT_DROP_FLAG_DEFAULT;
        stat_status_evt_th_drop_flag_q              <= STATUS_EVT_TH_DROP_FLAG_DEFAULT;
        stat_status_gen_th_flag_q                   <= STATUS_GEN_TH_FLAG_DEFAULT;
        cfg_version_version_minor_q                 <= VERSION_VERSION_MINOR_DEFAULT;
        cfg_version_version_major_q                 <= VERSION_VERSION_MAJOR_DEFAULT;
        cfg_smart_dropper_control_bypass_q          <= SMART_DROPPER_CONTROL_BYPASS_DEFAULT;
        cfg_smart_dropper_control_gen_other_evt_q   <= SMART_DROPPER_CONTROL_GEN_OTHER_EVT_DEFAULT;
        stat_smart_dropper_th_drop_cnt_value_q      <= SMART_DROPPER_TH_DROP_CNT_VALUE_DEFAULT;
        stat_smart_dropper_tl_drop_cnt_value_q      <= SMART_DROPPER_TL_DROP_CNT_VALUE_DEFAULT;
        stat_smart_dropper_evt_drop_cnt_value_q     <= SMART_DROPPER_EVT_DROP_CNT_VALUE_DEFAULT;
        cfg_th_recovery_control_bypass_q            <= TH_RECOVERY_CONTROL_BYPASS_DEFAULT;
        cfg_th_recovery_control_gen_missing_th_q    <= TH_RECOVERY_CONTROL_GEN_MISSING_TH_DEFAULT;
        cfg_th_recovery_control_enable_drop_evt_q   <= TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_DEFAULT;
        cfg_th_recovery_control_gen_other_evt_q     <= TH_RECOVERY_CONTROL_GEN_OTHER_EVT_DEFAULT;
        cfg_ts_checker_control_bypass_q             <= TS_CHECKER_CONTROL_BYPASS_DEFAULT;
        cfg_ts_checker_control_enable_drop_evt_q    <= TS_CHECKER_CONTROL_ENABLE_DROP_EVT_DEFAULT;
        cfg_ts_checker_control_gen_other_evt_q      <= TS_CHECKER_CONTROL_GEN_OTHER_EVT_DEFAULT;
        cfg_ts_checker_control_gen_tlast_on_other_q <= TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_DEFAULT;
        cfg_ts_checker_control_threshold_q          <= TS_CHECKER_CONTROL_THRESHOLD_DEFAULT;
        stat_ts_checker_th_detect_cnt_value_q       <= TS_CHECKER_TH_DETECT_CNT_VALUE_DEFAULT;
        stat_ts_checker_th_corrupt_cnt_value_q      <= TS_CHECKER_TH_CORRUPT_CNT_VALUE_DEFAULT;
        stat_ts_checker_th_error_cnt_value_q        <= TS_CHECKER_TH_ERROR_CNT_VALUE_DEFAULT;
      else
        -- Trigger Register (reset to default value every clock cycle)


        -- Register the inputs into the local signals
        stat_status_evt_drop_flag_q                 <= stat_status_evt_drop_flag_i;
        stat_status_evt_th_drop_flag_q              <= stat_status_evt_th_drop_flag_i;
        stat_status_gen_th_flag_q                   <= stat_status_gen_th_flag_i;
        stat_smart_dropper_th_drop_cnt_value_q      <= stat_smart_dropper_th_drop_cnt_value_i;
        stat_smart_dropper_tl_drop_cnt_value_q      <= stat_smart_dropper_tl_drop_cnt_value_i;
        stat_smart_dropper_evt_drop_cnt_value_q     <= stat_smart_dropper_evt_drop_cnt_value_i;
        stat_ts_checker_th_detect_cnt_value_q       <= stat_ts_checker_th_detect_cnt_value_i;
        stat_ts_checker_th_corrupt_cnt_value_q      <= stat_ts_checker_th_corrupt_cnt_value_i;
        stat_ts_checker_th_error_cnt_value_q        <= stat_ts_checker_th_error_cnt_value_i;
        if axi_awready = '1' then
          case axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) is
            when CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              cfg_control_enable_q                        <= s_axi_wdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB);
              cfg_control_global_reset_q                  <= s_axi_wdata(CONTROL_GLOBAL_RESET_MSB downto CONTROL_GLOBAL_RESET_LSB);
              cfg_control_clear_q                         <= s_axi_wdata(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB);
            when CONFIG_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              cfg_config_bypass_q                         <= s_axi_wdata(CONFIG_BYPASS_MSB downto CONFIG_BYPASS_LSB);
            when SMART_DROPPER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              cfg_smart_dropper_control_bypass_q          <= s_axi_wdata(SMART_DROPPER_CONTROL_BYPASS_MSB downto SMART_DROPPER_CONTROL_BYPASS_LSB);
              cfg_smart_dropper_control_gen_other_evt_q   <= s_axi_wdata(SMART_DROPPER_CONTROL_GEN_OTHER_EVT_MSB downto SMART_DROPPER_CONTROL_GEN_OTHER_EVT_LSB);
            when TH_RECOVERY_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              cfg_th_recovery_control_bypass_q            <= s_axi_wdata(TH_RECOVERY_CONTROL_BYPASS_MSB downto TH_RECOVERY_CONTROL_BYPASS_LSB);
              cfg_th_recovery_control_gen_missing_th_q    <= s_axi_wdata(TH_RECOVERY_CONTROL_GEN_MISSING_TH_MSB downto TH_RECOVERY_CONTROL_GEN_MISSING_TH_LSB);
              cfg_th_recovery_control_enable_drop_evt_q   <= s_axi_wdata(TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_MSB downto TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_LSB);
              cfg_th_recovery_control_gen_other_evt_q     <= s_axi_wdata(TH_RECOVERY_CONTROL_GEN_OTHER_EVT_MSB downto TH_RECOVERY_CONTROL_GEN_OTHER_EVT_LSB);
            when TS_CHECKER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              cfg_ts_checker_control_bypass_q             <= s_axi_wdata(TS_CHECKER_CONTROL_BYPASS_MSB downto TS_CHECKER_CONTROL_BYPASS_LSB);
              cfg_ts_checker_control_enable_drop_evt_q    <= s_axi_wdata(TS_CHECKER_CONTROL_ENABLE_DROP_EVT_MSB downto TS_CHECKER_CONTROL_ENABLE_DROP_EVT_LSB);
              cfg_ts_checker_control_gen_other_evt_q      <= s_axi_wdata(TS_CHECKER_CONTROL_GEN_OTHER_EVT_MSB downto TS_CHECKER_CONTROL_GEN_OTHER_EVT_LSB);
              cfg_ts_checker_control_gen_tlast_on_other_q <= s_axi_wdata(TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_MSB downto TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_LSB);
              cfg_ts_checker_control_threshold_q          <= s_axi_wdata(TS_CHECKER_CONTROL_THRESHOLD_MSB downto TS_CHECKER_CONTROL_THRESHOLD_LSB);
            when others =>
              -- Unknown address
              cfg_control_enable_q                        <= cfg_control_enable_q;
              cfg_control_global_reset_q                  <= cfg_control_global_reset_q;
              cfg_control_clear_q                         <= cfg_control_clear_q;
              cfg_config_bypass_q                         <= cfg_config_bypass_q;
              cfg_smart_dropper_control_bypass_q          <= cfg_smart_dropper_control_bypass_q;
              cfg_smart_dropper_control_gen_other_evt_q   <= cfg_smart_dropper_control_gen_other_evt_q;
              cfg_th_recovery_control_bypass_q            <= cfg_th_recovery_control_bypass_q;
              cfg_th_recovery_control_gen_missing_th_q    <= cfg_th_recovery_control_gen_missing_th_q;
              cfg_th_recovery_control_enable_drop_evt_q   <= cfg_th_recovery_control_enable_drop_evt_q;
              cfg_th_recovery_control_gen_other_evt_q     <= cfg_th_recovery_control_gen_other_evt_q;
              cfg_ts_checker_control_bypass_q             <= cfg_ts_checker_control_bypass_q;
              cfg_ts_checker_control_enable_drop_evt_q    <= cfg_ts_checker_control_enable_drop_evt_q;
              cfg_ts_checker_control_gen_other_evt_q      <= cfg_ts_checker_control_gen_other_evt_q;
              cfg_ts_checker_control_gen_tlast_on_other_q <= cfg_ts_checker_control_gen_tlast_on_other_q;
              cfg_ts_checker_control_threshold_q          <= cfg_ts_checker_control_threshold_q;
          end case;
        end if;
      end if;
    end if;
  end process;

  -- Address valid decoding for axi_bresp signal below
  awaddr_valid <= '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = CONFIG_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = SMART_DROPPER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = SMART_DROPPER_EVT_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = SMART_DROPPER_TH_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = SMART_DROPPER_TL_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = STATUS_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = TH_RECOVERY_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = TS_CHECKER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = TS_CHECKER_TH_CORRUPT_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = TS_CHECKER_TH_DETECT_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = TS_CHECKER_TH_ERROR_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '1' when axi_awaddr(ADDR_MSB_C downto ADDR_LSB_C) = VERSION_ADDR(ADDR_MSB_C downto ADDR_LSB_C) else
                  '0';

  ----------------------------
  -- Write response channel --
  ----------------------------

  -- axi_bvalid & axi_bresp: Write response
  -- The write response and response valid signals are asserted by the slave when
  -- axi_awready, s_axi_awvalid, axi_wready and s_axi_wvalid are asserted. This marks the acceptance of
  -- address and indicates the status of write transaction.
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_bvalid  <= '0';
        axi_bresp   <= "00";
      else
        if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0') then
          -- axi_bvalid: Write response valid
          -- This signal indicates that the channel is signaling a valid write response.
          axi_bvalid <= '1';
          -- axi_bresp: Write response
          -- This signal indicates the status of the write transaction.
          if (awaddr_valid = '1') then
            axi_bresp  <= "00";
          else
            axi_bresp  <= "10";  -- SLVERR
          end if;
        -- Check if bready is asserted while bvalid is high (there is a possibility that bready is always asserted high)
        elsif (s_axi_bready = '1' and axi_bvalid = '1') then
          axi_bvalid <= '0';
        end if;
      end if;
    end if;
  end process;

  --------------------------
  -- Read address channel --
  --------------------------

  -- axi_arready: Read address ready
  -- This signal indicates that the slave is ready to accept an address and associated control signals.
  -- It is asserted for one s_axi_aclk clock cycle when s_axi_arvalid is asserted.
  -- It is de-asserted when reset (active low) is asserted.
  -- The read address is also latched when s_axi_arvalid is asserted.
  -- It is reset to zero on reset assertion.
  -- Note: (s_axi_rvalid = '0' or s_axi_rready = '1') has been added from the equation (see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html)
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        -- read ready
        axi_arready <= '0';
        axi_araddr  <= (others => '0');
      else
        if (axi_arready = '0' and s_axi_arvalid = '1' and (axi_rvalid = '0' or s_axi_rready = '1')) then
          -- Indicates that the slave has accepted the valid read address
          axi_arready <= '1';
          -- Read address latching
          axi_araddr  <= s_axi_araddr;
        else
          axi_arready <= '0';
        end if;
      end if;
    end if;
  end process;

  --------------------------
  -- Read address channel --
  --------------------------

  -- axi_rvalid: Read valid
  -- This signal indicates that the channel is signaling the required read data.
  -- It is asserted for one clock cycle when both s_axi_arvalid and axi_arready are asserted.
  -- The slave registers data are available on the axi_rdata bus at this instance. The assertion of
  -- axi_rvalid marks the validity of read data on the bus and axi_rresp indicates the status of the
  -- read transaction.
  -- axi_rvalid is deasserted on reset (active low).
  -- axi_rresp and axi_rdata are cleared to zero on reset (active low).
  -- Note: (not axi_rvalid) has been removed from the equation (see https://zipcpu.com/blog/2021/05/22/vhdlaxil.html)
  process (s_axi_aclk)
  begin
    if rising_edge(s_axi_aclk) then
      if s_axi_aresetn = '0' then
        axi_rvalid <= '0';
        axi_rresp  <= "00";
        -- read data
        axi_rdata  <= (others => '0');
        stat_status_evt_drop_flag_clear_q <= '0';
        stat_status_evt_th_drop_flag_clear_q <= '0';
        stat_status_gen_th_flag_clear_q <= '0';
      else
        -- Reset clear flags
        stat_status_evt_drop_flag_clear_q <= '0';
        stat_status_evt_th_drop_flag_clear_q <= '0';
        stat_status_gen_th_flag_clear_q <= '0';
        if (axi_arready = '1' and s_axi_arvalid = '1') then
          -- Valid read data is available at the read data bus
          axi_rvalid <= '1';
          -- By default the slave respond with an OKAY status, which will be overriden if the address is not recognized
          axi_rresp   <= "00";

          -- Fill the bits that are not used with zeros
          axi_rdata <= (others => '0');

          -- When there is a valid read address (s_axi_arvalid) with acceptance of read address by the
          -- slave (axi_arready), output the read data

          -- Read address mux
          case axi_araddr(ADDR_MSB_C downto ADDR_LSB_C) is
            when CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB) <= cfg_control_enable_q;
              axi_rdata(CONTROL_GLOBAL_RESET_MSB downto CONTROL_GLOBAL_RESET_LSB) <= cfg_control_global_reset_q;
              axi_rdata(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB) <= cfg_control_clear_q;
            when CONFIG_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(CONFIG_BYPASS_MSB downto CONFIG_BYPASS_LSB) <= cfg_config_bypass_q;
            when STATUS_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(STATUS_EVT_DROP_FLAG_MSB downto STATUS_EVT_DROP_FLAG_LSB) <= stat_status_evt_drop_flag_q;
              stat_status_evt_drop_flag_clear_q <= '1';
              axi_rdata(STATUS_EVT_TH_DROP_FLAG_MSB downto STATUS_EVT_TH_DROP_FLAG_LSB) <= stat_status_evt_th_drop_flag_q;
              stat_status_evt_th_drop_flag_clear_q <= '1';
              axi_rdata(STATUS_GEN_TH_FLAG_MSB downto STATUS_GEN_TH_FLAG_LSB) <= stat_status_gen_th_flag_q;
              stat_status_gen_th_flag_clear_q <= '1';
            when VERSION_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(VERSION_VERSION_MINOR_MSB downto VERSION_VERSION_MINOR_LSB) <= cfg_version_version_minor_q;
              axi_rdata(VERSION_VERSION_MAJOR_MSB downto VERSION_VERSION_MAJOR_LSB) <= cfg_version_version_major_q;
            when SMART_DROPPER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(SMART_DROPPER_CONTROL_BYPASS_MSB downto SMART_DROPPER_CONTROL_BYPASS_LSB) <= cfg_smart_dropper_control_bypass_q;
              axi_rdata(SMART_DROPPER_CONTROL_GEN_OTHER_EVT_MSB downto SMART_DROPPER_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_smart_dropper_control_gen_other_evt_q;
            when SMART_DROPPER_TH_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(SMART_DROPPER_TH_DROP_CNT_VALUE_MSB downto SMART_DROPPER_TH_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_th_drop_cnt_value_q;
            when SMART_DROPPER_TL_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(SMART_DROPPER_TL_DROP_CNT_VALUE_MSB downto SMART_DROPPER_TL_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_tl_drop_cnt_value_q;
            when SMART_DROPPER_EVT_DROP_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(SMART_DROPPER_EVT_DROP_CNT_VALUE_MSB downto SMART_DROPPER_EVT_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_evt_drop_cnt_value_q;
            when TH_RECOVERY_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(TH_RECOVERY_CONTROL_BYPASS_MSB downto TH_RECOVERY_CONTROL_BYPASS_LSB) <= cfg_th_recovery_control_bypass_q;
              axi_rdata(TH_RECOVERY_CONTROL_GEN_MISSING_TH_MSB downto TH_RECOVERY_CONTROL_GEN_MISSING_TH_LSB) <= cfg_th_recovery_control_gen_missing_th_q;
              axi_rdata(TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_MSB downto TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_LSB) <= cfg_th_recovery_control_enable_drop_evt_q;
              axi_rdata(TH_RECOVERY_CONTROL_GEN_OTHER_EVT_MSB downto TH_RECOVERY_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_th_recovery_control_gen_other_evt_q;
            when TS_CHECKER_CONTROL_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(TS_CHECKER_CONTROL_BYPASS_MSB downto TS_CHECKER_CONTROL_BYPASS_LSB) <= cfg_ts_checker_control_bypass_q;
              axi_rdata(TS_CHECKER_CONTROL_ENABLE_DROP_EVT_MSB downto TS_CHECKER_CONTROL_ENABLE_DROP_EVT_LSB) <= cfg_ts_checker_control_enable_drop_evt_q;
              axi_rdata(TS_CHECKER_CONTROL_GEN_OTHER_EVT_MSB downto TS_CHECKER_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_ts_checker_control_gen_other_evt_q;
              axi_rdata(TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_MSB downto TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_LSB) <= cfg_ts_checker_control_gen_tlast_on_other_q;
              axi_rdata(TS_CHECKER_CONTROL_THRESHOLD_MSB downto TS_CHECKER_CONTROL_THRESHOLD_LSB) <= cfg_ts_checker_control_threshold_q;
            when TS_CHECKER_TH_DETECT_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(TS_CHECKER_TH_DETECT_CNT_VALUE_MSB downto TS_CHECKER_TH_DETECT_CNT_VALUE_LSB) <= stat_ts_checker_th_detect_cnt_value_q;
            when TS_CHECKER_TH_CORRUPT_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(TS_CHECKER_TH_CORRUPT_CNT_VALUE_MSB downto TS_CHECKER_TH_CORRUPT_CNT_VALUE_LSB) <= stat_ts_checker_th_corrupt_cnt_value_q;
            when TS_CHECKER_TH_ERROR_CNT_ADDR(ADDR_MSB_C downto ADDR_LSB_C) =>
              axi_rdata(TS_CHECKER_TH_ERROR_CNT_VALUE_MSB downto TS_CHECKER_TH_ERROR_CNT_VALUE_LSB) <= stat_ts_checker_th_error_cnt_value_q;
            when others =>
              -- unknown address
              axi_rresp <= "10";  -- SLVERR
          end case;

        elsif (axi_rvalid = '1' and s_axi_rready = '1') then
          -- Read data is accepted by the master
          axi_rvalid <= '0';
        end if;
      end if;
    end if;
  end process;

end arch_imp;
