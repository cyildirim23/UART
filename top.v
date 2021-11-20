`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/19/2021 12:30:05 PM
// Design Name: 
// Module Name: top
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


module top(
    
    input clk, Rx, Enable_Switch, Mode,
    input [2:0] BR_Select,
    input [7:0] User_Tx,
    
    output Tx,
    output [3:0] AN,
    output [6:0] C,
    output [7:0] User_Tx_LED
    );
    
    
    wire [1:0] Array;                                                                                       //Wires used to connect ports between modules
    wire [7:0] Rx_Data_Wires;
    
    UART_Rx Receiver(.clk(clk), .Rx_Serial(Rx), .Rx_Data(Rx_Data_Wires), .r_DV(Data_Ready));                //UART receiver module instantiation
    UART_Tx Transmitter(.clk(clk), .Tx_Serial(Tx), .Tx_Parallel(User_Tx), .Enable(Enable));                 //UART transmitter module instantiation
    Debounce_Pulse Enable_Pulse(.clk(clk), .switch_in(Enable_Switch), .pulse_out(Enable));                  //Module used to debounce an input signal, and produce a single pulse as an output
    Display_Selector Array_Select(.clk(clk), .Array(Array));                                                //7seg array selector module instantiation
    Display(.Rx_Data(Rx_Data_Wires), .Tx_Data(User_Tx), .Array(Array), .Mode(Mode), .C(C), .AN(AN));        //7seg display module instantiation
    
    Sw_Debug LED1(.switch(User_Tx[0]), .clk(clk), .LED(User_Tx_LED[0]));                                    //LEDs to show which switches are active
    Sw_Debug LED2(.switch(User_Tx[1]), .clk(clk), .LED(User_Tx_LED[1]));
    Sw_Debug LED3(.switch(User_Tx[2]), .clk(clk), .LED(User_Tx_LED[2]));
    Sw_Debug LED4(.switch(User_Tx[3]), .clk(clk), .LED(User_Tx_LED[3]));
    Sw_Debug LED5(.switch(User_Tx[4]), .clk(clk), .LED(User_Tx_LED[4]));
    Sw_Debug LED6(.switch(User_Tx[5]), .clk(clk), .LED(User_Tx_LED[5]));
    Sw_Debug LED7(.switch(User_Tx[6]), .clk(clk), .LED(User_Tx_LED[6]));
    Sw_Debug LED8(.switch(User_Tx[7]), .clk(clk), .LED(User_Tx_LED[7]));
    
    
endmodule
