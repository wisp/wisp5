/**
 * @file wisp-base.h
 *
 * The interface for the standard WISP library, including all definitions
 *  required to communicate with an RFID reader and use onboard peripherals.
 *
 * @author Aaron Parks, Saman Naderiparizi
 */

#ifndef WISP_BASE_H_
#define WISP_BASE_H_

//#include <msp430.h>
#include "globals.h" // Get these outta here (breaks encapsulation barrier)
#include "wired/spi.h"
#include "wired/uart.h"
#include "Sensors/accel.h"
#include "nvm/fram.h"
#include "RFID/rfid.h"
#include "config/wispGuts.h"
#include "Timing/timer.h"
#include "rand/rand.h"

void WISP_init(void);
void WISP_getDataBuffers(WISP_dataStructInterface_t* clientStruct);

#endif /* WISP_BASE_H_ */
