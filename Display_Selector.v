`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2021 03:35:44 PM
// Design Name: 
// Module Name: Display_Selector
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

module Display_Selector(    //This module is responsible for showing different messages on the 7-seg display
    input clk,              //to do so, it quickly increments a counter (Array), where each value of Array
    output reg [1:0] Array);    //Corresponds to a specific message on one of the four 7-seg arrays. Array changes 
                                //slow enough to consistently display messages, but fast enough to give the illusion
    reg [19:0] counter = 0;     //of all messages being displayed at once
    
    always@(posedge clk)
    begin
        counter <= counter + 1;
        if (counter == 200_000)     //Every 200_000 clocks, increment Array
        begin
            counter <= 0;
            Array <= Array + 1;
        end
    end
endmodule