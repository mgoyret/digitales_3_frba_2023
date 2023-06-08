#include "../inc/timer.h"

__attribute__((section(".text"))) void __timer_init()
{
    _timer_t* const timer_0 = (_timer_t*)TIMER0_ADDR;

    timer_0->TimerLoad = 0b00000101;
    timer_0->TimerControl = 0b11101010;
    /*
    timer_0->TimerControl |= 0b00000000;    // modo recarga
    timer_0->TimerControl |= 0b00000010;    // Contador de 32 bits
    timer_0->TimerControl |= 0b00001000;    // 10 -> clock dividido por 256
    timer_0->TimerControl |= 0b00100000;    // habilito interrupcion del timer
    timer_0->TimerControl |= 0b01000000;    // modo periodico
    timer_0->TimerControl |= 0b10000000;    // habilito el timer
    */
}
