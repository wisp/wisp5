;/***********************************************************************************************************************************/
;/**@file		Timer0A1_ISR.asm
;* 	@brief		Receive chain decoding routines.
;* 	@details
;*
;* 	@author		Justin Reina, UW Sensor Systems Lab
;* 	@created
;* 	@last rev
;*
;* 	@notes
;*
;*	@todo		Document the purpose(s) of this ISR better
;*/
;/***********************************************************************************************************************************/

	.cdecls C, LIST, "../globals.h", "../config/wispGuts.h", "rfid.h"
	.define "4", SR_SP_OFF
	.retain
	.retainrefs

;*************************************************************************************************************************************
;	Timer0A1 ISR:
; Modes: #CPU_OFF:   still in latch mode. shut down TA0_SM and restart RX State Machine                               				 *
;        #CPU_ON:    in parse mode. abort & send false message to EPC_SM so it doesn't hang. this state should never happen though.. *
;																																	 *
; Interrupt Sources: T0A1CCR0												 														 *
;*************************************************************************************************************************************
Timer0A1_ISR:						;[6] entry cycles into an interrupt (well, 5-6)
	PUSHM.A		#1,	R15				;[] save R15

	;---------------------------------------Check What State the Receive Chain is in-------------------------------------------------
	MOV	SR_SP_OFF(SP),  R15			;[]Grab previous SR (last item that was shoved 4 bytes beforehand "PUSHM.A")
	BIT	#CPUOFF, R15				;[]Check to see if the CPU was off.
	JZ	CPU_is_on					;[]

	;---------------------------------------------------(CPU IS OFF)-----------------------------------------------------------------
CPU_is_off:		;[]i.e. we're still in latch mode. restart the RX State Machine. Two entries here: either from RX State Machine or TA1_SM.
				; or... lowPowerSleep() is using it
	CMP.B	#TRUE, &isDoingLowPwrSleep;[] is the lowPowerSleep() call using it!?
	JEQ		Wakeup_Proc
	MOV.B	&isDoingLowPwrSleep, R15	;/** @todo This line seems unnecessary... */

	;we're gonna be careful on the TA1_SM for now because that should never happen. so just for now we'll add on clr R6 & rst R4.
	MOV		&(cmd), R4				;[] shouldn't need, just for safety (make sure TA1 starts up ok)
	CLR 	R5						;[1] reset R5 for rentry into RX State Machine
	BIC.B	#(PIN_RX), &PRXIES		;[4] wait again for #1 to fire on rising edge(inverted)  //@us_change, enable
	BIS.B	#(PIN_RX), &PRXIE		;[]Enable the interrupt
	CLR.B	PRXIFG					;[]clr any pending flasgs (safety)
	; TODO The following shouldn't overwrite other bits in PRXSEL!?
	BIC.B	#PIN_RX, &PRXSEL0					;[]disable TimerA1
	BIC.B	#PIN_RX, &PRXSEL1					;[]disable TimerA1

	BIC.B	#(CM_2+CCIE), &TA0CCTL0	;[] disable capture and interrupts by capture-compare unit
	BIC		#(CCIFG),	TA0CCTL0	;[] clear the interrupt flag
	BIS		#(SCG1+OSCOFF+CPUOFF+GIE), SR_SP_OFF(SP);[] put tag back into LPM4

	POPM.A #1, R15
	RETI							;[5] return from interrupt

Wakeup_Proc:

	BIC		#(CCIFG),	TA0CCTL0	;[] clear the interrupt flag
	;@us change:clear TA0CTL and TA0CCTL1, because lowpowermode is controlled by TA0CCTL1
	CLR TA0CTL
    CLR TA0CCTL0				;[]clear TA0CCTL0, no need to clear out of ISR
	CLR	TA0CCTL1				;[]clear TA0CCTL1, no need to clear out of ISR
	
	MOV		#(FALSE), &isDoingLowPwrSleep ;[] clear that flag!

	BIC		#(SCG1+OSCOFF+CPUOFF+GIE), SR_SP_OFF(SP);[] take tag out of LPM4
	POPM.A #1, R15
	RETI							;[5] return from interrupt

	;----------------------------------------------------(CPU IS ON)-----------------------------------------------------------------
CPU_is_on:		;i.e. we're now in parse mode
	;uh-oh. chances are that the EPC_SM is already to while(bits<NUM_X); by now we've already failed the command, so set bits high
	;wakeup. The command will be parsed in error and potentially handled in error, oh well. This command was already failed. This case
	;should never ever happen though.
	ADD 	#0xF000, R5				;[] set bits to a large value so machine can break out
	BIC		#(CCIFG),	TA0CCTL0	;[] clear the interrupt flag

	BIC		#(SCG1+OSCOFF+CPUOFF+GIE), SR_SP_OFF(SP);[] put tag back into LPM4
	POPM.A #1, R15
	RETI							;[5] return from interrupt

;*************************************************************************************************************************************
; DEFINE THE INTERRUPT VECTOR ASSIGNMENT																							 *
;*************************************************************************************************************************************
	;.sect	".int44"			    ; Timer0_A1 Vector
	;.short  Timer0A1_ISR			; This sect/short pair sets int52 = Timer0A1_ISR addr.
	.end
