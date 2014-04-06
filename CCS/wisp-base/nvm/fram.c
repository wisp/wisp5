/**
 * @file fram.c
 *
 * Provides access routines for FRAM non-volatile memory in the MSP430FR5xxx
 *
 * @author Saman Naderiparizi, Aaron Parks
 */

#include <msp430.h>
#include "fram.h"

/**
 * Call before writing anything to FRAM
 */
void FRAM_init(void){

	FRCTL0_H |= (FWPW) >> 8;
	__delay_cycles(3);
}

////// Write functions with the physical address

void FRAM_write_long_array(uint32_t *address, uint16_t numberOfLongs , uint32_t *writeData){

	int i;

	for(i = 0 ; i < numberOfLongs ; i++){
		*address = *writeData;
		writeData++;
		address++;
	}

}

void FRAM_write_int_array(uint16_t *address, uint16_t numberOfInts , uint16_t *writeData){

	int i;

	for(i = 0 ; i < numberOfInts ; i++){
		*address = *writeData;
		writeData++;
		address++;
	}

}

void FRAM_write_char_array(uint8_t *address, uint16_t numberOfChars , uint8_t *writeData){

	int i;

	for(i = 0 ; i < numberOfChars ; i++){
		*address = *writeData;
		writeData++;
		address++;
	}
}

///// Write to the offset address according to the specified segment.
///// info segment A

void FRAM_write_infoA_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOA_START_ADX) + addressOffset;

	FRAM_write_long_array(address , numberOfLongs , writeData);

}

void FRAM_write_infoA_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOA_START_ADX) + addressOffset;

	FRAM_write_int_array(address , numberOfInts , writeData);

}

void FRAM_write_infoA_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOA_START_ADX) + addressOffset;

	FRAM_write_char_array(address , numberOfChars , writeData);
}

///////////// info segment B

void FRAM_write_infoB_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOB_START_ADX) + addressOffset;

	FRAM_write_long_array(address , numberOfLongs , writeData);

}

void FRAM_write_infoB_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOB_START_ADX) + addressOffset;

	FRAM_write_int_array(address , numberOfInts , writeData);

}

void FRAM_write_infoB_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOB_START_ADX) + addressOffset;

	FRAM_write_char_array(address , numberOfChars , writeData);
}

///////////// info segment C

void FRAM_write_infoC_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOC_START_ADX) + addressOffset;

	FRAM_write_long_array(address , numberOfLongs , writeData);

}

void FRAM_write_infoC_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOC_START_ADX) + addressOffset;

	FRAM_write_int_array(address , numberOfInts , writeData);

}

void FRAM_write_infoC_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOC_START_ADX) + addressOffset;

	FRAM_write_char_array(address , numberOfChars , writeData);
}

///////////// info segment D

void FRAM_write_infoD_long(int addressOffset , uint16_t numberOfLongs , uint32_t *writeData){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOD_START_ADX) + addressOffset;

	FRAM_write_long_array(address , numberOfLongs , writeData);

}

void FRAM_write_infoD_int(int addressOffset , uint16_t numberOfInts , uint16_t *writeData){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOD_START_ADX) + addressOffset;

	FRAM_write_int_array(address , numberOfInts , writeData);

}

void FRAM_write_infoD_char(int addressOffset , uint16_t numberOfChars , uint8_t *writeData){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOD_START_ADX) + addressOffset;

	FRAM_write_char_array(address , numberOfChars , writeData);
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////// Read functions with the physical address

uint32_t FRAM_read_long(uint32_t *address){

	return *address;

}

uint16_t FRAM_read_int(uint16_t *address){

	return *address;

}

uint8_t FRAM_read_char(uint8_t *address){

	return *address;
}

///// Write to the offset address according to the specified segment.
///// info segment A

uint32_t FRAM_read_infoA_long(int addressOffset){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOA_START_ADX) + addressOffset;

	return *address;
}

uint16_t FRAM_read_infoA_int(int addressOffset){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOA_START_ADX) + addressOffset;

	return *address;
}

uint8_t FRAM_read_infoA_char(int addressOffset){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOA_START_ADX) + addressOffset;

	return *address;
}

///////////// info segment B

uint32_t FRAM_read_infoB_long(int addressOffset){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOB_START_ADX) + addressOffset;

	return *address;

}

uint16_t FRAM_read_infoB_int(int addressOffset){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOB_START_ADX) + addressOffset;

	return *address;

}

uint8_t FRAM_read_infoB_char(int addressOffset){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOB_START_ADX) + addressOffset;

	return *address;

}

///////////// info segment C

uint32_t FRAM_read_infoC_long(int addressOffset){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOC_START_ADX) + addressOffset;

	return *address;

}

uint16_t FRAM_read_infoC_int(int addressOffset){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOC_START_ADX) + addressOffset;

	return *address;

}

uint8_t FRAM_read_infoC_char(int addressOffset){

	unsigned char *address;
	address = ((unsigned char *) FRAM_INFOC_START_ADX) + addressOffset;

	return *address;

}

///////////// info segment D

uint32_t FRAM_read_infoD_long(int addressOffset){

	unsigned long *address;
	address = ((unsigned long *)FRAM_INFOD_START_ADX) + addressOffset;

	return *address;

}

uint16_t FRAM_read_infoD_int(int addressOffset){

	unsigned int *address;
	address = ((unsigned int *)FRAM_INFOD_START_ADX) + addressOffset;

	return *address;

}

uint8_t FRAM_read_infoD_char(int addressOffset){

	unsigned char *address;
	address = ((unsigned char *)FRAM_INFOD_START_ADX) + addressOffset;

	return *address;

}





