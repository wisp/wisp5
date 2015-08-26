/**
 * @file uart.c
 * @author Aaron Parks -- Framework + TX logic
 * @author Ivar in 't Veen -- RX logic + Baudrate calculations
 * @brief UART module for transmitting/receiving data using the USCI_A0 peripheral
 */

#include "uart.h"
#include "../globals.h"

/**
 * State variables for the UART module
 */
struct {
    uint8_t isTxBusy; // Is the module currently in the middle of a transmit operation?
    uint8_t* txPtr; // Pointer to the next byte to be transmitted
    uint16_t txBytesRemaining; // Number of bytes left to send

    uint8_t isRxBusy; // Is the module currently in the middle of a receive operation?
    uint8_t* rxPtr; // Pointer to the next byte to be received
    uint16_t rxBytesRemaining; // Maximum number of bytes left to receive
    uint8_t rxTermChar; // Stop receiving on this char.
} UART_SM;

/**
 * Configure the eUSCI_A0 module in UART mode and prepare for UART transmission.
 *
 * @todo Currently assumes an 8MHz SMCLK. Make robust to clock frequency changes by using 32k ACLK.
 */
void UART_init(void) {
    UART_initCustom(8000000, 9600);
}

/**
 * Configure the eUSCI_A0 module in UART mode and prepare for UART transmission.
 *
 * @param fsmclk SMCLK frequency
 * @param baudrate UART baudrate to be set
 *
 * @todo Currently assumes SMCLK. Make robust to clock frequency changes by using ACLK.
 */
void UART_initCustom(uint32_t fsmclk, uint32_t baudrate) {

    // Configure USCI_A0 for UART mode
    UCA0CTLW0 = UCSWRST;                        // Put eUSCI in reset
    UCA0CTLW0 |= UCSSEL__SMCLK;                 // CLK = SMCLK

    // Baud Rate calculation -- see section 21.3.10 of MSP430 User's Guide
    uint16_t n = fsmclk / baudrate;
    uint16_t nfrac = ((fsmclk * 100) / baudrate) - (n * 100);

    UCA0MCTLW &= ~(0xFFF0);                     // Clear modulation stage bits
    UCA0MCTLW |= ((nfrac * 3) - 20) << 8;       // Set second modulation stage (no LUT, approximated)

    if (n > 3) {
        UCA0MCTLW |= UCOS16;                    // Enable oversampling
        UCA0BRW = n >> 4;                       // Set clock prescaler
        UCA0MCTLW |= (n - (n & 0xFFF0)) << 4;   // Set first modulation stage
    } else {
        UCA0MCTLW &= ~UCOS16;                   // Disable oversampling
        UCA0BRW = n;                            // Set clock prescaler
    }

    // RX/TX Pin selection
    PUART_TXSEL0 &= ~PIN_UART_TX; // TX pin to UART module
    PUART_TXSEL1 |= PIN_UART_TX;

    PUART_RXSEL0 &= ~PIN_UART_RX; // RX pin to UART module
    PUART_RXSEL1 |= PIN_UART_RX;

    // Initialize eUSCI
    UCA0CTLW0 &= ~UCSWRST;

    // Initialize module state
    UART_SM.isTxBusy = FALSE;
    UART_SM.txBytesRemaining = 0;
    UART_SM.isRxBusy = FALSE;
    UART_SM.rxBytesRemaining = 0;
    UART_SM.rxTermChar = '\0';

}

/**
 * Transmit the contents of the given character buffer. Do not block.
 *
 * @param txBuf the character buffer to be transmitted
 * @param size the number of bytes to send
 */
void UART_asyncSend(uint8_t* txBuf, uint16_t size) {

    // Block until prior transmission has completed
    while (UART_SM.isTxBusy)
        ;

    // Set up for start of transmission
    UART_SM.isTxBusy = TRUE;
    UART_SM.txPtr = txBuf;
    UART_SM.txBytesRemaining = size - 1;

    UCA0IFG &= ~(USCI_UART_UCTXIFG); // Clear byte completion flag

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
    while (UART_SM.isTxBusy)
        ;
}

/**
 * Transmit the contents of the given character buffer. Block until complete,
 *  and use UART status register polling instead of interrupts.
 */
void UART_critSend(uint8_t* txBuf, uint16_t size) {

    // Block until prior transmission has completed
    while (UART_SM.isTxBusy)
        ;

    // Set up for start of transmission
    UART_SM.isTxBusy = TRUE;
    UART_SM.txPtr = txBuf;
    UART_SM.txBytesRemaining = size;

    UCA0IV &= ~(USCI_UART_UCTXIFG); // Clear byte completion flag

    while (UART_SM.txBytesRemaining--) {
        UCA0TXBUF = *(UART_SM.txPtr++); // Load in next byte
        while (!(UCA0IFG & UCTXIFG))
            ; // Wait for byte transmission to complete
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
 * Receive character buffer. Do not block.
 *
 * @param rxBuf the character buffer to be received to
 * @param size the number of bytes to receive
 */
void UART_asyncReceive(uint8_t* rxBuf, uint16_t size, uint8_t terminate) {

    // Block until prior reception has completed
    while (UART_SM.isRxBusy)
        ;

    // Set up for start of reception
    UART_SM.isRxBusy = TRUE;
    UART_SM.rxPtr = rxBuf;
    UART_SM.rxBytesRemaining = size;
    UART_SM.rxTermChar = terminate;

    UCA0IFG &= ~(UCRXIFG); // Clear byte completion flag

    UCA0IE |= UCRXIE; // Enable USCI_A0 RX interrupt

    // The rest of the reception will be completed by the RX ISR (which
    //  will wake after each byte has been received), and the isBusy flag
    //  will be cleared when done.
}

/**
 * Receive character buffer. Block until complete.
 *
 * @param rxBuf the character buffer to be received to
 * @param size the number of bytes to receive
 *
 */
void UART_receive(uint8_t* rxBuf, uint16_t size, uint8_t terminate) {

    UART_asyncReceive(rxBuf, size, terminate);

    // Block until complete
    while (UART_SM.isRxBusy)
        ;
}

/**
 * Receive to the given character buffer. Block until complete,
 *  and use UART status register polling instead of interrupts.
 */
void UART_critReceive(uint8_t* rxBuf, uint16_t size, uint8_t terminate) {

    // Block until prior reception has completed
    while (UART_SM.isRxBusy)
        ;

    // Set up for start of reception
    UART_SM.isRxBusy = TRUE;
    UART_SM.rxPtr = rxBuf;
    UART_SM.rxBytesRemaining = size;
    UART_SM.rxTermChar = terminate;

    UCA0IFG &= ~(UCRXIFG); // Clear byte completion flag

    while (UART_SM.rxBytesRemaining--) {
        while (!(UCA0IFG & UCRXIFG))
            ; // Wait for byte reception to complete
        UCA0IFG &= ~(UCRXIFG); // Clear byte completion flag

        uint8_t rec = UCA0RXBUF; // Read next byte
        *(UART_SM.rxPtr++) = rec; // Store byte

        if (rec == UART_SM.rxTermChar)
            break; // Stop receiving when the termination charactor is received
    }

    UART_SM.isRxBusy = FALSE;
}

/**
 * Return true if UART RX module is in the middle of an operation, false if not.
 */
uint8_t UART_isRxBusy() {
    return UART_SM.isRxBusy;
}

/**
 * Return true if UART RX module is not in the middle of an operation (e.g. done), false if not.
 *
 * Could be used in combination with UART_asyncReceive.
 */
uint8_t UART_isRxDone() {
    return !(UART_SM.isRxBusy);
}

/**
 * Handles transmit and receive interrupts for the UART module.
 * Interrupts typically occur once after each byte transmitted/received.
 */
#pragma vector=USCI_A0_VECTOR
__interrupt void USCI_A0_ISR(void) {
    BITTOG(PLED2OUT, PIN_LED2);
    uint8_t rec;

    switch (__even_in_range(UCA0IV, USCI_UART_UCTXCPTIFG)) {
    case USCI_NONE:
        break;
    case USCI_UART_UCRXIFG:
        if (UART_SM.rxBytesRemaining--) {
            rec = UCA0RXBUF; // Read next byte
            *(UART_SM.rxPtr++) = rec; // Store byte
        } else {
            rec = ~UART_SM.rxTermChar;
        }

        if ((0 == UART_SM.rxBytesRemaining) || (rec == UART_SM.rxTermChar)) {
            UCA0IE &= ~(UCRXIE); // Disable USCI_A0 RX interrupt
            UART_SM.isRxBusy = FALSE;
        }

        break;
    case USCI_UART_UCTXIFG:
        if (UART_SM.txBytesRemaining--) {
            UCA0TXBUF = *(UART_SM.txPtr++);
        } else {
            UCA0IE &= ~(UCTXIE); // Disable USCI_A0 TX interrupt
            UART_SM.isTxBusy = FALSE;
        }
        break;
    case USCI_UART_UCSTTIFG:
        break;
    case USCI_UART_UCTXCPTIFG:
        break;
    }
}

