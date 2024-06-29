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

		send_buffer equ 0x08

		save_port_b equ 0x09
		skip_release equ 0x0A
		bit_buffer_toggle equ 0x0B
		bit_buffer_h_tmp equ 0x0C
		bit_buffer_l_tmp equ 0x0D
		rand_delay_ctr equ 0x0E
		rand_delay_ctr_outer equ 0x0F
	
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

;	*** high priority interrupt code goes here **

		call interrupt_routine

		bcf INTCON,INT0IF
		bcf INTCON3,INT1IF
		bcf INTCON3,INT2IF
		bcf INTCON,RBIF

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

interrupt_routine:

		bsf send,0

		; test interrupt flags to identify pressed button
		btfsc INTCON,RBIF	; pin 4/5 pressed
		call send_rb_on_change
		btfsc INTCON,INT0IF	; pin 0 pressed
		call send_rb_0
		btfsc INTCON3,INT1IF	; pin 1 pressed
		call send_rb_1
		btfsc INTCON3,INT2IF	; pin 2 pressed
		call send_rb_2

		return


send_rb_on_change:
		btg skip_release,0
		bcf INTCON,RBIF
		; check if pin 4 or 5 was pressed
		btfss PORTB,4
		call send_rb_4
		btfss PORTB,5
		call send_rb_5
		return
send_rb_0:					; send stop command
		bsf skip_release,0
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110110'
		movwf bit_buffer_l
		bcf INTCON,INT0IF
		bsf send_buffer,0
		return
send_rb_1:					; send forward command
		bsf skip_release,0
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110100'
		movwf bit_buffer_l
		bcf INTCON,INT1IF
		bsf send_buffer,1
		return
send_rb_2:					; send pause command
		bsf skip_release,0
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110000'
		movwf bit_buffer_l
		bcf INTCON,INT2IF
		bsf send_buffer,2
		return
send_rb_4:					; send play command -> standby?
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00001100'
		movwf bit_buffer_l
		bsf send_buffer,4
		return

send_rb_5:					; send backward command
		movlw b'00110101'
		movwf bit_buffer_h
		movlw b'00110010'
		movwf bit_buffer_l
		bsf send_buffer,5
		return


;******************************************************************************

init_portc:
		; configure port c
		clrf PORTC
		clrf LATC
		movlw b'11111101'
		movwf TRISC
		return
		

init_portb:
		; Routine f r INT0- INT2
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

init_pwm:
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
		return



;******************************************************************************

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
		call init_portc
		call init_portb
		call init_ports
		call init_pwm

		movlw 0x00
		movwf reset_timers

		movlw 0x00
		movwf send

		clrf bit_buffer_toggle


		
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


		movlw 0x00
		movwf send_buffer

skip_cmd
		; send when rb4 or rb5 pressed, skip when released
		movlw 0x00
		movwf skip_release
		
		; toggle because it was toggled with button off falsely
		;btg bit_buffer_toggle,0


wait_cmd_loop
		
		bcf OSCCON,IDLEN
		sleep

		nop
		nop
		nop

		movlw d'14'
		movwf bit_ctr
		movlw 0x00
		movwf rev_bit_ctr

		movlw d'1'
		movwf cmd_ctr

		movlw 0x00
		movwf tmr_done

		; skip second command when button is released at rb4 and rb5 (-> interrupt on change, not on edge)
		btfss skip_release,0
		bra skip_cmd


send_cmd_loop

		; set toggle bit in bit_buffer
		btg bit_buffer_toggle,0
		btfsc bit_buffer_toggle,0
		bsf bit_buffer_h,3
		btfss bit_buffer_toggle,0
		bcf bit_buffer_h,3
		
		; send bit buffer from temporary constants to keep value
		movf bit_buffer_h,W
		movwf bit_buffer_h_tmp
		movf bit_buffer_l,W
		movwf bit_buffer_l_tmp

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp
		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp


send_bit_loop		

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp

		btfss STATUS,C
		call send_0
		btfsc STATUS,C
		call send_1


		decfsz bit_ctr
		bra send_bit_loop

		decfsz cmd_ctr
		bra send_cmd_loop ; not working

		movlw d'14'
		movwf bit_ctr
		clrf tmr_done

		movlw 0xFF
		movwf rand_delay_ctr
		movlw 0x40
		movwf rand_delay_ctr_outer

; little delay until command is sent again (9 ms)
wait_rand_delay_outer
wait_rand_delay
		nop
		nop
		decfsz rand_delay_ctr
		bra wait_rand_delay
		decfsz rand_delay_ctr_outer
		bra wait_rand_delay_outer

; send command again
		movf bit_buffer_h,W
		movwf bit_buffer_h_tmp
		movf bit_buffer_l,W
		movwf bit_buffer_l_tmp

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp
		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp

send_bit_loop_2

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp
		
		btfss STATUS,C
		call send_0
		btfsc STATUS,C
		call send_1

		decfsz bit_ctr
		bra send_bit_loop_2

		movlw d'14'
		movwf bit_ctr
		clrf tmr_done

		movlw 0xFF
		movwf rand_delay_ctr
		movlw 0x40
		movwf rand_delay_ctr_outer

; little delay until command is sent again (9 ms)
wait_rand_delay_outer_3
wait_rand_delay_3
		nop
		nop
		decfsz rand_delay_ctr
		bra wait_rand_delay_3
		decfsz rand_delay_ctr_outer
		bra wait_rand_delay_outer_3

; send command again
		movf bit_buffer_h,W
		movwf bit_buffer_h_tmp
		movf bit_buffer_l,W
		movwf bit_buffer_l_tmp

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp
		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp

send_bit_loop_3

		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp
		
		btfss STATUS,C
		call send_0
		btfsc STATUS,C
		call send_1

		decfsz bit_ctr
		bra send_bit_loop_3


		; go to sleep after sending 3 commands
		bra wait_cmd_loop



;******************************************************************************
;End of program
	goto $
		END