;/**@file		Clocking.asm
;*	@brief		Sets the proper clocks for Tx and Rx
;*
;*	@author		Saman Naderiparizi, UW Sensor Systems Lab
;*	@created	3-10-14
;*
;*
;*	@section	Command Handles
;*				-#TxClock , RxClock
;*/

;/INCLUDES----------------------------------------------------------------------------------------------------------------------------
    .cdecls C,LIST, "../globals.h"
    .cdecls C,LIST, "rfid.h"
	.def  TxClock, RxClock

TxClock:
	MOV.B           #(0xA5), &CSCTL0_H ;[] Switch to corr Tx frequency 12MHz
	MOV.W           #(DCORSEL|DCOFSEL_6), &CSCTL1 ;
	MOV.W           #(SELA_1|SELM_3), &CSCTL2     ;
	BIS.W           #(SELS_3), &CSCTL2
	MOV.W           #(DIVA_0|DIVS_1|DIVM_1), &CSCTL3 ;
	BIC.W           #(MODCLKREQEN|SMCLKREQEN|MCLKREQEN), &CSCTL6
	BIS.W			#(ACLKREQEN), &CSCTL6

	RETA


RxClock:
	MOV.B           #(0xA5), &CSCTL0_H ;[] Switch to corr Rx frequency  16MHz
	MOV.W           #(DCORSEL|DCOFSEL_4), &CSCTL1 ;
	MOV.W           #(SELA_1|SELM_3), &CSCTL2     ;
	BIS.W           #(SELS_3), &CSCTL2
	MOV.W           #(DIVA_0|DIVS_0|DIVM_0), &CSCTL3 ;
	BIC.W           #(MODCLKREQEN|SMCLKREQEN|MCLKREQEN), &CSCTL6
	BIS.W			#(ACLKREQEN), &CSCTL6
	
	RETA

	.end
