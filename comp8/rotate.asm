
;;
;;
;;

rotate_90_right:
    ld   c, 0                   ; i
loop_over_c:
    ld   b, 0                   ; j
    loop_over_b:
        ld   a, 15
        sub  b
        dec  a
        ld   l, a
        ld   h, c
        call atadd                  ; a := attr of ATTRS[l,h]

        ld   de, MAP_Y
        call SetElement             ; MAP_Y[c,b] := a

        inc  b
        ld   a, 16
        cp   b
        jr   nz, loop_over_b
    inc  c
    ld   a, 16
    cp   c
    jr   nz, loop_over_c

    ret

;ld a, 46
;loop1:
;   ld b, 64
;   loop2:
;      ld c, 64
;      loop3:
;      dec c
;      jnz c, loop3
;  dec b
;  jnz b, loop2
;dec a
;jnz a, loop1
;halt

; int[,] array = new int[4,4] {
;    { 1,2,3,4 },;
;    { 5,6,7,8 },
;    { 9,0,1,2 },
;    { 3,4,5,6 }
; };
;
; for (int i = 0; i < n; ++i) {
;        for (int j = 0; j < n; ++j) {
;            ret[i, j] = matrix[n - j - 1, i];
;        }
; }

;;
;; de is address of matrix
;; c is row
;; b is column
;; a is element value to be set
;;
;; matrix[c,b] := a
;;
SetElement:
    ld   l, c                   ;get row
    ld   h, 0
    add  hl, hl                 ; *2
    add  hl, hl                 ; *4
    add  hl, hl	                ; *8
    add  hl, hl                 ; *16 -> hl = c * 16
    add  hl, de	                ; add to matrix pointer
    ld   e, b	                ; get column
    ld   d, 0
    add  hl, de
    ld   (hl), a	            ; set element
    ret



MAP_Y
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
