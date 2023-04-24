; Encoder Object

.include "mini5_2.inc"
.include "GpioPortObj.inc"
.include "helper.inc"

.assume ADL=0

xdef EncoderObj

.define xyz
segment xyz

Class			equ 0
MaxVal			equ 2
AktVal			equ 3
LastRead		equ 4
DataEnd			equ 5

; --- Konstruktor ----

EncoderObj
		jr Start
		
		.word 0000h 	; keine Superklasse

		.byte 2

		.word GetAktVal
		.word SetMaxVal
		
; ---- Konstruktor ----
; B  -> max Wert
; C  -> aktueller Wert
; HL <- zeiger auf Objekt
Start	push af
		push de
		push bc
		push ix

		ld a,b
		sub c
		jr nc,Start1
		ld c,b
Start1
		push bc
		ld bc,DataEnd
		
		rst 08h
		.byte Betn_Mem_Alloc

		pop bc
		
		jr nc,Err
		
		push hl

		ld ix,hl

		ld hl,EncoderObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		ld (ix+AktVal),c
		ld (ix+MaxVal),b
		
		ld iy,ix
		
		rst 08h
		.byte Betn_Get_PortA
		
		ld hl,Interrupt
		ld b,ENC_A|ENC_B

		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetInterruptVektor
		
		ld a,GpioModeDualEdge
		ld b,ENC_A|ENC_B
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMode
		
		pop hl

		pop ix
		pop bc
		pop de
		pop af
		scf
		ret
		
Err		pop ix
		pop bc
		pop de
		pop af
		or a,a
		ret

; ---- Aktuellen Wert hohlen ----
; IX -> Zeiger auf Objekt
; A <- Aktueller Wert

GetAktVal
		ld a,(ix+AktVal)
		ret
		
;---- Maximalen Encoder Wert setzen ----
; IX -> Zeiger auf Objekt
; B  -> max Wert
; C  -> aktueller Wert

SetMaxVal push af
		  ld a,b
		  sub c
  		  jr nc,SetMaxVal1
		  ld c,b
SetMaxVal1
		 rst 08h
		 .byte Betn_Int_dis
		 
		 ld (ix+AktVal),c
		 ld (ix+MaxVal),b
		 
		 rst 08h
		 .byte Betn_Int_old
		 
		 pop af
		 
		 ret
		 
; ---- Interruptroutine ----

Interrupt
		push af
		push bc
		push hl
		
		push ix
		
		rst 08h
		.byte Betn_Int_dis
		
		rst 08h
		.byte Betn_Get_PortA
		
		ld b,ENC_A | ENC_B
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_RestInterrupt
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ReadPort
		
		ld bc,0
		
		push af
		and ENC_A
		jr z,Interrupt1
		ld b,1
Interrupt1
		pop af
		and ENC_B
		jr z,Interrupt2
		ld c,2
Interrupt2
		xor a
		add b
		add c
		ld b,a
		
		pop ix
		
		ld a,(ix+LastRead)
		and 00001100b
		or b
		ld b,a
		
		ld hl,Table
		call ByteGet
		
		or a

		ld a,(ix+AktVal)

		jp p,Interrupt4			; Inkrement positiv

		or a
		jr nz,Interrupt3		; AktWert != 0 -> AktWert = AktWert-1

		ld a,(ix+MaxVal)		; AktWert == 0 -> AktWert = MAxWert
		jr Interrupt6
Interrupt3
		add ffh
		jr Interrupt6
Interrupt4
		jr z,Interrupt7			; Inkrement null -> keine Aenderung
		cp a,(ix+MaxVal)
		jr c,Interrupt5			; Akt Wert < MaxWert -> AktWert = 0
		xor a
		ld a,0
		jr Interrupt6
Interrupt5
		add 1
Interrupt6
		ld (ix+AktVal),a
Interrupt7
		sla b
		sla b
		ld (ix+LastRead),b
		
		pop hl
		pop bc
		pop af
		pop ix

		rst 08h
		.byte Betn_Int_ret
		
		
		; Vorwaerts   00 -> 01 -> 11 -> 10 -> 00
		; Reuckwaerts 00 -> 10 -> 11 -> 01 -> 00
		
Table  .byte 00h,01h,ffh,00h 				; 00 -> 00, 00 ->01, 00 -> 10, 00->11
       .byte 00h,00h,00h,00h 				; 01 -> 00, 01 ->01, 01 -> 10, 01->11
       .byte 00h,00h,00h,00h 				; 10 -> 00, 10 ->01, 10 -> 10, 10->11
       .byte 00h,ffh,01h,00h 				; 11 -> 00, 11 ->01, 11 -> 10, 11->11
