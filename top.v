module top(clk, Enable, Rx_Serial, Load, Parallel_In, AN, C, Tx_Serial, Parallel_Out,
    EMPTY, FULL);
    input clk, Enable, Rx_Serial, Load;
    input wire [7:0] Parallel_In;
    wire [7:0] Rx_Data;
    wire [7:0] Tx_Data;
    wire [7:0] dataOut;
    wire [1:0] Array;
    wire write_ready;
    wire receive_pulse;
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
    output EMPTY;
    output FULL;
    Debounce_Pulse Enable_Pulse(Enable, clk, switch_out);
    Debounce_Pulse user_input_Pulse(Load, clk, pulse_out);
    UART_Rx inst_2(clk, Rx_Serial, Rx_Data, r_DV);
    UART_Tx inst_7(clk, switch_out, dataOut, Tx_Serial, read_enable);
    Display inst_3(r_Display_Data, dataOut, Array, receive_pulse, C, AN);
    Display_Selector inst_4(clk, Array);
    Pulse_Long Rx_Timed_Display(r_DV, pulse_out, clk, receive_pulse);
    Sw_Debug inst_5(Parallel_In, RD, WR, clk, Parallel_Out, RD_LED, WR_LED);
    FIFO_Unit inst_6(clk, r_DV, read_enable, pulse_out, Rx_Data, Parallel_In, dataOut, r_Display_Data,
    EMPTY, FULL); 
endmodule