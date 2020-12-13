library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proclib;
use proclib.types.all;

entity lsu is
	port (CLK, WE: in std_logic;
	      DEVICEIN: in ByteT;
			DATAIN: in ByteT;
			ADDR: in ByteT;
			DATAOUT: out ByteT;
			DEVICEOUT: out ByteT);
end entity;

architecture rtl of lsu is
	type ramT is array(0 to 2**(ByteT'length)-1) of ByteT;
  -- fib.asm
  signal ram: ramT := (
     32 => "00001000", -- 10: start: ldi  r2, 1
     33 => "00000001", -- 
     34 => "10010000", -- 11:        xor  r0, r0
     35 => "00001100", -- 12:        ldi  r3, @ssd
     36 => "00001110", -- 
     37 => "00100011", -- 13:        str  r0, [r3]
     38 => "00110001", -- 15: loop:  mov  r0, r1
     39 => "00001100", -- 16:        ldi  r3, @inp
     40 => "00001100", -- 
     41 => "00010111", -- 17:        ldr  r1, [r3]
     42 => "00001100", -- 18:        ldi  r3, 0xff
     43 => "11111111", -- 
     44 => "10010011", -- 19:        xor  r0, r3
     45 => "01110001", -- 20:        and  r0, r1
     46 => "10100010", -- 21:        rol  r0
     47 => "10100010", -- 22:        rol  r0
     48 => "00001100", -- 23:        ldi  r3, @loop
     49 => "00100110", -- 
     50 => "10111111", -- 24:        bcc  r3
     51 => "00001110", -- 25:        push r3
     52 => "00001100", -- 26:        ldi  r3, @fib
     53 => "10000000", -- 
     54 => "10111100", -- 27:        jmp  r3
    128 => "00001100", -- 30: fib:   ldi  r3, @ssd
    129 => "00001110", -- 
    130 => "00010011", -- 31:        ldr  r0, [r3]
    131 => "01010010", -- 32:        add  r0, r2
    132 => "11110100", -- 33:        bcci @fib2
    133 => "00000011", -- 34:        pop  r0
    134 => "00000000", -- 35:        ldi  r0, @start
    135 => "00100000", -- 
    136 => "10110000", -- 36:        jmp  r0
    137 => "00101011", -- 38: fib2:  str  r2, [r3]
    138 => "00111000", -- 39:        mov  r2, r0
    139 => "00000011", -- 40:        pop r0
    140 => "10110000", -- 41:        jmp r0
    others => "00000000");
begin
	process(CLK) is
	begin
		if rising_edge(CLK) then
			-- User I/O
			if WE = '1' then
				ram(to_integer(unsigned(ADDR))) <= DATAIN;
			else
				DATAOUT <= ram(to_integer(unsigned(ADDR)));
			end if;
			-- Device I/O
			DEVICEOUT <= ram(DeviceOutputAddr);
			ram(DeviceInputAddr) <= DEVICEIN;
		end if;
	end process;
end architecture;