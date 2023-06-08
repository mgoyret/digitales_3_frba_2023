/* Traducción de direcciones virtuales a físicas
 0x70000000 - 0x7000FFFF -> 0x70010000 - 0x7001FFFF
 0x80000000 - 0x8000FFFF -> 0x70800000 - 0x7080FFFF
 El resto de las direcciones virtuales deben ser inválidas.
 Hecho por Darío Alpern el 6 de junio de 2023. */

/* Más info en https://developer.arm.com/documentation/den0013/d/Boot-Code/Booting-a-bare-metal-system */

/* MARCOS: esto esta mal, hay que hacerlo con el linker dijo... */
      .equ tabla_primer_nivel, 0x70080000
      .equ tabla_segundo_nivel1, 0x70090000
      .equ tabla_segundo_nivel2, 0x700A0000
      .equ DIR_FISICA1, 0x70010000
      .equ DIR_FISICA2, 0x70800000
      .equ longitud_tablas, tabla_segundo_nivel2 + 0x10000 - tabla_primer_nivel
      .global _start

_start:

/* Para probar la paginación, escribir 0x12345678 en la
 dirección física 0x70800000. Luego de la habilitación
 de la MMU, deberíamos leer este valor en la dirección
 0x80000000. */
      LDR R0, =0x70800000 // MARCOS: si quisiera leer esta direccion luego de la operacion, seria una pagina no presente o invalida
      LDR R1, =0x12345678
      STR R1, [R0]

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
      LDR R0, =tabla_primer_nivel + 0x700*4 // *4 porque cada tabla tiene 4 bytes. Convertimos al indice en un offset
      // Bits 31-10: BADDR (dirección base tabla nivel 2)
      // 9: No usado
      // 8-5: dominio
      // 4: cero,
      // 3: NS (no seguro),
      // 2: PXN (no ejecución)
      // 1: cero,
      // 0: uno.
      LDR R1, =tabla_segundo_nivel1 + 1
      STR R1, [R0] // guardo entrada a la segunda tabla, en la abse de la primera

// Índice 0x800 apunta a tabla de páginas.
      LDR R0, =tabla_primer_nivel + 0x800*4
      // Bits 31-10: BADDR (dirección base tabla nivel 2)
      // 9: No usado
      // 8-5: dominio
      // 4: cero,
      // 3: NS (no seguro),
      // 2: PXN (no ejecución)
      // 1: cero,
      // 0: uno.
      LDR R1, =tabla_segundo_nivel2 + 1
      STR R1, [R0]

// Inicializar entrada 0x10 de la primera tabla de segundo nivel.
// AP 011 significa acceso lectura/escritura.
      LDR R0, =tabla_segundo_nivel1 + 0x10*4
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
      LDR R1, =DIR_FISICA1 + 0x30 + 2 //0x30 sale de AP1 y AP0. Lectura/escritura
      STR R1, [R0, #0]

// Inicializar entrada 0x00 de la segunda tabla de segundo nivel.
// AP 011 significa acceso lectura/escritura.
      LDR R0, =tabla_segundo_nivel2 + 0x00*4
      // mismos comentarios bit a bit que en el paso anterior
      LDR R1, =DIR_FISICA2 + 0x30 + 2
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

      B .
