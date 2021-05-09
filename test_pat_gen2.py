#!/usr/bin/python

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

def type0_positive():
	print "pattern will trigger on positive edges, pattern is in 1us steps"
	#                                              positive=true, type=edge, time_base=0us, count1=0us, count2=0, longer_no_edge=false, 12mhz=false, enable=true
	#                                              1bit           3bits      3bits          8bits        8bits    1bit                  1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             0,         0,             0,           0,        0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=1, num_gpio=1)  # timestep=1 is 10 ^ 1 = 10x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type0_negative():
	print "pattern will trigger on positive edges, pattern is in 1us steps"
	#                                              positive=false, type=edge, time_base=0us, count1=0us, count2=0, longer_no_edge=false, 12mhz=false, enable=true
	#                                              1bit            3bits      3bits          8bits       8bits     1bit                  1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              0,         0,             0,          0,        0,                    0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=1, num_gpio=1)  # timestep=1 is 10 ^ 1 = 10x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type1_positive():
	print "pattern will trigger on positive pulses shorter than 19us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true,  type=shorter, time_base=1us, count1=19us, count2=0, longer_no_edge=false, 12mhz=false, enable=true
	#                                              1bit            3bits         3bits          8bits        8bits     1bit                  1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,              1,            2,             19,          0,        0,                    0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type1_negative():
	print "pattern will trigger on positive pulses short than 19us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=false, type=shorter, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit            3bits         3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              1,            2,             19,          0,        0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern
	
def type2_positive():
	print "pattern will trigger on positive pulses longer than 19us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=longer, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             2,           2,             19,          0,        0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type2_positive_no_edge():
	print "pattern will trigger on positive pulses longer than 19us (as soon as 19us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=longer, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             2,           2,             19,          0,        1,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type2_negative():
	print "pattern will trigger on negative pulses longer than 19us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=false, type=longer, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit            3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              2,           2,             19,          0,        0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type2_negative_no_edge():
	print "pattern will trigger on negative pulses longer than 19us (as soon as 19us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=false, type=longer, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit            3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              2,           2,             19,          0,        1,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type3_positive():
	print "pattern will trigger on positive pulses longer than 19us and less than 29us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=inside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             3,           2,             19,          29,       0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type3_negative():
	print "pattern will trigger on negative pulses longer than 19us and less than 31us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=false, type=inside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit            3bits        3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,              3,           2,             19,          31,       0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type4_positive():
	print "pattern will trigger on positive pulses less than 19us OR greater than 29us (on the falling edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=outside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits         3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             4,            2,             19,          29,       0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type4_positive_no_edge():
	print "pattern will trigger on positive pulses less than 19us OR greater than 29us (as soon as 29us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=outside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits         3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[1,             4,            2,             19,          29,       1,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type4_negative():
	print "pattern will trigger on negative pulses less than 19us OR greater than 29us (on the rising edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=outside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits         3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,             4,            2,             19,          29,       0,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

def type4_negative_no_edge():
	print "pattern will trigger on negative pulses less than 19us OR greater than 29us (as soon as 29us is reached, no edge), pattern is in 10us steps, trigger is in 1us steps"
	#                                              positive=true, type=outside, time_base=1us, count1=19us, count2=0, longer_no_edge=true, 12mhz=false, enable=true
	#                                              1bit           3bits         3bits          8bits        8bits     1bit                 1bit         1bit
	trigger.write_list(addr=0x00, write_byte_list=[0,             4,            2,             19,          29,       1,                   0,           1])
	print(trigger.read_list(addr=0x00, num_bytes=8)) # confirm above values were loaded
	sram.write_list(addr=0x000000, write_byte_list=[0b11101101, 0b11101010, 0b00111110])
	pat_gen.cfg_sram_end_addr(end_addr=0x000002) # 3 bytes of data to be driven
	pat_gen.cfg_stage1_count(stage1_count=10)    # FPGA clock period * 10
	pat_gen.cfg_pat_gen(timestep=2, num_gpio=1)  # timestep=1 is 10 ^ 2 = 100x, only 1 fpga io will be driven
	pat_gen.cfg_enable()                         # start the pattern

print "These slave_ids need to be correct or FPGA is not connected/programmed"
print "pat_gen slave id is 0x%02x"  % pat_gen.scarf_slave.read_id()
print "sram slave id is 0x%02x"     % sram.read_id()
print "edge_det slave id is 0x%02x" % edge_det.read_id()
print "trigger slave id is 0x%02x"  % trigger.read_id()

type4_negative_no_edge()
time.sleep(1)

read_data = sram.read_list(addr=0x000000,num_bytes=3)
address = 0
for read_byte in read_data:
	print "SRAM Byte #%d Read data 0x%02x" % (address,read_byte)
	address += 1

pat_gen.read_all_regmap()
