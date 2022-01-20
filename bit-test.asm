        !addr   chrout      = $ffd2
        !addr   r6510       = $01
        !addr   reg_d030    = $d030
        !addr   screen0     = $0800
        !addr   screen1     = $0801
        !addr   screen2     = $0802

        !addr   mem_flags   = $b1       ; the flags after the memory-mode BIT instruction
        !addr   zp_mem      = $b2       ; memory value for the base-page-mode BIT instructions
        !addr   tmp_ptr     = $b3       ; tempoary pointer used by puts
        !addr   counter     = $b5       ; the number of differences found

        !addr   abs_mem     = $1300     ; memory value for the absolute-mode BIT instructions


;===============================================================================

        * = $2001

        !16     +
!ifdef NOAUTOSTART {
        !16     5                                       ; Line number
        !8      $80                                     ; END
        !8      0                                       ; End of BASIC line
+       !16     +
}
        !16     10                                      ; Line number
        !8      $FE, $02, '0'                           ; BANK 0
        !8      ':'
        !8      $9E                                     ; SYS startup
        !8      <(((main / 1000) % 10) + '0')
        !8      <(((main /  100) % 10) + '0')
        !8      <(((main /   10) % 10) + '0')
        !8      <(((main /    1) % 10) + '0')
        !8      0                                       ; End of BASIC line
+       !16     0                                       ; BASIC end marker


;===============================================================================

main:
        sei
        lda     reg_d030                                ; Map ROM into $C000-$CFFF
        ora     #%00100000
        sta     reg_d030
        lda     r6510                                   ; … I/O into $D000—$DFFF
        ora     #%00000101
        and     #%11111101
        sta     r6510
        lda     #0                                      ; … bank 0 RAM into $0000 - $BFFF
        tax
        tay
        ldz     #%10000011                              ; … and kernel into $E000—$FFFF
        map
        eom
@test_suite:
        lda     #13
        jsr     chrout
        ldx     #<intro_text
        ldy     #>intro_text
        jsr     puts
        jsr     vs_zp
        jsr     vs_zpx
        jsr     vs_abs
        jsr     vs_absx
@done:
        ldx     #<done_text
        ldy     #>done_text
        jsr     puts
-       jmp     -


;===============================================================================
; BIT #$nn verses BIT $nn (opcode $24)

vs_zp_text:    !text "TESTING BIT #IMM AGAINST BIT ZP   ... ", 0
vs_zp:
        ldx     #<vs_zp_text
        ldy     #>vs_zp_text
        jsr     puts
        lda     #$00
        sta     counter
        sta     counter+1
        ldz     #%00100100                              ; Test with N, V and Z flags being cleared initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
        ldz     #%11100110                              ; Test with N, V and Z flags being set initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
@same:                                                  ; In all combinations the flags were the same
        ldx     #<same_text
        ldy     #>same_text
        jmp     puts
@different:                                             ; In one combination the flags were different
        ldx     #<different_text
        ldy     #>different_text
        jsr     puts
        ldx     counter+1
        jsr     puthex
        ldx     counter
        jsr     puthex
        lda     #13
        jmp     chrout
@test:
        ; A = accumulator value for the BIT instruction
        ; X = reserved
        ; Y = temporary
        ; Z = value to reset flags to before each BIT instruction
        lda     #$00
        sta     zp_mem
        sta     vs_zp_mem_value
        tay
-       sty     screen1
--      sta     screen2
        phz                                             ; Reset flags
        plp
        bit     zp_mem                                  ; Do the memory-mode BIT
        php                                             ; Save flags into mem_flags
        ply
        sty     mem_flags
        phz                                             ; Reset flags again
        plp
        bit     #$00                                    ; Do the immediate-mode BIT
        !addr   vs_zp_mem_value = * - 1
        php                                             ; Detect a difference between the memory-mode and immediate-mode flags
        ply
        cpy     mem_flags
        beq     +
        inw     counter
+       inc                                             ; Increment A and repeat until A wraps back to zero
        bne     --
        ldy     zp_mem                                  ; Increment zp_mem and vs_zp_mem_value
        iny
        sty     zp_mem
        sty     vs_zp_mem_value
        bne     -                                       ; … and repeat until it wraps back to zero
        rts


;===============================================================================
; BIT #$nn verses BIT $nn,X (opcode $34)

vs_zpx_text:    !text "TESTING BIT #IMM AGAINST BIT ZP,X ... ", 0
vs_zpx:
        ldx     #<vs_zpx_text
        ldy     #>vs_zpx_text
        jsr     puts
        lda     #$00
        sta     counter
        sta     counter+1
        ldz     #%00100100                              ; Test with N, V and Z flags being cleared initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
        ldz     #%11100110                              ; Test with N, V and Z flags being set initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
@same:                                                  ; In all combinations the flags were the same
        ldx     #<same_text
        ldy     #>same_text
        jmp     puts
@different:                                             ; In one combination the flags were different
        ldx     #<different_text
        ldy     #>different_text
        jsr     puts
        ldx     counter+1
        jsr     puthex
        ldx     counter
        jsr     puthex
        lda     #13
        jmp     chrout
@test:
        ; A = accumulator value for the BIT instruction
        ; X = address of zp_mem
        ; Y = temporary
        ; Z = value to reset flags to before each BIT instruction
        ldx     #02
        lda     #$00
        sta     zp_mem
        sta     vs_zpx_mem_value
        tay
-       sty     screen1
--      sta     screen2
        phz                                             ; Reset flags
        plp
        bit     zp_mem-2,X                              ; Do the memory-mode BIT
        php                                             ; Save flags into mem_flags
        ply
        sty     mem_flags
        phz                                             ; Reset flags again
        plp
        bit     #$00                                    ; Do the immediate-mode BIT
        !addr   vs_zpx_mem_value = * - 1
        php                                             ; Detect a difference between the memory-mode and immediate-mode flags
        ply
        cpy     mem_flags
        beq     +
        inw     counter
+       inc                                             ; Increment A and repeat until A wraps back to zero
        bne     --
        ldy     zp_mem                                  ; Increment zp_mem and vs_zpx_mem_value
        iny
        sty     zp_mem
        sty     vs_zpx_mem_value
        bne     -                                       ; … and repeat until it wraps back to zero
        rts


;===============================================================================
; BIT #$nn verses BIT $abs (opcode $2C)

vs_abs_text:    !text "TESTING BIT #IMM AGAINST BIT ABS  ... ", 0
vs_abs:
        ldx     #<vs_abs_text
        ldy     #>vs_abs_text
        jsr     puts
        lda     #$00
        sta     counter
        sta     counter+1
        ldz     #%00100100                              ; Test with N, V and Z flags being cleared initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
        ldz     #%11100110                              ; Test with N, V and Z flags being set initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
@same:                                                  ; In all combinations the flags were the same
        ldx     #<same_text
        ldy     #>same_text
        jmp     puts
@different:                                             ; In one combination the flags were different
        ldx     #<different_text
        ldy     #>different_text
        jsr     puts
        ldx     counter+1
        jsr     puthex
        ldx     counter
        jsr     puthex
        lda     #13
        jmp     chrout
@test:
        ; A = accumulator value for the BIT instruction
        ; X = reserved
        ; Y = temporary
        ; Z = value to reset flags to before each BIT instruction
        lda     #$00
        sta     abs_mem
        sta     vs_abs_mem_value
        tay
-       sty     screen1
--      sta     screen2
        phz                                             ; Reset flags
        plp
        bit     abs_mem                                 ; Do the memory-mode BIT
        php                                             ; Save flags into mem_flags
        ply
        sty     mem_flags
        phz                                             ; Reset flags again
        plp
        bit     #$00                                    ; Do the immediate-mode BIT
        !addr   vs_abs_mem_value = * - 1
        php                                             ; Detect a difference between the memory-mode and immediate-mode flags
        ply
        cpy     mem_flags
        beq     +
        inw     counter
+       inc                                             ; Increment A and repeat until A wraps back to zero
        bne     --
        ldy     abs_mem                                 ; Increment abs_mem and vs_abs_mem_value
        iny
        sty     abs_mem
        sty     vs_abs_mem_value
        bne     -                                       ; … and repeat until it wraps back to zero
        rts


;===============================================================================
; BIT #$nn verses BIT $abs,X (opcode $3C)

vs_absx_text:    !text "TESTING BIT #IMM AGAINST BIT ABS,X... ", 0
vs_absx:
        ldx     #<vs_absx_text
        ldy     #>vs_absx_text
        jsr     puts
        lda     #$00
        sta     counter
        sta     counter+1
        ldz     #%00100100                              ; Test with N, V and Z flags being cleared initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
        ldz     #%11100110                              ; Test with N, V and Z flags being set initially
        stz     screen0
        bsr     @test
        lda     counter
        ora     counter+1
        bne     @different
@same:                                                  ; In all combinations the flags were the same
        ldx     #<same_text
        ldy     #>same_text
        jmp     puts
@different:                                             ; In one combination the flags were different
        ldx     #<different_text
        ldy     #>different_text
        jsr     puts
        ldx     counter+1
        jsr     puthex
        ldx     counter
        jsr     puthex
        lda     #13
        jmp     chrout
@test:
        ; A = accumulator value for the BIT instruction
        ; X = fixed at 2
        ; Y = temporary
        ; Z = value to reset flags to before each BIT instruction
        ldx     #2
        lda     #$00
        sta     abs_mem
        sta     vs_absx_mem_value
        tay
-       sty     screen1
--      sta     screen2
        phz                                             ; Reset flags
        plp
        bit     abs_mem-2,X                             ; Do the memory-mode BIT
        php                                             ; Save flags into mem_flags
        ply
        sty     mem_flags
        phz                                             ; Reset flags again
        plp
        bit     #$00                                    ; Do the immediate-mode BIT
        !addr   vs_absx_mem_value = * - 1
        php                                             ; Detect a difference between the memory-mode and immediate-mode flags
        ply
        cpy     mem_flags
        beq     +
        inw     counter
+       inc                                             ; Increment A and repeat until A wraps back to zero
        bne     --
        ldy     abs_mem                                 ; Increment abs_mem and vs_absx_mem_value
        iny
        sty     abs_mem
        sty     vs_absx_mem_value
        bne     -                                       ; … and repeat until it wraps back to zero
        rts


;===============================================================================
puthex:
        ; Prints the X register as a hexidecimal
        ; Uses A
        txa
        lsr:lsr:lsr:lsr
        jsr     +
        txa
+       and     #$0F
        cmp     #10
        bcc     +
        clc
        adc     #6
+       adc     #48
        jmp     chrout

puts:
        ; Prints a null-terminated string. Max 255 chars.
        ; X = LSB of the string
        ; Y = MSB of the string
        ; Uses A
        stx     tmp_ptr                                 ; Put Y:X into tmp_ptr
        sty     tmp_ptr+1
        ldy     #$00
-       lda     (tmp_ptr),Y                             ; Output each character
        beq     +
        jsr     chrout
        iny
        bne     -
+       rts


;===============================================================================

intro_text:     !text "BIT OPCODE TESTER", 13, 0
done_text:      !text "DONE", 0
same_text:      !text "SAME", 13, 0
different_text: !text "DIFFERENT ", 0
