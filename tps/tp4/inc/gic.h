#ifndef __GIC_LIB_H
#define __GIC_LIB_H

#include <stddef.h>
#include <stdint.h>

/* Ver 'RealView Platform Baseboard for Cortex-A8 User Guide' 4.11.2, pagina 167 */
#define GICC0_ADDR 0x1E000000
#define GICD0_ADDR 0x1E001000
#define GICC1_ADDR 0x1E010000
#define GICD1_ADDR 0x1E011000
#define GICC2_ADDR 0x1E020000
#define GICD2_ADDR 0x1E021000
#define GICC3_ADDR 0x1E030000
#define GICD3_ADDR 0x1E031000

/*
Esto esta mal... 36 es timer 0 y 1
37 timers 2 y 3
73 son 4 y 5
74 son 6 y 7
*/
#define GIC_SOURCE_TIMER0 36
#define GIC_SOURCE_TIMER1 37
#define GIC_SOURCE_TIMER2 73
#define GIC_SOURCE_TIMER3 74

#define reserved_bits(x,y,z) uint8_t reserved##x[z - y + 1];

/* tabla 4-46 CPU interface registers address offset values */
typedef volatile struct
{
    uint32_t    CTLR;   // CPU control
    uint32_t    PMR;    // Priority Mask
    uint32_t    BPR;    // Binary Point
    uint32_t    IAR;    // Interrupt Acknowledge
    uint32_t    EOIR;   // End of interrupt
    uint32_t    RPR;    // Running interrupt
    uint32_t    HPPIR;  // Highest pending interrupt
} _gicc_t;

/* tabla 4-55 Distribution registers address offset values */
typedef volatile struct
{
    uint32_t CTLR;                      // Distributor control
    uint32_t TYPER;                     // Controller type
    reserved_bits(0, 0x0008, 0x00FC);   // Reserved
    uint32_t ISENABLER[3];              // Set-enable0, 1 y 2
    reserved_bits(1, 0x010C, 0x017C);
    uint32_t ICENABLER[3];              // Clear-enable0, 1 y 2
    reserved_bits(2, 0x018C, 0x01FC);
    uint32_t ISPENDR[3];                // Set-pending0, 1 y 2
    reserved_bits(3, 0x020C, 0x027C);
    uint32_t ICPENDR[3];                // Clear-pending0, 1 y 2
    reserved_bits(4, 0x028C, 0x02FC);
    uint32_t ISACTIVER[3];              // Active0, 1 y 2
    reserved_bits(5, 0x030C, 0x03FC);
    uint32_t IPRIORITYR[24];            // Priority
    reserved_bits(6, 0x0460, 0x07FC);
    uint32_t ITARGETSR[24];             // CPU targets
    reserved_bits(7, 0x860, 0x0BFC);
    uint32_t ICFGR[6];                  // Configuration
    reserved_bits(8, 0x0C18, 0x0EFC);
    uint32_t SGIR;                      // Software interrupt
    reserved_bits(9, 0x0F04, 0x0FFC);
} _gicd_t;

#endif // __GIC_LIB_H
