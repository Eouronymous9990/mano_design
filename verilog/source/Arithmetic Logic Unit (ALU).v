module ALU(
    input [15:0] a,
    input [15:0] b,
    input e_in,
    input [2:0] op,
    output reg [15:0] result,
    output reg e_out,
    output reg zero_flag,
    output reg sign_flag
);
    always @(*) begin
        case(op)
            3'b000: {e_out, result} = {1'b0, a} + {1'b0, b}; // ADD
            3'b001: {e_out, result} = {1'b0, a} - {1'b0, b}; // SUB
            3'b010: begin result = a & b; e_out = e_in; end   // AND
            3'b011: begin result = a | b; e_out = e_in; end   // OR
            3'b100: begin result = a ^ b; e_out = e_in; end   // XOR
            3'b101: begin result = ~a; e_out = e_in; end      // NOT
            3'b110: begin result = {e_in, a[15:1]}; e_out = a[0]; end // CIR
            3'b111: begin result = {a[14:0], e_in}; e_out = a[15]; end // CIL
            default: begin result = 16'b0; e_out = e_in; end
        endcase
        
        zero_flag = (result == 16'b0);
        sign_flag = result[15];
    end
endmodule