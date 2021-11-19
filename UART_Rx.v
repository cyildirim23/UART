module UART_Rx(                                     //UART Receiver
    input clk,
    input Rx_Serial,                                //Serial input                
    output reg [7:0] Rx_Data,                       //Parallel data output
    output reg r_DV = 0                             //Data valid ("receive complete" marker)
    );
    
    parameter clks_per_bit = 868;                   //# of clocks per bit for a baud rate of 115200 on 
                                                    //xc7a35t basys 3 FPGA (100 MHz clock)
    parameter IDLE = 3'b000;                        //Different states
    parameter START = 3'b001;
    parameter DATA = 3'b010;
    parameter STOP = 3'b011;
    parameter CLEAN = 3'b100;
    
    reg [9:0] clk_count = 0;
    reg [2:0] bitIndex = 0;                         //Data is sent one byte at a time, calling for 8 indices (one index per bit)
    reg [7:0] r_Rx_Data = 0;                        //Stores parallel data, shifted into parallel output if valid
    reg [2:0] SM = 0;                               //Holds the current state
    
    always@(posedge clk)
    begin
        if (r_DV == 1)                              //if r_DV is ever set to 1 (data has been received)
            Rx_Data = r_Rx_Data;        
        case(SM)
        IDLE:
        begin
            clk_count <= 0;
            bitIndex <= 0;
            r_DV <= 0;
            if (Rx_Serial == 0)                     //If a start bit is sent, and the device is in receive mode
                SM <= START;                        //Go to "START" state
            else
                SM <= IDLE;                         //Else, stay in idle
        end
        START:                                      //Verifies that a start bit is being received
        begin
            if (clk_count == clks_per_bit / 2)      //Samples where the middle of the start bit would be
            begin                                   
                if (Rx_Serial == 0)                 //If the value is still 0, it is in fact a start bit
                begin                               //So, change states to "DATA", reset clock counter   
                    SM <= DATA;
                    clk_count <= 0;
                end
                else                                //Else, start bit not detected, return to "IDLE"
                    SM <= IDLE;
            end
            else                                    //Increment clk_count until clks_per_bit / 2 is reached
            begin                                   //and stay in current state (START)
                clk_count <= clk_count + 1;
                SM <= START;
            end
        end
        DATA:                                       //This state stores each bit in an internal reg
        begin                                       //Each full clks_per_bit cycle from here will end mid-bit
            if (clk_count < clks_per_bit)
            begin                                   //Make clk_count == clks_per_bit
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
        STOP:                                       //Same idea as "START"; sample where the middle of the next bit would be
        begin
            if (clk_count < clks_per_bit)
            begin
                clk_count <= clk_count + 1;
                SM <= STOP;
            end
            else
            begin
                if(Rx_Serial == 1'b1)               //If the sampled value is 1, the stop bit has ben received
                begin                               //reset clk_count, set r_DV to 1, proceed to "CLEAN" state
                    clk_count <= 0;
                    r_DV = 1;
                    SM <= CLEAN;
                end
            end
        end
        CLEAN:                                      //go to "IDLE" state, reset r_Dv
        begin
            r_DV <= 0;
            SM <= IDLE;
        end
       
       default : SM <= IDLE;
       
       endcase
    end
    
endmodule