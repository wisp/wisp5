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
	; Tx desired clock frequency is about 2.67MHz which is set here.

	MOV.B		#(0xA5), &CSCTL0_H;[] Switch to corr Tx frequency
	MOV.W		#(DCOFSEL0), &CSCTL1;
	MOV.W		#(SELA_0|SELS_3|SELM_3), &CSCTL2;
	MOV.W		#(DIVA_0|DIVS_0|DIVM_0), &CSCTL3;

	RETA


RxClock:
	; Rx desired clock frequency is 4MHz which is set here.

	MOV.B		#(0xA5), &CSCTL0_H;[] Switch to corr Rx frequency
	MOV.W		#(DCOFSEL0|DCOFSEL1), &CSCTL1;
	MOV.W		#(SELA_0|SELS_3|SELM_3), &CSCTL2;
	MOV.W		#(DIVA_0|DIVS_0|DIVM_0), &CSCTL3;

	RETA

	.end
