org 24000

INIT
    ;; set border
    ld   a,0                    ; black colour
    out  ($fe),a                ; permanent border

    ;; clear all attrs to black

    ld   hl,ATTRS_START         ; $5800
    ld   bc,32*24               ; 32 columns x 24 rows
CLEAR_ATTR
    ld   (hl),0                 ; black is black ink 1x0 + black paper 8x0 = 0
    inc  hl
    dec  bc
    ld   a,b                    ; 16 bit decrement ...
    or   c                      ; ... test. z set when b & c both 0
    jr   nz,CLEAR_ATTR          ; loop to set all attrs to 0

DRAW_SCREEN
    ld   hl,ATTRS_START
    ld   de,MAP
SCREEN_LOOP
    ld   a,(de)
    cp   255
    jp   z,DONE_SCREEN
    ld   c,a
    ld   b,0
    add  hl,bc
    ld   a,BRIGHT_WHITE_INK_ON_BLACK
    ld   (hl),a
    inc  de
    jp   SCREEN_LOOP

DONE_SCREEN
    ret

MAP

    defb  0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    defb 17, 1,                                       14
    defb 17,                                          15
    defb 17,                                          15
    defb 17,                                          15
    defb 17,                   7,                      8
    defb 17,                   7,                      8
    defb 17,1,             4,1,1,1,1,               5, 1
    defb 17,                   7,                      8
    defb 17,                   7,                      8
    defb 17,                                          15
    defb 17,                                          15
    defb 17,                                          15
    defb 17,                                    13, 1, 1
    defb 17,                                    13, 1, 1
    defb 17, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1
    defb 255

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
    ; defb 480,481,482,483,484,485,486,487,488,489,490,491,492,493,494,495,496                                                            255

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
