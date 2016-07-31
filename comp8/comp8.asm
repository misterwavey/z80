org 24000

INIT
    ;; set border
    ld   a, 0                    ; black colour
    out  ($fe), a                ; permanent border

    ;; clear all attrs to black

    ld   hl, ATTRS_START         ; $5800
    ld   bc, 32*24               ; 32 columns x 24 rows
CLEAR_ATTR
    ld   (hl), 0                 ; black is black ink 1x0 + black paper 8x0 = 0
    inc  hl
    dec  bc                     ; 16 bit decrement ...
    ld   a, b                    ; check if b
    or   c                      ; and c both zero
    jr   nz, CLEAR_ATTR          ; loop to set all attrs to 0

DRAW_SCREEN
    ld   hl, ATTRS_START
    ld   de, MAP                ; start of screen map bytes
    ld   b, 32                  ; bytes to process for whole map

LOOP_OVER_BYTES_IN_MAP
    push bc
    ld   b, 8                   ; bits to process per byte
    ld   a, (de)                ; take byte from map
    ld   c, a                   ; use c to rotate byte
    push bc

LOOP_OVER_ROTATESIZE
    rl   c                      ; rotate it
    jp   nc, SET_BLANK_CELL     ; got a carry?
    ld   a, BRIGHT_WHITE_INK_ON_BLACK ; yep
    jp   DRAW_CELL

SET_BLANK_CELL
    ld   a, 0                   ; didn't have carry, draw black cell
DRAW_CELL
    ld   (hl), a                ; colour attr using A
    inc  hl                     ; next attr
    djnz LOOP_OVER_ROTATESIZE   ; dec rotate count and rotate until done

    pop  bc
    ld   a, (FLIPFLOP)
    cp   0
    jp   z, NO_ATTR_JUMP

    ;; ATTR_JUMP
    push de
    ld   e, 16
    ld   d, 0
    add  hl, de                  ; next attr row
    pop  de
    ld   a, 0
    ld   (FLIPFLOP), a
    jp   AFTER_ATTR_JUMP

NO_ATTR_JUMP
    ld   a, 1
    ld   (FLIPFLOP), a

AFTER_ATTR_JUMP
    inc  de
    pop  bc
    djnz LOOP_OVER_BYTES_IN_MAP

GAME_LOOP
    ;; check input
    ld    a, $1a
    call  KTEST
    call  nc, ROTATELEFT
    call CLEAR

    ld    a, $22
    call  KTEST
    call  nc, ROTATERIGHT
    call CLEAR

    ;; move ball

    ;; check for goal

        ;JR GAME_LOOP
    ret

ROTATELEFT
    ; ld   a,22             ; AT code.
    ; rst  16
    ; ld   a,1              ; player vertical coord.
    ; rst  16              ; set vertical position of player.
    ; ld   a,1                ; player's horizontal position.
    ; rst  16              ; set the horizontal coord.
    ; ld   a,69             ; cyan ink (5) on black paper (0),
    ;                     ; bright (64).
    ; ld   (23695),a        ; set our temporary screen colours.
    ; ld   a,'o'            ; ASCII code for User Defined Graphic 'A'.
    ; rst  16              ; draw player.
    ret

ROTATERIGHT
    ; ld   a,22             ; AT code.
    ; rst  16
    ; ld   a,1              ; player vertical coord.
    ; rst  16              ; set vertical position of player.
    ; ld   a,1                ; player's horizontal position.
    ; rst  16              ; set the horizontal coord.
    ; ld   a,69             ; cyan ink (5) on black paper (0),
    ;                     ; bright (64).
    ; ld   (23695),a        ; set our temporary screen colours.
    ; ld   a,'p'            ; ASCII code for User Defined Graphic 'A'.
    ; rst  16              ; draw player.
    ret

CLEAR
    ld   a, 22             ; AT code.
    rst  16
    ld   a, 1              ; player vertical coord.
    rst  16              ; set vertical position of player.
    ld   a, 1                ; player's horizontal position.
    rst  16              ; set the horizontal coord.
    ld   a, 69             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld  (23695), a        ; set our temporary screen colours.
    ld  a, ' '            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

; loop over bytes in map 0..31
;   loop over rotatesize 1..8
;     rotate byte
;     draw bit
;     inc attr
;   if odd add 16 to attr

; Credit for this must go to Stephen Jones, a programmer who used to
; write excellent articles for the Spectrum Discovery Club many years ago.
;
; To use his routine, load the accumulator with the number of the key
; you wish to test, call ktest, then check the carry flag.  If it's set
; the key is not being pressed, if there's no carry then the key is
; being pressed.  If that's too confusing and seems like the wrong way
; round, put a ccf instruction just before the ret.

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

; Mr. Jones' keyboard test routine.

KTEST
    ld   c,a                    ; key to test in c.
    and  7                      ; mask bits d0-d2 for row.
    inc  a                      ; in range 1-8.
    ld   b,a                    ; place in b.
    srl  c                      ; divide c by 8,
    srl  c                      ; to find position within row.
    srl  c
    ld   a,5                    ; only 5 keys per row.
    sub  c                      ; subtract position.
    ld   c,a                    ; put in c.
    ld   a,254                  ; high byte of port to read.
KTEST0
    rrca                        ; rotate into position.
    djnz KTEST0                 ; repeat until we've found relevant row.
    in a,(254)                  ; read port (a=high, 254=low).
KTEST1
    rra                         ; rotate bit out of result.
    dec c                       ; loop counter.
    jp nz,KTEST1                ; repeat until bit for position in carry.
    ret

BALLX
    defb 0

BALLY
    defb 0

FLIPFLOP
    defb 0

MAP
    defb 11111111b,11111111b
    defb 11000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 11000011b,11100011b

    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000111b
    defb 10000000b,00000111b
    defb 11111111b,11111111b

    ; defb  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ; defb 17, 1,                                       14
    ; defb 17,                                          15
    ; defb 17,                                          15
    ; defb 17,                                          15
    ; defb 17,                   7,                      8
    ; defb 17,                   7,                      8
    ; defb 17,1,             4,1,1,1,1,               5, 1
    ; defb 17,                   7,                      8
    ; defb 17,                   7,                      8
    ; defb 17,                                          15
    ; defb 17,                                          15
    ; defb 17,                                          15
    ; defb 17,                                    13, 1, 1
    ; defb 17,                                    13, 1, 1
    ; defb 17, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    ; defb 255

    ; defb 0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10,  11,  12,  13,  14,  15
    ; defb 32, 33,                                                          47
    ; defb 64,                                                              79
    ; defb 96,                                                             111
    ; defb 128,                                                            143
    ; defb 160,                         168,                               175
    ; defb 192,                         200,                               207
    ; defb 224,225,             229,230,231,232,233,                   238,239
    ; defb 256,                         263,                               271
    ; defb 288,                         295,                               303
    ; defb 320,                                                            335
    ; defb 352,                                                            367
    ; defb 384,                                                            399
    ; defb 416,                                                    429,430,431
    ; defb 448,                                                    461,462,463
    ; defb 480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496

ATTRS_START equ $5800
BRIGHT_WHITE_INK_ON_BLACK equ 127

end 24000

;  1 2 3 4 5 6 7 8 9 0 A B C D E F
;1 x x x x x x x x x x x x x x x x
;2 x x                           x
;3 x                             x
;4 x                             x
;5 x                             x
;6 x             x               x
;7 x             x               x
;8 x x       x x x x x         x x
;9 x             x               x
;A x             x               x
;B x                             x
;C x                             x
;D x                         x x x
;E x                         x x x
;F x x x x x x x x x x x x x x x x


; ATTR DISPLAY FILE
; 32 WIDE X 24 HIGH = 768 cells
;
; 1 5800 .. 581F
; 2 5820 .. 583F
; 3 5840 .. 585F
; 4 5860 .. 587F
; 5 5880 .. 589F
; 6 58a0 .. 58bF
; 7 58c0 .. 58dF
; 8 58e0 .. 58fF

; 9 5900
;10 5920
;11 2940
;12 5960
;13 5980
;14 59a0
;15 59c0
;16 59e0
;17 5a00
;18 5a20
;19 5a40
;20 5a60
;21 5a80
;22 5aa0
;23 5ac0
;24 5ae0
