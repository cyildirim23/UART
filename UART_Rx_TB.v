`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/18/2021 10:43:33 PM
// Design Name: 
// Module Name: UART_Rx_TB
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


module UART_Rx_TB();

    reg clk = 0;
    reg Rx_Serial = 1;
    
    wire [7:0] Rx_Data;
    wire r_DV;
    
    UART_Rx TB(.clk(clk), .Rx_Serial(Rx_Serial), .Rx_Data(Rx_Data), .r_DV(r_DV));
    
    initial
    begin
        forever #1 clk = ~clk;
    end
    
    initial
    begin
        #1736;
        Rx_Serial = 0;
        #1736;
        Rx_Serial = 1;
        #1736;
        Rx_Serial = 0;
        #1736;
        Rx_Serial = 1;
        #1736;
        Rx_Serial = 0;
        #1736;
        Rx_Serial = 1;
        #1736;
        Rx_Serial = 0;
        #1736;
        Rx_Serial = 1;
        #1736;
        Rx_Serial = 0;
        #1736;
        Rx_Serial = 1;
        #1736;
        $finish;
    end
endmodule
