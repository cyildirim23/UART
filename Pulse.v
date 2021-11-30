`timescale 1ns / 1ps
//State machine used to force a pulse of specific clock cycle length when the input goes high

module Pulse(
    input wire pulse_in,                       //Input port
    input clk,                          
    output reg pulse_out = 0           //Output port
    ); 
                                        
    reg pulse = 0;                      //Output signal, drives output
    reg [7:0] counter = 0;              //Used to determine how long pulse lasts
    reg [1:0] SM = 0;                   //Register for holding current state

    parameter IDLE          = 2'b00;
    parameter HIGH          = 2'b01;
    parameter LOW           = 2'b10;
    parameter pulse_length  = 1;             //Sets pulse width (number of clock cycles for one pulse)
    
    always@(posedge clk)
    begin
        pulse_out          <= pulse;                //pulse drives pulse_out on every clock cycle
        case(SM)
            IDLE:
            begin
                if (pulse_in == 1)
                begin
                    counter <= 0;
                    pulse   <= 1;
                    SM      <= HIGH;
                end
            end
            HIGH:
            begin
                pulse       <= 1;
                counter     <= counter + 1;
                if (counter == pulse_length)
                begin
                    pulse   <= 0;
                    counter <= 0;
                    SM      <= LOW;
                end
            end
            LOW:
            begin
                if (pulse_in == 1)
                begin
                    SM      <= LOW;
                    pulse   <= 0;
                end
                if (pulse_in == 0)
                begin
                    SM      <= IDLE;
                    pulse   <= 0;
                end
            end
        endcase
    end
endmodule