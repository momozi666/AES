module AES128(
    input clk,
    input reset,
    input [127:0] IN_DATA,

    input [127:0] IN_KEY,

    output [127:0] OUT_DATA
);


reg [127:0] R0_OUT_DATA, KEY;
wire [127:0] R_OUT_DATA[0:9];

wire [127:0] OUT_KEYW[0:10];
wire [127:0] OUT_KEYR[0:9];

always @(posedge clk) begin//初始轮钥密加
    R0_OUT_DATA<=IN_DATA^IN_KEY;
    KEY <= IN_KEY;
end
assign R_OUT_DATA[0]=R0_OUT_DATA;
assign OUT_KEYW[0]=KEY;
genvar j;
generate
    for (j=0;j<10 ;j=j+1 ) begin:K
        GENERATE_KEY K_inst(
            .clk(clk),
            .ROUND_KEY(j[3:0]),
            .IN_KEY(OUT_KEYW[j]),
            .OUT_KEY(OUT_KEYW[j+1]),
            .OUT_KEY_R(OUT_KEYR[j])
        );
    end
endgenerate

genvar i;
generate
    for (i=0; i<9; i=i+1) begin:R
        ROUND_ITERATION R_inst(
            .clk(clk),
            .IN_DATA(R_OUT_DATA[i]),
            .IN_KEY(OUT_KEYR[i]),
            .OUT_DATA(R_OUT_DATA[i+1])
        );
    end
endgenerate

LAST_ROUND R10(.clk(clk), 
                .IN_DATA(R_OUT_DATA[9]),
                .IN_KEY(OUT_KEYR[9]),
                .OUT_DATA(OUT_DATA));


endmodule