; ======================================
; Data registers
; D0 - current readable symbol
; D1 - digits stacker
; D2 - operand 1
; D3 - operand 2
; D4 - not used
; D5 - not used
; D6 - not used
; D7 - discharge multiplier
; ======================================
; Address registers
; A0 - input address
; A1 - output address
; A2 - not used
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
    buffer_addr:     .word   0x300   ; 0x200 - stack pointer address for dataBuffer
    discharger:      .word   0x0a    ; 0x0A (hex), 10 (dec) - discharger multuplier for number writing

.text
.org 0x500
    load_operands:
        move.l   (A5)+, D2          ; save first operand to D2
        move.l   (A5)+, D3          ; save second operand to D3
        rts

    _start:
        movea.l input_addr, A0      ; A0 <- address of input_addr
        movea.l (A0), A0            ; A0 <- value at input_addr

        movea.l  output_addr, A1    ; A1 <- address of output_addr
        movea.l  (A1), A1           ; A1 <- value at output_addr

        movea.l  discharger, A2     ; A2 <- address of discharger
        move.l   (A2), D7           ; D7 <- mem[A2], load discharger value

        ; use A5 as data buffer
        movea.l buffer_addr, A5     ; A5 <- address of buffer_addr
        movea.l (A5), A5            ; 5 <- value at buffer_addr

        move.l   (A0), D0

    read_symbols:
        move.l   (A0), D0

        cmp.b    48, D0           ; D0 < 0x30 (0 in ASCII)
        blt      choose_operator

        cmp.b    57, D0           ; D0 > 0x39 (9 in ASCII)
        bgt      choose_operator

    write_number_part:
        mul.l    D1, D7             ; increasing the discharge of the accumulated number (D1 <- D1 * 10)
        add.l    D1, D0             ; adding accumulated and read numbers (D1 <- D1 + D0)
        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    choose_operator:
        ; if D0 equals to +
        cmp.b    0x2b, D0           ; + in ASCII
        beq      handle_plus

        ; if D0 equals to -
        cmp.b    0x2d, D0           ; - in ASCII
        beq      handle_minus

        ; if D0 equals to *
        cmp.b    0x2a, D0           ; * in ASCII
        beq      handle_multiplication

        ; if D0 equals to /
        cmp.b    0x2f, D0           ; / in ASCII
        beq      handle_division

        ; if D0 equals to newline
        cmp.b    0x0a, D0           ; \n in ASCII
        beq      handle_newline

        ; if D0 equals to space
        cmp.b    0x20, D0           ; space in ASCII
        beq      handle_space

        jmp      error              ; throw error if no one case had been triggered - unknown sign


    ; ======================================
    ; operation handlers
    ; ======================================
    handle_plus:
        jsr      load_operands      ; load operands - use subroutine

        add.l    D2, D3             ; adding two operands (D2 = D2 + D3)
        move.l   D2, -(A5)          ; save addition result to dataBuffer

        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    handle_minus:
        jsr      load_operands      ; load operands - use subroutine

        sub.l    D2, D3             ; substracting two operands (D2 = D2 + D3)
        move.l   D2, -(A5)          ; save subtraction result to dataBuffer

        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    handle_multiplication:
        jsr      load_operands      ; load operands - use subroutine

        mul.l    D2, D3             ; substracting two operands (D2 = D2 + D3)
        move.l   D2, -(A5)          ; save multiplication result to dataBuffer

        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    handle_division:
        jsr      load_operands      ; load operands - use subroutine

        cmp.l    0, D3              ; compare D3 and 0
        beq      error              ; throw error if division by 0 detected

        div.l    D2, D3             ; substracting two operands (D2 = D2 + D3)
        move.l   D2, -(A5)          ; save division result to dataBuffer

        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    handle_newline:
        move.l   (A5)+, D2          ; save result from buffer to D2
        move.l   D2, (A1)

    handle_space:
        move.l   D1, -(A5)          ; save finished number to data buffer
        move.l   0x00, D1           ; reset digits stacker (preparation for next number reading)

        jmp      read_symbols       ; jump to read_symbols for next symbol reading

    _finish:
        halt                        ; stop programm

    error:
        move.l   -1, (A1)           ; write -1 to output
        jmp      _finish            ; jump to finish