library ieee;
use ieee.std_logic_1164.all;

library proclib;
use proclib.types.all;

entity driver is
	port (CNT : in ByteT;
			CLK_50MHZ : in std_logic;
	      J1, J2 : out NibbleT);
end entity;

architecture rtl of driver is
	signal I : integer range 0 to 50000 := 0;
	signal DIG : std_logic := '0';
	signal A, B, C, D, E, F, G : std_logic;
begin
	-- Código sequencial
	process(CLK_50MHZ) is
	begin
		if rising_edge(CLK_50MHZ) then
			-- Controle do nibble
			if DIG = '0' then
				(A, B, C, D, E, F, G) <= hex2ssd(CNT(3 downto 0));
			else
				(A, B, C, D, E, F, G) <= hex2ssd(CNT(7 downto 4));
			end if;
			-- Controle do dígito
			if I = 50000 then
				DIG <= not DIG;
				I <= 0;
			else
				I <= I + 1;
			end if;
		end if;
	end process;
	
	-- Código concorrente
	J1 <= (D, C, B, A);
	J2 <= (DIG, G, F, E);
end architecture;

