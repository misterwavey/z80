; ====================================================================
;	Roadrace by gmail.com - atsign - jon.kingsman (reversed)
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


pixels_start	equ	0x4000		; ZXSP screen pixels
attr_start		equ	0x5800		; ZXSP screen attributes
printer_buffer	equ	0x5B00		; ZXSP printer buffer
code_start		equ	24000



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

; 30 RANDOMIZE USR 24000
        defb    0,30                    ; line number
        defb    end30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tPRINT,tUSR         	; token PRINT, token USR
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
		defb    "mcode     "	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

 		di
		ld hl, 22537 					;initialise road
		push hl  						;save road posn
		xor a
		ld b,24
fillscreen	ld (hl),a
		inc hl
		ld (hl),a
		ld de,9
		add hl,de
		ld (hl),a
		inc hl
		ld (hl),a
		ld de,21
		add hl,de
		djnz fillscreen
		ld c,b  						;initialise score
		push bc  						;save score
		ld hl,23278 					;initialise car
		ld a,8
		ld (hl),a
		ld (32900),hl 					;save car posn
principalloop	ld hl,(32900) 			;retrieve car posn
		ld a,56  						;erase car
		ld (hl),a
		ei
		ld bc,65278 					;read keyboard caps to v
		in a,(c)
		cp 191
		jr nz, moveright
		inc l
moveright	ld bc,32766 				;read keyboard space to b
		in a,(c)
		cp 191
		jr nz, dontmove
		dec l
dontmove	di
		ld (32900),hl 					;store car posn
		ld de, 32 						;new carposn
		xor a  							;set carry flag to 0
		sbc hl,de
		ld a,(hl) 						;crash?
		or a
		jr z,gameover
		ld a,8  						;print car
		ld (hl),a
		ld hl,23263						;scroll road
		ld de,23295
		ld bc,736
		lddr
		pop bc  						;retrieve score
		pop hl  						;retrieve road posn
		push hl  						;save road posn
		ld a,56  						;delete old road
		ld (hl),a
		inc hl
		ld (hl),a
		ld de,9
		add hl,de
		ld (hl),a
		inc hl
		ld (hl),a

	;random road left or right
		ld hl,14000 					;source of random bytes in ROM
		ld d,0
		ld e,c
		add hl, de
		ld a,(hl)
		pop hl  						;retrieve road posn
		dec hl  						;move road posn 1 left
		and 1
		jr z, roadleft
		inc hl
		inc hl
roadleft	ld a,l  					;check left
		cp 255
		jr nz, checkright
		inc hl
		inc hl
checkright	ld a,l
		cp 21
		jr nz, newroadposn
		dec hl
		dec hl
newroadposn	push hl  					;save road posn
		xor a  							;print new road
		ld (hl),a
		inc hl
		ld (hl),a
		ld de,9
		add hl,de
		ld (hl),a
		inc hl
		ld (hl),a
		inc bc  						;add 1 to score
		push bc  						;save score

	;wait routine
		ld bc,$1fff 					;max waiting time
wait 	dec bc
		ld a,b
		or c
		jr nz, wait
		jp principalloop
gameover	pop bc  					;retrieve score
		pop hl  						;empty stack
		ei
		ret 							;game and tutorial written by Jon Kingsman ('bigjon', 'bj'). electronic mail gmail.com - atsign - jon.kingsman (reversed)

code_end:
