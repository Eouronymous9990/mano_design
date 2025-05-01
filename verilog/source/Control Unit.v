module ControlUnit(
    input clk,
    input reset,
    input [15:0] ir,
    input zero_flag,
    input sign_flag,
    input keyboard_interrupt,
    output reg pc_load,
    output reg pc_inc,
    output reg ir_load,
    output reg ac_load,
    output reg dr_load,
    output reg e_load,
    output reg mem_read,
    output reg mem_write,
    output reg [2:0] alu_op,
    output reg io_read,
    output reg io_write,
    output reg [11:0] address_bus
);
    // Instruction opcodes
    localparam AND   = 4'b0000;
    localparam ADD   = 4'b0001;
    localparam LDA   = 4'b0010;
    localparam STA   = 4'b0011;
    localparam BUN   = 4'b0100;
    localparam BSA   = 4'b0101;
    localparam ISZ   = 4'b0110;
    localparam INP   = 16'hF800;
    localparam OUT   = 16'hF400;
    
    reg [3:0] state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 4'b0000;
            pc_load <= 0;
            pc_inc <= 0;
            ir_load <= 0;
            ac_load <= 0;
            dr_load <= 0;
            e_load <= 0;
            mem_read <= 0;
            mem_write <= 0;
            io_read <= 0;
            io_write <= 0;
            alu_op <= 3'b000;
            address_bus <= 12'b0;
        end
        else begin
            // Default control signals
            pc_load <= 0;
            pc_inc <= 0;
            ir_load <= 0;
            ac_load <= 0;
            dr_load <= 0;
            e_load <= 0;
            mem_read <= 0;
            mem_write <= 0;
            io_read <= 0;
            io_write <= 0;
            
            case(state)
                4'b0000: begin // Fetch instruction
                    if (keyboard_interrupt) begin
                        io_read <= 1;
                        ac_load <= 1;
                    end
                    else begin
                        mem_read <= 1;
                        address_bus <= pc_out;
                        state <= 4'b0001;
                    end
                end
                
                4'b0001: begin // Load instruction
                    ir_load <= 1;
                    state <= 4'b0010;
                end
                
                4'b0010: begin // Decode instruction
                    ir_load <= 0;
                    pc_inc <= 1;
                    
                    case(ir[15:12])
                        AND, ADD, LDA, STA, BUN, BSA, ISZ: begin
                            mem_read <= 1;
                            address_bus <= ir[11:0];
                            state <= 4'b0011;
                        end
                        default: begin
                            if (ir == INP) begin
                                io_read <= 1;
                                ac_load <= 1;
                            end
                            else if (ir == OUT) begin
                                io_write <= 1;
                            end
                            state <= 4'b0000;
                        end
                    endcase
                end
                
                4'b0011: begin // Execute memory reference
                    case(ir[15:12])
                        AND: begin ac_load <= 1; alu_op <= 3'b010; end
                        ADD: begin ac_load <= 1; alu_op <= 3'b000; end
                        LDA: begin ac_load <= 1; end
                        STA: begin mem_write <= 1; end
                        BUN: begin pc_load <= 1; address_bus <= ir[11:0]; end
                        BSA: begin 
                            mem_write <= 1; 
                            state <= 4'b0100;
                        end
                        ISZ: begin 
                            dr_load <= 1; 
                            state <= 4'b0101;
                        end
                    endcase
                    if (ir[15:12] != BSA && ir[15:12] != ISZ)
                        state <= 4'b0000;
                end
                
                4'b0100: begin // BSA continuation
                    mem_write <= 0;
                    pc_load <= 1;
                    address_bus <= ir[11:0] + 1;
                    state <= 4'b0000;
                end
                
                4'b0101: begin // ISZ continuation
                    dr_load <= 0;
                    mem_write <= 1;
                    if (~zero_flag) pc_inc <= 1;
                    state <= 4'b0000;
                end
            endcase
        end
    end
endmodule