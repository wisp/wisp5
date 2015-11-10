/*
 * @file catchall.c
 *
 * @author Aaron Parks
 */


#include <msp430.h>


/**
 * If interrupt vectors are left unassigned and are called, the CPU will reset.
 *
 * This function catches un-handled interrupts to reduce confusing resets
 * during debugging. If your application handles certain interrupts, comment
 * them out here to solve linker placement errors.
 */
#pragma vector=AES256_VECTOR          // ".int30" 0xFFCC AES256
#pragma vector=RTC_VECTOR             // ".int31" 0xFFCE RTC
#pragma vector=PORT4_VECTOR           // ".int32" 0xFFD0 Port 4
#pragma vector=PORT3_VECTOR           // ".int33" 0xFFD2 Port 3
#pragma vector=TIMER3_A1_VECTOR       // ".int34" 0xFFD4 Timer3_A2 CC1, TA
#pragma vector=TIMER3_A0_VECTOR       // ".int35" 0xFFD6 Timer3_A2 CC0
//#pragma vector=PORT2_VECTOR           // ".int36" 0xFFD8 Port 2
#pragma vector=TIMER2_A1_VECTOR       // ".int37" 0xFFDA Timer2_A2 CC1, TA
//#pragma vector=TIMER2_A0_VECTOR       // ".int38" 0xFFDC Timer2_A2 CC0
#pragma vector=PORT1_VECTOR           // ".int39" 0xFFDE Port 1
#pragma vector=TIMER1_A1_VECTOR       // ".int40" 0xFFE0 Timer1_A3 CC1-2, TA
//#pragma vector=TIMER1_A0_VECTOR       // ".int41" 0xFFE2 Timer1_A3 CC0
#pragma vector=DMA_VECTOR             // ".int42" 0xFFE4 DMA
#pragma vector=USCI_A1_VECTOR         // ".int43" 0xFFE6 USCI A1 Receive/Transmit
//#pragma vector=TIMER0_A1_VECTOR       // ".int44" 0xFFE8 Timer0_A3 CC1-2, TA
//#pragma vector=TIMER0_A0_VECTOR       // ".int45" 0xFFEA Timer0_A3 CC0
#pragma vector=ADC12_VECTOR           // ".int46" 0xFFEC ADC
#pragma vector=USCI_B0_VECTOR         // ".int47" 0xFFEE USCI B0 Receive/Transmit
#pragma vector=USCI_A0_VECTOR         // ".int48" 0xFFF0 USCI A0 Receive/Transmit
#pragma vector=WDT_VECTOR             // ".int49" 0xFFF2 Watchdog Timer
#pragma vector=TIMER0_B1_VECTOR       // ".int50" 0xFFF4 Timer0_B7 CC1-6, TB
#pragma vector=TIMER0_B0_VECTOR       // ".int51" 0xFFF6 Timer0_B7 CC0
#pragma vector=COMP_E_VECTOR          // ".int52" 0xFFF8 Comparator E
#pragma vector=UNMI_VECTOR            // ".int53" 0xFFFA User Non-maskable
#pragma vector=SYSNMI_VECTOR          // ".int54" 0xFFFC System Non-maskable
__interrupt void unRegistered_ISR (void) {
    return;
}
