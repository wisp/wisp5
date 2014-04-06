/**
 * @file uart.c
 * @author Aaron Parks
 * @brief UART module for transmitting/receiving data using the USCI_A0 peripheral
 *
 * @todo Write UART receive handler
 */

#include "uart.h"
#include "../globals.h"

/**
 * State variables for the UART module
 */
struct{
	uint8_t isTxBusy; // Is the module currently in the middle of a transmit operation?
	uint8_t* txPtr; // Pointer to the next byte to be transmitted
	uint16_t txBytesRemaining; // Number of bytes left to send
} UART_SM;


/**
 * Configure the eUSCI_A0 module in UART mode and prepare for UART transmission.
 *
 * @todo Currently assumes an 8MHz SMCLK. Make robust to clock frequency changes by using 32k ACLK.
 */
void UART_init(void) {

  // Configure USCI_A0 for UART mode
  UCA0CTLW0 = UCSWRST;                      // Put eUSCI in reset
  UCA0CTLW0 |= UCSSEL__SMCLK;               // CLK = SMCLK

  // Baud Rate calculation
  // 8000000/(16*9600) = 52.083
  // Fractional portion = 0.083
  // User's Guide Table 21-4: UCBRSx = 0x04
  // UCBRFx = int ( (52.083-52)*16) = 1
  UCA0BR0 = 52;                             // 8000000/16/9600
  UCA0BR1 = 0x00;
  UCA0MCTLW |= UCOS16 | UCBRF_1;
  UCA0CTLW0 &= ~UCSWRST;                    // Initialize eUSCI

  // Initialize module state
  UART_SM.isTxBusy=FALSE;
  UART_SM.txBytesRemaining=0;

}

/**
 * Transmit the contents of the given character buffer. Do not block.
 *
 * @param txBuf the character buffer to be transmitted
 * @param size the number of bytes to send
 */
void UART_asyncSend(uint8_t* txBuf, uint16_t size) {

  // Block until prior transmission has completed
  while(UART_SM.isTxBusy);

  // Set up for start of transmission
  UART_SM.isTxBusy=TRUE;
  UART_SM.txPtr=txBuf;
  UART_SM.txBytesRemaining=size-1;

  UCA0IE |= UCTXIE; // Enable USCI_A0 TX interrupt
  UCA0TXBUF = *(UART_SM.txPtr++); // Load in first byte

  // The rest of the transmission will be completed by the TX ISR (which
  //  will wake after each byte has been transmitted), and the isBusy flag
  //  will be cleared when done.
}

/**
 * Transmit the contents of the given character buffer. Block until complete.
 *
 * @param txBuf the character buffer to be transmitted
 * @param size the number of bytes to send
 *
 */
void UART_send(uint8_t* txBuf, uint16_t size) {

	UART_asyncSend(txBuf, size);

	// Block until complete
	while(UART_SM.isTxBusy);
}

/**
 * Transmit the contents of the given character buffer. Block until complete,
 *  and use UART status register polling instead of interrupts.
 */
void UART_critSend(uint8_t* txBuf, uint16_t size) {

	  // Block until prior transmission has completed
	  while(UART_SM.isTxBusy);

	  // Set up for start of transmission
	  UART_SM.isTxBusy=TRUE;
	  UART_SM.txPtr=txBuf;
	  UART_SM.txBytesRemaining=size;

	  UCA0IV &= ~(USCI_UART_UCTXIFG); // Clear byte completion flag

	  while(UART_SM.txBytesRemaining--){
	    UCA0TXBUF = *(UART_SM.txPtr++); // Load in next byte
	  	while(!(UCA0IFG & UCTXIFG)); // Wait for byte transmission to complete
	  	UCA0IFG &= ~(UCTXIFG); // Clear byte completion flag
	  }

	  UART_SM.isTxBusy = FALSE;
}

/**
 * Return true if UART TX module is in the middle of an operation, false if not.
 */
uint8_t UART_isTxBusy() {
	return UART_SM.isTxBusy;
}


/**
 * Handles transmit and receive interrupts for the UART module.
 * Interrupts typically occur once after each byte transmitted/received.
 *
 * @todo Write receive interrupt handler
 */
#pragma vector=USCI_A0_VECTOR
__interrupt void USCI_A0_ISR(void)
{
  switch(__even_in_range(UCA0IV, USCI_UART_UCTXCPTIFG))
  {
    case USCI_NONE: break;
    case USCI_UART_UCRXIFG: break;
    case USCI_UART_UCTXIFG:
      if(UART_SM.txBytesRemaining--) {
        UCA0TXBUF = *(UART_SM.txPtr++);
      } else {
    	UCA0IE &= ~(UCTXIE); // Disable USCI_A0 TX interrupt
    	UART_SM.isTxBusy = FALSE;
      }
      break;
    case USCI_UART_UCSTTIFG: break;
    case USCI_UART_UCTXCPTIFG: break;
  }
}

