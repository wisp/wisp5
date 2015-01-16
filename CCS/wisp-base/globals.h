/** @file       globals.h
 *  @brief      Global definitions, typedefs, variables
 *  @details
 *
 *  @author     Justin Reina, UW Sensor Systems Lab
 *  @created    4.14.12
 *  @last rev
 *
 *  @notes
 */

#ifndef GLOBALS_H_
#define GLOBALS_H_

#include <msp430.h>
#include "config/pin-assign.h"     /* low level pinDefs, IDs, etc. */

/* Global constants */
#define FOREVER         (1)
#define NEVER           (0)

#define TRUE            (1)
#define FALSE           (0)

#define HIGH            (1)
#define LOW             (0)

#define FAIL            (0)
#define SUCCESS         (1)

/** @todo write the comments for 4 below so I can actually read them... */
#define CMDBUFF_SIZE    (30)                                            /* ? */
#define DATABUFF_SIZE   (2+12+2)                                        /* first2/last2 are reserved. put data into B2..B13     */
                                                                        /*      format: [storedPC|EPC|CRC16]                    */
#define RFIDBUFF_SIZE   (1+16+2+2+50)                                   /* longest command handled is the read command for 8 wds*/

#define USRBANK_SIZE    (32)                                            /* ? */

#define RFID_SEED       (0x1234)    //change this to change the RN16 selection behavior. if using multiple tags make sure to put a
                                    //different value on each one!! /** @todo: maybe have this generated in INFO Mems during cal*/

#define CMD_PARSE_AS_QUERY_REP          (0x00)                          /** @todo   describe these myst vals!                   */
#define CMD_PARSE_AS_OVF                (0xFF)
#define ENOUGH_BITS_TO_FORCE_EXECUTION  (200)

#define RESET_BITS_VAL  (-1)        /* this is the value which will reset the TA1_SM if found in 'bits (R5)' by rfid_sm         */

//RFID TIMING DEFS                      /*4.08MHz                                                                                   */
/** @todo map these better based on full range of valid vals!                                                                   */
//Impinj Uses RTCal = 31.4us = 2.5*TARI (min possible.   RTCal goes between 2.5-3.0 TARI Per Spec)
#define RTCAL_MIN       (85)
#define RTCAL_NOM       (100)       /* (really only saw spread from 102 at high power to 96 at low power)                       */
#define RTCAL_MAX       (150)       /*(this accounts for readers who use up to 3TARI, plus a little wiggle room)                */
#define RTCAL_OFFS      (12)        /* see documentation for notes.                                                             */

//Impinj Uses TRCal = 50.2us = 1.6*RTCAL(middle of road. TRCal goes between 1.1-3 RTCAL per spec. also said, 2.75-9.00 TARI)
#define TRCAL_MIN       (124)
#define TRCAL_NOM       (193)       /* (really only saw spread from 193 at high power to 192 at low power)                      */
#define TRCAL_MAX       (451)       /* (this accounts for readers who use up to 9TARI)                                          */

//TIMING----------------------------------------------------------------------------------------------------------------------------//
//Goal is 56.125/62.500/68.875us. Trying to shoot for the lower to save (a little) power.
//Note: 1 is minVal here due to the way decrement timing loop works. 0 will act like (0xFFFF+1)!
#define TX_TIMING_QUERY (12)/*53.5-60us (depends on which Q value is loaded). */
#define TX_TIMING_ACK   (20)/*60.0us*/  //(14,58.6us)

#define TX_TIMING_QR    (52)//58.8us
#define TX_TIMING_QA    (48)//60.0us
#define TX_TIMING_REQRN (33)//60.4us
#define TX_TIMING_READ  (29)//58.0us
#define TX_TIMING_WRITE (31)//60.4us

#define FORCE_SKIP_INTO_RTCAL   (12)                    /* after delim, wait till data0 passes before starting TA1_SM. note     */
                                                            /* changing this will affect timing criteria on RTCal measurement       */
//PROTOCOL DEFS---------------------------------------------------------------------------------------------------------------------//
//(if # is rounded to 8 that is so  cmd[n] was finished being shifted in)
#define NUM_SEL_BITS    (48)    /* only need to parse through mask: (4+3+3+2+8+8+16 = 44 -> round to 48)                        */
#define NUM_QUERY_BITS  (22)
#define NUM_ACK_BITS    (18)
#define NUM_REQRN_BITS  (40)
#define NUM_WRITE_BITS  (66)

#define EPC_LENGTH      (0x06)  /* 10h..14h EPC Length in Words. (6 is 96bit std)                                               */
#define UMI             (0x01)  /* 15h          User-Memory Indicator. '1' means the tag has user memory available.             */
#define XI              (0x00)  /* 16h          XPC_W1 indicator. '0' means the tag does not support this feature.              */
#define NSI             (0x00)  /* 17h..1Fh Numbering System Identifier. all zeros means it isn't supported and is recommended default */

//CRC CALC DEFINES----------------------------------------------------------------------------------------------------------------
#define ZERO_BIT_CRC    (0x1020)                                        /* state of the CRC16 calculation after running a '0'   */
#define ONE_BIT_CRC     (0x0001)                                        /* state of the CRC16 calculation after running a '1'   */
#define CRC_NO_PRELOAD  (0x0000)                                        /* don't preload it, start with 0!                      */
#define CCITT_POLY      (0x1021)

#define TREXT_ON        (1)                                             /* Tag should use TRext format for backscatter          */
#define TREXT_OFF       (0)                                             /* Tag shouldn't use TRext format for backscatter       */
#define WRITE_DATA_BLINK_LED    (0x00)
#define WRITE_DATA_NEW_ID       (0x01)

#ifndef __ASSEMBLER__
#include <stdint.h>                                                     /* use xintx_t good var defs (e.g. uint8_t)             */
#include "config/wispGuts.h"

//TYPEDEFS----------------------------------------------------------------------------------------------------------------------------
//THE RFID STRUCT FOR INVENTORY STATE VARS
typedef struct {
    uint8_t     TRext;                      /** @todo What is this member? */
    uint16_t    handle;                     /** @todo What is this member? */
    uint16_t    slotCount;                  /** @todo What is this member? */
    uint8_t     Q;                          /** @todo What is this member? */

    uint8_t     mode;                       /** @todo What is this member? */
    uint8_t     abortOn;                    /*  List of command responses which cause the main RFID loop to return              */
    uint8_t     abortFlag;                  /** @todo What is this member? */
    uint8_t     isSelected;                 /* state of being selected via the select command. Zero if not selected             */

    uint8_t     rn8_ind;                    /* using our RN values in INFO_MEM, this points to the current one to use next      */

    uint16_t	edge_capture_prev_ccr;		/* Previous value of CCR register, used to compute delta in edge capture ISRs		*/

    /** @todo Add the following: CMD_enum latestCmd; */

}RFIDstruct;                                /* in MODE_USES_SEL!!                                                               */

extern RFIDstruct   rfid;

//THE RW STRUCT FOR ACCESS STATE VARS
typedef struct {
    //Parsed Cmd Fields
    uint8_t     memBank;                    /* for Rd/Wr, this will hold memBank parsed from cmd when hook is called            */
    uint8_t     wordPtr;                    /* for Rd/Wr, this will hold wordPtr parsed from cmd when hook is called            */
    uint16_t    wrData;                     /* for Write this will hold the 16-bit Write Data value when hook is called         */
    uint16_t    bwrByteCount;               /* for BlockWrite this will hold the number of BYTES received                       */
    uint8_t*    bwrBufPtr;                  /* for BlockWrite this will hold a pointer to the data buffer containing write data */

    //Function Hooks
    void*       *akHook;                    /* this function is called with no params or return after an ack command response   */
    void*       *wrHook;                    /* this function is called with no params or return after a write command response  */
    void*       *bwrHook;                   /* this function is called with no params or return after a write command response  */
    void*       *rdHook;                    /* this function is called with no params or return after a read command response   */

    //Memory Map Bank Ptrs
    uint8_t*    RESBankPtr;                 /* for read command, this is a pointer to the virtual, mapped Reserved Bank         */
    uint8_t*    EPCBankPtr;                 /* "" mapped EPC Bank                                                               */
    uint8_t*    TIDBankPtr;                 /* "" mapped TID Bank                                                               */
    uint8_t*    USRBankPtr;                 /* "" mapped USR Bank                                                               */
}RWstruct;

// Boolean type
typedef uint8_t     BOOL;

extern RWstruct     RWData;

//Memory Banks
extern uint8_t cmd      [CMDBUFF_SIZE];
extern uint8_t dataBuf  [DATABUFF_SIZE];
extern uint8_t rfidBuf  [RFIDBUFF_SIZE];


extern uint8_t  usrBank [USRBANK_SIZE];
extern uint16_t wisp_ID;
extern volatile uint8_t     isDoingLowPwrSleep;

//Register Macros
#define bits        _get_R5_register()
#define dest        _get_R4_register()
#define setBits(x)  _set_R5_register(x)
#define setDest(x)  _set_R4_register(x)

//FUNCTION PROTOTYPES---------------------------------------------------------------------------------------------------------------//
extern void WISP_doRFID(void);
extern void TxFM0(volatile uint8_t *data, uint8_t numBytes, uint8_t numBits, uint8_t TRext); //sends out MSB first...

// Linker hack: We need to reference assembly ISRs directly somewhere to force linker to include them in binary.
extern void RX_ISR(void);
extern void Timer0A0_ISR(void);
extern void Timer0A1_ISR(void);

extern void handleQuery     (void);
extern void handleAck       (void);
extern void handleQR        (void);
extern void handleQA        (void);
extern void handleReq_RN    (void);
extern void handleRead      (void);
extern void handleWrite     (void);
extern void handleBlockWrite(void);

//MACROS----------------------------------------------------------------------------------------------------------------------------//
#define BITSET(port,pin)    port |= (pin)
#define BITCLR(port,pin)    port &= ~(pin)
#define BITTOG(port,pin)    port ^= (pin)

//RFID DEFINITIONS------------------------------------------------------------------------------------------------------------------//

#define STORED_PC       (  ((EPC_LENGTH&0x001F)<<11) | ((UMI&0x0001)<<10) | ((XI&0x0001)<<9) | (NSI&0x01FF)<<01 )
//**per EPC Spec would be:
//#define STORED_PC_GRR     (uint16_t)  (  ((NSI&0x01FF)<<7) | ((XI&0x01)<<6) | ((UMI&0x01)<<5) | (EPC_LENGTH&0x1F)  )

//This is the ugliest, non-portable code ever BUT it allows the compiler to setup the memory at compile time.
#define STORED_PC1      ( (STORED_PC&0xFF00)>>8 )
#define STORED_PC0      ( (STORED_PC&0x00FF)>>0 )

//CRC STUFF (TO MOVE TO ANOTHER HEADER FILE SOMEDAY)--------------------------------------------------------------------------------//
extern uint16_t crc16_ccitt     (uint16_t preload,uint8_t *dataPtr, uint16_t numBytes);
extern uint16_t crc16Bits_ccitt (uint16_t preload,uint8_t *dataPtr, uint16_t numBytes,uint16_t numBits);

//LUT for Table Driven Methods
extern uint16_t crc16_LUT[256];
extern uint16_t crc16_cLUT      (uint16_t crc16_cLUT(uint8_t *pmsg, uint8_t msg_size);

#endif /* __ASSEMBLER__ */
#endif /* GLOBALS_H_ */
