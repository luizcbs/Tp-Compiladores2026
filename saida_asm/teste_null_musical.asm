; Assembly MOS6502 gerado pelo compilador Soundy Script
; Arquivo fonte: testes/teste_null_musical.sndy

; Mapa de memoria zero page
; v_GDG                = $00 ; GDG

; Variavel verificada no teste: GDG em $00

*=$0600
__main:
    LDA #0
    STA $00
__halt:
    JMP __halt
