ENTRY(_start)                                   /* aclara que el punto de entrada del programa es '_start' */

_PUBLIC_ROM_START = 0x70010000;                 /* Definicion de simbolo */
_PUBLIC_PROGRAM_DEST = 0x70030000;              /* "" */
_PUBLIC_DATA_START = 0x70100000;                /* "" Es la direccion a donde el enunciado pide copiar el string */

MEMORY      /* definición del mapa de memoria */
{
    ROM : org = _PUBLIC_ROM_START, len = 0x10000
    RAM	: org = _PUBLIC_PROGRAM_DEST, len = 0x10000
    DATA : org = _PUBLIC_DATA_START, len = 0x10000

}


SECTIONS        /* definición de las secciones y sus ubicaciones en memoria */
{
    /*
        A continuacion ubico las secciones en memoria. El '> ROM' deja al
        sistema que se encargue de ubicarla donde le parezca, dentro de la region
        ROM. Le damos cierta libertad.
        Si ponemos:
            .init : AT(_PUBLIC_ROM_START)
        no tendria sentido, ya que damos la estamos forzando la ubicacion exacta en memoria.
        Pierde el sentido el '> ROM'.
    */

    .init :
    {
        *(.init*)
    } > ROM

    .text :
    {
        *(.text*)
    } > RAM

    .data :
    {
        *(.data*)
    } > ROM
}

/*
    A continuacion definimos dos simbolos que dependen de la
    seccion .data, por lo que recien ahora podemos definirlos
    Como en el archivo ASM hicimos que la seccion '.data' unicamente
    contenga al string "hola mundo", entonces sabemos que la direccion
    y tamano de esta seccion, son la direccion y tamano del string
    a copiar.
*/
DATA_SIZE = SIZEOF(.data);
DATA_ORIG = LOADADDR(.data);