; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_call_dois_args.sndy

; Mapa de memoria zero page
; v_E                  = $00 ; E
; v_GA                 = $01 ; GA
; v_GD                 = $02 ; GD
; v_A                  = $03 ; A
; v_D                  = $04 ; D
; v___arg0             = $05 ; __arg0
; v___arg1             = $06 ; __arg1

; Variavel verificada no teste: E em $00

*=$0600
    JMP __main
fn_G:
    LDA $05
    STA $03
    LDA $06
    STA $04
    LDA $03
    CLC
    ADC $04
    STA $00
    LDA $00
    RTS
__main:
    LDA $01
    STA $05
    LDA $02
    STA $06
    JSR fn_G
    STA $00
__applause:
    BRK
