`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2021 03:31:04 PM
// Design Name: 
// Module Name: Display
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


module Display(                     //This module is responsible for displaying the mode, last received byte
                                    //(in hex, if the device is in receive mode) and the next byte to send 
                                    //(if the device is in transmit mode) 
                                            
    input wire [7:0] Rx_Data,
                               //Array which holds the most recently stored word  (Displayed in Rx mode)
    input wire Array,
    input wire receive_pulse,
    
    output reg [7:1] C,         //Array responsible for the lighting of each individual segment for a 7-seg display
    output reg [3:0] AN         //Array responsible for controlling which displays are in use 
    );                          //(displaying the current value of C)
    
    //for both Rx_Data and Tx_Data, each array is split in two. Each part is used to determine a hex digit
    
    parameter nine = 7'b0010000;                //Values of C corresponding to the different numbers and letters used
    parameter eight = 7'b0000000;               //in displaying hex values
    parameter seven = 7'b1111000;
    parameter six = 7'b0000010;
    parameter five = 7'b0010010;
    parameter four = 7'b0011001;
    parameter three = 7'b0110000;
    parameter two = 7'b0100100;
    parameter one = 7'b1111001;
    parameter zero = 7'b1000000;
    parameter A = 7'b0001000;
    parameter b = 7'b0000011;
    parameter c = 7'b1000110;
    parameter d = 7'b0100001;
    parameter E = 7'b0000110;
    parameter F = 7'b0001110;
    parameter L = 7'b1000111;
    parameter S = 7'b0010010;
    parameter r = 7'b1001110;
    parameter U = 7'b1000001;
    
    parameter blank = 7'b1111111;
    
    parameter gas = 8'b01110100;
    parameter brake = 8'b01110110;
    parameter left = 8'b01110111;
    parameter right = 8'b01110101;
    parameter gas_left = 8'b01110001;
    parameter gas_right = 8'b01110000;
    parameter brake_left = 8'b01110011;
    parameter brake_right = 8'b01110010; 
    
    always@(Array)
    begin
        if(receive_pulse == 1)
        begin
            case(Array)                         //Displays the first hex character, then the second, then the "r" 
            0:                                  //while in receive mode. Happens fast enough for all to appear at once
            begin
                AN = 4'b1101;
                case(Rx_Data)
                    left:           C = blank;
                    gas_left:       C = U;
                    gas_right:      C = U;
                    gas:            C = U;
                    brake_left:     C = b;
                    brake_right:    C = b;
                    brake:          C = b; 
                    right:          C = blank;
                    default:        C = blank;      
                endcase
            end  
            1:
            begin 
                AN = 4'b1110;
                case(Rx_Data)
                    left:           C = L;
                    gas_left:       C = L;
                    gas_right:      C = r;
                    gas:            C = blank;
                    brake_left:     C = L;
                    brake_right:    C = r;
                    brake:          C = blank;  
                    right:          C = r; 
                    default:        C = blank;      
                endcase
            end
            endcase                
        end
        else                                       //Same process outlined above, but with Tx_Data
            AN = 4'b1111;
       
    end
endmodule