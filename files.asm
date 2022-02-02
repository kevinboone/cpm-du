;------------------------------------------------------------------------
;  files.asm 
;
;  See files.inc for details
;
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------
	;global filesize
	global enumfiles 

	include bdos.inc
	include initfcb.inc
	include dbgutl.inc

	.Z80

;------------------------------------------------------------------------
;  enumfiles 
;  HL=input fname, BC=callback address 
;  
;------------------------------------------------------------------------

enumfiles:
	PUSH	HL
	PUSH    DE	
	PUSH	BC

	; Make some space on the stack for the FCB we need
	LD	IX, -FCBSIZE
	ADD	IX, SP
	LD	SP, IX 
	
	; Get the current SP into DE, for use as an FCB area. 
	; But be careful, though -- we have protect HL, which
	;   contains the filename, by pushing it; but this puts
	;   the SP  2 bytes down. So we need to add 2 to the
	;   SP to get DE. If we get this wrong, the stack top ends up in 
	;   the FCB

	PUSH	HL
	LD	HL, 2
	ADD	HL, SP
	LD	D, H
	LD	E, L
	POP	HL

	; Filename address is in HL, FCB in DE at start of stack area
	PUSH	BC
	CALL	initfcb
	PUSH	HL
	PUSH	DE	
	LD	C, F_SFIRST
	CALL	BDOS
	POP	DE
	POP	HL
	POP	BC
	CP	0FFh	; This is the defined error code
	JR	Z, .ef_openfail
	
.fcbnext:
	; A (0-3) contains the address of the resulting FCB, in the
	;   DMA area. So the actual address is DMABUF + A * 32.
	;   Since 
	LD 	H, 0
	LD	L, A
	ADD	HL, HL	; Multiply A by 32
	ADD	HL, HL	
	ADD	HL, HL	
	ADD	HL, HL	
	ADD	HL, HL	
	PUSH	BC
	LD	BC, DMABUF
	ADD	HL, BC
	POP	BC
	; HL now contains the new FCB

	; Copy the drive from the original, search FCB to the new,
	;   result FCB. This might be zero, if no drive was 
	;   specified. Why BDOS does not do this itself, I really
	;   don't know. 
	LD	A, (DE)
	LD	(HL), A

	; The following bit of ugliness is "call (bc)". Unfortunably.
	;   The Z80 doesn't have indirect call instructions
	LD	IX, .enum_foo
	PUSH  	IX	
	
	PUSH 	BC
	POP	IX	
 	JP	(IX) 
	
.enum_foo:

	CP	0
	JR	Z, .ef_openok
	
	; DE still contains the address of the original FCB. 
	;   it is unclear whether BDOS S_FNEXT actually needs
	;   this or not

	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	C, F_SNEXT
	CALL	BDOS
	POP	BC
	POP	DE
	POP	HL
	CP	0FFh	; This is the defined error code
	JR	NZ, .fcbnext
	LD	A, 1
	JR	.ef_openok

.ef_openfail:
	LD	A, 0

.ef_openok:
	LD	IX, FCBSIZE
	ADD	IX, SP
	LD	SP, IX 
	POP	BC
	POP	DE
	POP	HL

	RET	

END

; ROUTINES NOT CURRENTLY USED

;------------------------------------------------------------------------
;  filesize 
;  HL=input fname, result as RECORDS in BC. Success A == 1 on exit,
;    else A == 0 
;------------------------------------------------------------------------
filesize:
	PUSH	HL
	PUSH    DE	

	; Make some space on the stack for the FCB we need
	LD	IX, -FCBSIZE
	ADD	IX, SP
	LD	SP, IX 
	
	; Get the current SP into DE, for use as an FCB area. 
	; But be careful, though -- we have protect HL, which
	;   contains the filename, by pushing it; but this puts
	;   the SP  2 bytes down. So we need to add 2 to the
	;   SP to get DE. If we get this wrong, the stack top ends up in 
	;   the FCB

	PUSH	HL
	LD	HL, 2
	ADD	HL, SP
	LD	D, H
	LD	E, L
	POP	HL

	; Filename address is in HL, FCB in DE at start of stack area
	CALL	initfcb
	LD	H, D
	LD	L, E
	PUSH	DE	
	LD	C, F_OPEN 
	CALL	BDOS
	POP	DE
	CP	0FFh	; This is the defined error code
	JR	Z, .openfail

	LD	C, F_SIZE
	; DE still points to FCB
	PUSH	DE
	PUSH	HL
	CALL	BDOS
	POP	HL
	POP	DE

	LD	BC, 33 
	LD	H, D
	LD	L, E
	ADD	HL, BC 
	LD	A, (HL)
	LD	C, A
	INC	HL
	LD	A, (HL)
	LD	B, A
	; Record count now in BC
	
	PUSH	BC
	; DE still points to FCB
	PUSH	DE
	PUSH	HL
	LD	C, F_CLOSE
	CALL	BDOS
	POP	HL
	POP	DE
	LD	A, 1
	POP	BC
	JR	.openok

.openfail:
	LD	A, 0

.openok:
	LD	IX, FCBSIZE
	ADD	IX, SP
	LD	SP, IX 
	POP	DE
	POP	HL

	RET



