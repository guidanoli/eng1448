library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proclib;
use proclib.types.all;

entity ru is
	port (CLK, EN_C: in std_logic;
			SEL_A, SEL_B, SEL_C: in RegAddrT;
			C: in ByteT;
			A, B: out ByteT);
end entity;

architecture rtl of ru is
	type RegT is array(0 to 2**(RegAddrT'length)-1) of ByteT;
	signal REG : RegT := (others => (others => '0'));
begin
	process(CLK) is
	begin
		if rising_edge(CLK) then
			if EN_C = '1' then
				REG(to_integer(unsigned(SEL_C))) <= C;
			end if;
		end if;
	end process;
	A <= REG(to_integer(unsigned(SEL_A)));
	B <= REG(to_integer(unsigned(SEL_B)));
end architecture;