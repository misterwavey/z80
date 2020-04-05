                        ; An example CP/M application

Zeus_cpm_drives         = "cpm_disks.bin"               ; Tell Zeus where the CP/M virtual disks are stored

                        zeusemulate "cpm"               ; Tell Zeus and the emulator what to emulate
                        profile=true                    ; Allow profiling if anyone's interested.

; We'll start execauting at zero, so fire up CP/M Start here

                        org $0000                       ; Z80 reset vector

                        di                              ; Disable Interrupts
                        jp RawCPMBoot                   ; Start CP/M

; This jump is the CP/M API entry point, we include it in the source so Zeus will show it when single-stepping
                        org $5                          ;
CPM_CMD                 jp FBASE                        ; The CP/M command entry point

; Build the CP/M application here.

;
; parse args (add/list) (entry)
; if add
;     open file
;     add entry [with timestamp]
;     close file
; else if list
;      open file
;      list entries
;      close?
; else error
;
COMTAIL$COUNT           equ $0080                       ; our command's argument list length
COMTAIL$CHARS           equ $0081                       ; our command's argument list contents

B$CONOUT                equ 2                           ; BDOS FN 2 - wite byte to console
B$PRINTS                equ 9                           ; BDOS FN 9 - write $ terminated string to console

ORG                     $100                            ; TRANSIENT PROGRAM AREA
AppStart                equ *                           ;

                        ld hl, COMTAIL$COUNT            ; check comtail for arguments
                        ld a, (hl)                      ;
                        ld c, a                         ; copy length for later
                        CP 0                            ; length == 0?
                        JP z, NoArgs                    ; yes

CheckArgs               ld de, COMTAIL$CHARS-1          ; skip leading spaces
SkipLeadingSpaces       inc de                          ;
                        ld a, (de)                      ;
                        cp a, ' '                       ;
                        jp z, SkipLeadingSpaces         ;
                        ld hl, CMDBUFF                  ; populate cmdbuf with comtail until next space
CopyUntilSpaceOrMax     ld (hl), a                      ; add char to cmdbuf[hl]
                        inc hl                          ;
                        push hl                         ; store
                        push bc                         ;
                        ld bc, COMTAIL$CHARS            ;
                        ld hl, de                       ;
                        or a                            ; clear carry for next op
                        sbc hl, bc                      ; hl = hl - bc
                        ld a, l                         ; a = low byte of hl
                        ld hl, COMTAIL$COUNT            ;
                        ld b, (hl)                      ;
                        cp b                            ;   z = a - b
                        pop bc                          ;
                        pop hl                          ;
                        jp z, FinaliseCmd               ; a = size diff
                        inc de                          ;
                        ld a, (de)                      ;
                        cp a, ' '                       ;
                        jp nz, CopyUntilSpaceOrMax      ;
FinaliseCmd             ld a, '$'                       ; $ terminate cmdbuf
                        ld (hl), a                      ;

                        ld C, B$PRINTS                  ;
                        ld DE, CMDBUFF                  ;
                        CALL CPM_CMD                    ;
                        RET                             ; RETURN TO THE CCP

/*                      ld b,0                          ;  copy args and add $ terminator
                        ld hl, COMTAIL$COUNT            ;
                        ld c, (hl)                      ;
                        ld hl, COMTAIL$CHARS            ;
                        ld de, COPYCOMTAIL$CHARS        ;
                        ldir                            ;
                        ld hl, de                       ;
                        ld a, '$'                       ;
                        ld (hl), a                      ;
                        ld b, 0                         ; print args and exit

                        ld C, B$PRINTS                  ;
                        ld DE, COPYCOMTAIL$CHARS        ;
                        CALL CPM_CMD                    ;
                        RET                             ; RETURN TO THE CCP
*/

NoArgs                  ld DE, NO_ARGS                  ; print usage message and exit
                        ld C, B$PRINTS                  ;
                        CALL CPM_CMD                    ;
                        RET                             ; RETURN TO THE CCP
; STRING CONSTANTS
CMD_ADD                 defb "ADD"                      ; text of add command
CMD_LIST                defb "LIST"                     ; text of list command
NO_ARGS                 defb "usage: journal list|add [new journal entry text]$" ;

; VARS
CMDBUFF                 defs $127                       ; copy of the command entered
COPYCOMTAIL$CHARS       defs $127                       ; a copy of the space for commtail so we can $ terminate it

AppEnd                  equ *                           ; We'll need to know how long the application is.


                        output_cpm "A:JOURNAL.COM",AppStart,AppEnd-AppStart;
; Save this application as a CP/M file

;                        output_cpm "A:H.COM",AppStart,AppEnd-AppStart

; Now, we'll also include and build the CP/M source files while we're at it, so they can be single-stepped

                        include "..\zeus\cpm22.asm"     ;
                        include "..\zeus\cbios.asm"     ;

; Setup the CP/M terminal colours

                        zeussyntaxhighlight 300,$00,$20,$00 ; Normal background
                        zeussyntaxhighlight 301,$00,$FF,$00 ; Normal foreground
                        zeussyntaxhighlight 302,$00,$00,$80 ; Highlight background
                        zeussyntaxhighlight 303,$FF,$FF,$FF ; Highlight foreground

; These will show some extra memory display panels, which are set to disappear whenever the emulator page is left.
; Uncomment the following line to have them displayed, then drag/resise them to suit your display
; This is just to give an idea what you can do with memory panels.

                        bShowTheMemoryPanels equ true   ;

        if enabled bShowTheMemoryPanels                 ;
                        ; zeusmem $0000,"CP/M - vars",16,true,true,true ; Show the CP/M variable area, with address and characters and hide when editing
                        zeusmem $0100,"CP/M - TPA",16,true,true,true ; Show the TPA, with address and characters and hide when editing
                        ; zeusmem $0100,"CP/M - 64 chars wide",64,true,false,true ; Show a wide view of memory, with address but no characters and hide when editing
        endif                                           ;

                        zeussyntaxhighlight 0, $00,$FF,$11, true ; Set the token colour
                        zeussyntaxhighlight 1, $FF,$00,$FF, false ; Set the identifier colour
                        zeussyntaxhighlight 2, $00,$C0,$00, false ; Set the comment colour
                        zeussyntaxhighlight 3, $0,$FF,$AA, false ; Set the constant colour
                        zeussyntaxhighlight 4, $00,$FF,$00, true ; Set the line number colour
                        zeussyntaxhighlight 5, $FF,$FF,$FF, true ; Set the marker colour
                        zeussyntaxhighlight 6, $FF,$00,$FF ; Set the error colour
                        zeussyntaxhighlight 7, $ff,$FF,$FF ; Set the margin data colour

                        zeussyntaxhighlight 100, $00,$FF,$FF ; Diana background
                        zeussyntaxhighlight 101, $00,$ff,$00 ; Diana foreground
                        zeussyntaxhighlight 102, $FF,$FF,$FF ; Diana defn background
                        zeussyntaxhighlight 103, $00,$00,$A0 ; Diana defn foreground

                        zeussyntaxhighlight 249, $00,$00,$A0 ; Set the "marked line" colour. [not used in this version]
                        zeussyntaxhighlight 250, $ff,$00,$ff ; Set the margin separator line colour
                        zeussyntaxhighlight 251, $00,$00,$C8 ; Set the margin separator line2 colour
                        zeussyntaxhighlight 252, $22,$22,$00 ; Set the current executing line background colour
                        zeussyntaxhighlight 253, $22,$22,$aa ; Set the current editing line background colour
                        zeussyntaxhighlight 254, $00,$00,$00 ; Set the margin background colour
                        zeussyntaxhighlight 255, $00,$00,$00 ; Set the editor background colour

