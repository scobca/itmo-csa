; ======================================
; Zero - always zero
; Ra   - return address
; Sp   - stack pointer
; Gp   - global pointer
; Tp   - thread pointer
; ======================================
; Temporary registers
; T0      - current readable symbol
; T1      - <readonly> flag
; T2-T5   - not used
; T6      - extra return address
; ======================================
; Saved registers
; S0      - outline_offset
; S1      - "\n" ascii code
; S2      - "a" ascii code
; S3      - "z" ascii code
; S4      - "\0" ascii code
; S5-S11  - not used
; ======================================
; Address registers
; A0      - input address
; A1      - output buffer address
; A2      - maximum string length
; A3      - buffer index
; A4      - output filler index
; A5-A7   - not used
; ======================================
.data
    buffer:          .byte  '________________________________'

    ; I/O consts
    input_addr:     .word   0x80                ; input address
    output_addr:    .word   0x84                ; output address
    buffer_addr:    .word   0x00                ; buffer output address

    ; algo consts
    max_length:     .word   0x20                ; maximum string length (32 symbols)
    overflow_value: .word   0xCCCCCCCC          ; overflow value

.text
.org 0x100

    _start:
        lui       a0, %hi(input_addr)           ; load the upper 20 bits of input_addr address
        addi      a0, a0, %lo(input_addr)       ; load the lower 12 bits of input_addr address & add them to previous 20
        lw        a0, 0(a0)                     ; load value from input_addr to a0 register <—> a0 <- 0x80

        lui       a1, %hi(output_addr)
        addi      a1, a1, %lo(output_addr)
        lw        a1, 0(a1)

        lui       a2, %hi(max_length)
        addi      a2, a2, %lo(max_length)
        lw        a2, 0(a2)

        lui       a3, %hi(buffer_addr)
        addi      a3, a3, %lo(buffer_addr)
        lw        a3, 0(a3)

        lui       a4, %hi(buffer_addr)
        addi      a4, a4, %lo(buffer_addr)
        lw        a4, 0(a4)

        ; ================================
        ; immediate values
        ; ================================

        addi      s0, zero, 0x20                ; load into s0 outline_offset (difference between uppercase and lowercase letters in ASCII)
        addi      s1, zero, 0x0A                ; load into s1 newline (\n) symbol in ASCII
        addi      s2, zero, 0x60                ; load into s2 ascii-code before "a" letter ascii-code
        addi      s3, zero, 0x7A                ; load into s3 "z" letter ascii-code
        addi      s4, zero, 0x00                ; load null terminator ascii-code

    read_line:
        jal       ra, check_length              ; check is maximum length reached

        lb        t0, 0(a0)                     ; read symbol from input_addr

        beq       t0, s1, handle_newline            ; handle \n
        ble       t0, s2, write_symbol          ; write symbol if it less than 'a'
        bgt       t0, s3, write_symbol          ; write symbol if it greater than 'z'

        jal       ra, write_uppercase_symbol    ; write uppercase symbol
        j         read_line

    _finish:
        halt


    ; ================================
    ; procedures
    ; ================================
    increment_buffer:
        addi      a3, a3, 1                     ; increment buffer address
        jr        t6

    check_length:
        beq       a2, a3, overflow              ; if current buffer addr equals to max length -> throw overflow
        jr        ra                            ; if ok - return to read_line

    write_symbol:
        sb        t0, 0(a3)                     ; load to output buffer current byte

        jal       t6, increment_buffer          ; increment buffer address
        mv        t6, zero                      ; clear T6 register
        j         read_line                     ; jump to read_line

    write_uppercase_symbol:
        sub       t0, t0, s0                    ; get uppercase letter ascii-code = (downcase ascii-code) - 20
        sb        t0, 0(a3)                     ; store uppercase symbol into 0x84

        jal       t6, increment_buffer          ; increment buffer address
        mv        t6, zero                      ; clear T6 register
        jr        ra                            ; return to read_line

    handle_newline:
        sb        zero, 0(a3)

    fill_output:
        beq       a3, a4, _finish               ; if all symbols from buffer copied to output -> goto finish
        lb        t0, 0(a4)                     ; t0 <- next symbol from memory
        addi      a4, a4, 1                     ; increment output filler index

        bnez      t1, fill_output               ; read mem until the end (without writing) if <readonly> set
        beq       t0, s4, set_readonly_flag     ; if current symbol is \0 -> set <readonly>

        sb        t0, 0(a1)                     ; copy symbol from buffer to output
        j fill_output

    set_readonly_flag:
        addi    t1, zero, 1                     ; set <readonly> flag
        j       fill_output


    overflow:
        lui      t0, %hi(overflow_value)        ; load the upper 20 bits of overflow_value address
        addi     t0, t0, %lo(overflow_value)    ; load the lower 12 bits of overflow_value address & add them to previous 20
        lw       t0, 0(t0)                      ; load value by overflow_value address to t0

        sw       t0, 0(a1)                      ; write overflow value to output
        j        _finish                        ; goto finish