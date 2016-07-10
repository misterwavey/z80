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

START
        call INIT_SCREEN                ; setup screen
        ld hl,SPRITE_DATA               ; sprite address.
        ld a,0                          ; initial position in circle list
        ld (POS),a                      ; store in variable
        ld a,$0A
        ld (PULSE_RADIUS), a            ; variable for growing circle
        push hl
        call SPRITE
        pop hl
GAME_LOOP
        call KEY_SCAN
        inc d
        jr nz,CYCLE                     ; Don't move if more than one key pressed.
        ld a,e                          ; a: = key code of key pressed (ff if none).
        cp $1a                          ; check for o key
        jr z,HANDLE_RIGHT
        cp $22                          ; check for p key
        jr z,HANDLE_LEFT
        jr nz,CYCLE                     ; no match? loop again.
HANDLE_LEFT
        push af
        call UNDISPLAY_SPRITE           ; undisplay current position
        pop af
        ld a,(POS)                      ; find current position in list
        cp 0                            ; already 0 position?
        jp nz,DEC_POS                   ; no, decrease position
        ld a,(MAX_POS)                  ; yes, wrap to max list pos
        ld (POS),a                      ; store new value
        jr AFTER_DEC_POS
DEC_POS
        dec a                           ; pos is > 0 so decrement
        ld (POS),a                      ; store new value
AFTER_DEC_POS
        jr DISPLAY_SPRITE

HANDLE_RIGHT
        push af
        call UNDISPLAY_SPRITE           ; undisplay current position
        pop af
        ld a,(MAX_POS)
        ld d,a
        ld a,(POS)
        cp d                            ; already MAX_POS position?
        jp nz,INC_POS                   ; no, increase position
        ld a,0                          ; yes, wrap to list start pos
        ld (POS),a
        jr AFTER_INC_POS
INC_POS
        inc a                           ; pos is < MAX so increment
        ld (POS),a                      ; store new value
AFTER_INC_POS
DISPLAY_SPRITE
        ld hl,SPRITE_DATA
        ;halt
        call SPRITE
CYCLE
        call TUNNEL
        jp GAME_LOOP

        ;;
        ;; subroutines
        ;;

UNDISPLAY_SPRITE
        ld hl,SPRITE_DATA
        halt
        call SPRITE                     ; remove old
        ret

TUNNEL
        ld a,128
        ld (PULSE_X),a
        ld a,96
        ld (PULSE_Y),a
        ld a,(PULSE_RADIUS)
    buc:
        ld (PULSE_RADIUS),a
        call CIRCLE
        ; inc a
        ; cp 90
        ; jr nz,buc
        ret

INIT_SCREEN
        ;; setup screen handling
        ld a,0
        ld (DF_SZ),a                    ; set lower part of screen to 0 size so we get 24 lines

        ld a,$2                         ; set printing to
        call $1601                      ; top part of screen

        ld a,71                         ; white ink (7) on black paper (0), bright (64).
        ld (ATTR_P),a                   ; set our screen colours.
        xor a                           ; a := 0
        call SET_BORDER                 ; permanent border ROM
        call CLEAR_SCREEN               ; clear screen ROM

        ;call DRAW_BACKGROUND
        ret

DRAW_BACKGROUND
        ld a,AT_CONTROL                 ; set print position:
        rst $10                         ; AT:
        ld a,$0
        rst $10                         ; 0,
        rst $10                         ; 0
        ld de,704d                      ; 22d*34d = characters in background
DRAW_BACKGROUND_CHAR
        ld a,'.'
        rst $10
        dec de
        ld a,d
        or e
        jp nz,DRAW_BACKGROUND_CHAR
        ret

SPRIT7
        xor 7                           ; complement last 3 bits.
        inc a                           ; add one for luck!
SPRIT3
        rl d                            ; rotate left...
        rl c                            ; ...into middle byte...
        rl e                            ; ...and finally into left character cell.
        dec a                           ; count shifts we've done.
        jr nz,SPRIT3                    ; return until all shifts complete.

; Line of sprite image is now in e + c + d, we need it in form c + d + e.

        ld a,e                          ; left edge of image is currently in e.
        ld e,d                          ; put right edge there instead.
        ld d,c                          ; middle bit goes in d.
        ld c,a                          ; and the left edge back into c.
        jr SPRIT0                       ; we've done the switch so transfer to screen.

SPRITE
        push hl
        ld a,(POS)                      ; lookup index into list of coords
        ld d,a                          ; store index in d as a counter
        xor a                           ; a:=0
        ld hl,CIRCLE_POS                ; point bc at start of coords
POS_LOOP
        cp d                            ; is counter zero?
        jr z,DONE_POS                   ; yes
        inc hl                          ; no, move bc one 1 byte (y)
        inc hl                          ; move bc on 1 more byte (x)
        dec d                           ; decrement counter
        jp POS_LOOP                     ; check if done
DONE_POS
        ld a,(hl)                       ; read y from low byte of hl
        ld c,a                          ; copy into c
        inc hl                          ; move hl on one byte
        ld a,(hl)                       ; read x from low byte of hl
        ld b,a                          ; copy into b
        pop hl                          ; hl := sprite image addr
        ld (DISPX),bc                   ; store coords in dispx for now.
        call SCADD                      ; calculate screen address.
        ld a,16                         ; height of sprite in pixels.
SPRIT1
        ex af,af'                       ; store loop counter.
        push de                         ; store screen address.
        ld c,(hl)                       ; first sprite graphic.
        inc hl                          ; increment poiinter to sprite data.
        ld d,(hl)                       ; next bit of sprite image.
        inc hl                          ; point to next row of sprite data.
        ld (SPRTMP),hl                  ; store it for later.
        ld e,0                          ; blank right byte for now.
        ld a,b                          ; b holds y position.
        and 7                           ; how are we straddling character cells?
        jr z,SPRIT0                     ; we're not straddling them, don't bother shifting.
        cp 5                            ; 5 or more right shifts needed?
        jr nc,SPRIT7                    ; yes, shift from left as it's quicker.
        and a                           ; oops, carry flag is set so clear it.
SPRIT2
        rr c                            ; rotate left byte right...
        rr d                            ; ...through middle byte...
        rr e                            ; ...into right byte.
        dec a                           ; one less shift to do.
        jr nz,SPRIT2                    ; return until all shifts complete.
SPRIT0
        pop hl                          ; pop screen address from stack.
        ld a,(hl)                       ; what's there already.
        xor c                           ; merge in image data.
        ld (hl),a                       ; place onto screen.
        inc l                           ; next character cell to right please.
        ld a,(hl)                       ; what's there already.
        xor d                           ; merge with middle bit of image.
        ld (hl),a                       ; put back onto screen.
        inc l                           ; next bit of screen area.
        ld a,(hl)                       ; what's already there.
        xor e                           ; right edge of sprite image data.
        ld (hl),a                       ; plonk it on screen.
        ld a,(DISPX)                    ; vertical coordinate.
        inc a                           ; next line down.
        ld (DISPX),a                    ; store new position.
        and 63                          ; are we moving to next third of screen?
        jr z,SPRIT4                     ; yes so find next segment.
        and 7                           ; moving into character cell below?
        jr z,SPRIT5                     ; yes, find next row.
        dec l                           ; left 2 bytes.
        dec l                           ; not straddling 256-byte boundary here.
        inc h                           ; next row of this character cell.
SPRIT6
        ex de,hl                        ; screen address in de.
        ld hl,(SPRTMP)                  ; restore graphic address.
        ex af,af'                       ; restore loop counter.
        dec a                           ; decrement it.
        jp nz,SPRIT1                    ; not reached bottom of sprite yet to repeat.
        ret                             ; job done.
SPRIT4
        ld de,30                        ; next segment is 30 bytes on.
        add hl,de                       ; add to screen address.
        jp SPRIT6                       ; repeat.
SPRIT5
        ld de,63774                     ; minus 1762.
        add hl,de                       ; subtract 1762 from physical screen address.
        jp SPRIT6                       ; rejoin loop.

; This routine returns a screen address for (c, b) in de.

SCADD
        ld a,c                          ; get vertical position.
        and 7                           ; line 0-7 within character square.
        add a,64                        ; 64 * 256 = 16384 (Start of screen display)
        ld d,a                          ; line * 256.
        ld a,c                          ; get vertical again.
        rrca                            ; multiply by 32.
        rrca
        rrca
        and 24                          ; high byte of segment displacement.
        add a,d                         ; add to existing screen high byte.
        ld d,a                          ; that's the high byte sorted.
        ld a,c                          ; 8 character squares per segment.
        rlca                            ; 8 pixels per cell, mulplied by 4 = 32.
        rlca                            ; cell x 32 gives position within segment.
        and 224                         ; make sure it's a multiple of 32.
        ld e,a                          ; vertical coordinate calculation done.
        ld a,b                          ; y coordinate.
        rrca                            ; only need to divide by 8.
        rrca
        rrca
        and 31                          ; squares 0 - 31 across screen.
        add a,e                         ; add to total so far.
        ld e,a                          ; hl = address of screen.
        ret

MAX_POS         defb 15                 ; 0, 1, 2, 3
POS             defb 0                  ; index into circle pos for sprite
DISPX           defb 0                  ; tmp for SPRITE routine
TMP0            defw 0                  ; tmp for SPRITE routine
SPRTMP          defw 0                  ; tmp for SPRITE routine
PULSE_RADIUS    defb 0                  ; growing circle in tunnel
PULSE_X         defb 0                  ;
PULSE_Y         defb 0                  ; coordinates

SPRITE_DATA
;; main sprite
    ; defb 7,    31,  63, 127, 127, 255, 255, 255 ; A top left
    ; defb 224, 248, 252, 254, 254, 255, 255, 255 ; B top right
    ; defb 255, 255, 243, 115, 127, 63,   31, 7   ; C bottom left
    ; defb 255, 255, 255, 254, 254, 252, 248, 224 ; D bottom right
;interleaved now: A0 B0 A1 B1 A2 B2 A3 B3 A4 B4 A5 B5 A6 B6 A7 B7
    defb 7,  224,31, 248, 63, 252,127,254,127,254,255,255,255,255,255,255
;interleaved now: C0 D0 C1 D1 C2 D2 C3 D3 C4 D4 C5 D5 C6 D6 C7 D7
    defb 255,255,255,255,243,255,115,254,127,254,63,252,31,248,7,224

; CIRCLE_POS  defb 120,24,  84,28,   68,40,   48,60,   40,96,  52,128, 68,148, 88,160
;             defb 120,164, 152,160, 180,144, 196,120, 200,96, 192,60, 180,44, 160,32  ; x,y coords in a list
; above reversed
CIRCLE_POS  defb 24,120,  28,84,   40,68,   60,48,   96,40,  128,52, 148,68, 160,88
            defb 164,120, 160,152, 144,180, 120,196, 96,200, 60,192, 44,180, 32,160  ; x,y coords in a list

INCLUDE circle.asm

PIXELS_START    EQU $4000               ; ZXSP SCREEN PIXELS
ATTR_START      EQU $5800               ; ZXSP SCREEN ATTRIBUTES
PRINTER_BUFFER  EQU $5B00               ; ZXSP PRINTER BUFFER
CODE_START      EQU 24000

; colours
COLOUR_BLACK    equ $0
COLOUR_WHITE    equ $07

; characters
ENTER           equ $0d
INK_CONTROL     equ $10
PAPER_CONTROL   equ $11
AT_CONTROL      equ $16
SPACE           equ $20
ASTERISK        equ $2A
PLUS            equ $2b
ZERO            equ $30
NINE            equ $39
GRAPHIC_A       equ $90
GRAPHIC_B       equ $91
GRAPHIC_C       equ $92
GRAPHIC_D       equ $93
GRAPHIC_SHIFT_3 equ $8C

; system vars
TVFLAG          equ $5c3c
DF_SZ           equ $5C6B
UDGS            equ $5C7B
DF_CC           equ $5c84
S_POSN          equ $5c88
ATTR_P          equ $5C8D ; permanent colours
ATTR_T          equ $5C8F
MEMBOT          equ $5C92

; rom routines
KEY_SCAN        equ $028e
KEY_TEST        equ $031e
KEY_CODE        equ $0333
CLEAR_SCREEN    equ $0DAF ; based on ATTR_P contents
SET_BORDER      equ $229B


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
end 24000
