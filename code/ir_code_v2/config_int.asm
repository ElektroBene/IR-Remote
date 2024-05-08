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
    CONFIG	OSC = XT             ;LP
    CONFIG WDT = OFF
    CONFIG LVP = OFF

;******************************************************************************
;Variable definitions
	

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





        ORG 0x0018
        nop
		nop
        bra LowInt 

;******************************************************************************
;High priority interrupt routine
; The high priority interrupt code is placed here to avoid conflicting with
; the low priority interrupt vector.

HighInt:

;	*** high priority interrupt code goes here ***
        bcf INTCON, INT0IF  ; Clear interrupt Flag

check btfss PORTB, RB0 ; ist schalter gedrückt
        retfie 
        bcf LATB, 1 ; Schalte LED an RB1 aus
        goto check 

		



LowInt:

        retfie 
       
;******************************************************************************
;Start of main program
; The main program code is placed here.

Main:

movlw 0x01
movwf TRISB
movlw 0x01
movwf ADCON1


bsf INTCON,  INT0IE 
bcf INTCON,  INT0IF ; Clears Flag
bsf INTCON2, INTEDG0 ; sensitive on rising edge 
bsf INTCON,  GIE ; Sets Globes interrupt Enable bit

; muss ich jetzt noch die Flanke einstellen 


loop bsf LATB,1 
     bsf LATB,RB2         ; LED an
goto loop




;******************************************************************************
;End of program
	goto $
		END

