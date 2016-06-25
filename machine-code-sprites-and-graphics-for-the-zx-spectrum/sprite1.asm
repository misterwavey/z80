; ====================================================================
;	Roadrace by gmail.com - atsign - jon.kingsman (reversed)
;   part of chuntey's z80 blog http://chuntey.arjunnair.in/?cat=62
;   wrapped in zasm's zx spectrum .tap template by stuart martin 2017
;   assemble using zasm 4:
;     zasm -u roadrace.asm
; ====================================================================


; fill byte is 0x00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync byte and the checksum byte
; of the preceding segment are not counted when calculating the start address of this segment.


#target tap


; sync bytes:
headerflag:     equ 0
dataflag:       equ 0xff


; some Basic tokens:
tCLEAR		equ     $FD             ; token CLEAR
tLOAD		equ     $EF             ; token LOAD
tCODE		equ     $AF             ; token CODE
tPRINT		equ     $F5             ; token PRINT
tRANDOMIZE	equ     $F9             ; token RANDOMIZE
tUSR		equ     $C0             ; token USR
tCLS 		equ		$FB				; token CLS

pixels_start	equ	0x4000		; ZXSP screen pixels
attr_start		equ	0x5800		; ZXSP screen attributes
printer_buffer	equ	0x5B00		; ZXSP printer buffer
code_start		equ	24000


; colours
colour_black 	equ $0
colour_white 	equ $07

; characters
enter     		equ $0d
ink_control 	equ $10
paper_control 	equ $11
at_control		equ $16
space			equ $20
asterisk  		equ $2A
plus      		equ $2b
zero      		equ $30
nine 			equ $39
graphic_A		equ $90
graphic_B		equ $91
graphic_C		equ $92
graphic_D		equ $93
graphic_shift_3	equ $8C

; system vars
TVFLAG   	equ $5c3c
DF_SZ 		equ $5C6B
UDGS 		equ $5C7B
DF_CC    	equ $5c84
S_POSN   	equ $5c88
ATTR_T   	equ $5C8F
MEMBOT   	equ $5C92

; rom routines
KEY_SCAN	equ $028e
KEY_TEST	equ $031e
KEY_CODE	equ $0333

; ---------------------------------------------------
;		ram-based, non-initialized variables
;		(note: 0x5B00 is the printer buffer)
;		(note: system variables at 0x5C00 were initialized by Basic)
; ---------------------------------------------------

#data VARIABLES, printer_buffer, 0x100

; define some variables here



; ---------------------------------------------------
;		a Basic Loader:
; ---------------------------------------------------

#code PROG_HEADER,0,17,headerflag
		defb    0						; Indicates a Basic program
		defb    "mloader   "			; the block name, 10 bytes long
		defw    variables_end-0			; length of block = length of basic program plus variables
		defw    10		    			; line number for auto-start, 0x8000 if none
		defw    program_end-0			; length of the basic program without variables


#code PROG_DATA,0,*,dataflag

		; ZX Spectrum Basic tokens

; 10 CLEAR 23999
        defb    0,10                    ; line number
        defb    end10-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLEAR                  ; token CLEAR
        defm    "23999",$0e0000bf5d00   ; number 23999, ascii & internal format
end10:  defb    $0d                     ; line end marker

; 20 LOAD "" CODE 24000
        defb    0,20                    ; line number
        defb    end20-($+1)             ; line length
        defb    0                       ; statement number
        defb    tLOAD,'"','"',tCODE     ; token LOAD, 2 quotes, token CODE
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
end20:  defb    $0d                     ; line end marker

; 30 CLS
        defb    0,30                    ; line number
        defb    end30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLS		         	; token RANDOMIZE, token USR
end30:  defb    $0d                     ; line end marker

; 40 PRINT USR 24000
        defb    0,40                    ; line number
        defb    end40-($+1)             ; line length
        defb    0                       ; statement number
        defb    tRANDOMIZE,tUSR         ; token RANDOMIZE, token USR
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
end40:  defb    $0d                     ; line end marker

program_end:

		; ZX Spectrum Basic variables

variables_end:



; ---------------------------------------------------
;		a machine code block:
; ---------------------------------------------------

#code CODE_HEADER,0,17,headerflag
		defb    3						; Indicates binary data
		defb    "mcode     "	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

	LD HL,UDG_LOCAL_DATA    ;point to local UDG data
	LD (UDGS),HL   			;tell system to use ours

	LD A, 2					;set printing to
	CALL $1601				;top part of screen

	LD BC,$0909            	;setup x,y
	CALL AT_X_Y				;print AT
	LD A,graphic_A			;udg 'A'
	RST $10 				;PRINT udg
	LD BC,$090A            	;setup x,y
	CALL AT_X_Y				;print AT
	LD A,graphic_B			;udg 'A'
	RST $10 				;PRINT udg
	LD BC,$0A09            	;setup x,y
	CALL AT_X_Y				;print AT
	LD A,graphic_D			;udg 'A'
	RST $10 				;PRINT udg
	LD BC,$0A0A            	;setup x,y
	CALL AT_X_Y				;print AT
	LD A,graphic_C			;udg 'A'
	RST $10 				;PRINT udg
	RET

AT_X_Y
	LD A,at_control
	RST $10
	LD A,B 					;First AT co-ordinate.
	RST $10
	LD A,C 					;Second AT co-ordinate.
	RST $10
	RET

#include "udgs.asm"


code_end:
