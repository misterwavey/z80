; **************************************************************
; *
; *             C P / M   version   2 . 2
; *
; *   Reconstructed from memory image on February 27, 1981
; *
; *                by Clark A. Calkins
; *
; **************************************************************
;
;   Set memory limit here. This is the amount of contigeous
; ram starting from 0000. CP/M will reside at the end of this space.
;

IOBYTE                  equ 3                           ; i/o definition byte.
TDRIVE                  equ 4                           ; current drive name and user number.
ENTRY                   equ 5                           ; entry point for the cp/m bdos.
TFCB                    equ $5C                         ; default file control block.
TBUFF                   equ $80                         ; i/o buffer and command line storage.
TBASE                   equ $100                        ; transiant program storage area.
;
;   Set control character equates.
;
CNTRLC                  equ 3                           ; control-c
CNTRLE                  equ $05                         ; control-e
cBS                     equ $08                         ; backspace
TAB                     equ $09                         ; tab
LF                      equ $0A                         ; line feed
FF                      equ $0C                         ; form feed
CR                      equ $0D                         ; carriage return
CNTRLP                  equ $10                         ; control-p
CNTRLR                  equ $12                         ; control-r
CNTRLS                  equ $13                         ; control-s
CNTRLU                  equ $15                         ; control-u
CNTRLX                  equ $18                         ; control-x
CNTRLZ                  equ $1A                         ; control-z (end-of-file mark)
DEL                     equ $7F                         ; rubout
;
;   Set origin for CP/M
;
                        org $D000                       ;
;
CBASE                   jp COMMAND                      ; execute command processor (ccp).
                        jp CLEARBUF                     ; entry to empty input buffer before starting ccp.

;
;   Standard cp/m ccp input buffer. Format is (max length),
; (actual length), (char #1), (char #2), (char #3), etc.
;
INBUFF                  db 127                          ; length of input buffer.
                        db 0                            ; current length of contents.
                        db "Copyright"                  ;
                        db " 1979 (c) by Digital Research      ";
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
INPOINT                 dw INBUFF+2                     ; input line pointer
NAMEPNT                 dw 0                            ; input line pointer used for error message. Points to
;                       ;start of name in error.
;
;   Routine to print (A) on the console. All registers used.
;
PRINT                   ld e,a                          ; setup bdos call.
                        ld c,2                          ;
                        jp ENTRY                        ;
;
;   Routine to print (A) on the console and to save (BC).
;
PRINTB                  push bc                         ;
                        call PRINT                      ;
                        pop bc                          ;
                        ret                             ;
;
;   Routine to send a carriage return, line feed combination
; to the console.
;
CRLF                    ld a,CR                         ;
                        call PRINTB                     ;
                        ld a,LF                         ;
                        jp PRINTB                       ;
;
;   Routine to send one space to the console and save (BC).
;
SPACE                   ld a,' '                        ;
                        jp PRINTB                       ;
;
;   Routine to print character string pointed to be (BC) on the
; console. It must terminate with a null byte.
;
PLINE                   push bc                         ;
                        call CRLF                       ;
                        pop hl                          ;
PLINE2                  ld a,(hl)                       ;
                        or a                            ;
                        ret z                           ;
                        inc hl                          ;
                        push hl                         ;
                        call PRINT                      ;
                        pop hl                          ;
                        jp PLINE2                       ;
;
;   Routine to reset the disk system.
;
RESDSK                  ld c,13                         ;
                        jp ENTRY                        ;
;
;   Routine to select disk (A).
;
DSKSEL                  ld e,a                          ;
                        ld c,14                         ;
                        jp ENTRY                        ;
;
;   Routine to call bdos and save the return code. The zero
; flag is set on a return of 0ffh.
;
ENTRY1                  call ENTRY                      ;
                        ld (RTNCODE),a                  ; save return code.
                        inc a                           ; set zero if 0ffh returned.
                        ret                             ;
;
;   Routine to open a file. (DE) must point to the FCB.
;
OPEN                    ld c,15                         ;
                        jp ENTRY1                       ;
;
;   Routine to open file at (FCB).
;
OPENFCB                 xor a                           ; clear the record number byte at fcb+32
                        ld (FCB+32),a                   ;
                        ld de,FCB                       ;
                        jp OPEN                         ;
;
;   Routine to close a file. (DE) points to FCB.
;
CLOSE                   ld c,16                         ;
                        jp ENTRY1                       ;
;
;   Routine to search for the first file with ambigueous name
; (DE).
;
SRCHFST                 ld c,17                         ;
                        jp ENTRY1                       ;
;
;   Search for the next ambigeous file name.
;
SRCHNXT                 ld c,18                         ;
                        jp ENTRY1                       ;
;
;   Search for file at (FCB).
;
SRCHFCB                 ld de,FCB                       ;
                        jp SRCHFST                      ;
;
;   Routine to delete a file pointed to by (DE).
;
DELETE                  ld c,19                         ;
                        jp ENTRY                        ;
;
;   Routine to call the bdos and set the zero flag if a zero
; status is returned.
;
ENTRY2                  call ENTRY                      ;
                        or a                            ; set zero flag if appropriate.
                        ret                             ;
;
;   Routine to read the next record from a sequential file.
; (DE) points to the FCB.
;
RDREC                   ld c,20                         ;
                        jp ENTRY2                       ;
;
;   Routine to read file at (FCB).
;
READFCB                 ld de,FCB                       ;
                        jp RDREC                        ;
;
;   Routine to write the next record of a sequential file.
; (DE) points to the FCB.
;
WRTREC                  ld c,21                         ;
                        jp ENTRY2                       ;
;
;   Routine to create the file pointed to by (DE).
;
CREATE                  ld c,22                         ;
                        jp ENTRY1                       ;
;
;   Routine to rename the file pointed to by (DE). Note that
; the new name starts at (DE+16).
;
RENAM                   ld c,23                         ;
                        jp ENTRY                        ;
;
;   Get the current user code.
;
GETUSR                  ld e,$FF                        ;
;
;   Routne to get or set the current user code.
; If (E) is FF then this is a GET, else it is a SET.
;
GETSETUC                ld c,32                         ;
                        jp ENTRY                        ;
;
;   Routine to set the current drive byte at (TDRIVE).
;
SETCDRV                 call GETUSR                     ; get user number
                        add a,a                         ; and shift into the upper 4 bits.
                        add a,a                         ;
                        add a,a                         ;
                        add a,a                         ;
                        ld hl,CDRIVE                    ; now add in the current drive number.
                        or (hl)                         ;
                        ld (TDRIVE),a                   ; and save.
                        ret                             ;
;
;   Move currently active drive down to (TDRIVE).
;
MOVECD                  ld a,(CDRIVE)                   ;
                        ld (TDRIVE),a                   ;
                        ret                             ;
;
;   Routine to convert (A) into upper case ascii. Only letters
; are affected.
;
UPPER                   cp 'a'                          ; check for letters in the range of 'a' to 'z'.
                        ret c                           ;
                        cp '{'                          ;
                        ret nc                          ;
                        and $5F                         ; convert it if found.
                        ret                             ;
;
;   Routine to get a line of input. We must check to see if the
; user is in (BATCH) mode. If so, then read the input from file
; ($$$.SUB). At the end, reset to console input.
;
GETINP                  ld a,(BATCH)                    ; if =0, then use console input.
                        or a                            ;
                        jp z,GETINP1                    ;
;
;   Use the submit file ($$$.sub) which is prepared by a
; SUBMIT run. It must be on drive (A) and it will be deleted
; if and error occures (like eof).
;
                        ld a,(CDRIVE)                   ; select drive 0 if need be.
                        or a                            ;
                        ld a,0                          ; always use drive A for submit.
                        call nz,DSKSEL                  ; select it if required.
                        ld de,BATCHFCB                  ;
                        call OPEN                       ; look for it.
                        jp z,GETINP1                    ; if not there, use normal input.
                        ld a,(BATCHFCB+15)              ; get last record number+1.
                        dec a                           ;
                        ld (BATCHFCB+32),a              ;
                        ld de,BATCHFCB                  ;
                        call RDREC                      ; read last record.
                        jp nz,GETINP1                   ; quit on end of file.
;
;   Move this record into input buffer.
;
                        ld de,INBUFF+1                  ;
                        ld hl,TBUFF                     ; data was read into buffer here.
                        ld b,128                        ; all 128 characters may be used.
                        call HL2DE                      ; (HL) to (DE), (B) bytes.
                        ld hl,BATCHFCB+14               ;
                        ld (hl),0                       ; zero out the 's2' byte.
                        inc hl                          ; and decrement the record count.
                        dec (hl)                        ;
                        ld de,BATCHFCB                  ; close the batch file now.
                        call CLOSE                      ;
                        jp z,GETINP1                    ; quit on an error.
                        ld a,(CDRIVE)                   ; re-select previous drive if need be.
                        or a                            ;
                        call nz,DSKSEL                  ; don't do needless selects.
;
;   Print line just read on console.
;
                        ld hl,INBUFF+2                  ;
                        call PLINE2                     ;
                        call CHKCON                     ; check console, quit on a key.
                        jp z,GETINP2                    ; jump if no key is pressed.
;
;   Terminate the submit job on any keyboard input. Delete this
; file such that it is not re-started and jump to normal keyboard
; input section.
;
                        call DELBATCH                   ; delete the batch file.
                        jp CMMND1                       ; and restart command input.
;
;   Get here for normal keyboard input. Delete the submit file
; incase there was one.
;
GETINP1                 call DELBATCH                   ; delete file ($$$.sub).
                        call SETCDRV                    ; reset active disk.
                        ld c,10                         ; get line from console device.
                        ld de,INBUFF                    ;
                        call ENTRY                      ;
                        call MOVECD                     ; reset current drive (again).
;
;   Convert input line to upper case.
;
GETINP2                 ld hl,INBUFF+1                  ;
                        ld b,(hl)                       ; (B)=character counter.
GETINP3                 inc hl                          ;
                        ld a,b                          ; end of the line?
                        or a                            ;
                        jp z,GETINP4                    ;
                        ld a,(hl)                       ; convert to upper case.
                        call UPPER                      ;
                        ld (hl),a                       ;
                        dec b                           ; adjust character count.
                        jp GETINP3                      ;
GETINP4                 ld (hl),a                       ; add trailing null.
                        ld hl,INBUFF+2                  ;
                        ld (INPOINT),hl                 ; reset input line pointer.
                        ret                             ;
;
;   Routine to check the console for a key pressed. The zero
; flag is set is none, else the character is returned in (A).
;
CHKCON                  ld c,11                         ; check console.
                        call ENTRY                      ;
                        or a                            ;
                        ret z                           ; return if nothing.
                        ld c,1                          ; else get character.
                        call ENTRY                      ;
                        or a                            ; clear zero flag and return.
                        ret                             ;
;
;   Routine to get the currently active drive number.
;
GETDSK                  ld c,25                         ;
                        jp ENTRY                        ;
;
;   Set the stabdard dma address.
;
STDDMA                  ld de,TBUFF                     ;
;
;   Routine to set the dma address to (DE).
;
DMASET                  ld c,26                         ;
                        jp ENTRY                        ;
;
;  Delete the batch file created by SUBMIT.
;
DELBATCH                ld hl,BATCH                     ; is batch active?
                        ld a,(hl)                       ;
                        or a                            ;
                        ret z                           ;
                        ld (hl),0                       ; yes, de-activate it.
                        xor a                           ;
                        call DSKSEL                     ; select drive 0 for sure.
                        ld de,BATCHFCB                  ; and delete this file.
                        call DELETE                     ;
                        ld a,(CDRIVE)                   ; reset current drive.
                        jp DSKSEL                       ;
;
;   Check to two strings at (PATTRN1) and (PATTRN2). They must be
; the same or we halt....
;
VERIFY                  ld de,PATTRN1                   ; these are the serial number bytes.
                        ld hl,PATTRN2                   ; ditto, but how could they be different?
                        ld b,6                          ; 6 bytes each.
VERIFY1                 ld a,(de)                       ;
                        cp (hl)                         ;
                        jp nz,HALTNOW                   ; jump to halt routine.
                        inc de                          ;
                        inc hl                          ;
                        dec b                           ;
                        jp nz,VERIFY1                   ;
                        ret                             ;
;
;   Print back file name with a '?' to indicate a syntax error.
;
SYNERR                  call CRLF                       ; end current line.
                        ld hl,(NAMEPNT)                 ; this points to name in error.
SYNERR1                 ld a,(hl)                       ; print it until a space or null is found.
                        cp ' '                          ;
                        jp z,SYNERR2                    ;
                        or a                            ;
                        jp z,SYNERR2                    ;
                        push hl                         ;
                        call PRINT                      ;
                        pop hl                          ;
                        inc hl                          ;
                        jp SYNERR1                      ;
SYNERR2                 ld a,'?'                        ; add trailing '?'.
                        call PRINT                      ;
                        call CRLF                       ;
                        call DELBATCH                   ; delete any batch file.
                        jp CMMND1                       ; and restart from console input.
;
;   Check character at (DE) for legal command input. Note that the
; zero flag is set if the character is a delimiter.
;
CHECK                   ld a,(de)                       ;
                        or a                            ;
                        ret z                           ;
                        cp ' '                          ; control characters are not legal here.
                        jp c,SYNERR                     ;
                        ret z                           ; check for valid delimiter.
                        cp '='                          ;
                        ret z                           ;
                        cp '_'                          ;
                        ret z                           ;
                        cp '.'                          ;
                        ret z                           ;
                        cp ':'                          ;
                        ret z                           ;
                        cp $3B                          ; ';'
                        ret z                           ;
                        cp '<'                          ;
                        ret z                           ;
                        cp '>'                          ;
                        ret z                           ;
                        ret                             ;
;
;   Get the next non-blank character from (DE).
;
NONBLANK                ld a,(de)                       ;
                        or a                            ; string ends with a null.
                        ret z                           ;
                        cp ' '                          ;
                        ret nz                          ;
                        inc de                          ;
                        jp NONBLANK                     ;
;
;   Add (HL)=(HL)+(A)
;
ADDHL                   add a,l                         ;
                        ld l,a                          ;
                        ret nc                          ; take care of any carry.
                        inc h                           ;
                        ret                             ;
;
;   Convert the first name in (FCB).
;
CONVFST                 ld a,0                          ;
;
;   Format a file name (convert * to '?', etc.). On return,
; (A)=0 is an unambigeous name was specified. Enter with (A) equal to
; the position within the fcb for the name (either 0 or 16).
;
CONVERT                 ld hl,FCB                       ;
                        call ADDHL                      ;
                        push hl                         ;
                        push hl                         ;
                        xor a                           ;
                        ld (CHGDRV),a                   ; initialize drive change flag.
                        ld hl,(INPOINT)                 ; set (HL) as pointer into input line.
                        ex de,hl                        ;
                        call NONBLANK                   ; get next non-blank character.
                        ex de,hl                        ;
                        ld (NAMEPNT),hl                 ; save pointer here for any error message.
                        ex de,hl                        ;
                        pop hl                          ;
                        ld a,(de)                       ; get first character.
                        or a                            ;
                        jp z,CONVRT1                    ;
                        sbc a,'A'-1                     ; might be a drive name, convert to binary.
                        ld b,a                          ; and save.
                        inc de                          ; check next character for a ':'.
                        ld a,(de)                       ;
                        cp ':'                          ;
                        jp z,CONVRT2                    ;
                        dec de                          ; nope, move pointer back to the start of the line.
CONVRT1                 ld a,(CDRIVE)                   ;
                        ld (hl),a                       ;
                        jp CONVRT3                      ;
CONVRT2                 ld a,b                          ;
                        ld (CHGDRV),a                   ; set change in drives flag.
                        ld (hl),b                       ;
                        inc de                          ;
;
;   Convert the basic file name.
;
CONVRT3                 ld b,$08                        ;
CONVRT4                 call CHECK                      ;
                        jp z,CONVRT8                    ;
                        inc hl                          ;
                        cp '*'                          ; note that an '*' will fill the remaining
                        jp nz,CONVRT5                   ; field with '?'.
                        ld (hl),'?'                     ;
                        jp CONVRT6                      ;
CONVRT5                 ld (hl),a                       ;
                        inc de                          ;
CONVRT6                 dec b                           ;
                        jp nz,CONVRT4                   ;
CONVRT7                 call CHECK                      ; get next delimiter.
                        jp z,GETEXT                     ;
                        inc de                          ;
                        jp CONVRT7                      ;
CONVRT8                 inc hl                          ; blank fill the file name.
                        ld (hl),' '                     ;
                        dec b                           ;
                        jp nz,CONVRT8                   ;
;
;   Get the extension and convert it.
;
GETEXT                  ld b,$03                        ;
                        cp '.'                          ;
                        jp nz,GETEXT5                   ;
                        inc de                          ;
GETEXT1                 call CHECK                      ;
                        jp z,GETEXT5                    ;
                        inc hl                          ;
                        cp '*'                          ;
                        jp nz,GETEXT2                   ;
                        ld (hl),'?'                     ;
                        jp GETEXT3                      ;
GETEXT2                 ld (hl),a                       ;
                        inc de                          ;
GETEXT3                 dec b                           ;
                        jp nz,GETEXT1                   ;
GETEXT4                 call CHECK                      ;
                        jp z,GETEXT6                    ;
                        inc de                          ;
                        jp GETEXT4                      ;
GETEXT5                 inc hl                          ;
                        ld (hl),' '                     ;
                        dec b                           ;
                        jp nz,GETEXT5                   ;
GETEXT6                 ld b,3                          ;
GETEXT7                 inc hl                          ;
                        ld (hl),0                       ;
                        dec b                           ;
                        jp nz,GETEXT7                   ;
                        ex de,hl                        ;
                        ld (INPOINT),hl                 ; save input line pointer.
                        pop hl                          ;
;
;   Check to see if this is an ambigeous file name specification.
; Set the (A) register to non zero if it is.
;
                        ld bc,11                        ; set name length.
GETEXT8                 inc hl                          ;
                        ld a,(hl)                       ;
                        cp '?'                          ; any question marks?
                        jp nz,GETEXT9                   ;
                        inc b                           ; count them.
GETEXT9                 dec c                           ;
                        jp nz,GETEXT8                   ;
                        ld a,b                          ;
                        or a                            ;
                        ret                             ;
;
;   CP/M command table. Note commands can be either 3 or 4 characters long.
;
NUMCMDS                 equ 6                           ; number of commands
CMDTBL                  db "DIR "                       ;
                        db "ERA "                       ;
                        db "TYPE"                       ;
                        db "SAVE"                       ;
                        db "REN "                       ;
                        db "USER"                       ;
;
;   The following six bytes must agree with those at (PATTRN2)
; or cp/m will HALT. Why?
;
PATTRN1                 db 0,22,0,0,0,0                 ; (* serial number bytes *).
;
;   Search the command table for a match with what has just
; been entered. If a match is found, then we jump to the
; proper section. Else jump to (UNKNOWN).
; On return, the (C) register is set to the command number
; that matched (or NUMCMDS+1 if no match).
;
SEARCH                  ld hl,CMDTBL                    ;
                        ld c,0                          ;
SEARCH1                 ld a,c                          ;
                        cp NUMCMDS                      ; this commands exists.
                        ret nc                          ;
                        ld de,FCB+1                     ; check this one.
                        ld b,4                          ; max command length.
SEARCH2                 ld a,(de)                       ;
                        cp (hl)                         ;
                        jp nz,SEARCH3                   ; not a match.
                        inc de                          ;
                        inc hl                          ;
                        dec b                           ;
                        jp nz,SEARCH2                   ;
                        ld a,(de)                       ; allow a 3 character command to match.
                        cp ' '                          ;
                        jp nz,SEARCH4                   ;
                        ld a,c                          ; set return register for this command.
                        ret                             ;
SEARCH3                 inc hl                          ;
                        dec b                           ;
                        jp nz,SEARCH3                   ;
SEARCH4                 inc c                           ;
                        jp SEARCH1                      ;
;
;   Set the input buffer to empty and then start the command
; processor (ccp).
;
CLEARBUF                xor a                           ;
                        ld (INBUFF+1),a                 ; second byte is actual length.
;
; **************************************************************
; *
; *
; * C C P  -   C o n s o l e   C o m m a n d   P r o c e s s o r
; *
; **************************************************************
; *
COMMAND                 ld sp,CCPSTACK                  ; setup stack area.
                        push bc                         ; note that (C) should be equal to:
                        ld a,c                          ; (uuuudddd) where 'uuuu' is the user number
                        rra                             ; and 'dddd' is the drive number.
                        rra                             ;
                        rra                             ;
                        rra                             ;
                        and $0F                         ; isolate the user number.
                        ld e,a                          ;
                        call GETSETUC                   ; and set it.
                        call RESDSK                     ; reset the disk system.
                        ld (BATCH),a                    ; clear batch mode flag.
                        pop bc                          ;
                        ld a,c                          ;
                        and $0F                         ; isolate the drive number.
                        ld (CDRIVE),a                   ; and save.
                        call DSKSEL                     ; ...and select.
                        ld a,(INBUFF+1)                 ;
                        or a                            ; anything in input buffer already?
                        jp nz,CMMND2                    ; yes, we just process it.
;
;   Entry point to get a command line from the console.
;
CMMND1                  ld sp,CCPSTACK                  ; set stack straight.
                        call CRLF                       ; start a new line on the screen.
                        call GETDSK                     ; get current drive.
                        add a,'A'                       ;
                        call PRINT                      ; print current drive.
                        ld a,'>'                        ;
                        call PRINT                      ; and add prompt.
                        call GETINP                     ; get line from user.
;
;   Process command line here.
;
CMMND2                  ld de,TBUFF                     ;
                        call DMASET                     ; set standard dma address.
                        call GETDSK                     ;
                        ld (CDRIVE),a                   ; set current drive.
                        call CONVFST                    ; convert name typed in.
                        call nz,SYNERR                  ; wild cards are not allowed.
                        ld a,(CHGDRV)                   ; if a change in drives was indicated,
                        or a                            ; then treat this as an unknown command
                        jp nz,UNKNOWN                   ; which gets executed.
                        call SEARCH                     ; else search command table for a match.
;
;   Note that an unknown command returns
; with (A) pointing to the last address
; in our table which is (UNKNOWN).
;
                        ld hl,CMDADR                    ; now, look thru our address table for command (A).
                        ld e,a                          ; set (DE) to command number.
                        ld d,0                          ;
                        add hl,de                       ;
                        add hl,de                       ; (HL)=(CMDADR)+2*(command number).
                        ld a,(hl)                       ; now pick out this address.
                        inc hl                          ;
                        ld h,(hl)                       ;
                        ld l,a                          ;
                        jp (hl)                         ; now execute it.
;
;   CP/M command address table.
;
CMDADR                  dw DIRECT,ERASE,TYPE,SAVE       ;
                        dw RENAME,USER,UNKNOWN          ;
;
;   Halt the system. Reason for this is unknown at present.
;
HALTNOW                 ld hl,$76F3                     ; 'DI HLT' instructions.
                        ld (CBASE),hl                   ;
                        ld hl,CBASE                     ;
                        jp (hl)                         ;
;
;   Read error while TYPEing a file.
;
RDERROR                 ld bc,RDERR                     ;
                        jp PLINE                        ;
RDERR                   db "Read error"                 ;
                        db 0                            ;
;
;   Required file was not located.
;
NONE                    ld bc,NOFILE                    ;
                        jp PLINE                        ;
NOFILE                  db "No file"                    ;
                        db 0                            ;
;
;   Decode a command of the form 'A>filename number{ filename}.
; Note that a drive specifier is not allowed on the first file
; name. On return, the number is in register (A). Any error
; causes 'filename?' to be printed and the command is aborted.
;
DECODE                  call CONVFST                    ; convert filename.
                        ld a,(CHGDRV)                   ; do not allow a drive to be specified.
                        or a                            ;
                        jp nz,SYNERR                    ;
                        ld hl,FCB+1                     ; convert number now.
                        ld bc,11                        ; (B)=sum register, (C)=max digit count.
DECODE1                 ld a,(hl)                       ;
                        cp ' '                          ; a space terminates the numeral.
                        jp z,DECODE3                    ;
                        inc hl                          ;
                        sub '0'                         ; make binary from ascii.
                        cp 10                           ; legal digit?
                        jp nc,SYNERR                    ;
                        ld d,a                          ; yes, save it in (D).
                        ld a,b                          ; compute (B)=(B)*10 and check for overflow.
                        and $E0                         ;
                        jp nz,SYNERR                    ;
                        ld a,b                          ;
                        rlca                            ;
                        rlca                            ;
                        rlca                            ; (A)=(B)*8
                        add a,b                         ; .......*9
                        jp c,SYNERR                     ;
                        add a,b                         ; .......*10
                        jp c,SYNERR                     ;
                        add a,d                         ; add in new digit now.
DECODE2                 jp c,SYNERR                     ;
                        ld b,a                          ; and save result.
                        dec c                           ; only look at 11 digits.
                        jp nz,DECODE1                   ;
                        ret                             ;
DECODE3                 ld a,(hl)                       ; spaces must follow (why?).
                        cp ' '                          ;
                        jp nz,SYNERR                    ;
                        inc hl                          ;
DECODE4                 dec c                           ;
                        jp nz,DECODE3                   ;
                        ld a,b                          ; set (A)=the numeric value entered.
                        ret                             ;
;
;   Move 3 bytes from (HL) to (DE). Note that there is only
; one reference to this at (A2D5h).
;
MOVE3                   ld b,3                          ;
;
;   Move (B) bytes from (HL) to (DE).
;
HL2DE                   ld a,(hl)                       ;
                        ld (de),a                       ;
                        inc hl                          ;
                        inc de                          ;
                        dec b                           ;
                        jp nz,HL2DE                     ;
                        ret                             ;
;
;   Compute (HL)=(TBUFF)+(A)+(C) and get the byte that's here.
;
EXTRACT                 ld hl,TBUFF                     ;
                        add a,c                         ;
                        call ADDHL                      ;
                        ld a,(hl)                       ;
                        ret                             ;
;
;  Check drive specified. If it means a change, then the new
; drive will be selected. In any case, the drive byte of the
; fcb will be set to null (means use current drive).
;
DSELECT                 xor a                           ; null out first byte of fcb.
                        ld (FCB),a                      ;
                        ld a,(CHGDRV)                   ; a drive change indicated?
                        or a                            ;
                        ret z                           ;
                        dec a                           ; yes, is it the same as the current drive?
                        ld hl,CDRIVE                    ;
                        cp (hl)                         ;
                        ret z                           ;
                        jp DSKSEL                       ; no. Select it then.
;
;   Check the drive selection and reset it to the previous
; drive if it was changed for the preceeding command.
;
RESETDR                 ld a,(CHGDRV)                   ; drive change indicated?
                        or a                            ;
                        ret z                           ;
                        dec a                           ; yes, was it a different drive?
                        ld hl,CDRIVE                    ;
                        cp (hl)                         ;
                        ret z                           ;
                        ld a,(CDRIVE)                   ; yes, re-select our old drive.
                        jp DSKSEL                       ;
;
; **************************************************************
; *
; *           D I R E C T O R Y   C O M M A N D
; *
; **************************************************************
;
DIRECT                  call CONVFST                    ; convert file name.
                        call DSELECT                    ; select indicated drive.
                        ld hl,FCB+1                     ; was any file indicated?
                        ld a,(hl)                       ;
                        cp ' '                          ;
                        jp nz,DIRECT2                   ;
                        ld b,11                         ; no. Fill field with '?' - same as *.*.
DIRECT1                 ld (hl),'?'                     ;
                        inc hl                          ;
                        dec b                           ;
                        jp nz,DIRECT1                   ;
DIRECT2                 ld e,0                          ; set initial cursor position.
                        push de                         ;
                        call SRCHFCB                    ; get first file name.
                        call z,NONE                     ; none found at all?
DIRECT3                 jp z,DIRECT9                    ; terminate if no more names.
                        ld a,(RTNCODE)                  ; get file's position in segment (0-3).
                        rrca                            ;
                        rrca                            ;
                        rrca                            ;
                        and $60                         ; (A)=position*32
                        ld c,a                          ;
                        ld a,10                         ;
                        call EXTRACT                    ; extract the tenth entry in fcb.
                        rla                             ; check system file status bit.
                        jp c,DIRECT8                    ; we don't list them.
                        pop de                          ;
                        ld a,e                          ; bump name count.
                        inc e                           ;
                        push de                         ;
                        and $03                         ; at end of line?
                        push af                         ;
                        jp nz,DIRECT4                   ;
                        call CRLF                       ; yes, end this line and start another.
                        push bc                         ;
                        call GETDSK                     ; start line with ('A:').
                        pop bc                          ;
                        add a,'A'                       ;
                        call PRINTB                     ;
                        ld a,':'                        ;
                        call PRINTB                     ;
                        jp DIRECT5                      ;
DIRECT4                 call SPACE                      ; add seperator between file names.
                        ld a,':'                        ;
                        call PRINTB                     ;
DIRECT5                 call SPACE                      ;
                        ld b,1                          ; 'extract' each file name character at a time.
DIRECT6                 ld a,b                          ;
                        call EXTRACT                    ;
                        and $7F                         ; strip bit 7 (status bit).
                        cp ' '                          ; are we at the end of the name?
                        jp nz,DRECT65                   ;
                        pop af                          ; yes, don't print spaces at the end of a line.
                        push af                         ;
                        cp 3                            ;
                        jp nz,DRECT63                   ;
                        ld a,9                          ; first check for no extension.
                        call EXTRACT                    ;
                        and $7F                         ;
                        cp ' '                          ;
                        jp z,DIRECT7                    ; don't print spaces.
DRECT63                 ld a,' '                        ; else print them.
DRECT65                 call PRINTB                     ;
                        inc b                           ; bump to next character psoition.
                        ld a,b                          ;
                        cp 12                           ; end of the name?
                        jp nc,DIRECT7                   ;
                        cp 9                            ; nope, starting extension?
                        jp nz,DIRECT6                   ;
                        call SPACE                      ; yes, add seperating space.
                        jp DIRECT6                      ;
DIRECT7                 pop af                          ; get the next file name.
DIRECT8                 call CHKCON                     ; first check console, quit on anything.
                        jp nz,DIRECT9                   ;
                        call SRCHNXT                    ; get next name.
                        jp DIRECT3                      ; and continue with our list.
DIRECT9                 pop de                          ; restore the stack and return to command level.
                        jp GETBACK                      ;
;
; **************************************************************
; *
; *                E R A S E   C O M M A N D
; *
; **************************************************************
;
ERASE                   call CONVFST                    ; convert file name.
                        cp 11                           ; was '*.*' entered?
                        jp nz,ERASE1                    ;
                        ld bc,YESNO                     ; yes, ask for confirmation.
                        call PLINE                      ;
                        call GETINP                     ;
                        ld hl,INBUFF+1                  ;
                        dec (hl)                        ; must be exactly 'y'.
                        jp nz,CMMND1                    ;
                        inc hl                          ;
                        ld a,(hl)                       ;
                        cp 'Y'                          ;
                        jp nz,CMMND1                    ;
                        inc hl                          ;
                        ld (INPOINT),hl                 ; save input line pointer.
ERASE1                  call DSELECT                    ; select desired disk.
                        ld de,FCB                       ;
                        call DELETE                     ; delete the file.
                        inc a                           ;
                        call z,NONE                     ; not there?
                        jp GETBACK                      ; return to command level now.
YESNO                   db "All (y/n)?"                 ;
                        db 0                            ;
;
; **************************************************************
; *
; *            T Y P E   C O M M A N D
; *
; **************************************************************
;
TYPE                    call CONVFST                    ; convert file name.
                        jp nz,SYNERR                    ; wild cards not allowed.
                        call DSELECT                    ; select indicated drive.
                        call OPENFCB                    ; open the file.
                        jp z,TYPE5                      ; not there?
                        call CRLF                       ; ok, start a new line on the screen.
                        ld hl,NBYTES                    ; initialize byte counter.
                        ld (hl),$FF                     ; set to read first sector.
TYPE1                   ld hl,NBYTES                    ;
TYPE2                   ld a,(hl)                       ; have we written the entire sector?
                        cp 128                          ;
                        jp c,TYPE3                      ;
                        push hl                         ; yes, read in the next one.
                        call READFCB                    ;
                        pop hl                          ;
                        jp nz,TYPE4                     ; end or error?
                        xor a                           ; ok, clear byte counter.
                        ld (hl),a                       ;
TYPE3                   inc (hl)                        ; count this byte.
                        ld hl,TBUFF                     ; and get the (A)th one from the buffer (TBUFF).
                        call ADDHL                      ;
                        ld a,(hl)                       ;
                        cp CNTRLZ                       ; end of file mark?
                        jp z,GETBACK                    ;
                        call PRINT                      ; no, print it.
                        call CHKCON                     ; check console, quit if anything ready.
                        jp nz,GETBACK                   ;
                        jp TYPE1                        ;
;
;   Get here on an end of file or read error.
;
TYPE4                   dec a                           ; read error?
                        jp z,GETBACK                    ;
                        call RDERROR                    ; yes, print message.
TYPE5                   call RESETDR                    ; and reset proper drive
                        jp SYNERR                       ; now print file name with problem.
;
; **************************************************************
; *
; *            S A V E   C O M M A N D
; *
; **************************************************************
;
SAVE                    call DECODE                     ; get numeric number that follows SAVE.
                        push af                         ; save number of pages to write.
                        call CONVFST                    ; convert file name.
                        jp nz,SYNERR                    ; wild cards not allowed.
                        call DSELECT                    ; select specified drive.
                        ld de,FCB                       ; now delete this file.
                        push de                         ;
                        call DELETE                     ;
                        pop de                          ;
                        call CREATE                     ; and create it again.
                        jp z,SAVE3                      ; can't create?
                        xor a                           ; clear record number byte.
                        ld (FCB+32),a                   ;
                        pop af                          ; convert pages to sectors.
                        ld l,a                          ;
                        ld h,0                          ;
                        add hl,hl                       ; (HL)=number of sectors to write.
                        ld de,TBASE                     ; and we start from here.
SAVE1                   ld a,h                          ; done yet?
                        or l                            ;
                        jp z,SAVE2                      ;
                        dec hl                          ; nope, count this and compute the start
                        push hl                         ; of the next 128 byte sector.
                        ld hl,128                       ;
                        add hl,de                       ;
                        push hl                         ; save it and set the transfer address.
                        call DMASET                     ;
                        ld de,FCB                       ; write out this sector now.
                        call WRTREC                     ;
                        pop de                          ; reset (DE) to the start of the last sector.
                        pop hl                          ; restore sector count.
                        jp nz,SAVE3                     ; write error?
                        jp SAVE1                        ;
;
;   Get here after writing all of the file.
;
SAVE2                   ld de,FCB                       ; now close the file.
                        call CLOSE                      ;
                        inc a                           ; did it close ok?
                        jp nz,SAVE4                     ;
;
;   Print out error message (no space).
;
SAVE3                   ld bc,NOSPACE                   ;
                        call PLINE                      ;
SAVE4                   call STDDMA                     ; reset the standard dma address.
                        jp GETBACK                      ;
NOSPACE                 db "No space"                   ;
                        db 0                            ;
;
; **************************************************************
; *
; *           R E N A M E   C O M M A N D
; *
; **************************************************************
;
RENAME                  call CONVFST                    ; convert first file name.
                        jp nz,SYNERR                    ; wild cards not allowed.
                        ld a,(CHGDRV)                   ; remember any change in drives specified.
                        push af                         ;
                        call DSELECT                    ; and select this drive.
                        call SRCHFCB                    ; is this file present?
                        jp nz,RENAME6                   ; yes, print error message.
                        ld hl,FCB                       ; yes, move this name into second slot.
                        ld de,FCB+16                    ;
                        ld b,16                         ;
                        call HL2DE                      ;
                        ld hl,(INPOINT)                 ; get input pointer.
                        ex de,hl                        ;
                        call NONBLANK                   ; get next non blank character.
                        cp '='                          ; only allow an '=' or '_' seperator.
                        jp z,RENAME1                    ;
                        cp '_'                          ;
                        jp nz,RENAME5                   ;
RENAME1                 ex de,hl                        ;
                        inc hl                          ; ok, skip seperator.
                        ld (INPOINT),hl                 ; save input line pointer.
                        call CONVFST                    ; convert this second file name now.
                        jp nz,RENAME5                   ; again, no wild cards.
                        pop af                          ; if a drive was specified, then it
                        ld b,a                          ; must be the same as before.
                        ld hl,CHGDRV                    ;
                        ld a,(hl)                       ;
                        or a                            ;
                        jp z,RENAME2                    ;
                        cp b                            ;
                        ld (hl),b                       ;
                        jp nz,RENAME5                   ; they were different, error.
RENAME2                 ld (hl),b                       ;       reset as per the first file specification.
                        xor a                           ;
                        ld (FCB),a                      ; clear the drive byte of the fcb.
RENAME3                 call SRCHFCB                    ; and go look for second file.
                        jp z,RENAME4                    ; doesn't exist?
                        ld de,FCB                       ;
                        call RENAM                      ; ok, rename the file.
                        jp GETBACK                      ;
;
;   Process rename errors here.
;
RENAME4                 call NONE                       ; file not there.
                        jp GETBACK                      ;
RENAME5                 call RESETDR                    ; bad command format.
                        jp SYNERR                       ;
RENAME6                 ld bc,EXISTS                    ; destination file already exists.
                        call PLINE                      ;
                        jp GETBACK                      ;
EXISTS                  db "File exists"                ;
                        db 0                            ;
;
; **************************************************************
; *
; *             U S E R   C O M M A N D
; *
; **************************************************************
;
USER                    call DECODE                     ; get numeric value following command.
                        cp 16                           ; legal user number?
                        jp nc,SYNERR                    ;
                        ld e,a                          ; yes but is there anything else?
                        ld a,(FCB+1)                    ;
                        cp ' '                          ;
                        jp z,SYNERR                     ; yes, that is not allowed.
                        call GETSETUC                   ; ok, set user code.
                        jp GETBACK1                     ;
;
; **************************************************************
; *
; *        T R A N S I A N T   P R O G R A M   C O M M A N D
; *
; **************************************************************
;
UNKNOWN                 call VERIFY                     ; check for valid system (why?).
                        ld a,(FCB+1)                    ; anything to execute?
                        cp ' '                          ;
                        jp nz,UNKWN1                    ;
                        ld a,(CHGDRV)                   ; nope, only a drive change?
                        or a                            ;
                        jp z,GETBACK1                   ; neither???
                        dec a                           ;
                        ld (CDRIVE),a                   ; ok, store new drive.
                        call MOVECD                     ; set (TDRIVE) also.
                        call DSKSEL                     ; and select this drive.
                        jp GETBACK1                     ; then return.
;
;   Here a file name was typed. Prepare to execute it.
;
UNKWN1                  ld de,FCB+9                     ; an extension specified?
                        ld a,(de)                       ;
                        cp ' '                          ;
                        jp nz,SYNERR                    ; yes, not allowed.
UNKWN2                  push de                         ;
                        call DSELECT                    ; select specified drive.
                        pop de                          ;
                        ld hl,COMFILE                   ; set the extension to 'COM'.
                        call MOVE3                      ;
                        call OPENFCB                    ; and open this file.
                        jp z,UNKWN9                     ; not present?
;
;   Load in the program.
;
                        ld hl,TBASE                     ; store the program starting here.
UNKWN3                  push hl                         ;
                        ex de,hl                        ;
                        call DMASET                     ; set transfer address.
                        ld de,FCB                       ; and read the next record.
                        call RDREC                      ;
                        jp nz,UNKWN4                    ; end of file or read error?
                        pop hl                          ; nope, bump pointer for next sector.
                        ld de,128                       ;
                        add hl,de                       ;
                        ld de,CBASE                     ; enough room for the whole file?
                        ld a,l                          ;
                        sub e                           ;
                        ld a,h                          ;
                        sbc a,d                         ;
                        jp nc,UNKWN0                    ; no, it can't fit.
                        jp UNKWN3                       ;
;
;   Get here after finished reading.
;
UNKWN4                  pop hl                          ;
                        dec a                           ; normal end of file?
                        jp nz,UNKWN0                    ;
                        call RESETDR                    ; yes, reset previous drive.
                        call CONVFST                    ; convert the first file name that follows
                        ld hl,CHGDRV                    ; command name.
                        push hl                         ;
                        ld a,(hl)                       ; set drive code in default fcb.
                        ld (FCB),a                      ;
                        ld a,16                         ; put second name 16 bytes later.
                        call CONVERT                    ; convert second file name.
                        pop hl                          ;
                        ld a,(hl)                       ; and set the drive for this second file.
                        ld (FCB+16),a                   ;
                        xor a                           ; clear record byte in fcb.
                        ld (FCB+32),a                   ;
                        ld de,TFCB                      ; move it into place at(005Ch).
                        ld hl,FCB                       ;
                        ld b,33                         ;
                        call HL2DE                      ;
                        ld hl,INBUFF+2                  ; now move the remainder of the input
UNKWN5                  ld a,(hl)                       ; line down to (0080h). Look for a non blank.
                        or a                            ; or a null.
                        jp z,UNKWN6                     ;
                        cp ' '                          ;
                        jp z,UNKWN6                     ;
                        inc hl                          ;
                        jp UNKWN5                       ;
;
;   Do the line move now. It ends in a null byte.
;
UNKWN6                  ld b,0                          ; keep a character count.
                        ld de,TBUFF+1                   ; data gets put here.
UNKWN7                  ld a,(hl)                       ; move it now.
                        ld (de),a                       ;
                        or a                            ;
                        jp z,UNKWN8                     ;
                        inc b                           ;
                        inc hl                          ;
                        inc de                          ;
                        jp UNKWN7                       ;
UNKWN8                  ld a,b                          ; now store the character count.
                        ld (TBUFF),a                    ;
                        call CRLF                       ; clean up the screen.
                        call STDDMA                     ; set standard transfer address.
                        call SETCDRV                    ; reset current drive.
                        call TBASE                      ; and execute the program.
;
;   Transiant programs return here (or reboot).
;
                        ld sp,BATCH                     ; set stack first off.
                        call MOVECD                     ; move current drive into place (TDRIVE).
                        call DSKSEL                     ; and reselect it.
                        jp CMMND1                       ; back to comand mode.
;
;   Get here if some error occured.
;
UNKWN9                  call RESETDR                    ; inproper format.
                        jp SYNERR                       ;
UNKWN0                  ld bc,BADLOAD                   ; read error or won't fit.
                        call PLINE                      ;
                        jp GETBACK                      ;
BADLOAD                 db "Bad load"                   ;
                        db 0                            ;
COMFILE                 db "COM"                        ; command file extension.
;
;   Get here to return to command level. We will reset the
; previous active drive and then either return to command
; level directly or print error message and then return.
;
GETBACK                 call RESETDR                    ; reset previous drive.
GETBACK1                call CONVFST                    ; convert first name in (FCB).
                        ld a,(FCB+1)                    ; if this was just a drive change request,
                        sub ' '                         ; make sure it was valid.
                        ld hl,CHGDRV                    ;
                        or (hl)                         ;
                        jp nz,SYNERR                    ;
                        jp CMMND1                       ; ok, return to command level.
;
;   ccp stack area.
;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
CCPSTACK                equ $                           ; end of ccp stack area.
;
;   Batch (or SUBMIT) processing information storage.
;
BATCH                   db 0                            ; batch mode flag (0=not active).
BATCHFCB                db 0                            ;
                        db "$$$     SUB"                ;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
;
;   File control block setup by the CCP.
;
FCB                     db 0                            ;
                        db "           "                ;
                        db 0,0,0,0,0                    ;
                        db "           "                ;
                        db 0,0,0,0,0                    ;
RTNCODE                 db 0                            ; status returned from bdos call.
CDRIVE                  db 0                            ; currently active drive.
CHGDRV                  db 0                            ; change in drives flag (0=no change).
NBYTES                  dw 0                            ; byte counter used by TYPE.
;
;   Room for expansion?
;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0    ;
;
;   Note that the following six bytes must match those at
; (PATTRN1) or cp/m will HALT. Why?
;
PATTRN2                 db 0,22,0,0,0,0                 ; (* serial number bytes *).
;
; **************************************************************
; *
; *                    B D O S   E N T R Y
; *
; **************************************************************
;
FBASE                   jp FBASE1                       ;
;
;   Bdos error table.
;
BADSCTR                 dw ERROR1                       ; bad sector on read or write.
BADSLCT                 dw ERROR2                       ; bad disk select.
RODISK                  dw ERROR3                       ; disk is read only.
ROFILE                  dw ERROR4                       ; file is read only.
;
;   Entry into bdos. (DE) or (E) are the parameters passed. The
; function number desired is in register (C).
;
FBASE1                  ex de,hl                        ; save the (DE) parameters.
                        ld (PARAMS),hl                  ;
                        ex de,hl                        ;
                        ld a,e                          ; and save register (E) in particular.
                        ld (EPARAM),a                   ;
                        ld hl,0                         ;
                        ld (STATUS),hl                  ; clear return status.
                        add hl,sp                       ;
                        ld (USRSTACK),hl                ; save users stack pointer.
                        ld sp,STKAREA                   ; and set our own.
                        xor a                           ; clear auto select storage space.
                        ld (AUTOFLAG),a                 ;
                        ld (AUTO),a                     ;
                        ld hl,GOBACK                    ; set return address.
                        push hl                         ;
                        ld a,c                          ; get function number.
                        cp NFUNCTS                      ; valid function number?
                        ret nc                          ;
                        ld c,e                          ; keep single register function here.
                        ld hl,FUNCTNS                   ; now look thru the function table.
                        ld e,a                          ;
                        ld d,0                          ; (DE)=function number.
                        add hl,de                       ;
                        add hl,de                       ; (HL)=(start of table)+2*(function number).
                        ld e,(hl)                       ;
                        inc hl                          ;
                        ld d,(hl)                       ; now (DE)=address for this function.
                        ld hl,(PARAMS)                  ; retrieve parameters.
                        ex de,hl                        ; now (DE) has the original parameters.
                        jp (hl)                         ; execute desired function.
;
;   BDOS function jump table.
;
NFUNCTS                 equ 41                          ; number of functions in followin table.
;
FUNCTNS                 dw WBOOT,GETCON,OUTCON,GETRDR,PUNCH,LIST,DIRCIO,GETIOB;
                        dw SETIOB,PRTSTR,RDBUFF,GETCSTS,GETVER,RSTDSK,SETDSK,OPENFIL;
                        dw CLOSEFIL,GETFST,GETNXT,DELFILE,READSEQ,WRTSEQ,FCREATE;
                        dw RENFILE,GETLOG,GETCRNT,PUTDMA,GETALOC,WRTPRTD,GETROV,SETATTR;
                        dw GETPARM,GETUSER,RDRANDOM,WTRANDOM,FILESIZE,SETRAN,LOGOFF,RTN;
                        dw RTN,WTSPECL                  ;
;
;   Bdos error message section.
;
ERROR1                  ld hl,BADSEC                    ; bad sector message.
                        call PRTERR                     ; print it and get a 1 char responce.
                        cp CNTRLC                       ; re-boot request (control-c)?
                        jp z,0                          ; yes.
                        ret                             ; no, return to retry i/o function.
;
ERROR2                  ld hl,BADSEL                    ; bad drive selected.
                        jp ERROR5                       ;
;
ERROR3                  ld hl,DISKRO                    ; disk is read only.
                        jp ERROR5                       ;
;
ERROR4                  ld hl,FILERO                    ; file is read only.
;
ERROR5                  call PRTERR                     ;
                        jp 0                            ; always reboot on these errors.
;
BDOSERR                 db "Bdos Err On "               ;
BDOSDRV                 db " : $"                       ;
BADSEC                  db "Bad Sector$"                ;
BADSEL                  db "Select$"                    ;
FILERO                  db "File "                      ;
DISKRO                  db "R/O$"                       ;
;
;   Print bdos error message.
;
PRTERR                  push hl                         ; save second message pointer.
                        call OUTCRLF                    ; send (cr)(lf).
                        ld a,(ACTIVE)                   ; get active drive.
                        add a,'A'                       ; make ascii.
                        ld (BDOSDRV),a                  ; and put in message.
                        ld bc,BDOSERR                   ; and print it.
                        call PRTMESG                    ;
                        pop bc                          ; print second message line now.
                        call PRTMESG                    ;
;
;   Get an input character. We will check our 1 character
; buffer first. This may be set by the console status routine.
;
GETCHAR                 ld hl,CHARBUF                   ; check character buffer.
                        ld a,(hl)                       ; anything present already?
                        ld (hl),0                       ; ...either case clear it.
                        or a                            ;
                        ret nz                          ; yes, use it.
                        jp CONIN                        ; nope, go get a character responce.
;
;   Input and echo a character.
;
GETECHO                 call GETCHAR                    ; input a character.
                        call CHKCHAR                    ; carriage control?
                        ret c                           ; no, a regular control char so don't echo.
                        push af                         ; ok, save character now.
                        ld c,a                          ;
                        call OUTCON                     ; and echo it.
                        pop af                          ; get character and return.
                        ret                             ;
;
;   Check character in (A). Set the zero flag on a carriage
; control character and the carry flag on any other control
; character.
;
CHKCHAR                 cp CR                           ; check for carriage return, line feed, backspace,
                        ret z                           ; or a tab.
                        cp LF                           ;
                        ret z                           ;
                        cp TAB                          ;
                        ret z                           ;
                        cp cBS                          ;
                        ret z                           ;
                        cp ' '                          ; other control char? Set carry flag.
                        ret                             ;
;
;   Check the console during output. Halt on a control-s, then
; reboot on a control-c. If anything else is ready, clear the
; zero flag and return (the calling routine may want to do
; something).
;
CKCONSOL                ld a,(CHARBUF)                  ; check buffer.
                        or a                            ; if anything, just return without checking.
                        jp nz,CKCON2                    ;
                        call CONST                      ; nothing in buffer. Check console.
                        and $01                         ; look at bit 0.
                        ret z                           ; return if nothing.
                        call CONIN                      ; ok, get it.
                        cp CNTRLS                       ; if not control-s, return with zero cleared.
                        jp nz,CKCON1                    ;
                        call CONIN                      ; halt processing until another char
                        cp CNTRLC                       ; is typed. Control-c?
                        jp z,0                          ; yes, reboot now.
                        xor a                           ; no, just pretend nothing was ever ready.
                        ret                             ;
CKCON1                  ld (CHARBUF),a                  ; save character in buffer for later processing.
CKCON2                  ld a,1                          ; set (A) to non zero to mean something is ready.
                        ret                             ;
;
;   Output (C) to the screen. If the printer flip-flop flag
; is set, we will send character to printer also. The console
; will be checked in the process.
;
OUTCHAR                 ld a,(OUTFLAG)                  ; check output flag.
                        or a                            ; anything and we won't generate output.
                        jp nz,OUTCHR1                   ;
                        push bc                         ;
                        call CKCONSOL                   ; check console (we don't care whats there).
                        pop bc                          ;
                        push bc                         ;
                        call CONOUT                     ; output (C) to the screen.
                        pop bc                          ;
                        push bc                         ;
                        ld a,(PRTFLAG)                  ; check printer flip-flop flag.
                        or a                            ;
                        call nz,LIST                    ; print it also if non-zero.
                        pop bc                          ;
OUTCHR1                 ld a,c                          ; update cursors position.
                        ld hl,CURPOS                    ;
                        cp DEL                          ; rubouts don't do anything here.
                        ret z                           ;
                        inc (hl)                        ; bump line pointer.
                        cp ' '                          ; and return if a normal character.
                        ret nc                          ;
                        dec (hl)                        ; restore and check for the start of the line.
                        ld a,(hl)                       ;
                        or a                            ;
                        ret z                           ; ingnore control characters at the start of the line.
                        ld a,c                          ;
                        cp cBS                          ; is it a backspace?
                        jp nz,OUTCHR2                   ;
                        dec (hl)                        ; yes, backup pointer.
                        ret                             ;
OUTCHR2                 cp LF                           ; is it a line feed?
                        ret nz                          ; ignore anything else.
                        ld (hl),0                       ; reset pointer to start of line.
                        ret                             ;
;
;   Output (A) to the screen. If it is a control character
; (other than carriage control), use ^x format.
;
SHOWIT                  ld a,c                          ;
                        call CHKCHAR                    ; check character.
                        jp nc,OUTCON                    ; not a control, use normal output.
                        push af                         ;
                        ld c,'^'                        ; for a control character, preceed it with '^'.
                        call OUTCHAR                    ;
                        pop af                          ;
                        or '@'                          ; and then use the letter equivelant.
                        ld c,a                          ;
;
;   Function to output (C) to the console device and expand tabs
; if necessary.
;
OUTCON                  ld a,c                          ;
                        cp TAB                          ; is it a tab?
                        jp nz,OUTCHAR                   ; use regular output.
OUTCON1                 ld c,' '                        ; yes it is, use spaces instead.
                        call OUTCHAR                    ;
                        ld a,(CURPOS)                   ; go until the cursor is at a multiple of 8

                        and $07                         ; position.
                        jp nz,OUTCON1                   ;
                        ret                             ;
;
;   Echo a backspace character. Erase the prevoius character
; on the screen.
;
BACKUP                  call BACKUP1                    ; backup the screen 1 place.
                        ld c,' '                        ; then blank that character.
                        call CONOUT                     ;
BACKUP1                 ld c,cBS                        ; then back space once more.
                        jp CONOUT                       ;
;
;   Signal a deleted line. Print a '#' at the end and start
; over.
;
NEWLINE                 ld c,'#'                        ;
                        call OUTCHAR                    ; print this.
                        call OUTCRLF                    ; start new line.
NEWLN1                  ld a,(CURPOS)                   ; move the cursor to the starting position.
                        ld hl,STARTING                  ;
                        cp (hl)                         ;
                        ret nc                          ; there yet?
                        ld c,' '                        ;
                        call OUTCHAR                    ; nope, keep going.
                        jp NEWLN1                       ;
;
;   Output a (cr) (lf) to the console device (screen).
;
OUTCRLF                 ld c,CR                         ;
                        call OUTCHAR                    ;
                        ld c,LF                         ;
                        jp OUTCHAR                      ;
;
;   Print message pointed to by (BC). It will end with a '$'.
;
PRTMESG                 ld a,(bc)                       ; check for terminating character.
                        cp '$'                          ;
                        ret z                           ;
                        inc bc                          ;
                        push bc                         ; otherwise, bump pointer and print it.
                        ld c,a                          ;
                        call OUTCON                     ;
                        pop bc                          ;
                        jp PRTMESG                      ;
;
;   Function to execute a buffered read.
;
RDBUFF                  ld a,(CURPOS)                   ; use present location as starting one.
                        ld (STARTING),a                 ;
                        ld hl,(PARAMS)                  ; get the maximum buffer space.
                        ld c,(hl)                       ;
                        inc hl                          ; point to first available space.
                        push hl                         ; and save.
                        ld b,0                          ; keep a character count.
RDBUF1                  push bc                         ;
                        push hl                         ;
RDBUF2                  call GETCHAR                    ; get the next input character.
                        and $7F                         ; strip bit 7.
                        pop hl                          ; reset registers.
                        pop bc                          ;
                        cp CR                           ; en of the line?
                        jp z,RDBUF17                    ;
                        cp LF                           ;
                        jp z,RDBUF17                    ;
                        cp cBS                          ; how about a backspace?
                        jp nz,RDBUF3                    ;
                        ld a,b                          ; yes, but ignore at the beginning of the line.
                        or a                            ;
                        jp z,RDBUF1                     ;
                        dec b                           ; ok, update counter.
                        ld a,(CURPOS)                   ; if we backspace to the start of the line,
                        ld (OUTFLAG),a                  ; treat as a cancel (control-x).
                        jp RDBUF10                      ;
RDBUF3                  cp DEL                          ; user typed a rubout?
                        jp nz,RDBUF4                    ;
                        ld a,b                          ; ignore at the start of the line.
                        or a                            ;
                        jp z,RDBUF1                     ;
                        ld a,(hl)                       ; ok, echo the previous character.
                        dec b                           ; and reset pointers (counters).
                        dec hl                          ;
                        jp RDBUF15                      ;
RDBUF4                  cp CNTRLE                       ; physical end of line?
                        jp nz,RDBUF5                    ;
                        push bc                         ; yes, do it.
                        push hl                         ;
                        call OUTCRLF                    ;
                        xor a                           ; and update starting position.
                        ld (STARTING),a                 ;
                        jp RDBUF2                       ;
RDBUF5                  cp CNTRLP                       ; control-p?
                        jp nz,RDBUF6                    ;
                        push hl                         ; yes, flip the print flag filp-flop byte.
                        ld hl,PRTFLAG                   ;
                        ld a,1                          ; PRTFLAG=1-PRTFLAG
                        sub (hl)                        ;
                        ld (hl),a                       ;
                        pop hl                          ;
                        jp RDBUF1                       ;
RDBUF6                  cp CNTRLX                       ; control-x (cancel)?
                        jp nz,RDBUF8                    ;
                        pop hl                          ;
RDBUF7                  ld a,(STARTING)                 ; yes, backup the cursor to here.
                        ld hl,CURPOS                    ;
                        cp (hl)                         ;
                        jp nc,RDBUFF                    ; done yet?
                        dec (hl)                        ; no, decrement pointer and output back up one space.
                        call BACKUP                     ;
                        jp RDBUF7                       ;
RDBUF8                  cp CNTRLU                       ; cntrol-u (cancel line)?
                        jp nz,RDBUF9                    ;
                        call NEWLINE                    ; start a new line.
                        pop hl                          ;
                        jp RDBUFF                       ;
RDBUF9                  cp CNTRLR                       ; control-r?
                        jp nz,RDBUF14                   ;
RDBUF10                 push bc                         ; yes, start a new line and retype the old one.
                        call NEWLINE                    ;
                        pop bc                          ;
                        pop hl                          ;
                        push hl                         ;
                        push bc                         ;
RDBUF11                 ld a,b                          ; done whole line yet?
                        or a                            ;
                        jp z,RDBUF12                    ;
                        inc hl                          ; nope, get next character.
                        ld c,(hl)                       ;
                        dec b                           ; count it.
                        push bc                         ;
                        push hl                         ;
                        call SHOWIT                     ; and display it.
                        pop hl                          ;
                        pop bc                          ;
                        jp RDBUF11                      ;
RDBUF12                 push hl                         ; done with line. If we were displaying
                        ld a,(OUTFLAG)                  ; then update cursor position.
                        or a                            ;
                        jp z,RDBUF2                     ;
                        ld hl,CURPOS                    ; because this line is shorter, we must
                        sub (hl)                        ; back up the cursor (not the screen however)
                        ld (OUTFLAG),a                  ; some number of positions.
RDBUF13                 call BACKUP                     ; note that as long as (OUTFLAG) is non
                        ld hl,OUTFLAG                   ; zero, the screen will not be changed.
                        dec (hl)                        ;
                        jp nz,RDBUF13                   ;
                        jp RDBUF2                       ; now just get the next character.
;
;   Just a normal character, put this in our buffer and echo.
;
RDBUF14                 inc hl                          ;
                        ld (hl),a                       ; store character.
                        inc b                           ; and count it.
RDBUF15                 push bc                         ;
                        push hl                         ;
                        ld c,a                          ; echo it now.
                        call SHOWIT                     ;
                        pop hl                          ;
                        pop bc                          ;
                        ld a,(hl)                       ; was it an abort request?
                        cp CNTRLC                       ; control-c abort?
                        ld a,b                          ;
                        jp nz,RDBUF16                   ;
                        cp 1                            ; only if at start of line.
                        jp z,0                          ;
RDBUF16                 cp c                            ; nope, have we filled the buffer?
                        jp c,RDBUF1                     ;
RDBUF17                 pop hl                          ; yes end the line and return.
                        ld (hl),b                       ;
                        ld c,CR                         ;
                        jp OUTCHAR                      ; output (cr) and return.
;
;   Function to get a character from the console device.
;
GETCON                  call GETECHO                    ; get and echo.
                        jp SETSTAT                      ; save status and return.
;
;   Function to get a character from the tape reader device.
;
GETRDR                  call READER                     ; get a character from reader, set status and return.
                        jp SETSTAT                      ;
;
;  Function to perform direct console i/o. If (C) contains (FF)
; then this is an input request. If (C) contains (FE) then
; this is a status request. Otherwise we are to output (C).
;
DIRCIO                  ld a,c                          ; test for (FF).
                        inc a                           ;
                        jp z,DIRC1                      ;
                        inc a                           ; test for (FE).
                        jp z,CONST                      ;
                        jp CONOUT                       ; just output (C).
DIRC1                   call CONST                      ; this is an input request.
                        or a                            ;
                        jp z,GOBACK1                    ; not ready? Just return (directly).
                        call CONIN                      ; yes, get character.
                        jp SETSTAT                      ; set status and return.
;
;   Function to return the i/o byte.
;
GETIOB                  ld a,(IOBYTE)                   ;
                        jp SETSTAT                      ;
;
;   Function to set the i/o byte.
;
SETIOB                  ld hl,IOBYTE                    ;
                        ld (hl),c                       ;
                        ret                             ;
;
;   Function to print the character string pointed to by (DE)
; on the console device. The string ends with a '$'.
;
PRTSTR                  ex de,hl                        ;
                        ld c,l                          ;
                        ld b,h                          ; now (BC) points to it.
                        jp PRTMESG                      ;
;
;   Function to interigate the console device.
;
GETCSTS                 call CKCONSOL                   ;
;
;   Get here to set the status and return to the cleanup
; section. Then back to the user.
;
SETSTAT                 ld (STATUS),a                   ;
RTN                     ret                             ;
;
;   Set the status to 1 (read or write error code).
;
IOERR1                  ld a,1                          ;
                        jp SETSTAT                      ;
;
OUTFLAG                 db 0                            ; output flag (non zero means no output).
STARTING                db 2                            ; starting position for cursor.
CURPOS                  db 0                            ; cursor position (0=start of line).
PRTFLAG                 db 0                            ; printer flag (control-p toggle). List if non zero.
CHARBUF                 db 0                            ; single input character buffer.
;
;   Stack area for BDOS calls.
;
USRSTACK                dw 0                            ; save users stack pointer here.
;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
                        db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
STKAREA                 equ $                           ; end of stack area.
;
USERNO                  db 0                            ; current user number.
ACTIVE                  db 0                            ; currently active drive.
PARAMS                  dw 0                            ; save (DE) parameters here on entry.
STATUS                  dw 0                            ; status returned from bdos function.
;
;   Select error occured, jump to error routine.
;
SLCTERR                 ld hl,BADSLCT                   ;
;
;   Jump to (HL) indirectly.
;
JUMPHL                  ld e,(hl)                       ;
                        inc hl                          ;
                        ld d,(hl)                       ; now (DE) contain the desired address.
                        ex de,hl                        ;
                        jp (hl)                         ;
;
;   Block move. (DE) to (HL), (C) bytes total.
;
DE2HL                   inc c                           ; is count down to zero?
DE2HL1                  dec c                           ;
                        ret z                           ; yes, we are done.
                        ld a,(de)                       ; no, move one more byte.
                        ld (hl),a                       ;
                        inc de                          ;
                        inc hl                          ;
                        jp DE2HL1                       ; and repeat.
;
;   Select the desired drive.
;
SELECT                  ld a,(ACTIVE)                   ; get active disk.
                        ld c,a                          ;
                        call SELDSK                     ; select it.
                        ld a,h                          ; valid drive?
                        or l                            ; valid drive?
                        ret z                           ; return if not.
;
;   Here, the BIOS returned the address of the parameter block
; in (HL). We will extract the necessary pointers and save them.
;
                        ld e,(hl)                       ; yes, get address of translation table into (DE).
                        inc hl                          ;
                        ld d,(hl)                       ;
                        inc hl                          ;
                        ld (SCRATCH1),hl                ; save pointers to scratch areas.
                        inc hl                          ;
                        inc hl                          ;
                        ld (SCRATCH2),hl                ; ditto.
                        inc hl                          ;
                        inc hl                          ;
                        ld (SCRATCH3),hl                ; ditto.
                        inc hl                          ;
                        inc hl                          ;
                        ex de,hl                        ; now save the translation table address.
                        ld (XLATE),hl                   ;
                        ld hl,DIRBUF                    ; put the next 8 bytes here.
                        ld c,8                          ; they consist of the directory buffer
                        call DE2HL                      ; pointer, parameter block pointer,
                        ld hl,(DISKPB)                  ; check and allocation vectors.
                        ex de,hl                        ;
                        ld hl,SECTORS                   ; move parameter block into our ram.
                        ld c,15                         ; it is 15 bytes long.
                        call DE2HL                      ;
                        ld hl,(DSKSIZE)                 ; check disk size.
                        ld a,h                          ; more than 256 blocks on this?
                        ld hl,BIGDISK                   ;
                        ld (hl),$FF                     ; set to samll.
                        or a                            ;
                        jp z,SELECT1                    ;
                        ld (hl),0                       ; wrong, set to large.
SELECT1                 ld a,$FF                        ; clear the zero flag.
                        or a                            ;
                        ret                             ;
;
;   Routine to home the disk track head and clear pointers.
;
HOMEDRV                 call HOME                       ; home the head.
                        xor a                           ;
                        ld hl,(SCRATCH2)                ; set our track pointer also.
                        ld (hl),a                       ;
                        inc hl                          ;
                        ld (hl),a                       ;
                        ld hl,(SCRATCH3)                ; and our sector pointer.
                        ld (hl),a                       ;
                        inc hl                          ;
                        ld (hl),a                       ;
                        ret                             ;
;
;   Do the actual disk read and check the error return status.
;
DOREAD                  call READ                       ;
                        jp IORET                        ;
;
;   Do the actual disk write and handle any bios error.
;
DOWRITE                 call WRITE                      ;
IORET                   or a                            ;
                        ret z                           ; return unless an error occured.
                        ld hl,BADSCTR                   ; bad read/write on this sector.
                        jp JUMPHL                       ;
;
;   Routine to select the track and sector that the desired
; block number falls in.
;
TRKSEC                  ld hl,(FILEPOS)                 ; get position of last accessed file
                        ld c,2                          ; in directory and compute sector #.
                        call SHIFTR                     ; sector #=file-position/4.
                        ld (BLKNMBR),hl                 ; save this as the block number of interest.
                        ld (CKSUMTBL),hl                ; what's it doing here too?
;
;   if the sector number has already been set (BLKNMBR), enter
; at this point.
;
TRKSEC1                 ld hl,BLKNMBR                   ;
                        ld c,(hl)                       ; move sector number into (BC).
                        inc hl                          ;
                        ld b,(hl)                       ;
                        ld hl,(SCRATCH3)                ; get current sector number and
                        ld e,(hl)                       ; move this into (DE).
                        inc hl                          ;
                        ld d,(hl)                       ;
                        ld hl,(SCRATCH2)                ; get current track number.
                        ld a,(hl)                       ; and this into (HL).
                        inc hl                          ;
                        ld h,(hl)                       ;
                        ld l,a                          ;
TRKSEC2                 ld a,c                          ; is desired sector before current one?
                        sub e                           ;
                        ld a,b                          ;
                        sbc a,d                         ;
                        jp nc,TRKSEC3                   ;
                        push hl                         ; yes, decrement sectors by one track.
                        ld hl,(SECTORS)                 ; get sectors per track.
                        ld a,e                          ;
                        sub l                           ;
                        ld e,a                          ;
                        ld a,d                          ;
                        sbc a,h                         ;
                        ld d,a                          ; now we have backed up one full track.
                        pop hl                          ;
                        dec hl                          ; adjust track counter.
                        jp TRKSEC2                      ;
TRKSEC3                 push hl                         ; desired sector is after current one.
                        ld hl,(SECTORS)                 ; get sectors per track.
                        add hl,de                       ; bump sector pointer to next track.
                        jp c,TRKSEC4                    ;
                        ld a,c                          ; is desired sector now before current one?
                        sub l                           ;
                        ld a,b                          ;
                        sbc a,h                         ;
                        jp c,TRKSEC4                    ;
                        ex de,hl                        ; not yes, increment track counter
                        pop hl                          ; and continue until it is.
                        inc hl                          ;
                        jp TRKSEC3                      ;
;
;   here we have determined the track number that contains the
; desired sector.
;
TRKSEC4                 pop hl                          ; get track number (HL).
                        push bc                         ;
                        push de                         ;
                        push hl                         ;
                        ex de,hl                        ;
                        ld hl,(OFFSET)                  ; adjust for first track offset.
                        add hl,de                       ;
                        ld b,h                          ;
                        ld c,l                          ;
                        call SETTRK                     ; select this track.
                        pop de                          ; reset current track pointer.
                        ld hl,(SCRATCH2)                ;
                        ld (hl),e                       ;
                        inc hl                          ;
                        ld (hl),d                       ;
                        pop de                          ;
                        ld hl,(SCRATCH3)                ; reset the first sector on this track.
                        ld (hl),e                       ;
                        inc hl                          ;
                        ld (hl),d                       ;
                        pop bc                          ;
                        ld a,c                          ; now subtract the desired one.
                        sub e                           ; to make it relative (1-# sectors/track).
                        ld c,a                          ;
                        ld a,b                          ;
                        sbc a,d                         ;
                        ld b,a                          ;
                        ld hl,(XLATE)                   ; translate this sector according to this table.
                        ex de,hl                        ;
                        call SECTRN                     ; let the bios translate it.
                        ld c,l                          ;
                        ld b,h                          ;
                        jp SETSEC                       ; and select it.
;
;   Compute block number from record number (SAVNREC) and
; extent number (SAVEXT).
;
GETBLOCK                ld hl,BLKSHFT                   ; get logical to physical conversion.
                        ld c,(hl)                       ; note that this is base 2 log of ratio.
                        ld a,(SAVNREC)                  ; get record number.
GETBLK1                 or a                            ; compute (A)=(A)/2^BLKSHFT.
                        rra                             ;
                        dec c                           ;
                        jp nz,GETBLK1                   ;
                        ld b,a                          ; save result in (B).
                        ld a,8                          ;
                        sub (hl)                        ;
                        ld c,a                          ; compute (C)=8-BLKSHFT.
                        ld a,(SAVEXT)                   ;
GETBLK2                 dec c                           ; compute (A)=SAVEXT*2^(8-BLKSHFT).
                        jp z,GETBLK3                    ;
                        or a                            ;
                        rla                             ;
                        jp GETBLK2                      ;
GETBLK3                 add a,b                         ;
                        ret                             ;
;
;   Routine to extract the (BC) block byte from the fcb pointed
; to by (PARAMS). If this is a big-disk, then these are 16 bit
; block numbers, else they are 8 bit numbers.
; Number is returned in (HL).
;
EXTBLK                  ld hl,(PARAMS)                  ; get fcb address.
                        ld de,16                        ; block numbers start 16 bytes into fcb.
                        add hl,de                       ;
                        add hl,bc                       ;
                        ld a,(BIGDISK)                  ; are we using a big-disk?
                        or a                            ;
                        jp z,EXTBLK1                    ;
                        ld l,(hl)                       ; no, extract an 8 bit number from the fcb.
                        ld h,0                          ;
                        ret                             ;
EXTBLK1                 add hl,bc                       ; yes, extract a 16 bit number.
                        ld e,(hl)                       ;
                        inc hl                          ;
                        ld d,(hl)                       ;
                        ex de,hl                        ; return in (HL).
                        ret                             ;
;
;   Compute block number.
;
COMBLK                  call GETBLOCK                   ;
                        ld c,a                          ;
                        ld b,0                          ;
                        call EXTBLK                     ;
                        ld (BLKNMBR),hl                 ;
                        ret                             ;
;
;   Check for a zero block number (unused).
;
CHKBLK                  ld hl,(BLKNMBR)                 ;
                        ld a,l                          ; is it zero?
                        or h                            ;
                        ret                             ;
;
;   Adjust physical block (BLKNMBR) and convert to logical
; sector (LOGSECT). This is the starting sector of this block.
; The actual sector of interest is then added to this and the
; resulting sector number is stored back in (BLKNMBR). This
; will still have to be adjusted for the track number.
;
LOGICAL                 ld a,(BLKSHFT)                  ; get log2(physical/logical sectors).
                        ld hl,(BLKNMBR)                 ; get physical sector desired.
LOGICL1                 add hl,hl                       ; compute logical sector number.
                        dec a                           ; note logical sectors are 128 bytes long.
                        jp nz,LOGICL1                   ;
                        ld (LOGSECT),hl                 ; save logical sector.
                        ld a,(BLKMASK)                  ; get block mask.
                        ld c,a                          ;
                        ld a,(SAVNREC)                  ; get next sector to access.
                        and c                           ; extract the relative position within physical block.
                        or l                            ; and add it too logical sector.
                        ld l,a                          ;
                        ld (BLKNMBR),hl                 ; and store.
                        ret                             ;
;
;   Set (HL) to point to extent byte in fcb.
;
SETEXT                  ld hl,(PARAMS)                  ;
                        ld de,12                        ; it is the twelth byte.
                        add hl,de                       ;
                        ret                             ;
;
;   Set (HL) to point to record count byte in fcb and (DE) to
; next record number byte.
;
SETHLDE                 ld hl,(PARAMS)                  ;
                        ld de,15                        ; record count byte (#15).
                        add hl,de                       ;
                        ex de,hl                        ;
                        ld hl,17                        ; next record number (#32).
                        add hl,de                       ;
                        ret                             ;
;
;   Save current file data from fcb.
;
STRDATA                 call SETHLDE                    ;
                        ld a,(hl)                       ; get and store record count byte.
                        ld (SAVNREC),a                  ;
                        ex de,hl                        ;
                        ld a,(hl)                       ; get and store next record number byte.
                        ld (SAVNXT),a                   ;
                        call SETEXT                     ; point to extent byte.
                        ld a,(EXTMASK)                  ; get extent mask.
                        and (hl)                        ;
                        ld (SAVEXT),a                   ; and save extent here.
                        ret                             ;
;
;   Set the next record to access. If (MODE) is set to 2, then
; the last record byte (SAVNREC) has the correct number to access.
; For sequential access, (MODE) will be equal to 1.
;
SETNREC                 call SETHLDE                    ;
                        ld a,(MODE)                     ; get sequential flag (=1).
                        cp 2                            ; a 2 indicates that no adder is needed.
                        jp nz,STNREC1                   ;
                        xor a                           ; clear adder (random access?).
STNREC1                 ld c,a                          ;
                        ld a,(SAVNREC)                  ; get last record number.
                        add a,c                         ; increment record count.
                        ld (hl),a                       ; and set fcb's next record byte.
                        ex de,hl                        ;
                        ld a,(SAVNXT)                   ; get next record byte from storage.
                        ld (hl),a                       ; and put this into fcb as number of records used.
                        ret                             ;
;
;   Shift (HL) right (C) bits.
;
SHIFTR                  inc c                           ;
SHIFTR1                 dec c                           ;
                        ret z                           ;
                        ld a,h                          ;
                        or a                            ;
                        rra                             ;
                        ld h,a                          ;
                        ld a,l                          ;
                        rra                             ;
                        ld l,a                          ;
                        jp SHIFTR1                      ;
;
;   Compute the check-sum for the directory buffer. Return
; integer sum in (A).
;
CHECKSUM                ld c,128                        ; length of buffer.
                        ld hl,(DIRBUF)                  ; get its location.
                        xor a                           ; clear summation byte.
CHKSUM1                 add a,(hl)                      ; and compute sum ignoring carries.
                        inc hl                          ;
                        dec c                           ;
                        jp nz,CHKSUM1                   ;
                        ret                             ;
;
;   Shift (HL) left (C) bits.
;
SHIFTL                  inc c                           ;
SHIFTL1                 dec c                           ;
                        ret z                           ;
                        add hl,hl                       ; shift left 1 bit.
                        jp SHIFTL1                      ;
;
;   Routine to set a bit in a 16 bit value contained in (BC).
; The bit set depends on the current drive selection.
;
SETBIT                  push bc                         ; save 16 bit word.
                        ld a,(ACTIVE)                   ; get active drive.
                        ld c,a                          ;
                        ld hl,1                         ;
                        call SHIFTL                     ; shift bit 0 into place.
                        pop bc                          ; now 'or' this with the original word.
                        ld a,c                          ;
                        or l                            ;
                        ld l,a                          ; low byte done, do high byte.
                        ld a,b                          ;
                        or h                            ;
                        ld h,a                          ;
                        ret                             ;
;
;   Extract the write protect status bit for the current drive.
; The result is returned in (A), bit 0.
;
GETWPRT                 ld hl,(WRTPRT)                  ; get status bytes.
                        ld a,(ACTIVE)                   ; which drive is current?
                        ld c,a                          ;
                        call SHIFTR                     ; shift status such that bit 0 is the
                        ld a,l                          ; one of interest for this drive.
                        and $01                         ; and isolate it.
                        ret                             ;
;
;   Function to write protect the current disk.
;
WRTPRTD                 ld hl,WRTPRT                    ; point to status word.
                        ld c,(hl)                       ; set (BC) equal to the status.
                        inc hl                          ;
                        ld b,(hl)                       ;
                        call SETBIT                     ; and set this bit according to current drive.
                        ld (WRTPRT),hl                  ; then save.
                        ld hl,(DIRSIZE)                 ; now save directory size limit.
                        inc hl                          ; remember the last one.
                        ex de,hl                        ;
                        ld hl,(SCRATCH1)                ; and store it here.
                        ld (hl),e                       ; put low byte.
                        inc hl                          ;
                        ld (hl),d                       ; then high byte.
                        ret                             ;
;
;   Check for a read only file.
;
CHKROFL                 call FCB2HL                     ; set (HL) to file entry in directory buffer.
CKROF1                  ld de,9                         ; look at bit 7 of the ninth byte.
                        add hl,de                       ;
                        ld a,(hl)                       ;
                        rla                             ;
                        ret nc                          ; return if ok.
                        ld hl,ROFILE                    ; else, print error message and terminate.
                        jp JUMPHL                       ;
;
;   Check the write protect status of the active disk.
;
CHKWPRT                 call GETWPRT                    ;
                        ret z                           ; return if ok.
                        ld hl,RODISK                    ; else print message and terminate.
                        jp JUMPHL                       ;
;
;   Routine to set (HL) pointing to the proper entry in the
; directory buffer.
;
FCB2HL                  ld hl,(DIRBUF)                  ; get address of buffer.
                        ld a,(FCBPOS)                   ; relative position of file.
;
;   Routine to add (A) to (HL).
;
ADDA2HL                 add a,l                         ;
                        ld l,a                          ;
                        ret nc                          ;
                        inc h                           ; take care of any carry.
                        ret                             ;
;
;   Routine to get the 's2' byte from the fcb supplied in
; the initial parameter specification.
;
GETS2                   ld hl,(PARAMS)                  ; get address of fcb.
                        ld de,14                        ; relative position of 's2'.
                        add hl,de                       ;
                        ld a,(hl)                       ; extract this byte.
                        ret                             ;
;
;   Clear the 's2' byte in the fcb.
;
CLEARS2                 call GETS2                      ; this sets (HL) pointing to it.
                        ld (hl),0                       ; now clear it.
                        ret                             ;
;
;   Set bit 7 in the 's2' byte of the fcb.
;
SETS2B7                 call GETS2                      ; get the byte.
                        or $80                          ; and set bit 7.
                        ld (hl),a                       ; then store.
                        ret                             ;
;
;   Compare (FILEPOS) with (SCRATCH1) and set flags based on
; the difference. This checks to see if there are more file
; names in the directory. We are at (FILEPOS) and there are
; (SCRATCH1) of them to check.
;
MOREFLS                 ld hl,(FILEPOS)                 ; we are here.
                        ex de,hl                        ;
                        ld hl,(SCRATCH1)                ; and don't go past here.
                        ld a,e                          ; compute difference but don't keep.
                        sub (hl)                        ;
                        inc hl                          ;
                        ld a,d                          ;
                        sbc a,(hl)                      ; set carry if no more names.
                        ret                             ;
;
;   Call this routine to prevent (SCRATCH1) from being greater
; than (FILEPOS).
;
CHKNMBR                 call MOREFLS                    ; SCRATCH1 too big?
                        ret c                           ;
                        inc de                          ; yes, reset it to (FILEPOS).
                        ld (hl),d                       ;
                        dec hl                          ;
                        ld (hl),e                       ;
                        ret                             ;
;
;   Compute (HL)=(DE)-(HL)
;
SUBHL                   ld a,e                          ; compute difference.
                        sub l                           ;
                        ld l,a                          ; store low byte.
                        ld a,d                          ;
                        sbc a,h                         ;
                        ld h,a                          ; and then high byte.
                        ret                             ;
;
;   Set the directory checksum byte.
;
SETDIR                  ld c,$FF                        ;
;
;   Routine to set or compare the directory checksum byte. If
; (C)=0ffh, then this will set the checksum byte. Else the byte
; will be checked. If the check fails (the disk has been changed),
; then this disk will be write protected.
;
CHECKDIR                ld hl,(CKSUMTBL)                ;
                        ex de,hl                        ;
                        ld hl,(ALLOC1)                  ;
                        call SUBHL                      ;
                        ret nc                          ; ok if (CKSUMTBL) > (ALLOC1), so return.
                        push bc                         ;
                        call CHECKSUM                   ; else compute checksum.
                        ld hl,(CHKVECT)                 ; get address of checksum table.
                        ex de,hl                        ;
                        ld hl,(CKSUMTBL)                ;
                        add hl,de                       ; set (HL) to point to byte for this drive.
                        pop bc                          ;
                        inc c                           ; set or check ?
                        jp z,CHKDIR1                    ;
                        cp (hl)                         ; check them.
                        ret z                           ; return if they are the same.
                        call MOREFLS                    ; not the same, do we care?
                        ret nc                          ;
                        call WRTPRTD                    ; yes, mark this as write protected.
                        ret                             ;
CHKDIR1                 ld (hl),a                       ; just set the byte.
                        ret                             ;
;
;   Do a write to the directory of the current disk.
;
DIRWRITE                call SETDIR                     ; set checksum byte.
                        call DIRDMA                     ; set directory dma address.
                        ld c,1                          ; tell the bios to actually write.
                        call DOWRITE                    ; then do the write.
                        jp DEFDMA                       ;
;
;   Read from the directory.
;
DIRREAD                 call DIRDMA                     ; set the directory dma address.
                        call DOREAD                     ; and read it.
;
;   Routine to set the dma address to the users choice.
;
DEFDMA                  ld hl,USERDMA                   ; reset the default dma address and return.
                        jp DIRDMA1                      ;
;
;   Routine to set the dma address for directory work.
;
DIRDMA                  ld hl,DIRBUF                    ;
;
;   Set the dma address. On entry, (HL) points to
; word containing the desired dma address.
;
DIRDMA1                 ld c,(hl)                       ;
                        inc hl                          ;
                        ld b,(hl)                       ; setup (BC) and go to the bios to set it.
                        jp SETDMA                       ;
;
;   Move the directory buffer into user's dma space.
;
MOVEDIR                 ld hl,(DIRBUF)                  ; buffer is located here, and
                        ex de,hl                        ;
                        ld hl,(USERDMA)                 ; put it here.
                        ld c,128                        ; this is its length.
                        jp DE2HL                        ; move it now and return.
;
;   Check (FILEPOS) and set the zero flag if it equals 0ffffh.
;
CKFILPOS                ld hl,FILEPOS                   ;
                        ld a,(hl)                       ;
                        inc hl                          ;
                        cp (hl)                         ; are both bytes the same?
                        ret nz                          ;
                        inc a                           ; yes, but are they each 0ffh?
                        ret                             ;
;
;   Set location (FILEPOS) to 0ffffh.
;
STFILPOS                ld hl,$FFFF                     ;
                        ld (FILEPOS),hl                 ;
                        ret                             ;
;
;   Move on to the next file position within the current
; directory buffer. If no more exist, set pointer to 0ffffh
; and the calling routine will check for this. Enter with (C)
; equal to 0ffh to cause the checksum byte to be set, else we
; will check this disk and set write protect if checksums are
; not the same (applies only if another directory sector must
; be read).
;
NXENTRY                 ld hl,(DIRSIZE)                 ; get directory entry size limit.
                        ex de,hl                        ;
                        ld hl,(FILEPOS)                 ; get current count.
                        inc hl                          ; go on to the next one.
                        ld (FILEPOS),hl                 ;
                        call SUBHL                      ; (HL)=(DIRSIZE)-(FILEPOS)
                        jp nc,NXENT1                    ; is there more room left?
                        jp STFILPOS                     ; no. Set this flag and return.
NXENT1                  ld a,(FILEPOS)                  ; get file position within directory.
                        and $03                         ; only look within this sector (only 4 entries fit).
                        ld b,5                          ; convert to relative position (32 bytes each).
NXENT2                  add a,a                         ; note that this is not efficient code.
                        dec b                           ; 5 'ADD A's would be better.
                        jp nz,NXENT2                    ;
                        ld (FCBPOS),a                   ; save it as position of fcb.
                        or a                            ;
                        ret nz                          ; return if we are within buffer.
                        push bc                         ;
                        call TRKSEC                     ; we need the next directory sector.
                        call DIRREAD                    ;
                        pop bc                          ;
                        jp CHECKDIR                     ;
;
;   Routine to to get a bit from the disk space allocation
; map. It is returned in (A), bit position 0. On entry to here,
; set (BC) to the block number on the disk to check.
; On return, (D) will contain the original bit position for
; this block number and (HL) will point to the address for it.
;
CKBITMAP                ld a,c                          ; determine bit number of interest.
                        and $07                         ; compute (D)=(E)=(C and 7)+1.
                        inc a                           ;
                        ld e,a                          ; save particular bit number.
                        ld d,a                          ;
;
;   compute (BC)=(BC)/8.
;
                        ld a,c                          ;
                        rrca                            ; now shift right 3 bits.
                        rrca                            ;
                        rrca                            ;
                        and $1F                         ; and clear bits 7,6,5.
                        ld c,a                          ;
                        ld a,b                          ;
                        add a,a                         ; now shift (B) into bits 7,6,5.
                        add a,a                         ;
                        add a,a                         ;
                        add a,a                         ;
                        add a,a                         ;
                        or c                            ; and add in (C).
                        ld c,a                          ; ok, (C) ha been completed.
                        ld a,b                          ; is there a better way of doing this?
                        rrca                            ;
                        rrca                            ;
                        rrca                            ;
                        and $1F                         ;
                        ld b,a                          ; and now (B) is completed.
;
;   use this as an offset into the disk space allocation
; table.
;
                        ld hl,(ALOCVECT)                ;
                        add hl,bc                       ;
                        ld a,(hl)                       ; now get correct byte.
CKBMAP1                 rlca                            ; get correct bit into position 0.
                        dec e                           ;
                        jp nz,CKBMAP1                   ;
                        ret                             ;
;
;   Set or clear the bit map such that block number (BC) will be marked
; as used. On entry, if (E)=0 then this bit will be cleared, if it equals
; 1 then it will be set (don't use anyother values).
;
STBITMAP                push de                         ;
                        call CKBITMAP                   ; get the byte of interest.
                        and $FE                         ; clear the affected bit.
                        pop bc                          ;
                        or c                            ; and now set it acording to (C).
;
;  entry to restore the original bit position and then store
; in table. (A) contains the value, (D) contains the bit
; position (1-8), and (HL) points to the address within the
; space allocation table for this byte.
;
STBMAP1                 rrca                            ; restore original bit position.
                        dec d                           ;
                        jp nz,STBMAP1                   ;
                        ld (hl),a                       ; and store byte in table.
                        ret                             ;
;
;   Set/clear space used bits in allocation map for this file.
; On entry, (C)=1 to set the map and (C)=0 to clear it.
;
SETFILE                 call FCB2HL                     ; get address of fcb
                        ld de,16                        ;
                        add hl,de                       ; get to block number bytes.
                        push bc                         ;
                        ld c,17                         ; check all 17 bytes (max) of table.
SETFL1                  pop de                          ;
                        dec c                           ; done all bytes yet?
                        ret z                           ;
                        push de                         ;
                        ld a,(BIGDISK)                  ; check disk size for 16 bit block numbers.
                        or a                            ;
                        jp z,SETFL2                     ;
                        push bc                         ; only 8 bit numbers. set (BC) to this one.
                        push hl                         ;
                        ld c,(hl)                       ; get low byte from table, always
                        ld b,0                          ; set high byte to zero.
                        jp SETFL3                       ;
SETFL2                  dec c                           ; for 16 bit block numbers, adjust counter.
                        push bc                         ;
                        ld c,(hl)                       ; now get both the low and high bytes.
                        inc hl                          ;
                        ld b,(hl)                       ;
                        push hl                         ;
SETFL3                  ld a,c                          ; block used?
                        or b                            ;
                        jp z,SETFL4                     ;
                        ld hl,(DSKSIZE)                 ; is this block number within the
                        ld a,l                          ; space on the disk?
                        sub c                           ;
                        ld a,h                          ;
                        sbc a,b                         ;
                        call nc,STBITMAP                ; yes, set the proper bit.
SETFL4                  pop hl                          ; point to next block number in fcb.
                        inc hl                          ;
                        pop bc                          ;
                        jp SETFL1                       ;
;
;   Construct the space used allocation bit map for the active
; drive. If a file name starts with '$' and it is under the
; current user number, then (STATUS) is set to minus 1. Otherwise
; it is not set at all.
;
BitMAP                  ld hl,(DSKSIZE)                 ; compute size of allocation table.
                        ld c,3                          ;
                        call SHIFTR                     ; (HL)=(HL)/8.
                        inc hl                          ; at lease 1 byte.
                        ld b,h                          ;
                        ld c,l                          ; set (BC) to the allocation table length.
;
;   Initialize the bitmap for this drive. Right now, the first
; two bytes are specified by the disk parameter block. However
; a patch could be entered here if it were necessary to setup
; this table in a special mannor. For example, the bios could
; determine locations of 'bad blocks' and set them as already
; 'used' in the map.
;
                        ld hl,(ALOCVECT)                ; now zero out the table now.
BitMAP1                 ld (hl),0                       ;
                        inc hl                          ;
                        dec bc                          ;
                        ld a,b                          ;
                        or c                            ;
                        jp nz,BitMAP1                   ;
                        ld hl,(ALLOC0)                  ; get initial space used by directory.
                        ex de,hl                        ;
                        ld hl,(ALOCVECT)                ; and put this into map.
                        ld (hl),e                       ;
                        inc hl                          ;
                        ld (hl),d                       ;
;
;   End of initialization portion.
;
                        call HOMEDRV                    ; now home the drive.
                        ld hl,(SCRATCH1)                ;
                        ld (hl),3                       ; force next directory request to read
                        inc hl                          ; in a sector.
                        ld (hl),0                       ;
                        call STFILPOS                   ; clear initial file position also.
BitMAP2                 ld c,$FF                        ; read next file name in directory
                        call NXENTRY                    ; and set checksum byte.
                        call CKFILPOS                   ; is there another file?
                        ret z                           ;
                        call FCB2HL                     ; yes, get its address.
                        ld a,$E5                        ;
                        cp (hl)                         ; empty file entry?
                        jp z,BitMAP2                    ;
                        ld a,(USERNO)                   ; no, correct user number?
                        cp (hl)                         ;
                        jp nz,BitMAP3                   ;
                        inc hl                          ;
                        ld a,(hl)                       ; yes, does name start with a '$'?
                        sub '$'                         ;
                        jp nz,BitMAP3                   ;
                        dec a                           ; yes, set atatus to minus one.
                        ld (STATUS),a                   ;
BitMAP3                 ld c,1                          ; now set this file's space as used in bit map.
                        call SETFILE                    ;
                        call CHKNMBR                    ; keep (SCRATCH1) in bounds.
                        jp BitMAP2                      ;
;
;   Set the status (STATUS) and return.
;
STSTATUS                ld a,(FNDSTAT)                  ;
                        jp SETSTAT                      ;
;
;   Check extents in (A) and (C). Set the zero flag if they
; are the same. The number of 16k chunks of disk space that
; the directory extent covers is expressad is (EXTMASK+1).
; No registers are modified.
;
SAMEXT                  push bc                         ;
                        push af                         ;
                        ld a,(EXTMASK)                  ; get extent mask and use it to
                        cpl                             ; to compare both extent numbers.
                        ld b,a                          ; save resulting mask here.
                        ld a,c                          ; mask first extent and save in (C).
                        and b                           ;
                        ld c,a                          ;
                        pop af                          ; now mask second extent and compare
                        and b                           ; with the first one.
                        sub c                           ;
                        and $1F                         ; (* only check buts 0-4 *)
                        pop bc                          ; the zero flag is set if they are the same.
                        ret                             ; restore (BC) and return.
;
;   Search for the first occurence of a file name. On entry,
; register (C) should contain the number of bytes of the fcb
; that must match.
;
FINDFST                 ld a,$FF                        ;
                        ld (FNDSTAT),a                  ;
                        ld hl,COUNTER                   ; save character count.
                        ld (hl),c                       ;
                        ld hl,(PARAMS)                  ; get filename to match.
                        ld (SAVEFCB),hl                 ; and save.
                        call STFILPOS                   ; clear initial file position (set to 0ffffh).
                        call HOMEDRV                    ; home the drive.
;
;   Entry to locate the next occurence of a filename within the
; directory. The disk is not expected to have been changed. If
; it was, then it will be write protected.
;
FINDNXT                 ld c,0                          ; write protect the disk if changed.
                        call NXENTRY                    ; get next filename entry in directory.
                        call CKFILPOS                   ; is file position = 0ffffh?
                        jp z,FNDNXT6                    ; yes, exit now then.
                        ld hl,(SAVEFCB)                 ; set (DE) pointing to filename to match.
                        ex de,hl                        ;
                        ld a,(de)                       ;
                        cp $E5                          ; empty directory entry?
                        jp z,FNDNXT1                    ; (* are we trying to reserect erased entries? *)
                        push de                         ;
                        call MOREFLS                    ; more files in directory?
                        pop de                          ;
                        jp nc,FNDNXT6                   ; no more. Exit now.
FNDNXT1                 call FCB2HL                     ; get address of this fcb in directory.
                        ld a,(COUNTER)                  ; get number of bytes (characters) to check.
                        ld c,a                          ;
                        ld b,0                          ; initialize byte position counter.
FNDNXT2                 ld a,c                          ; are we done with the compare?
                        or a                            ;
                        jp z,FNDNXT5                    ;
                        ld a,(de)                       ; no, check next byte.
                        cp '?'                          ; don't care about this character?
                        jp z,FNDNXT4                    ;
                        ld a,b                          ; get bytes position in fcb.
                        cp 13                           ; don't care about the thirteenth byte either.
                        jp z,FNDNXT4                    ;
                        cp 12                           ; extent byte?
                        ld a,(de)                       ;
                        jp z,FNDNXT3                    ;
                        sub (hl)                        ; otherwise compare characters.
                        and $7F                         ;
                        jp nz,FINDNXT                   ; not the same, check next entry.
                        jp FNDNXT4                      ; so far so good, keep checking.
FNDNXT3                 push bc                         ; check the extent byte here.
                        ld c,(hl)                       ;
                        call SAMEXT                     ;
                        pop bc                          ;
                        jp nz,FINDNXT                   ; not the same, look some more.
;
;   So far the names compare. Bump pointers to the next byte
; and continue until all (C) characters have been checked.
;
FNDNXT4                 inc de                          ; bump pointers.
                        inc hl                          ;
                        inc b                           ;
                        dec c                           ; adjust character counter.
                        jp FNDNXT2                      ;
FNDNXT5                 ld a,(FILEPOS)                  ; return the position of this entry.
                        and $03                         ;
                        ld (STATUS),a                   ;
                        ld hl,FNDSTAT                   ;
                        ld a,(hl)                       ;
                        rla                             ;
                        ret nc                          ;
                        xor a                           ;
                        ld (hl),a                       ;
                        ret                             ;
;
;   Filename was not found. Set appropriate status.
;
FNDNXT6                 call STFILPOS                   ; set (FILEPOS) to 0ffffh.
                        ld a,$FF                        ; say not located.
                        jp SETSTAT                      ;
;
;   Erase files from the directory. Only the first byte of the
; fcb will be affected. It is set to (E5).
;
ERAFILE                 call CHKWPRT                    ; is disk write protected?
                        ld c,12                         ; only compare file names.
                        call FINDFST                    ; get first file name.
ERAFIL1                 call CKFILPOS                   ; any found?
                        ret z                           ; nope, we must be done.
                        call CHKROFL                    ; is file read only?
                        call FCB2HL                     ; nope, get address of fcb and
                        ld (hl),$E5                     ; set first byte to 'empty'.
                        ld c,0                          ; clear the space from the bit map.
                        call SETFILE                    ;
                        call DIRWRITE                   ; now write the directory sector back out.
                        call FINDNXT                    ; find the next file name.
                        jp ERAFIL1                      ; and repeat process.
;
;   Look through the space allocation map (bit map) for the
; next available block. Start searching at block number (BC-1).
; The search procedure is to look for an empty block that is
; before the starting block. If not empty, look at a later
; block number. In this way, we return the closest empty block
; on either side of the 'target' block number. This will speed
; access on random devices. For serial devices, this should be
; changed to look in the forward direction first and then start
; at the front and search some more.
;
;   On return, (DE)= block number that is empty and (HL) =0
; if no empty block was found.
;
FNDSPACE                ld d,b                          ; set (DE) as the block that is checked.
                        ld e,c                          ;
;
;   Look before target block. Registers (BC) are used as the lower
; pointer and (DE) as the upper pointer.
;
FNDSPA1                 ld a,c                          ; is block 0 specified?
                        or b                            ;
                        jp z,FNDSPA2                    ;
                        dec bc                          ; nope, check previous block.
                        push de                         ;
                        push bc                         ;
                        call CKBITMAP                   ;
                        rra                             ; is this block empty?
                        jp nc,FNDSPA3                   ; yes. use this.
;
;   Note that the above logic gets the first block that it finds
; that is empty. Thus a file could be written 'backward' making
; it very slow to access. This could be changed to look for the
; first empty block and then continue until the start of this
; empty space is located and then used that starting block.
; This should help speed up access to some files especially on
; a well used disk with lots of fairly small 'holes'.
;
                        pop bc                          ; nope, check some more.
                        pop de                          ;
;
;   Now look after target block.
;
FNDSPA2                 ld hl,(DSKSIZE)                 ; is block (DE) within disk limits?
                        ld a,e                          ;
                        sub l                           ;
                        ld a,d                          ;
                        sbc a,h                         ;
                        jp nc,FNDSPA4                   ;
                        inc de                          ; yes, move on to next one.
                        push bc                         ;
                        push de                         ;
                        ld b,d                          ;
                        ld c,e                          ;
                        call CKBITMAP                   ; check it.
                        rra                             ; empty?
                        jp nc,FNDSPA3                   ;
                        pop de                          ; nope, continue searching.
                        pop bc                          ;
                        jp FNDSPA1                      ;
;
;   Empty block found. Set it as used and return with (HL)
; pointing to it (true?).
;
FNDSPA3                 rla                             ; reset byte.
                        inc a                           ; and set bit 0.
                        call STBMAP1                    ; update bit map.
                        pop hl                          ; set return registers.
                        pop de                          ;
                        ret                             ;
;
;   Free block was not found. If (BC) is not zero, then we have
; not checked all of the disk space.
;
FNDSPA4                 ld a,c                          ;
                        or b                            ;
                        jp nz,FNDSPA1                   ;
                        ld hl,0                         ; set 'not found' status.
                        ret                             ;
;
;   Move a complete fcb entry into the directory and write it.
;
FCBSET                  ld c,0                          ;
                        ld e,32                         ; length of each entry.
;
;   Move (E) bytes from the fcb pointed to by (PARAMS) into
; fcb in directory starting at relative byte (C). This updated
; directory buffer is then written to the disk.
;
UPDATE                  push de                         ;
                        ld b,0                          ; set (BC) to relative byte position.
                        ld hl,(PARAMS)                  ; get address of fcb.
                        add hl,bc                       ; compute starting byte.
                        ex de,hl                        ;
                        call FCB2HL                     ; get address of fcb to update in directory.
                        pop bc                          ; set (C) to number of bytes to change.
                        call DE2HL                      ;
UPDATE1                 call TRKSEC                     ; determine the track and sector affected.
                        jp DIRWRITE                     ; then write this sector out.
;
;   Routine to change the name of all files on the disk with a
; specified name. The fcb contains the current name as the
; first 12 characters and the new name 16 bytes into the fcb.
;
CHGNAMES                call CHKWPRT                    ; check for a write protected disk.
                        ld c,12                         ; match first 12 bytes of fcb only.
                        call FINDFST                    ; get first name.
                        ld hl,(PARAMS)                  ; get address of fcb.
                        ld a,(hl)                       ; get user number.
                        ld de,16                        ; move over to desired name.
                        add hl,de                       ;
                        ld (hl),a                       ; keep same user number.
CHGNAM1                 call CKFILPOS                   ; any matching file found?
                        ret z                           ; no, we must be done.
                        call CHKROFL                    ; check for read only file.
                        ld c,16                         ; start 16 bytes into fcb.
                        ld e,12                         ; and update the first 12 bytes of directory.
                        call UPDATE                     ;
                        call FINDNXT                    ; get te next file name.
                        jp CHGNAM1                      ; and continue.
;
;   Update a files attributes. The procedure is to search for
; every file with the same name as shown in fcb (ignoring bit 7)
; and then to update it (which includes bit 7). No other changes
; are made.
;
SAVEATTR                ld c,12                         ; match first 12 bytes.
                        call FINDFST                    ; look for first filename.
SAVATR1                 call CKFILPOS                   ; was one found?
                        ret z                           ; nope, we must be done.
                        ld c,0                          ; yes, update the first 12 bytes now.
                        ld e,12                         ;
                        call UPDATE                     ; update filename and write directory.
                        call FINDNXT                    ; and get the next file.
                        jp SAVATR1                      ; then continue until done.
;
;  Open a file (name specified in fcb).
;
OPENIT                  ld c,15                         ; compare the first 15 bytes.
                        call FINDFST                    ; get the first one in directory.
                        call CKFILPOS                   ; any at all?
                        ret z                           ;
OPENIT1                 call SETEXT                     ; point to extent byte within users fcb.
                        ld a,(hl)                       ; and get it.
                        push af                         ; save it and address.
                        push hl                         ;
                        call FCB2HL                     ; point to fcb in directory.
                        ex de,hl                        ;
                        ld hl,(PARAMS)                  ; this is the users copy.
                        ld c,32                         ; move it into users space.
                        push de                         ;
                        call DE2HL                      ;
                        call SETS2B7                    ; set bit 7 in 's2' byte (unmodified).
                        pop de                          ; now get the extent byte from this fcb.
                        ld hl,12                        ;
                        add hl,de                       ;
                        ld c,(hl)                       ; into (C).
                        ld hl,15                        ; now get the record count byte into (B).
                        add hl,de                       ;
                        ld b,(hl)                       ;
                        pop hl                          ; keep the same extent as the user had originally.
                        pop af                          ;
                        ld (hl),a                       ;
                        ld a,c                          ; is it the same as in the directory fcb?
                        cp (hl)                         ;
                        ld a,b                          ; if yes, then use the same record count.
                        jp z,OPENIT2                    ;
                        ld a,0                          ; if the user specified an extent greater than
                        jp c,OPENIT2                    ; the one in the directory, then set record count to 0.
                        ld a,128                        ; otherwise set to maximum.
OPENIT2                 ld hl,(PARAMS)                  ; set record count in users fcb to (A).
                        ld de,15                        ;
                        add hl,de                       ; compute relative position.
                        ld (hl),a                       ; and set the record count.
                        ret                             ;
;
;   Move two bytes from (DE) to (HL) if (and only if) (HL)
; point to a zero value (16 bit).
;   Return with zero flag set it (DE) was moved. Registers (DE)
; and (HL) are not changed. However (A) is.
;
MOVEWORD                ld a,(hl)                       ; check for a zero word.
                        inc hl                          ;
                        or (hl)                         ; both bytes zero?
                        dec hl                          ;
                        ret nz                          ; nope, just return.
                        ld a,(de)                       ; yes, move two bytes from (DE) into
                        ld (hl),a                       ; this zero space.
                        inc de                          ;
                        inc hl                          ;
                        ld a,(de)                       ;
                        ld (hl),a                       ;
                        dec de                          ; don't disturb these registers.
                        dec hl                          ;
                        ret                             ;
;
;   Get here to close a file specified by (fcb).
;
CLOSEIT                 xor a                           ; clear status and file position bytes.
                        ld (STATUS),a                   ;
                        ld (FILEPOS),a                  ;
                        ld (FILEPOS+1),a                ;
                        call GETWPRT                    ; get write protect bit for this drive.
                        ret nz                          ; just return if it is set.
                        call GETS2                      ; else get the 's2' byte.
                        and $80                         ; and look at bit 7 (file unmodified?).
                        ret nz                          ; just return if set.
                        ld c,15                         ; else look up this file in directory.
                        call FINDFST                    ;
                        call CKFILPOS                   ; was it found?
                        ret z                           ; just return if not.
                        ld bc,16                        ; set (HL) pointing to records used section.
                        call FCB2HL                     ;
                        add hl,bc                       ;
                        ex de,hl                        ;
                        ld hl,(PARAMS)                  ; do the same for users specified fcb.
                        add hl,bc                       ;
                        ld c,16                         ; this many bytes are present in this extent.
CLOSEIT1                ld a,(BIGDISK)                  ; 8 or 16 bit record numbers?
                        or a                            ;
                        jp z,CLOSEIT4                   ;
                        ld a,(hl)                       ; just 8 bit. Get one from users fcb.
                        or a                            ;
                        ld a,(de)                       ; now get one from directory fcb.
                        jp nz,CLOSEIT2                  ;
                        ld (hl),a                       ; users byte was zero. Update from directory.
CLOSEIT2                or a                            ;
                        jp nz,CLOSEIT3                  ;
                        ld a,(hl)                       ; directories byte was zero, update from users fcb.
                        ld (de),a                       ;
CLOSEIT3                cp (hl)                         ; if neither one of these bytes were zero,
                        jp nz,CLOSEIT7                  ; then close error if they are not the same.
                        jp CLOSEIT5                     ; ok so far, get to next byte in fcbs.
CLOSEIT4                call MOVEWORD                   ; update users fcb if it is zero.
                        ex de,hl                        ;
                        call MOVEWORD                   ; update directories fcb if it is zero.
                        ex de,hl                        ;
                        ld a,(de)                       ; if these two values are no different,
                        cp (hl)                         ; then a close error occured.
                        jp nz,CLOSEIT7                  ;
                        inc de                          ; check second byte.
                        inc hl                          ;
                        ld a,(de)                       ;
                        cp (hl)                         ;
                        jp nz,CLOSEIT7                  ;
                        dec c                           ; remember 16 bit values.
CLOSEIT5                inc de                          ; bump to next item in table.
                        inc hl                          ;
                        dec c                           ; there are 16 entries only.
                        jp nz,CLOSEIT1                  ; continue if more to do.
                        ld bc,$FFEC                     ; backup 20 places (extent byte).
                        add hl,bc                       ;
                        ex de,hl                        ;
                        add hl,bc                       ;
                        ld a,(de)                       ;
                        cp (hl)                         ; directory's extent already greater than the
                        jp c,CLOSEIT6                   ; users extent?
                        ld (hl),a                       ; no, update directory extent.
                        ld bc,3                         ; and update the record count byte in
                        add hl,bc                       ; directories fcb.
                        ex de,hl                        ;
                        add hl,bc                       ;
                        ld a,(hl)                       ; get from user.
                        ld (de),a                       ; and put in directory.
CLOSEIT6                ld a,$FF                        ; set 'was open and is now closed' byte.
                        ld (CLOSEFLG),a                 ;
                        jp UPDATE1                      ; update the directory now.
CLOSEIT7                ld hl,STATUS                    ; set return status and then return.
                        dec (hl)                        ;
                        ret                             ;
;
;   Routine to get the next empty space in the directory. It
; will then be cleared for use.
;
GETEMPTY                call CHKWPRT                    ; make sure disk is not write protected.
                        ld hl,(PARAMS)                  ; save current parameters (fcb).
                        push hl                         ;
                        ld hl,EMPTYFCB                  ; use special one for empty space.
                        ld (PARAMS),hl                  ;
                        ld c,1                          ; search for first empty spot in directory.
                        call FINDFST                    ; (* only check first byte *)
                        call CKFILPOS                   ; none?
                        pop hl                          ;
                        ld (PARAMS),hl                  ; restore original fcb address.
                        ret z                           ; return if no more space.
                        ex de,hl                        ;
                        ld hl,15                        ; point to number of records for this file.
                        add hl,de                       ;
                        ld c,17                         ; and clear all of this space.
                        xor a                           ;
GETMT1                  ld (hl),a                       ;
                        inc hl                          ;
                        dec c                           ;
                        jp nz,GETMT1                    ;
                        ld hl,13                        ; clear the 's1' byte also.
                        add hl,de                       ;
                        ld (hl),a                       ;
                        call CHKNMBR                    ; keep (SCRATCH1) within bounds.
                        call FCBSET                     ; write out this fcb entry to directory.
                        jp SETS2B7                      ; set 's2' byte bit 7 (unmodified at present).
;
;   Routine to close the current extent and open the next one
; for reading.
;
GETNEXT                 xor a                           ;
                        ld (CLOSEFLG),a                 ; clear close flag.
                        call CLOSEIT                    ; close this extent.
                        call CKFILPOS                   ;
                        ret z                           ; not there???
                        ld hl,(PARAMS)                  ; get extent byte.
                        ld bc,12                        ;
                        add hl,bc                       ;
                        ld a,(hl)                       ; and increment it.
                        inc a                           ;
                        and $1F                         ; keep within range 0-31.
                        ld (hl),a                       ;
                        jp z,GTNEXT1                    ; overflow?
                        ld b,a                          ; mask extent byte.
                        ld a,(EXTMASK)                  ;
                        and b                           ;
                        ld hl,CLOSEFLG                  ; check close flag (0ffh is ok).
                        and (hl)                        ;
                        jp z,GTNEXT2                    ; if zero, we must read in next extent.
                        jp GTNEXT3                      ; else, it is already in memory.
GTNEXT1                 ld bc,2                         ; Point to the 's2' byte.
                        add hl,bc                       ;
                        inc (hl)                        ; and bump it.
                        ld a,(hl)                       ; too many extents?
                        and $0F                         ;
                        jp z,GTNEXT5                    ; yes, set error code.
;
;   Get here to open the next extent.
;
GTNEXT2                 ld c,15                         ; set to check first 15 bytes of fcb.
                        call FINDFST                    ; find the first one.
                        call CKFILPOS                   ; none available?
                        jp nz,GTNEXT3                   ;
                        ld a,(RDWRTFLG)                 ; no extent present. Can we open an empty one?
                        inc a                           ; 0ffh means reading (so not possible).
                        jp z,GTNEXT5                    ; or an error.
                        call GETEMPTY                   ; we are writing, get an empty entry.
                        call CKFILPOS                   ; none?
                        jp z,GTNEXT5                    ; error if true.
                        jp GTNEXT4                      ; else we are almost done.
GTNEXT3                 call OPENIT1                    ; open this extent.
GTNEXT4                 call STRDATA                    ; move in updated data (rec #, extent #, etc.)
                        xor a                           ; clear status and return.
                        jp SETSTAT                      ;
;
;   Error in extending the file. Too many extents were needed
; or not enough space on the disk.
;
GTNEXT5                 call IOERR1                     ; set error code, clear bit 7 of 's2'
                        jp SETS2B7                      ; so this is not written on a close.
;
;   Read a sequential file.
;
RDSEQ                   ld a,1                          ; set sequential access mode.
                        ld (MODE),a                     ;
RDSEQ1                  ld a,$FF                        ; don't allow reading unwritten space.
                        ld (RDWRTFLG),a                 ;
                        call STRDATA                    ; put rec# and ext# into fcb.
                        ld a,(SAVNREC)                  ; get next record to read.
                        ld hl,SAVNXT                    ; get number of records in extent.
                        cp (hl)                         ; within this extent?
                        jp c,RDSEQ2                     ;
                        cp 128                          ; no. Is this extent fully used?
                        jp nz,RDSEQ3                    ; no. End-of-file.
                        call GETNEXT                    ; yes, open the next one.
                        xor a                           ; reset next record to read.
                        ld (SAVNREC),a                  ;
                        ld a,(STATUS)                   ; check on open, successful?
                        or a                            ;
                        jp nz,RDSEQ3                    ; no, error.
RDSEQ2                  call COMBLK                     ; ok. compute block number to read.
                        call CHKBLK                     ; check it. Within bounds?
                        jp z,RDSEQ3                     ; no, error.
                        call LOGICAL                    ; convert (BLKNMBR) to logical sector (128 byte).
                        call TRKSEC1                    ; set the track and sector for this block #.
                        call DOREAD                     ; and read it.
                        jp SETNREC                      ; and set the next record to be accessed.
;
;   Read error occured. Set status and return.
;
RDSEQ3                  jp IOERR1                       ;
;
;   Write the next sequential record.
;
WTSEQ                   ld a,1                          ; set sequential access mode.
                        ld (MODE),a                     ;
WTSEQ1                  ld a,0                          ; allow an addition empty extent to be opened.
                        ld (RDWRTFLG),a                 ;
                        call CHKWPRT                    ; check write protect status.
                        ld hl,(PARAMS)                  ;
                        call CKROF1                     ; check for read only file, (HL) already set to fcb.
                        call STRDATA                    ; put updated data into fcb.
                        ld a,(SAVNREC)                  ; get record number to write.
                        cp 128                          ; within range?
                        jp nc,IOERR1                    ; no, error(?).
                        call COMBLK                     ; compute block number.
                        call CHKBLK                     ; check number.
                        ld c,0                          ; is there one to write to?
                        jp nz,WTSEQ6                    ; yes, go do it.
                        call GETBLOCK                   ; get next block number within fcb to use.
                        ld (RELBLOCK),a                 ; and save.
                        ld bc,0                         ; start looking for space from the start
                        or a                            ; if none allocated as yet.
                        jp z,WTSEQ2                     ;
                        ld c,a                          ; extract previous block number from fcb
                        dec bc                          ; so we can be closest to it.
                        call EXTBLK                     ;
                        ld b,h                          ;
                        ld c,l                          ;
WTSEQ2                  call FNDSPACE                   ; find the next empty block nearest number (BC).
                        ld a,l                          ; check for a zero number.
                        or h                            ;
                        jp nz,WTSEQ3                    ;
                        ld a,2                          ; no more space?
                        jp SETSTAT                      ;
WTSEQ3                  ld (BLKNMBR),hl                 ; save block number to access.
                        ex de,hl                        ; put block number into (DE).
                        ld hl,(PARAMS)                  ; now we must update the fcb for this
                        ld bc,16                        ; newly allocated block.
                        add hl,bc                       ;
                        ld a,(BIGDISK)                  ; 8 or 16 bit block numbers?
                        or a                            ;
                        ld a,(RELBLOCK)                 ; (* update this entry *)
                        jp z,WTSEQ4                     ; zero means 16 bit ones.
                        call ADDA2HL                    ; (HL)=(HL)+(A)
                        ld (hl),e                       ; store new block number.
                        jp WTSEQ5                       ;
WTSEQ4                  ld c,a                          ; compute spot in this 16 bit table.
                        ld b,0                          ;
                        add hl,bc                       ;
                        add hl,bc                       ;
                        ld (hl),e                       ; stuff block number (DE) there.
                        inc hl                          ;
                        ld (hl),d                       ;
WTSEQ5                  ld c,2                          ; set (C) to indicate writing to un-used disk space.
WTSEQ6                  ld a,(STATUS)                   ; are we ok so far?
                        or a                            ;
                        ret nz                          ;
                        push bc                         ; yes, save write flag for bios (register C).
                        call LOGICAL                    ; convert (BLKNMBR) over to loical sectors.
                        ld a,(MODE)                     ; get access mode flag (1=sequential,
                        dec a                           ; 0=random, 2=special?).
                        dec a                           ;
                        jp nz,WTSEQ9                    ;
;
;   Special random i/o from function #40. Maybe for M/PM, but the
; current block, if it has not been written to, will be zeroed
; out and then written (reason?).
;
                        pop bc                          ;
                        push bc                         ;
                        ld a,c                          ; get write status flag (2=writing unused space).
                        dec a                           ;
                        dec a                           ;
                        jp nz,WTSEQ9                    ;
                        push hl                         ;
                        ld hl,(DIRBUF)                  ; zero out the directory buffer.
                        ld d,a                          ; note that (A) is zero here.
WTSEQ7                  ld (hl),a                       ;
                        inc hl                          ;
                        inc d                           ; do 128 bytes.
                        jp p,WTSEQ7                     ;
                        call DIRDMA                     ; tell the bios the dma address for directory access.
                        ld hl,(LOGSECT)                 ; get sector that starts current block.
                        ld c,2                          ; set 'writing to unused space' flag.
WTSEQ8                  ld (BLKNMBR),hl                 ; save sector to write.
                        push bc                         ;
                        call TRKSEC1                    ; determine its track and sector numbers.
                        pop bc                          ;
                        call DOWRITE                    ; now write out 128 bytes of zeros.
                        ld hl,(BLKNMBR)                 ; get sector number.
                        ld c,0                          ; set normal write flag.
                        ld a,(BLKMASK)                  ; determine if we have written the entire
                        ld b,a                          ; physical block.
                        and l                           ;
                        cp b                            ;
                        inc hl                          ; prepare for the next one.
                        jp nz,WTSEQ8                    ; continue until (BLKMASK+1) sectors written.
                        pop hl                          ; reset next sector number.
                        ld (BLKNMBR),hl                 ;
                        call DEFDMA                     ; and reset dma address.
;
;   Normal disk write. Set the desired track and sector then
; do the actual write.
;
WTSEQ9                  call TRKSEC1                    ; determine track and sector for this write.
                        pop bc                          ; get write status flag.
                        push bc                         ;
                        call DOWRITE                    ; and write this out.
                        pop bc                          ;
                        ld a,(SAVNREC)                  ; get number of records in file.
                        ld hl,SAVNXT                    ; get last record written.
                        cp (hl)                         ;
                        jp c,WTSEQ10                    ;
                        ld (hl),a                       ; we have to update record count.
                        inc (hl)                        ;
                        ld c,2                          ;
;
; *   This area has been patched to correct disk update problem
; * when using blocking and de-blocking in the BIOS.
;
WTSEQ10                 nop                             ; was 'dcr c'
                        nop                             ; was 'dcr c'
                        ld hl,0                         ; was 'jnz wtseq99'
;
; *   End of patch.
;
                        push af                         ;
                        call GETS2                      ; set 'extent written to' flag.
                        and $7F                         ; (* clear bit 7 *)
                        ld (hl),a                       ;
                        pop af                          ; get record count for this extent.
WTSEQ99                 cp 127                          ; is it full?
                        jp nz,WTSEQ12                   ;
                        ld a,(MODE)                     ; yes, are we in sequential mode?
                        cp 1                            ;
                        jp nz,WTSEQ12                   ;
                        call SETNREC                    ; yes, set next record number.
                        call GETNEXT                    ; and get next empty space in directory.
                        ld hl,STATUS                    ; ok?
                        ld a,(hl)                       ;
                        or a                            ;
                        jp nz,WTSEQ11                   ;
                        dec a                           ; yes, set record count to -1.
                        ld (SAVNREC),a                  ;
WTSEQ11                 ld (hl),0                       ; clear status.
WTSEQ12                 jp SETNREC                      ; set next record to access.
;
;   For random i/o, set the fcb for the desired record number
; based on the 'r0,r1,r2' bytes. These bytes in the fcb are
; used as follows:
;
;       fcb+35            fcb+34            fcb+33
;  |     'r-2'      |      'r-1'      |      'r-0'     |
;  |7             0 | 7             0 | 7             0|
;  |0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0 | 0 0 0 0 0 0 0 0|
;  |    overflow   | | extra |  extent   |   record #  |
;  | ______________| |_extent|__number___|_____________|
;                     also 's2'
;
;   On entry, register (C) contains 0ffh if this is a read
; and thus we can not access unwritten disk space. Otherwise,
; another extent will be opened (for writing) if required.
;
POSITION                xor a                           ; set random i/o flag.
                        ld (MODE),a                     ;
;
;   Special entry (function #40). M/PM ?
;
POSITN1                 push bc                         ; save read/write flag.
                        ld hl,(PARAMS)                  ; get address of fcb.
                        ex de,hl                        ;
                        ld hl,33                        ; now get byte 'r0'.
                        add hl,de                       ;
                        ld a,(hl)                       ;
                        and $7F                         ; keep bits 0-6 for the record number to access.
                        push af                         ;
                        ld a,(hl)                       ; now get bit 7 of 'r0' and bits 0-3 of 'r1'.
                        rla                             ;
                        inc hl                          ;
                        ld a,(hl)                       ;
                        rla                             ;
                        and $1F                         ; and save this in bits 0-4 of (C).
                        ld c,a                          ; this is the extent byte.
                        ld a,(hl)                       ; now get the extra extent byte.
                        rra                             ;
                        rra                             ;
                        rra                             ;
                        rra                             ;
                        and $0F                         ;
                        ld b,a                          ; and save it in (B).
                        pop af                          ; get record number back to (A).
                        inc hl                          ; check overflow byte 'r2'.
                        ld l,(hl)                       ;
                        inc l                           ;
                        dec l                           ;
                        ld l,6                          ; prepare for error.
                        jp nz,POSITN5                   ; out of disk space error.
                        ld hl,32                        ; store record number into fcb.
                        add hl,de                       ;
                        ld (hl),a                       ;
                        ld hl,12                        ; and now check the extent byte.
                        add hl,de                       ;
                        ld a,c                          ;
                        sub (hl)                        ; same extent as before?
                        jp nz,POSITN2                   ;
                        ld hl,14                        ; yes, check extra extent byte 's2' also.
                        add hl,de                       ;
                        ld a,b                          ;
                        sub (hl)                        ;
                        and $7F                         ;
                        jp z,POSITN3                    ; same, we are almost done then.
;
;  Get here when another extent is required.
;
POSITN2                 push bc                         ;
                        push de                         ;
                        call CLOSEIT                    ; close current extent.
                        pop de                          ;
                        pop bc                          ;
                        ld l,3                          ; prepare for error.
                        ld a,(STATUS)                   ;
                        inc a                           ;
                        jp z,POSITN4                    ; close error.
                        ld hl,12                        ; put desired extent into fcb now.
                        add hl,de                       ;
                        ld (hl),c                       ;
                        ld hl,14                        ; and store extra extent byte 's2'.
                        add hl,de                       ;
                        ld (hl),b                       ;
                        call OPENIT                     ; try and get this extent.
                        ld a,(STATUS)                   ; was it there?
                        inc a                           ;
                        jp nz,POSITN3                   ;
                        pop bc                          ; no. can we create a new one (writing?).
                        push bc                         ;
                        ld l,4                          ; prepare for error.
                        inc c                           ;
                        jp z,POSITN4                    ; nope, reading unwritten space error.
                        call GETEMPTY                   ; yes we can, try to find space.
                        ld l,5                          ; prepare for error.
                        ld a,(STATUS)                   ;
                        inc a                           ;
                        jp z,POSITN4                    ; out of space?
;
;   Normal return location. Clear error code and return.
;
POSITN3                 pop bc                          ; restore stack.
                        xor a                           ; and clear error code byte.
                        jp SETSTAT                      ;
;
;   Error. Set the 's2' byte to indicate this (why?).
;
POSITN4                 push hl                         ;
                        call GETS2                      ;
                        ld (hl),$C0                     ;
                        pop hl                          ;
;
;   Return with error code (presently in L).
;
POSITN5                 pop bc                          ;
                        ld a,l                          ; get error code.
                        ld (STATUS),a                   ;
                        jp SETS2B7                      ;
;
;   Read a random record.
;
READRAN                 ld c,$FF                        ; set 'read' status.
                        call POSITION                   ; position the file to proper record.
                        call z,RDSEQ1                   ; and read it as usual (if no errors).
                        ret                             ;
;
;   Write to a random record.
;
WRITERAN                ld c,0                          ; set 'writing' flag.
                        call POSITION                   ; position the file to proper record.
                        call z,WTSEQ1                   ; and write as usual (if no errors).
                        ret                             ;
;
;   Compute the random record number. Enter with (HL) pointing
; to a fcb an (DE) contains a relative location of a record
; number. On exit, (C) contains the 'r0' byte, (B) the 'r1'
; byte, and (A) the 'r2' byte.
;
;   On return, the zero flag is set if the record is within
; bounds. Otherwise, an overflow occured.
;
COMPRAND                ex de,hl                        ; save fcb pointer in (DE).
                        add hl,de                       ; compute relative position of record #.
                        ld c,(hl)                       ; get record number into (BC).
                        ld b,0                          ;
                        ld hl,12                        ; now get extent.
                        add hl,de                       ;
                        ld a,(hl)                       ; compute (BC)=(record #)+(extent)*128.
                        rrca                            ; move lower bit into bit 7.
                        and $80                         ; and ignore all other bits.
                        add a,c                         ; add to our record number.
                        ld c,a                          ;
                        ld a,0                          ; take care of any carry.
                        adc a,b                         ;
                        ld b,a                          ;
                        ld a,(hl)                       ; now get the upper bits of extent into
                        rrca                            ; bit positions 0-3.
                        and $0F                         ; and ignore all others.
                        add a,b                         ; add this in to 'r1' byte.
                        ld b,a                          ;
                        ld hl,14                        ; get the 's2' byte (extra extent).
                        add hl,de                       ;
                        ld a,(hl)                       ;
                        add a,a                         ; and shift it left 4 bits (bits 4-7).
                        add a,a                         ;
                        add a,a                         ;
                        add a,a                         ;
                        push af                         ; save carry flag (bit 0 of flag byte).
                        add a,b                         ; now add extra extent into 'r1'.
                        ld b,a                          ;
                        push af                         ; and save carry (overflow byte 'r2').
                        pop hl                          ; bit 0 of (L) is the overflow indicator.
                        ld a,l                          ;
                        pop hl                          ; and same for first carry flag.
                        or l                            ; either one of these set?
                        and $01                         ; only check the carry flags.
                        ret                             ;
;
;   Routine to setup the fcb (bytes 'r0', 'r1', 'r2') to
; reflect the last record used for a random (or other) file.
; This reads the directory and looks at all extents computing
; the largerst record number for each and keeping the maximum
; value only. Then 'r0', 'r1', and 'r2' will reflect this
; maximum record number. This is used to compute the space used
; by a random file.
;
RANSIZE                 ld c,12                         ; look thru directory for first entry with
                        call FINDFST                    ; this name.
                        ld hl,(PARAMS)                  ; zero out the 'r0, r1, r2' bytes.
                        ld de,33                        ;
                        add hl,de                       ;
                        push hl                         ;
                        ld (hl),d                       ; note that (D)=0.
                        inc hl                          ;
                        ld (hl),d                       ;
                        inc hl                          ;
                        ld (hl),d                       ;
RANSIZ1                 call CKFILPOS                   ; is there an extent to process?
                        jp z,RANSIZ3                    ; no, we are done.
                        call FCB2HL                     ; set (HL) pointing to proper fcb in dir.
                        ld de,15                        ; point to last record in extent.
                        call COMPRAND                   ; and compute random parameters.
                        pop hl                          ;
                        push hl                         ; now check these values against those
                        ld e,a                          ; already in fcb.
                        ld a,c                          ; the carry flag will be set if those
                        sub (hl)                        ; in the fcb represent a larger size than
                        inc hl                          ; this extent does.
                        ld a,b                          ;
                        sbc a,(hl)                      ;
                        inc hl                          ;
                        ld a,e                          ;
                        sbc a,(hl)                      ;
                        jp c,RANSIZ2                    ;
                        ld (hl),e                       ; we found a larger (in size) extent.
                        dec hl                          ; stuff these values into fcb.
                        ld (hl),b                       ;
                        dec hl                          ;
                        ld (hl),c                       ;
RANSIZ2                 call FINDNXT                    ; now get the next extent.
                        jp RANSIZ1                      ; continue til all done.
RANSIZ3                 pop hl                          ; we are done, restore the stack and
                        ret                             ; return.
;
;   Function to return the random record position of a given
; file which has been read in sequential mode up to now.
;
SETRAN                  ld hl,(PARAMS)                  ; point to fcb.
                        ld de,32                        ; and to last used record.
                        call COMPRAND                   ; compute random position.
                        ld hl,33                        ; now stuff these values into fcb.
                        add hl,de                       ;
                        ld (hl),c                       ; move 'r0'.
                        inc hl                          ;
                        ld (hl),b                       ; and 'r1'.
                        inc hl                          ;
                        ld (hl),a                       ; and lastly 'r2'.
                        ret                             ;
;
;   This routine select the drive specified in (ACTIVE) and
; update the login vector and bitmap table if this drive was
; not already active.
;
LOGINDRV                ld hl,(LOGIN)                   ; get the login vector.
                        ld a,(ACTIVE)                   ; get the default drive.
                        ld c,a                          ;
                        call SHIFTR                     ; position active bit for this drive
                        push hl                         ; into bit 0.
                        ex de,hl                        ;
                        call SELECT                     ; select this drive.
                        pop hl                          ;
                        call z,SLCTERR                  ; valid drive?
                        ld a,l                          ; is this a newly activated drive?
                        rra                             ;
                        ret c                           ;
                        ld hl,(LOGIN)                   ; yes, update the login vector.
                        ld c,l                          ;
                        ld b,h                          ;
                        call SETBIT                     ;
                        ld (LOGIN),hl                   ; and save.
                        jp BitMAP                       ; now update the bitmap.
;
;   Function to set the active disk number.
;
SETDSK                  ld a,(EPARAM)                   ; get parameter passed and see if this
                        ld hl,ACTIVE                    ; represents a change in drives.
                        cp (hl)                         ;
                        ret z                           ;
                        ld (hl),a                       ; yes it does, log it in.
                        jp LOGINDRV                     ;
;
;   This is the 'auto disk select' routine. The firsst byte
; of the fcb is examined for a drive specification. If non
; zero then the drive will be selected and loged in.
;
AUTOSEL                 ld a,$FF                        ; say 'auto-select activated'.
                        ld (AUTO),a                     ;
                        ld hl,(PARAMS)                  ; get drive specified.
                        ld a,(hl)                       ;
                        and $1F                         ; look at lower 5 bits.
                        dec a                           ; adjust for (1=A, 2=B) etc.
                        ld (EPARAM),a                   ; and save for the select routine.
                        cp $1E                          ; check for 'no change' condition.
                        jp nc,AUTOSL1                   ; yes, don't change.
                        ld a,(ACTIVE)                   ; we must change, save currently active
                        ld (OLDDRV),a                   ; drive.
                        ld a,(hl)                       ; and save first byte of fcb also.
                        ld (AUTOFLAG),a                 ; this must be non-zero.
                        and $E0                         ; whats this for (bits 6,7 are used for
                        ld (hl),a                       ; something)?
                        call SETDSK                     ; select and log in this drive.
AUTOSL1                 ld a,(USERNO)                   ; move user number into fcb.
                        ld hl,(PARAMS)                  ; (* upper half of first byte *)
                        or (hl)                         ;
                        ld (hl),a                       ;
                        ret                             ; and return (all done).
;
;   Function to return the current cp/m version number.
;
GETVER                  ld a,$22                        ; version 2.2
                        jp SETSTAT                      ;
;
;   Function to reset the disk system.
;
RSTDSK                  ld hl,0                         ; clear write protect status and log
                        ld (WRTPRT),hl                  ; in vector.
                        ld (LOGIN),hl                   ;
                        xor a                           ; select drive 'A'.
                        ld (ACTIVE),a                   ;
                        ld hl,TBUFF                     ; setup default dma address.
                        ld (USERDMA),hl                 ;
                        call DEFDMA                     ;
                        jp LOGINDRV                     ; now log in drive 'A'.
;
;   Function to open a specified file.
;
OPENFIL                 call CLEARS2                    ; clear 's2' byte.
                        call AUTOSEL                    ; select proper disk.
                        jp OPENIT                       ; and open the file.
;
;   Function to close a specified file.
;
CLOSEFIL                call AUTOSEL                    ; select proper disk.
                        jp CLOSEIT                      ; and close the file.
;
;   Function to return the first occurence of a specified file
; name. If the first byte of the fcb is '?' then the name will
; not be checked (get the first entry no matter what).
;
GETFST                  ld c,0                          ; prepare for special search.
                        ex de,hl                        ;
                        ld a,(hl)                       ; is first byte a '?'?
                        cp '?'                          ;
                        jp z,GETFST1                    ; yes, just get very first entry (zero length match).
                        call SETEXT                     ; get the extension byte from fcb.
                        ld a,(hl)                       ; is it '?'? if yes, then we want
                        cp '?'                          ; an entry with a specific 's2' byte.
                        call nz,CLEARS2                 ; otherwise, look for a zero 's2' byte.
                        call AUTOSEL                    ; select proper drive.
                        ld c,15                         ; compare bytes 0-14 in fcb (12&13 excluded).
GETFST1                 call FINDFST                    ; find an entry and then move it into
                        jp MOVEDIR                      ; the users dma space.
;
;   Function to return the next occurence of a file name.
;
GETNXT                  ld hl,(SAVEFCB)                 ; restore pointers. note that no
                        ld (PARAMS),hl                  ; other dbos calls are allowed.
                        call AUTOSEL                    ; no error will be returned, but the
                        call FINDNXT                    ; results will be wrong.
                        jp MOVEDIR                      ;
;
;   Function to delete a file by name.
;
DELFILE                 call AUTOSEL                    ; select proper drive.
                        call ERAFILE                    ; erase the file.
                        jp STSTATUS                     ; set status and return.
;
;   Function to execute a sequential read of the specified
; record number.
;
READSEQ                 call AUTOSEL                    ; select proper drive then read.
                        jp RDSEQ                        ;
;
;   Function to write the net sequential record.
;
WRTSEQ                  call AUTOSEL                    ; select proper drive then write.
                        jp WTSEQ                        ;
;
;   Create a file function.
;
FCREATE                 call CLEARS2                    ; clear the 's2' byte on all creates.
                        call AUTOSEL                    ; select proper drive and get the next
                        jp GETEMPTY                     ; empty directory space.
;
;   Function to rename a file.
;
RENFILE                 call AUTOSEL                    ; select proper drive and then switch
                        call CHGNAMES                   ; file names.
                        jp STSTATUS                     ;
;
;   Function to return the login vector.
;
GETLOG                  ld hl,(LOGIN)                   ;
                        jp GETPRM1                      ;
;
;   Function to return the current disk assignment.
;
GETCRNT                 ld a,(ACTIVE)                   ;
                        jp SETSTAT                      ;
;
;   Function to set the dma address.
;
PUTDMA                  ex de,hl                        ;
                        ld (USERDMA),hl                 ; save in our space and then get to
                        jp DEFDMA                       ; the bios with this also.
;
;   Function to return the allocation vector.
;
GETALOC                 ld hl,(ALOCVECT)                ;
                        jp GETPRM1                      ;
;
;   Function to return the read-only status vector.
;
GETROV                  ld hl,(WRTPRT)                  ;
                        jp GETPRM1                      ;
;
;   Function to set the file attributes (read-only, system).
;
SETATTR                 call AUTOSEL                    ; select proper drive then save attributes.
                        call SAVEATTR                   ;
                        jp STSTATUS                     ;
;
;   Function to return the address of the disk parameter block
; for the current drive.
;
GETPARM                 ld hl,(DISKPB)                  ;
GETPRM1                 ld (STATUS),hl                  ;
                        ret                             ;
;
;   Function to get or set the user number. If (E) was (FF)
; then this is a request to return the current user number.
; Else set the user number from (E).
;
GETUSER                 ld a,(EPARAM)                   ; get parameter.
                        cp $FF                          ; get user number?
                        jp nz,SETUSER                   ;
                        ld a,(USERNO)                   ; yes, just do it.
                        jp SETSTAT                      ;
SETUSER                 and $1F                         ; no, we should set it instead. keep low
                        ld (USERNO),a                   ; bits (0-4) only.
                        ret                             ;
;
;   Function to read a random record from a file.
;
RDRANDOM                call AUTOSEL                    ; select proper drive and read.
                        jp READRAN                      ;
;
;   Function to compute the file size for random files.
;
WTRANDOM                call AUTOSEL                    ; select proper drive and write.
                        jp WRITERAN                     ;
;
;   Function to compute the size of a random file.
;
FILESIZE                call AUTOSEL                    ; select proper drive and check file length
                        jp RANSIZE                      ;
;
;   Function #37. This allows a program to log off any drives.
; On entry, set (DE) to contain a word with bits set for those
; drives that are to be logged off. The log-in vector and the
; write protect vector will be updated. This must be a M/PM
; special function.
;
LOGOFF                  ld hl,(PARAMS)                  ; get drives to log off.
                        ld a,l                          ; for each bit that is set, we want
                        cpl                             ; to clear that bit in (LOGIN)
                        ld e,a                          ; and (WRTPRT).
                        ld a,h                          ;
                        cpl                             ;
                        ld hl,(LOGIN)                   ; reset the login vector.
                        and h                           ;
                        ld d,a                          ;
                        ld a,l                          ;
                        and e                           ;
                        ld e,a                          ;
                        ld hl,(WRTPRT)                  ;
                        ex de,hl                        ;
                        ld (LOGIN),hl                   ; and save.
                        ld a,l                          ; now do the write protect vector.
                        and e                           ;
                        ld l,a                          ;
                        ld a,h                          ;
                        and d                           ;
                        ld h,a                          ;
                        ld (WRTPRT),hl                  ; and save. all done.
                        ret                             ;
;
;   Get here to return to the user.
;
GOBACK                  ld a,(AUTO)                     ; was auto select activated?
                        or a                            ;
                        jp z,GOBACK1                    ;
                        ld hl,(PARAMS)                  ; yes, but was a change made?
                        ld (hl),0                       ; (* reset first byte of fcb *)
                        ld a,(AUTOFLAG)                 ;
                        or a                            ;
                        jp z,GOBACK1                    ;
                        ld (hl),a                       ; yes, reset first byte properly.
                        ld a,(OLDDRV)                   ; and get the old drive and select it.
                        ld (EPARAM),a                   ;
                        call SETDSK                     ;
GOBACK1                 ld hl,(USRSTACK)                ; reset the users stack pointer.
                        ld sp,hl                        ;
                        ld hl,(STATUS)                  ; get return status.
                        ld a,l                          ; force version 1.4 compatability.
                        ld b,h                          ;
                        ret                             ; and go back to user.
;
;   Function #40. This is a special entry to do random i/o.
; For the case where we are writing to unused disk space, this
; space will be zeroed out first. This must be a M/PM special
; purpose function, because why would any normal program even
; care about the previous contents of a sector about to be
; written over.
;
WTSPECL                 call AUTOSEL                    ; select proper drive.
                        ld a,2                          ; use special write mode.
                        ld (MODE),a                     ;
                        ld c,0                          ; set write indicator.
                        call POSITN1                    ; position the file.
                        call z,WTSEQ1                   ; and write (if no errors).
                        ret                             ;
;
; **************************************************************
; *
; *     BDOS data storage pool.
; *
; **************************************************************
;
EMPTYFCB                db $E5                          ; empty directory segment indicator.
WRTPRT                  dw 0                            ; write protect status for all 16 drives.
LOGIN                   dw 0                            ; drive active word (1 bit per drive).
USERDMA                 dw $80                          ; user's dma address (defaults to 80h).
;
;   Scratch areas from parameter block.
;
SCRATCH1                dw 0                            ; relative position within dir segment for file (0-3).
SCRATCH2                dw 0                            ; last selected track number.
SCRATCH3                dw 0                            ; last selected sector number.
;
;   Disk storage areas from parameter block.
;
DIRBUF                  dw 0                            ; address of directory buffer to use.
DISKPB                  dw 0                            ; contains address of disk parameter block.
CHKVECT                 dw 0                            ; address of check vector.
ALOCVECT                dw 0                            ; address of allocation vector (bit map).
;
;   Parameter block returned from the bios.
;
SECTORS                 dw 0                            ; sectors per track from bios.
BLKSHFT                 db 0                            ; block shift.
BLKMASK                 db 0                            ; block mask.
EXTMASK                 db 0                            ; extent mask.
DSKSIZE                 dw 0                            ; disk size from bios (number of blocks-1).
DIRSIZE                 dw 0                            ; directory size.
ALLOC0                  dw 0                            ; storage for first bytes of bit map (dir space used).
ALLOC1                  dw 0                            ;
OFFSET                  dw 0                            ; first usable track number.
XLATE                   dw 0                            ; sector translation table address.
;
;
CLOSEFLG                db 0                            ; close flag (=0ffh is extent written ok).
RDWRTFLG                db 0                            ; read/write flag (0ffh=read, 0=write).
FNDSTAT                 db 0                            ; filename found status (0=found first entry).
MODE                    db 0                            ; I/o mode select (0=random, 1=sequential, 2=special random).
EPARAM                  db 0                            ; storage for register (E) on entry to bdos.
RELBLOCK                db 0                            ; relative position within fcb of block number written.
COUNTER                 db 0                            ; byte counter for directory name searches.
SAVEFCB                 dw 0,0                          ; save space for address of fcb (for directory searches).
BIGDISK                 db 0                            ; if =0 then disk is > 256 blocks long.
AUTO                    db 0                            ; if non-zero, then auto select activated.
OLDDRV                  db 0                            ; on auto select, storage for previous drive.
AUTOFLAG                db 0                            ; if non-zero, then auto select changed drives.
SAVNXT                  db 0                            ; storage for next record number to access.
SAVEXT                  db 0                            ; storage for extent number of file.
SAVNREC                 dw 0                            ; storage for number of records in file.
BLKNMBR                 dw 0                            ; block number (physical sector) used within a file or logical sect
LOGSECT                 dw 0                            ; starting logical (128 byte) sector of block (physical sector).
FCBPOS                  db 0                            ; relative position within buffer for fcb of file of interest.
FILEPOS                 dw 0                            ; files position within directory (0 to max entries -1).
;
;   Disk directory buffer checksum bytes. One for each of the
; 16 possible drives.
;
CKSUMTBL                db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0;
;
;   Extra space ?
;
                        db 0,0,0,0                      ;
;
; **************************************************************
; *
; *        B I O S   J U M P   T A B L E
; *
; **************************************************************
;
BOOT                    jp 0                            ; NOTE WE USE FAKE DESTINATIONS
WBOOT                   jp 0                            ;
CONST                   jp 0                            ;
CONIN                   jp 0                            ;
CONOUT                  jp 0                            ;
LIST                    jp 0                            ;
PUNCH                   jp 0                            ;
READER                  jp 0                            ;
HOME                    jp 0                            ;
SELDSK                  jp 0                            ;
SETTRK                  jp 0                            ;
SETSEC                  jp 0                            ;
SETDMA                  jp 0                            ;
READ                    jp 0                            ;
WRITE                   jp 0                            ;
PRSTAT                  jp 0                            ;
SECTRN                  jp 0                            ;
;
; *
; ******************   E N D   O F   C P / M   *****************
; *

