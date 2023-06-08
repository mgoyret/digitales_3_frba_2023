#include "../inc/gic.h"

__attribute__((section(".text"))) void __gic_init()
{
    _gicc_t* const GICC0 = (_gicc_t*)GICC0_ADDR;
    _gicd_t* const GICD0 = (_gicd_t*)GICD0_ADDR;

    GICC0->PMR           = 0x000000F0;  // ver Table 4-48 Priority mask. Permite todas las interrupciones
    GICD0->ISENABLER[1] |= 0x00000010;  // bit 33 GIC, SW interrupt. DUDA: En realidad mi SW es del u, no del GIC. PERO SI SACO ESTO, EL TIMER NO ANDA...

    GICD0->ISENABLER[1] |= 0x00010000;  // bit 36 del GIC. Timer 0-1
    GICD0->TYPER         = 0x00000001;  // Fixed value indicating 64 external interrupt input lines are available for this GIC.

    GICC0->CTLR          = 0x00000001;  // habilita la interfaz con la cpu
    GICD0->CTLR          = 0x00000001;  // habilita el distribuidor
}
