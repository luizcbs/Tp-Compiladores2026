; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_operadores_musical.sndy

; Mapa de memoria zero page
; v_GG                 = $00 ; GG
; v_GA                 = $01 ; GA
; v_GE                 = $02 ; GE
; v_AA                 = $03 ; AA
; v_AG                 = $04 ; AG
; v_AE                 = $05 ; AE
; v_EE                 = $06 ; EE
; v_EG                 = $07 ; EG
; v_EA                 = $08 ; EA
; v_DD                 = $09 ; DD
; v_DA                 = $0A ; DA
; v_DG                 = $0B ; DG
; v_tmp_mul_a          = $0C ; tmp_mul_a
; v_tmp_mul_b          = $0D ; tmp_mul_b

; Variavel verificada no teste: GG em $00

*=$0600
__main:
    LDA $01
    CLC
    ADC $02
    STA $00
    LDA $04
    SEC
    SBC $05
    STA $03
    LDA $07
    STA $0C
    LDA $08
    STA $0D
    JSR __mul_u8
    STA $06
    LDA $0A
    BEQ __logic_false_0
    LDA $0B
    BEQ __logic_false_0
    JMP __logic_true_0
__logic_false_0:
    LDA #0
    STA $09
    JMP __logic_end_0
__logic_true_0:
    LDA #1
    STA $09
__logic_end_0:
__applause:
    BRK

__mul_u8:
    LDA #0
    LDX $0D
__mul_loop:
    CPX #0
    BEQ __mul_done
    CLC
    ADC $0C
    DEX
    JMP __mul_loop
__mul_done:
    RTS
