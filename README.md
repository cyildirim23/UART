# UART
Anything related to Basys 3 UART (Rx, Tx, bigger project)

This version is completely functional at its core. 
In receive mode, it will store any byte typed through a terminal (set up with a baud rate of 115200, no parity, 8 data bits) in a FIFO.
It will also store any user-entered byte (using the eight data switches) once if the Load switch is on.
In transmit (send) mode, it will send the bytes that are stored in the FIFO in the correct order. One word sent per enable.

Next step is to have the display show the most recently stored word when in receive mode, and show the next word to be sent when in transmit mode.
