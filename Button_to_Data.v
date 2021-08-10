`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2021 04:02:29 PM
// Design Name: 
// Module Name: Button_to_Data
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


module Button_to_Data(
    input button1, button2, button3, button4, //button5,
    input clk,
    output reg [7:0] Byte);
    
    always@(posedge clk)
    begin
        if (button1 && button2) //Gas + right  
            Byte <= 8'b01110000;    //p
        else if (button1 && button4) //Gas + left
            Byte <= 8'b01110001;    //q
        else if (button3 && button2) //Brake + right
            Byte <= 8'b01110010;    //r
        else if (button3 && button4) //Brake + left
            Byte <= 8'b01110011;    //s
        else if (button1)
            Byte <= 8'b01110100; //t (gas)
        else if (button2)
            Byte <= 8'b01110101; //u (right)
        else if (button3)
            Byte <= 8'b01110110; //v (brake) 
        else if (button4)
            Byte <= 8'b01110111; //w (left)
       /* else if (button5)
            Byte <= 8'b01111000; //x (middle) */
    end
endmodule
