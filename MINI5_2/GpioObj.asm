; ---- RTC Objekt ----

.include "ez80f91.inc"
.include "helper.inc"
.include "mini5_2.inc"
.include "GpioPortObj.inc"

Class			equ 0
Mask			equ 2
GpioPort		equ 3
Task			equ 5
DataEnd			equ 7

xdef GpioObj

GpioObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 2
		.word WaitForEvent
		.word GetBit

; ---- Konstruktor ----
; HL -> GpioPortObj
; B -> Bitmaske
; C -> =0 Faling Edge =1 rising edge

Start
		push af
		push bc
		push de
		push ix
		push iy
		push hl
		push bc
		
		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		
		pop bc
		
		jr nc,Err
		
		ld ix,hl

		ld hl,GpioObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		ld (ix+Mask),b
		xor a
		ld (ix+Task),a
		ld (ix+Task+1),a

		ld iy,ix
		pop hl
		ld ix,hl
		
		ld (iy+GpioPort),l
		ld (iy+GpioPort+1),h

		ld hl,Interrupt
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetInterruptVektor
		
		ld a,GpioModeEdgeTriggert

		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMode
		
		ld hl,iy
		
		pop iy
		pop ix
		pop de
		pop bc
		pop af
		scf
		ret
Err
		pop hl
		pop iy
		pop ix
		pop de
		pop bc
		pop af
		or a
		ret

; ---- Wait for Event ----

WaitForEvent
		push af
		push hl
		
		rst 08h
		.byte Betn_Int_dis
		
		rst 08h
		.byte Betn_GetAktTask
		
		ld (ix+Task),l
		ld (ix+Task+1),h
		
		call Test_HL
		jr z,WaitForEvent1
		
		ld hl,TaskChancel
		
		rst 08h
		.byte Betn_Suspend

WaitForEvent1
		pop hl
		pop af
		
		ret

; ----- Task Chanceln ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Task

TaskChancel
		push af
		ld a,(ix+Task)
		cp l
		jr nz,TaskChancel1
		ld a,(ix+Task+1)
		cp h
		jr nz,TaskChancel1
		xor a
		ld (ix+Task),a
		ld (ix+Task+1),a
TaskChancel1
		pop af
		ret
		

; ---- Bit holhlen
; IX -> Zeiger auf Objekt
; A   <- Bitmaske
; CFL <- =1 Bit gesetzt,l 00 Bit geloescht

GetBit	push hl
		push bc
		push ix

		ld l,(ix+GpioPort)
		ld h,(ix+GpioPort+1)
		ld b,(ix+Mask)

		ld ix,hl
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ReadPort
		
		and b
		jr z,GetBit1
		
		pop ix
		pop bc
		pop hl
		or a
		scf
		ret
GetBit1
		pop ix
		pop bc
		pop hl
		or a
		ret
		
		
; --- Interruptroutiene ----

Interrupt
		push af
		push bc
		push de
		push hl
		
		rst 08h
		.byte Betn_Int_dis
		
		push ix

		ld l,(ix+GpioPort)
		ld h,(ix+GpioPort+1)
		ld b,(ix+Mask)
		
		ld ix,hl
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_RestInterrupt
		
		pop ix
		
		ld l,(ix+Task)
		ld h,(ix+Task+1)
		
		call Test_HL
		jr z,Interrupt1

		xor a
		ld (ix+Task),a
		ld (ix+Task+1),a
		
		rst 08h
		.byte Betn_ScheduleNow

		pop hl
		pop de
		pop bc
		pop af
		pop ix

		rst 08h
		.byte Betn_Yield
		
Interrupt1
		pop hl
		pop de
		pop bc
		pop af
		pop ix

		rst 08h
		.byte Betn_Int_ret
		
Alt0Tab	.byte PA_ALT0,PB_ALT0,PC_ALT0,PD_ALT0