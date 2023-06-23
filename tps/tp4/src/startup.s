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
.extern __timer_init

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

/* //////////////////////////////////////// */
.extern TABLE_START

.extern SIZE_TABLA_1
.extern SIZE_TABLA_2
/* CALCULO DE LOS PESOS
Una tabla de nivel 1, si la direccion virtual es de 12b (3 hex) para nivel 1 y 8b (2hxe) para nivel 2
Entonces el nivel 1 tiene 2^12=4096 entradas. Cada entrada es una direccion de 4B, por lo que una tabla
de nivel 1 pesa 4096*4 = 16K
Para nivel 2, 2^8=256 y 256*4 = 1k */
.extern longitud_tablas //la obtube al final de la seccion en el linker

/* Modo de funcionamiento: arm (32b instructions) */
.code 32

.section .tablas
/* genero un vloque de memoria con espacio para mis tablas */
    tabla_primer_nivel: //RAM y STACK estan en la misma pagina de 1L
        .space 16384
    tabla_segundo_nivel_1: //stack y text
        .space 1024
    tabla_segundo_nivel_2: //gic
        .space 1024
    tabla_segundo_nivel_3: //timer
        .space 1024
    tabla_segundo_nivel_4: //tablas handlers. 000
        .space 1024


/* Hasta este momento, no hay nada inicializado */
.section .start_code // por que le puso .start_code en lugar de .text??

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

            LDR R10, =__timer_init
            BLX R10

            MRS R0, cpsr
            BIC R0, R0, #0x80 /* R0 = R0 & 0x80 (0x80 = 1000 0000) */
            MSR cpsr_c, R0

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //LDR R0, =0x70800000 // MARCOS: si quisiera leer esta direccion luego de la operacion, seria una pagina no presente o invalida
    //LDR R1, =0x12345678
    //STR R1, [R0]

// Borrar las tablas de paginación. CICLO DE BORRADO
            LDR R1, =tabla_primer_nivel
            LDR R2, =longitud_tablas
            MOV R0, #0

/*  ERROR: El codigo se pierde en este ciclo, no sale a la primer instruccion luego dle ciclo
    el PC se va a la seccion .debug_info
            ciclo_borrado:
                STRB R0, [R1], #1
                SUBS R2, #1 // IMPORTANTE PONER SUBS. Con SUB se va a colgar
                BNE ciclo_borrado
*/
        
            // Ahora armamos las tablas. Ponemos los valores a las entraads de tablas de nivel 1 y 2

            /* Inicializar las 4 entradas de la tabla 1er nivel */

            // text/stack: entrada 0x700 1er nivel. _PUBLIC_RAM_INIT = 0x70010000;, _PUBLIC_STACK_INIT = 0x70020000;
            LDR R0, = tabla_primer_nivel + 0x700*4 // *4 porque cada tabla tiene 4 bytes. Convertimos al indice en un offset
            LDR R1, =tabla_segundo_nivel_1 + 1
            STR R1, [R0] // guardo entrada a la segunda tabla, en la base de la primera

            // GIC: entrada 0x1E0 1er nivel. _GIC_INIT = 0x1E000000
            LDR R0, =tabla_primer_nivel + 0x1E0*4
            LDR R1, =tabla_segundo_nivel_2 + 1
            STR R1, [R0]
        
            // TIEMR: entrada 0x100 1er nivel. _TIMER0_INIT = 0x10011000
            LDR R0, =tabla_primer_nivel + 0x100*4
            LDR R1, =tabla_segundo_nivel_3 + 1
            STR R1, [R0]

            // TABLE_HANDLERS: entrada 0x000 1er nivel. _ISR_TABLE_START = 0x00000000
            LDR R0, =tabla_primer_nivel + 0x000*4
            LDR R1, =tabla_segundo_nivel_4 + 1
            STR R1, [R0]

            /* Ahora ya tengo las posiciones de mi tabla de 1er nivel, cargadas con las direcciones
                de entrada a sus respectivas tablas de segundo nivel
                Procedemos a cargar EN las posiciones de la tabla de 2do nivel, la direccion fisica correspondiente */

            /* Inicializar las 5 entradas de las tablas de 2do nivel */

            // RAM: entrada 0x10 2do nivel. _PUBLIC_RAM_INIT = 0x70010000
            LDR R0, =tabla_segundo_nivel_1 + 0x10*4
            LDR R1, = _PUBLIC_RAM_INIT  + 0x30 + 2 //0x30 sale de AP1 y AP0. Lectura/escritura
            STR R1, [R0, #0]
        
        // AP 011 significa acceso lectura/escritura.
            // stack: entrada 0x20 2do nivel. _PUBLIC_STACK_INIT = 0x70020000
            LDR R0, =tabla_segundo_nivel_1 + 0x20*4
            LDR R1, =_PUBLIC_STACK_INIT  + 0x30 + 2
            STR R1, [R0, #0]

            // gic: entrada 0x00 2do nivel. _GIC_INIT = 0x1E000000
            LDR R0, =tabla_segundo_nivel_2 + 0x00*4
            LDR R1, =_GIC_INIT + 0x30 + 2
            STR R1, [R0, #0]

            // timer: entrada 0x11 2do nivel. _TIMER0_INIT = 0x10011000 
            LDR R0, =tabla_segundo_nivel_3 + 0x11*4
            LDR R1, =_TIMER0_INIT + 0x30 + 2
            STR R1, [R0, #0]

            // TABLE_HANDLERS: entrada 0x00 2do nivel. _ISR_TABLE_START = 0x00000000
            LDR R0, =tabla_segundo_nivel_4 + 0x00*4
            LDR R1, =_ISR_TABLE_START + 0x30 + 2
            STR R1, [R0, #0]

        
            // Apuntamos TTRB0 con la direccion de la base de la tabla 1er nivel
            LDR R0, =tabla_primer_nivel // se carga TTRB[0] puede ser cualquie registro
            MCR p15, 0, R0, c2, c0, 0
            //El resto es para entrar en ese registro. (c2, c0 y 0)
        
            // Todos los dominios van a ser cliente.
            LDR R0, =0x55555555
            MCR p15, 0, R0, c3, c0, 0 // MCR escribe
        
            // Habilitar MMU
            MRC p15, 0,R1, c1, c0, 0    // Leer reg. control. MRC lee
            ORR R1, R1, #0x1            // Bit 0 es habilitación de MMU.
            MCR p15, 0, R1, c1, c0, 0   // Escribir reg. control.

        // para probar que todo ande bien, deberia ir al src/exception_handlers.s:SVC_Handler

        /* ERROR:
            si comento el ciclo de borrado, el codigo sigue. Llega hasta aca y se va el
            pc a 0xc */
        //SVC #11
        idle:
            // whait for interrupt, y en modo bajo consumo. SIEMPRE PONER ESTE MODO, OBLIGATORIO
            SWI #95
            WFI
            B idle
.end
