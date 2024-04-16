----------------------------------------------------------------------------------
-- Copyright 2015-2023 Prophesee
--
-- Company:        Prophesee
-- Module Name:    evt_stream_smart_tracker_reg_bank
-- Description:    EVT STREAM SMART TRACKER Register Bank
-- Comment:        
--
-- Note:           File generated automatically by Prophesee's
--                 Register Map to AXI Lite tool.
--                 Please do not modify its contents.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.evt_stream_smart_tracker_reg_bank_pkg.all;

-------------------------------
-- EVT STREAM SMART TRACKER Register Bank
-------------------------------
entity evt_stream_smart_tracker_reg_bank is
  generic (
    -- VERSION Register
    VERSION_MINOR_DEFAULT                    : std_logic_vector(16-1 downto 0) := "0000000000000000";
    VERSION_MAJOR_DEFAULT                    : std_logic_vector(16-1 downto 0) := "0000000000000001";

    -- AXI generics
    C_S_AXI_DATA_WIDTH                       : integer  := 32;
    C_S_AXI_ADDR_WIDTH                       : integer  := 32
  );
  port (
    -- CONTROL Register
    cfg_control_enable_o                     : out  std_logic_vector(1-1 downto 0);
    cfg_control_bypass_o                     : out  std_logic_vector(1-1 downto 0);
    cfg_control_clear_o                      : out  std_logic_vector(1-1 downto 0);
    -- SMART_DROPPER_CONTROL Register
    cfg_smart_dropper_control_bypass_o       : out  std_logic_vector(1-1 downto 0);
    cfg_smart_dropper_control_gen_other_evt_o : out  std_logic_vector(1-1 downto 0);
    stat_smart_dropper_control_evt_drop_flag_i : in   std_logic_vector(1-1 downto 0);
    stat_smart_dropper_control_evt_drop_flag_clear_o : out  std_logic;
    -- SMART_DROPPER_TH_DROP_CNT Register
    stat_smart_dropper_th_drop_cnt_value_i   : in   std_logic_vector(32-1 downto 0);
    -- SMART_DROPPER_TL_DROP_CNT Register
    stat_smart_dropper_tl_drop_cnt_value_i   : in   std_logic_vector(32-1 downto 0);
    -- SMART_DROPPER_EVT_DROP_CNT Register
    stat_smart_dropper_evt_drop_cnt_value_i  : in   std_logic_vector(32-1 downto 0);
    -- TH_RECOVERY_CONTROL Register
    cfg_th_recovery_control_bypass_o         : out  std_logic_vector(1-1 downto 0);
    cfg_th_recovery_control_gen_missing_th_o : out  std_logic_vector(1-1 downto 0);
    cfg_th_recovery_control_enable_drop_evt_o : out  std_logic_vector(1-1 downto 0);
    cfg_th_recovery_control_gen_other_evt_o  : out  std_logic_vector(1-1 downto 0);
    stat_th_recovery_control_evt_drop_flag_i : in   std_logic_vector(1-1 downto 0);
    stat_th_recovery_control_evt_drop_flag_clear_o : out  std_logic;
    stat_th_recovery_control_gen_th_flag_i   : in   std_logic_vector(1-1 downto 0);
    stat_th_recovery_control_gen_th_flag_clear_o : out  std_logic;
    -- TS_CHECKER_CONTROL Register
    cfg_ts_checker_control_bypass_o          : out  std_logic_vector(1-1 downto 0);
    cfg_ts_checker_control_enable_drop_evt_o : out  std_logic_vector(1-1 downto 0);
    cfg_ts_checker_control_gen_other_evt_o   : out  std_logic_vector(1-1 downto 0);
    cfg_ts_checker_control_gen_tlast_on_other_o : out  std_logic_vector(1-1 downto 0);
    cfg_ts_checker_control_threshold_o       : out  std_logic_vector(28-1 downto 0);
    -- TS_CHECKER_TH_DETECT_CNT Register
    stat_ts_checker_th_detect_cnt_value_i    : in   std_logic_vector(16-1 downto 0);
    -- TS_CHECKER_TH_CORRUPT_CNT Register
    stat_ts_checker_th_corrupt_cnt_value_i   : in   std_logic_vector(16-1 downto 0);
    -- TS_CHECKER_TH_ERROR_CNT Register
    stat_ts_checker_th_error_cnt_value_i     : in   std_logic_vector(16-1 downto 0);

    -- AXI LITE port in/out signals
    s_axi_aclk                               : in   std_logic;
    a_axi_aresetn                            : in   std_logic;
    s_axi_awaddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_awprot                             : in   std_logic_vector(2 downto 0);
    s_axi_awvalid                            : in   std_logic;
    s_axi_awready                            : out  std_logic;
    s_axi_wdata                              : in   std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_wstrb                              : in   std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    s_axi_wvalid                             : in   std_logic;
    s_axi_wready                             : out  std_logic;
    s_axi_bresp                              : out  std_logic_vector(1 downto 0);
    s_axi_bvalid                             : out  std_logic;
    s_axi_bready                             : in   std_logic;
    s_axi_araddr                             : in   std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    s_axi_arprot                             : in   std_logic_vector(2 downto 0);
    s_axi_arvalid                            : in   std_logic;
    s_axi_arready                            : out  std_logic;
    s_axi_rdata                              : out  std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    s_axi_rresp                              : out  std_logic_vector(1 downto 0);
    s_axi_rvalid                             : out  std_logic;
    s_axi_rready                             : in   std_logic
  );
end evt_stream_smart_tracker_reg_bank;


architecture arch_imp of evt_stream_smart_tracker_reg_bank is

  -- AXI4LITE signals
  signal axi_awaddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_awready  : std_logic;
  signal axi_wready   : std_logic;
  signal axi_bresp    : std_logic_vector(1 downto 0);
  signal axi_bvalid   : std_logic;
  signal axi_araddr   : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
  signal axi_arready  : std_logic;
  signal axi_rdata    : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
  signal axi_rresp    : std_logic_vector(1 downto 0);
  signal axi_rvalid   : std_logic;

  -- Constant declarations
  constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
  constant REGISTER_NUMBER : integer := 11;
  constant OPT_MEM_ADDR_BITS : integer := integer(ceil(log2(real(REGISTER_NUMBER))));
  constant BUS_ADDR_ERROR_CODE : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0) := (1 downto 0 => '0', others => '1');

  -- common signals
  signal write_addr_error_q : std_logic;
  signal read_addr_error_q  : std_logic;
  
  signal slv_reg_rden       : std_logic;
  signal slv_reg_wren       : std_logic;
  signal byte_index         : integer;
  signal aw_en              : std_logic;

  ------------------------------------------------
  ---- Signals for user logic register space
  ------------------------------------------------

  -- VERSION Register
  signal cfg_version_minor_q                      : std_logic_vector(16-1 downto 0);
  signal cfg_version_major_q                      : std_logic_vector(16-1 downto 0);
  -- CONTROL Register
  signal cfg_control_enable_q                     : std_logic_vector(1-1 downto 0);
  signal cfg_control_bypass_q                     : std_logic_vector(1-1 downto 0);
  signal cfg_control_clear_q                      : std_logic_vector(1-1 downto 0);
  -- SMART_DROPPER_CONTROL Register
  signal cfg_smart_dropper_control_bypass_q       : std_logic_vector(1-1 downto 0);
  signal cfg_smart_dropper_control_gen_other_evt_q : std_logic_vector(1-1 downto 0);
  signal stat_smart_dropper_control_evt_drop_flag_q : std_logic_vector(1-1 downto 0);
  signal stat_smart_dropper_control_evt_drop_flag_clear_q : std_logic;
  -- SMART_DROPPER_TH_DROP_CNT Register
  signal stat_smart_dropper_th_drop_cnt_value_q   : std_logic_vector(32-1 downto 0);
  -- SMART_DROPPER_TL_DROP_CNT Register
  signal stat_smart_dropper_tl_drop_cnt_value_q   : std_logic_vector(32-1 downto 0);
  -- SMART_DROPPER_EVT_DROP_CNT Register
  signal stat_smart_dropper_evt_drop_cnt_value_q  : std_logic_vector(32-1 downto 0);
  -- TH_RECOVERY_CONTROL Register
  signal cfg_th_recovery_control_bypass_q         : std_logic_vector(1-1 downto 0);
  signal cfg_th_recovery_control_gen_missing_th_q : std_logic_vector(1-1 downto 0);
  signal cfg_th_recovery_control_enable_drop_evt_q : std_logic_vector(1-1 downto 0);
  signal cfg_th_recovery_control_gen_other_evt_q  : std_logic_vector(1-1 downto 0);
  signal stat_th_recovery_control_evt_drop_flag_q : std_logic_vector(1-1 downto 0);
  signal stat_th_recovery_control_evt_drop_flag_clear_q : std_logic;
  signal stat_th_recovery_control_gen_th_flag_q   : std_logic_vector(1-1 downto 0);
  signal stat_th_recovery_control_gen_th_flag_clear_q : std_logic;
  -- TS_CHECKER_CONTROL Register
  signal cfg_ts_checker_control_bypass_q          : std_logic_vector(1-1 downto 0);
  signal cfg_ts_checker_control_enable_drop_evt_q : std_logic_vector(1-1 downto 0);
  signal cfg_ts_checker_control_gen_other_evt_q   : std_logic_vector(1-1 downto 0);
  signal cfg_ts_checker_control_gen_tlast_on_other_q : std_logic_vector(1-1 downto 0);
  signal cfg_ts_checker_control_threshold_q       : std_logic_vector(28-1 downto 0);
  -- TS_CHECKER_TH_DETECT_CNT Register
  signal stat_ts_checker_th_detect_cnt_value_q    : std_logic_vector(16-1 downto 0);
  -- TS_CHECKER_TH_CORRUPT_CNT Register
  signal stat_ts_checker_th_corrupt_cnt_value_q   : std_logic_vector(16-1 downto 0);
  -- TS_CHECKER_TH_ERROR_CNT Register
  signal stat_ts_checker_th_error_cnt_value_q     : std_logic_vector(16-1 downto 0);


begin

  -------------------------------------
  -- Asynchronous Signal Assignments --
  -------------------------------------
  
  -- AXI4LITE Async signals assignements
  s_axi_awready    <= axi_awready;
  s_axi_wready     <= axi_wready;
  s_axi_bresp      <= axi_bresp;
  s_axi_bvalid     <= axi_bvalid;
  s_axi_arready    <= axi_arready;
  s_axi_rdata      <= axi_rdata;
  s_axi_rresp      <= axi_rresp;
  s_axi_rvalid     <= axi_rvalid;

  slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;
  slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;
  
  -- Assign register to output async
  cfg_control_enable_o                     <= cfg_control_enable_q;
  cfg_control_bypass_o                     <= cfg_control_bypass_q;
  cfg_control_clear_o                      <= cfg_control_clear_q;
  cfg_smart_dropper_control_bypass_o       <= cfg_smart_dropper_control_bypass_q;
  cfg_smart_dropper_control_gen_other_evt_o <= cfg_smart_dropper_control_gen_other_evt_q;
  stat_smart_dropper_control_evt_drop_flag_clear_o <= stat_smart_dropper_control_evt_drop_flag_clear_q;
  cfg_th_recovery_control_bypass_o         <= cfg_th_recovery_control_bypass_q;
  cfg_th_recovery_control_gen_missing_th_o <= cfg_th_recovery_control_gen_missing_th_q;
  cfg_th_recovery_control_enable_drop_evt_o <= cfg_th_recovery_control_enable_drop_evt_q;
  cfg_th_recovery_control_gen_other_evt_o  <= cfg_th_recovery_control_gen_other_evt_q;
  stat_th_recovery_control_evt_drop_flag_clear_o <= stat_th_recovery_control_evt_drop_flag_clear_q;
  stat_th_recovery_control_gen_th_flag_clear_o <= stat_th_recovery_control_gen_th_flag_clear_q;
  cfg_ts_checker_control_bypass_o          <= cfg_ts_checker_control_bypass_q;
  cfg_ts_checker_control_enable_drop_evt_o <= cfg_ts_checker_control_enable_drop_evt_q;
  cfg_ts_checker_control_gen_other_evt_o   <= cfg_ts_checker_control_gen_other_evt_q;
  cfg_ts_checker_control_gen_tlast_on_other_o <= cfg_ts_checker_control_gen_tlast_on_other_q;
  cfg_ts_checker_control_threshold_o       <= cfg_ts_checker_control_threshold_q;


  process (s_axi_aclk)
    variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
    begin
      if rising_edge(s_axi_aclk) then 
        if a_axi_aresetn = '0' then
          -- address write
          axi_awready <= '0';
          aw_en <= '1';
          axi_awaddr <= (others => '0');
          -- write ready
          axi_wready <= '0';
          -- write response
          axi_bvalid  <= '0';
          axi_bresp   <= "00";
          -- read ready
          axi_arready <= '0';
          axi_araddr  <= (others => '1');
          -- read response
          axi_rvalid <= '0';
          axi_rresp  <= "00";
          -- read data
          axi_rdata  <= (others => '0');
          -- clear registers (values by default)
          cfg_version_minor_q <= VERSION_MINOR_DEFAULT;
          cfg_version_major_q <= VERSION_MAJOR_DEFAULT;
          cfg_control_enable_q <= CONTROL_ENABLE_DEFAULT;
          cfg_control_bypass_q <= CONTROL_BYPASS_DEFAULT;
          cfg_control_clear_q <= CONTROL_CLEAR_DEFAULT;
          cfg_smart_dropper_control_bypass_q <= SMART_DROPPER_CONTROL_BYPASS_DEFAULT;
          cfg_smart_dropper_control_gen_other_evt_q <= SMART_DROPPER_CONTROL_GEN_OTHER_EVT_DEFAULT;
          stat_smart_dropper_control_evt_drop_flag_q <= SMART_DROPPER_CONTROL_EVT_DROP_FLAG_DEFAULT;
          stat_smart_dropper_control_evt_drop_flag_clear_q <= '0';
          stat_smart_dropper_th_drop_cnt_value_q <= SMART_DROPPER_TH_DROP_CNT_VALUE_DEFAULT;
          stat_smart_dropper_tl_drop_cnt_value_q <= SMART_DROPPER_TL_DROP_CNT_VALUE_DEFAULT;
          stat_smart_dropper_evt_drop_cnt_value_q <= SMART_DROPPER_EVT_DROP_CNT_VALUE_DEFAULT;
          cfg_th_recovery_control_bypass_q <= TH_RECOVERY_CONTROL_BYPASS_DEFAULT;
          cfg_th_recovery_control_gen_missing_th_q <= TH_RECOVERY_CONTROL_GEN_MISSING_TH_DEFAULT;
          cfg_th_recovery_control_enable_drop_evt_q <= TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_DEFAULT;
          cfg_th_recovery_control_gen_other_evt_q <= TH_RECOVERY_CONTROL_GEN_OTHER_EVT_DEFAULT;
          stat_th_recovery_control_evt_drop_flag_q <= TH_RECOVERY_CONTROL_EVT_DROP_FLAG_DEFAULT;
          stat_th_recovery_control_evt_drop_flag_clear_q <= '0';
          stat_th_recovery_control_gen_th_flag_q <= TH_RECOVERY_CONTROL_GEN_TH_FLAG_DEFAULT;
          stat_th_recovery_control_gen_th_flag_clear_q <= '0';
          cfg_ts_checker_control_bypass_q <= TS_CHECKER_CONTROL_BYPASS_DEFAULT;
          cfg_ts_checker_control_enable_drop_evt_q <= TS_CHECKER_CONTROL_ENABLE_DROP_EVT_DEFAULT;
          cfg_ts_checker_control_gen_other_evt_q <= TS_CHECKER_CONTROL_GEN_OTHER_EVT_DEFAULT;
          cfg_ts_checker_control_gen_tlast_on_other_q <= TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_DEFAULT;
          cfg_ts_checker_control_threshold_q <= TS_CHECKER_CONTROL_THRESHOLD_DEFAULT;
          stat_ts_checker_th_detect_cnt_value_q <= TS_CHECKER_TH_DETECT_CNT_VALUE_DEFAULT;
          stat_ts_checker_th_corrupt_cnt_value_q <= TS_CHECKER_TH_CORRUPT_CNT_VALUE_DEFAULT;
          stat_ts_checker_th_error_cnt_value_q <= TS_CHECKER_TH_ERROR_CNT_VALUE_DEFAULT;

          -- error signals
          read_addr_error_q     <= '0';
          write_addr_error_q     <= '0';
          
        else
          -- default value for signals
          axi_bresp   <= "00"; --need to work more on the responses
          axi_rresp   <= "00";
        
          -- Trigger Register (reset to default value every clock cycle)
          cfg_control_clear_q <= CONTROL_CLEAR_DEFAULT;

        
          -- Register the inputs into the local signals
          stat_smart_dropper_control_evt_drop_flag_q <= stat_smart_dropper_control_evt_drop_flag_i;
          stat_smart_dropper_th_drop_cnt_value_q <= stat_smart_dropper_th_drop_cnt_value_i;
          stat_smart_dropper_tl_drop_cnt_value_q <= stat_smart_dropper_tl_drop_cnt_value_i;
          stat_smart_dropper_evt_drop_cnt_value_q <= stat_smart_dropper_evt_drop_cnt_value_i;
          stat_th_recovery_control_evt_drop_flag_q <= stat_th_recovery_control_evt_drop_flag_i;
          stat_th_recovery_control_gen_th_flag_q <= stat_th_recovery_control_gen_th_flag_i;
          stat_ts_checker_th_detect_cnt_value_q <= stat_ts_checker_th_detect_cnt_value_i;
          stat_ts_checker_th_corrupt_cnt_value_q <= stat_ts_checker_th_corrupt_cnt_value_i;
          stat_ts_checker_th_error_cnt_value_q <= stat_ts_checker_th_error_cnt_value_i;

                    
          -- Reset clear flags
          stat_smart_dropper_control_evt_drop_flag_clear_q <= '0';
          stat_th_recovery_control_evt_drop_flag_clear_q <= '0';
          stat_th_recovery_control_gen_th_flag_clear_q <= '0';

        
          -- implement axi_awready generation
          -- axi_awready is asserted for one s_axi_aclk clock cycle when both
          -- s_axi_awvalid and s_axi_wvalid are asserted. axi_awready is
          -- de-asserted when reset is low.
          if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
            -- slave is ready to accept write address when
            -- there is a valid write address and write data
            -- on the write address and data bus. this design 
            -- expects no outstanding transactions. 
            axi_awready <= '1';
            aw_en <= '0';
          elsif (s_axi_bready = '1' and axi_bvalid = '1') then
            aw_en <= '1';
            axi_awready <= '0';
          else
            axi_awready <= '0';
          end if; 
          
          -- implement axi_awaddr latching
          -- this process is used to latch the address when both 
          -- s_axi_awvalid and s_axi_wvalid are valid.  
          if (axi_awready = '0' and s_axi_awvalid = '1' and s_axi_wvalid = '1' and aw_en = '1') then
            -- write address latching
            axi_awaddr <= s_axi_awaddr;
          end if;
          
          -- implement axi_wready generation
          -- axi_wready is asserted for one s_axi_aclk clock cycle when both
          -- s_axi_awvalid and s_axi_wvalid are asserted. axi_wready is 
          -- de-asserted when reset is low.         
          if (axi_wready = '0' and s_axi_wvalid = '1' and s_axi_awvalid = '1' and aw_en = '1') then
            -- slave is ready to accept write data when 
            -- there is a valid write address and write data
            -- on the write address and data bus. this design 
            -- expects no outstanding transactions.           
            axi_wready <= '1';
          else
            axi_wready <= '0';
          end if;
          
          -- implement memory mapped register select and write logic generation
          -- the write data is accepted and written to memory mapped registers when
          -- axi_awready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted. write strobes are used to
          -- select byte enables of slave registers while writing.
          -- these registers are cleared when reset (active low) is applied.
          -- slave register write enable is asserted when valid address and data are available
          -- and the slave is ready to accept the write address and write data.
          loc_addr := axi_awaddr(addr_lsb + opt_mem_addr_bits downto addr_lsb);
          if (slv_reg_wren = '1') then
            case loc_addr is
              when CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_control_enable_q <= S_AXI_WDATA(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB);
                cfg_control_bypass_q <= S_AXI_WDATA(CONTROL_BYPASS_MSB downto CONTROL_BYPASS_LSB);
                cfg_control_clear_q <= S_AXI_WDATA(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB);
              when SMART_DROPPER_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_smart_dropper_control_bypass_q <= S_AXI_WDATA(SMART_DROPPER_CONTROL_BYPASS_MSB downto SMART_DROPPER_CONTROL_BYPASS_LSB);
                cfg_smart_dropper_control_gen_other_evt_q <= S_AXI_WDATA(SMART_DROPPER_CONTROL_GEN_OTHER_EVT_MSB downto SMART_DROPPER_CONTROL_GEN_OTHER_EVT_LSB);
              when TH_RECOVERY_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_th_recovery_control_bypass_q <= S_AXI_WDATA(TH_RECOVERY_CONTROL_BYPASS_MSB downto TH_RECOVERY_CONTROL_BYPASS_LSB);
                cfg_th_recovery_control_gen_missing_th_q <= S_AXI_WDATA(TH_RECOVERY_CONTROL_GEN_MISSING_TH_MSB downto TH_RECOVERY_CONTROL_GEN_MISSING_TH_LSB);
                cfg_th_recovery_control_enable_drop_evt_q <= S_AXI_WDATA(TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_MSB downto TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_LSB);
                cfg_th_recovery_control_gen_other_evt_q <= S_AXI_WDATA(TH_RECOVERY_CONTROL_GEN_OTHER_EVT_MSB downto TH_RECOVERY_CONTROL_GEN_OTHER_EVT_LSB);
              when TS_CHECKER_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                cfg_ts_checker_control_bypass_q <= S_AXI_WDATA(TS_CHECKER_CONTROL_BYPASS_MSB downto TS_CHECKER_CONTROL_BYPASS_LSB);
                cfg_ts_checker_control_enable_drop_evt_q <= S_AXI_WDATA(TS_CHECKER_CONTROL_ENABLE_DROP_EVT_MSB downto TS_CHECKER_CONTROL_ENABLE_DROP_EVT_LSB);
                cfg_ts_checker_control_gen_other_evt_q <= S_AXI_WDATA(TS_CHECKER_CONTROL_GEN_OTHER_EVT_MSB downto TS_CHECKER_CONTROL_GEN_OTHER_EVT_LSB);
                cfg_ts_checker_control_gen_tlast_on_other_q <= S_AXI_WDATA(TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_MSB downto TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_LSB);
                cfg_ts_checker_control_threshold_q <= S_AXI_WDATA(TS_CHECKER_CONTROL_THRESHOLD_MSB downto TS_CHECKER_CONTROL_THRESHOLD_LSB);

              when others =>
                -- unknown address
                write_addr_error_q <= '1';
                axi_bresp <= "10";  -- SLVERR
                axi_rdata  <= BUS_ADDR_ERROR_CODE; --error code on the read data bus (not aligned with valid signal)
                
                cfg_control_enable_q <= cfg_control_enable_q;
                cfg_control_bypass_q <= cfg_control_bypass_q;
                cfg_control_clear_q <= cfg_control_clear_q;
                cfg_smart_dropper_control_bypass_q <= cfg_smart_dropper_control_bypass_q;
                cfg_smart_dropper_control_gen_other_evt_q <= cfg_smart_dropper_control_gen_other_evt_q;
                cfg_th_recovery_control_bypass_q <= cfg_th_recovery_control_bypass_q;
                cfg_th_recovery_control_gen_missing_th_q <= cfg_th_recovery_control_gen_missing_th_q;
                cfg_th_recovery_control_enable_drop_evt_q <= cfg_th_recovery_control_enable_drop_evt_q;
                cfg_th_recovery_control_gen_other_evt_q <= cfg_th_recovery_control_gen_other_evt_q;
                cfg_ts_checker_control_bypass_q <= cfg_ts_checker_control_bypass_q;
                cfg_ts_checker_control_enable_drop_evt_q <= cfg_ts_checker_control_enable_drop_evt_q;
                cfg_ts_checker_control_gen_other_evt_q <= cfg_ts_checker_control_gen_other_evt_q;
                cfg_ts_checker_control_gen_tlast_on_other_q <= cfg_ts_checker_control_gen_tlast_on_other_q;
                cfg_ts_checker_control_threshold_q <= cfg_ts_checker_control_threshold_q;

            end case;
          end if;
          
          -- implement write response logic generation
          -- the write response and response valid signals are asserted by the slave 
          -- when axi_wready, s_axi_wvalid, axi_wready and s_axi_wvalid are asserted.  
          -- this marks the acceptance of address and indicates the status of 
          -- write transaction.
          if (axi_awready = '1' and s_axi_awvalid = '1' and axi_wready = '1' and s_axi_wvalid = '1' and axi_bvalid = '0'  ) then
            axi_bvalid <= '1';
            
            if (write_addr_error_q = '1') then
              axi_bresp  <= "10";  -- SLVERR
            end if;
          elsif (s_axi_bready = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
            axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
            write_addr_error_q <= '0';
          end if;
          
          -- implement axi_arready generation
          -- axi_arready is asserted for one s_axi_aclk clock cycle when
          -- s_axi_arvalid is asserted. axi_awready is 
          -- de-asserted when reset (active low) is asserted. 
          -- the read address is also latched when s_axi_arvalid is 
          -- asserted. axi_araddr is reset to zero on reset assertion.
          if (axi_arready = '0' and s_axi_arvalid = '1') then
            -- indicates that the slave has acceped the valid read address
            axi_arready <= '1';
            -- read address latching 
            axi_araddr  <= s_axi_araddr;           
          else
            axi_arready <= '0';
          end if;
          
          -- implement axi_arvalid generation
          -- axi_rvalid is asserted for one s_axi_aclk clock cycle when both 
          -- s_axi_arvalid and axi_arready are asserted. the slave registers 
          -- data are available on the axi_rdata bus at this instance. the 
          -- assertion of axi_rvalid marks the validity of read data on the 
          -- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
          -- is deasserted on reset (active low). axi_rresp and axi_rdata are 
          -- cleared to zero on reset (active low).  
          if (axi_arready = '1' and s_axi_arvalid = '1' and axi_rvalid = '0') then
            -- valid read data is available at the read data bus
            axi_rvalid <= '1';
            
            -- when there is a valid read address (s_axi_arvalid) with 
            -- acceptance of read address by the slave (axi_arready), 
            -- output the read dada 
            -- Read address mux
            loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
            case loc_addr is
              when VERSION_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(VERSION_MINOR_MSB downto VERSION_MINOR_LSB) <= cfg_version_minor_q;
                axi_rdata(VERSION_MAJOR_MSB downto VERSION_MAJOR_LSB) <= cfg_version_major_q;
              when CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(CONTROL_ENABLE_MSB downto CONTROL_ENABLE_LSB) <= cfg_control_enable_q;
                axi_rdata(CONTROL_BYPASS_MSB downto CONTROL_BYPASS_LSB) <= cfg_control_bypass_q;
                axi_rdata(CONTROL_CLEAR_MSB downto CONTROL_CLEAR_LSB) <= cfg_control_clear_q;
              when SMART_DROPPER_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(SMART_DROPPER_CONTROL_BYPASS_MSB downto SMART_DROPPER_CONTROL_BYPASS_LSB) <= cfg_smart_dropper_control_bypass_q;
                axi_rdata(SMART_DROPPER_CONTROL_GEN_OTHER_EVT_MSB downto SMART_DROPPER_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_smart_dropper_control_gen_other_evt_q;
                axi_rdata(SMART_DROPPER_CONTROL_EVT_DROP_FLAG_MSB downto SMART_DROPPER_CONTROL_EVT_DROP_FLAG_LSB) <= stat_smart_dropper_control_evt_drop_flag_q;
                stat_smart_dropper_control_evt_drop_flag_clear_q <= '1';
              when SMART_DROPPER_TH_DROP_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(SMART_DROPPER_TH_DROP_CNT_VALUE_MSB downto SMART_DROPPER_TH_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_th_drop_cnt_value_q;
              when SMART_DROPPER_TL_DROP_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(SMART_DROPPER_TL_DROP_CNT_VALUE_MSB downto SMART_DROPPER_TL_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_tl_drop_cnt_value_q;
              when SMART_DROPPER_EVT_DROP_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(SMART_DROPPER_EVT_DROP_CNT_VALUE_MSB downto SMART_DROPPER_EVT_DROP_CNT_VALUE_LSB) <= stat_smart_dropper_evt_drop_cnt_value_q;
              when TH_RECOVERY_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(TH_RECOVERY_CONTROL_BYPASS_MSB downto TH_RECOVERY_CONTROL_BYPASS_LSB) <= cfg_th_recovery_control_bypass_q;
                axi_rdata(TH_RECOVERY_CONTROL_GEN_MISSING_TH_MSB downto TH_RECOVERY_CONTROL_GEN_MISSING_TH_LSB) <= cfg_th_recovery_control_gen_missing_th_q;
                axi_rdata(TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_MSB downto TH_RECOVERY_CONTROL_ENABLE_DROP_EVT_LSB) <= cfg_th_recovery_control_enable_drop_evt_q;
                axi_rdata(TH_RECOVERY_CONTROL_GEN_OTHER_EVT_MSB downto TH_RECOVERY_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_th_recovery_control_gen_other_evt_q;
                axi_rdata(TH_RECOVERY_CONTROL_EVT_DROP_FLAG_MSB downto TH_RECOVERY_CONTROL_EVT_DROP_FLAG_LSB) <= stat_th_recovery_control_evt_drop_flag_q;
                stat_th_recovery_control_evt_drop_flag_clear_q <= '1';
                axi_rdata(TH_RECOVERY_CONTROL_GEN_TH_FLAG_MSB downto TH_RECOVERY_CONTROL_GEN_TH_FLAG_LSB) <= stat_th_recovery_control_gen_th_flag_q;
                stat_th_recovery_control_gen_th_flag_clear_q <= '1';
              when TS_CHECKER_CONTROL_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(TS_CHECKER_CONTROL_BYPASS_MSB downto TS_CHECKER_CONTROL_BYPASS_LSB) <= cfg_ts_checker_control_bypass_q;
                axi_rdata(TS_CHECKER_CONTROL_ENABLE_DROP_EVT_MSB downto TS_CHECKER_CONTROL_ENABLE_DROP_EVT_LSB) <= cfg_ts_checker_control_enable_drop_evt_q;
                axi_rdata(TS_CHECKER_CONTROL_GEN_OTHER_EVT_MSB downto TS_CHECKER_CONTROL_GEN_OTHER_EVT_LSB) <= cfg_ts_checker_control_gen_other_evt_q;
                axi_rdata(TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_MSB downto TS_CHECKER_CONTROL_GEN_TLAST_ON_OTHER_LSB) <= cfg_ts_checker_control_gen_tlast_on_other_q;
                axi_rdata(TS_CHECKER_CONTROL_THRESHOLD_MSB downto TS_CHECKER_CONTROL_THRESHOLD_LSB) <= cfg_ts_checker_control_threshold_q;
              when TS_CHECKER_TH_DETECT_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(TS_CHECKER_TH_DETECT_CNT_VALUE_MSB downto TS_CHECKER_TH_DETECT_CNT_VALUE_LSB) <= stat_ts_checker_th_detect_cnt_value_q;
              when TS_CHECKER_TH_CORRUPT_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(TS_CHECKER_TH_CORRUPT_CNT_VALUE_MSB downto TS_CHECKER_TH_CORRUPT_CNT_VALUE_LSB) <= stat_ts_checker_th_corrupt_cnt_value_q;
              when TS_CHECKER_TH_ERROR_CNT_ADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) =>
                axi_rdata(TS_CHECKER_TH_ERROR_CNT_VALUE_MSB downto TS_CHECKER_TH_ERROR_CNT_VALUE_LSB) <= stat_ts_checker_th_error_cnt_value_q;

              when others =>
                -- unknown address
                axi_rdata  <= BUS_ADDR_ERROR_CODE;
                read_addr_error_q <= '1';
                axi_rresp <= "10";  -- SLVERR
            end case; 
          
            if (read_addr_error_q = '1') then
              axi_rresp  <= "10";  -- SLVERR
            end if;
          elsif (axi_rvalid = '1' and s_axi_rready = '1') then
            -- Read data is accepted by the master
            axi_rvalid <= '0';
            read_addr_error_q <= '0';
          end if;  
        end if;
      end if;
    end process;

end arch_imp;
