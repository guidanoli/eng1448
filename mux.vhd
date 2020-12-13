library ieee;
use ieee.std_logic_1164.all;

library proclib;
use proclib.types.all;

entity mux is
	port (SEL: in std_logic;
	      BYTEIN_0, BYTEIN_1: in ByteT;
			BYTEOUT: out ByteT);
end entity;

architecture rtl of mux is
begin
	BYTEOUT <= BYTEIN_1 when SEL = '1' else BYTEIN_0;
end architecture;

