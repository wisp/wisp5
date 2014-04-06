/**
 * @file accel.h
 *
 * Interface to the ADXL362 accelerometer driver
 *
 * @author Aaron Parks
 */

#ifndef ACCEL_H_
#define ACCEL_H_

#include "../globals.h"

typedef struct {
    uint16_t x;
    uint16_t y;
    uint16_t z;
} threeAxis_t;

BOOL ACCEL_initialize();
BOOL ACCEL_singleSample(threeAxis_t* result);


#endif /* ACCEL_H_ */
