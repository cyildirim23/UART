`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/20/2021 11:23:47 AM
// Design Name: 
// Module Name: Variable_BR_Wrapper
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


module Variable_BR_Wrapper(

    input clk, Rx, Enable, 
    input [2:0] BR_Select,
    input [7:0] Tx_Data,
    output Tx,
    output [7:0] Rx_Data,
    output reg [14:0] BR_Clocks,
    output wire [14:0] Tx_r_BR_Clocks,
    output wire [14:0] Rx_r_BR_Clocks,
    output wire [14:0] clk_count
    );
    
    wire Tx_Ready;
    wire Rx_Ready;
    //reg [14:0] BR_Clocks;
    
    always@(posedge clk)
    begin
        if (Tx_Ready && Rx_Ready)
        begin
            case(BR_Select)
                0:  BR_Clocks <= 15'd20834;                                   //Selected baud is 4800
                1:  BR_Clocks <= 15'd10417;                                   //Selected baud is 9600  
                2:  BR_Clocks <= 15'd6945;                                    //Selected baud is 14400
                3:  BR_Clocks <= 15'd5208;                                    //Selected baud is 19200
                4:  BR_Clocks <= 15'd2604;                                    //Selected baud is 38400
                5:  BR_Clocks <= 15'd1736;                                    //Selected baud is 57600
                6:  BR_Clocks <= 15'd868;                                     //Selected baud is 115200
                7:  BR_Clocks <= 15'd434;                                     //Selected baud is 230400
            endcase
        end
    end
    
    
    UART_Rx Receiver(.clk(clk), .BR_Clocks(BR_Clocks), .Rx_Serial(Rx), .Rx_Data(Rx_Data), .r_DV(Data_Ready), .Rx_Ready(Rx_Ready), .Rx_r_BR_Clocks(Rx_r_BR_Clocks));                //UART receiver module instantiation
    UART_Tx Transmitter(.clk(clk), .BR_Clocks(BR_Clocks), .Tx_Serial(Tx), .Tx_Parallel(Tx_Data), .Enable(Enable), .Tx_Ready(Tx_Ready), .Tx_r_BR_Clocks(Tx_r_BR_Clocks), .clk_count(clk_count));                 //UART transmitter module instantiation
    
endmodule
