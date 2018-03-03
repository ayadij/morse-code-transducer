#include <msp430.h>
/*
 * morse2.h
 *
 *  Created on: Nov 26, 2016
 *      Author: Aya Dijkwel
 */
////////////////////////////////////////////////////////////////////////////
//translate all assembly .equ's to C #define's and include in morse2.h
	//do not put any variable or function definitions (code) in your header files!
	//be careful to parenthesize all constant calculations (i.e., use #define ELEMENT (...*10)/100 )
////////////////////////////////////////////////////////////////////////////////

#ifndef MORSE2_H_
#define MORSE2_H_

#define myCLOCK		1025000			  	//myCLOCK     .equ    1200000                 ; 1.2 Mhz clock
#define WDT_CTL		WDT_MDLY_0_5	  	//WDT_CTL     .equ    WDT_MDLY_0_5            ; WD: Timer, SMCLK, 0.5 ms
#define	WDT_CPI		500				  	//WDT_CPI     .equ    500                     ; WDT Clocks Per Interrupt (@1 Mhz)
#define	WDT_IPS		(myCLOCK/WDT_CPI) 	//WDT_IPS     .equ    (myCLOCK/WDT_CPI)       ; WDT Interrupts Per Second
#define STACK		0x0600			  	//STACK       .equ    0x0600                  ; top of stack

//; Morse Code equates ----------------------------------------------------------
#define END			0				  	//END         .equ    0
#define DOT			1					//DOT         .equ    1
#define DASH		2					//DASH        .equ    2
#define ELEMENT		((WDT_IPS*240)/1000)//ELEMENT     .equ    ((WDT_IPS*240)/1000)    ; (WDT_IPS * 6 / WPM) / 5
#define DEBOUNCE	10					//DEBOUNCE	  .equ	  10

#endif // MORSE2_H_
