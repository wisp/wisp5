/*
 * @file adc.h
 * @brief Provides an interface to the ADC module
 *
 * @author Ivar in 't Veen
 */

#ifndef ADC_H_
#define ADC_H_

#include <stdint.h>

void ADC_init(void);

uint16_t ADC_read(void);
void ADC_asyncRead(void (*callback)(uint16_t));

uint8_t ADC_busy(void);

#endif /* ADC_H_ */
