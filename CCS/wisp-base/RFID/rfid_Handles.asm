;/**@file		rfid_Handles.asm
;*	@brief		command handles for most of the EPC C1G2 protocol (Query/Ack/etc.)
;* 	@details	each routine is called after the corresponding command was parsed. Each handle is highly timing sensitive
;*
;*	@author		Justin Reina, UW Sensor Systems Lab
;*	@created	7-15-11
;*	@last rev	7-25-11
;*
;*	@notes		x
;*
;*	@section	Command Handles
;*				-#Query, QueryAdj, QueryRep, Ack, ReqRN
;*/

;/INCLUDES----------------------------------------------------------------------------------------------------------------------------
    .cdecls C,LIST, "../globals.h"
    .cdecls C,LIST, "rfid.h"
	.def  handleQuery, handleAck, handleQR, handleQA, handleReqRN, handleSelect
	.global TxClock, RxClock


;/PRESERVED REGISTERS-----------------------------------------------------------------------------------------------------------------
R_bits		.set	R5

R_scratch2	.set	R13
R_scratch1	.set	R14
R_scratch0	.set	R15

;//***********************************************************************************************************************************
; Handle QueryRep
; decrement slot counter if >0.
; if slot counter is 0, backscatter. that's it!
; all we backscatter is our RN16.
;//***********************************************************************************************************************************
handleQR:

	;Don't need to wait for bits, RX_SM already woke us up.
	BIC		#(GIE),	SR				;[] clear the GIE bit just as a safety. RX_SM already cleared it for us.
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #PIN_RX_EN, &PDIR_RX_EN   ;@us_change
	
	; @Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	CLR		&TA0CTL					;[] todo: maybe come back and remove this line.

	;Decrement the slotcounter if it is >1. this is a safety to prevent underflow.
	CMP		#(1),	&rfid.slotCount	;[]
	JL		QRTimeToBackscatter		;[]

QRJustDecrementAndLeave:
	;else just decrement and exit
	DEC		&(rfid.slotCount)		;[]
	RETA								;[]

;we found slot count as 0 or 1, so it's our turn!
QRTimeToBackscatter:

	MOV		#(0),	&(rfid.slotCount) ;[]as a safety leave slot count in predicted state. prolly don't need this, no one ever uses slot count afterwards anyways....

	;Delay is a bit tricky because of stupid Q. Q adds 8*Q cycles to the timing. So we need to subtract that (grr...)
	MOV		#TX_TIMING_QR,  R5		;[]

QRTimingLoop:
	NOP								;[1]
	DEC		R5						;[1] Info stored in N: N = (R5<0)
	JNZ		QRTimingLoop			;[2] Break out of loop on N

	;Load up function call, then transmit! bam!
	MOV		(rfid.handle), 	R_scratch0 ;[3] bring in the RN16
	SWPB	R_scratch0				;[1] swap bytes so we can shove full word out in one call (MSByte into dataBuf[0],...)
	MOV		R_scratch0, &(rfidBuf)	;[4] load the MSByte

	;Setup TxFM0
	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#(rfidBuf),	R12			;[2] load the &rfidBuf[0]
	MOV		#(2),		R13			;[1] load into corr reg (numBytes)
	MOV		#(0),		R14			;[1] load numBits=0
	MOV.B	rfid.TRext,	R15			;[3] load TRext
	CALLA	#TxFM0					;[5] call the routine @us@todo: need to check RN16 in the future, fake TxFM0 in TX

	;Restore faster Rx Clock
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

	CALLA #RxClock	;Switch to Rx Clock

	RETA



;/************************************************************************************************************************************/
;/** @fcn		void handleQuery (void)
; *  @brief		response to Query Command. Marks entry into an RFID inventory round.
; *  @details	reset inventory state, recalculate slotCount/handle, and maybe backscatter a response.
; *
; *  @section	Purpose
; *  	x
; *
; *  @param		[in]	name	descrip
; *
; *  @param		[out]	name	descrip
; *
; *  @return		(type) descrip
; *
; *  @pre		x
; *
; *  @post		x
; *
; *  @section	Operation
; *		-# Parse the TRext, Q fields
; *		-# Generate a new slotCount based on Q
; *		-# If slotCount is 0, then generate a newHandle, prep response, then backscatter
; *		-# Else just exit
; *
; *  @section	Ignores
; *  	-# The Query Command Fields DR, M (wisp assumes fixed at Tari=6.25us, LF=160kHz and Modulation=FM0)
; *		-# The Query Command Fields Sel, Session, Target (wisp uses a static, reduced subset of inventory params. ignore these fields.)
; *		-# The Query Command Field  CRC-5 (wisp just doesn't have enough time to process it).
; *
; *	@section	Command Format (22bits)
; * 	[CMD]	cmd[0].b7-b4
; * 	[DR]	cmd[0].b3
; * 	[M]		cmd[0].b2b1
; * 	[TRext] cmd[0].b0
; * 	[Sel]	cmd[1].b7b6
; * 	[Sess]	cmd[1].b5b4
; * 	[Targ]	cmd[1].b3
; * 	[Q]		cmd[1].b2-b0 | cmd[2].b7
; * 	[CRC-5] cmd[2].b6-b2	*assuming cmd[2] had shifted in all the way. last bit of CRC-5 will actually just be in b0.
; *
; *	@section	Response Format
; *		[RN16]	rfidBuf[0].b7-b0 | rfidBuf[1].b7-b0
; *
; * @section	Hazards & Risks
; *  	x
; *
; *	@section	Todo
; *		- Timing (T2) is dependent on Q value. compensate for this is the TX_TIMING_QUERY countdown (i.e. just offset it...)
; *
; *  @section	Timing
; *  	x
; *
; *  @section	Entry Register Permissions
; *		- Until RX_SM is halted, R4-R9 are restricted.
; */
;/***********************************************************************************************************************************/
handleQuery:
	;*********************************************************************************************************************************
	; STEP 1: Parse the Command
	;*********************************************************************************************************************************
	
	;Wait For Enough Bits-----------------------------------------------------------------------------------------------------------//
	CMP		#NUM_QUERY_BITS, R_bits	;[1] Is R_bits>=22? Info stored in C: ( C = (R_bits>=22) )

	;;;;;;;;;;;;Debug
	;BIS.B 	#PIN_LED2, &PDIR_LED2
	;XOR.B	#PIN_LED2, &PLED2OUT


	JLO		handleQuery				;[2] Loop until C pops up.

	;STEP2: Wakeup and Parse--------------------------------------------------------------------------------------------------------//
	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #PIN_RX_EN, &PDIR_RX_EN	  ;@us_change
	
	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN


	CLR		&TA0CTL

	;Parse TRext as cmd[0].b0
	MOV.B	(cmd),	R_scratch0		;[3] parse TRext
	AND.B	#0x01,	R_scratch0		;[1] it is cmd[0].b0
	MOV.B	R_scratch0, &(rfid.TRext);[4] push it out

	;Parse Q as cmd[1].b2-b0 | cmd[2].b7
	MOV.B	(cmd+1), R_scratch0		;[3] prep to parse Q (in cmd[1]/cmd[2])
	MOV.B	(cmd+2), R_scratch1		;[3]

	RRA		R_scratch1				;[1]
	RLC		R_scratch0				;[1]
	AND		#0x000F, R_scratch0		;[2]
	MOV.B	R_scratch0, &(rfid.Q)	;[4] store Q

	;Exit: Q and TRext have been parsed. no registers are held.

	;*********************************************************************************************************************************
	; STEP 2: Generate New Slot Count
	;	-Random Seed will be prev RN16 with simple operation on it
	;*********************************************************************************************************************************
	;Generate psuedo-random #---------------------------------------------------------------------------------------------------------
	;Grab a Random Value from Random Value Table in InfoB
	MOV.B	rfid.rn8_ind,	R_scratch0 ;[1] bring in rn8_ind
	INC		R_scratch0				;[1] rn8_ind++
	AND		#0x001F, 		R_scratch0 ;[1] modulo 32 on the ind
	MOV.B	R_scratch0, 	&rfid.rn8_ind ;[4] store new rn8_ind

	;Grab the RN8 (as a 16bit val) and use for RN16 and slotCount
	ADD		#INFO_WISP_RAND_TBL, R_scratch0 ;[] offset the index into the table
	MOV		@R_scratch0, 	R_scratch0 ;[] bring in random val (as int, grab some other byte too!)
	MOV		R_scratch0,		&rfid.handle ;[] store the handle (don't store slotCount just yet!)

	;Generate the Slot Count Mask into R_scratch2
	CLR		R_scratch2				;[1] load Rs2 with a empty mask
	MOV.B	(rfid.Q),  		R_scratch1 ;[] bring Q in too

	;Mask Slot Count to only contain (Q) bits (i.e. slotCount<2^Q)
keepShifting:
	CMP.B	#1,		R_scratch1		;[1] is Qctr>=1? Info stored in C: ( C = (R_s1>=1) )
	JNC		doneShifting			;[2] break when Qctr is 0.

	DEC		R_scratch1				;[1] Decrement the Qctr
	SETC							;[1] Load a C bit
	RLC		R_scratch2				;[1] insert the 1 bit into mask
	JMP		keepShifting			;[2] continue shifting

doneShifting:
	;now apply mask to slotCount (and also inc the RN16)
	AND		R_scratch2, R_scratch0	;[4] apply mask to slotCount (in Rs0)
	MOV		R_scratch0, &rfid.slotCount	;[] move it out!

	;is it our turn? (recall, slotCount is still in Rs0)
	CMP #(1), R_scratch0			;[2] is SlotCt>=1? Info stored in C: ( C = (SlotCt>=1) )
	JNC	rspWithQuery				;[2] respond with a query if !C

	RETA								;[5] not our turn; return from call

rspWithQuery:
	;Delay is a bit tricky because of stupid Q. Q adds 8*Q cycles to the timing. So we need to subtract that (grr...)
	MOV		#TX_TIMING_QUERY,  R5	;[]

queryTimingLoop:
	NOP								;[1]
	DEC		R5						;[1] Info stored in N: N = (R5<0)
	JNZ		queryTimingLoop			;[2] Break out of loop on N

	;Load up function call, then transmit! bam!
	MOV		(rfid.handle), 	R_scratch0 ;[3] bring in the RN16
	SWPB	R_scratch0				;[1] swap bytes so we can shove full word out in one call (MSByte into dataBuf[0],...)
	MOV		R_scratch0, 	&(rfidBuf) ;[4] load the MSByte

	;Setup TxFM0
	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#(rfidBuf),		R12		;[2] load the &rfidBuf[0]
	MOV		#(2),			R13		;[1] load into corr reg (numBytes)
	MOV		#(0),			R14		;[1] load numBits=0
	MOV.B	rfid.TRext,		R15		;[3] load TRext
	CALLA	#TxFM0					;[5] call the routine


	;Restore faster Rx Clock
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

;	MOV.B		#(0xA5), &CSCTL0_H;[] Switch to corr Rx frequency
;	MOV.W		#(DCOFSEL0|DCOFSEL1), &CSCTL1;
;	MOV.W		#(SELA_0|SELS_3|SELM_3), &CSCTL2;
;	MOV.W		#(DIVA_0|DIVS_0|DIVM_0), &CSCTL3;

	RETA											;[5]


;//***********************************************************************************************************************************
;	Handle Ack.
;	- Buffer is Already Prepped!
;	- Just Wait to Talk Back...
;	- Ignore DR,M,Sel,Session,Target,CRC5
;	- Generate a Slot Count, Update Handle, and Talk back if ready!
;//***********************************************************************************************************************************
handleAck:

ackWaits:
	;STEP1: Wait For Enough Bits----------------------------------------------------------------------------------------------------//
	CMP		#NUM_ACK_BITS, R_bits	;[1] Is R_bits>=18? Info stored in C: ( C = (R_bits>=18) )
	JNC		ackWaits				;[2] Loop until C pops up.


	;STEP2: Wakeup and Parse--------------------------------------------------------------------------------------------------------//
	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN ;@us_change

    ;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	CLR		&TA0CTL
    
	;Check RN16 @TODO note:check RN16 for read command or write?
	MOV.B 	(cmd),  		R_scratch0	 ;[] bring in cmd[0] to parse:01(ACK)+(00 00 00)RN16_MARK(b0-b5): MSB is b0
	SWPB    R_scratch0					 ;01(ACK)+RN16 b0-b2 +  0x00;
	MOV.B   (cmd+1),	  	R_scratch1   ;ACK+RN16 is b2-b17 in cm[0-3]; get RN16_b6-b13
	BIS     R_scratch1,	   	R_scratch0   ;get 01+RN16 b0-b13
	RLA     R_scratch0                   ;left shift 2 bits to get b14-b15,now it is b0-b13 + (0+0)
	RLA     R_scratch0

	MOV.B   (cmd+2),	   	R_scratch1   ;get b1b0 @us check: does cmd+2 save as b1b0+00000000 or 000000b1b0
	AND   	#0003,			R_scratch1
	ADD   	R_scratch1,		R_scratch0
	CMP   	(rfid.handle),  R_scratch0
	JNE     ackSkipHookCall
	;;;;;;;;;;;;;;
	;keepDoingHandleACK if it is passed RN16	check
keepDoHandleACK:	
	;Delay for 10us(28.5cycles) so we can hit the 57.0us mark (remember, we're at 2.85MHz now)
	MOV		#TX_TIMING_ACK, R5		;[2]

ackTimingLoop:
	NOP								;[1]
	NOP								;[1]
	DEC		R5						;[1] Info stored in N: N = (R5<0)
	JNZ		ackTimingLoop			;[2] Break out of loop on N

	;Setup TxFM0
	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#dataBuf,	R12			;[2] load the &dataBuf[0]
	MOV		#(16),		R13			;[1] load into corr reg (numBytes)
	MOV		#(0),		R14			;[1] load numBits=0
	MOV.B	rfid.TRext,	R15			;[3] load TRext

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;NO HIT

	CALLA	#TxFM0					;[5] call transmit routine

	;Restore faster Rx Clock
	;/** @todo Should we do this now, or at the top of keepDoingRFID? */
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

	CALLA #RxClock	;Switch to RxClock

	;Call user hook function if it's configured (if it's non-NULL)
	CMP.B		#(0), &(RWData.akHook);[]
	JEQ			ackSkipHookCall		;[]
	MOV			&(RWData.akHook), R_scratch0 ;[]

	CALLA		R_scratch0			;[] Can mangle R12-R15

ackSkipHookCall:
	
	;Modify Abort Flag if necessary (i.e. if in std_mode
	BIT.B		#(CMD_ID_ACK),	(rfid.abortOn);[] Should we abort on ACK?
	JNZ			ackBreakOutofRFID	;[]
	RETA							;[] else return w/o setting flag
	
; If configured to abort on successful ACK, set abort flag cause it just happened!
ackBreakOutofRFID:

	BIS.B		#1, (rfid.abortFlag);[] by setting this bit we'll abort correctly!
	RETA

;//***********************************************************************************************************************************
; Handle QueryAdjust
; - Parse UpDn
; - Act of Q
; - Pick a new slot count
; - if 0, backscatter
;//***********************************************************************************************************************************
handleQA:
	;Wait for enough bits to parse Q (8) only need first two bits to uniquely identify Q.
	BIC		#(GIE),	SR
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN ;@us_change
	
	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	CLR		&TA0CTL

	;Parse UpDn
	MOV		(cmd),	R_scratch0		;[] bring in UpDn
	AND		#0x03,	R_scratch0		;[] mask off all bits except for UpDn in b1b0

	CMP		#0x03,	R_scratch0		;[]
	JEQ		incrementQ
	CMP		#0x01,	R_scratch0		;[]
	JEQ		decrementQ
	RETA

incrementQ:
	INC.B	&(rfid.Q)				;[] increment Q
	JMP		QALoadNewSlot

decrementQ:
	MOV.B	&(rfid.Q), R_scratch0	;[] bring in Q for operation
	DEC		R_scratch0				;[]
	CMP.B	#0xFF, R_scratch0		;[]
	JEQ		QALoadNewSlot			;[] if Q was 0 on entry we decremented and underflowed.
									;	EPC spec says in this case set Q=0, which it already is, so leave it alone.
	MOV.B	R_scratch0, &(rfid.Q)	;[] else move new Q value out

QALoadNewSlot:
	;Grab a Random Value from Random Value Table in InfoB
	MOV.B	rfid.rn8_ind,	R_scratch0 ;[1] bring in rn8_ind
	INC		R_scratch0				;[1] rn8_ind++
	AND		#0x001F, R_scratch0		;[1] modulo 32 on the ind
	MOV.B	R_scratch0, 	&rfid.rn8_ind ;[4] store new rn8_ind

	;Grab the RN8 (as a 16bit val) and use for RN16 and slotCount
	ADD		#INFO_WISP_RAND_TBL,	R_scratch0 ;[] offset the index into the table
	MOV		@R_scratch0, 	R_scratch0 ;[] bring in random val (as int, grab some other byte too!)

	CLR		R_scratch2				;[1] load Rs0 with a empty mask
	MOV.B	(rfid.Q),		  R_scratch1 ;[3] bring Q in too

	;Mask Slot Count to only contain (Q) bits (i.e. slotCount<2^Q)
QAkeepShifting:
	CMP.B	#1,		R_scratch1		;[1] is Qctr>=1? Info stored in C: ( C = (R_s1>=1) )
	JNC		QAdoneShifting			;[2] break when Qctr is 0.

	DEC		R_scratch1				;[1] Decrement the Qctr
	SETC							;[1] Load a C bit
	RLC		R_scratch2				;[1] insert the 1 bit into mask
	JMP		QAkeepShifting			;[2] continue shifting

QAdoneShifting:
	;now apply mask to slotCount (and also inc the RN16)
	AND		R_scratch2,	R_scratch0
	MOV		R_scratch0, &rfid.slotCount 
	
	;is it our turn?
	CMP #(1), R_scratch0			;[2] is SlotCt>=1? Info stored in C: ( C = (SlotCt>=1) )
	JNC		rspWithQueryAdj			;[2] respond with a query if !C
	RETA								;[5] not our turn; return from call

rspWithQueryAdj:
	;Delay is a bit tricky because of stupid Q. Q adds 8*Q cycles to the timing. So we need to subtract that (grr...)
	MOV		#TX_TIMING_QA,  R5		;[]

QATimingLoop:
	NOP								;[1]
	DEC		R5						;[1] Info stored in N: N = (R5<0)
	JNZ		QATimingLoop			;[2] Break out of loop on N

	;Load up function call, then transmit! bam!
	MOV		(rfid.handle), 	R_scratch0 ;[3] bring in the RN16
	SWPB	R_scratch0				;[1] swap bytes so we can shove full word out in one call (MSByte into dataBuf[0],...)
	MOV		R_scratch0, &(rfidBuf)	;[4] load the MSByte

	;Setup TxFM0
	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#(rfidBuf),	R12			;[2] load the &rfidBuf[0]
	MOV		#(2),		R13			;[1] load into corr reg (numBytes)
	MOV		#(0),		R14			;[1] load numBits=0
	MOV.B	rfid.TRext,	R15			;[3] load TRext
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;NO HIT
	CALLA	#TxFM0					;[5] call the routine

	;Restore faster Rx Clock
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

;	MOV.B		#(0xA5), &CSCTL0_H;[] Switch to corr Rx frequency
;	MOV.W		#(DCOFSEL0|DCOFSEL1), &CSCTL1;
;	MOV.W		#(SELA_0|SELS_3|SELM_3), &CSCTL2;
;	MOV.W		#(DIVA_0|DIVS_0|DIVM_0), &CSCTL3;

	RETA


;*************************************************************************************************************************************
; REQ RN HANDLE
;*************************************************************************************************************************************
handleReqRN:
	;STEP1: Wait For Enough Bits to proc RN16 (i.e. first three bytes)---------------------------------------------------------------//
	CMP		#24, R_bits			;[1] Is R_bits>=24? Info stored in C: ( C = (R_bits>=18) )
	JNC		handleReqRN			;[2] Loop until C pops up.

	;Because cmd[1] isn't word aligned we have to bring it in one byte at a time.
	MOV.B	(cmd+1), 	   R_scratch1
	SWPB	R_scratch1
	MOV.B	(cmd+2), 	   R_scratch0 ;[]now the rxHandle is loaded
	BIS		R_scratch0,	   R_scratch1 ;[]
	CMP		(rfid.handle), R_scratch1 ;[]
	JNE		reqRN_badHandle			;[]

	;Generate a new handle! (Grab a Random Value from Random Value Table in InfoB)
	MOV.B	rfid.rn8_ind,	R_scratch0 ;[1] bring in rn8_ind
	INC		R_scratch0				;[1] rn8_ind++ (why?? This doesn't appear to change behavior)
	AND		#0x001F, R_scratch0		;[1] modulo 32 on the ind
	MOV.B	R_scratch0, 	&rfid.rn8_ind ;[4] store new rn8_ind

	;Grab the RN8 (as a 16bit val) and use for RN16 and slotCount
	ADD		#INFO_WISP_RAND_TBL,	R_scratch0 ;[] offset the index into the table
	MOV		@R_scratch0,	R_scratch0
	MOV		R_scratch0,		&rfid.handle ;[] store the new handle!

	;Load up function call, then transmit! bam! (entry: handle is already in R_scratch0)
	SWPB	R_scratch0				;[1] swap bytes so we can shove full word out in one call (MSByte into dataBuf[0],...)
	MOV		R_scratch0, &(rfidBuf)	;[4] load the MSByte

	;Calc CRC16! (careful, it will clobber R11-R15)
	;uint16_t crc16_ccitt(uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
	MOV		#(rfidBuf),		R13		;[2] load &dataBuf[0] as dataPtr
	MOV		#(2),			R14		;[2] load num of bytes in ACK

	MOV 	#CRC_NO_PRELOAD, R12 	;[1] don't use a preload!

	CALLA	#crc16_ccitt			;[5+196]
	;onReturn: R12 holds the CRC16 value.

	;STORE CRC16
	MOV.B	R12,	&(rfidBuf+3)	;[4] store lower CRC byte first
	SWPB	R12						;[1] move upper byte into lower byte
	MOV.B	R12,	&(rfidBuf+2)	;[4] store upper CRC byte

reqRN_delay:
	;STEP1: Wait For Enough Bits to proc RN16 (i.e. first three bytes)---------------------------------------------------------------//
	CMP		#NUM_REQRN_BITS, R_bits	;[1] Is R_bits>=40? Info stored in C: ( C = (R_bits>=40) )
	JNC		reqRN_delay				;[2] Loop until C pops up.
	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN ;@us_change

	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	BIC.B	#PIN_RX,	&PDIR_RX
	
	CLR		&TA0CTL

rspWithReqRN:
	;timing loop till transmit
	MOV		#TX_TIMING_REQRN,  R5	;[]

REQRNTimingLoop:
	NOP								;[1]
	DEC		R5						;[1] Info stored in N: N = (R5<0)
	JNZ		REQRNTimingLoop			;[2] Break out of loop on N

	;Setup TxFM0
	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#(rfidBuf),	R12			;[2] load the &rfidBuf[0]
	MOV		#(4),		R13			;[1] load into corr reg (numBytes)
	MOV		#(0),		R14			;[1] load numBits=0
	MOV.B	rfid.TRext,	R15			;[3] load TRext
;;;;;;;;;;;;;;;;;;;;;;; NO HIT
	CALLA	#TxFM0					;[5] call the routine

	;Restore faster Rx Clock
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

;	MOV.B		#(0xA5), &CSCTL0_H;[] Switch to corr Rx frequency
;	MOV.W		#(DCOFSEL0|DCOFSEL1), &CSCTL1;
;	MOV.W		#(SELA_0|SELS_3|SELM_3), &CSCTL2;
;	MOV.W		#(DIVA_0|DIVS_0|DIVM_0), &CSCTL3;

	RETA


reqRN_badHandle:
	;BIC.B	#(PIN_RX_EN), &PRXEOUT	;[] disable the receive comparator now that we're done!
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN	;@us_change

	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN
	
	BIC.B	#PIN_RX,	&PDIR_RX
	
	INC.B	&(rfid.abortFlag)
	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	RETA


;*************************************************************************************************************************************
; SELECT HANDLE
; -Wisp only supports select for purposes of preselection for read or write under the following scenario:
;
; -If you want to support other configs, hack, hack away!
; Command = cmd[0].b7-b4
; Target  = cmd[0].b3-b1
; Action  = cmd[0].b0 | cmd[1].b7b6
; MemBank = cmd[1].b5b4
; BitPtr  = cmd[1].b3-b0 | cmd[2].b7-b4
; Length  = cmd[2].b3-b0 | cmd[3].b7-b4
; Mask    = cmd[3].b3-b0 | cmd[4] | cmd[5].b7-b4
; Trunc   = DNC
; CRC	  = DNC
;
; -Selection Process
; -Goal: Have reader unambiguously talk to one tag at a time.
; -Solution: Reader uses an inventory filter for the last 16bits of the EPC value (i.e. dataBuf[12] | dataBuf[13]) when it wants to
;		singulate a unique tag. Individual WISPs can choose to support or not support this selection feature by asserting the
;		MODE_USES_SEL bit in the rfid.mode field. In Select handle, tag handles select if MODE_USES_SEL, else it ignores the command.
;
; -#Wait for all bits to come in
; -#BitPtr has to equal 0x0020
; -#BitLength should equal 0x0010
;
;
;*************************************************************************************************************************************
handleSelect:
	;*********************************************************************************************************************************
	; STEP 0: Decide if we Handle Select
	;	- if we do, wait for all bits to come in
	;*********************************************************************************************************************************
	BIT.B	#MODE_USES_SEL,	&(rfid.mode) ;[] should we even respond to command? (C = bit is set)
	JNC		dontHandleSelect		;[] ""

	CMP		#NUM_SEL_BITS, R_bits	;[1] Is R_bits>=44? Info stored in C: ( C = (R_bits>=44) )
	JNC		handleSelect			;[2] Loop until C pops up.

	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT	  ;@us_change
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN ;@us_change

	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	BIC.B	#PIN_RX,	&PDIR_RX
	
	CLR		&TA0CTL					;[] disable the timer

	;*********************************************************************************************************************************
	; STEP 1: Parse the Command
	;*********************************************************************************************************************************
	;Check if BitPtr is correct for the mask filter (else just ignore command)
	;recall: ; BitPtr  = cmd[1].b3-b0 | cmd[2].b7-b4
	MOV.B	(cmd+1),	R_scratch0	;[] scratch0 = (cmd[2] | cmd[1])
	MOV.B	(cmd+2),	R_scratch1	;[]
	SWPB	R_scratch1				;[] now cmd[2] is in upper byte
	BIS.W	R_scratch1,	R_scratch0	;[] now cmd[1] is in lower byte
	AND		#0xF00F,	R_scratch0
	CMP.B	#0x0002,	R_scratch0	;[] check if correct bitPtr (this is equivalent to BitPtr=0x0010 but jumbled around)
	JNZ		dontHandleSelect

	;Parse Mask as cmd[3].b3-b0 | cmd[4].b7-4
	MOV.B	(cmd+3),	R_scratch0	;[] bring in bits b15-b12 into lower 4 bits of REG (REG.b3-b0)
	SWPB	R_scratch0				;[] bring b15-b12 up to REG.b11-b8.
	AND		#0x0F00,	R_scratch0	;[] clear out all bits except REG.b11-b8. in prep for upcoming OR instr.

	MOV.B	(cmd+4),	R_scratch1	;[] bring in bits b11-b4 into REG.b7-b0. after shifting these will slide up to REG.b11-b4
	BIS.W	R_scratch1,	R_scratch0	;[] or them in. don't worry, scratch1.b15-b8 are zeros.

	MOV.B	(cmd+5),	R_scratch1	;[] bring in bits b3-b0 into upper 4 bits of REG
	RLC.B	R_scratch1				;[] bring over b3
	RLC		R_scratch0				;[]	""
	RLC.B	R_scratch1				;[] bring over b2
	RLC		R_scratch0				;[]	""
	RLC.B	R_scratch1				;[] bring over b1
	RLC		R_scratch0				;[]	""
	RLC.B	R_scratch1				;[] bring over b0
	RLC		R_scratch0				;[]	""


	;Exit: Mask is in R_scratch0

	;*********************************************************************************************************************************
	; STEP 2: Act on the Command
	;	-when we bring in a word from a byte array, later index gets put into higher byte.
	;	-e.g. (dataBuf+12) loads R_scratch0 = (cmd[13] | cmd[12])
	;	-so when comparing mask to lower EPC bits, one of them has to be SWPB first. Lowest cycle count would be to SWPB on R_scratch0
	;*********************************************************************************************************************************
	;Does the Mask Match Lower EPC Bits?
	CLR		R_scratch1				;[] prep scratch1 for the comparison result
	SWPB	R_scratch0				;[] prep Mask for comparison to lower EPC Bits

	CMP		(dataBuf+2),	R_scratch0 ;[] do they match? (Z = matches)
	JNZ		skipAssertingFlag
	MOV		#TRUE,			R_scratch1 ;[] else assert the flag
skipAssertingFlag:
	MOV.B	R_scratch1, &(rfid.isSelected) ;[] move out the selection result
	RETA

dontHandleSelect:
	BIC		#(GIE), SR				;[1] don't need anymore bits, so turn off Rx_SM
	NOP
	;BIC.B   #(PIN_RX_EN), &PRXEOUT    ;@us_change
	;BIC.B   #(PIN_RX_EN), &PDIR_RX_EN ;@us_change

	;@Saman
	;BIS.B   #PIN_NRX_EN, &PNRXEOUT    ;@us_change
	;BIC.B   #PIN_NRX_EN, &PDIR_NRX_EN

	;BIC.B	#PIN_RX,	&PDIR_RX

	CLR		&TA0CTL					;[]  disable the timer
	MOV.B	#1,	&(rfid.isSelected)	;[]  if we're not in MODE_USES_SEL, then leave isSelected true so it handles other commands.
	RETA

	.end
