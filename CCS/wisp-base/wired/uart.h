/*
 * @file uart.h
 * @brief Provides an interface to the UART module
 *
 * @author Aaron Parks
  */

#ifndef UART_H_
#define UART_H_

#include <stdint.h>

void UART_init(void);
void UART_asyncSend(uint8_t* txBuf, uint16_t size);
void UART_send(uint8_t* txBuf, uint16_t size);
void UART_critSend(uint8_t* txBuf, uint16_t size);
uint8_t UART_isTxBusy();

#endif /* UART_H_ */
