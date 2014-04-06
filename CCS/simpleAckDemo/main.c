/**
 * @file       usr.c
 * @brief      WISP application-specific code set
 * @details    The WISP application developer's implementation goes here.
 *
 * @author     Aaron Parks, UW Sensor Systems Lab
 * @created    4.14.12
 *
 * @todo       It should be more clear how the user gets/sends data from/to the
 *             reader
 * @todo		Currently you cannot enable interrupts in user event callbacks. Change that!
 *
 */

#include "wisp-base.h"

WISP_dataStructInterface_t wispData;

/** @fcn        void my_ackHook (void)
 *  @brief      this hook is called by WISP FW after a successful ACK reply
 *  @details
 *
 *  @todo       Implement the callback for this function
 */
void my_ackCallback (void) {
	asm(" NOP");
    return;
}

/** @fcn        void my_readHook (void)
 *  @brief      this hook is called by WISP FW after a successful read command
 *              reception
 *
 *  @note       The data to be sent by the next read can be accessed in ...
 *
 *  @todo       Test this function
 */
void my_readCallback (void) {
    asm(" NOP");
}

/** @fcn        void my_writeHook (void)
 *  @brief      this hook is called by WISP FW after a successful write command
 *              reception
 *  @details
 *
 *  @note       Data written to tag will be present in ...
 *
 *  @todo
 */
void my_writeCallback (void) {
    asm(" NOP");
    return;
}

/** @fcn        void my_blockWriteHook (void)
 *  @brief      this hook is called by WISP FW after a successful BlockWrite
 *              command decode
 *  @details
 *
 *  @note       Data written to tag will be present in ...
 *
 *  @todo       Test this function
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

    // Register callback functions with WISP comm routines
    WISP_registerCallback_ACK(&my_ackCallback);
    WISP_registerCallback_READ(&my_readCallback);
    WISP_registerCallback_WRITE(&my_writeCallback);
    WISP_registerCallback_BLOCKWRITE(&my_blockWriteCallback);

    // Get access to EPC, READ, and WRITE data buffers
    WISP_getDataBuffers(&wispData);

    // Set up operating parameters for WISP comm routines
    /* @todo Make macros for the following two config lines*/
    /* @todo Determine whether it's OK to dynamically change rfid.mode in usr.c
     * */

    /* tag responds to R/W and obeys the sel cmd */
    WISP_setMode( MODE_READ | MODE_WRITE | MODE_USES_SEL);
    WISP_setAbortConditions(CMD_ID_READ | CMD_ID_WRITE | CMD_ID_ACK);

    /*
	 * Set up static EPC
	 */
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


    while (FOREVER) {
    	WISP_doRFID();
    }
}
