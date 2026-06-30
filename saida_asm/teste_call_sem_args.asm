; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_call_sem_args.sndy

; Mapa de memoria zero page
; v_E                  = $00 ; E
; v_A                  = $01 ; A

; Variavel verificada no teste: E em $00

*=$0600
    JMP __main
fn_G:
    LDA #0
    STA $01
    LDA $01
    RTS
__main:
    JSR fn_G
    STA $00
__applause:
    BRK
