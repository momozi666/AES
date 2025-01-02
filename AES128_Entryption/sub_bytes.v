`timescale 1ns / 1ps

module SUB_BYTES(//字节代换，用到S盒的模块，替换16个字节
    input clk,
    input [127:0] IN_DATA,
    output reg [127:0] SB_DATA
);

wire [127:0] SB_DATA_W;

genvar i;
generate
    for (i=0; i<16;i=i+1)begin:INST
        FORWARD_SUBSTITUTION_BOX TEST(
            .clk(clk),
            .A(IN_DATA[i*8+:8]),
            .C(SB_DATA_W[i*8+:8])
        );
        
    end
endgenerate

  always @(*) begin
        SB_DATA = SB_DATA_W;
    end

endmodule