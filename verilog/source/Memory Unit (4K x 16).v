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