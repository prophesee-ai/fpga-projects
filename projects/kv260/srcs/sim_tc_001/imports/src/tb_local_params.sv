//////////////////////////////////////////////////////////////////////////////////
// Company:        Prophesee
// Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
//
// Create Date:    Sept. 18, 2023
// Design Name:    tb_local_params
// Module Name:    
// Project Name:   kv260
// Target Devices: Zynq Ultrascale
// Tool versions:  Vivado 2022.2
// Description:    local param in system verilog for top test bench
//////////////////////////////////////////////////////////////////////////////////
// Define here access to Zynq VIP instance
`define ZYNQ_VIP_0 test_bench.kv260_top_wrapper.kv260_top_i.zynq_processing_system.inst
// Define AXI DMA signals for sniffing data to S2MM (Stream to Memory map)
`define AXI_DMA_CLK   test_bench.kv260_top_wrapper.kv260_top_i.zynq_processing_system_pl_clk0
`define AXI_DMA_READY test_bench.kv260_top_wrapper.kv260_top_i.S01_AXI_1_WREADY
`define AXI_DMA_VALID test_bench.kv260_top_wrapper.kv260_top_i.S01_AXI_1_WVALID
`define AXI_DMA_DATA  test_bench.kv260_top_wrapper.kv260_top_i.S01_AXI_1_WDATA
// Define bit of init done for MIPI RX
`define MIPI_RX_INIT_DONE_BIT test_bench.kv260_top_wrapper.kv260_top_i.mipi_csi2_rx_subsyst_0.U0.phy.init_done

`define axi_bram_ctrl_base_addr 32'hA0000000
`define mipi_csi2_rx_base_addr  32'hA0010000
`define axi_gpio_base_addr      32'hA0020000
`define ps_host_if_base_addr    32'hA0030000
`define axi_dma_base_addr       32'hA1000000
`define axi_iic_base_addr       32'hA1010000

/// AXI DMA ///
/// S2MM    ///
`define s2mm_dmacr              32'h00000030
`define s2mm_dmasr              32'h00000034
`define s2mm_curdesc            32'h00000038
`define s2mm_curdesc_msb        32'h0000003C
`define s2mm_taildesc           32'h00000040
`define s2mm_taildesc_msb       32'h00000044

/// PS HOST IF ///
`define  packet_length          32'h00000008

/// Buffer Descriptor ///
`define nxtdesc                 32'h00000000
`define nxtdesc_msb             32'h00000004
`define buffer_address          32'h00000008
`define buffer_address_msb      32'h0000000C
`define control                 32'h00000018
`define status                  32'h0000001C