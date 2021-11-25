`timescale 1ns / 1ps

//Mimics receiving data. All possible values of a byte are sent over Rx_Serial data line. Captured byte (Rx_Data) is compared to the test input that was serialized (Tx_Value)

module UART_Rx_TB();
                                        //Necessary ports for testing
    reg clk = 0;
    reg Rx_Serial = 1;
    reg [14:0] BR_Clocks = 15'd868;
    
    wire [7:0] Rx_Data;

    UART_Rx TB(.clk(clk), .Rx_Serial(Rx_Serial), .Rx_Data(Rx_Data), .BR_Clocks(BR_Clocks));
    
    //Testbench values
    reg [7:0] Tx_Value = 8'b0000000;
    reg [7:0] bitTest = 8'b00000001;
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
        for (k = 0; k <= 255; k = k + 1)                        //for loop to cycle through each test input of Tx_Value
        begin
            Rx_Serial = 0;                                      //Receive start bit
            #1736;
            for (i = 0; i <= 8; i = i + 1)                      //for loop to cycle through each bit of serial input
            begin
                j = (bitTest & Tx_Value);                       //bitwise AND of bitTest and parallel value to be serialized 
                if (j == bitTest)                               //If the current bit of Tx_Value is a 1, send a 1. Else, send a 0.
                    Rx_Serial = 1;
                else
                    Rx_Serial = 0;
                bitTest = bitTest << 1;                         //Shift bitTest left by 1 to test the next significant bit
                #1736;                                          //Wait one bit to test next bit transmission
            end 
            bitTest = 1;                                        //Reset bitTest and Rx_Serial (idles at 1)
            Rx_Serial = 1;
            #1736;
            if (Tx_Value != Rx_Data)                            //Compare serial output data to the parallel input
            begin
                errorCount = errorCount + 1;                            //If mismatch, add 1 to errorCount, print value of input where mismatch occurred
                $display("Mismatch at Tx_Value =  %d", Tx_Value);
            end
            j = 0;                                                      //Reset accumulator
            Tx_Value = Tx_Value + 1;                                    //Increase Tx_Parallel by 1
        end
        $display("Total mismatches =  %d", errorCount);                 //Once finished, output total error count
        $finish;
    end
endmodule
