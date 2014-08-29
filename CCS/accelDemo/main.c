/**
 * @file main.c
 *
 * An example of a WISP application. Takes an accelerometer measurement and
 * modulates EPC to transfer the measurement in response to a reader ACK.
 *
 * @author	Aaron Parks, UW Sensor Systems Lab
 *
 */

#include "wisp-base.h"

// A pointer to the data struct owned by the WISP library which contains EPC
//  memory, read and write buffers.
WISP_dataStructInterface_t wispData;
threeAxis_t_8 accelOut;

/**
 * To be called from within WISP_doRFID() after an ACK reply (EPC) has been sent.
 *
 */
void my_ackCallback (void) {
	asm(" NOP");
}

/**
 * To be called by WISP FW after a successful READ response has been sent.
 *
 */
void my_readCallback (void) {
    asm(" NOP");
}

/**
 * To be called from within WISP_doRFID() when a successful WRITE has occurred.
 *
 */
void my_writeCallback (void) {
    asm(" NOP");
}

/**
 * To be called from within WISP_doRFID() when a successful BLOCKWRITE has occurred.
 */
void my_blockWriteCallback  (void) {
	asm(" NOP");
}



/** @fcn        void main(void)
 *  @brief      This implements the user application and should never return
 *
 * Must call WISP_init() in the first line of main()
 * Must call WISP_doRFID() at some point to start interacting with a reader
 */
void main(void) {


	WISP_init();

	BITSET(PDIR_AUX3 , PIN_AUX3);
	__delay_cycles(50);
	BITCLR(P1OUT , PIN_AUX3);
	__delay_cycles(50);
	BITSET(P1OUT , PIN_AUX3);
	__delay_cycles(50);


	BITSET(P4SEL1 , PIN_ACCEL_EN);
	BITSET(P4SEL0 , PIN_ACCEL_EN);

	accelOut.x = 1;
	accelOut.y = 1;
	accelOut.z = 1;
	BITSET(P2SEL1 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
	BITCLR(P2SEL0 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
	__delay_cycles(5);
	SPI_initialize();
	__delay_cycles(5);
//	ACCEL_reset();
//	__delay_cycles(50);
	ACCEL_range();
	__delay_cycles(5);
	ACCEL_initialize();
	__delay_cycles(5);
	ACCEL_readID(&accelOut);

	while(accelOut.x != 0xAD){
		__delay_cycles(5);
		wispData.epcBuf[9] = accelOut.x;
		WISP_doRFID();

		ACCEL_readID(&accelOut);


	}
	__delay_cycles(5);
	ACCEL_readStat(&accelOut);

//	PLED1OUT = PIN_LED1;

	while((accelOut.x & 192) != 0x40){
		__delay_cycles(5);
		wispData.epcBuf[9] = accelOut.x;
		WISP_doRFID();
		ACCEL_readStat(&accelOut);
	}
	__delay_cycles(5);
	ACCEL_singleSample(&accelOut);

	// Set up desired local variables

    // Register callback functions with WISP base routines
    WISP_registerCallback_ACK(&my_ackCallback);
    WISP_registerCallback_READ(&my_readCallback);
    WISP_registerCallback_WRITE(&my_writeCallback);
    WISP_registerCallback_BLOCKWRITE(&my_blockWriteCallback);

    // Set up operating parameters for WISP comm routines
    // Set mode: Tag responds to R/W and obeys the sel cmd
    WISP_setMode(MODE_READ | MODE_WRITE | MODE_USES_SEL);

    // Set abort conditions: Exits WISP_doRFID() when the following events happen:
    WISP_setAbortConditions(CMD_ID_READ | CMD_ID_WRITE | CMD_ID_ACK);

    // Set up static EPC
	wispData.epcBuf[0] = 0x05; // WISP version
	wispData.epcBuf[1] = *((uint8_t*)INFO_WISP_TAGID+1); // WISP ID MSB: Pull from INFO seg
	wispData.epcBuf[2] = *((uint8_t*)INFO_WISP_TAGID); // WISP ID LSB: Pull from INFO seg
	wispData.epcBuf[3] = 0x03;
	wispData.epcBuf[4] = 0x04;
	wispData.epcBuf[5] = 0x05;
	wispData.epcBuf[6] = 0x06;
	wispData.epcBuf[7] = 0x07;
	wispData.epcBuf[8] = 0x08;
	wispData.epcBuf[9] = accelOut.x;
	wispData.epcBuf[10] = accelOut.y;
	wispData.epcBuf[11] = accelOut.z;
	wispData.epcBuf[12] = 0x0C;

    while (FOREVER) {
    	ACCEL_readStat(&accelOut);
    	while((accelOut.x & 193) != 0x41){
    		ACCEL_readStat(&accelOut);
    		__delay_cycles(5);
    	}
    	__delay_cycles(5);
		ACCEL_singleSample(&accelOut);
		wispData.epcBuf[9] = accelOut.x;
		wispData.epcBuf[10] = accelOut.y;
		wispData.epcBuf[11] = accelOut.z;

//    	BITCLR(P2SEL1 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
//    	BITCLR(P2SEL0 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
//    	PTXDIR = PIN_TX;

    	WISP_doRFID();

//    	P4DIR |= PIN_ACCEL_CS;
//    	BITSET(P2SEL1 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
//    	BITCLR(P2SEL0 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);


   }
}
