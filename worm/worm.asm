;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; worm.asm
;; zx spectrum game to escape from a wormhole in space
;;
;; assemble using:
;;    pasmo --tapbas -d worm.asm worm.tap worm.map > worm.lis
;; then open the worm.tap in any emulator
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

org 24000

;;
;; main game loop
;;

START
    call INIT_SCREEN            ; setup screen
    ld hl,SPRITE_DATA           ; sprite address.
    xor a                       ; a:=0 initial position in circle list
    ld (POS),a                  ; store in variable
    ld a,$0A
    ld (PULSE_RADIUS),a         ; variable for growing circle
    push hl
    call SPRITE
    pop hl
GAME_LOOP
    call KEY_SCAN
    inc d
    jr nz,CYCLE                 ; Don't move if more than one key pressed.
    ld a,e                      ; a: = key code of key pressed (ff if none).
    cp $1a                      ; check for o key
    jr z,HANDLE_RIGHT
    cp $22                      ; check for p key
    jr z,HANDLE_LEFT
    jr nz,CYCLE                 ; no match? loop again.
HANDLE_LEFT
    push af
    call UNDISPLAY_SPRITE       ; undisplay current position
    pop af
    ld a,(POS)                  ; find current position in list
    cp 0                        ; already 0 position?
    jp nz,DEC_POS               ; no, decrease position
    ld a,(MAX_POS)              ; yes, wrap to max list pos
    ld (POS),a                  ; store new value
    jr AFTER_DEC_POS
DEC_POS
    dec a                       ; pos is > 0 so decrement
    ld (POS),a                  ; store new value
AFTER_DEC_POS
    jr DISPLAY_SPRITE
HANDLE_RIGHT
    push af
    call UNDISPLAY_SPRITE       ; undisplay current position
    pop af
    ld a,(MAX_POS)
    ld d,a
    ld a,(POS)
    cp d                        ; already MAX_POS position?
    jp nz,INC_POS               ; no, increase position
    ld a,0                      ; yes, wrap to list start pos
    ld (POS),a
    jr AFTER_INC_POS
INC_POS
    inc a                       ; pos is < MAX so increment
    ld (POS),a                  ; store new value
AFTER_INC_POS
DISPLAY_SPRITE
    ld hl,SPRITE_DATA
    ;halt
    call SPRITE
CYCLE
    call TUNNEL
    call PULSE_WAIT
    ;call FRAME_WAIT
    jp GAME_LOOP

;;
;; subroutines
;;

PULSE_WAIT
    ld hl,PULSE_TIME
    ld a,(FRAMES)               ; current timer setting.
    sub (hl)
    cp 50                       ; 1 second
    jr nc,PULSE_READY
    ret
PULSE_READY
    ld a,(PULSE_RADIUS)         ; current size
    add a,$10                   ; make bigger
    ld (PULSE_RADIUS),a         ; store
    xor a                       ; a := 0
    ld a,(FRAMES)
    ld (PULSE_TIME),a           ; reset pulse wait
    ret

FRAME_WAIT
    ld hl,PREV_TIME             ; previous time setting
    ld a,(FRAMES)               ; current timer setting.
    sub (hl)                    ; difference between the two.
    cp 2                        ; have two frames elapsed yet?
    jr nc,FRAME_DONE            ; yes, no more delay.
    jp FRAME_WAIT
FRAME_DONE
    ld a,(FRAMES)               ; current timer.
    ld (hl),a                   ; store in PRETIM
    ret

UNDISPLAY_SPRITE
    ld hl,SPRITE_DATA
    halt
    call SPRITE                 ; remove old
    ret

TUNNEL
    ld a,128                    ; x centre
    ld (PULSE_X),a
    ld a,96                     ; y centre
    ld (PULSE_Y),a
    ld a,(PULSE_RADIUS)
    call CIRCLE                 ; circle at x,y with radius
    ret

INIT_SCREEN
    ld a,0
    ld (DF_SZ),a                ; set lower part of screen to 0 size so we get 24 lines

    ld a,$2                     ; set printing to
    call $1601                  ; top part of screen

    ld a,71                     ; white ink (7) on black paper (0), bright (64).
    ld (ATTR_P),a               ; set our screen colours.
    xor a                       ; a := 0
    call SET_BORDER             ; permanent border ROM
    call CLEAR_SCREEN           ; clear screen ROM

    ;call DRAW_BACKGROUND        ; fill screen with dots to test xor sprite
    ret

DRAW_BACKGROUND
    ld a,AT_CONTROL              ; set print position:
    rst $10                      ; AT:
    ld a,$0
    rst $10                      ; 0,
    rst $10                      ; 0
    ld de,704d                   ; 22d*34d = characters in background
DRAW_BACKGROUND_CHAR
    ld a,'.'
    rst $10
    dec de
    ld a,d
    or e
    jp nz,DRAW_BACKGROUND_CHAR
    ret

;;
;; variables
;;

MAX_POS         defb 15          ; 0, 1, 2, 3
POS             defb 0           ; index into circle pos for sprite
DISPX           defb 0           ; tmp for SPRITE routine
TMP0            defw 0           ; tmp for SPRITE routine
SPRTMP          defw 0           ; tmp for SPRITE routine
PULSE_RADIUS    defb 0           ; growing circle in tunnel
PULSE_X         defb 0           ;
PULSE_Y         defb 0           ; coordinates
PREV_TIME       defb 0           ; last recorded frame count
PULSE_TIME      defb 0           ; last frame we did a pulse

;;
;; supporting source files
;;

INCLUDE defs.asm
INCLUDE circle.asm
INCLUDE sprite.asm

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

end 24000
