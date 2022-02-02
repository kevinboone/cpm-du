;------------------------------------------------------------------------
;  DU utility
;
;  main.asm 
;
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

	.Z80

	ORG    0100H

	include conio.inc
	include dbgutl.inc
	include clargs.inc
	include string.inc
	include bdos.inc
	include files.inc
	include bdmem.inc
	include initfcb.inc
	include mem.inc

	JP	main

;------------------------------------------------------------------------
;  prthelp 
;  Print the help message
;------------------------------------------------------------------------
prthelp:
	PUSH	HL
	LD 	HL, us_msg
	CALL	puts
	LD 	HL, hlpmsg
	CALL	puts
	POP	HL
	RET

;------------------------------------------------------------------------
;  prtversion
;  Print the version message
;------------------------------------------------------------------------
prtversion:
	PUSH	HL
	LD 	HL, ver_msg
	CALL	puts
	POP	HL
	RET

;------------------------------------------------------------------------
; enum_bc 
; A callback function for enum_files. It is called for each file 
;   found, with HL set to the start of an FCB. In this case, we
;   append the FCB to memory, in a region starting at the start of
;   heap. We store the entire FCB, so we can use it later in a BDOS
;   call to get the file size.
; This callback function must preserve all registers, except that it
;   must return non-zero in A to continue enumeration.
;------------------------------------------------------------------------
enum_cb:

	PUSH	BC
	PUSH 	DE	
	
	; HL points to FCB on entry	
	; (flpos) stores the current location in the heap to
	;   store the FCB
        ; Copy the first 36 bytes from HL to (flpos)
	LD	BC, 36 
	LD	DE, (flpos)
	CALL	memcpy 

	PUSH	HL
	; Add 36 to (flpos)
	LD	HL, 36 
	ADD	HL, DE
	LD	(flpos), HL

	; Increment (flcount), the number of files found
	LD	HL, (flcount)
	INC	HL
	LD	(flcount), HL 
	POP	HL
	LD 	A, 1	; Return non-zero to continue

	POP 	DE	
	POP	BC
	RET

;------------------------------------------------------------------------
; prtrec
; print the record count in DE, both raw and as a size. To avoid having
;   to do any math larger than 16 bits, we display the size in kB,
;   rather than bytes, when it is > 1 kB (one record is 1/8 of a kB)
; A lot of the fiddling in this function is for trivial matters like
;   printing "1 record" rather than "1 record(s)"
;------------------------------------------------------------------------
prtrec:
	PUSH	DE
	PUSH	BC
	PUSH	HL

	; Print the raw records
	LD 	HL, numbuff
	CALL	utoa
	CALL	puts
	LD 	HL, rec_txt 
	CALL	puts
	
	LD	A, D
	OR	A
	JR	NZ, .notone
	LD	A, E
	CP	1
	JR	NZ, .notone
	JR	.one
	
.notone:
	LD	A, 's'
	CALL	putch

.one:
	LD	A, ','
	CALL	putch
	CALL	space
	LD	B, D
	LD	C, E

	; Covert records to kB by shift-left three times
	SRL D
  	RR E
  	SRL D
  	RR E
  	SRL D
  	RR E

	LD 	HL, numbuff

	; If we end up with zero kB, print bytes instead 
	LD	A, D
	OR	E
	JR	Z, .inbytes
	CALL	utoa
	CALL 	puts	
	LD	HL, kbt_txt
	CALL 	puts	
	JR	.prt_dn	

.inbytes:
	LD	D, B
	LD	E, C
	SRL 	D	; Divide by 8
  	RR 	E
  	LD 	D, E
  	LD 	E, 0
  	RR 	E
	CALL	utoa
	CALL 	puts	
	LD	HL, bt_txt
	CALL 	puts	

.prt_dn:
	CALL	newline
	POP	HL
	POP	BC
	POP	DE
	RET
	
;------------------------------------------------------------------------
; doarg 
; This function is called once for each non-switch command-line
;   argument. It does all the work for that drive:file pattern.
; On entry, HL address the argument, which can take a variety
;   of different formats.
;------------------------------------------------------------------------
doarg:
	PUSH	BC

	PUSH	HL
	; Initialize the file counter to 0 and the file data pointer
	;   to the bottom of the heap
	LD	HL, 0
	LD	(flcount), HL 
	CALL	membase
	LD	(flpos), HL 
	POP	HL
	; HL contains the command-line argument

	; If the argument is of the form "X:", we must replace it
	;   (in HL) with the string allfldrv; but first we take the
	;   drive letter from the CL arg, and substitute it as the
	;   first character in allfldrv
	PUSH	HL
	INC	HL
	LD	A, (HL)
	CP	':'
	JR	NZ, .nodrv
	INC	HL
	LD	A, (HL)
	CP	0
	JR	NZ, .noempty
	; If we get here, the argument is a drive only "P:".
	POP	HL
	LD	A, (HL)
	LD	HL, allfldrv
	LD	(HL), A
	PUSH	HL
	JR	.nodrv
.noempty:
.nodrv:
	POP	HL
	
	; Store the file pattern ref in IY, because it's hard to
	;  keep track of it in the subsequent processing. This is
	;  a dodgy way to save storing 12 bytes, but I happen to
	;  know that IY isn't used anywhere else.
	PUSH HL
	POP IY
	
	LD	BC, enum_cb ; Address called by enumfiles when enumerating
	CALL 	enumfiles
	CP	0
	JP	Z, .nomatch	; Enumeration failed

	PUSH	HL
	; Store the flcount value in sflcount, because we will 
	;   decrement flcount to keep track of how many saved 
	;   FCBs to read in the processing that follows. The
	;   saved value will be used for display when all the
	;   rest of the work has been done.
	LD	HL, (flcount) 
	LD	(sflcount), HL 
	POP	HL

	CALL	membase
	; Get the start of heap into (flpos) (again)
	LD	(flpos), HL

.flnext:
	; This loop is done once for each FCB stored when iterating files
	LD	HL, (flpos) 
	; Get flcount into DE, and see if it is 0
	LD	DE, (flcount)
	LD	A, D
	OR	E
	JP	Z, .fln1	; All FBCs done

	LD	DE, (flpos)

	; Open the file using the stored FCB
	LD	C, F_OPEN
	PUSH	DE
	PUSH	HL
	CALL	BDOS
	POP	HL
	POP	DE
	CP	0
	; I _think_ anything but zero is a failure here
	JR	NZ, .openfail

	; Get the file size from BDOS
	LD	C, F_SIZE
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	BDOS
	POP	HL	
	POP	DE
	POP	BC

	PUSH	DE	; We're going to need the FCB again to close file

	; This section is for printing the name
        LD      H, D
        LD      L, E
	PUSH	HL
	LD	BC, 12
	ADD	HL, BC
	LD	(HL), 0
	POP	HL
	INC	HL
	LD	A, (details)
	CP	0
	JR	Z, .noprtname
	CALL	puts
	CALL	space
.noprtname:

	; Record count is at pos 33 and 34 of the FCB
	LD	HL, (flpos) 
        LD      BC, 33
        ADD     HL, BC
        LD      A, (HL)
        LD      C, A
        INC     HL
        LD      A, (HL)
        LD      B, A
	; Record count is now in BC

	; Add the record count to the running total
	PUSH	HL
	LD	HL, (reccount)
	ADD	HL, BC
	LD	(reccount), HL 
	POP	HL

	; Print the individual file details if (details) in set
	LD	A, (details)
	CP	0
	JR	Z, .noprtrecs
	LD	D, B
	LD	E, C
	LD	HL, numbuff
	CALL	utoa
	CALL	puts
	CALL	newline
.noprtrecs:

	POP	DE
	; Close the file. I'm not sure whether this is necessary
	LD	C, F_CLOSE
	CALL	BDOS
	JR	.openok

.openfail:
	; If we get here, a file open failed. This shouldn't happen,
	;   because very file we try to open has been enumerated 
	;   by BDOS. On my emulator, files with mixed case names 
	;   enumarate, but do not open. I don't know if this is
	;   possible in a real CP/M system.
	PUSH	HL
	INC	HL
	call    puts	
	LD	HL, copen_msg 
	call    puts	
	call 	newline	
	POP	HL

.openok:
	; Now increment the current FCB position by 36 bytes, and
	;   decrement the count of FCBs to process
	LD	HL, (flpos) 
	LD	BC, 36
	ADD	HL, BC 
	LD	(flpos), HL
	LD	DE, (flcount)
	DEC	DE
	LD	(flcount), DE
	JP	.flnext

.fln1:	
	; We've finished scanning the saved FCBs in the heap. Now
	;   print the summary information.
	PUSH	IY
	POP 	HL
	CALL 	puts	
	LD	HL, colon
	CALL 	puts	

	LD	HL, numbuff
	LD	DE, (sflcount)
	CALL	utoa
	CALL 	puts	
	LD	HL, file_txt 
	CALL 	puts

	LD	A, D
	OR	A
	JR	NZ, .flnotone
	LD	A, E
	CP	1
	JR	NZ, .flnotone
	JR	.flone
	
.flnotone:
	LD	A, 's'
	CALL	putch

.flone:
	LD	A, ','
	CALL	putch
	CALL	space
	LD	B, D
	LD	C, E

	LD	HL, numbuff
	LD	DE, (reccount)
	CALL	prtrec

.fln2:	
	POP	BC
	RET

.nomatch:
	; If we get here, enumfiles returned zero. CP/M doesn't give
	;   us a way to tell if that's an error, or just that a 
	;   pattern was give that didn't match anything.
	PUSH	HL
	LD	HL, nm_msg
	CALL	puts
	POP	HL
	CALL	puts
	CALL 	newline	
	JR	.fln2

;------------------------------------------------------------------------
;  Start here 
;------------------------------------------------------------------------
main:
	; Initialize the command-line parser
	CALL	clinit
	LD	B, 0	; Arg count

	; Loop until all CL arguments have been seen
.nextarg:
	CALL	clnext
	JR	Z, .argsdone

	OR	A
	JR	Z, .notsw
	; A is non-zero, so this is a switch character 
	CP	'H'
	JR	NZ, .no_h
	CALL	prthelp
	JP	.done
.no_h:
	CP	'D'
	JR	NZ, .no_s
	LD	A, 1
	LD 	(details), A
	JR	.nextarg
.no_s:
	CP	'V'
	JR	NZ, .no_v
	CALL	prtversion
	JP	.done
.no_v:
	JP	.badswitch
.notsw:
	; A was zero after clnext, so not a switch
	LD	A, B
	OR	0
	JR	Z, .sknl
	CALL	newline
.sknl:
	CALL	doarg
	INC	B
	JR	.nextarg
.argsdone:
	; Arguments are done. 
	LD	A, B
	CP	0
	JR	NZ, .done
	LD	HL, allfiles
	CALL	doarg

.done:
	; ...and exit cleanly
	CALL	exit

;-------------------------------------------------------------------------
; badswitch
; print "Bad option" message and exit. 
;-------------------------------------------------------------------------
.badswitch:
	LD	HL, bs_msg
	CALL	puts
	CALL	newline
	LD	HL, us_msg
	CALL	puts
	CALL	newline
	JR	.done

;------------------------------------------------------------------------
; Data 
;------------------------------------------------------------------------
; Help message
hlpmsg: 	
	db "Show space used by files", 13, 10
	db "    /d file details", 13, 10
	db "    /h help", 13, 10
	db "    /v version", 13, 10
	db 0

; Scratch area for converting integers to strings
numbuff:
	db "12345678"
	db 0

; Various text messages 
us_msg:
	db "Usage: du [/dhv] [drv:pattern]..."
        db 13, 10, 0

ver_msg:
	db "Version 0.1a, (c)2022 K Boone, GPLv3"
        db 13, 10, 0

bs_msg:
	db "Bad option.", 0 

copen_msg:
	db ": can't open", 0 

nm_msg:
	db "No match: ", 0 

rec_txt:
	db " record", 0 

bt_txt:
	db " bytes", 0 

file_txt:
	db " file", 0 

colon:
	db ": ", 0 

kbt_txt:
	db " kB", 0 

allfiles:
	db "*.* ", 0 

allfldrv:
	db "@:*.*", 0 

; flcount is the running total of files found. It increments when 
;  enumerating the drive, then decremements as the saved FCBs are
;  processed
flcount:
	dw 0

; Saved file count. Used in the summary display
sflcount:
	dw 0

; Total number of records
reccount:	
	dw 0

; Pointer into the heap where we are storing FCBs enumerated by BDOS
flpos:
	dw 0

; Set to 1 if the /d switch is given
details:
	db 0

end 

