`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/07/2021 04:07:45 PM
// Design Name: 
// Module Name: UART_Tx
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
    reg [7:0] Tx_Parallel = 0;
    wire Tx_Serial;
    integer i;
    integer j;
    integer k;
    integer marker;

    UART_Tx inst_1(.clk(clk), .Enable(Enable), .Tx_Parallel(Tx_Parallel),
        .Tx_Serial(Tx_Serial));
        
    initial
    begin
        for(k = 0; k < 128; k=k+1)
        begin
            #1;
            Enable = 1;
            for(j = 0; j < 10; j=j+1)
            begin
                #1;
                marker = 0;
                for(i = 0; i < 1640; i=i+1)
                begin
                    #1;
                    clk = ~clk;
                end
                marker = 1;
                #1;
            end
            #1;
            Enable = 0;
            #1;
            Tx_Parallel = Tx_Parallel + 1;
        end
    end
endmodule
