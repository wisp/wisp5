/*
 * @file adc.h
 * @brief Provides an interface to the ADC module
 *
 * @author Ivar in 't Veen
 */

#ifndef ADC_H_
#define ADC_H_

#include <stdint.h>
#include <msp430.h>

/**
 * ADC reference voltage selection (see user guide 24.2.2.2 and 25.2.3)
 */
typedef enum {
    ADC_reference_1_2V = REFVSEL_0,
    ADC_reference_2_0V = REFVSEL_1,
    ADC_reference_2_5V = REFVSEL_2,
} ADC_referenceSelect;

/**
 * ADC precision (see user guide 25.3.3)
 */
typedef enum {
    ADC_precision_8bit = ADC12RES__8BIT,
    ADC_precision_10bit = ADC12RES__10BIT,
    ADC_precision_12bit = ADC12RES__12BIT,
} ADC_precisionSelect;

/**
 * ADC input channel, for now only external analog inputs
 */
typedef enum {
    ADC_input_temperature,
    ADC_input_A0 = ADC12INCH_0,
    ADC_input_A1 = ADC12INCH_1,
    ADC_input_A2 = ADC12INCH_2,
    ADC_input_A3 = ADC12INCH_3,
    ADC_input_A4 = ADC12INCH_4,
    ADC_input_A5 = ADC12INCH_5,
    ADC_input_A6 = ADC12INCH_6,
    ADC_input_A7 = ADC12INCH_7,
    ADC_input_A8 = ADC12INCH_8,
    ADC_input_A9 = ADC12INCH_9,
    ADC_input_A10 = ADC12INCH_10,
    ADC_input_A11 = ADC12INCH_11,
    ADC_input_A12 = ADC12INCH_12,
    ADC_input_A13 = ADC12INCH_13,
    ADC_input_A14 = ADC12INCH_14,
    ADC_input_A15 = ADC12INCH_15,
    ADC_input_A16 = ADC12INCH_16,
    ADC_input_A17 = ADC12INCH_17,
    ADC_input_A18 = ADC12INCH_18,
    ADC_input_A19 = ADC12INCH_19,
    ADC_input_A20 = ADC12INCH_20,
    ADC_input_A21 = ADC12INCH_21,
    ADC_input_A22 = ADC12INCH_22,
    ADC_input_A23 = ADC12INCH_23,
    ADC_input_A24 = ADC12INCH_24,
    ADC_input_A25 = ADC12INCH_25,
    ADC_input_A26 = ADC12INCH_26,
    ADC_input_A27 = ADC12INCH_27,
    ADC_input_A28 = ADC12INCH_28,
    ADC_input_A29 = ADC12INCH_29,
    ADC_input_A30 = ADC12INCH_30,
    ADC_input_A31 = ADC12INCH_31,
} ADC_inputSelect;

// Initialization functions
void ADC_init(void);
void ADC_initCustom(ADC_referenceSelect, ADC_precisionSelect, ADC_inputSelect);

// Read functions
uint16_t ADC_read(void);
void ADC_asyncRead(void (*)(uint16_t));
uint16_t ADC_critRead(void);

// Conversion functions
uint16_t ADC_rawToVoltage(uint16_t);
int16_t ADC_rawToTemperature(uint16_t);

// Get ADC status
uint8_t ADC_isBusy(void);
uint8_t ADC_isReady(void);

// Enable/Disable functions
void ADC_enable(void);
void ADC_disable(void);
void ADC_enableConversion(void);
void ADC_disableConversion(void);
void ADC_enableInterrupts(void);
void ADC_disableInterrupts(void);

// Internal ADC settings functions, should not be needed for normal use (use ADC_initCustom() instead).
void ADC_setReference(ADC_referenceSelect);
ADC_referenceSelect ADC_getReference(void);
void ADC_setPrecision(ADC_precisionSelect);
ADC_precisionSelect ADC_getPrecision(void);
void ADC_setInputChannel(ADC_inputSelect);
ADC_inputSelect ADC_getInputChannel(void);
void ADC_setSampleHold(void);

#endif /* ADC_H_ */
