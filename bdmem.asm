;------------------------------------------------------------------------
;  bdmem.asm 
;
;  See bdmem.inc for details 
;
;  Copyright (c)2022 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

 	.Z80

	global memtop, membase 
	include bdos.inc
	include end.inc

;------------------------------------------------------------------------
; memtop 
;------------------------------------------------------------------------
memtop:
	PUSH	BC
	LD 	HL, 0
	ADD 	HL, SP 
	LD	BC, -BD_STACK_MAX
	ADD	HL, BC 
	POP	BC
	RET

;------------------------------------------------------------------------
; membase.
; HL = start of heap 
;------------------------------------------------------------------------
membase:
	PUSH	BC
	LD 	HL, endprog 
	LD	BC, 128
	ADD	HL, BC 
	POP	BC
	RET

END


