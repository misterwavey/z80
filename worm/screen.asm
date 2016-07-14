;;
;; get attribute address in de (attribute in a) given character position (x,y) in bc
;;

ATADD
    push hl
    ld a,(hl)           ; vertical coordinate.
    rrca                ; multiply by 32.
    rrca                ; Shifting right with carry 3 times is
    rrca                ; quicker than shifting left 5 times.
    ld e,a
    and 3
    add a,88            ; 88x256=address of attributes.
    ld d,a
    ld a,e
    and 224
    ld e,a
    inc hl
    ld a,(hl)              ; horizontal position.
    add a,e
    ld e,a              ; de=address of attributes.
    ld a,(de)           ; return with attribute in accumulator.
    pop hl
    ret

;; Interrogating the contents of the byte at hl will give the attribute's
;; value, while writing to the memory location at hl will change the colour
;; of the square.

;; To make sense of the result we have to know that each attribute is made up
;; of 8 bits which are arranged in this manner:

;; d0-d2		ink colour 0-7,			0=black, 1=blue, 2=red, 3=magenta,
;;						                4=green, 5=cyan, 6=yellow, 7=white
;; d3-d5		paper colour 0-7,		0=black, 1=blue, 2=red, 3=magenta,
;;						                4=green, 5=cyan, 6=yellow, 7=white
;; d6		    bright,	     			0=dull, 1=bright
;; d7		    flash,		     		0=stable, 1=flashing

;;The test for green paper for example, might involve

    ;    and 56              ; mask away all but paper bits.
    ;    cp 32               ; is it green(4) * 8?
    ;    jr z,green          ; yes, do green thing.

; while checking for yellow ink could be done like this
;
;        and 7               ; only want bits pertaining to ink.
;        cp 6                ; is it yellow (6)?
;        jr z,yellow         ; yes, do yellow wotsit.
