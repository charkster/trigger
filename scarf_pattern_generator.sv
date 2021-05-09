// pattern generator will read bytes from on-board SRAM and send them to fpga pins as output
// byte data from the SRAM can be sent out on 1, 2, 4 or 8 pins (selectable)
// byte data from SRAM can be looped, so that a small pattern of SRAM data can be repeated (selectable) 

module scarf_pattern_generator
  ( input  logic        clk,              // fpga clk (either 12MHz or 100MHz)
    input  logic        rst_n_sync,       // active-low reset (push button on fpga board)
    input  logic  [7:0] data_in,          // SCARF
    input  logic        data_in_valid,    // SCARF
    input  logic        data_in_finished, // SCARF
    input  logic  [6:0] slave_id,         // SCARF
    input  logic        rnw,              // SCARF
    output logic  [7:0] read_data_out,    // SCARF
    output logic        pattern_active,   // when high the SRAM will be read from by this block, else SRAM can be read/written to by SCARF
    output logic        pattern_done,     // fpga output signal that indicates that all selected SRAM data has been driven
    output logic  [7:0] gpio_pat_gen_out, // fpga output signals (from SRAM values)
    input  logic  [7:0] sram_data,        // SRAM data
    output logic [18:0] sram_addr_pat_gen // SRAM address
    );
    
   parameter SLAVE_ID = 7'd01;
   
   logic [23:0] cfg_end_address_pat_gen;
   logic        cfg_enable_pat_gen;
   logic  [1:0] cfg_num_gpio_sel_pat_gen;
   logic  [2:0] cfg_timestep_sel_pat_gen;
   logic        cfg_repeat_enable_pat_gen;
   logic  [3:0] cfg_stage1_count_sel_pat_gen;
   
   scarf_regmap 
   # ( .SLAVE_ID( SLAVE_ID ) )
   u_scarf_regmap_pattern_gen
     ( .clk,                         // input
       .rst_n_sync,                  // input
       .data_in,                     // input [7:0]
       .data_in_valid,               // input
       .data_in_finished,            // input
       .slave_id,                    // input [6:0]
       .rnw,                         // input
       .read_data_out,               // output [7:0]
       .cfg_end_address_pat_gen,     // output [23:0]
       .cfg_enable_pat_gen,          // output
       .cfg_repeat_enable_pat_gen,   // output
       .cfg_num_gpio_sel_pat_gen,    // output [1:0]
       .cfg_timestep_sel_pat_gen,    // output [2:0]
       .cfg_stage1_count_sel_pat_gen // output [3:0]
      );
      
   pattern_gen u_pattern_gen
     ( .clk,                              // input
       .rst_n               (rst_n_sync), // input
       .cfg_enable_pat_gen,               // input
       .cfg_end_address_pat_gen,          // input  [23:0]
       .cfg_num_gpio_sel_pat_gen,         // input  [1:0]
       .cfg_timestep_sel_pat_gen,         // input  [2:0]
       .cfg_stage1_count_sel_pat_gen,     // input  [3:0]
       .cfg_repeat_enable_pat_gen,        // input
       .pattern_active,                   // output
       .pattern_done,                     // output
       .gpio_pat_gen_out,                 // output [7:0]
       .sram_data,                        // input  [7:0]
       .sram_addr_pat_gen                 // output [18:0]
       );
       
 endmodule