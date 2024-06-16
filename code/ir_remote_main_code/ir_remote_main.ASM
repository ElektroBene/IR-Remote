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

;******************************************************************************
;Variable definitions
; These variables are only needed if low priority interrupts are used. 
; More variables may be needed to store other special function registers used
; in the interrupt routines.

		bit_buffer_h equ 0x00
		bit_buffer_l equ 0x01
		bit_buffer_toggle equ 0x02
		
		bit_ctr equ 0x10

		command_ctr equ 0x11

		tmr_done equ 0x12
		

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

		ORG 0x0018
		
		bra LowInt

;******************************************************************************
;High priority interrupt routine
; The high priority interrupt code is placed here to avoid conflicting with
; the low priority interrupt vector.

HighInt:
		; toggle bit
		btg bit_buffer_toggle,0
		; test interrupt flags to identify pressed button
		btfsc INTCON,RBIF	; pin 4/5 pressed
		call send_rb_on_change
		btfsc INTCON,INT0IF	; pin 0 pressed
		call send_rb_0
		btfsc INTCON,INT1IF	; pin 1 pressed
		call send_rb_1
		btfsc INTCON,INT2IF	; pin 2 pressed
		call send_rb_2

		retfie	FAST

send_rb_on_change:
		; check if pin 4 or 5 was pressed
		btfsc PORTB,4
		call send_rb_4
		btfsc PORTB,5
		call send_rb_5
		bcf INTCON,RBIF
		return

send_rb_0:					; send stop command
		movlw b'00110101'
		movwf bit_buffer_h
		btfsc bit_buffer_toggle ; set toggle bit in bit buffer
		bsf bit_buffer_h,3
		movlw b'00110110'
		movwf bit_buffer_l
		bcf INTCON,INT0IF
		return

send_rb_1:					; send forward command
		movlw b'00110101'
		movwf bit_buffer_h
		btfsc bit_buffer_toggle,0 ; set toggle bit in bit buffer
		bsf bit_buffer_h,3
		movlw b'00110100'
		movwf bit_buffer_l
		bcf INTCON,INT1IF
		return

send_rb_2:					; send pause command
		movlw b'00110101'
		movwf bit_buffer_h
		btfsc bit_buffer_toggle ; set toggle bit in bit buffer
		bsf bit_buffer_h,3
		movlw b'00110000'
		movwf bit_buffer_l
		bcf INTCON,INT2IF
		return

send_rb_4:					; send play command
		movlw b'00110101'
		movwf bit_buffer_h
		btfsc bit_buffer_toggle ; set toggle bit in bit buffer
		bsf bit_buffer_h,3
		movlw b'00110101'
		movwf bit_buffer_l
		return

send_rb_5:					; send backward command
		movlw b'00110101'
		movwf bit_buffer_h
		btfsc bit_buffer_toggle ; set toggle bit in bit buffer
		bsf bit_buffer_h,3
		movlw b'00110010'
		movwf bit_buffer_l
		return

;******************************************************************************
;Low priority interrupt routine

LowInt:
		
		; stop timers
		bcf T0CON,TMR0ON
		bcf T2CON,TMR2ON
		
		bcf INTCON,TMR0IF

		; stop flag for delay loop
		bsf tmr_done,0

		retfie


;******************************************************************************
;Interrupt configuration routines
init_portb:
		; Routine f r INT0- INT2 
		clrf	 PORTB      
     
		bcf    ADCON0,ADON ; AD Converter disabled 
      
		movlw	0xFF
		movwf	TRISB  

		movlw	 0xFF
		movwf	 ADCON1
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
      
		bsf 	RCON,IPEN ; Enables Priorities 

; Setting Priority high for INT1, INT2 
		bsf		INTCON3,INT2IP
		bsf		INTCON3,INT1IP
    	bsf		INTCON2,RBIP ; Low Priority for interrupt on change

		return

;******************************************************************************
; Output configuration routines

init_portc:
		; configure port c
		clrf PORTC
		clrf LATC
		clrf TRISC
		return

init_tmr:
		; configure pwm module
		banksel PR2
		movlw 0x44			; configure period time with 0x44
		movwf PR2

		movlw b'00000101' ;b'00000100'	; configure duty cycle with 0x11
		movwf CCPR2L
		movlw b'00101100' ;b'00011100'	; configure pwm mode and 2 lsbs of duty cycle
		movwf CCP2CON

		movlw b'00000000'
		movwf T2CON

		; configure timer 0 for delay
		movlw b'00001000'
		movwf T0CON
	
		bcf INTCON,TMR0IF ;interrupt flag
		bsf INTCON,TMR0IE ;interrupt enable
		bcf INTCON2,TMR0IP ;low priority interrupt
		bsf INTCON,GIE ;general interrupt enable

		;movlw 0x00
		;movwf tmr_done		

		return

init_i_o:
		; configure all remaining ports as inputs for sleep mode
		clrf 	PORTA
		movlw	0xFF
		movwf	TRISA
		clrf 	PORTD
		movlw	0xFF
		movwf	TRISD
		return


;******************************************************************************
; Helper sender routines
tmr_delay:
		;start timer 0 for pausing
		movlw 0xFF ; 0xF7
		movwf TMR0H
		movlw 0x52
		movwf TMR0L
		bsf T0CON,TMR0ON
		call delay_loop
		return

pwm_delay:
		;load timer 0 for half bit
		movlw 0xFF ; 0xF7
		movwf TMR0H
		movlw 0x52
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
		

send_0:
		call tmr_delay
		call pwm_delay
		return

send_1:
		call pwm_delay
		call tmr_delay
		return

;******************************************************************************
; Main sender routine

send_command:
		;skip first two bits
		rlcf bit_buffer_l
		rlcf bit_buffer_h
		rlcf bit_buffer_l
		rlcf bit_buffer_h
		;init bit counter
		movlw d'14'
		movwf bit_ctr
		goto send_bit
		return

send_bit:
		rlcf bit_buffer_l
		rlcf bit_buffer_h
		btfss STATUS,C
		call send_0
		call send_1
		decfsz bit_ctr
		bra send_bit
		return


;******************************************************************************
;Start of main program
; The main program code is placed here.

Main:
		call init_portb
		call init_portc
		call init_tmr
		call init_i_o

		; temp: send command 256 times
		movlw 0xFF
		movwf command_ctr
		movlw 0x00
		movwf bit_buffer_toggle

		bcf OSCCON,IDLEN
go_to_sleep
		sleep
		nop
		call send_command
		decfsz command_ctr
		bra go_to_sleep




;******************************************************************************
;End of program
	goto $
		END
