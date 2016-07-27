;/***********************************************************************************************************************************/
;/**@file       Timer0A0_ISR.asm
;*  @brief      Implement the receiving mechanism of RFID (RTCAL, TRCAL, data bits).
;*
;*  @author     Justin Reina, UW Sensor Systems Lab
;*  @created
;*  @last rev
;*
;*  @notes
;*
;*	@TODO
;*/
;/***********************************************************************************************************************************/

	.cdecls C, LIST, "../globals.h", "../config/wispGuts.h", "rfid.h"
	.define "0", SR_SP_OFF
	.retain
	.retainrefs

;Register Defs
R_dest          .set  R4
R_bits          .set  R5
R_bitCt         .set  R6
R_newCt         .set  R7
R_pivot         .set  R8
R_scratch2      .set  R9
R_wakeupBits    .set  R10
R_scratch0      .set  R15


;*************************************************************************************************************************************
;   Timer0A0 ISR: Save timer values on entry, then parse and deploy mode accordingly.
;*************************************************************************************************************************************
Timer0A0_ISR:                                                ;[6]

	MOV     &TA0CCR0, R_newCt                                ;[3] Store the timer value where the falling edge was detected.
	SUB     &(rfid.edge_capture_prev_ccr), R_newCt           ;[]  delta = new_edge - prev_edge
	MOV     &TA0CCR0, &(rfid.edge_capture_prev_ccr)          ;[]  prev_edge = new_edge
	
	BIC     #CCIFG, &TA0CCTL0                                ;[4] Clear interrupt flag so the timer can continue.
	
	; Check how many bits we have received.
	CMP     #(2), R_bits                                     ;[2]
	JGE     ModeD_process                                    ;[2] R_bits = 2  -> rest of data bits
	CMP     #(1), R_bits                                     ;[2]
	JEQ     ModeC_process                                    ;[2] R_bits = 1  -> 2nd data bit
	CMP     #(0), R_bits                                     ;[2]
	JEQ     ModeB_process                                    ;[2] R_bits = 0  -> TRCAL and/or 1st data bit
	CMP     #(-1), R_bits                                    ;[2] R_bits = -1 -> RTCAL
	JEQ     ModeA_process                                    ;[2]
	
	INC     R_bits                                           ;[0] Else, we detected the falling edge of data-0 after the delimiter.
	RETI                                                     ;[5] Return from interrupt.

;*************************************************************************************************************************************
;   MODE A: RTCal
;*************************************************************************************************************************************
ModeA_process:
	CMP     #RTCAL_MIN, R_newCt                              ;[2] RTCAL >= 2.5*TARI - PW?
	JL      failed_RTCal                                     ;[2] RTCAL  too small
	CMP     #RTCAL_MAX, R_newCt                              ;[2] RTCAL <= 3*TARI - PW?
	JGE     failed_RTCal                                     ;[2] RTCAL too large
	
	;RTCAL is correct length, now proceed to compute pivot.
	MOV     R_newCt, R_scratch2                              ;[1] Save RTCAL to compare with TRCAL later on.
	RRA     R_newCt                                          ;[1] pivot = RTCAL/2
	MOV     #(-1), R_pivot                                   ;[1] Preload pivot value with MAX (i.e. 0xFFFFh)
	SUB     R_newCt, R_pivot                                 ;[1] Make pivot negative (so we can use ADD later on).
	INC     R_bits                                           ;[1] RTCAL done, proceed to read TRCAL and/or 1st data bit.
	RETI                                                     ;[5] Return


;*************************************************************************************************************************************
;	MODE B: TRCal/bit0
;*************************************************************************************************************************************
ModeB_process:
	CMP     R_scratch2, R_newCt                              ;[1] delta >= RTCAL -> TRCAL, else 1st data bit.
	JGE     ModeB_TRCal                                      ;[2]
	NOP                                                      ;[]  Pipeline dodging. TODO: Is this needed?
	NOP
	NOP
	
ModeB_dataBit:
	ADD     R_pivot, R_newCt                                 ;[1] -pivot + delta > FFFF will result in carry bit.
	ADDC.B  @R_dest+,-1(R_dest)                              ;[5] Add R_dest to itself, i.e. multiply by 2, i.e. shift 1 bit left. Then add carry from previous operation.
	INC     R_bits                                           ;[1] Increment bit received count.
	INC     R_bitCt                                          ;[1] Increment current command bit received count.
	DEC     R_dest                                           ;[]
	RETI                                                     ;[5] Return

ModeB_TRCal:
	CMP     #TRCAL_MIN, R_newCt                              ;[2] TRCAL >= 1.1*RTCAL_ESTIMATE?
	JL      failed_TRCal                                     ;[2] TRCAL too small
	CMP     #TRCAL_MAX,  R_newCt                             ;[2] TRCAL <= 3 RTCAL_ESTIMATE?
	JGE     failed_TRCal                                     ;[2] TRCAL too large
	
	CLR     R_bitCt                                          ;[1] Since we received full preamble, clear current command bit received count.
	RETI                                                     ;[5] Return


;*************************************************************************************************************************************
;   MODE C: bit1
;*************************************************************************************************************************************
ModeC_process:
	ADD     R_pivot, R_newCt                                 ;[1] -pivot + delta > FFFF will result in carry bit.
	ADDC.B  @R_dest+, -1(R_dest)                             ;[5] Add R_dest to itself, i.e. multiply by 2, i.e. shift 1 bit left. Then add carry from previous operation.
	
	; We have now received 2 bits, check if it's the QueryRep command. (6.3.2.12.2.3)
	MOV.B   (cmd), R_scratch0                                ;[2] Pull cmd_buffer (b1b0)
	AND.B   #0x03, R_scratch0                                ;[2] Mask out everything but b1b0 (i.e. use only first 2 bits)
	CMP.B   #0x00, R_scratch0                                ;[1] Compare command with "00"
	JEQ     ModeC_queryRep                                   ;[2]
	
	; If we did get a queryRep, we don't need to do these operations (because WISP is ignoring session field anyway).
	INC     R_bits                                           ;[1] update R5(bits) cause we got a databit
	INC     R_bitCt                                          ;[1] mark that we've stored a bit into r6(currCmdBits)
	DEC     R_dest
	RETI                                                     ;[5] return from interrupt
	
ModeC_queryRep:
	MOV.W   #(0), &TA0CTL                                    ;[4] turn off the timer
	MOV.B   #CMD_PARSE_AS_QUERY_REP, &cmd                    ;[4] set the cmd[0] to a known value for queryRep to parse.
	BIC.W   #(LPM4), SR_SP_OFF(SP)             ;[5] Turn off interrupts, enable clock!
	RETI                                                     ;[5] return from interrupt


;*************************************************************************************************************************************
;	MODE D: Plain ol' Data Bit (bits>=2)
;*************************************************************************************************************************************
ModeD_process:
	ADD     R_pivot, R_newCt                                 ;[1] -pivot + delta > FFFF will result in carry bit.
	ADDC.B  @R_dest+, -1(R_dest)                             ;[5] Add R_dest to itself, i.e. multiply by 2, i.e. shift 1 bit left. Then add carry from previous operation.
	
	INC     R_bits                                           ;[1] update R5(bits) cause we got a databit
	INC     R_bitCt                                          ;[1] mark that we've stored a bit into r6(currCmdBits)
	
	; Check if byte is finished in cmd.
	CMP.W   #(8), R_bitCt                                    ;[1]
	JGE     ModeD_setupNewByte                               ;[2]
	DEC     R_dest
	RETI                                                     ;[5] return from interrupt


ModeD_setupNewByte:
	CLR     R_bitCt                                          ;[1] Clear bit count for next byte in cmd buffer.
	BIC     #(LPM4), SR_SP_OFF(SP)             ;[5] enable the clock so the doRFIDThread can parse b7-b4! *Leave Interrupts On.
	RETI                                                     ;[5] return from interrupt


;*************************************************************************************************************************************
;   MODE FAILS: Reset RX State Machine
;*************************************************************************************************************************************
failed_RTCal:
failed_TRCal:
   	CLR		&TA0CTL				;[] Disable TimerA before exiting the ISR after a fail observed to allow going to lpm4.
	CLR     R_bits                                           ;[1] reset R5 for rentry into RX State Machine
	CLR     R_bitCt                                          ;[]
	; TODO The following shouldn't overwrite other bits in PRXSEL!?
	BIC.B   #PIN_RX, &PRXSEL0                                ;[] disable TimerA1
	BIC.B   #PIN_RX, &PRXSEL1                                ;[] disable TimerA1
	BIC.W   #4010h, TA0CCTL0                                 ;[5] Turn off TimerA1 -> 4010h -> b14+b4 -> TA0CCTL1 &= ~CM0+CCIE (CM0-> CAPTURE ON RISING EDGE)
	CLR.B   &PRXIFG                                          ;[] clr any pending flags (safety)
	BIS.B   #PIN_RX, &PRXIES                                 ;[4] wait again for #1 to fire on falling edge
	MOV.B   #PIN_RX, &PRXIE                                  ; Enable the interrupt
	
	RETI                                                     ;[5] return from interrupt

;*************************************************************************************************************************************
;   DEFINE THE INTERRUPT VECTOR ASSIGNMENT
;*************************************************************************************************************************************
	;.sect	".int45"                                         ; Timer0_A0 Vector
	;.short  Timer0A0_ISR                                    ; This sect/short pair sets int53 = Timer0A0_ISR addr.
	.end
