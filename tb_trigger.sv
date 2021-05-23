`timescale 1ns/1ns

module tb_spi_slave_lbus ();

   parameter EXT_CLK_PERIOD_NS = 83;   // 12MHz
   parameter SCLK_PERIOD_NS    = 1000; // 1MHz
   
   parameter scarf_pat_gen_slave_id = 7'd1; // num addr_bytes = 1
   parameter scarf_sram_slave_id    = 7'd2; // num_addr_bytes = 3
   parameter scarf_edge_det_slave   = 7'd3; // num_addr_bytes = 50
   parameter scarf_trigger_slave_id = 7'd4; // num_addr_bytes = 1
   
   parameter stage1_count      = 4'd0;
   parameter pat_gen_time_base = 4'd3;
   parameter trig_time_base    = 4'd2;
   
   // trigger edge decode
   parameter trigger_pos_edge = 8'd1;
   parameter trigger_neg_edge = 8'd0;
   
   // trigger_type decode
   parameter trigger_type_edge    = 8'd0;
   parameter trigger_type_shorter = 8'd1;
   parameter trigger_type_longer  = 8'd2;
   parameter trigger_type_inside  = 8'd3;
   parameter trigger_type_outside = 8'd4;
   
   parameter pat_gen_1_gpio =  2'b00;
   parameter pat_gen_2_gpio =  2'b01;
   parameter pat_gen_4_gpio =  2'b10;
   parameter pat_gen_8_gpio =  2'b11;
    
   //   cfg_enable_pat_gen           = registers[0][0];
   //   cfg_repeat_enable_pat_gen    = registers[0][1];
   //   cfg_stage1_count_sel_pat_gen = registers[0][7:4];
   //   cfg_num_gpio_sel_pat_gen     = registers[1][1:0];
   //   cfg_timestep_sel_pat_gen     = registers[1][5:3];
   //   cfg_end_address_pat_gen      = {registers[2],registers[3],registers[4]};
   
   reg [559:0] display_string = "empty";

   reg         clk;
   reg         reset;
   reg         sclk;
   reg         ss_n;
   reg         mosi;
   wire        miso;
   wire  [7:0] gpio_pat_gen_out;
   wire [18:0] sram_addr;
   wire  [7:0] sram_data;
   wire        sram_oen;
   wire        sram_wen;
   wire        sram_cen;
   
   // for observability
   wire        trigger_out;
   wire [6:0]  scarf_slave_id;
   wire [7:0]  scarf_data_out;
   wire        scarf_data_out_valid;
   wire        scarf_data_out_finished;
   wire        scarf_rnw;
   wire        scarf_rst_n_sync;
   wire        clk_100mhz;
   wire        clk_100mhz_locked;
   wire        trigger_source;
   wire [7:0]  trigger_count1;
   wire [7:0]  trigger_count2;
   wire [2:0]  trigger_type;
   wire [3:0]  trigger_stage1;
   wire [2:0]  trigger_time_base;
   wire        trigger_longer_no_edge;
   wire        trigger_enable;

   assign scarf_slave_id          = u_scarf_top.slave_id;
   assign scarf_data_out          = u_scarf_top.data_out;
   assign scarf_data_out_valid    = u_scarf_top.data_out_valid;
   assign scarf_data_out_finished = u_scarf_top.data_out_finished;
   assign scarf_rnw               = u_scarf_top.rnw;
   assign scarf_rst_n_sync        = u_scarf_top.rst_n_sync;
   assign clk_100mhz              = u_scarf_top.clk_100mhz;
   assign clk_100mhz_locked       = u_scarf_top.u_clk_wiz_0.locked;
   assign trigger_source          = u_scarf_top.trigger_source;
   assign trigger_count1          = u_scarf_top.u_scarf_trigger.cfg_count1;
   assign trigger_count2          = u_scarf_top.u_scarf_trigger.cfg_count2;
   assign trigger_type            = u_scarf_top.u_scarf_trigger.cfg_type;
   assign trigger_stage1          = u_scarf_top.u_scarf_trigger.cfg_stage1_count;
   assign trigger_time_base       = u_scarf_top.u_scarf_trigger.cfg_time_base;
   assign trigger_longer_no_edge  = u_scarf_top.u_scarf_trigger.cfg_longer_no_edge;
   assign trigger_enable          = u_scarf_top.u_scarf_trigger.cfg_enable;

   initial begin
      clk = 1'b0;
      forever
        #(EXT_CLK_PERIOD_NS/2) clk = ~clk;
   end

   task send_byte (input [7:0] byte_val);
      begin
         $display("Called send_byte task: given byte_val is %h",byte_val);
         sclk  = 1'b0;
         for (int i=7; i >= 0; i=i-1) begin
            $display("Inside send_byte for loop, index is %d",i);
            mosi = byte_val[i];
            #(SCLK_PERIOD_NS/2);
            sclk  = 1'b1;
            #(SCLK_PERIOD_NS/2);
            sclk  = 1'b0;
         end
      end
   endtask
   
   task pat_gen_enable ();
     begin
 //      display_string = "Trigger pattern start";
       ss_n  = 1'b0;
       mosi  = 1'b0;
       #(SCLK_PERIOD_NS/2);
       send_byte({1'b0,scarf_pat_gen_slave_id}); // rnw is the MSB 
       send_byte(8'h00); // address
       send_byte({stage1_count,4'd0}); //disable pattern
       ss_n  = 1'b1;
       #SCLK_PERIOD_NS;
       ss_n  = 1'b0;
       mosi  = 1'b0;
       #(SCLK_PERIOD_NS/2);
       send_byte({1'b0,scarf_pat_gen_slave_id}); // rnw is the MSB 
       send_byte(8'h00); // address
       send_byte({stage1_count,4'd1}); // enable pattern
       ss_n  = 1'b1;
       #SCLK_PERIOD_NS;
     end
   endtask
   
   task config_trigger (input [7:0] cfg_pos_edge, input [7:0] cfg_type, input [7:0] cfg_count1, input [7:0] cfg_count2, input [7:0] cfg_longer_no_edge, input [7:0] cfg_enable);
     begin
       ss_n  = 1'b0;
       mosi  = 1'b0;
       #(SCLK_PERIOD_NS/2);
       send_byte({1'b0,scarf_trigger_slave_id}); // rnw is the MSB 
       send_byte(8'h00); // address
       send_byte(cfg_pos_edge);
       send_byte(cfg_type);
       send_byte(stage1_count);
       send_byte(trig_time_base);
       send_byte(cfg_count1);
       send_byte(cfg_count2);
       send_byte(cfg_longer_no_edge);
       send_byte(cfg_enable);
       ss_n  = 1'b1;
       #SCLK_PERIOD_NS;
     end
   endtask

   initial begin
      reset = 1'b1;
      sclk  = 1'b0;
      ss_n  = 1'b1;
      mosi  = 1'b0;
      #SCLK_PERIOD_NS;
      reset = 1'b0;
      #SCLK_PERIOD_NS;
      @(posedge clk_100mhz_locked); // wait for locked 100MHz clock
      repeat (2) @(posedge clk_100mhz);
      
      display_string = "Configure SRAM with pattern data";
      ss_n  = 1'b0;
      mosi  = 1'b0;
      #(SCLK_PERIOD_NS/2);
      send_byte({1'b0,scarf_sram_slave_id}); // rnw is the MSB 
      send_byte(8'h00); // address upper
      send_byte(8'h00); // address mid
      send_byte(8'h00); // address lower
      send_byte(8'b11101101); // pattern data
      send_byte(8'b11101010); // pattern data
      send_byte(8'b00111110); // pattern data
      ss_n  = 1'b1;
      #SCLK_PERIOD_NS;
      
      display_string = "Configure Pattern Generator";
      ss_n  = 1'b0;
      mosi  = 1'b0;
      #(SCLK_PERIOD_NS/2);
      send_byte({1'b0,scarf_pat_gen_slave_id}); // rnw is the MSB 
      send_byte(8'h01); // address
      send_byte({pat_gen_time_base,1'b0,pat_gen_1_gpio});
      send_byte(8'h00); // pattern end address upper
      send_byte(8'h00); // pattern end address mid
      send_byte(8'h02); // pattern end address lower
      ss_n  = 1'b1;
      #SCLK_PERIOD_NS;
      
      display_string = "Trig posedge, no cnt";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_edge), .cfg_count1(8'd0), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig negedge, no cnt";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_edge), .cfg_count1(8'd0), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig shorter posedge, cnt less than 18us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_shorter), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig shorter negedge, cnt less than 18us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_shorter), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig longer posedge, cnt longer than 18us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_longer), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig longer negedge, cnt longer than 18us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_longer), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig longer posedge, no edge, cnt longer than 18us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_longer), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd1), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig longer negedge, no edge, cnt longer than 18us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_longer), .cfg_count1(8'd18), .cfg_count2(8'd0), .cfg_longer_no_edge(8'd1), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig inside posedge, cnt greater than 18us, less than 28us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_inside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig inside negedge, cnt greater than 18us, less than 28us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_inside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig outside posedge, cnt less than 18us, greater than 28us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_outside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig outside negedge, cnt less than 18us, greater than 28us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_outside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd0), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig outside posedge, no edge, cnt less than 18us, greater than 28us";
      config_trigger(.cfg_pos_edge(trigger_pos_edge), .cfg_type(trigger_type_outside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd1), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      display_string = "Trig outside negedge, no edge, cnt less than 18us, greater than 28us";
      config_trigger(.cfg_pos_edge(trigger_neg_edge), .cfg_type(trigger_type_outside), .cfg_count1(8'd18), .cfg_count2(8'd28), .cfg_longer_no_edge(8'd1), .cfg_enable(8'd1));
      pat_gen_enable();
      #400us;
      
      $finish;
   end

   // dump waveforms
   initial begin
      $shm_open("waves.shm");
      $shm_probe("MAS");
   end

  ram_model u_ram_model
  ( .sram_addr,
    .sram_data,
    .sram_cen,
    .sram_wen,
    .sram_oen
   );
   
   scarf_top u_scarf_top
   ( .clk,                                     // input fpga board clock (12MHz or 100MHz)
     .reset,                                   // input button
     .sclk,                                    // input SPI CLK
     .ss_n,                                    // input SPI CS_N
     .mosi,                                    // input SPI MOSI
     .miso,                                    // output SPI MISO
     .sram_addr,                               // output [18:0] ext sram address
     .sram_data,                               // inout [7:0] ext sram data (bidir)
     .sram_oen,                                // output ext sram output enable (active low)
     .sram_wen,                                // output ext sram write enable  (active low)
     .sram_cen,                                // output ext sram chip enable   (active low)
     .gpio_pat_gen_out,                        // output [7:0] pattern generation outputs 
     .pattern_done      (),                    // output pattern generator indicator that pattern has completed
     .gpio_0_in         (1'b0),                // input edge counter 0
     .gpio_1_in         (1'b0),                // input edge counter 1
     .gpio_2_in         (1'b0),                // input edge counter 2
     .gpio_3_in         (1'b0),                // input edge counter 3
     .trigger_source    (gpio_pat_gen_out[0]), // input trigger input
     .trigger_out                              // output
    );

endmodule
