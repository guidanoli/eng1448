library ieee;
use ieee.std_logic_1164.all;

library proclib;
use proclib.types.all;

entity proc is
	port (CLK: in std_logic;
	      BTN_NORTH, BTN_EAST, BTN_SOUTH, BTN_WEST: in std_logic;
			ROT_A, ROT_B, ROT_CENTER: in std_logic;
			J1, J2: out NibbleT);
end entity;

architecture rtl of proc is
	component alu is
		port (A, B: in ByteT;
				OP: in AluOpT;
				C: out ByteT;
				ZERO, CARRY: out std_logic);
	end component;
	component cu is
		port (CLK, ALU_ZERO, ALU_CARRY: in std_logic;
				SP, ALU_OUT, LSU_OUT: in ByteT;
				A_MUX_SEL, B_MUX_SEL, C_MUX_SEL : out std_logic;
				SP_INC, SP_DEC, LSU_WE, RU_C_EN: out std_logic;
				A_MUX_IN, B_MUX_IN: out ByteT;
				RU_SEL_A, RU_SEL_B, RU_SEL_C: out RegAddrT;
				ALU_OP: out AluOpT);
	end component;
	component lsu is
		port (CLK, WE: in std_logic;
				DEVICEIN: in ByteT;
				DATAIN: in ByteT;
				ADDR: in ByteT;
				DATAOUT: out ByteT;
				DEVICEOUT: out ByteT);
	end component;
	component ru is
		port (CLK, EN_C: in std_logic;
				SEL_A, SEL_B, SEL_C: in RegAddrT;
				C: in ByteT;
				A, B: out ByteT);
	end component;
	component mux is
		port (SEL: in std_logic;
				BYTEIN_0, BYTEIN_1: in ByteT;
				BYTEOUT: out ByteT);
	end component;
	component rising_edge_detector is
		port (CLK, A: in std_logic;
				B: out std_logic);
	end component;
	component counter is
		generic (INITIAL_VALUE: integer);
		port (CLK, INC, DEC: in std_logic;
				VALUE: out ByteT);
	end component;
	component driver is
		port (CNT : in ByteT;
				CLK_50MHZ : in std_logic;
				J1, J2 : out NibbleT);
	end component;
	
	signal DATA_BUS, ADDR_BUS, REG_BUS : ByteT;
	
	signal ALU_OUT : ByteT;
	signal ALU_OP : AluOpT;
	signal ALU_ZERO, ALU_CARRY : std_logic;
	
	signal LSU_WE : std_logic;
	signal LSU_OUT : ByteT;
	
	signal RU_C_EN, RU_C_EN_EDGE : std_logic;
	signal RU_SEL_A, RU_SEL_B, RU_SEL_C : RegAddrT;
	signal RU_A, RU_B : ByteT;
	
	signal A_MUX_SEL : std_logic;
	signal MUX_A_IN_CPU : ByteT;
	
	signal B_MUX_SEL : std_logic;
	signal MUX_B_IN_CPU : ByteT;
	
	signal C_MUX_SEL : std_logic;
	
	signal SP : ByteT;
	signal SP_INC_EDGE, SP_DEC_EDGE : std_logic;
	signal SP_INC, SP_DEC : std_logic;
	
	signal DEVICEIN, DEVICEOUT : ByteT;
begin
	proc_alu: entity work.alu
	port map(
		A => ADDR_BUS, B => DATA_BUS, C => ALU_OUT,
		OP => ALU_OP, ZERO => ALU_ZERO, CARRY => ALU_CARRY);
	
	proc_lsu: entity work.lsu
	port map(
		CLK => CLK, WE => LSU_WE,
		DEVICEIN => DEVICEIN, DEVICEOUT => DEVICEOUT,
		DATAIN => DATA_BUS, DATAOUT => LSU_OUT,
		ADDR => ADDR_BUS);

	proc_ru: entity work.ru
	port map(
		CLK => CLK, EN_C => RU_C_EN_EDGE,
		SEL_A => RU_SEL_A, SEL_B => RU_SEL_B, SEL_C => RU_SEL_C,
		A => RU_A, B => RU_B, C => REG_BUS);
	
	proc_mux_a: entity work.mux
	port map(
		SEL => A_MUX_SEL,
		BYTEIN_0 => MUX_A_IN_CPU, BYTEIN_1 => RU_A,
		BYTEOUT => ADDR_BUS);
	
	proc_mux_b: entity work.mux
	port map(
		SEL => B_MUX_SEL,
		BYTEIN_0 => MUX_B_IN_CPU, BYTEIN_1 => RU_B,
		BYTEOUT => DATA_BUS);
	
	proc_mux_c: entity work.mux
	port map(
		SEL => C_MUX_SEL,
		BYTEIN_0 => LSU_OUT, BYTEIN_1 => ALU_OUT,
		BYTEOUT => REG_BUS);
	
	proc_ru_c_en_detector: entity work.rising_edge_detector
	port map(
		CLK => CLK, A => RU_C_EN, B => RU_C_EN_EDGE);
	
	proc_sp: entity work.counter
	generic map(
		INITIAL_VALUE => StackBaseAddr)
	port map(
		CLK => CLK, INC => SP_INC_EDGE, DEC => SP_DEC_EDGE, VALUE => SP);
	
	proc_sp_inc_detector: entity work.rising_edge_detector
	port map(
		CLK => CLK, A => SP_INC, B => SP_INC_EDGE);
	
	proc_sp_dec_detector: entity work.rising_edge_detector
	port map(
		CLK => CLK, A => SP_DEC, B => SP_DEC_EDGE);
	
	proc_cu: entity work.cu
	port map(
		CLK => CLK, ALU_ZERO => ALU_ZERO, ALU_CARRY => ALU_CARRY,
		SP => SP, ALU_OUT => ALU_OUT, LSU_OUT => LSU_OUT,
		A_MUX_SEL => A_MUX_SEL, B_MUX_SEL => B_MUX_SEL, C_MUX_SEL => C_MUX_SEL,
		SP_INC => SP_INC, SP_DEC => SP_DEC, LSU_WE => LSU_WE, RU_C_EN => RU_C_EN,
		A_MUX_IN => MUX_A_IN_CPU, B_MUX_IN => MUX_B_IN_CPU,
		RU_SEL_A => RU_SEL_A, RU_SEL_B => RU_SEL_B, RU_SEL_C => RU_SEL_C,
		ALU_OP => ALU_OP);
	
	proc_drv: entity work.driver
	port map(
		CNT => DEVICEOUT, CLK_50MHZ => CLK, J1 => J1, J2 => J2);
	
	DEVICEIN <= '0'      & BTN_EAST & BTN_NORTH & BTN_SOUTH &
	            BTN_WEST & ROT_A    & ROT_B     & ROT_CENTER;
end architecture;