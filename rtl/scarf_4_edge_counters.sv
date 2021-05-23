// Four instances of EDGE COUNTERS, each instance has 3 x 32bit registers that hold the number of fpga clocks between each edge toggle
// EDGE COUNTER instances allow for a trigger-in and a trigger-out, which can be connected to other instances
// each EDGE counter instance looks at a unique fpga io input, but the trigger-out can start counting before the io toggles
// this allows different io signals to be compared with registers holding the durations 

module scarf_4_edge_counters
  ( input  logic        clk,              // fpga clk (either 12MHz or 100MHz)
    input  logic        rst_n_sync,       // active-low reset (push button on fpga board)
    input  logic  [7:0] data_in,          // SCARF
    input  logic        data_in_valid,    // SCARF
    input  logic        data_in_finished, // SCARF
    input  logic  [6:0] slave_id,         // SCARF
    input  logic        rnw,              // SCARF
    output logic  [7:0] read_data_out,    // SCARF
    input  logic        gpio_0_in,        // EDGE COUNTER input 0
    input  logic        gpio_1_in,        // EDGE COUNTER input 1
    input  logic        gpio_2_in,        // EDGE COUNTER input 2
    input  logic        gpio_3_in         // EDGE COUNTER input 3
    );
    
   parameter SLAVE_ID = 7'd03;
   
   logic        trig_out_0;      // this is a trigger output from EDGE COUNTER instance 0, which feeds into other EDGE COUTNER instances
   logic        trig_out_1;      // this is a trigger output from EDGE COUNTER instance 1, which feeds into other EDGE COUTNER instances
   logic        trig_out_2;      // this is a trigger output from EDGE COUNTER instance 2, which feeds into other EDGE COUTNER instances
   logic        trig_out_3;      // this is a trigger output from EDGE COUNTER instance 3, which feeds into other EDGE COUTNER instances
   logic  [3:0] cfg_trig_out;    // 4 bits, one for each EDGE COUNTER instance
   logic  [3:0] cfg_in_inv;      // 4 bits, one for each EDGE COUNTER instance
   logic  [3:0] cfg_enable;      // 4 bits, one for each EDGE COUNTER instance
   logic  [3:0] cfg_trig_enable; // 4 bits, one for each EDGE COUNTER instance
   logic [31:0] d1_count_0;      // D1 counter value from EDGE COUNTER instance 0
   logic [31:0] d2_count_0;      // D2 counter value from EDGE COUNTER instance 0
   logic [31:0] d3_count_0;      // D3 counter value from EDGE COUNTER instance 0
   logic [31:0] d1_count_1;      // D1 counter value from EDGE COUNTER instance 1
   logic [31:0] d2_count_1;      // D2 counter value from EDGE COUNTER instance 1
   logic [31:0] d3_count_1;      // D3 counter value from EDGE COUNTER instance 1
   logic [31:0] d1_count_2;      // D1 counter value from EDGE COUNTER instance 2
   logic [31:0] d2_count_2;      // D2 counter value from EDGE COUNTER instance 2
   logic [31:0] d3_count_2;      // D3 counter value from EDGE COUNTER instance 2
   logic [31:0] d1_count_3;      // D1 counter value from EDGE COUNTER instance 3
   logic [31:0] d2_count_3;      // D2 counter value from EDGE COUNTER instance 3
   logic [31:0] d3_count_3;      // D3 counter value from EDGE COUNTER instance 3


   scarf_regmap_4_edge_counters 
   # ( .SLAVE_ID( SLAVE_ID ) )
   u_scarf_regmap_4_edge_counters
     ( .clk,                   // input
       .rst_n_sync,            // input
       .data_in,               // input [7:0]
       .data_in_valid,         // input
       .data_in_finished,      // input
       .slave_id,              // input [6:0]
       .rnw,                   // input
       .read_data_out,         // output [7:0]
       .cfg_trig_out,          // output [3:0]
       .cfg_in_inv,            // output [3:0]
       .cfg_enable,            // output [3:0]
       .cfg_trig_enable,       // output [3:0]
       .d1_count_0,            // input  [31:0]
       .d2_count_0,            // input  [31:0]
       .d3_count_0,            // input  [31:0]
       .d1_count_1,            // input  [31:0]
       .d2_count_1,            // input  [31:0]
       .d3_count_1,            // input  [31:0]
       .d1_count_2,            // input  [31:0]
       .d2_count_2,            // input  [31:0]
       .d3_count_2,            // input  [31:0]
       .d1_count_3,            // input  [31:0]
       .d2_count_3,            // input  [31:0]
       .d3_count_3             // input  [31:0]
      );

   edge_counter u_edge_counter_0
     ( .clk,                                      // input
       .rst_n               (rst_n_sync),         // input
       .gpio_in             (gpio_0_in),          // input
       .cfg_enable          (cfg_enable[0]),      // input
       .cfg_trig_enable     (cfg_trig_enable[0]), // input
       .trig_in             (trig_out_3),         // input
       .trig_out            (trig_out_0),         // output
       .cfg_trig_out        (cfg_trig_out[0]),    // input
       .cfg_in_inv          (cfg_in_inv[0]),      // input
       .d1_count            (d1_count_0),         // output [31:0]
       .d2_count            (d2_count_0),         // output [31:0]
       .d3_count            (d3_count_0)          // output [31:0]
       );

   edge_counter u_edge_counter_1
     ( .clk,                                      // input
       .rst_n               (rst_n_sync),         // input
       .gpio_in             (gpio_1_in),          // input
       .cfg_enable          (cfg_enable[1]),      // input
       .cfg_trig_enable     (cfg_trig_enable[1]), // input
       .trig_in             (trig_out_0),         // input
       .trig_out            (trig_out_1),         // output
       .cfg_trig_out        (cfg_trig_out[1]),    // input
       .cfg_in_inv          (cfg_in_inv[1]),      // input
       .d1_count            (d1_count_1),         // output [31:0]
       .d2_count            (d2_count_1),         // output [31:0]
       .d3_count            (d3_count_1)          // output [31:0]
       );

   edge_counter u_edge_counter_2
     ( .clk,                                      // input
       .rst_n               (rst_n_sync),         // input
       .gpio_in             (gpio_2_in),          // input
       .cfg_enable          (cfg_enable[2]),      // input
       .cfg_trig_enable     (cfg_trig_enable[2]), // input
       .trig_in             (trig_out_1),         // input
       .trig_out            (trig_out_2),         // output
       .cfg_trig_out        (cfg_trig_out[2]),    // input
       .cfg_in_inv          (cfg_in_inv[2]),      // input
       .d1_count            (d1_count_2),         // output [31:0]
       .d2_count            (d2_count_2),         // output [31:0]
       .d3_count            (d3_count_2)          // output [31:0]
       );

   edge_counter u_edge_counter_3
     ( .clk,                                      // input
       .rst_n               (rst_n_sync),         // input
       .gpio_in             (gpio_3_in),          // input
       .cfg_enable          (cfg_enable[3]),      // input
       .cfg_trig_enable     (cfg_trig_enable[3]), // input
       .trig_in             (trig_out_2),         // input
       .trig_out            (trig_out_3),         // output
       .cfg_trig_out        (cfg_trig_out[3]),    // input
       .cfg_in_inv          (cfg_in_inv[3]),      // input
       .d1_count            (d1_count_3),         // output [31:0]
       .d2_count            (d2_count_3),         // output [31:0]
       .d3_count            (d3_count_3)          // output [31:0]
       );
   
   endmodule
