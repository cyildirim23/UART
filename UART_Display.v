`timescale 1ns / 1ps

/*
This module acts as a simple wrapper for the display module, in order to simplify the display module.
It takes the received byte and the byte to send as inputs, and displays the correct data depending on which
mode is selected. Simply, this module can be seen as a multiplexer.
*/

module UART_Display(

    input wire [7:0] Rx_Data,           //Array which holds the most recently stored word (Displayed in Rx mode)
    input wire [7:0] Tx_Data,           //Array which holds the next word to be sent (Displayed in Tx mode)
    input wire Mode,                    //Display mode
    input wire [1:0] Array,

    output [3:0] AN,                    //7seg array selector
    output [6:0] C                      //7seg array segment selector
    );
    
    reg [7:0] Display_Data;
    
    always@(*)
    begin
        if (Mode)                       //If mode is 1, display the data to transmit
            Display_Data = Tx_Data;
        else                            //Else, display the data last received
            Display_Data = Rx_Data;
    end
        
    Display(.Mode(Mode), .Data(Display_Data), .Array(Array), .C(C), .AN(AN));       //Display module instantiation
    
endmodule
