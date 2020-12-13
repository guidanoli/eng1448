	.equ inp, 0x0c  ; input register
	.equ ssd, 0x0e  ; 7-segment display register

; r0
; r1 - previous input register state
; r2 - next Fibonacci number to be displayed
; r3
; @ssd - current Fibonacci number being displayed

	.org 0x20       ; Start of program text
start:	ldi  r2, 1      ; F(n) = 1
	xor  r0, r0
	ldi  r3, @ssd
	str  r0, [r3]   ; Initialize display counter with F(n-1) = 0

loop:	mov  r0, r1     ; Save prevous input status into r0
	ldi  r3, @inp   ;
	ldr  r1, [r3]   ; Read current input status into r1
	ldi  r3, 0xff
	xor  r0, r3     ; Invert r0
	and  r0, r1     ; Detect positive edge (r1 & ~r0)
	rol  r0
	rol  r0         ; Move BTN_EAST into carry
	ldi  r3, @loop
	bcc  r3         ; If no edge, continue loop
	push r3
	ldi  r3, @fib
	jmp  r3         ; Call @fib, returning to @loop

	.org 0x80
fib:	ldi  r3, @ssd
	ldr  r0, [r3]   ; Read display counter
	add  r0, r2     ; F(n+1) = F(n) + F(n-1)
	bcci @fib2      ; If sum didn't overflow, branch to fib2
	pop  r0
	ldi  r0, @start
	jmp  r0         ; goto start

fib2:	str  r2, [r3]   ; F(n-1) -> F(n)
	mov  r2, r0     ; F(n)   -> F(n+1)
	pop r0
	jmp r0          ; ret

