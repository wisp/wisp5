;Taken from SLAA221 app note on look up table methods.
	;C callable assembly, file: _crc_algs.s43
	;arg1 > [R13:]R12, arg2 > [R15:]R14, others stack
	;result > [R13:]R12

	;R0:R2, 	system registers
	;R3 		constant generator
	;R4:R5, 	reserved for ROM monitor mode, else GP
	;R6:R11, 	6 general purpose registers 
	;R12:R15, 	reserved for passing args
;/INCLUDES----------------------------------------------------------------------------------------------------------------------------
    .cdecls C,LIST, "../globals.h"


	.def 	crc16_ccitt, crc16Bits_ccitt
	.ref	crc16_LUT
	

r_index		.set	R11				;[] the register used to first hold &VAL, then VAL. (see PDRD descr)
r_crc		.set	R12				;[] working register where the CRC is stored.
r_dataPtr	.set	R13				;[] address of the data to calculate CRC on
r_numBytes  .set	R14				;[] num of bytes to calculate the CRC on
r_numBits	.set	R15				;[] num of bits to calculate CRC on


;*************************************************************************************************************************************
;				unsigned int crc16_ccitt(unsigned short preload,unsigned char *dataPtr, unsigned int numBytes)						 *
; TODO: List Steps Here:																											 *
; Assumption: numBits > 0 																											 *
;*************************************************************************************************************************************
crc16_ccitt:                            ;[11] (2+2+2+5)entry into function and setup with vals
    INV     r_crc                       ;[2] #1. bring CRC preload into working form (inverted) before operation
    MOV     r_crc,      &CRCINIRES      ;[1] #2. move CRC preload to correct register

crc16_a_byte:
    MOV.B	@r_dataPtr+,&CRCDIRB_L      ;[1] #3. add item to CRC checksum

    DEC     r_numBytes                  ;[1] #4. continue calculating bytes until all are proc'd
    JNZ     crc16_a_byte                ;[2] ""

crc16_a_exit:
    MOV     &CRCINIRES, r_crc           ;[1] #5. move result back from register
    INV     r_crc                       ;[2] #6. restore CRC to working form (invert it)

    ;r_crc is in proper return register on exit.
    RETA                                ;[8] 4 for return, 4 for moving data out to RAM (from R12)


;*************************************************************************************************************************************
;			unsigned int crc16Bits_ccitt(unsigned short preload,unsigned char *dataPtr, unsigned int numBytes,unsigned int numBits)  *
; TODO: List Steps Here:																											 *
; ASSUMPTION: numBytes & numBits >0																									 *
;*************************************************************************************************************************************
crc16Bits_ccitt:
	INV		r_crc						;[2] #1. bring CRC preload into working form (inverted) before operation

crc16Bits_a_byte:
    SWPB    r_crc						;[1] #4, swap" CRC[i] = (CRClsb[i-1] | CRCmsb[i-1] )
    MOV.B   r_crc,		r_index			;[1] #2. start out      VAL[i]  = (0x00|CRCmsb[i-1]) 
    XOR.B   @r_dataPtr+,r_index			;[2] #2. bring data in  VAL[i] ^= (0x00|data[i++]) 
    ADD     r_index,	r_index			;[1] #2. mult by 2      VAL[i]  = 2*VAL[i]
    ADD		#crc16_LUT,	r_index			;[2] #2. offst ptr,     VAL[i] += &crc16_LUT
    AND     #0xFF00,	r_crc			;[2] #2. mask bottByte, CRC[i] &= 0xFF00
    XOR     @r_index,	r_crc			;[2] #3/5. XOR tableVal,  CRC[i] ^= *VAL[i] 
	
	DEC		r_numBytes					;[1] #6. continue calculating bytes until all are proc'd
	JNZ		crc16Bits_a_byte			;[2] ""

	;Load the last byte in prep to shift bits!
	MOV.B	@r_dataPtr,	r_index			;[2] load the last message byte, which is where bits get grabbed from (MSB side)
	
crc16Bits_Bits:
	CLR		r_dataPtr					;[1] use dataPtr as the register to store the inbound dataBit into (b15)
	RLC.B	r_index						;[1] shift out b7 of data
	RRC		r_dataPtr					;[1] shift it into b15 or workingRef
	XOR		r_dataPtr,	r_crc			;[1] XOR in that dataBit into the CRC
	RLA		r_crc						;[1] Shift CRC left
	
	JNC		crc16Bits_skipXOR			;[2] if bit shifted out was set, XOR in the poly
	XOR		#CCITT_POLY,	r_crc		;[2] b15 was set, so XOR in CRC16-CCITT poly 

crc16Bits_skipXOR:
	DEC		r_numBits					;[1] continue until all bits are proc'd
	JNZ		crc16Bits_Bits				;[2] ""

crc16Bits_a_exit:	
	INV		r_crc						;[2] #7. restore CRC to working form (invert it)

	;r_crc is in proper return register on exit. 
	RETA									;[8] 4 for return, 4 for moving data out to RAM (from R12)










.end
