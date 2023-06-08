/**
 * Archivo: startup.S
 * Función: Realiza la inicialización básica del uP
 * Autor: Ferreyro
 **/

/* Referencias a funciones externas */
.extern UND_Handler
.extern SVC_Handler
.extern PREF_Handler
.extern ABT_Handler
.extern IRQ_Handler
.extern FIQ_Handler

.global _start
.extern __gic_init

/* Referencia a variables o simbolos externos */
.extern _ISR_VECTORS_BASE
.extern __isr_table_start__

.extern _reset_vector
.extern __bss_start
.extern __bss_end


.extern __irq_stack_top__
.extern __fiq_stack_top__
.extern __svc_stack_top__
.extern __abt_stack_top__
.extern __und_stack_top__
.extern __sys_stack_top__


/* Tamaños en Public RAM
    .equ es como un define
    .equ [etiqueta], [valor]
    Solo que no reemplaza con su valor. Por ejemplo:
        .equ pepe, 5
        .equ juan, pepe+3
        Mov R0, #juan*3
    En el R0 no va a decir 8*3, si no 5+3*8 */
.equ _PUB_RAM_SYS_STACK_SIZE, 256
.equ _PUB_RAM_IRQ_STACK_SIZE, 256
.equ _PUB_RAM_FIQ_STACK_SIZE, 8
.equ _PUB_RAM_SVC_STACK_SIZE, 8
.equ _PUB_RAM_ABT_STACK_SIZE, 8
.equ _PUB_RAM_UND_STACK_SIZE, 8

/*
    Definimos bits del CPSR para los diferentes modos

    CPSR: Current Program Status Register - Ver ARM B1
    El SPSR posee la misma estructura que el CPSR, solo que se refiere al
    "Saved Program Status Register".
*/

.equ USR_MODE, 0x10    /* USER       - Encoding segun ARM B1.3.1 (pag. B1-1139): 10000 - Bits 4:0 del CPSR */
.equ FIQ_MODE, 0x11    /* FIQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10001 - Bits 4:0 del CPSR */
.equ IRQ_MODE, 0x12    /* IRQ        - Encoding segun ARM B1.3.1 (pag. B1-1139): 10010 - Bits 4:0 del CPSR */
.equ SVC_MODE, 0x13    /* Supervisor - Encoding segun ARM B1.3.1 (pag. B1-1139): 10011 - Bits 4:0 del CPSR */
.equ ABT_MODE, 0x17    /* Abort      - Encoding segun ARM B1.3.1 (pag. B1-1139): 10111 - Bits 4:0 del CPSR */
.equ UND_MODE, 0x1B    /* Undefined  - Encoding segun ARM B1.3.1 (pag. B1-1139): 11011 - Bits 4:0 del CPSR */
.equ SYS_MODE, 0x1F    /* System     - Encoding segun ARM B1.3.1 (pag. B1-1139): 11111 - Bits 4:0 del CPSR */
.equ I_BIT,    0x80    /* Mask bit I - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 7 del CPSR */
.equ F_BIT,    0x40    /* Mask bit F - Encoding segun ARM B1.3.3 (pag. B1-1149) - Bit 6 del CPSR */

/* Modo de funcionamiento: arm (32b instructions) */
.code 32

/* Hasta este momento, no hay nada inicializado */
.section ._start_code
_table_start:
/*
Esta sección es la lista de handlers. Tiene que copiarse a la dirección 0. Entonces al programar
el GIC, ante una interrupción, debe saltar a la posición x de memoria, que debe ser una
de las posiciones de la tabla. Ahí se ejecuta el handler correspondiente.

Creo que la idea es que en una itnerrupcion, yo ya se que tengo que saltar a la posicion '3' de la tabla
y ahi va a decir 'LDR PC, addr_PREF_Handler', por lo que va a 'addr_PREF_Handler', osea a 'PREF_Handler'
*/
    LDR PC, addr__reset_vector
    LDR PC, addr_UND_Handler
    LDR PC, addr_SVC_Handler
    LDR PC, addr_PREF_Handler
    LDR PC, addr_ABT_Handler
    LDR PC, addr_start
    LDR PC, addr_IRQ_Handler
    LDR PC, addr_FIQ_Handler

/* aca se deifne un label addr__, y se guarda en memoria la direccion __reset_vector asociada */
addr__reset_vector:  .word _reset_vector
addr_UND_Handler  :  .word UND_Handler
addr_SVC_Handler  :  .word SVC_Handler
addr_PREF_Handler :  .word PREF_Handler
addr_ABT_Handler  :  .word ABT_Handler
addr_start        :  .word _start
addr_IRQ_Handler  :  .word IRQ_Handler
addr_FIQ_Handler  :  .word FIQ_Handler

_start:

/* Limpiamos la sección BSS - Sugerido por Starterware */
_clear_BSS:
    LDR R0, =__bss_start__      /* Dirección de inicio de la sección BSS (pública) */
    LDR R1, =__bss_end__        /* Dirección final de la sección BSS (pública) */
    MOV R2, #0                  /* Copiamos el valor "0" en R2 */
    CMP R0,R1
    BEQ _TABLE_COPY             /* Para el caso particular en el que bss está vacía (__bss_start__ == __bss_end__) no hay nada que inicializar, asi que me salteo el loop */
_LOOP:
    STR R2, [R0], #4            /* El contenido de R2 es cargado en "lo apuntado" por R0, luego incrementa la dirección de R0 */
    CMP R0, R1                  /* Comparamos R0 y R1, que poseen las direcciones de interés */
    BLE _LOOP                   /* Mientras la comparación anterior sea falsa, se vuelve a _LOOP */


_TABLE_COPY:
    MOV R0, #0
    LDR R1, = _table_start  /* pongo la direccion _table_start, en R1 */
    LDR R2, = _start

_TABLE_LOOP: /* copia la tabla, a partir de la direccion 0 */
    LDR R3, [ R1 ], #4      /* pongo el contenido de R1 (contenido de _table_start) en R3, y aumento R1 en 4 */
    STR R3, [ R0 ], #4      /* pongo eso que hagarre de table_start, en la posicion R0 (0 la primera vez). Basicamente, copio la table a partir de la direccion 0 */
    CMP R1, R2              /* DUDA, creo que se asume que la tabla es mas chica que el espacio entre _table_start y _start. Y si sobra espacio, noe staria rellenando con cosas mas alla de la tabla, que no se que hay? */
    BNE _TABLE_LOOP


_STACK_INIT:
    /* Inicializamos los stack pointers para los diferentes modos de funcionamiento */
    MSR cpsr_c,#(IRQ_MODE | I_BIT |F_BIT)
    LDR SP,=__irq_stack_top__     /* IRQ stack pointer */

    MSR cpsr_c,#(FIQ_MODE | I_BIT |F_BIT)
    LDR SP,=__fiq_stack_top__     /* FIQ stack pointer */

    MSR cpsr_c,#(SVC_MODE | I_BIT |F_BIT)
    LDR SP,=__svc_stack_top__     /* SVC stack pointer */

    MSR cpsr_c,#(ABT_MODE | I_BIT |F_BIT)
    LDR SP,=__abt_stack_top__     /* ABT stack pointer */

    MSR cpsr_c,#(UND_MODE | I_BIT |F_BIT)
    LDR SP,=__und_stack_top__     /* UND stack pointer */

    MSR cpsr_c,#(SYS_MODE | I_BIT |F_BIT)
    LDR SP,=__sys_stack_top__     /* SYS stack pointer */

    LDR R10, =__gic_init
    MOV LR, PC /* estas dos lineas es lo mismo que hacer BLX R10 */
    BX R10

    MRS R0, cpsr
    BIC R0, R0, #0x80 /* R0 = R0 & 0x80 (0x80 = 1000 0000) */
    MSR cpsr_c, R0

    SWI 95 /* el 95 es arbitrario. SWI genera software interrupt, pasando a modo privilegiado SVC dentro del mismo core. SGI seria multicore
                Segun el pdf interrupciones, SWI fue reemplazada por SVC que no necesita ningun valor */

idle:
    WFI /* whait for interrupt, y en modo bajo consumo. SIEMPRE PONER ESTE MODO, OBLIGATORIO */
    B idle

.end
