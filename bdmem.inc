;------------------------------------------------------------------------
;  bdmem.inc
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

	.Z80

;------------------------------------------------------------------------
; memtop 
; Returns in HL the highest memory address that can be used by the
;   program. This is derived from the stack pointer and is, at best
;   an estimate  
;------------------------------------------------------------------------
external memtop 


;------------------------------------------------------------------------
; membase
; Returns in HL the lowest memory address that can be used by the
;   program. This is derived from the "endprog" symbol that must be
;   in the module linked last. This address might be "inside" the last
;   block of the program's .COM file, because files are always an exact
;   number of records in CP/M. The size of the .COM file can exceed the
;   program's code+data size by up to one record
;------------------------------------------------------------------------
external membase


