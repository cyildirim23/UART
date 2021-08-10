module Debounce_Pulse(      //Module for debouncing input switch, and outputting a pulse
    input switch_in,
    input clk,
    output pulse_out);
    
    Debounce switch_debounce(switch_in, clk, switch);
    Pulse switch_pulse(switch, clk, pulse_out);
    
endmodule