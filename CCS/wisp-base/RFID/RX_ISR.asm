;/************************************************************************************************************************************
;*                                           PORT 1 ISR (Starting a Command Receive)
;*   Here starts the hard real time stuff.
;*   MCLK is 16 MHz (See Clocking.asm) -> 0.0625 us per cycle
;*   Entering ISR takes 6 cycles (4.5.1.5.1) + Time needed to wake up from LPM1 (~4 us)
;*   Each BIT.B takes 5-1 cycles (4.5.1.5.4)
;*   Each JNZ or JZ takes 2 cycles regardless whether it is taken or not (4.5.1.5.3)
;*   Start this ISR at t = 0.375 us + wake up time (~1.5 us?) TODO: Find out  this exact wakeup time or why we have this gap.
;*   Listed instruction cycles are taken from MSP430FR5969 User Guide (SLAU367F).
;*
;*   Purpose:
;*   This ISR kicks in on a falling edge and tries to find the rising edge marking the end of the delimiter of a PREAMBLE/FRAME-SYNC.
;*   After that, we disable PORT1 interrupts and setup Timer0A0.
;*   In the worst case (readers with 6.25 Tari), we only have 0.475*6.25 us = 47 clock cycles) before the falling edge of data-0.
;*   Then we quickly return from this interrupt and wait for Timer0A0 to wake us up on the data-0 falling edge.
;*   An ASCII drawing of the situation can be found below:
;*
;*   |   data-0  |           RTCAL             |
;*   /-----\_____/------------------------\____/   - Wave form
;*
;*************************************************************************************************************************************

	.cdecls C, LIST, "../globals.h"
	.retain
	.retainrefs

RX_ISR:
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]

	;;;Around 2.7us
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]

	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim

	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]

	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[3]
	JNZ		badDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[3]
	JNZ		badDelim				;[2]
	;;;Around 8.5us

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;*********************************************************************************************************************************
	; JUST RIGHT (8us < DELIM <16us @ 16MHz)
	;*********************************************************************************************************************************
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim

	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim				;[2]
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	BIT.B	#PIN_RX,	&PRXIN		;[4]
	JNZ		goodDelim
	;;;Around 16us

; Delim is too short so go back to sleep.
badDelim:
	BIT.B   R15, R14                                    ;[]
	BIC     #CCIFG, &TA0CCTL0                           ;[] Clear the interrupt flag for Timer0A0 Compare (safety).
	CLR     &TA0R                                       ;[] Reset TAR value
	CLR     &(rfid.edge_capture_prev_ccr)               ;[] Clear previous value of CCR capture.
	CLR.B   &PRXIFG                                     ;[] Clear the Port 1 flag.
	RETI

; We found a delim ~12.5 us, now turn off PORT1 and prepare Timer0A0.
goodDelim:                                              ;[24]
	BIS.B   #PIN_RX, &PRXSEL0                           ;[5] Enable Timer0A0
	BIC.B   #PIN_RX, &PRXSEL1                           ;[5] Enable Timer0A0
	CLR.B   &PRXIE                                      ;[4] Disable the Port 1 Interrupt
	BIC     #(SCG1), 0(SP)                              ;[5] Enable the DCO to start counting
	BIS.W   #(CM_2+CCIE), &TA0CCTL0                     ;[5] Wake up so we can make use of Timer0A0 control registers?

startupT0A0_ISR:                                        ;[22]
	BIC     #CCIFG, &TA0CCTL0                           ;[5] Clear the interrupt flag for Timer0A0 Compare
	CLR     &TA0R                                       ;[4] ***Reset clock!***
	CLR     &(rfid.edge_capture_prev_ccr)               ;[4] Clear previous value of CCR capture
	CLR.B   &PRXIFG                                     ;[4] Clear the Port 1 flag.
	
	RETI                                                ;[5] Return from interrupt (46 cycles total).

;*************************************************************************************************************************************
; DEFINE THE INTERRUPT VECTOR ASSIGNMENT
;*************************************************************************************************************************************
	;.sect ".int36"                                     ; Port 1 Vector
	;.short  RX_ISR                                     ; This sect/short pair sets int02 = RX_ISR addr.
	.end
