`timescale 1ns / 1ps
/*
This module transmits the byte given by the input "Tx_Parallel" over the UART Tx out pin.
It sends a Tx_Complete pulse to the control wrapper once a transmission is complete
*/


module UART_Tx(          
  
    input clk,
    input Enable,                                       //Enable, when == 1, sends the current parallel input as a serial output       
    input [7:0] Tx_Parallel,                            //Parallel input, to be sent serially
    output reg Tx_Serial,                               //Serial output                             
    output reg Tx_Complete                              //Pulse, increments a counter in wrapper once a byte is successfully transmitted
    ); 
                              
    parameter clks_per_bit = 868; 
                                                        //Different states
    parameter IDLE              = 3'b000;
    parameter LOAD              = 3'b001;
    parameter START             = 3'b010;
    parameter DATA              = 3'b011;
    parameter STOP              = 3'b100;
    
    reg [9:0] clk_count         = 0;                    //used to count clock cycles, to output bits for the proper # of clock cycles
    reg [2:0] bitIndex          = 0;                    //Bit index, used when serializing data
    reg [2:0] SM                = 0;                    //Represents current state
    reg [7:0] r_Tx_Parallel     = 0;                    //Internal register. Holds parallel data when Enable is active
    
    always@(posedge clk)
    begin
        case(SM)
            0:                                          //Waits for enable signal
            begin
            Tx_Complete <= 0;
            Tx_Serial <= 1;                             //Serial output is driven high when not transmitting
                if(Enable)
                begin                                   //Begin transmission
                    SM <= LOAD;
                end
                else
                    SM <= IDLE;                         //If Enable is 1, and device is in transmission mode, 
            end
            1:                                          //LOAD, loads input
            begin
                r_Tx_Parallel <= Tx_Parallel;           //Parallel input is loaded to internal reg
                SM <= START;                            //Proceed to "START" state
            end
            2:                                          //START, sends a start bit
            begin       
                Tx_Serial <= 0;                         //Serial out is driven low for for 868 clocks (115200 baud) for the start bit
                if (clk_count < clks_per_bit - 1)
                begin
                    clk_count <= clk_count + 1;
                    SM <= START;
                end
                else                                    //After start bit is transmitted, proceed to "DATA" state, reset clk count
                begin
                    SM <= DATA;
                    clk_count <= 0;
                end
            end
            3:                                          //DATA, sends each bit of data
            begin
                Tx_Serial <= r_Tx_Parallel[bitIndex];
                if (clk_count < clks_per_bit - 1)       //for 868 clocks, drive the output with the current
                begin                                   //index of the internal reg
                    SM <= DATA;
                    clk_count <= clk_count + 1;
                end
                else                                    //After, increment the index and repeat until
                begin                                   //the last bit is transmitted
                    if (bitIndex < 7)
                    begin
                        bitIndex <= bitIndex + 1;
                        clk_count <= 0;
                        SM <= DATA;
                    end
                    else 
                    begin                               //After all indices have been transmitted, 
                        bitIndex <= 0;                  //proceed to "STOP" state
                        clk_count <= 0;
                        SM <= STOP;
                    end
                end
            end  
           
            4:                                          //STOP, sends a stop bit
            begin
                Tx_Serial <= 1;                         //Drive Tx output high for 868 clock cycles
                if (clk_count < clks_per_bit - 1)
                begin
                    clk_count <= clk_count + 1;
                    SM <= STOP;
                end
                else                                    //After stop bit has been sent for appropriate time
                begin
                    Tx_Complete <= 1;                   //Send "complete" pulse, reset clk count, return to IDLE
                    clk_count <= 0;
                    SM <= IDLE; 
                end
            end
   
            default: SM <= IDLE;
        endcase
    end
endmodule          
