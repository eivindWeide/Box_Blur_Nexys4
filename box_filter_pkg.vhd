-- box_filter_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.lzc_wire.all;
use work.fp_wire.all;
use work.all;

package box_filter_pkg is

    -- Data widths
    constant PIXEL_DATA_WIDTH   : natural := 8;
    
    -- Image dimensions
    constant IMAGE_WIDTH_CONST  : natural := 64;
    constant IMAGE_HEIGHT_CONST : natural := 64;
    
    -- Kernel Coefficients
    constant KF00 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF01 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF02 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF10 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF11 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF12 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF20 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF21 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9
    constant KF22 : std_logic_vector(31 downto 0) := (x"3de38e39"); -- 1/9

    -- Types for a 3x3 window of pixels
    type pixel_window_array is array (0 to 2, 0 to 2) of std_logic_vector(PIXEL_DATA_WIDTH-1 downto 0);
    type float_window_array is array (0 to 8) of std_logic_vector(31 downto 0);
    type flat_window_array is array (0 to 8) of std_logic_vector(7 downto 0);
    
    constant KERNEL : float_window_array := (
        KF00, KF01, KF02,
        KF10, KF11, KF12,
        KF20, KF21, KF22
    );
    
    -- Operations for FPU
	constant OP_I2F : fp_operation_type := (
		fmadd    => '0',
		fmsub    => '0',
		fnmadd   => '0',
		fnmsub   => '0',
		fadd     => '0',
		fsub     => '0',
		fmul     => '0',
		fdiv     => '0',
		fsqrt    => '0',
		fsgnj    => '0',
		fcmp     => '0',
		fmax     => '0',
		fclass   => '0',
		fmv_i2f  => '0',
		fmv_f2i  => '0',
		fcvt_i2f => '1',
		fcvt_f2i => '0',
		fcvt_op  => "01"
	);
	
    constant OP_F2I : fp_operation_type := (
		fmadd    => '0',
		fmsub    => '0',
		fnmadd   => '0',
		fnmsub   => '0',
		fadd     => '0',
		fsub     => '0',
		fmul     => '0',
		fdiv     => '0',
		fsqrt    => '0',
		fsgnj    => '0',
		fcmp     => '0',
		fmax     => '0',
		fclass   => '0',
		fmv_i2f  => '0',
		fmv_f2i  => '0',
		fcvt_i2f => '0',
		fcvt_f2i => '1',
		fcvt_op  => "01"
	);
	
    constant OP_MADD : fp_operation_type := (
		fmadd    => '1',
		fmsub    => '0',
		fnmadd   => '0',
		fnmsub   => '0',
		fadd     => '0',
		fsub     => '0',
		fmul     => '0',
		fdiv     => '0',
		fsqrt    => '0',
		fsgnj    => '0',
		fcmp     => '0',
		fmax     => '0',
		fclass   => '0',
		fmv_i2f  => '0',
		fmv_f2i  => '0',
		fcvt_i2f => '0',
		fcvt_f2i => '0',
		fcvt_op  => "00"
	);


end package box_filter_pkg;
