module UART_Tx(            
    input clk,
    input Enable,            //Enable, when == 1, sends the current parallel input as a serial output         
    input [7:0] Tx_Parallel, //Parallel input, to be sent serially
    output reg Tx_Serial);    //Serial output
    //output reg read_enable);  //Used by FIFO to clear a byte after the byte to be transmitted has
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
                if (Enable == 1)
                begin
                    //read_enable <= 1;   //Set read_enable to 1, proceed to "LOAD" state
                    SM <= LOAD;
                end
                else
                    SM <= IDLE;
            end
            1: //LOAD           loads input
            begin
                r_Tx_Parallel <= Tx_Parallel; //Parallel input is loaded to internal reg
                SM <= START;                 //Proceed to "START" state
            end
            2: //START     sends a start bit
            begin
                //read_enable <= 0;       
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
                    SM <= IDLE;
                    clk_count <= 0;
                    /*
                    case(Enable)        //This case statement ensures that the data is sent once. 
                    0:                  
                    begin               
                        clk_count <= 0;
                        SM <= IDLE;
                    end
                    1:
                        SM <= STOP;
                    endcase
                        */
                end
            end
   
            default: SM <= IDLE;
        endcase
    end
endmodule         