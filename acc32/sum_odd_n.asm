; код для выполнения лабораторной 3, архитектура acc32, задание sum_odd_n

.data

    ; IO consts
    input_addr:   .word 0x80     ; input address
    output_addr:  .word 0x84     ; output address

    ; program variables
    n:            .word 0        ; n
    result:       .word 0        ; result
    iter:         .word 0        ; iterator
    current_num:  .word 0        ; current number for check_odd func

    ; consts
    zero:         .word 0
    one:          .word 1
    two:          .word 2
    max_value:    .word 2147483647   ; 2^31 - 1
    overflow_val: .word 0xCCCCCCCC   ; value in case of overflowing

.text

    ; startup
    _start:
        ; read n
        load        input_addr
        load_acc
        store       n

        ; check if n <= 0 return -1
        ; if n > 0 -> go to .init
        load        n
        bgt          init

        ; if n <= 0 -> return -1
        load        -1
        store       output_addr
        halt


    ; init data
    init:
        ; set result to 0 (result = 0)
        load        zero
        store       result

        ; set iterator to 1 (iter = 1)
        load        one
        store       iter


    ; start of the cycle
    loop_start:
        ; check is iter <= n
        ; if true  -->  go next step
        ; if false -->  stop cycle and return result
        load        iter
        sub         n
        bgt         loop_end

        ; send current iter to checkup
        load        iter
        store       current_num
        jmp         check_odd


    ; end of the cycle
    loop_end:
        ; return result
        load        result
        store       output_addr
        halt


    ; check current iterator value odd
    check_odd:
        ; get current_num (last iterator value)
        ; if (current_num % 2 > 0) -> number is odd   => add it to result
        ; if (current_num == 0) -> number is even  => skip this one
        load        current_num
        rem         two
        bgt         add_iter_to_result
        beqz        increment_iter


    ; add current iterator value to result
    add_iter_to_result:
        ; overflow check-up
        ; if (result > (max_value - iter)) -> overflow happened
        load        max_value
        sub         iter
        sub         result
        ble         overflow

        load        result
        add         iter
        store       result
        jmp         increment_iter


    ; increment iterator value & go to next cycle step
    increment_iter:
        load        iter
        add         one
        store       iter
        jmp         loop_start


    ; return 0xCC if overflow happened
    overflow:
        load        overflow_val
        store       output_addr
        halt