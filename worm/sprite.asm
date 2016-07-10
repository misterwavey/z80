
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
