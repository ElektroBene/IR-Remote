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
bcf INTCON, INT0IF

check	
		nop
		nop

		btfss PORTB, RB0 ; Kann hier den Pin nicht richtig auslesen. PBADEN oder RBPU ? 
        retfie 
		nop 
		nop
		nop
        ; bcf LATB, 1Schalte LED an RB1 aus
        ;bcf INTCON, INT0IF  ; Clear interrupt Flag
        ;retfie
        goto check 
		
		



LowInt:
nop
nop

        retfie 

routine 
       nop
       nop
       nop
       return      

Taste4
      nop
      nop 
      nop 
	  nop
      return 
;******************************************************************************
;Start of main program
; The main program code is placed here.

Main:




      clrf	 PORTB      
     
      bcf    ADCON0,ADON ; AD Converter disabled 
      
      movlw	0xFF
      movwf	TRISB  

     movlw	 0xFF
     movwf	 ADCON1

      bcf 	 INTCON, INT0IF
      bcf 	INTCON2, RBPU
	;bsf		INTCON, RBIE
      
      bsf 	 INTCON, INT0IE
      bcf 	 INTCON2, INTEDG0
      bsf 	 INTCON, GIEH  
	bsf 	 INTCON, GIEL 
      
	  bsf RCON,IPEN 
    


; Am schalter RB0 kommt kein High Signal default - 1,7V und dann 0 V bei druecken
; War die ganze zeit nur auf 1,7V, weil jumper 6 drinnen war beim board 
           
 MLOOP  
nop
nop 
nop

nop

GOTO  MLOOP  

End
