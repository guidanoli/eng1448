library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proclib;
use proclib.types.all;

entity counter is
	generic (INITIAL_VALUE: integer);
	port (CLK, INC, DEC: in std_logic;
	      VALUE: out ByteT);
end entity;

architecture rtl of counter is
	signal CNT : ByteT := ByteT(to_unsigned(INITIAL_VALUE, ByteT'length));
begin
	process(CLK) is
	begin
		if rising_edge(CLK) then
			if INC = '1' and DEC = '0' then
				CNT <= ByteT(unsigned(CNT) + 1);
			elsif DEC = '1' and INC = '0' then
				CNT <= ByteT(unsigned(CNT) - 1);
			end if;
		end if;
	end process;
	VALUE <= CNT;
end architecture;

