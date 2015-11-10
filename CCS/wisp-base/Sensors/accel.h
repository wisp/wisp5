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
    int8_t x;
    int8_t y;
    int8_t z;
} threeAxis_t_8;

BOOL ACCEL_initialize();
BOOL ACCEL_singleSample(threeAxis_t_8* result);
BOOL ACCEL_readStat(threeAxis_t_8* result);
BOOL ACCEL_readID(threeAxis_t_8* result);
BOOL ACCEL_reset();
BOOL ACCEL_range();
BOOL ACCEL_singleSample_FIFO(threeAxis_t_8* result);


#endif /* ACCEL_H_ */
