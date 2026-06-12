; ======================================
; Data registers
; D0 - current readable symbol
; D1 - digits stacker
; D2 - operand 1
; D3 - operand 2
; D4 - stack size counter
; D5 - <isLastNumber> flag
; D6 - <isLastSymbol> flag
; D7 - not used
; ======================================
; Address registers
; A0 - input address
; A1 - output address
; A2 - register for temporary transitions
; A3 - not used
; A4 - not used
; A5 - dataBuffer
; A6 - ASCII symbols, operators & numbers general counters buffer
; A7 - system
; ======================================

.data
    ; I/O consts
    input_addr:     .word   0x80     ; input address
    output_addr:    .word   0x84     ; output address

    ; system consts
    ascii_num_base:  .word   0x30            ; 0x30 (hex), - base of nubers in ASCII equals to 0

    ; buffers
    numbers_buffer_addr:     .word   0x300   ; 0x300 - stack pointer address for numbersBuffer
    common_buffer_addr:      .word   0x400   ; 0x500 - stack pointer address for commonbuffer
    sp_buffer_addr:          .word   0x500   ; 0x500 - stack pointer address for A7 SP

    ; errors consts
    overflow_val:    .word   0xCCCCCCCC      ; value in case of overflowing
    error_val:       .word   0xFFFFFFFF      ; value in case of common error

.text
.org 0x500
    ; ======================================
    ; operation handlers
    ; ======================================
    handle_plus:
        jsr      check_stack_size     ; check stack.size before operation
        jsr      load_operands        ; load operands - use subroutine

        add.l    D3, D2               ; adding two operands (D2 = D2 + D3)
        move.l   D2, -(A5)            ; save addition result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_minus:
        jsr      check_stack_size     ; check stack.size before operation
        jsr      load_operands        ; load operands - use subroutine

        sub.l    D2, D3               ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)            ; save subtraction result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_multiplication:
        jsr      check_stack_size     ; check stack.size before operation
        jsr      load_operands        ; load operands - use subroutine

        mul.l    D2, D3               ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)            ; save multiplication result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_division:
        jsr      check_stack_size     ; check stack.size before operation
        jsr      load_operands        ; load operands - use subroutine

        cmp.l    0, D2                ; compare D3 and 0
        beq      error                ; throw error if division by 0 detected

        div.l    D2, D3               ; substracting two operands (D2 = D2 + D3)
        move.l   D3, -(A5)            ; save division result to dataBuffer

        jmp      operation_finalizer  ; finalize operation work

    handle_newline:
        move.l   1, D6                ; set <isLastSymbol> flag

        cmp.b    0, -10(A6)           ; check general operators counter
        beq      error                ; if no operators - throw error

        cmp.b    0, -11(A6)           ; chech general numbers counter
        beq      error                ; if no numbers - throw error

        move.l   (A5)+, D2            ; save result from buffer to D2
        move.l   D2, (A1)             ; load reasult into output addr
        jmp      _finish

    handle_space:
        cmp.l    0, D5                ; check is last symbol was a number
        beq      read_symbol

        move.l   D1, -(A5)            ; save finished number to data buffer
        move.l   0x00, D1             ; reset digits stacker (preparation for next number reading)

        move.l   0, D5                ; reset number flag
        jmp      read_symbol          ; jump to read_symbol for next symbol reading

    ; ======================================
    ; subrutines
    ; ======================================
    load_operands:
        move.l   (A5)+, D2            ; save first operand to D2
        move.l   (A5)+, D3            ; save second operand to D3
        rts

    check_stack_size:
        cmp.l    2, D4                ; check is (stack.size - 2) >= 0
        bmi      error                ; if stack.size < 2 => throw error
        rts

    ; ======================================
    ; utils
    ; ======================================
    operation_finalizer:
        bvs      overflow             ; check overflowing

        add.l    1, -10(A6)           ; update general operators counter
        sub.l    1, D4                ; decrease numbers stack counter
        move.l   0, D5                ; reset <isLastNumber> flag

        jmp      read_symbol          ; jump to read_symbol for next symbol reading

    clear_input:
        move.l   (A0), D0             ; load next symbol

        ; if D0 equals to newline
        cmp.b    -2(A6), D0           ; \n in ASCII
        bne      clear_input

        jmp      _finish

    ; ======================================
    ; algo
    ; ======================================
    _start:
        ; load input address
        movea.l  input_addr, A0       ; A0 <- address of input_addr
        movea.l  (A0), A0             ; A0 <- value at input_addr

        ; load output address
        movea.l  output_addr, A1      ; A1 <- address of output_addr
        movea.l  (A1), A1             ; A1 <- value at output_addr

        movea.l  numbers_buffer_addr, A5      ; A5 <- address of buffer_addr
        movea.l  (A5), A5                     ; A5 <- value at buffer_addr

        movea.l  common_buffer_addr, A6       ; A6 <- address of sp_addr
        movea.l  (A6), A6                     ; A6 <- value at sp_addr

        ; load A6 SP
        movea.l  sp_buffer_addr, A7           ; A7 <- address of sp_addr
        movea.l  (A7), A7                     ; A7 <- value at sp_addr

        move.l   0, D4                ; set numbers stack counter
        move.l   0, D5                ; set <isLastNumber> flag
        move.l   0, D6                ; set <isLastSymbol> flag

    link_buffer:
        move.b   0x46, -14(A6)        ; load F in ASCII
        move.b   0x41, -13(A6)        ; load A in ASCII
        move.b   0x00, -12(A6)        ; length of current number
        move.b   0x00, -11(A6)        ; general numbers counter
        move.b   0x00, -10(A6)        ; general operators counter
        move.b   0x00, -9(A6)         ; error container
        move.b   0x30, -8(A6)         ; load 0 in ASCII
        move.b   0x39, -7(A6)         ; load 9 in ASCII
        move.b   0x2b, -6(A6)         ; load + in ASCII
        move.b   0x2d, -5(A6)         ; load - in ASCII
        move.b   0x2a, -4(A6)         ; load * in ASCII
        move.b   0x2f, -3(A6)         ; load / in ASCII
        move.b   0x0a, -2(A6)         ; load \n in ASCII
        move.b   0x20, -1(A6)         ; load " " in ASCII

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
        sub.l    48, D0               ; convert ascii code to real number

        mul.l    10, D1               ; increasing the discharge of the accumulated number (n = n * 10)
        add.l    D0, D1               ; adding accumulated and read numbers (D1 <- D1 + D0)

        add.l    1, -12(A6)           ; update length of current number
        cmp.b    64, -12(A6)
        beq      overflow

        add.l    1, -11(A6)           ; update general numbers counter
        add.l    1, D4                ; update numbers stack counter
        move.l   1, D5                ; set number flat to True
        jmp      read_symbol          ; jump to read_symbol for next symbol reading

    _finish:
        halt                          ; stop programm

    error:
        movea.l  error_val, A2        ; A2 <- address of sp_addr
        move.l   (A2), (A1)           ; mem[0x84] <- error code

        cmp.l    0, D6                ; check <isLastSymbol> flag
        beq      clear_input

        jmp      _finish

    overflow:
        movea.l  overflow_val, A2     ; A2 <- address of sp_addr
        move.l   (A2), (A1)           ; mem[0x84] <- error code

        jmp _finish