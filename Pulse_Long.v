module Pulse_Long(input r_DV, user_input, clk, output reg switch_out); 
                                //This module creates a pulse from an input switch. If a switch is
                                //Turned on, the output stays on for 2 clock cycles, the returns to 0
    reg pulse = 0;              //Output
    reg [26:0] counter = 0;            //Used to determine how long pulse lasts
    reg lock = 0;               //Used to keep the output at 0 after a pulse, if the input is still high
    
    always@(posedge clk)
    begin
        switch_out <= pulse;
        if (user_input == 1 || r_DV == 1 || lock == 1)
        begin
            pulse <= 1;
            counter <= counter + 1;
            lock <= 1;
            if (counter == 128_000_000)           //This condition is met one clock cycle after high input begins
            begin
                lock <= 0;
                pulse <= 0;
                counter <= 0;     
            end
        end
    end
endmodule