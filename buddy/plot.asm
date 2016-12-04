org 38000

        jp init

PIXELS_START    equ     $4000   ; 16384d
ATTRS_START     equ     $5800   ; 22528d
TIMER           equ     23672d  ; used for random seed

BORDER:
        defb    0
SEED:
        defw    0               ; current seed value
LAST_STAR_X:
        defb    0

init:
        ld   a, 0               ; black colour
        out  ($fe), a           ; permanent border
        ;; clear all attrs to black

        ld   hl, ATTRS_START    ; $5800
        ld   bc, 32*24          ; 32 columns x 24 rows
clear_attr:
        ld   (hl), 7            ; white on black is white ink 1x7 + black paper 8x0 = 0
        inc  hl
        dec  bc
        ld   a, b               ; 16 bit decrement ...
        or   c                  ; ... test. z set when b & c both 0
        jr   nz, clear_attr     ; loop to set all attrs to 0

wait_input:
        ld   a, $1a             ; key 'o' 26d
        call ktest
        jr nc, done_wait_input
        jr wait_input

done_wait_input:
        ld a, (TIMER)           ; current timer.
        ld (SEED), a            ; set first byte of random seed.

        ; call show_all_bytes
        call scroll_screen_draw_star
        ret

scroll_screen_draw_star:

        ; scroll buffer up one pixel row
        ld bc, 6144d - 32d     ; include all rows except first one
        ld hl, BUFFER + 32d    ; src:  start at 2nd row
        ld de, BUFFER          ; dest: start at 1st row
        ldir

        ; ld bc, $ffff
        ; call delay
;
        ; blank bottom pixel row
        ld bc, 32d                  ; count whole row
        ld hl, BUFFER + 6144d - 32d ; start of bottom pixel row
        ld (hl), 0                  ; blank pixel
        ld de, BUFFER + 6144d - 31d ; start of bottom row + 1
        ldir

gen_random_star:
        ; draw random star on bottom row
        call random             ; get random byte 0-255d
        ld b, a                 ; store random as x pos. bc is now xy
        ld a, (LAST_STAR_X)
        cp b                    ; big enough difference from last time?
        jr z, gen_random_star ; < 10 different from last star position
got_star:
        ld hl, LAST_STAR_X              ; save original random value as LAST_STAR_X
        ld (hl), b

        ;tmp fix star y
        ld c, 191d                  ; y (0-191d)

        call plot_buffer          ; plot point at xy

        call paste_buffer

        jr scroll_screen_draw_star
        ret

;; sub
;; bc = xy
;; plot xy on buffer
plot_buffer:
        push de
        push hl

        ld a, b                 ; a holds x
        ld e, c                 ; e holds y

        ld c, 08d               ; find which 0-31 char x fits into
        call Divide             ; b:=a/c b:=x/8 b:= char a:=remainder
        ld c, a                 ; pixel offset in c

        push bc                 ; store x charpos, pixel offset
        ld d, 0                 ; de holds y
        ld bc, 32d              ; calc 32 bytes * y
        call Mul16
        ld de, BUFFER           ; start of buffer
        add hl, de              ; plus result of 191*y (already in hl)
        pop bc                  ; x charpos in b, pixel offset in c
        push bc
        ld c, b                 ; x charpos
        ld b, 0                 ; bc := x charpos
        add hl, bc              ; hl = pixel byte address
        pop bc                  ; x charpos in b, pixel offset in c

        ld b, c                 ; b = pixel offset
        inc b
        ld a, 1               ; set pixel
plot_pix:
        rrca                    ; rotate to pixel offset count
        djnz plot_pix           ; done?
        xor (hl)                ; flip pixel
        ld (hl), a              ; set byte at address

        pop hl
        pop de
        ret

;; sub
;Inputs:
;    A=divisor
;    C=dividend
;
;Outputs:
;    B=A/C
;    A=A%C
Divide:
        ld b, 0
DivLoop:
        sub c
        jr c, DivEnd
        inc b
        jr DivLoop
DivEnd:
        add a, c
        ret

;; sub
;; DEHL=BC*DE
Mul16:                           ; This routine performs the operation DEHL=BC*DE
        ld hl,0
        ld a,16
Mul16Loop:
        add hl,hl
        rl e
        rl d
        jp nc,NoMul16
        add hl,bc
        jp nc,NoMul16
        inc de                         ; This instruction (with the jump) is like an "ADC DE,0"
NoMul16:
        dec a
        jp nz,Mul16Loop
        ret

; Simple pseudo-random number generator.
; Steps a pointer through the ROM (held in seed), returning
; the contents of the byte at that location.
; a <- random byte
; trashes hl, a

random:
        ld hl,(SEED)            ; Pointer
        ld a, h
        and 31                  ; keep it within first 8k of ROM.
        ld h, a
        ld a, (hl)              ; Get "random" number from location.
        xor l
        inc hl                  ; Increment pointer.
        ld (SEED), hl
        ret

ktest:
        ld   c, a               ; key to test in c.
        and  7                  ; mask bits d0-d2 for row.
        inc  a                  ; in range 1-8.
        ld   b, a               ; place in b.
        srl  c                  ; divide c by 8,
        srl  c                  ; to find position within row.
        srl  c
        ld   a, 5               ; only 5 keys per row.
        sub  c                  ; subtract position.
        ld   c, a               ; put in c.
        ld   a, $FE             ; high byte of port to read.
ktest0:
        rrca                    ; rotate into position.
        djnz ktest0             ; repeat until we've found relevant row.
        in   a, ($FE)           ; read port (a=high, 254=low).
ktest1:
        rra                     ; rotate bit out of result.
        dec  c                  ; loop counter.
        jp   nz, ktest1         ; repeat until bit for position in carry.
        ret

; sub
; rearrange displayfile into BUFFER
populate_buffer:
        ld hl, PIXELS_START
        ld de, BUFFER
        ld c, $c0
l0:
        push hl
        ld b, $20
l1:
        ld a, (hl)
        ld (de), a
        inc hl
        inc de
        djnz l1

        pop hl
        inc h
        ld a, h
        and $07
        jr nz, l2

        ld a, l
        add a, $20
        ld l, a
        ccf
        sbc a, a
        and $f8
        add a, h

        ld h, a
l2:
        dec c
        jr nz, l0
        ret

; sub
; restore BUFFER to D/File
paste_buffer:
        push hl
        push de
        push bc

        ld hl, PIXELS_START
        ld de, BUFFER
        ld c, $c0
r0:
        push hl
        ld b, $20
r1:
        ld a, (de)
        ld (hl), a
        inc hl
        inc de
        djnz r1

        pop hl
        inc h
        ld a, h
        and $07
        jr nz, r2

        ld a, l
        add a, $20
        ld l, a
        ccf
        sbc a, a
        and $f8
        add a, h

        ld h, a
r2:
        dec c
        jr nz, r0
        pop bc
        pop de
        pop hl
        ret

; sub
; delay while counting down from bc to 0
delay:
        dec bc
        ld a, b
        or c
        jr nz, delay
        ret

show_all_bytes:
        ld hl, BUFFER
        ld bc, 6144d
show_l1:
        ld (hl), $ff
        call paste_buffer
    ;     ld   a, BORDER               ; black colour
    ;     out  ($fe), a           ; permanent border
    ;     inc a
    ;     cp 8
    ;     jr nz, skip_reset_border
    ;     ld a, 0
    ; skip_reset_border:
    ;     ld (BORDER), a

        ld (hl), 0

        inc hl
        dec bc
        ld a, b
        or c
        jr nz, show_l1

; loop forever to observe pixel test
za:
        jr za
;; end loop

;;
;; sub
;; find pixel address
;; b = y coord, c = x coord
;; hl <- address
;; a <- pixel number
;;
pixadd:
        ld a, b
        rra
        scf
        rra
        rra
        and 58h
        ld h, a
        ld a, b
        and 7
        add a, h
        ld h, a
        ld a, c
        rrca
        rrca
        rrca
        and 1fh
        ld l, a
        ld a, b
        and 38h
        add a, a
        add a, a
        or l
        ld l, a
        ld a, c
        and 7
        ret

;;
;; sub
;;
plot:
        push bc                 ; save xy
        call pixadd             ; convert xy to screen address byte in hl
        ld b, a                 ; store pixel offset count
        inc b                   ; increase by 1
        ld a, 1                 ; set pixel
pix:
        rrca                    ; rotate to pixel offset count
        djnz pix                ; done?
        xor (hl)                ; merge a with current pixel byte
        ld (hl), a              ; update byte at address
        pop bc                  ; restore xy
        ret



BUFFER:
        defs 6144d          ; offscreen  buffer 6144 bytes big

end 38000

; start:
;         ld bc, 0900h
        ; ld d, 200
; loop:
        ; push bc
        ; ld bc, 0x01
        ; halt
        ; ; call delay
        ; ; pop bc
        ;
        ; call plot

        ; dec c
        ; call plot
        ; inc c

        ; dec d
        ; inc c
        ; ld a, 0
        ; cp d
        ; jp nz, loop

        ; jr start
