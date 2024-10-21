// Copyright (c) Prophesee S.A.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


// Define here access to Zynq VIP instance
`define ZYNQ_VIP_0 kv260_tb.kv260_v1_0_0.kv260_i.zynq_processing_system.inst

// Define AXI DMA signals for sniffing data to S2MM (Stream to Memory map)
`define AXI_DMA_CLK   kv260_tb.kv260_v1_0_0.kv260_i.zynq_processing_system_pl_clk0
`define AXI_DMA_READY kv260_tb.kv260_v1_0_0.kv260_i.S01_AXI_1_WREADY
`define AXI_DMA_VALID kv260_tb.kv260_v1_0_0.kv260_i.S01_AXI_1_WVALID
`define AXI_DMA_DATA  kv260_tb.kv260_v1_0_0.kv260_i.S01_AXI_1_WDATA

// Define bit of init done for MIPI RX
`define MIPI_RX_INIT_DONE_BIT kv260_tb.kv260_v1_0_0.kv260_i.mipi_csi2_rx_subsyst_0.U0.phy.init_done

`define axi_bram_ctrl_base_addr        32'hA0000000
`define mipi_csi2_rx_base_addr         32'hA0010000
`define axi_gpio_base_addr             32'hA0020000
`define ps_host_if_base_addr           32'hA0030000
`define axis_tkeep_handler_base_addr   32'hA0040000
`define event_stream_smart_t_base_addr 32'hA0050000
`define axi_dma_base_addr              32'hA1000000
`define axi_iic_base_addr              32'hA1010000

/// AXI DMA ///
/// S2MM    ///
`define s2mm_dmacr                     32'h00000030
`define s2mm_dmasr                     32'h00000034
`define s2mm_curdesc                   32'h00000038
`define s2mm_curdesc_msb               32'h0000003C
`define s2mm_taildesc                  32'h00000040
`define s2mm_taildesc_msb              32'h00000044

/// PS HOST IF ///
`define packet_length                  32'h00000014

/// Buffer Descriptor ///
`define nxtdesc                        32'h00000000
`define nxtdesc_msb                    32'h00000004
`define buffer_address                 32'h00000008
`define buffer_address_msb             32'h0000000C
`define control                        32'h00000018
`define status                         32'h0000001C
