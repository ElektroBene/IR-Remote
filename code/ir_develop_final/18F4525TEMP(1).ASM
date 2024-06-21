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
		send equ 0x01
		bit_buffer_h equ 0x02
		bit_buffer_l equ 0x03
		bit_ctr equ 0x04
		tmr_done equ 0x05
		cmd_ctr equ 0x06
		rev_bit_ctr equ 0x07


toggel  Equ     0x20            ; zählt ir-Sendungen, bit 0 ist toggelbit
gr      Equ     0x21            ; Gruppencode 5 bit rechtsbündig
co      Equ     0x22            ; Commandocode 6 bit rechtsbündig
cycl_1  Equ     0x23            ; zähler 
cycl_2  Equ     0x24            ; zähler 
	
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
		bcf INTCON,INT0IF
		bcf INTCON3,INT1IF
		bcf INTCON3,INT2IF
		bcf INTCON,RBIF

		bsf send,0
		
;		call isr

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
		bcf T0CON,TMR0ON
		bcf T2CON,TMR2ON

		bcf INTCON,TMR0IF

		bsf tmr_done,0


		retfie	FAST

;******************************************************************************

isr:
		;bsf send,0

		bcf T0CON,TMR0ON
		bcf T2CON,TMR2ON

		bcf INTCON,TMR0IF

		bsf reset_timers,0
		return

init_portb:
		; Routine f r INT0- INT2 
		;clrf	PORTB
		clrf	PORTB
		clrf LATB
     
		bcf    ADCON0,ADON ; AD Converter disabled 
      

		movlw	 0xFF
		movwf	 ADCON1

		movlw	0xFF
		movwf	TRISB  
		
		movlw	b'00111011'
		movwf	PORTB
; Clear Interrupt flags
    	bcf 	INTCON,INT0IF
		bcf		INTCON3,INT1IF
		bcf		INTCON3,INT2IF
    	bcf		INTCON,RBIF
    
    	bcf 	INTCON2,RBPU

; Enable Interrupts       
    	bsf 	INTCON,INT0IE
		bsf		INTCON3,INT1IE
		bsf		INTCON3,INT2IE
    	bsf		INTCON,RBIE

; Set edges in this case on falling edge 
    	bcf 	INTCON2,INTEDG0
    	bcf		INTCON2,INTEDG1
		bcf		INTCON2,INTEDG2

; Interrupt priority of int1 / 2 needs to be configured 

    	bsf 	INTCON,GIEH  
		bsf 	INTCON,GIEL 
		bsf		INTCON,GIE
      
		bsf 	RCON,IPEN ; Enables Priorities 

; Setting Priority high for INT1, INT2 
		bsf		INTCON3,INT2IP
		bsf		INTCON3,INT1IP
    	bsf		INTCON2,RBIP ; Low Priority for interrupt on change

		
		;
		;movlw b'11111000'
		;movwf INTCON
		;

		return

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



tmr_delay:
		;start timer 0 for pausing
		movlw 0xF7
		movwf TMR0H
		movlw 0x70 ; 0xC0 ; 0x52
		movwf TMR0L
		bsf T0CON,TMR0ON
		call delay_loop
		return

pwm_delay:
		;load timer 0 for half bit
		movlw 0xF7
		movwf TMR0H
		movlw 0x70 ; 0xC0 ; 0x52
		movwf TMR0L
		;load timer 2 for pwm
		movlw 0x00
		movwf TMR2
		bsf LATC,1 ;set first pulse manually

		bsf T0CON,TMR0ON
		bsf T2CON,TMR2ON

		call delay_loop

		return

;wait for interrupt to end half bit
delay_loop:
		btfss tmr_done,0
		bra delay_loop
		bcf tmr_done,0
		return
		

send_1:
		call tmr_delay
		call pwm_delay
		return

send_0:
		call pwm_delay
		call tmr_delay
		return






;Start of main program
; The main program code is placed here.

Main:
		; configure port c
		clrf PORTC
		clrf LATC
		movlw b'11111101'
		movwf TRISC
		;call Init
		call init_portb
		call init_ports
		
		bsf LATC,1
		
		; configure pwm module
		banksel PR2
		movlw 0x46			; configure period time with 0x44
		movwf PR2

		movlw b'00010101' ;b'00000100'	; configure duty cycle with 0x11
		movwf CCPR2L
		movlw b'00001100' ;b'00011100'	; configure pwm mode and 2 lsbs of duty cycle
		movwf CCP2CON
		
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
		bcf INTCON2,TMR0IP ;high priority interrupt
		bsf INTCON,GIE ;general interrupt enable

		movlw 0x00
		movwf reset_timers

		movlw 0x00
		movwf send

;wait_loop
;		btfss send,0
;		bra wait_loop

		
		movlw 0xF7
		movwf TMR0H
		movlw 0x70 ; 0xC0 ; 0x52
		movwf TMR0L
		;load timer 2 for pwm
		movlw 0x00
		movwf TMR2

		bsf LATC,1
		nop
		nop
		nop


wait_cmd_loop
		
		bcf OSCCON,IDLEN
		sleep

		nop
		nop
		nop

		; start timers
;		movlw 0xF7
;		movwf TMR0H
;		movlw 0x52
;		movwf TMR0L
;		bsf T0CON,TMR0ON
;		bsf T2CON,TMR2ON
;
;send_loop
;		btfss reset_timers,0
;		bra send_loop

		
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110101'
		movwf bit_buffer_l

		movlw d'14'
		movwf bit_ctr
		movlw 0x00
		movwf rev_bit_ctr

		movlw d'1'
		movwf cmd_ctr

		movlw 0x00
		movwf tmr_done


send_cmd_loop
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110101'
		movwf bit_buffer_l
		rlcf bit_buffer_l
		rlcf bit_buffer_h
		rlcf bit_buffer_l
		rlcf bit_buffer_h

;		bcf OSCCON,IDLEN
;		sleep
;		nop
;		nop
;		nop


send_bit_loop

;		sleep
;		nop
;		nop
;		nop		

		rlcf bit_buffer_l
		rlcf bit_buffer_h

		btfss STATUS,C
		call send_0
		btfsc STATUS,C
		call send_1

;
		incf rev_bit_ctr
		
;		bcf OSCCON,IDLEN
;		sleep
;		nop
;		nop
;		nop
;
		
		;call TxNull
		;call TxEins

		decfsz bit_ctr
		bra send_bit_loop

		decfsz cmd_ctr
		bra send_cmd_loop

		bra wait_cmd_loop







;****************************************************************************
; Senden einer 0 (on-off)
TxNull
        call    LichtAn         ;2T
        call    LichtAus        ;2T
        return                  ;2T

;****************************************************************************
; Senden einer 1 (off-on) 
TxEins
        call    LichtAus
        call    LichtAn
        return

;****************************************************************************
; Licht aus  (889 us)
; ca. 13 Takte werden für den Aufruf benötigt
;  889 us -13 us =876 us = 175 Takte x 5
LichtAus

        movlw   D'175'
        movwf   cycl_2
LichtAus2
        nop                     ;1T
        nop                     ;1T
        decfsz  cycl_2,f        ;1T
        goto    LichtAus2       ;2T
        return                  ;2T

;****************************************************************************
; Licht pulsen (889 us)
; ideal: 32 IR Pulse von je 6,944 us mit Pausen von 20,8332 us
; real:  32 Pulse a 7 us mit je 21 us Pause, letzte Pause entfällt (32x7+31*21=875 us)
LichtAn
        ; 1. Puls
        bsf     PORTC,1
        movlw   D'31'           ; 31 weitere Zyklen
        movwf   cycl_1
        nop
        nop
        nop
        nop
        bcf     PORTC,1

        ;31 Zyklen aus Pause und Puls
LichtAn1
        ;Pause
        movlw   D'5'            ;1T
        movwf   cycl_2          ;1T
        nop                     ;1T
        nop                     ;1T
LichtAn2                        ; 4x3T + 1x2T =14T
        decfsz  cycl_2,f        ;1T
        goto    LichtAn2        ;2T
        ;Puls                   ;7T
        bsf     PORTC,1
        nop
        nop
        nop
        nop
        nop
        nop
        bcf     PORTC,1
        decfsz  cycl_1,f        ;1T
        goto    LichtAn1        ;2T

        return 



Init
; ports einstellen
        ;bsf     STATUS, RP0     ; Bank 1
        movlw   B'00111101'     ; RA1 output 
        movwf   TRISA           ; 
        movlw   B'11110000'     ; PortB7..4 input, 3..0 output
        movwf   TRISB
        ;bcf     STATUS, RP0     ; Bank 0
        clrf    PORTA           ; 
        clrf    PORTB           ;

; 16F628 alle Comparatoreingänge auf Digital umschalten
        BSF     CMCON, CM0
        BSF     CMCON, CM1
        BSF     CMCON, CM2

; interrupt on change an PortB RB4..7
;        bsf     STATUS, RP0     ; Bank 1
;        bcf     OPTION_REG, 7   ; pull up an
;        bcf     STATUS, RP0     ; Bank 0
;        clrf    INTCON          ; GIE aus
;        bsf     INTCON, RBIE    ; RBIF kann wecken 
		return


;******************************************************************************
;End of program
	goto $
		END
