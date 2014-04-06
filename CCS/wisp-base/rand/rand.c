/**
 * rand.c
 *
 * Random number generator using noisy LSb from the ADC12
 *
 * @author Aaron Parks, Justin Reina
 */

#include "../globals.h"

/**	@fcn		adc12_genRN16 (void)
 *  @brief		generate a random 16-bit value by sampling b0 of the temperature sensor.
 *
 * 		Use the 10-bit ADC in repeat-single-sample mode to read the ADC 16 times, keeping each samples' b0 and assembling a full word
 * 		from them at the end. Use the WISPs recently acquired ADC_clk setting, just cause its available.
 *
 *  @return		(int16_t)	a random 16 bit value.
 *
 */
uint16_t RAND_adcRand16 (void) {
	uint8_t 	 i;
	uint16_t 	 returnVal;									/* the final RN16 value to return										*/

	//------------------------------Turn on reference module's VREF and Temp Sense--------------------------------------------------//
	REFCTL0 = REFVSEL_1 + REFON;							/* turn module on @ 2V with temp sense active							*/

	// @todo Replace with low power delay
	__delay_cycles(75*16);									/* do an ~75us delay for ref to stabilize								*/

	//-----------------------------------Initalize the ADC to known state-----------------------------------------------------------//
	ADC12CTL0  = 0;
	ADC12CTL1  = 0;
	ADC12CTL2  = 0;
	ADC12MCTL0 = 0;
	ADC12IER0  = 0;

	//----------------------------Setup the ADC for Repeat Single-Sample on Temp Sensor---------------------------------------------//

	//--------Clocking Stuff------------//
//	ADC12CTL1 |= ADC12SSEL_2;								/* ADC Clk src is SMCLK													*/
	ADC12CTL1 |= ADC12DIV_0;								/* ADC Clk is /1 off source												*/

	//---------S&H Config---------------//
	//ADC12CTL0 |= ADC12MSC;								/* setup for repeated samples off first SHI pulse						*/
//	ADC12CTL1 |= ADC12SHS0;									/* S&H source comes directly from ADC12SC								*/
	ADC12CTL1 |= ADC12SHP;									/* enable using the S&H Sampling Timer (longer sample time (SHT00)		*/
	ADC12CTL0 |= ADC12SHT0_2;								/* 16 S&H Cycle cause we need min 13 for the 12-bit res sample			*/

	//--------Msrmnt Source-------------//
	ADC12CTL2 |= ADC12RES_2;								/* 10 bit sample res to max noise res in msr							*/
	ADC12MCTL0|= ADC12VRSEL_1;								/* reference is VREF and AVSS											*/
	ADC12MCTL0|= ADC12INCH_10;								/* setup to A10															*/

	//-----Conversion Sequence----------//
	ADC12CTL1 |= ADC12CONSEQ_0;								/* mode is single-sample on single-channel										*/

	//-----Turn On the ADC--------------//
	ADC12CTL0 |= ADC12ON;									/* turn that sucker on!													*/
	while (ADC12CTL1 & ADC12BUSY);             				/* Wait if ADC12 core is active (i.e. wait until its inactive, safety)	*/

	//-------------------------------------Acquire 16 measurements!-----------------------------------------------------------------//
	ADC12CTL0 |= ADC12ENC+ADC12SC;								/* start that conversion!											*/
	while (ADC12CTL1 & ADC12BUSY);             					/* Wait for it to complete all 16 samples into MEM0-15				*/

	returnVal = 0;

	for(i=0;i<15;i++) {

		returnVal = (returnVal<<1) | (ADC12MEM0 & BIT0);

		ADC12CTL0 |= ADC12SC;
		while (ADC12CTL1 & ADC12BUSY);               			/* Wait for it to complete all 16 samples into MEM0-15				*/
	}

	//--------------------------------------Turn off the ADC------------------------------------------------------------------------//
	ADC12CTL0  = 0;
	ADC12CTL1  = 0;
	ADC12CTL2  = 0;
	ADC12MCTL0 = 0;
	ADC12IER0  = 0;

	//--------------------------------------Turn off the REF------------------------------------------------------------------------//
	REFCTL0    = 0;

	return returnVal;
}
