/**
 * Archivo: exception_handlers.s
 * Función: manejadores de las excepciones
 * Autor: Ferreyro
 **/

.global UND_Handler
.global SVC_Handler
.global PREF_Handler
.global ABT_Handler
.global IRQ_Handler
.global FIQ_Handler

.section .data
    string_INV: .asciz "INV" /* invalid instruction -> undefined instruction UND_Handler */
    string_MEM: .asciz "MEM" /* abort */
    string_SVC: .asciz "SVC"
    string_IRQ: .asciz "IRQ" /* no lo pide el enunciado, pero para debug sirve */

    var_cnt:    .word 0 //hicimos contador de 32b en timer.c

.section .text_handlers

UND_Handler:
    SUB LR, LR, #0 /* pag 86 ppt 'ARMv7 - Gestión de Interrupciones' */
    PUSH {R0-R3}
    LDR R10, =string_INV
    POP {R0-R3}
    MOVS PC, LR
/*  MOVS PC, LR:
        MOV R5, LR
        MRS R4, SPSR
        MSR CPSR, R4
        BX R5
*/

SVC_Handler: /* aca viene al hacer SWI 95 */
    SUB LR, LR, #0 // pag 86 ppt 'ARMv7 - Gestión de Interrupciones'
    PUSH {R0-R3}
    //LDR R10, =string_SVC
    SVC #11
    POP {R0-R3}
    MOVS PC, LR


PREF_Handler:
    LDR R10,=#0x0300
    RFEFD   SP!

ABT_Handler:
    SUB LR, LR, #8 // pag 86 ppt 'ARMv7 - Gestión de Interrupciones'
    PUSH {R0-R3, LR} // creo que si modifique el LR, lo guardo... ver ppt 91
    LDR R10, =string_MEM
    POP {R0-R3}
    MOVS PC, LR


IRQ_Handler:
    SUB LR, LR, #4 // pag 86 ppt 'ARMv7 - Gestión de Interrupciones'
    PUSH {R0-R3}    // ver ppt 91. Hace stmfd r13 ! , {r0´r 3 , r14}. No me termina de cerrar por que guarda el LR
    LDR R10, =string_IRQ

    LDR R0, =var_cnt
    LDR R1, [R0]
    ADD R1, R1, #1
    STR R1, [R0]

    POP {R0-R3}
    MOVS PC, LR

FIQ_Handler:
    LDR R10,=#0x0600
    RFEFD   SP!
