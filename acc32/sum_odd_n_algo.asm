.data

    ; IO consts
    input_addr:   .word 0x80     ; input address
    output_addr:  .word 0x84     ; output address

    ; program variables
    n:            .word 0        ; n
    k:            .word 0

    ; consts
    one:          .word 1
    two:          .word 2
    minus_one:    .word -1
    overflow_val: .word 0xCCCCCCCC   ; value in case of overflowing

.text

_start:
    load         input_addr
    load_acc                                 ; load into ACC value by address from ACC (acc <- mem[acc])
    store        n

    load         n
    bgt          init

bad_input:
    load         minus_one
    jmp          _finish

init:
    load         n
    rem          two
    bgt          init_odd_N
    jmp          init_even_N

init_odd_N:
    load         n
    add          one
    div          two
    store        k
    jmp          solution


init_even_N:
    load         n
    div          two
    store        k
    jmp          solution

solution:
    load         k
    mul          k

    bvs          overflow

    jmp _finish

overflow:
    load overflow_val

_finish:
    store_ind output_addr
    halt


