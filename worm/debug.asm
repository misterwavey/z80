
DEBUG1
    ld a,22             ; AT code.
    rst 16
    ld a,1              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,69             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'1'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

DEBUG2
    ld a,22             ; AT code.
    rst 16
    ld a,1              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,69             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'2'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret
DEBUG3
    ld a,22             ; AT code.
    rst 16
    ld a,1              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,69             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'3'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret
DEBUG4
    ld a,22             ; AT code.
    rst 16
    ld a,1              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,69             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'4'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

DEBUGX
    ld a,22             ; AT code.
    rst 16
    ld a,2              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,70             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'X'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

DEBUGXN
    ld a,70             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,'X'            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

DEBUGXSP
    ld a,70             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,' '            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret

DEBUG_SPACE
    ld a,22             ; AT code.
    rst 16
    ld a,2              ; player vertical coord.
    rst 16              ; set vertical position of player.
    ld a,1                ; player's horizontal position.
    rst 16              ; set the horizontal coord.
    ld a,70             ; cyan ink (5) on black paper (0),
                        ; bright (64).
    ld (23695),a        ; set our temporary screen colours.
    ld a,' '            ; ASCII code for User Defined Graphic 'A'.
    rst 16              ; draw player.
    ret
