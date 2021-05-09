// TRIGGER looks at a fpga io and decides when a trigger output is to be signaled
// logic analyzers and oscilloscope have basic trigger functions, but this block adds many more
// Type 0 is basic edge detection (used if your logic analyzer is not fast enough to see the signal pulse)
// type 1 is pulse shorter than defined width
// type 2 is pulse longer than defined width
// type 3 is pulse is longer than first defined width and shorter than second defined width (inside window)
// type 4 is pulse shorter than first defined width OR longer than second defined width (outside window)
// positive or negative edges are selectable
// for type 2 and type 4 a timeout trigger can be selected (THIS IS IMPORTANT), this does not require an io edge to generate a trigger
// for the timeout operation, set cfg_longer_no_edge high.

module scarf_trigger
  ( input  logic       clk,              // fpga clk (either 12MHz or 100MHz)
    input  logic       rst_n_sync,       // active-low reset (push button on fpga board)
    input  logic [7:0] data_in,          // SCARF
    input  logic       data_in_valid,    // SCARF
    input  logic       data_in_finished, // SCARF
    input  logic [6:0] slave_id,         // SCARF
    input  logic       rnw,              // SCARF
    output logic [7:0] read_data_out,    // SCARF
    input  logic       trigger_source,   // TRIGGER source input
    output logic       trigger_out       // TRIGGER out
    );
    
    parameter SLAVE_ID = 7'd04;
    
    // configuration registers from scarf_regmap_trigger
    logic       cfg_enable;
    logic       cfg_positive;
    logic [2:0] cfg_type;
    logic [7:0] cfg_count1;
    logic [7:0] cfg_count2;
    logic [2:0] cfg_time_base;
    logic       cfg_longer_no_edge;
    logic       cfg_12mhz;
  
    scarf_regmap_trigger 
    # ( .SLAVE_ID( SLAVE_ID ) )
    u_scarf_regmap_trigger
    ( .clk,                   // input
      .rst_n_sync,            // input
      .data_in,               // input [7:0]   // SCARF
      .data_in_valid,         // input         // SCARF
      .data_in_finished,      // input         // SCARF
      .slave_id,              // input [6:0]   // SCARF
      .rnw,                   // input         // SCARF
      .read_data_out,         // output [7:0]  // SCARF
      .cfg_enable,            // output
      .cfg_positive,          // output
      .cfg_type,              // output [2:0]
      .cfg_count1,            // output [7:0]
      .cfg_count2,            // output [7:0]
      .cfg_time_base,         // output [2:0]
      .cfg_longer_no_edge,    // output
      .cfg_12mhz              // output
     );
    
    trigger u_trigger
    ( .clk,                   // input
      .rst_n_sync,            // input
      .trigger_source,        // input
      .trigger_out,           // output
      .cfg_enable,            // input
      .cfg_positive,          // input
      .cfg_type,              // input [2:0]
      .cfg_count1,            // input [7:0]
      .cfg_count2,            // input [7:0]
      .cfg_time_base,         // input [2:0]
      .cfg_longer_no_edge,    // input
      .cfg_12mhz              // input
     );
    
endmodule