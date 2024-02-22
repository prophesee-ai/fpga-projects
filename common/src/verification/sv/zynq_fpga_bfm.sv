//////////////////////////////////////////////////////////////////////////////////
// Company:        Prophesee
// Engineer:       Ladislas ROBIN (lrobin@prophesee.ai)
//
// Create Date:    Sept. 26, 2023
// Design Name:    zynq_fpga_bfm
// Module Name:    
// Project Name:   kria_generic
// Target Devices: Zynq Ultrascale
// Tool versions:  Vivado 2022.2
// Description:    BFM for Zynq processing part: Take a file and apply to internal
//                 AXIL bus to FPGA PL
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`include "tb_local_params.sv"

module zynq_fpga_bfm #(
    parameter string FILE_PATH = "input.txt", string WHOIAM_G = "Zynq FPGA BFM") 
    (
    input logic clk,
    input logic rst,
    input logic enable_i,
    output logic end_of_file_o
);

    // File handle and other variables
    int file_handle;
    string action, line;
    reg [31:0] addr, data, resp_data;
    int delay, halt, check_mask;
    
    int nargs, length, n_lines = 0;
    reg resp;
    
    reg end_of_file_s = 1'b0;

    // Module states
    typedef enum logic [2:0] {
        STATE_IDLE = 3'b000,
        STATE_READ_FILE = 3'b001
        // Add more states as needed
    } state_type;

    state_type state, next_state;
    
    // async assign
    assign end_of_file_o = end_of_file_s;
    
    initial
    begin
        while(end_of_file_o == 1'b0) begin
            @(posedge clk);
            if (state == STATE_READ_FILE) begin
                if (!$feof(file_handle)) begin
                    // Read a line from the file
                    $fgets(line, file_handle);
                    n_lines = n_lines + 1;
                    case (line[0])
                        "W": begin
                            nargs=$sscanf(line, "%s %h %h %d %d", action, addr, data, delay, halt);
                            case(nargs)
                                3:begin
                                    $display("%s: Write @ %08h : %08h", WHOIAM_G, addr, data);                                    
                                    delay = 0;
                                    halt = 0;
                                end
                                4:begin
                                    $display("%s: Write @ %08h : %08h / delay: %d", WHOIAM_G, addr, data, delay); 
                                    halt = 0;
                                end
                                5:begin
                                    $display("%s: Write @ %08h : %08h / delay: %d / halt: %d", WHOIAM_G, addr, data, delay, halt); 
                                end
                            endcase
                            while(delay > 0) begin
                                #1
                                delay = delay - 1;
                            end
                            `ZYNQ_VIP_0.write_data(addr, 8'h4, data, resp);
                            while(halt > 0) begin
                                #1
                                halt = halt - 1;
                            end
                            
                        end
                        "R": begin
                            delay = 0;
                            halt = 0;
                            check_mask = 0;
                            $sscanf(line, "%s %h %h %d %d %h", action, addr, data, delay, halt, check_mask);
                            $display("%s: Read @ %08h : %08h / delay: %d / halt: %d / Check Mask: %08h", WHOIAM_G, addr, data, delay, halt, check_mask);
                            while(delay > 0) begin
                                #1
                                delay = delay - 1;
                            end
                            `ZYNQ_VIP_0.read_data(addr, 8'h4, resp_data, resp);
                            while(halt > 0) begin
                                #1
                                halt = halt - 1;
                            end
                            if ((resp_data & check_mask) != (data & check_mask)) begin
                                $display("%s: ERROR at line %d: output read differs from expected: @0x%08h => 0x%08h /= 0x%08h (check_mask: %08h, read_data: %08h, exp_data: %08h", WHOIAM_G, n_lines, 
                                                                                                                                                                                    addr, 
                                                                                                                                                                                    (resp_data & check_mask), 
                                                                                                                                                                                    (data & check_mask),
                                                                                                                                                                                    check_mask,
                                                                                                                                                                                    resp_data,
                                                                                                                                                                                    data);
                                $finish; 
                            end
                        end
                        "C": begin
                            length=line.len();
                            $display("%s: %s", WHOIAM_G, line.substr(2, length-2));    
                        end
                        "E": begin
                            end_of_file_s = 1'b1;
                            $display("%s: End of file %s", WHOIAM_G, FILE_PATH); 
                        end                    
                        default: begin
                            //Do Nothing
                        end
                    endcase
                end else begin
                    // End of file reached
                    end_of_file_s = 1'b1;
                end
            end
        end
    end

    // State transition logic
    always_ff @(posedge clk) begin
        state <= next_state;
        case (state)
            STATE_IDLE: begin
                if (!rst) begin
                    file_handle = $fopen(FILE_PATH, "r");
                    if (file_handle) begin
                        if (enable_i == 1'b1) begin
                            next_state = STATE_READ_FILE;
                        end
                    end else begin
                        $display("%s: Error: Could not open the file.", WHOIAM_G);
                        next_state = STATE_IDLE;
                    end
                end
            end
            STATE_READ_FILE: begin
                next_state = STATE_READ_FILE;
            end
            // Add more cases for other states as needed
            default: begin
                next_state = STATE_IDLE;
            end
        endcase
    end

    // File handling cleanup
    always_ff @(posedge clk) begin
        if (rst) begin
            if (file_handle != 0) begin
                $fclose(file_handle);
            end
        end
    end

endmodule