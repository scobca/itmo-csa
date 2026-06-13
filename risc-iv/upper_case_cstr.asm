; ======================================
; Zero - always zero (hardwired)
; Ra   - return address (for calls)
; Sp   - stack pointer
; Gp   - global pointer (not used)
; Tp   - thread pointer (not used)
; ======================================
; Temporary registers
; T0      - current readable symbol
; T1-T6   - not used
; ======================================
; Saved registers
; S0      - outline_offset
; S1      - "\n" ascii code
; S2      - "a" ascii code
; S3      - "z" ascii code
; S4-S11  - not used
; ======================================
; Address registers
; A0      - input address
; A1      - output address
; A2-A7   - not used
; ======================================
.data
    ; I/O consts
    input_addr:     .word   0x80                ; input address
    output_addr:    .word   0x84                ; output address

.text
    _start:
        lui       a0, %hi(input_addr)           ; load the upper 20 bits of input_addr address
        addi      a0, a0, %lo(input_addr)       ; load the lower 12 bits of input_addr address & add them to previous 20
        lw        a0, 0(a0)                     ; load value from input_addr to a0 register <—> a0 <- 0x80

        lui       a1, %hi(output_addr)          ; load the upper 20 bits of output_addr address
        addi      a1, a1, %lo(output_addr)      ; load the lower 12 bits of output_addr address & add them to previous 20
        lw        a1, 0(a1)                     ; load value from output_addr to a1 register <—> a1 <- 0x84

        addi      s0, zero, 0x20                ; load into s0 outline_offset (difference between uppercase and lowercase letters in ASCII)
        addi      s1, zero, 0x0A                ; load into s1 newline (\n) symbol in ASCII
        addi      s2, zero, 0x61                ; load into s2 "a" letter ASCII-code
        addi      s3, zero, 0x7A                ; load into s3 "z" letter ASCII-code

        j         read_symbol

    handle_letter:
        bgt       t0, s3, write_symbol          ; check is current symbol ascii-code greater than 'z'
        jal       ra, write_symbol_uppercase    ; if current symbol in [a..z] -> write_symbol_uppercase

    read_symbol:
        lw        t0, 0(a0)                      ; load current string symbol

        beq       t0, s1, _finish                ; if find \n -> finish
        beq       t0, s2, write_symbol_uppercase ; check is current letter equals to 'a' (just because we haven't got Branch if Greater Than or Equal)
        bgt       t0, s2, handle_letter          ; check is current symbol ascii-code greater than 'a'
        j         write_symbol                   ; read next symbol, if current symbol isn't a downcase letter

    _finish:
        halt


    ; ======================================
    ; procedures
    ; ======================================
    write_symbol_uppercase:
        sub       t0, t0, s0                    ; get uppercase letter ascii-code = (downcase ascii-code) - 20
        sw        t0, 0(a1)                     ; store uppercase symbol into 0x84
        jr        ra                            ; return to read_symbol

    write_symbol:
        sw        t0, 0(a1)                     ; store symbol into 0x84
        j         read_symbol