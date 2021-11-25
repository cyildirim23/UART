`timescale 1ns / 1ps

/*
This module is responsible for showing different messages on the 7-seg display
to do so, it quickly increments a counter (Array), where each value of Array
Corresponds to a specific message on one of the four 7-seg arrays. Array changes 
slow enough to consistently display messages, but fast enough to give the illusion
of all messages being displayed at once 
*/

module Display_Selector(    
    input clk,              
    output reg [1:0] Array);        //Output used to select which 7seg array is lit
    reg [19:0] counter = 0;         //Counter used to change the array at a specific rate
    
    always@(posedge clk)
    begin
        counter <= counter + 1;
        if (counter == 200_000)     //Every 200_000 clock cycles, increment Array
        begin
            counter     <= 0;
            Array       <= Array + 1;
        end
    end
endmodule