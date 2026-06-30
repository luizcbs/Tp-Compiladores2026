; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_call_literais.sndy

; Mapa de memoria zero page
; v_E                  = $00 ; E
; v_A                  = $01 ; A
; v_D                  = $02 ; D
; v___arg0             = $03 ; __arg0
; v___arg1             = $04 ; __arg1

; Variavel verificada no teste: E em $00

*=$0600
    JMP __main
fn_G:
    LDA $03
    STA $01
    LDA $04
    STA $02
    LDA $01
    CLC
    ADC $02
    STA $00
    LDA $00
    RTS
__main:
    LDA #1
    STA $03
    LDA #2
    STA $04
    JSR fn_G
    STA $00
__applause:
    BRK
