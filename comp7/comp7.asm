;comp7v3

org 24000

ROM_CHARS_START equ $3C00
ATTRS_START equ $5800
BRIGHT_WHITE_INK_ON_BLACK equ 127

; ROM char = 3C00 + 8 * character code (A=65) = $3C00 + 8x65 = $3E08

; bright white is white ink 1x7 + white paper 8x7 + bright 64x1 = 127d
; black is black ink 1x0 + black paper 8x0 = 0

; set border
; clear attrs
; loop over chars in text
;   find rom char
;   loop over rotatesize 1..8 times
;       loop over rom char bytes 1..8 times
;           rotate-left rom char byte rotatesize times
;           draw carry at attr
;       scroll attrs

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

MAIN
    ld   hl,COMP_TEXT           ; start of text to scroll

LOOP_OVER_CHARS_IN_TEXT
    ld   a,(hl)                 ; at end of text?
    cp   0
    jr   z,MAIN                 ; yes, restart

    push hl                     ; store text char position

    ;; find ROM char using comp text value
    ld   l,a
    ld   h,0                    ; put char val in hl
    add  hl,hl                  ; x2. Add reqs HL when adding another reg pair
    add  hl,hl                  ; char value x 4
    add  hl,hl                  ; char value x 8
    ld   de,ROM_CHARS_START
    add  hl,de                  ; ROM char = 3C00 + 8 * character code
    ex   de,hl                  ; de := ROM char position
    push de

    ld   a,1
    ld   (ROTATESIZE),a         ; setup rotate counter

LOOP_OVER_ROTATESIZE
    ld   b,8                    ; rom char byte count
    ld   hl,ATTRS_START-1       ; allow for loop to add 32d each time when displaying
    xor  a                      ; clear carry for later rotations

LOOP_OVER_BYTES_IN_ROM_CHAR
    ld   a,(ROTATESIZE)
    ld   c,a                    ; local rotate counter
    ld   a,(de)                 ; examine current rom char byte
    push af                     ;

ROTATE_C_TIMES
    pop  af                     ; restore rotated a
    rl   a                      ; rotate rom char byte left
    push af
    dec  c                      ; reduce local rotate counter
    ld   a,c
    cp   0
    jp   nz,ROTATE_C_TIMES
    pop  af
    jr   nc,NO_ROW_CELL         ; did rotation result in carry being set?
    ld   a,BRIGHT_WHITE_INK_ON_BLACK    ; yes so set cell ...
    jp   DRAW_ROW_CELL
NO_ROW_CELL
    ld   a,0                    ; no so draw empty cell...
DRAW_ROW_CELL
    ;; calc next row of attr
    push bc
    ld   bc,32                  ; add 32 to attrs ..
    add  hl,bc                  ; .. for next row
    pop  bc

    ld   (hl),a

    inc  de
    dec  b
    ld   a,b
    cp   0
    jp   nz,LOOP_OVER_BYTES_IN_ROM_CHAR

    halt
    ;; scroll attrs
    ld   de,ATTRS_START
    ld   hl,ATTRS_START+1
    ld   bc,8*32                ; top 8 ATTR rows
    ldir                        ; shift attrs left

    ld   a,(ROTATESIZE)         ; bump rotatesize
    inc  a
    ld   (ROTATESIZE),a
    pop  de
    push de
    cp   9                     ; unless we've done all 8
    jp   nz,LOOP_OVER_ROTATESIZE

    pop  de
    pop  hl
    inc  hl                     ; next text char
    jp   LOOP_OVER_CHARS_IN_TEXT

ROTATESIZE
    defb 0
COMP_TEXT
    defb "Welcome to the Z80 Assembly Programming "
    defb "On The ZX Spectrum Compo #7 ScrollText.....",0

end 24000

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
