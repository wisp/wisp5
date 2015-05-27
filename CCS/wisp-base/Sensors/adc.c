/**
 * @file adc.c
 * @author Ivar in 't Veen
 * @brief ADC module for using the ADC12_B peripheral
 */

#include "adc.h"
#include "../globals.h"

/**
 * State variables for the ADC module
 */
struct {
    uint16_t lastValue; // Last read value (RAW bits)

    void (*callback)(uint16_t); // Callback function for asynchronous measurements
} ADC_SM;

/**
 * Configure the ADC12_B module in single channel single measurement mode and prepare for measurement.
 *
 * @todo Currently assumes all kinds of stuf. Make more flexible by accepting parameters/arguments.
 */
void ADC_init(void) {
    // Select reference voltage.
    REFCTL0 = REFVSEL_1 + REFON + REFTCOFF;

    // Wait for REF to stabilize.
    __delay_cycles(75 * 16);

    // Set registers to their reset conditions..
    ADC12CTL0 = 0;
    ADC12CTL1 = 0;
    ADC12CTL2 = 0;
    ADC12MCTL0 = 0;
    ADC12IER0 = 0;

    // Turn on ADC.
    ADC12CTL0 = ADC12ON;

    // Enable using sample and hold pulse mode and use clock as source.
    ADC12CTL1 |= ADC12SHP + ADC12SSEL1;

    // Enable TA0 CCR1 trigger
    //ADC12CTL1 |= ADC12SHS_5;

    // Set resolution to 10 bits. (see user guide 25.3.3)
    ADC12CTL2 |= ADC12RES__10BIT;

    // Select VR+ = VREF and VR- = AVSS. (see user guide 25.3.6)
    ADC12MCTL0 |= ADC12VRSEL_1;

    // enable interrupt
    ADC12IER0 |= ADC12IE0;

    __delay_cycles(75 * 16);

    // Select analog input channel.
    ADC12MCTL0 |= ADC12INCH_9;

    // Select conversion sequence to single channel-single conversion. (see user guide 25.2.8)
    ADC12CTL1 |= ADC12CONSEQ_0;

    BITSET(PMEAS_ENOUT, PIN_MEAS_EN);

    // Enable ADC conversions
    ADC12CTL0 |= ADC12ENC;
}

/**
 * Return true if ADC module is in the middle of an conversion, false if not.
 */
uint8_t ADC_busy(void) {
    return (ADC12CTL1 & ADC12BUSY);
}

/**
 * Synchronously read ADC. Does block.
 */
uint16_t ADC_read(void) {
    ADC_asyncRead(0);

    while (ADC_busy())
        ;

    return ADC_SM.lastValue;
}

/**
 * Asynchronously read ADC. Do not block, call callback when done.
 *
 * @param callback function to be called after conversion finishes
 */
void ADC_asyncRead(void (*callback)(uint16_t)) {
    ADC_SM.callback = callback;
    ADC12CTL0 |= ADC12SC;
}

/**
 * Handles interrupts for the ADC module.
 * Interrupts typically occur once after each conversion.
 */
#pragma vector=ADC12_VECTOR
__interrupt void INT_ADC12(void) {
    switch (__even_in_range(ADC12IV, ADC12IV_ADC12RDYIFG)) {
    case ADC12IV_ADC12IFG0:
        ADC_SM.lastValue = ADC12MEM0;

        if (ADC_SM.callback)
            (*ADC_SM.callback)(ADC_SM.lastValue);

        break;
    default:
        break;
    }
}
