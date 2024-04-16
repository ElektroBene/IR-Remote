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
    CONFIG	OSC = HS   ; XT 

;******************************************************************************
;Variable definitions
buffer_send_h	equ		0x08
buffer_send_l	equ		0x09
bit_counter		equ		0x10
delay_pulse_counter	equ	0x11
inner_count		equ		0x12
outer_count		equ		0x13
pulse_delay_count equ	0x14
pulse_count		equ		0x15
pulse_pause_count equ	0x16

time_counter	equ		0x20

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


		retfie	FAST

;******************************************************************************
;Delay routines
delay_half_bit
	movlw d'10'
	movwf outer_count
outer_delay
	movlw d'21'
	movwf inner_count
inner_delay
	nop
	decfsz inner_count
	bra inner_delay
	decfsz outer_count
	bra outer_delay
	nop
	;nop
	;nop
	;nop
	return

delay_pulse
	nop
	nop
	;nop
	return

delay_pause
	movlw d'4'
	movwf pulse_pause_count
delay_pause_loop
	decfsz pulse_pause_count
	bra delay_pause_loop
	return

;******************************************************************************
;Send routines
send_half_bit
	movlw d'32'		; count 32 pulses for half bit
	movwf pulse_count
send_pulse_on
	bsf LATC,0
	movlw d'3'		; count 3 pauses between pulses
	movwf pulse_pause_count
	call delay_pulse
send_pulse_off
	bcf LATC,0
	nop
	nop
	nop
	decfsz pulse_pause_count
	bra send_pulse_off
	decfsz pulse_count
	bra send_pulse_on
	return

send_half_bit_2
	movlw d'32'		; count 32 pulses for half bit
	movwf pulse_count
send_pulse_on_2
	bsf LATC,0
	call delay_pulse
	bcf LATC,0
	call delay_pause
	decfsz pulse_count
	bra send_pulse_on_2
	return

send_low
	bcf LATC,0
	call delay_half_bit
	call send_half_bit

send_high
	call send_half_bit_2
 	bcf LATC,0
	call delay_half_bit

send_buffer
	movlw d'14'
	movwf bit_counter
	
	rlcf buffer_send_l	; skip first 2 bits
	rlcf buffer_send_h
	rlcf buffer_send_l
	rlcf buffer_send_h
send_next_bit
	rlcf buffer_send_l	; rotate next bit in carry
	rlcf buffer_send_h
	btfss STATUS,C		; test carry to send 0 or 1
	call send_low
	call send_high
	decfsz bit_counter
	bra send_next_bit
	return

;******************************************************************************
;Start of main program
; The main program code is placed here.

Main:
;configure port c as output port
	clrf PORTC			; initialize PORTB by clearing output data latches
	movlw 0Fh			; set RB as digital I/O pins
	movwf ADCON1
	movlw b'00000000'	; configure output and input pins at portc
	movwf TRISC

; temporary: set output buffer
	movlw b'00110100'
	movwf buffer_send_h
	movlw b'01110101'
	movwf buffer_send_l

; send bits
call send_buffer


;******************************************************************************
;End of program
	goto $
		END
