; *******************************************************************
; ****                                                           ****
; ****           Z80 MINI-EMUF Betriebssystem 05.02              ****
; ****                                                           ****
; ****                  (c) 24.12.2019                           ****
; ****                                                           ****
; *******************************************************************
;
; geschriebnen fÅr den TASM 3.0 Assembler in Z80
; Tabulatorschrittweite : 8
; Tabulatorschrittweite : 8
; Codepage              : 850

.include "ez80f91.inc"
.include "PrintfObj.inc"
.include "FifoObj.inc"
.include "helper.inc"
.include "SerialObj.inc"
.include "LcdObj.inc"
.include "MINI5_2.INC"
.include "Char.inc"
.include "Heap.inc"
.include "RtcObj.inc"
.include "Dcf77Obj.inc"
.include "MqttObj.inc"
.include "config.inc"

xdef Monitor

xref EEPROM

xref Timer1_IV
xref Task_mem_start
xref Task_mem_ende
xref Bezeichner_mem_start
xref Bezeichner_mem_ende
xref Stack_mem_start
xref Stack_mem_ende
xref Kaltstart
xref Version_text
xref Hard_jmp_start
xref Hard_jmp_end
xref BetSysSegStart
xref BetSysSegEnd
xref DataSegStart
xref DataSegEnd

UserSegStart 	.equ 6000h
UserSegEnd		.equ B7FFh

.define MonitorSeg

.define UserSeg,org=UserSegStart
segment UserSeg
.block UserSegEnd-UserSegStart+1
User_mem_ende

.define DataSeg

; ---- Speicheraufteilung ----


Ramtest_start   EQU 4000h
Ramtest_ende    EQU ffffh

; Bereich BF00 bis BFFF : reserviert fÅr Z80mini-EMUF Monitor Version 3.03

; EQUEQUEQUEQU allgemeine Konstaten EQUEQUEQUEQU

LCK_STATUS      EQU %20

; ---- Objektstruktur ----

ClassOffset			 equ 0
SuperClassOffset	 equ 2
MethodsTabOffset     equ 4

; EQUEQUEQUEQU Konstanten des Monitorprogramms EQUEQUEQUEQU

Puffer_len      EQU 78    ; max. LÑnge der Komandozeile ohne 0 am Ende
Stack_max       EQU 16    ; max. angezeigte Anzahl von Stackwîrtern
Promt           EQU '>'
Meld_char       EQU '?'
Md_inp          EQU  1
Md_brk          EQU  2
Md_ueok         EQU  3
Md_abr          EQU  4
Md_uef          EQU  5
Md_mem          EQU  6
Md_ver          EQU  7
Md_baud         EQU  8
Md_datum        EQU  9
Md_var		EQU 11

Ihex_bytes      EQU 20h

Def_arg         EQU 8000h  ; Default-Argument
Def_io          EQU 20h     ; Default I/O-Adresse
Def_fill        EQU ffh       ; Default Fill Wert


; EQUEQUEQUEQU Konstanten des Betriebssytems EQUEQUEQUEQU

Break_char      EQU 03h   ; User-Break Zeichen ( Control C )

Watchdog_adr    EQU f0h
WDTCR           EQU f1h


OscFreqMult		EQU 10
Sysclk			EQU 50000000
WaitStatesRam	EQU 1
Sysint_freq		EQU 50
Def_baudrate    EQU 38400      ; 38400 Baud

WD_mode		EQU 3


PB_DDR_MASK		equ ENC_A|ENC_B|ENC_BUTTON|BUTTON|DCF_77
; EQUEQUEQUEQUEQU Konstanten der Hiflsfunktionen EQUEQUEQUEQU

Pre_bin         EQU '%'   ; Prexif fÅr bin %
Pre_dez         EQU '&'   ; Prexif fÅr dez &
Pre_hex         EQU '$'   ; Prexif fÅr hex $
Pre_asc         EQU 27h   ; Prexic fÅr ASCII '
Pre_bez         EQU '*'   ; Prexic fÅr Bezeichner *

Start_jahr      EQU 1917          ; Jahr auf das sich die Datumsberechnung
				; bezieht, dieses Jahr muss eiem Schaltjahr
				; folgen, kein BCD-Format
Start_tag       EQU 1             ; ( 01.01.1917 war ein Montag )

; ---- Konstanten ----

Brk_opt         EQU ffh   ; Opcode fÅe Breakpoint
Magic           EQU a5h   ; Magic-Code

Lcd_basis	EQU 0100h

; EQUEQUEQUEQU Variablen EQUEQUEQUEQUEQU

segment DataSeg
Sys_mem_start

; ---- Betriebsystemvariabeln ----

Execute_jmp     .block 2 ; Zeiger auf Rutine zur Befehlsausfuehrung

; ---- lokale Variablen ----

Temp		.block 2
Temp1		.block 2
Meldung         .block 1
Heap		.block 2
HeapTemp	.block 2

; ---- Variablen fÅr den Debuger ----

Sys_stack       .block 2

Reg_1

Reg_af          .block 2  ; Prozessor-Register
Reg_bc          .block 2
Reg_de          .block 2
Reg_hl          .block 2
Reg_afs         .block 2
Reg_bcs         .block 2
Reg_des         .block 2
Reg_hls         .block 2
Reg_ix          .block 2
Reg_iy          .block 2
Reg_pc          .block 2
Reg_sp          .block 2

Reg_IFF2        .block 1
Reg_2

Reg_undo        .block Reg_2 - Reg_1 ; Speicher fuer UNDO

Reg_sp_stop     .block 2 ; Register fÅr Debugger
Ret_test        .block 3 ; Register fÅr Debugger
Breakpoint_add  .block 2 ; Parameter fÅr Breakpoint
Breakpoint_opt  .block 1

; ---- Variablen fÅr das Monitorprogramm ----

Kom_puffer      .block Puffer_len  ; Komadozeilen Speicher
Watch_add       .block 2 ; Adresse fÅr Watch
Dump_def        .block 2     ; Default Argumente
Edit_def        .block 2
Call_def        .block 2
Out_def         .block 2
In_def          .block 2
Fill_def        .block 1
Stack_base      .block 2
Prg_start       .block 2

Date			.block 8

; ---- Variablen fÅr die Speicherverwaltung ----

Ihex_in_bc      .block 2
Ihex_in_de      .block 2
Ihex_in_hl      .block 2


; ---- Ende der Variabelen ----

Sysende_p_1    ; Ende des Systemspeichers + 1

Sys_mem_ende    EQU Sysende_p_1-1

; EQUEQUEQUEQU Programtext EQUEQUEQUEQU

segment MonitorSeg
.assume ADL=0

; ********************************************************************
; **		       						    **
; **     Monitor-Programm					    **
; **		       						    **
; ********************************************************************

; ---- Komunikation ----

Monitor	call Monitor_init

Warmstart rst 08h
		.byte Betn_Int_enable

		call Break_clr                  ; Breakpoints lîschen
			

Komun           call Printf  ; Promt ausgeben, Cursor ein
		.byte Cr,Pf_s,Pf_clrs,Promt,Pf_s,Pf_ein,0

		ld hl,Kom_puffer
		ld b,Puffer_len
		rst 08h
		.byte Betn_Line_get
		call Newline
		ld bc,Kom_tab
		call Execute
		jr Komun

; ---- Vergeleichsfunktion ----

HeapCompare
		call Read_hl
		call Read_bc_bc
		call Cmp_hl_bc
		ret
		
; ---- Monitorprogramm initialisieren ----

Monitor_init    
		push af
		push hl

		call Reg_save
		call Reg_dup

		ld hl,Execute_1
		ld (Execute_jmp),hl
		ld hl,Breakpoint
		rst 08h
		.byte Betn_SetUserBreakVektor
		ld hl,Def_arg

		ld (Prg_start),hl
		ld (Reg_pc),hl
		ld (Dump_def),hl
		ld (Edit_def),hl
		ld (Call_def),hl
		ld hl,User_mem_ende
		ld (Reg_sp),hl
		ld (Stack_base),hl
		ld a,Def_io
		ld (In_def),hl
		ld (Out_def),hl
		ld a,Def_fill
		ld (Fill_def),a

		ld hl,0
		ld (Breakpoint_add),hl
		ld (Watch_add),hl

		ld a,1
		ld (Reg_IFF2),a

		ld b,4
		ld c,2
		ld hl,HeapCompare
		call HeapObj
		ld (Heap),hl
		
		pop hl
		pop af

		ret

; ---- Befehl ausfuehren ----
; HL -> Zeiger auf Befehl
; BC -> Zeiger auf Befehlstabelle

Execute         push hl
		ld hl,(Execute_jmp)
		ex (sp),hl
		ret

Execute_1       rst 08h
		.byte Betn_Space_ignore
		call Line_end
		ret c

		rst 08h
		.byte Betn_Kom_add

		jr c,Execute_3

		ld a,Md_inp
		jp Std_meld

Execute_3       push bc   ; Adresse des Befehl -> (SP)
		push hl   ; alle Register ausser HL loeschen
		call Reg_clr
		pop hl
		ret     ; Befehl ausfÅhren

; ---- Tabelle der Komandos ----

Kom_tab .byte "eeprom",0
		.word EEPROM_CMD
		.byte "publish",0
		.word Publish
		.byte "pass",0
		.word Passtrough
		.byte "put", 0
		.word HeapPut
		.byte "get", 0
		.word HeapGet
		.byte "remove",0
		.word HeapRemove
		.byte "alloc", 0
		.word Alloc
		.byte "auto", 0
		.word Auto
		.byte "baud", 0
		.word Baud
		.byte "Befehle", 0
		.word Befehle
		.byte "chks", 0
		.word Chks
		.byte "cls",0
		.word Cls
		.byte "del",0
		.word Del
		.byte "hexdump", 0
		.word Hexdump
		.byte "echo", 0
		.word Echo
		.byte "free", 0
		.word Free
		.byte "load",0
		.word Load
		.byte "mem", 0
		.word Mem
		.byte "pop", 0
		.word Pop
		.byte "prn",0
		.word Print
		.byte "push", 0
		.word Push
		.byte "rclr", 0
		.word Rclr
		.byte "uhr",0
		.word Uhr
		.byte "set", 0
		.word Set
		.byte "shrink", 0
		.word Shrink
		.byte "undo", 0
		.word Undo
		.byte "var", 0
		.word Var
		.byte "watchdog"  ,0
		.word Watchdog
		.byte "b", 0
		.word Set_breakpoint
		.byte "c", 0
		.word User_call
		.byte "dcf",0
		.word DcfCmd
		.byte "d", 0
		.word Dump
		.byte "e", 0
		.word Edit
		.byte "f", 0
		.word Fill
		.byte "g", 0
		.word Go
		.byte "h", 0
		.word Help
		.byte "i", 0
		.word In
		.byte "l", 0
		.word Ihex_load
		.byte "m", 0
		.word Move
		.byte "o", 0
		.word Out
		.byte "p", 0
		.word Ihex_out
		.byte "r", 0
		.word Register
		.byte "s", 0
		.word Step
		.byte "t", 0
		.word Trace
		.byte "u", 0
		.word Until
		.byte "v", 0
		.word Version
		.byte "w", 0
		.word Watch
		.byte "?", 0
		.word Help
		.byte "@", 0
		.word Return
		.byte 0

HeapPut	ld ix,(Heap)
		call Lastw_in
		jp nc,Std_meld
		ld (HeapTemp),de
		ld hl,HeapTemp
		rst 08h
		.byte Betn_Objekt_call
		.byte HeapObj_Put
		ret

HeapGet	ld ix,(Heap)
		ld hl,HeapTemp
		rst 08h
		.byte Betn_Objekt_call
		.byte HeapObj_Get
		ld hl,(HeapTemp)
		call Hl_out
		call Newline
		ret
		
HeapRemove
		ld ix,(Heap)
		call Lastw_in
		jp nc,Std_meld
		ld hl,de
		rst 08h
		.byte Betn_Objekt_call
		.byte HeapObj_Remove
		ret
		
; ---- EEPROM Kommando ----

EEPROM_CMD
		call EEPROM
		jr nc,EEPROM_CMD1
		
		call Printf
		.byte "EEPROM-Test passed",Cr,Lf,0
		
		ret
EEPROM_CMD1
		call Printf
		.byte "EEPROM-Test failed",Cr,Lf,0
		
		ret
		
; ---- Standart - Meldung ausgeben ----

Std_meld        push hl
		call Printf
		.byte Meld_char,' ',0
		call Hexout
		call Space_out
		ld hl,Meld_tab
		rst 08h
		.byte Betn_Meld_out
		call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf,0
		pop hl
		ret

; ---- Tabelle der Meldungen ----

Meld_tab        .byte "OK",0     ; Nr. 0
		.byte "Eingabefehler "   ; Nr. 1 Md_inp
		.byte "( Hilfe mit h )",0
		.byte "Break",0   ; Nr. 2 Md_brk
		.byte "Uebertragung OK",0  ; Nr. 3 Md_ueok
		.byte "Abbruch",0    ; Nr. 4 Md_abr
		.byte "Uebertragungs-Fehler",0 ; Nr. 5 Md_uef
		.byte "Speicherfehler",0   ; Nr. 6 Md_mem
		.byte "falsche Betriebssystemversion",0 ; Nr. 7 Md_ver
		.byte "falsche Baudrate",0 ; Nr. 8 Md_ver
		.byte "Datumsfehler",0 ; Nr. 9 Md_datum
		.byte "Variable nicht definiert",0 ; Nr. 10 Md_var
		.byte 0

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Benutzer - Befehle    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Publish ----

Publish		rst 08h
			.byte Betn_Get_MqttClient
			
			rst 08h
			.byte Betn_Objekt_call
			.byte MqttObj_Connected
			
			jr c,Publish1
			
			push hl
			
			ld hl,BROKER
			
			call Printf
			.byte "Connecting to ",Pf_s,Pf_str," ... ",0
			
			rst 08h
			.byte Betn_Objekt_call
			.byte MqttObj_Connect
			
			pop hl

			jr nc,Publish4
			
			call Printf
			.byte "Connected",Cr,Lf,0
			
Publish1	rst 08h
			.byte Betn_Space_ignore
		
			push hl
Publish2
			ld a,(hl)
			or a
			jr z,Publish3
			inc hl
			call Space_test
			jr nc,Publish2
			
			dec hl
			xor a
			ld (hl),a
			inc hl

			rst 08h
			.byte Betn_Space_ignore
			
Publish3	ld bc,hl

			pop hl
			
			rst 08h
			.byte Betn_Objekt_call
			.byte MqttObj_Publish
			
			ret
			
Publish4
			call Printf
			.byte "failed",Cr,Lf,0
			
			ret
			
; ----- direkete Kommunikation mit dem ESP 01 ----

Passtrough	rst 08h
			.byte Betn_Get_EspOut
Passtrough1
			rst 08h
			.byte Betn_Char_get_non_blocking

			jr nc,Passtrough2
			
			rst 08h
			.byte Betn_Objekt_call
			.byte SerialObj_CharOut
Passtrough2
			rst 08h
			.byte Betn_Objekt_call
			.byte SerialObj_CharIn
			
			jr nc,Passtrough1
			
			rst 08h
			.byte Betn_Char_out
			
			jr Passtrough1

; ---- Autostart-Unterprogramm instalieren ----

Auto    call Lastw_in
		jp nc,Std_meld

		ld hl,de
		rst 08h
		.byte Betn_Set_AutoStart
		ret

; ---- Breakpoint setzen ----

Set_breakpoint  call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		ld (Breakpoint_add),de
		call Monitor_aus

		ret

; ---- Daten-Watch seten ----

Watch           call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		ld (Watch_add),de
		call Monitor_aus

		ret

; ---- letzten User-Register-Ihalt zurueckhohlen ----

Undo            call Line_end
		jp nc,Syntax_err

		ld b,Reg_2-Reg_1
		ld hl,Reg_1
		ld de,Reg_2

Undo_1          ld a,(de)
		ld c,(hl)
		ld (hl),a
		ld a,c
		ld (de),a
		inc hl
		inc de
		djnz Undo_1

		call Monitor_aus

		ret

; ----1 Variablen ausgeben ----

Var:    call Line_end
		jp nc,Syntax_err

		ld hl,Bezeichner_mem_start
		call Var_list

		ret

; ---- Variablen auflisten ----
;
; HL -> Zeiger auf Liste


Var_list        push af
		push hl
		push de

Var_list_1      ld a,(hl)
		or a
		jr z,Var_list_2

		push de
		ld d,h
		ld e,l
		call Pointprn
		ld h,d
		ld l,e
		pop de

		call Space_out

		push hl
		call Read_hl
		call Hl_out
		pop hl

		inc hl
		inc hl

		call Newline

		jr Var_list_1

Var_list_2      pop de
		pop hl
		pop af

		ret


; ---- Varibele defnieren ----

Set:    rst 08h
		.byte Betn_Space_ignore
		
		push hl

		call Bez_read
		call c,Trenn_ignore
		call c,Wort_in
		ld b,d
		ld c,e

		ex (sp),hl

		jr nc,Bez_set_1
		
		rst 08h
		.byte Betn_Bez_set
		
Bez_set_1
		pop hl

		call nc,Std_meld

		ret

; ---- Variable loeschen ----

Del     rst 08h
		.byte Betn_Space_ignore
		ld de,Bezeichner_mem_start
		rst 08h
		.byte Betn_Bez_del
		call nc,Std_meld

		ret


; ---- Alle User-Register loeschen ----

Rclr            call Line_end
		jp nc,Syntax_err

		call Reg_dup
		call Reg_clr
		call Reg_save
		ld hl,(Stack_base)
		ld (Reg_sp),hl
		ld hl,(Prg_start)
		ld (Reg_pc),hl
		ld a,1
		ld (Reg_IFF2),a
		call Monitor_aus
		ret

; ---- Versionsnummer ausgeben ----

Version         call Line_end
		jp nc,Syntax_err

		rst 08h
		.byte Betn_GetStdOut
		rst 08h
		.byte Betn_Objekt_call
		.byte SerialObj_GetBaud 

		call Printf

		.byte Cr,Lf, Pf_s, Pf_str | Pf_nn
		.word Version_text
		.byte Cr,Lf
		.byte Cr,Lf
		.byte "Schnittstelle Uart0     : "
		.byte Pf_s,Pf_dez
		.byte "-8N1 kein Handshake"
		.byte Cr,Lf

		.byte "Terminalemulation       : VT100"
		.byte Cr,Lf
		.byte "Programm                : ",Pf_s,Pf_hex | Pf_nn
		.word BetSysSegStart
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word BetSysSegEnd
		.byte Cr,Lf

		.byte "Stack                   : "
		.byte Pf_s,Pf_hex | Pf_nn
		.word Stack_mem_start
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word Stack_mem_ende-1
		.byte Cr,Lf

		.byte "Modulspeicher           : "
		.byte Pf_s,Pf_hex | Pf_nn
		.word Task_mem_start
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word Task_mem_ende-1
		.byte Cr,Lf

		.byte "Variablen               : "
		.byte Pf_s,Pf_hex | Pf_nn
		.word Bezeichner_mem_start
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word Bezeichner_mem_ende-1
		.byte Cr,Lf

		.byte "System                  : "
		.byte Pf_s,Pf_hex | Pf_nn
		.word DataSegStart
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word DataSegEnd-DataSegStart+1
		.byte Cr,Lf

		.byte "Hardware-Sprungadressen : "
		.byte Pf_s,Pf_hex | Pf_nn
		.word Hard_jmp_start
		.byte " ",Pf_s,Pf_hex | Pf_nn
		.word (Hard_jmp_end-1)&ffffh
		.byte Cr,Lf

		.byte Cr,Lf

		.byte 0

		ret

; ---- Speicher-Checksumme berechnen ----

Chks            call Bereich_in
		jp nc,Std_meld

		call Trenn_ignore

		push de
		ld e,0
		call Line_end
		call nc,Byte_in
		jr nc,Chks_1
		ld a,e
		pop de

		push bc
		ld b,a
		call Line_end
		ld a,b
		pop bc
		jp nc,Syntax_err

		call Chksum_test
		call Hexout
		call Newline
		ret

Chks_1          pop de
		jp Std_meld

;---- empfangene Zeichen in HEX ausgeben ----

Hexdump         call Line_end
		jp nc,Syntax_err

		call Printf
		.byte Cr,Lf,"HEX-Dump: Abbruch "
		.byte "mit CTRL-Z !",Lf,Cr,00h

Hexdump_1       call Char_get
		cp Ctrl_z
		jp z,Newline
		call Hexout
		ld a,' '
		call Char_out
		jr Hexdump_1

;---- empfangene Zeichen direkt ausgeben ----

Echo            call Line_end
		jp nc,Syntax_err

		call Printf
		.byte Cr,Lf,"Echo: Abbruch mit CTRL-Z !",Lf,Cr,00h

Echo_1          call Char_get
		cp Ctrl_z
		jp z,Newline
		call Char_out
		jr Echo_1

; ---- Bildschirm lîschen ----

Cls		call Line_end
		jp nc,Syntax_err

		call Printf
		.byte Pf_s,Pf_clrscr,0

		ret

; ---- Wert ausgeben ----

Print:           call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		ld h,d
		ld l,e
		call Printf
		.byte "$",Pf_s,Pf_hex," &",Pf_s,Pf_dez," %",Pf_s,Pf_bin,0

		ld a,d
		or a
		jr nz,Print_1
		ld a,e
		call Print_test
		jr nc,Print_1

		call Printf
		.byte ' ',Strich,0
		call Char_out
		call Printf
		.byte Strich,0

Print_1		call Newline

		ret

; ---- Einzelschritt ----

Trace           ld de,(Reg_pc)
		call Lastw_in
		jp nc,Std_meld
		call Reg_dup
		ld (Reg_pc),de

		call Reg_load
		call Singel_step
		call Reg_save

		call Monitor_aus

		ret

; ---- Einzelschtitt ohne call / rst ----

Step            ld de,(Reg_pc)
		call Lastw_in
		jp nc,Std_meld
		call Reg_dup
		ld (Reg_pc),de

		call Reg_load
		call Step_over
		call Reg_save

		call Monitor_aus

		ret

; ---- ProgrammausfÅhrung bis ret ----

Until           ld de,(Reg_pc)
		call Lastw_in
		jp nc,Std_meld
		call Reg_dup
		ld (Reg_pc),de

		call Reg_load
		call Until_ret
		call Reg_save

		call Monitor_aus

		ret

; ---- Dump ----

Dump            ld bc,(Dump_def)
		ld d,b
		ld e,c
		call Line_end
		call nc,Bereich_in
		jp nc,Std_meld

		ld (Dump_def),bc

		ld h,b
		ld l,c
		ld bc,20h

Dump_1          call Hex_line
		call Cmp_hl_de
		jr c,Dump_2
		jr nz,Dump_3
Dump_2          call Newline
		jr Dump_1

Dump_3          call Esc_sync
Dump_4          cp Esc
		jr nz,Dump_7

		call Char_get
		call Char_get
		call Menu_branch
		.byte "A"
		.word Dump_8
		.byte "B"
		.word Dump_5
		.byte  0
		.word Dump_4

Dump_5          call Newline      ; ja, dann Zeile weiter
		jr Dump_6

Dump_8          call Printf
		.byte Cr,Pf_s,Pf_upscroll,0
		or a       ; CFL EQU 0
		sbc hl,bc

Dump_6          call Hex_line
		jr Dump_3

Dump_7          call Newline
		ret

; ---- Edit: Speicherinhalt editieren ----

Edit            ld de,(Edit_def)
		call Lastw_in  ; DE -> Addresse des ersten Bytes in der Zeile
		jp nc,Std_meld
		ld (Edit_def),de

		ld a,e
		and 1111b
		ld c,a    ; C  -> rel. Addresse
		ld a,e
		and 11110000b
		ld e,a

Edit_1          ld h,d
		ld l,e

		call Hex_line
		ld a,8     ; Crsr. positionieren
		add a,c
		add a,c
		add a,c
		call Crsr_spalte

		; Verzweigungen fÅr Cursor auf oberem Halbbit

Edit_2          call Esc_sync

		call Hex2bin
		jr c,Edit_3

		call Menu_branch
		.byte Cr
		.word Edit_12
		.byte Ctrl_z
		.word Edit_12
		.byte ' '
		.word Edit_13
		.byte Backspace
		.word Edit_14
		.byte Esc
		.word Edit_16
		.byte 0
		.word Edit_2

Edit_16         call Char_get
				call Char_get
		call Menu_branch
		.byte "A"
		.word Edit_4 ; Crsr. rauf
		.byte "B"
		.word Edit_5 ; Crsr. runter
		.byte "C"
		.word Edit_6 ; Crsr. recht
		.byte "D"
		.word Edit_7 ; Crsr. links
		.byte 0
		.word Edit_2

Edit_3          ld b,0    ; oberes Halbbit speichern
		ld h,d
		ld l,e
		add hl,bc
		ld b,a
		ld a,(hl)
		and 00001111b
		sla b
		sla b
		sla b
		sla b
		or b

		ld (hl),a
		cp (hl) ; Vergleich mit dem tatsÑchlichen Speicherinhalts
		jr nz,Edit_2

		srl a
		srl a
		srl a
		srl a
		call Hex4bit
		call Char_out
		jr Edit_8

Edit_4          call Printf       ; Crsr rauf
		.byte Cr,Pf_s,Pf_upscroll,0
		ld h,d
		ld l,e
		xor a
		ld de,10h
		sbc hl,de
		ld d,h
		ld e,l
		jr Edit_1    ; neu Zeile ausgeben

Edit_5          call Newline     ; Crsr runter
		ld hl,10h
		add hl,de
		ld d,h
		ld e,l
		jp Edit_1

Edit_6          call Printf    ; Crsr recht
		.byte Pf_s,Pf_rigth,0
		jr Edit_8

Edit_7          ld a,c      ; Crsr links
		ld c,fh
		or a
		jr z,Edit_4   ; Zeile hîher
		dec a
		ld c,a
		call Printf
		.byte Pf_s,Pf_left,Pf_s,Pf_left,0
		jr Edit_8

Edit_13         ld a,c      ; ein Byte weiter
		ld c,0
		cp fh
		jr z,Edit_5   ; Zeile tiefer
		call Printf
		.byte Pf_s,Pf_rigth,Pf_s,Pf_rigth,Pf_s,Pf_rigth,0
		inc a
		ld c,a
		jp Edit_2

Edit_14         ld a,c      ; ein Byte zurÅck
		ld c,fh
		or a
		jr z,Edit_4   ; Zeile hîher
		dec a
		ld c,a
		call Printf
		.byte Pf_s,Pf_left,Pf_s,Pf_left,0
		jp Edit_2

		; Verzweigungen fÅr Cursor auf unterem Halbbit

Edit_8          call Esc_sync

		call Hex2bin
		jr c,Edit_9

		call Menu_branch
		.byte Cr
		.word Edit_12
		.byte Ctrl_z
		.word Edit_12
		.byte ' '
		.word Edit_10
		.byte Backspace
		.word Edit_15
		.byte Esc
		.word Edit_17
		.byte 0
		.word Edit_8

Edit_17         call Char_get
		call Char_get
		call Menu_branch
		.byte "A"
		.word Edit_4  ; Crsr. rauf
		.byte "B"
		.word Edit_5  ; Crsr. runter
		.byte "C"
		.word Edit_10 ; Crsr. recht
		.byte "D"
		.word Edit_11  ; Crsr. links
		.byte 0
		.word Edit_8

Edit_9          ld b,0    ; unteres Halbbyte speichern
		ld h,d
		ld l,e
		add hl,bc
		and 00001111b
		ld b,a
		ld a,(hl)
		and 11110000b
		or b
		ld (hl),a

		cp (hl) ; Verglieich mit dem tatsÑchlichen Speicherinhalt
		jr nz,Edit_8

		and 00001111b
		call Hex4bit
		call Char_out

		ld a,c
		ld c,0
		cp fh
		jp z,Edit_5 ; eine Zeile tiefer
		call Printf
		.byte Pf_s,Pf_rigth,0
		inc a
		ld c,a
		jp Edit_2

Edit_10         ld a,c    ; Crsr rechts
		ld c,0
		cp fh
		jp z,Edit_5 ; eine Zeiel tiefer
		call Printf
		.byte Pf_s,Pf_rigth,Pf_s,Pf_rigth,0
		inc a
		ld c,a
		jp Edit_2

Edit_11         call Printf  ; Crsr links
		.byte Pf_s,Pf_left,0
		jp Edit_2

Edit_15         ld a,c    ; ein Byte zurÅck
		ld c,fh
		or a
		jp z,Edit_4 ; eine Zeile hîher
		dec a
		ld c,a
		call Printf
		.byte Pf_s,Pf_left,Pf_s,Pf_left,Pf_s,Pf_left,0
		jp Edit_2

Edit_12         call Newline   ; Ende
		ret

; ---- Hilfstext ausgben ----

Help            call Line_end
		jp nc,Syntax_err

		ld de,Help_text
		call Pointprn
		ret

; ---- alle vorhandenen Befehle ausgeben ----

Befehle         call Line_end
		jp nc,Syntax_err

		call Printf
		.byte Pf_s,Pf_clrscr
		.byte Cr,Lf," Befehle:",Cr,Lf,0

		ld hl,Kom_tab
Befehle_5       call Newline
		ld b,4     ; Anzahl der Befehle pro Zeile
Befehle_1       ld a,(hl)
		or a
		jr z,Befehle_2        ; Tabelle zu ende ?
		call Space_out
		call Space_out

Befehle_4       ld a,(hl) ; Befehlswort ausgben
		inc hl
		or a
		jr z,Befehle_3
		call Upper
		call Char_out
		jr Befehle_4

Befehle_3       inc hl
		inc hl
		djnz Befehle_1
		jr Befehle_5

Befehle_2       call Newline
		call Newline
		ret

; ---- Programm starten ----

Go              ld de,(Reg_pc)
		call Lastw_in
		jp nc,Std_meld
		call Reg_dup
		ld (Reg_pc),de

		ld h,d		       ; Test auf Breakpoint
		ld l,e
		call Break_test
		jr nc,Go_1

		call Reg_load
		call Singel_step       ; ja, dan erste Einzelschritt
		jr Go_2

Go_1		call Reg_load

Go_2		call Break_set

		jp User_go

; ---- Unterprogramm aufrufen ----

User_call       ld de,(Call_def)
		call Lastw_in
		jp nc,Std_meld
		ld (Call_def),de

		call Reg_dup
		ld (Sys_stack),sp
		ld sp,(Reg_sp)

		ld hl,User_call_1
		push hl

		push de   ; Sprungadresse speichern
		call Reg_load
		ret       ; Sprung aufuehren

User_call_1     ld (Reg_sp),sp
		ld sp,(Sys_stack)
		call Reg_save
		call Monitor_aus
		ret

; ---- Intelhexdatei ausgeben ----

Ihex_out        call Bereich_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		call Taste

		ld h,d    ; Anzahl der auszugebenden
		ld l,e    ; Bytes ->DE
		or a
		sbc hl,bc
					jr c,Ihex_out_3
		inc hl
		ld d,h
		ld e,l
		ld h,b    ; Startadresse -> HL
		ld l,c

Ihex_out_0      ld a,3ah     ; ":" ausgeben
		call Char_out

		ld a,d       ; Anzahl der Bytes -> A
		or a
		jr nz,Ihex_out_4
		ld a,e
		or a      ; Anzahl der Bytes 10000h ?
		jr z,Ihex_out_4   ; ja, dann ganze Zeile ausgeben
		cp Ihex_bytes
		jr c,Ihex_out_1
Ihex_out_4      ld a,Ihex_bytes

Ihex_out_1      ld b,a
		call Hexout  ; Anzahl der Informationsbytes

		add a,h
		add a,l
		ld c,a

		call Hl_out  ; Startadresse
		ld a,0   ; 00 ausgeben
		call Hexout

Ihex_out_2      ld a,(hl)
		call Hexout  ; Informationsbyte
		add a,c
		ld c,a
		inc hl
		dec de
		djnz Ihex_out_2

		ld a,c
		neg
		call Hexout ; Checksumme augeben
		call Newline

		ld a,d
		or e
		jr nz,Ihex_out_0

Ihex_out_3      call Printf
		.byte ":00000001FF",Cr,Lf,0
		call Char_get
		ret

; ---- Intelhexdatei einlesen ----

Ihex_load       call Line_end
		jr c,Ihex_load_2

		call Wort_in
		jp nc,Std_meld
		ld b,d
		ld c,e
		ld de,ffffh
		call Line_end
		jr c,Ihex_load_1
		call Trenn_ignore
		call Lastw_in
		jp nc,Std_meld
		call Bereich_test
		jp nc,Std_meld

Ihex_load_1     call Ihex_in_meld
		call Bereich_load
		jr Ihex_load_3

Ihex_load_2     call Ihex_in_meld
		call Ihex_in

Ihex_load_3     call Newline
		call Bereich_out
		call Newline

		cp 0
		ret z
		cp Md_ueok
		ret z

		call Std_meld

		ret

; ---- Speicher reservieren, Programm laden ----

Load            push hl
		rst 08h				 
		.byte Betn_Mem_max
		
		ld h,b  
		ld l,c
		ld bc,2
		call Divi
		pop hl

		call Lastw_in
		jp nc,Std_meld
		ld b,d
		ld c,e

		rst 08h
		.byte Betn_Mem_Alloc
		
		jp nc,Std_meld
		ld (Prg_start),hl
		ld (Reg_pc),hl

		rst 08h
		.byte Betn_Mem_size
		
		ld b,h
		ld c,l

		call Ihex_in_meld
		call Bereich_load
		call Newline
		call Bereich_out
		call Newline

		cp 0
		jr z,Load_1
		cp Md_ueok
		jr z,Load_1

		call Std_meld
		rst 08h
		.byte Betn_Mem_free
Load_1          ret

; ---- Baudrate aendern ----

Baud            call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err


		ld h,d
		ld l,e

		push hl
; TODO
		scf
;		call Baud_test
		pop hl

		jp nc,Std_meld

		call Printf
		.byte "Baudrate umstellen, ",0

		call Taste
		
		call All_sent
		
		rst 08
		.byte Betn_GetStdOut
		rst 08h
		.byte SerialObj_SetBaud		
		call Char_get

		ret

; ---- Registerinhalt Ñndern ----

Register        call Line_end
		jr c,Register_2
		ld d,h
		ld e,l
		ld bc,Reg2_tab

		rst 08h
		.byte Betn_Kom_add
		jr nc,Register_1

		call Trenn_ignore
		call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		call Reg_dup
		ld a,e
		ld (bc),a
		inc bc
		ld a,d
		ld (bc),a
		call Monitor_aus
		ret

Register_1      ld h,d
		ld l,e
		ld bc,Reg1_tab
		rst 08h
		.byte Betn_Kom_add
		ld a,Md_inp
		jp nc,Std_meld

		call Trenn_ignore
		call Byte_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		call Reg_dup
		ld a,e
		ld (bc),a

Register_2      call Monitor_aus

		ret

; ---- Tabelle der Reigisteradressen ----

Reg2_tab        .byte "AF",Strich ,0
		.word Reg_afs  ; 2 Byte-Register
		.byte "BC",Strich ,0
		.word Reg_bcs
		.byte "DE",Strich ,0
		.word Reg_des
		.byte "HL",Strich ,0
		.word Reg_hls
		.byte "AF"  ,0
		.word Reg_af
		.byte "BC"  ,0
		.word Reg_bc
		.byte "DE"  ,0
		.word Reg_de
		.byte "HL"  ,0
		.word Reg_hl
		.byte "IX"  ,0
		.word Reg_ix
		.byte "IY"  ,0
		.word Reg_iy
		.byte "SP"  ,0
		.word Reg_sp
		.byte "PC"  ,0
		.word Reg_pc
		.byte "BASIS"     ,0
		.word Stack_base
		.byte "START"     ,0
		.word Prg_start
		.byte 0

Reg1_tab        .byte "A",Strich,0
		.word Reg_afs+1  ; 1 Byte-Register
		.byte "F",Strich,0
		.word Reg_afs
		.byte "B",Strich,0
		.word Reg_bcs+1
		.byte "C",Strich,0
		.word Reg_bcs
		.byte "D",Strich,0
		.word Reg_des+1
		.byte "E",Strich,0
		.word Reg_des
		.byte "H",Strich,0
		.word Reg_hls+1
		.byte "L",Strich,0
		.word Reg_hls
		.byte "A"       ,0
		.word Reg_af+1
		.byte "F"       ,0
		.word Reg_af
		.byte "B"       ,0
		.word Reg_bc+1
		.byte "C"       ,0
		.word Reg_bc
		.byte "D"       ,0
		.word Reg_de+1
		.byte "E"       ,0
		.word Reg_de
		.byte "H"       ,0
		.word Reg_hl+1
		.byte "L"       ,0
		.word Reg_hl
		.byte 0

; ---- Wort auf dem Userstack ablegen ----

Push:           call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		call Reg_dup
		ld h,d
		ld l,e
		call User_push
		call Monitor_aus
		ret

; ---- Wort vom Userstack hohlen ----

Pop:             call Line_end
		jp nc,Syntax_err

		call Reg_dup
		call User_pop
		call Monitor_aus
		ret

; ---- Speicherbereich fuellen ----

Fill            call Bereich_in
		jp nc,Std_meld
		call Trenn_ignore

		push de
		ld a,(Fill_def)
		ld e,a
		call Line_end
		call nc,Byte_in
		jr nc,Fill_1
		call Line_end
		ld a,e
		pop de
		jp nc,Syntax_err

		call Mem_fill

		ret

Fill_1          pop de
		jp Std_meld


; ---- Speicherinhalt verschieben ----

Move            call Bereich_in
		jp nc,Std_meld ; Anfang -> BC, Ende -> DE
		call Trenn_ignore

		push de
		call Wort_in    ; Ziel -> DE
		jr c,Move_0
Move_1          pop de
		jp Std_meld

Move_0          call Line_end
		ld a,Md_inp
		jr nc,Move_1

		ld h,d   ; Ziel -> HL
		ld l,e
		pop de   ; Ende -> DE

		; Anfang Quelle EQU (BC)
		; Ende Quelle   EQU (DE)
		; Anfang Ziel   EQU (HL)

		call Mem_move

		ret

; ---- OUT-Befehl ----

Out:    ld de,(Out_def)

		call Feld_end
		call nc,Wort_in
		jp nc,Std_meld

		ld bc,de
		
Out_1   call Trenn_ignore
		call Byte_in
		jp nc,Std_meld

		out (bc),e
		nop
		nop
		nop

		ld (Out_def),bc

		call Line_end
		jr nc,Out_1

		ret

; ---- In-Befehl ----

In:     ld de,(In_def)
		ld e,a
		call Feld_end
		call nc,Wort_in
		jp nc,Std_meld

		ld bc,de

		call Trenn_ignore

		ld e,1
		call Line_end
		call nc,Byte_in
		jp nc,Std_meld

		ld (In_def),bc

In_1    ld a,e
		or a
		ret z
		dec e

		in d,(bc)
		nop
		nop
		nop

		ld a,'$'
		call Char_out
		ld a,d
		call Hexout

		call Space_out
		ld a,'%'
		call Char_out
		ld a,d
		call Bin_out

		call Space_out
		ld a,'&'
		call Char_out
		ld h,0
		ld l,d
		call Printf
		.byte Pf_s,Pf_dez,0

		call Print_test
		jr nc, In_2
		call Space_out
		ld a,Strich
		call Char_out
		ld a,d
		call Char_out
		ld a,Strich
		call Char_out

In_2            call Newline
		jr In_1

; ---- Speicher reservieren ----

Alloc           call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		ld b,d
		ld c,e
		
		rst 08h
		.byte Betn_Mem_Alloc

		push af
		rst 08h
		.byte Betn_Mem_size
		jr c,Alloc_1
		ld hl,0
		ld de,0
Alloc_1         ld b,h
		ld c,l
		call Bereich_out
		call Newline
		pop af

		jp nc,Std_meld

		ret

; ---- Speicher verkleinern ----

Shrink          call Wort_in            ; Adresse -> HL, LÑnge -> BC
		jp nc,Std_meld
		ld b,d
		ld c,e
		call Trenn_ignore
		call Wort_in
		jp nc,Syntax_err
		call Line_end
		jp nc,Syntax_err
		ld h,b
		ld l,c
		ld b,d
		ld c,e

		rst 08h
		.byte Betn_Mem_shrink
		push af
		rst 08h
		.byte Betn_Mem_size
		jr c,Shrink_1
		ld hl,0
		ld de,0
Shrink_1        ld b,h
		ld c,l
		call Bereich_out
		call Newline
		pop af

		jp nc,Std_meld

		ret

; ---- Speicher freigeben ----

Free            call Wort_in
		jp nc,Std_meld
		call Line_end
		jp nc,Syntax_err

		ld h,d
		ld l,e

		rst 08h
		.byte Betn_Mem_free
		jp nc,Std_meld

		ret

; ---- SpeicherÅbersicht ----
; TODO funktion implementieren
Mem             call Line_end
		jp nc,Syntax_err

		call Printf
		.byte Cr,Lf,"Funktion nicht implementiert",Cr,Lf,0
		ret

; ---- Watchdog ein und ausschalten ----

; TODO Funktion implentieren

Watchdog	        
		call Line_end
		jp nc,Syntax_err

		ret

; ---- leerer Befehl, tue nichts ----

Return          call Line_end
		jp nc,Syntax_err

		ret

; ---- Echtzeiturh ----

Uhr		ld bc,Date+3
		rst 08h
		.byte Betn_Datum_in
		jr nc,Uhr1
		
		push hl
		ld hl,Date
		rst 08h
		.byte Betn_Calc_DOW
		ld (Date+DOW_OFFSET),a
		pop hl
		
		ld bc,Date
		rst 08h
		.byte Betn_Time_in
		jr nc,Uhr1
		
		ld hl,bc

		rst 08h
		.byte Betn_GetRtc

		rst 08h
		.byte Betn_Objekt_call
		.byte RtcObj_SetTime
Uhr1		
		rst 08h
		.byte Betn_GetRtc
		
		ld hl,Date

		rst 08h
		.byte Betn_Objekt_call
		.byte RtcObj_GetTime
		
		call Printf
		.byte "RTC: ",Pf_s,Pf_wt|Pf_dt|Pf_hhmm|Pf_ss,Cr,Lf,0

		rst 08h
		.byte Betn_Get_dcf
		
		ld hl,Date

		rst 08h
		.byte Betn_Objekt_call
		.byte Dcf77Obj_GetTime
		
		call Printf
		.byte "DCF: ",Pf_s,Pf_wt|Pf_dt|Pf_hhmm|Pf_ss,Cr,Lf,0

		ld hl,100
		rst 08h
		.byte Betn_Timer

		rst 08h
		.byte Betn_Char_get_non_blocking
		
		ret c
		
		call Printf
		.byte Pf_s,Pf_up,Pf_s,Pf_up,0

		jr Uhr1
; ----

DcfCmd	rst 08h
		.byte Betn_Printf
		.byte "-------------------1mmmmMMMPssssSSPttttTTWWWmmmmMjjjjJJJJP",Cr,Lf,0

		rst 08h
		.byte Betn_Get_dcf

rst 08h
		.byte Betn_Objekt_call
		.byte Dcf77Obj_Clear
		
DcfCmd1
		rst 08h
		.byte Betn_Objekt_call
		.byte Dcf77Obj_GetChar
		
		jr nc,DcfCmd3
		
		cp a,Cr
		jr nz,DcfCmd2
	
		ld hl,Date

		rst 08h
		.byte Betn_Objekt_call
		.byte Dcf77Obj_GetTime

		call Printf
		.byte " ",Pf_s,Pf_wt|Pf_dt|Pf_hhmm,Cr,Lf,0
		
DcfCmd2
		call Char_out

DcfCmd3	ld hl,100
		rst 08h
		.byte Betn_Timer

		rst 08h
		.byte Betn_Char_get_non_blocking
		
		jr c,DcfCmd4
		
		jr DcfCmd1
DcfCmd4
		rst 08h
		.byte Betn_Printf
		.byte Cr,Lf,0
		
		ret
; ---- Syntax Error Meldung ausgeben ----

Syntax_err      ld a,Md_inp
		call Std_meld
		ret

; ---- Debug-Informationen ausgeben ----

Monitor_aus     push af
		push bc
		push de
		push hl

		call Printf
		.byte Pf_s,Pf_home,Pf_s,Pf_clrl,Cr,Lf
		.byte "Register:",Pf_s,Pf_clrl,Cr,Lf
		.byte "AF   SZ-H-PNC BC"
		.byte "   DE   HL   AF",Strich
		.byte "  SZ-H-PNC BC",Strich
		.byte "  DE",Strich,"  HL",Strich,"  IX   IY"
		.byte "   PC   SP",Pf_s,Pf_clrl,Cr,Lf

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_af
		.byte ' '

		.byte Pf_s,Pf_bin | Pf_nn | Pf_ind| Pf_byte
		.word Reg_af
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_bc
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_de
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_hl
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_afs
		.byte ' '

		.byte Pf_s,Pf_bin | Pf_nn | Pf_ind | Pf_byte
		.word Reg_afs
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_bcs
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_des
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_hls
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_ix
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_iy
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_pc
		.byte ' '

		.byte Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Reg_sp
		.byte ' '

		.byte Pf_s,Pf_clrl,Cr,Lf
		.byte Pf_s,Pf_clrl,Cr,Lf,"I: ",0

		ld a,i
		call Hexout

		call Printf
		.byte ", IFF2: ",0
		ld a,(Reg_IFF2)
		and 1b
		add a,'0'
		call Char_out

		call Printf
		.byte ", Startadresse ",Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Prg_start
		.byte ", Stack-Basis: ",Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Stack_base
		.byte ", Stack:",Pf_s,Pf_clrl,Cr,Lf,0

		ld a,Stack_max

		ld hl,(Stack_base)
		ld de,(Reg_sp)
		or a
		sbc hl,de
		jr c,Monitor_aus_1

		ld de,2*Stack_max+1
		call Cmp_hl_de
		jr nc,Monitor_aus_1

		srl l
		jr c,Monitor_aus_1

		ld a,l

Monitor_aus_1   or a
		jr z,Monitor_aus_3
		ld hl,(Reg_sp)
		ld c,a
		sla c
		ld b,0
		add hl,bc

Monitor_aus_2   dec hl
		dec hl
		push hl
		call Read_hl
		call Hl_out
		pop hl
		dec a
		or a
		jr z,Monitor_aus_3
		call Space_out
		jr Monitor_aus_2

Monitor_aus_3   ld hl,(Breakpoint_add)
		ld a,h
		or l
		jr z,Monitor_aus_6

		call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf,Pf_s,Pf_clrl,Cr,Lf
		.byte "Breakpoint: ",0
		call Hl_out

Monitor_aus_6   call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf
		.byte Pf_s,Pf_clrl,Cr,Lf
		.byte "Programm:",Pf_s,Pf_clrl,Cr,Lf,0

		ld hl,(Reg_pc)
		ld a,l
		and 11100000b
		ld l,a
		ld de,10h
		sbc hl,de

		ld b,4
Monitor_aus_4   call Hex_line
		call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf,0
		djnz Monitor_aus_4

		call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf,0

		ld hl,(Watch_add)
		ld a,h
		or l
		jr z,Monitor_aus_5

		call Printf
		.byte "Daten:",Pf_s,Pf_clrl,Cr,Lf,0
		call Hex_line
		call Printf
		.byte Pf_s,Pf_clrl,Cr,Lf
		.byte Pf_s,Pf_clrl,Cr,Lf,0

Monitor_aus_5   pop hl
		pop de
		pop bc
		pop af

		ret


; ---- eine Zeile in Hex ausgeben ( 16 Byte ) ----
;
; HL -> Adresse
; HL <- nÑchstses Byte

Hex_line        push af
		push bc
		push de

		push hl

		call Printf
		.byte Pf_s,Pf_hex,": ",0

		ld b,16
		ld de,(Reg_pc)

Hex_line_1      ld a,'>'
		call Cmp_hl_de
		jr z,Hex_line_4

		call Break_test
		ld a,'.'
		jr z,Hex_line_4

		ld a,' '

Hex_line_4      call Char_out

		ld a,(hl)
		call Hexout
		inc hl
		djnz Hex_line_1
		pop hl

		call Space_out
		call Space_out
		ld b,16
Hex_line_2      ld a,(hl)
		call Print_test
		jr c,Hex_line_3
		ld a,'.'
Hex_line_3      call Char_out
		inc hl
		djnz Hex_line_2

		call Printf
		.byte Pf_s,Pf_clrl,0

		pop de
		pop bc
		pop af

		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Intelhexdatei verarbeiten    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Meldung fÅr Intel-Hex-Datei lesen ausgeben ----

Ihex_in_meld    call Printf
		.byte "Abbruch mit "
		.byte "ESC, CTRL-Z oder @",Cr,Lf,0
		ret

; ---- Reset fÅr Intel-Hex-Datei lesen ----

Ihex_in_res     push bc
		ld b,0
		ld (Ihex_in_bc),bc
		pop bc
		ret

; ---- ein Byte aus Intel-Hex-Datei lesen ----
;
; HL  <-  neue Speicheradresse
;  A  <-  EQUZeichen oder EQU5 Fehler; EQU6 erfogreich beendet
; CFL <- EQU1 Zeichen gelesen ( in A ) ; EQU0 Ende oder Fehler

Ihex_byte       push bc
		push de

		ld bc,(Ihex_in_bc)
		ld de,(Ihex_in_de)
		ld hl,(Ihex_in_hl)

		inc hl
		ld a,b
		or a
		jr nz,Ihex_byte_1   ; aktuelle Zeile fortsetzen

		ld c,0        ; Checksummen-Startwert

		call Ihex_byte_sub  ; Bytezahl lesen
		jr nc,Ihex_byte_5
		ld b,a

		call Ihex_byte_sub  ; Adresse lesen -> HL
		jr nc,Ihex_byte_5
		ld h,a
		call Ihex_byte_sub
		jr nc,Ihex_byte_5
		ld l,a

		call Ihex_byte_sub  ; Erweiterungs-Byte -> E
		jr nc,Ihex_byte_5
		ld e,a

		ld a,b
		or a
		jr z,Ihex_byte_4    ; Bytezahl EQU 0 ?

		ld a,e
		or a
		jr nz,Ihex_byte_3   ; E !EQU 0 -> Fehler

Ihex_byte_1     call Ihex_byte_sub       ; Datenbyte lesen -> D
		jr nc,Ihex_byte_5
		ld d,a

		djnz Ihex_byte_2

		call Ihex_byte_sub     ; Checksumme lesen
		jr nc,Ihex_byte_5
		ld a,c
		or a
		jr nz,Ihex_byte_3
		ld a,'.'   ; Punkt ausgeben
		call Char_out

Ihex_byte_2     ld a,d
		scf
		jr Ihex_byte_5

Ihex_byte_4     ld a,e
		cp 1       ; Erweiterungsbyte !EQU 1 ?
		jr nz,Ihex_byte_3    ; -> Fehler

		ld a,h
		or l
		jr nz,Ihex_byte_3    ; HL !EQU 0 -> Fehler

		call Ihex_byte_sub     ; Checksumme lesen
		jr nc,Ihex_byte_5
		ld a,c
		or a
		jr nz,Ihex_byte_3

		ld a,Md_ueok       ; Uebertragung beendet
		jr Ihex_byte_6

Ihex_byte_3     ld a,70     ; "F" ausgeben
		call Char_out
		ld a,Md_uef      ; Fehlermeldung

Ihex_byte_6     or a

Ihex_byte_5     ld (Ihex_in_hl),hl
		ld (Ihex_in_de),de
		ld (Ihex_in_bc),bc

		pop de
		pop bc

		ret

; ---- Intelhex-Datei laden ----

Ihex_in         ex af,af'
		push af
		push hl

		ld a,0      ; Default fuer OK -> A"
		ex af,af'
		ld bc,ffffh ; oberen Bereich auf Maximum
		ld de,0h    ; Umterren Bereich aug Minimunm

Ihex_in_0       call Ihex_in_res
Ihex_in_1       call Ihex_byte  ; Byte einlesen
		jr nc,Ihex_in_2 ; kein Byte eingelesen

		ld (hl),a ; Byte speichern
		cp (hl)
		jr z,Ihex_in_7
		ld a,Md_mem
		ex af,af'
		ld a,83   ; "S" ausgeben
		call Char_out

Ihex_in_7       call Cmp_hl_bc  ; MIN( BC, HL ) -> BC
		jr nc,Ihex_in_6
		ld b,h
		ld c,l

Ihex_in_6       call Cmp_hl_de  ; MAX( DE, HL ) -> DE
		jr c,Ihex_in_1
		ld d,h
		ld e,l

		jr Ihex_in_1

Ihex_in_2       cp Md_ueok    ; Beendet ?
		jr z,Ihex_in_3
		cp Md_abr
		jr z,Ihex_in_4  ; Abbruch

		ex af,af'   ; Meldung merken
		call Ihex_sync
		jr nc,Ihex_in_4 ; Abbruch
		jr Ihex_in_0

Ihex_in_3       ex af,af' ; Status zurueckholen

Ihex_in_4       pop hl
		ex af,af'
		pop af
		ex af,af'
		ret

; ---- Datei in bestimmten Bereich laden ----
; BC,DE -> Bereich in den geladen werden soll
; BC,DE <- Bereich in den geladen wurde

Bereich_load    push hl

		ld h,b
		ld l,c

		call Ihex_in_res

Bereich_load_1  push hl
		call Ihex_byte
		pop hl
		jr nc,Bereich_load_2
		call Cmp_hl_de
		jr z,Bereich_load_4
		jr nc,Bereich_load_3
Bereich_load_4  ld (hl),a
		cp (hl)
		ld a,Md_mem
		jr nz,Bereich_load_2
		inc hl
		jr Bereich_load_1

Bereich_load_3  ld a,Md_mem

Bereich_load_2  call In_str
		.byte Md_ueok, Md_abr,0
		jr c, Bereich_load_5
		call Ihex_skip

Bereich_load_5  dec hl
		ld d,h
		ld e,l

		pop hl

		ret

; ---- Byte ohne echo von RS-232 lesen ----
;
;   A <-  gelesenes Byte bzw. Fehlermeldung
;   C <-> Checksumme
; CFL <- EQU1 : Byte gelesen, EQU0 Abbruch ( Esc, Ctrl_z,  )

Ihex_byte_sub   push bc

Ihex_byte_sub_1 call Char_get
		call Ihex_break
		jr z,Ihex_byte_sub_3

		call Hex2bin
		jr nc,Ihex_byte_sub_1

		sla a
		sla a
		sla a
		sla a
		ld b,a

Ihex_byte_sub_2 call Char_get
		call Ihex_break
		jr z,Ihex_byte_sub_3

		call Hex2bin
		jr nc,Ihex_byte_sub_2

		or b
		pop bc

		push af
		add a,c
		ld c,a
		pop af

		scf
		ret

Ihex_byte_sub_3 pop bc
		or a
		ld a,Md_abr ; Meldung Abbruch
		ret

; ---- Intelhex-Empfang neu synchronisieren ----
;
; A <- Fehlercode
; CFL <- EQU1 CR oder ":" empfangen, sonst ESC, CTRL-Z oder "@" empfangen

Ihex_sync       call Char_get
		call Ihex_break
		jr z,Ihex_sync_1
		call In_str
		.byte ":",Cr,0
		ld a,0
		ret c

		jr Ihex_sync

Ihex_sync_1     ld a,Md_abr
		or a
		ret

; ---- Intelhex-Datei einlesen und verwerfen ----

Ihex_skip       push af
		push hl

Ihex_skip_1     call Ihex_sync
		cp Md_abr
		jr z,Ihex_skip_3

		call Ihex_in_res
Ihex_skip_2     call Ihex_byte
		jr c,Ihex_skip_2

		cp Md_abr
		jr z,Ihex_skip_3
		cp Md_ueok
		jr z,Ihex_skip_3
		jr Ihex_skip_1

Ihex_skip_3     pop hl
		pop af
		ret

; ---- Test auf Intel-Hex Abbruch ----
; A -> Zeichen
; ZFL <- EQU1 break, EQU0 weiter

Ihex_break      cp Esc
		ret z
		cp '@'
		ret z
		cp Ctrl_z
		ret

; ---- Interrupt FILP-FILOP 2 ermitteln ----
;  A <- Zustand des IFF2 ( EQU0 disable, EQU1 enable )

Get_IFF2        push af
		ld a,i
		jp pe,Get_IFF2_1

		pop af
		ld a,0
		ret

Get_IFF2_1      pop af
		ld a,1
		ret

; ---- AusfÅhrung bis Return ----
;
; (Reg_pc) -> Programmzeiger
; (Reg_sp) -> Stapelzeiger

Until_ret       push hl
		push af

Until_ret_0	ld hl,(Reg_pc)
		ld a,(hl)
		cp c9h     ; Opcode EQU ret
		jr z,Until_ret_2   ; dann Ende
		and 11000111b
		cp c0h     ; Opcode !EQU ret cc
		jr nz,Until_ret_1  ; dann weiter

		ld a,(hl)
		ld (Ret_test),a
		ld hl,c9afh      ; Optcode fuer xor a  ret
		ld (Ret_test+1),hl

		pop af         ; F-Register laden
		push af

		ld a,1
		call Ret_test
		or a
		jr nz,Until_ret_2  ; Sprung aufgefuehrt, dann Ende

Until_ret_1     pop af          ; kein return, dann weiter
		pop hl

		call Step_over

		push hl
		push af
		ld hl,(Reg_pc)
		call Break_test
		jp c,Breakpoint_sim
		jr Until_ret_0

Until_ret_2     pop af    ; Ende
		pop hl
		ret

; ---- Einzelschritt ohne Unterprogramm ----
;
; (Reg_pc) -> Programmzeiger
; (Reg_sp) -> Stapelzeiger

Step_over       push af
		push hl
		ld hl,(Reg_pc)
		call Call_test
		jr c,Step_over_1
		pop hl
		pop af
		jr Singel_step

Step_over_1     ld hl,(Reg_sp)
		ld (Reg_sp_stop),hl

		pop hl
Step_over_2     pop af
		call Singel_step
		push af
		push hl
		push bc
		ld hl,(Reg_sp)
		ld bc,(Reg_sp_stop)
		or a
		sbc hl,bc
		pop bc
		pop hl
		jr c,Step_over_2
		pop af
		ret

; ---- Einzelschritt ----
;
; (Reg_pc) -> Programmzeiger
; (Reg_sp) -> Stapelzeiger

Singel_step

		ld (Sys_stack),sp
		ld sp,(Reg_sp)
		push hl

		ld hl,Int_step
		ld (Timer1_IV),hl

		ld hl,(Reg_pc)
		ex (sp),hl

		push af

		ld a,10000000b
		out0 (TMR1_CTL),a
		nop
		nop
		nop

		ld a,LOW(5)
		out0 (TMR1_RR_L),a
		nop
		nop
		nop
		ld a,HIGH(5)
		out0 (TMR1_RR_H),a
		nop
		nop
		nop
		
		in0 a,(TMR1_IIR)
		nop
		nop
		nop

		ld a,00000001b
		out0 (TMR1_IER),a
		nop
		nop
		nop

		ld a,10000010b
		out0 (TMR1_CTL),a
		nop
		nop
		nop

		ld a,10000001b
		out0 (TMR1_CTL),a
		nop
		nop
		nop

		pop af

		ei
		
		nop
		ret     ; Einzelschritt ausfÅhren

; ---- Interruptrutine Einzeilschritt ----

Int_step        ex (sp),hl
		ld (Reg_pc),hl
		pop hl
		ld (Reg_sp),sp
		ld sp,(Sys_stack)

		call Step_off

		rst 08h
		.byte Betn_Int_ret
		
; ---- Einzelschritt Interrupt abschalten ----

Step_off        push af
		in0 a,(TMR1_IIR)
		ld a,00000000b   ; CtC Interupt disabel
		out (TMR1_IER),a
		nop
		nop
		nop
		pop af
		ret

; ---- Breakpoint-Berarbeitung ----

Breakpoint      ex (sp),hl
		ld (Reg_pc),hl
		pop hl
		ld (Reg_sp),sp
		jr Breakpoint_sim

; ---- Breakpoint simuliren ----
;
; (Reg_pc) -> Programmzeiger
; (Reg_sp) -> Stapelzeigeb
; TODO
Breakpoint_sim	;ld sp,Stack

		push af
		call Get_IFF2
		ld (Reg_IFF2),a
		pop af

		di

		call Step_off

		call Reg_save
		ld hl,(Reg_pc)
		dec hl
		ld (Reg_pc),hl

		rst 08h
		.byte Betn_Int_enable

		call Break_clr

		call Monitor_aus
		ld a,Md_brk
		call Std_meld
		call Printf
		.byte Pf_s,Pf_clrl,0

		jp Warmstart

; ----- Breakpoints setzen ----

Break_set       push af
		push hl
		ld hl,(Breakpoint_add)
		ld a,l
		or h
		jr z,Break_set_1
		ld a,(hl)
		ld (Breakpoint_opt),a
		ld a,Brk_opt
		ld (hl),a
Break_set_1     pop hl
		pop af

		ret

; ----- Breakpoints lîschen ----

Break_clr       push af
		push hl
		ld hl,(Breakpoint_add)
		ld a,l
		or h
		jr z,Break_set_1
		ld a,(Breakpoint_opt)
		ld (hl),a
Break_clr_1     pop hl
		pop af

		ret

; ----- Breakpoints lîschen ----
;
; HL   -> Adresse
; A   <-  Optcode and dieser Adresse
; CFL <-  EQU0 kein Breakpoint, EQU1 Breakpoint

Break_test      push bc
		ld bc,(Breakpoint_add)
		call Cmp_hl_bc
		jr nz,Break_test_1
		ld a,(Breakpoint_opt)
		scf
		pop bc
		ret
Break_test_1    or a
		pop bc
		ret

; ---- alten Registerinhalte merken ----

Reg_dup         push bc
		push de
		push hl
		ld bc,Reg_1
		ld de,Reg_2-1
		ld hl,Reg_undo
		call Mem_move
		pop hl
		pop de
		pop bc

		ret

; ---- Register in den Zwischenspeichen ----

Reg_save        ld (Reg_hl),hl
		push af
		pop hl
		ld (Reg_af),hl
		ld (Reg_bc),bc
		ld (Reg_de),de
		ex af,af'
		exx
		ld (Reg_hls),hl
		push af
		pop hl
		ld (Reg_afs),hl
		ld (Reg_bcs),bc
		ld (Reg_des),de
		ex af,af'
		exx
		ld (Reg_ix),ix
		ld (Reg_iy),iy

		ret

; ---- Register aus dem Zwischenspeichen hohlen ----

Reg_load        ld hl,(Reg_afs)
		push hl
		pop af
		ld bc,(Reg_bcs)
		ld de,(Reg_des)
		ld hl,(Reg_hls)
		ex af,af'
		exx
		ld hl,(Reg_af)
		push hl
		pop af
		ld bc,(Reg_bc)
		ld de,(Reg_de)
		ld hl,(Reg_hl)
		ld ix,(Reg_ix)
		ld iy,(Reg_iy)

		ret

; ---- Wort auf dem Userstack ablegen ----
; HL -> --(Reg_sp)

User_push       push de
		ld de,(Reg_sp)
		dec de
		ld a,h
		ld (de),a
		dec de
		ld a,l
		ld (de),a
		ld (Reg_sp),de
		pop de
		ret

; ---- Wort vom Userstack hohlen ----
; (Reg_sp)++ -> HL

User_pop        push de
		ld de,(Reg_sp)
		ld a,(de)
		ld l,a
		inc de
		ld a,(de)
		ld h,a
		inc de
		ld (Reg_sp),de
		pop de
		ret

; ---- Test auf Unterprogrammaufruf oder RST in (HL) ----
;
; zerstîrt AF
; CFL <- EQU1 Unterprogramm, EQU0 keins

Call_test       ld a,(hl)
		cp cdh       ; call
		jr z,Call_test_1
		and 11000111b
		cp 11000100b      ; call condition 11ccc100
		jr z,Call_test_1
		cp 11000111b      ; Restart 11xxx111
		jr z,Call_test_1

		or a         ; CFL <- 0
		ret

Call_test_1     scf
		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Ein- Ausgabeverarbeitung    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Esc synchronisieren ----
; wenn kein Zeichen empfangen, dann Zeichen hohlen
; wenn ESC-Zeichen empfangen, ESC zurÅckgeben
; wenn kein Esc empfangen, dann neues Zeichen hohlen
; A <- Zeichen

Esc_sync
		call Char_get
		ret
		
		call Char_get_non_blocking
		jr nc,Esc_sync_1
		cp a,Esc
		ret z
		call Char_get
		ret
		
Esc_sync_1
		call Char_get
		ret
		
; ---- Aufforderung Tatse zu druecken ----

Taste   call Printf
		.byte "Taste druecken !",Cr,Lf,0

		call Char_get
		
		ret
			
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    formatierte Standartausgebe    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Leerzeichen ausgeben ----

Space_out       push af
		ld a,' '
		call Char_out
		pop af
		ret

; ---- neu Zeile ----

Newline         call Printf
		.byte Cr,Lf,0
		ret

; ---- Cursor auf Spalte setzen ----
;
; A -> Spaltennr. ( beginnent mit 1 )

Crsr_spalte     push af
		ld a,Cr
		call Char_out
		pop af
		push af

Crsr_spalte_1   dec a
		or a
		jr z,Crsr_spalte_2
		call Printf
		.byte Pf_s,Pf_rigth,0
		jr Crsr_spalte_1

Crsr_spalte_2   pop af
		ret

; ---- Zeichen auf der Standartausgabe ausgeben ----
;
; A -> Zeichen

Char_out	rst 08h
		.byte Betn_Char_out
		ret

;---- Byte als Hex ausgeben ----
; A -> Byte

Hexout          push hl
		ld l,a
		call Printf
		.byte Pf_s,Pf_hex | Pf_byte, 0
		pop hl

		ret

; ---- Hl als Hex ausgeben ----

Hl_out          call Printf
		.byte Pf_s,Pf_hex,0

		ret

; ---- Hl im Dezimalsystem ausgeben ----
;
; HL -> Zahl

Zahl_dez_out    call Printf
		.byte Pf_s,Pf_dez,0

		ret

; ---- formatierte Ausgabe auf Standartausgabe ----
;
; DE  -> Zeiger auf String
; DE <-  Zeiger auf Stringende + 1

Pointprn	rst 08h
		.byte Betn_Pointprn
		ret

; ---- formatierte Ausgabe auf Standartausgabe ----
;
; HL   -> Argument
; (SP) -> String

Printf:	call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		call Pointprn

		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		ret

; ---- formatierte Ausgabe auf Objekt ----
; IX  -> Zeiger auf Objekt
; HL   -> Argument
; (SP) -> String

Printf_obj		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_Pointprn

		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		ret

; ---- Bereich ausgeben ----

Bereich_out     push hl
		ld h,b
		ld l,c
		call Hl_out
		call Space_out
		ld h,d
		ld l,e
		call Hl_out
		pop hl
		ret

; ---- A als BinÑrzahl ausgeben ----
; A -> Byte

Bin_out         push hl
		ld l,a
		call Printf
		.byte Pf_s,Pf_bin | Pf_byte, 0
		pop hl

		ret


; ---- warten bis alles gesendet ist ----
;TODO
All_sent        ret

;---- Zeichen von RS 232 holen ----
;
; A <- Zeichen
; CFL <- =1 Zeichen geholt, 0= kein Zeichen geholt
Char_get_non_blocking  
		rst 08h
		.byte Betn_Char_get_non_blocking
		ret

;---- Zeichen von RS 232 holen ----
;
; A <- Zeichen
Char_get	rst 08h
			.byte Betn_Char_get
			ret
			


; ---- Bezeichner lesen ----
;
; HL   -> Bezeichner
; HL  <-  Zeichen nach dem Bezeichner
; CFL <-  EQU1 Ok, EQU0 Fehler

Bez_read        push af

		ld a,(hl)          ; 1. Zeichen kein Buchstabe -> Fehler
		call Is_literal
		jr nc,Bez_read_2


Bez_read_1      inc hl             ; Ziffern und Buchstaben Åberlesen
		ld a,(hl)
		call Is_alpha
		jr c,Bez_read_1

		pop af
		scf
		ret

Bez_read_2      pop af
		or a
		ret

; ---- Bezeichner vergleichen ----
;
; HL   -> 1. Bezeichner
; DE   -> 2. Bezeicner
; CFL <-  EQU1 Bezeicner gleich, EQU0 Bezeichner ungleich

Bez_cmp         push af
		push bc
		push de
		push hl

		ld a,(de)              ; 1. Zeichen Buchstabe
		ld b,(hl)

		call Char_cmp
		jr nc,Bez_cmp_4
		
		call Is_literal
		jr nc,Bez_cmp_4

Bez_cmp_1       inc de
		inc hl

		ld a,(de)
		ld b,(hl)

		call Char_cmp
		jr nc,Bez_cmp_2

		call Is_alpha
		jr nc,Bez_cmp_3

		jr Bez_cmp_1

Bez_cmp_2       call Is_alpha
		jr c,Bez_cmp_4
		
		ld a,b
		call Is_alpha
		jr c,Bez_cmp_4

Bez_cmp_3       pop hl
		pop de
		pop bc
		pop af

		scf

		ret

Bez_cmp_4       pop hl
		pop de
		pop bc
		pop af

		or a

		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Komandozeilen - Interpretation    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- 16 Bit Zahl in bin,dez oder hex Zahlensystem einlesen ----
;  Hl  -> Zeiger auf Komandozeile
;  DE <-  Zahl
;  HL <-  naechstes Zeichen
; A   <-  Fehlercode
; CFl <-  EQU1 Ok, EQU0 nicht gefunden

Wort_in         push bc
		rst 08h
		.byte Betn_Space_ignore
				ld a,(hl)
		inc hl

		ld c,2
		cp Pre_bin
		jr z,Wort_in_1
		ld c,10
		cp Pre_dez
		jr z,Wort_in_1
		ld c,16
		cp Pre_hex
		jr z,Wort_in_1
		cp Pre_asc
		jr z,Wort_in_2
		cp Pre_bez
		jr z,Wort_in_5
		dec hl

Wort_in_1 
		rst 08h
		.byte Betn_Zahl_in

		pop bc

		ret

Wort_in_2       pop bc
		ld a,(hl)  ;   ASCII-Zeichen
		inc hl
		or a
		jr nz,Wort_in_3
		ld a,Md_inp
		or a
		ret

Wort_in_3       ld e,a
		ld a,(hl)
		cp Pre_asc
		jr nz,Wort_in_4
		inc hl
Wort_in_4       xor a
		ld d,a
		scf
		ret

Wort_in_5       pop bc
		ld de,Bezeichner_mem_start ; Keine Zahl -> Bezeichner laden
		rst 08h
		.byte Betn_Bez_get

		ret

; ---- letzes optionales Wort in einer Zeile einlesen ----
;
;  Hl  -> Zeiger auf Komandozeile
;  DE <-  Zahl
;  HL <-  naechstes Zeichen
; A   <-  Fehlercode
; CFl <-  EQU1 Ok, EQU0 nicht gefunden

Lastw_in        xor a
		call Line_end
		ret c
		call Wort_in
		ret nc
		call Line_end
		ret c
		ld a,Md_inp
		or a
		ret

; ---- Bereichsangabe einlesen  ----
;
; HL  -> Zeiger auf Komandozeile
; HL  <- nÑchstes Zeichen
; BC  <- Beginn
; DE  <- Ende
; A   <- Fehlercode
; CFl <- EQU1 Ok, EQU0 nicht gefunden


Bereich_in      call Wort_in   ; 1. Parameter -> BC,DE
		ret nc
		ld b,d
		ld c,e

		call Trenn_ignore
		xor a
		call Feld_end
		ret c

		call Wort_in
		ret nc

		call Bereich_test

		ret

; ---- Hexbyte aus der Komandozeile lesen ----
;
; HL  -> Zeiger auf Komandozeile
; E   -> Default-Wert
; HL  <- nÑchstes Zeichen
; E   <- Byte
; A   <- Fehlercode
; CFl <- EQU1 Ok, EQU0 nicht gefunden
;
; Das D Register wird zerstîrt

Byte_in         call Wort_in
		ret nc
		ld a,d
		or a
		jr nz,Byte_in_1
		ld d,a
		scf
		ret

Byte_in_1       ld a,Md_inp ; Falscher Wert
		or a
		ret
		

; ---- Test ob Zeichen in der Komandozeile  ist ----

;  HL  -> Zeiger auf Komandozeile
;  A   -> zu testendes Zeichen
;  HL  <- nÑchstes Zeichen
;  A   <- Fehlercode
;  CFl <- EQU1 Ok, EQU0 nicht gefunden

Char_test       rst 08h
		.byte Betn_Space_ignore
		cp (hl)
		jr nz,Char_test_1
		inc hl
		rst 08h
		.byte Betn_Space_ignore
				xor a
		scf
		ret

Char_test_1     ld a,Md_inp
		or a
		ret

; ---- Leerzeichen und ein Trennzeichen Åberlesen ----
;
; HL  -> Zeiger auf Komandozeile
; HL  <- Zeiger auf naechstes Nicht-Leerzeichen ( evt. nach Trennzeichen )

Trenn_ignore    push af
		rst 08h
		.byte Betn_Space_ignore
		ld a,(hl)
		call Trenn_test
		jr nc,Trenn_ignore_1
		inc hl
Trenn_ignore_1  pop af
		ret

; ---- Test ob Eingabefeld zuende ----

Feld_end        rst 08h
		.byte Betn_Space_ignore
		call Line_end
		ret c

		push bc
		ld b,a
		ld a,(hl)
		call Trenn_test
		ld a,b
		pop bc

		ret

; ---- Zeilenende erreicht ----
;
; HL  -> Zeiger auf Komandozeile
; HL  <- Zeiger auf naechstes Nicht-Leerzeichen
; CFL <- EQU1 Zeilenende erreicht EQU0 nicht erreicht

Line_end        push af
		rst 08h
		.byte Betn_Space_ignore
		ld a,(hl)
		or a
		jr z,Line_end_1
		pop af
		or a
		ret

Line_end_1      pop af
		scf
		ret

; ---- Testen ob Bereich leer ist ----
; BC,DE -> Bereich
; A   <- Fehlercode
; CFl <- EQU1 Ok, EQU0 nicht gefunden

Bereich_test    push hl
		push bc
		call Ber_len
		pop bc
		pop hl

		ld a,0
		ret c
		ld a,Md_inp
		or a
		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Zeichenverarbeitung    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU


; ---- Test auf Trennzeichen ----
;
; A    -> Zeichen
; CFL <-  EQU1 Trennzeichen ",;" ; EQU0 anderes Zeichen

Trenn_test      cp 2ch    ; A EQU ,
		scf
		ret z

		cp 3bh      ; A EQU ;
		scf
		ret z

Trenn_test_1    or a
		ret


; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    allgemein Hilfsfunktionen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Test ob Zeichen im String vorhanden ----
; (SP) -> String
; A    -> Zeichen
; CFL  <- EQU1 enthalten, EQU0 nicht enthalten
; 0 ist in keinem String enthalten

In_str          ex (sp),hl
		push bc
		ld c,a

In_str_1        ld a,(hl)
		inc hl
		or a
		jr z,In_str_2
		cp c
		jr nz,In_str_1

		call Read_str
		scf

In_str_2        ld a,c
		pop bc
		ex (sp),hl
		ret


; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Verzweigungs- und Tabbelnenoperationen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Ende einer Stringtabelle suchen ----
;
; DE -> Zeiger auf Tablle
; DE <- Zeiger auf 0-Byte am Ende der Tablle

Tab_end         push af
		push hl

		ld h,d
		ld l,e


Tab_end_1       ld a,(hl)       ; Ende der Tabelle suchen
		or a
		jr z,Tab_end_2
		call Read_str
		inc hl
		inc hl
		jr Tab_end_1


Tab_end_2       ld d,h
		ld e,l

		pop hl
		pop af

		ret

; ---- Verzweigungstablle ----
;
; (SP+1)  -> Zeiger auf Adresse der Tabelle
; (SP+3)  -> Zeiger auf Funktionsmummer
; (SP+3) <-  (SP+3)+1
; SP     <-  SP+2

Tab_branch	ex (sp),hl
		push af
		push bc
		push de
		ld bc,(Temp)
		push bc
		push hl

		ld (Temp),sp  ; SP -> HL
		ld hl,(Temp)

		inc hl        ; Zeiger auf Zeiger auf Tabelle -> HL
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl

		call Read_de
		ld a,(de)
		inc de        ; neu RÅcksprungadresse auf Stack
		call Write_de

		pop hl

		call Read_hl
		call Tab_add  ; Adresse der Rutine -> HL

		pop bc
		ld (Temp),bc
		pop de
		pop bc
		pop af

		ex (sp),hl

		ret	       ; Rutine ausfÅhren

; ---- Adress aus Tabelle holen ----
;
; A  <-> Index
; HL  -> Zeiger auf Tabelle
; HL <-  Tabelleneintrag
; CFL <- EQU1 ok, EQU0 Indexfehler
;
; Aufbau der Tabelle :
; Anzahl der EintrÑge ohne default, Default Sprung, Eintag1, ...

Tab_add         push af
		push bc

		cp (hl)      ; Test ob Eintag existiert
		inc hl
		jr nc,Tab_add_1

		inc hl       ; Defaultsprung Åberlesen
		inc hl

		ld b,0
		ld c,a

		sla b
		rl c

		or a
		add hl,bc

		call Read_hl

		pop bc
		pop af

		scf

		ret

Tab_add_1	call Read_hl

		pop bc
		pop af

		or a

		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Registertransfer Rutienen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- SP nach IY ----
; SP -> Iy

SP_TO_IY	push hl
			ld hl,(Temp1)
			push hl
			ld (Temp1),sp
			ld iy,(Temp1)
			inc iy
			inc iy
			inc iy
			inc iy
			inc iy
			inc iy
			pop hl
			ld (Temp1),hl
			pop hl
			ret 
			
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    diverse Hilfrutienen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Userprogramm starten ----
;
; (Reg_pc) -> Programmzeiger
; (Reg_sp) -> Stapelzeiger

User_go         ld (Sys_stack),sp
		ld sp,(Reg_sp)
		push hl
		ld hl,(Reg_pc)
		ex (sp),hl
		ret

			
Programm_ende

Help_text        .byte Pf_s,Pf_clrscr

.include "HELP.INC"

.byte 00h ; Ende des Hiflfstextes

Help_text_ende	

Ende