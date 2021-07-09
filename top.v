`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2021 03:42:59 PM
// Design Name: 
// Module Name: top
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

module Debounce(
    input switch_in,
    input clk,
    output reg switch_out);
    
    parameter clks_per_switch = 25_000_000;
    reg [25:0] clk_count = 0;
    reg i_switch_in = 0;
    
    //if Enable pressed, send value of enable after a quarter of a second

    always@(posedge clk)
    begin
        i_switch_in <= switch_in;
        if (clk_count == clks_per_switch)
            clk_count <= clk_count + 1;
        else
        begin
            clk_count <= 0;
            switch_out <= i_switch_in;
        end
    end
endmodule

module UART(
    input clk,              //clock signal
    input Mode,             //Controls whether UART is in Rx or Tx mode
    input Enable,           //Enable, controls when data is sent in Tx mode
    input Rx_Serial,         // Serial in, for Rx
    input [7:0] Tx_Parallel, //Parallel in, for Tx
    
    output reg [7:0] Rx_Data, //Parallel Out, for Rx
    output reg Tx_Serial);   //Serial Out, for Tx
    
    parameter clks_per_bit = 868; //corresponding to FPGA clock speed divided by configured baud rate (115200)
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;
    
    reg [9:0] clk_count = 0; //used to count clock cycles, to output bits for the proper # of clock cycles,
                            //or to sample serial input at the correct time (at peak stability)
    reg [2:0] bitIndex = 0; //Used to keep track of which index of parallel data is being transmitted or received
    reg [7:0] r_Rx_Data = 0;
    reg r_DV = 0;           //Data valid boolean. Final step for receiver. When 1, the parallelized data is loaded
    reg [2:0] SM = 0;       //Keeps track of which state the UART is in when receiving or transmitting
    reg [7:0] r_Tx_Parallel = 0;    //Internal register for Tx. Holds parallel data when Enable is active
    
    always@(posedge clk)
    begin
        case(Mode)
        0:
        begin
            case(SM)
            IDLE:
            begin
                clk_count <= 0;
                bitIndex <= 0;
                r_DV <= 0;
                
                if (Rx_Serial == 1'b0)
                    SM <= START;
                else
                    SM <= IDLE;
            end
            START:
            begin
                if (clk_count == clks_per_bit / 2)
                begin
                    if (Rx_Serial == 1'b0)
                    begin
                        SM <= DATA;
                        clk_count <= 0;
                    end
                    else
                        SM <= IDLE;
                end
                else
                begin
                    clk_count <= clk_count + 1;
                    SM <= START;
                end
            end
            DATA:
            begin
                if (clk_count < clks_per_bit)
                begin
                    clk_count <= clk_count + 1;
                    SM <= DATA;
                end
                else
                begin
                    r_Rx_Data[bitIndex] <= Rx_Serial;
                    clk_count <= 0;
                    if (bitIndex < 7)
                    begin
                        bitIndex = bitIndex + 1;
                        SM <= DATA;
                    end
                    else
                    begin
                        bitIndex = 0;
                        SM <= STOP;
                    end
                end
            end
            STOP:
            begin
                if (clk_count < clks_per_bit)
                begin
                    clk_count <= clk_count + 1;
                    SM <= STOP;
                end
                else
                    begin
                        clk_count <= 0;
                        r_DV = 1;
                        SM <= CLEAN;
                    end
            end
            CLEAN:
            begin
               r_DV = 0;
               SM <= IDLE;
            end
           
           default : SM <= IDLE;
           
           endcase
        end
    
        1:
        begin
            case(SM)
            0:      //Waits for enable signal
            begin
            Tx_Serial <= 1;
                case(Enable)
                0:
                    SM <= IDLE;
                1:
                begin
                    r_Tx_Parallel <= Tx_Parallel; //Parallel input is loaded to internal reg
                    SM <= START;
                end
                endcase
            end
            1:      //Sends a start bit
            begin
                Tx_Serial <= 0;
                if (clk_count < clks_per_bit - 1)
                begin
                    clk_count <= clk_count + 1;
                    SM <= START;
                end
                else
                begin
                    bitIndex <= 0;
                    SM <= DATA;
                    clk_count <= 0;
                end
            end
            2:      //Sends each bit of data
            begin
                Tx_Serial <= r_Tx_Parallel[bitIndex];
                if (clk_count < clks_per_bit - 1)
                begin
                    SM <= DATA;
                    clk_count <= clk_count + 1;
                end
                else
                begin
                    if (bitIndex < 7)
                    begin
                        bitIndex <= bitIndex + 1;
                        clk_count <= 0;
                        SM <= DATA;
                    end
                    else 
                    begin
                        bitIndex <= 0;
                        clk_count <= 0;
                        SM <= STOP;
                    end
                end
            end
                
           
            3:      //Sends a stop bit, then returns to IDLE
            begin
                Tx_Serial <= 1;
                if (clk_count < clks_per_bit - 1)
                begin
                    clk_count <= clk_count + 1;
                    SM <= STOP;
                end
                else
                begin
                    case(Enable)        //This case statement ensures that the data is sent once. 
                    0:                  
                    begin               
                        clk_count <= 0;
                        SM <= IDLE;
                    end
                    1:
                        SM <= STOP;
                    endcase
                end
            end
            default: SM <= IDLE;
            endcase
        end
        endcase
    end
        
        
    always@(r_DV)
    begin
        if (r_DV == 1)
            Rx_Data = r_Rx_Data;
    end
  
endmodule      

module Display_Selector(
    input clk,
    output reg [1:0] Array);
    
    reg [19:0] counter = 0;   
    
    always@(posedge clk)
    begin
        counter <= counter + 1;
        if (counter == 200_000)
        begin
            counter <= 0;
            Array <= Array + 1;
        end
    end
endmodule
        

module Display(
    input wire [7:0] Data,
    input wire [1:0] Array,
    input wire Mode,
    output reg [7:1] C,
    output reg [3:0] AN
    );
    
    wire [3:0] dataLower;
    wire [3:0] dataUpper;
    assign dataLower = Data[3:0];
    assign dataUpper = Data[7:4];
    
    //AN 4'b0111 and 4'b1011
    //toggle between very fast
    //One display is responsible for first 4 bits
    //Other is responsible for last 4 bits
    
    parameter nine = 7'b0010000;
    parameter eight = 7'b0000000;
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
    parameter S = 7'b0010010;
    parameter r = 7'b1001110;
    
    //One AN is on, and it displays the Hex digit of the upper half
    //Another AN is on, and it displays the Hex digit of the lower half
    //They toggle on and off fast
    
    always@(Array)
    begin
        case(Array)
            0:
            begin
                AN = 4'b0111;
                case(dataUpper)
                    4'b0000:    C = zero;
                    4'b0001:    C = one;
                    4'b0010:    C = two;
                    4'b0011:    C = three;
                    4'b0100:    C = four;
                    4'b0101:    C = five;
                    4'b0110:    C = six;
                    4'b0111:    C = seven;
                endcase
            end  
            1:
            begin 
                AN = 4'b1011;
                case(dataLower)
                    4'b0000:    C = zero;
                    4'b0001:    C = one;
                    4'b0010:    C = two;
                    4'b0011:    C = three;
                    4'b0100:    C = four;
                    4'b0101:    C = five;
                    4'b0110:    C = six;
                    4'b0111:    C = seven;
                    4'b1000:    C = eight;
                    4'b1001:    C = nine;
                    4'b1010:    C = A;  
                    4'b1011:    C = b;
                    4'b1100:    C = c;
                    4'b1101:    C = d;
                    4'b1110:    C = E;
                    4'b1111:    C = F;
                endcase
            end
            2:
            begin
                AN = 4'b1110;
                case(Mode)
                    0:  C = r;
                    1:  C = S;
                endcase
            end
            
            default: AN = 4'b1111;
        endcase
                    
    end

endmodule

module Sw_Debug(
    input [7:0] switch,
    input clk,
    output reg [7:0] LED);
    
    always@(posedge clk)
        LED <= switch;
endmodule
             
module top(clk, Enable, Mode, Rx_Serial, Tx_Parallel, AN, C, Tx_Serial, Parallel_Out);
    input clk, Enable, Mode, Rx_Serial;
    input wire [7:0] Tx_Parallel;
    wire [7:0] Rx_Data;
    wire [1:0] Array;
    output [3:0] AN;
    output [7:1] C;
    output Tx_Serial;
    output [7:0] Parallel_Out;
    Debounce inst_1(Enable, clk, switch_out);
    UART inst_2(clk, Mode, switch_out, Rx_Serial, Tx_Parallel, Rx_Data, Tx_Serial);
    Display inst_3(Rx_Data, Array, Mode, C, AN);
    Display_Selector inst_4(clk, Array);
    Sw_Debug inst_5(Tx_Parallel, clk, Parallel_Out);
     
endmodule
