/**
 * @file rfid.h
 *
 * Defines the public interface for the RFID module
 *
 * @author Aaron Parks
 */

#ifndef RFID_H_
#define RFID_H_

extern void WISP_doRFID(void);

void WISP_registerCallback_ACK(void(*fnPtr)(void));
void WISP_registerCallback_READ(void(*fnPtr)(void));
void WISP_registerCallback_WRITE(void(*fnPtr)(void));
void WISP_registerCallback_BLOCKWRITE(void(*fnPtr)(void));

// Linker hack: We need to reference assembly ISRs directly somewhere to force linker to include them in binary.
extern void RX_ISR(void);
extern void Timer0A0_ISR(void);
extern void Timer0A1_ISR(void);



#endif /* RFID_H_ */
