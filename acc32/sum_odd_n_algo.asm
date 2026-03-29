.data

    ; IO consts
    input_addr:   .word 0x80     ; input address
    output_addr:  .word 0x84     ; output address

    ; program variables
    n:            .word 0        ; n
    k:            .word 0
    result:       .word 0        ; result
    counter:      .word 0

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

    load         n
    rem          two
    bgt          init_odd_N
    jmp          init_even_N

init_odd_N:
    load         n
    add          one
    div          two
    store        k
    jmp          loop


init_even_N:
    load         n
    div          two
    store        k
    jmp          loop

loop:
    load         k
    mul          k

    bvs         overflow
    store       result

    jmp         _finish

overflow:
    load        overflow_val
    store_ind   output_addr
    halt

_finish:
    load        result
    store_ind   output_addr
    halt


