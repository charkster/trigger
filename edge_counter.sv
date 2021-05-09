
module edge_counter
  ( input  logic	    clk,             // fpga clock (12MHz or 100MHz)
    input  logic	    rst_n,           // active-low reset, from fpga board button
    input  logic	    gpio_in,         // this is the fpga pin input to look for edges on
    input  logic        cfg_enable,      // if high enable for edge counting
    input  logic        cfg_trig_enable, // if high enable trig_out, else trig_out is always low 
    input  logic	    trig_in,         // trigger input from another EDGE COUNTER instance
    output logic	    trig_out,        // trigger output to another EDGE COUNTER instance
    input  logic	    cfg_trig_out,    // if high a negative edge seen will cause a trig_out, else a positve edge will cause a trig_out
    input  logic	    cfg_in_inv,      // if high the gpio_in will be inverted, else it will have no inversion
    output logic [31:0] d1_count,        // counter value from the first edge to the opposite edge
    output logic [31:0] d2_count,        // counter value from the last d1 edge to the next opposite edge 
    output logic [31:0] d3_count         // counter value from the last d2 edge to the next opposite edge
    );
    
  logic gpio_in_pol_sync;
  logic gpio_in_pol;
  logic trig_done;
  logic non_trig_done;
  logic d1_count_done;
  logic d1_count_done_hold;
  logic d2_count_done;
  logic d2_count_done_hold;
  logic d3_count_done;
  logic d3_count_done_hold;
  logic pos_edge_trig_out;
  logic neg_edge_trig_out;
  logic trig_out_hold;
  
  // the FPGA input pin can be inverted, if desired
  assign gpio_in_pol = (cfg_in_inv) ? ~gpio_in : gpio_in;
  
  // synchronizer to ensure that noisy gpio input does not cause metastability
  synchronizer u_synchronizer_gpio_in
    ( .clk      (clk),
      .rst_n    (rst_n),
      .data_in  (gpio_in_pol),
      .data_out (gpio_in_pol_sync) // synchronized output
     );
     
  assign trig_done     =  cfg_trig_enable  &&   gpio_in_pol_sync;
  assign non_trig_done = (!cfg_trig_enable) && (!gpio_in_pol_sync);
  assign d1_count_done = (d1_count != 32'd0) && (trig_done || non_trig_done);
     
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d1_count_done_hold <= 1'b0;
    else if (!cfg_enable)   d1_count_done_hold <= 1'b0;
    else if (d1_count_done) d1_count_done_hold <= 1'b1;
  
  // d1_count is the number of fpga clocks from first edge to opposite edge
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                                         d1_count <= 32'd0;
    else if (!cfg_enable)                                                               d1_count <= 32'd0;
    else if ((d1_count == '1) || d1_count_done || d1_count_done_hold)                   d1_count <= d1_count;
    else if ((d1_count == 32'd0) && ((trig_in && cfg_trig_enable) || gpio_in_pol_sync)) d1_count <= 32'd1;
    else if ((d1_count != 32'd0) &&   cfg_trig_enable  && (!gpio_in_pol_sync))          d1_count <= d1_count + 32'd1;
    else if ((d1_count != 32'd0) && (!cfg_trig_enable) &&   gpio_in_pol_sync)           d1_count <= d1_count + 32'd1;

  assign d2_count_done = (d2_count != 32'd0) && ((cfg_trig_enable && (!gpio_in_pol_sync)) || ((!cfg_trig_enable) && gpio_in_pol_sync));
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d2_count_done_hold <= 1'b0;
    else if (!cfg_enable)   d2_count_done_hold <= 1'b0;
    else if (d2_count_done) d2_count_done_hold <= 1'b1;
  
  // d2_count starts when d1_count finishes, counts until the next opposite edge
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                                d2_count <= 32'd0;
    else if (!cfg_enable)                                                      d2_count <= 32'd0;
    else if ((d2_count == '1) || d2_count_done || d2_count_done_hold)          d2_count <= d2_count;
    else if ((d2_count == 32'd0) && d1_count_done)                             d2_count <= 32'd1;
    else if ((d2_count != 32'd0) &&   cfg_trig_enable  &&   gpio_in_pol_sync)  d2_count <= d2_count + 32'd1;
    else if ((d2_count != 32'd0) && (!cfg_trig_enable) && (!gpio_in_pol_sync)) d2_count <= d2_count + 32'd1;
  
  assign d3_count_done = (d3_count != 32'd0) && ((cfg_trig_enable && gpio_in_pol_sync) || ((~cfg_trig_enable) && (~gpio_in_pol_sync)));
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d3_count_done_hold <= 1'b0;
    else if (!cfg_enable)   d3_count_done_hold <= 1'b0;
    else if (d3_count_done) d3_count_done_hold <= 1'b1;
  
  // d3_count starts when d2_count finishes, counts until the next opposite edge
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                                d3_count <= 32'd0;
    else if (!cfg_enable)                                                      d3_count <= 32'd0;
    else if ((d3_count == '1) || d3_count_done || d3_count_done_hold)          d3_count <= d3_count;
    else if ((d3_count == 32'd0) && d2_count_done)                             d3_count <= 32'd1;
    else if ((d3_count != 32'd0) &&   cfg_trig_enable  && (!gpio_in_pol_sync)) d3_count <= d3_count + 32'd1;
    else if ((d3_count != 32'd0) && (!cfg_trig_enable) &&   gpio_in_pol_sync)  d3_count <= d3_count + 32'd1;
  
  assign pos_edge_trig_out = (!cfg_trig_out) && (d1_count == 32'd0) &&   gpio_in_pol_sync;
  assign neg_edge_trig_out =   cfg_trig_out  && (d1_count != 32'd0) && (!gpio_in_pol_sync);
  
  // the trig_out will allow other EDGE COUNTER instances to start counting based on a specific edge seen on a different gpio input
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                          trig_out <= 1'b0;
    else if (!cfg_enable)                                                trig_out <= 1'b0;
    else if (!trig_out_hold && (pos_edge_trig_out || neg_edge_trig_out)) trig_out <= 1'b1;
    else                                                                 trig_out <= 1'b0;
  
  // this will allow the trig_out signal to only be 1 fpga clock period in width
  // this can be converted into a counter if a longer duration on the trig_out is wanted
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)            trig_out_hold <= 1'b0;
    else if (!cfg_enable)  trig_out_hold <= 1'b0;
    else if (trig_out)     trig_out_hold <= 1'b1;

endmodule

   