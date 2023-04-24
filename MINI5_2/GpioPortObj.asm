; ---- GPIO Port Objekt ----

.include "ez80f91.inc"
.include "helper.inc"
.include "mini5_2.inc"
.include "GpioPortObj.inc"

Class			equ 0
PortNr			equ 2
DrAdd			equ 3
Latch			equ 4
Alt0Add			equ 5
DataEnd			equ 6

xdef GpioPortObj

GpioPortObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 9
		.word SetMode
		.word SetMask
		.word ClrMask
		.word InvertMask
		.word WriteMask
		.word ReadPort
		.word Readlatch
		.word RestInterrupt
		.word SetInterruptVektor
		
; ---- Konstruktor ----
; B -> Portnummer

Start
		push de
		push ix
		push af
		push bc
		
		ld a,b
		cp Gpio_PortD+1
		jr nc,Err
		
		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		
		jr nc,Err
		
		pop bc
		
		ld ix,hl
		
		ld hl,GpioPortObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		ld (ix+PortNr),b
		
		ld hl,DRTab
		call ByteGet
		ld (ix+DrAdd),a
		
		ld hl,Alt0Tab
		call ByteGet
		ld (ix+Alt0Add),a
		
		ld hl,ix
		
		pop af
		pop ix
		pop de
		scf
		ret
Err
		pop bc
		pop af
		pop ix
		pop de
		or a
		ret

; --- GPIO Mode setzen ----
; IX -> Zeiger auf Objekt
; A -> GPIO Mode
; B -> Bitmaske
; C -> =0 Faling Edge =1 rising edge

SetMode		push af
			push bc
			push de
			push hl
			
			ld l,c
			ld h,a
			ld a,b
			ld d,a
			cpl
			ld e,a
			ld b,(ix+PortNr)
			ld a,h
			
			cp a,GpioModeOutput
			jr nz,SetMode1
			
			ld hl,Alt2Tab
			call ByteGet
			ld c,a
			
			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,Alt1Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,DDRTab
			call ByteGet
			ld c,a

			ld b,0
			in a,(bc)
			and e
			out (bc),a
			
			ld c,(ix+DrAdd)
			ld a,(ix+Latch)
			out (bc),a
			
			jr SetModeEnd
SetMode1
			cp a,GpioModeInput
			jr nz,SetMode6
			
			ld hl,Alt2Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,Alt1Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,DDRTab
			call ByteGet
			ld c,a

			ld b,0
			in a,(bc)
			or d
			out (bc),a
			
			jr SetModeEnd
SetMode6
			cp a,GpioModeDualEdge
			jr nz,SetMode2

			push bc
			ld b,0
			ld c,(ix+DrAdd)

			ld a,(ix+Latch)
			or d
			out (bc),a
			ld (ix+Latch),a
			
			pop bc
			
			ld hl,Alt2Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			or d
			out (bc),a
			pop bc
			
			ld hl,Alt1Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,DDRTab
			call ByteGet
			ld c,a

			ld b,0
			in a,(bc)
			and e
			out (bc),a
			
			jr SetModeEnd
SetMode2
			cp a,GpioModeAlternateFunctiuon
			jr nz,SetMode3
			
			ld hl,Alt2Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			or d
			out (bc),a
			pop bc
			
			ld hl,Alt1Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			and e
			out (bc),a
			pop bc
			
			ld hl,DDRTab
			call ByteGet
			ld c,a

			ld b,0
			in a,(bc)
			or d
			out (bc),a
			
			jr SetModeEnd
SetMode3
			cp a,GpioModeEdgeTriggert
			jr nz,SetModeErr
			
			push bc
			ld b,0
			ld c,(ix+DrAdd)
			ld a,l
			or a
			jr z,SetMode5

			ld a,(ix+Latch)
			or d
			out (bc),a
			ld (ix+Latch),a
			
			jr SetMode4
SetMode5
			ld a,(ix+Latch)
			and e
			out (bc),a
			ld (ix+Latch),a
SetMode4
			pop bc
			
			ld hl,Alt2Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			or d
			out (bc),a
			pop bc
			
			ld hl,Alt1Tab
			call ByteGet
			ld c,a

			push bc
			ld b,0
			in a,(bc)
			or d
			out (bc),a
			pop bc
			
			ld hl,DDRTab
			call ByteGet
			ld c,a

			ld b,0
			in a,(bc)
			or d
			out (bc),a
			
SetModeEnd	pop hl
			pop de
			pop bc
			pop af
			scf
			ret

SetModeErr	pop hl
			pop de
			pop bc
			pop af
			or a
			ret
			
; ---- Bits setzen ----
; IX -> Zeiger auf Objekt
; B -> Bitmaske

SetMask		push af
			push bc
			ld c,(ix+DrAdd)
			rst 08h
			.byte Betn_Int_dis
			ld a,(ix+Latch)
			or b
			ld b,0
			out (bc),a
			ld (ix+Latch),a
			rst 08h
			.byte Betn_Int_old
			pop bc
			pop af
			ret

; ---- Bits setzen ----
; IX -> Zeiger auf Objekt
; B -> Bitmaske

ClrMask		push af
			ld a,b
			cpl
			push bc
			ld b,a
			ld c,(ix+DrAdd)
			rst 08h
			.byte Betn_Int_dis
			ld a,(ix+Latch)
			and b
			ld b,0
			out (bc),a
			ld (ix+Latch),a
			rst 08h
			.byte Betn_Int_old
			pop bc
			pop af
			ret

; ---- Bits setzen ----
; IX -> Zeiger auf Objekt
; B -> Bitmaske

InvertMask	push af
			push bc
			ld c,(ix+DrAdd)
			rst 08h
			.byte Betn_Int_dis
			ld a,(ix+Latch)
			xor b
			ld b,0
			out (bc),a
			ld (ix+Latch),a
			rst 08h
			.byte Betn_Int_old
			pop bc
			pop af
			ret

; ---- Bits setzen ----
; IX -> Zeiger auf Objekt
; A -> Bit Werte
; B -> Bitmaske

WriteMask	push af
			push bc
			push de
			and b
			ld e,a
			ld a,b
			cpl
			ld b,a
			ld c,(ix+DrAdd)
			rst 08h
			.byte Betn_Int_dis
			ld a,(ix+Latch)
			and b
			or e
			ld b,0
			out (bc),a
			ld (ix+Latch),a
			rst 08h
			.byte Betn_Int_old
			pop de
			pop bc
			pop af
			ret


; ---- Port lesen ----
; IX -> Zeiger auf Objekt
; A  <- Port
ReadPort	push bc
			ld c,(ix+DrAdd)
			ld b,0
			in a,(bc)
			pop bc
			ret

; ---- Latch lesen ----
; IX -> Zeiger auf Objekt
; A <- Latch

Readlatch	ld a,(ix+Latch)
			ret
; ---- Interrupt zurücksetzen ----
; IX -> Zeiger auf Objekt
; B -> Maske

RestInterrupt	push af
				push bc
				push de
				ld e,b
				ld b,0
				ld c,(ix+DrAdd)
				ld a,(ix+Latch)
				out (bc),a
				ld c,(ix+Alt0Add)
				ld a,e
				out (bc),a
				pop de
				pop bc
				pop af
				ret

; --- Interruptvektor setzen ----
; IX -> Zeiger auf Objekt
; B -> Maske
; HL -> Interuptvektor
; IY -> Enviorment

SetInterruptVektor
		push af
		push bc
		push de
		push ix
		
		ld e,b
		
		ld a,(ix+PortNr)					; Interruptvektornummer -> B
		sla a
		sla a
 		sla a
 		sla a
 		sla a
		add 80h
		ld b,a

		ld ix,iy
SetInterruptVektor1
		ld a,e						; sind noch Interrupt vektoren zun setzen?
		or a
		jr z,SetInterruptVektor3	; nein => Ende
		
		srl a						; aktuelles Bitz -> CFL
		ld e,a						; neue Bistamske -> C
		ld a,b
		jr nc,SetInterruptVektor2	; soll der aktuelle Interruptvektor gesetzt werden, nein => weiter
		
		rst 08h
		.byte Betn_SetIntVek
SetInterruptVektor2		
		add 4						; Vektornummer aktualisieren
		ld b,a
		jr SetInterruptVektor1
SetInterruptVektor3
		pop ix
		pop de
		pop bc
		pop af
		
		ret
		
Alt0Tab	.byte PA_ALT0,PB_ALT0,PC_ALT0,PD_ALT0
Alt1Tab	.byte PA_ALT1,PB_ALT1,PC_ALT1,PD_ALT1
Alt2Tab	.byte PA_ALT2,PB_ALT2,PC_ALT2,PD_ALT2
DRTab   .byte PA_DR,PB_DR,PC_DR,PD_DR
DDRTab  .byte PA_DDR,PB_DDR,PC_DDR,PD_DDR