			.title	"morse.asm"
;*******************************************************************************
;     Project:  morse.asm
;      Author: 	Aya Dijkwel
;   Statement: 	I wrote this code.
;
; Description:  Outputs a message in Morse Code using a LED and a transducer
;               (speaker).  The watchdog is configured as an interval timer.
;               The watchdog interrupt service routine (ISR) toggles the green
;               LED every second and pulse width modulates (PWM) the speaker
;               such that a tone is produced.
;
;	Morse code is composed of dashes and dots:
;
;        1. A dot is equal to an element of time.
;        2. One dash is equal to three dots.
;        3. The space between parts of the letter is equal to one dot.
;        4. The space between two letters is equal to three dots.
;        5. The space between two words is equal to seven dots.
;
;    5 WPM = 60 sec / (5 * 50) elements = 240 milliseconds per element.
;    element = (WDT_IPS * 6 / WPM) / 5
;
;******************************************************************************




; System equates --------------------------------------------------------------
            .cdecls C,"msp430.h"            ; include c header
			.cdecls C,"morse2.h"

;myCLOCK     .equ    1200000                 ; 1.2 Mhz clock
;WDT_CTL     .equ    WDT_MDLY_0_5            ; WD: Timer, SMCLK, 0.5 ms
;WDT_CPI     .equ    500                     ; WDT Clocks Per Interrupt (@1 Mhz)
;WDT_IPS     .equ    (myCLOCK/WDT_CPI)       ; WDT Interrupts Per Second
;STACK       .equ    0x0600                  ; top of stack

;set outputs for LED----------------------------------------------------------
            .asg   "bis.b #0x40,&P4OUT",RED_LED_ON
            .asg   "bic.b #0x40,&P4OUT",RED_LED_OFF
            .asg   "xor.b #0x40,&P4OUT",RED_LED_TOGGLE

            .asg   "bis.b #0x10,&P3OUT",GREEN_LED_ON
            .asg   "bic.b #0x10,&P3OUT",GREEN_LED_OFF
            .asg   "xor.b #0x10,&P3OUT",GREEN_LED_TOGGLE

; Morse Code equates ----------------------------------------------------------
;END         .equ    0
;DOT         .equ    1
;DASH        .equ    2
;ELEMENT     .equ    ((WDT_IPS*240)/1000)    ; (WDT_IPS * 6 / WPM) / 5
;DEBOUNCE	.equ	10

; External references ---------------------------------------------------------
            .ref    numbers                 ; codes for 0-9
            .ref    letters                 ; codes for A-Z

            .def	doDOT
            .def	doDASH
            .def	doSPACE
            .def	doEND
			.def	beep_cnt
			.def	delay_cnt
			.def	debounce_cnt
			.def	watchdog_cnt
			.def	message

; Global variables ------------------------------------------------------------
            .bss    beep_cnt,2              ; beeper flag
            .bss    delay_cnt,2             ; delay flag
			.bss    debounce_cnt,2         	; debounce count
            .bss	watchdog_cnt,2			; watchdog counter for flashing green LED

; Program section -------------------------------------------------------------
            .text                           ; program section
message:    .string "HELLO CS124 WORLD"     ;
            .byte   0
            .align  2                       ; align on word boundary

; power-up reset --------------------------------------------------------------
;RESET:      mov.w   #STACK,SP               ; initialize stack pointer
;            call    #main_asm               ; call main function
;            jmp     $                       ; you should never get here!


; start main function vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

; output char in morse code (DOT, DASH, SPACE)
doDOT:      push	r15
			mov.w   #ELEMENT,r15            ; output DOT
            call    #beep
            mov.w   #ELEMENT,r15            ; delay 1 element
            call    #delay
            pop		r15
            ret

doDASH:     push	r15
			mov.w   #ELEMENT*3,r15          ; output DASH
            call    #beep
            mov.w   #ELEMENT,r15            ; delay 1 element
            call    #delay
            pop		r15
            ret

doSPACE:	push	r15
            mov.w   #ELEMENT*4,r15          ; output space
            call    #delay                  ; delay
            pop		r15
            ret

doEND:		push	r15
			mov.w	#ELEMENT*2, R15
			call	#delay
			pop		r15
			ret

; end main function ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; beep (r15) ticks subroutine -------------------------------------------------
beep:       mov.w   r15,&beep_cnt           ; start beep

beep02:     tst.w   &beep_cnt               ; beep finished?
              jne   beep02                  ; n
            ret                             ; y

; delay (r15) ticks subroutine ------------------------------------------------
delay:      mov.w   r15,&delay_cnt          ; start delay

delay02:    tst.w   &delay_cnt              ; delay done?
              jne   delay02                 ; n
            ret                             ; y

; Watchdog Timer ISR ----------------------------------------------------------
WDT_ISR:    tst.w   &beep_cnt               ; beep on?
              jeq   WDT_01                  ; n
            dec.w   &beep_cnt               ; y, decrement count
            xor.b   #0x20,&P4OUT            ; beep using 50% PWM
            RED_LED_ON

WDT_01:		tst.w   debounce_cnt           	; debouncing?
             jeq   	WDT_02                 	; n
; debounce switches

           	dec.w   debounce_cnt           	; y, decrement count
             jne   	WDT_02                 	; not done

           	push    r15                    	; y
           	mov.b   &P1IN,r15              	; read buttons
           	and.b   #0x0f,r15
           	xor.b   #0x0f,r15              	; any button pressed?
             jeq   	WDT_20                 	; n
			xor.b   #0x20,&P4DIR			; turns off sound if button is pressed

WDT_20:    	pop     r15

;-------------------------------------------------------------------------------
WDT_02:     tst.w   &delay_cnt              ; delay?
              jeq   WDT_10                  ; n
            dec.w   &delay_cnt              ; y, decrement count
            		RED_LED_OFF

WDT_10:		dec.w	&watchdog_cnt

			jnz		WDT_30
					GREEN_LED_TOGGLE
			mov.w	#WDT_IPS, watchdog_cnt

WDT_30:  	reti

;------------------------------------------------------------------------------                        ; return from interrupt
;P1_ISR:    	bic.b   #0x0f,&P1IFG           	; acknowledge interrupt
;           	mov.w   #DEBOUNCE,debounce_cnt 	; reset debounce count
;           	reti

; Interrupt Vectors -----------------------------------------------------------
            .sect   ".int10"                ; Watchdog Vector
            .word   WDT_ISR                 ; Watchdog ISR
;            .sect	".int02"				; interrupt vector
;            .word	P1_ISR					; interrupt ISR

;            .sect   ".reset"                ; PUC Vector
;            .word   RESET                   ; RESET ISR
            .end




























/*


; System equates --------------------------------------------------------------
            .cdecls C,"msp430.h"            ; include c header
			.cdecls C,"morse2.h"
myCLOCK     .equ    1200000                 ; 1.2 Mhz clock
WDT_CTL     .equ    WDT_MDLY_0_5            ; WD: Timer, SMCLK, 0.5 ms
WDT_CPI     .equ    500                     ; WDT Clocks Per Interrupt (@1 Mhz)
WDT_IPS     .equ    (myCLOCK/WDT_CPI)       ; WDT Interrupts Per Second
STACK       .equ    0x0600                  ; top of stack

DEBOUNCE   	.equ    10





;set outputs for LED----------------------------------------------------------
            .asg   "bis.b #0x40,&P4OUT",RED_LED_ON
            .asg   "bic.b #0x40,&P4OUT",RED_LED_OFF
            .asg   "xor.b #0x10,&P3OUT",GREEN_LED_TOGGLE

;initialize switches----------------------------------------------------------------


; Morse Code equates ----------------------------------------------------------
END         .equ    0
DOT         .equ    1
DASH        .equ    2
ELEMENT     .equ    ((WDT_IPS*240)/1000)    ; (WDT_IPS * 6 / WPM) / 5

; External references ---------------------------------------------------------
            .ref    numbers                 ; codes for 0-9
            .ref    letters                 ; codes for A-Z

            .def	doDOT
            .def	doDASH
            .def	doSPACE
            .def	doEND
			.def	beep_cnt
			.def	delay_cnt
			.def	debounce_cnt
			.def	watchdog_cnt
			.def	message
; Global variables ------------------------------------------------------------
            .bss    beep_cnt,2              ; beeper flag
            .bss    delay_cnt,2             ; delay flag
           	.bss    debounce_cnt,2         	; debounce count
           	.bss    watchdog_cnt,2         	; watchdog count

; Program section -------------------------------------------------------------
            .text                           ; program section
message:    .string "HELLO CS 124 WORLD"  ; message
            .byte   0
            .align  2                       ; align on word boundary

			.def	main_asm				; temporarily added					/////////?????????
; start main function =========================================================
main_asm:   mov.w   #WDT_CTL,&WDTCTL        ; set WD timer interval
            mov.b   #WDTIE,&IE1             ; enable WDT interrupt
            bis.b   #0x20,&P4DIR            ; set P4.5 as output (speaker)
            bis.b   #0x40,&P4DIR    		; set P4.6 as output redled
            bis.b   #0x10,&P3DIR			; green led
            clr.w   &beep_cnt               ; clear counters
            clr.w   &delay_cnt
            bis.w   #GIE,SR                 ; enable interrupts
           	bic.b   #0x0f,&P1SEL           	; RBX430-1 push buttons
           	bic.b   #0x0f,&P1DIR           	; Configure P1.0-3 as Inputs
           	bis.b   #0x0f,&P1OUT           	; pull-ups
           	bis.b   #0x0f,&P1IES           	; h to l
           	bis.b   #0x0f,&P1REN           	; enable pull-ups
           	bis.b   #0x0f,&P1IE            	; enable switch interrupts
           	mov.w	#WDT_IPS,watchdog_cnt


;----------------------------------------------------------------------------
mloop:      mov.w  #message,r4            	; point to message

getChar:	mov.b  	@r4+,r5                	; get character
  			;figure out if it's letter space or number
 			cmp.b	#0, r5
  			jeq 	mloop

			cmp.b	#32,r5
			jeq		space

			cmp.w 	#'A',r5
			jge		letter

  			sub.w  	#48,r5                	; make index 0-25
  			add.w  	r5,r5                  	; make word index
  			mov.w  	numbers(r5),r5         	; get pointer to letter codes
  			jmp		loop

letter:
  			sub.w  	#'A',r5                ; make index 0-25
  			add.w  	r5,r5                  ; make word index
  			mov.w  	letters(r5),r5         ; get pointer to letter codes
  			jmp		loop


;subroutines--------------------------------------------------------------------
loop:   	mov.b  	@r5+,r6                ; get DOT, DASH, or END
  			cmp.b  	#DOT,r6                ; dot?
  			jeq		dot
  			cmp.b	#DASH,r6
  			jeq		dash
  			cmp.b	#END,r6
  			jeq		end

dot:		call	#doDOT
  			jmp		loop

dash:		call	#doDASH
  			jmp		loop

end:		call	#doEND
			jmp		getChar
;-----------------------------------------------------------------------------
space:
  			call	#doSPACE
   			jmp		getChar

;check_if_done:;check to see if a space has already been outputted, if so then

;---------------------------------------------------------------------------

; output 'A' in morse code (DOT, DASH, space)

doDOT:      push 	r15
			mov.w   #ELEMENT,r15            ; output DOT
            call    #beep
            mov.w   #ELEMENT,r15            ; delay 1 element
            call    #delay
 		    pop 	r15
            ret

doDASH:     push 	r15
		    mov.w   #ELEMENT*3,r15          ; output DASH
            call    #beep
            mov.w   #ELEMENT,r15            ; delay 1 element
            call    #delay
            pop 	r15
            ret

doSPACE:    push 	r15
            mov.w   #ELEMENT*4,r15          ; output space
            call    #delay                  ; delay
            pop		r15
            ret

doEND:    	push 	r15
            mov.w   #ELEMENT*2,r15          	; output space
            call    #delay                  ; delay
            pop		r15
            ret

;==============================================================================



; beep (r15) ticks subroutine -------------------------------------------------
beep:       mov.w   r15,&beep_cnt           ; start beep

beep02:     tst.w   &beep_cnt               ; beep finished?
            jne   	beep02                  ; n
            ret                             ; y


; delay (r15) ticks subroutine ------------------------------------------------
delay:      mov.w   r15,&delay_cnt          ; start delay

delay02:    tst.w   &delay_cnt              ; delay done?
            jne   	delay02                 ; n
            ret                             ; y


; Watchdog Timer ISR ----------------------------------------------------------
WDT_ISR:    tst.w   &beep_cnt               ; beep on?
            jeq   	WDT_01	                ; n
            dec.w   &beep_cnt               ; y, decrement count
            xor.b   #0x20,&P4OUT            ; beep using 50% PWM
            		RED_LED_ON

WDT_01:    	tst.w   debounce_cnt           	; debouncing?
            jeq   	WDT_02                	; n

           	dec.w   debounce_cnt           	; y, decrement count, done?
           	jne   	WDT_02                	; n
           	push    r15                    	; y
           	mov.b   &P1IN,r15              	; read switches
           	and.b   #0x0f,r15
           	xor.b   #0x0f,r15	         	; any switches?
           	jeq   	WDT_20       	        ; n
			xor.b   #0x20,&P4DIR

WDT_20:    	pop     r15

WDT_02:     tst.w   &delay_cnt              ; delay?
            jeq   	WDT_11                  ; n
            dec.w   &delay_cnt              ; y, decrement count
					RED_LED_OFF


WDT_11:    	dec.w	&watchdog_cnt
			jnz		WDT_30
					GREEN_LED_TOGGLE
			mov.w	#WDT_IPS,watchdog_cnt


WDT_30:	   reti


P1_ISR:    bic.b   	#0x0f,&P1IFG           	; acknowledge (put hands down)
           mov.w   	#DEBOUNCE,debounce_cnt 	; reset debounce count
           reti

; Interrupt Vectors -----------------------------------------------------------
            .sect   ".int10"                ; Watchdog Vector
            .word   WDT_ISR                 ; Watchdog ISR

           	.sect  ".int02"                	; P1 interrupt vector
           	.word  P1_ISR

            .end

*/
