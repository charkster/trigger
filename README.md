# trigger
SystemVerilog FPGA design of a custom trigger circuit which can be used with oscilloscopes or logic analyzers.
For a description of all supported modes see: https://www.tiepie.com/en/fut/pulse-width-trigger
The "trigger.sv" file implements all the trigger modes and it fits into a SCARF framework. 
The reason I needed to build this fpga circuit is that I wanted advanced triggering which my oscilloscope and logic analyzer did not have. One really cool feature that I have never seen on any high-end oscilloscope or logic analyzer is the ability to force a trigger output based on a time-out. For type 2 (pulse longer than) and type 4 (pulse outside window) the "cfg_longer_no_edge" bit can be set high to force a trigger when the pulse exceeds the limit (no edge needed). This was very useful in triggering on a stuck I2C SDA line where SDA remained low permanently.

Three other SCARF-compliant blocks are included: pattern_generator, external_sram and edge_counters.
These designs were put into a Digilent CMOD A7 fpga board, and I have 2 versions: one with a 12MHz clock and another with a 100MHz clock.
I used the "test_pat_gen2.py" script to show that all the modes work as expected. The pattern_generator block generates the pulses that the trigger block looks at.
So if you have a CMOD A7 board and an oscilloscope or logic analyzer (Amazon has great $12 USB logic analyzers that do 8 channels at 24MHz) you can try this out as-is. Otherwise you are welcome to use the "trigger.sv" in your projects.
"scarf_top.sv" is my FGPA top-level.

"scarf_top_100mhz.bit" and "scarf_top_100mhz.bin" can be programmed directly into the CMOD A7. I use the following command on my raspberry pi to program the FPGA (not the SPI flash memory):

 xc3sprog -c jtaghs1_fast scarf_top_100mhz.bit
 
 I will soon upload the 12mhz versions of the bit and bin files as most CMOD A7 use that board clock frequency.
