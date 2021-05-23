// pattern generator will read bytes from on-board SRAM and send them to fpga pins as output
// byte data from the SRAM can be sent out on 1, 2, 4 or 8 pins (selectable)
// byte data from SRAM can be looped, so that a small pattern of SRAM data can be repeated (selectable)

// if fpga board clock is 12MHz, that is not a base 10 period. To convert to base 10, the state1 needs to be set to 12
// this will make a pulse that toggles every 1MHz (1us). The timestep can then be used to align to a slower timestep.
// if data is to be driven every 1ms. the timestep should be set to 3 (10 ^ 3 = 1000 us)

// if the repeat_enable is used, only a write of 1'b0 to the enable_pat_gen register will stop the pattern 

module pattern_gen
  ( input  logic        clk,
    input  logic        rst_n,
    input  logic        cfg_enable_pat_gen,           // enable the pattern generation
    input  logic [23:0] cfg_end_address_pat_gen,      // SRAM starts at address zero and goes to this address (inclusive)
    input  logic  [1:0] cfg_num_gpio_sel_pat_gen,     // 2'b00 is 1, 2'b01 is 2, 2'b10 is 4 and 2'b11 is 8
    input  logic  [2:0] cfg_timestep_sel_pat_gen,     // timebase is 10 ^ n
    input  logic  [3:0] cfg_stage1_count_sel_pat_gen, // stage1 is to convert the fpga clock to a base 10 time unit
    input  logic        cfg_repeat_enable_pat_gen,    // high value enables repeated (continuous) pattern output
    output logic        pattern_active,               // when high the SRAM will be read from by this block, else SRAM can be read/written to by SCARF
    output logic        pattern_done,                 // fpga output signal that indicates that all selected SRAM data has been driven
    output logic  [7:0] gpio_pat_gen_out,             // fpga output signals (from SRAM values)
    input  logic  [7:0] sram_data,                    // SRAM data
    output logic [18:0] sram_addr_pat_gen             // SRAM address
    );
    
    logic        reached_final_address;
    logic        reached_final_bit_count;
    logic        enable_pat_gen_delay;
    logic        enable_pat_gen_rise_edge;
    logic [18:0] current_address;
    logic  [2:0] bit_count;
    logic [25:0] timestep_counter;
    logic [25:0] final_timestep_count;
    logic        reached_final_timestep_count;
    logic        timestep_change;
    logic        timestep_change_delay;
    logic  [7:0] gpio_mask;
    logic  [7:0] gpio_pat_gen_comb;
    logic        enable_bit_counter;
    logic        pattern_active_hold;
    logic        reached_final_stage1_count;
    logic  [3:0] stage1_counter;
    logic  [3:0] final_stage1_count;
    
    assign reached_final_address = (current_address == cfg_end_address_pat_gen[18:0]);
    
    assign reached_final_bit_count  = ((cfg_num_gpio_sel_pat_gen ==  2'b00) && (bit_count == 3'd7)) ||
                                      ((cfg_num_gpio_sel_pat_gen ==  2'b01) && (bit_count == 3'd6)) ||
                                      ((cfg_num_gpio_sel_pat_gen ==  2'b10) && (bit_count == 3'd4)) ||
                                      ((cfg_num_gpio_sel_pat_gen ==  2'b11) && (bit_count == 3'd0));
                                      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n) enable_pat_gen_delay <= 1'b0;
      else        enable_pat_gen_delay <= cfg_enable_pat_gen;
      
    assign enable_pat_gen_rise_edge = (cfg_enable_pat_gen && (!enable_pat_gen_delay));
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                      pattern_active <= 1'b0;
      else if (!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen))                                                    pattern_active <= 1'b0;
      else if (cfg_repeat_enable_pat_gen || enable_pat_gen_rise_edge)                                                  pattern_active <= 1'b1;
      else if (reached_final_address && reached_final_bit_count && reached_final_timestep_count && enable_bit_counter) pattern_active <= 1'b0;

   always_ff @(posedge clk, negedge rst_n)
     if (~rst_n) pattern_active_hold <= 1'b0;
     else        pattern_active_hold <= pattern_active;

   always_ff @(posedge clk, negedge rst_n)
     if (~rst_n)                                                   pattern_done <= 1'b0;
     else if (!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) pattern_done <= 1'b0;
     else if (!pattern_active && pattern_active_hold)              pattern_done <= 1'b1;
   

    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                              current_address <= '0;
      else if ((!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) || (!enable_bit_counter))                                 current_address <= '0;
      else if (!reached_final_address && reached_final_bit_count && reached_final_timestep_count)                              current_address <= current_address + 1;
      else if ( reached_final_address && reached_final_bit_count && reached_final_timestep_count && cfg_repeat_enable_pat_gen) current_address <= '0;
      
    assign sram_addr_pat_gen = current_address;

    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                          enable_bit_counter <= 1'b0;
      else if ((!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) || (!pattern_active)) enable_bit_counter <= 1'b0;
      else if (pattern_active && reached_final_timestep_count)                             enable_bit_counter <= 1'b1;
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                                   bit_count <= '0;
      else if ((!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) || (!enable_bit_counter))                                      bit_count <= '0;
      else if (!reached_final_bit_count && reached_final_timestep_count && (cfg_num_gpio_sel_pat_gen == 2'b00))                     bit_count <= bit_count + 1;
      else if (!reached_final_bit_count && reached_final_timestep_count && (cfg_num_gpio_sel_pat_gen == 2'b01))                     bit_count <= bit_count + 2;
      else if (!reached_final_bit_count && reached_final_timestep_count && (cfg_num_gpio_sel_pat_gen == 2'b10))                     bit_count <= bit_count + 4;
      else if ( reached_final_bit_count && reached_final_timestep_count && ((!reached_final_address) || cfg_repeat_enable_pat_gen)) bit_count <= '0;

    always_comb
        if (cfg_stage1_count_sel_pat_gen >= 3'd2) final_stage1_count = cfg_stage1_count_sel_pat_gen - 3'd1;
        else if (cfg_timestep_sel_pat_gen == '0)  final_stage1_count = 3'd1; // minimum
        else                                      final_stage1_count = 3'd0;
    
    assign reached_final_stage1_count = (stage1_counter == final_stage1_count);
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                          stage1_counter <= '0;
      else if ((!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) || (!pattern_active)) stage1_counter <= '0;
      else if (!reached_final_stage1_count)                                                stage1_counter <= stage1_counter + 1;
      else if ( reached_final_stage1_count)                                                stage1_counter <= '0;
 
    always_comb
      case(cfg_timestep_sel_pat_gen)
        3'd0:    final_timestep_count = 'd0;            // stage1
        3'd1:    final_timestep_count = 'd10       - 1; // stage1 * 10
        3'd2:    final_timestep_count = 'd100      - 1; // stage1 * 100
        3'd3:    final_timestep_count = 'd1000     - 1; // stage1 * 1k
        3'd4:    final_timestep_count = 'd10000    - 1; // stage1 * 10k
        3'd5:    final_timestep_count = 'd100000   - 1; // stage1 * 100k
        3'd6:    final_timestep_count = 'd1000000  - 1; // stage1 * 1M
        3'd7:    final_timestep_count = 'd10000000 - 1; // stage1 * 10M
        default: final_timestep_count = 'd10000000 - 1; // added for lint
      endcase
      
    assign reached_final_timestep_count = (timestep_counter == final_timestep_count) && reached_final_stage1_count;
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                               timestep_counter <= '0;
      else if ((!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) || (!pattern_active))                      timestep_counter <= '0;
      else if (!reached_final_timestep_count && (cfg_timestep_sel_pat_gen != '0) && reached_final_stage1_count) timestep_counter <= timestep_counter + 1;
      else if ( reached_final_timestep_count)                                                                   timestep_counter <= '0;
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                            timestep_change <= 1'b0;
      else if (reached_final_timestep_count) timestep_change <= 1'b1;
      else                                   timestep_change <= 1'b0;
    
    // need to update the gpio pins after address and bit_count changes
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n) timestep_change_delay <= 1'b0;
      else        timestep_change_delay <= timestep_change && pattern_active;
      
    always_comb
      case(cfg_num_gpio_sel_pat_gen)
        2'b00: gpio_mask = 8'b0000_0001;
        2'b01: gpio_mask = 8'b0000_0011;
        2'b10: gpio_mask = 8'b0000_1111;
        2'b11: gpio_mask = 8'b1111_1111;
      endcase
      
    // LSB to MSB
//    assign gpio_pat_gen_comb = {sram_data[bit_count+7],sram_data[bit_count+6],sram_data[bit_count+5],sram_data[bit_count+4],
//                                sram_data[bit_count+3],sram_data[bit_count+2],sram_data[bit_count+1],sram_data[bit_count]};

    // MSB to LSB
    assign gpio_pat_gen_comb = {sram_data[bit_count],sram_data[1-bit_count],sram_data[2-bit_count],sram_data[3-bit_count],
                                sram_data[4-bit_count],sram_data[5-bit_count],sram_data[6-bit_count],sram_data[7-bit_count]};
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                   gpio_pat_gen_out <= 8'b0000_0000;
      else if (!cfg_enable_pat_gen && (!cfg_repeat_enable_pat_gen)) gpio_pat_gen_out <= 8'b0000_0000;
      else if (timestep_change_delay)                               gpio_pat_gen_out <= gpio_pat_gen_comb & gpio_mask;

endmodule
