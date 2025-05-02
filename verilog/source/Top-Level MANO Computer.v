module MANO_Computer(
    input clk,
    input reset,
    output [7:0] segment,
    output [3:0] digit_select
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
    wire io_write;
    wire [11:0] address_bus;

    ProgramCounter pc(.*);
    Memory memory(.*);
    InstructionRegister ir(.*);
    Accumulator ac(.*);
    DataRegister dr(.*);
    ExtendedAccumulator e(.*);
    ALU alu(.*);
    DisplayOutput display(.*);
    ControlUnit cu(.*);

    assign ir.instruction_in = mem_data_out;
    assign ac.data_in = alu_out;
    assign ac.load = ac_load;
    assign dr.data_in = mem_data_out;
    assign e.data_in = alu_e_out;
    assign alu.a = ac_out;
    assign alu.b = dr_out;
    assign alu.e_in = e_reg;
    assign memory.address = address_bus;
    assign memory.data_in = ac_out;
    assign display.io_write = io_write;
    assign display.data_in = ac_out;
    assign cu.ir = ir_out;
    assign cu.zero_flag = zero_flag;
    assign cu.sign_flag = sign_flag;
endmodule
