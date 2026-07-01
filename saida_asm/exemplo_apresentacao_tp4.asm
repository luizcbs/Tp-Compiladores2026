; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/exemplo_apresentacao_tp4.sndy

; Mapa de memoria zero page
; v_G                  = $00 ; G
; v_D                  = $01 ; D
; v_A                  = $02 ; A
; v_E                  = $03 ; E
; v_AE                 = $04 ; AE
; v_GG                 = $05 ; GG
; v_GA                 = $06 ; GA
; v_AD                 = $07 ; AD
; v_EG                 = $08 ; EG
; v_DE                 = $09 ; DE

; Variavel verificada no teste: G em $00

*=$0600
__main:
    LDA #3
    STA $00
    LDA #4
    STA $01
    LDA #7
    STA $02
    LDA #6
    STA $03
    LDA #7
    CMP #6
    BCS __cmp_true_0
__cmp_false_0:
    LDA #0
    STA $08
    JMP __cmp_end_0
__cmp_true_0:
    LDA #1
    STA $08
__cmp_end_0:
    LDA $08
    BEQ L0
    LDA #1
    STA $04
    JMP L1
L0:
    LDA #0
    STA $04
L1:
    LDA #0
    STA $05
    LDA #1
    STA $06
    LDA #3
    STA $07
    LDA #0
    CMP #3
    BCC __cmp_true_1
__cmp_false_1:
    LDA #0
    STA $09
    JMP __cmp_end_1
__cmp_true_1:
    LDA #1
    STA $09
__cmp_end_1:
L2:
    LDA $09
    BEQ L3
    LDA $05
    CLC
    ADC $06
    STA $05
    LDA $05
    CMP $07
    BCC __cmp_true_2
__cmp_false_2:
    LDA #0
    STA $09
    JMP __cmp_end_2
__cmp_true_2:
    LDA #1
    STA $09
__cmp_end_2:
    JMP L2
L3:
__applause:
    BRK
