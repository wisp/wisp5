;/************************************************************************************************************************************/
;/**
; * @file		TxFM0.asm
; * @brief		RFID Transmit in FM0
; * @details
; *
; * @author		Justin Reina, UW Sensor Systems Lab
; * @created
; * @last rev	
; *
; *	@notes
; *	@todo
; *	@calling	extern void TxFM0(volatile uint8_t *data,uint8_t numBytes,uint8_t numBits,uint8_t TRext)
; */
;/************************************************************************************************************************************/

;/INCLUDES----------------------------------------------------------------------------------------------------------------------------
    .cdecls C,LIST, "../globals.h"
    .cdecls C,LIST, "rfid.h"
    .include "../internals/NOPdefs.asm"; Definitions of NOPx MACROs...
    .global TxClock, RxClock

;/PRESERVED REGISTERS-----------------------------------------------------------------------------------------------------------------
R_currByte	.set  R6 
R_prevState .set  R7
R_scratch0  .set  R8        
R_scratch1  .set  R9
R_scratch2  .set  R10


;/SCRATCH REGISTERS-------------------------------------------------------------------------------------------------------------------
R_dataPtr	.set    R12				; Entry: address of dataBuf start is in R_dataPtr
R_byteCt    .set	R13				; Entry: length of Tx'd Bytes is in R_byteCt
R_bitCt 	.set	R14				; Entry: length of Tx'd Bits is in R_bitCt
R_TRext     .set  	R15				; Entry: TRext? is in R_TRext

;/Timing Notes------------------------------------------------------------------------------------------------------------------------
    ;*   Cycles Between Bits: 9 (for LF=640kHz @ 11.52MHz CPU)                                                                      */
    ;/** @todo Make sure the proper link frequency is listed here, or give a table of LF vs clock frequency							*/
    ;*   Cycles Before First Bit Toggle: 29 worst case                                                                              */

;/Begin ASM Code----------------------------------------------------------------------------------------------------------------------
	.def  TxFM0

TxFM0:
	BIS.W #BIT7, &PTXDIR;
	BIS.W #BIT7, &PTXOUT;
	BIC.W #BIT7, &PTXOUT;

    ;/Push the Preserved Registers----------------------------------------------------------------------------------------------------
	PUSHM.A #5, R10					;[?] Push all preserved registers onto stack R6-R10/** @todo Find out how long this takes */

	;PUSH    R_currByte				;[3] Note: Could optimize these two lines down into the preamble if necessary
	;PUSH    R_prevState				;[3] ""
	;PUSH    R_scratch0				;[3]
	;PUSH    R_scratch1				;[3] Note: Could optimize this line down into the pilot if necessary
	;PUSH    R_scratch2				;[3] "" <- this one would need a jump conditional and would be messy.

	CALLA #TxClock	;Switch to TxClock

	;MOV		&(INFO_ADDR_TXUCS0), &UCSCTL0;[] switch to corr Tx Frequency
	;MOV		&(INFO_ADDR_TXUCS1), &UCSCTL1;[] ""

			 
;/************************************************************************************************************************************
;/												CHECK WHICH VERSION TO SEND                    							             *
;/ operation: in order to meet the timing constraint of 10 cycles, we need to eliminate some overhead in transmitting the data (see  *
;/              'why:' below). Thus we split the transmission into three possible modes V0/V1/V2. We establish which mode to use for *
;/              transmit here and then use it.                                                                                       *
;/                                                                                                                                   *
;/ versions:    V0: (bytes>0)  && (bits>0)                                                                                           *
;/              V1: (bytes>0)  && (bits==0)                                                                                          *
;/              V2: (bytes==0) && (bits>0)                                                                                           *
;/              V3: (bytes==0) && (bits==0)  <- D.C. cause no one should ever call this. it is coded to go to V1 in this case.       *
;                                                                                                                                   *
;/ why:         notice that the jump to 'load_byte:' after sending b7 takes JNZ[2],MOV[2],INV[1],MOV[4] == 9 cycles. Note here for b0*
;/              we also optimized out a MOV but left it commented for clarity. Anyways this is 9 cycles, 1 less than our 10 cycle    *
;/              criteria. It would be nice to hit 9 cycles though; then we could drop our CPU speed.                                 *
;/                                                                                                                                   *
;/ entry timing: worst case this code burns 37 cycles before transmitting the first pilot tone bit of V1. At 12.57MHz this is 2.9us..*
;/               I hope this won't be an issue later!                                                                                *
;/                                                                                                                                   *
;/ future optim: one note here is that the pilot tones never really get called in FM0_640, so if that's the case then the cycles are *
;/               32. also not that two PUSH cycles could be optimized, and perhaps the test logic could too. let's hope we never have*
;/               to go there!                                                                                                        *
;/  opt note:    (temp until fixed) I load up scratch0/1 for transmitting tones to save cycles. but i don't need to save those cycles*
;/               and in fact it costs me entry and exit cycles because it requires a pop/push of R_scratch2. FIXME!!!                *
;/************************************************************************************************************************************
Test_For_Version0:
    TST.B   R_byteCt				;[1] Check for bytes
    JZ      Test_For_Version2		;[2] JMP if no bytes
    TST.B   R_bitCt					;[1] Check for bytes
    JZ      Test_For_Version2		;[2] JMP if no bits
    JMP     V0_Send_Pilot_Tones		;[2] if we got here then (bytes>0) && (bits>0). JMP to V0.

Test_For_Version2:    
    TST.B   R_byteCt				;[1] Check for bytes
    JNZ     Go_To_Version1			;[2] JMP if bytes
    TST.B   R_bitCt					;[1] Check For bits
    JZ      Go_To_Version1			;[2] JMP if no bits
    JMP     tramp_V2_Send_Pilot_Tones 	;[2] if we got here then (bytes==0) && (bits>0). JMP to V2
    
Go_To_Version1:                 ; Else just go to Version1
;*************************************************************************************************************************************
;                                                                                                                                    *
;  Version 1:       bytes>0 && bits==0         todo make NOPdefs.h NOPx4 something more optimized.                                   *
;                                                                                                                                    *
;  Optimizations:   For Each Byte sent, we need to do the following tasks:                                                           *
;                    - decrement byte count (R_byteCt)                                                                               *
;                    - test for more bytes                                                                                           *
;************************************************************************************************************************************/
V1_Send_Pilot_Tones:
    ;/Prep Some Registers to Send (optimized scratch0/2 down below though)------------------------------------------------------------
    MOV.B   #0xFF, R_scratch1		;[1] preloading our HIGH and LOW Tx bits to save us some cycles for pilot tones and preamble
    MOV.B   #12,   R_scratch2		;[2] load up numTones=12

    ;/Test to see if we should send pilot tones---------------------------------------------------------------------------------------
    TST.B   R_TRext					;[1] TRext means that we should send the pilot tones
    JZ      V1_Send_Preamble		;[2] skip 'em if (!TRext)

    ;/Send Pilot Tones if TRext-------------------------------------------------------------------------------------------------------
V1_Send_A_Pilot_Tone:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;*Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] setup R_scratch0 as LOW (note: if this is skipped, make sure to do it in preamble below too)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] LOW on PTXOUT.PIN_TX
    NOP								;[1] 1 timing cycles
    DEC     R_scratch2				;[1] decrement the tone count
    TST.B   R_scratch2				;[1] keep sending until the count is zero
    JNZ     V1_Send_A_Pilot_Tone	;[2] ""
    
;/************************************************************************************************************************************
;/													SEND PREAMBLE (UNROLLED)                       							         *
;/ operation: The preamble signals a tag transmission. It is unique as one data bit (the 5th, LL) doesn't follow FM0 modulation, so  *
;/              the reader can pick up the transmission for sure. other than that, not too much here.                                *
;/                                                                                                                                   *
;/ tx sequence: 000...[1/0/1/0/v/1] or encoded as -> [HH/LH/LL/HL/LL/HH]                                                             *
;/************************************************************************************************************************************    
V1_Send_Preamble:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;* Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] just in case the pilot tones were skipped (where scratch0 was loaded)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    MOV.B   #0xFF, R_prevState		;[1] load up prevStateLogic to HIGH (cause preamble left it that way)
    ;* Timing Optimization Shoved Here (1 Free Cycle)*/
    MOV     R_prevState, R_scratch0	;[1] load prevStateLogic into scratch0 for calc (optimized line for b0 of transmit below).
    ;* End of 1 free cycle */
    
;/************************************************************************************************************************************
;/													SEND A DATA BYTE (UNROLLED)                    							         *
;/ operation: first a data byte is loaded into currByte, then 8 bits are shifted out onto PIN_TX. one nice cycle saving thing here is*
;/              that the secondFM0bit is also prevStateLogic for the next bit. also, keep in mind that prevStateLogic is only in the *
;/              b0 spot, so careful with byte or word operations if you change the code.                                             *
;/************************************************************************************************************************************
V1_Load_Data:
    MOV.B     @R_dataPtr+, R_currByte ;[2] load current byte of data

V1_Send_a_Byte:
    ;/(b0)First Bit [FM0 Calculations are only commented for bit0]--------------------------------------------------------------------
    ;*optimizedOut:MOV     R_prevState, R_scratch0 ;[1] load prevStateLogic into scratch0 for calc*/;<-Now meets 9 cycles on JMP!
    INV     R_scratch0				;[1] firstFM0Bit = !prevLogicState (i.e. STATE0|STATE2 from EPC Spec Table)
    MOV.B   R_scratch0, &PTXOUT		;[4] push bit out on PTXOUT.PIN_TX
    XOR     R_currByte, R_prevState	;[1] secondFM0Bit = currDataBit^prevLogicState (STATE1|STATE2) from EPC Spec Table). This also
    NOPx4							;[4] 4 timing cycles
    MOV.B   R_prevState, &PTXOUT	;[4] push bit out on PTXOUT.PIN_TX                          //happens to be the new value of prevLogicState
    RLA     R_currByte				;[1] load next bit into hot seat                   //, which this line does too.
    NOPx2							;[2] 2 timing cycles
            
    ;/(b1)Second Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1] any lines beyond here that I don't comment are just standard FM0 calc&shoveOut lines
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b2)Third Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b3)Fourth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b4)Fifth Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b5)Sixth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b6)Seventh Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b7)Eighth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]

    XOR     R_currByte, R_prevState	;[1]
    ;*Timing Optimization Shoved Here (4 free cycles)*/
    DEC     R_byteCt				;[1] decrement the number of bytes sent
    TST.B   R_byteCt				;[1] test if there are bytes left to send
    MOV     R_prevState, R_scratch0	;[1] load prevStateLogic into scratch0 for calc (optimized line for b0 of next byte)
    NOP								;[1] 1 timing cycle
    ;*End of 4 free cycles*/
    MOV.B   R_prevState, &PTXOUT	;[4] *don't worry, MOV doesn't affect Z
    
    JNZ     V1_Load_Data			;[2] if (byteCt!=0) Continue Sending Bytes

    ;/Send the Last Bit (EoS Bit)-----------------------------------------------------------------------------------------------------
V1_Send_EoS_Byte:
    NOP								;[1] 1 timing cycles
    MOV     R_prevState, R_scratch0	;[1] calc last bit
    INV     R_scratch0				;[1] invert it
    MOV.B   R_scratch0, &PTXOUT		;[4] push it out on 2.0
    ;*Timing Optimization Shoved Here(14 free cycles). Note that the 14 cycles are used to enforce EoS bit timing (18cycles total)*/
    ;BIS.B   #PIN_RX_EN, &PRXEOUT	;[4] Leave with Port Low except for RX_EN.

	POPM.A #5, R10					;[?] Restore preserved registers R6-R10 /** @todo Find out how long this takes */

	;POP     R_scratch2				;[2] return the preserved registers
	;POP     R_scratch1				;[2] ""
	;POP     R_scratch0				;[2] ""
	;POP     R_prevState				;[2] ""
	;POP     R_currByte				;[2] ""


    BIC.B	#0x81, &PTXOUT			;[] Clear 2.0 & 2.7 (1.0 is for old 4.1 HW, 2.7 is for current hack...) eventually just 1.0
    ;* End of 16 free cycles. Also note we only put these here to save 3 friggin cycles which prolly won't make a darn difference...*/
    RETA

; trampoline to avoid a very long jump to V2_Send_Pilot_Tones
; XXX does this extra redirection take too long?
tramp_V2_Send_Pilot_Tones:
    JMP V2_Send_Pilot_Tones

;*************************************************************************************************************************************
;                                                                                                                                    *
;  Version 0:       bytes>0 && bits>0                                                                                                *      
;                                                                                                                                    *
;  Notes: This is the same as version 1 above, but it does a bits transmit loop too.                                                 *
;                                                                                                                                    *
;************************************************************************************************************************************/
V0_Send_Pilot_Tones:
    ;/Prep Some Registers to Send (optimized scratch0/2 down below though)------------------------------------------------------------
    MOV.B   #0xFF, R_scratch1		;[1] preloading our HIGH and LOW Tx bits to save us some cycles for pilot tones and preamble
    MOV.B   #12,   R_scratch2		;[1] load up numTones=12

    ;/Test to see if we should send pilot tones---------------------------------------------------------------------------------------
    TST.B   R_TRext					;[1] TRext means that we should send the pilot tones
    JZ      V0_Send_Preamble		;[2] skip 'em if (!TRext)


    ;/Send Pilot Tonies if TRext------------------------------------------------------------------------------------------------------
V0_Send_A_Pilot_Tone:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;*Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] setup R_scratch0 as LOW (note: if this is skipped, make sure to do it in preamble below too)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] LOW on PTXOUT.PIN_TX
    NOP								;[1] 1 timing cycles
    DEC     R_scratch2				;[1] decrement the tone count
    TST.B   R_scratch2				;[1] keep sending until the count is zero
    JNZ     V0_Send_A_Pilot_Tone	;[2] ""
    
;/************************************************************************************************************************************
;/													SEND PREAMBLE (UNROLLED)                       							         *
;/ operation: The preamble signals a tag transmission. It is unique as one data bit (the 5th, LL) doesn't follow FM0 modulation, so  *
;/              the reader can pick up the transmission for sure. other than that, not too much here.                                *
;/                                                                                                                                   *
;/ tx sequence: 000...[1/0/1/0/v/1] or encoded as -> [HH/LH/LL/HL/LL/HH]                                                             *
;/************************************************************************************************************************************    
V0_Send_Preamble:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;* Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] just in case the pilot tones were skipped (where scratch0 was loaded)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    MOV.B   #0xFF, R_prevState		;[1] load up prevStateLogic to HIGH (cause preamble left it that way)
    ;* Timing Optimization Shoved Here (1 Free Cycle)*/
    MOV     R_prevState, R_scratch0	;[1] load prevStateLogic into scratch0 for calc (optimized line for b0 of transmit below).
    ;* End of 1 free cycle */
    
;/************************************************************************************************************************************
;/													SEND A DATA BYTE (UNROLLED)                    							         *
;/ operation: first a data byte is loaded into currByte, then 8 bits are shifted out onto PIN_TX. one nice cycle saving thing here is*
;/              that the secondFM0bit is also prevStateLogic for the next bit. also, keep in mind that prevStateLogic is only in the *
;/              b0 spot, so careful with byte or word operations if you change the code.                                             *
;/************************************************************************************************************************************
V0_Load_Data:
    MOV.B     @R_dataPtr+, R_currByte ;[2] load current byte of data

V0_Send_a_Byte:
    ;/(b0)First Bit [FM0 Calculations are only commented for bit0]--------------------------------------------------------------------
    ;*optimizedOut:MOV     R_prevState, R_scratch0 ;[1] load prevStateLogic into scratch0 for calc*/;<-Now meets 9 cycles on JMP!
    INV     R_scratch0				;[1] firstFM0Bit = !prevLogicState (i.e. STATE0|STATE2 from EPC Spec Table)
    MOV.B   R_scratch0, &PTXOUT		;[4] push bit out on PTXOUT.PIN_TX
    XOR     R_currByte, R_prevState	;[1] secondFM0Bit = currDataBit^prevLogicState (STATE1|STATE2) from EPC Spec Table). This also
    NOPx4							;[4] 4 timing cycles
    MOV.B   R_prevState, &PTXOUT	;[4] push bit out on PTXOUT.PIN_TX		//happens to be the new value of prevLogicState
    RLA     R_currByte				;[1] load next bit into hot seat		//, which this line does too.
    NOPx2							;[2] 2 timing cycles
            
    ;/(b1)Second Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1] any lines beyond here that I don't comment are just standard FM0 calc&shoveOut lines
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b2)Third Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b3)Fourth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b4)Fifth Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b5)Sixth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]
            
    ;/(b6)Seventh Bit-------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    NOPx4							;[4]
    MOV.B   R_prevState, &PTXOUT	;[4]
    RLA     R_currByte				;[1]
    NOPx2							;[2]

    ;/(b7)Eighth Bit------------------------------------------------------------------------------------------------------------------
    MOV     R_prevState, R_scratch0	;[1]
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]

    XOR     R_currByte, R_prevState	;[1]
    ;*Timing Optimization Shoved Here (4 free cycles)*/
    DEC     R_byteCt				;[1] decrement the number of bytes sent
    TST.B   R_byteCt				;[1] test if there are bytes left to send
    MOV     R_prevState, R_scratch0	;[1] load prevStateLogic into scratch0 for calc (optimized line for b0 of next byte)
    NOP								;[1] 1 timing cycle
    ;*End of 4 free cycles*/
    MOV.B   R_prevState, &PTXOUT	;[4] *don't worry, MOV doesn't affect Z
    
    JNZ     V0_Load_Data			;[2] if (byteCt!=0) Continue Sending Bytes

;/************************************************************************************************************************************
;/													SEND LAST BITS                     							                     *
;/ operation: same procedure as looping on bytes. number of bits to Tx is in R_bitCt.                                                *
;/************************************************************************************************************************************
V0_Send_Last_Bits:
    MOV.B     @R_dataPtr+, R_currByte;[2] load current byte of data

V0_Send_A_Bit:
    ;*optimizedOut:MOV     R_prevState, R_scratch0 ;[1] <- Already there for us from above. optimized out*/
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    ;*Timing Optimization Shoved Here (4 free cycles)*/
    RLA     R_currByte				;[1] load in next bit
    DEC     R_bitCt					;[1] decrement the number of bits to send
    TST.B   R_bitCt					;[1] test if there are bytes left to send
    MOV     R_prevState, R_scratch0	;[1]
    ;*End of 4 free cycles*/        
    MOV.B   R_prevState, &PTXOUT	;[4]
    NOPx2							;[2] 2 timing cycles
    JNZ     V0_Send_A_Bit			;[2] if(bitCt!=0) Continue Sending Bytes

    ;/Send the Last Bit (EoS Bit)-----------------------------------------------------------------------------------------------------
V0_Send_EoS_Byte:
    NOP								;[1] 1 timing cycles
    MOV     R_prevState, R_scratch0	;[1] calc last bit
    INV     R_scratch0				;[1] invert it
    MOV.B   R_scratch0, &PTXOUT		;[4] push it out on 2.0
    ;*Timing Optimization Shoved Here(14 free cycles). Note that the 14 cycles are used to enforce EoS bit timing (18cycles total)*/
    ;BIS.B   #PIN_RX_EN, &PRXEOUT	;[4] Leave with Port Low except for RX_EN.

    POPM.A #5, R10					;[?] Restore preserved registers R6-R10 /** @todo Find out how long this takes */


	;POP     R_scratch2				;[2] return the preserved registers
	;POP     R_scratch1				;[2] ""
	;POP     R_scratch0				;[2] ""
	;POP     R_prevState				;[2] ""
	;POP     R_currByte				;[2] ""


    BIC.B	#0x81, &PTXOUT			;[] Clear 1.0 & 1.7 (1.0 is for old 4.1 HW, 1.7 is for current hack...) eventually just 1.0
    ;* End of 16 free cycles. Also note we only put these here to save 3 friggin cycles which prolly won't make a darn difference...*/
    RETA


;*************************************************************************************************************************************
;                                                                                                                                    *
;  Version 2:       bytes==0 && bits>0                                                                                               *
;                                                                                                                                    *
;  Notes: This is the same as version 0 above, but it omits the byte loop                                                            *
;                                                                                                                                    *
;************************************************************************************************************************************/
V2_Send_Pilot_Tones:
    ;/Prep Some Registers to Send (optimized scratch0/2 down below though)------------------------------------------------------------
    MOV.B   #0xFF, R_scratch1		;[1] preloading our HIGH and LOW Tx bits to save us some cycles for pilot tones and preamble
    MOV.B   #12,   R_scratch2		;[1] load up numTones=12

    ;/Test to see if we should send pilot tones---------------------------------------------------------------------------------------
    TST.B   R_TRext					;[1] TRext means that we should send the pilot tones
    JZ      V2_Send_Preamble		;[2] skip 'em if (!TRext)


    ;/Send Pilot Tonies if TRext------------------------------------------------------------------------------------------------------
V2_Send_A_Pilot_Tone:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;*Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] setup R_scratch0 as LOW (note: if this is skipped, make sure to do it in preamble below too)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] LOW on PTXOUT.PIN_TX
    NOP								;[1] 1 timing cycles
    DEC     R_scratch2				;[1] decrement the tone count
    TST.B   R_scratch2				;[1] keep sending until the count is zero
    JNZ     V2_Send_A_Pilot_Tone	;[2] ""
    
;/************************************************************************************************************************************
;/													SEND PREAMBLE (UNROLLED)                       							         *
;/ operation: The preamble signals a tag transmission. It is unique as one data bit (the 5th, LL) doesn't follow FM0 modulation, so  *
;/              the reader can pick up the transmission for sure. other than that, not too much here.                                *
;/                                                                                                                                   *
;/ tx sequence: 000...[1/0/1/0/v/1] or encoded as -> [HH/LH/LL/HL/LL/HH]                                                             *
;/************************************************************************************************************************************    
V2_Send_Preamble:
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    ;* Timing Optimization Shoved Here(5 free cycles)*/
    MOV.B   #0x00, R_scratch0		;[1] just in case the pilot tones were skipped (where scratch0 was loaded)
    NOPx4							;[4] 4 timing cycles
    ;*End of 5 free cycles*/
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*LL*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch0, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX       /*HH*/
    NOPx5							;[5] 5 timing cycles
    MOV.B   R_scratch1, &PTXOUT		;[4] HIGH on PTXOUT.PIN_TX
    MOV.B   #0xFF, R_prevState		;[1] load up prevStateLogic to HIGH (cause preamble left it that way)
    ;* Timing Optimization Shoved Here (1 Free Cycle)*/
    MOV     R_prevState, R_scratch0 ;[1] load prevStateLogic into scratch0 for calc (optimized line for b0 of transmit below).
    ;* End of 1 free cycle */
    
;/************************************************************************************************************************************
;/													SEND LAST BITS                     							                     *
;/ operation: same procedure as looping on bytes. number of bits to Tx is in R_bitCt.                                                *
;/************************************************************************************************************************************
V2_Send_Last_Bits:
    MOV.B     @R_dataPtr+, R_currByte;[2] load current byte of data

V2_Send_A_Bit:
    ;*optimizedOut:MOV     R_prevState, R_scratch0 ;[1] <- Already there for us from above. optimized out*/
    INV     R_scratch0				;[1]
    MOV.B   R_scratch0, &PTXOUT		;[4]
    XOR     R_currByte, R_prevState	;[1]
    ;*Timing Optimization Shoved Here (4 free cycles)*/
    RLA     R_currByte				;[1] load in next bit
    DEC     R_bitCt					;[1] decrement the number of bits to send
    TST.B   R_bitCt					;[1] test if there are bytes left to send
    MOV     R_prevState, R_scratch0	;[1]
    ;*End of 4 free cycles*/        
    MOV.B   R_prevState, &PTXOUT	;[4]
    NOPx2							;[2] 2 timing cycles
    JNZ     V2_Send_A_Bit			;[2] if(bitCt!=0) Continue Sending Bytes

    ;/Send the Last Bit (EoS Bit)-----------------------------------------------------------------------------------------------------
V2_Send_EoS_Byte:
    NOP								;[1] 1 timing cycles (note: instead of PIN_RX_EN line below(4cyc) we could just use this cycle to OR in Bit3 @ a reg (maybe 2 cyc though:( )
    MOV     R_prevState, R_scratch0	;[1] calc last bit
    INV     R_scratch0				;[1] invert it
    MOV.B   R_scratch0, &PTXOUT		;[4] push it out on 2.0
    ;*Timing Optimization Shoved Here(14 free cycles). Note that the 14 cycles are used to enforce EoS bit timing (18cycles total)*/
    ;BIS.B   #PIN_RX_EN, &PRXEOUT	;[4] Leave with Port Low except for RX_EN.

   	POPM.A #5, R10					;[?] Restore preserved registers R6-R10 /** @todo Find out how long this takes */


	;POP     R_scratch2				;[2] return the preserved registers
	;POP     R_scratch1				;[2] ""
	;POP     R_scratch0				;[2] ""
	;POP     R_prevState				;[2] ""
	;POP     R_currByte				;[2] ""


    BIC.B	#0x81, &PTXOUT			;[] Clear 1.0 & 1.7 (1.0 is for old 4.1 HW, 1.7 is for current hack...) eventually just 1.0
    ;* End of 16 free cycles. Also note we only put these here to save 3 friggin cycles which prolly won't make a darn difference...*/
    RETA
    
    .end ;* End of ASM */
    
    
    
    
  
