; abstarct Printf Object

.include "helper.inc"
.include "PrintfObj.inc"
.include "ez80f91.inc"
.include "mini5_2.inc"
.include "FifoObj.inc"
.include "GpioPortObj.inc"

.assume ADL=0

xdef SerialObj

.define SerialObjSeg
segment SerialObjSeg

Esc		EQU 1bh
Cr              EQU 0dh   ; Wagenrcklauf
Lf              EQU 0ah   ; Linefeed

INSTS_MASK					EQU 00001110b
INSTS_RECIVE_DATA_READY		EQU 00000100b
INSTS_TRANSMIT_BUFFER_EMPTY EQU 00000010b

FifoLen		equ ffh
; TODO
Sysclk		equ 50000000
Baudrate	equ 115200

Class		equ 0
UartBase	equ 2
InFifo		equ 4
OutFifo		equ 6
Baud		equ 8
OutTask		equ 10
SioNr		equ 12
DataEnd		equ 13


; ---- Konstruktor ----
; A -> =0 Uart 0, =1 Uart 1
; CFL <- =1 Ok, =0 Fehler

SerialObj
		jr Start
		
		.word PrintfObj	; Superklasse
		.byte 11
		.word Free
		.word Pointprn_obj
		.word Meld_obj_out
		.word CharOut
		.word Terminal
		.word CharIn
		.word Baud_test
		.word Baud_set
		.word Baud_get
		.word Char_get
		.word ClrInBuffer

Start
		push af
		push bc
		push de
		push ix
		push af
		
		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		jr nc,StartErr
 
		ld bc,SerialObj
		ld ix,hl
		ld (ix+Class),c
		ld (ix+(Class+1)),b
		
 ; TODO Fehlerbehandlung
 
		push hl
		ld bc,FifoLen
		call FifoObj
		ld (ix+InFifo),l
		ld (ix+(InFifo+1)),h
		pop hl
		
		push hl
		ld bc,FifoLen
		call FifoObj
		ld (ix+OutFifo),l
		ld (ix+(OutFifo+1)),h
		pop hl
		
		pop af

		ld (ix+SioNr),a

		cp a,0
		jr nz,Start1
		
		ld bc,UART0_THR		; Basisadresse
		ld a,70h		; Interuptvektor
		
		jr Start2
		
Start1	cp a,1
		jr nz,StartErr1
		
		ld bc,UART1_THR		; Basisadresse
		ld a,74h		; Interuptvektor

Start2	ld (ix+UartBase),c
		ld (ix+(UartBase+1)),b
		ld de,0
		ld (ix+OutTask),d
		ld (ix+(OutTask+1)),e
		
		call HwDisable

		push hl

		ld hl,Interrupt
		rst 08h
		.byte Betn_SetIntVek
		
;		ld hl,Baudrate
		call UartInit
		
		pop hl
		
		jr nc,StartErr1
		
		pop ix
		pop de
		pop bc
		pop af
		scf
		ret
		
StartErr	
		pop af
StartErr1
		pop ix
		pop de
		pop bc
		pop af
		ld hl,0
		or a,a
		ret

; ---- Eingapuffer loeschen ----

ClrInBuffer
			push af
			push hl
			push ix

			ld l,(ix+InFifo)
			ld h,(ix+(InFifo+1))
			ld ix,hl
			
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Clear
			
			pop ix
			pop hl
			pop af
			ret
			
; ---- Objekt freigeben ----
; IX -> Zeiger auf Objekt

Free		push af
			push hl
			
			ld l,(ix+InFifo)
			ld h,(ix+(InFifo+1))
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Free
			
			ld l,(ix+OutFifo)
			ld h,(ix+(OutFifo+1))
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Free
			
			ld hl,ix
			rst 08h
			.byte Betn_Mem_free
			pop hl
			pop af
			ret
 		
; ---- serielle šbertragung initialisieren ----
;
; IX -> Zeiger auf Objekt
; HL -> Baudrate

UartInit    push af
			push bc
			push de
			
;			call  Baud_set
;			jr nc,UartInit1
			ld c,(ix+UartBase)
			ld b,(ix+(UartBase+1))

			ld a,10000000b
			ld d,UART0_LCTL-UART0_THR
			call IoOut
			
			ld d,UART0_LCTL-UART0_THR
			call IoOut

			ld a,LOW(Sysclk/16/Baudrate)
			ld d,UART0_BRG_L-UART0_THR
			call IoOut

			ld a,HIGH(Sysclk/16/Baudrate)
			ld d,UART0_BRG_H-UART0_THR
			call IoOut
			
			ld a,00000011b
			ld d,UART0_LCTL-UART0_THR
			call IoOut

			
			ld a,00000000b
			ld d,UART0_FCTL-UART0_THR
			call IoOut

			ld a,00000001b
			ld d,UART0_FCTL-UART0_THR
			call IoOut

			ld a,00000111b
			ld d,UART0_FCTL-UART0_THR
			call IoOut

			ld a,00000011b
			ld d,UART0_LCTL-UART0_THR
			call IoOut
			
			push ix
			
			ld a,(ix+SioNr)
			or a
			jr nz,UartInit2
			
			rst 08h
			.byte Betn_Get_PortD
			
			jr UartInit3
UartInit2
			rst 08h
			.byte Betn_Get_PortC
UartInit3
			push bc
			ld a,GpioModeAlternateFunctiuon
			ld b,00000011b
			
			rst 08h
			.byte Betn_Objekt_call
			.byte GpioPortObj_SetMode
			
			pop bc
			
			pop ix
			
			ld a,00000001b
			ld d,UART0_IER-UART0_THR
			call IoOut
			
			pop de
			pop bc
			pop af
			scf
			ret     
			
UartInit1	pop de
			pop bc
			pop af
			or a,a
			ret     

; ---- 

Pointprn_obj	rst 08h
			.byte Betn_ObjektSuperJmp
			.byte PrintfObj_Pointprn
			
MeldOut		rst 08h
			.byte Betn_ObjektSuperJmp
			.byte PrintfObj_MeldOut

; ---- Baudrate einstellen ----

; HL -> Baudrate ( muss ganzzahliger Teiler von 38400 sein )
; CFL <- =1 Baudrate eingestellt ; =0 Fehler

Baud_set    push hl

			call Baud_test
			jr nc,Baud_set_1

			push bc
			push de
			
			ld c,(ix+UartBase)
			ld b,(ix+(UartBase+1))
			
			ld a,10000000b
			ld d,UART0_LCTL-UART0_THR
			call IoOut
			
			ld d,UART0_LCTL-UART0_THR
			call IoOut

			ld a,l
			ld d,UART0_BRG_L-UART0_THR
			call IoOut

			ld a,h
			
			ld d,UART0_BRG_H-UART0_THR
			call IoOut
			
			ld a,00000011b
			ld d,UART0_LCTL-UART0_THR
			call IoOut

			pop de
			pop bc
			pop hl

			ld (ix+Baud),l
			ld (ix+(Baud+1)),h

			scf	
			ret

Baud_set_1	pop hl
			or a,a
			ret

; ---- Baudrate einstellen ----

; HL -> Baudrate ( muss ganzzahliger Teiler von 38400 sein )
; HL <- Teiler
; CFL <- =1 Baudrate eingestellt ; =0 Fehler

Baud_test       
		push af
		push bc
		push de

		ld b,h          ; ( 38400 / Baudrate ) * 2 -> HL
		ld c,l
		ld hl,38400
		call Divi
		jr nc,Baud_test_1 ; Division durch 0 ?
		ld a,h            ; Teiler ganzzahlig ?
		or l
		jr nz,Baud_test_1
		ld b,d
		ld c,e
		ld hl,Sysclk/16/38400
		call Multi
		jr nc,Baud_test_1

		pop de
		pop bc
		pop af
	
		scf
		ret
		
Baud_test_1     
		pop de
		pop bc
		pop af
		
		or a,a

		ret
		
; ---- Baudrate holen ----
; IX -> Zeiger auf objekt

Baud_get	ld l,(ix+Baud)
			ld h,(ix+(Baud+1))
			ret
; ----
; IX -> Zeiger auf objekt

HwDisable	push af
			push bc
			push de
			
			ld c,(ix+UartBase)
			ld b,(ix+(UartBase+1))
			
			ld a,0			; Interrupts diablen
			ld d,UART0_IER-UART0_THR
			call IoOut

			pop de
			pop bc
			pop af
			
			ret
			
;---- Zeichen von RS 232 holen ----
; IX -> Zeiger auf objekt
; A <- Zeichen
; CFL <- =1 zeichen geholt, =0 kein Zeichen da
CharIn  push hl
		push ix
		ld l,(ix+InFifo)
		ld h,(ix+(InFifo+1))
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Get
		pop ix
		pop hl
		ret

;---- RS 232 Ausgabe ----
; IX -> Zeiger auf objekt
; A  -> Zeichen
CharOut		push af
			push bc
			push de
			push hl
			push ix
			
			ld c,(ix+UartBase)
			ld b,(ix+(UartBase+1))
			
CharOut1
			rst 08h
			.byte Betn_Int_dis

			push ix
			ld l,(ix+OutFifo)
			ld h,(ix+(OutFifo+1))
			ld ix,hl
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Put
			pop ix
			
			push af
			ld d,UART0_IER-UART0_THR
			call IoIn
			or a,00000010b
			call IoOut
			pop af
			
			jr c,CharOut2
			
			rst 08h
			.byte Betn_GetAktTask
			
			call Test_HL
			jr nz,CharOut3

			rst 08h
			.byte Betn_Int_old
			jr CharOut1
CharOut3
			ld (ix+OutTask),l
			ld (ix+(OutTask+1)),h

			ld hl,OutTaskChancel
			
			rst 08h
			.byte Betn_Suspend
		
			jr CharOut1
			
CharOut2
			rst 08h
			.byte Betn_Int_old
			
			pop ix
			pop hl
			pop de
			pop bc
			pop af
			ret

; ----- Task Chanceln ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Task

OutTaskChancel
		push af
		ld a,(ix+OutTask)
		cp l
		jr nz,OutTaskChancel1
		ld a,(ix+OutTask+1)
		cp h
		jr nz,OutTaskChancel1
		xor a
		ld (ix+OutTask),a
		ld (ix+OutTask+1),a

OutTaskChancel1
		pop af
		ret

; ---- Terminalemulation VT52 steuern ----
;
; IX -> Objekt
; A  -> CODE ( Pf_cls, ... )
; H  -> Zeile beginnend mit 0
; L  -> Spalte beginnend mit 0

Terminal		push af
		
		push hl
		ld hl,Terminal_tab

		call Meld_obj_out
		pop hl

		cp Pf_pos
		jr nz,Terminal_1

		; Cursorpositon ausgeben

		push hl
		push hl
		
		ld l,h
		ld h,0
		inc l
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Esc,"[",Pf_s,Pf_dez,";",0

		pop hl
		
		ld h,0
		inc l
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Pf_s,Pf_dez,"H",0
		ld a,' '

		pop hl
Terminal_1      pop af

		ret

Terminal_tab	.byte Esc, '[H', Esc, '[2J', 0 	; CLRSCR
		.byte Esc, '[H',0                ; HOME
		.byte Esc, '[A',0		; UP
		.byte Esc, '[B',0		; DOWN
		.byte Esc, '[C',0		; RIGHT
		.byte Esc, '[D',0		; LEFT
		.byte Esc, '[K',0		; CLRL
		.byte Esc, '[J',0		; CLRS
		.byte Esc, 'M',0		; DOWNSCROLL
		.byte Esc, 'Y',0		; POS
		.byte 0

; ---- Meldung auf Objekt ausgeben ----
;
; IX -> Objekt
; A  -> Nummer der Meldung
; HL -> Tabelle der Meldungen
; CFL <- EQU1 ok, EQU0 nicht gefunden

Meld_obj_out    push af
		push bc
		push de
		push hl

		inc a
		ld b,a

Meld_obj_out_1  ld a,(hl)       ; Tabellenedne erreicht ?
		or a
		jr z,Meld_obj_out_2

		djnz Meld_obj_out_3     ; Meldung gefunden ?

		ld d,h
		ld e,l
		call Pointprn_obj

Meld_obj_out_2  pop hl
		pop de
		pop bc
		pop af
		ret

Meld_obj_out_3  inc hl        ; nicht gefunden, dann n„chste suchen
		call Read_str
		jr Meld_obj_out_1

; --- Zeichen holen ----

Char_get 
		push hl
		push ix
		ld l,(ix+InFifo)
		ld h,(ix+(InFifo+1))
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_GetBlocking
		pop ix
		pop hl
		ret

			ret

; ---- Interruptroutiene ----
; IX -> Zeiger auf Objekt

Interrupt
		push af
		push bc
		push de
		
		rst 08h
		.byte  Betn_Int_dis
		ld c,(ix+UartBase)
		ld b,(ix+(UartBase+1))

		ld d,UART0_IIR-UART0_THR
		call IoIn

		and a,INSTS_MASK
		cp a,INSTS_RECIVE_DATA_READY
		jr nz,Interrupt1
		call Recive_Data_Ready
		jr Interrupt2 
		
Interrupt1
		cp a,INSTS_TRANSMIT_BUFFER_EMPTY
		jr nz,Interrupt3
		call Transmit_Buffer_Empty

Interrupt2
		jr nc,Interrupt3
		pop de
		pop bc
		pop af
		pop ix
		
		rst 08h
		.byte Betn_Yield
		
Interrupt3
		pop de
		pop bc
		pop af
		pop ix
		rst 08h
		.byte Betn_Int_ret

; ---- Interruptroutiene recive ----
; IX -> Zeiger auf Objekt
; BC -> UART Basisadresse

Recive_Data_Ready
		push af
		push de
		push hl
		
		ld d,UART0_RBR-UART0_THR
		call IoIn

		ld e,(ix+InFifo)
		ld d,(ix+(InFifo+1))

		push ix
		ld ix,de

		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_InTaskPending

		push af
		
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Put

		pop af
		pop ix

		jr nc,Recive_Data_Ready1

		pop hl
		pop de
		pop af
		scf
		ret
		
Recive_Data_Ready1
		pop hl
		pop de
		pop af
		or a
		ret

; ---- Interruptroutiene transmit ----
; IX -> Zeiger auf Objekt
; BC -> UART Basisadresse
		
Transmit_Buffer_Empty
			push af
			push de
			push hl
			
Transmit_Buffer_Empty1
			ld l,(ix+OutFifo)
			ld h,(ix+(OutFifo+1))
			
			push ix
			ld ix,hl
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Get
			pop ix
			jr nc,Transmit_Buffer_Empty2
			
			ld d,UART0_THR-UART0_THR
			call IoOut

			push ix
			ld ix,hl
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_ElementAvailable
			pop ix
			jr c,Transmit_Buffer_Empty3

Transmit_Buffer_Empty2
			ld d,UART0_IER-UART0_THR
			call IoIn
			and a,~00000010b
			call IoOut

Transmit_Buffer_Empty3
			ld l,(ix+OutTask)
			ld h,(ix+(OutTask+1))
			call Test_HL
			jr z,Transmit_Buffer_Empty4

			rst 08h
			.byte Betn_ScheduleNow
			
			ld hl,0
			ld (ix+OutTask),l
			ld (ix+(OutTask+1)),h
			pop hl
			pop de
			pop af
			scf
			ret
			
Transmit_Buffer_Empty4
			pop hl
			pop de
			pop af
			or a,a
			ret