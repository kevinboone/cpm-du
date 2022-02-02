;------------------------------------------------------------------------
;  initfcb.asm 
;
;  See initfcb.inc for description
;
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------
	global fn2fcb, initfcb

	include mem.inc
	include string.inc
	include dbgutl.inc
	include bdos.inc

	.Z80

;------------------------------------------------------------------------
;  fn2fcb 
;  HL=input fname, DE=BDOS fname
;------------------------------------------------------------------------
fn2fcb:
	PUSH	BC
	PUSH	HL
	PUSH	DE

        ; Start by padding the output with spaces
	PUSH	HL
	LD	H, D
	LD	L, E
	LD	BC, 11
	LD	A, ' '
	CALL	memset
	POP	HL

	POP	DE

        ; HL points to input filename 
 	; DE points to output filename
	; HL and DE now remain constant throughout this routine
	; B = in index, C = out index. These are incremented
        ; independently according to the input filename
	LD	B, 0
	LD	C, 0

        ; Repeat this first loop until either in[b] == 0 or
        ;  in[b] == '.' or b == 8 
.fn_lp1:
	; First test for B == 8
	LD	A, B
	CP      8	
	JR	Z, .fn_skext
	CALL	.fn_get 	; get in[b]


	; Test in[b]] == 0
	OR	A
	JR	Z, .fn_done	; if in[b] == 0, we're done

	; See if in[b] is a dot. If it is, jump to extension block
	CP	'.'
	JR	Z, .fn_ext

	; See if in[b] is a *. 
	CP	'*'
	JR	NZ, .fn_nostar

	; We've hit a * in the filename part. Fill the rest
	;  of the output filename with ?, and then skip to
	;  finding the extension part of the input filename
.fn_lp4:
	LD	A, '?'
	CALL	.fn_put
	INC	C
	LD	A, C
	CP	8
	JR	NZ, .fn_lp4

	JR	.fn_skext

.fn_nostar:
	CALL	.fn_put
	INC 	B
	INC	C
	JR	.fn_lp1

.fn_ext:
	; If we get here, we either found in[b] == '.', or we
	;  exceeded 8 characters before the dot, or we expanded a
	;  * in the input filename.
        ; So now we read again, until we find in[b] == 0 or
        ;  c == 11, or another *
	lD	C, 8 	; Skip output to extension
	INC	B	; Skip input over the dot

.fn_lp2:
	; First test for C == 11
	LD	A, C
	CP      11	
	JR	Z, .fn_done

	CALL	.fn_get 	; get in[b]

	; Test in[b]] == 0
	OR	A
	JR	Z, .fn_done	; if in[b] == 0, we're done

 	; Test for *
	CP	'*'
	JR	NZ, .fn_ndo2

	; We've hit a * in the extension part. Fill the rest
	;  of the output filename with ?, and then skip to done
.fn_lp5:
	LD	A, '?'
	CALL	.fn_put
	INC	C
	LD	A, C
	CP	11	
	JR	NZ, .fn_lp5

	JR	.fn_done

.fn_ndo2:
	CALL	.fn_put
	INC 	B
	INC	C
	JR	.fn_lp2

.fn_done:
	POP	HL
	POP	BC
	RET

.fn_skext:
	; If we get here, B == 8 or we found a * in the filename part of
	;  the input. We must skip everything in the
	;  input until we find a zero or a dot. If it's a dot, then
        ;  jump to the exception handling block. If it's a zero, 
	;  we're done

.fn_lp3:
	CALL .fn_get
	OR	A
	JR	Z, .fn_done
	CP	'.'
	JR	Z, .fn_ext
	INC	B
	JR	.fn_lp3

.fn_get:
	; Read A from (HL + B)
	PUSH	HL
	PUSH	BC
	LD	C, B
	LD	B, 0
	ADD	HL, BC
	LD	A, (HL)
	POP	BC
	POP	HL
	RET

.fn_put:
	; Write A to (DE + C)
	PUSH	HL
	PUSH	BC	
	LD	H, D
	LD	L, E
	LD	B, 0
	ADD	HL, BC
	LD	(HL), A
	POP	BC
	POP	HL
	RET

;------------------------------------------------------------------------
;  initfcb 
;  HL=fname, DE=fcb
;------------------------------------------------------------------------
initfcb:
	PUSH	HL
	PUSH	AF
	PUSH	DE
	LD	D, 0	; default drive letter
	CALL 	strlen
	LD	A, E
	; filename len now in A
	CP	2	
	JR	C, .shtfn
	; filename 2 chars or longer -- may have a drive letter
	INC	HL
	LD	A, (HL)
	DEC	HL	
	CP	':'
	JR	NZ, .nodrv
	; We have a drive letter
	LD	A, (HL)
	SUB	'@'
	INC	HL
	INC	HL
	LD	D, A
	JR	.gotdrf	
	
.nodrv:
	LD	D, 0
	
.shtfn:
	; filename only one char: cannot meaningfully have drive letter
	; So HL points to complete filename, and drive=0
	LD	D, 0

.gotdrf:
	; By this point, D=drive number (1=a) (which might be zero)
	;   and HL indicates the filename (which might be blank)
	LD	A, D

	POP	DE
	; DE now indicates the FCB address

	PUSH	HL
	LD	H, D
	LD	L, E
	; Init FCB to 0
	LD	BC, FCBSIZE
	PUSH	AF
	LD	A, 0
	CALL	memset
	POP	AF
	LD	(HL), A		; Store drive number at FCB + 0
	POP	HL

	INC	DE
	CALL	fn2fcb		; Write fname at FCB + 1
	DEC	DE	

	POP	AF
	POP	HL
	RET


END

