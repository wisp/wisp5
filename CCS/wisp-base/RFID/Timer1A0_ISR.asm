;/***********************************************************************************************************************************/
;/**@file		Timer1A1_ISR.asm
;* 	@brief		Communications timeout interrupt service routine
;* 	@details
;*
;* 	@author		Aaron Parks
;*/
;/***********************************************************************************************************************************/

	.cdecls C, LIST, "../globals.h", "../config/wispGuts.h", "rfid.h"
	.define "0", SR_SP_OFF
	.retain
	.retainrefs

;*************************************************************************************************************************************
;	Timer1A1 ISR:
;   Interrupt Sources: TA1CCR0												 														 *
;*************************************************************************************************************************************
Timer1A0_ISR:						;[6] entry cycles into an interrupt (well, 5-6)
	MOV.B	#1,	(rfid.abortFlag)	; Abort RFID on ISR exit
	BIC		#(SCG1+OSCOFF+CPUOFF+GIE), SR_SP_OFF(SP);[] take tag out of LPM4
	RETI							;[5] return from interrupt

;*************************************************************************************************************************************
; DEFINE THE INTERRUPT VECTOR ASSIGNMENT																							 *
;*************************************************************************************************************************************
	;.sect	".int41"			    ; Timer1_A0 Vector <-> int41
	;.short  Timer1A0_ISR			;
	.end