;/***********************************************************************************************************************************/
;/**@file		rfid_WriteHandle.asm
;*	@brief
;* 	@details
;*
;*	@author		Justin Reina, UW Sensor Systems Lab
;*	@created
;*	@last rev
;*
;*	@notes
;*
;*	@section
;*
;*	@todo		Show the write command bitfields here
;*/
;/***********************************************************************************************************************************/

   .cdecls C,LIST, "../globals.h"

R_writePtr	.set  R13   			;[0] ptr to which membank at which offset will be reading from
R_handle	.set  R12				;[0] store inbound handle for Tx here.
R_scratch1	.set  R14
R_scratch0	.set  R15

   	.ref cmd,memBank_RES			;[0] declare TACCR1
	.def  handleWrite
	.global RxClock, TxClock
	.sect ".text"

;	extern void handleWrite (uint8_t handle);
handleWrite:

	;Wait for Enough Bits to Come in(8+8) (first two bytes come in, then memBank is in cmd[1].b7b6)
waitOnBits_0:
	MOV.W	R5,	R15					;[1]
	CMP.W	#16, R15				;[3] while(bits<18)
	JLO		waitOnBits_0			;[2]

	;Put Proper memBankPtr into WritePtr. Switch on Membank
calc_memBank:
	MOV.B	(cmd+1),R15				;[3] load cmd byte into R15. memBank is in b7b6 (0xC0)
	AND.B	#0xC0,	R15				;[2] mask of non-memBank bits, then switch on it to load corr memBankPtr
	RRA		R15						;[1] move b7b6 down to b1b0
	RRA		R15						;[1] ""
	RRA		R15						;[1] ""
	RRA		R15						;[1] ""
	RRA		R15						;[1] ""
	RRA		R15						;[1] ""
	MOV.B	R15,	&(RWData.memBank);[] store the memBank

	;Now wait for wordPtr to come in, and off R_readPtr by it. R15 is unused, R14 is held.
	;Wait for Enough Bits to Come in(2+8+8+8) (first three bytes come in, then wordPtr is in cmd[1].b5-b0 | cmd[2].b7b6
waitOnBits_1:
	MOV.W	R5,	R15					;[1]
	CMP.W	#24, R15				;[2] while(bits<26)
	JLO		waitOnBits_1			;[2]

calc_wordPtr:
	MOV.B 	(cmd+1), R15			;[3] bring in top 6 bits into b5-b0 of R15 (wordCt.b7-b2)
	MOV.B 	(cmd+2), R14			;[3] bring in bot 2 bits into b7b6  of R14 (wordCt.b1-b0)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b1)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b1)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b0)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b0)
	MOV.B	R15, R15				;[1] mask wordPtr to just lower 8 bits
	MOV.B	R15, &(RWData.wordPtr)	;[] store the wordPtr


	;Now wait for Data to come in.
	;Wait for Enough Bits to Come in(5*8) (first five bytes come in, then data&RN16 is in cmd[2].b5-b0|cmd[3]|cmd[4].b7b6
waitOnBits_2:
	MOV.W	R5,	R15					;[1]
	CMP.W	#40, R15				;[2] while(bits<26)
	JLO		waitOnBits_2			;[2]

	;Pull out Data and stuff into R14 (safe, R14 isn't used by RX_SM)
	MOV.B 	(cmd+2), R14			;[3] bring in top 6 bits into b5-b0 of R14 (data.b15-b10)
	MOV.B 	(cmd+3), R13			;[3] bring in mid 8 bits into b7-b0 of R13 (data.b9-b2)
	MOV.B 	(cmd+4), R12			;[3] bring in bot 2 bits into b7b6  of R12 (data.b1b0)

	RLC.B	R13						;[1]
	RLC.B	R14						;[1]
	RLC.B	R13						;[1]
	RLC.B	R14						;[1]
	RRC.B	R13						;[1]
	RRC.B	R13						;[1]

	RLC.B	R12						;[1]
	RLC.B	R13						;[1]
	RLC.B	R12						;[1]
	RLC.B	R13						;[1]

	SWPB	R14						;[1]
	BIS		R13, R14				;[] merge b15-b8(R14) and b7-b(R13) together into R14 as Data^RN16
	PUSHM.A	#1,	R14					;[] save the value to the stack for safekeeping

	;exit: data^RN16 is on stack @ 0(SP)

	;Now wait for RN16 to come in.
	;Wait for Enough Bits to Come in(7*8) (first seven bytes come in, then RN16 is in cmd[4].b5-b0|cmd[5]|cmd[6].b7b6
waitOnBits_3:
	MOV.W	R5,	R15					;[1]
	CMP.W	#56, R15				;[2] while(bits<26)
	JLO		waitOnBits_3			;[2] 						/** @todo Timeout needed here? */


;*************************************************************************************************************************************
;	[7a/8]	Check if handle matched.
;*************************************************************************************************************************************
	MOV.B		(cmd+4),	R_scratch0
	SWPB		R_scratch0
	MOV.B		(cmd+5),	R_scratch1
	BIS.W		R_scratch1, R_scratch0 ;cmd[4] into MSByte,  cmd[5] into LSByte of Rs0
	MOV.B		(cmd+6),	R_scratch1
	;Shove bottom 2 bits from Rs1 INTO Rs0
	RLC.B		R_scratch1
	RLC			R_scratch0
	RLC.B		R_scratch1
	RLC			R_scratch0	

;/** @todo Clean up the slop */
	
	;Check if Handle Matched
	CMP		R_scratch0, &rfid.handle
	JNE		writeHandle_Ignore

	;Pull out Data and stuff into R14 (safe, R14 isn't used by RX_SM)
	MOV.B 	(cmd+4), R14			;[3] bring in top 6 bits into b5-b0 of R14 (RN16.b15-b10)
	MOV.B 	(cmd+5), R13			;[3] bring in mid 8 bits into b7-b0 of R13 (RN16.b9-b2)
	MOV.B 	(cmd+6), R12			;[3] bring in bot 2 bits into b7b6  of R12 (RN16.b1b0)

	RLC.B	R13						;[1] /** @todo Document what this is doing, exactly... ? */
	RLC.B	R14						;[1]
	RLC.B	R13						;[1]
	RLC.B	R14						;[1]
	RRC.B	R13						;[1]
	RRC.B	R13						;[1]

	RLC.B	R12						;[1]
	RLC.B	R13						;[1]
	RLC.B	R12						;[1]
	RLC.B	R13						;[1]

	SWPB	R14						;[1]
	BIS		R13, R14				;[] merge b15-b8(R14) and b7-b(R13) together into R14 as RN16

	POPM.A	#1,	R13					;[] now data^RN16 is in R13
	XOR		R14, R13				;[] unXOR data & RN16 to reveal actual data value
	MOV		R13,	&(RWData.wrData);[] move the data out

;Load the Reply Buffer (rfidBuf)
	;Load up function call, the transmit! bam!
	MOV		(rfid.handle), 	R_scratch0;[3] bring in the RN16
	SWPB	R_scratch0				;[1] swap bytes so we can shove full word out in one call (MSByte into dataBuf[0],...)
	MOV		R_scratch0, &(rfidBuf)	;[4] load the MSByte

	;Calc CRC16! (careful, it will clobber R11-R15)
	;uint16_t crc16_ccitt(uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
	MOV		#(rfidBuf),		R13		;[2] load &dataBuf[0] as dataPtr
	MOV		#(2),			R14		;[2] load num of bytes in ACK

	MOV 	#ZERO_BIT_CRC, R12 		;[1]

	CALLA	#crc16_ccitt			;[5+196]
	;onReturn: R12 holds the CRC16 value.

	;STORE CRC16
	MOV.B	R12,	&(rfidBuf+3)	;[4] store lower CRC byte first
	SWPB	R12						;[1] move upper byte into lower byte
	MOV.B	R12,	&(rfidBuf+2)	;[4] store upper CRC byte

	CLRC
	RRC.B	(rfidBuf)
	RRC.B	(rfidBuf+1)
	RRC.B	(rfidBuf+2)
	RRC.B	(rfidBuf+3)
	RRC.B	(rfidBuf+4)

	;------------WAIT FOR FINAL BITS, THEN TRANSMIT-----------------------------------------------------------------------------------
waitOnBits_4:
	MOV.W	R5,	R15					;[1]
	CMP.W	#NUM_WRITE_BITS, R15	;[2] while(bits<66)
	JLO		waitOnBits_4			;[2]

haltRxSM_inWriteHandle:
	;this should be the equivalent of the RxSM call in C Code. WARNING: if RxSM() ever changes, change it here too!!!!
	DINT							;[2]
	NOP

	CLR		&TA0CTL					;[4]

	;TRANSMIT DELAY FOR TIMING
	MOV		#TX_TIMING_WRITE, R15 	;[1]

timing_delay_for_Write:
	DEC		R15						;[1] while((X--)>0);
	CMP		#0XFFFF,			R15	;[1] 'when X underflows'
	JNE		timing_delay_for_Write	;[2]

	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#rfidBuf, 	R12			;[2] load the &rfidBuf[0]
	MOV		#(4),		R13			;[1] load into corr reg (numBytes)
	MOV		#1,			R14			;[1] load numBits=1
	MOV.B	#TREXT_ON,	R15			;[3] load TRext (write always uses trext=1. wtf)

	CALLA	#TxFM0					;[5] call the routine
	;TxFM0(volatile uint8_t *data,uint8_t numBytes,uint8_t numBits,uint8_t TRext);
	;exit: state stays as Open!

	;/** @todo Should we do this now, or at the top of keepDoingRFID? */
	;MOV	&(INFO_ADDR_RXUCS0), &UCSCTL0;[] switch to corr Rx Frequency
	;MOV	&(INFO_ADDR_RXUCS1), &UCSCTL1;[] ""

	CALLA #RxClock	;Switch to RxClock

	;/** @todo When exactly should we enable/disable rx comparator? */
	;BIC.B	#PIN_RX_EN, &PRXEOUT	;[] disable the receive comparator now that we're done!

	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	CLR		&TA0CTL

	;Call user hook function if it's configured (if it's non-NULL)
	CMP.B		#(0), &(RWData.wrHook);[]
	JEQ			writeHandle_SkipHookCall ;[]
	MOV			&(RWData.wrHook), R_scratch0 ;[]
	CALLA		R_scratch0			;[]

writeHandle_SkipHookCall:

	;Modify Abort Flag if necessary (i.e. if in std_mode
	BIT.B		#(CMD_ID_WRITE), (rfid.abortOn);[] Should we abort on WRITE?
	JNZ			writeHandle_BreakOutofRFID	;[]
	RETA								;[] else return w/o setting flag

; If configured to abort on successful WRITE, set abort flag cause it just happened!
writeHandle_BreakOutofRFID:

	BIS.B		#1, (rfid.abortFlag);[] by setting this bit we'll abort correctly!
	RETA

writeHandle_Ignore:
	DINT							;[2]
	NOP
s
	CLR		&TA0CTL					;[4]
	POPM.A	#1,	R_scratch0			;[] Need to pop this off stack to avoid returning to address (RN16) !!
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1;[] ""

	CALLA #RxClock	;Switch to RxClock

	RETA


	.end
