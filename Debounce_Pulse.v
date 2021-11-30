`timescale 1ns / 1ps
//Module for debouncing input switch, and outputting a pulse

module Debounce_Pulse(      
    input in,
    input clk,
    output out
    );
    
    wire DB_out;
    
    Debounce switch_debounce(.switch_in(in), .clk(clk), .switch_out(DB_out));
    Pulse Enable(.pulse_in(DB_out), .clk(clk), .pulse_out(out));
    
endmodule