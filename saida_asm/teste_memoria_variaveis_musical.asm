; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_memoria_variaveis_musical.sndy

; Mapa de memoria zero page
; v_G                  = $00 ; G
; v_D                  = $01 ; D
; v_A                  = $02 ; A

; Variavel verificada no teste: G em $00

*=$0600
__main:
    LDA #3
    STA $00
    LDA #4
    STA $01
    LDA $00
    CLC
    ADC $01
    STA $02
__applause:
    BRK
