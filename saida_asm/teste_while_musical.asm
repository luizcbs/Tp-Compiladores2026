; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_while_musical.sndy

; Mapa de memoria zero page
; v_GG                 = $00 ; GG
; v_GA                 = $01 ; GA
; v_AD                 = $02 ; AD
; v_DE                 = $03 ; DE

; Variavel verificada no teste: GG em $00

*=$0600
__main:
    LDA #0
    STA $00
    LDA #1
    STA $01
    LDA #5
    STA $02
    LDA $00
    CMP $02
    BCC __cmp_true_0
__cmp_false_0:
    LDA #0
    STA $03
    JMP __cmp_end_0
__cmp_true_0:
    LDA #1
    STA $03
__cmp_end_0:
L0:
    LDA $03
    BEQ L1
    LDA $00
    CLC
    ADC $01
    STA $00
    LDA $00
    CMP $02
    BCC __cmp_true_1
__cmp_false_1:
    LDA #0
    STA $03
    JMP __cmp_end_1
__cmp_true_1:
    LDA #1
    STA $03
__cmp_end_1:
    JMP L0
L1:
__applause:
    BRK
