; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_call_um_arg.sndy

; Mapa de memoria zero page
; v_E                  = $00 ; E
; v_D                  = $01 ; D
; v_A                  = $02 ; A
; v___arg0             = $03 ; __arg0

; Variavel verificada no teste: E em $00

*=$0600
    JMP __main
fn_G:
    LDA $03
    STA $02
    LDA $02
    STA $00
    LDA $00
    RTS
__main:
    LDA $01
    STA $03
    JSR fn_G
    STA $00
__applause:
    JMP __applause
