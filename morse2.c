#include <msp430.h> 		////// is this line right? is it needed?
#include "msp430.h"          // .cdecls C,"msp430.h"
#include "morse2.h"
#include <stdlib.h>
#include <ctype.h>

//////////////////////////////////////////////////////////////////////////////////
extern int beep_cnt;					//.bss    beep_cnt,2             		; beeper flag
extern int delay_cnt;					//.bss    delay_cnt,2           		; delay flag
extern int debounce_cnt;				//.bss    debounce_cnt,2         		; debounce count
extern int watchdog_cnt;				//.bss	  watchdog_cnt,2				; watchdog counter for flashing green LED

extern char message[];
extern char* letters[];
extern char* numbers[];

void space();
void doLetter(char);
void doNumber(char);

extern void doDOT();
extern void doDASH();
extern void doSPACE();
extern void doEND();

void mcode(char*);
//////////////////////////////////////////////////////////////////////////////////



extern int main_asm(void);					//code from lab site

int main(void)
{
	//WDTCTL = WDTPW | WDTHOLD;				//stops watchdog timer
											//	; start main function vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
											//          .def    main_asm
											//	  main_asm:
											//			mov.w   #WDT_CTL,&WDTCTL ; set WD timer interval
											//          mov.b   #WDTIE,&IE1      ; enable WDT interrupt
											//					...
											//          jmp     loop             ; repeat
											//	; end main function ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


/////////////////////////////////////////////////////////////////////////////////////
//	; start main function =========================================================
	WDTCTL = WDT_CTL;						//	main_asm:   mov.w   #WDT_CTL,&WDTCTL        ; set WD timer interval/////////????????
	IE1 = WDTIE;							//	            mov.b   #WDTIE,&IE1             ; enable WDT interrupt
	P4DIR |= 0x60;							//	            bis.b   #0x20,&P4DIR            ; set P4.5 as output (speaker)
											//	            bis.b   #0x40,&P4DIR    		; set P4.6 as output redled
	P3DIR |= 0x10;							//	            bis.b   #0x10,&P3DIR			; green led
	beep_cnt = 0;							//	            clr.w   &beep_cnt               ; clear counters
	delay_cnt = 0;							//	            clr.w   &delay_cnt
	__bis_SR_register(GIE);					//	            bis.w   #GIE,SR                 ; enable interrupts
	P1SEL &= ~0x0f;							//	           	bic.b   #0x0f,&P1SEL           	; RBX430-1 push buttons
	P1DIR &= ~0x0f;							//	           	bic.b   #0x0f,&P1DIR           	; Configure P1.0-3 as Inputs
	P1OUT |= 0x0f;							//	           	bis.b   #0x0f,&P1OUT           	; pull-ups
	P1IES |= 0x0f;							//	           	bis.b   #0x0f,&P1IES           	; h to l
	P1REN |= 0x0f;							//	           	bis.b   #0x0f,&P1REN           	; enable pull-ups
	P1IE  |= 0x0f;							//	           	bis.b   #0x0f,&P1IE            	; enable switch interrupts
											//
	watchdog_cnt = WDT_IPS;					//	           	mov.w	#WDT_IPS,watchdog_cnt
											//
											//	;main lopp----------------------------------------------------------------------
	while(1){								//	mloop:      mov.w  #message,r4            	; point to message
											//
		char* mptr = message;				//	getChar:	mov.b  	@r4+,r5                	; get character
											//	  											;figure out if it's letter space or number
		char c = 0;							//	 			cmp.b	#0, r5
		char* cptr;							//	  			jeq 	mloop
		char code;							//
		while(c = *mptr++){					//
			if(isspace(c)){					//				cmp.b	#32,r5
				doSPACE(); continue;		//				jeq		space
			}								//
			else if (c >= 'A'){				//				cmp.w 	#'A',r5
				cptr = letters[toupper(c) - 'A'];//			jge		letter
			}								//
			else if(c >= '0'){				//				sub.w  	#48,r5					; make index 0-25
				cptr = numbers[c - '0'];	//
			}								//
											//
			while(code = *cptr++){			//
				if(code==DOT){				//
					doDOT();				//
				}							//
				else if(code == DASH){		//
					doDASH();				//
				}							//
			}								//
			doEND();						//
		}				//
	}//end of while(1) loop					//

}


											//	;-----------------------------------------------------------------------------
void doLetter(char c)						//
{											//
	char c1;								//				add.w  	r5,r5                  	; make word index
	c1 = c - 'A';							//	  			mov.w  	numbers(r5),r5         	; get pointer to letter codes
	mcode(letters[c1]);						//	  			jmp		loop
	return;									//
}											//
											//
void doNumber(char c)						//	  			sub.w  	#'A',r5                ; make index 0-25
{											//	  			add.w  	r5,r5                  ; make word index
	char c1;								//	  			mov.w  	letters(r5),r5         ; get pointer to letter codes
	c1 = c - '0';							//	  			jmp		loop
	mcode(numbers[c1]);						//
	return;									//
}											//
											//	;-----------------------------------------------------------------------------
											//	space:
void space()								//
{											//	  			call	#doSPACE
	doSPACE();								//	   			jmp		getChar
}											//
											//	;check_if_done:;check to see if a space has already been outputted, if so then
											//
											//	;subroutines--------------------------------------------------------------------
void mcode(char c[])						//
{											//	loop:   	mov.b  	@r5+,r6                ; get DOT, DASH, or END
	unsigned int i = 0;						//	  			cmp.b  	#DOT,r6                ; dot?
	while(c[i != END]){						//	  			jeq		dot
											//	  			cmp.b	#DASH,r6
											//	  			jeq		dash
											//	  			cmp.b	#END,r6
											//	  			jeq		end
											//
		if(c[i] == DOT){					//	dot:		call	#doDOT
			doDOT();						//	  			jmp		loop
		}									//
		else if(c[i] == DASH){				//	dash:		call	#doDASH
			doDASH();						//	  			jmp		loop
		}									//
		else if(c[i] == END){				//	end:		call	#doEND
			doEND();						//				jmp		getChar
			break;							//
		}									//
		i++;								//
	}										//
	return;									//
}											//
											//
											//
											//
#pragma vector = PORT1_VECTOR				//;---------------------------------------------------------------------------
											//
__interrupt void Port_1_ISR(void){			//
	P1IFG &= ~0x0f;							//; output 'A' in morse code (DOT, DASH, space)
	debounce_cnt = DEBOUNCE;				//
	return;									//	doDOT:      push 	r15
}											//				mov.w   #ELEMENT,r15            ; output DOT
											//	            call    #beep
											//	            mov.w   #ELEMENT,r15            ; delay 1 element
											//	            call    #delay
											//	 		    pop 	r15
											//	            ret
											//
											//	doDASH:     push 	r15
											//			    mov.w   #ELEMENT*3,r15          ; output DASH
											//	            call    #beep
											//	            mov.w   #ELEMENT,r15            ; delay 1 element
											//	            call    #delay
											//	            pop 	r15
											//	            ret
											//
											//	doSPACE:    push 	r15
											//	            mov.w   #ELEMENT*4,r15          ; output space
											//	            call    #delay                  ; delay
											//	            pop		r15
											//	            ret
											//
											//	doEND:    	push 	r15
											//	            mov.w   #ELEMENT*2,r15          	; output space
											//	            call    #delay                  ; delay
											//	            pop		r15
											//	            ret
											//
											//	;==============================================================================









