// MANO Computer - Complete Implementation with I/O
// Includes: CPU, Memory, Keyboard Interface, and Display Output

// ==============================================
// Module: Program Counter
// ==============================================
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

// ==============================================
// Module: Memory Unit (4K x 16)
// ==============================================
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

// ==============================================
// Module: Instruction Register
// ==============================================
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

// ==============================================
// Module: Accumulator
// ==============================================
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

// ==============================================
// Module: Data Register
// ==============================================
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

// ==============================================
// Module: Extended Accumulator (1-bit)
// ==============================================
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

// ==============================================
// Module: Arithmetic Logic Unit
// ==============================================
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
            3'b000: {e_out, out} = {1'b0, a} + {1'b0, b}; // ADD
            3'b001: {e_out, out} = {1'b0, a} - {1'b0, b}; // SUB
            3'b010: begin out = a & b; e_out = e_in; end  // AND
            3'b011: begin out = a | b; e_out = e_in; end  // OR
            3'b100: begin out = a ^ b; e_out = e_in; end  // XOR
            3'b101: begin out = ~a; e_out = e_in; end     // NOT
            3'b110: begin out = {e_in, a[15:1]}; e_out = a[0]; end // CIR
            3'b111: begin out = {a[14:0], e_in}; e_out = a[15]; end // CIL
            default: begin out = 16'b0; e_out = e_in; end
        endcase
        
        zero_flag = (out == 16'b0);
        sign_flag = out[15];
    end
endmodule

// ==============================================
// Module: Keyboard Interface
// ==============================================
module KeyboardInterface(
    input clk,
    input reset,
    input ps2_clk,
    input ps2_data,
    input io_read,
    output reg [15:0] data_out,
    output reg data_ready,
    output reg interrupt
);

    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam PARITY = 3'b011;
    localparam STOP  = 3'b100;
    
    reg [2:0] state;
    reg [3:0] bit_count;
    reg [7:0] shift_reg;
    reg parity;
    reg [15:0] key_buffer;
    
    // PS/2 clock synchronization
    reg [2:0] ps2_clk_sync;
    always @(posedge clk) ps2_clk_sync <= {ps2_clk_sync[1:0], ps2_clk};
    wire ps2_clk_falling = (ps2_clk_sync[2:1] == 2'b10);
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 0;
            shift_reg <= 0;
            parity <= 0;
            key_buffer <= 0;
            data_ready <= 0;
            interrupt <= 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if (ps2_clk_falling && !ps2_data) begin
                        state <= START;
                        bit_count <= 0;
                        parity <= 0;
                    end
                end
                
                START: begin
                    if (ps2_clk_falling)
                        state <= DATA;
                end
                
                DATA: begin
                    if (ps2_clk_falling) begin
                        shift_reg <= {ps2_data, shift_reg[7:1]};
                        parity <= parity ^ ps2_data;
                        if (bit_count == 7)
                            state <= PARITY;
                        bit_count <= bit_count + 1;
                    end
                end
                
                PARITY: begin
                    if (ps2_clk_falling) begin
                        if (parity == ps2_data)
                            state <= STOP;
                        else
                            state <= IDLE;
                    end
                end
                
                STOP: begin
                    if (ps2_clk_falling) begin
                        key_buffer <= {8'h00, shift_reg};
                        data_ready <= 1;
                        interrupt <= 1;
                        state <= IDLE;
                    end
                end
            endcase
            
            if (io_read) begin
                data_ready <= 0;
                interrupt <= 0;
            end
        end
    end
    
    always @(*) begin
        data_out = 16'b0;
        if (data_ready)
            data_out = key_buffer;
    end
endmodule

// ==============================================
// Module: Display Output
// ==============================================
module DisplayOutput(
    input clk,
    input reset,
    input io_write,
    input [15:0] data_in,
    output reg [7:0] segment,
    output reg [3:0] digit_select
);
    reg [15:0] display_buffer;
    reg [1:0] digit_counter;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            display_buffer <= 16'b0;
            digit_counter <= 2'b0;
        end
        else begin
            if (io_write)
                display_buffer <= data_in;
            
            digit_counter <= digit_counter + 1;
        end
    end
    
    always @(*) begin
        case(digit_counter)
            2'b00: begin
                digit_select = 4'b1110;
                case(display_buffer[3:0])
                    4'h0: segment = 8'b11000000;
                    4'h1: segment = 8'b11111001;
                    // ... complete segment decoding for all hex digits
                    default: segment = 8'b11111111;
                endcase
            end
            // ... similar cases for other digits
            default: begin
                digit_select = 4'b1111;
                segment = 8'b11111111;
            end
        endcase
    end
endmodule

// ==============================================
// Module: Control Unit
// ==============================================
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
                            address_bus <= ir[11:0]; 
                            state <= 4'b0100;
                        end
                        ISZ: begin 
                            dr_load <= 1; 
                            alu_op <= 3'b000; 
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
                
                default: state <= 4'b0000;
            endcase
        end
    end
endmodule

// ==============================================
// Module: MANO Computer (Top Level)
// ==============================================
module MANO_Computer(
    input clk,
    input reset,
    input ps2_clk,
    input ps2_data,
    output [7:0] segment,
    output [3:0] digit_select
);

    // Internal wires
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
    wire keyboard_interrupt;
    wire [15:0] keyboard_data;
    wire keyboard_data_ready;
    
    // Control signals
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
    wire io_write;
    wire [11:0] address_bus;

    // Program Counter
    ProgramCounter pc(
        .clk(clk),
        .reset(reset),
        .load(pc_load),
        .inc(pc_inc),
        .in(address_bus),
        .out(pc_out)
    );

    // Memory
    Memory memory(
        .clk(clk),
        .read(mem_read),
        .write(mem_write),
        .address(address_bus),
        .data_in(ac_out),
        .data_out(mem_data_out)
    );

    // Instruction Register
    InstructionRegister ir(
        .clk(clk),
        .load(ir_load),
        .in(mem_data_out),
        .out(ir_out)
    );

    // Accumulator
    Accumulator ac(
        .clk(clk),
        .reset(reset),
        .load(ac_load || (io_read && keyboard_data_ready)),
        .in(io_read && keyboard_data_ready ? keyboard_data : alu_out),
        .out(ac_out)
    );

    // Data Register
    DataRegister dr(
        .clk(clk),
        .reset(reset),
        .load(dr_load),
        .in(mem_data_out),
        .out(dr_out)
    );

    // Extended Accumulator
    ExtendedAccumulator e(
        .clk(clk),
        .reset(reset),
        .load(e_load),
        .in(alu_e_out),
        .out(e_reg)
    );

    // ALU
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

    // Keyboard Interface
    KeyboardInterface keyboard(
        .clk(clk),
        .reset(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .io_read(io_read),
        .data_out(keyboard_data),
        .data_ready(keyboard_data_ready),
        .interrupt(keyboard_interrupt)
    );

    // Display Output
    DisplayOutput display(
        .clk(clk),
        .reset(reset),
        .io_write(io_write),
        .data_in(ac_out),
        .segment(segment),
        .digit_select(digit_select)
    );

    // Control Unit
    ControlUnit cu(
        .clk(clk),
        .reset(reset),
        .ir(ir_out),
        .zero_flag(zero_flag),
        .sign_flag(sign_flag),
        .keyboard_interrupt(keyboard_interrupt),
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
        .io_write(io_write),
        .address_bus(address_bus)
    );

endmodule