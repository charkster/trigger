# trigger
SystemVerilog FPGA design of a custom trigger circuit which can be used with oscilloscopes or logic analyzers.
For a description of all supported modes see: https://www.tiepie.com/en/fut/pulse-width-trigger
The "trigger.sv" file implements all the trigger modes, but it fits into a SCARF framework. 
Three other SCARF-compliant blocks are included: pattern_generator, external_sram and edge_counters.
These designs were put into a Digilent CMOD A7 fpga board, and I have 2 versions: one with a 12MHz clock and another with a 100MHz clock.
I used the "test_pat_gen2.py" script to show that all the modes work as expected. The pattern_generator block generates the pulses that the trigger block looks at.
So if you have a CMOD A7 board and an oscilloscope or logic analyzer (Amazon has great $12 USB logic analyzers that do 8 channels at 24MHz) you can try this out as-is. Otherwise you are welcome to use the "trigger.sv" in your projects.
"scarf_top.sv" is my FGPA top-level.
