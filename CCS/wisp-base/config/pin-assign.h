/**
 * @file       pin-assign.h
 *
 * This file specifies pin assignments for the particular hardware platform used.
 *  currently this file targets the WISP5-LRG platform.
 *
 * @author     Aaron Parks, Justin Reina, UW Sensor Systems Lab
 *
 * @todo       The pin definitions in this file are incomplete! Use script to autogenerate these.
 *
 */

#ifndef PIN_ASSIGN_H_
#define PIN_ASSIGN_H_
#include "wispGuts.h"

/** @section    IO CONFIGURATION
 *  @brief      This represents the default IO configuration for the WISP 5.0 rev 0.1 hardware
 *  @details    Pay very close attention to your IO direction and connections if you are modifying any of this!
 *
 *  @note   PIN_TX Must be BIT7 of a port register, as the register is used as a mini-FIFO in the transmit operation. BIT0 may also be
 *          used with some modification of the transmit routine. Do NOT attempt to use other pins on PTXOUT as outputs.
 */
/************************************************************************************************************************************/

/*
 * Port 1
 */

// P1.0 - RX_BITLINE INPUT
#define PIN_RX_BITLINE		(BIT0)
#define PRX_BITLINEOUT 		(P1OUT)

// P1.4 - AUX3 -  INPUT/OUTPUT
#define		PIN_AUX3			(BIT4)
#define 	PAUX3IN				(P1IN)
#define 	PDIR_AUX3			(P1DIR)
#define		PAUX3SEL0			(P1SEL0)
#define		PAUX3SEL1			(P1SEL1)

// P1.6 - I2C_SDA -  INPUT/OUTPUT
#define		PIN_I2C_SDA				(BIT6)
#define 	PI2C_SDAIN				(P1IN)
#define 	PDIR_I2C_SDA			(P1DIR)
#define		PI2C_SDASEL0			(P1SEL0)
#define		PI2C_SDASEL1			(P1SEL1)

// P1.7 - I2C_SCL -  INPUT/OUTPUT
#define		PIN_I2C_SCL				(BIT7)
#define 	PDIR_I2C_SCL			(P1DIR)
#define		PI2C_SCLSEL0			(P1SEL0)
#define		PI2C_SCLSEL1			(P1SEL1)

/*
 * Port 2
 */

// P2.0 - UART TX - OUTPUT
#define		PIN_UART_TX				(BIT0)
#define		PUART_TXSEL0			(P2SEL0)
#define		PUART_TXSEL1			(P2SEL1)

// P2.1 - UART RX - INPUT
#define		PIN_UART_RX				(BIT1)
#define		PUART_RXSEL0			(P2SEL0)
#define		PUART_RXSEL1			(P2SEL1)

// P2.3 - RECEIVE - INPUT
#define		PIN_RX			(BIT3)
#define 	PRXIN			(P2IN)
#define 	PDIR_RX			(P2DIR)
#define		PRXIES			(P2IES)
#define		PRXIE			(P2IE)
#define		PRXIFG			(P2IFG)
#define		PRXSEL0			(P2SEL0)
#define		PRXSEL1			(P2SEL1)
#define 	PRX_VECTOR_DEF	(PORT2_VECTOR)

// P2.4 - ACCEL_SCLK - OUTPUT
#define 	PIN_ACCEL_SCLK			(BIT4)
#define 	PDIR_ACCEL_SCLK			(P2DIR)
#define		PACCEL_SCLKSEL0			(P2SEL0)
#define		PACCEL_SCLKSEL1			(P2SEL1)

// P2.5 - ACCEL_MOSI - OUTPUT
#define 	PIN_ACCEL_MOSI			(BIT5)
#define 	PDIR_ACCEL_MOSI			(P2DIR)
#define		PACCEL_MOSISEL0			(P2SEL0)
#define		PACCEL_MOSISEL1			(P2SEL1)


// P2.6 - ACCEL_MISO - INPUT
#define 	PIN_ACCEL_MISO			(BIT6)
#define 	PDIR_ACCEL_MISO			(P2DIR)
#define		PACCEL_MISOSEL0			(P2SEL0)
#define		PACCEL_MISOSEL1			(P2SEL1)


// P2.7 - TRANSMIT - OUTPUT
#define		PIN_TX			(BIT7)
#define 	PTXOUT			(P2OUT)
#define		PTXDIR			(P2DIR)

/*
 * Port 3
 */

// P3.4 - AUX1 -  INPUT/OUTPUT
#define		PIN_AUX1			(BIT4)
#define 	PAUX1IN				(P3IN)
#define 	PDIR_AUX1			(P3DIR)
#define		PAUX1SEL0			(P3SEL0)
#define		PAUX1SEL1			(P3SEL1)

// P3.5 - AUX2 -  INPUT/OUTPUT
#define		PIN_AUX2			(BIT5)
#define 	PAUX2IN				(P3IN)
#define 	PDIR_AUX2			(P3DIR)
#define		PAUX2SEL0			(P3SEL0)
#define		PAUX2SEL1			(P3SEL1)

// P3.6 - ACCEL_INT2 - INPUT
#define 	PIN_ACCEL_INT2			(BIT6)
#define 	PDIR_ACCEL_INT2			(P3DIR)
#define		PACCEL_INT2SEL0			(P3SEL0)
#define		PACCEL_INT2SEL1			(P3SEL1)

// P3.7 - ACCEL_INT1 - INPUT
#define 	PIN_ACCEL_INT1			(BIT7)
#define 	PDIR_ACCEL_INT1			(P3DIR)
#define		PACCEL_INT1SEL0			(P3SEL0)
#define		PACCEL_INT1SEL1			(P3SEL1)

/*
 * Port 4
 */

// P4.0 - LED1 OUTPUT
#define		PLED1OUT			(P4OUT)
#define 	PIN_LED1			(BIT0)
#define 	PDIR_LED1			(P4DIR)

// P4.1 MEAS INPUT
#define 	PIN_MEAS			(BIT1)
#define		PMEASOUT			(P4OUT)
#define		PMEASDIR			(P4DIR)
#define		PMEASSEL0			(P4SEL0)
#define		PMEASSEL1			(P4SEL1)

// P4.2 - ACCEL_EN - OUTPUT
#define PIN_ACCEL_EN		BIT2
#define POUT_ACCEL_EN		P4OUT
#define PDIR_ACCEL_EN		P4DIR

// P4.3 - ACCEL_CS - OUTPUT
#define PIN_ACCEL_CS		BIT3
#define POUT_ACCEL_CS		P4OUT
#define PDIR_ACCEL_CS		P4DIR

// P4.5 - RECEIVE ENABLE - OUTPUT
#define     PIN_RX_EN       (BIT5)
#define     PRXEOUT         (P4OUT)
#define     PDIR_RX_EN      (P4DIR)


// P4.6 - DEBUG LINE - OUTPUT
#define     PIN_DBG0        (BIT6)
#define     PDBGOUT         (P4OUT)

/*
 * Port 5
 */

/*
 * Port 6
 */

/*
 * Port J
 */

// PJ.1 MEAS_EN (OUTPUT)
#define		PMEAS_ENOUT			(PJOUT)
#define		PMEAS_ENDIR			(PJDIR)
#define 	PIN_MEAS_EN			(BIT1)


// PJ.6 - LED2
#define 	PDIR_LED2			(PJDIR)
#define		PLED2OUT			(PJOUT)
#define 	PIN_LED2			(BIT6)

/*
 * ADC Channel definitions
 */

/**
 * Default IO setup
 */
/** @todo: Default for unused pins should be output, not tristate.  */
/** @todo:  Make sure the Tx port pin should be tristate not output and unused pin to be output*/
#ifndef __ASSEMBLER__
#define setupDflt_IO() \
    P1OUT = 0x00;\
    P2OUT = 0x00;\
    P3OUT = 0x00;\
    P4OUT = 0x00;\
    PJOUT = 0x00;\
    P1DIR = 0x00;\
    PJDIR = PIN_LED2;\
    P2DIR = PIN_TX;\
    P3DIR = 0x00;\
    P4DIR = PIN_ACCEL_CS | PIN_LED1 | PIN_ACCEL_EN;\

#endif /* ~__ASSEMBLER__ */

#endif /* PIN_ASSIGN_H */
