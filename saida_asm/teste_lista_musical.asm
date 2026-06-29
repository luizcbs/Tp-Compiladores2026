; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_lista_musical.sndy

; Mapa de memoria zero page
; v_GA                 = $00 ; GA[]
; v_DE                 = $05 ; DE
; v_EAD                = $06 ; EAD

; Variavel verificada no teste: GA em $00

*=$0600
__main:
    LDA #0
    STA $05
    LDA #42
    STA $00
    LDA $00
    STA $06
__applause:
    JMP __applause
