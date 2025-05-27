# Box_Blur_Nexys4
A VHDL implementation of a floating point box blur. Uses block memory generator IP to load an image with  a .coe file. Uses https://github.com/taneroksuz/fpu-sp as FPU. 

**Description of files:**

box_filter_pgk: Types and constant declarations
box_filter_top: Top module
box_filter_core: FSM for reading and writing to memory
convolution_unit: FSM for UINT8 <-> FP32 converting and convolution operation
ram_sync: Memory
constraints: Constraints for Nexys4 board
tb_box_filter_top: Testbench
tb_convolution_unit: Testbench
