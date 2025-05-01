module ProgramCounter(
    input clk,
    input reset,
    input load,
    input inc,
    input [11:0] new_addr,
    output reg [11:0] current_addr
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_addr <= 12'b0;
        else if (load)
            current_addr <= new_addr;
        else if (inc)
            current_addr <= current_addr + 1;
    end
endmodule