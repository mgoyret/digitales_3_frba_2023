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
.extern longitud_tablas

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


/*
.section .data
    var_inicio_tabla_1: .word 0x70800000;
    var_fin_tabla_1: .word 0; //var_inicio_tabla_1+SIZE_TABLA_1;
    var_inicio_tabla_2_1: .word 0;// contenido de [inicio_tabla_1 + 700*4]
    var_fin_tabla_2_1: .word 0; //inicio_tabla_2_1+SIZE_TABLA_2;
    var_inicio_tabla_2_2: .word 0;// contenido de [inicio_tabla_1 + 000*4]
    var_fin_tabla_2_2: .word 0; //inicio_tabla_2_2+SIZE_TABLA_2;
*/

/* Hasta este momento, no hay nada inicializado */
.section .text // por que le puso .start_code ??

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
            ciclo_borrado:
                STRB R0, [R1], #1
                SUBS R2, #1 // IMPORTANTE PONER SUBS. Con SUB se va a colgar
                BNE ciclo_borrado

            // Inicializar ambas entradas de la tabla de primer nivel.
            // Índice 0x700 apunta a tabla de páginas.
            // 700 es por Text y stack
            LDR R0, = tabla_primer_nivel + 0x700*4 // *4 porque cada tabla tiene 4 bytes. Convertimos al indice en un offset
              // Bits 31-10: BADDR (dirección base tabla nivel 2)
              // 9: No usado
              // 8-5: dominio
              // 4: cero,
              // 3: NS (no seguro),
              // 2: PXN (no ejecución)
              // 1: cero,
              // 0: uno.
            LDR R1, =tabla_segundo_nivel_1 + 1
            STR R1, [R0] // guardo entrada a la segunda tabla, en la abse de la primera

        // Ahora cargamos el GIC
            LDR R0, =tabla_primer_nivel + 0x1E0*4
            LDR R1, =tabla_segundo_nivel_2 + 1
            STR R1, [R0]
        
        // Ahora cargamos el TIMEr 0x100
            LDR R0, =tabla_primer_nivel + 0x100*4
            LDR R1, =tabla_segundo_nivel_3 + 1
            STR R1, [R0]

        // Ahora cargamos tablas handles 0x000
            LDR R0, =tabla_primer_nivel + 0x000*4
            LDR R1, =tabla_segundo_nivel_4 + 1
            STR R1, [R0]


        // Inicializar entrada 0x10 de la primera tabla de segundo nivel.
        // AP 011 significa acceso lectura/escritura.
        // cargamos RAM init
            LDR R0, =tabla_segundo_nivel_1 + 0x10*4
              // Bits 31-12: BADDR (dir. base)
              // 11: nG (no global),
              // 10: S (memoria compartida)
              // 9: AP2 (bits de permisos)
              // 8-6: TEX (atributos de la región de memoria)
              // 5-4: AP1, AP0 (bits de permisos)
              // 3: C (atributos de la región de memoria)
              // 2: B (atributos de la región de memoria)
              // 1: uno
              // 0: XN (la página no se puede ejecutar).
            LDR R1, = _PUBLIC_RAM_INIT  + 0x30 + 2 //0x30 sale de AP1 y AP0. Lectura/escritura
            STR R1, [R0, #0]
        
        // Inicializar entrada 0x00 de la segunda tabla de segundo nivel.
        // AP 011 significa acceso lectura/escritura.
        // cargamos stack
            LDR R0, =tabla_segundo_nivel_1 + 0x20*4
            // mismos comentarios bit a bit que en el paso anterior
            LDR R1, =_PUBLIC_STACK_INIT  + 0x30 + 2
            STR R1, [R0, #0]

        // cargamos gic
            LDR R0, =tabla_segundo_nivel_2 + 0x00*4
            LDR R1, =_GIC_INIT + 0x30 + 2
            STR R1, [R0, #0]

        // cargamos timer
            LDR R0, =tabla_segundo_nivel_3 + 0x11*4
            LDR R1, =_TIMER0_INIT + 0x30 + 2
            STR R1, [R0, #0]

        // cargamos table isr
            LDR R0, =tabla_segundo_nivel_4 + 0x00*4
            LDR R1, =_ISR_TABLE_START + 0x30 + 2
            STR R1, [R0, #0]

        
        // TTRB0 debe apuntar a la tabla de directorio de páginas.
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
////////////////////////////////////////////////////////////////////////////////////////////////////////
    /* Ahora verificamos si saltan las excepciones */
        SVC #11
        nop
        idle:
            WFI /* whait for interrupt, y en modo bajo consumo. SIEMPRE PONER ESTE MODO, OBLIGATORIO */
            B idle

.end
