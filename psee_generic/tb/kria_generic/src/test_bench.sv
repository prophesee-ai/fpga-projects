//////////////////////////////////////////////////////////////////////////////////
// Company:        Prophesee
// Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
//
// Create Date:    Sept. 18, 2023
// Design Name:    kria_generic_test_bench
// Module Name:    
// Project Name:   kria_generic
// Target Devices: Zynq Ultrascale
// Tool versions:  Vivado 2022.2
// Description:    test bench to simulate top kria generic
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "tb_local_params.sv"

module test_bench #(
  parameter AXIL_MIPI_TX_PATTERN_FILE_G = "axil_bfm_file.pat",
  parameter AXIL_FPGA_PATTERN_FILE_G    = "axil_bfm_file.pat",
  parameter IN_DATA_FILE_PATH_G         = "in_evt_file.evt",
  parameter REF_DATA_FILE_PATH_G        = "out_evt_file.evt",
  parameter INIT_MEM_FILE_PATH_G        = "init_mem_file.mem",
  parameter OUT_MEM_FILE_PATH_G         = "out_mem_file.mem"
);
reg tb_ACLK;
reg tb_ARESETn; 
  
reg bfm_mipi_tx_enable_s = 1'b0;
reg bfm_mipi_tx_sync_request_s = 1'b0; 
reg bfm_mipi_tx_sync_ack_s; 
reg bfm_mipi_tx_eof_s;
reg bfm_axil_run_step_s = 1'b0;
reg bfm_axil_busy_s;
reg bfm_axil_end_s; 
reg bfm_fpga_enable_s = 1'b0;
reg bfm_fpga_end_s;
reg dma_received_data_finished = 1'b0;

wire temp_clk;
wire temp_rstn; 

wire ccam5_csi_rx_clk_n;
wire ccam5_csi_rx_clk_p;
wire [1:0] ccam5_csi_rx_data_n;
wire [1:0] ccam5_csi_rx_data_p;
wire ccam5_i2c_scl_io;
wire ccam5_i2c_sda_io;
wire [0:0]fan_en_b;
wire [1:0] gpio_generic_tri_o;

reg [31:0] read_data;
reg resp;

wire core_clk_s   ;
wire core_arst_n_s;
wire core_srst_s  ;
 
wire mipi_tx_hs_clk_s   ;
wire mipi_tx_hs_arst_n_s;
wire mipi_tx_hs_srst_s  ;
wire mipi_tx_hs_clk90_s ;
 
wire mipi_rx_dphy_clk_s   ;
wire mipi_rx_dphy_arst_n_s;
wire mipi_rx_dphy_srst_s  ;

wire clk_axi_dma_s2mm_s;
wire in_ready_s ;
wire in_valid_s ;
wire [63:0] in_data_s  ;

reg axi_dma_record_end_s = 1'b0;
reg axi_dma_record_err_s = 1'b0;

initial 
begin       
    tb_ACLK = 1'b0;
end
    
initial 
begin      
    while(axi_dma_record_end_s == 1'b0) begin
        if(axi_dma_record_err_s == 1'b1) begin
            $display("Error with AXI_DMA_CHECKER_OUT");
            $finish;                
        end
    end
end

//------------------------------------------------------------------------
// Simple Clock Generator
//------------------------------------------------------------------------

always #10 tb_ACLK = !tb_ACLK;
   
initial
begin

    $display ("running the tb");
    
    tb_ARESETn = 1'b0;
    repeat(200)@(posedge tb_ACLK);        
    tb_ARESETn = 1'b1;
    @(posedge tb_ACLK);
    
    repeat(5) @(posedge tb_ACLK);
      
    //Reset the PL zynq_ultra_ps_e_0   Base_Zynq_MPSoC_zynq_ultra_ps_e_0_0
    `ZYNQ_VIP_0.por_srstb_reset(1'b0);
    `ZYNQ_VIP_0.fpga_soft_reset(32'h1);   
    #200;  // This delay depends on your clock frequency. It should be at least 16 clock cycles. 
    `ZYNQ_VIP_0.por_srstb_reset(1'b1);
    `ZYNQ_VIP_0.fpga_soft_reset(32'h0);
    
    // Set debug level info to off. For more info, set to 1.
    `ZYNQ_VIP_0.set_debug_level_info(1);
    `ZYNQ_VIP_0.set_stop_on_error(1);
    
    //Fill the source data area
    `ZYNQ_VIP_0.pre_load_mem_from_file(INIT_MEM_FILE_PATH_G, 32'h00000000, 16*4);
    #1000
    
    // Send configuration to MIPI TX
    // Wait for end of MIPI TX configuration
    while (bfm_axil_end_s == 1'b0) begin  
        if (bfm_axil_busy_s == 1'b0) begin 
          bfm_axil_run_step_s = 1'b1;
        end else begin
          bfm_axil_run_step_s = 1'b0;
        end
        @(posedge core_clk_s);
    end
    
    // Enabling configuration of FPGA
    bfm_fpga_enable_s = 1'b1;
    wait (bfm_fpga_end_s == 1'b1);  
    bfm_fpga_enable_s = 1'b0;    
    
    // Wait for MIPI RX init to be done 
    wait (`MIPI_RX_INIT_DONE_BIT == 1'b1);
    
    // Enable TX BFM
    bfm_mipi_tx_enable_s = 1'b1; 
    
    // Request for data sent to MIPI TX from evt stream reader
    bfm_mipi_tx_sync_request_s = 1'b1;
    wait (bfm_mipi_tx_sync_ack_s == 1'b1);
    bfm_mipi_tx_sync_request_s = 1'b0;   
    
    // Wait for end of file (input events from MIPI TX)
    wait (bfm_mipi_tx_eof_s == 1'b1);   
    
    // Wait for DMA to finish receiving and writting into DDR
    // Reading the 7th 32-bits word from the first Buffer Descriptor to get the Status
    // Get the packet length to match automatically to read_data
    `ZYNQ_VIP_0.read_data(`ps_host_if_base_addr + `packet_length, 8'h4, read_data, resp);
    `ZYNQ_VIP_0.wait_mem_update(`status, (32'h8c000000 | (read_data << 3)), read_data);
    $display("addr: 0x%04X, data: 0x%08X", `status, read_data);
    $display("Number of bytes transfered: %d", read_data[25:0]);
    
    // Write data from DDR memory to file for further verifications
    `ZYNQ_VIP_0.peek_mem_to_file(OUT_MEM_FILE_PATH_G, 32'h00010000, read_data[25:0]);

    $display("End of Test with Success"); 
    dma_received_data_finished = 1'b1;
      
    $finish;

end

    assign temp_clk = tb_ACLK;
    assign temp_rstn = tb_ARESETn;
        
        
    kria_generic_top_wrapper kria_generic_top_wrapper(
       ccam5_csi_rx_clk_n,
       ccam5_csi_rx_clk_p,
       ccam5_csi_rx_data_n,
       ccam5_csi_rx_data_p,
       ccam5_i2c_scl_io,
       ccam5_i2c_sda_io,
       fan_en_b,
       gpio_generic_tri_o
    );
    
    clk_rst_bfm #(100e6)
    clk_rst_bfm_u(
        core_clk_s, 
        core_arst_n_s, 
        core_srst_s, 
        mipi_tx_hs_clk_s, 
        mipi_tx_hs_arst_n_s, 
        mipi_tx_hs_srst_s, 
        mipi_tx_hs_clk90_s, 
        mipi_rx_dphy_clk_s,   
        mipi_rx_dphy_arst_n_s,
        mipi_rx_dphy_srst_s 
    );
    
    zynq_fpga_bfm #(.FILE_PATH(AXIL_FPGA_PATTERN_FILE_G)) 
    zynq_fpga_bfm_u(
        .clk                (core_clk_s),
        .rst                (core_srst_s),
        .enable_i           (bfm_fpga_enable_s),
        .end_of_file_o      (bfm_fpga_end_s)
    );
    
    assign in_ready_s = `AXI_DMA_READY;
    assign in_valid_s = `AXI_DMA_VALID;
    assign in_data_s  = `AXI_DMA_DATA;
    
    assign clk_axi_dma_s2mm_s = `AXI_DMA_CLK;
    
    evt_record_generic #(.CHECKER_NAME_G("AXI_DMA_CHECKER_OUT"), .PATTERN_FILE_G(REF_DATA_FILE_PATH_G), .MSG_EVT_NB_MOD_G(256))
    axi_dma_evt_record_u(
        .clk                (clk_axi_dma_s2mm_s),
        .stat_error_o       (axi_dma_record_err_s),
        .stat_end_o         (axi_dma_record_end_s),
        .in_ready_o         (),
        .in_valid_i         (in_valid_s & in_ready_s),
        .in_data_i          (in_data_s)
    );
    
    mipi_tx_sim_bfm #(
        .EVT_FORMAT_G               (0),          
        .AXIL_MASTER_PATTERN_FILE_G (AXIL_MIPI_TX_PATTERN_FILE_G),
        .IN_DATA_FILE_PATH_G        (IN_DATA_FILE_PATH_G),
        .BUS_ADDR_WIDTH_G           (32),
        .BUS_DATA_WIDTH_G           (32)
    )
    mipi_tx_sim_bfm_u(
        .clk                        (core_clk_s),
        .arst_n                     (core_arst_n_s),
        .srst                       (core_srst_s),
        .hs_clk                     (mipi_tx_hs_clk_s),
        .hs_arst_n                  (mipi_tx_hs_arst_n_s),
        .hs_srst                    (mipi_tx_hs_srst_s),
        .bfm_mipi_tx_enable_i       (bfm_mipi_tx_enable_s),
        .bfm_mipi_tx_eof_o          (bfm_mipi_tx_eof_s),   
        .bfm_mipi_tx_sync_request_i (bfm_mipi_tx_sync_request_s),
        .bfm_mipi_tx_sync_ack_o     (bfm_mipi_tx_sync_ack_s), 
        .bfm_axil_run_step_i        (bfm_axil_run_step_s),
        .bfm_axil_busy_o            (bfm_axil_busy_s),
        .bfm_axil_end_o             (bfm_axil_end_s),     
        .mipi_tx_hs_clk_o           ({ccam5_csi_rx_clk_p, ccam5_csi_rx_clk_n}),
        .mipi_tx_hs_d1_o            ({ccam5_csi_rx_data_p[1], ccam5_csi_rx_data_n[1]}),
        .mipi_tx_hs_d0_o            ({ccam5_csi_rx_data_p[0], ccam5_csi_rx_data_n[0]}),
        .mipi_tx_lp_clk_o           (),
        .mipi_tx_lp_d1_o            (),
        .mipi_tx_lp_d0_o            ()
    );
     

endmodule
