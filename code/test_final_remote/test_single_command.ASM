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

		#define timer_0_h 0x08
		#define timer_0_l 0x09


	
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

		
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110101'
		movwf bit_buffer_l


		return

; configure port b as input port
init_port_b:
		; Routine f r INT0- INT2
		clrf PORTB
		clrf LATB
     
		bcf    ADCON0,ADON 		; disable ad converter
      

		movlw	 0xFF
		movwf	 ADCON1

		movlw	0xFF
		movwf	TRISB  
		
		movlw	b'00111011'
		movwf	PORTB

; clear interrupt flags for interrupts 0,1,2 and port b on change interrupts
    	bcf 	INTCON,INT0IF
		bcf		INTCON3,INT1IF
		bcf		INTCON3,INT2IF
    	bcf		INTCON,RBIF
    
    	bcf 	INTCON2,RBPU

; enable interrupts 0,1,2 and on change interrupts       
    	bsf 	INTCON,INT0IE
		bsf		INTCON3,INT1IE
		bsf		INTCON3,INT2IE
    	bsf		INTCON,RBIE

; set edges for interrupts 0,1,2 to falling edge 
    	bcf 	INTCON2,INTEDG0
    	bcf		INTCON2,INTEDG1
		bcf		INTCON2,INTEDG2

; configure interrupt priority for interrupt 0,1,2 to high priority

    	bsf 	INTCON,GIEH  
		bsf 	INTCON,GIEL 
		bsf		INTCON,GIE
      
		bsf 	RCON,IPEN 		; enable priorities 

; set high priority for INT1, INT2 -> int0????????????????????????????????????????????????????????????????????????????
		bsf		INTCON3,INT2IP
		bsf		INTCON3,INT1IP
    	bsf		INTCON2,RBIP ; Low Priority for interrupt on change

		return

; configure ports a, b and d as digital inputs
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

; configure port c with RC1 as output pin
init_port_c:
		; configure port c
		clrf PORTC
		clrf LATC
		movlw b'11111101'
		movwf TRISC
		return

; configure pwm module and timer 2 to be able to send bits
init_pwm:
		; configure pwm module with timer 2
		banksel PR2
		movlw 0x46			; configure period time with 0x44
		movwf PR2

		movlw b'00010101'		; configure duty cycle to be between 1/4 and 1/3 of the whole cycle
		movwf CCPR2L
		movlw b'00001100'		; activate pwm mode and configure 2 lsbs of duty cycle
		movwf CCP2CON
		
		;bcf PIR1,TMR2IF			; reset interrupt flag for timer 2
		bcf T2CON,T2CKPS1		; configure timer 2 prescaler for cycle calculation
		bcf T2CON,T2CKPS0
		
		; start timer 0 for half bit
		movlw b'00001000'
		movwf T0CON
		bcf INTCON,TMR0IF 		; reset interrupt flag for timer 0
		bsf INTCON,TMR0IE 		; enable timer 0 interrupt on overflow
		bcf INTCON2,TMR0IP 		; set timer 0 interrupt priority to high interrupt
		bsf INTCON,GIE 			; enable general interrupt register

		movlw 0x00
		movwf reset_timers
		
;		; preload timer values
;		movlw 0xF7
;		movwf TMR0H
;		movlw 0x70
;		movwf TMR0L
;		;load timer 2 for pwm
;		movlw 0x00
;		movwf TMR2
		movlw 0xF7
		movwf timer_0_h
		movlw 0x70
		movwf timer_0_l

		return


; start delay with 889 us pause which indicates the half of a bit without any signal
tmr_delay:
		;start timer 0 for pausing
		movlw tmr_0_h
		movwf TMR0H
		movlw tmr_0_l
		movwf TMR0L
		bsf T0CON,TMR0ON
		call delay_loop
		return

; start delay with 889 us of rectangle signal which indicates the half of a bit with 32 pulses
pwm_delay:
		;load timer 0 for half bit
		movlw tmr_0_h
		movwf TMR0H
		movlw tmr_0_l
		movwf TMR0L
		;load timer 2 for pwm
		movlw 0x00
		movwf TMR2
		bsf LATC,1 		; set first pulse manually

		bsf T0CON,TMR0ON
		bsf T2CON,TMR2ON

		call delay_loop

		return

; wait for timer 0 interrupt to end half bit by seting timer_done<0>
delay_loop:
		btfss tmr_done,0
		bra delay_loop
		bcf tmr_done,0
		return
		
; send logic 1 by first sending 889 us delay, then 889us of 32 pulses with frequency of 36 kHz
send_1:
		call tmr_delay
		call pwm_delay
		return

; send logic 0 by first sending 889us of 32 pulses with frequency of 36 kHz, then 889us delay
send_0:
		call pwm_delay
		call tmr_delay
		return






;Start of main program
; The main program code is placed here.

Main:
		call init_port_c
		call init_port_b
		call init_ports
		call init_port_c
		
		
		bsf LATC,1
		nop
		nop
		nop


wait_cmd_loop
		; go to sleep mode
		bcf OSCCON,IDLEN
		sleep
		nop
		nop
		nop
		
		; counter to count 14 bits
		movlw d'14'
		movwf bit_ctr

		; counter to send command multiple times
		movlw d'1'
		movwf cmd_ctr

		movlw 0x00
		movwf tmr_done


send_cmd_loop
		; skip 2 msbs of bit command because only 14 bits are used
		rlcf bit_buffer_l
		rlcf bit_buffer_h
		rlcf bit_buffer_l
		rlcf bit_buffer_h

send_bit_loop	
		; put next bit in carry bit
		rlcf bit_buffer_l
		rlcf bit_buffer_h

		; test bit to see if logic 0 or logic 1 needs to be sent
		btfss STATUS,C		; is next bit logic 0?
		call send_0			; yes
		btfsc STATUS,C		; no, is next bit logic 1?
		call send_1			; yes

		; go to next bit
		decfsz bit_ctr		; no, are all bits sent?
		bra send_bit_loop	; no, send next bit

		; send command multiple times
		decfsz cmd_ctr		; yes, is the command sent enough times?
		bra send_cmd_loop	; no, send the command again

		; wait for next bit
		bra wait_cmd_loop	; yes, go to sleep and wait for next command




;******************************************************************************
;End of program
	goto $
		END
