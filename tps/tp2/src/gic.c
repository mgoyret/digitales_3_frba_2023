#include "../inc/gic.h"

__attribute__((section(".text"))) void __gic_init()
{
    _gicc_t* const GICC0 = (_gicc_t*)GICC0_ADDR;
    _gicd_t* const GICD0 = (_gicd_t*)GICD0_ADDR;

    GICC0->PMR           = 0x000000F0;  // ver Table 4-48 Priority mask. Permite todas las interrupciones
    GICD0->ISENABLER[1] |= 0x00000010;  // bit 33 GIC, SW interrupt
    
    GICC0->CTLR          = 0x00000001;  // habilita la interfaz con la cpu
    GICD0->CTLR          = 0x00000001;  // habilita el distribuidor
}
