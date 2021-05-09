
module scarf_regmap_trigger
  ( input  logic       clk,
    input  logic       rst_n_sync,
    input  logic [7:0] data_in,
    input  logic       data_in_valid,
    input  logic       data_in_finished,
    input  logic [6:0] slave_id,
    input  logic       rnw,
    output logic [7:0] read_data_out,
    output logic       cfg_enable,
    output logic       cfg_positive,
    output logic [2:0] cfg_type,
    output logic [2:0] cfg_time_base,
    output logic [7:0] cfg_count1,
    output logic [7:0] cfg_count2,
    output logic       cfg_longer_no_edge,
    output logic       cfg_12mhz
    );
    
    parameter SLAVE_ID    = 7'h04;
    parameter MAX_ADDRESS = 3'd7;
    
    logic [7:0] registers[7:0];
    logic [2:0] address;
    logic       first_byte;
    logic       final_byte;
    logic       valid_slave;
    logic       valid_read;
    logic       valid_write;
    logic       first_byte_slave_id;
     
    assign valid_slave = (slave_id == SLAVE_ID);
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                       first_byte <= 1'd1;
      else if (data_in_finished)             first_byte <= 1'd1;
      else if (data_in_valid && valid_slave) first_byte <= 1'd0;
    
    always_ff @(posedge clk, negedge rst_n_sync)
        if (~rst_n_sync)                                                  address <= 'd0;
        else if (data_in_finished)                                        address <= 'd0;
        else if (valid_slave && data_in_valid && first_byte)              address <= data_in[2:0];
        else if (valid_slave && data_in_valid && (address < MAX_ADDRESS)) address <= address + 1;
        
    always_ff @(posedge clk, negedge rst_n_sync)
        if (~rst_n_sync)                                                                    final_byte <= 1'b0;
        else if (data_in_finished)                                                          final_byte <= 1'b0;
        else if (valid_slave && data_in_valid && (!first_byte) && (address == MAX_ADDRESS)) final_byte <= 1'b1;
 
    assign valid_read = valid_slave && rnw && (!first_byte) && (!final_byte);
    
    assign first_byte_slave_id = valid_slave && rnw && first_byte;
    
    assign read_data_out[7:0] =  ({8{valid_read}} & registers[address]) | ({8{first_byte_slave_id}} & {1'b0,SLAVE_ID});
      
    assign valid_write = valid_slave && (!rnw) && data_in_valid && (!first_byte) && (!final_byte);
    
    // each cfg register has its own address, just to keep things simple
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) begin cfg_positive       <= 1'b0;
                             cfg_type           <= 3'd0;
                             cfg_time_base      <= 3'd0;
                             cfg_count1         <= 8'd0;
                             cfg_count2         <= 8'd0;
                             cfg_longer_no_edge <= 1'b0; 
                             cfg_12mhz          <= 1'b0; 
                             cfg_enable         <= 1'b0; end
      else if (valid_write && (address == 'd0)) cfg_positive       <= data_in[0];
      else if (valid_write && (address == 'd1)) cfg_type           <= data_in[2:0];
      else if (valid_write && (address == 'd2)) cfg_time_base      <= data_in[2:0];
      else if (valid_write && (address == 'd3)) cfg_count1         <= data_in[7:0];
      else if (valid_write && (address == 'd4)) cfg_count2         <= data_in[7:0];
      else if (valid_write && (address == 'd5)) cfg_longer_no_edge <= data_in[0];
      else if (valid_write && (address == 'd6)) cfg_12mhz          <= data_in[0];
      else if (valid_write && (address == 'd7)) cfg_enable         <= data_in[0];
    
    // this is used for read_data_out decode
    assign registers[0] = {7'd0,cfg_positive};
    assign registers[1] = {5'd0,cfg_type};
    assign registers[2] = {5'd0,cfg_time_base};
    assign registers[3] = cfg_count1;
    assign registers[4] = cfg_count2;
    assign registers[5] = {7'd0,cfg_longer_no_edge};
    assign registers[6] = {7'd0,cfg_12mhz};
    assign registers[7] = {7'd0,cfg_enable};
    
endmodule