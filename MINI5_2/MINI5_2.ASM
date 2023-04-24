; *******************************************************************
; ****                                                           ****
; ****           Z80 MINI-EMUF Betriebssystem 05.01              ****
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
.include "Char.inc"
.include "Heap.inc"
.include "Task.inc"
.include "RtcObj.inc"
.include "GpioObj.inc"
.include "Dcf77Obj.inc"
.include "mini5_2.inc"
.include "GpioPortObj.inc"
.include "EncoderObj.inc"
.include "WifiClientObj.inc"
.include "MqttObj.inc"

xref Monitor
xref UserIf

xdef Timer1_IV
xdef Task_mem_start
xdef Task_mem_ende
xdef Bezeichner_mem_start
xdef Bezeichner_mem_ende
xdef Stack_mem_start
xdef Stack_mem_ende
xdef Kaltstart
xdef Version_text
xdef Hard_jmp_start
xdef Hard_jmp_end
xdef BetSysSegStart
xdef BetSysSegEnd
xdef DataSegStart
xdef DataSegEnd

.assume ADL=0

BetSysSegStart	.equ 0000h
BetSysSegEnd	.equ 5fffh
StackSegStart	.equ c000h
StackSegEnd		.equ C1ffh
TaskSegStart	.equ c200h
TaskSegEnd		.equ efffh
BezSegStart		.equ f000h
BezSegEnd		.equ f7ffh
DataSegStart    .equ f800h
DataSegEnd      .equ fc77h
IntTabSegStart	.equ fd00h
IntTabSegEnd	.equ fdffh
InfVektSegStart	.equ fe00h
IntVectSegEnd	.equ ffffh

.define BetsysSeg,Org=0h

.define StackSeg, org=StackSegStart
segment StackSeg
Stack_mem_start
.block StackSegEnd-StackSegStart+1
Stack_mem_ende

.define TaskSeg, org=TaskSegStart
segment TaskSeg
Task_mem_start
.block TaskSegEnd-TaskSegStart+1
Task_mem_ende

.define BezeichnerSeg,org=BezSegStart
segment BezeichnerSeg
Bezeichner_mem_start
.block BezSegEnd-BezSegStart+1
Bezeichner_mem_ende

.define DataSeg

.define InterruptTabelSeg,org=IntTabSegStart
InterruptTabel
.block 40h
It_40	.block 4
It_44	.block 4
It_48	.block 4
It_4c	.block 4
It_50	.block 4
It_54	.block 4
It_58	.block 4
It_5c	.block 4
It_60	.block 4
It_64	.block 4
It_68	.block 4
It_6c	.block 4
It_70	.block 4
It_74	.block 4
It_78	.block 4
It_7c	.block 4
It_80	.block 4
It_84	.block 4
It_88	.block 4
It_8c	.block 4
It_90	.block 4
It_94	.block 4
It_98	.block 4
It_9c	.block 4
It_a0	.block 4
It_a4	.block 4
It_a8	.block 4
It_ac	.block 4
It_b0	.block 4
It_b4	.block 4
It_b8	.block 4
It_bc	.block 4
It_c0	.block 4
It_c4	.block 4
It_c8	.block 4
It_cc	.block 4
It_d0	.block 4
It_d4	.block 4
It_d8	.block 4
It_dc	.block 4
It_e0	.block 4
It_e4	.block 4
It_e8	.block 4
It_ec	.block 4
It_f0	.block 4
It_f4	.block 4
It_f8	.block 4
It_fc	.block 4

.define InterruptVektorSeg,org=InfVektSegStart

; ---- Speicheraufteilung ----


Ramtest_start   EQU BetSysSegEnd+1
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
Md_bp           EQU  6
Md_mem          EQU  7
Md_ver          EQU  8
Md_baud         EQU  9
Md_datum        EQU 10
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
WaitCounter     EQU ((2000*(Sysclk/1000000))/50)
WaitStatesRam	EQU 1
Sysint_freq		EQU 1000
Def_baudrate    EQU 38400      ; 38400 Baud

WD_mode		EQU 3
TaskHeapSize	EQU 31
TimerHeapSize   EQU 31

PB_DDR_MASK		equ ENC_A|ENC_B|ENC_BUTTON|BUTTON|DCF_77
; EQUEQUEQUEQUEQU Konstanten der Hiflsfunktionen EQUEQUEQUEQU

Pre_bin         EQU '%'   ; Prexif fÅr bin %
Pre_dez         EQU '&'   ; Prexif fÅr dez &
Pre_hex         EQU '$'   ; Prexif fÅr hex $
Pre_asc         EQU 27h   ; Prexic fÅr ASCII '
Pre_bez         EQU '*'   ; Prexic fÅr Bezeichner *

Min_char        EQU 20h
Max_char        EQU 7eh

Start_jahr      EQU 1917          ; Jahr auf das sich die Datumsberechnung
				; bezieht, dieses Jahr muss eiem Schaltjahr
				; folgen, kein BCD-Format
Start_tag       EQU 1             ; ( 01.01.1917 war ein Montag )

; ---- Konstanten ----

AplicationPriority	EQU 20h
AplicationStackSize EQU 200h
BlinkPriority		EQU 40h
BlinkStackSize 		EQU 100h
UserIfPriority		EQU 10h
UserIfStackSize 		EQU 200h

Version_nr      EQU 0502h ; Version 05.01
Version_min     EQU 0400h ; Mindestversionsnummer fÅr Programme

Stack           EQU (Stack_mem_ende)&ffffh
Magic           EQU a5h   ; Magic-Code

Lcd_basis	EQU 0100h

; EQUEQUEQUEQU Variablen EQUEQUEQUEQUEQU

; ---- Hardware Sprungadresen ----

segment InterruptVektorSeg

InterruptVektors
Hard_jmp_start:
Nmi            .block 4 ; Startadresse der NMI-Rutine
Rst_08         .block 4 ; 04h
Rst_10         .block 4 ; 08h
Rst_18         .block 4 ; 0ch
Rst_20         .block 4 ; 10h
Rst_28         .block 4 ; 14h
Rst_30         .block 4 ; 18h
Rst_38         .block 4 ; IRM 1 Service-Rutine
				.block 4 ; 20h
				.block 4 ; 24h
				.block 4 ; 28h
				.block 4 ; 2ch
				.block 4 ; 30h
				.block 4 ; 34h
				.block 4 ; 38h
				.block 4 ; 3ch
Iv_40			.block 4 ; 40h
Iv_44			.block 4 ; 44h
Iv_48			.block 4 ; 48h
Iv_4c			.block 4 ; 4ch
Iv_50			.block 4 ; 50h
Timer0_IV
Iv_54			.block 4 ; 54h
Timer1_IV		
Iv_58			.block 4 ; 58h
Iv_5c			.block 4 ; 5ch
Iv_60			.block 4 ; 60h
Iv_64			.block 4 ; 64h
Iv_68			.block 4 ; 68h
Iv_6c			.block 4 ; 6ch
Uart0_IV
Iv_70			.block 4 ; 70h
Iv_74			.block 4 ; 74h
Iv_78			.block 4 ; 78h
Iv_7c			.block 4 ; 7ch
Iv_80			.block 4 ; 80h
Iv_84			.block 4 ; 84h
Iv_88			.block 4 ; 88h
Iv_8c			.block 4 ; 8ch
Iv_90			.block 4 ; 90h
Iv_94			.block 4 ; 94h
Iv_98			.block 4 ; 98h
Iv_9c			.block 4 ; 9ch
Iv_a0			.block 4 ; a0h
Iv_a4			.block 4 ; a4h
Iv_a8			.block 4 ; a8h
Iv_ac			.block 4 ; ach
Iv_b0			.block 4 ; b0h
Iv_b4			.block 4 ; b4h
Iv_b8			.block 4 ; b8h
Iv_bc			.block 4 ; bch
Iv_c0			.block 4 ; c0h
Iv_c4			.block 4 ; c4h
Iv_c8			.block 4 ; c8h
Iv_cc			.block 4 ; cch
Iv_d0			.block 4 ; d0h
Iv_d4			.block 4 ; d4h
Iv_d8			.block 4 ; d8h
Iv_dc			.block 4 ; dch
Iv_e0			.block 4 ; e0h
Iv_e4			.block 4 ; e4h
Iv_e8			.block 4 ; e8h
Iv_ec			.block 4 ; ech
Iv_f0			.block 4 ; f0h
Iv_f4			.block 4 ; f4h
Iv_f8			.block 4 ; f8h
Iv_fc			.block 4 ; fch

Hard_jmp_end:
	
segment DataSeg
Sys_mem_start

; ---- Betriebsystemvariabeln ----

User_break_jmp  .block 2 ; Zeiger auf User-Break-Rutine
Stdout		 .block 2
SerialOut	 .block 2
EspSerialOut .block 2
SystemTicks	 .block 2

; ---- lokale Variablen ----

Temp		.block 2
Temp1		.block 2
TaskTemp	.block 2
AktTask		.block 2

Meldung         .block 1
Int_count       .block 1 ; Interrupt-verhinderungs ZÑhler
Akt_page        .block 1           ; aktuelle Speicherseite
Auto_magic      .block 1 ; Magic-Byte fÅr Autostart
Auto_vek        .block 2 ; Vektor fÅr Autostart
Batterie_puff   .block 1 ; Magic-Byte fÅr Batteriepufferung
Lcd_initstatus	.block 1 ; EQU0 Lcd Fehler, sonst LCD ok
TimerTask		.block 2
NextTime		.block 2

; ---- Variablen fÅr den Debuger ----

Sys_stack       .block 2

Reg_pc          .block 2
Reg_ix          .block 2

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

; ---- Variablen fÅr die Speicherverwaltung ----

Mem_ges         .block 2 ; geamter instalierter Speicher
Free_add        .block 2 ; Zeiger auf freien Spiecher
Geraet          .block 2 ; Zeiger auf Geraete-Speicher
Ob_add          .block 2 ; Zeiger auf Unterblock bei Mem_sweep
Block_z         .block 2 ; Blockparameter
Block_a         .block 2
Block_l         .block 2

TaskHeap		.block 2
TimerHeap		.block 2

; ---- Variablen fÅr LCD Objekt ----

LcdPointer		.block 2

; EQUEQUEQUEQU Programtext EQUEQUEQUEQU

RtcPointer		.block 2
Dcf77Pointer	.block 2
PortA_Pointer	.block 2
PortB_Pointer	.block 2
PortC_Pointer	.block 2
PortD_Pointer	.block 2
EncoderPointer  .block 2
WifiClient		.block 2
MqttClient		.block 2

segment BetsysSeg
.assume ADL=0

Start;
		; rst 00h, Code C7h

		di
		jp.lil Kaltstart
		.byte ffh,ffh

		; rst 08h, Code CFh

		push hl
		ld hl,(Rst_08)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 10h, Code D7h

		push hl
		ld hl,(Rst_10)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 18h, Code DFh

		push hl
		ld hl,(Rst_18)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 20h, Code E7h

		push hl
		ld hl,(Rst_28)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 28h, Code EFh
		
		push hl
		ld hl,(Rst_28)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 30h, Code F7h

		push hl
		ld hl,(Rst_30)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; rst 38h, Code FFh, IRM 1 Service-Rutine

		push hl
		ld hl,(Rst_38)
		ex (sp),hl
		ret

		.byte ffh,ffh

		; Bereich zum nachbrennen im EPROM

		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh
		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh
		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh
		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh
		.byte ffh,ffh,ffh,ffh,ffh,ffh

		push hl ; NMI-Rutine
		ld hl,(Nmi)
		ex (sp),hl
		ret

		.byte ffh,ffh,ffh,ffh

		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh
		.byte ffh,ffh,ffh,ffh,ffh,ffh,ffh,ffh


; ********************************************************************
; **		       						    **
; **    Bootrutiene                                                 **
; **		       						    **
; ********************************************************************

Version_name   	.byte "Z80-Mini "
		.byte ( Version_nr >> 12 ) & 0fh + '0'
		.byte ( Version_nr >>  8 ) & 0fh + '0'
		.byte '.'
		.byte ( Version_nr >>  4 ) & 0fh + '0'
		.byte ( Version_nr >>  0 ) & 0fh + '0'
		.byte 0

Version_c	.byte "(c) 25.09.2020",0

Version_text    .byte Pf_s,Pf_str | Pf_nn, Version_name & ffh, Version_name >> 8
		.byte " "
		.byte Pf_s,Pf_str | Pf_nn, Version_c & ffh, Version_c >> 8,0

.assume ADL=1

Kaltstart	ld a,10001000b		; Flash 4 wait states, enabeld
			out0 (FLASH_CTRL),a

			ld a,~LED_GE		; gelbe Led einschalten
			out0 (PB_DR),a
			out0 (PB_DDR),a
			
			ld a,ffh				; Internen Ram nach ffe0000h
			out0 (RAM_ADDR_U),a
			ld a,11000000b
			out0 (RAM_CTL),a
			
			ld sp,000000h
			
			call SetupSystem
			
			ld a,0					; Internen RAM abschalten
			out0 (RAM_CTL),a
			jp.sis Kaltstart_3

.assume ADL=0

; TODO
Kaltstart_3 
;ld a,(Batterie_puff)
;			jp Magic
;			jr z,Kaltstart_4
;			
;			ld a,ffh
;			ld (hl),a
;			inc hl
;			ld a,h
;			or a,l
;			jr nz,Kaltstart_3

Kaltstart_4 
		ld a,0
		ld sp,Stack   ; Stackpointer setzen
		
		push af
		push hl

		call Int_reset

;		ld a,WD_mode   ; Watchdog aktiveiren
;		call WD_eneb

		ld hl,100 ; Warten bis alle Zeichen aus SIO-Puffer gesendet
		call Wait
;		call WD_clear

		call Io_reset ; IO-Bausteine zurÅcksetzen
		call Grund_init
		call Sysint_init

		ld b,Gpio_PortA
		call GpioPortObj
		ld (PortA_Pointer),hl
		
		ld b,Gpio_PortB
		call GpioPortObj
		ld (PortB_Pointer),hl
		
		ld ix,hl
		ld a,GpioModeOutput
		ld b,LED_GR|LED_GE
		call Objekt_call
		.byte GpioPortObj_SetMode
		
		ld b,Gpio_PortC
		call GpioPortObj
		ld (PortC_Pointer),hl
		
		ld b,Gpio_PortD
		call GpioPortObj
		ld (PortD_Pointer),hl
		
		call Aux_init

		call Lcd_init
		ld a,0
		adc a,0
		ld (Lcd_initstatus),a
		
		call WifiClientObj
		ld (WifiClient),hl

		call MqttObj
		ld (MqttClient),hl
		
		call RtcObj
		ld (RtcPointer),hl
		
		call Dcf77Obj
		ld (Dcf77Pointer),hl

		ld b,ffh
		ld c,0
		call EncoderObj
		ld (EncoderPointer),hl

		call Int_eneb ; Interrupt freigebnen
		
		call Header_out
		call Autostart
		call Hardware_test ; Test und Speicher fÅllen
		call Newline

		ld ix,(PortB_Pointer)
		ld b,LED_GE
		call Objekt_call
		.byte GpioPortObj_SetMask

		pop hl
		pop af

		ld a,BlinkPriority
		ld hl,Blink
		ld bc,BlinkStackSize
		call TaskObj
		call ScheduleNow	
		
		ld a,AplicationPriority
		ld hl,Aplikation
		ld bc,AplicationStackSize
		call TaskObj
		call ScheduleNow

		ld a,UserIfPriority
		ld hl,UserIf
		ld bc,UserIfStackSize
		call TaskObj
		call ScheduleNow
		
		call Yield
		
		jp Leerlauf

; --- Blinktast ----

Blink
		ld ix,(PortB_Pointer)
		ld b,LED_GR
		call Objekt_call
		.byte GpioPortObj_InvertMask
		
		ld hl,500
		
		call Timer
		
		jr Blink

; ---- Encoder hohlen ----

GetEncoder
		ld ix,(EncoderPointer)
		ret
		

; ---- Header ausgeben ----

Header_out
		push af
		push ix
		
		ld ix,(Stdout)
		call Objekt_call
		.byte SerialObj_GetBaud
		
		ld ix,(LcdPointer)
		call Printf_obj
		.byte Pf_s,Pf_aus,Pf_s,Pf_str | Pf_nn
		.word Version_name
		.byte Cr,Lf
		.byte Pf_s,Pf_str|Pf_nn
		.word Version_c
		.byte Cr,Lf,Pf_s,Pf_dez,"-8N1 VT100",Cr,Lf,0

		call Printf
		.byte Cr,Lf
		.byte Pf_s,Pf_clrscr
		.byte " ---- ",Pf_s,Pf_str | Pf_nn
		.word Version_text
		.byte " ---- ",Cr,Lf,Cr,Lf,0
		
		pop ix
		pop af
		
		ret
		
; ---- Autostart-Rutine ----

Autostart
		push af
		push bc
		push hl
		
		ld a,(Auto_magic)
		cp Magic
		jp nz,Autostart_6

		call Printf
		.byte "Autostart-Rutine bei ",Pf_s,Pf_hex | Pf_nn | Pf_ind
		.word Auto_vek
		.byte " ( Abbruch mit ESC"
		.byte " oder CTRL-Z ) ",0

		ld b,30    ; 3 Sekunde warten
		ld hl,100

Autostart_2     
		call Wait

		call Char_get_non_blocking
		jr nc,Autostart_3

		call Char_get
		call In_str
		.byte Ctrl_z,Esc,0
		jr c,Autostart_5
		jr Autostart_4

Autostart_3     
		djnz Autostart_2

Autostart_4     call Printf  ; Rutine ausfuehren
		.byte "aktiviert",Cr,Lf,Cr,Lf,0

		ld hl,Autostart_6
		push hl           ; RÅcksprungadresse aud Stack
		ld hl,(Auto_vek)  ; Rutine ausfÅhren
		push hl
		call All_sent
		call Reg_clr
		ret

Autostart_5     call Printf
		.byte "ignoriert",Cr,Lf,Cr,Lf,0

Autostart_6
		pop hl
		pop bc
		pop af
		
		ret
		
; ---- Grundinitialisierung ----

Grund_init      
		push af
		push bc
		push de
		push hl
		
		im 2
		ld a,HIGH(InterruptVektors)
		ld i,a

		ld de,Guru128           ; Default Int Vekt. auf Guru 128
		ld b,80h		
		ld hl,InterruptTabel
		ld a,00h
Grund_init_2
		ld c,l
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld (hl),c
		inc hl
		ld (hl),a
		inc hl
		djnz Grund_init_2		

		ld hl,InterruptVektors+40h
		ld bc,IntVect_44-IntVect_40
		ld de,IntVect_40
		ld a,ffh
Grund_init_3
		ld (hl),e
		inc hl
		ld (hl),d
		inc hl
		ld a,ffh
		ld (hl),a
		inc hl
		ld (hl),a
		inc hl
		push hl
		ld hl,de
		add hl,bc
		ld de,hl
		pop hl
		ld a,l
		or a,a
		jr nz,Grund_init_3
		
		ld hl,Guru131
		ld (Nmi),hl

		ld hl,0
		ld (User_break_jmp),hl

		ld hl,Bet_call
		ld (Rst_08),hl
		ld hl,User_break
		ld (Rst_38),hl
		ld hl,0 ; Geraete und Speicher lîschen
		ld (Mem_ges),hl
		ld (Geraet),hl
		ld (Free_add),hl

		ld hl,Task_mem_start
		ld bc,Task_mem_ende-Task_mem_start
		call Mem_inst

		ld hl,Bezeichner_mem_start
		ld bc,Bezeichner_mem_ende-Bezeichner_mem_start
		call Bez_clr

		ld hl,TaskCompare
		ld b,TaskHeapSize
		ld c,2
		call HeapObj
		ld (TaskHeap),hl
		
		ld hl,TimerCompare
		ld b,TimerHeapSize
		ld c,4
		call HeapObj
		ld (TimerHeap),hl
		
		ld hl,0
		ld (AktTask),hl
		ld hl,0
		ld (AktTask),hl
		
		pop hl
		pop de
		pop bc
		pop af
		
		ret
		
.assume ADL=1

; ---- System einrichten ----
; PLL aktivieren
; Betiebssystem in den RASM Kopieren
; Speicheraufteilung initiualisieren

SetupSystem     push af
				push hl
				push bc
				push de
				
				ld a,0
				out0 (FLASH_ADDR_U),a
				ld a,4 << 5 | 00001000b
				
				; load PLL divider
				ld.lis hl, OscFreqMult
				ld a, l
				out0 (PLL_DIV_L), a
				ld a, h
				out0 (PLL_DIV_H), a
				; Set charge pump and lock criteria
				ld a, 41h
				and a, %CC  ; mask off reserved and clock source bits
				out0 (PLL_CTL0), a
				; enable PLL
				in0 a, (PLL_CTL1)
				set 0, a
				out0 (PLL_CTL1), a
				; wait for PLL to lock
SetupSystem_1
				in0 a, (PLL_CTL1)
				and a, LCK_STATUS
				cp a, LCK_STATUS

				jr nz, SetupSystem_1
				; select PLL as system clock source
				ld a, 41h
				set 0, a
				out0 (PLL_CTL0), a

				ld a,0
				out0 (CS2_CTL),a
				out0 (CS3_CTL),a

				ld a,10h
				out0 (CS1_LBR),a
				ld a,10h
				out0 (CS1_UBR),a

			ld a,00001000b | (WaitStatesRam << 5)
			out0 (CS1_CTL),a

			ld a,HIGH(Lcd_basis)
			out0 (CS0_LBR),a
			ld a,11111000b
			out0 (CS0_CTL),a
			ld a,10001111b
			out0 (CS0_BMC),a	
			
			; TODO 
			ld hl,100000h
			ld de,BetSysSegStart
			ld bc,BetSysSegEnd+1
			
SetupSystem_2
			ld a,(de)			
			ld (hl),a
			cp a,(hl)
			dec bc
			inc hl
			inc de
			ld a,b
			or a,c
			jr nz,SetupSystem_2

			ld a,00000000b | (WaitStatesRam << 5)
			out0 (CS1_CTL),a

			ld a,00h
			out0 (CS1_LBR),a
			ld a,00h
			out0 (CS1_UBR),a

			ld a,00001000b |  (WaitStatesRam << 5)
			out0 (CS1_CTL),a
			
			ld a,4 << 5
			out0 (FLASH_CTRL),a

			pop de
			pop bc
			pop hl
			pop af
			
			ret
			
.assume ADL=0

; ---- Ramtest ----
;
; BC   -> Anfang des Bereichs
; DE   -> Ende des Bereichs ( DE EQU> BC )
; HL  <-  Adresse bei Fehler
; CFL <- EQU1 ok, EQU0 Fehler
;
; zerstîrt nur AF, BC, DE, HL
;

Ramtest	call Ber_len
		call Invert_c
		ret c   ; Bereich leer

Ramtest_1       call Int_dis

		ld d,(hl) ; alten Speicherinhalt sichern

		ld a,10101010b
		ld (hl),a
		cp (hl)
		jr nz,Ramtest_2
		ld a,01010101b
		ld (hl),a
		cp (hl)
		jr nz,Ramtest_2

		ld (hl),d ; alten Speicherinhalt zurÅckschreiben

		call Int_old

		cpi
		jp pe,Ramtest_1

		scf
		ret

Ramtest_2       call Int_old

		or a
		ret

; ---- Hardware-Test ----
;

Hardware_test   call Printf
		.byte "Checksumme  : ",0

		ld bc,Start
		ld de,Ende-1
		call Bereich_out

		xor a        ; Startwert 0
		call Chksum_test

		call Space_out
		call Hexout
		call Space_out
		or a
		call z,Hardware_test_o
		call nz,Hardware_test_f
		call Newline

		call Printf
		.byte "Ramtest     : ",0

		ld bc,Ramtest_start
		ld de,Ramtest_ende

		call Bereich_out
		call Ramtest
		call Space_out

		call c,Hardware_test_o
		jr c,Hardware_test_1

		call Hardware_test_f
		call Space_out
		call Hl_out

Hardware_test_1 call Newline

		call Printf
		.byte "Batterie    : ",0
		ld a,(Batterie_puff)
		cp Magic
		ld a,Magic
		ld (Batterie_puff),a
		call z,Hardware_test_o
		call nz,Hardware_test_f

		call Newline

		call Printf
		.byte "LCD-Display : ",0
		
		ld a,(Lcd_initstatus)
		or a
		call nz,Hardware_test_o
		call z,Hardware_test_f

		call Newline

		ret

Hardware_test_o ld a,28
		call Crsr_spalte
		call Printf
		.byte "OK",0
		ret

Hardware_test_f ld a,28
		call Crsr_spalte
		call Printf
		.byte "Fehler",0
		ret

; ---- Leerlaufprozess ----

Leerlauf	jr Leerlauf

; ---- Guru-Meditation Errors ----

Guru128         push af
		ld a,128 ; Unbekanntes Interruput aufgetreten
		jr Guru

Guru129         push af
		ld a,129 ; fehlerhafte Interruput-Verschachtelung
		jr Guru

Guru130         push af
		ld a,130 ; illegaler Betriebssystemaufruf
		jr Guru

Guru131         push af
		ld a,131 ; NMI aufgetreten
		jr Guru

Guru132         push af
		ld a,132 ; I/O Fehler
		jr Guru

Guru133         push af
		ld a,133 ; Fifo voll
		jr Guru

Guru134         push af
		ld a,134 ; Interner Fehler
		jr Guru

Guru135         push af
		ld a,135 ; Interner Fehler
		jr Guru

Guru136         push af
		ld a,136 ; Ilegaler Methodenaufruf
		jr Guru

Guru137	push af	; Taskpuffer voll
		ld a,137
		jr Guru
		
; ---- Guru ----
;
; A -> Nr. des Gurus
; (SP) -> alten Akku
; (SP) -> Adresse des Fehlers

Guru    ld (Meldung),a

		pop af

		ld sp,Stack

		push af
		push hl
		push bc
		push de
		push ix
		
		ld (Reg_ix),ix
		
		call Int_reset
		call Grund_init
		call Sysint_init
		call Aux_init
		call Lcd_init
		call Int_eneb

Guru_1  ld ix,(LcdPointer)
		ld a,(Meldung)
		ld l,a
		
		call Printf_obj
		.byte Pf_s,Pf_clrscr,"GURU ",Pf_s,Pf_hex | Pf_byte,Cr,Lf,0

		and 01111111b
		ld hl,Guru_meld
		call Objekt_call
		.byte PrintfObj_MeldOut

		call Printf_obj
		.byte Cr,Lf,"PC: ",Pf_s,Pf_nn|Pf_hex|Pf_ind
		.word Reg_pc
		.byte " IX: ",Pf_s,Pf_nn|Pf_hex|Pf_ind
		.word Reg_ix
		.byte 0

		ld a,(Meldung)

		ld l,a
		call Printf
		.byte Pf_s,Pf_clrscr,Cr,Lf," ===========",Cr,Lf
		.byte" = GURU ",Pf_s,Pf_hex | Pf_byte," =",Cr,Lf
		.byte " ===========",Cr,Lf,Cr,Lf," ",0

		and 01111111b
		ld hl,Guru_meld
		call Meld_out
		
		call Printf
		.byte Cr,Lf
		.byte Cr,Lf," PC: ",Pf_s,Pf_nn|Pf_hex|Pf_ind
		.word Reg_pc
		.byte " IX: ",Pf_s,Pf_nn|Pf_hex|Pf_ind
		.word Reg_ix
		.byte Cr,Lf,Cr,Lf," Taste drueken!",Cr,Lf,Cr,Lf," ",0
		.byte 0

		call Char_get
		
		pop ix
		pop de
		pop bc
		pop hl
		pop af
		
		jp Aplikation

Guru_meld:       .byte "unbekanntes Interrupt",0 
		.byte "fehlerhafte Interrupt-Verschachtelung",0
		.byte "illegaler Betriebssystemaufruf",0
		.byte "NMI aufgetreten ( Watchdog )",0
		.byte "I/O Fehler",0
		.byte "Fifo voll",0
		.byte "interner Fehler",0
		.byte "Syteminterrupt ‹berlauf",0
		.byte "Ilegaler Methodenaufruf",0
		.byte "Taskpuffer voll",0
		.byte 0

; ---  Einsprung in die Anwmdung ----

Aplikation
		jp Monitor
		

; ********************************************************************
; **		       						    **
; **     Betriebssystem  					    **
; **		       						    **
; ********************************************************************

; ---- IO Bausteine und Daisy-Chain zurÅcksetzen ----

Io_reset
		push af
		
		ld a,~LED_GE
		out0 (PB_DR),a
		out0 (PB_DDR),a
		
		ld a,11111111b		; alle Ports auf Eingabe
		out0 (PA_DDR),a
		out0 (PC_DDR),a
		out0 (PD_DDR),a
		
		ld a,0				; GPIO Interrupts disablen
		out0 (PA_ALT1),a
		out0 (PB_ALT1),a
		out0 (PC_ALT1),a
		out0 (PD_ALT1),a
		out0 (PA_ALT2),a
		out0 (PB_ALT2),a
		out0 (PC_ALT2),a
		out0 (PD_ALT2),a
		
		ld a,0				; Timer Interrupts disablen
		out0 (TMR0_IER),a
		out0 (TMR1_IER),a
		out0 (TMR2_IER),a
		out0 (TMR3_IER),a
		
		ld a,0				; RTC Interrupt disablen
		out0 (RTC_CTRL),a
		
		ld a,0				; UART Interrupts disablen
		out (UART0_IER),a		
		out (UART1_IER),a
		
		pop af
		ret

; ---- serielle öbertragung initialisieren ----

Aux_init        
		push af
		push hl
		ld a,0
		call SerialObj
		ld (Stdout),hl
		ld (SerialOut),hl
		ld a,1
		call SerialObj
		ld (EspSerialOut),hl
		pop hl
		pop af
		ret

; ---- LCD initialisieren ----

Lcd_init        
		push hl
		push bc
		ld bc,Lcd_basis
		call LcdObj
		ld (LcdPointer),hl
		pop bc
		pop hl

		ret

; ---- 100Hz Systeminterrupt initialisieren ----

Sysint_init	
		push af
		push hl

		ld hl,Sys_interrupt
		ld (Timer0_IV),hl

		ld hl,0
		ld (SystemTicks),hl
		
		ld a,LOW(Sysclk/Sysint_freq/16)
		out0 (TMR0_RR_L),a
		ld a,HIGH(Sysclk/Sysint_freq/16)
		out0 (TMR0_RR_H),a
		ld a,10001111b
		out0 (TMR0_CTL),a
		ld a,00000001b
		out0 (TMR0_IER),a


		pop hl
		pop af
		ret

; ---- Timer Copmpare ----
; HL -> Zeiger auf Zeit 1
; BC -> Zeiger auf Zeit 2
; CFL <- =1 Zeit2 > Zeit 1, sonst =0

TimerCompare
		push af
		push bc
		push de
		push hl
		
		inc hl
		inc hl
		inc bc
		inc bc
		
		ld de,(SystemTicks)
		
		call Read_hl
		or a,a
		sbc hl,de
		
		push hl
		ld hl,bc
		call Read_hl
		or a,a
		sbc hl,de
		ld bc,hl
		pop hl
		
		or a,a
		sbc hl,bc
		jr nc,TimerCompare1
		
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
		
TimerCompare1
		pop hl
		pop de
		pop bc
		pop af
		or a,a
		ret

; ---- 100Hz System-Interruptrutiene ----

Sys_interrupt   
		push af
		push bc
		push hl
		push ix

		in0 a,(TMR0_IIR)

		call Int_dis
		
		ld hl,TimerTask
		ld ix,(TimerHeap)
		call Objekt_call
		.byte HeapObj_Top
		jr nc,Sys_interrupt3

		ld hl,(SystemTicks)
		ld bc,(NextTime)

		or a,a
		sbc hl,bc
		jr nz,Sys_interrupt3
		
		ld hl,(TimerTask)
		call ScheduleNow

		ld hl,TimerTask
		call Objekt_call
		.byte HeapObj_Get
		
Sys_interrupt1
		ld hl,TimerTask
		ld ix,(TimerHeap)
		call Objekt_call
		.byte HeapObj_Top
		jr nc,Sys_interrupt2

		ld hl,(SystemTicks)
		ld bc,(NextTime)

		or a,a
		sbc hl,bc
		jr nz,Sys_interrupt2
		
		ld hl,(TimerTask)
		call ScheduleNow

		ld hl,TimerTask
		call Objekt_call
		.byte HeapObj_Get
		
		jr Sys_interrupt1

Sys_interrupt2
		ld hl,(SystemTicks)
		inc hl
		ld (SystemTicks),hl

		pop ix
		pop hl
		pop bc
		pop af
		
		call Yield
		
Sys_interrupt3
		ld hl,(SystemTicks)
		inc hl
		ld (SystemTicks),hl

		pop ix
		pop hl
		pop bc
		pop af
		
		call Int_ret
; 
; ---- Betriebssystem aufrufen ----

Bet_call	call Tab_branch
		.word Bet_tab

; ---- Tabelle der Betriebssystem-Funktionen ----

Bet_tab:		.byte Betcall_zahl
		.word Guru130

		; Funktion 00h, ab 04.00

Betn_Ver_test   .equ 0
;		.xdef Betn_Ver_test
		.word Ver_test
		; Funktion 01h, ab 04.00

Betn_Warmstart  .equ 1
;		.xdef Betn_Warmstart
		.word Warmstart

		; ( Funktion 02h, ab 04.00, veraltet ab 4.01 )

		.word Guru130

		; ( Funktion 03h, ab 04.00, veraltet ab 4.01 )

		.word Guru130

		; Funktion 04h, ab 04.00

Betn_Char_out   .equ 4
;		.xdef Betn_Char_out
		.word Char_out

		; ( Funktion 05h, ab 04.00, veraltet ab 4.01 )

		.word Hexout

		; ( Funktion 06h, ab 04.00, veraltet ab 4.01 )

		.word Hl_out

		; ( Funktion 07h, ab 04.00, veraltet ab 4.01 )

		.word Bin_out

		; Funktion 08h, ab 04.00

Betn_Char_da    .equ 8
;		.xdef Betn_Char_da
		.word Guru130

		; Funktion 09h, ab 04.00

Betn_Char_get   .equ 9
;		.xdef Betn_Char_get
		.word Char_get

		; Funktion 0Ah, ab 04.00

Betn_Meld_out    .equ 0ah
;		.xdef Betn_Meld_out
		.word Meld_out

		; Funktion 0Bh, ab 04.00

Betn_Line_get  .equ 0bh
;		.xdef Betn_Line_get
		.word Line_get

		; Funktion 0Ch, ab 04.00

Betn_Time_in    .equ 0ch
;		.xdef Betn_Time_in
		.word Time_in

		; ( Funktion 0Dh, ab 04.00, veraltet ab 4.01 )

		.word Datum_in_alt

		; ( Funktion 0Eh, ab 04.00, veraltet ab 4.01 )

		.word Time_out

		; Funktion 0Fh, ab 04.01

Betn_Int_dis   .equ 0fh
;		.xdef Betn_Int_dis
		.word Int_dis

		; Funktion 10h, ab 04.01

Betn_Int_old    .equ 10h
;		.xdef Betn_Int_old
		.word Int_old

		; Funktion 11h, ab 04.01

Betn_Relocate   .equ 11h
;		.xdef Betn_Relocate
		.word Relocate

		; Funktion 12h, ab 04.01

Betn_Mem_max    .equ 12h
;		.xdef Betn_Mem_max
		.word Mem_max

		; Funktion 13h, ab 04.01

Betn_Mem_Alloc  .equ 13h
;		.xdef Betn_Mem_Alloc
		.word Mem_alloc

		; Funktion 14h, ab 04.01

Betn_Mem_size   .equ 14h
;		.xdef Betn_Mem_size
		.word Mem_size

		; Funktion 15h, ab 04.01

Betn_Mem_shrink .equ 15h
;		.xdef Betn_Mem_shrink
		.word Mem_shrink

		; Funktion 16h, ab 04.01

Betn_Mem_free   .equ 16h
;		.xdef Betn_Mem_free
		.word Mem_free

		; Funktion 17h, ab 04.01

Betn_Tagnummer  .equ 17h
;		.xdef Betn_Tagnummer
		.word Tagnummer

		; Funktion 18h, ab 04.01

Betn_Guru       .equ 18h
;		.xdef Betn_Guru
		.word Guru134

		; Funktion 19h, ab 04.01

Betn_Meld_obj_out .equ 19h
;		  .xdef Betn_Meld_obj_out
		  .word Guru130

		 ; Funktion 1Ah, ab 04.01

Betn_Tagnr2datum .equ 1ah
;		.xdef Betn_Tagnr2datum
		.word Tagnr2datum

		; Funktion 1Bh, ab 04.01

Betn_Wait       .equ 1bh
;		.xdef Betn_Wait
		.word Wait

		; Funktion 1Ch, ab 04.01

Betn_Bez_set    .equ 1ch
;		.xdef Betn_Bez_set
		.word Bet_Bez_set

		; Funktion 1Dh, ab 04.01

Betn_Bez_get    .equ 1dh
;		.xdef Betn_Bez_get
		.word Bet_Bez_get

		; Funktion 1Eh, ab 04.01

Betn_Bez_del    .equ 1eh
;		.xdef Betn_Bez_del
		.word Bet_Bez_del

		; Funktion 1Fh, ab 04.01

Betn_Objekt_call .equ 1fh
;		 .xdef Betn_Objekt_call
		 .word Objekt_call

		; Funktion 20h, ab 04.01

Betn_Tab_branch .equ 20h
;		.xdef Betn_Tab_branch
		.word Tab_branch

		; Funktion 21h, ab 04.01

Betn_Bcd2bin    .equ 21h
;		.xdef Betn_Bcd2bin
		.word Bcd2bin

		; Funktion 22h, ab 04.01

Betn_Get_stdout .equ 22h
;		.xdef Betn_Get_stdout
		.word Get_stdout

		; Funktion 23h, ab 04.01

Betn_Printf_obj .equ 23h
;		.xdef Betn_Printf_obj
		.word Printf_obj

		; Funktion 24h, ab 04.01

Betn_Divi       .equ 24h
;		.xdef Betn_Divi
		.word Divi

		; Funktion 25h, ab 04.01

Betn_Multi      .equ 25h
;		.xdef Betn_Multi
		.word Multi

		; Funktion 26h, ab 04.01

Betn_Menu_branch .equ 26h
;		 .xdef Betn_Menu_branch
		 .word Menu_branch

		; Funktion 27h, ab 04.01

Betn_Get_lcdout .equ 27h
;		.xdef Betn_Get_lcdout
		.word Get_lcdout

		; Funktion 28h, ab 04.01

Betn_Get_sioout .equ 28h
;		.xdef Betn_Get_sioout
		.word Get_sioout

		; Funktion 29h, ab 04.01

Betn_Printf	 .equ 29h
;		.xdef Betn_Printf
		.word Printf

		; Funktion 2Ah, ab 04.01

Betn_Wort_in	 .equ 2ah
;		.xdef Betn_Wort_in
		.word Guru130

		; Funktion 2Bh, ab 04.01

Betn_Zahl_in	 .equ 2bh
;		.xdef Betn_Zahl_in
		.word Zahl_in

		; Funktion 2Ch, ab 04.01

Betn_Kom_add    .equ 2ch
;		.xdef Betn_Kom_add
		.word Kom_add

		; Funktion 2Dh, ab 04.01

Betn_Mem_fill   .equ 2dh
;		.xdef Betn_Mem_fill
		.word Mem_fill

		; Funktion 2Eh, ab 04.01

Betn_Mem_move   .equ 2eh
;		.xdef Betn_Mem_move
		.word Mem_move

		; Funktion 2Fh, ab 04.01

Betn_Datum_in   .equ 2fh
;		.xdef Betn_Datum_in
		.word Datum_in

		; Funktion 30h, ab 04.01

Betn_Calc_wochentag .equ 30h
;		    .xdef Betn_Calc_wochentag
		    .word Calc_wochentag

		; Funktion 31h, ab 04.01

Betn_Sysint_set	.equ 31h
;		.xdef Betn_Sysint_set
		.word Guru130

		; Funktion 32h, ab 04.01

Betn_Sysint_clr	.equ 32h
;		.xdef Betn_Sysint_clr
		.word Guru130
		
		; Function 33h
		.word Objekt_SuperJmp
		
		; Function 34h
		.word SetIntVek

		; Function 35h
		.word ClrIntVek
		
		; Funktion 36h
		.word Int_eneb
		
		;Funktion 37h
		.word Get_StdOut
		
		;Funktion 38h
		.word Char_get_non_blocking
		
		;Funktion 39h
		.word Pointprn

		;Funktion 3ah
		.word Set_AutoStart
		
		;Funktion 3bh
		.word SetUserBreakVektor
		
		;Funktion 3ch
		.word ScheduleNow
		
		;Funktion 3dh
		.word Yield
		
		;Funktion 3eh
		.word Suspend
		
		;Funktion 3fh
		.word GetAktTask
		
		;Funktion 40h
		.word Timer
		
		;Funktion 41h
		.word Get_rtc
		
		;Funktion 42h
		.word Get_PortB
		
		;Funktion 43h
		.word Get_Timer
		
		;Funktion 44h
		.word GetEncoder
		
		;Funktion 45h
		.word Get_PortA
		
		;Funktion 46h
		.word Get_dcf
		
		;Funktion 47h
		.word Calc_DOW
		
		;Funktion 48h
		.word Int_ret
		
		;Funktion 49h
		.word Get_EspOut
		
		;Funktion 4Ah
		.word Get_PortC
		
		;Funktion 4Bh
		.word Get_PortD
		
		;Funktion 4ch
		.word Chancel_Task
		
		;Funktion 4dh
		.word Get_WifiClient
		
		;Funktion 4eh
		.word Space_ignore

		;Funktion 4fh
		.word Get_MqttClient		
		
Betcall_zahl    .equ 50h

; --- Timer ----
; HL -> Wartezeit in ms
; CFL <- =1 OK; =0 Fehler

Timer		push af
			push bc
			push hl
			push ix
			
			push hl
			ld hl,(AktTask)
			call Test_HL
			pop hl
			jr z,Timer4
			call Test_HL
			jr z,Timer1
			ld ix,(TimerHeap)
			call Int_dis
			ld bc,(SystemTicks)
			add hl,bc
			ld (NextTime),hl
			ld hl,(AktTask)
			ld (TimerTask),hl
			ld hl,TimerTask
			call Objekt_call
			.byte HeapObj_Put
			call Int_old
			jr nc,Timer2
			ld hl,TimerChancel
			call Suspend
Timer1
			pop ix
			pop hl
			pop bc
			pop af
			scf
			ret
Timer2		pop ix
			pop hl
			pop bc
			pop af
			or a,a
			ret

Timer4		call Wait
			pop ix
			pop hl
			pop bc
			pop af
			scf
			ret

; ---- Timer Task Chanceln ----
; HL -> Zeiger auf Task

TimerChancel
			push af
			push hl
			push ix
			ld ix,(TimerHeap)
			call Objekt_call
			.byte HeapObj_Remove
			pop ix
			pop hl
			pop af
			ret
			
; ---- aktuelle Task Holen ----
; HL <- aktuelle Task

GetAktTask	ld hl,(AktTask)
			ret
			
; ---- Aktuelle Tasks anhalten ----
; HL -> Zeiger auf ChancelCallback
; IX -> Chancel callback enviorment

Suspend		push af
			push hl
			call Int_dis
			ld hl,(AktTask)
			call Test_HL
			jr z,Suspend1
			pop hl
			pop af

			push ix
			push iy
			push hl
			push de
			push bc
			push af
			exx
			ex Af,AF'
			push hl
			push de
			push bc
			push af
			
			ld (TaskTemp),sp
			
			exx
			
			push ix
			ld ix,(AktTask)
			ld (ix+TaskObj_ChancelCallback),l
			ld (ix+TaskObj_ChancelCallback+1),h
			pop hl
			
			ld (ix+TaskObj_ChancelEnv),l
			ld (ix+TaskObj_ChancelEnv+1),h
			ld hl,(TaskTemp)
			
			ld (ix+TaskObj_StackPointer),l
			ld (ix+(TaskObj_StackPointer+1)),h

			ld ix,(TaskHeap)
			ld hl,TaskTemp
			call Objekt_call
			.byte HeapObj_Get
			
			jr nc,Suspend1
			
			ld hl,(TaskTemp)
			ld (AktTask),hl
			
			ld ix,hl
			ld l,(ix+TaskObj_StackPointer)
			ld h,(ix+(TaskObj_StackPointer+1))
			ld sp,hl
			pop af
			pop bc
			pop de
			pop hl
			exx
			ex AF,AF'
			pop af
			pop bc
			pop de
			pop hl
			pop iy
			pop ix

			call Int_ret

Suspend1	ld hl,0
			ld (AktTask),hl
			pop hl
			pop af
			ld sp,Stack   ; Stackpointer setzen
			call Int_eneb
			jp Leerlauf

; ---- Task f¸pr sofortige Ausf¸hrung vormerken ----
; HL -> Zeiger auf Task

ScheduleNow	push hl
			push ix
			call Int_dis
			ld (TaskTemp),hl
			ld ix,(TaskHeap)
			ld hl,TaskTemp
			call Objekt_call
			.byte HeapObj_Put
			call Int_old
			jr nc,Guru137
			pop ix
			pop hl
			ret

; ---- Kontrolle abgeben ----

Yield		inc sp
			inc sp

			push af
			push bc
			push hl
			push ix
			ld ix,(TaskHeap)
			ld hl,TaskTemp
			call Int_dis
			call Objekt_call
			.byte HeapObj_Top
			jr nc,Yield3

			ld hl,(AktTask)
			call Test_HL
			jr z,Yield1
			
			ld bc,AktTask
			ld hl,TaskTemp
			call TaskCompare
			
			jr nc,Yield3
	
			pop ix
			pop hl
			pop bc
			pop af
			
			push ix
			push iy
			push hl
			push de
			push bc
			push af
			exx
			ex Af,AF'
			push hl
			push de
			push bc
			push af
			
			ld (TaskTemp),sp
			ld hl,(TaskTemp)
			ld ix,(AktTask)
			ld (ix+TaskObj_StackPointer),l
			ld (ix+(TaskObj_StackPointer+1)),h
			
			ld ix,(TaskHeap)
			ld hl,AktTask
			call Objekt_call
			.byte HeapObj_Replace
			jr Yield2
Yield1			
			ld ix,(TaskHeap)
			ld hl,AktTask
			call Objekt_call
			.byte HeapObj_Get
Yield2
			ld hl,(AktTask)
			
			ld ix,hl
			ld l,(ix+TaskObj_StackPointer)
			ld h,(ix+(TaskObj_StackPointer+1))
			xor a
			ld (ix+TaskObj_ChancelCallback),a
			ld (ix+(TaskObj_ChancelCallback+1)),a
			ld sp,hl
			pop af
			pop bc
			pop de
			pop hl
			exx
			ex AF,AF'
			pop af
			pop bc
			pop de
			pop hl
			pop iy
			pop ix

			call Int_ret
			
Yield3		pop ix
			pop hl
			pop bc
			pop af
			
			call Int_ret

; ---- Task Chancel ----
; HL -> Zeiger auf Task

Chancel_Task	
			push af
			push hl
			push ix
			
			call Test_HL
			jr z,ChancelTask1
			
			call Int_dis
			
			call ChancelTask2
			
			call Int_old
			
			ld ix,(TaskHeap)
			
			call Objekt_call
			.byte HeapObj_Remove
ChancelTask1			
			pop ix
			pop hl
			pop af
			ret
			
ChancelTask2			
			push hl

			ld ix,hl
			ld l,(ix+TaskObj_ChancelCallback)
			ld h,(ix+TaskObj_ChancelCallback+1)
			
			call Test_HL
			jr z,ChancelTask3
			
			ex (sp),hl

			push hl
			ld l,(ix+TaskObj_ChancelEnv)
			ld h,(ix+TaskObj_ChancelEnv+1)
			ld ix,hl
ChancelTask3
			pop hl
			
			ret
			
; ---- Vektor f¸r User Break setzen ----
; HL -> USer Break Vektor

SetUserBreakVektor
		ld (User_break_jmp),hl
		ret
		
; ---- Auostart Vektor setzen ----
; HL -> Autostart Vektor (=0 Vektor loeschen)

Set_AutoStart	
		call Test_HL
		jr z,Set_AutoStart_1
		ld (Auto_vek),hl
		ld a,Magic
		ld (Auto_magic),a
		ret
Set_AutoStart_1
		ld a,0
		ld (Auto_magic),a
		ret

; ---- Relozieren, Speichergîsse anpassen ----
;
; (SP)    -> Referenzadresse
; (SP+2)  -> Adresse der Relocationstabelle
; (SP+4)  -> Anzahl der Relocationsadressen
; (SP+6)  -> Startadresse des Programms
; (SP+8)  -> Endadresse des Programms incl. Daten
; (SP+10) -> Flag, reserviert
;  SP+11  -> RÅcksprungadresse
;
; Reich der Speicher nicht aus, so wrid eine Meldung ausgebeen und ein
; Warmstart ausgelîsst.

Relocate        ex (sp),hl
		push af
		push bc
		push de

		ld e,(hl)               ; Referenzadresse holen
		inc hl
		ld d,(hl)
		dec hl

		push hl                 ; Offset berechnen -> DE
		or a
		sbc hl,de
		ld d,h
		ld e,l
		pop hl
		inc hl
		inc hl

		call Relocate_sub       ; Addresse der Relocationstabelle
		inc hl                  ; berechne -> (SP)
		inc hl
		push bc

		ld c,(hl)               ; Anzahl der Relocationsadressen
		inc hl                  ; holen -> BC
		ld b,(hl)
		inc hl
		ex (sp),hl              ; Addresse der Relocationstab. -> HL

		jr Relocate_2

Relocate_1      push bc
		call Relocate_sub      ; Relocationstabelle neu berechnen
		ld (hl),c
		inc hl
		ld (hl),b
		inc hl
		push hl
		ld h,b
		ld l,c
		call Relocate_sub      ; Adresse relozieren
		ld (hl),c
		inc hl
		ld (hl),b
		pop hl
		pop bc

		dec bc

Relocate_2      ld a,b
		or c
		jr nz, Relocate_1

		pop hl

		push hl
		call Read_hl
		call Mem_size
		pop hl

		call Read_bc            ; Startadresse -> BC
		inc hl
		inc hl                  ; Endadresse -> DE
		call Read_de
		inc hl
		inc hl

		jr nc,Relocate_4        ; kein Speicher reserviert

		push hl                 ; Bereich verkleinern
		call Ber_len
		jr nc,Relocate_3        ; leeren Bereich -> Fehler ausgeben
		call Mem_shrink
		pop hl
		jr nc,Relocate_3        ; Fehler -> Fehler ausgeben, Warmstart

Relocate_4      inc hl                  ; Flag Åberlesen

		pop de
		pop bc
		pop af

		ex (sp),hl

		ret

Relocate_3      ld a,Md_mem
		call Guru134

; ---- eine Adresse Relozieren ----
;
; HL <-> Zeiger auf zu relozierende Adresse
; DE  -> Offset
; BC <-  Relozeirte Adresse

Relocate_sub    push af
		push hl
		call Read_hl
		or a
		add hl,de
		ld b,h
		ld c,l
		pop hl
		pop af
		ret

; ---- Zeiger auf Standart Ausgabe Objekt hohlen
; IX <- Zeige auf Szandratausgebaobjekt

Get_StdOut		ld ix,(Stdout)
				ret
				
; ---- Bezeichner setzen ----
;
;  HL <-> Zeiger auf den Bezeichner
;  BC <-> Wert des Bezeicners


Bet_Bez_set     push de
		push hl
		ld de,Bezeichner_mem_start
		call Bez_set
		pop hl
		pop de
		ret

; ---- Bezeichner abfragen ----
;
;  HL <-> Zeiger auf den Bezeichner
;  BC <-  Wert des Bezeicners
;  A  <- Fehlercode
; CFl <-  EQU1 Ok, EQU0 nicht gefunden


Bet_Bez_get     push de
		push hl
		ld de,Bezeichner_mem_start
		call Bez_get
		ld b,d
		ld c,e
		pop hl
		pop de
		ret

; ---- Bezeichner lîschen ----
;
;  HL <-> Zeiger auf den Bezeichner


Bet_Bez_del     push de
		push hl
		ld de,Bezeichner_mem_start
		call Bez_del
		pop hl
		pop de
		ret

; ---- Version testen ----
;
; HL  -> mindestens benîtigte Version ( fall nicht ausreichend Warmstart )
; HL <-  aktuelle Version

Ver_test        push af
		push bc

		ld bc,Version_min
		call Cmp_hl_bc
		jr c,Ver_test_2

		ld bc,Version_nr
		call Cmp_hl_bc
		jr z,Ver_test_1
		jp nc,Ver_test_2

Ver_test_1	ld hl,Version_nr

		pop bc
		pop af

		ret

Ver_test_2	ld a,Md_ver
		call Guru134


; ---- Adresse des Standartausgabeobjekts holen ----
;
; IX <- Adresse

Get_stdout	ld ix,(Stdout)

		ret

; ---- Adresse des LCD-Ausgabeobjekts holen ----
;
; IX <- Adresse

Get_lcdout	ld ix,(LcdPointer)

		ret

; ---- Adresse des LCD-Ausgabeobjekts holen ----
;
; IX <- Adresse

Get_rtc	ld ix,(RtcPointer)

		ret

; ---- Adresse des DCF77-Ausgabeobjekts holen ----
;
; IX <- Adresse

Get_dcf	ld ix,(Dcf77Pointer)

		ret

; ---- Adresse des Port B Gpio Ojekts holen ----
;
; IX <- Adresse

Get_PortB	ld ix,(PortB_Pointer)

		ret

; ---- Adresse des Port B Gpio Ojekts holen ----
;
; IX <- Adresse

Get_PortA	ld ix,(PortA_Pointer)

		ret

; ---- Adresse des Port B Gpio Ojekts holen ----
;
; IX <- Adresse

Get_PortC	ld ix,(PortC_Pointer)

		ret

; ---- Adresse des Port B Gpio Ojekts holen ----
;
; IX <- Adresse

Get_PortD	ld ix,(PortD_Pointer)

		ret

; ---- ¥Timerwertn holen .----
; HL <- Tiomerwert

Get_Timer	call Int_dis
			ld hl,(SystemTicks)
			call Int_old
			ret

; ---- Adresse des LCD-Ausgabeobjekts holen ----
;
; IX <- Adresse

Get_sioout	ld ix,(SerialOut)

		ret

; ---- Adresse des ESP01-Ausgabeobjekts holen ----
;
; IX <- Adresse

Get_EspOut	ld ix,(EspSerialOut)

		ret
		
; ---- Adresse de WifiClients hohlen ----

Get_WifiClient	ld ix,(WifiClient)
				ret

; ---- Adresse de MQTT-Clients hohlen ----

Get_MqttClient	ld ix,(MqttClient)
				ret

; ---- Interrupt verhindern / IFF merken ----

Int_dis         push af
		di
		ld a,(Int_count)
		inc a
		call z,Guru129
		ld (Int_count),a
		pop af
		ret

; ---- Interruptvektor setzen ----
; A  -> Vektor
; HL -> Interupt handler
; IX -> enviorment

SetIntVek	push af
			push hl
			push de
			ld de,hl
			ld hl,InterruptTabel
			call Add_HL_A
			call Int_dis
			call Write_de
			inc hl
			inc hl
			ld de,ix
			call Write_de
			call Int_old
			pop de
			pop hl
			pop af
			ret

; ---- Interruptvektor lˆschen ----
; A  -> Vektor

ClrIntVek	push af
			push hl
			push bc
			push de
			ld de,Guru128
			ld c,a
			ld b,0
			sla c
			rl b
			ld hl,InterruptTabel
			add hl,bc
			call Int_dis
			call Write_de
			inc hl
			inc hl
			ld de,0000h
			call Write_de
			call Int_old
			pop de
			pop bc
			pop hl
			pop af
			ret
			
; ---- alten Interupptzustand herstellen ----

Int_old         push af
		ld a,(Int_count)
		or a
		call z,Guru129
		dec a
		ld (Int_count),a
		jr nz,Int_old_1
		ei
Int_old_1       pop af
		ret

; ---- Interrupt freigeben ----

Int_eneb        push af
		xor a
		ld (Int_count),a
		ei
		pop af
		ret

; ---- Interrupt freigeben ----

Int_ret push af
		xor a
		ld (Int_count),a
		pop af
		inc sp
		inc sp
		ei
		reti

; ---- Interrupt sperren, ZÑhler zurÅcksetzen ----

Int_reset       di
		push af
		ld a,1
		ld (Int_count),a
		pop af

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

; ---- Wait ----
;
; HL -> Zei in ms 

Wait    push af
		push hl

Wait_1
		call Test_HL
		jr z,Wait_3
		dec hl

		push hl
		ld hl,WaitCounter
Wait_2
		dec hl
		call Test_HL
		jr nz,Wait_2
		pop hl
		dec hl
		jr Wait_1
		
Wait_3
		pop hl
		pop af
		
		ret
		
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Speicherverwaltung    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Speciher reservieren ----
;
; BC   -> benîtigte Bytes
; HL  <-  Startdresse des Speichers ( 0 bei Fehler )
; DE  <-  Endadresse des Speichers ( 0 bei Fehler )
; CLF <-  EQU1 ok, EQU0 Fehler
; A   <-  Fehlercode

Mem_alloc       push bc
		push de

		inc bc          ; Speicher fÅr Zeiger und LÑnge zufÅgen
		inc bc
		inc bc
		inc bc

		ld hl,Free_add
		call Block_first

Mem_alloc_2     push bc
		call Block_next
		pop bc
		ld a,Md_mem
		ld hl,0
		jr nc,Mem_alloc_1       ; kein passender Block -> Fehler
		ld hl,(Block_l)
		or a
		sbc hl,bc
		jr c,Mem_alloc_2        ; Block zu klein -> weiter

		ld hl,(Block_a)         ; Block zerteilen
		push hl
		call Block_shrink
		pop de
		ld a,Md_mem
		ld hl,0
		jr nc, Mem_alloc_1

		ld hl,Free_add          ; Block suchen
		call Block_find
		ld a,Md_mem
		ld hl,0
		jr nc, Mem_alloc_1
		ld hl,Geraet
		call Block_move

		ld hl,(Block_a)
		inc hl
		inc hl
		inc hl
		inc hl

		xor a
		scf

Mem_alloc_1     pop de
		pop bc

		ret


; ---- Speicher freigeben ----
;
; HL -> Addresse des Speichers
; CLF <- EQU1 ok, EQU0 Fehler
; A   <- Fehlercode

Mem_free        push bc
		push de
		push hl

		dec hl
		dec hl
		dec hl
		dec hl
		ld e,l
		ld d,h
		ld hl,Geraet
		call Block_free
		ld a,Md_mem
		jr nc,Mem_free_1
		xor a
		scf

Mem_free_1      pop hl
		pop de
		pop bc

		ret

; ---- Speicher instalieren ----
;
; HL -> Addresse
; BC -> LÑnge
;

Mem_inst        push hl ; Blockadresse -> DE
		pop de

		call Int_dis

		ld hl,(Mem_ges) ; Block hinzufÅgen
		add hl,bc
		ld (Mem_ges),hl
		ld hl,Free_add
		call Block_add

		call Int_old

		jp Mem_sweep

; ---- Speicher verkleinern ----
;
; HL  <-> Addresse des Speichers
; BC  <-> Grîsse
; CLF <-  EQU1 ok, EQU0 Fehler
; A   <-  Fehlercode

Mem_shrink      ld a,b
		or c
		jr z,Mem_free

		push bc
		push de
		push hl

		inc bc
		inc bc
		inc bc
		inc bc
		dec hl
		dec hl
		dec hl
		dec hl

		push hl         ; Test ob Block belegt
		push bc
		ld d,h
		ld e,l
		ld hl,Geraet
		call Block_find
		pop bc
		pop hl
		ld a,Md_mem
		jr nc,Mem_shrink_1

		call Block_shrink
		jr nc,Mem_shrink_1

		call Mem_sweep

		xor a
		scf

Mem_shrink_1    pop hl
		pop de
		pop bc

		ret

; ---- Grîsse de grîssten frein Blocks ermitteln ----
;
; BC <- Grîsse

Mem_max         push af
		push de
		push hl

		ld bc,4

		ld hl,Free_add
		call Block_first
Mem_max_1       call Block_next
		jr nc,Mem_max_2
		ld hl,(Block_l)
		call Cmp_hl_bc
		jr c,Mem_max_1
		ld b,h
		ld c,l
		jr Mem_max_1

Mem_max_2       dec bc
		dec bc
		dec bc
		dec bc

		pop hl
		pop de
		pop af

		ret

; ---- Grîsse eines belegeten Speicherblocks ermitteln ----
;
; HL  <-> Adresse des Blocks
; BC  <-  Grîsse ( EQU0 bei Fehler )
; DE  <-  Endadresse
; CLF <-  EQU1 ok, EQU0 Fehler
; A   <-  Fehlercode

Mem_size        push hl

		dec hl
		dec hl
		dec hl
		dec hl

		ld d,h
		ld e,l
		ld hl,Geraet
		call Block_find

		ld a,Md_mem
		ld bc,0
		ld de,0
		jr nc,Mem_size_1

		ld hl,(Block_a)         ; Endadresse Berechnen -> DE
		ld bc,(Block_l)
		or a
		add hl,bc
		dec hl
		ld d,h
		ld e,l

		ld bc,(Block_l)         ; LÑnge -> BC
		dec bc
		dec bc
		dec bc
		dec bc

		xor a
		scf

Mem_size_1      pop hl

		ret

; ---- Speicher zerteilen ----
;
; HL  <-> Zeiger auf Block
; BC   -> Neue LÑnge
; CLF <-  EQU1 ok, EQU0 Fehler
; A   <-  Fehlercode

Block_shrink    push bc
		push de
		push hl

		push hl
		inc hl
		inc hl

		call Read_hl            ; BlocklÑnge -> HL
		or a
		sbc hl,bc               ; LÑnge des Restblocks -> HL

		jr nc,Block_shrink_2    ; Block kleiner oder gleich

		ld a,Md_mem
		or a
Block_shrink_3  pop de
		jr Block_shrink_1

Block_shrink_2   xor a
		ld de,5                 ; RestlÑnge < 5 dann fertig
		call Cmp_hl_de
		jr c,Block_shrink_3

		call Int_dis

		ex (sp),hl              ; Blockadresse -> HL, RestlÑnde -> (SP)
		inc hl
		inc hl
		call Write_bc           ; neue BlocklÑnge speichern
		dec hl
		dec hl

		or a                    ; Restblockadresse -> DE
		add hl,bc
		ld d,h
		ld e,l

		pop bc                  ; RestlÑnge -> BC

		ld hl,Free_add          ; Restblock zu freien Blocks zufÅgen
		call Block_add

		call Int_old

		xor a
		scf

Block_shrink_1  pop hl
		pop de
		pop bc

		ret

; ---- Block zu einer Kette hinzufÅgen ----
;
; HL -> Adresse des Kettenzeigers
; DE -> Blockadresse
; BC -> BlocklÑnge
;

Block_add       push bc ; BlocklÑnge -> (SP)

		call Read_bc ; Adresse des nÑchsten Blocks -> Header
		call Write_de_bc

		pop bc ; BlocklÑnge -> BC

		inc de ; BlocklÑnge -> Header
		inc de
		call Write_de_bc
		dec de
		dec de

		call Int_dis

		call Write_de

		call Int_old

		ret

; ---- Block aus einer Kette entfernen ----
;
; BP <-> Blockparameter
;

Block_del       ld hl,(Block_a) ; Zeiger auf nÑchsten Block -> DE
		call Read_de

		call Int_dis

		ld hl,(Block_z) ; DE -> Zeiger auf Block
		call Write_de

		call Int_old

		ret

; ---- Zeiger auf ersten Block einer Kette setzen ----
;
; HL -> Zeiger
;

Block_first     ld (Block_a),hl
		ret

; ---- Blockparameter des auf (BP) folgenden Blocks holen ----
;
; BP <-> Blockparameter
; CFL <- 1 wenn Block vorhanden / 0 wenn kein block vorhanden
; HL <- Adresse des Block ( 0 wenn nicht gefunden )
;

Block_next      ld hl,(Block_a)

; ---- Blockparameter holen ----
;
; HL -> Adresse des Zeigers auf den Block
;
; CFL <- 1 wenn Block vorhanden / 0 wenn kein block vorhanden
; BP <- Blockparameter
; HL <- Addresse des Blocks ( 0 wenn Block nicht gefunden )
; A  <- undefiniert
;

Block_param     ld (Block_z),hl ; Addr. des Zeigers auf Block setzen
		call Read_hl ; Blockaddr. -> HL
		xor  a ; CFL, A EQU 0
		or  h
		or  l
		ret z ; kein Block mehr dann return
		ld (Block_a),hl ; Blockaddr. setzen
		inc hl ; Zeiger auf BlocklÑnge
		inc hl
		push de
		call Read_de ; BlocklÑnge -> DE
		ld (Block_l),de ; Bl. setzen
		pop de
		dec hl ; alter Zeiger
		dec hl
		scf
		ret


; ---- Block suchen / Blockparameter setzen ----
;
; HL -> Addr. des Kettenzeigers
; DE -> Addr. des Blockheaders
;
; CFL <- 1 wenn Block gefunden / 0 wenn Block nicht gefunden
; BP <- Blockparameter
;

Block_find      push de ; Blockparameter holen
		call Block_param
		pop de

		ret nc ; kein Block mehr -> return

		push hl ; gefunden ?
		xor  a
		sbc hl,de
		pop hl

		jr nz,Block_find ; nein -> weitersuchen

		scf
		ret

;---- Block freigeben ----
;
; HL -> Adresse des Kettenzeigers
; DE -> Adresse Blocks
; CFL <- 1 wenn Block gefunden / 0 wenn Block nicht gefunden
;

Block_free      call Block_find
		ret nc
		ld hl,Free_add
		call Block_move
		call Mem_sweep ; Speicher aufrÑumen
		scf
		ret

;---- Block Åbergeben ----
;
;BP <-> Blockparameter
;HL  -> Adresse des neuen Kettenzeigers
;

Block_move      call Int_dis

		push hl
		call Block_del
		pop hl

		ld de,(Block_a)
		ld bc,(Block_l)
		call Block_add

		call Int_old

		ret

;---- Speicher aufrÑumen / Leere Blîcke vereinigen ----

Mem_sweep       ld hl,Free_add ; Addresse des ersten Unterblocks -> HL

Mem_sweep_1     call Block_param
		ret nc ; kein Block mehr

		ld hl,(Block_a) ; Addresse des aktuellen Unterblocks -> (Ob_add)
		ld (Ob_add),hl

		push hl ; Endadresse+1 des ersten Unterblocks -> DE
		inc hl
		inc hl
		call Read_de
		pop hl
		add hl,de
		ld e,l
		ld d,h

		ld hl,Free_add ; Zeiger auf Zeiger auf aktuellen Oberblock

Mem_sweep_3     push de
		call Block_param ; Adresse des Oberlocks -> HL
		pop de
		jr c,Mem_sweep_4 ; Oberblock vorhanden ?

		ld hl,(Ob_add) ; Zeiger auf nÑchsten Unterblock nach HL
		jr Mem_sweep_1 ; ? NÑchster Obeblock !

Mem_sweep_4     ld hl,(Block_a) ; grenzt Oberblock an Unterblock ?
		xor  a
		sbc hl,de
		jr z,Mem_sweep_2 ; ja -> Blocke vereinigen

		ld hl,(Block_a)
		jr Mem_sweep_3

Mem_sweep_2     call Int_dis

		call Block_del ; Oberblock lîschen

		ld hl,(Ob_add) ; UnterblocklÑnge EQU Ubl. + OberblocklÑnge

		inc hl
		inc hl

		push hl

		call Read_de ; UnterblocklÑnge lesen
		ld hl,(Block_l)
		add hl,de
		ld d,h ; neue BlocklÑnge -> DE
		ld e,l

		pop hl

		call Write_de

		call Int_old

		jr Mem_sweep ; nochmal von vorne


; ---- User CTRL-C Interruputrutine ----

User_break      
		push hl
		push af
		ld hl,(User_break_jmp)
		call Test_HL
		jr z,User_break_1
		pop af
		ex (sp),hl
		ret
		
User_break_1
		pop af
		pop hl
		ret
		
; ---- Warmstart ----

Warmstart
		jp Aplikation
		

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Ein- Ausgabeverarbeitung    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Esc synchronisieren ----
; wenn kein Zeichen empfangen, dann Zeichen hohlen
; wenn ESC-Zeichen empfangen, ESC zurÅckgeben
; wenn kein Esc empfangen, dann neues Zeichen hohlen
; A <- Zeichen

Esc_sync call Char_get_non_blocking
		jr nc,Esc_sync
		cp a,Esc
		ret z
		jr Esc_sync

; ---- Zeile einlesen ----
;
; HL <-> Startadresse zum speichern
; B   -> max. Anzahl der zu lesenden Zeichen ohne NULL
; B  <-  Anzahl der Gelesenen Zeichen

Line_get        push af
		push de
		push hl

		ld e,b
		ld b,0

Line_get_0      call Char_get

		call Print_test
		jr c,Line_get_2
		call Menu_branch
		.byte Cr
		.word Line_get_3
		.byte Backspace
		.word Line_get_4
		.byte Delete
		.word Line_get_4
		.byte Esc
		.word Line_get_5
		.byte Ht
		.word Line_get_1
		.byte 0
		.word Line_get_0

Line_get_1      ld a,' '

Line_get_2      ld d,a
		ld a,e
		cp b
		jr z,Line_get_0
		ld a,d
		ld (hl),a
		call Char_out
		inc hl
		inc b
		jr Line_get_0

Line_get_3      xor a    ; eingabe beendet
		ld (hl),a
		pop hl
		pop de
		pop af
		ret

Line_get_4      ld a,b     ; Backspace
		or a
		jr z,Line_get_0
		dec hl
		dec b
		call Printf
		.byte Pf_s,Pf_left,' ',Pf_s,Pf_left,0
		jr Line_get_0

Line_get_5      call Char_get
		jr Line_get_0

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

; ---- Meldung ausgeben ----
;
; A  -> Nummer der Meldung
; HL -> Tabelle der Meldungen
; CFL <- EQU1 ok, EQU0 nicht gefunden

Meld_out        push ix
		ld ix,(Stdout)
		call Objekt_call
		.byte PrintfObj_MeldOut
		pop ix
		ret

; ---- Datum und Uhrzeit ausgeben ----
;
; HL -> Zeiger aud Datum und Uhrzeit

Time_out	push ix
		ld ix,(Stdout)
		call Printf_obj
		
		.byte Pf_s,Pf_wt | Pf_dt | Pf_hhmm | Pf_ss, 0
		pop ix

		ret

; ---- Zeichen auf der Standartausgabe ausgeben ----
;
; A -> Zeichen

Char_out	push ix
		ld ix,(Stdout)
		call Objekt_call
		.byte SerialObj_CharOut
		pop ix

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

Pointprn	push ix
		ld ix,(Stdout)
		call Objekt_call
		.byte PrintfObj_Pointprn
		pop ix
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

		call Objekt_call
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
Char_get_non_blocking  push ix
		ld ix,(Stdout)
		rst 08h
		.byte Betn_Objekt_call
		.byte SerialObj_CharIn
		pop ix
		ret

;---- Zeichen von RS 232 holen ----
;
; A <- Zeichen
Char_get push ix
		ld ix,(Stdout)
		rst 08h
		.byte Betn_Objekt_call
		.byte SerialObj_Char_get
		pop ix
		ret
			
; ********************************************************************
; **		       						    **
; **    Hilfsrutienen                                               **
; **		       						    **
; ********************************************************************


; ====================================================================
; ==    Objekt Rutinenen                                            ==
; ====================================================================

; ---- Objekt aufrufen ----
;
; IX -> Adresse des Objekts

Objekt_call	ex (sp),hl 		; R¸cksprungadresse setzen
			inc hl
			ex (sp),hl
			
			push hl		
			push af
			push iy
			
			call SP_TO_IY				; Methodennummer nach A
			ld l,(iy+6)
			ld h,(iy+7)

			dec hl
			ld a,(hl)

			push af
			
			ld l,(ix+ClassOffset)		; Zeiger auf Klasse nach HL
			ld h,(ix+(ClassOffset+1))
			
			call Test_HL				; Zeiger =0 -> Fehler
			call z,Guru136

			ld a,MethodsTabOffset		; Zeiger auf Methodentabelle nach HL
			call Add_HL_A

			pop af
			
			call Tab_get				; Zeiger auf Methode holen
			call nc,Guru136				; Methode nicht gefunden -> Fehler
			
			call Test_HL				; Methodenzeiger =0 -> Fehler
			call z,Guru136

			pop iy
			pop af
			ex (sp),hl					; Methodenaddress auf Stack ablegen
			
			ret							; Methode aufrufen
			
; ---- Super Methode eines Objekts aufrufen ----
;
; IX -> Adresse des Objekts

Objekt_SuperJmp
			push hl		
			push af
			push iy

			call SP_TO_IY				; Methodennummer nach A
			ld l,(iy+6)
			ld h,(iy+7)
			ld a,(hl)

			push af

			ld l,(ix+ClassOffset)		; Zeiger auf Klasse nach HL
			ld h,(ix+(ClassOffset+1))
			
			call Test_HL				; Zeiger =0 -> Fehler
			call z,Guru136

			ld a,SuperClassOffset		; Zeiger auf Superklasse nach HL
			call Add_HL_A
			call Read_hl
			
			call Test_HL				; keine Superklass =0 -> Fehler
			call z,Guru136

			ld a,MethodsTabOffset		; Zeiger auf Methodentabelle der Superkassee nach HL
			call Add_HL_A

			pop af
			
			call Tab_get				; Zeiger auf Methode holen
			call nc,Guru136				; Methode nicht gefunden -> Fehler
			
			call Test_HL				; Methodenzeiger =0 -> Fehler
			call z,Guru136

			ld a,(iy+4)
			ld (iy+6),a
			ld a,(iy+5)
			ld (iy+7),a
			
			ld a,(iy+2)
			ld (iy+4),a
			ld a,(iy+3)
			ld (iy+5),a
			
			ld a,(iy)
			ld (iy+2),a
			ld a,(iy+1)
			ld (iy+3),a
			
			inc sp
			inc sp
			
			pop iy
			pop af
			ex (sp),hl					; Methodenaddress auf Stack ablegen
			
			ret							; Methode aufrufen
			

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Berabeitung von Bezeichnertabellen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Befehl in Tabelle suchen / Adresse hohlen ----
;
;  DE -> Zeiger auf die Tabelle
;  HL -> Zeiger auf den Befehl
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  DE <- Zeiger auf  Bezeichner
; CFl <- EQU1 Ok, EQU0 nicht gefunden
;
; Aufbau der Tabelle:
; "Befehl",0,Adresse,...,0

Bez_find        push hl
		call Bez_read
		pop hl
		ret nc

		push af

Bez_find_1      ld a,(de)
		or a
		jr z,Bez_find_3

		call Bez_cmp
		jr c,Bez_find_2

		call Ex_hl_de
		call Read_str
		inc hl
		inc hl
		call Ex_hl_de

		jr Bez_find_1

Bez_find_2      call Bez_read

		pop af
		scf
		ret

Bez_find_3      pop af
		or a
		ret

; ---- Wert eines Bezeichners holen ----
;
;  DE -> Zeiger auf die Tabelle
;  HL -> Zeiger auf den Befehl
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  DE <- Wert des Bezeichners

Bez_get         call Bez_find
		ld a,Md_var
		ret nc

		push hl
		ld h,d
		ld l,e
		call Read_str
		call Read_de
		pop hl

		or a
		scf

		ret

; ---- gesamten Variablespeicher lîschen ----
;
; DE -> Tabelle
; BC -> maximaler Speicherplatz

Bez_clr         push af
		xor a
		ld (de),a
		pop af
		ret

; ---- Bezeichner setzen ----
;
;  HL -> Zeiger auf den Bezeichner
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  BC -> Wert des Bezeicners
;  DE -> Speicher fÅr den Bezeichner


Bez_set         push hl
		call Bez_read
		pop hl
		ret nc

		call Bez_find
		jp nc,Bez_gen

		call Ex_hl_de
		call Read_str
		call Write_bc
		call Ex_hl_de

		ret

; ---- Bezeichner lîschen ----
;
;  HL -> Zeiger auf den Bezeichner
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  BC -> Wert des Bezeicners
;  DE -> Speicher fÅr den Bezeichner

Bez_del         push hl
		call Bez_read
		pop hl
		ret nc

		call Bez_find           ; Anf. Bezeichner -> DE
		ret nc

		push de                 ; Anf. Bezeichner -> (SP)

		ld h,d                  ; Ende Bezeichner -> BC
		ld l,e
		call Read_str
		inc hl
		inc hl
		ld b,h
		ld c,l

		call Tab_end            ; Ende Tabelle -> DE

		pop hl                  ; Anf. Bezeichner -> HL

		call Mem_move

		ret

; ---- Bezeichner erzeugen ----
;
;  HL -> Zeiger auf den Bezeichner
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  BC -> Wert des Bezeicners
;  DE -> Speicher fÅr den Bezeichner

Bez_gen         push hl
		call Bez_read
		pop hl
		ret nc

		push af
		push de
		push bc

		push hl

		ld h,d          ; Ende des Speichers -> BC
		ld l,e
		call Read_bc
		or a
		adc hl,bc
		ld b,h
		ld c,l

		pop hl

		call Tab_end

Bez_gen_3       ld a,(hl)
		call Is_alpha
		jr nc,Bez_gen_4


		ld (de),a
		inc hl
		inc de

		jr Bez_gen_3


Bez_gen_4       pop bc

		call Ex_hl_de
		xor a
		ld (hl),a       ; Abschluss des Strings
		inc hl
		ld (hl),c       ; Wert setzen
		inc hl
		ld (hl),b
		inc hl
		ld (hl),a       ; Ende der Tabelle
		call Ex_hl_de

		pop de
		pop af

		scf

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

; ---- Ziffer einlesen ----
;  C  <-> Basis ( 2 bis 16 )
;  Hl  -> Zeiger auf Komandozeile
;  DE <->  10*DE+Ziffer
;  HL <-  naechstes Zeichen
; A   <-  Fehlercode
; CFl <-  EQU1 Ok, EQU0 nicht gefunden

Ziffer_in       push bc
		push de
		ld b,0

		ld a,(hl)
		call Hex2bin
		jr nc,Ziffer_in_1 ; Ziffer falsch -> Fehler
		cp c
		jr nc,Ziffer_in_1 ; Ziffer falsch -> Fehler

		push hl
		ld h,d
		ld l,e
		call Multi    ; DE EQU DE * Basis
		ld d,h
		ld e,l
		pop hl
		jr nc,Ziffer_in_1 ; Ueberlauf -> Fehler

		add a,e     ; DE EQU DE + lezte Ziffer
		ld e,a
		ld a,d
		adc a,0
		ld d,a
		jr c,Ziffer_in_1  ; Ueberlauf -> Fehler

		inc hl

		pop bc
		pop bc
		xor a
		scf
		ret

Ziffer_in_1     pop de
		pop bc
		ld a,Md_inp
		or a
		ret

; ---- 16 Bit Zahl in angegebenem Zahlensystem einlesen ----
;  C  <-> Basis ( 2 bis 16 )
;  Hl  -> Zeiger auf Komandozeile
;  DE <-  Zahl
;  HL <-  naechstes Zeichen
; A   <-  Fehlercode
; CFl <-  EQU1 Ok, EQU0 nicht gefunden

Zahl_in         call Space_ignore
		ld de,0
		call Ziffer_in
		ret nc
Zahl_in_1       call Ziffer_in
		jr c,Zahl_in_1  ; weitere Ziffer ?

		xor a      ; OK
		scf
		ret

; ---- dezimael Byte lesen ----
;
; HL  -> Zeiger auf Komandozeile
; E   -> Default-Wert
; HL  <- nÑchstes Zeichen
; E   <- Byte
; A   <- Fehlercode
; CFl <- EQU1 Ok, EQU0 nicht gefunden
;
; Das D Register wird zerstîrt

Byte_dez_in     push bc
		ld c,10
		call Zahl_in
		pop bc

		ld a,d
		or a
		jr nz,Byte_dez_in_1
		ld a,0
		scf
		ret

Byte_dez_in_1   ld a,Md_inp ; Falscher Wert
		or a
		ret

		ret nc

; ---- Befehl in Tabelle suchen / Adresse hohlen ----
;
;  BC -> Zeiger auf die Tabelle
;  HL -> Zeiger auf den Befehl
;  HL <- Zeiger auf erstes Zeichen nach dem Befehl
;  BC <- zugeordnete Adresse
; CFl <- EQU1 Ok, EQU0 nicht gefunden
;
; Aufbau der Tabelle:
; "Befehl",0,Adresse,...,0

Kom_add         push de
		ld d,h       ; HL -> DE
		ld e,l

Kom_add_0       ld a,(bc)    ; Tabellenede erreicht ?
		or a
		jr z,Kom_add_3

		ld a,(bc)
		push bc
		ld b,(hl)
		call Char_cmp
		pop bc
		jr c,Kom_add_2     ; Zeichen richtig

Kom_add_1       inc bc       ; nein, dann zum nÑchsten Eintrag
		ld a,(bc)
		or a
		jr nz,Kom_add_1
		inc bc       ;  0 und Adresse Åberlesen
		inc bc
		inc bc
		ld h,d       ; DE -> HL
		ld l,e
		jr Kom_add_0

Kom_add_2       inc bc       ; Zeichen richtig
		inc hl
		ld a,(bc)
		or a
		jr nz,Kom_add_0    ; Ende des Eintrags

		inc bc       ; ja, Adresse -> BC
		ld a,(bc)
		ld e,a
		inc bc
		ld a,(bc)
		ld b,a
		ld c,e
		scf

Kom_add_3       pop de

		ret

; ---- Zeitangabe einlesen ----
;
;  HL  -> Zeiger auf Komandozeile
; (BC) -> Speicherbereich fÅr Zeit
;  HL  <- nÑchstes Zeichen
;  A   <- Fehlercode
;  CFl <- EQU1 Ok, EQU0 nicht gefunden
;

Time_in         push bc
		push hl

		inc bc
		inc bc
		call Byte_dez_in
		jr nc,Time_in_1
		ld a,e
		ld (bc),a

		dec bc
		ld a,':'
		call Char_test
		jr nc,Time_in_1

		call Byte_dez_in
		jr nc,Time_in_1
		ld a,e
		ld (bc),a

		dec bc
		ld e,0                  ; Default Wert
		ld a,':'
		call Char_test
		jr nc,Time_in_2

		call Byte_dez_in
		jr nc,Time_in_1

Time_in_2       ld a,e
		ld (bc),a

		xor a
		scf
		pop bc
		pop bc
		ret

Time_in_1       or a
		pop hl
		pop bc

		ret

; ---- Datum in Datum und Zeitspeicher einlesen ----
; diese Funktion entspricht Datum ina der Version 04.00
;
;  HL  -> Zeiger auf Komandozeile
; (BC) -> Speicherbereich fÅr Datum und Zeit
;  HL  <- nÑchstes Zeichen
;  A   <- Fehlercode
;  CFl <- EQU1 Ok, EQU0 nicht gefunden

Datum_in_alt    push bc
		inc bc
		inc bc
		inc bc
		call Datum_in
		pop bc
		ret

; ---- Datum einlesen ----
;
;  HL  -> Zeiger auf Komandozeile
; (BC) -> Speicherbereich fÅr Datum
;  HL  <- nÑchstes Zeichen
;  A   <- Fehlercode
;  CFl <- EQU1 Ok, EQU0 nicht gefunden
;

Datum_in        push bc
		push hl

		call Byte_dez_in
		jr nc,Datum_in_1
		ld a,e
		ld (bc),a

		ld a,'.'
		call Char_test
		jr nc,Datum_in_1

		inc bc
		call Byte_dez_in
		jr nc,Datum_in_1
		ld a,e
		ld (bc),a

		ld a,'.'
		call Char_test
		jr nc,Datum_in_1

		inc bc

		push bc
		ld c,10
		call Zahl_in
		pop bc

		jr nc,Datum_in_2
		ld a,e
		ld (bc),a
		inc bc
		ld a,d
		ld (bc),a

Datum_in_2      xor a
		scf
		pop bc
		pop bc

		ret

Datum_in_1      or a
		pop hl
		pop bc

		ret

; ---- Test ob Zeichen in der Komandozeile  ist ----

;  HL  -> Zeiger auf Komandozeile
;  A   -> zu testendes Zeichen
;  HL  <- nÑchstes Zeichen
;  A   <- Fehlercode
;  CFl <- EQU1 Ok, EQU0 nicht gefunden

Char_test       call Space_ignore
		cp (hl)
		jr nz,Char_test_1
		inc hl
		call Space_ignore
		xor a
		scf
		ret

Char_test_1     ld a,Md_inp
		or a
		ret

; ---- Leerzeichen Åberlesen ----

Space_ignore    push af
Space_ignore_1  ld a,(hl)
		call Space_test
		inc hl
		jr c,Space_ignore_1
		dec hl
		pop af
		ret

; ---- Leerzeichen und ein Trennzeichen Åberlesen ----
;
; HL  -> Zeiger auf Komandozeile
; HL  <- Zeiger auf naechstes Nicht-Leerzeichen ( evt. nach Trennzeichen )

Trenn_ignore    push af
		call Space_ignore
		ld a,(hl)
		call Trenn_test
		jr nc,Trenn_ignore_1
		inc hl
Trenn_ignore_1  pop af
		ret

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Zeichenverarbeitung    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- ASCI Hex Zeichen nach binÑr wandeln ----

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

; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU
; EQU    Datums- und Zeioperationen    EQU
; EQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQUEQU

; ---- Tage seit dem Starttag in Datum umwandeln ----
;
; HL  <-> Zeiger auf Datum
; DE  <->  Anzahl der Tage seit dem Starttag

Tagnr2datum     push af
		push bc
		push de
		push hl

		ld h,d
		ld l,e

		ld bc,4*365+1           ; Anzahl der Tage in 4 Jahern
		call Divi               ; Anzahl der Olympiaden -> DE

		push de

		dec bc
		call Cmp_hl_bc
		jr nz,Tagnr2datum_2
		ld hl,365
		ld de,3
		jr Tagnr2datum_3

Tagnr2datum_2   ld bc,365
		call Divi

Tagnr2datum_3   ex (sp),hl	       ; Anzahl der Olympiaden ->  HL
				       ; Tag im Jahr           -> (SP)

		ld bc,4                ; Jahr berechnen
		call Multi
		or a
		adc hl,de
		ld bc,Start_jahr
		adc hl,bc

		ld d,h                  ; Jahr -> DE
		ld e,l

		pop hl                  ; Tag des Jahers -> hl

		ld a,13

Tagnr2datum_4   dec a                   ; Monat berechen -> A
		call Tag_im_jahr
		call Cmp_hl_bc
		jr c,Tagnr2datum_4

		or a                    ; Tag des Monats - 1 -> HL
		sbc hl,bc

		ld b,l
		ld c,a
		inc b

		pop hl

		push hl
		ld (hl),b
		inc hl
		ld (hl),a
		inc hl
		ld (hl),e
		inc hl
		ld (hl),d
		pop hl

		pop de
		pop bc

		push hl
		call Calc_wochentag
		inc hl
		inc hl
		inc hl
		inc hl
		ld (hl),a
		pop hl

		pop af

		ret

; ---- Wochentag bestimmen ----
; HL -A> zeiger auf Datum und Zeit
; A <- Wochentag
Calc_DOW
		push de
		push hl
		
		inc hl
		inc hl
		inc hl
		
		call Tagnummer
		jr nc,Calc_DOW1

		call Calc_wochentag
		
		pop hl
		pop de
		scf
		ret
Calc_DOW1
		pop hl
		pop hl
		xor a
		ret
		
; ---- Tage seit dem Startjahres berechnen ----
;
; HL  <-> Zeiger auf Datum
; DE  <-  Anzahl der Tage seit dem Starttag
; A   <-  Fehelrcode
; CFL <-  EQU1  ok, EQU0 Fehler

Tagnummer       push bc
		push hl

		ld b,(hl)
		inc hl
		ld c,(hl)
		inc hl

		call Read_hl
		ld d,h
		ld e,l

		call Tagnr
		ld d,h
		ld e,l

		pop hl
		pop bc

		ret

; ---- Tage seit dem Startjahres berechnen ----
;
; B  <-> Tag
; C  <-> Monat
; DE   -> Jahr
; HL  <-  Anzahl der Tage seit dem Starttag
; A   <-  Fehelrcode
; CFL <-  EQU1  ok, EQU0 Fehler

Tagnr           push bc

		push bc
		push de

		ld h,d                  ; Anzahl der Jahre seit dem Startjahr -> HL
		ld l,e
		ld bc,Start_jahr
		or a
		sbc hl,bc
		jr c,Tagnr_2

		push hl                 ; Anzahl der Schalttage -> DE
		ld bc,4
		call Divi
		pop hl

		ld bc,365               ; Anzahl der Tage ohne Schalttage -> HL
		call Multi
		jr nc,Tagnr_2

		or a                    ; Anzahl der Tage der ganzen Jahre -> DE
		add hl,de
		ld d,h
		ld e,l

		pop de
		pop bc


		ld a,c                  ; Monat -> A
		dec b                   ; Tag-1 -> BC
		ld c,b
		ld b,0

		or a                    ; Tage dazurechnen
		adc hl,bc
		jr c,Tagnr_1

		call Tag_im_jahr       ; Monate dazurechnen
		or a
		adc hl,bc
		jr c,Tagnr_1

		xor a
		scf

		pop bc

		ret

Tagnr_2         pop de
		pop bc

Tagnr_1         pop bc

		ld a,Md_datum
		or a

		ret

; ---- Nummer des Tages eines Jahres berechenen ----
;
; A   -> Monat
; DE  -> Jahr
; BC <-  Tage von Jahresanfang bis Monatsanfang

Tag_im_jahr     push hl

		push af

		dec a          ; vergangene Monate dazurechen
		sla a
		ld hl,Tag_im_jahr_tab
		add a,l
		ld l,a
		ld a,h
		adc a,0
		ld h,a
		call Read_bc

		pop af

		call Schaltjahr
		jr nc,Tag_im_jahr_1
		cp 3
		jr c,Tag_im_jahr_1
		inc bc

Tag_im_jahr_1   pop hl

		ret

Tag_im_jahr_tab .word 0                                      ; Januar
		.word 31                                     ; Febebruar
		.word 31+28                                  ; MÑrz
		.word 31+28+31                               ; April
		.word 31+28+31+30                            ; Mai
		.word 31+28+31+30+31                         ; Juni
		.word 31+28+31+30+31+30                      ; Juli
		.word 31+28+31+30+31+30+31                   ; August
		.word 31+28+31+30+31+30+31+30                ; September
		.word 31+28+31+30+31+30+31+30+31             ; Oktober
		.word 31+28+31+30+31+30+31+30+31+31          ; November
		.word 31+28+31+30+31+30+31+30+31+31+30       ; Dezmber

; ---- Wochentag bestimmen ----
;
; DE <-> Tagnummer
; A  <-  Wochentag ( 1EQU Montag )

Calc_wochentag  push bc
		push de
		push hl

		ld h,d
		ld l,e
		ld bc,Start_tag
		dec bc
		or a
		add hl,bc

		ld bc,7
		call Divi
		ld a,l
		inc a

		pop hl
		pop de
		pop bc

		or a

		ret

; ---- Test auf Schaltjahr ----
;
; DE   -> Jahre
; CFL <-  EQU0 kein Schaltjahr, EQU1 Schaltjahr

Schaltjahr      push af
		ld a,e
		and 11b
		jr z,Schaltjahr_1

		pop af
		or a
		ret

Schaltjahr_1    pop af
		scf
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

; ---- Prioritaeten zweier Task vergleichen ----
; HL ->
; BC ->

TaskCompare
			push af
			push bc
			push de
			push ix
			call Read_hl
			call Read_bc_bc
			ld ix,hl
			ld e,(ix+TaskObj_Priority)
			ld ix,bc
			ld a,(ix+TaskObj_Priority)
			cp a,e
			jr nc,TaskCompare1
			pop ix
			pop de
			pop bc
			pop af
			scf
			ret
TaskCompare1
			pop ix
			pop de
			pop bc
			pop af
			or a,a
			ret
			
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
					
IntVect_40		push ix
				ld ix,(It_40+2)
				push hl
				ld hl,(It_40)
				ex (sp),hl
				ret

IntVect_44		push ix
				ld ix,(It_44+2)
				push hl
				ld hl,(It_44)
				ex (sp),hl
				ret

IntVect_48		push ix
				ld ix,(It_48+2)
				push hl
				ld hl,(It_48)
				ex (sp),hl
				ret

IntVect_4c		push ix
				ld ix,(It_4c+2)
				push hl
				ld hl,(It_4c)
				ex (sp),hl
				ret

IntVect_50		push ix
				ld ix,(It_50+2)
				push hl
				ld hl,(It_50)
				ex (sp),hl
				ret

IntVect_54		push ix
				ld ix,(It_54+2)
				push hl
				ld hl,(It_54)
				ex (sp),hl
				ret

IntVect_58		push ix
				ld ix,(It_58+2)
				push hl
				ld hl,(It_58)
				ex (sp),hl
				ret

IntVect_5c		push ix
				ld ix,(It_5c+2)
				push hl
				ld hl,(It_5c)
				ex (sp),hl
				ret

IntVect_60		push ix
				ld ix,(It_60+2)
				push hl
				ld hl,(It_60)
				ex (sp),hl
				ret

IntVect_64		push ix
				ld ix,(It_64+2)
				push hl
				ld hl,(It_64)
				ex (sp),hl
				ret

IntVect_68		push ix
				ld ix,(It_68+2)
				push hl
				ld hl,(It_68)
				ex (sp),hl
				ret

IntVect_6c		push ix
				ld ix,(It_6c+2)
				push hl
				ld hl,(It_6c)
				ex (sp),hl
				ret

IntVect_70		push ix
				ld ix,(It_70+2)
				push hl
				ld hl,(It_70)
				ex (sp),hl
				ret

IntVect_74		push ix
				ld ix,(It_74+2)
				push hl
				ld hl,(It_74)
				ex (sp),hl
				ret

IntVect_78		push ix
				ld ix,(It_78+2)
				push hl
				ld hl,(It_78)
				ex (sp),hl
				ret

IntVect_7c		push ix
				ld ix,(It_7c+2)
				push hl
				ld hl,(It_7c)
				ex (sp),hl
				ret

IntVect_80		push ix
				ld ix,(It_80+2)
				push hl
				ld hl,(It_80)
				ex (sp),hl
				ret

IntVect_84		push ix
				ld ix,(It_84+2)
				push hl
				ld hl,(It_84)
				ex (sp),hl
				ret

IntVect_88		push ix
				ld ix,(It_88+2)
				push hl
				ld hl,(It_88)
				ex (sp),hl
				ret

IntVect_8c		push ix
				ld ix,(It_8c+2)
				push hl
				ld hl,(It_8c)
				ex (sp),hl
				ret

IntVect_90		push ix
				ld ix,(It_90+2)
				push hl
				ld hl,(It_90)
				ex (sp),hl
				ret

IntVect_94		push ix
				ld ix,(It_94+2)
				push hl
				ld hl,(It_94)
				ex (sp),hl
				ret

IntVect_98		push ix
				ld ix,(It_98+2)
				push hl
				ld hl,(It_98)
				ex (sp),hl
				ret

IntVect_9c		push ix
				ld ix,(It_9c+2)
				push hl
				ld hl,(It_9c)
				ex (sp),hl
				ret

IntVect_a0		push ix
				ld ix,(It_a0+2)
				push hl
				ld hl,(It_a0)
				ex (sp),hl
				ret

IntVect_a4		push ix
				ld ix,(It_a4+2)
				push hl
				ld hl,(It_a4)
				ex (sp),hl
				ret

IntVect_a8		push ix
				ld ix,(It_a8+2)
				push hl
				ld hl,(It_a8)
				ex (sp),hl
				ret

IntVect_ac		push ix
				ld ix,(It_ac+2)
				push hl
				ld hl,(It_ac)
				ex (sp),hl
				ret

IntVect_b0		push ix
				ld ix,(It_b0+2)
				push hl
				ld hl,(It_b0)
				ex (sp),hl
				ret

IntVect_b4		push ix
				ld ix,(It_b4+2)
				push hl
				ld hl,(It_b4)
				ex (sp),hl
				ret

IntVect_b8		push ix
				ld ix,(It_b8+2)
				push hl
				ld hl,(It_b8)
				ex (sp),hl
				ret

IntVect_bc		push ix
				ld ix,(It_bc+2)
				push hl
				ld hl,(It_bc)
				ex (sp),hl
				ret

IntVect_c0		push ix
				ld ix,(It_c0+2)
				push hl
				ld hl,(It_c0)
				ex (sp),hl
				ret

IntVect_c4		push ix
				ld ix,(It_c4+2)
				push hl
				ld hl,(It_c4)
				ex (sp),hl
				ret

IntVect_c8		push ix
				ld ix,(It_c8+2)
				push hl
				ld hl,(It_c8)
				ex (sp),hl
				ret

IntVect_cc		push ix
				ld ix,(It_cc+2)
				push hl
				ld hl,(It_cc)
				ex (sp),hl
				ret

IntVect_d0		push ix
				ld ix,(It_d0+2)
				push hl
				ld hl,(It_d0)
				ex (sp),hl
				ret

IntVect_d4		push ix
				ld ix,(It_d4+2)
				push hl
				ld hl,(It_d4)
				ex (sp),hl
				ret

IntVect_d8		push ix
				ld ix,(It_d8+2)
				push hl
				ld hl,(It_d8)
				ex (sp),hl
				ret

IntVect_dc		push ix
				ld ix,(It_dc+2)
				push hl
				ld hl,(It_dc)
				ex (sp),hl
				ret

IntVect_e0		push ix
				ld ix,(It_e0+2)
				push hl
				ld hl,(It_e0)
				ex (sp),hl
				ret

IntVect_e4		push ix
				ld ix,(It_e4+2)
				push hl
				ld hl,(It_e4)
				ex (sp),hl
				ret

IntVect_e8		push ix
				ld ix,(It_e8+2)
				push hl
				ld hl,(It_e8)
				ex (sp),hl
				ret

IntVect_ec		push ix
				ld ix,(It_ec+2)
				push hl
				ld hl,(It_ec)
				ex (sp),hl
				ret

IntVect_f0		push ix
				ld ix,(It_f0+2)
				push hl
				ld hl,(It_f0)
				ex (sp),hl
				ret

IntVect_f4		push ix
				ld ix,(It_f4+2)
				push hl
				ld hl,(It_f4)
				ex (sp),hl
				ret

IntVect_f8		push ix
				ld ix,(It_f8+2)
				push hl
				ld hl,(It_f8)
				ex (sp),hl
				ret

IntVect_fc		push ix
				ld ix,(It_fc+2)
				push hl
				ld hl,(It_fc)
				ex (sp),hl
				ret
				
Programm_ende

Ende

