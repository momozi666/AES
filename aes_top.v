`timescale 1ns / 1ps
module AES128(
    input clk,
    input rstn,
    input en, // AES启动使能信号(key是否可以开始generate)

    input data_in_valid, // 输入明文是否有效
    input [127:0] data_in, // 输入的明文

    output aes_state, // AES工作状态
    output rk_ready, // 密钥准备就绪，提示可以开始加密

    output data_out_valid, // 输出密文是否有效
    output [127:0] data_out, // 输出的密文

    input [127:0] key_in, // 输入的密钥
    input slt_module // 选择加密/解密模式（默认加密，由于暂时没有完成解密，暂不考虑解密模式）
);

reg aes_state_reg;
reg rk_ready_reg;
reg data_out_valid_reg;
reg [127:0] data_out_reg;

assign aes_state = aes_state_reg;
assign rk_ready = rk_ready_reg;
assign data_out_valid = data_out_valid_reg;
assign data_out = data_out_reg;

reg [3:0] round_counter;
reg [127:0] ROUND_KEY [0:9];
reg [127:0] NEXT_KEY [0:10];
always @(*) begin
    NEXT_KEY[0]=key_in;
end
reg [127:0] ROUND_OUT_DATA [0:10];

//用状态机实现密钥扩展,三段式
parameter IDLE =2'b00,GENERATING=2'b01,DONE=2'b10 ;
reg [1:0] current_state,next_state;
reg [3:0] i;
reg [127:0]in_key;
wire [127:0]out_key;
reg [3:0]round;
always @(posedge clk or negedge rstn) begin
    if(!rstn)begin
        current_state<=IDLE;
    end
    else begin
        current_state<=next_state;
    end
end
always @(posedge clk or negedge rstn) begin
    if(!rstn)next_state<=IDLE;
end
always @(posedge clk or negedge rstn) begin
    if(!rstn)i<=0;
    else if(current_state==GENERATING)begin
        if(NEXT_KEY[i+1]&&i<10)i<=i+1;
    end
end
always @(*) begin
    case(current_state)
        IDLE:begin
            if(en&&i==0)begin
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
always @(posedge clk or negedge rstn) begin
    case(current_state)
        GENERATING:begin
        NEXT_KEY[i+1]=out_key;
        ROUND_KEY[i]=NEXT_KEY[i+1];
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

always @(posedge clk or negedge rstn) begin
    if(!rstn)rk_ready_reg<=1'b0;
    else if(current_state==DONE)rk_ready_reg<=1'b1;
end

reg [1:0] round_cstate,round_nstate;
reg [127:0]in_data,round_key;
wire [127:0] round_out_data;
reg flag;

// AES加密执行逻辑
always @(*) begin
    if(!rstn)ROUND_OUT_DATA[0]<=0;
    else if(data_in_valid)begin
        if(slt_module)begin
            ROUND_OUT_DATA[0]<=data_in^key_in;//解密
        end
        else begin
            ROUND_OUT_DATA[0]<=data_in^key_in;//加密
        end
    end
end


// AES状态控制逻辑
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        aes_state_reg <= 1'b0;
    end else if (rk_ready_reg && data_in_valid) begin
        aes_state_reg <= 1'b1;
    end else if (round_counter+1 > 0 && round_counter+1 < 11) begin
        aes_state_reg <= 1'b1; // 保持 aes_state_reg 为 1
    end else begin
        aes_state_reg <= 1'b0; // 保持 aes_state_reg 为 0
    end
end

// AES输出控制逻辑
always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        data_out_valid_reg <= 1'b0;
        data_out_reg <= 128'b0;
    end else if (round_cstate==DONE) begin
        data_out_reg <= ROUND_OUT_DATA[10];
        data_out_valid_reg <= 1'b1;
    end else begin
        data_out_valid_reg <= 1'b0;
    end
end

//AES加密 流水线结构
always @(posedge clk or negedge rstn) begin
    if(!rstn)begin
        round_cstate<=IDLE;
    end
    else begin
        round_cstate<=round_nstate;
    end
end
always @(posedge clk or negedge rstn) begin
    if(!rstn)round_nstate<=IDLE;
end
always @(posedge clk or negedge rstn) begin
    if(!rstn)round_counter<=0;
    else if(ROUND_OUT_DATA[round_counter+1]&&round_counter<10)round_counter<=round_counter+1;
end

always @(*) begin
    case(round_cstate)
    IDLE:begin
        if(ROUND_OUT_DATA[round_counter]&rk_ready_reg&&round_counter==0&&data_in_valid)round_nstate<=GENERATING;
    end
    GENERATING:begin
        if(round_counter<10)round_nstate<=GENERATING;
        else round_nstate<=DONE;
    end
    DONE:begin
        round_nstate<=IDLE;
    end
    default:round_nstate<=round_nstate;
    endcase
end

always @(posedge clk or negedge rstn) begin
    case(round_cstate)
    GENERATING:begin
            in_data=ROUND_OUT_DATA[round_counter];
            round_key=ROUND_KEY[round_counter];
            ROUND_OUT_DATA[round_counter+1]=round_out_data;
            if(round_counter==9)flag=1'b1;
            else flag=1'b0;
        end
    endcase
end
ROUND_ITERATION R(
        .IN_DATA(in_data), 
        .IN_KEY(round_key), 
        .LAST_ROUND_FLAG(flag), 
        .OUT_DATA(round_out_data)  
);

endmodule