; ================================================================
;	Example source for target 'tap'
;	Tape file for ZX Spectrum and Jupiter ACE
;	Copyright  (c)	Günter Woigk 1994 - 2015
;					mailto:kio@little-bat.de
; ================================================================


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

pixels_start	equ	0x4000		; ZXSP screen pixels
attr_start		equ	0x5800		; ZXSP screen attributes
printer_buffer	equ	0x5B00		; ZXSP printer buffer
code_start		equ	24000

; characters
asterisk equ 0x2A
enter equ 0x0d

;system vars
TVFLAG equ 0x5c3c
DF_CC equ 0x5c84
S_POSN equ 0x5c88


; rom routines
KEY_SCAN equ 0x028e
KEY_TEST equ 0x031e
KEY_CODE equ 0x0333

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

; 30 PRINT USR 24000
        defb    0,30                    ; line number
        defb    end30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tRANDOMIZE,tUSR         	; token RANDOMIZE, token USR
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
end30:  defb    $0d                     ; line end marker

program_end:

		; ZX Spectrum Basic variables

variables_end:



; ---------------------------------------------------
;		a machine code block:
; ---------------------------------------------------

#code CODE_HEADER,0,17,headerflag
		defb    3						; Indicates binary data
		defb    "mcoder    "	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

LARGE	XOR A
		LD (TVFLAG),A ;Send PRINT to upper part of screen.
AT_0_0	LD HL,0x4000
		LD (DF_CC),HL
		LD HL,0x1821
		LD (S_POSN),HL ;PRINT AT 0,0.
WAIT	CALL SCAN; Scan the keyboard
		JR C,WAIT
		CP 0x20
		RET C; Return to BASIC if
		CP 0x80 ;a non-printable character is pressed
		RET NC
		LD L,A
		LD H,0x00 ;HL: = character code of character pressed
		ADD HL,HL
		ADD HL,HL
		ADD HL,HL ;Multiply character code by eight
		LD DE,0x3C00
		ADD HL,DE ;Add 3C00 to this number (See Chapter Seven about this rule)
		LD C,0x04
OUTERLOOP	LD B,0x04
		LD D,(HL); Transfer two rows
		INC HL;    of pixels into DE.
		LD E,(HL)
		INC HL
INNERLOOP	LD A,0x08; (08 will become 80 once shifted left four times)
		RL E ;Compute which graphics character is to be printed
		RL A 
		RL E
		RL A
		RL D
		RL A
		RL D
		RLA
		RST 0x10; Print this symbol
		DJNZ INNERLOOP ;Next print position
		LD A,enter
		RST 0x10; End of current line
		DEC C
		JR NZ,OUTERLOOP
		JR AT_0_0


SCAN	CALL KEY_SCAN
		JR NZ,VOID
		CALL KEY_TEST
		JR NC,VOID
		LD E,A
		LD C,0x00
		LD D,0x08
		CALL KEY_CODE
		AND A
		RET
VOID	SCF
		RET
	

code_end:












