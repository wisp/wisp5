/**
 * @file interface.c
 *
 * General access functions for interface between client code and WISP library
 *
 * @author Aaron Parks
 */


#include "globals.h"

// Access macro for above, please rewrite as function
void WISP_getDataBuffers(WISP_dataStructInterface_t* clientStruct) {
	clientStruct->epcBuf=&dataBuf[2];
	clientStruct->writeBufPtr=&(RWData.wrData);
	clientStruct->blockWriteBufPtr=RWData.bwrBufPtr;
	clientStruct->blockWriteSizePtr=&(RWData.bwrByteCount);
	clientStruct->readBufPtr=&usrBank[0];
}
