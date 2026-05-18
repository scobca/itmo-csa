.data
.org 0x00

    ; I/O consts
    input_addr:     .word   0x80    ; input address
    output_addr:    .word   0x84    ; output address


.text
.org 0x90
    _start:
        movea.l input_addr, A0
        movea.l (A0), A0

        movea.l  output_addr, A1
        movea.l  (A1), A1

    _finish:
        halt