;/***********************************************************************************************************************************/
;/**@file		Timer0A0_ISR.asm
;* 	@brief		Receive chain decoding routines.
;* 	@details
;*
;* 	@author		Justin Reina, UW Sensor Systems Lab
;* 	@created
;* 	@last rev	
;*
;* 	@notes
;*
;*	@todo
;*/
;/***********************************************************************************************************************************/

	.cdecls C, LIST, "../globals.h", "../config/wispGuts.h"
	.define "0", SR_SP_OFF
	.retain
	.retainrefs

;Register Defs
R_dest			.set  R4
R_bits			.set  R5
R_bitCt			.set  R6
R_newCt			.set  R7
R_pivot			.set  R8
R_scratch2		.set  R9
R_wakeupBits	.set  R10
R_scratch0  	.set  R15


;*************************************************************************************************************************************
;	Timer0A0 ISR: On Entry Latch,Reset T0A0R. Then Parse and Deploy Mode
;*************************************************************************************************************************************
Timer0A0_ISR:						;[6] entry cycles into an interrupt (well, 5-6)

	 MOV		&TA0CCR0, 	R_newCt	;[3] latch TA0CCR1 value into the new count reg
	 SUB		&(rfid.edge_capture_prev_ccr), R_newCt; Compute delta by subtracting CCR value captured on previous edge
	 MOV		&TA0CCR0, 	&(rfid.edge_capture_prev_ccr); Update previous CCR value with current value (preparing for next edge)

     BIC		#CCIFG, 	&TA0CCTL0;[4] clear the TA1 interrupt flag
	
;Check Which Mode We Are In
	CMP		#(2),		R_bits		;[2]
	JGE		ModeD_process			;[2] deploy mode D (does a signed comparison)
	CMP		#(1),		R_bits		;[2]
	JEQ		ModeC_process			;[2] deploy mode C
	CMP		#(0),		R_bits		;[2]
	JEQ 	ModeB_process			;[2] deploy mode B
									;[0] else deploy mode A

;*************************************************************************************************************************************
;	MODE A: RTCal
;*************************************************************************************************************************************
ModeA_process:
; DEBUG!!
	CMP		#RTCAL_MIN,  R_newCt 	;[2]error catch: check if valid RTCal (i.e. if TA0CCR1<2TARI)
	JL		failed_RTCal		 	;[2] break if doesn't work.
    CMP		#RTCAL_MAX,	 R_newCt 	;[2]
    JGE		failed_RTCal		 	;[2] break if doesn't work.

	;ok valid RTCal, now process to get pivot(R8)
    MOV    	R_newCt, 	 R_scratch2 ;[1] Load R7 into a scratch reg(R9) so we can use this RTCal value in Mode 2 Processing next
    ADD		#RTCAL_OFFS, R_newCt 	;[2] Compensate for lost cycles in this measurement method to get to actual RTCal val.
    RRA   	R_newCt             	;[1] Divide R7 by 2
    MOV    	#(-1),		 R_pivot    ;[1] preload pivot value with MAX (i.e. 0xFFFFh)
    SUB    	R_newCt, 	 R_pivot  	;[1] pivotReg = pivotReg-(currCount/2) <-- This sets up the pivot reg for calc discussed.
    INC    	R_bits               	;[1] (r5=2) use r5 as a flag for the next entry (entry into mode 2)
    RETI                        	;[5] return from interrupt


;*************************************************************************************************************************************
;	MODE B: TRCal/bit0
;*************************************************************************************************************************************
ModeB_process:
	CMP    	R_scratch2, R_newCt		;[1] is currCount>RTCal? if so it's TRCal, else data
    JGE    	ModeB_TRCal        		;[2] if currCount>RTCal then jump to process TRCal


	;else it's databit0. store it!
ModeB_dataBit:
    ADD    	R_pivot, 	R_newCt    	;[1] do pivotTest (currCount = currCount+pivotReg. if Carry, its data1) <-note: thus dataBit is stored in carry.
    ADDC.B 	@R_dest+,	-1(R_dest) 	;[5] shift cmd[curr] by one (i.e. add it to itself), then store dataBit(carryFlag), into cmd[currCmdByte], then increment currCmdByte (all as one asm:))

    INC    	R_bits                  ;[1] update R5(bits) cause we got a databit
    INC    	R_bitCt                 ;[1] mark that we've stored a bit into r6(currCmdBits)
    DEC		R_dest
    RETI                        	;[5] return from interrupt


    ;Check if Valid TRCal (i.e. ~50.2us).
ModeB_TRCal:
    ;BIS.B	#PIN_DBG0, &PDBGOUT      ;@us_change: cancell debug line here
    ;BIC.B	#PIN_DBG0, &PDBGOUT
    CMP		#TRCAL_MIN, R_newCt		;[2]
    JL		failed_TRCal 			;[2] reset RX State Machine if TRCal is too short!! we won't check if too long, because 320kHz uses the max TRCal length.
    CMP		#TRCAL_MAX,  R_newCt 	;[2] error catch: check if valid TRCal (i.e. if TA0CCR1>2TARI)
	JGE		failed_TRCal			;[2]

    CLR    	R_bitCt					;[1] start the counting of R6 fresh (cause databits will come immeadiately following)
    RETI                        	;[5] return from interrupt


;*************************************************************************************************************************************
;	MODE C: bit1
;*************************************************************************************************************************************
ModeC_process:
    ADD    	R_pivot, 	R_newCt    	;[1] do pivotTest (currCount = currCount+pivotReg. if Carry, its data1) <-note: thus dataBit is stored in carry.
    ADDC.B 	@R_dest+,	-1(R_dest) 	;[5] shift cmd[curr] by one (i.e. add it to itself), then store dataBit(carryFlag), into cmd[currCmdByte], then increment currCmdByte (all as one asm:))
	;Check if Query Rep
	MOV.B	(cmd),		R_scratch0	;[2] pull in the first two dataBits (b1b0)
	AND.B	#0x03,		R_scratch0	;[2] mask out everything but b1b0
    CMP.B	#0x00,		R_scratch0	;[1] check if we got a queryRep
	JEQ		ModeC_queryRep			;[2]

    INC    	R_bits               	;[1] update R5(bits) cause we got a databit
    INC    	R_bitCt                 ;[1] mark that we've stored a bit into r6(currCmdBits)
    DEC		R_dest
	RETI                        	;[5] return from interrupt


ModeC_queryRep:
	MOV.W	#(0), 		&TA0CTL				;[4] turn off the timer
	MOV.B	#CMD_PARSE_AS_QUERY_REP, &cmd	;[4] set the cmd[0] to a known value for queryRep to parse.
    BIC.W	#(SCG1+CPUOFF+OSCOFF), SR_SP_OFF(SP);[5] Turn off interrupts, enable clock!
    RETI                        			;[5] return from interrupt


;*************************************************************************************************************************************
;	MODE D: Plain ol' Data Bit (bits>=2)
;*************************************************************************************************************************************
ModeD_process:
    ADD    	R_pivot, 	R_newCt    	;[1] do pivotTest (currCount = currCount+pivotReg. if Carry, its data1) <-note: thus dataBit is stored in carry.
    ADDC.B 	@R_dest+,	-1(R_dest) 	;[5] shift cmd[curr] by one (i.e. add it to itself), then store dataBit(carryFlag), into cmd[currCmdByte], then increment currCmdByte (all as one asm:))

    INC    	R_bits                  ;[1] update R5(bits) cause we got a databit
    INC    	R_bitCt                 ;[1] mark that we've stored a bit into r6(currCmdBits)

	;Check if that finished off a whole byte in cmd[]
	CMP.W		#(8),		R_bitCt	;[1] Check if we have gotten 8 bits
	JGE		ModeD_setupNewByte		;[2]
	DEC		R_dest
    RETI                        	;[5] return from interrupt


ModeD_setupNewByte:
	CLR		R_bitCt					;[1] Clear the Current Bit Count to reset for the next byte
	BIC		#(SCG1+CPUOFF+OSCOFF),	SR_SP_OFF(SP);[5] enable the clock so the doRFIDThread can parse b7-b4! *Leave Interrupts On.
    RETI                        	;[5] return from interrupt


;*************************************************************************************************************************************
;	MODE FAILS: Reset RX State Machine																								 *
;*************************************************************************************************************************************
failed_RTCal:
failed_TRCal:
	CLR 	R_bits					;[1] reset R5 for rentry into RX State Machine
	CLR		R_bitCt					;[]
	BIS.B	#PIN_RX, &PRXIES		;[4] wait again for #1 to fire on falling edge
	MOV.B	#PIN_RX, &PRXIE			; Enable the interrupt
	CLR.B	&PRXIFG					;[] clr any pending flasgs (safety)
	; TODO The following shouldn't overwrite other bits in PRXSEL!?
	BIC.B	#PIN_RX, &PRXSEL0				;[] disable TimerA1
	BIC.B	#PIN_RX, &PRXSEL1				;[] disable TimerA1
	BIC.W  	#4010h, TA0CCTL0     	;[5] Turn off TimerA1 -> 4010h -> b14+b4 -> TA0CCTL1 &= ~CM0+CCIE (CM0-> CAPTURE ON RISING EDGE)

	; /** @todo Figure out why the following line gives us trouble. What state do/should we return to here? */
	;BIS		#(LPM4+GIE), SR_SP_OFF(SP);[5] put tag back into LPM4, set GIE
    RETI                        	;[5] return from interrupt

;*************************************************************************************************************************************
; DEFINE THE INTERRUPT VECTOR ASSIGNMENT																							 *
;*************************************************************************************************************************************
	;.sect	".int45"			    ; Timer0_A0 Vector
	;.short  Timer0A0_ISR			; This sect/short pair sets int53 = Timer0A0_ISR addr.
	.end
