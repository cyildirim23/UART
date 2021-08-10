module Sw_Debug(                //This module lights up the LEDs corresponding to a user's input 
                                //(where the input is a byte to be stored in the FIFO)
    input [7:0] switch,         //Input byte (each switch represents a bit)
    input RD,
    input WR,
    input clk,
    output reg [7:0] LED,       //LEDs for each bit
    output reg RD_LED,
    output reg WR_LED);
    
    always@(posedge clk)
    begin
        LED <= switch;
        RD_LED <= RD;
        WR_LED <= WR;
    end
    
endmodule