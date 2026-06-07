; ======================================
; Data registers
; D0 - current readable symbol
; D1 - digits stacker
; D2 - operand 1
; D3 - operand 2
; D4 - temp ASCII code storage
; D5 - not used
; D6 - not used
; D7 - discharge multiplier
; ======================================
; Address registers
; A0 - input address
; A1 - output address
; A2 - temp storage
; A3 - not used
; A4 - not used
; A5 - pointer for custom dataBuffer
; A6 - not used
; A7 - standart stack pointer
; ======================================

.data
    ; I/O consts
    input_addr:     .word   0x80     ; input address
    output_addr:    .word   0x84     ; output address

    ; system consts
    buffer_addr:     .word   0x200   ; 0x200 - stack pointer address for dataBuffer
    sp_addr:         .word   0x300   ; 0x300 - stack pointer address for A7 SP
    discharger:      .word   0x0a    ; 0x0A (hex), 10 (dec) - discharger multuplier for number writing


.text
.org 0x500

    _start:
        ; load input address
        movea.l input_addr, A0     ; A0 <- address of input_addr
        movea.l (A0), A0           ; A0 <- value at input_addr

        ; load output address
        movea.l output_addr, A1    ; A1 <- address of output_addr
        movea.l (A1), A1           ; A1 <- value at output_addr

        ; load discharger
        movea.l discharger, A2     ; A2 <- address of discharger
        move.l (A2), D7            ; D7 <- mem[A2], load discharger value

        ; use A5 as data buffer
        movea.l buffer_addr, A5    ; A5 <- address of buffer_addr
        movea.l (A5), A5           ; A5 <- value at buffer_addr

        ; load A7 SP
        movea.l sp_addr, A7        ; A7 <- address of sp_addr
        movea.l (A5), A5           ; A7 <- value at sp_addr

    link:
        link A6, -8

        move.l 0x30, -8(A6)         ; load 0 in ASCII
        move.l 0x39, -7(A6)         ; load 9 in ASCII
        move.l 0x2b, -6(A6)         ; load + in ASCII
        move.l 0x2d, -5(A6)         ; load - in ASCII
        move.l 0x2a, -4(A6)         ; load * in ASCII
        move.l 0x2f, -3(A6)         ; load / in ASCII
        move.l 0x0a, -2(A6)         ; load \n in ASCII
        move.l 0x20, -1(A6)         ; load " " in ASCII

    _finish:
        unlk A6
        halt                        ; stop programm