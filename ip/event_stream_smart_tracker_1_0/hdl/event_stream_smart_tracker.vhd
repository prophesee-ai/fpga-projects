-------------------------------------------------------------------------------
-- Copyright (c) Prophesee S.A. - All Rights Reserved
-- Subject to Starter Kit Specific Terms and Conditions ("License T&C's").
-- You may not use this file except in compliance with these License T&C's.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity event_stream_smart_tracker is
    generic (
        ENABLE_SMART_DROP_G  : boolean := true;
        ENABLE_TS_CHECKER_G  : boolean := true;
        ENABLE_TH_RECOVERY_G : boolean := true;

        TIME_HIGH_PERIOD_US_G : positive := 16;

        BYPASS_PIPELINE_STAGES_G  : positive := 4;

        SMART_DROP_FIFO_DEPTH_G            : positive range 32 to 4194304 := 32;
        SMART_DROP_REDUCE_FLOW_THRESHOLD_G : positive range 21 to 4194304 := 21;
        SMART_DROP_ALL_THRESHOLD_G         : positive range  5 to 4194304 := 5;

        -- Parameters of Axi Slave Bus Interface axil_s
        AXIL_DATA_WIDTH_G    : integer    := 32;
        AXIL_ADDR_WIDTH_G    : integer    := 32;
        AXIS_TDATA_WIDTH_G   : positive   := 64;
        AXIS_TUSER_WIDTH_G   : positive   := 1
    );
    port (
        -- Clock and Reset
        clk              : in  std_logic;
        arst_n           : in  std_logic;
        srst             : in  std_logic;

        -- Input Data Streaming Interface
        in_ready_o       : out std_logic;
        in_valid_i       : in  std_logic;
        in_last_i        : in  std_logic;
        in_data_i        : in  std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
        in_tkeep_i       : in  std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
        in_tuser_i       : in  std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

        -- Output Data Streaming Interface
        out_ready_i      : in  std_logic;
        out_valid_o      : out std_logic;
        out_last_o       : out std_logic;
        out_data_o       : out std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
        out_tkeep_o      : out std_logic_vector(AXIS_TDATA_WIDTH_G/8-1 downto 0);
        out_tuser_o      : out std_logic_vector(AXIS_TUSER_WIDTH_G-1 downto 0);

        -- Ports of Axi Slave Bus Interface axil_s
        axil_s_awaddr    : in std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
        axil_s_awprot    : in std_logic_vector(2 downto 0);
        axil_s_awvalid    : in std_logic;
        axil_s_awready    : out std_logic;
        axil_s_wdata    : in std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
        axil_s_wstrb    : in std_logic_vector((AXIL_DATA_WIDTH_G/8)-1 downto 0);
        axil_s_wvalid    : in std_logic;
        axil_s_wready    : out std_logic;
        axil_s_bresp    : out std_logic_vector(1 downto 0);
        axil_s_bvalid    : out std_logic;
        axil_s_bready    : in std_logic;
        axil_s_araddr    : in std_logic_vector(AXIL_ADDR_WIDTH_G-1 downto 0);
        axil_s_arprot    : in std_logic_vector(2 downto 0);
        axil_s_arvalid    : in std_logic;
        axil_s_arready    : out std_logic;
        axil_s_rdata    : out std_logic_vector(AXIL_DATA_WIDTH_G-1 downto 0);
        axil_s_rresp    : out std_logic_vector(1 downto 0);
        axil_s_rvalid    : out std_logic;
        axil_s_rready    : in std_logic
    );
end event_stream_smart_tracker;

architecture arch_imp of event_stream_smart_tracker is

    -- component declaration
    component evt_stream_smart_tracker_reg_bank is
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
            stat_smart_dropper_th_drop_cnt_value_i    : in  std_logic_vector(32-1 downto 0);
            -- SMART_DROPPER_TL_DROP_CNT Register
            stat_smart_dropper_tl_drop_cnt_value_i    : in  std_logic_vector(32-1 downto 0);
            -- SMART_DROPPER_EVT_DROP_CNT Register
            stat_smart_dropper_evt_drop_cnt_value_i   : in  std_logic_vector(32-1 downto 0);
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
    end component evt_stream_smart_tracker_reg_bank;


    ----------------------------------------------------------
    -- Checks incoming Time High events and recover them if an
    -- incoherence is detected.
    component evt21_th_recovery is
        generic (
            TIME_HIGH_PERIOD_US : positive := 16;
            TIME_BASE_INIT_MS   : natural  := 0
        );
        port (
            -- Clock and Reset
            clk              : in std_logic;
            arst_n           : in std_logic;
            srst             : in std_logic;

            -- Configuration Interface
            cfg_enable_i               : in  std_logic_vector(0 downto 0);
            cfg_bypass_i               : in  std_logic_vector(0 downto 0);
            cfg_gen_missing_th_i       : in  std_logic_vector(0 downto 0);
            cfg_enable_drop_evt_i      : in  std_logic_vector(0 downto 0);
            cfg_gen_other_evt_i        : in  std_logic_vector(0 downto 0);
            stat_gen_th_flag_o         : out std_logic_vector(0 downto 0);
            stat_gen_th_flag_clear_i   : in  std_logic;
            stat_evt_drop_flag_o       : out std_logic_vector(0 downto 0);
            stat_evt_drop_flag_clear_i : in  std_logic;

            -- Input Interfaces
            in_ready_o       : out std_logic;
            in_valid_i       : in  std_logic;
            in_last_i        : in  std_logic;
            in_data_i        : in  std_logic_vector(63 downto 0);

            -- Output Interface
            out_ready_i      : in  std_logic;
            out_valid_o      : out std_logic;
            out_last_o       : out std_logic;
            out_data_o       : out std_logic_vector(63 downto 0)
        );
    end component evt21_th_recovery;

    ---------------------------------------------------------------
    -- EVT 2.1 smart event stream dropper
    component evt21_smart_drop is
        port (
            -- Clock and Reset
            clk                         : in std_logic;
            arst_n                      : in std_logic;
            srst                        : in std_logic;

            -- Configuration Interface
            cfg_enable_i                : in  std_logic_vector(0 downto 0);
            cfg_bypass_i                : in  std_logic_vector(0 downto 0);
            cfg_gen_other_evt_i         : in  std_logic_vector(0 downto 0);
            cfg_reduce_flag_i           : in  std_logic;         -- first stage full flag, don't drop TH
            cfg_drop_flag_i             : in  std_logic;         -- second stage full flag, drop all

            -- Debug Counter
            stat_evt_drop_flag_o        : out std_logic_vector(0 downto 0); -- Indicate event dropped
            stat_evt_drop_flag_clear_i  : in  std_logic;
            stat_th_drop_cnt_o          : out std_logic_vector(31 downto 0);
            stat_tl_drop_cnt_o          : out std_logic_vector(31 downto 0);
            stat_evt_drop_cnt_o         : out std_logic_vector(31 downto 0);

            -- Input Interfaces
            in_ready_o                  : out std_logic;
            in_valid_i                  : in  std_logic;
            in_last_i                   : in  std_logic;
            in_data_i                   : in  std_logic_vector(63 downto 0);

            -- Output Interface
            out_ready_i                 : in  std_logic;
            out_valid_o                 : out std_logic;
            out_last_o                  : out std_logic;
            out_data_o                  : out std_logic_vector(63 downto 0)
        );
    end component evt21_smart_drop;

    ------------------------------------
    -- Two steps fifo almost full Fifo
    component evt_smart_fifo is
        generic (
            MEMORY_TYPE_G               : string                       := "auto"; -- Allowed values: auto, block, distributed, ultra. Default value = auto.
            DEPTH_G                     : positive range 32 to 4194304 := 2048;
            STEP1_ALMOST_FULL_THRESH_G  : positive range 21 to 4194304 := 2048;
            STEP2_ALMOST_FULL_THRESH_G  : positive range  5 to 4194304 := 2048;
            DATA_WIDTH_G                : positive                     := 32      -- FIFO_WIDTH = DATA_WIDTH_G + 2 (for first and last bits)
        );
        port (
            -- Clock and Reset
            clk                         : in  std_logic;
            srst                        : in  std_logic;

            -- Status Interface
            cfg_fifo_full_flag_o        : out std_logic_vector(1 downto 0);         -- bit0 : first stage full flag, don't drop TH; bit1 : second stage full flag, drop all

            -- Input Interface
            in_ready_o                  : out std_logic;
            in_valid_i                  : in  std_logic;
            in_first_i                  : in  std_logic;
            in_last_i                   : in  std_logic;
            in_data_i                   : in  std_logic_vector(DATA_WIDTH_G-1 downto 0);

            -- Output Interface
            out_ready_i                 : in  std_logic;
            out_valid_o                 : out std_logic;
            out_first_o                 : out std_logic;
            out_last_o                  : out std_logic;
            out_data_o                  : out std_logic_vector(DATA_WIDTH_G-1 downto 0)
        );
    end component evt_smart_fifo;

    ------------------------------------
    -- EVT2.1 TimeStamp Checker
    component evt21_ts_checker is
        generic (
            TIME_HIGH_PERIOD_US   : positive := 16
        );
        port (
            -- Clock and Reset
            clk                   : in std_logic;
            arst_n                : in std_logic;
            srst                  : in std_logic;

            -- Configuration Interface
            cfg_enable_i             : in  std_logic_vector(0 downto 0);
            cfg_bypass_i             : in  std_logic_vector(0 downto 0);
            cfg_ts_threshold_i       : in  std_logic_vector(27 downto 0);
            cfg_enable_drop_evt_i    : in  std_logic_vector(0 downto 0);
            cfg_gen_other_evt_i      : in  std_logic_vector(0 downto 0);
            cfg_gen_tlast_on_other_i : in  std_logic_vector(0 downto 0);
            stat_th_detect_cnt_o     : out std_logic_vector(15 downto 0);
            stat_th_corrupt_cnt_o    : out std_logic_vector(15 downto 0);
            stat_th_error_cnt_o      : out std_logic_vector(15 downto 0);

            -- Input Interfaces
            in_ready_o            : out std_logic;
            in_valid_i            : in  std_logic;
            in_last_i             : in  std_logic;
            in_data_i             : in  std_logic_vector(63 downto 0);

            -- Output Interface
            out_ready_i           : in  std_logic;
            out_valid_o           : out std_logic;
            out_last_o            : out std_logic;
            out_data_o            : out std_logic_vector(63 downto 0)
        );
    end component evt21_ts_checker;

    ------------------------------------
    -- AXI4S Demultiplexer 1 to 2
    component axi4s_demux_1_2_keep is
        generic (
            DATA_WIDTH   : positive := 32
        );
        port (
            -- Core clock and reset
            clk          : in  std_logic;
            arst_n       : in  std_logic;
            srst         : in  std_logic;

            -- Output selection control
            out_select_i  : in  std_logic;

            -- Input event stream interface
            in_ready_o   : out std_logic;
            in_valid_i   : in  std_logic;
            in_first_i   : in  std_logic;
            in_last_i    : in  std_logic;
            in_data_i    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            in_keep_i    : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);

            -- Output 0 event stream interface
            out0_ready_i : in  std_logic;
            out0_valid_o : out std_logic;
            out0_first_o : out std_logic;
            out0_last_o  : out std_logic;
            out0_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out0_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0);

            -- Output 1 event stream interface
            out1_ready_i : in  std_logic;
            out1_valid_o : out std_logic;
            out1_first_o : out std_logic;
            out1_last_o  : out std_logic;
            out1_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out1_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0)
          );
    end component axi4s_demux_1_2_keep;

    ------------------------------------
    -- AXI4S Multiplexer 2 to 1
    component axi4s_mux_2_1_keep is
        generic (
            DATA_WIDTH       : positive := 32;
            UNSEL_READY_HIGH : boolean  := false  -- If true, unselected inputs have their ready line driven high.
        );
        port (
            -- Clock and Reset
            clk         : in  std_logic;
            arst_n      : in  std_logic;
            srst        : in  std_logic;

            -- Input Selection Control
            in_select_i : in  std_logic;

            -- Input 0 Stream Interface
            in0_ready_o : out std_logic;
            in0_valid_i : in  std_logic;
            in0_first_i : in  std_logic;
            in0_last_i  : in  std_logic;
            in0_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            in0_keep_i  : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);

            -- Input 1 Stream Interface
            in1_ready_o : out std_logic;
            in1_valid_i : in  std_logic;
            in1_first_i : in  std_logic;
            in1_last_i  : in  std_logic;
            in1_data_i  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            in1_keep_i  : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);

            -- Output Event Stream Interface
            out_ready_i : in  std_logic;
            out_valid_o : out std_logic;
            out_first_o : out std_logic;
            out_last_o  : out std_logic;
            out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0)
        );
    end component axi4s_mux_2_1_keep;

    -----------------------------
    -- AXI4-Stream Pipeline Stage
    component axi4s_pipeline_stage is
        generic (
            PIPELINE_STAGES : integer   := 1;
            DATA_WIDTH      : positive  := 32
        );
        port (
            clk         : in  std_logic;
            rst         : in  std_logic;

            -- Input interface
            in_ready_o  : out std_logic;
            in_valid_i  : in  std_logic;
            in_first_i  : in  std_logic;
            in_last_i   : in  std_logic;
            in_data_i   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            in_keep_i   : in  std_logic_vector(DATA_WIDTH/8-1 downto 0);

            -- Output interface
            out_ready_i : in  std_logic;
            out_valid_o : out std_logic;
            out_first_o : out std_logic;
            out_last_o  : out std_logic;
            out_data_o  : out std_logic_vector(DATA_WIDTH-1 downto 0);
            out_keep_o  : out std_logic_vector(DATA_WIDTH/8-1 downto 0)
        );
    end component axi4s_pipeline_stage;

    ------------------------
    -- Types Declarations --
    ------------------------

    -------------------------
    -- Constants Declarations --
    -------------------------

    -------------------------
    -- Signal Declarations --
    -------------------------
    -- GLOBAL signals
    signal cfg_control_enable_s                              : std_logic_vector(0 downto 0);
    signal cfg_control_bypass_s                              : std_logic_vector(0 downto 0);
    signal cfg_control_clear_s                               : std_logic_vector(0 downto 0);

    -- SMART DROPPER signals
    signal cfg_smart_dropper_control_bypass_s                : std_logic_vector(0 downto 0);
    signal cfg_smart_dropper_control_gen_other_evt_s         : std_logic_vector(0 downto 0);
    signal stat_smart_dropper_control_evt_drop_flag_s        : std_logic_vector(0 downto 0);
    signal stat_smart_dropper_control_evt_drop_flag_clear_s  : std_logic;
    signal stat_smart_dropper_th_drop_cnt_value_s            : std_logic_vector(31 downto 0);
    signal stat_smart_dropper_tl_drop_cnt_value_s            : std_logic_vector(31 downto 0);
    signal stat_smart_dropper_evt_drop_cnt_value_s           : std_logic_vector(31 downto 0);
    signal evt21_smart_drop_out_ready_s                      : std_logic;
    signal evt21_smart_drop_out_valid_s                      : std_logic;
    signal evt21_smart_drop_out_last_s                       : std_logic;
    signal evt21_smart_drop_out_data_s                       : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

    signal evt_smart_fifo_full_flag_s                        : std_logic_vector(1 downto 0);
    signal evt_smart_fifo_out_ready_s                        : std_logic;
    signal evt_smart_fifo_out_valid_s                        : std_logic;
    signal evt_smart_fifo_out_last_s                         : std_logic;
    signal evt_smart_fifo_out_data_s                         : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

    -- TH RECOVERY signals
    signal cfg_th_recovery_control_bypass_s                  : std_logic_vector(0 downto 0);
    signal cfg_th_recovery_control_gen_missing_th_s          : std_logic_vector(0 downto 0);
    signal cfg_th_recovery_control_enable_drop_evt_s         : std_logic_vector(0 downto 0);
    signal cfg_th_recovery_control_gen_other_evt_s           : std_logic_vector(0 downto 0);
    signal stat_th_recovery_control_evt_drop_flag_s          : std_logic_vector(0 downto 0);
    signal stat_th_recovery_control_evt_drop_flag_clear_s    : std_logic;
    signal stat_th_recovery_control_gen_th_flag_s            : std_logic_vector(0 downto 0);
    signal stat_th_recovery_control_gen_th_flag_clear_s      : std_logic;

    signal evt21_th_recovery_out_ready_s                     : std_logic;
    signal evt21_th_recovery_out_valid_s                     : std_logic;
    signal evt21_th_recovery_out_last_s                      : std_logic;
    signal evt21_th_recovery_out_data_s                      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

    -- EVT21_TS_CHECKER
    signal cfg_ts_checker_control_bypass_s                   : std_logic_vector(0 downto 0);
    signal cfg_ts_checker_control_enable_drop_evt_s          : std_logic_vector(0 downto 0);
    signal cfg_ts_checker_control_gen_other_evt_s            : std_logic_vector(0 downto 0);
    signal cfg_ts_checker_control_gen_tlast_on_other_s       : std_logic_vector(0 downto 0);
    signal cfg_ts_checker_control_threshold_s                : std_logic_vector(27 downto 0);
    signal stat_ts_checker_th_detect_cnt_value_s             : std_logic_vector(15 downto 0);
    signal stat_ts_checker_th_corrupt_cnt_value_s            : std_logic_vector(15 downto 0);
    signal stat_ts_checker_th_error_cnt_value_s              : std_logic_vector(15 downto 0);

    signal evt21_ts_checker_out_ready_s                      : std_logic;
    signal evt21_ts_checker_out_valid_s                      : std_logic;
    signal evt21_ts_checker_out_last_s                       : std_logic;
    signal evt21_ts_checker_out_data_s                       : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

    -- Bypass internal signals
    signal cfg_smart_dropper_control_bypass_int              : std_logic_vector(0 downto 0);
    signal cfg_th_recovery_control_bypass_int                : std_logic_vector(0 downto 0);
    signal cfg_ts_checker_control_bypass_int                 : std_logic_vector(0 downto 0);

    -- Demux signals
    signal demux_ready_s                                     : std_logic;
    signal demux_valid_s                                     : std_logic;
    signal demux_last_s                                      : std_logic;
    signal demux_data_s                                      : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);

    signal demux_bypass_ready_s                              : std_logic;
    signal demux_bypass_valid_s                              : std_logic;
    signal demux_bypass_first_s                              : std_logic;
    signal demux_bypass_last_s                               : std_logic;
    signal demux_bypass_data_s                               : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    signal demux_bypass_keep_s                               : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);

    -- Pipeline signal
    signal pipeline_bypass_ready_s                           : std_logic;
    signal pipeline_bypass_valid_s                           : std_logic;
    signal pipeline_bypass_first_s                           : std_logic;
    signal pipeline_bypass_last_s                            : std_logic;
    signal pipeline_bypass_data_s                            : std_logic_vector(AXIS_TDATA_WIDTH_G-1 downto 0);
    signal pipeline_bypass_keep_s                            : std_logic_vector((AXIS_TDATA_WIDTH_G/8)-1 downto 0);

    -- Clear internal signal
    signal clear_srst_int                                    : std_logic;

begin

    -- Clear signal driver : srst drived with clear
    clear_srst_int  <= srst or cfg_control_clear_s(0);

    -- Output Demux with bypass
    axi4s_demux_1_2_inst : axi4s_demux_1_2_keep
        generic map (
            DATA_WIDTH => AXIS_TDATA_WIDTH_G
        )
        port map (
            -- Clock and Reset
            clk                         => clk,
            arst_n                      => arst_n,
            srst                        => clear_srst_int,
            -- Output selection control
            out_select_i                => cfg_control_bypass_s(0),

            -- Input event stream interface
            in_ready_o                  => in_ready_o,
            in_valid_i                  => in_valid_i,
            in_first_i                  => in_tuser_i(0),
            in_last_i                   => in_last_i,
            in_data_i                   => in_data_i,
            in_keep_i                   => in_tkeep_i,

            -- Output 0 event stream interface
            out0_ready_i                => demux_ready_s,
            out0_valid_o                => demux_valid_s,
            out0_first_o                => open,
            out0_last_o                 => demux_last_s,
            out0_data_o                 => demux_data_s,
            out0_keep_o                 => open,

            -- Output 1 event stream interface
            out1_ready_i                => demux_bypass_ready_s,
            out1_valid_o                => demux_bypass_valid_s,
            out1_first_o                => demux_bypass_first_s,
            out1_last_o                 => demux_bypass_last_s,
            out1_data_o                 => demux_bypass_data_s,
            out1_keep_o                 => demux_bypass_keep_s
        );

    axi4s_pipeline_bypass_stage_inst : axi4s_pipeline_stage
        generic map (
            PIPELINE_STAGES => BYPASS_PIPELINE_STAGES_G,
            DATA_WIDTH      => AXIS_TDATA_WIDTH_G
        )
        port map (
            clk             => clk,
            rst             => clear_srst_int,

            -- Input interface
            in_ready_o      => demux_bypass_ready_s,
            in_valid_i      => demux_bypass_valid_s,
            in_first_i      => demux_bypass_first_s,
            in_last_i       => demux_bypass_last_s,
            in_data_i       => demux_bypass_data_s,
            in_keep_i       => demux_bypass_keep_s,

            -- Output interface
            out_ready_i     => pipeline_bypass_ready_s,
            out_valid_o     => pipeline_bypass_valid_s,
            out_first_o     => pipeline_bypass_first_s,
            out_last_o      => pipeline_bypass_last_s,
            out_data_o      => pipeline_bypass_data_s,
            out_keep_o      => pipeline_bypass_keep_s
        );

    -- Instantiation of Axi Bus Interface axil_s
    event_stream_smart_tracker_reg_bank_inst : evt_stream_smart_tracker_reg_bank
        generic map (
            C_S_AXI_DATA_WIDTH    => AXIL_ADDR_WIDTH_G,
            C_S_AXI_ADDR_WIDTH    => AXIL_DATA_WIDTH_G
        )
        port map (
                -- CONTROL Register
            cfg_control_enable_o                                => cfg_control_enable_s,
            cfg_control_bypass_o                                => cfg_control_bypass_s,
            cfg_control_clear_o                                 => cfg_control_clear_s,
            -- SMART_DROPPER_CONTROL Register
            cfg_smart_dropper_control_bypass_o                  => cfg_smart_dropper_control_bypass_s,
            cfg_smart_dropper_control_gen_other_evt_o           => cfg_smart_dropper_control_gen_other_evt_s,
            stat_smart_dropper_control_evt_drop_flag_i          => stat_smart_dropper_control_evt_drop_flag_s,
            stat_smart_dropper_control_evt_drop_flag_clear_o    => stat_smart_dropper_control_evt_drop_flag_clear_s,
            -- SMART_DROPPER_TH_DROP_CNT Register
            stat_smart_dropper_th_drop_cnt_value_i               => stat_smart_dropper_th_drop_cnt_value_s,
            -- SMART_DROPPER_TL_DROP_CNT Register
            stat_smart_dropper_tl_drop_cnt_value_i               => stat_smart_dropper_tl_drop_cnt_value_s,
            -- SMART_DROPPER_EVT_DROP_CNT Register
            stat_smart_dropper_evt_drop_cnt_value_i              => stat_smart_dropper_evt_drop_cnt_value_s,
            -- TH_RECOVERY_CONTROL Register
            cfg_th_recovery_control_bypass_o                    => cfg_th_recovery_control_bypass_s,
            cfg_th_recovery_control_gen_missing_th_o            => cfg_th_recovery_control_gen_missing_th_s,
            cfg_th_recovery_control_enable_drop_evt_o           => cfg_th_recovery_control_enable_drop_evt_s,
            cfg_th_recovery_control_gen_other_evt_o             => cfg_th_recovery_control_gen_other_evt_s,
            stat_th_recovery_control_evt_drop_flag_i            => stat_th_recovery_control_evt_drop_flag_s,
            stat_th_recovery_control_evt_drop_flag_clear_o      => stat_th_recovery_control_evt_drop_flag_clear_s,
            stat_th_recovery_control_gen_th_flag_i              => stat_th_recovery_control_gen_th_flag_s,
            stat_th_recovery_control_gen_th_flag_clear_o        => stat_th_recovery_control_gen_th_flag_clear_s,
            -- TS_CHECKER_CONTROL Register
            cfg_ts_checker_control_bypass_o                     => cfg_ts_checker_control_bypass_s,
            cfg_ts_checker_control_enable_drop_evt_o            => cfg_ts_checker_control_enable_drop_evt_s,
            cfg_ts_checker_control_gen_other_evt_o              => cfg_ts_checker_control_gen_other_evt_s,
            cfg_ts_checker_control_gen_tlast_on_other_o         => cfg_ts_checker_control_gen_tlast_on_other_s,
            cfg_ts_checker_control_threshold_o                  => cfg_ts_checker_control_threshold_s,
            -- TS_CHECKER_TH_DETECT_CNT Register
            stat_ts_checker_th_detect_cnt_value_i               => stat_ts_checker_th_detect_cnt_value_s,
            -- TS_CHECKER_TH_CORRUPT_CNT Register
            stat_ts_checker_th_corrupt_cnt_value_i              => stat_ts_checker_th_corrupt_cnt_value_s,
            -- TS_CHECKER_TH_ERROR_CNT Register
            stat_ts_checker_th_error_cnt_value_i                => stat_ts_checker_th_error_cnt_value_s,

            s_axi_aclk     => clk,
            a_axi_aresetn  => arst_n,
            s_axi_awaddr   => axil_s_awaddr,
            s_axi_awprot   => axil_s_awprot,
            s_axi_awvalid  => axil_s_awvalid,
            s_axi_awready  => axil_s_awready,
            s_axi_wdata    => axil_s_wdata,
            s_axi_wstrb    => axil_s_wstrb,
            s_axi_wvalid   => axil_s_wvalid,
            s_axi_wready   => axil_s_wready,
            s_axi_bresp    => axil_s_bresp,
            s_axi_bvalid   => axil_s_bvalid,
            s_axi_bready   => axil_s_bready,
            s_axi_araddr   => axil_s_araddr,
            s_axi_arprot   => axil_s_arprot,
            s_axi_arvalid  => axil_s_arvalid,
            s_axi_arready  => axil_s_arready,
            s_axi_rdata    => axil_s_rdata,
            s_axi_rresp    => axil_s_rresp,
            s_axi_rvalid   => axil_s_rvalid,
            s_axi_rready   => axil_s_rready
    );

smart_dropper_gen: if (ENABLE_SMART_DROP_G = true) generate

    cfg_smart_dropper_control_bypass_int <= cfg_smart_dropper_control_bypass_s or cfg_control_bypass_s;

    evt21_smart_drop_inst : evt21_smart_drop
        port map (
            -- Clock and Reset
            clk                         => clk,
            arst_n                      => arst_n,
            srst                        => clear_srst_int,
            -- Configuration Interface
            cfg_enable_i                => cfg_control_enable_s,
            cfg_bypass_i                => cfg_smart_dropper_control_bypass_int,
            cfg_gen_other_evt_i         => cfg_smart_dropper_control_gen_other_evt_s,
            cfg_reduce_flag_i           => evt_smart_fifo_full_flag_s(0),
            cfg_drop_flag_i             => evt_smart_fifo_full_flag_s(1),
            -- Debug Counter
            stat_evt_drop_flag_o        => stat_smart_dropper_control_evt_drop_flag_s,
            stat_evt_drop_flag_clear_i  => stat_smart_dropper_control_evt_drop_flag_clear_s,
            stat_th_drop_cnt_o          => stat_smart_dropper_th_drop_cnt_value_s,
            stat_tl_drop_cnt_o          => stat_smart_dropper_tl_drop_cnt_value_s,
            stat_evt_drop_cnt_o         => stat_smart_dropper_evt_drop_cnt_value_s,
            -- Input Interfaces
            in_ready_o                  => demux_ready_s,
            in_valid_i                  => demux_valid_s,
            in_last_i                   => demux_last_s,
            in_data_i                   => demux_data_s,
            -- Output Interface
            out_ready_i                 => evt21_smart_drop_out_ready_s,
            out_valid_o                 => evt21_smart_drop_out_valid_s,
            out_last_o                  => evt21_smart_drop_out_last_s,
            out_data_o                  => evt21_smart_drop_out_data_s
        );

    evt_smart_fifo_inst : evt_smart_fifo
        generic map (
            MEMORY_TYPE_G               => "auto", -- Allowed values: auto, block, distributed, ultra. Default value = auto.
            DEPTH_G                     => SMART_DROP_FIFO_DEPTH_G,
            STEP1_ALMOST_FULL_THRESH_G  => SMART_DROP_REDUCE_FLOW_THRESHOLD_G,
            STEP2_ALMOST_FULL_THRESH_G  => SMART_DROP_ALL_THRESHOLD_G,
            DATA_WIDTH_G                => AXIS_TDATA_WIDTH_G -- FIFO_WIDTH = DATA_WIDTH_G + 2 (for first and last bits)
        )
        port map (
            -- Clock and Reset
            clk                         => clk,
            srst                        => clear_srst_int,

            -- Status Interface
            cfg_fifo_full_flag_o        => evt_smart_fifo_full_flag_s,         -- bit0 : first stage full flag, don't drop TH; bit1 : second stage full flag, drop all

            -- Input Interface
            in_ready_o                  => evt21_smart_drop_out_ready_s,
            in_valid_i                  => evt21_smart_drop_out_valid_s,
            in_first_i                  => '0',
            in_last_i                   => evt21_smart_drop_out_last_s,
            in_data_i                   => evt21_smart_drop_out_data_s,

            -- Output Interface
            out_ready_i                 => evt_smart_fifo_out_ready_s,
            out_valid_o                 => evt_smart_fifo_out_valid_s,
            out_first_o                 => open,
            out_last_o                  => evt_smart_fifo_out_last_s,
            out_data_o                  => evt_smart_fifo_out_data_s
        );

end generate smart_dropper_gen;

smart_dropper_not_gen: if (ENABLE_SMART_DROP_G = false) generate

    demux_ready_s               <= evt_smart_fifo_out_ready_s;
    evt_smart_fifo_out_valid_s  <= demux_valid_s;
    evt_smart_fifo_out_last_s   <= demux_last_s;
    evt_smart_fifo_out_data_s   <= demux_data_s;

end generate smart_dropper_not_gen;

ts_checker_gen: if (ENABLE_TS_CHECKER_G = true) generate

    cfg_ts_checker_control_bypass_int <= cfg_ts_checker_control_bypass_s or cfg_control_bypass_s;

    evt21_ts_checker_inst : evt21_ts_checker
        generic map (
            TIME_HIGH_PERIOD_US         => TIME_HIGH_PERIOD_US_G
        )
        port map (
            -- Clock and Reset
            clk                         => clk,
            arst_n                      => arst_n,
            srst                        => clear_srst_int,
            -- Configuration Interface
            cfg_enable_i                => cfg_control_enable_s,
            cfg_bypass_i                => cfg_ts_checker_control_bypass_int,
            cfg_ts_threshold_i          => cfg_ts_checker_control_threshold_s,
            cfg_enable_drop_evt_i       => cfg_ts_checker_control_enable_drop_evt_s,
            cfg_gen_other_evt_i         => cfg_ts_checker_control_gen_other_evt_s,
            cfg_gen_tlast_on_other_i    => cfg_ts_checker_control_gen_tlast_on_other_s,
            stat_th_detect_cnt_o        => stat_ts_checker_th_detect_cnt_value_s,
            stat_th_corrupt_cnt_o       => stat_ts_checker_th_corrupt_cnt_value_s,
            stat_th_error_cnt_o         => stat_ts_checker_th_error_cnt_value_s,
            -- Input Interfaces
            in_ready_o                  => evt_smart_fifo_out_ready_s,
            in_valid_i                  => evt_smart_fifo_out_valid_s,
            in_last_i                   => evt_smart_fifo_out_last_s,
            in_data_i                   => evt_smart_fifo_out_data_s,
            -- Output Interface
            out_ready_i                 => evt21_ts_checker_out_ready_s,
            out_valid_o                 => evt21_ts_checker_out_valid_s,
            out_last_o                  => evt21_ts_checker_out_last_s,
            out_data_o                  => evt21_ts_checker_out_data_s
        );

end generate ts_checker_gen;

ts_checker_not_gen: if (ENABLE_TS_CHECKER_G = false) generate

    evt_smart_fifo_out_ready_s    <= evt21_ts_checker_out_ready_s;
    evt21_ts_checker_out_valid_s  <= evt_smart_fifo_out_valid_s;
    evt21_ts_checker_out_last_s   <= evt_smart_fifo_out_last_s;
    evt21_ts_checker_out_data_s   <= evt_smart_fifo_out_data_s;

end generate ts_checker_not_gen;

th_recovery_gen: if (ENABLE_TH_RECOVERY_G = true) generate

    cfg_th_recovery_control_bypass_int <= cfg_th_recovery_control_bypass_s or cfg_control_bypass_s;

    evt21_th_recovery_inst : evt21_th_recovery
        generic map (
            TIME_HIGH_PERIOD_US => TIME_HIGH_PERIOD_US_G,
            TIME_BASE_INIT_MS   => 0
        )
        port map(
            -- Clock and Reset
            clk              => clk,
            arst_n           => arst_n,
            srst             => clear_srst_int,

            -- Configuration Interface
            cfg_enable_i               => cfg_control_enable_s,
            cfg_bypass_i               => cfg_th_recovery_control_bypass_s,
            cfg_gen_missing_th_i       => cfg_th_recovery_control_gen_missing_th_s,
            cfg_enable_drop_evt_i      => cfg_th_recovery_control_enable_drop_evt_s,
            cfg_gen_other_evt_i        => cfg_th_recovery_control_gen_other_evt_s,
            stat_gen_th_flag_o         => stat_th_recovery_control_gen_th_flag_s,
            stat_gen_th_flag_clear_i   => stat_th_recovery_control_gen_th_flag_clear_s,
            stat_evt_drop_flag_o       => stat_th_recovery_control_evt_drop_flag_s,
            stat_evt_drop_flag_clear_i => stat_th_recovery_control_evt_drop_flag_clear_s,

            -- Input Interfaces
            in_ready_o       => evt21_ts_checker_out_ready_s,
            in_valid_i       => evt21_ts_checker_out_valid_s,
            in_last_i        => evt21_ts_checker_out_last_s,
            in_data_i        => evt21_ts_checker_out_data_s,

            -- Output Interface
            out_ready_i      => evt21_th_recovery_out_ready_s,
            out_valid_o      => evt21_th_recovery_out_valid_s,
            out_last_o       => evt21_th_recovery_out_last_s,
            out_data_o       => evt21_th_recovery_out_data_s
        );

end generate th_recovery_gen;

th_recovery_not_gen: if (ENABLE_TH_RECOVERY_G = false) generate

    evt21_ts_checker_out_ready_s    <= evt21_th_recovery_out_ready_s;
    evt21_th_recovery_out_valid_s   <= evt21_ts_checker_out_valid_s;
    evt21_th_recovery_out_last_s    <= evt21_ts_checker_out_last_s;
    evt21_th_recovery_out_data_s    <= evt21_ts_checker_out_data_s;

end generate th_recovery_not_gen;

    ---------------------------------------------------
    -- Output MUX
    axi4s_mux_1_2_inst : axi4s_mux_2_1_keep
       generic map (
           DATA_WIDTH => AXIS_TDATA_WIDTH_G
       )
       port map (
           -- Clock and Reset
           clk                         => clk,
           arst_n                      => arst_n,
           srst                        => clear_srst_int,
           -- input selection control
           in_select_i                 => cfg_control_bypass_s(0),

           -- Input 0 stream interface
           in0_ready_o                => evt21_th_recovery_out_ready_s,
           in0_valid_i                => evt21_th_recovery_out_valid_s,
           in0_first_i                => '0',
           in0_last_i                 => evt21_th_recovery_out_last_s,
           in0_data_i                 => evt21_th_recovery_out_data_s,
           in0_keep_i                 => (others => '1'),

           -- Input 1 stream interface
           in1_ready_o                => pipeline_bypass_ready_s,
           in1_valid_i                => pipeline_bypass_valid_s,
           in1_first_i                => pipeline_bypass_first_s,
           in1_last_i                 => pipeline_bypass_last_s,
           in1_data_i                 => pipeline_bypass_data_s,
           in1_keep_i                 => pipeline_bypass_keep_s,

           -- Output stream interface
           out_ready_i                => out_ready_i,
           out_valid_o                => out_valid_o,
           out_first_o                => out_tuser_o(0),
           out_last_o                 => out_last_o,
           out_data_o                 => out_data_o,
           out_keep_o                 => out_tkeep_o
       );

end arch_imp;
