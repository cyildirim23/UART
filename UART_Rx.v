`timescale 1ns / 1ps

module UART_Rx(                                     //UART Receiver
    input clk,
    input Rx_Serial,                                //Serial input           
    input [14:0] BR_Clocks,     
    output reg [7:0] Rx_Data,                       //Parallel data output
    output reg r_DV = 0,                            //Data valid ("receive complete" marker)
    output reg Rx_Ready                             //Control signal, active high
    );
    
    parameter IDLE          = 4'b0001;                        //Different states. One-hot encoding to simplify decoding logic
    parameter START         = 4'b0010;
    parameter DATA          = 4'b0100;
    parameter STOP          = 4'b1000;
    
    reg [14:0] clk_count        = 0;
    reg [2:0] bitIndex          = 0;                        //Data is sent one byte at a time, calling for 8 indices (one index per bit)
    reg [7:0] r_Rx_Data         = 0;                        //Stores parallel data, shifted into parallel output if valid
    reg [3:0] SM                = IDLE;                     //Holds the current state
    reg [14:0] Rx_r_BR_Clocks   = 0;
    
    always@(posedge clk)
    begin
        if (r_DV == 1)                              //if r_DV is ever set to 1 (data has been fully received), output received data
            Rx_Data             <= r_Rx_Data;        
        case(SM)
        IDLE:                                       //IDLE state
        begin
            Rx_Ready            <= 1;               //Rx_ready set to 1 since no transaction is in progress
            clk_count           <= 0;
            bitIndex            <= 0;
            r_DV                <= 0;
            Rx_r_BR_Clocks      <= BR_Clocks;       //BR_Clocks is copied to an internal reg so it can be manipulated when needed
            if (Rx_Serial == 0)                     //If a start bit is sent, and the device is in receive mode
                SM <= START;                        //Go to "START" state
            else
                SM <= IDLE;                         //Else, stay in idle
        end
        START:                                      //Verifies that a start bit is being received
        begin
            Rx_Ready <= 0;
            if (clk_count == Rx_r_BR_Clocks / 2)    //Samples where the middle of the start bit would be
            begin                                   
                if (Rx_Serial == 0)                 //If the value is still 0, it is in fact a start bit
                begin                               //So, change states to "DATA", reset clock counter   
                    SM          <= DATA;
                    clk_count   <= 0;
                end
                else                                //Else, start bit not detected, return to "IDLE"
                    SM          <= IDLE;
            end
            else                                    //Increment clk_count until BR_Clocks / 2 is reached
            begin                                   //and stay in current state (START)
                clk_count       <= clk_count + 1;
                SM              <= START;
            end
        end
        DATA:                                       //This state stores each bit in an internal reg
        begin                                       //Each full clk_count cycle from here will end mid-bit
            if (clk_count < Rx_r_BR_Clocks)         //While clk_count < BR_Clocks, increment clk_count
            begin                                   
                clk_count       <= clk_count + 1;     
                SM              <= DATA;
            end
            else                                    //Once clk_count == BR_Clocks
            begin
                r_Rx_Data[bitIndex] <= Rx_Serial;   //Store the current serial value in the current index 
                clk_count           <= 0;           //of the internal reg
                if (bitIndex < 7)
                begin                                       //While max bit index (7) hasn't been reached, repeat above
                    bitIndex        <= bitIndex + 1;        //with the next index of the internal reg
                    SM              <= DATA;
                end
                else                                //Once internal reg is full, reset bitIndex, proceed
                begin                               //to "STOP" state
                    bitIndex        <= 0;
                    SM              <= STOP;
                end
            end
        end
        STOP:                                       //Same idea as "START"; sample where the middle of the next bit would be
        begin
            if (clk_count < Rx_r_BR_Clocks)
            begin
                clk_count           <= clk_count + 1;
                SM                  <= STOP;
            end
            else
            begin
                if(Rx_Serial == 1'b1)               //If the sampled value is 1, the stop bit has ben received
                begin                               //reset clk_count, set r_DV to 1, proceed to "CLEAN" state
                    clk_count       <= 0;
                    r_DV            <= 1;
                    SM              <= IDLE;
                end
            end
        end
      
       default : SM <= IDLE;
       
       endcase
    end
    
endmodule