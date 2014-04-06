;************************************************************************************************************************************/
;/**@file		rfid_ReadHandle.asm
;*	@brief		Implements the EPC C1Gen2 READ command
;* 	@details
;*
;*	@author		Justin Reina, UW Sensor Systems Lab
;*	@created	6.8.11
;*	@last rev
;*
;*	@notes
;*
;*	@section
;*	@calling	void rfid_ReadHandle (void)
;*
;*/
;************************************************************************************************************************************/
;																																	 *
; 	Note:	Timing is super tight for full support of EPC Read. Estimates (un-optimized) place theoretical minimum at 75% of 	 	 *
;					before even considering error checking and details. Thus this gets moved to assembly.							 *	
;	Notes:		See below for detailed timing and procedure. Supports up to 16 word reads											 *
;																																	 *
;	Procedure:																														 *
;		[1/8]	Decode the Fields (memBank, wordPtr, wordCt)	(45 cycles)															 *
;		[2/8]	Load Read Bytes into the Buffer					(193 cycles)														 *
;		[3/8]	Decode WordCt									(19 cycles)															 *
;		[4/8]	Load RN16										(11 cycles)															 *
;		[5/8]	Calc/Load CRC16									(549* cycles)														 *
;		[6/8]	Shift all bytes, insert status bit.				(116 cycles)														 *
;		[7/8]	Check if the mem request was valid!!			(*0 cycles)															 *
;		[8/8]	Sync on end of rx_CRC16, then Transmit!			(73 cycles)															 *
;		TOTAL													(1006 cycles)														 *
;																																	 *
; Speed:		Requires X cycles for 16 words. Consider that until CRC16 is processed we only have ~40% CPU because of RX_SM		 *
;																																	 *
; Optimizations: Code automatically pushes for worst case in order to save cycles for worst case.									 *
;					- always loads 32 bytes into read buffer. this way it doesn't have to wait to parse wordCt! saves ~X cycles		 *
;																																	 *
; Remaining Cycle Analysis: 220 spare cycles to use (see derivation using entry/exit notes through routine).						 *
;																																	 *	
; WARNING:	As this routine executes concurrently with RX_SM, it is restricted access to R4,R5,R6,R7,R8,R9&R10!! sorry X(			 *
;				*I think we can eliminate R10 use from RX_SM though...																 *
;																																	 *
;************************************************************************************************************************************/

    .cdecls C,LIST, "../globals.h"

R_readPtr	.set  R13   			; ptr to which membank at which offset will be reading from
R_handle	.set  R12				; store inbound handle for Tx here.
   
   
R_scratch0	.set R15
R_scratch1  .set R14    

   	.ref cmd
	.def  handleRead
	.global RxClock, TxClock
	.sect ".text"
   
;	extern void handleRead (uint8_t handle);
handleRead:

;*************************************************************************************************************************************
;	[1/8]	Decode the Fields (memBank, wordPtr, wordCt) (45 cycles)                                                                 *
; 			Entry Timing: somewhere before first three bytes have come in. sync after first three bytes.							 *
;			Exit Timing:  18 cycles into the fourth Rx Byte.																		 *
;	/** @todo Show the read command bitfields here */																				 *
;************************************************************************************************************************************/
	;(put initAddrOfMemBank into R15 by combining memBank&wordPtr. Assume valid combo BECAUSE no combo of memBank/wordPtr/wordCt 
	;	accesses unique data!!)

	;Wait for Enough Bits to Come in(2+8+8) (first two bytes come in, then memBank is in cmd[1].b7b6)
waitOnBits_0:
	MOV.W	R5,	R15					;[1]
	CMP.W	#16, R15				;[3] while(bits<18)
	JLO		waitOnBits_0			;[2]
	
	;Put Proper memBankPtr into ReadPtr. Switch on Membank
switchOn_memBank:
	MOV.B	(cmd+1),R15				;[3] load cmd byte into R15. memBank is in b7b6 (0xC0)
	AND.B	#0xC0,	R15				;[2] mask of non-memBank bits, then switch on it to load corr memBankPtr
	CLRC							;[] b3 will now be a 0
	RLC.B	R15						;[] move  out b7 into C
	RLC.B	R15						;[] move  out b6 into C, C into b0
	RLC.B	R15						;[] move  out b5 into C, C into b0
	MOV.B	R15,	&(RWData.memBank) ;[] move out the memBank Val
	
	CMP.B	#0x00,	R15				;[1] memBank==0, Reserved memory bank
	JEQ		load_memBank_RESPtr		;[2]
	CMP.B	#0x01,	R15				;[1] memBank==1, EPC memory bank
	JEQ		load_memBank_UIIPtr		;[2]
	CMP.B	#0x02,	R15				;[1] memBank==2, Tag ID (TID) memory bank
	JEQ		load_memBank_TIDPtr		;[2]
	CMP.B	#0x03,	R15				;[1] memBank==3, User memory bank
	JEQ		load_memBank_USRPtr		;[2]
	
load_memBank_RESPtr:	
	MOV.W	#(RWData.RESBankPtr),	R_readPtr;[2] load the &memBank_RES[0] as the read pointer
	MOV		@R_readPtr, R_readPtr
	JMP		load_memBank_completed 	;[2]
load_memBank_UIIPtr:
	MOV.W	#(RWData.EPCBankPtr),	R_readPtr;[2] load the &memBank_UII[0] as the read pointer
	MOV		@R_readPtr, R_readPtr
	JMP		load_memBank_completed 	;[2]
load_memBank_TIDPtr:
	MOV.W	#(RWData.TIDBankPtr),	R_readPtr;[2] load the &memBank_TID[0] as the read pointer
	MOV		@R_readPtr, R_readPtr
	JMP		load_memBank_completed	;[2]
load_memBank_USRPtr:	
	MOV.W	#(RWData.USRBankPtr),	R_readPtr;[2] load the &memBank_USR[0] as the read pointer
	MOV		@R_readPtr, R_readPtr
	JMP		load_memBank_completed	;[2]
	
load_memBank_completed:	
	
	;Now wait for wordPtr to come in, and off R_readPtr by it. R15 is unused, R14 is held.
	;Wait for Enough Bits to Come in(2+8+8+8) (first three bytes come in, then wordPtr is in cmd[1].b5-b0 | cmd[2].b7b6
waitOnBits_1:
	MOV.W	R5,		R15				;[1]
	CMP.W	#24, 	R15				;[2] while(bits<26)
	JLO		waitOnBits_1			;[2]
	
offSetByWordPtr:
	MOV.B 	(cmd+1), R15			;[3] bring in top 6 bits into b5-b0 of R15 (wordCt.b7-b2)
	MOV.B 	(cmd+2), R14			;[3] bring in bot 2 bits into b7b6  of R14 (wordCt.b1-b0)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b1)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b1)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b0)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b0)
	MOV.B	R15, R15				;[1] mask wordPtr to just lower 8 bits
	RLA		R15						;[1] multiply by two (now is byte addr)
	ADD.W	R15, R_readPtr			;[1] calculate final memBank Pointer!! that took a lot of effort in assembly X(...
	
	MOV.W	R_readPtr,	&(RWData.wordPtr)

	;exit: R15 and R14 open for use. R12 restricted. memBankPtr is setup for transfer into rfidBuf. automatically

;*************************************************************************************************************************************
;	[2/8]	Load Read Bytes into the Buffer (193 cycles)				                                                             *
; 			Entry Timing: 40%*600cyc-18cyc --> 222 cycles remaining before end of Rx Byte 4      									 *
;			Exit Timing:  222 cycles-193cyc --> 29 cycles remaining before end of Rx Byte 4											 *
;************************************************************************************************************************************/
	MOV		#rfidBuf, 	R15			;[2] load up the initial rfidBuf Addr. then load 32 bytes!

	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 1
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 2
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 3
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 4
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 5
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 6
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 7
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 8
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 9
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 10
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 11
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 12
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 13
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 14
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 15
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 16
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 17
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 18
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 19
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 20
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 21
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 22
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 23
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 24
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 25
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 26
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 27
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 28
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 29
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 30
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 31
	INC		R15						;[1] increment readPtr
	MOV.B	@R_readPtr+, 0(R15) 	;[5] load byte 32

	;exit: R15 and R14 and R_readPtr(R13) open for use. R12 restricted. readBytes are in buffer.

;*************************************************************************************************************************************
;	[3/8]	Decode WordCt (19 cycles)																								 *
;			Entry Timing: 29 cycles remaining before end of Rx Byte 4											 					 *
;			Exit Timing:  40%*600cyc-13cyc --> 227 cycles remaining before end of Rx Byte 5											 *
;************************************************************************************************************************************/
	;Now wait for wordPtr to come in, and off R_readPtr by it. R15 is unused, R14 is held.
	;Wait for Enough Bits to Come in(2+8+8+8+8) (first four bytes come in, then wordPtr is in cmd[2].b5-b0 | cmd[3].b7b6
waitOnBits_2:
	MOV.W	R5,	R15					;[1]
	CMP.W	#32, R15				;[1] while(bits<34)
	JLO		waitOnBits_2			;[2]

	;Decode WordCt into R15
	MOV.B 	(cmd+2), R15			;[3] bring in top 6 bits into b5-b0 of R15 (wordCt.b7-b2)
	MOV.B 	(cmd+3), R14			;[3] bring in bot 2 bits into b7b6  of R14 (wordCt.b1-b0)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b1)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b1)
	RLC.B	R14						;[1] pull out b7 from R14 (wordCt.b0)
	RLC.B	R15						;[1] shove it into R15 at bottom (wordCt.b0)
	MOV.B	R15, R15				;[1] mask wordCt to just lower 8 bits
	PUSHM.A #1,	R15					;[2] keep wordCt for use in Tx

	;exit: R15 and R14 and R_readPtr(R13) open for use. R12 restricted. wordCt is stored in R15 and on 0(StackPtr)
;VALIDATING HANDLE GOES HERE U MOFO X(
	
;*************************************************************************************************************************************
;	[4/8]	Load RN16 (11 cycles)																									 *
;			Entry Timing: 227 cycles remaining before end of Rx Byte 5											 					 *
;			Exit Timing:  216 cycles remaining before end of Rx Byte 5
;************************************************************************************************************************************/
	;handle is in R12. It goes into rfidBuf[2*wordCt]
	RLA		R15						;[1] Multiply R15(wordCt) by 2 (because of bytes/words...)
	ADD		#rfidBuf, R15			;[1] Offset ptr into rfidBuf where RN16 goes (i.e. rfidBuf[2*wordCt]
	
	MOV		(rfid.handle),	R12		;[]
	MOV.B	R12, 1(R15)				;[4] store lower byte first of RN16
	SWPB	R12						;[1] move upper byte into lower byte
	MOV.B	R12, 0(R15)				;[4] store upper byte of RN16
	
	;exit: R15, R14, R12 and R_readPtr(R13) open for use. RN16 was loaded into the buffer. wordCt is still at 0(SP).

;*************************************************************************************************************************************
;	[5/8]	Calc/Load CRC16	(549 cycles)								                                                     		 *
;			Entry Timing: 216 cycles remaining before end of Rx Byte 5											 					 *
;			Exit Timing:  333 cycles into Rx Byte 6; or actually 147 cycles remaining before end of Rx Byte 7(LAST BYTE)			 *
;************************************************************************************************************************************/
	;uint16_t crc16_ccitt(uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
	MOV		#rfidBuf,		R13		;[2] load &rfidBuf[0] as dataPtr
	POPM.A	#1,	R15					;[2]
	MOV		R15,			R14		;[1] extract wordCt into R14, then push it back
	PUSHM.A	#1, R15					;[3]
	
	RLA		R14						;[1] mult wordCt*2
	ADD		#2,				R14		;[1] add 2 to wordCt cause of RN16 (now R14 is msg_size in bytes)
	MOV 	#ZERO_BIT_CRC, 	R12 	;[1] load preload to crc16_ccitt(give it the equivalent preload for just the '0' status bit)

	CALLA	#crc16_ccitt		;[5+524] 
	;onReturn: R12 holds the CRC16 value.
	
	;STORE CRC16(10?)
	MOV.B	R12,	1(R_readPtr)	;[4] store lower CRC byte first
	SWPB	R12						;[1] move upper byte into lower byte
	MOV.B	R12,	0(R_readPtr)	;[4] store upper CRC byte
	
;*************************************************************************************************************************************
;	[6/8]	Shift all bytes, insert status bit.	(116 cycles)			                                            				 *
;			Note:		  Recall we shift everything, considering worst-case timing (this is actually faster than doing a loop)	     *
;			Entry Timing: 147 cycles remaining before end of Rx Byte 7											 					 *
;			Exit Timing:  31  cycles remaining before end of Rx Byte 7											 					 *
;************************************************************************************************************************************/
	MOV		#rfidBuf, R15			;[2] set R15 to point to beginning of buff for shifting.
	CLRC							;[1] reset the clear bit for insertion as status bit
	RRC.B	@R15+					;[3] rotate rfidBuf[0] rotate Carry[n=0] into b7. shove b0 into Carry[n=1]
	RRC.B	@R15+					;[3] rotate rfidBuf[1] ...
	RRC.B	@R15+					;[3] rotate rfidBuf[2]
	RRC.B	@R15+					;[3] rotate rfidBuf[3]
	RRC.B	@R15+					;[3] rotate rfidBuf[4]
	RRC.B	@R15+					;[3] rotate rfidBuf[5]
	RRC.B	@R15+					;[3] rotate rfidBuf[6]
	RRC.B	@R15+					;[3] rotate rfidBuf[7]
	RRC.B	@R15+					;[3] rotate rfidBuf[8]
	RRC.B	@R15+					;[3] rotate rfidBuf[9]
	RRC.B	@R15+					;[3] rotate rfidBuf[10]
	RRC.B	@R15+					;[3] rotate rfidBuf[11]
	RRC.B	@R15+					;[3] rotate rfidBuf[12]
	RRC.B	@R15+					;[3] rotate rfidBuf[13]
	RRC.B	@R15+					;[3] rotate rfidBuf[14]
	RRC.B	@R15+					;[3] rotate rfidBuf[15]
	RRC.B	@R15+					;[3] rotate rfidBuf[16]
	RRC.B	@R15+					;[3] rotate rfidBuf[17]
	RRC.B	@R15+					;[3] rotate rfidBuf[18]
	RRC.B	@R15+					;[3] rotate rfidBuf[19]
	RRC.B	@R15+					;[3] rotate rfidBuf[20]
	RRC.B	@R15+					;[3] rotate rfidBuf[21]
	RRC.B	@R15+					;[3] rotate rfidBuf[22]
	RRC.B	@R15+					;[3] rotate rfidBuf[23]
	RRC.B	@R15+					;[3] rotate rfidBuf[24]
	RRC.B	@R15+					;[3] rotate rfidBuf[25]
	RRC.B	@R15+					;[3] rotate rfidBuf[26]
	RRC.B	@R15+					;[3] rotate rfidBuf[27]
	RRC.B	@R15+					;[3] rotate rfidBuf[28]
	RRC.B	@R15+					;[3] rotate rfidBuf[29]
	RRC.B	@R15+					;[3] rotate rfidBuf[30]
	RRC.B	@R15+					;[3] rotate rfidBuf[31]

	;Rotate the RN16 Field
	RRC.B	@R15+					;[3] rotate rfidBuf[32] b15-b9 of RN16 into rfidBuf[32].b6-b0
	RRC.B	@R15+					;[3] rotate rfidBuf[33] b8-b1  of RN16 into rfidBuf[33].b7-b0
	RRC.B	@R15+					;[3] rotate rfidBuf[34] b0     of RN16 into rfidBuf[34].b7

	;Rotate the CRC16 Field
	RRC.B	@R15+					;[3] rotate rfidBuf[35] b15-b9 of CRC16 into rfidBuf[32].b6-b0
	RRC.B	@R15+					;[3] rotate rfidBuf[36] b8-b1  of CRC16 into rfidBuf[33].b7-b0
	RRC.B	@R15+					;[3] rotate rfidBuf[37] b0     of CRC16 into rfidBuf[34].b7


;*************************************************************************************************************************************
;	[7/8]	Check if the mem request was valid!!    (0 cycles)																		 *
;************************************************************************************************************************************/
	;only come back and do this if we find we have extra cycles to spare...

;*************************************************************************************************************************************
;	[7a/8]	Check if handle matched.
;************************************************************************************************************************************/
waitOnBits_2a:
	MOV.W	R5,	R15					;[1]
	CMP.W	#48, R15				;[1] while(bits<48)
	JLO		waitOnBits_2a			;[2]

	MOV.B		(cmd+3),	R_scratch0
	SWPB		R_scratch0
	MOV.B		(cmd+4),	R_scratch1
	BIS.W		R_scratch1, R_scratch0 ;cmd[3] into MSByte,  cmd[4] into LSByte of Rs0
	MOV.B		(cmd+5),	R_scratch1

	;Shove bottom 2 bits from Rs1 INTO Rs0
	RLC.B		R_scratch1
	RLC			R_scratch0
	RLC.B		R_scratch1
	RLC			R_scratch0	
	
	;Check if Handle Matched
	CMP		R_scratch0, &rfid.handle
	JNE		readHandle_Ignore

;*************************************************************************************************************************************
;	[2/8]	Sync on end of rx_CRC16, then Transmit!	(73 cycles)			                                                             *
;			Entry Timing: 31 cycles remaining before end of Rx Byte 7											 					 *
;			Exit Timing:  31  cycles remaining before end of Rx Byte 7											 					 *
;			Spare Timing: 31 + 2lastBits*6.25us*12cyc/bit*40%RX_SM_loading = 91 before 16.125us T1 window begins					 *
;						  then, 16.125*12-64cycToPrepTxFM0 = 129 cycles in the T1 window for use									 *
;			Net Spare:	  91+129 = 220 cycles (10us)																				 *												
;************************************************************************************************************************************/
	;Wait for All Bits to Come in(2+8+2+8+8+16+16) all of it!
waitOnBits_3:
	MOV.W	R5,	R15					;[1]
	CMP.W	#58, R15				;[1] while(bits<60)
	JLO		waitOnBits_3			;[2]

		
haltRxSM_inReadHandle:

	DINT							;[2]
	NOP
	CLR		&TA0CTL					;[4]
		
	;TRANSMIT DELAY FOR TIMING
	MOV		#TX_TIMING_READ, R15 ;[1]

timing_delay_for_Read:
	DEC		R15						;[1] while((X--)>0);
	CMP		#0XFFFF,		R15		;[1] 'when X underflows'
	JNE		timing_delay_for_Read	;[2]	

	;TRANSMIT (16pre,38tillTxinTxFM0 -> 54cycles)
	MOV		#rfidBuf, 	R12			;[2] load the &rfidBuf[0]
	
	POPM.A	#1,	R15					;[2] recall value of wordCt from stack
	RLA		R15						;[1] byteCt=wordCt<<1
	ADD		#4,			R15			;[1] add extra 4 bytes for remainingPacket(RN16,CRC16)
	MOV		R15,		R13			;[1] load into corr reg (numBytes)
	MOV		#1,			R14			;[1] load numBits=1
	
	MOV.B	rfid.TRext,	R15			;[3] load TRext
	
	CALLA	#TxFM0					;[5] call the routine
	;TxFM0(volatile uint8_t *data,uint8_t numBytes,uint8_t numBits,uint8_t TRext);
	;exit: state stays as Open!

	;Done with the read!
readHandle_exit:

	;/** @todo Should we do this now, or at the top of keepDoingRFID? */
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

	CALLA #RxClock	;Switch to RxClock


	;Call user hook function if it's configured (if it's non-NULL)
	CMP.B		#(0), &(RWData.rdHook) ;[]
	JEQ			readHandle_SkipHookCall ;[]
	MOV			&(RWData.rdHook), R_scratch0 ;[]
	CALLA		R_scratch0			;[]

readHandle_SkipHookCall:

	;Modify Abort Flag if necessary (i.e. if in std_mode
	BIT.B		#(CMD_ID_READ),	(rfid.abortOn);[] Should we abort on READ?
	JNZ			readHandle_breakOutofRFID	;[]
	RETA								;[] else return w/o setting flag

; If configured to abort on successful READ, set abort flag cause it just happened!
readHandle_breakOutofRFID:

	BIS.B		#1, (rfid.abortFlag);[] by setting this bit we'll abort correctly!
	RETA

readHandle_Ignore:
	DINT							;[2]
	NOP

	CLR		&TA0CTL					;[4]
	POPM.A	#1,	R15					;[] clean off the top word
	;MOV		&(INFO_ADDR_RXUCS0), &UCSCTL0 ;[] switch to corr Rx Frequency
	;MOV		&(INFO_ADDR_RXUCS1), &UCSCTL1 ;[] ""

	CALLA #RxClock	;Switch to RxClock

	RETA	
	
	.end
