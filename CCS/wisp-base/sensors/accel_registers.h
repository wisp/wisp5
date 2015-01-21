/**
 * accel_registers.h
 *
 * Register map for the ADXL362 digital accelerometer
 *
 * @date Aug 2013
 * @author Aaron Parks
 */

#ifndef ACCEL_REGISTERS_H_
#define ACCEL_REGISTERS_H_

//
// Commands used for ADXL362 read/write access. Commands are sent prior to data/adx.
//
#define ADXL_CMD_WRITE_REG      0x0A
#define ADXL_CMD_READ_REG       0x0B
#define ADXL_CMD_READ_FIFO      0x0D

//
// Registers in the ADXL362. Created from the register map given in Table 11 of the datasheet.
//
#define ADXL_REG_DEVID_AD       0x00
#define ADXL_REG_DEVID_MST      0x01
#define ADXL_REG_PARTID         0x02
#define ADXL_REG_REVID          0x03
#define ADXL_REG_XDATA          0x08
#define ADXL_REG_YDATA          0x09
#define ADXL_REG_ZDATA          0x0A
#define ADXL_REG_STATUS         0x0B
#define ADXL_REG_FIFO_ENTRIES_L 0x0C
#define ADXL_REG_FIFO_ENTRIES_H 0x0D
#define ADXL_REG_XDATA_L        0x0E
#define ADXL_REG_XDATA_H        0x0F
#define ADXL_REG_YDATA_L        0x10
#define ADXL_REG_YDATA_H        0x11
#define ADXL_REG_ZDATA_L        0x12
#define ADXL_REG_ZDATA_H        0x13
#define ADXL_REG_TEMP_L         0x14
#define ADXL_REG_TEMP_H         0x15
#define ADXL_REG_Reserved0      0x16
#define ADXL_REG_Reserved1      0x17
#define ADXL_REG_SOFT_RESET     0x1F
#define ADXL_REG_THRESH_ACT_L   0x20
#define ADXL_REG_THRESH_ACT_H   0x21
#define ADXL_REG_TIME_ACT       0x22
#define ADXL_REG_THRESH_INACT_L 0x23
#define ADXL_REG_THRESH_INACT_H 0x24
#define ADXL_REG_TIME_INACT_L   0x25
#define ADXL_REG_TIME_INACT_H   0x26
#define ADXL_REG_ACT_INACT_CTL  0x27
#define ADXL_REG_FIFO_CONTROL   0x28
#define ADXL_REG_FIFO_SAMPLES   0x29
#define ADXL_REG_INTMAP1        0x2A
#define ADXL_REG_INTMAP2        0x2B
#define ADXL_REG_FILTER_CTL     0x2C
#define ADXL_REG_POWER_CTL      0x2D
#define ADXL_REG_SELF_TEST      0x2E


#endif /* ACCEL_REGISTERS_H_ */
