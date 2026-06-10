; ======================================
; Data registers
; D0 - current readable symbol
; D1 - digits stacker
; D2 - operand 1
; D3 - operand 2
; D4 - overflow val
; D5 - number flag
; D6 - ascii num base
; D7 - discharge multiplier
; ======================================
; Address registers
; A0 - input address
; A1 - output address
; A2 - register for temporary transitions
; A3 - not used
; A4 - not used
; A5 - dataBuffer
; A6 - ASCII symbols buffer
; A7 - ASCII symbols buffer SP
; ======================================

.data
    ; I/O consts
    input_addr:     .word   0x80     ; input address
    output_addr:    .word   0x84     ; output address

    ; system consts
    overflow_val:    .word   0xCCCCCCCC   ; value in case of overflowing
    buffer_addr:     .word   0x300   ; 0x200 - stack pointer address for dataBuffer
    sp_addr:         .word   0x400   ; 0x300 - stack pointer address for A7 SP
    discharger:      .word   0x0a    ; 0x0A (hex), 10 (dec) - discharger multuplier for number writing
    ascii_num_base:  .word   0x30    ; 0x30 (hex), - base of nubers in ASCII equals to 0
    number_flag:     .word   0x00    ; flag for spaces checking, 1 - if last symbol was a number, 0 if it was an op

.text
.org 0x500
    ; ======================================
    ; operation handlers
    ; ======================================
    handle_plus:
        jsr      load_operands        ; load operands - use subroutine

        add.l    D3, D2               ; adding two operands (D2 = D2 + D3)
        move.l   D2, -(A5)            ; save addition result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_minus:
        jsr      load_operands        ; load operands - use subroutine

        sub.l    D2, D3               ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)            ; save subtraction result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_multiplication:
        jsr      load_operands        ; load operands - use subroutine

        mul.l    D2, D3               ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)            ; save multiplication result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_division:
        jsr      load_operands      ; load operands - use subroutine

        cmp.l    0, D2              ; compare D3 and 0
        beq      error              ; throw error if division by 0 detected

        div.l    D2, D3             ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)          ; save division result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_newline:
        move.l   (A5)+, D2            ; save result from buffer to D2
        move.l   D2, (A1)
        jmp      _finish


    handle_space:
        cmp.l    0, D5                ; check is last symbol was a number
        beq      read_symbol

        move.l   D1, -(A5)            ; save finished number to data buffer
        move.l   0x00, D1             ; reset digits stacker (preparation for next number reading)

        jmp      operation_finalizer  ; finalize operation work

    ; ======================================
    ; subrutines & utils
    ; ======================================
    reset_number_flag:
        move.l 0, D5               ; D7 <- 0, load number flag value
        rts

    load_operands:
        move.l   (A5)+, D2            ; save first operand to D2
        move.l   (A5)+, D3            ; save second operand to D3
        rts

    operation_finalizer:
        bvs      overflow_error       ; check overflowing
        jsr      reset_number_flag    ; reset number flag
        jmp      read_symbol          ; jump to read_symbol for next symbol reading

    ; ======================================
    ; algo
    ; ======================================
    _start:
        ; load input address
        movea.l  input_addr, A0        ; A0 <- address of input_addr
        movea.l  (A0), A0              ; A0 <- value at input_addr

        ; load output address
        movea.l  output_addr, A1       ; A1 <- address of output_addr
        movea.l  (A1), A1              ; A1 <- value at output_addr

        ; use A5 as data buffer
        movea.l  buffer_addr, A5       ; A5 <- address of buffer_addr
        movea.l  (A5), A5              ; A5 <- value at buffer_addr

        ; load A7 SP
        movea.l  sp_addr, A7           ; A7 <- address of number_flag
        movea.l  (A7), A7              ; A7 <- value at number_flag

        movea.l  overflow_val, A2      ; A2 <- address if overflow_val
        move.l   (A2), D4              ; A2 <- value of overflow_val

        movea.l  number_flag, A2       ; A2 <- address if number_flag
        move.l   (A2), D5              ; A2 <- value of number_flag

        movea.l  ascii_num_base, A2    ; A2 <- address if ascii_num_base
        move.l   (A2), D6              ; A2 <- value of ascii_num_base

        movea.l  discharger, A2        ; A2 <- address of discharger
        move.l  (A2), D7               ; D7 <- mem[A2], load discharger value

    link_ascii:
        link     A6, -8
        move.l   0x30, -8(A6)         ; load 0 in ASCII
        move.l   0x39, -7(A6)         ; load 9 in ASCII
        move.l   0x2b, -6(A6)         ; load + in ASCII
        move.l   0x2d, -5(A6)         ; load - in ASCII
        move.l   0x2a, -4(A6)         ; load * in ASCII
        move.l   0x2f, -3(A6)         ; load / in ASCII
        move.l   0x0a, -2(A6)         ; load \n in ASCII
        move.l   0x20, -1(A6)         ; load " " in ASCII

    read_symbol:
        move.l   (A0), D0             ; load next symbol

        ; if D0 equals to +
        cmp.b    -6(A6), D0           ; + in ASCII
        beq      handle_plus

        ; if D0 equals to -
        cmp.b    -5(A6), D0           ; - in ASCII
        beq      handle_minus

        ; if D0 equals to *
        cmp.b    -4(A6), D0           ; * in ASCII
        beq      handle_multiplication

        ; if D0 equals to /
        cmp.b    -3(A6), D0           ; / in ASCII
        beq      handle_division

        ; if D0 equals to newline
        cmp.b    -2(A6), D0           ; \n in ASCII
        beq      handle_newline

        ; if D0 equals to space
        cmp.b    -1(A6), D0           ; space in ASCII
        beq      handle_space

    write_number_part:
        sub.l    D6, D0               ; convert ascii code to real number

        mul.l    D7, D1               ; increasing the discharge of the accumulated number (n = n * 10)
        add.l    D0, D1               ; adding accumulated and read numbers (D1 <- D1 + D0)

        move.l   1, D5                ; set number flat to True
        jmp      read_symbol          ; jump to read_symbol for next symbol reading

    _finish:
        unlk     A6
        halt                          ; stop programm

    error:
        move.l   -1, (A1)             ; write -1 to output
        jmp      _finish              ; jump to finish

    overflow_error:
        move.l   D4, (A1)             ; write 0xCCCCCCCC to output
        jmp      _finish              ; jump to finish