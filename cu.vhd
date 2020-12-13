library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library proclib;
use proclib.types.all;

entity cu is
	port (CLK, ALU_ZERO, ALU_CARRY: in std_logic;
			SP, ALU_OUT, LSU_OUT: in ByteT;
			A_MUX_SEL, B_MUX_SEL, C_MUX_SEL : out std_logic;
			SP_INC, SP_DEC, LSU_WE, RU_C_EN: out std_logic;
			A_MUX_IN, B_MUX_IN: out ByteT;
			RU_SEL_A, RU_SEL_B, RU_SEL_C: out RegAddrT;
			ALU_OP: out AluOpT);
end entity;

architecture rtl of cu is
	-- State machine
	type StateT is (Fetch1, Fetch2, Decode, Execute);
	signal state, next_state : StateT := Fetch1;
	
	-- Internal variables
	signal zero, carry : std_logic := '0';
	signal pc : ByteT := ByteT(to_unsigned(ProgramBaseAddr, ByteT'length));
	signal cir : ByteT;

	-- Current instruction enumerator
	type InstructionT is (LdiI, LdrI, StrI, PushI, PopI, MovI, IncI,
	                      DecI, InccI, DecbI, AddI, SubI, AndI, OrI,
								 XorI, LslI, LsrI, RolI, RorI, JmpI, BzI,
								 BnzI, BccI, JmpiI, BziI, BnziI, BcciI,
								 NoOpI);
	signal cie : InstructionT;
	
	-- Current instruction kind
	type InstructionK is (MemoryK, ArithmK, LogicK, IJumpK, DJumpK, NoneK);
	signal ci_kind : InstructionK;
	
	-- Instruction splices aliases
	-- Note: each instruction has 8 bits: AA BB CC DD
	alias iab : NibbleT is cir(7 downto 4); -- AA BB
	alias icd : NibbleT is cir(3 downto 0); -- CC DD
	alias ic : CrumbT   is cir(3 downto 2); -- CC
	alias id : CrumbT   is cir(1 downto 0); -- DD
	
	-- Constants
	constant const_zero : ByteT := (others => '0');
	constant const_one : ByteT := (0 => '1', others => '0');
begin
	process(CLK) is
	begin
		if rising_edge(CLK) then
			state <= next_state;
		end if;
	end process;
	
	process(CLK) is
	begin
		if rising_edge(CLK) then
			case state is
				when Fetch1 =>
					-- A <- pc
					A_MUX_SEL <= SelectCU;
					A_MUX_IN <= pc;
					-- B <- 1
					B_MUX_SEL <= SelectCU;
					B_MUX_IN <= const_one;
					-- Untrigger write to LSU
					LSU_WE <= '0';
					-- Untrigger write to RU
					RU_C_EN <= '0';
					-- Untrigger stack pointer controls
					SP_INC <= '0';
					SP_DEC <= '0';
					-- Add A and B
					ALU_OP <= OpAdd;
					
					-- To the next step
					next_state <= Fetch2;
				when Fetch2 =>
					-- cir <- MEM[pc]
					cir <= LSU_OUT;
					-- pc <- pc + 1
					pc <= ALU_OUT;
					
					-- To the next step
					next_state <= Decode;
				when Decode =>
					case cie is
						when LdiI =>
							-- A <- pc
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= pc;
							-- B <- 1
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= const_one;
							-- Write from LSU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectLSU;
							-- Add A and B
							ALU_OP <= OpAdd;
						when LdrI =>
							-- A <- Rr
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= id;
							-- Write from LSU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectLSU;
						when StrI =>
							-- A <- Rr
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= id;
							-- B <- Rd
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= ic;
						when PushI =>
							-- A <- SP
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= SP;
							-- B <- Rd
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= ic;
						when PopI =>
							-- A <- SP + 1
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= ByteT(unsigned(SP) + 1);
							-- Write from LSU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectLSU;
						when MovI =>
							-- A <- Rr
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= id;
							-- Select A
							ALU_OP <= OpSel;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when IncI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 1
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= const_one;
							-- Add A and B
							ALU_OP <= OpAdd;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when DecI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 1
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= const_one;
							-- Subtract A and B
							ALU_OP <= OpSub;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when InccI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- carry
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= (0 => carry, others => '0');
							-- Add A and B
							ALU_OP <= OpAdd;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when DecbI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 1 - carry
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= (0 => not carry, others => '0');
							-- Subtract A and B
							ALU_OP <= OpSub;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when AddI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- Rr
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= id;
							-- Add A and B
							ALU_OP <= OpAdd;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when SubI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- Rr
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= id;
							-- Subtract A and B
							ALU_OP <= OpSub;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when AndI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- Rr
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= id;
							-- "And" A and B
							ALU_OP <= OpAnd;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when OrI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- Rr
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= id;
							-- "Or" A and B
							ALU_OP <= OpOr;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when XorI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- Rr
							B_MUX_SEL <= SelectRU;
							RU_SEL_B <= id;
							-- "Xor" A and B
							ALU_OP <= OpXor;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when LslI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 0
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= const_zero;
							-- Shift A to the left and concatenate with B(0)
							ALU_OP <= OpLShift;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when LsrI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 0
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= const_zero;
							-- Shift A to the right and concatenate with B(0)
							ALU_OP <= OpRShift;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when RolI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 0
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= (0 => carry, others => '0');
							-- Shift A to the left and concatenate with B(0)
							ALU_OP <= OpLShift;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when RorI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- B <- 0
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= (0 => carry, others => '0');
							-- Shift A to the right and concatenate with B(0)
							ALU_OP <= OpRShift;
							-- Write from ALU to Rd
							RU_SEL_C <= ic;
							C_MUX_SEL <= SelectALU;
						when JmpI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- Select A
							ALU_OP <= OpSel;
						when BzI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- Select A
							ALU_OP <= OpSel;
						when BnzI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- Select A
							ALU_OP <= OpSel;
						when BccI =>
							-- A <- Rd
							A_MUX_SEL <= SelectRU;
							RU_SEL_A <= ic;
							-- Select A
							ALU_OP <= OpSel;
						when JmpiI =>
							-- A <- pc
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= pc;
							-- B <- N
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= ByteT(resize(signed(icd), 8));
							-- Add A and B
							ALU_OP <= OpAdd;
						when BziI =>
							-- A <- pc
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= pc;
							-- B <- N
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= ByteT(resize(signed(icd), 8));
							-- Add A and B
							ALU_OP <= OpAdd;
						when BnziI =>
							-- A <- pc
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= pc;
							-- B <- N
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= ByteT(resize(signed(icd), 8));
							-- Add A and B
							ALU_OP <= OpAdd;
						when BcciI =>
							-- A <- pc
							A_MUX_SEL <= SelectCU;
							A_MUX_IN <= pc;
							-- B <- N
							B_MUX_SEL <= SelectCU;
							B_MUX_IN <= ByteT(resize(signed(icd), 8));
							-- Add A and B
							ALU_OP <= OpAdd;
						when NoOpI =>
					end case;
					
					-- To the next step
					next_state <= Execute;
				when Execute =>
					case cie is
						when LdiI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
							-- pc <- pc + 1
							pc <= ALU_OUT;
						when LdrI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when StrI =>
							-- Trigger write to LSU
							LSU_WE <= '1';
						when PushI =>
							-- Trigger write to LSU
							LSU_WE <= '1';
							-- Trigger SP decrement
							SP_DEC <= '1';
						when PopI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
							-- Trigger SP increment
							SP_INC <= '1';
						when MovI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when IncI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when DecI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when InccI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when DecbI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when AddI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when SubI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when AndI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when OrI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when XorI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when LslI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when LsrI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when RolI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when RorI =>
							-- Trigger write to RU
							RU_C_EN <= '1';
						when JmpI =>
							-- pc <- Rd
							pc <= ALU_OUT;
						when BzI =>
							if zero = '1' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when BnzI =>
							if zero = '0' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when BccI =>
							if carry = '0' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when JmpiI =>
							-- pc <- Rd
							pc <= ALU_OUT;
						when BziI =>
							if zero = '1' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when BnziI =>
							if zero = '0' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when BcciI =>
							if carry = '0' then
								-- pc <- Rd
								pc <= ALU_OUT;
							end if;
						when NoOpI =>
					end case;
					
					if ci_kind = ArithmK or
					   ci_kind = LogicK then
						-- Register flags
						zero <= ALU_ZERO;
						carry <= ALU_CARRY;
					end if;
					
					-- To the next step
					next_state <= Fetch1;
			end case;
		end if;
	end process;
	
	cie <= LdiI when (iab = "0000" and id = "00") else
	       LdrI when iab = "0001" else
			 StrI when iab = "0010" else
			 PushI when (iab = "0000" and id = "10") else
			 PopI when (iab = "0000" and id = "11") else
			 MovI when iab = "0011" else
			 IncI when (iab = "0100" and id = "00") else
			 DecI when (iab = "0100" and id = "01") else
			 InccI when (iab = "0100" and id = "10") else
			 DecbI when (iab = "0100" and id = "11") else
			 AddI when iab = "0101" else
			 SubI when iab = "0110" else
			 AndI when iab = "0111" else
			 OrI when iab = "1000" else
			 XorI when iab = "1001" else
			 LslI when (iab = "1010" and id = "00") else
			 LsrI when (iab = "1010" and id = "01") else
			 RolI when (iab = "1010" and id = "10") else
			 RorI when (iab = "1010" and id = "11") else
			 JmpI when (iab = "1011" and id = "00") else
			 BzI when (iab = "1011" and id = "01") else
			 BnzI when (iab = "1011" and id = "10") else
			 BccI when (iab = "1011" and id = "11") else
			 JmpiI when iab = "1100" else
			 BziI when iab = "1101" else
			 BnziI when iab = "1110" else
			 BcciI when iab = "1111" else
			 NoOpI;
	 
	 with cie select
		ci_kind <= MemoryK when LdiI,
		           MemoryK when LdrI,
		           MemoryK when StrI,
		           MemoryK when PushI,
		           MemoryK when PopI,
		           ArithmK when MovI,
		           ArithmK when IncI,
		           ArithmK when DecI,
		           ArithmK when InccI,
		           ArithmK when DecbI,
		           ArithmK when AddI,
		           ArithmK when SubI,
		           LogicK when AndI,
		           LogicK when OrI,
		           LogicK when XorI,
		           LogicK when LslI,
		           LogicK when LsrI,
		           LogicK when RolI,
		           LogicK when RorI,
		           IJumpK when JmpI,
		           IJumpK when BzI,
		           IJumpK when BnzI,
		           IJumpK when BccI,
		           DJumpK when JmpiI,
		           DJumpK when BziI,
		           DJumpK when BnziI,
		           DJumpK when BcciI,
		           NoneK when NoOpI;
	
end architecture;