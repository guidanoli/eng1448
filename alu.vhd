library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proclib;
use proclib.types.all;

entity alu is
	port (A, B: in ByteT;
			OP: in AluOpT;
			C: out ByteT;
			ZERO, CARRY: out std_logic);
end entity;

architecture rtl of alu is
	-- Overflow byte type
	subtype OByteT is std_logic_vector(ByteT'high+1 downto ByteT'low);
	
	-- Result registers
	signal AddR, SubR, LShiftR, RShiftR : OByteT;
	signal SelR, AndR, OrR, XorR : ByteT;
	signal Result : ByteT;
	
	-- Register truncations
	alias AddRT    is AddR    (ByteT'high   downto ByteT'low  );
	alias SubRT    is SubR    (ByteT'high   downto ByteT'low  );
	alias LShiftRT is LShiftR (ByteT'high   downto ByteT'low  );
	alias RShiftRT is RShiftR (ByteT'high+1 downto ByteT'low+1);
	
	-- Register overflow bits
	alias AddRO    is AddR    (ByteT'high+1);
	alias SubRO    is SubR    (ByteT'high+1);
	alias LShiftRO is LShiftR (ByteT'high+1);
	alias RShiftRO is RShiftR (ByteT'low   );
begin
	SelR <= A;
	AddR <= OByteT(unsigned('0' & A) + unsigned('0' & B));
	SubR <= OByteT(unsigned('0' & A) + unsigned('0' & not B) + 1); -- -B = ~B + 1
	AndR <= A and B;
	OrR <= A or B;
	XorR <= A xor B;
	LShiftR <= OByteT(A & B(ByteT'low));
	RShiftR <= OByteT(B(ByteT'low) & A);

	with OP select
		Result <= SelR     when OpSel,
		          AddRT    when OpAdd,
					 SubRT    when OpSub,
					 AndR     when OpAnd,
					 OrR      when OpOr,
					 XorR     when OpXor,
					 LShiftRT when OpLShift,
					 RShiftRT when OpRShift;

	with OP select
		CARRY <= AddRO    when OpAdd,
		         SubRO    when OpSub,
					LShiftRO when OpLShift,
					RShiftRO when OpRShift,
					'0'      when others;
	
	ZERO <= '1' when unsigned(Result) = 0 else '0';
	C <= Result;
end architecture;