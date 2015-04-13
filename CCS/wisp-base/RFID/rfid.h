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

//RFID MODE DEFS
#define MODE_STD        (0)         /* tag only responds up to ACKs (even ignores ReqRNs)                                       */
#define MODE_READ       (BIT0)      /* tag responds to read commands                                                            */
#define MODE_WRITE      (BIT1)      /* tag responds to write commands                                                           */
#define MODE_USES_SEL   (BIT2)      /* tags only use select when they want to play nice (they don't have to)                    */

// RFID command IDs
#define CMD_ID_ACK      (BIT0)
#define CMD_ID_READ     (BIT1)
#define CMD_ID_WRITE    (BIT2)
#define CMD_ID_BLOCKWRITE (BIT3)

// Client interface to read, write, and EPC memory buffers
typedef struct {
	uint8_t* epcBuf;
	uint16_t* writeBufPtr;
	uint16_t* blockWriteBufPtr;
	uint16_t* blockWriteSizePtr;
	uint8_t* readBufPtr;
} WISP_dataStructInterface_t;

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
