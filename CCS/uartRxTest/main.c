/**
 * @file       usr.c
 * @brief      WISP application-specific code set
 * @details    The WISP application developer's implementation goes here.
 *
 * @author     Aaron Parks, UW Sensor Systems Lab
 * @author     Ivar in 't Veen, TUD Embedded Software Group
 *
 */

#include "wisp-base.h"

WISP_dataStructInterface_t wispData;

/** 
 * This function is called by WISP FW after a successful ACK reply
 *
 */
void my_ackCallback (void) {
	asm(" NOP");
}

/**
 * This function is called by WISP FW after a successful read command
 *  reception
 *
 */
void my_readCallback (void) {
	asm(" NOP");
}

/**
 * This function is called by WISP FW after a successful write command
 *  reception
 *
 */
void my_writeCallback (void) {
	asm(" NOP");
}

/** 
 * This function is called by WISP FW after a successful BlockWrite
 *  command decode

 */
void my_blockWriteCallback  (void) {
	asm(" NOP");
}


/**
 * This implements the user application and should never return
 *
 * Must call WISP_init() in the first line of main()
 * Must call WISP_doRFID() at some point to start interacting with a reader
 */
void main(void) {

	WISP_init();

	// Register callback functions with WISP comm routines
	WISP_registerCallback_ACK(&my_ackCallback);
	WISP_registerCallback_READ(&my_readCallback);
	WISP_registerCallback_WRITE(&my_writeCallback);
	WISP_registerCallback_BLOCKWRITE(&my_blockWriteCallback);

	// Get access to EPC, READ, and WRITE data buffers
	WISP_getDataBuffers(&wispData);

	// Set up operating parameters for WISP comm routines
	WISP_setMode( MODE_READ | MODE_WRITE | MODE_USES_SEL);
	WISP_setAbortConditions(CMD_ID_READ | CMD_ID_WRITE /*| CMD_ID_ACK*/);

	// Set up EPC
	wispData.epcBuf[0] = 0x05; // WISP version
	wispData.epcBuf[1] = *((uint8_t*)INFO_WISP_TAGID+1); // WISP ID MSB
	wispData.epcBuf[2] = *((uint8_t*)INFO_WISP_TAGID); // WISP ID LSB
	wispData.epcBuf[3] = 0x33;
	wispData.epcBuf[4] = 0x44;
	wispData.epcBuf[5] = 0x55;
	wispData.epcBuf[6] = 0x66;
	wispData.epcBuf[7] = 0x77;
	wispData.epcBuf[8] = 0x88;
	wispData.epcBuf[9] = 0x99;
	wispData.epcBuf[10]= 0xAA;
	wispData.epcBuf[11]= 0xBB;


	// Send and/or Receive
#define SEND
#define RECEIVE

	// Choose Receive mode:
	//#define NORMAL
#define ASYNC
	//#define CRITICAL

#if (defined(NORMAL) && defined(ASYNC)) || (defined(NORMAL) && defined(CRITICAL)) || (defined(ASYNC) && defined(CRITICAL))
#error "Please enable only ONE receive mode!"
#endif

#if defined(SEND) || defined(RECEIVE)
	UART_init(); // Init UART
	__bis_SR_register(GIE); // Enable global interrupts
#endif

#if defined(SEND)
	uint8_t s[10] = {1,2,3,4,5,0,7,8,9,10};
#endif

#if defined(RECEIVE)
	uint8_t r[10] = {0};
#endif

	while (FOREVER) {

#if defined(RECEIVE) && defined(ASYNC)
		// Tell UART module to async receive
		UART_asyncReceive(r, 10, '\0');
#endif

#if defined(SEND)
		//UART_critSend(&s, 1);
		//UART_send(&s, 1);
		UART_asyncSend(s, 10);
		Timer_LooseDelay(40000);
#endif

#if defined(RECEIVE) && defined(NORMAL)
		// Receive, block
		UART_receive(r, 10, '\0');
#elif defined(RECEIVE) && defined(ASYNC)
		// Wait until async is done, block
		while(!UART_isRxDone());
#elif defined(RECEIVE) && defined(CRITICAL)
		// Receive without interrupt use, block
		UART_critReceive(r, 10, '\0');
#endif

#if defined(RECEIVE)

		if(    r[0]==1
		    && r[1]==2
		    && r[2]==3
		    && r[3]==4
		    && r[4]==5
		    && r[5]==0
		    && r[6]==0
		    && r[7]==0
		    && r[8]==0
		    && r[9]==0)
		    BITTOG(PLED1OUT, PIN_LED1);

#endif
	}
}
