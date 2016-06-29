; ====================================================================
;	pixel sprite code largely taken from
;	machine code sprites and graphics for the zx spectrum by john durst
;
;   assemble using zasm 4:
;     zasm -u test-pixel.asm
; ====================================================================

; fill byte is 0x00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync byte and the checksum byte
; of the preceding segment are not counted when calculating the start address of this segment.

#target tap

; sync bytes:
HEADERFLAG:     equ 0
DATAFLAG:       equ $ff


; some Basic tokens:
tCLEAR		equ     $FD             ; token CLEAR
tLOAD		equ     $EF             ; token LOAD
tCODE		equ     $AF             ; token CODE
tPRINT		equ     $F5             ; token PRINT
tRANDOMIZE	equ     $F9             ; token RANDOMIZE
tUSR		equ     $C0             ; token USR
tCLS 		equ		$FB				; token CLS

PIXELS_START	EQU	$4000		; ZXSP SCREEN PIXELS
ATTR_START		EQU	$5800		; ZXSP SCREEN ATTRIBUTES
PRINTER_BUFFER	EQU	$5B00		; ZXSP PRINTER BUFFER
CODE_START		EQU	24000

; colours
COLOUR_BLACK 	equ $0
COLOUR_WHITE 	equ $07

; characters
ENTER     		equ $0d
INK_CONTROL 	equ $10
PAPER_CONTROL 	equ $11
AT_CONTROL		equ $16
SPACE			equ $20
ASTERISK  		equ $2A
PLUS      		equ $2b
ZERO      		equ $30
NINE 			equ $39
GRAPHIC_A		equ $90
GRAPHIC_B		equ $91
GRAPHIC_C		equ $92
GRAPHIC_D		equ $93
GRAPHIC_SHIFT_3	equ $8C

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

#data VARIABLES, PRINTER_BUFFER, 0x100

; define some variables here



; ---------------------------------------------------
;		a Basic Loader:
; ---------------------------------------------------

#code PROG_HEADER,0,17,HEADERFLAG
		defb    0						; Indicates a Basic program
		defb    "sprite-p  "			; the block name, 10 bytes long
		defw    VARIABLES_END-0			; length of block = length of basic program plus variables
		defw    10		    			; line number for auto-start, 0x8000 if none
		defw    PROGRAM_END-0			; length of the basic program without variables


#code PROG_DATA,0,*,DATAFLAG

		; ZX Spectrum Basic tokens

; 10 CLEAR 23999
        defb    0,10                    ; line number
        defb    END10-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLEAR                  ; token CLEAR
        defm    "23999",$0e0000bf5d00   ; number 23999, ascii & internal format
END10:  defb    $0d                     ; line end marker

; 20 LOAD "" CODE 24000
        defb    0,20                    ; line number
        defb    END20-($+1)             ; line length
        defb    0                       ; statement number
        defb    tLOAD,'"','"',tCODE     ; token LOAD, 2 quotes, token CODE
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
END20:  defb    $0d                     ; line end marker

; 30 CLS
        defb    0,30                    ; line number
        defb    END30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLS		         	; token RANDOMIZE, token USR
END30:  defb    $0d                     ; line end marker

; 40 PRINT USR 24000
        defb    0,40                    ; line number
        defb    END40-($+1)             ; line length
        defb    0                       ; statement number
        defb    tRANDOMIZE,tUSR         ; token RANDOMIZE, token USR
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
END40:  defb    $0d                     ; line end marker

PROGRAM_END:

		; ZX Spectrum Basic variables

VARIABLES_END:



; ---------------------------------------------------
;		a machine code block:
; ---------------------------------------------------

#code CODE_HEADER,0,17,HEADERFLAG
	defb    3						; Indicates binary data
	defb    "sprite-p-c"	  		; the block name, 10 bytes long
	defw    CODE_END-CODE_START		; length of data block which follows
	defw    CODE_START				; default location for the data
	defw    0       				; unused

#code CODE_DATA, CODE_START,*,DATAFLAG

; Z80 assembler code and data

	;; setup
		ld a,0
		ld (DF_SZ),a 			;set lower part of screen to 0 size so we get 24 lines

		ld a,$2					;set printing to
		call $1601				;top part of screen

		;; draw background
		ld a,AT_CONTROL			;set print position:
		rst $10 				;at
		ld a,$0
		rst $10					;0,
		rst $10					;0
		ld de, 704d				;22d*34d = characters in background
DRAW_BACKGROUND_CHAR
		ld a,'.'
		rst $10
		dec de
		ld a,d
		or e
		jp nz,DRAW_BACKGROUND_CHAR

		;; save background
		call DUMP_DISPLAYFILE

		;; display sprite
		ld a,$20
		ld (XPOS),a				;initial X
		ld (YPOS),a				;initial Y
		call PRINT_SPRITE
LOOP
		call KEY_SCAN
		inc d
		jr nz,CYCLE 			;Don't move if more than one key pressed.
		ld a,e 					;a: = key code of key pressed (ff if none).
		cp $1a					;check for o key
		jr z,LEFT
		cp $22					;check for p key
		jr z,RIGHT
		cp $25					;check for q key
		jr z,UP
		cp $26 					;check for a key
		jr z,DOWN
		cp $27					;check for capshift (left shift on mac) key
		jr nz,CYCLE				;no match? loop again. otherwise fall through
QUIT
		ld a,$2
		ld (DF_SZ),a 			;restore lower part of screen to 2
		ret						;return to BASIC
DOWN
		ld a,(YPOS)
		cp $28					;is y at bottom? 32d (we're 2 tall)
		jr z,CYCLE				;yes. can't move down any further
		push af
		call ERASE_SPRITE
		pop af
		sub $3
		ld (YPOS),a
		jr MOVE_SPRITE_1
LEFT
		ld a,(XPOS)
		cp $0					;is x at left?
		jr z,CYCLE				;yes. can't move left any further
		push af
		call ERASE_SPRITE
		pop af
		sub $3
		ld (XPOS),a
		jr MOVE_SPRITE_1
RIGHT
		ld a,(XPOS)
		cp $e7					;is x at right? 30d
		jr z,CYCLE 				;yes. can't move right any further
		push af
		call ERASE_SPRITE
		pop af
		add $3
		ld (XPOS),a
		jr MOVE_SPRITE_1
UP
		ld a,(YPOS)
		cp $10					;is y at top?
		jr z,CYCLE				;yes. can't move up any further
		push af
		call ERASE_SPRITE
		pop af
		add $3
		ld (YPOS),a
MOVE_SPRITE_1
		call PRINT_SPRITE
CYCLE
		jr LOOP
		ret

	;;
	;; subroutines
	;;

DUMP_DISPLAYFILE
		ld hl,$4000
		ld de,$d800
		ld bc,$1b00
		ldir
		ret

RESTORE_DISPLAYFILE
		ld hl,$d800
		ld de,$4000
		ld bc,$1b00
		ldir
		ret

REARRANGE_UDGS
		ld hl,PRINTER_BUFFER	;scratch area for rotated chars
		push hl
		xor a
		ld b,a					;B:=0 becomes 255 when decremented
CLEAR_PRN_BUF					;so visits all 265 bytes in printer buffer
		ld (hl),a				;set to 0
		inc hl
		djnz CLEAR_PRN_BUF
		pop de					;de:=printer_buffer
		ld hl,UDG_LOCAL_DATA	;our UDG area
		; ld hl,(UDGS)			;our UDG area
		ld b,$04				;2 groups of chars + 2 groups of matte
GROUP_LOOP
		push bc
    	ld c,$08               	;8 bytes per char
CONSECUTIVE_CHARS
		ld b,$02				;2 consecutive chars in our sprite
		push hl
BYTES_LOOP
		ld a,(hl)
		ld (de),a
		push bc
		ld bc,$0008
		add hl,bc
		pop bc
		inc de
		djnz BYTES_LOOP
		inc de
		pop hl
		inc hl					;select next char
		dec c
		jr nz, CONSECUTIVE_CHARS
		ld c,$10				;b is already 0
		add hl,bc				;select next group
		pop bc
		djnz GROUP_LOOP
		ret

ROTATE_SPRITE_TO_RIGHT
		;; setup sprite X,Y
		ld a,(YPOS)            	;
		ld b,a					;
		ld a,(XPOS)            	;
		ld c,a					;bc := ypos,xpos
		push bc
		ld de,PRINTER_BUFFER
		call $22aa
		ld c,a					;c:=number of rotates
		and a					;check for zero
		jr z,SKIP_ROTATE		;no rotate needed
ROTATE_NEXT_SPRITE_CHAR
		push de
		;ld b,$60				;3x3d sprite but 4d bytes wide = 12d * 8d = 92d = $60
		ld b,$60				;2x2d sprite but 3d bytes wide = 6d * 8d = 48d = $30
								;x2 for matte = $60
ROTATE_ONE_CHAR_N_TIMES
		ld a,(de)
		rra
		ld (de),a
		inc de
		djnz ROTATE_ONE_CHAR_N_TIMES
		pop de
		dec c					;need to rotate again?
		jr nz, ROTATE_NEXT_SPRITE_CHAR
SKIP_ROTATE
		pop bc
		ret

DISPLAY_SPRITE
		ld de,$9800				;offset for displayfile copy
		ld ix,PRINTER_BUFFER
		exx
		ld b,$10				;$18=24d = 3x8 pixel lines
EACH_BYTE_IN_CHAR_Y
		exx
		push bc
		call $22aa				;pixel_add
		ld b,$03				;sprite width=3
EACH_CHAR_IN_SPRITE
		push hl
		add hl,de
		ld a,(ix+48d)
		cpl
		and (hl)
		ld c,a
		ld a,(ix+48d)
		and (ix)
		or c
		pop hl
		ld (hl),a
		inc hl
		inc ix
		djnz EACH_CHAR_IN_SPRITE
		pop bc
		dec b
		exx
		djnz EACH_BYTE_IN_CHAR_Y
		exx
		ret

PRINT_SPRITE
		call REARRANGE_UDGS
		call ROTATE_SPRITE_TO_RIGHT
		call DISPLAY_SPRITE
		ret

ERASE_SPRITE
		call RESTORE_DISPLAYFILE
		ret

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

CODE_END:
