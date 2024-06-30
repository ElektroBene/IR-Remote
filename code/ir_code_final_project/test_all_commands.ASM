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

	LIST P=18F4525			; directive to define processor
	#include "P18F4525.INC"	; processor specific variable definitions

;******************************************************************************
;Configuration bits

;   Oscillator Selection:
    CONFIG OSC = HS			; set oscillator mode to high-speed crystal with
    						; external 10 MHz quartz
    CONFIG WDT = OFF		; disable watchdog timer
    CONFIG LVP = OFF		; disable low voltage programming, because MPLAB
    						; ICD 3 can do high voltage programming

;******************************************************************************
;Variable definitions

		bit_buffer_h 			equ 	0x00	; hold bits 13-8 of command
		bit_buffer_l 			equ 	0x01	; hold bits 7-0 of command
		bit_ctr 				equ 	0x02	; count 14 bits while sending
		tmr_done 				equ 	0x03	; signal that half bit is finished
		cmd_ctr 				equ 	0x04	; count times of sending command
		skip_release 			equ 	0x05	; decide between falling and rising edge at rb 4/5
		bit_buffer_toggle 		equ 	0x06	; toggle 3rd sent bit
		bit_buffer_h_tmp 		equ 	0x07	; hold bits 13-8 of command while sending
		bit_buffer_l_tmp 		equ 	0x08	; hold bits 7-0 of command while sending
		rand_delay_ctr 			equ 	0x09	; count during inner delay loop between commands
		rand_delay_ctr_outer 	equ 	0x0A	; count during outer delay loop between commands
	
;******************************************************************************
;EEPROM data

		ORG	0xf00000

		DE	"Test Data",0,1,2,3,4,5

;******************************************************************************
;Reset vector

		ORG	0x0000

		goto	Main		; go to start of main code

;******************************************************************************
;High priority interrupt vector

		ORG	0x0008

		bra	HighInt			; go to high priority interrupt routine	

;******************************************************************************
;High priority interrupt routine

HighInt:

		call interrupt_routine		; read pressed button and put the right
									; command in bit buffer to send it

                ; deleted lower commands because already in code in routines 
		;bcf INTCON,INT0IF			; clear interrupt flags for pins rb
		;bcf INTCON3,INT1IF			; 0/1/2/4/5 to prevent getting multiple
		;bcf INTCON3,INT2IF			; interrupts with one button press
		;bcf INTCON,RBIF

		retfie	FAST 			
							; pops the contents of the program counter 
							;previously pushed before going to the service routine, enables all interrupts, 
							; and returns control to the appropriate place in the main program. 

;******************************************************************************
;Low priority interrupt vector

		ORG	0x0018

		bra	LowInt			; go to high priority interrupt routine	

;******************************************************************************
;Low priority interrupt routine

LowInt:

		bcf T0CON,TMR0ON	; stop timers 0 and 2 which are used for pwm pulses
		bcf T2CON,TMR2ON	; and do not need to be used after sending these
							; pulses is finished

		bcf INTCON,TMR0IF	; clear interrupt flag of timer 0 which triggers
							; the low interrupt, clearing prevents multiple
							; interrupts for one overflow event

		bsf tmr_done,0

		retfie	FAST

;******************************************************************************

interrupt_routine:

		; test interrupt flags to identify pressed button
		btfsc INTCON,RBIF		; pin 4/5 pressed
		call send_rb_on_change
		btfsc INTCON,INT0IF		; pin 0 pressed
		call send_rb_0
		btfsc INTCON3,INT1IF	; pin 1 pressed
		call send_rb_1
		btfsc INTCON3,INT2IF	; pin 2 pressed
		call send_rb_2

		return

; handle pressing pin 4 or 5, because both pins trigger on change interrupt
send_rb_on_change:
		btg skip_release,0	; toggle skip_release flag to prevent sending
							; commands twice (by pressing and releasing
							; button), command is skipped when skip_release<0>
							; is '0'
		bcf INTCON,RBIF		; clear interrupt flag to prevent multiple
							; interrupts
		btfss PORTB,4		; check if pin 4 was pressed
		call send_rb_4
		btfss PORTB,5		; check if pin 5 was pressed
		call send_rb_5
		return

; send stop command with pin RB0
send_rb_0:
		bsf skip_release,0	; set skip_release<0> to prevent skipping this
							; command
		movlw b'00110101'	; move rc5 code for stop command to bit buffer
		movwf bit_buffer_h
		movlw b'00110110'
		movwf bit_buffer_l
		bcf INTCON,INT0IF	; clear interrupt flag to prevent multiple
							; interrupts
		return

; send forward command with pin RB1
send_rb_1:
		bsf skip_release,0	; set skip_release<0> to prevent skipping this
							; command
		movlw b'00110101'	; move rc5 code for forward command to bit buffer
		movwf bit_buffer_h
		movlw b'00110100'
		movwf bit_buffer_l
		bcf INTCON,INT1IF	; clear interrupt flag to prevent multiple
							; interrupts
		return

; send pause command with pin RB2
send_rb_2:
		bsf skip_release,0	; set skip_release<0> to prevent skipping this
							; command
		movlw b'00110101'	; move rc5 code for pause command to bit buffer
		movwf bit_buffer_h
		movlw b'00110000'
		movwf bit_buffer_l
		bcf INTCON,INT2IF	; clear interrupt flag to prevent multiple
							; interrupts
		return
		
; send play command with pin RB4
send_rb_4:
		movlw b'00110101'	; move rc5 code for play command to bit buffer
		movwf bit_buffer_h
		movlw b'00001100'
		movwf bit_buffer_l
		return

; send backward command
send_rb_5:
		movlw b'00110101'	; move rc5 code for backward command to bit buffer
		movwf bit_buffer_h
		movlw b'00110010'
		movwf bit_buffer_l
		return


;******************************************************************************
;Initialization routines

; configure port c
init_portc:
		clrf PORTC			; reset port c and its latch
		clrf LATC
		movlw b'11111101'	; set pin RC1 to be output, all other RC pins to be
		movwf TRISC			; inputs
		return
		
; configure port b as input with interrupts
init_portb:
		clrf PORTB			; reset port b and its latch
		clrf LATB
     
		bcf ADCON0,ADON		; disable ad converter and reset its configuration
		movlw 0xFF			; bits
		movwf ADCON1

		movlw 0xFF			; set all port b pins as inputs
		movwf TRISB
		
		movlw b'00111011'	; set pins with buttons to '1' to prevent
		movwf PORTB			; triggering interrupt because buttons create
							; high state as default (active low buttons)

    		bcf 	INTCON,INT0IF	; clear interrupt flags for pins rb
		bcf	INTCON3,INT1IF	; 0/1/2/4/5 to prevent getting multiple
		bcf	INTCON3,INT2IF	; interrupts with one button press
    		bcf	INTCON,RBIF
    
    		bcf 	INTCON2,RBPU	; activate internal weak pull-ups for all pins
    						; on port b

    		bsf 	INTCON,INT0IE	; enable interrupts for interrupt 0/1/2 and
		bsf	INTCON3,INT1IE	; on change interrupts on port b
		bsf	INTCON3,INT2IE
    		bsf	INTCON,RBIE

    		bcf 	INTCON2,INTEDG0	; set interrupts 0/1/2 to trigger on falling 
    		bcf	INTCON2,INTEDG1	; edge
		bcf	INTCON2,INTEDG2

    		bsf 	INTCON,GIEH		; activate all high priority interrupts	
		bsf 	INTCON,GIEL 	; activate all low priority interrupts
		bsf	INTCON,GIE		; activate all interrupts
      
		bsf 	RCON,IPEN		; enable interrupt priorities 

		bsf	INTCON3,INT1IP	; set interrupt priority for interrupts 1/2
		bsf	INTCON3,INT2IP	; and on change interrupt to high priority
    		bsf	INTCON2,RBIP

		return

; configure ports a and d as inputs, routines are taken from pic18f4525 manual
init_ports
		clrf PORTA 		; initialize port a by clearing output data latches
		clrf LATA
		movlw 0x07 		; configure A/D for digital inputs
		movwf ADCON1
		movlw 0x07 		; configure comparators for digital input
		movwf CMCON
		movlw 0xFF 		; initialize data direction for all pins as output
		movwf TRISA		
		
		clrf PORTD		; initialize port d by clearing output data latches
		clrf LATD
		movlw 0FFh 		; initialize data direction for all pins as output
		movwf TRISD
		
		return

; configure pwm module
init_pwm:
		banksel PR2
		movlw 0x46			; configure period time with 0x46 for 36 kHz frequency
		movwf PR2

		movlw b'00010101' 	; configure duty cycle to be between 1/3 and 1/4 of
		movwf CCPR2L		; the whole signal
		movlw b'00001100' 	; configure pwm mode and 2 lsbs of duty cycle
		movwf CCP2CON
		
		bcf PIR1,TMR2IF		; clear interrupt flag to prevent multiple
							; interrupts
		bcf T2CON,T2CKPS1	; set timer 2 clock prescaler value to '00'
		bcf T2CON,T2CKPS0

		movlw b'00001000'	; configure timer 0 with 16 bit, internal clock
		movwf T0CON			; and prescaler value of '000'
		movlw 0xF7			; set start value for timer 0
		movwf TMR0H
		movlw 0x52
		movwf TMR0L
		bcf INTCON,TMR0IF 	; clear interrupt flag to prevent multiple
							; interrupts
		bsf INTCON,TMR0IE 	; enable timer 0 interrupt
		bcf INTCON2,TMR0IP 	; set interrupt priority to high
		bsf INTCON,GIE 		; enable all interrupts
		return



;******************************************************************************
;Sending routines

; start half bit with low state by waiting for 889 us
tmr_delay:
		;start timer 0 for pausing
		movlw 0xF7			; set start value for timer 0 which counts to overflow
		movwf TMR0H
		movlw 0x70
		movwf TMR0L
		bsf T0CON,TMR0ON	; start timer 0
		call delay_loop		; wait for timer 0 low interrupt
		return

; start half bit with rectangle signal by running pwm for 889 us
pwm_delay:
		movlw 0xF7			; set start value for timer 0 which counts to overflow
		movwf TMR0H
		movlw 0x70
		movwf TMR0L
		movlw 0x00			; set start value for timer 2 which counts for each pulse
		movwf TMR2
		bsf LATC,1 			; set first pulse manually

		bsf T0CON,TMR0ON	; start timer 0 for 889 us delay and timer 2 for pwm
		bsf T2CON,TMR2ON

		call delay_loop		; wait for timer 0 low interrupt

		return

;wait for timer 0 interrupt to end half bit
delay_loop:
		btfss tmr_done,0
		bra delay_loop
		bcf tmr_done,0
		return
		
; send logic '1' by first sending 889 us delay and then 32 pwm pulses
send_1:
		call tmr_delay
		call pwm_delay
		return

; send logic '0' by first sending 32 pwm pulses and then 889 us delay
send_0:
		call pwm_delay
		call tmr_delay
		return


;******************************************************************************

;Start of main program

Main:
		call init_portc		; configure ports and pwm module
		call init_portb
		call init_ports
		call init_pwm

		clrf bit_buffer_toggle

skip_cmd
		; send when rb4 or rb5 pressed, skip when released
		movlw 0x00
		movwf skip_release


wait_cmd_loop
		
		bcf OSCCON,IDLEN	; go to sleep until next button is pressed
		sleep
		nop
		nop
		nop

		movlw d'3'			; send every command 3 times
		movwf cmd_ctr
		
		btfss skip_release,0	; skip second command when button is released
		bra skip_cmd			; at rb4 and rb5 because interrupt is triggered
								; on change, not only on falling edge

		btg bit_buffer_toggle,0		; set toggle bit in bit_buffer
		btfsc bit_buffer_toggle,0
		bsf bit_buffer_h,3
		btfss bit_buffer_toggle,0
		bcf bit_buffer_h,3

send_cmd_loop

		movlw d'14'			; send 14 bits
		movwf bit_ctr

		clrf tmr_done			; reset flag that stops delay loop during sending

		movf bit_buffer_h,W		; send bit buffer from temporary constants to keep value
		movwf bit_buffer_h_tmp
		movf bit_buffer_l,W
		movwf bit_buffer_l_tmp

		rlcf bit_buffer_l_tmp	; skip first 2 bits because only 14 bits hold information
		rlcf bit_buffer_h_tmp
		rlcf bit_buffer_l_tmp
		rlcf bit_buffer_h_tmp


send_bit_loop		

		rlcf bit_buffer_l_tmp	; transfer the next bit that should be sent in carry bit
		rlcf bit_buffer_h_tmp

		btfss STATUS,C			; test carry bit to see if '0' or '1' should be sent
		call send_0
		btfsc STATUS,C
		call send_1

		decfsz bit_ctr			; send next bit if not all bits are sent already
		bra send_bit_loop
		
		movlw 0xFF				; load inner and outer delay counter to create delay
		movwf rand_delay_ctr	; between sending the command multiple times
		movlw 0x40
		movwf rand_delay_ctr_outer

wait_rand_delay_outer			; create delay of around 9 ms
wait_rand_delay
		nop
		nop
		decfsz rand_delay_ctr
		bra wait_rand_delay
		decfsz rand_delay_ctr_outer
		bra wait_rand_delay_outer

		decfsz cmd_ctr			; send command again if it was not sent 3 times already
		bra send_cmd_loop


		bra wait_cmd_loop		; go to sleep after sending 3 commands



;******************************************************************************
;End of program
	goto $
		END
