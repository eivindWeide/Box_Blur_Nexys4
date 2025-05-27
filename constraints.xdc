# Constraints for Nexys4 rev B board

# Clock signal
#Bank = 35, Pin name = IO_L12P_T1_MRCC_35,					Sch name = CLK100MHZ
set_property PACKAGE_PIN E3 [get_ports clk]							
	set_property IOSTANDARD LVCMOS33 [get_ports clk]
	create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Buttons
#Bank = 15, Pin name = IO_L3P_T0_DQS_AD1P_15,				Sch name = CPU_RESET
set_property PACKAGE_PIN C12 [get_ports reset_n]				
	set_property IOSTANDARD LVCMOS33 [get_ports reset_n]
#Bank = 15, Pin name = IO_L11N_T1_SRCC_15,					Sch name = BTNC
set_property PACKAGE_PIN E16 [get_ports start_i]						
	set_property IOSTANDARD LVCMOS33 [get_ports start_i]

# LEDs
#Bank = 34, Pin name = IO_L24N_T3_34,						Sch name = LED0
set_property PACKAGE_PIN T8 [get_ports done_o]					
	set_property IOSTANDARD LVCMOS33 [get_ports done_o]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
