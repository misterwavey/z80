;;
;; rotate top leftmost 16x16 attrs into
;; a copy matrix by 90 degrees to right
;;

; int[,] array = new int[4,4] {
;    { 1,2,3,4 },
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
;
; left: = matrix[j][n - i - 1];

rotate_90_right:
    ld   c, 0                   ; i
loop_over_c_r:
    ld   b, 0                   ; j
    loop_over_b_r:
        ld   a, 16
        sub  b
        dec  a
        ld   l, a
        ld   h, c
        call atadd                  ; a := attr of ATTRS[16-b-1, c]

        ld   de, MAP
        call set_element             ; MAP_Y[c,b] := a

        inc  b
        ld   a, 16
        cp   b
        jr   nz, loop_over_b_r
    inc  c
    ld   a, 16
    cp   c
    jr   nz, loop_over_c_r

    ret

;;
;; rotate top leftmost 16x16 attrs into
;; a copy matrix by 90 degrees to right
;;

rotate_90_left:
    ld   c, 0                   ; i
loop_over_c_l:
    ld   b, 0                   ; j
    loop_over_b_l:
        ld   a, 16
        sub  c
        dec  a
        ld   h, a
        ld   l, b
        call atadd                  ; a := attr of ATTRS[b,16-c-1]

        ld   de, MAP
        call set_element             ; MAP_Y[c,b] := a

        inc  b
        ld   a, 16
        cp   b
        jr   nz, loop_over_b_l
    inc  c
    ld   a, 16
    cp   c
    jr   nz, loop_over_c_l

    ret

;;
;; de is address of matrix
;; c is row
;; b is column
;; a is element value to be set
;; trashes hl
;;
;; matrix[c,b] := a
;;
set_element:
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

MAP
    defb 127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127
    defb 127,000,000,000,000,000,000,000,000,000,000,000,000,000,000,127
    defb 127,000,127,127,127,000,127,000,127,000,000,000,000,000,000,127
    defb 127,000,000,000,127,000,127,000,127,000,000,000,000,000,000,127
    defb 127,000,000,127,000,000,000,127,000,000,000,000,000,000,000,127
    defb 127,000,127,000,000,000,127,000,127,000,000,000,000,000,000,127
    defb 127,000,127,127,127,000,127,000,127,000,000,000,000,000,000,127
    defb 127,000,000,000,000,000,000,000,000,000,000,000,000,000,000,127
    defb 127,000,000,127,000,000,000,127,127,000,000,127,000,127,000,127
    defb 127,000,127,000,127,000,127,000,000,000,127,000,127,000,127,127
    defb 127,000,127,127,127,000,000,127,000,000,127,000,127,000,127,127
    defb 127,000,127,000,127,000,000,000,127,000,127,000,127,000,127,127
    defb 127,000,127,000,127,000,127,127,000,000,127,000,127,000,127,127
    defb 127,000,000,000,000,000,000,000,000,000,000,000,000,000,000,127
    defb 127,000,000,000,000,000,000,000,000,000,000,000,000,000,000,127
    defb 127,127,127,127,127,127,127,127,127,127,127,127,127,127,127,127
