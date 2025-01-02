module AES128(
    input clk,
    input rstn,

    input valid_key_gen,
    input valid_round,
    input valid_out,

    input [127:0] IN_DATA,
    input [127:0] IN_KEY,
    output [127:0] OUT_DATA,

    // 测试每轮的密钥和加密后的数据，功能确认后可以删去
    output [127:0] round_key_0, // in_key
    output [127:0] round_key_1,
    output [127:0] round_key_2,
    output [127:0] round_key_3,
    output [127:0] round_key_4,
    output [127:0] round_key_5,
    output [127:0] round_key_6,
    output [127:0] round_key_7,
    output [127:0] round_key_8,
    output [127:0] round_key_9,
    output [127:0] round_key_10,

    output [127:0] round_data_0, // first output = in_data^in_key
    output [127:0] round_data_1,
    output [127:0] round_data_2,
    output [127:0] round_data_3,
    output [127:0] round_data_4,
    output [127:0] round_data_5,
    output [127:0] round_data_6,
    output [127:0] round_data_7,
    output [127:0] round_data_8,
    output [127:0] round_data_9,
    output [127:0] round_data_10 // out_data -> the correct encrypted text
);

reg [127:0] R0_OUT_DATA;
reg [127:0] ROUND_KEY [0:9];
reg [127:0] NEXT_KEY [0:10];
reg [127:0] ROUND_OUT_DATA [0:10];
always @(*) begin
    NEXT_KEY[0]=IN_KEY;
end
// // 生成密钥扩展组合逻辑
// generate
//     genvar i;
//     for (i = 0; i < 10; i = i + 1) begin : KEY_GEN
//         GENERATE_KEY K(
//             .ROUND_KEY(i),
//             .IN_KEY(NEXT_KEY[i]),
//             .OUT_KEY(NEXT_KEY[i+1])
//         );
//     end
// endgenerate
//用状态机实现密钥扩展,三段式
parameter IDLE =2'b00,GENERATING=2'b01,DONE=2'b10 ;
reg [1:0] current_state,next_state;
reg [3:0] i;
reg [127:0]in_key;
wire [127:0]out_key;
reg [3:0]round;
always @(posedge clk or posedge rstn) begin
    if(rstn)begin
        current_state<=IDLE;
    end
    else begin
        current_state<=next_state;
    end
end
always @(posedge clk or posedge rstn) begin
    if(rstn)next_state<=IDLE;
end
always @(posedge clk or posedge rstn) begin
    if(rstn)i<=0;
    else if(current_state==GENERATING)begin
        if(NEXT_KEY[i+1]&&i<10)i<=i+1;
    end
end
always @(*) begin
    case(current_state)
        IDLE:begin
            if(valid_key_gen&&i==0)begin
                next_state=GENERATING;
            end
            else next_state=IDLE;
        end
        GENERATING:begin
            if(i<10) begin
                next_state=GENERATING;
            end
            else begin
                next_state=DONE;
            end
        end
        DONE:begin
            next_state=IDLE;
        end
        default:next_state=next_state;
    endcase
end
//输出逻辑用case, if默认是有优先级的
always @(posedge clk or posedge rstn) begin
    case(current_state)
        GENERATING:
        if(i+1<11&&i+1>0)begin
        NEXT_KEY[i+1]=out_key;
        in_key=NEXT_KEY[i];
        round=i;
        end
    endcase
end
GENERATE_KEY K_inst(
    .ROUND_KEY(round),
    .IN_KEY(in_key),
    .OUT_KEY(out_key)
);


// 将 NEXT_KEY 赋值给 ROUND_KEY
always @(posedge clk or negedge rstn) begin
    if (rstn) begin
        ROUND_KEY[0] <= 128'b0;
        ROUND_KEY[1] <= 128'b0;
        ROUND_KEY[2] <= 128'b0;
        ROUND_KEY[3] <= 128'b0;
        ROUND_KEY[4] <= 128'b0;
        ROUND_KEY[5] <= 128'b0;
        ROUND_KEY[6] <= 128'b0;
        ROUND_KEY[7] <= 128'b0;
        ROUND_KEY[8] <= 128'b0;
        ROUND_KEY[9] <= 128'b0;
    end else if (valid_key_gen) begin
        ROUND_KEY[0] <= NEXT_KEY[1];
        ROUND_KEY[1] <= NEXT_KEY[2];
        ROUND_KEY[2] <= NEXT_KEY[3];
        ROUND_KEY[3] <= NEXT_KEY[4];
        ROUND_KEY[4] <= NEXT_KEY[5];
        ROUND_KEY[5] <= NEXT_KEY[6];
        ROUND_KEY[6] <= NEXT_KEY[7];
        ROUND_KEY[7] <= NEXT_KEY[8];
        ROUND_KEY[8] <= NEXT_KEY[9];
        ROUND_KEY[9] <= NEXT_KEY[10];
    end
end

always @(posedge clk or negedge rstn) begin
    if (rstn) begin
        R0_OUT_DATA <= 128'b0;
    end else if (valid_round) begin
        R0_OUT_DATA <= IN_DATA ^ IN_KEY;
    end
end
always @(*) begin
    ROUND_OUT_DATA[0]=R0_OUT_DATA;
end

// // 生成轮迭代
// generate
//     genvar j;
//     for (j = 0; j < 10; j = j + 1) begin : ROUND_ITER
//         if(j!=9)begin
//             ROUND_ITERATION R(
//                     .IN_DATA(ROUND_OUT_DATA[j]), 
//                     .IN_KEY(ROUND_KEY[j]), 
//                     .LAST_ROUND_FLAG(1'b0), 
//                     .OUT_DATA(ROUND_OUT_DATA[j+1])  
//             );
//         end
//         else begin
//             ROUND_ITERATION R(
//                 .IN_DATA(ROUND_OUT_DATA[j]), 
//                 .IN_KEY(ROUND_KEY[j]), 
//                 .LAST_ROUND_FLAG(1'b1), 
//                 .OUT_DATA(ROUND_OUT_DATA[j+1])  
//         );
//         end
//     end
// endgenerate

reg [1:0] round_cstate,round_nstate;
reg [3:0] j;
reg [127:0]in_data,round_key;
wire [127:0] round_out_data;
reg flag;
always @(posedge clk or posedge rstn) begin
    if(rstn)begin
        round_cstate<=IDLE;
    end
    else begin
        round_cstate<=round_nstate;
    end
end
always @(posedge clk or posedge rstn) begin
    if(rstn)round_nstate<=IDLE;
end
always @(posedge clk or posedge rstn) begin
    if(rstn)j<=0;
    else if(ROUND_OUT_DATA[j+1]&&j<10)j<=j+1;
end

always @(*) begin
    case(round_cstate)
    IDLE:begin
        if(valid_round&&j==0)round_nstate<=GENERATING;
    end
    GENERATING:begin
        if(j<10)round_nstate<=GENERATING;
        else round_nstate<=DONE;
    end
    DONE:begin
        round_nstate<=IDLE;
    end
    default:round_nstate<=round_nstate;
    endcase
end

always @(posedge clk or posedge rstn) begin
    case(round_cstate)
    GENERATING:begin
        if(j+1<11&&j+1>0)begin
            in_data=ROUND_OUT_DATA[j];
            round_key=ROUND_KEY[j];
            ROUND_OUT_DATA[j+1]=round_out_data;
            if(j==9)flag=1'b1;
            else flag=1'b0;
        end
    end
    endcase
end
ROUND_ITERATION R(
        .IN_DATA(in_data), 
        .IN_KEY(round_key), 
        .LAST_ROUND_FLAG(flag), 
        .OUT_DATA(round_out_data)  
);

// 输出每轮的密钥和加密后的数据
assign round_key_0 = IN_KEY;
assign round_key_1 = ROUND_KEY[0];
assign round_key_2 = ROUND_KEY[1];
assign round_key_3 = ROUND_KEY[2];
assign round_key_4 = ROUND_KEY[3];
assign round_key_5 = ROUND_KEY[4];
assign round_key_6 = ROUND_KEY[5];
assign round_key_7 = ROUND_KEY[6];
assign round_key_8 = ROUND_KEY[7];
assign round_key_9 = ROUND_KEY[8];
assign round_key_10 = ROUND_KEY[9];

assign round_data_0 = ROUND_OUT_DATA[0];
assign round_data_1 = ROUND_OUT_DATA[1];
assign round_data_2 = ROUND_OUT_DATA[2];
assign round_data_3 = ROUND_OUT_DATA[3];
assign round_data_4 = ROUND_OUT_DATA[4];
assign round_data_5 = ROUND_OUT_DATA[5];
assign round_data_6 = ROUND_OUT_DATA[6];
assign round_data_7 = ROUND_OUT_DATA[7];
assign round_data_8 = ROUND_OUT_DATA[8];
assign round_data_9 = ROUND_OUT_DATA[9];
assign round_data_10 = ROUND_OUT_DATA[10];

assign OUT_DATA = valid_out ? ROUND_OUT_DATA[10] : 128'b0;

endmodule