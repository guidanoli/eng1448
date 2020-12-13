library ieee;
use ieee.std_logic_1164.all;

library proclib;
use proclib.types.all;
 
entity proc_tb is
end proc_tb;

architecture behavior of proc_tb is 
    component proc is
		port (CLK: in std_logic;
				BTN_NORTH, BTN_EAST, BTN_SOUTH, BTN_WEST: in std_logic;
				ROT_A, ROT_B, ROT_CENTER: in std_logic;
				J1, J2: out NibbleT);
	end component;

   -- Inputs
   signal CLK : std_logic := '0';
	signal BTN_EAST : std_logic := '0';

   -- Clock period definitions
   constant CLK_period : time := 10 ns;
begin
 
	-- Instantiate the Unit Under Test (UUT)
   uut: proc port map (
		CLK        => CLK,
		BTN_EAST   => BTN_EAST,
		BTN_NORTH  => '0',
		BTN_SOUTH  => '0',
		BTN_WEST   => '0',
		ROT_A      => '0',
		ROT_B      => '0',
		ROT_CENTER => '0');

   -- Clock process definitions
   CLK_process: process
   begin
		CLK <= '0';
		wait for CLK_period/2;
		CLK <= '1';
		wait for CLK_period/2;
   end process;

	PULSE_process: process
	begin
		wait for 500*CLK_period;
		BTN_EAST <= '1';
		wait for 500*CLK_period;
		BTN_EAST <= '0';
	end process;
end;
