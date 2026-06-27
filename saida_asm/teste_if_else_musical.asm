; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_if_else_musical.sndy

; Mapa de memoria zero page
; v_GA                 = $00 ; GA
; v_DE                 = $01 ; DE
; v_AE                 = $02 ; AE
; v_EG                 = $03 ; EG

; Variavel verificada no teste: GA em $00

*=$0600
__main:
    LDA #7
    STA $00
    LDA #6
    STA $01
    LDA $00
    CMP $01
    BCS __cmp_true_0
__cmp_false_0:
    LDA #0
    STA $03
    JMP __cmp_end_0
__cmp_true_0:
    LDA #1
    STA $03
__cmp_end_0:
    LDA $03
    BEQ L0
    LDA #1
    STA $02
    JMP L1
L0:
    LDA #0
    STA $02
L1:
__halt:
    JMP __halt
