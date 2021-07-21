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
        begin
            clk_count <= 0;
            switch_out <= i_switch_in;
        end
        else
            clk_count <= clk_count + 1;
    end
endmodule

module UART_Rx(
    input clk,
    input Rx_Serial,
    input wire Mode,
    output reg [7:0] Rx_Data,
    output reg r_DV = 0
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
    reg [2:0] SM = 0;
    
    always@(posedge clk)
    begin
        case(SM)
        IDLE:
        begin
            clk_count <= 0;
            bitIndex <= 0;
            r_DV <= 0;
            
            if (Rx_Serial == 1'b0 && Mode == 0)
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
                    bitIndex <= 0;
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
    input Enable, 
    input wire Mode,          //Enable, mapped to a switch
    input [7:0] Tx_Parallel, //Each bit mapped to a switch (8)
    output reg Tx_Serial,
    output reg read_enable);   //Mapped to UART Tx
    
    parameter clks_per_bit = 868; //corresponding to FPGA clock speed divided by configured baud rate (115200)
    parameter IDLE = 3'b000;
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter LOAD = 3'b100;
    
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
                    if (Mode == 1)
                    begin
                        read_enable <= 1;
                        SM <= LOAD;
                    end
                end
                endcase
            end
            1:      //Sends a start bit
            begin
                read_enable <= 0;
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
            4:
            begin
                r_Tx_Parallel <= Tx_Parallel; //Parallel input is loaded to internal reg
                SM <= START;
            end
            default: SM <= IDLE;
        endcase
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
    input wire [7:0] Rx_Data,
    input wire [7:0] Tx_Data,
    input wire [1:0] Array,
    input wire Mode,
    
    output reg [7:1] C,
    output reg [3:0] AN
    );
    
    wire [3:0] r_dataLower;
    wire [3:0] r_dataUpper;
    wire [3:0] t_dataLower;
    wire [3:0] t_dataUpper;
    assign r_dataLower = Rx_Data[3:0];
    assign r_dataUpper = Rx_Data[7:4];
    assign t_dataLower = Tx_Data[3:0];
    assign t_dataUpper = Tx_Data[7:4];
    
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
        case(Mode)
        0:
        begin
            case(Array)
            0:
            begin
                AN = 4'b0111;
                case(r_dataUpper)
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
                case(r_dataLower)
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
                C = r;
            end
            
            default: AN = 4'b1111;
            
            endcase                
        end
        1:
        begin
            case(Array)
                0:
                begin
                    AN = 4'b0111;
                    case(t_dataUpper)
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
                    case(t_dataLower)
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
                    C = S;
                end
                
                default: AN = 4'b1111;
            endcase
        end
        endcase
    end
endmodule

module Sw_Debug(
    input [7:0] switch,
    input RD,
    input WR,
    input clk,
    output reg [7:0] LED,
    output reg RD_LED,
    output reg WR_LED);
    
    always@(posedge clk)
    begin
        LED <= switch;
        RD_LED <= RD;
        WR_LED <= WR;
    end
    
endmodule

module FIFO_Unit(
    input clk, r_DV,
    input wire read_ready,
    input wire Mode,
    input wire user_input,
    input wire [7:0] Rx_dataIn,
    input wire [7:0] Parallel_In,
    output [7:0] dataOut,
    output reg EMPTY = 1,
    output reg FULL = 0,
    output reg [1:0] counter = 0);
    
    reg [7:0] FIFO [1:0];
    reg [1:0] SM = 0;
    reg readCount = 0;
    
    parameter IDLE = 2'b00;
    parameter WRITE = 2'b01;
    parameter READ = 2'b10;
    
    assign dataOut = FIFO[readCount];
    
    always@(posedge clk)
    begin
        case(SM)
        0:
        begin
            if (Mode == 0 && FULL != 1)    //Write process for Rx Data
                SM <= WRITE;
            else if (Mode == 1 && EMPTY != 1)  //Read process
                SM <= READ;
            else
                SM <= IDLE;
        end
        1:
        begin
            if(FULL)
            begin
                readCount <= 0;
                SM <= IDLE;
            end
            else if(r_DV == 1)                           //If data is marked as valid by the receiver
            begin
                counter <= counter + 1;
                FIFO[counter] <= Rx_dataIn;  
                SM <= IDLE;                     //Received word is written to FIFO
            end
            else if (user_input == 1)
            begin
                counter <= counter + 1;
                FIFO[counter] <= Parallel_In;
                SM <= IDLE;
            end
            else
                SM <= WRITE;    
        end
        2:
        begin
            if(EMPTY)
            begin
                SM <= IDLE;
            end
            else if(read_ready == 1)                      //If transmitter begins transmittion
            begin
                counter <= counter - 1;
                readCount <= readCount + 1;
                FIFO[readCount] <= 8'b00000000;         //Word to be sent is the oldest one in FIFO 
                SM <= IDLE;                    
            end
            else
                SM <= READ;
        end
        endcase
        
        case(counter)               //EMPTY/FULL flags updated according to counter
            0:
            begin
                EMPTY <= 1;
                FULL <= 0;
            end
            2:
            begin
                EMPTY <= 0;
                FULL <= 1;
            end
            default:
            begin
                EMPTY <= 0;
                FULL <= 0;
            end
        endcase
    end
endmodule

module Pulse(input switch, clk, output reg switch_out);

    reg pulse = 0;
    reg counter = 0;
    reg lock = 0;
    
    always@(posedge clk)
    begin
        switch_out <= pulse;
        if (switch == 1 && lock == 0)
        begin
            pulse <= 1;
            counter <= counter + 1;
            if (counter == 1)
            begin
                lock <= 1;
                pulse <= 0;
                counter <= 0;     
            end
        end
        else if (switch == 0)
        begin
            lock <= 0;
            pulse <= 0;
        end
    end
endmodule
            
             
module top(clk, Enable, Mode, Rx_Serial, Load, Parallel_In, AN, C, Tx_Serial, Parallel_Out,
    RD_LED, WR_LED, EMPTY, FULL);
    input clk, Enable, Mode, Rx_Serial, Load;
    input wire [7:0] Parallel_In;
    wire [7:0] Rx_Data;
    wire [7:0] Tx_Data;
    wire [7:0] dataOut;
    wire [1:0] Array;
    wire write_ready;
    wire Mode;
    wire switch_out;
    wire r_DV;
    wire pulse_out;
    wire read_enable;
    wire FIFO_RD_FLAG;
    wire [1:0] counter;
    output [3:0] AN;
    output [7:1] C;
    output Tx_Serial;
    output [7:0] Parallel_Out;
    output RD_LED;
    output WR_LED;
    output EMPTY;
    output FULL;
    Debounce inst_1(Enable, clk, switch_out);
    UART_Rx inst_2(clk, Rx_Serial, Mode, Rx_Data, r_DV);
    UART_Tx inst_7(clk, switch_out, Mode, dataOut, Tx_Serial, read_enable);
    Display inst_3(Rx_Data, dataOut, Array, Mode, C, AN);
    Display_Selector inst_4(clk, Array);
    Sw_Debug inst_5(Parallel_In, RD, WR, clk, Parallel_Out, RD_LED, WR_LED);
    FIFO_Unit inst_6(clk, r_DV, read_enable, Mode, pulse_out, Rx_Data, Parallel_In, dataOut, EMPTY, FULL, counter); 
    Pulse inst_8(Load, clk, pulse_out);
endmodule
