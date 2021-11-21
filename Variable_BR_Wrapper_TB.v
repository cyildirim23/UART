`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2021 08:42:40 PM
// Design Name: 
// Module Name: Variable_BR_Wrapper_TB
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Variable_BR_Wrapper_TB();

    reg clk = 0;
    reg Rx = 0;
    reg Enable; 
    reg [2:0] BR_Select = 3'b000;
    reg [7:0] Tx_Data = 8'b10101010;
    
    wire Tx;
    wire [7:0] Rx_Data;
    wire [14:0] BR_Clocks;
    wire [14:0] Tx_r_BR_Clocks;
    wire [14:0] Rx_r_BR_Clocks;
    wire [14:0] clk_count;
    
    initial
    begin
        forever #1 clk = ~clk;
    end
    
    initial
    begin
         Enable = 1;
         #2;
         Enable = 0;
         #100;
         Enable = 1;
         #2;
         Enable = 0;
         #100000;
         $finish;
    end
    
    Variable_BR_Wrapper TB(.clk(clk), .Rx(Rx), .Enable(Enable), .Tx(Tx), .Rx_Data(Rx_Data), .Tx_Data(Tx_Data), .BR_Clocks(BR_Clocks), .BR_Select(BR_Select),
    .Rx_r_BR_Clocks(Rx_r_BR_Clocks), .Tx_r_BR_Clocks(Tx_r_BR_Clocks), .clk_count(clk_count));
    
endmodule
