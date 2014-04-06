/**
 * sensor_spi.h
 *
 * @author Aaron Parks
 * @date Aug 2013
 */

#ifndef SPI_H_
#define SPI_H_

#define SPI_GP_RXBUF_SIZE 20
extern uint8_t gpRxBuf[SPI_GP_RXBUF_SIZE];

BOOL SPI_initialize();
BOOL SPI_acquirePort();
BOOL SPI_releasePort();
BOOL SPI_transaction(uint8_t* rxBuf, uint8_t* txBuf, uint16_t size);

#ifdef __MSPGCC__
#define USCI_UCRXIFG UCRXIFG
#define USCI_UCTXIFG UCTXIFG
#endif /* __MSPGCC__ */

#endif /* SPI_H_ */
