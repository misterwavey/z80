; ;;compo #7
;
;  Final size is the size of the code plus any initialised variables,
;  you cannot assume RAM will be 0 though.
; DETAILS: You must scroll the given scroll text across the screen using
;  attributes rather than pixels.
; 1) You may READ from the ROM Font located at $3d00 but no other ROM access
;  is allowed. You cannot Read or Write to any other location below $4000.
; 2) The scrolltext is included in the size of the entry, but you are free
;  to encode it how you like, it must read correctly when run.
; 3) The scrolltext must loop constantly
; 4) You must include a halt (or similar) for timing. You are free to assume
;  interrupts will be enabled.
; 5) The text must be in bright white on black (with a black border)
; 6) It must be on the top 8 attribute lines
; 7) All entries MUST BE EMAILED TO compo@zxasm.net. DO NOT POST source
;  code to the group (Or other websites) before the end of the compo else
;  your entry will be disqualified.
; 8) Your program can be anywhere you like in RAM
; SCROLLTEXT:
; Welcome to the Z80 Assembly Programming On The ZX
; Spectrum Compo #7 ScrollText......
;
; DEADLINE: 9am GMT July 18th.

org 24000

CHARS_START equ $3C00
ATTRS_START equ $5800

; ROM char = 3C00 + 8 * character code (A=65) = $3C00 + 8x65 = $3E08

    ld a,0                      ; 0 is the code for black.
    out (254),a                 ; set border colour
    ld bc,704
    ld de,ATTRS_START
    push af
FILL_BLACK
    pop af
    ld (de),a
    push af
    inc de
    dec bc
    ld a,b
    or c
    jp nz,FILL_BLACK

PRINT_W
    ld hl,(COMP_TEXT)           ; "W" = $57 = 87d
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl                   ; $57 * 8
    ld de,CHARS_START
    add hl,de                   ; 3C00 + 8 x character
    ld c,8                      ; process this many bytes per character
    push bc
    ld de,ATTRS_START           ; write to attr displayfile here
    ex de,hl
DRAW_CHAR_ROW
    ld a,(de)                   ; byte N of character

    bit 7,a
    jp z,DRAW_NO_BIT7
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT7
    inc hl
    bit 6,a
    jp z,DRAW_NO_BIT6
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT6
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT5
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT5
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT4
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT4
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT3
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT3
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT2
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT2
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT1
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT1
    inc hl
    bit 5,a
    jp z,DRAW_NO_BIT0
    ld a,56
    ld (hl),a                   ; draw attr
DRAW_NO_BIT0
    ld bc,32
    add hl,bc
    inc de
    pop bc
    dec c
    jp nz,DRAW_CHAR_ROW

    ret

COMP_TEXT
    defb "Welcome to the Z80 Assembly Programming "
    defb "On The ZX Spectrum Compo #7 ScrollText......"

end 24000
