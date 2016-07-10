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
UDGS            equ $5C7B ; location of UDGs
DF_CC           equ $5c84
S_POSN          equ $5c88
ATTR_P          equ $5C8D ; permanent colours
ATTR_T          equ $5C8F
MEMBOT          equ $5C92
FRAMES          equ $5C78 ; frame counter

; rom routines
KEY_SCAN        equ $028e
KEY_TEST        equ $031e
KEY_CODE        equ $0333
CLEAR_SCREEN    equ $0DAF ; based on ATTR_P contents
SET_BORDER      equ $229B
