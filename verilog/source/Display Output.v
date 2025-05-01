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
    reg [3:0] current_digit;
    
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
            2'b00: current_digit = display_buffer[3:0];
            2'b01: current_digit = display_buffer[7:4];
            2'b10: current_digit = display_buffer[11:8];
            2'b11: current_digit = display_buffer[15:12];
        endcase
        
        case(digit_counter)
            2'b00: digit_select = 4'b1110;
            2'b01: digit_select = 4'b1101;
            2'b10: digit_select = 4'b1011;
            2'b11: digit_select = 4'b0111;
        endcase
        
        case(current_digit)
            4'h0: segment = 8'b11000000;
            4'h1: segment = 8'b11111001;
            4'h2: segment = 8'b10100100;
            4'h3: segment = 8'b10110000;
            4'h4: segment = 8'b10011001;
            4'h5: segment = 8'b10010010;
            4'h6: segment = 8'b10000010;
            4'h7: segment = 8'b11111000;
            4'h8: segment = 8'b10000000;
            4'h9: segment = 8'b10010000;
            4'hA: segment = 8'b10001000;
            4'hB: segment = 8'b10000011;
            4'hC: segment = 8'b11000110;
            4'hD: segment = 8'b10100001;
            4'hE: segment = 8'b10000110;
            4'hF: segment = 8'b10001110;
            default: segment = 8'b11111111;
        endcase
    end
endmodule