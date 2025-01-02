`timescale 1ns / 1ps

module LAST_ROUND(//最后一轮，没有列混合，只有字节代换和行移位
    input clk, 
    input [127:0] IN_DATA, 
    input [127:0] IN_KEY, 
    output reg [127:0] OUT_DATA
);

wire [127:0] SB_DATA, SHIFT_DATA, OUT_KEY;

SUB_BYTES SB(.clk(clk), .IN_DATA(IN_DATA), .SB_DATA(SB_DATA));
SHIFT_ROWS SR(.clk(clk), .IN_DATA(SB_DATA), .SHIFT_DATA(SHIFT_DATA));

always @(posedge clk) OUT_DATA <= IN_KEY ^ SHIFT_DATA;

endmodule