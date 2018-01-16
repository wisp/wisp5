/**
 * @file       usr.c
 * @brief      WISP application-specific code set
 * @details    The WISP application developer's implementation goes here.
 *
 * @author     Aaron Parks, UW Sensor Systems Lab
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
  
  // Initialize BlockWrite data buffer.
  uint16_t bwr_array[6] = {0};
  RWData.bwrBufPtr = bwr_array;
  
  // Get access to EPC, READ, and WRITE data buffers
  WISP_getDataBuffers(&wispData);
  
  // Set up operating parameters for WISP comm routines
  WISP_setMode( MODE_READ | MODE_WRITE | MODE_USES_SEL); 
  WISP_setAbortConditions(CMD_ID_READ | CMD_ID_WRITE | CMD_ID_ACK);
  
  // Set up EPC
  wispData.epcBuf[0] = 0x0B; 		// Tag type
  wispData.epcBuf[1] = 0;			// Unused data field
  wispData.epcBuf[2] = 0;			// Unused data field
  wispData.epcBuf[3] = 0;			// Unused data field
  wispData.epcBuf[4] = 0;			// Unused data field
  wispData.epcBuf[5] = 0;			// Unused data field
  wispData.epcBuf[6] = 0;			// Unused data field
  wispData.epcBuf[7] = 0x11;		// Unused data field
  wispData.epcBuf[8] = 0x00;		// Unused data field
  wispData.epcBuf[9] = 0x51;		// Tag hardware revision (5.1)
  wispData.epcBuf[10] = *((uint8_t*)INFO_WISP_TAGID+1); // WISP ID MSB: Pull from INFO seg
  wispData.epcBuf[11] = *((uint8_t*)INFO_WISP_TAGID); // WISP ID LSB: Pull from INFO seg
  


  FRAM_init();

  if( 0 ){
        FRAM_write((uint16_t* )(0x1808), 0x180a);
        FRAM_write((uint16_t* )(0x180a), 0);
        FRAM_write((uint16_t* )(0x180c), 0);
        FRAM_write((uint16_t* )(0x180e), 0);
        FRAM_write((uint16_t* )(0x1810), 0);
        FRAM_write((uint16_t* )(0x1812), 0);
        FRAM_write((uint16_t* )(0x1814), 0);
        FRAM_write((uint16_t* )(0x1816), 0);
        FRAM_write((uint16_t* )(0x1818), 0);
        FRAM_write((uint16_t* )(0x181a), 0);
        FRAM_write((uint16_t* )(0x181c), 0);
        FRAM_write((uint16_t* )(0x181e), 0);
        FRAM_write((uint16_t* )(0x1820), 0);
        FRAM_write((uint16_t* )(0x1822), 0);
        FRAM_write((uint16_t* )(0x1824), 0);
        FRAM_write((uint16_t* )(0x1826), 0);
        FRAM_write((uint16_t* )(0x1828), 0);
        FRAM_write((uint16_t* )(0x182a), 0);
        FRAM_write((uint16_t* )(0x182c), 0);
        FRAM_write((uint16_t* )(0x182e), 0);
        FRAM_write((uint16_t* )(0x1830), 0);
        FRAM_write((uint16_t* )(0x1832), 0);
        FRAM_write((uint16_t* )(0x1834), 0);
        FRAM_write((uint16_t* )(0x1836), 0);
        FRAM_write((uint16_t* )(0x1838), 0);
        FRAM_write((uint16_t* )(0x183a), 0);
        FRAM_write((uint16_t* )(0x183c), 0);
        FRAM_write((uint16_t* )(0x183e), 0);
        FRAM_write((uint16_t* )(0x1830), 0);
        FRAM_write((uint16_t* )(0x1832), 0);
        FRAM_write((uint16_t* )(0x1834), 0);
        FRAM_write((uint16_t* )(0x1836), 0);
        FRAM_write((uint16_t* )(0x1838), 0);
        FRAM_write((uint16_t* )(0x183a), 0);
        FRAM_write((uint16_t* )(0x183c), 0);
        FRAM_write((uint16_t* )(0x183e), 0);
        FRAM_write((uint16_t* )(0x1840), 0);
        FRAM_write((uint16_t* )(0x1842), 0);
        FRAM_write((uint16_t* )(0x1844), 0);
        FRAM_write((uint16_t* )(0x1846), 0);
        FRAM_write((uint16_t* )(0x1848), 0);
        FRAM_write((uint16_t* )(0x184a), 0);
        FRAM_write((uint16_t* )(0x184c), 0);
        FRAM_write((uint16_t* )(0x184e), 0);
        FRAM_write((uint16_t* )(0x1850), 0);
        FRAM_write((uint16_t* )(0x1852), 0);
        FRAM_write((uint16_t* )(0x1854), 0);
        FRAM_write((uint16_t* )(0x1856), 0);
        FRAM_write((uint16_t* )(0x1858), 0);
        FRAM_write((uint16_t* )(0x185a), 0);
        FRAM_write((uint16_t* )(0x185c), 0);
        FRAM_write((uint16_t* )(0x185e), 0);
        FRAM_write((uint16_t* )(0x1860), 0);
        FRAM_write((uint16_t* )(0x1862), 0);
        FRAM_write((uint16_t* )(0x1864), 0);
        FRAM_write((uint16_t* )(0x1866), 0);
        FRAM_write((uint16_t* )(0x1868), 0);
        FRAM_write((uint16_t* )(0x186a), 0);
        FRAM_write((uint16_t* )(0x186c), 0);
        FRAM_write((uint16_t* )(0x186e), 0);
        FRAM_write((uint16_t* )(0x1870), 0);
        FRAM_write((uint16_t* )(0x1872), 0);
        FRAM_write((uint16_t* )(0x1874), 0);
        FRAM_write((uint16_t* )(0x1876), 0);
        FRAM_write((uint16_t* )(0x1878), 0);
        FRAM_write((uint16_t* )(0x187a), 0);
        FRAM_write((uint16_t* )(0x187c), 0);
        FRAM_write((uint16_t* )(0x187e), 0);
        FRAM_write((uint16_t* )(0x1880), 0);
        FRAM_write((uint16_t* )(0x1882), 0);
        FRAM_write((uint16_t* )(0x1884), 0);
        FRAM_write((uint16_t* )(0x1886), 0);
        FRAM_write((uint16_t* )(0x1888), 0);
        FRAM_write((uint16_t* )(0x188a), 0);
        FRAM_write((uint16_t* )(0x188c), 0);
        FRAM_write((uint16_t* )(0x188e), 0);
        FRAM_write((uint16_t* )(0x1890), 0);
        FRAM_write((uint16_t* )(0x1892), 0);
        FRAM_write((uint16_t* )(0x1894), 0);
        FRAM_write((uint16_t* )(0x1896), 0);
        FRAM_write((uint16_t* )(0x1898), 0);
        FRAM_write((uint16_t* )(0x189a), 0);
        FRAM_write((uint16_t* )(0x189c), 0);
        FRAM_write((uint16_t* )(0x189e), 0);
        FRAM_write((uint16_t* )(0x18a0), 0);
        FRAM_write((uint16_t* )(0x18a2), 0);
        FRAM_write((uint16_t* )(0x18a4), 0);
        FRAM_write((uint16_t* )(0x18a6), 0);
        FRAM_write((uint16_t* )(0x18a8), 0);
        FRAM_write((uint16_t* )(0x18aa), 0);
        FRAM_write((uint16_t* )(0x18ac), 0);
        FRAM_write((uint16_t* )(0x18ae), 0);
        FRAM_write((uint16_t* )(0x18b0), 0);
        FRAM_write((uint16_t* )(0x18b2), 0);
        FRAM_write((uint16_t* )(0x18b4), 0);
        FRAM_write((uint16_t* )(0x18b6), 0);
        FRAM_write((uint16_t* )(0x18b8), 0);
        FRAM_write((uint16_t* )(0x18ba), 0);
        FRAM_write((uint16_t* )(0x18bc), 0);
        FRAM_write((uint16_t* )(0x18be), 0);
        FRAM_write((uint16_t* )(0x18c0), 0);
        FRAM_write((uint16_t* )(0x18c2), 0);
        FRAM_write((uint16_t* )(0x18c4), 0);
        FRAM_write((uint16_t* )(0x18c6), 0);
        FRAM_write((uint16_t* )(0x18c8), 0);
        FRAM_write((uint16_t* )(0x18ca), 0);
        FRAM_write((uint16_t* )(0x18cc), 0);
        FRAM_write((uint16_t* )(0x18ce), 0);
        FRAM_write((uint16_t* )(0x18d0), 0);
        FRAM_write((uint16_t* )(0x18d2), 0);
        FRAM_write((uint16_t* )(0x18d4), 0);
        FRAM_write((uint16_t* )(0x18d6), 0);
        FRAM_write((uint16_t* )(0x18d8), 0);
        FRAM_write((uint16_t* )(0x18da), 0);
        FRAM_write((uint16_t* )(0x18dc), 0);
        FRAM_write((uint16_t* )(0x18de), 0);
        FRAM_write((uint16_t* )(0x18e0), 0);
        FRAM_write((uint16_t* )(0x18e2), 0);
        FRAM_write((uint16_t* )(0x18e4), 0);
        FRAM_write((uint16_t* )(0x18e6), 0);
        FRAM_write((uint16_t* )(0x18e8), 0);
        FRAM_write((uint16_t* )(0x18ea), 0);
        FRAM_write((uint16_t* )(0x18ec), 0);
        FRAM_write((uint16_t* )(0x18ee), 0);
        FRAM_write((uint16_t* )(0x18f0), 0);
        FRAM_write((uint16_t* )(0x18f2), 0);
        FRAM_write((uint16_t* )(0x18f4), 0);
        FRAM_write((uint16_t* )(0x18f6), 0);
        FRAM_write((uint16_t* )(0x18f8), 0);
        FRAM_write((uint16_t* )(0x18fa), 0);
        FRAM_write((uint16_t* )(0x18fc), 0);
        FRAM_write((uint16_t* )(0x18fe), 0);
        FRAM_write((uint16_t* )(0x1900), 0);
        FRAM_write((uint16_t* )(0x1902), 0);
        FRAM_write((uint16_t* )(0x1904), 0);
        FRAM_write((uint16_t* )(0x1906), 0);
        FRAM_write((uint16_t* )(0x1908), 0);
        FRAM_write((uint16_t* )(0x190a), 0);
        FRAM_write((uint16_t* )(0x190c), 0);
        FRAM_write((uint16_t* )(0x190e), 0);
        FRAM_write((uint16_t* )(0x1910), 0);
        FRAM_write((uint16_t* )(0x1912), 0);
        FRAM_write((uint16_t* )(0x1914), 0);
        FRAM_write((uint16_t* )(0x1916), 0);
        FRAM_write((uint16_t* )(0x1918), 0);
        FRAM_write((uint16_t* )(0x191a), 0);
        FRAM_write((uint16_t* )(0x191c), 0);
        FRAM_write((uint16_t* )(0x191e), 0);
        FRAM_write((uint16_t* )(0x1920), 0);
        FRAM_write((uint16_t* )(0x1922), 0);
        FRAM_write((uint16_t* )(0x1924), 0);
        FRAM_write((uint16_t* )(0x1926), 0);
        FRAM_write((uint16_t* )(0x1928), 0);
        FRAM_write((uint16_t* )(0x192a), 0);
        FRAM_write((uint16_t* )(0x192c), 0);
        FRAM_write((uint16_t* )(0x192e), 0);
        FRAM_write((uint16_t* )(0x1930), 0);
        FRAM_write((uint16_t* )(0x1932), 0);
        FRAM_write((uint16_t* )(0x1934), 0);
        FRAM_write((uint16_t* )(0x1936), 0);
        FRAM_write((uint16_t* )(0x1938), 0);
        FRAM_write((uint16_t* )(0x193a), 0);
        FRAM_write((uint16_t* )(0x193c), 0);
        FRAM_write((uint16_t* )(0x193e), 0);
        FRAM_write((uint16_t* )(0x1930), 0);
        FRAM_write((uint16_t* )(0x1932), 0);
        FRAM_write((uint16_t* )(0x1934), 0);
        FRAM_write((uint16_t* )(0x1936), 0);
        FRAM_write((uint16_t* )(0x1938), 0);
        FRAM_write((uint16_t* )(0x193a), 0);
        FRAM_write((uint16_t* )(0x193c), 0);
        FRAM_write((uint16_t* )(0x193e), 0);
        FRAM_write((uint16_t* )(0x1940), 0);
        FRAM_write((uint16_t* )(0x1942), 0);
        FRAM_write((uint16_t* )(0x1944), 0);
        FRAM_write((uint16_t* )(0x1946), 0);
        FRAM_write((uint16_t* )(0x1948), 0);
        FRAM_write((uint16_t* )(0x194a), 0);
        FRAM_write((uint16_t* )(0x194c), 0);
        FRAM_write((uint16_t* )(0x194e), 0);
        FRAM_write((uint16_t* )(0x1950), 0);
        FRAM_write((uint16_t* )(0x1952), 0);
        FRAM_write((uint16_t* )(0x1954), 0);
        FRAM_write((uint16_t* )(0x1956), 0);
        FRAM_write((uint16_t* )(0x1958), 0);
        FRAM_write((uint16_t* )(0x195a), 0);
        FRAM_write((uint16_t* )(0x195c), 0);
        FRAM_write((uint16_t* )(0x195e), 0);
        FRAM_write((uint16_t* )(0x1960), 0);
        FRAM_write((uint16_t* )(0x1962), 0);
        FRAM_write((uint16_t* )(0x1964), 0);
        FRAM_write((uint16_t* )(0x1966), 0);
        FRAM_write((uint16_t* )(0x1968), 0);
        FRAM_write((uint16_t* )(0x196a), 0);
        FRAM_write((uint16_t* )(0x196c), 0);
        FRAM_write((uint16_t* )(0x196e), 0);
        FRAM_write((uint16_t* )(0x1970), 0);
        FRAM_write((uint16_t* )(0x1972), 0);
        FRAM_write((uint16_t* )(0x1974), 0);
        FRAM_write((uint16_t* )(0x1976), 0);
        FRAM_write((uint16_t* )(0x1978), 0);
        FRAM_write((uint16_t* )(0x197a), 0);
        FRAM_write((uint16_t* )(0x197c), 0);
        FRAM_write((uint16_t* )(0x197e), 0);
  }











  // Talk to the RFID reader.
  while (FOREVER) {
    WISP_doRFID();
  }
}
