; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/exemplo_apresentacao_tp4.sndy

; Mapa de memoria zero page
; v_G                  = $00 ; G
; v_D                  = $01 ; D
; v_A                  = $02 ; A
; v_E                  = $03 ; E
; v_AE                 = $04 ; AE
; v_EG                 = $05 ; EG

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
    STA $05
    JMP __cmp_end_0
__cmp_true_0:
    LDA #1
    STA $05
__cmp_end_0:
    LDA $05
    BEQ L0
    LDA #1
    STA $04
    JMP L1
L0:
    LDA #0
    STA $04
L1:
__applause:
    BRK
