# MPLAB IDE generated this makefile for use with GNU make.
# Project: ir_remote_main_code.mcp
# Date: Fri Jun 14 13:28:03 2024

AS = MPASMWIN.exe
CC = 
LD = mplink.exe
AR = mplib.exe
RM = rm

ir_remote_main.cof : ir_remote_main.o
	$(CC) /p18F4525 "ir_remote_main.o" /u_DEBUG /u_DEBUGCODESTART=0xbd30 /u_DEBUGCODELEN=0x2d0 /u_DEBUGDATASTART=0xef6 /u_DEBUGDATALEN=0xa /z__MPLAB_BUILD=1 /z__MPLAB_DEBUG=1 /z__MPLAB_DEBUGGER_ICD3=1 /z__ICD2RAM=1 /o"ir_remote_main.cof" /M"ir_remote_main.map" /W /x

ir_remote_main.o : ir_remote_main.ASM P18F4525.INC
	$(AS) /q /p18F4525 "ir_remote_main.ASM" /l"ir_remote_main.lst" /e"ir_remote_main.err" /d__DEBUG=1 /d__MPLAB_DEBUGGER_ICD3=1

clean : 
	$(CC) "ir_remote_main.o" "ir_remote_main.hex" "ir_remote_main.err" "ir_remote_main.lst" "ir_remote_main.cof"

