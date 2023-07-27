/* definiciones necesarias: formato de salida, arquitectura y punto de entrada */
OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_reset_vector)

/* definiciones de simbolos necesarios */
_ISR_TABLE_START = 0x00000000;      /* offset 1: 000*4     offset2: 00*4    offsetPage 000 */
_PUBLIC_RAM_INIT = 0x70010000;      /* offset 1: 700*4     offset2: 10*4    offsetPage 000 */
_PUBLIC_STACK_INIT = 0x70020000;    /* offset 1: 700*4     offset2: 20*4    offsetPage 000 */
_GIC_INIT = 0x1E000000;
_TIMER0_INIT = 0x10011000;

_KERNEL_START = 0x70030000;

/* hay 4 entradas de 1er nivel */  /* 0x1E84800 */ /* 0x71e94800 */
/*////////////////////////////////////////////////////////////*/

TABLE_START = 70080000; /* TTBR0 */
SIZE_TABLA_1 = 16K;    /* 2^12 * 4 */
SIZE_TABLA_2 = 1K;     /* 2^8 * 4 */
/* cada pagina pesa 4KB */

/* CALCULO DE LOS PESOS
Una tabla de nivel 1, si la direccion virtual es de 12b (3 hex) para nivel 1 y 8b (2hxe) para nivel 2
Entonces el nivel 1 tiene 2^12=4096 entradas. Cada entrada es una direccion de 4B, por lo que una tabla
de nivel 1 pesa 4096*4 = 16K
Para nivel 2, 2^8=256 y 256*4 = 1k */
/*////////////////////////////////////////////////////////////*/
C_STACK_SIZE   = 4K;
IRQ_STACK_SIZE = 128;
FIQ_STACK_SIZE = 128;
SVC_STACK_SIZE = 128;
ABT_STACK_SIZE = 128;
UND_STACK_SIZE = 128;

/* definición del mapa de memoria */
MEMORY
{
    /* creamos una region para cada cosa, para poder paginarlas bien */
    public_ram	: org = _PUBLIC_RAM_INIT, len = 32M /* 1E84800 */
    public_stack : org = _PUBLIC_STACK_INIT, len = 1M
    memory_section_gic : org = _GIC_INIT, len = 4096 /* PARA QUE */
    public_kernel : org = _KERNEL_START, len = 1M; /*#####################33*/
}

/* definición de las secciones */
SECTIONS
{
    __isr_table_start__ = _ISR_TABLE_START;
    . = _PUBLIC_RAM_INIT;
    .start_code : /* chequear si es esto */
    {
        *(._reset_vector_code*)
        *(._start_code*)
        *(.text_pub*)
        *(.start_code*)
    } > public_ram

    .data :
    {
        *(.data*)
    } > public_ram
/*en el linker van direcciones y en el ASM las longitudes*/
    .bss :
    {
        . = ALIGN(4);
        __bss_start__ = .;
        *(.bss*)
        __bss_end__ = .;
    } > public_ram

    .stack :
    {
        __stack_start__ = .;
        . += IRQ_STACK_SIZE;
        . = ALIGN(4);
        __irq_stack_top__ = .;

        . += FIQ_STACK_SIZE;
        . = ALIGN(4);
        __fiq_stack_top__ = .;

        . += SVC_STACK_SIZE;
        . = ALIGN(4);
        __svc_stack_top__ = .;

        . += ABT_STACK_SIZE;
        . = ALIGN(4);
        __abt_stack_top__ = .;

        . += UND_STACK_SIZE;
        . = ALIGN(4);
        __und_stack_top__ = .;

        . += C_STACK_SIZE;
        . = ALIGN(4);
        __sys_stack_top__ = .;

        __stack_end__ = .;
    } > public_stack

    . = _KERNEL_START;
    .tablas ALIGN(16384):
    {
        _kernel_data_start = .;
        *(.tablas*)
        _kernel_data_end = .;
    } > public_kernel
    longitud_tablas = SIZEOF(.tablas);

}

/*
    .= TABLE_START;
    .kdata :
    {
        inicio_tabla_1 = .;
        *(.kdata*)
        . += SIZE_TABLA_1;
        . = ALIGN(4);
        fin_tabla_1 = .;
        
        inicio_tabla_2_1 = .;
        . += SIZE_TABLA_2; 
        . = ALIGN(4);
        fin_tabla_2_1 = .;

        inicio_tabla_2_2 = .;
        . += SIZE_TABLA_2; 
        . = ALIGN(4);
        fin_tabla_2_2 = .;
    }
*/
