; ================================================================
; breakout from p249 of 'mastering machine code on your zx Spectrum'
; by toni baker 1983
;
; assembled using zasm 4.0:
; 	zasm -u p243_tap.asm
; .tap output file tested on fuse spectrum emulator on OS X
; ================================================================


; fill byte is $00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync byte and the checksum byte
; of the preceding segment are not counted when calculating the start address of this segment.


#target tap


; sync bytes:
headerflag:     equ 0
dataflag:       equ $ff

; some Basic tokens:
tCLEAR		equ     $FD             ; token CLEAR
tLOAD		equ     $EF             ; token LOAD
tCODE		equ     $AF             ; token CODE
tPRINT		equ     $F5             ; token PRINT
tRANDOMIZE	equ     $F9             ; token RANDOMIZE
tUSR		equ     $C0             ; token USR
tCLS 		equ		$FB				; token CLS

; memory areas
pixels_start	equ	$4000		; ZXSP screen pixels
attr_start		equ	$5800		; ZXSP screen attributes
printer_buffer	equ	$5B00		; ZXSP printer buffer
code_start		equ	24000

; characters
enter     	equ $0d
at_control	equ $16
asterisk  	equ $2A
plus      	equ $2b
zero      	equ $30
nine 		equ $39

;system vars
TVFLAG   	equ $5c3c
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
;		(note: $5B00 is the printer buffer)
;		(note: system variables at $5C00 were initialized by Basic)
; ---------------------------------------------------

#data VARIABLES, printer_buffer, $100

; vars
POSITION  	defs 2
LAST_MOVE	defs 2

; ---------------------------------------------------
;		a Basic Loader:
; ---------------------------------------------------

#code PROG_HEADER,0,17,headerflag
		defb    0						; Indicates a Basic program
		defb    "mloader   "			; the block name, 10 bytes long
		defw    variables_end-0			; length of block = length of basic program plus variables
		defw    10		    			; line number for auto-start, $8000 if none
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
        defb    tRANDOMIZE,tUSR         	; token RANDOMIZE, token USR
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
		defb    "mcoder    "	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

START
	XOR A
	LD (TVFLAG),A ;Print to upper part of screen.
	LD B,$0A
	LD HL,SPIRAL ;Point to spiral data.
S_LOOP
	LD E,(HL)
	INC HL
	LD D,(HL) ;DE: = next word of data.
	INC HL
	EX DE,HL ;HL: = next word of data.
R_LOOP
	ADD HL,HL
	JR C,WALL
	LD (IY+$55),$3f ;Set colours white on white.
	JR PR_SQ
WALL
	LD (IY+$55),$00 ;Set colours black on black.
PR_SQ
	LD A, plus
	RST $10 ;Print as required.
	LD A,H
	OR L
	JR NZ,R_LOOP ;Print whole row.
	LD A, enter
	RST $10 ;Prepare for next row.
	EX DE,HL ;HL: = points to next word of data.
	DJNZ S_LOOP ;Print whole structure.
	LD A,$38 ;A represents the colour scheme black on white.
	LD (attr_start + $21),A ;Print cross at starting position.
	LD (IY+$55),$30;Attribute for black on yellow.
	LD HL,SCORE_I ;Point HL to initial score data
	LD B,$15
SC_LOOP
	LD A,(HL)
	INC HL
	RST $10 ;Print initial score.
	DJNZ SC_LOOP
	LD HL,$3939
	LD (SCORE_C + $3),HL
	LD (SCORE_C + $4),HL ;Set current score to 999(00).
	LD HL,attr_start + $21 ;Point HL to current position.
	LD (POSITION),HL; Store current position.
	LD HL,$0000
	LD (LAST_MOVE),HL
LOOP
	LD HL,SCORE_C + $5 ;Point HL to hundreds digit of score.
DECIMAL
	LD A,(HL)
	CP $0F
	JR NZ,POSITIVE
	LD B,$03
RESET
 	INC HL
	LD (HL),zero
	DJNZ RESET
	RET
POSITIVE
	DEC A ;Decrement the score.
	CP $2F
	JR NZ,OK
	LD (HL),nine
	DEC HL
	JR DECIMAL
OK
	LD (HL),A
	LD HL,SCORE_C ;Point HL to current score data.
	LD B,$06
CS_LOOP
	LD A,(HL)
	INC HL
	RST $10 ;Print the current score.
	DJNZ CS_LOOP
	LD BC,$2800 ;A timed delay. Altering the initial
DELAY
	DEC BC ;value of BC changes the speed of the game.
	LD A, B
	OR C
	JR NZ,DELAY
	CALL KEY_SCAN ;Scan keyboard.
	LD A,E ;A: = which key has been pressed.
	CP $09 ;Check for “J” key.
	JR Z,LEFT
	CP $10 ;Check for “M” key.
	JR Z,DOWN
	CP $11 ;Check for “K” key.
	JR Z,RIGHT
	CP $12 ;Check for “I” KEY.
	JR NZ,LOOP
UP
	LD DE,$FFE0
	JR MOVE
LEFT
	LD DE,$FFFF
	JR MOVE
DOWN
	LD DE,$0020
	JR MOVE
RIGHT
	LD DE,$0001
MOVE
	LD HL,(LAST_MOVE); Is the player embedded in the wall?
	LD A,H
	OR L
	JR Z,MOVE_OK
	ADD HL,DE ;If so, is the player reversing?
	LD A,H
	OR L
	JR NZ,LOOP
MOVE_OK
	LD HL,(POSITION)
	LD A,(HL)
	XOR $07 ;Reassign square
	LD (HL),A ;with black or white square as required.
	ADD HL,DE ;Find new position.
	LD A,(HL)
	XOR $07    ;Draw black or
	LD (HL),A ;white cross as appropriate.
	LD (POSITION),HL ;Store new position.
	LD HL,$0000
	CP $38 ;Have we hit a wall?
	JR Z,FINISH ;Jump if not.
	LD H,D
	LD L,E
FINISH
	LD (LAST_MOVE),HL
	LD HL,(POSITION)
	LD DE,attr_start + $85
	SBC HL,DE ;Check whether or
	RET Z ;not the finishing square has been reached.
	JP LOOP

SPIRAL
	DEFW 1111111111100000b ;This data
	DEFW 1010000000100000b ;represents the
	DEFW 1010111110100000b ;shape of the
	DEFW 1010100010100000b ;square spiral,
	DEFW 1010101010100000b ;with ones
	DEFW 1010111010100000b ;representing
	DEFW 1010000010100000b ;walls, and zeros
	DEFW 1011111110100000b ;representing
	DEFW 1000000000100000b ;spaces.
	DEFW 1111111111100000b
SCORE_I
	DEFM enter   ;This data
	DEFM "Your " ; represents
	DEFM "score "; the message to
	DEFM "now " ; be printing giving
	DEFM "99900" ;your current score.
SCORE_C
	DEFM at_control,11,15; This data will be
	DEFM "000" ;used to represent the current score.

code_end:
