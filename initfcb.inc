;------------------------------------------------------------------------
;  initfcb.inc
;  Copyright (c)2021 Kevin Boone, GPL v3.0
;------------------------------------------------------------------------

	.Z80

; --- fn2fcb
; Converts a useable filename, e.g., "foo.bar" into the 8+3 pattern
;   required in a BDOS FCB. On Entry, HL points to a zero-terminated
;   input filename, and DE points to a block of memory at least 
;   11 bytes long (probably in an FCB). No more than 8 characters of the
;   input will be read before the dot (if present), nor more than 
;   three characters after the dot. The output filename will not be
;   zero-terminated, as the FCB does not require it to be, since it is
;   always of exactly 11 characters.
;
; Wildcard * characters in the input are expanded to ? in the output,
;   up to a point. This implementation is not complete at present.
external fn2fcb 

external initfcb

