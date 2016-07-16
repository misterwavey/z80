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

; bright white is white ink 1x7 + white paper 8x7 + bright 64x1 = 127
; black is black ink 1x0 + black paper 8x0 = 0

    ld a,0                      ; 0 is the code for black.
    out (254),a                 ; set border colour
    ld bc,704                   ; prepare to write attrs for 32 chars x 22 rows
    ld de,ATTRS_START           ; start of attrs displayfile
    push af                     ; protect a
FILL_BLACK
    pop af                      ; restore a
    ld (de),a                   ; write to attr
    push af                     ; protect a
    inc de                      ; next attr
    dec bc                      ; dec counter
    ld a,b
    or c                        ; counter at 0?
    jp nz,FILL_BLACK            ; no continue

PRINT_W
    ld hl,(COMP_TEXT)           ; "W" = $57 = 87d
    ld h,0                      ; zero high byte
    add hl,hl                   ; char x 2
    add hl,hl                   ; char x 4
    add hl,hl                   ; char x 8 ($57 * 8 = $2B8)
    ld de,CHARS_START
    add hl,de                   ; $3C00 + $2B8 = "W" in font rom
    ld c,8                      ; process this many bytes (rows) per character
    ld b,0                      ; zero high byte of bc
    ex de,hl                    ; de := char row byte
    ld hl,ATTRS_START           ; hl := attr displayfile
DRAW_CHAR_ROW
    ld a,(de)                   ; char row byte N
    bit 7,a
    jp z,DRAW_NO_BIT7
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT7
    inc hl
    ld a,(de)                   ; char row byte N
    bit 6,a
    jp z,DRAW_NO_BIT6
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT6
    inc hl
    ld a,(de)                   ; char row byte N
    bit 5,a
    jp z,DRAW_NO_BIT5
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT5
    inc hl
    ld a,(de)                   ; char row byte N
    bit 4,a
    jp z,DRAW_NO_BIT4
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT4
    inc hl
    ld a,(de)                   ; char row byte N
    bit 3,a
    jp z,DRAW_NO_BIT3
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT3
    inc hl
    ld a,(de)                   ; char row byte N
    bit 2,a
    jp z,DRAW_NO_BIT2
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT2
    inc hl
    ld a,(de)                   ; char row byte N
    bit 1,a
    jp z,DRAW_NO_BIT1
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT1
    inc hl
    ld a,(de)                   ; char row byte N
    bit 0,a
    jp z,DRAW_NO_BIT0
    ld a,127
    ld (hl),a                   ; draw attr
DRAW_NO_BIT0
    inc hl
    push bc
    ld bc,24
    add hl,bc                   ; move attr displayfile on to next row
    inc de                      ; next byte row for font character
    pop bc
    dec c                       ; done all byte rows for character?
    jp nz,DRAW_CHAR_ROW

    ret

COMP_TEXT
    defb "Welcome to the Z80 Assembly Programming "
    defb "On The ZX Spectrum Compo #7 ScrollText......"

end 24000

; 1 5800
; 2 5820
; 3 5840
; 4 5860
; 5 5880
; 6 58a0
; 7 58c0
; 8 58e0
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
