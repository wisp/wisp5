/**
 * @file rfid.h
 *
 * Defines the public interface for the RFID module
 *
 * @author Aaron Parks
 */

#ifndef RFID_H_
#define RFID_H_

#include <stdint.h>

extern void WISP_doRFID(void);

// Callback registration
void WISP_registerCallback_ACK(void(*fnPtr)(void));
void WISP_registerCallback_READ(void(*fnPtr)(void));
void WISP_registerCallback_WRITE(void(*fnPtr)(void));
void WISP_registerCallback_BLOCKWRITE(void(*fnPtr)(void));

// Access functions for RFID mode parameters
void WISP_setMode(uint8_t newMode);
void WISP_setAbortConditions(uint8_t newAbortConditions);


// Linker hack: We need to reference assembly ISRs directly somewhere to force linker to include them in binary.
extern void RX_ISR(void);
extern void Timer0A0_ISR(void);
extern void Timer0A1_ISR(void);





#endif /* RFID_H_ */
