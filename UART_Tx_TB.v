`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2021 12:12:07 PM
// Design Name: 
// Module Name: UART_Tx_TB
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


module UART_Tx_TB();

    reg clk = 0;
    reg Enable = 0;
    reg [7:0] Tx_Parallel = 8'b10101010;
    reg [14:0] BR_Clocks = 15'd868;
    
    wire Tx_Ready;
    wire Tx_Serial;
    wire Tx_Complete;
    
    UART_Tx TB(.BR_Clocks(BR_Clocks), .clk(clk), .Enable(Enable), .Tx_Parallel(Tx_Parallel), .Tx_Serial(Tx_Serial), .Tx_Complete(Tx_Complete), .Tx_Ready(Tx_Ready));
    
    initial
    begin
        forever #1 clk= ~clk;
    end
    
    initial
    begin
        #400;
        Enable = 1;
        #2;
        Enable = 0;
        #20000;
        $finish;
    end
endmodule
