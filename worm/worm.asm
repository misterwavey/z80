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

    ld a,1
    ld (PULSE_COUNT),a          ; initialise pulse count to 1

    xor a                       ; a:=0 initial position in circle list
    ld (POS),a                  ; store in variable
    push hl
    call SPRITE
    pop hl

    call TUNNEL_DRAW
    call HIDE_PULSE1
    call HIDE_PULSE2
    call HIDE_PULSE3
    call HIDE_PULSE4
GAME_LOOP
    call KEY_SCAN
    inc d
    jr nz,CYCLE                 ; Don't move if more than one key pressed.
    ld a,e                      ; a: = key code of key pressed (ff if none).
    cp $1a                      ; check for o key
    jr z,HANDLE_RIGHT
    cp $22                      ; check for p key
    jr z,HANDLE_LEFT
    jr CYCLE                    ; no match? end gameloop

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
    ld d,a                      ; d := maxpos for comparison
    ld a,(POS)                  ; a := current position
    cp d                        ; current already at MAX_POS position?
    jp nz,INC_POS               ; no, increase position
    ld a,0                      ; yes, wrap to list start pos
    ld (POS),a
    jr AFTER_INC_POS
INC_POS
    inc a                       ; pos is < MAX so increment
    ld (POS),a                  ; store new value
AFTER_INC_POS                   ; fallthrough to DISPLAY_SPRITE

DISPLAY_SPRITE
    ld hl,SPRITE_DATA
    ;halt
    call SPRITE

CYCLE
    call PULSE_TIMING
    ;call FRAME_WAIT
    jp GAME_LOOP

;;
;; subroutines
;;

UNDISPLAY_SPRITE
    ld hl,SPRITE_DATA
    halt
    call SPRITE                 ; remove old
    ret

PULSE_TIMING
    ld hl,PULSE_TIME            ; time of last check
    ld a,(FRAMES)               ; current timer setting.
    sub (hl)
    cp 15                       ; 1 second
    jr nc,PULSE_READY           ; window exceeded?
    ret                         ; no, end sub
PULSE_READY                     ; yes
    ld a,(PULSE_COUNT)          ; which pulse needs showing?
    push af
    cp 1
    jp z,HANDLE_PULSE_1
    cp 2
    jp z,HANDLE_PULSE_2
    cp 3
    jp z,HANDLE_PULSE_3
    cp 4
    jp z,HANDLE_PULSE_4
    jp PULSE_DONE
HANDLE_PULSE_1
    call SHOW_PULSE1
    jp PULSE_DONE
HANDLE_PULSE_2
    call SHOW_PULSE2
    jp PULSE_DONE
HANDLE_PULSE_3
    call SHOW_PULSE3
    jp PULSE_DONE
HANDLE_PULSE_4
    call SHOW_PULSE4            ; then fallthrough
PULSE_DONE
    pop af
    inc a
    cp 5                        ; pulse needs resetting?
    jp nz,PULSE_DONE_2
    ld a,1                      ; yes
PULSE_DONE_2                    ; no
    ld (PULSE_COUNT),a          ; store
    ld a,(FRAMES)
    ld (PULSE_TIME),a           ; reset pulse wait
    ret

;;
;; hl must point to attr array [y,x,colour,[rpt],0]
;;
SET_ATTR_BYTES
    ; call DEBUGXN
    CALL ATADD                  ; after, de := attr address
    inc hl                      ; point at byte 2 (y)
    inc hl                      ; point at byte 3 (colour)
    ld a,(hl)                   ; a := byte 3 (colour)
    ld (de),a                   ; set colour of attr address
    inc hl                      ; point at next byte
    ld a,(hl)                   ; a := byte 1 of next attr def or 0
    cp 255                      ; is it our end marker?
    ret z                       ; yes end
    jp SET_ATTR_BYTES           ; if no repeat until zero found

HIDE_PULSE1
    ; call DEBUGX
    ld hl,PULSE_1_ATTRS_OFF
    call SET_ATTR_BYTES
    ret

HIDE_PULSE2
    ; call DEBUGX
    ld hl,PULSE_2_ATTRS_OFF
    call SET_ATTR_BYTES
    ret

HIDE_PULSE3
    ld hl,PULSE_3_ATTRS_OFF
    call SET_ATTR_BYTES
    ret

HIDE_PULSE4
    ld hl,PULSE_4_ATTRS_OFF
    call SET_ATTR_BYTES
    ret

SHOW_PULSE1
    call DEBUG1
    ; TODO SHOW 1
    ld hl,PULSE_1_ATTRS_ON
    call SET_ATTR_BYTES
    call HIDE_PULSE4
    ret

SHOW_PULSE2
    call DEBUG2
    ld hl,PULSE_2_ATTRS_ON
    call SET_ATTR_BYTES
    call HIDE_PULSE1
    ; TODO SHOW 2
    ret

SHOW_PULSE3
    call DEBUG3
    ld hl,PULSE_3_ATTRS_ON
    call SET_ATTR_BYTES
    call HIDE_PULSE2
    ; TODO SHOW 3
    ret

SHOW_PULSE4
    call DEBUG4
    ld hl,PULSE_4_ATTRS_ON
    call SET_ATTR_BYTES
    call HIDE_PULSE3
    ; TODO SHOW 4
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


;; TODO attributes to black for old pulses
TUNNEL_DRAW
    ld a,127                    ; x centre
    ld (PULSE_X),a
    ld a,95                   ; y centre
    ld (PULSE_Y),a
    ld a,6
    ld (PULSE_RADIUS),a
    call CIRCLE                 ; circle at x,y with radius
    ld a,14
    ld (PULSE_RADIUS),a
    call CIRCLE                 ; circle at x,y with radius
    ld a,23
    ld (PULSE_RADIUS),a
    call CIRCLE                 ; circle at x,y with radius
    ld a,35
    ld (PULSE_RADIUS),a
    call CIRCLE                 ; circle at x,y with radius
    ; ld a,
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
    ; ld a,55
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
    ; ld a,63
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
    ; ld a,71
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
    ; ld a,79
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
    ; ld a,87
    ; ld (PULSE_RADIUS),a
    ; call CIRCLE                 ; circle at x,y with radius
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

PULSE_1_ATTRS_OFF
    defb 11,15,0,11,16,0
    defb 12,15,0,12,16,0
    defb 255

PULSE_1_ATTRS_ON
    defb 11,15,7,11,16,7
    defb 12,15,7,12,16,7
    defb 255

PULSE_2_ATTRS_OFF
    defb 10,14,0,10,15,0,10,16,0,10,17,0
    defb 11,14,0,11,17,0
    defb 12,14,0,12,17,0
    defb 13,14,0,13,15,0,13,16,0,13,17,0
    defb 255

PULSE_2_ATTRS_ON
    defb 10,14,7,10,15,7,10,16,7,10,17,7
    defb 11,14,7,11,17,7
    defb 12,14,7,12,17,7
    defb 13,14,7,13,15,7,13,16,7,13,17,7
    defb 255

PULSE_3_ATTRS_OFF
    defb 09,13,0,09,14,0,09,15,0,09,16,0,09,17,0,09,18,0
    defb 10,13,0,10,18,0
    defb 11,13,0,11,18,0
    defb 12,13,0,12,18,0
    defb 13,13,0,13,18,0
    defb 14,13,0,14,14,0,14,15,0,14,16,0,14,17,0,14,18,0
    defb 255

PULSE_3_ATTRS_ON
    defb 09,13,7,09,14,7,09,15,7,09,16,7,09,17,7,09,18,7
    defb 10,13,7,10,18,7
    defb 11,13,7,11,18,7
    defb 12,13,7,12,18,7
    defb 13,13,7,13,18,7
    defb 14,13,7,14,14,7,14,15,7,14,16,7,14,17,7,14,18,7
    defb 255

PULSE_4_ATTRS_OFF
    defb 07,12,0,07,13,0,07,14,0,07,15,0,07,16,0,07,17,0,07,18,0
    defb 08,12,0,8,13,0,08,17,0,08,18,0,08,19,0
    defb 09,11,0,09,12,0,09,19,0
    defb 10,11,0,10,19,0,10,20,0
    defb 11,11,0,11,20,0
    defb 12,11,0,12,20,0
    defb 13,11,0,13,12,0,13,19,0,13,20,0
    defb 14,12,0,14,19,0
    defb 15,12,0,15,13,0,15,14,0,15,17,0,15,18,0,15,19,0
    defb 16,13,0,16,14,0,16,15,0,16,16,0,16,17,0,16,18,0,16,19,0
    defb 255

PULSE_4_ATTRS_ON
    defb 07,12,7,07,13,7,07,14,7,07,15,7,07,16,7,07,17,7,07,18,0
    defb 08,12,7,8,13,7,08,17,7,08,18,7,08,19,7
    defb 09,11,7,09,12,7,09,19,7
    defb 10,11,7,10,19,7,10,20,7
    defb 11,11,7,11,20,7
    defb 12,11,7,12,20,7
    defb 13,11,7,13,12,7,13,19,7,13,20,7
    defb 14,12,7,14,19,7
    defb 15,12,7,15,13,7,15,14,7,15,17,7,15,18,7,15,19,7
    defb 16,13,7,16,14,7,16,15,7,16,16,7,16,17,7,16,18,7,16,19,7
    defb 255

;;
;; variables
;;

MAX_POS         defb 15          ; 0, 1, 2, 3
POS             defb 0           ; index into circle pos for sprite
DISPX           defw 0           ; tmp for SPRITE routine
TMP0            defw 0           ; tmp for SPRITE routine
SPRTMP          defw 0           ; tmp for SPRITE routine
PULSE1_HIDDEN   defb 1           ; growing circle in tunnel
PULSE2_HIDDEN   defb 1           ; growing circle in tunnel
PULSE3_HIDDEN   defb 1           ; growing circle in tunnel
PULSE4_HIDDEN   defb 1           ; growing circle in tunnel
PULSE_COUNT     defb 0
PULSE_X         defb 0           ;
PULSE_Y         defb 0           ; coordinates
PULSE_RADIUS    defb 0
PREV_TIME       defb 0           ; last recorded frame count
PULSE_TIME      defb 0           ; last frame we did a pulse

;;
;; supporting source files
;;

INCLUDE defs.asm
INCLUDE circle.asm
INCLUDE sprite.asm
INCLUDE screen.asm
INCLUDE debug.asm

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
