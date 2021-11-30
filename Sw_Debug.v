`timescale 1ns / 1ps
/*
This module lights up the LEDs corresponding to a user's input 
*/

module Sw_Debug(                
                                
    input  switch,           //Input switch
    output wire LED          //LED for corresponding switch
);

    assign LED = switch;     //If switch is on, LED is on

endmodule