/**
 * @file timer.c
 *
 * Provides hardware and software delay and alarm/scheduling functions
 *
 * @author Aaron Parks
 */

#include "timer.h"
#include "../globals.h"

static BOOL wakeOnDelayTimer;       // A flag indicating we are waiting for a delay timer to expire

//----------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////
/// Timer_LooseDelay
///
/// This function uses the timer to generate delays that are at least as long as
/// the specified duration
///
/// \param usTime32kHz - The minimum amount of time to delay in ~30.5us units (1/32768Hz)
/// @todo Move config register and value definitions to config.h
/////////////////////////////////////////////////////////////////////////////
void Timer_LooseDelay(uint16_t usTime32kHz)
{
    TA2CCTL0 = CCIE;                          // CCR0 interrupt enabled
    TA2CCR0 = usTime32kHz;
    TA2CTL = TASSEL_1 | MC_1 | TACLR;         // ACLK(=REFO), upmode, clear TAR

    wakeOnDelayTimer = TRUE;

    while(wakeOnDelayTimer) {
        __bis_SR_register(LPM3_bits | GIE);
    }

    TA2CCTL0 = 0x00;
    TA2CTL = 0;

}

//----------------------------------------------------------------------------

////////////////////////////////////////////////////////////////////////////
// INT_TimerA1
//
// Interrupt 0 for timer A2 (CCR0). Used in low power ACLK delay routine.
//
////////////////////////////////////////////////////////////////////////////
#pragma vector=TIMER2_A0_VECTOR //TCCR0 Interrupt Vector for TIMER A1
__interrupt void INT_Timer2A0(void)
{
    if(wakeOnDelayTimer) {
        __bic_SR_register_on_exit(LPM3_bits);
        wakeOnDelayTimer = FALSE;
    }

}

//----------------------------------------------------------------------------




