.global _start                      // declaro el punto de entrada al programa. Luego lo uso
.extern _PUBLIC_DATA_START          // declaracion de simbolo externo
.extern DATA_ORIG                   // ""
.extern DATA_SIZE                   // ""

.SECTION .data                      // empieza seccion .data
    var: .asciz "hola mundo"        // inicializacion de variable asci temrinada en cero (asciz) "hola mundo\0"

.SECTION .init                          // empieza seccion init
    _start:                             // indico cual es el inicio del programa
        LDR R0, = _PUBLIC_DATA_START    // carga direccion _PUBLIC_DATA_START en R0
        LDR R1, = DATA_ORIG             // ""
        LDR R2, = DATA_SIZE             // ""
        BL memcpy_asm                   // branch and link a la subrutina memcpy_asm. Los parametros los apse en R0, R1 y R2 por el abi
        LDR R12 ,= salto                // luego de copiar los datos, va a un B. ubicado en la posicion 'salto'
        BX R12                          //
    memcpy_asm:                         // implementacion en ASSM de la subrutina ( seria memcpy() en c ).
        LDRB R3, [R1]
        STRB R3, [R0]
        ADD R0, R0, #1
        ADD R1, R1, #1
        SUBS R2, R2, #1
        BNE memcpy_asm                  // si la resta anterior no es cero, hace otro ciclo
        BX lr                           // sale de la subrutina

.SECTION .text
    salto:
        B .
