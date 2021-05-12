#!/usr/bin/python

from __future__ import print_function
import spidev
import time
from scarf_slave          import scarf_slave
from scarf_pat_gen        import scarf_pat_gen

spi              = spidev.SpiDev(0,0)
spi.max_speed_hz = 12000000
spi.mode         = 0b00

pat_gen  = scarf_pat_gen (slave_id=0x01, spidev=spi,                    debug=False)
sram     = scarf_slave   (slave_id=0x02, spidev=spi, num_addr_bytes=3,  debug=False)
edge_det = scarf_slave   (slave_id=0x03, spidev=spi, num_addr_bytes=50, debug=False)
trigger  = scarf_slave   (slave_id=0x04, spidev=spi, num_addr_bytes=1,  debug=False)

# these are needed to switch between the 2 possible fpga board clock frequencies
stage1_count = 12 # set this to 12 for a 12MHz fpga clk, for 100MHz this can be zero (or 1)
pat_gen_time_base = 2 # the count1 and count2 trigger values hard-coded below rely on pat_get_time_base being 1 higher than trigger time_base
trigger_time_base = 1

def type0_positive():
	print("pattern will trigger on positive edges, pattern is in 1us steps")
	#                                              positive=true, type=edge, stage1_count, time_base=0us,     count1=0us, count2=0, longer_no_edge=false, enable=true
	#                                              1bit           3bits      4bits         3bits              8bits       8bits     1bit                  1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             0,         stage1_count, trigger_time_base, 0,          0,        0,                    1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 1 = 10x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type0_negative():
	print("pattern will trigger on positive edges, pattern is in 1us steps")
	#                                              positive=false, type=edge, stage1_count, time_base=0us,     count1=0us, count2=0, longer_no_edge=false, enable=true
	#                                              1bit            3bits      4bits         3bits              8bits       8bits     1bit                  1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              0,         stage1_count, trigger_time_base, 0,          0,        0,                    1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 1 = 10x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type1_positive():
	print("pattern will trigger on positive pulses shorter than 19us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true,  type=shorter, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=false, enable=true
	#                                              1bit            3bits         4bits         3bits              8bits        8bits     1bit                  1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,              1,            stage1_count, trigger_time_base, 19,          0,        0,                    1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type1_negative():
	print("pattern will trigger on positive pulses short than 19us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=false, type=shorter, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit            3bits         4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              1,            stage1_count, trigger_time_base, 19,          0,        0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern
	
def type2_positive():
	print("pattern will trigger on positive pulses longer than 19us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=longer, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             2,           stage1_count, trigger_time_base, 19,          0,        0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type2_positive_no_edge():
	print("pattern will trigger on positive pulses longer than 19us (as soon as 19us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=longer, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             2,           stage1_count, trigger_time_base, 19,          0,        1,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type2_negative():
	print("pattern will trigger on negative pulses longer than 19us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=false, type=longer, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit            3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              2,           stage1_count, trigger_time_base, 19,          0,        0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type2_negative_no_edge():
	print("pattern will trigger on negative pulses longer than 19us (as soon as 19us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=false, type=longer, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit            3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              2,           stage1_count, trigger_time_base, 19,          0,        1,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type3_positive():
	print("pattern will trigger on positive pulses longer than 19us and less than 29us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=inside, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             3,           stage1_count, trigger_time_base, 19,          29,       0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type3_negative():
	print("pattern will trigger on negative pulses longer than 19us and less than 31us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=false, type=inside, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit            3bits        4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              3,           stage1_count, trigger_time_base, 19,          31,       0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type4_positive():
	print("pattern will trigger on positive pulses less than 19us OR greater than 29us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=outside, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits         4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             4,            stage1_count, trigger_time_base, 19,          29,       0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type4_positive_no_edge():
	print("pattern will trigger on positive pulses less than 19us OR greater than 29us (as soon as 29us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=outside, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits         4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             4,            stage1_count, trigger_time_base, 19,          29,       1,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type4_negative():
	print("pattern will trigger on negative pulses less than 19us OR greater than 29us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=outside, stage1_count, time_base=1us,     count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits         4bits         3bits              8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,             4,            stage1_count, trigger_time_base, 19,          29,       0,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

def type4_negative_no_edge():
	print("pattern will trigger on negative pulses less than 19us OR greater than 29us (as soon as 29us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps")
	#                                              positive=true, type=outside, stage1_count, time_base=1us,      count1=19us, count2=0, longer_no_edge=true, enable=true
	#                                              1bit           3bits         4bits         3bits               8bits        8bits     1bit                 1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,             4,            stage1_count,  trigger_time_base, 19,          29,       1,                   1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002)                # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=stage1_count)         # FPGA clock period * stage1
	pat_gen.cfg_pat_gen(timestep=pat_gen_time_base, num_gpio=1) # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                                        # start the pattern

print("These slave_ids need to be correct or FPGA is not connected/programmed")
print("pat_gen slave id is 0x{:02x}".format(pat_gen.scarf_slave.read_id()))
print("sram slave id is 0x{:02x}".format(sram.read_id()))
print("edge_det slave id is 0x{:02x}".format(edge_det.read_id()))
print("trigger slave id is 0x{:02x}".format(trigger.read_id()))

# Select one of the above functions to verify
type2_negative_no_edge()
time.sleep(1)
trigger.write_list(addr=0x00, write_byte_list=[0,0,0,0,0,0,0,0]) #turn-off trigger

# demonstration of how to directly access the fpga board external SRAM which holds the pattern for pattern_generator
read_data = sram.read_list(addr=0x000000,num_bytes=3)
address = 0
for read_byte in read_data:
	print("SRAM Byte #{:d} Read data 0x{:02x}".format(address,read_byte))
	address += 1

pat_gen.read_all_regmap()
