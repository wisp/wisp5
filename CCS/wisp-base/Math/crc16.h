/**
 * @file crc16.h
 *
 * Interface to the Cyclic Redundancy Check module
 *
 * @author Ivar in 't Veen, Aaron Parks
 */

#ifndef CRC16_H_
#define CRC16_H_

// DEFINES
#define ZERO_BIT_CRC    (0x1020)                                        /* state of the CRC16 calculation after running a '0'   */
#define ONE_BIT_CRC     (0x0001)                                        /* state of the CRC16 calculation after running a '1'   */
#define CRC_NO_PRELOAD  (0x0000)                                        /* don't preload it, start with 0!                      */
#define CCITT_POLY      (0x1021)

#ifndef __ASSEMBLER__
#include <stdint.h>                                                     /* use xintx_t good var defs (e.g. uint8_t)             */

// CRC calculation
extern uint16_t crc16_ccitt     (uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
extern uint16_t crc16Bits_ccitt (uint16_t preload,uint8_t *dataPtr, uint16_t numBytes,uint16_t numBits);

#endif /* __ASSEMBLER__ */

#endif /* CRC16_H_ */
