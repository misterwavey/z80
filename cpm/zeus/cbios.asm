;==================================================================================
; Contents of this file are copyright Grant Searle
;
; Modified (quickly and dirtily) to run under Zeus emulation by Crem.
;
; Blocking/unblocking routines are the published version by Digital Research
; (bugfixed, as found on the web)
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

bEmulatedUART           equ true                        ; Zeus is emulating a UART

CF_SIZE                 equ 64                          ; 64 or 128 MB

ccp                     equ   $D000                     ; Base of CCP.
bdos                    equ   ccp + $0806               ; Base of BDOS.
bios                    equ   ccp + $1600               ; Base of BIOS.

; Set CP/M low memory datA, vector and buffer addresses.

iobyte                  equ   $03                       ; Intel standard I/O definition byte.
userdrv                 equ   $04                       ; Current user number and drive.
tpabuf                  equ   $80                       ; Default I/O buffer and command line storage.

        if enabled bEmulatedUART
uartA_Status            equ 0
uartA_Data              equ 1
uartA_Control           equ 2
uartB_Status            equ 4
uartB_Data              equ 5
uartB_Control           equ 6
        else
SER_BUFSIZE             equ   60
SER_FULLSIZE            equ   50
SER_EMPTYSIZE           equ   5

RTS_HIGH                equ   $E8
RTS_LOW                 equ   $EA

SIOA_D                  equ   $00
SIOA_C                  equ   $02
SIOB_D                  equ   $01
SIOB_C                  equ   $03
        endif

int38                   equ   $38
nmi                     equ   $66

blksiz                  equ   4096                      ;CP/M allocation size
hstsiz                  equ   512                       ;host disk sector size
hstspt                  equ   32                        ;host disk sectors/trk
hstblk                  equ   hstsiz/128                ;CP/M sects/host buff
cpmspt                  equ   hstblk * hstspt           ;CP/M sectors/track
secmsk                  equ   hstblk-1                  ;sector mask
                        ;compute sector mask
;secshf         equ   2               ;log2(hstblk)

wrall                   equ   0                         ;write to allocated
wrdir                   equ   1                         ;write to directory
wrual                   equ   2                         ;write to unallocated

; CF registers
CF_DATA                 equ   $10
CF_FEATURES             equ   $11
CF_ERROR                equ   $11
CF_SECCOUNT             equ   $12
CF_SECTOR               equ   $13
CF_CYL_LOW              equ   $14
CF_CYL_HI               equ   $15
CF_HEAD                 equ   $16
CF_STATUS               equ   $17
CF_COMMAND              equ   $17
CF_LBA0                 equ   $13
CF_LBA1                 equ   $14
CF_LBA2                 equ   $15
CF_LBA3                 equ   $16

;CF Features
CF_8BIT                 equ   1
CF_NOCACHE              equ   $82
;CF Commands
CF_READ_SEC             equ   $20
CF_WRITE_SEC            equ   $30
CF_SET_FEAT             equ   $EF

LF                      equ   $0A                       ;line feed
FF                      equ   $0C                       ;form feed
CR                      equ   $0D                       ;carriage RETurn

;================================================================================================

;                import_bin "cpm22.bin",$D000

                        org    bios                     ; BIOS origin.

;================================================================================================
; BIOS jump table.
;================================================================================================
                        jp      boot                    ;  0 Initialize.
wboote:                 jp      wboot                   ;  1 Warm boot.
                        jp      const                   ;  2 Console status.
                        jp      conin                   ;  3 Console input.
                        jp      conout                  ;  4 Console OUTput.
                        jp      list                    ;  5 List OUTput.
                        jp      punch                   ;  6 punch OUTput.
                        jp      reader                  ;  7 Reader input.
                        jp      home                    ;  8 Home disk.
                        jp      seldsk                  ;  9 Select disk.
                        jp      settrk                  ; 10 Select track.
                        jp      setsec                  ; 11 Select sector.
                        jp      setdma                  ; 12 Set DMA ADDress.
                        jp      read                    ; 13 Read 128 bytes.
                        jp      write                   ; 14 Write 128 bytes.
                        jp      listst                  ; 15 List status.
                        jp      sectran                 ; 16 Sector translate.

;================================================================================================
; Disk parameter headers for disk 0 to 15
;================================================================================================
        if CF_SIZE = 64
dpbase                  dw $0000,$0000,$0000,$0000,dirbuf,dpb0,$0000,alv00
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv01
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv02
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv03
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv04
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv05
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv06
                        dw $0000,$0000,$0000,$0000,dirbuf,dpbLast,$0000,alv07
        elseif CF_SIZE = 128
dpbase                  dw $0000,$0000,$0000,$0000,dirbuf,dpb0,$0000,alv00
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv01
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv02
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv03
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv04
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv05
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv06
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv07
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv08
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv09
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv10
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv11
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv12
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv13
                        dw $0000,$0000,$0000,$0000,dirbuf,dpb,$0000,alv14
                        dw $0000,$0000,$0000,$0000,dirbuf,dpbLast,$0000,alv15
        else
                        zeusprint "CF_SIZE is invalid"
        endif

; First drive has a reserved track for CP/M
dpb0:
                        dw 128                          ;SPT - sectors per track
                        db 5                            ;BSH - block shift factor
                        db 31                           ;BLM - block mask
                        db 1                            ;EXM - Extent mask
                        dw 2043                         ; (2047-4) DSM - Storage size (blocks - 1)
                        dw 511                          ;DRM - Number of directory entries - 1
                        db 240                          ;AL0 - 1 bit set per directory block
                        db 0                            ;AL1 -            "
                        dw 0                            ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
                        dw 1                            ;OFF - Reserved tracks

dpb:
                        dw 128                          ;SPT - sectors per track
                        db 5                            ;BSH - block shift factor
                        db 31                           ;BLM - block mask
                        db 1                            ;EXM - Extent mask
                        dw 2047                         ;DSM - Storage size (blocks - 1)
                        dw 511                          ;DRM - Number of directory entries - 1
                        db 240                          ;AL0 - 1 bit set per directory block
                        db 0                            ;AL1 -            "
                        dw 0                            ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
                        dw 0                            ;OFF - Reserved tracks

; Last drive is smaller because CF is never full 64MB or 128MB
        if CF_SIZE = 64
dpbLast                 dw 128                          ;SPT - sectors per track
                        db 5                            ;BSH - block shift factor
                        db 31                           ;BLM - block mask
                        db 1                            ;EXM - Extent mask
                        dw 1279                         ;DSM - Storage size (blocks - 1)  ; 511 = 2MB (for 128MB card), 1279 = 5MB (for 64MB card)
                        dw 511                          ;DRM - Number of directory entries - 1
                        db 240                          ;AL0 - 1 bit set per directory block
                        db 0                            ;AL1 -            "
                        dw 0                            ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
                        dw 0                            ;OFF - Reserved tracks
        elseif CF_SIZE = 128
dpbLast                 dw 128                          ;SPT - sectors per track
                        db 5                            ;BSH - block shift factor
                        db 31                           ;BLM - block mask
                        db 1                            ;EXM - Extent mask
                        dw 511                          ;DSM - Storage size (blocks - 1)  ; 511 = 2MB (for 128MB card), 1279 = 5MB (for 64MB card)
                        dw 511                          ;DRM - Number of directory entries - 1
                        db 240                          ;AL0 - 1 bit set per directory block
                        db 0                            ;AL1 -            "
                        dw 0                            ;CKS - DIR check vector size (DRM+1)/4 (0=fixed disk)
                        dw 0                            ;OFF - Reserved tracks
        endif
;================================================================================================
; Cold boot
;================================================================================================

boot:
                        di                              ; Disable interrupts.
                        ld      sp,biosstack            ; Set default stack.

;               Turn off ROM

                        ld      a,$01                   ; Zeus emulates this correctly
                        out ($38),a                     ; (any out to $38..$3F kills the ROM)

;       Initialise SIO

        if enabled bEmulatedUART
        else
                        ld      a,$00
                        out     (SIOA_C),a
                        ld      a,$18
                        out     (SIOA_C),a

                        ld      a,$04
                        out     (SIOA_C),a
                        ld      a,$C4
                        out     (SIOA_C),a

                        ld      a,$01
                        out     (SIOA_C),a
                        ld      a,$18
                        out     (SIOA_C),a

                        ld      a,$03
                        out     (SIOA_C),a
                        ld      a,$E1
                        out     (SIOA_C),a

                        ld      a,$05
                        out     (SIOA_C),a
                        ld      a,RTS_LOW
                        out     (SIOA_C),a

                        ld      a,$00
                        out     (SIOB_C),a
                        ld      a,$18
                        out     (SIOB_C),a

                        ld      a,$04
                        out     (SIOB_C),a
                        ld      a,$C4
                        out     (SIOB_C),a

                        ld      a,$01
                        out     (SIOB_C),a
                        ld      a,$18
                        out     (SIOB_C),a

                        ld      a,$02
                        out     (SIOB_C),a
                        ld      a,$E0                   ; INTERRUPT VECTOR ADDRESS
                        out     (SIOB_C),a

                        ld      a,$03
                        out     (SIOB_C),a
                        ld      a,$E1
                        out     (SIOB_C),a

                        ld      a,$05
                        out     (SIOB_C),a
                        ld      a,RTS_LOW
                        out     (SIOB_C),a

                        ; Interrupt vector in page FF
                        ld      a,$FF
                        ld      i,a
        endif

                        call    printInline
                        noflow
                        db $1A
                        db "Z80 CP/M BIOS 1.0 by G. Searle 2007-13"
                        db CR,LF
                        db CR,LF
                        db "CP/M 2.2 "
                        db   "Copyright"
                        db   " 1979 (c) by Digital Research"
                        db CR,LF,0


                        call    cfWait
                        ld      a,CF_8BIT               ; Set IDE to be 8bit
                        out     (CF_FEATURES),a
                        ld      a,CF_SET_FEAT
                        out     (CF_COMMAND),a


                        call    cfWait
                        ld      a,CF_NOCACHE            ; No write cache
                        out     (CF_FEATURES),a
                        ld      a,CF_SET_FEAT
                        out     (CF_COMMAND),a

                        xor     a                               ; Clear I/O & drive bytes.
                        ld      (userdrv),a

        if not enabled bEmulatedUART
                        ld      (serABufUsed),a
                        ld      (serBBufUsed),a
                        ld      hl,serABuf
                        ld      (serAInPtr),hl
                        ld      (serARdPtr),hl

                        ld      hl,serBBuf
                        ld      (serBInPtr),hl
                        ld      (serBRdPtr),hl
        endif

                        jp      gocpm

;================================================================================================
; Warm boot
;================================================================================================

wboot:
                        di                              ; Disable interrupts.
                        ld      sp,biosstack            ; Set default stack.



                        ; Interrupt vector in page FF
                        ld      a,$FF
                        ld      i,a


                        ld      b,11                    ; Number of sectors to reload

                        ld      a,0
                        ld      (hstsec),a
                        ld      hl,ccp
rdSectors:

                        call    cfWait

                        ld      a,(hstsec)
                        out     (CF_LBA0),a
                        ld      a,0
                        out     (CF_LBA1),a
                        out     (CF_LBA2),a
                        ld      a,$E0
                        out     (CF_LBA3),a
                        ld      a,1
                        out     (CF_SECCOUNT),a

                        push    bc

                        call    cfWait

                        ld      a,CF_READ_SEC
                        out     (CF_COMMAND),a

                        call    cfWait

                        ld      c,4
rd4secs512:
                        ld      b,128
rdByte512:
                        in      a,(CF_DATA)
                        ld      (hl),a
                        inc     hl
                        dec     b
                        jr      nz, rdByte512
                        dec     c
                        jr      nz,rd4secs512

                        pop     bc

                        ld      a,(hstsec)
                        inc     a
                        ld      (hstsec),a

                        djnz    rdSectors


;================================================================================================
; Common code for cold and warm boot
;================================================================================================

gocpm:
                        xor     a                       ;0 to accumulator
                        ld      (hstact),a              ;host buffer inactive
                        ld      (unacnt),a              ;clear unalloc count

        if not enabled bEmulatedUART
                        ld      hl,serialInt            ; ADDress of serial interrupt.
                        ld      ($40),hl
        endif

                        ld      hl,tpabuf               ; ADDress of BIOS DMA buffer.
                        ld      (dmaAddr),hl
                        ld      a,$C3                   ; Opcode for 'JP'.
                        ld      ($00),a                 ; Load at start of RAM.
                        ld      hl,wboote               ; ADDress of jump for a warm boot.
                        ld      ($01),hl
                        ld      ($05),a                 ; Opcode for 'JP'.
                        ld      hl,bdos                 ; ADDress of jump for the BDOS.
                        ld      ($06),hl
                        ld      a,(userdrv)             ; Save new drive number (0).
                        ld      c,a                     ; Pass drive number in C.

        if not enabled bEmulatedUART
                        im      2
                        ei                              ; Enable interrupts
        endif
                        jp      ccp                     ; Start CP/M by jumping to the CCP.

;================================================================================================
; Console I/O routines
;================================================================================================

        if enabled bEmulatedUART

const:                  ld      a,(iobyte)
                        and     00001011B               ; Mask off console and high bit of reader
                        cp      00001010B               ; redirected to reader on UR1/2 (Serial A)
                        jr      z,constA
                        cp      00000010B               ; redirected to reader on TTY/RDR (Serial B)
                        jr      z,constB

                        and     $03                     ; remove the reader from the mask - only console bits then remain
                        cp      $01
                        jr      nz,constB
constA:
                        push    hl
                        in a,(uartA_Status)             ; Is there an Rx character waiting?
                        bit 0,a                         ;
                        jr      z, dataAEmpty
                        ld      a,$FF
                        pop     hl
                        ret
dataAEmpty:
                        ld      a,0
                        pop     hl
                        ret


constB:
                        push    hl
                        in a,(uartB_Status)             ; Is there an Rx character waiting?
                        bit 0,a                         ;
                        jr      z, dataBEmpty
                        ld      a,$FF
                        pop     hl
                        ret
dataBEmpty:
                        ld      a,0
                        pop     hl
                        ret

;------------------------------------------------------------------------------------------------
reader:
                        push    hl
                        push    af
reader2:                ld      a,(iobyte)
                        and     $08
                        cp      $08
                        jr      nz,coninB
                        jr      coninA
;------------------------------------------------------------------------------------------------
conin:
                        push    hl
                        push    af
                        ld      a,(iobyte)
                        and     $03
                        cp      $02
                        jr      z,reader2               ; "BAT:" redirect
                        cp      $01
                        jr      nz,coninB


coninA:
                        pop     af

                        ; Wait for a character on UART A

coninAlp                in a,(uartA_Status)             ; Is there one ready? Bit 0
                        bit 0,a                         ;
                        jr z coninAlp                   ; No, loop

                        in a,(uartA_Data)               ; Get it

                        pop     hl

                        ret                             ; Char ready in A


coninB:
                        pop     af
coninBlp                in a,(uartB_Status)             ; Is there one ready? Bit 0
                        bit 0,a                         ;
                        jr z coninBlp                   ; No, loop

                        in a,(uartB_Data)               ; Get it

                        pop     hl

                        ret                             ; Char ready in A

;------------------------------------------------------------------------------------------------
list:                   push    af                      ; Store character
list2:                  ld      a,(iobyte)
                        and     $C0
                        cp      $40
                        jr      nz,conoutB1
                        jr      conoutA1

;------------------------------------------------------------------------------------------------
punch:                  push    af                      ; Store character
                        ld      a,(iobyte)
                        and     $20
                        cp      $20
                        jr      nz,conoutB1
                        jr      conoutA1

;------------------------------------------------------------------------------------------------
conout:                 push    af                      ; Store character
                        ld      a,(iobyte)
                        and     $03
                        cp      $02
                        jr      z,list2                 ; "BAT:" redirect
                        cp      $01
                        jr      nz,conoutB1

conoutA1                in a,(uartA_Status)             ; Is the TX clear? Bit 1
                        bit 1,a                         ;
                        jr nz conoutA1                  ; No, loop

                        ld a,c                          ;
                        out (uartA_Data),a              ; Send it
                        pop af                          ; Restore
                        ret

conoutB1                in a,(uartB_Status)             ; Is the TX clear? Bit 1
                        bit 1,a                         ;
                        jr nz conoutB1                  ; No, loop

                        ld a,c                          ;
                        out (uartB_Data),a              ; Send it
                        pop af                          ; Restore
                        ret

;------------------------------------------------------------------------------------------------
listst:                 ld      a,$FF                   ; Return list status of 0xFF (ready).
                        ret

        else

serialInt:              push    af
                        push    hl

                        ; Check if there is a char in channel A
                        ; If not, there is a char in channel B
                        sub     a
                        out     (SIOA_C),a
                        in      a,(SIOA_C)              ; Status byte D2=TX Buff Empty, D0=RX char ready
                        rrca                            ; Rotates RX status into Carry Flag,
                        jr      nc, serialIntB

serialIntA:
                        ld      hl,(serAInPtr)
                        inc     hl
                        ld      a,l
                        cp      (serABuf+SER_BUFSIZE) & $FF
                        jr      nz, notAWrap
                        ld      hl,serABuf
notAWrap:
                        ld      (serAInPtr),hl
                        in      a,(SIOA_D)
                        ld      (hl),a

                        ld      a,(serABufUsed)
                        inc     a
                        ld      (serABufUsed),a
                        cp      SER_FULLSIZE
                        jr      c,rtsA0
                        ld      a,$05
                        out     (SIOA_C),a
                        ld      a,RTS_HIGH
                        out     (SIOA_C),a
rtsA0:
                        pop     hl
                        pop     af
                        ei
                        reti

serialIntB:
                        ld      hl,(serBInPtr)
                        inc     hl
                        ld      a,l
                        cp      (serBBuf+SER_BUFSIZE) & $FF
                        jr      nz, notBWrap
                        ld      hl,serBBuf
notBWrap:
                        ld      (serBInPtr),hl
                        in      a,(SIOB_D)
                        ld      (hl),a

                        ld      a,(serBBufUsed)
                        inc     a
                        ld      (serBBufUsed),a
                        cp      SER_FULLSIZE
                        jr      c,rtsB0
                        ld      a,$05
                        out     (SIOB_C),a
                        ld      a,RTS_HIGH
                        out     (SIOB_C),a
rtsB0:
                        pop     hl
                        pop     af
                        ei
                        reti

;------------------------------------------------------------------------------------------------
const:
                        ld      a,(iobyte)
                        and     00001011B               ; Mask off console and high bit of reader
                        cp      00001010B               ; redirected to reader on UR1/2 (Serial A)
                        jr      z,constA
                        cp      00000010B               ; redirected to reader on TTY/RDR (Serial B)
                        jr      z,constB

                        and     $03                     ; remove the reader from the mask - only console bits then remain
                        cp      $01
                        jr      nz,constB
constA:
                        push    hl
                        ld      a,(serABufUsed)
                        cp      $00
                        jr      z, dataAEmpty
                        ld      a,$FF
                        pop     hl
                        ret
dataAEmpty:
                        ld      a,0
                        pop     hl
                        ret


constB:
                        push    hl
                        ld      a,(serBBufUsed)
                        cp      $00
                        jr      z, dataBEmpty
                        ld      a,$FF
                        pop     hl
                        ret
dataBEmpty:
                        ld      a,0
                        pop     hl
                        ret

;------------------------------------------------------------------------------------------------
reader:
                        push    hl
                        push    af
reader2:                ld      a,(iobyte)
                        and     $08
                        cp      $08
                        jr      nz,coninB
                        jr      coninA
;------------------------------------------------------------------------------------------------
conin:
                        push    hl
                        push    af
                        ld      a,(iobyte)
                        and     $03
                        cp      $02
                        jr      z,reader2               ; "BAT:" redirect
                        cp      $01
                        jr      nz,coninB


coninA:
                        pop     af
waitForCharA:
                        ld      a,(serABufUsed)
                        cp      $00
                        jr      z, waitForCharA
                        ld      hl,(serARdPtr)
                        inc     hl
                        ld      a,l
                        cp      (serABuf+SER_BUFSIZE) & $FF
                        jr      nz, notRdWrapA
                        ld      hl,serABuf
notRdWrapA:
                        di
                        ld      (serARdPtr),hl

                        ld      a,(serABufUsed)
                        dec     a
                        ld      (serABufUsed),a

                        cp      SER_EMPTYSIZE
                        jr      nc,rtsA1
                        ld      a,$05
                        out     (SIOA_C),a
                        ld      a,RTS_LOW
                        out     (SIOA_C),a
rtsA1:
                        ld      a,(hl)
                        ei

                        pop     hl

                        ret                             ; Char ready in A


coninB:
                        pop     af
waitForCharB:
                        ld      a,(serBBufUsed)
                        cp      $00
                        jr      z, waitForCharB
                        ld      hl,(serBRdPtr)
                        inc     hl
                        ld      a,l
                        cp      (serBBuf+SER_BUFSIZE) & $FF
                        jr      nz, notRdWrapB
                        ld      hl,serBBuf
notRdWrapB:
                        di
                        ld      (serBRdPtr),hl

                        ld      a,(serBBufUsed)
                        dec     a
                        ld      (serBBufUsed),a

                        cp      SER_EMPTYSIZE
                        jr      nc,rtsB1
                        ld      a,$05
                        out     (SIOB_C),a
                        ld      a,RTS_LOW
                        out     (SIOB_C),a
rtsB1:
                        ld      a,(hl)
                        ei

                        pop     hl

                        ret                             ; Char ready in A

;------------------------------------------------------------------------------------------------
list:                   push    af                      ; Store character
list2:                  ld      a,(iobyte)
                        and     $C0
                        cp      $40
                        jr      nz,conoutB1
                        jr      conoutA1

;------------------------------------------------------------------------------------------------
punch:                  push    af                      ; Store character
                        ld      a,(iobyte)
                        and     $20
                        cp      $20
                        jr      nz,conoutB1
                        jr      conoutA1

;------------------------------------------------------------------------------------------------
conout:                 push    af                      ; Store character
                        ld      a,(iobyte)
                        and     $03
                        cp      $02
                        jr      z,list2                 ; "BAT:" redirect
                        cp      $01
                        jr      nz,conoutB1

conoutA1:               call    CKSIOA                  ; See if SIO channel B is finished transmitting
                        jr      z,conoutA1              ; Loop until SIO flag signals ready
                        ld      a,c
                        out     (SIOA_D),a              ; OUTput the character
                        pop     af                      ; RETrieve character
                        ret

conoutB1:               call    CKSIOB                  ; See if SIO channel B is finished transmitting
                        jr      z,conoutB1              ; Loop until SIO flag signals ready
                        ld      a,c
                        out     (SIOB_D),a              ; OUTput the character
                        pop     af                      ; RETrieve character
                        ret

;------------------------------------------------------------------------------------------------
CKSIOA                  sub     a
                        out     (SIOA_C),a
                        in      a,(SIOA_C)              ; Status byte D2=TX Buff Empty, D0=RX char ready
                        rrca                            ; Rotates RX status into Carry Flag,
                        bit     1,a                     ; Set Zero flag if still transmitting character
                        ret

CKSIOB                  sub     a
                        out     (SIOB_C),a
                        in      a,(SIOB_C)              ; Status byte D2=TX Buff Empty, D0=RX char ready
                        rrca                            ; Rotates RX status into Carry Flag,
                        bit     1,a                     ; Set Zero flag if still transmitting character
                        ret

;------------------------------------------------------------------------------------------------
listst:                 ld      a,$FF                   ; Return list status of 0xFF (ready).
                        ret
        endif

;================================================================================================
; Disk processing entry points
;================================================================================================

seldsk:
                        ld      hl,$0000
                        ld      a,c

        if CF_SIZE = 64
                        cp      8                       ; 16 for 128MB disk, 8 for 64MB disk
        elseif CF_SIZE = 128
                        cp      16                      ; 16 for 128MB disk, 8 for 64MB disk
        endif

                        jr      c,chgdsk                ; if invalid drive will give BDOS error
                        ld      a,(userdrv)             ; so set the drive back to a:
                        cp      c                       ; If the default disk is not the same as the
                        ret     nz                      ; selected drive then return,
                        xor     a                       ; else reset default back to a:
                        ld      (userdrv),a             ; otherwise will be stuck in a loop
                        ld      (sekdsk),a
                        ret

chgdsk:                 ld      (sekdsk),a
                        rlc     a                       ;*2
                        rlc     a                       ;*4
                        rlc     a                       ;*8
                        rlc     a                       ;*16
                        ld      hl,dpbase
                        ld      b,0
                        ld      c,a
                        add     hl,bc

                        ret

;------------------------------------------------------------------------------------------------
home:
                        ld      a,(hstwrt)              ;check for pending write
                        or      a
                        jr      nz,homed
                        ld      (hstact),a              ;clear host active flag
homed:
                        ld      bc,$0000

;------------------------------------------------------------------------------------------------
settrk:                 ld      (sektrk),bc             ; Set track passed from BDOS in register BC.
                        ret

;------------------------------------------------------------------------------------------------
setsec:                 ld      (seksec),bc             ; Set sector passed from BDOS in register BC.
                        ret

;------------------------------------------------------------------------------------------------
setdma:                 ld      (dmaAddr),bc            ; Set DMA ADDress given by registers BC.
                        ret

;------------------------------------------------------------------------------------------------
sectran:                push    bc
                        pop     hl
                        ret

;------------------------------------------------------------------------------------------------
read:
                        ;read the selected CP/M sector
                        xor     a
                        ld      (unacnt),a
                        ld      a,1
                        ld      (readop),a              ;read operation
                        ld      (rsflag),a              ;must read data
                        ld      a,wrual
                        ld      (wrtype),a              ;treat as unalloc
                        jp      rwoper                  ;to perform the read


;------------------------------------------------------------------------------------------------
write:
                        ;write the selected CP/M sector
                        xor     a                       ;0 to accumulator
                        ld      (readop),a              ;not a read operation
                        ld      a,c                     ;write type in c
                        ld      (wrtype),a
                        cp      wrual                   ;write unallocated?
                        jr      nz,chkuna               ;check for unalloc
;
;               write to unallocated, set parameters
                        ld      a,blksiz/128            ;next unalloc recs
                        ld      (unacnt),a
                        ld      a,(sekdsk)              ;disk to seek
                        ld      (unadsk),a              ;unadsk = sekdsk
                        ld      hl,(sektrk)
                        ld      (unatrk),hl             ;unatrk = sectrk
                        ld      a,(seksec)
                        ld      (unasec),a              ;unasec = seksec
;
chkuna:
;               check for write to unallocated sector
                        ld      a,(unacnt)              ;any unalloc remain?
                        or      a
                        jr      z,alloc                 ;skip if not
;
;               more unallocated records remain
                        dec     a                       ;unacnt = unacnt-1
                        ld      (unacnt),a
                        ld      a,(sekdsk)              ;same disk?
                        ld      hl,unadsk
                        cp      (hl)                    ;sekdsk = unadsk?
                        jp      nz,alloc                ;skip if not
;
;               disks are the same
                        ld      hl,unatrk
                        call    sektrkcmp               ;sektrk = unatrk?
                        jp      nz,alloc                ;skip if not
;
;               tracks are the same
                        ld      a,(seksec)              ;same sector?
                        ld      hl,unasec
                        cp      (hl)                    ;seksec = unasec?
                        jp      nz,alloc                ;skip if not
;
;               match, move to next sector for future ref
                        inc     (hl)                    ;unasec = unasec+1
                        ld      a,(hl)                  ;end of track?
                        cp      cpmspt                  ;count CP/M sectors
                        jr      c,noovf                 ;skip if no overflow
;
;               overflow to next track
                        ld      (hl),0                  ;unasec = 0
                        ld      hl,(unatrk)
                        inc     hl
                        ld      (unatrk),hl             ;unatrk = unatrk+1
;
noovf:
                        ;match found, mark as unnecessary read
                        xor     a                       ;0 to accumulator
                        ld      (rsflag),a              ;rsflag = 0
                        jr      rwoper                  ;to perform the write
;
alloc:
                        ;not an unallocated record, requires pre-read
                        xor     a                       ;0 to accum
                        ld      (unacnt),a              ;unacnt = 0
                        inc     a                       ;1 to accum
                        ld      (rsflag),a              ;rsflag = 1

;------------------------------------------------------------------------------------------------
rwoper:
                        ;enter here to perform the read/write
                        xor     a                       ;zero to accum
                        ld      (erflag),a              ;no errors (yet)
                        ld      a,(seksec)              ;compute host sector
                        or      a                       ;carry = 0
                        rra                             ;shift right
                        or      a                       ;carry = 0
                        rra                             ;shift right
                        ld      (sekhst),a              ;host sector to seek
;
;               active host sector?
                        ld      hl,hstact               ;host active flag
                        ld      a,(hl)
                        ld      (hl),1                  ;always becomes 1
                        or      a                       ;was it already?
                        jr      z,filhst                ;fill host if not
;
;               host buffer active, same as seek buffer?
                        ld      a,(sekdsk)
                        ld      hl,hstdsk               ;same disk?
                        cp      (hl)                    ;sekdsk = hstdsk?
                        jr      nz,nomatch
;
;               same disk, same track?
                        ld      hl,hsttrk
                        call    sektrkcmp               ;sektrk = hsttrk?
                        jr      nz,nomatch
;
;               same disk, same track, same buffer?
                        ld      a,(sekhst)
                        ld      hl,hstsec               ;sekhst = hstsec?
                        cp      (hl)
                        jr      z,match                 ;skip if match
;
nomatch:
                        ;proper disk, but not correct sector
                        ld      a,(hstwrt)              ;host written?
                        or      a
                        call    nz,writehst             ;clear host buff
;
filhst:
                        ;may have to fill the host buffer
                        ld      a,(sekdsk)
                        ld      (hstdsk),a
                        ld      hl,(sektrk)
                        ld      (hsttrk),hl
                        ld      a,(sekhst)
                        ld      (hstsec),a
                        ld      a,(rsflag)              ;need to read?
                        or      a
                        call    nz,readhst              ;yes, if 1
                        xor     a                       ;0 to accum
                        ld      (hstwrt),a              ;no pending write
;
match:
                        ;copy data to or from buffer
                        ld      a,(seksec)              ;mask buffer number
                        and     secmsk                  ;least signif bits
                        ld      l,a                     ;ready to shift
                        ld      h,0                     ;double count
                        add     hl,hl
                        add     hl,hl
                        add     hl,hl
                        add     hl,hl
                        add     hl,hl
                        add     hl,hl
                        add     hl,hl
;               hl has relative host buffer address
                        ld      de,hstbuf
                        add     hl,de                   ;hl = host address
                        ex      de,hl                   ;now in DE
                        ld      hl,(dmaAddr)            ;get/put CP/M data
                        ld      c,128                   ;length of move
                        ld      a,(readop)              ;which way?
                        or      a
                        jr      nz,rwmove               ;skip if read
;
;       write operation, mark and switch direction
                        ld      a,1
                        ld      (hstwrt),a              ;hstwrt = 1
                        ex      de,hl                   ;source/dest swap
;
rwmove:
                        ;C initially 128, DE is source, HL is dest
                        ld      a,(de)                  ;source character
                        inc     de
                        ld      (hl),a                  ;to dest
                        inc     hl
                        dec     c                       ;loop 128 times
                        jr      nz,rwmove
;
;               data has been moved to/from host buffer
                        ld      a,(wrtype)              ;write type
                        cp      wrdir                   ;to directory?
                        ld      a,(erflag)              ;in case of errors
                        ret     nz                      ;no further processing
;
;               clear host buffer for directory write
                        or      a                       ;errors?
                        ret     nz                      ;skip if so
                        xor     a                       ;0 to accum
                        ld      (hstwrt),a              ;buffer written
                        call    writehst
                        ld      a,(erflag)
                        ret

;------------------------------------------------------------------------------------------------
;Utility subroutine for 16-bit compare
sektrkcmp:
                        ;HL = .unatrk or .hsttrk, compare with sektrk
                        ex      de,hl
                        ld      hl,sektrk
                        ld      a,(de)                  ;low byte compare
                        cp      (hl)                    ;same?
                        ret     nz                      ;return if not
;               low bytes equal, test high 1s
                        inc     de
                        inc     hl
                        ld      a,(de)
                        cp      (hl)                    ;sets flags
                        ret

;================================================================================================
; Convert track/head/sector into LBA for physical access to the disk
;================================================================================================
setLBAaddr:
                        ld      hl,(hsttrk)
                        rlc     l
                        rlc     l
                        rlc     l
                        rlc     l
                        rlc     l
                        ld      a,l
                        and     $E0
                        ld      l,a
                        ld      a,(hstsec)
                        add     a,l
                        ld      (lba0),a

                        ld      hl,(hsttrk)
                        rrc     l
                        rrc     l
                        rrc     l
                        ld      a,l
                        and     $1F
                        ld      l,a
                        rlc     h
                        rlc     h
                        rlc     h
                        rlc     h
                        rlc     h
                        ld      a,h
                        and     $20
                        ld      h,a
                        ld      a,(hstdsk)
                        rlc     a
                        rlc     a
                        rlc     a
                        rlc     a
                        rlc     a
                        rlc     a
                        and     $C0
                        add     a,h
                        add     a,l
                        ld      (lba1),a


                        ld      a,(hstdsk)
                        rrc     a
                        rrc     a
                        and     $03
                        ld      (lba2),a

; LBA Mode using drive 0 = E0
                        ld      a,$E0
                        ld      (lba3),a


                        ld      a,(lba0)
                        out     (CF_LBA0),a

                        ld      a,(lba1)
                        out     (CF_LBA1),a

                        ld      a,(lba2)
                        out     (CF_LBA2),a

                        ld      a,(lba3)
                        out     (CF_LBA3),a

                        ld      a,1
                        out     (CF_SECCOUNT),a

                        ret

;================================================================================================
; Read physical sector from host
;================================================================================================

readhst:
                        push    af
                        push    bc
                        push    hl

                        call    cfWait

                        call    setLBAaddr

                        ld      a,CF_READ_SEC
                        out     (CF_COMMAND),a

                        call    cfWait

                        ld      c,4
                        ld      hl,hstbuf
rd4secs:
                        ld      b,128
rdByte:
                        in      a,(CF_DATA)
                        ld      (hl),a
                        inc     hl
                        dec     b
                        jr      nz, rdByte
                        dec     c
                        jr      nz,rd4secs

                        pop     hl
                        pop     bc
                        pop     af

                        xor     a
                        ld      (erflag),a
                        ret

;================================================================================================
; Write physical sector to host
;================================================================================================

writehst:
                        push    af
                        push    bc
                        push    hl


                        call    cfWait

                        call    setLBAaddr

                        ld      a,CF_WRITE_SEC
                        out     (CF_COMMAND),a

                        call    cfWait

                        ld      c,4
                        ld      hl,hstbuf
wr4secs:
                        ld      b,128
wrByte:                 ld      a,(hl)
                        out     (CF_DATA),a
                        inc     hl
                        dec     b
                        jr      nz, wrByte

                        dec     c
                        jr      nz,wr4secs

                        pop     hl
                        pop     bc
                        pop     af

                        xor     a
                        ld      (erflag),a
                        ret

;================================================================================================
; Wait for disk to be ready (busy=0,ready=1)
;================================================================================================
cfWait:
                        push    af
cfWait1:
                        in      a,(CF_STATUS)
                        and     $80
                        cp      $80
                        jr      z,cfWait1
                        pop     af
                        ret

;================================================================================================
; Utilities
;================================================================================================

printInline:
                        ex      (sp),hl                 ; PUSH HL and put RET ADDress into HL
                        push    af
                        push    bc
nextILChar:             ld      a,(hl)
                        cp      0
                        jr      z,endOfPrint
                        ld      c,a
                        call    conout                  ; Print to TTY
                        inc     hl
                        jr      nextILChar
endOfPrint:             inc     hl                      ; Get past "null" terminator
                        pop     bc
                        pop     af
                        ex      (sp),hl                 ; PUSH new RET ADDress on stack and restore HL
                        ret

;================================================================================================
; Data storage
;================================================================================================

dirbuf:                 ds 128                          ;scratch directory area
alv00:                  ds 257                          ;allocation vector 0
alv01:                  ds 257                          ;allocation vector 1
alv02:                  ds 257                          ;allocation vector 2
alv03:                  ds 257                          ;allocation vector 3
alv04:                  ds 257                          ;allocation vector 4
alv05:                  ds 257                          ;allocation vector 5
alv06:                  ds 257                          ;allocation vector 6
alv07:                  ds 257                          ;allocation vector 7
        if CF_SIZE = 128
alv08:                  ds 257                          ;allocation vector 8
alv09:                  ds 257                          ;allocation vector 9
alv10:                  ds 257                          ;allocation vector 10
alv11:                  ds 257                          ;allocation vector 11
alv12:                  ds 257                          ;allocation vector 12
alv13:                  ds 257                          ;allocation vector 13
alv14:                  ds 257                          ;allocation vector 14
alv15:                  ds 257                          ;allocation vector 15
        endif

lba0                    db     $00
lba1                    db     $00
lba2                    db     $00
lba3                    db     $00

                        ds     $20                      ; Start of BIOS stack area.
biosstack               equ   *

sekdsk:                 ds     1                        ;seek disk number
sektrk:                 ds     2                        ;seek track number
seksec:                 ds     2                        ;seek sector number
;
hstdsk:                 ds     1                        ;host disk number
hsttrk:                 ds     2                        ;host track number
hstsec:                 ds     1                        ;host sector number
;
sekhst:                 ds     1                        ;seek shr secshf
hstact:                 ds     1                        ;host active flag
hstwrt:                 ds     1                        ;host written flag
;
unacnt:                 ds     1                        ;unalloc rec cnt
unadsk:                 ds     1                        ;last unalloc disk
unatrk:                 ds     2                        ;last unalloc track
unasec:                 ds     1                        ;last unalloc sector
;
erflag:                 ds     1                        ;error reporting
rsflag:                 ds     1                        ;read sector flag
readop:                 ds     1                        ;1 if read operation
wrtype:                 ds     1                        ;write operation type
dmaAddr:                ds     2                        ;last dma address
hstbuf:                 ds     512                      ;host buffer

hstBufEnd               equ   *

        if not enabled bEmulatedUART
serABuf:                ds     SER_BUFSIZE              ; SIO A Serial buffer
serAInPtr               dw     $00
serARdPtr               dw     $00
serABufUsed             db     $00
serBBuf:                ds     SER_BUFSIZE              ; SIO B Serial buffer
serBInPtr               dw     $00
serBRdPtr               dw     $00
serBBufUsed             db     $00

serialVarsEnd           equ   *
        endif


biosEnd                 equ   *

; Disable the ROM, pop the active IO port from the stack (supplied by monitor),
; then start CP/M
popAndRun:
                        ld      a,$01                   ; Disable the ROM
                        out     ($38),a                 ;

                        pop     af
                        cp      $01
                        jr      z,consoleAtB
RawCPMBoot              ld      a,$01                   ;(List is TTY:, Punch is TTY:, Reader is TTY:, Console is CRT:)
                        jr      setIOByte
consoleAtB:             ld      a,$00                   ;(List is TTY:, Punch is TTY:, Reader is TTY:, Console is TTY:)
setIOByte:              ld (iobyte),a
                        jp      bios

;       IM 2 lookup for serial interrupt

        if not enabled bEmulatedUART
                        org    $FFE0
                        dw     serialInt
        endif

;=================================================================================
; Relocate TPA area from 4100 to 0100 then start CP/M
; Used to manually transfer a loaded program after CP/M was previously loaded
;=================================================================================

                        org    $FFE8
                        ld      a,$01
                        out     ($38),a

                        ld      hl,$4100
                        ld      de,$0100
                        ld      bc,$8F00
                        ldir
                        jp      bios

;=================================================================================
; Normal start CP/M vector
;=================================================================================

                        org $FFFE
                        dw     popAndRun

