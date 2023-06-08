#ifndef __TIMER_LIB_H
#define __TIMER_LIB_H

#include <stdint.h>

#define TIMER0_ADDR  0x10011000
#define TIMER2_ADDR  0x10012000
#define TIMER4_ADDR  0x10018000
#define TIMER6_ADDR  0x10019000
#define TIMER1_ADDR  0x10011020
#define TIMER3_ADDR  0x10012020
#define TIMER5_ADDR  0x10018020
#define TIMER7_ADDR  0x10019020

#define TIMER01_ID    36
#define TIMER23_ID    37
#define TIMER45_ID    73
#define TIMER67_ID    74

// ver 'Placa de desarrollo PBA8 RealView.pdf'
// ver 'RealView Platform Baseboard for Cortex-A8 User Guide' 4.20

/*
A continuacion son los re
*/
typedef volatile struct
{
    uint32_t    TimerLoad;     // Al escribir el contador, y cada vez que llega a 0, se carga con esto
    uint32_t    TimerValue;    // Valor actual del contador
    uint32_t    TimerControl;  // Ver pdf para ver cada bit
    uint32_t    TimerIntClr;   // Al escribir este registro, el módulo reconoce la interrupción enviada
    uint32_t    TimerRIS;      // Raw Interrupt Status Register. El bit cero indica el estado de la interrupción
    uint32_t    TimerMIS;      // Masked Interrupt Status Register: Bit 0: bit0(RIS) & bit5(Timer1Control)
    uint32_t    TimerBGLoad;   // como el Timer1Load, pero al escribirlo el contador no se recarga
} _timer_t;

#endif // __TIMER_LIB_H
