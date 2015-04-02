;/***********************************************************************************************************************************/
;/**@file		WISP_doRFID.asm
;* 	@brief		This is the main RFID loop that executes an RFID transaction
;* 	@details
;*
;* 	@author		Justin Reina, UW Sensor Systems Lab
;* 	@created	6.14.11
;* 	@last rev
;*
;* 	@notes
;*
;*	@todo		Maybe doRFID() should 1) take arguments which set RFID response mode, and 2) return last cmd to which it responded
;*	@todo		doRFID() should sleep_till_full_power() after a transaction when it's in a mode where it doesn't always return...
;*/
;/***********************************************************************************************************************************/

;/INCLUDES----------------------------------------------------------------------------------------------------------------------------
    .cdecls C,LIST, "../globals.h"
    .cdecls C,LIST, "rfid.h"
	.def  WISP_doRFID
	.global handleAck, handleQR, handleReqRN, handleRead, handleWrite, handleSelect, WISP_doRFID, TxClock, RxClock

;/PRESERVED REGISTERS-----------------------------------------------------------------------------------------------------------------
R_bitCt			.set  R6
R_bits			.set  R5
R_dest			.set  R4

R_wakeupBits	.set  R10

R_scratch0  	.set  R15



WISP_doRFID:
;/************************************************************************************************************************************
;/								PREP THE DATABUF W/STOREDPC AND A CRC16 (225 cycles, 55us)                                     		 *
;/************************************************************************************************************************************
	;Load the Stored Protocol Control (PC) values
	MOV.B		#(STORED_PC1), &(dataBuf)	;[5]
	MOV.B		#(STORED_PC0), &(dataBuf+1)	;[5]

	;Data was already loaded by user into B2..B13, so we don't need to load it.
	;[0]! cool...

	;Calc CRC16! (careful, it will clobber R11-R15)
	;uint16_t crc16_ccitt(uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
	MOV		#(dataBuf),		R13		;[2] load &dataBuf[0] as dataPtr
	MOV		#(14),			R14		;[2] load num of bytes in ACK

	MOV 	#CRC_NO_PRELOAD, R12 	;[1] don't use a preload!

	CALLA	#crc16_ccitt			;[5+196]
	;onReturn: R12 holds the CRC16 value.

	;STORE CRC16
	MOV.B	R12,	&(dataBuf+15)	;[4] store lower CRC byte first
	SWPB	R12						;[1] move upper byte into lower byte
	MOV.B	R12,	&(dataBuf+14)	;[4] store upper CRC byte


	;Initial Config of RFID Transaction
	MOV.B	#FALSE, &(rfid.abortFlag);[] Initialize abort flag
	;BIS.B	#(PIN_RX_EN), &PRXEOUT	;[] enable the receive comparator for a new round

keepDoingRFID:
;/************************************************************************************************************************************
;/										SET TO FASTER CLOCK               						                                     *
;/************************************************************************************************************************************
	DINT 									;[] safety
	NOP

	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 	;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1	;[] ""

	CALLA #RxClock	;Switch to Rx Clock

;/************************************************************************************************************************************
;/										CONFIG, ENABLE The RX State Machine															 *
;/************************************************************************************************************************************
	;Configure Hardware (Port, Rx Comp)
	BIC.B 	#PIN_RX, &PRXSEL0			;[] make sure TimerA is disabled (safety)
	BIC.B 	#PIN_RX, &PRXSEL1			;[] make sure TimerA is disabled (safety)

	;TIMER A CONFIG (pre before RX ISR)
	CLR		&TA0CTL				;[] Disable TimerA before config (required)
	CLR		&TA0R				;[] Clear Ctr
	CLR		&(rfid.edge_capture_prev_ccr) ;[] Clear previous value of CCR capture
	MOV		#0xFFFF,&TA0CCR1	;[] Don't let timer0A1 overflow!
	CLR		&TA0CCTL1			;[] Don't do the overflow, yet on T0A1

	;@us change:clear TA0
	CLR		&TA0CCTL0

	MOV		#(SCS+CAP+CCIS_1),&TA0CCTL0	;[] Sync on Cap Src and Cap Mode on Rising Edge(Inverted). don't set all bits until in RX ISR though.
	MOV		#(TASSEL__SMCLK+MC__CONTINOUS) , &TA0CTL 		;[] SMCLK and continuous mode.  (TASSEL1 + MC1)

	;Setup rfid_rxSM vars
	MOV		#RESET_BITS_VAL, R_bits	 ;[]MOD
	CLR		R_bitCt					 ;[]
	MOV		#(cmd), R_dest			 ;[]load the R_dest to the reg!

	;RX State Machine Config (setup PRX for falling edge interrupt on PRX.PIN_RX)
	BIS.B   #(PIN_RX_EN), &PDIR_RX_EN	;[]@us_change: config I/O here and quit after use
	BIS.B	#PIN_RX_EN, &PRXEOUT	;[] Enable the Receive Comparator
	;BIC.B	#PIN_RX,	&PDIR_RX	;[]@us_change: config I/O here and quit after use
	;@Saman
	;BIS.B   #(PIN_NRX_EN), &PDIR_NRX_EN	;[]@us_change: config I/O here and quit after use
	;BIC.B	#PIN_NRX_EN, &PNRXEOUT	;[] Enable the Receive Comparator (Enable the Negative Supply)


	
	BIS.B	#PIN_RX,	&PRXIES		;[] Make falling edge for port interrupt to detect start of delimiter

	CLR.B	&PRXIFG					;[] Clear interrupt flag
	MOV.B	#PIN_RX,	&PRXIE		;[] Enable Port1 interrupt

	; @todo Shouldn't we sleep_till_full_power here? Where else could that happen?
	BIS		#(GIE+SCG1+SCG0+OSCOFF+CPUOFF), SR			;[] sleep! (LPM4 | GIE)
	NOP

	;"it won't wakeup until either 8bits came in or QR
	; /** @todo Maybe implement some sort of timeout */


;/************************************************************************************************************************************
;/												DECODE COMMAND				                                                         *
;/	level1 = cmd[0] | 0xC0 (just examine the first two bits)																		 *
;/	every command except for select will be skipped if !rfid.isSelected																 *
;/***********************************************************************************************************************************/
decodeCmd_lvl1:
	MOV.B 	(cmd),  R_scratch0	;[] bring in cmd[0] to parse
	AND.B	#0xC0,  R_scratch0	;[] just compare the first two bits

	CMP.B	#0xC0,	R_scratch0
	JEQ		decodeCmd_lvl2_11
	CMP.B	#0x80,	R_scratch0
	JEQ		decodeCmd_lvl2_10

	CMP.B	#0,		&(rfid.isSelected)
	JZ		tagNotSelected

	CMP.B	#0x40,	R_scratch0
	JEQ		callAckHandler

	CMP.B	#0x00, R_scratch0
	JEQ		callQRHandler



	JMP		endDoRFID

;either Req_RN/Read/Write.
decodeCmd_lvl2_11:
	CMP.B	#0,		&(rfid.isSelected)
	JZ		tagNotSelected

	MOV.B 	(cmd),  R_scratch0	;[] bring in cmd[0] to parse
	CMP.B	#0xC1,	R_scratch0	;[] is it reqRN?
	JEQ		callReqRNHandler	;[]
	CMP.B	#0xC2,	R_scratch0	;[] is it read?
	JEQ		callReadHandler		;[]
	CMP.B	#0xC3,	R_scratch0	;[] is it write?
	JEQ		callWriteHandler	;[]
	CMP.B	#0xC7,	R_scratch0	;[] is it BlockWrite?
	JEQ		callBlockWriteHandler;[]
	JMP		endDoRFID 			;[] come back and handle after query is working.


; either Select/QA/Query
; level2 = cmd[0] | 0x30
decodeCmd_lvl2_10:

	MOV.B 	(cmd), 	R_scratch0	;[] bring in cmd[0] to parse
	AND.B	#0x30,  R_scratch0	;[] just compare the second two bits

	CMP.B	#0x20,	R_scratch0	;[] is it select?
	JEQ		callSelectHandler	;[]

	CMP.B	#0,		&(rfid.isSelected)
	JZ		tagNotSelected

	CMP.B	#0x10,	R_scratch0	;[] is it queryAdjust?
	JEQ		callQAHandler		;[]
	CMP.B	#0x00,	R_scratch0	;[] is it query?
	JEQ		callQueryHandler	;[]
	JMP		endDoRFID			;[] come back and handle after query is working.

;/************************************************************************************************************************************
;/								CALL APPROPRIATE COMMAND HANDLER						                                     		 *
;/************************************************************************************************************************************/

callSelectHandler:
	CALLA	#handleSelect
	JMP		endDoRFID

callQueryHandler:
	CALLA	#handleQuery
	JMP		endDoRFID

callQRHandler:
	CALLA	#handleQR
	JMP		endDoRFID

callQAHandler:
	CALLA	#handleQA
	JMP		endDoRFID

callAckHandler:
	CALLA	#handleAck
	JMP		endDoRFID

callReqRNHandler:
	CALLA	#handleReqRN
	JMP		endDoRFID

callReadHandler:
	BIT.B	#MODE_READ,	&(rfid.mode)
	JNC		endDoRFID
	CALLA	#handleRead
	JMP		endDoRFID

callWriteHandler:
	BIT.B	#MODE_WRITE, &(rfid.mode)
	JNC		endDoRFID
	CALLA	#handleWrite
	JMP		endDoRFID

callBlockWriteHandler:
	BIT.B	#MODE_WRITE, &(rfid.mode)
	JNC		endDoRFID
	CALLA	#handleBlockWrite
	JMP		endDoRFID


;/************************************************************************************************************************************/
;/										DECIDE IF STAYING IN RFID LOOP		                                                         *
;/																																	 *
;/ If the abort flag has been set during the RFID transaction, return! Otherwise, keep doing RFID.									 *
;/************************************************************************************************************************************/
endDoRFID:
	TST.B	(rfid.abortFlag)
	JZ		keepDoingRFID
	MOV		#(0), &(TA0CCTL0)
	RETA

tagNotSelected:
	BIC		#GIE,	0(SR)
	CLR		&TA0CTL
	RETA

	.end
