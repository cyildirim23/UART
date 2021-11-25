`timescale 1ns / 1ps

/*
    This module holds control logic for the UART receiver and transmitter, namely the logic
    that controls the baud rate for both modules
*/


module Variable_BR_Wrapper(

    input clk, 
    input Rx,                                                                   //UART Rx input
    input Enable,                                                               //Enable for Tx
    input [2:0] BR_Select,                                                      //Baud rate select
    input [7:0] Tx_Data,                                                        //Data to transmit
    output Tx,                                                                  //UART Tx for output
    output [7:0] Rx_Data                                                        //Data received
    );
    
    wire Tx_Ready;                                                              //Wire from Tx module, indicating no active transmission if high
    wire Rx_Ready;                                                              //Wire from Rx module, indicating no active transmission if high
    reg [14:0] BR_Clocks;                                                       //Number of clock cycles for 1 bit to be sent or recieved, depending on baud rate and FPGA clock (100MHz)
    
    always@(posedge clk)
    begin
        if (Tx_Ready && Rx_Ready)                                               //If no transmissions are active, set desired baud rate
        begin
            case(BR_Select)
                0:  BR_Clocks <= 15'd20834;                                   //Selected baud is 4800
                1:  BR_Clocks <= 15'd10417;                                   //Selected baud is 9600  
                2:  BR_Clocks <= 15'd6945;                                    //Selected baud is 14400
                3:  BR_Clocks <= 15'd5208;                                    //Selected baud is 19200
                4:  BR_Clocks <= 15'd2604;                                    //Selected baud is 38400
                5:  BR_Clocks <= 15'd1736;                                    //Selected baud is 57600
                6:  BR_Clocks <= 15'd868;                                     //Selected baud is 115200
                7:  BR_Clocks <= 15'd434;                                     //Selected baud is 230400
            endcase
        end
    end
    
    
    UART_Rx Receiver(.clk(clk), .BR_Clocks(BR_Clocks), .Rx_Serial(Rx), .Rx_Data(Rx_Data), .r_DV(Data_Ready), .Rx_Ready(Rx_Ready));                //UART receiver module instantiation
    UART_Tx Transmitter(.clk(clk), .BR_Clocks(BR_Clocks), .Tx_Serial(Tx), .Tx_Parallel(Tx_Data), .Enable(Enable), .Tx_Ready(Tx_Ready));           //UART transmitter module instantiation
    
endmodule
