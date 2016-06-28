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
		defb    "sprite-p  "			; the block name, 10 bytes long
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
		defb    "sprite-p-c"	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

	;; setup
	LD A,0
	LD (DF_SZ),A 			;set lower part of screen to 0 size so we get 24 lines

	LD A,$2					;set printing to
	CALL $1601				;top part of screen

	LD A,$20
	LD (XPOS),A				;initial X
	LD (YPOS),A				;initial Y
	CALL PRINT_SPRITE

LOOP
	CALL KEY_SCAN
	INC D
	JR NZ,CYCLE 			;Don't move if more than one key pressed.
	LD A,E 					;A: = key code of key pressed (FF if none).
	CP $1A					;Check for O key
	JR Z,LEFT
	CP $22					;Check for P key
	JR Z,RIGHT
	CP $25					;Check for Q key
	JR Z,UP
	CP $26 					;Check for A key
	JR Z,DOWN
	CP $27					;Check for capshift (left shift on mac) key
	JR NZ,CYCLE				;no match? loop again. otherwise fall through
QUIT
	LD A,$2
	LD (DF_SZ),A 			;restore lower part of screen to 2
	RET						;return to BASIC
DOWN
	LD A,(YPOS)
	CP $15					;is Y at bottom? 20d (we're 2 tall)
	JR Z,CYCLE				;yes. can't move down any further
	PUSH AF
	CALL ERASE_SPRITE
	POP AF
	SUB $1
	LD (YPOS),A
	JR MOVE_SPRITE_1
LEFT
	LD A,(XPOS)
	CP $0					;is X at left?
	JR Z,CYCLE				;yes. can't move left any further
	PUSH AF
	CALL ERASE_SPRITE
	POP AF
	SUB $1
	LD (XPOS),A
	JR MOVE_SPRITE_1
RIGHT
	LD A,(XPOS)
	CP $E7					;is X at right? 30d
	JR Z,CYCLE 				;yes. can't move right any further
	PUSH AF
	CALL ERASE_SPRITE
	POP AF
	ADD $1
	LD (XPOS),A
	JR MOVE_SPRITE_1
UP
	LD A,(YPOS)
	CP $0					;is Y at top?
	JR Z,CYCLE				;yes. can't move up any further
	PUSH AF
	CALL ERASE_SPRITE
	POP AF
	ADD $1
	LD (YPOS),A
MOVE_SPRITE_1
	CALL PRINT_SPRITE
CYCLE
	LD HL,$1000				;delay size
DELAY
	DEC HL 					;This is a short delay loop which controls
	LD A,H 					;the speed of the game.
	OR L
	JR NZ,DELAY
	JR LOOP
	RET

REARRANGE_9_UDGS
	LD HL,printer_buffer	;scratch area for rotated chars
	PUSH HL
	XOR A
	LD B,A					;B:=0 becomes 255 when decremented
CLEAR_PRN_BUF				;so visits all 265 bytes in printer buffer
	LD (HL),A				;set to 0
	INC HL
	DJNZ CLEAR_PRN_BUF
	POP DE					;DE:=printer_buffer
	LD HL,UDG_LOCAL_DATA	;our UDG area
	; LD HL,(UDGS)	;our UDG area
	LD B,$02				;3 groups of chars
GROUP_LOOP
	PUSH BC
	LD C,$08				;8 bytes per char
CONSECUTIVE_CHARS
	LD B,$02					;3 consecutive chars
	PUSH HL
BYTES_LOOP
	LD A,(HL)
	LD (DE),A
	PUSH BC
	LD BC,$0008
	ADD HL,BC
	POP BC
	INC DE
	DJNZ BYTES_LOOP
	INC DE
	POP HL
	INC HL					;select next char
	DEC C
	JR NZ, CONSECUTIVE_CHARS
	LD C,$10				;b is already 0
	ADD HL,BC				;select next group
	POP BC
	DJNZ GROUP_LOOP
	RET

ROTATE_SPRITE_TO_RIGHT
	;; setup sprite X,Y
	LD A,(YPOS)            	;
	LD B,A					;
	LD A,(XPOS)            	;
	LD C,A					;BC := YPOS,XPOS
	PUSH BC
	LD DE,printer_buffer
	CALL $22AA
	LD C,A					;C:=number of rotates
	AND A					;check for zero
	JR Z,SKIP_ROTATE		;no rotate needed
ROTATE_NEXT_SPRITE_CHAR
	PUSH DE
	LD B,$30				;3x3d sprite but 4d bytes wide = 12d * 8d = 92d = $60
ROTATE_ONE_CHAR_N_TIMES
	LD A,(DE)
	RRA
	LD (DE),A
	INC DE
	DJNZ ROTATE_ONE_CHAR_N_TIMES
	POP DE
	DEC C					;need to rotate again?
	JR NZ, ROTATE_NEXT_SPRITE_CHAR
SKIP_ROTATE
	POP BC
	RET

DISPLAY_SPRITE
	LD A,(YPOS)            	;
	LD B,A					;
	LD A,(XPOS)            	;
	LD C,A					;BC := YPOS,XPOS
	LD IX,printer_buffer
	EXX
	LD B,$10				;$18=24d = 3x8 pixel lines
EACH_BYTE_IN_CHAR_Y
	EXX
	PUSH BC
	CALL $22AA				;PIXEL_ADD
	LD B,$03				;sprite width=4
EACH_CHAR_IN_SPRITE
	LD A,(IX)
	LD (HL),A
	INC HL
	INC IX
	DJNZ EACH_CHAR_IN_SPRITE
	POP BC
	DEC B
	EXX
	DJNZ EACH_BYTE_IN_CHAR_Y
	EXX
	RET

PRINT_SPRITE
	CALL REARRANGE_9_UDGS
	CALL ROTATE_SPRITE_TO_RIGHT
	CALL DISPLAY_SPRITE
	RET

ERASE_SPRITE
	RET

XPOS	defb 0
YPOS	defb 0


#include "udgs.asm"

;; $028e.  5  KEY_SCAN   {001} the keyboard scanning subroutine
;; On returning from $028e KEY_SCAN the DE register and the Zero flag indicate
;; which keys are being pressed.
;;
;; . The Zero flag is reset if pressing more than two keys, or pressing two
;;  keys and neither is a shift key; DE identifies two of the keys.
;; . The Zero flag is set otherwise, and DE identifies the keys.
;; . If pressing just the two shift keys then DE = $2718.
;; . If pressing one shift key and one other key, then D identifies the shift
;;   key and E identifies the other key.
;; . If pressing any one key, then D=$ff and E identifies the key.
;; . If pressing no key, then DE=$ffff.
;;
;; The key codes returned by KEY_SCAN are shown below.
;;
;; KEY_SCAN key codes: hex, decimal, binary
;; ? hh dd bbbbbbbb   ? hh dd bbbbbbbb   ? hh dd bbbbbbbb   ? hh dd bbbbbbbb
;; 1 24 36 00100011   Q 25 37 00100101   A 26 38 00100110  CS 27 39 00100111
;; 2 1c 28 00011100   W 1d 29 00011101   S 1e 30 00011110   Z 1f 31 00011111
;; 3 14 20 00010100   E 15 21 00010101   D 16 22 00010110   X 17 23 00010111
;; 4 0c 12 00001100   R 0d 13 00001101   F 0e 14 00001110   C 0f 15 00001111
;; 5 04  4 00000100   T 05  5 00000101   G 06  6 00000110   V 07  7 00000111
;; 6 03  3 00000011   Y 02  2 00000010   H 01  1 00000001   B 00  0 00000000
;; 7 0b 11 00001011   U 0a 10 00001010   J 09  9 00001001   N 08  8 00001000
;; 8 13 19 00010011   I 12 18 00010010   K 11 17 00010001   M 10 16 00010000
;; 9 1b 27 00011011   O 1a 26 00011010   L 19 25 00011001  SS 18 24 00011000
;; 0 23 35 00100011   P 22 34 00100010  EN 21 33 00100001  SP 20 32 00100000

code_end:
