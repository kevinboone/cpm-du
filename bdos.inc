;------------------------------------------------------------------------
;  dbgutil.inc
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

	.Z80

	; BDOS call entry point
	BDOS	equ	5

	; Default FCB address 
	DEFFCB	equ	05Ch

	; Start of DMA buffer
	DMABUF  equ	80h
	
	; Console output character
	CONOUT equ 2 

	; Open file 
	F_OPEN equ 15 

	; Search first 
	F_SFIRST equ 17

	; Search first 
	F_SNEXT equ 18

	; Close file 
	F_CLOSE equ 16

	; Sizefile 
	F_SIZE equ 35 

	; Size in bytes of an FCB
	FCBSIZE	equ 36

	; Size to allow for the stack, which is located just below the
	;   BDOS CCP, and grows downwards. This figure is used when
	;   calculating the amount of memory available to a program and
	;   is, at best, an estimate. Stack-crashing is a well-known
	;   problem in CP/M
	BD_STACK_MAX	equ	256


