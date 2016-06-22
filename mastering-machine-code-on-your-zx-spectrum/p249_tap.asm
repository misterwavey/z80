 ; ================================================================
;	Example source for target 'tap'
;	Tape file for ZX Spectrum and Jupiter ACE
;	Copyright  (c)	Günter Woigk 1994 - 2015
;					mailto:kio@little-bat.de
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
graphic_shift_3	equ $8C

;system vars
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
;		(note: $5B00 is the printer buffer)
;		(note: system variables at $5C00 were initialized by Basic)
; ---------------------------------------------------

#data VARIABLES, printer_buffer, $100

; vars
BALL_POS 	defs 2
BALL_INIT 	defs 2
SPEED 		defs 2
DIRECTION 	defs 2
LIVES 		defs 2
BAT_POS 	defs 2

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
		defb    "mcoder    "	  		; the block name, 10 bytes long
		defw    code_end-code_start		; length of data block which follows
		defw    code_start				; default location for the data
		defw    0       				; unused


#code CODE_DATA, code_start,*,dataflag

; Z80 assembler code and data

START
	XOR A					;A: = zero, CARRY reset.
	PUSH AF 				;Stack NO CARRY.

	LD (TVFLAG),A 			;Sent PRINT to upper part of screen.
	LD (DF_SZ),A 			;Extend upper part of screen to 24d lines.
	LD BC,$02DF
	LD A, enter
	RST $10 				;Print from start of second line.
	LD HL,UDG_LOCAL_DATA    ;point to local UDG data
    LD (UDGS),HL   			;tell system to use ours
SET_UP
	LD A,graphic_A
	RST $10 				;PRINT “ball” symbol.
	DEC BC
	LD A,B
	OR C
	JR NZ,SET_UP 			;Fill whole screen.

	LD HL,attr_start+$21 	;Point HL to first white square.
	LD (HL),$3F 			;Set colours white on white.
	LD DE,attr_start+$22 	;Point to second white square.
	LD BC,$02DE
	LDIR 					;Whiten all required squares.

	LD HL,attr_start+$81 	;Point HL to first brick.
	LD A,$09
	CALL BRICKS 			;Print row of blue and red bricks.

	LD A,$2D
	CALL BRICKS 			;Print row of cyan and yellow bricks.

	LD A,$1B
	CALL BRICKS 			;Print row of magenta and green bricks.

	LD A,$09
	CALL BRICKS 			;Print row of blue and red bricks.

	XOR A
	LD HL,attr_start 		;Point to top left-hand corner of wall.
	LD (HL),A 				;Black this square.
	LD DE,attr_start+$01	;Point to second square of wall.
	LD BC,$001F
	PUSH BC
	LDIR 					;Blacken remainder of top wall.

	POP DE 					;DE: = 001F
	LD B,$17
SIDES
	INC HL 					;Point to next square in left wall
	LD (HL),A 				;Blacken this square.
	ADD HL,DE 				;Point to next square in right wall.
	LD (HL),A 				;Blacken this square.
	DJNZ SIDES

	LD HL,SCORE+$07 		;Point to SCORE space reserved.
	LD B,$04
SCORE_LOOP
	LD (HL), space 			;Blank out any existing data.
	INC HL
	DJNZ SCORE_LOOP
	LD (HL),zero 			;Reset score to zero.
	LD HL,SCORE 			;Point HL to label SCORE.  !!! was LD L, 11 !!!
	LD B,$0C
PRINT_SCORE
	LD A,(HL)
	INC HL
	RST $10 				;Print the score onto the screen.
	DJNZ PRINT_SCORE

	LD HL,attr_start+$0260
	LD (BALL_INIT),HL 		;Store the ball's starting position.
	LD HL,$0B00 			;Store the initial speed of play.
	LD (SPEED),HL
	LD A,$02
	LD (DF_SZ),A 			;Restore system variable to avoid crashing.
	LD A,$09
	LD (LIVES),A 			;Store number of lives plus one.

	;start the game loop for the current life
RESTART_BALL
	LD A,(LIVES)
	DEC A
	JR NZ,LIVES_OK
	POP AF					;Balance the stack.
	RET 					;Return to BASIC if no lives left.

LIVES_OK
	LD (LIVES),A

	; update ball starting position
	LD HL,(BALL_INIT)
	INC HL 					;Change the starting position of the ball.
	LD (BALL_INIT),HL
	LD (BALL_POS),HL 		;Set current ball position.
	LD (HL),$39 			;Print the ball (blue on white).
	LD HL,$FFE1
	LD (DIRECTION),HL 		;Set initial direction to up-right.

	;update bat starting position
	LD A,$03
	LD (BAT_POS),A 			;Set centre of bat to column three.
	LD A,$01
	CALL AT_15_A 			;Print AT 15h,1;.
	LD (IY+$55),$07 		;Set colours to white on black.
	LD B,$05
BAT_LOOP
	LD A,graphic_shift_3
	RST $10					;Print bat symbol.
	DJNZ BAT_LOOP
	LD (IY+$55),$3F 		;Set colours to white on white.

	;erase next 25 cells
	LD B,$19
ERASE
	LD A, graphic_A
	RST $10					;Erase former bat symbol.
	DJNZ ERASE

	; delay before ball starts moving
	LD B,$04
RDL_1
	LD HL,$0000
RDL_2
	DEC HL
	LD A,H
	OR L
	JR NZ,RDL_2 			;Set a very long delay,
	DJNZ RDL_1 				;for the player to recover for the next ball.

	;main loop for each ball/life
LOOP
	LD HL,(SPEED)
DELAY
	DEC HL 					;This is a short delay loop which controls
	LD A,H 					;the speed of the game.
	OR L
	JR NZ,DELAY

	;do we need to move the ball this iteration?
	POP AF 					;Retrieve the carry flag.
	CCF 					;Complement it.
	PUSH AF 				;And re-store it.
	JP C,MOVE_BAT 			;The ball is only moved every other time round the loop,
							;so that the bat moves twice as fast as the ball.
	;move ball
	LD HL,(BALL_POS) 		;HL points to ball.
	LD (HL),$3F 			;Erase former ball symbol.
	LD DE,(DIRECTION)
NEW_POS
	ADD HL,DE 				;Compute new ball position.
	LD (BALL_POS), HL 		;Store this position.
	LD A,(HL)
	CP $07 					;Is a bat at this new position?
	JR NZ,SQ_FREE 			;Jump if not.
	LD A,E
	NEG
	LD E,A
	LD A,D
	CPL 					;Negate DE (the direction of travel).
	LD D,A
	LD (DIRECTION),DE 		;Store new direction.
	JR NEW_POS

SQ_FREE
	LD (HL),$39 			;Print ball (blue on white) at new position.
	CP $3F 					;Was a brick formerly at that square?
	JR Z,V_CH 				;Jump if not.
	AND $07 				;A: = score attained for hitting brick.
	LD HL,(SPEED)
	LD BC,$FFF0 			;BC: = – 10.
	ADD HL,BC
	LD (SPEED),HL 			;Increase speed of game.
	LD HL,SCORE+$0B 		;HL points to last digit of score.
	ADD A,(HL) 				;A: = new units digit.

CARRY
	CP $3A 					;Is new digit greater than nine?
	JR C,INC 				;Jump if not.
	SUB $0A 				;Find proper digit.
	LD (HL),A 				;Store this digit.
	DEC HL 					;Point to next left digit.
	LD A,(HL) 				;A: = next digit.
	OR $10 					;Change from “space” to“zero” if needed.
	INC A 					;Add the carry from the last digit.
	JR CARRY
INC
	LD (HL),A 				;Store digit.
	LD HL,SCORE 			;Point HL to the label SCORE.
	LD B,$0C
PRINT_SCORE_2
	LD A,(HL)
	INC HL
	RST $10 				;Print score.
	DJNZ PRINT_SCORE_2
	JR VERT

V_CH
	PUSH DE 				;Stack direction.
	LD A,D
	AND $C0
	OR $20
	LD E,A 					;DE: = vertical component of direction.
	LD HL,(BALL_POS) 		;HL: = current ball position.
	ADD HL,DE
	LD A,(HL) 				;A: = attribute of computed square.
	AND $F8 				;Disregard ink colour.
	POP DE 					;DE: = true direction.
	JR NZ,H_CH 				;Jump unless paper
VERT
	LD A,E  				;colour is black (ie bat or wall).
	XOR $C0
	LD E,A
	LD A,D
	CPL
	LD D,A 					;Reverse vertical
	LD (DIRECTION),DE 		;component of direction.

H_CH
	PUSH DE 				;Stack direction.
	RR E
	RR E
	SBC A,A 				;A: = FF (leftward) or 00 (rightward).
	LD D,A
	OR $01 					;A: = FF (leftward) or 01 (rightward).
	LD E,A 					;DE: = horizontal component of direction.
	LD HL,(BALL_POS) 		;HL: = current position of ball.
	ADD HL,DE
	LD A,(HL) 				;A: = contents of computed square.
	AND $F8 				;Disregard ink colour.
	POP DE 					;DE: = true direction.
	JR NZ,L_CH 				;Jump unless wall or bat at square.
	LD A,E
	XOR $3E
	LD E,A 					;Reverse horizontal
	LD (DIRECTION),DE 		;component of direction.
L_CH
	LD HL,(BALL_POS) 		;HL: = current ball position.
	LD DE,attr_start+$02E0
	AND A
	SBC HL,DE
	JR C,MOVE_BAT
	ADD HL,DE 				;If ball is on bottom row
	LD (HL),$3F 			;of screen then erase it,
	JP RESTART_BALL 		;and restart game with new ball.

	; move bat
MOVE_BAT
	CALL KEY_SCAN
	INC D
	JR NZ,CYCLE 			;Don't move bat if more than one key pressed.
	LD A,E 					;A: = key code of key pressed (FF if none).
	CP $11					;Check for J key
	JR Z,RIGHT
	CP $09 					;Check for M key
	JR NZ,CYCLE
LEFT
	LD D,$01
	JR M_BAT_1
RIGHT
	LD D,$FF
M_BAT_1
	LD A,(BAT_POS) 			;A: = column number of bat centre.
	SUB D
	SUB D
	SUB D 					;A: = column number of next square in line.
	PUSH AF
	ADD A,$A0
	LD L,A
	LD H,$5A 				;HL: = address of this square in attributes.
	LD A,(HL)
	CP $3F 					;Is this square empty?
	JR Z,M_BAT_2 			;Jump if so.
	POP AF 					;Balance the stack.
	JR CYCLE  				;Bat doesn't move.
M_BAT_2
	POP AF
	CALL AT_15_A 			;Move print position to this square.
	LD (IY+$55),$07 		;Set colours to white on black.
	PUSH AF
	LD A,graphic_shift_3
	RST $10 				; Extend bat in required direction.
	POP AF
	ADD A,D
	ADD A,D
	LD (BAT_POS),A 			;Store new bat position.
	ADD A,D
	ADD A,D
	ADD A,D
	CALL AT_15_A 			;Move print position to trailing end of bat.
	LD (IY+$55),$3F 		;Set colours to white on white.
	LD A,graphic_A
	RST $10 				;Erase trailing edge of bat.
CYCLE
	JP LOOP 				;Same for next time round

BRICKS
	LD B,$08
BR_LOOP
	LD (HL),A
	INC HL
	LD (HL),A 				;Print brick in first colour.
	INC HL
	ADD A,$09 				;Change colour.
	LD (HL),A
	INC HL
	LD (HL),A 				;Print brick in second colour.
	INC HL
	SUB $09 				;Revert to original colour.
	DJNZ BR_LOOP
	RET

SCORE
	DEFM at_control,0,$10 	;Data for PRINT SCORE routine later on.
	DEFM ink_control,colour_white
	DEFM paper_control,colour_black
	DEFS $05 				;Space in which to store current score.

; AT_0_0
; 	PUSH HL
; 	LD HL,4000
; 	LD (DF_CC),HL
; 	LD HL,1821
; 	LD (S_POSN),HL
; 	POP HL
; 	RET

AT_15_A
	PUSH AF
	PUSH AF
	LD A,at_control
	RST $10
	LD A,$15 				;First AT co-ordinate.
	RST $10
	POP AF 					;Second AT co-ordinate.
	RST $10
	POP AF
	RET

UDG_LOCAL_DATA
	defb 0,60,126,126,126,126,60,0

code_end:
