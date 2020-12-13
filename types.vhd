library ieee;
use ieee.std_logic_1164.all;

-- Common types for processor components

package types is
	-- Byte and its subdivisions
	subtype ByteT   is std_logic_vector(7 downto 0);
	subtype NibbleT is std_logic_vector(3 downto 0);
	subtype CrumbT  is std_logic_vector(1 downto 0);
	
	-- Register address
	subtype RegAddrT is std_logic_vector(1 downto 0);
	
	-- ALU operation
	type AluOpT is (OpSel, OpAdd, OpSub, OpAnd,
	                OpOr, OpXor, OpLShift, OpRShift);
	
	-- Bus arbitration constants
	constant SelectCU  : std_logic := '0';
	constant SelectRU  : std_logic := '1';
	constant SelectLSU : std_logic := '0';
	constant SelectALU : std_logic := '1';
	
	-- Memory address space constants
	constant DeviceInputAddr  : integer := 16#0C#;
	constant DeviceOutputAddr : integer := 16#0E#;
	constant ProgramBaseAddr  : integer := 16#20#;
	constant StackBaseAddr    : integer := 16#FF#;
	
	-- Hexadecimal to SSD conversion
	function hex2ssd(HEX: NibbleT) return
		std_logic_vector;
end package;

package body types is
	-- Convert hexadecimal to ssd
	function hex2ssd(HEX: NibbleT) return
		std_logic_vector is
		variable X : std_logic_vector(6 downto 0);
		variable A, B, C, D : std_logic;
	begin
		-- Give easier names for each bit
		(A, B, C, D) := HEX;
		-- Assign each segment its value
		-- G
		X(0) := (not B and C) or
		        (C and not D) or
				  (A and not B) or
				  (A and D) or
				  (not A and B and not C);
		-- F
		X(1) := (not C and not D) or
		        (B and not D) or
				  (A and not B) or
				  (A and C) or
				  (not A and B and not C);
		-- E
		X(2) := (not B and not D) or
		        (C and not D) or
				  (A and C) or
				  (A and B);
		-- D
		X(3) := (not B and not D) or
		        (not B and C) or
				  (C and not D) or
				  (A and not D) or
				  (B and not C and D);
		-- C
		X(4) := (not A and not C) or
		        (not A and D) or
				  (not C and D) or
				  (not A and B) or
				  (A and not B);
		-- B
		X(5) := (not A and not B) or
		        (not B and not D) or
				  (not A and not C and not D) or
				  (not A and C and D) or
				  (A and not C and D);
		-- A
		X(6) := (not B and not D) or
		        (not A and C) or
				  (B and C) or
				  (A and not D) or
				  (not A and B and D) or
				  (A and not B and not C);
		return X;
	end function;
end package body;