module Display(                     //This module is responsible for displaying the mode, last received byte
                                    //(in hex, if the device is in receive mode) and the next byte to send 
                                    //(if the device is in transmit mode) 
    input wire Mode,                                       
    input wire [7:0] Data,           //Array which holds the most recently stored word  (Displayed in Rx mode)
    input wire [1:0] Array,
    
    output reg [6:0] C,         //Array responsible for the lighting of each individual segment for a 7-seg display
    output reg [3:0] AN         //Array responsible for controlling which displays are in use 
    );                          //(displaying the current value of C)
    
    wire [3:0] dataLower;     
    wire [3:0] dataUpper;     
    
    assign dataLower    = Data[3:0];                //Byte is split into 2 4-bit arrays, each for representing a hex digit
    assign dataUpper    = Data[7:4];
    
    parameter nine      = 7'b0010000;               //Values of C corresponding to the different numbers and letters used
    parameter eight     = 7'b0000000;               //in displaying hex values
    parameter seven     = 7'b1111000;
    parameter six       = 7'b0000010;
    parameter five      = 7'b0010010;
    parameter four      = 7'b0011001;
    parameter three     = 7'b0110000;
    parameter two       = 7'b0100100;
    parameter one       = 7'b1111001;
    parameter zero      = 7'b1000000;
    parameter A         = 7'b0001000;
    parameter b         = 7'b0000011;
    parameter c         = 7'b1000110;
    parameter d         = 7'b0100001;
    parameter E         = 7'b0000110;
    parameter F         = 7'b0001110;
    parameter S         = 7'b0010010;
    parameter r         = 7'b1001110;
    
    always@(*)
    begin
        case(Array)                         //Displays the first hex character, then the second, then the mode (Either "r" for receiving, "s" for "sending" (transmitting)) 
        0:                                  //while in receive mode. Happens fast enough for all to appear at once
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
            if (Mode)
                C = S;
            else
                C = r;
        end
        
        default: AN = 4'b1111;
                     
        endcase
    end
endmodule

