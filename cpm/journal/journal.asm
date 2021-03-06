; standard zeus CP/M setup
; see http://desdes.com/products/oldfiles/index.htm to download zeus(ish) (zeustest.exe at time of writing)
; will also need the cpm sources file http://desdes.com/products/oldfiles/cpm_app.zip

Zeus_cpm_drives         = "cpm_disks.bin"               ; Tell Zeus where the CP/M virtual disks are stored

                        zeusemulate "cpm"               ; Tell Zeus and the emulator what to emulate
                        profile=true                    ; Allow profiling if anyone's interested.

; We'll start execauting at zero, so fire up CP/M Start here

                        org $0000                       ; Z80 reset vector

                        di                              ; Disable Interrupts
                        jp RawCPMBoot                   ; Start CP/M

; This jump is the CP/M API entry point, we include it in the source so Zeus will show it when single-stepping
                        org $5                          ;
BDOS_CMD                jp FBASE                        ; The CP/M command entry point


        ; * * * * * * * * * * * * * * * *
        ; *                             *
        ; * start of JOURNAL.COM source *
        ; *                             *
        ; * * * * * * * * * * * * * * * *


; parse args (add/list) (entry)
; if add
;     open file
;     move to end of file
;     add entry
;     close file
; else if list
;      open file
;      list entries
;      close
; else error
;
COMTAIL_COUNT           equ $0080                       ; our command's argument list length
COMTAIL_CHARS           equ $0081                       ; our command's argument list contents

B_CONOUT                equ 2                           ; BDOS FN 2  - wite byte to console
B_PRINTS                equ 9                           ; BDOS FN 9  - write $ terminated string to console
B_OPENF                 equ 15                          ; BDOS FN 15 - open file
B_CLOSEF                equ 16                          ; BDOS FN 16 - close file
B_READSEQ               equ 20                          ; BDOS FN 20 - read sequential record
B_WRITESEQ              equ 21                          ; BDOS FN 21 - write sequential record
B_CREATEF               equ 22                          ; BDOS FN 22 - create file
B_SETDMA                equ 26                          ; BDOS FN 26 - set DMA location

ORG                     $100                            ; TRANSIENT PROGRAM AREA
AppStart                equ *                           ;

                        ld hl, COMTAIL_COUNT            ; check comtail for arguments
                        ld a, (hl)                      ;
                        cp 0                            ; length == 0?
                        jp z, ShowUsage                 ; yes

CheckArgs               ld de, COMTAIL_CHARS-1          ; skip any leading spaces
SkipLeadingSpaces       inc de                          ;
                        ld a, (de)                      ;
                        cp a, ' '                       ;
                        jp z, SkipLeadingSpaces         ;
                        ld a, (de)                      ; examine first nonspace char in args
                        cp '+'                          ; add?
                        jp z, AddEntry                  ; yes
                        cp '='                          ; or list?
                        jp z, ListEntries               ; yes
                        jp ShowUsage                    ; else err


AddEntry                ld hl, COMTAIL_COUNT            ; check comtail for arguments
                        ld a, (hl)                      ;
                        cp 4                            ;
                        jp c, ShowUsage                 ;

AddEntryLoop            inc de                          ; skip any leading spaces of the remainder of the arguments
                        ld a, (de)                      ;
                        cp a, ' '                       ;
                        jp z, AddEntryLoop              ;

                        ld hl, de                       ; hl = text entry
                        push hl                         ;
                        ld bc, COMTAIL_CHARS            ; find length of tail remaining
                        or a                            ; clear carry for sbc
                        sbc hl, bc                      ; hl = hl - bc
                        ld b, l                         ; b = comtail header length
                        ld hl, COMTAIL_COUNT            ;
                        ld a, (hl)                      ; a = comtail total len
                        sub b                           ; a = a - b = comtail entry len

CopyEntry               ld de, ENTRYBUF                 ; populate entrybuf with len(entry) chars
                        pop hl                          ; hl = text entry
                        ld b, 0                         ;
                        ld c, a                         ; bc = entry len
                        ldir                            ;

WriteEntry              call OpenOrCreateFile           ;
                        call MoveToEndOfFile            ;

                        ld c, B_SETDMA                  ; point dma at our entry
                        ld de, ENTRYBUF                 ;
                        call BDOS_CMD                   ;

                        ld de, FCB_DISK                 ; write entrybuf
                        ld c, B_WRITESEQ                ;
                        call BDOS_CMD                   ;
                        cp 0                            ; error writing?
                        jp nz, FileWriteError           ; yes

                        ld de, FCB_DISK                 ;
                        ld c, B_CLOSEF                  ; close file
                        call BDOS_CMD                   ;
                        cp $FF                          ; error closing?
                        jp z, FileCloseError            ; yes

                        ld de, OK                       ;
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ; RETURN TO THE CCP

ListEntries             call OpenOrCreateFile           ;
                        ld c, B_SETDMA                  ; point dma at our entry
                        ld de, ENTRYBUF                 ;
                        call BDOS_CMD                   ;

                        ld de, FCB_DISK                 ;
                        ld c, B_READSEQ                 ; read record into entrybuf
                        call BDOS_CMD                   ;
                        cp 0                            ; a = 0 = successful?
                        jp nz, NoEntries                ; no

ListNext                ld de, ENTRY_HEADER             ; yes
                        ld c, B_PRINTS                  ; print >
                        call BDOS_CMD                   ;

                        ld hl, ENTRYBUF-1               ; move through loaded entry until the first $1a EOF char
SkipToEofChar           inc hl                          ;
                        ld a, (hl)                      ;
                        cp $1a                          ;
                        jp nz, SkipToEofChar            ;
                        ld (hl), '$'                    ; and replace with $ terminator for printing

                        ld de, ENTRYBUF                 ;
                        ld c, B_PRINTS                  ; print entry
                        call BDOS_CMD                   ;

                        ld de, CR_CHAR                  ;
                        ld c, B_PRINTS                  ; print CR
                        call BDOS_CMD                   ;

                        ld de, FCB_DISK                 ;
                        ld c, B_READSEQ                 ; read record into entrybuf
                        call BDOS_CMD                   ;
                        cp 0                            ; a = 0 = successful?
                        jp z, ListNext                  ; yes, keep reading

                        ret                             ;

OpenOrCreateFile        ld c, B_OPENF                   ;
                        ld de, FCB_DISK                 ;
                        call BDOS_CMD                   ;
                        cp $ff                          ; a = ff -> file not found ?
                        ret nz                          ; no. we're done so return
                        ld c, B_CREATEF                 ; yes no file found. create it
                        ld de, FCB_DISK                 ;
                        call BDOS_CMD                   ;
                        cp $ff                          ; a = ff -> directory full?
                        jp z, FileError                 ; yes - err
                        ret                             ; no -  return

MoveToEndOfFile         ld de, FCB_DISK                 ;  read one record
                        ld c, B_READSEQ                 ;
                        call BDOS_CMD                   ;
                        cp 0                            ;  a = 0 = successful?
                        jp z, MoveToEndOfFile           ;  yes, keep reading
                        ret                             ;

Showtoken               ld c, B_PRINTS                  ; print first token
                        ld de, CMDBUF                   ;
                        call BDOS_CMD                   ;
                        ret                             ; RETURN TO THE CCP

ShowUsage               ld de, NO_ARGS                  ; print usage message and exit
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ; RETURN TO THE CCP

FileError               ld de, FILE_ERROR               ; print usage message and exit
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ; RETURN TO THE CCP

FileWriteError          ld de, FILE_WRITE_ERROR         ; print usage message and exit
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ;

FileCloseError          ld de, FILE_CLOSE_ERROR         ; print usage message and exit
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ;

NoEntries               ld de, NO_ENTRIES               ; print usage message and exit
                        ld c, B_PRINTS                  ;
                        call BDOS_CMD                   ;
                        ret                             ;


FCB_DISK                defb 0                          ; =FCB$FCB_DISK
FCB_NAME                defb "JOURNAL "                 ;
FCB_TYP                 defb "DAT"                      ;
FCB_EXTENT              defb 0                          ;
FCB_RESV                defb 0,0                        ;
FCB_RECUSED             defb 0                          ;
FCB_ABUSED              defb 0,0,0,0,0,0,0,0            ;
                        defb 0,0,0,0,0,0,0,0            ;
FCB_SEQREC              defb 0                          ;
FCB_RANREC              defw 0                          ;
FCB_RANRECO             defb 0                          ;

; CMD values
CMD_ADD                 defb "+"                        ; text of add command
CMD_LIST                defb "="                        ; text of list command

; STRING CONSTANTS - $ TERMINATE!!
NO_ARGS                 defb "usage: journal [+|-] [new journal entry text]$" ;
FILE_ERROR              defb "Failed to open/create file$" ;
FILE_WRITE_ERROR        defb "Failed to write file$"    ;
FILE_CLOSE_ERROR        defb "Failed to close file$"    ;
ENTRY_HEADER            defb "> $"                      ;
NO_ENTRIES              defb "No journal entries exist. add with +$" ;
OK                      defb "OK$"                      ;
CR_CHAR                 defb 13,10,'$'                  ; <CR><LF>$

; VARS
CMDBUF                  defb 0                          ; copy of the command entered
ENTRYBUF                defs 128, $1a                   ; pre-populate buffer with EOF chars (convention for ascii files)
CMDBUF_LEN              defb 0                          ; length of cmdbuf
AppEnd                  equ *                           ; We'll need to know how long the application is.

        ; * * * * * * * * * * * * * * *
        ; *                           *
        ; * end of JOURNAL.COM source *
        ; *                           *
        ; * * * * * * * * * * * * * * *


; Save this application as a CP/M file
                        output_cpm "A:JOURNAL.COM",AppStart,AppEnd-AppStart ;
; And a local copy for distribution
                        output_bin "JOURNAL.COM",AppStart,AppEnd-AppStart ;

; Now, we'll also include and build the CP/M source files while we're at it, so they can be single-stepped

                        include "..\zeus\cpm22.asm"     ;  assumes file can be found in relative directory
                        include "..\zeus\cbios.asm"     ;  assumes file can be found in relative directory

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

                        zeussyntaxhighlight 249, $00,$00,$A0 ; Set the "marked line" colour. [not used in this version]
                        zeussyntaxhighlight 250, $ff,$ff,$00 ; Set the margin separator line colour
                        zeussyntaxhighlight 251, $00,$00,$C8 ; Set the margin separator line2 colour
                        zeussyntaxhighlight 252, $22,$22,$00 ; Set the current executing line background colour
                        zeussyntaxhighlight 253, $22,$22,$aa ; Set the current editing line background colour
                        zeussyntaxhighlight 254, $00,$00,$00 ; Set the margin background colour
                        zeussyntaxhighlight 255, $00,$00,$00 ; Set the editor background colour

