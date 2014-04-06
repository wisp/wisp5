/**
 * @file fram.h
 *
 * Provides an interface to the FRAM access routines for the MSP430FR5xxx
 *
 * @author Saman Naderiparizi, Aaron Parks
 */

#ifndef FRAM_H_
#define FRAM_H_

#include <stdint.h>

#define FRAM_INFOA_START_ADX 	0x1980
#define FRAM_INFOB_START_ADX 	0x1900
#define FRAM_INFOC_START_ADX 	0x1880
#define FRAM_INFOD_START_ADX 	0x1800

#define FRAM_write(address, writeData) (*(address))=(writeData)

void FRAM_init(void);

void FRAM_write_long_array(uint32_t *address , uint16_t numberOfLongs , uint32_t *writeData);
void FRAM_write_int_array(uint16_t *address , uint16_t numberOfInts , uint16_t *writeData);
void FRAM_write_char_array(uint8_t *address , uint16_t numberOfChars , uint8_t *writeData);

void FRAM_write_infoA_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData);
void FRAM_write_infoA_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData);
void FRAM_write_infoA_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData);

void FRAM_write_infoB_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData);
void FRAM_write_infoB_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData);
void FRAM_write_infoB_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData);

void FRAM_write_infoC_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData);
void FRAM_write_infoC_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData);
void FRAM_write_infoC_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData);

void FRAM_write_infoD_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData);
void FRAM_write_infoD_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData);
void FRAM_write_infoD_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData);


uint32_t FRAM_read_long(uint32_t *address);
uint16_t FRAM_read_int(uint16_t *address);
uint8_t FRAM_read_char(uint8_t *address);

uint32_t FRAM_read_infoA_long(int addressOffset);
uint16_t FRAM_read_infoA_int(int addressOffset);
uint8_t FRAM_read_infoA_char(int addressOffset);

uint32_t FRAM_read_infoB_long(int addressOffset);
uint16_t FRAM_read_infoB_int(int addressOffset);
uint8_t FRAM_read_infoB_char(int addressOffset);

uint32_t FRAM_read_infoC_long(int addressOffset);
uint16_t FRAM_read_infoC_int(int addressOffset);
uint8_t FRAM_read_infoC_char(int addressOffset);

uint32_t FRAM_read_infoD_long(int addressOffset);
uint16_t FRAM_read_infoD_int(int addressOffset);
uint8_t FRAM_read_infoD_char(int addressOffset);

#endif /* FRAM_H_ */
