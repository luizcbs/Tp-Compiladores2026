; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_funcao_musical.sndy

; Mapa de memoria zero page
; v_AG                 = $00 ; AG
; v_AA                 = $01 ; AA
; v_EE                 = $02 ; EE
; v_DD                 = $03 ; DD
; v___arg0             = $04 ; __arg0
; v___arg1             = $05 ; __arg1

; Variavel verificada no teste: AG em $00

*=$0600
    JMP __main
fn_GG:
    LDA $04
    STA $01
    LDA $05
    STA $02
    LDA $01
    CLC
    ADC $02
    STA $03
    LDA $03
    RTS
__main:
    LDA #10
    STA $04
    LDA #20
    STA $05
    JSR fn_GG
    STA $00
__applause:
    BRK
