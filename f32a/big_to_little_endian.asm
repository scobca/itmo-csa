.data

    \; I/O consts
    input_addr:     .word   0x80    \; input address
    output_addr:    .word   0x84    \; output address

    \; programm consts
    mask:           .word   0xFF    \; mask for byte highlighting
    move_bytes:     .word   0x04       \; number of bytes not shifted
    move_bits:      .word   0x07       \; numver of bits shall be shifted
    current_byte:   .word   0x00       \; value of working byte

.text
.org 0x90

    shift_right_8:                  \; set count of unshifted bits into R stack
        @p move_bits >r

    shift_right_loop:               \; shift >> 1, if (R.top != 0): shift_right_loop else: return
        2/
        next shift_right_loop
        ;

    shift_left_8:                   \; set count of unshifted bits into R stack
        @p move_bits >r

    shift_left_loop:                \; shift << 1, if (R.top != 0): shift_right_loop else: return
        2*
        next shift_left_loop
        ;

    decrement_move_bytes:
        @p move_bytes               \; stack <- mem[move_bytes]
        lit -1 +                    \; stack <- -1 && (+ mem[move_bytes] -1)
        !p move_bytes ;             \; mem[move_bytes] <- stack.top


    _start:
        @p  input_addr              \; stack <- mem[input_addr] <=> stack <- 0x80
        b!                          \; A register <- stack.top <=> A register <- 0x80
        @b                          \; stack <- mem[A] <=> stack <- mem[0x80]


    preloop_check:
        @p move_bytes               \; stack <- mem[move_bytes]
        if _finish                  \; if (move_bytes == 0) => _finish

    loop:
        \; select junior byte of the number
        dup
        @p mask and
        !p current_byte

        \; move result << 8 & add our current working byte
        a shift_left_8
        @p current_byte +
        a!

        \; preparation before next loop step
        shift_right_8
        decrement_move_bytes
        preloop_check ;


    _finish:
        @p output_addr b!       \; stack <- 0x84 && B register <- 0x84
        a !b                    \; stack <- A register && mem[B] <- stack.top
        halt