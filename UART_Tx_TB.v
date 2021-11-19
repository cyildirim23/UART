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
    
    wire Tx_Serial;
    wire Tx_Complete;
    
    UART_Tx TB(.clk(clk), .Enable(Enable), .Tx_Parallel(Tx_Parallel), .Tx_Serial(Tx_Serial), .Tx_Complete(Tx_Complete));
    
    initial
    begin
        forever #1 clk= ~clk;
    end
    
    initial
    begin
        Enable = 1;
        #2;
        Enable = 0;
        #20000;
        $finish;
    end
endmodule
