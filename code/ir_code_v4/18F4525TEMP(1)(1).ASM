;******************************************************************************
;   This file is a basic template for assembly code for a PIC18F4525. Copy    *
;   this file into your project directory and modify or add to it as needed.  *
;                                                                             *
;   Refer to the MPASM User's Guide for additional information on the         *
;   features of the assembler.                                                *
;                                                                             *
;   Refer to the PIC18FX525/X620 Data Sheet for additional                    *
;   information on the architecture and instruction set.                      *
;                                                                             *
;******************************************************************************
;                                                                             *
;    Filename:                                                                *
;    Date:                                                                    *
;    File Version:                                                            *
;                                                                             *
;    Author:                                                                  *
;    Company:                                                                 *
;                                                                             * 
;******************************************************************************
;                                                                             *
;    Files Required: P18F4525.INC                                             *
;                                                                             *
;******************************************************************************

	LIST P=18F4525	;directive to define processor
	#include "P18F4525.INC"	;processor specific variable definitions

;******************************************************************************
;Configuration bits
;Microchip has changed the format for defining the configuration bits, please 
;see the .inc file for futher details on notation.  Below are a few examples.



;   Oscillator Selection:
    CONFIG	OSC = HS             ;LP

;******************************************************************************
;Variable definitions
; These variables are only needed if low priority interrupts are used. 
; More variables may be needed to store other special function registers used
; in the interrupt routines.

		tmr_cnt equ 0x10

;******************************************************************************
;EEPROM data
; Data to be programmed into the Data EEPROM is defined here

		ORG	0xf00000

		DE	"Test Data",0,1,2,3,4,5

;******************************************************************************
;Reset vector
; This code will start executing when a reset occurs.

		ORG	0x0000

		goto	Main		;go to start of main code

;******************************************************************************
;High priority interrupt vector
; This code will start executing when a high priority interrupt occurs or
; when any interrupt occurs if interrupt priorities are not enabled.

		ORG	0x0008

		bra	HighInt		;go to high priority interrupt routine

;******************************************************************************
;Low priority interrupt vector and routine
; This code will start executing when a low priority interrupt occurs.
; This code can be removed if low priority interrupts are not used.

		

;******************************************************************************
;High priority interrupt routine
; The high priority interrupt code is placed here to avoid conflicting with
; the low priority interrupt vector.

HighInt:

;	*** high priority interrupt code goes here ***

		decf tmr_cnt
		retfie	FAST

;******************************************************************************
;Timer interrupt service routine

		ORG	0x0010
		
		btfsc PIR1, TMR2IF
		bra T2_ISR

		retfie

T2_ISR
		decf tmr_cnt
		retfie
		

;******************************************************************************
;Start of main program
; The main program code is placed here.

Main:
		; configure port c
		clrf PORTC
		clrf LATC
		clrf TRISC
		
		;bsf PORTB,0x01

;		; configure pwm module
		banksel PR2
		movlw 0x44			; configure period time with 0x44
		movwf PR2

		movlw b'00001100' ;b'00000100'	; configure duty cycle with 0x11
		movwf CCPR2L
		movlw b'00111100' ;b'00011100'	; configure pwm mode and 2 lsbs of duty cycle
		movwf CCP2CON
		
		;bcf T2CON,T2CKPS1	; configure timer prescale value with 1
		;bcf T2CON,T2CKPS0
		;bsf T2CON,TMR2ON	; enable timer
		;movlw b'00001100'	; configure timer postscale, prescale and turn on timer
		;movwf T2CON

		; start timer 1 for half bit
;		banksel PR1
;		movlw 0x
;		bcf PIR1,TMR1IF
		

		; start timer 2 for pwm
		movlw 0x20
		movwf tmr_cnt
		
		movlw b'00000000'
		movwf T2CON
		movlw 0x00
		movwf TMR2

		bcf PIR1,TMR2IF
		bsf PIE1,TMR2IE ; Enable Timer1 interrupt

		bsf T2CON,TMR2ON
		
		;bcf T2CON,T2CKPS1
		;bcf T2CON,T2CKPS0
		;bsf T2CON,TMR2ON



		;bsf PORTB,0x03
		
		;banksel CCP2CON
		;bsf CCP2CON, 0x03	; turn on pwm mode with 11xx
		;bsf CCP2CON, 0x02

		;bcf PORTB,0x03
loop:
IP	goto loop


;******************************************************************************
;End of program
	goto $
		END
