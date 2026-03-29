.data

    ; IO consts
    input_addr:   .word 0x80     ; input address
    output_addr:  .word 0x84     ; output address

    ; program variables
    n:            .word 0        ; n
    result:       .word 0        ; result
    iter:         .word 1        ; iterator

    ; consts
    zero:         .word 0
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
    store_ind    output_addr
    halt

init:
    load         zero
    store        result

loop:
    load         iter
    sub          n
    bgt          _finish

    load        iter
    rem         two
    beqz        increment_iter

    load        result
    add         iter
    bvs         overflow
    store       result

increment_iter:
    load        iter
    add         one
    store       iter
    jmp         loop

overflow:
    load        overflow_val
    store_ind   output_addr
    halt

_finish:
    load        result
    store_ind   output_addr
    halt


