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

    ADC_referenceSelect reference;
    ADC_precisionSelect precision;
    ADC_inputSelect channel;

    void (*read_callback)(uint16_t); // Callback function for asynchronous measurements
} ADC_SM;

/**
 * Configure the ADC12_B module in single channel single measurement mode and prepare for measurement.
 */
void ADC_init(void) {
    ADC_initCustom(ADC_reference_2_0V, ADC_precision_10bit, ADC_input_A9);
}

/**
 * Configure the ADC12_B module in single channel single measurement mode and prepare for measurement.
 *
 * @param reference voltage reference source
 * @param precision ADC measurement precision
 * @param channel ADC input channel
 */
void ADC_initCustom(ADC_referenceSelect reference,
        ADC_precisionSelect precision, ADC_inputSelect channel) {
    // Set registers to their reset conditions..
    ADC12CTL0 = 0;
    ADC12CTL1 = 0;
    ADC12CTL2 = 0;
    ADC12MCTL0 = 0;
    ADC12IER0 = 0;

    // Select reference voltage.
    ADC_setReference(reference);

    // Turn on ADC.
    ADC_enable();

    // Enable using sample and hold pulse mode and use clock as source.
    ADC_setSampleHold();

    // Set resolution to 10 bits. (see user guide 25.3.3)
    ADC_setPrecision(precision);

    // enable interrupt
    ADC_enableInterrupts();

    // Select analog input channel.
    ADC_setInputChannel(channel);

    // Enable ADC conversions
    ADC_enableConversion();
}

/**
 * Synchronously read ADC. Does block.
 */
uint16_t ADC_read(void) {
    ADC_asyncRead(0);

    while (ADC_isBusy())
        ;

    return ADC_SM.lastValue;
}

/**
 * Asynchronously read ADC. Do not block, call callback when done.
 *
 * @param callback function to be called after conversion finishes
 */
void ADC_asyncRead(void (*callback)(uint16_t)) {
    ADC_enableInterrupts();

    ADC_SM.read_callback = callback;
    ADC12CTL0 |= ADC12SC;
}

/**
 * Critical ADC read. Does block, does not use interrupts.
 */
uint16_t ADC_critRead(void) {
    ADC_disableInterrupts();

    // Enable conversion and start.
    ADC12CTL0 |= ADC12SC + ADC12ENC;

    // Wait until conversion is done.
    while (ADC_isBusy())
        ;

    // Read voltage from memory register.
    ADC_SM.lastValue = ADC12MEM0;

    return ADC_SM.lastValue;
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

        if (ADC_SM.read_callback)
            (*ADC_SM.read_callback)(ADC_SM.lastValue);

        break;
    default:
        break;
    }
}

/**
 * Convert RAW ADC reading to Volts.
 *
 * Based on formula (see user guide 25.2.1):
 *  Nadc = 4096 * ( (Vin + .5LSB) - Vr- ) / ( Vr+ - Vr- )  where  LSB = ( Vr+ - Vr- ) / 4096
 *
 * Formula converted to:
 *  Vin = (Nadc/4096) * ( Vr+ - Vr- ) + Vr- - .5LSB  where  LSB = ( Vr+ - Vr- ) / 4096
 *
 * @param raw RAW ADC value
 */
uint16_t ADC_rawToMilliVolts(uint16_t raw) {

    ADC_referenceSelect reference = ADC_getReference();
    ADC_precisionSelect precision = ADC_getPrecision();

    uint16_t v_minus = 0;

    uint16_t v_plus = (reference == ADC_reference_1_2V) ? 1200 :
                      (reference == ADC_reference_2_0V) ? 2000 :
                      (reference == ADC_reference_2_5V) ? 2500 : 0;

    uint16_t factor = (precision == ADC_precision_8bit) ? 8 :
                      (precision == ADC_precision_10bit) ? 10 :
                      (precision == ADC_precision_12bit) ? 12 : 0;

    uint16_t lsb = (v_plus - v_minus) >> factor;
    uint32_t temp = (((uint32_t) (0x00000000 + raw) * (v_plus - v_minus))
            >> factor) + v_plus - (lsb >> 1);

    return (uint16_t) (temp & 0xFFFF);
}

/**
 * Convert RAW ADC reading to Celcius.
 *
 * Based on formula (see user guide 25.2.10):
 *  Celcius = (RAW * 0.4) - 280
 *
 * @param raw RAW ADC value
 */
uint16_t ADC_rawToCelcius(uint16_t raw) {
    uint32_t temp = ((uint32_t) (0x00000000 + ADC_rawToMilliVolts(raw)) * 10
            / 25) - 280;

    return (uint16_t) (temp & 0xFFFF);
}

/**
 * Return true if ADC module is in the middle of a conversion, false if not.
 */
uint8_t ADC_isBusy(void) {
    return !!(ADC12CTL1 & ADC12BUSY);
}

/**
 * Return false if ADC module is in the middle of a conversion, true if not.
 */
uint8_t ADC_isReady(void) {
    return !ADC_isBusy();
}

/**
 * Enable the ADC12_B peripheral.
 */
void ADC_enable(void) {
    // Enable ADC
    ADC12CTL0 |= ADC12ON;
}

/**
 * Disable the ADC12_B peripheral.
 */
void ADC_disable(void) {
    ADC_disableConversion();

    // Disable ADC conversions
    ADC12CTL0 &= ~ADC12ENC;
}

/**
 * Enable ADC conversions.
 */
void ADC_enableConversion(void) {
    ADC_enable();

    // Enable ADC conversions
    ADC12CTL0 |= ADC12ENC;
}

/**
 * Disable ADC conversions.
 */
void ADC_disableConversion(void) {
    // Disable ADC
    ADC12CTL0 &= ~ADC12ON;
}

/**
 * Enable ADC interrupts.
 */
void ADC_enableInterrupts(void) {
    // Enable ADC12IFG0 interrupt
    ADC12IER0 |= ADC12IE0;

    __delay_cycles(75 * 16);

    // TODO: is it `correct` for this line to be here?
    __bis_SR_register(GIE); // Enable global interrupts
}

/**
 * Disable all ADC interrupts.
 */
void ADC_disableInterrupts(void) {
    // Disable all ADC interrupts
    ADC12IER0 = 0;
    ADC12IER1 = 0;
    ADC12IER2 = 0;
}

/**
 * Set voltage reference and make the ADC to use it.
 *
 * @param reference the wanted reference voltage.
 */
void ADC_setReference(ADC_referenceSelect reference) {
    if (REFCTL0 & REFGENBUSY)
        return;

    ADC_SM.reference = reference;

    // Set reference voltage.
    REFCTL0 = reference + REFON + REFTCOFF;

    // Wait for REF to stabilize.
    __delay_cycles(75 * 16);

    // Select VR+ = VREF and VR- = AVSS. (see user guide 25.3.6)
    ADC12MCTL0 |= ADC12VRSEL_1;
}

/**
 * Get currently set voltage reference.
 */
ADC_referenceSelect ADC_getReference(void) {
    return ADC_SM.reference;
}

/**
 * Set ADC conversion precision.
 *
 * @param precision the wanted precision.
 */
void ADC_setPrecision(ADC_precisionSelect precision) {
    ADC_SM.precision = precision;

    ADC12CTL2 |= precision;
}

/**
 * Get currently set conversion precision.
 */
ADC_precisionSelect ADC_getPrecision(void) {
    return ADC_SM.precision;
}

/**
 * Set ADC input channel and single channel-single conversion mode.
 *
 * Possible channels: analog input pins A0-A31 and internal temperature sensor.
 *
 * @param channel the wanted channel.
 */
void ADC_setInputChannel(ADC_inputSelect channel) {
    ADC_SM.channel = channel;

    switch (channel) {
    case ADC_input_temperature:
        // Use alternate channel muxing
        ADC12CTL3 |= ADC12TCMAP;

        // Select temperature input channel
        ADC12MCTL0 &= ~(0x1F);
        ADC12MCTL0 |= ADC12INCH_30;
        break;
    default:
        // Use default channel muxing
        ADC12CTL3 &= ~ADC12TCMAP;

        // Select analog input channel
        ADC12MCTL0 &= ~(0x1F);
        ADC12MCTL0 |= channel;
        break;
    }

    // Select conversion sequence to single channel-single conversion. (see user guide 25.2.8)
    ADC12CTL1 |= ADC12CONSEQ_0;
}

/**
 * Get currently set input channel.
 */
ADC_inputSelect ADC_getInputChannel(void) {
    return ADC_SM.channel;
}

/**
 * Set ADC to sample and hold pulse mode.
 */
void ADC_setSampleHold(void) {
    // Enable using sample and hold pulse mode and use clock as source.
    ADC12CTL1 |= ADC12SHP + ADC12SSEL1;
}
