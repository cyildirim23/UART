`timescale 1ns / 1ps
/*
This module transmits the byte given by the input "Tx_Parallel" over the UART Tx out pin.
It sends a Tx_Complete pulse to the control wrapper once a transmission is complete
*/


module UART_Tx(          
  
    input clk,
    input Enable,                                       //Enable, when == 1, sends the current parallel input as a serial output       
    input [7:0] Tx_Parallel,                            //Parallel input, to be sent serially
    input [14:0] BR_Clocks,
    output reg Tx_Serial,                               //Serial output                             
    output reg Tx_Complete = 0,                         //Pulse, increments a counter in wrapper once a byte is successfully transmitted (UNUSED)
    output reg Tx_Ready = 0
    ); 
                                                        //Different states, parameterized for clarity
    parameter IDLE              = 3'b000;
    parameter LOAD              = 3'b001;
    parameter START             = 3'b010;
    parameter DATA              = 3'b011;
    parameter STOP              = 3'b100;
    
    reg [14:0] clk_count        = 0;                    //used to count clock cycles, to output bits for the proper # of clock cycles
    reg [2:0] bitIndex          = 0;                    //Bit index, used when serializing data
    reg [2:0] SM                = IDLE;                 //Represents current state
    reg [7:0] r_Tx_Parallel     = 0;                    //Internal register. Holds parallel data when Enable is active
    reg [14:0] Tx_r_BR_Clocks   = 0;                    //Internal register. Holds a copy of BR_Clocks that can be manipulated
    
    always@(posedge clk)
    begin
        case(SM)
            IDLE:                                      //Waits for enable signal
            begin
                Tx_Ready            <= 1;              //Tells wrapper that the baud rate can be safely changed. No transaction in progress
                Tx_Complete         <= 0;              
                Tx_Serial           <= 1;              //Serial output is driven high when not transmitting
                Tx_r_BR_Clocks      <= BR_Clocks;      //# clock cycles gets moved to an internal register where it can be manipulated without interfering with the original signal
                if(Enable)                             //If Enable is high, begin transmission. Else, stay in IDLE state
                begin                                  
                    SM <= LOAD;
                end
                else
                    SM <= IDLE;                        
            end
            LOAD:                                       //LOAD, loads input to be transmitted
            begin
                Tx_Ready            <= 0;
                r_Tx_Parallel       <= Tx_Parallel;     //Parallel input is loaded to internal reg
                SM                  <= START;           //Proceed to "START" state
            end
            START:                                      //START, sends a start bit
            begin       
                Tx_Serial <= 0;                         //Serial out is driven low for # clocks corresponding to selected baud rate
                if (clk_count < Tx_r_BR_Clocks - 1)     //Increment a counter while the counter != BR_Clocks 
                begin
                    clk_count       <= clk_count + 1;
                    SM              <= START;
                end
                else                                    //After start bit is transmitted, proceed to "DATA" state, reset clk count
                begin
                    SM              <= DATA;
                    clk_count       <= 0;
                end
            end
            DATA:                                       //DATA, sends each bit of data
            begin
                Tx_Serial <= r_Tx_Parallel[bitIndex];   //Drive the output with the current bit for BR_Clocks clock cycles
                if (clk_count < Tx_r_BR_Clocks - 1)    
                begin                                   
                    SM              <= DATA;
                    clk_count       <= clk_count + 1;
                end
                else                                    //After, increment the index and repeat until
                begin                                   //the last bit is transmitted
                    if (bitIndex < 7)
                    begin
                        bitIndex    <= bitIndex + 1;
                        clk_count   <= 0;
                        SM          <= DATA;
                    end
                    else 
                    begin                               //After all indices have been transmitted, 
                        bitIndex    <= 0;               //proceed to "STOP" state
                        clk_count   <= 0;
                        SM          <= STOP;
                    end
                end
            end  
           
            STOP:                                       //STOP, sends a stop bit
            begin
                Tx_Serial <= 1;                         //Drive Tx output high for BR_Clocks clock cycles
                if (clk_count < Tx_r_BR_Clocks - 1)
                begin
                    clk_count       <= clk_count + 1;
                    SM              <= STOP;
                end
                else                                    //After stop bit has been sent for appropriate time
                begin
                    Tx_Complete     <= 1;               //Send "complete" pulse, reset clk count, return to IDLE
                    clk_count       <= 0;
                    SM              <= IDLE; 
                end
            end
   
            default: SM             <= IDLE;
        endcase
    end
endmodule          