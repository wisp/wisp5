/**
 * @file timer.h
 *
 * An interface to low-level hardware and software timing and alarm/scheduling features
 *
 * @author Aaron Park
 */

#ifndef TIMER_H_
#define TIMER_H_

#include "../globals.h"

/*
 * Timing macros based on LFXT clock frequency
 */
#define LP_LSDLY_2S     65535   // ~2s at 32.768kHz
#define LP_LSDLY_1S     32768   // ~1s at 32.768kHz
#define LP_LSDLY_500MS  16383   // ~500ms at 32.768kHz
#define LP_LSDLY_200MS  6554    // ~200ms at 32.768kHz
#define LP_LSDLY_100MS  3277    // ~100ms at 32.768kHz
#define LP_LSDLY_50MS   1638    // ~50ms at 32.768kHz
#define LP_LSDLY_20MS   655     // ~20ms at 32.768kHz
#define LP_LSDLY_10MS   328     // ~10ms at 32.768kHz
#define LP_LSDLY_5MS    164     // ~5ms at 32.768kHz
#define LP_LSDLY_2MS    66      // ~2ms at 32.768kHz
#define LP_LSDLY_1MS    33      // ~1ms at 32.768kHz


/*
 * Function prototypes
 */

void Timer_LooseDelay(uint16_t usTime32kHz);


#endif /*TIMER_H_*/
