; =======================================================================
;  pixel sprite code largely taken from
;  'how to write spectrum games' by jonathan caldwell
;
;  assemble using zasm 4 to create a .tap file:
;    zasm -u cauldwell-pixel.asm
;  load tap into emulator and it will run automatically
;
;  for other assemblers remove lines from 1 to up until around 110 and eg
;    pasmo --tapbas cauldwell-pixel.asm cauldwell-pixel.tap
;  load tap into emulator and from BASIC enter:
;    RANDOMIZE USR 24000
; =======================================================================

; fill byte is 0x00
; #code has an additional argument: the sync byte for the block.
; The assembler calculates and appends checksum byte to each segment.
; Note: If a segment is appended without an explicite address, then the sync byte and the checksum byte
; of the preceding segment are not counted when calculating the start address of this segment.

#target tap

; sync bytes:
HEADERFLAG:         equ 0
DATAFLAG:           equ $ff

; some Basic tokens:
tCLEAR              equ     $FD         ; token CLEAR
tLOAD               equ     $EF         ; token LOAD
tCODE               equ     $AF         ; token CODE
tPRINT              equ     $F5         ; token PRINT
tRANDOMIZE          equ     $F9         ; token RANDOMIZE
tUSR                equ     $C0         ; token USR
tCLS                equ     $FB         ; token CLS

; ---------------------------------------------------
;        ram-based, non-initialized variables
;        (note: 0x5B00 is the printer buffer)
;        (note: system variables at 0x5C00 were initialized by Basic)
; ---------------------------------------------------

#data VARIABLES, PRINTER_BUFFER, 0x100

; define some variables here

; ---------------------------------------------------
;        a Basic Loader:
; ---------------------------------------------------

#code PROG_HEADER,0,17,HEADERFLAG
        defb    0                       ; Indicates a Basic program
        defb    "sprite-p  "            ; the block name, 10 bytes long
        defw    VARIABLES_END-0         ; length of block = length of basic program plus variables
        defw    10                      ; line number for auto-start, 0x8000 if none
        defw    PROGRAM_END-0           ; length of the basic program without variables


#code PROG_DATA,0,*,DATAFLAG

        ; ZX Spectrum Basic tokens

; 10 CLEAR 23999
        defb    0,10                    ; line number
        defb    END10-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLEAR                  ; token CLEAR
        defm    "23999",$0e0000bf5d00   ; number 23999, ascii & internal format
END10:  defb    $0d                     ; line end marker

; 20 LOAD "" CODE 24000
        defb    0,20                    ; line number
        defb    END20-($+1)             ; line length
        defb    0                       ; statement number
        defb    tLOAD,'"','"',tCODE     ; token LOAD, 2 quotes, token CODE
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
END20:  defb    $0d                     ; line end marker

; 30 CLS
        defb    0,30                    ; line number
        defb    END30-($+1)             ; line length
        defb    0                       ; statement number
        defb    tCLS                    ; token RANDOMIZE, token USR
END30:  defb    $0d                     ; line end marker

; 40 PRINT USR 24000
        defb    0,40                    ; line number
        defb    END40-($+1)             ; line length
        defb    0                       ; statement number
        defb    tRANDOMIZE,tUSR         ; token RANDOMIZE, token USR
        defm    "24000",$0e0000c05d00   ; number 24000, ascii & internal format
END40:  defb    $0d                     ; line end marker

PROGRAM_END:

        ; ZX Spectrum Basic variables

VARIABLES_END:

; ---------------------------------------------------
;        a machine code block:
; ---------------------------------------------------

#code CODE_HEADER,0,17,HEADERFLAG
        defb    3                       ; Indicates binary data
        defb    "sprite-p-c"            ; the block name, 10 bytes long
        defw    CODE_END-CODE_START     ; length of data block which follows
        defw    CODE_START              ; default location for the data
        defw    0                       ; unused

#code CODE_DATA, CODE_START,*,DATAFLAG

; Z80 assembler code and data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; end of zasm .tap template header
;;
;; for other assemblers just copy from here onwards
;; and use an org directive eg:
;;
;; org 24000
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; move a 2x2 sprite against a background
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        call INIT_SCREEN
        ld hl,UDG_LOCAL_DATA            ; sprite address.
        ; ld a,160
        ; ld c,a                          ; set x coordinate.
        ; ld a,$50
        ; ld b,a                          ; set y coordinate.
        ; ld (XPOS),bc                    ; set up sprite routine coords.
        ld a,0                          ;initial position in circle list
        ld (POS),a
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
        ; cp $25                          ; check for q key
        ; jr z,HANDLE_UP
        ; cp $26                          ; check for a key
        ; jr z,HANDLE_DOWN
        cp $27                          ; check for capshift (left shift on mac) key
        jr nz,CYCLE                     ; no match? loop again. otherwise fall through
HANDLE_QUIT
        ld a,$2
        ld (DF_SZ),a                    ; restore lower part of screen to 2
        ret                             ; return to BASIC
; HANDLE_DOWN
;         ld a,(YPOS)
;         cp 170                          ; is y at bottom? 32d (we're 2 tall)
;         jr z,CYCLE                      ; yes. can't move down any further
;         push af
;         call UNDISPLAY_SPRITE
;         pop af
;         add a,$2
;         ld (YPOS),a
;         jr DISPLAY_SPRITE
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
        jp nz,INC_POS                   ; no, decrease position
        ld a,0                          ; yes, wrap to list start pos
        ld (POS),a
        jr AFTER_INC_POS
INC_POS
        inc a                           ; pos is < MAX so increment
        ld (POS),a                      ; store new value
AFTER_INC_POS
        jr DISPLAY_SPRITE

; HANDLE_LEFT
;         ld a,(XPOS)
;         cp $0                           ; is x at left?
;         jr z,CYCLE                      ; yes. can't move left any further
;         push af
;         call UNDISPLAY_SPRITE
;         pop af
;         sub a,$2
;         ld (XPOS),a
;         jr DISPLAY_SPRITE
; HANDLE_RIGHT
;         ld a,(XPOS)
;         cp $e7                          ; is x at right? 30d
;         jr z,CYCLE                      ; yes. can't move right any further
;         push af
;         call UNDISPLAY_SPRITE
;         pop af
;         add a,$2
;         ld (XPOS),a
;         jr DISPLAY_SPRITE
; HANDLE_UP
;         ld a,(YPOS)
;         cp $0                          ; is y at top?
;         jr z,CYCLE                      ; yes. can't move up any further
;         push af
;         call UNDISPLAY_SPRITE
;         pop af
;         sub a,$2
;         ld (YPOS),a                     ; and fall through..
DISPLAY_SPRITE
        ld hl,UDG_LOCAL_DATA
        halt
        call SPRITE
CYCLE
        jp GAME_LOOP

UNDISPLAY_SPRITE
        ld hl,UDG_LOCAL_DATA
        halt
        call SPRITE                     ; remove old
        ret

        ;;
        ;; subroutines
        ;;

INIT_SCREEN
        ;; setup screen handling
        ld a,0
        ld (DF_SZ),a                    ; set lower part of screen to 0 size so we get 24 lines

        ld a,$2                         ; set printing to
        call $1601                      ; top part of screen

        ;; draw background
        ld a,AT_CONTROL                 ; set print position:
        rst $10                         ; at
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
        ld ix,CIRCLE_POS                ; ix points to list of xy positions for circle
        ld de,(POS)                     ; lookup index into list
        push hl                         ; protect hl
        ld hl,de                        ; store a copy of the index counter
        add hl,de                       ; double the value because we've got 2 co ord
        ld de,hl                        ; swap registers
        pop hl                          ; restore hl
        add ix,de                       ; add index to list address
        ld a,(ix)                       ; find x coordinate at that position in list
        ld b,a                          ; b:= y coord
        ld a,(ix+1)                     ; find y coordinate at next position in list
        ld c,a                          ; c:= x coord
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

MAX_POS defb 15                        ; 0, 1, 2, 3
POS     defb 0                          ; index into circle pos for sprite
XPOS    defb 0
YPOS    defb 0
DISPX   defb 0
TMP0    defw 0
SPRTMP  defw 0

;; UDG characters
UDG_LOCAL_DATA
;; main sprite
    ; defb 7,    31,  63, 127, 127, 255, 255, 255 ; A top left
    ; defb 224, 248, 252, 254, 254, 255, 255, 255 ; B top right
    ; defb 255, 255, 243, 115, 127, 63,   31, 7   ; C bottom left
    ; defb 255, 255, 255, 254, 254, 252, 248, 224 ; D bottom right
;interleaved now: A0B0A1B1A2B2A3B3A4B4A5B5A6B6A7B7
    defb 7,  224,31, 248, 63, 252,127,254,127,254,255,255,255,255,255,255
;interleaved now: C0D0C1D1C2D2C3D3C4D4C5D5C6D6C7D7
    defb 255,255,255,255,243,255,115,254,127,254,63,252,31,248,7,224

CIRCLE_POS  defb 120,24,  84,28,   68,40,   48,60,   40,96,  52,128, 68,148, 88,160
            defb 120,164, 152,160, 180,144, 196,120, 200,96, 192,60, 180,44, 160,32  ; x,y coords in a list

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
ATTR_T          equ $5C8F
MEMBOT          equ $5C92

; rom routines
KEY_SCAN        equ $028e
KEY_TEST        equ $031e
KEY_CODE        equ $0333


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
