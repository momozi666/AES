 `timescale 1ns / 1ps

//  `include "aes_top.v"
//  `include "generate_key.v"
//  `include "mix_columns.v"
//  `include "last_round.v"
//  `include "s_box.v"
//  `include "round_iteration.v"
//  `include "shift_rows.v"
//  `include "sub_bytes.v"

module testbench;
  reg clk;
  reg reset;


  reg [127:0] inp_data;

  reg [127:0] inp_key;


  // wire [127:0] inp_data;
  // wire [127:0] inp_key;
  wire [127:0] out_data;

  AES128 AES128_DUT(clk,reset,inp_data,inp_key,out_data);
  initial 
    begin  
      clk = 0;
      reset = 0;

      inp_key = 128'h0123456789ABCDEF0123456789ABCDEF;
      inp_data = 128'hd7e5dbd3324595f8fdc7d7c571da6c2a;
        #300 $display("Encrypted value: %h",out_data);
      #100 $finish;
  end
  always #5  clk =  ! clk; 
endmodule
