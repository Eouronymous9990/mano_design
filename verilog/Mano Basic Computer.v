module ProgramCounter(
    input clk,
    input reset,
    input load,
    input inc,
    input [11:0] in,
    output reg [11:0] out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 12'b0;
        else if (load)
            out <= in;
        else if (inc)
            out <= out + 1;
    end
endmodule

module Memory(
    input clk,
    input read,
    input write,
    input [11:0] address,
    input [15:0] data_in,
    output reg [15:0] data_out
);
    reg [15:0] mem [0:4095];
    initial begin
        for (integer i = 0; i < 4096; i = i + 1)
            mem[i] = 16'b0;
    end
    always @(posedge clk) begin
        if (write)
            mem[address] <= data_in;
        if (read)
            data_out <= mem[address];
    end
endmodule

module InstructionRegister(
    input clk,
    input load,
    input [15:0] in,
    output reg [15:0] out
);
    always @(posedge clk) begin
        if (load)
            out <= in;
    end
endmodule

module Accumulator(
    input clk,
    input reset,
    input load,
    input [15:0] in,
    output reg [15:0] out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 16'b0;
        else if (load)
            out <= in;
    end
endmodule

module DataRegister(
    input clk,
    input reset,
    input load,
    input [15:0] in,
    output reg [15:0] out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 16'b0;
        else if (load)
            out <= in;
    end
endmodule

module ExtendedAccumulator(
    input clk,
    input reset,
    input load,
    input in,
    output reg out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 1'b0;
        else if (load)
            out <= in;
    end
endmodule

module ALU(
    input [15:0] a,
    input [15:0] b,
    input e_in,
    input [2:0] op,
    output reg [15:0] out,
    output reg e_out,
    output reg zero_flag,
    output reg sign_flag
);
    always @(*) begin
        case(op)
            3'b000: {e_out, out} = {1'b0, a} + {1'b0, b};
            3'b001: {e_out, out} = {1'b0, a} - {1'b0, b};
            3'b010: begin out = a & b; e_out = e_in; end
            3'b011: begin out = a | b; e_out = e_in; end
            3'b100: begin out = a ^ b; e_out = e_in; end
            3'b101: begin out = ~a; e_out = e_in; end
            3'b110: begin out = {e_in, a[15:1]}; e_out = a[0]; end
            3'b111: begin out = {a[14:0], e_in}; e_out = a[15]; end
            default: begin out = 16'b0; e_out = e_in; end
        endcase
        zero_flag = (out == 16'b0);
        sign_flag = out[15];
    end
endmodule

module ControlUnit(
    input clk,
    input reset,
    input [15:0] ir,
    input zero_flag,
    input sign_flag,
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
    output reg [11:0] address_bus
);
    localparam AND = 4'b0000;
    localparam ADD = 4'b0001;
    localparam LDA = 4'b0010;
    localparam STA = 4'b0011;
    localparam BUN = 4'b0100;
    localparam BSA = 4'b0101;
    localparam ISZ = 4'b0110;
    localparam INP = 16'hF800;
    localparam OUT = 16'hF400;
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
            alu_op <= 3'b000;
            address_bus <= 12'b0;
        end
        else begin
            pc_load <= 0;
            pc_inc <= 0;
            ir_load <= 0;
            ac_load <= 0;
            dr_load <= 0;
            e_load <= 0;
            mem_read <= 0;
            mem_write <= 0;
            io_read <= 0;
            case(state)
                4'b0000: begin
                    mem_read <= 1;
                    address_bus <= pc_out;
                    state <= 4'b0001;
                end
                4'b0001: begin
                    ir_load <= 1;
                    state <= 4'b0010;
                end
                4'b0010: begin
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
                            state <= 4'b0000;
                        end
                    endcase
                end
                4'b0011: begin
                    case(ir[15:12])
                        AND: begin ac_load <= 1; alu_op <= 3'b010; end
                        ADD: begin ac_load <= 1; alu_op <= 3'b000; end
                        LDA: begin ac_load <= 1; end
                        STA: begin mem_write <= 1; end
                        BUN: begin pc_load <= 1; address_bus <= ir[11:0]; end
                        BSA: begin mem_write <= 1; address_bus <= ir[11:0]; state <= 4'b0100; end
                        ISZ: begin dr_load <= 1; alu_op <= 3'b000; state <= 4'b0101; end
                    endcase
                    if (ir[15:12] != BSA && ir[15:12] != ISZ)
                        state <= 4'b0000;
                end
                4'b0100: begin
                    mem_write <= 0;
                    pc_load <= 1;
                    address_bus <= ir[11:0] + 1;
                    state <= 4'b0000;
                end
                4'b0101: begin
                    dr_load <= 0;
                    mem_write <= 1;
                    if (~zero_flag) pc_inc <= 1;
                    state <= 4'b0000;
                end
                default: state <= 4'b0000;
            endcase
        end
    end
endmodule

module MANO_Computer(
    input clk,
    input reset
);
    wire [11:0] pc_out;
    wire [15:0] mem_data_out;
    wire [15:0] ir_out;
    wire [15:0] ac_out;
    wire [15:0] dr_out;
    wire [15:0] alu_out;
    wire alu_e_out;
    wire zero_flag;
    wire sign_flag;
    wire e_reg;
    wire pc_load;
    wire pc_inc;
    wire ir_load;
    wire ac_load;
    wire dr_load;
    wire e_load;
    wire mem_read;
    wire mem_write;
    wire [2:0] alu_op;
    wire io_read;
    wire [11:0] address_bus;
    ProgramCounter pc(
        .clk(clk),
        .reset(reset),
        .load(pc_load),
        .inc(pc_inc),
        .in(address_bus),
        .out(pc_out)
    );
    Memory memory(
        .clk(clk),
        .read(mem_read),
        .write(mem_write),
        .address(address_bus),
        .data_in(ac_out),
        .data_out(mem_data_out)
    );
    InstructionRegister ir(
        .clk(clk),
        .load(ir_load),
        .in(mem_data_out),
        .out(ir_out)
    );
    Accumulator ac(
        .clk(clk),
        .reset(reset),
        .load(ac_load),
        .in(alu_out),
        .out(ac_out)
    );
    DataRegister dr(
        .clk(clk),
        .reset(reset),
        .load(dr_load),
        .in(mem_data_out),
        .out(dr_out)
    );
    ExtendedAccumulator e(
        .clk(clk),
        .reset(reset),
        .load(e_load),
        .in(alu_e_out),
        .out(e_reg)
    );
    ALU alu(
        .a(ac_out),
        .b(dr_out),
        .e_in(e_reg),
        .op(alu_op),
        .out(alu_out),
        .e_out(alu_e_out),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag)
    );
    ControlUnit cu(
        .clk(clk),
        .reset(reset),
        .ir(ir_out),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .pc_load(pc_load),
        .pc_inc(pc_inc),
        .ir_load(ir_load),
        .ac_load(ac_load),
        .dr_load(dr_load),
        .e_load(e_load),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_op(alu_op),
        .io_read(io_read),
        .address_bus(address_bus)
    );
endmodule
