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
    input clk,
    input Rx_Serial,
    output reg [7:0] Rx_Data
    
    );
    parameter clks_per_bit = 868;
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;
    
    reg [9:0] clk_count = 0;
    reg [2:0] bitIndex = 0;
    reg [7:0] r_Rx_Data = 0;
    reg r_DV = 0;
    reg [2:0] SM = 0;
    
    always@(posedge clk)
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
    
    always@(r_DV)
    begin
        if (r_DV == 1)
            Rx_Data = r_Rx_Data;
    end
    
endmodule

module UART_Tx(            
    input clk,
    input Enable,           //Enable, mapped to a switch
    input [7:0] Tx_Parallel, //Each bit mapped to a switch (8)
    output reg Tx_Serial);   //Mapped to UART Tx
    
    parameter clks_per_bit = 868; //corresponding to FPGA clock speed divided by configured baud rate (115200)
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;
    
    reg [9:0] clk_count = 0;        //used to count clock cycles, to output bits for the proper # of clock cycles
    reg [2:0] bitIndex = 0;         //Bit index, used when serializing data
    reg [2:0] SM = 0;               //Represents current state
    reg [7:0] r_Tx_Parallel = 0;    //Internal register. Holds parallel data when Enable is active
    
    always@(posedge clk)
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
endmodule    

module Slow_Clock(
    input clk,
    output reg clk_out);
    
    reg [19:0] counter = 0;   
    
    always@(posedge clk)
    begin
        counter <= counter + 1;
        if (counter == 200_000)
        begin
            counter <= 0;
            clk_out <= ~clk_out;
        end
    end
endmodule
        

module Display(
    input wire [7:0] Data,
    input wire clk_out,
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
    
    //One AN is on, and it displays the Hex digit of the upper half
    //Another AN is on, and it displays the Hex digit of the lower half
    //They toggle on and off fast
    
    always@(clk_out)
    begin
        if (clk_out == 0)
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
        else
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
    end

endmodule

module Sw_Debug(
    input [7:0] switch,
    input clk,
    output reg [7:0] LED);
    
    always@(posedge clk)
        LED <= switch;
endmodule
    
      
            
             
module top(clk, Enable, Tx_Parallel, AN, C, Tx_Serial, Parallel_Out);
    input clk, Enable;
    input wire [7:0] Tx_Parallel;
    output [3:0] AN;
    output [7:1] C;
    output Tx_Serial;
    output [7:0] Parallel_Out;
    UART inst_1(clk, switch_out, Tx_Parallel, Tx_Serial);
    //UART_Rx inst_2(clk, Rx_Serial, Data);
    Display inst_3(Tx_Parallel, clk_out, C, AN);
    Slow_Clock inst_4(clk, clk_out);
    Sw_Debug inst_5(Tx_Parallel, clk, Parallel_Out);
    Debounce inst_6(Enable, clk, switch_out);
    
    
   
endmodule