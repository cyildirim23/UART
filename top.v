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
// Description:             All-in-one UART receiver-transmitter, with integrated 4-word FIFO
//                          Stores received words in a FIFO (allows for user input directly from FPGA
//                          as well as through serial port), and sends them one at a time, in the correct 
//                          order, with a switch press. Displays current mode, and depending on mode, displays
//                          either the most recent word written to the FIFO, or the oldest word written (next to be sent)
// Dependencies:        
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Debounce(                    //Module for debouncing a switch input
    input switch_in,
    input clk,
    output reg switch_out);         //Debounced output
    
    parameter clks_per_switch = 25_000_000;
    reg [25:0] clk_count = 0;
    reg i_switch_in = 0;
    
    //if switch pressed, send value of switch after a quarter of a second

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

module UART_Rx(                     //UART Receiver
    input clk,
    input Rx_Serial,                //Serial input
    input wire Mode,                //Mode represents 2 states: receiving or transmitting
    output reg [7:0] Rx_Data,       //Parallel data output
    output reg r_DV = 0             //Data valid ("receive complete" marker)
    );
    
    parameter clks_per_bit = 868;   //# of clocks per bit for a baud rate of 115200 on 
                                    //xc7a35t basys 3 FPGA (100 MHz clock)
    parameter IDLE = 3'b000;        //Different states
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;
    
    reg [9:0] clk_count = 0;
    reg [2:0] bitIndex = 0;     //Data is sent one byte at a time, calling for 8 indices (one index per bit)
    reg [7:0] r_Rx_Data = 0;    //Stores parallel data, shifted into parallel output if valid
    reg [2:0] SM = 0;           //Holds the current state
    
    always@(posedge clk)
    begin
        case(SM)
        IDLE:
        begin
            clk_count <= 0;
            bitIndex <= 0;
            r_DV <= 0;
            if (Rx_Serial == 1'b0 && Mode == 0) //If a start bit is sent, and the device is in receive mode
                SM <= START;                    //Go to "START" state
            else
                SM <= IDLE;                     //Else, stay in idle
        end
        START:      //Verifies that a start bit is being received
        begin
            if (clk_count == clks_per_bit / 2)      //Samples where the middle of the start bit would be
            begin                                   
                if (Rx_Serial == 1'b0)              //If the value is still 0, it is in fact a start bit
                begin                               //So, change states to "DATA", reset clock counter   
                    SM <= DATA;
                    clk_count <= 0;
                end
                else                                //Else, start bit not detected, return to "IDLE"
                    SM <= IDLE;
            end
            else                                //Increment clk_count until clks_per_bit / 2 is reached
            begin                               //and stay in current state (START)
                clk_count <= clk_count + 1;
                SM <= START;
            end
        end
        DATA:                                   //This state stores each bit in an internal reg
        begin                                   //Each full clks_per_bit cycle from here will end mid-bit
            if (clk_count < clks_per_bit)
            begin                               //Make clk_count == clks_per_bit
                clk_count <= clk_count + 1;     
                SM <= DATA;
            end
            else                                    //Once clk_count == clks_per_bit
            begin
                r_Rx_Data[bitIndex] <= Rx_Serial;   //Store the current serial value in the current index 
                clk_count <= 0;                     //of the internal reg
                if (bitIndex < 7)
                begin                               //While max bit index (7) hasn't been reached, repeat above
                    bitIndex = bitIndex + 1;        //with the next index of the internal reg
                    SM <= DATA;
                end
                else                                //Once internal reg is full, reset bitIndex, proceed
                begin                               //to "STOP" state
                    bitIndex <= 0;
                    SM <= STOP;
                end
            end
        end
        STOP:                               //Same idea as "START"; sample where the middle of the next bit would be
        begin
            if (clk_count < clks_per_bit)
            begin
                clk_count <= clk_count + 1;
                SM <= STOP;
            end
            else
            begin
                if(Rx_Serial == 1'b1)       //If the sampled value is 1, the stop bit has ben received
                begin                       //reset clk_count, set r_DV to 1, proceed to "CLEAN" state
                    clk_count <= 0;
                    r_DV = 1;
                    SM <= CLEAN;
                end
            end
        end
        CLEAN:                              //set r_DV back to 0, go to "IDLE"
        begin
           r_DV = 0;
           SM <= IDLE;
        end
       
       default : SM <= IDLE;
       
       endcase
    end
    
    always@(r_DV)                           //if r_DV is ever set to 1 (data has been received)
    begin                                   //update parallel output with value of internal reg
        if (r_DV == 1)
            Rx_Data = r_Rx_Data;
    end
    
endmodule

module UART_Tx(            
    input clk,
    input Enable,            //Enable, when == 1, sends the current parallel input as a serial output
    input wire Mode,         
    input [7:0] Tx_Parallel, //Parallel input, to be sent serially
    output reg Tx_Serial,    //Serial output
    output reg read_enable);  //Used by FIFO to clear a byte after the byte to be transmitted has
                              //been read and stored in the transmitter
    parameter clks_per_bit = 868; 
    
    parameter IDLE = 3'b000;
    parameter LOAD = 3'b001;
    parameter START = 3'b010;
    parameter DATA = 3'b011;
    parameter STOP = 3'b100;
    
    
    reg [9:0] clk_count = 0;        //used to count clock cycles, to output bits for the proper # of clock cycles
    reg [2:0] bitIndex = 0;         //Bit index, used when serializing data
    reg [2:0] SM = 0;               //Represents current state
    reg [7:0] r_Tx_Parallel = 0;    //Internal register. Holds parallel data when Enable is active
    
    always@(posedge clk)
    begin
        case(SM)
            0:      //Waits for enable signal
            begin
            Tx_Serial <= 1;             //Serial output is driven high when not transmitting
                case(Enable)
                0:
                    SM <= IDLE;
                1:                      //If Enable is 1, and device is in transmission mode, 
                begin                   //Begin transmission
                    if (Mode == 1)
                    begin
                        read_enable <= 1;   //Set read_enable to 1, proceed to "LOAD" state
                        SM <= LOAD;
                    end
                end
                endcase
            end
            1: //LOAD           loads input
            begin
                r_Tx_Parallel <= Tx_Parallel; //Parallel input is loaded to internal reg
                SM <= START;                 //Proceed to "START" state
            end
            2: //START     sends a start bit
            begin
                read_enable <= 0;       
                Tx_Serial <= 0;                     //Serial out is driven low for for 868 clocks
                if (clk_count < clks_per_bit - 1)
                begin
                    clk_count <= clk_count + 1;
                    SM <= START;
                end
                else                                //After above is done, proceed to "DATA" state, reset clk count
                begin
                    SM <= DATA;
                    clk_count <= 0;
                end
            end
            3:      //Data      sends each bit of data
            begin
                Tx_Serial <= r_Tx_Parallel[bitIndex];
                if (clk_count < clks_per_bit - 1)              //for 868 clocks, drive the output with the current
                begin                                          //index of the internal reg
                    SM <= DATA;
                    clk_count <= clk_count + 1;
                end
                else                                            //After, increment the index and repeat until
                begin                                           //the last bit is transmitted
                    if (bitIndex < 7)
                    begin
                        bitIndex <= bitIndex + 1;
                        clk_count <= 0;
                        SM <= DATA;
                    end
                    else 
                    begin                                       //After all indices have been transmitted, 
                        bitIndex <= 0;                          //proceed to "STOP" state
                        clk_count <= 0;
                        SM <= STOP;
                    end
                end
            end  
           
            4:      //Sends a stop bit, then returns to IDLE
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

module Display_Selector(    //This module is responsible for showing different messages on the 7-seg display
    input clk,              //to do so, it quickly increments a counter (Array), where each value of Array
    output reg [1:0] Array);    //Corresponds to a specific message on one of the four 7-seg arrays. Array changes 
                                //slow enough to consistently display messages, but fast enough to give the illusion
    reg [19:0] counter = 0;     //of all messages being displayed at once
    
    always@(posedge clk)
    begin
        counter <= counter + 1;
        if (counter == 200_000)     //Every 200_000 clocks, increment Array
        begin
            counter <= 0;
            Array <= Array + 1;
        end
    end
endmodule
        

module Display(                     //This module is responsible for displaying the mode, last received byte
                                    //(in hex, if the device is in receive mode) and the next byte to send 
                                    //(if the device is in transmit mode) 
                                            
    input wire [7:0] Rx_Data,           //Array which holds the most recently stored word  (Displayed in Rx mode)
    input wire [7:0] Tx_Data,           //Array which holds the next word to be sent (Displayed in Tx mode)
    input wire [1:0] Array,
    input wire Mode,
    
    output reg [7:1] C,         //Array responsible for the lighting of each individual segment for a 7-seg display
    output reg [3:0] AN         //Array responsible for controlling which displays are in use 
    );                          //(displaying the current value of C)
    
    //for both Rx_Data and Tx_Data, each array is split in two. Each part is used to determine a hex digit
    
    wire [3:0] r_dataLower;     
    wire [3:0] r_dataUpper;     
    
    wire [3:0] t_dataLower;
    wire [3:0] t_dataUpper;
    
    assign r_dataLower = Rx_Data[3:0];
    assign r_dataUpper = Rx_Data[7:4];
    
    assign t_dataLower = Tx_Data[3:0];
    assign t_dataUpper = Tx_Data[7:4];
    
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
    parameter S = 7'b0010010;
    parameter r = 7'b1001110;
    
    always@(Array)
    begin
        case(Mode)                      //If the device is in receive mode, display the hex value of Rx_Data, 
        0:                              //along with "r" to display the mode
        begin
            case(Array)                         //Displays the first hex character, then the second, then the "r" 
            0:                                  //while in receive mode. Happens fast enough for all to appear at once
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
        1:                                       //Same process outlined above, but with Tx_Data
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

module Sw_Debug(                //This module lights up the LEDs corresponding to a user's input 
                                //(where the input is a byte to be stored in the FIFO)
    input [7:0] switch,         //Input byte (each switch represents a bit)
    input RD,
    input WR,
    input clk,
    output reg [7:0] LED,       //LEDs for each bit
    output reg RD_LED,
    output reg WR_LED);
    
    always@(posedge clk)
    begin
        LED <= switch;
        RD_LED <= RD;
        WR_LED <= WR;
    end
    
endmodule

module FIFO_Unit(                   //This module is for a FIFO. It stores any words received by the receiver
                                    //or any user-inputted byte, and reads them oldest first                              
    input clk, r_DV,
    input wire read_ready,
    input wire Mode,
    input wire user_input,
    input wire [7:0] Rx_dataIn,     //UART receiver input
    input wire [7:0] Parallel_In,   //User input
    output [7:0] dataOut,           //Data output
    output [7:0] r_Display_Data,    //Holds the most recently stored word for display purposes (displayed in Rx mode)
    output reg EMPTY = 1,           //Used to tell if FIFO is empty. Linked to an LED
    output reg FULL = 0,            //Used to tell if FIFO is full. Linked to an LED
    output reg [3:0] counter = 0);  //Used to update EMPTY and FULL flags
    
    reg [7:0] FIFO [3:0];   //FIFO is 8 bits deep, 4 words wide
    reg [1:0] SM = 0;
    reg [2:0] readCount = 0;    //Keeps track of how many read processes 
    reg [2:0] writeCount = 0;   //Keeps track of how many write processes
    
    parameter IDLE = 2'b00;     //Different states
    parameter WRITE = 2'b01;
    parameter READ = 2'b10;
    
    assign dataOut = FIFO[readCount];                   //readCount will always be the index of the oldest word
    assign r_Display_Data = FIFO[writeCount - 1];       //writeCount will always be the index of the most recent word
    
    always@(posedge clk)
    begin
        case(SM)
        0:              //IDLE
        begin
            if (Mode == 0 && FULL != 1)    //If in receive mode, and the FIFO isn't full, go to WRITE
                SM <= WRITE;
            else if (Mode == 1 && EMPTY != 1)  //If in transmit mode, and the FIFO isn't empty, go to READ
                SM <= READ;
            else
                SM <= IDLE;
        end
        1:             //WRITE
        begin
            if(FULL)                            //If FIFO is full, go to IDLE, reset readCount, go to IDLE
            begin
                readCount <= 0;
                SM <= IDLE;
            end
            else if(r_DV == 1)                           //If data is marked as valid by the receiver
            begin
                writeCount <= writeCount + 1;           //Write the word from the appropriate input, go to IDLE
                counter <= counter + 1;                 //Increment counter
                FIFO[counter] <= Rx_dataIn;  
                SM <= IDLE;                     
            end
            else if (user_input == 1)               //If the user is sending a value to the FIFO
            begin                                   //Write the word from the appropriate input, go to IDLE
                writeCount <= writeCount + 1;       //Increment counter
                counter <= counter + 1;
                FIFO[counter] <= Parallel_In;
                SM <= IDLE;
            end
            else                                    //Else, stay in write
                SM <= WRITE;    
        end
        2:          //READ
        begin
            if(EMPTY)                   //If FIFO is empty, reset writeCount, go to IDLE
            begin
                writeCount <= 0;
                SM <= IDLE;
            end
            else if(read_ready == 1)                      //If transmitter begins transmission
            begin                                         //Transmitter takes FIFO[readCount] before setting to 0
                FIFO[readCount] <= 8'b00000000;
                counter <= counter - 1;                   //Decrement counter
                readCount <= readCount + 1;               //Increment readCount
                SM <= IDLE;                               //Go to IDLE
            end
            else                                          //Else, stay in READ
                SM <= READ;
        end
        endcase
        
        case(counter)               //EMPTY/FULL flags updated according to counter
            0:
            begin
                EMPTY <= 1;
                FULL <= 0;
            end
            4:
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
                                //This module creates a pulse from an input switch. If a switch is
                                //Turned on, the output stays on for 2 clock cycles, the returns to 0
    reg pulse = 0;              //Output
    reg counter = 0;            //Used to determine how long pulse lasts
    reg lock = 0;               //Used to keep the output at 0 after a pulse, if the input is still high
    
    always@(posedge clk)
    begin
        switch_out <= pulse;
        if (switch == 1 && lock == 0)
        begin
            pulse <= 1;
            counter <= counter + 1;
            if (counter == 1)           //This condition is met one clock cycle after high input begins
            begin
                lock <= 1;
                pulse <= 0;
                counter <= 0;     
            end
        end
        else if (switch == 0)           //If input goes back to 0, turn lock off, output goes to 0.
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
    wire [2:0] counter;
    wire [7:0] r_Display_Data;
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
    Display inst_3(r_Display_Data, dataOut, Array, Mode, C, AN);
    Display_Selector inst_4(clk, Array);
    Sw_Debug inst_5(Parallel_In, RD, WR, clk, Parallel_Out, RD_LED, WR_LED);
    FIFO_Unit inst_6(clk, r_DV, read_enable, Mode, pulse_out, Rx_Data, Parallel_In, dataOut, r_Display_Data,
    EMPTY, FULL, counter); 
    Pulse inst_8(Load, clk, pulse_out);
endmodule
