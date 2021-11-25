`timescale 1ns / 1ps

module top(
    
    input clk,
    input Rx,                                                                                               //UART serial input (receive)
    input Enable_Switch,                                                                                    //Switch used to transmit byte via Tx module
    input Mode,                                                                                             //Switch used to show last received byte (set to 0), or current byte to send (set to 1)
    input [2:0] BR_Select,                                                                                  //Switches used to control baud rate of transactions
    input [7:0] User_Tx,                                                                                    //Switches used to represent a binary number to send over Tx dataline
    
    output Tx,                                                                                              //UART serial output (transmit)
    output [3:0] AN,                                                                                        //7seg array control. Each "0" bit represents a lit 7seg array (active low)
    output [6:0] C,                                                                                         //7seg array segment control. Each "0" bit represents a lit segment of an array (active low)
    
    output [7:0] User_Tx_LED,                                                                               //LEDs for each bit of the binary number to send
    output [2:0] BR_LED,                                                                                    //LEDs for each bit of the baud rate control 
    output Mode_LED,                                                                                        //LED for the Mode switch
    output Enable_LED                                                                                       //LED for the Enable switch
    );
    
    wire [1:0] Array;                                                                                       //Wires used to connect ports between modules
    wire [7:0] Rx_Data_Wires;
    
    Variable_BR_Wrapper UART(.clk(clk), .Rx(Rx), .Enable(Enable), .Tx(Tx),                                  //Wrapper for UART module. Includes control logic
    .Rx_Data(Rx_Data_Wires), .Tx_Data(User_Tx), .BR_Select(BR_Select));
    
    Debounce_Pulse Enable_Pulse(.clk(clk), .switch_in(Enable_Switch), .pulse_out(Enable));                  //Module used to debounce an input signal, and produce a single pulse as an output
    
    Display_Selector Array_Select(.clk(clk), .Array(Array));                                                //7seg array selector module instantiation
    
    UART_Display Display_Wrapper(.Rx_Data(Rx_Data_Wires), .Tx_Data(User_Tx),                                //7seg display wrapper instantiation
    .Array(Array), .Mode(Mode), .C(C), .AN(AN));        
    
    Sw_Debug LED1(.switch(User_Tx[0]), .clk(clk), .LED(User_Tx_LED[0]));                                    //LEDs to show which switches are active
    Sw_Debug LED2(.switch(User_Tx[1]), .clk(clk), .LED(User_Tx_LED[1]));
    Sw_Debug LED3(.switch(User_Tx[2]), .clk(clk), .LED(User_Tx_LED[2]));
    Sw_Debug LED4(.switch(User_Tx[3]), .clk(clk), .LED(User_Tx_LED[3]));
    Sw_Debug LED5(.switch(User_Tx[4]), .clk(clk), .LED(User_Tx_LED[4]));
    Sw_Debug LED6(.switch(User_Tx[5]), .clk(clk), .LED(User_Tx_LED[5]));
    Sw_Debug LED7(.switch(User_Tx[6]), .clk(clk), .LED(User_Tx_LED[6]));
    Sw_Debug LED8(.switch(User_Tx[7]), .clk(clk), .LED(User_Tx_LED[7]));
    
    Sw_Debug En_LED(.switch(Enable_Switch), .clk(clk), .LED(Enable_LED));
    
    Sw_Debug M_LED(.switch(Mode), .clk(clk), .LED(Mode_LED));
    
    Sw_Debug BR_LED1(.switch(BR_Select[0]), .clk(clk), .LED(BR_LED[0]));
    Sw_Debug BR_LED2(.switch(BR_Select[1]), .clk(clk), .LED(BR_LED[1]));
    Sw_Debug BR_LED3(.switch(BR_Select[2]), .clk(clk), .LED(BR_LED[2]));
    
endmodule

