`timescale 1ns / 1ps

//Gives parallel data to send, then samples the serial data, comparing to the original parallel data.

module UART_Tx_TB();

    reg clk = 0;
    reg Enable = 0;
    reg [7:0] Tx_Parallel = 8'b00000000;
    reg [14:0] BR_Clocks = 15'd868;
    
    wire Tx_Ready;
    wire Tx_Serial;
    
    UART_Tx TB(.BR_Clocks(BR_Clocks), .clk(clk), .Enable(Enable), .Tx_Parallel(Tx_Parallel), .Tx_Serial(Tx_Serial), .Tx_Ready(Tx_Ready));
    
    integer k = 0;
    integer i;
    integer j = 0;
    integer errorCount = 0;
    
    initial
    begin
        forever #1 clk= ~clk;
    end
    
    initial
    begin
        #10;
        for (k = 0; k <= 255; k = k + 1)                      //for loop to cycle through each test input of Tx_Parallel
        begin
            Enable = 1;
            #2;
            Enable = 0;
            #1302;                                            //Wait 1.5 bits after assertion to skip over start bit, and align to middle of 1st data bit
            for (i = 0; i <= 8; i = i + 1)                    //for loop to cycle through each bit of serial output
            begin
                j = j + (Tx_Serial << i - 1);                 //Add current output bit to the power of current index being sent, to accumulator
                #1736;                                        //Wait one bit to test next bit transmission
            end
            if (j != Tx_Parallel)                             //Compare serial output data to the parallel input
            begin
                errorCount = errorCount + 1;                                //If mismatch, add 1 to errorCount, print value of input where mismatch occurred
                $display("Mismatch at Tx_Parallel =  %d", Tx_Parallel);
            end
            j = 0;                                                          //Reset accumulator
            Tx_Parallel = Tx_Parallel + 1;                                  //Increase Tx_Parallel by 1
            #440;                                                           //Wait at least half a bit to realign with output
        end
        $display("Total mismatches =  %d", errorCount);                     //Once finished, output total error count
        $finish;
    end
endmodule
