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

uint8_t counter = 5;

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

	// Accelerometer power up sequence
//	BITCLR(POUT_ACCEL_EN , PIN_ACCEL_EN);
//    CSCTL0_H = 0xA5;
//    CSCTL1 = DCOFSEL_0; //1MHz
//    CSCTL2 = SELA__VLOCLK + SELS_3 + SELM_3;
//    CSCTL3 = DIVA_0 + DIVS_0 + DIVM_0;
//	BITCLR(CSCTL6 , (MODCLKREQEN|SMCLKREQEN|MCLKREQEN));
//	BITSET(CSCTL6 , ACLKREQEN);
//
//
//	__delay_cycles(100);
	BITSET(PDIR_ACCEL_EN , PIN_ACCEL_EN);
	BITSET(POUT_ACCEL_EN , PIN_ACCEL_EN);

    // Register callback functions with WISP base routines
    WISP_registerCallback_ACK(&my_ackCallback);
    WISP_registerCallback_READ(&my_readCallback);
    WISP_registerCallback_WRITE(&my_writeCallback);
    WISP_registerCallback_BLOCKWRITE(&my_blockWriteCallback);

    // Get access to EPC, READ, and WRITE data buffers
    WISP_getDataBuffers(&wispData);

    // Set up operating parameters for WISP comm routines
    // Set mode: Tag responds to R/W and obeys the sel cmd
    WISP_setMode(MODE_READ | MODE_WRITE | MODE_USES_SEL);

    // Set abort conditions: Exits WISP_doRFID() when the following events happen:
    WISP_setAbortConditions(CMD_ID_READ | CMD_ID_WRITE | CMD_ID_ACK);

	accelOut.x = 1;
	accelOut.y = 1;
	accelOut.z = 1;
//	BITSET(P2SEL1 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
//	BITCLR(P2SEL0 , PIN_ACCEL_SCLK | PIN_ACCEL_MISO | PIN_ACCEL_MOSI);
//	__delay_cycles(5);
//	SPI_initialize();
//	__delay_cycles(5);
////	ACCEL_reset();
////	__delay_cycles(50);
//	ACCEL_range();
//	__delay_cycles(5);
//	ACCEL_initialize();
//	__delay_cycles(5);
//
//	__delay_cycles(5);

    // Set up EPC, copy in sensor data
	wispData.epcBuf[0] = 0x0B; // Tag type: Accelerometer
//	wispData.epcBuf[1] = 0;			// Y value MSB
//	wispData.epcBuf[2] = ((uint8_t)accelOut.y);// Y value LSB
//	wispData.epcBuf[3] = 0;			// X value MSB
//	wispData.epcBuf[4] = ((uint8_t)accelOut.x);// X value LSB
//	wispData.epcBuf[5] = 0;			// Z value MSB
//	wispData.epcBuf[6] = ((uint8_t)accelOut.z);// Z value LSB
	wispData.epcBuf[7] = 0x00;		// Unused data field
	wispData.epcBuf[8] = 0x00;		// Unused data field
	wispData.epcBuf[9] = 0x51;		// Tag hardware revision (5.1)
	wispData.epcBuf[10] = *((uint8_t*)INFO_WISP_TAGID+1); // WISP ID MSB: Pull from INFO seg
	wispData.epcBuf[11] = *((uint8_t*)INFO_WISP_TAGID); // WISP ID LSB: Pull from INFO seg

//	ACCEL_singleSample(&accelOut);
//
//    BITSET(TA2CCTL0 , CCIE);
//    TA2CCR0 = 1000;
//    BITSET(TA2CTL , (TASSEL_1 | MC_1 | TACLR));
//    __bis_SR_register(LPM4_bits | GIE);       // Enter LPM4 w/ interrupt
//	__delay_cycles(1);
//    BITCLR(TA2CCTL0 , CCIE);
//    BITCLR(TA2CCR0 , 1000);
//    BITCLR(TA2CTL , (TASSEL_1 | MC_1 | TACLR));
//	ACCEL_readStat(&accelOut);
//	while((((uint8_t)accelOut.x) & 193) != 0x41){
//		ACCEL_readStat(&accelOut);
//		__delay_cycles(10);
//	}
//
////	ACCEL_singleSample(&accelOut);
//	__delay_cycles(10);
//	ACCEL_singleSample(&accelOut);
	wispData.epcBuf[1] = 0;			// Y value MSB
	wispData.epcBuf[2] = (accelOut.y+128);// Y value LSB
	wispData.epcBuf[3] = 0;			// X value MSB
	wispData.epcBuf[4] = (accelOut.x+128);// X value LSB
	wispData.epcBuf[5] = 0;			// Z value MSB
	wispData.epcBuf[6] = (accelOut.z+128);// Z value LSB

    while (FOREVER) {

    	WISP_doRFID();

//        CSCTL0_H = 0xA5;
//        CSCTL1 = DCOFSEL_0; //1MHz
//        CSCTL2 = SELA__VLOCLK + SELS_3 + SELM_3;
//        CSCTL3 = DIVA_0 + DIVS_0 + DIVM_0;
//    	BITCLR(CSCTL6 , (MODCLKREQEN|SMCLKREQEN|MCLKREQEN));
//    	BITSET(CSCTL6 , ACLKREQEN);
//
//		ACCEL_readStat(&accelOut);
//		if((((uint8_t)accelOut.x) & 193) == 0x41){
//			__delay_cycles(20);
//			ACCEL_singleSample(&accelOut);
//			wispData.epcBuf[1] = 0;			// Y value MSB
//			wispData.epcBuf[2] = (accelOut.y+128);// Y value LSB
//			wispData.epcBuf[3] = 0;			// X value MSB
//			wispData.epcBuf[4] = (accelOut.x+128);// X value LSB
//			wispData.epcBuf[5] = 0;			// Z value MSB
//			wispData.epcBuf[6] = (accelOut.z+128);// Z value LSB
//		}

//		BITSET(TA2CCTL0 , CCIE);
//	    TA2CCR0 = 20;
//	    BITSET(TA2CTL , (TASSEL_1 | MC_1 | TACLR));
//	    __bis_SR_register(LPM4_bits | GIE);       // Enter LPM4 w/ interrupt
//		__delay_cycles(1);
//	    BITCLR(TA2CCTL0 , CCIE);
//	    BITCLR(TA2CTL , (TASSEL_1 | MC_1 | TACLR));
   }
}

// Timer A2 interrupt service routine
#pragma vector = TIMER2_A0_VECTOR
__interrupt void Timer2_A0_ISR(void)
{
	BITCLR(TA2CTL , TAIFG);
	__bic_SR_register_on_exit(LPM4_bits|GIE);
}
