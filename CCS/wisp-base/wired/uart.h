/*
 * @file uart.h
 * @brief Provides an interface to the UART module
 *
 * @author Aaron Parks
 * @author Ivar in 't Veen
 */

#ifndef UART_H_
#define UART_H_

#include <stdint.h>

void UART_init(void);

void UART_asyncSend(uint8_t* txBuf, uint16_t size);
void UART_send(uint8_t* txBuf, uint16_t size);
void UART_critSend(uint8_t* txBuf, uint16_t size);
uint8_t UART_isTxBusy();

void UART_asyncReceive(uint8_t* rxBuf, uint16_t size, uint8_t terminate);
void UART_receive(uint8_t* rxBuf, uint16_t size, uint8_t terminate);
void UART_critReceive(uint8_t* rxBuf, uint16_t size, uint8_t terminate);
uint8_t UART_isRxBusy();
uint8_t UART_isRxDone();

#endif /* UART_H_ */
