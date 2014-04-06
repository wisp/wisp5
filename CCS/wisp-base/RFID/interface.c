/**
 * @file interface.c
 *
 * Provides some client interfacing functions for the RFID module
 *
 * @author Aaron Parks
 */

#include "../globals.h"

uint8_t usrBank[USRBANK_SIZE];

/**
 *  Registers a callback for ACK event
 */
void WISP_registerCallback_ACK(void(*fnPtr)(void)){
	RWData.akHook = ((void*)(fnPtr));
}

/**
 * Registers a callback for READ event
 */
void WISP_registerCallback_READ(void(*fnPtr)(void)){
	RWData.rdHook = ((void*)(fnPtr));
}

/**
 * Registers a callback for a WRITE event
 */
void WISP_registerCallback_WRITE(void(*fnPtr)(void)){
	RWData.wrHook = ((void*)(fnPtr));
}

/**
 * Registers a callback for a BLOCKWRITE event
 */
void WISP_registerCallback_BLOCKWRITE(void(*fnPtr)(void)){
	RWData.bwrHook =((void*)(fnPtr));
}
