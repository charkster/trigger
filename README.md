# trigger
SystemVerilog FPGA design of a custom trigger circuit which can be used with oscilloscopes or logic analyzers.
For a description of all supported modes see: https://www.tiepie.com/en/fut/pulse-width-trigger .
The "trigger.sv" file implements all the trigger modes and it fits into a SCARF framework. 
The reason I needed to build this fpga circuit is that I wanted advanced triggering which my logic analyzer did not have. One really cool feature that I wanted is the ability to force a trigger output based on a time-out. For type 2 (pulse longer than) and type 4 (pulse outside window) the "cfg_longer_no_edge" bit can be set high to force a trigger when the pulse exceeds the limit (no edge needed). This was very useful in triggering on a stuck I2C SDA line where SDA remained low permanently.

Three other SCARF-compliant blocks are included: pattern_generator, external_sram and edge_counters.
These designs were all put into a Digilent CMOD A7 fpga board, and I have 2 hardware versions of that board: one with a 12MHz clock and another with a 100MHz clock. The stage1_count for the pattern_generator and trigger blocks can be used to adjust the clock to be a multiple of base 10.
I used the "test_pat_gen2.py" script to show that all the trigger modes work as expected. The pattern_generator block generates the pulses that the trigger block looks at.
So if you have a CMOD A7 board and an oscilloscope or logic analyzer (Amazon has great $12 USB2.0 logic analyzers that do 8 channels at 24MHz) you can try this out as-is. Otherwise you are welcome to use the "trigger.sv" (and all other parts) in your projects.
"scarf_top.sv" is my FGPA top-level.

The included bit and bin files were made using the clk_wiz block (which takes the 12MHz clock and multiplies it to be 100MHz, 10ns period).
"scarf_top.bit" and "scarf_top.bin" can be programmed directly into the CMOD A7. I use the following command on my raspberry pi to program the FPGA:

 xc3sprog -c jtaghs1_fast scarf_top.bit

I compiled xc3sprog from source and added the spi flash chip that this board uses (I have submitted a git pull request). I use this command to program the spi flash:

xc3sprog -c jtaghs1_fast -I scarf_top.bit

 SCARF requires a SPI bus to communicate with the fpga board, so a raspberry pi or a USB SPI adapter is needed.
"CmodA7_Master.xdc" defines all the pin connections needed.
