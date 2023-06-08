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

.section .text_handlers

UND_Handler:
    LDR R10,=#0x0100
    RFEFD   SP!

SVC_Handler: /* aca viene al hacer SWI 95 */
    SUB LR, LR, #0 // pag 86 ppt 'ARMv7 - Gestión de Interrupciones'
    PUSH {R0-R3}
    LDR R10,=#0x0200
    POP {R0-R3}
    MOVS PC, LR
    // RFEFD   SP! me estaba generando un reset que llevaba al pc a _start */

PREF_Handler:
    LDR R10,=#0x0300
    RFEFD   SP!

ABT_Handler:
    LDR R10,=#0x0400
    RFEFD   SP!

IRQ_Handler:
    LDR R10,=#0x0500
    RFEFD   SP!

FIQ_Handler:
    LDR R10,=#0x0600
    RFEFD   SP!
