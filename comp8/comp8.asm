org 24000

ATTRS_START                 equ $5800
BRIGHT_WHITE_INK_ON_BLACK   equ 127
FRAMES                      equ $5C78       ; frame counter 23672d

;;
;; execution begins
;;
init:
    ;; set border
    ld   a, 7                   ; black colour
    out  ($fe), a               ; permanent border

    ;; clear all attrs to black
    ld   hl, ATTRS_START        ; $5800
    ld   bc, 32*24              ; 32 columns x 24 rows
clear_attr:
    ld   (hl), 0                ; black is black ink 1x0 + black paper 8x0 = 0
    inc  hl
    dec  bc                     ; 16 bit decrement ...
    ld   a, b                   ; check if b
    or   c                      ; and c both zero
    jr   nz, clear_attr         ; loop to set all attrs to 0

    call setup_map_and_draw

;    call rotate_90_right

    ;;
    ;; main loop - no exit
    ;;
game_loop:
    ld   hl, LAST_FRAME_TIME    ; time of last check
    ld   a, (FRAMES)            ; current timer setting.
    sub  (hl)
    cp   15                     ; 1/2 second elapsed?
    jr   nc, check_input         ; window exceeded?
    jr   skip_input

check_input:
    ld   a, $1a                 ; 'o' 26d
    call ktest
    ; call nc, rotate_left        ; pressed?
    call nc, rotate_left_new    ; pressed?

    ld   a, $22                 ; 'p' 34d
    call ktest
    call nc, rotate_right_new   ; pressed?

    ld   a, (FRAMES)            ; current timer setting.
    ld   (LAST_FRAME_TIME), a   ; store current frames

skip_input:
    ;; move ball
    ld   hl, LAST_BALL_FRAME
    ld   a, (FRAMES)
    sub  (hl)
    cp   10
    jr   nc, handle_ball
    jr   skip_ball

handle_ball:
    ld   hl, BALLYX
    ld   d, (hl)                ; put yx coords in de
    inc  hl
    ld   e, (hl)
    ex   de, hl                 ; put yx coords in hl
    inc  l                      ; look 1 row below y
    call atadd                  ; is it clear?
    and  7                      ; only want bits pertaining to ink.
    cp   7                      ; is it white (7)?
    jr   nz, move_ball          ; no? lower ball
    jr   skip_ball              ; yes? don't move ball

move_ball:
    dec  l                      ; undo the '1 row below' move
    dec  l                      ; look 1 row above to erase old pos
    call erase_ball
    inc  l                      ; back to current
    call draw_ball
    inc  l                      ; move down 1 row
    ld   d, l                   ; swap h/l for saving
    ld   e, h
    ld   (BALLYX), de           ; save new position

    ld   a, (FRAMES)            ; current timer setting.
    ld   (LAST_BALL_FRAME), a   ; store current frames

skip_ball:
    ;; check for goal

    halt

    jr   game_loop

;;
;; erase ball
;;
erase_ball:
    call atadd
    ld   a, 0
    ld   (de), a
    ret

;;
;; draw ball
;;
draw_ball:
    call atadd
    ld   a, 20
    ld   (de), a
    ret

;;
;; get attribute address in de (attribute in a) given
;; character position (x,y) in hl
;;

atadd:
    push hl
    ld   a, l                   ; vertical coordinate.
    rrca                        ; multiply by 32.
    rrca                        ; Shifting right with carry 3 times is
    rrca                        ; quicker than shifting left 5 times.
    ld   e, a
    and  3
    add  a, 88                  ; 88x256=address of attributes.
    ld   d, a
    ld   a, e
    and  224
    ld   e, a
    ld   a, h                   ; horizontal position.
    add  a, e
    ld   e, a                   ; de=address of attributes.
    ld   a, (de)                ; return with attribute in accumulator.
    pop  hl
    ret

    ;;
    ;; DRAW SCREEN routine
    ;;

    ; loop over rows in map 1..16
    ;   loop over bytes in row 1..2
    ;     loop over rotatesize 1..8
    ;       rotate byte
    ;       draw bit
    ;       inc attr
    ;   inc attr row

draw_screen:
    ld   hl, ATTRS_START
    ld   de, MAP                ; start of screen map bytes
    ld   b, 16                  ; rows of bytes in map

loop_over_rows_in_map:
    push bc
    push hl
    ld   b, 2                   ; 2 bytes per row

loop_over_bytes_in_row:
    push bc
    ld   b, 8                   ; rotatesize: bits to process per byte
    ld   a, (de)                ; take byte from map
    ld   c, a                   ; we'll use c to rotate byte

loop_over_rotatesize:
    rl   c                      ; rotate bit 7 into carry
    jp   nc, set_blank_cell     ; got a carry?
    ld   a, BRIGHT_WHITE_INK_ON_BLACK ; yep
    jp   draw_cell

set_blank_cell:
    ld   a, 0                   ; didn't have carry, draw black cell
draw_cell:
    ld   (hl), a                ; colour attr using A
    inc  hl                     ; next attr
    djnz loop_over_rotatesize   ; dec rotate count and rotate until done

    inc  de                     ; next byte in map
    pop  bc
    djnz loop_over_bytes_in_row

    pop  hl
    ld   bc, 32                 ; next attr row
    add  hl, bc
    pop  bc
    djnz loop_over_rows_in_map

    ret

    ;;
    ;; INIT_MAP routine
    ;; accumulator needs to hold 0,1,2,3 for 0,90,180,270 version of map
    ;;
setup_map:
    cp  3
    jr  z, handle_270
    cp  2
    jr  z, handle_180
    cp  1
    jr  z, handle_90
handle_0:                       ; fallthrough
    ld  hl, MAP_0
    jr  populate_map
handle_270:
    ld  hl, MAP_270
    jr  populate_map
handle_180:
    ld  hl, MAP_180
    jr  populate_map
handle_90:
    ld  hl, MAP_90
    jr  populate_map
populate_map:
    ld  de, MAP
    ld  bc, 32
    ldir
    ret

rotate_right_new:
    call rotate_90_right
    call draw_map_y
    ret

rotate_left_new:
    call rotate_90_left
    call draw_map_y
    ret

draw_map_y:
    ld   c, 0                   ; i
loop_over_c:
    ld   b, 0                   ; j
    loop_over_b:
        ld   de, MAP_Y
        call GetElement             ; a := MAP_Y[c,b]
        push af
        ld   h, b
        ld   l, c
        call atadd                  ; de := address of ATTRS[b,c]
        pop af
        ld   (de), a
        inc  b
        ld   a, 16
        cp   b
        jr   nz, loop_over_b
    inc  c
    ld   a, 16
    cp   c
    jr   nz, loop_over_c
    ret

    ;;
    ;; rotate map_template into map area
    ;;
rotate_right:
    ld   a, (ROTATION_COUNT)
    inc  a
    cp   4
    jr   nz, done_setup_degrees_r
    ld   a, 0                   ; was 4, loop over to 0
done_setup_degrees_r:
    call setup_map_and_draw
    ret

rotate_left:
    ld   a, (ROTATION_COUNT)
    dec  a
    cp   -1
    jr   nz, done_setup_degrees_l
    ld   a, 3                   ; was 0, loop over to 3
done_setup_degrees_l:
    call setup_map_and_draw
    ret

setup_map_and_draw:
    ld   (ROTATION_COUNT), a
    call setup_map
    call draw_screen
    ret

; Credit for this must go to Stephen Jones, a programmer who used to
; write excellent articles for the Spectrum Discovery Club many years ago.
;
; To use his routine, load the accumulator with the number of the key
; (see below) you wish to test, call ktest, then check the carry flag.
; If it's set the key is not being pressed, if there's no carry then the
; key is being pressed.  If that's too confusing and seems like the wrong
; way round, put a ccf instruction just before the ret.

; Mr. Jones' keyboard test routine.

ktest:
    ld   c, a                   ; key to test in c.
    and  7                      ; mask bits d0-d2 for row.
    inc  a                      ; in range 1-8.
    ld   b, a                   ; place in b.
    srl  c                      ; divide c by 8,
    srl  c                      ; to find position within row.
    srl  c
    ld   a, 5                   ; only 5 keys per row.
    sub  c                      ; subtract position.
    ld   c, a                   ; put in c.
    ld   a, $FE                 ; high byte of port to read.
ktest0:
    rrca                        ; rotate into position.
    djnz ktest0                 ; repeat until we've found relevant row.
    in    a, ($FE)              ; read port (a=high, 254=low).
ktest1:
    rra                         ; rotate bit out of result.
    dec   c                     ; loop counter.
    jp    nz, ktest1            ; repeat until bit for position in carry.
    ret

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

BALLYX
    defb 3,3

LAST_FRAME_TIME                 ; last frame counter value
    defb 0

LAST_BALL_FRAME                 ; last frame counter value
    defb 255

INPUT_ALLOWED
    defb 1

ROTATION_COUNT
    defb 0                      ; 0=0 degrees, 1=90 degrees, 2=180, 3=270

    ;; rotated versions of the screen map for 0, 90, 180, 270 degrees

MAP_0
    defb 11111111b,11111111b
    defb 11000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 11011111b,11100011b

    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000111b
    defb 10000000b,00000111b
    defb 11111111b,11111111b

MAP_90
    defb 11111111b,11111111b
    defb 10000000b,10000011b
    defb 10000000b,00000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000011b,11100001b

    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 11100000b,00000001b
    defb 11100000b,10000001b
    defb 11111111b,11111111b

MAP_180
    defb 11111111b,11111111b
    defb 11100000b,00000001b
    defb 11100000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 11000011b,11111011b

    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,00000011b
    defb 11111111b,11111111b

MAP_270
    defb 11111111b,11111111b
    defb 10000000b,10000111b
    defb 10000000b,00000111b
    defb 10000000b,00000001b
    defb 10000000b,00000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000011b,11100001b

    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,10000001b
    defb 10000000b,00000001b
    defb 11000000b,10000001b
    defb 11111111b,11111111b

    ;; AREA THAT EACH TEMPLATE IS COPIED INTO
MAP
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0

    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0
    defb 0,0

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
; 9 5900 .. 591f
;10 5920 .. 593f
;11 5940 .. 595f
;12 5960 .. 597f
;13 5980 .. 599f
;14 59a0 .. 59bf
;15 59c0 .. 59df
;16 59e0 .. 59ff
;17 5a00 .. 5a1f
;18 5a20 .. 5a3f
;19 5a40 .. 5a5f
;20 5a60 .. 5a7f
;21 5a80 .. 5a9f
;22 5aa0 .. 5abf
;23 5ac0 .. 5adf
;24 5ae0 .. 5aff

include rotate.asm

sizeofALL: equ $-init

    end 24000
