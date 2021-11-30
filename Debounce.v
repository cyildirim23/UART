`timescale 1ns / 1ps

module Debounce(                                    //Module for debouncing a switch input
    input switch_in,
    input clk,
    output reg switch_out                           //Debounced output
    );         
    
    reg [20:0] counter = 0;
    parameter debounce_limit = 2_000_000;
    
    always@(posedge clk)
    begin
       if (counter == debounce_limit)       //after 2_000_000 consecutive high input samples
       begin                                //(input is stable high), output is set to 1
           switch_out <= 1;
           counter <= 0;
       end
       else if (switch_in == 1)                  //if switch input is high, increment counter
           counter <= counter + 1;
       else if (switch_in == 0)
       begin
           switch_out <= 0;
           counter <= 0;
       end
   end
endmodule
