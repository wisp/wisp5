/**
 * accel.h
 *
 *  @date Aug 2013
 *  @author Aaron Parks
 */

#ifndef ACCEL_H_
#define ACCEL_H_

#include "../globals.h"

typedef struct {
    uint16_t x;
    uint16_t y;
    uint16_t z;
} threeAxis_t;

typedef struct {
    uint8_t x;
    uint8_t y;
    uint8_t z;
} threeAxis_t_8;

BOOL ACCEL_initialize();
BOOL ACCEL_singleSample(threeAxis_t_8* result);
BOOL ACCEL_readStat(threeAxis_t_8* result);
BOOL ACCEL_readID(threeAxis_t_8* result);
BOOL ACCEL_reset();
BOOL ACCEL_range();


#endif /* ACCEL_H_ */
