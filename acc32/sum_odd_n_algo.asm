.data

    ; IO consts
    input_addr:   .word 0x80     ; input address
    output_addr:  .word 0x84     ; output address

    ; program variables
    n:            .word 0        ; n — input number
    k:            .word 0        ; k — count of odd numbers in [1..n]

    ; consts
    one:          .word 1
    two:          .word 2
    minus_one:    .word -1
    overflow_val: .word 0xCCCCCCCC   ; value in case of overflowing

.text

_start:
    ; load into ACC value by address from ACC (acc <- mem[acc])
    load         input_addr
    load_acc
    store        n

    ; check is n > 0
    ; if n <= 0 --> stop program
    load         n
    bgt          init


; bad N input handler
; return -1 if bad input happened
bad_input:
    load         minus_one
    jmp          _finish


; check is n % 2 == 0 and select useful algo for odd numbers count
init:
    load         n
    rem          two
    bgt          init_odd_N
    jmp          init_even_N


; counter for odd numbers in case N is odd
init_odd_N:
    load         n
    add          one
    div          two
    store        k
    jmp          solution


; counter for odd numbers in case N is even
init_even_N:
    load         n
    div          two
    store        k
    jmp          solution


; result counter
; use formula [sum_odd = k_odd ** 2]
solution:
    load         k
    mul          k

    bvs          overflow

    jmp _finish


; overflow situation handler
overflow:
    load overflow_val


; finish method
_finish:
    store_ind output_addr
    halt


