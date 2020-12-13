library ieee;
use ieee.std_logic_1164.all;

entity rising_edge_detector is
	port (CLK, A: in std_logic;
	      B: out std_logic);
end entity;

architecture rtl of rising_edge_detector is
	signal Q: std_logic := '0';
begin
	process(CLK) is
	begin
		if rising_edge(CLK) then
			Q <= A;
		end if;
	end process;
	
	B <= (not Q) and A;
end architecture;

