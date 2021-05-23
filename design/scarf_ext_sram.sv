// SCARF to external SRAM interface

module scarf_ext_sram
  ( input  logic        clk,
    input  logic        rst_n_sync,
    input  logic  [7:0] data_in,          // SCARF
    input  logic        data_in_valid,    // SCARF
    input  logic        data_in_finished, // SCARF
    input  logic  [6:0] slave_id,         // SCARF
    input  logic        rnw,              // SCARF
    output logic  [7:0] read_data_out,    // SCARF
    input  logic  [7:0] sram_data_in,
    output logic  [7:0] sram_data_out,
    output logic [18:0] sram_addr,
    output logic        sram_oen,
    output logic        sram_wen,
    output logic        sram_cen
    );
    
    parameter SLAVE_ID    = 7'h02;
    parameter MAX_ADDRESS = 19'h7FFFF; // this value is for the CMOD A7 board SRAM
    
    logic  [2:0] byte_count;
    logic        valid_data;
    logic        valid_data_ff;
    logic        valid_slave;
    
    assign valid_slave = (slave_id == SLAVE_ID);
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                           byte_count <= 'd0;
      else if (data_in_finished)                                 byte_count <= 'd0;
      else if (valid_slave && data_in_valid && (byte_count < 4)) byte_count <= byte_count + 1'd1;
   
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                                                                      sram_addr        <= 'd0;
      else if (valid_slave && data_in_valid && (byte_count == 'd0))                                         sram_addr[18:16] <= data_in[2:0];
      else if (valid_slave && data_in_valid && (byte_count == 'd1))                                         sram_addr[15:8]  <= data_in;
      else if (valid_slave && data_in_valid && (byte_count == 'd2))                                         sram_addr[7:0]   <= data_in;
      else if (valid_slave && data_in_valid && (byte_count >= 'd3) && (sram_addr != MAX_ADDRESS) &&   rnw)  sram_addr        <= sram_addr + 1'b1;
      else if (valid_slave && data_in_valid && (byte_count == 'd4) && (sram_addr != MAX_ADDRESS) && (!rnw)) sram_addr        <= sram_addr + 1'b1;
      else if ((byte_count == 'd0) && sram_cen)                                                             sram_addr        <= 'd0;
    
    assign valid_data = (byte_count >= 'd3) && data_in_valid;
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) valid_data_ff <= 1'b0;
      else             valid_data_ff <= valid_data;
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)               sram_data_out <= 8'd0;
      else if (valid_data && (!rnw)) sram_data_out <= data_in;
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                  sram_wen <= 1'b1;
      else if (valid_data_ff && (!rnw)) sram_wen <= 1'b0;
      else                              sram_wen <= 1'b1;
      
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                   sram_oen <= 1'b1;
      else if (data_in_finished)         sram_oen <= 1'b1;
      else if ((byte_count == 3) && rnw) sram_oen <= 1'b0;
      
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                                              sram_cen <= 1'b1;
      else if (valid_slave && data_in_valid && (byte_count == 'd2)) sram_cen <= 1'b0;
      else if (byte_count == 'd0)                                   sram_cen <= 1'b1;
      
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                             read_data_out <= 8'd0;
      else if (!valid_slave)                       read_data_out <= 8'd0;
      else if (valid_slave && (byte_count == 'd0)) read_data_out <= {1'b0,SLAVE_ID};
      else if ((!sram_cen) && rnw)                 read_data_out <= sram_data_in;
    
endmodule
    
