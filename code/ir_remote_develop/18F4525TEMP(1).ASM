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
    CONFIG OSC = HS
    CONFIG WDT = OFF
    CONFIG LVP = OFF

;******************************************************************************
;Variable definitions
		reset_timers equ 0x00
	
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
;High priority interrupt routine
; The high priority interrupt code is placed here to avoid conflicting with
; the low priority interrupt vector.

HighInt:

;	*** high priority interrupt code goes here ***
		bcf T0CON,TMR0ON
		bcf T2CON,TMR2ON

		bsf reset_timers,0

		retfie	FAST

;******************************************************************************
;Low priority interrupt vector
; This code will start executing when a low priority interrupt occurs.

		ORG	0x0018

		bra	LowInt		;go to high priority interrupt routine	

;******************************************************************************
;Low priority interrupt routine
; The low priority interrupt code is placed here to avoid conflicting with
; the high priority interrupt vector.

LowInt:

;	*** low priority interrupt code goes here ***


		retfie	FAST

;******************************************************************************

init_portb:
		; Routine f r INT0- INT2 
		;clrf	PORTB
		clrf	PORTB
		clrf LATB

init_ports
		CLRF PORTA ; Initialize PORTA by
					; clearing output
					; data latches
		CLRF LATA ; Alternate method
					; to clear output
					; data latches
		MOVLW 07h ; Configure A/D
		MOVWF ADCON1 ; for digital inputs
		MOVWF 07h ; Configure comparators
		MOVWF CMCON ; for digital input
		MOVLW 0FFh ; Value used to
					; initialize data
					; direction
		MOVWF TRISA ; Set RA<7:6,3:0> as inputs
					; RA<5:4> as outputs
		
		CLRF PORTD ; Initialize PORTD by
					; clearing output
					; data latches
		CLRF LATD ; Alternate method
					; to clear output
					; data latches
		MOVLW 0FFh ; Value used to
					; initialize data
					; direction
		MOVWF TRISD ; Set RD<3:0> as inputs
					; RD<5:4> as outputs
					; RD<7:6> as inputs
		
		return






;Start of main program
; The main program code is placed here.

Main:
		; configure port c
		clrf PORTC
		clrf LATC
		movlw b'11111101'
		movwf TRISC
		
		bsf LATC,1

		
		; configure pwm module
		banksel PR2
		movlw 0x44			; configure period time with 0x44
		movwf PR2

		movlw b'00010101' ;b'00000100'	; configure duty cycle with 0x11
		movwf CCPR2L
		movlw b'00001100' ;b'00011100'	; configure pwm mode and 2 lsbs of duty cycle
		movwf CCP2CON
		
		;bcf T2CON,T2CKPS1	; configure timer prescale value with 1
		;bcf T2CON,T2CKPS0
		;bsf T2CON,TMR2ON	; enable timer
		;movlw b'00001100'	; configure timer postscale, prescale and turn on timer
		;movwf T2CON
		
		bcf PIR1,TMR2IF
		bcf T2CON,T2CKPS1
		bcf T2CON,T2CKPS0
;		bsf T2CON,TMR2ON

		
		; start timer 0 for half bit
		movlw b'00001000'
		movwf T0CON
		movlw 0xF7
		movwf TMR0H
		movlw 0x52
		movwf TMR0L
		bcf INTCON,TMR0IF ;interrupt flag
		bsf INTCON,TMR0IE ;interrupt enable
		bsf INTCON2,TMR0IP ;high priority interrupt
		bsf INTCON,GIE ;general interrupt enable

		
		; start timer 2 for pwm
;		movlw 0x20
;		movwf tmr_cnt
		
;		movlw b'00000000'
;		movwf T2CON
;		movlw 0x00
;		movwf TMR2
;
;		bcf PIR1,TMR2IF
;		bcf PIE1,TMR2IE ; Enable Timer1 interrupt



		movlw 0x00
		movwf reset_timers


		
		; start timers
		bsf T0CON,TMR0ON
		bsf T2CON,TMR2ON

		

		;bsf PORTB,0x03
		
		;banksel CCP2CON
		;bsf CCP2CON, 0x03	; turn on pwm mode with 11xx
		;bsf CCP2CON, 0x02

		;bcf PORTB,0x03
;reset_loop
;		movlw 0x00
;		movwf TMR2
;		movlw 0xF7
;		movwf TMR0H
;		movlw 0x52
;		movwf TMR0L
;send_loop
;				
;		btfss reset_timers,0
;		bra send_loop
;		bra reset_loop

send_loop
		btfss reset_timers,0
		bra send_loop


;******************************************************************************
;End of program
	goto $
		END
