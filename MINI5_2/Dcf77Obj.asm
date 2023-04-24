; DCF77 Object

.include "mini5_2.inc"
.include "helper.inc"
.include "ez80f91.inc"
.include "GpioObj.inc"
.include "Task.inc"
.include "GpioPortObj.inc"
.include "RtcObj.inc"
.include "FifoObj.inc"

.assume ADL=0

xdef Dcf77Obj

.define xyz
segment xyz

Cr				equ 13

Dcf77Priority	equ 40h
Dcf77StackSize	equ 100h

Class			equ 0
Dcf77Gpio		equ 2
Fifo			equ 4
TimerVal		equ 6
DateTimeValid   equ 8
DateTime        equ 9
DataEnd			equ DateTime+DATETIME_SIZE

StartYear		equ 2000

; --- Konstruktor ----

Dcf77Obj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 3
		.word GetChar
		.word Clear
		.word GetTime
		
; ---- Konstruktor ----

Start	push af
		push de
		push bc
		push ix
		
		ld bc,DataEnd
		
		rst 08h
		.byte Betn_Mem_Alloc
		
		jr nc,Err
		
		ld ix,hl
		
		push hl
		ld bc,5
		call FifoObj
		ld (ix+Fifo),l
		ld (ix+Fifo+1),h

		xor a
		ld (ix+DateTime+SEC_OFFSET),a
		ld (ix+DateTime+MIN_OFFSET),a
		ld (ix+DateTime+HOUR_OFFSET),a
		ld (ix+DateTime+DOW_OFFSET),a
		inc a
		ld (ix+DateTime+DOM_OFFSET),a
		ld (ix+DateTime+MON_OFFSET),a
		ld (ix+DateTime+DOW_OFFSET),a
		ld hl,StartYear

		ld (ix+DateTime+YEAR_OFFSET),l
		ld (ix+DateTime+YEAR_OFFSET+1),h
		pop hl
		
		push hl
		ld hl,Dcf77Obj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		
		rst 08h
		.byte Betn_Get_Timer

		ld l,(ix+TimerVal)
		ld h,(ix+TimerVal+1)
		
		xor a
		ld (ix+DateTimeValid),a

		push ix

		rst 08h
		.byte Betn_Get_PortA
		
		ld hl,ix
		
		pop ix
		
		ld c,GpioRisingEdge
		ld b,DCF_77 | DCF_77_MIRROR

		call GpioObj
		ld (ix+Dcf77Gpio),l
		ld (ix+Dcf77Gpio+1),h
		
		ld a,Dcf77Priority
		ld hl,Dcf77Task
		ld bc,Dcf77StackSize
		call TaskObj
		
		rst 08h
		.byte Betn_ScheduleNow	

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
	
; -----

GetChar	push ix
		push hl
		ld l,(ix+Fifo)
		ld h,(ix+Fifo+1)
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Get
		pop hl
		pop ix
		ret
		
; -----

Clear	push ix
		push hl
		ld l,(ix+Fifo)
		ld h,(ix+Fifo+1)
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Clear
		pop hl
		pop ix
		ret

; ---- Zeit hohlen ----
; IX -> Zeiger auf Objekt
; HL -> Puffer

GetTime	push af
		push hl
		
		rst 08h
		.byte Betn_Int_dis
		
		ld a,(ix+DateTime+SEC_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+MIN_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+HOUR_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+DOM_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+MON_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+YEAR_OFFSET)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+YEAR_OFFSET+1)
		ld (hl),a
		inc hl

		ld a,(ix+DateTime+DOW_OFFSET)
		ld (hl),a
		inc hl

		rst 08h
		.byte Betn_Int_old
		
		pop hl
		pop af
		
		ret
		
; ----
; IX -> DCF77 objekt

Dcf77Task
		ld b,1
		call GetByte
		jr c,Dcf77Task
Dcf77Task1		
		xor a
		ld (ix+DateTime+SEC_OFFSET),a

		ld a,Cr
		ld l,(ix+Fifo)
		ld h,(ix+Fifo+1)
		push ix
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Put
		
		pop ix
		push ix
		
		ld a,(ix+DateTimeValid)
		or a
		jr z,Dcf77Task2
		
		xor a
		ld (ix+DateTimeValid),a

		ld hl,ix
		ld bc,DateTime
		add hl,bc
		
		rst 08h
		.byte Betn_GetRtc
		
		rst 08h
		.byte Betn_Objekt_call
		.byte RtcObj_SetTime

Dcf77Task2
		pop ix
		
		ld b,20
		call GetByte
		jr nc,Dcf77Task1
		
		ld b,7			; Minute lesen
		call GetByte
		jr nc,Dcf77Task1

		call Bcd2bin
		ld (ix+(DateTime+MIN_OFFSET)),a
		
        ld b,1			; Parität Minute
        call GetByte
		jr nc,Dcf77Task1

		ld b,6			; Stunde lesen
		call GetByte
		jr nc,Dcf77Task1

		call Bcd2bin
		ld (ix+(DateTime+HOUR_OFFSET)),a
		
        ld b,1			; Parität Stunde
        call GetByte
		jr nc,Dcf77Task1

		ld b,6			; Kalendertag lesen
		call GetByte
		jr nc,Dcf77Task1

		call Bcd2bin
		ld (ix+(DateTime+DOM_OFFSET)),a
		
		ld b,3			; Wochentag lesen
		call GetByte
		ld (ix+(DateTime+DOW_OFFSET)),a
		jr nc,Dcf77Task1
		
		ld b,5			; Monat lesen
		call GetByte
		jr nc,Dcf77Task1

		call Bcd2bin
		ld (ix+(DateTime+MON_OFFSET)),a
		
		ld b,8			; Jahr lesen
		call GetByte
		jr nc,Dcf77Task1

		call Bcd2bin
		ld l,a
		ld h,0
		ld bc,StartYear
		add hl,bc
		ld (ix+(DateTime+YEAR_OFFSET)),l
		ld (ix+(DateTime+YEAR_OFFSET+1)),h
		
		ld b,1			; Pariteat Datum
        call GetByte
		jr nc,Dcf77Task1

		ld a,1
		ld (ix+DateTimeValid),a
	
		jr Dcf77Task
		
; ---- Get Bit ----
; IX -> DCF77 objekt
; A <- =0 0 gelesen, =1 1 gelsen
; CFL <- =0 neue Minute, =1 Bit gelesen

GetBit
		push bc
		push hl
GetBit4
		push ix
		ld l,(ix+Dcf77Gpio)
		ld h,(ix+Dcf77Gpio+1)

		ld ix,hl
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioObj_GetBit
		
		ld hl,150
		rst 08h
		.byte Betn_Timer

		rst 08h
		.byte Betn_Objekt_call
		.byte GpioObj_WaitForEvent

		pop ix

		rst 08h
		.byte Betn_Get_Timer
		

		inc (ix+DateTime+SEC_OFFSET)

		ld c,(ix+TimerVal)
		ld b,(ix+TimerVal+1)

		ld (ix+TimerVal),l
		ld (ix+TimerVal+1),h
		
		or a
		
		sbc hl,bc
		
		ld bc,1100
		call Cmp_hl_bc
		jr 	c,GetBit3
		
		ld bc,1900
		call Cmp_hl_bc
		jr 	c,GetBit4
		
		ld bc,2100
		call Cmp_hl_bc
		jr nc,GetBit4
		jr GetBit1
GetBit3
		ld hl,150
		rst 08h
		.byte Betn_Timer
		
		push ix
		
		ld l,(ix+Dcf77Gpio)
		ld h,(ix+Dcf77Gpio+1)
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioObj_GetBit
		
		pop ix

		ld hl,600
		rst 08h
		.byte Betn_Timer
		
		and DCF_77
		jr z,GetBit2
		
		ld a,'1'
		ld l,(ix+Fifo)
		ld h,(ix+Fifo+1)
		push ix
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Put
		pop ix
		
		ld a,1
		pop hl
		pop bc
		scf
		ret

GetBit2 
		ld a,'0'
		ld l,(ix+Fifo)
		ld h,(ix+Fifo+1)
		push ix
		ld ix,hl
		rst 08h
		.byte Betn_Objekt_call
		.byte FifoObj_Put		
		pop ix
		
		xor a
		pop hl
		pop bc
		scf
		ret

GetBit1	
		xor a
		pop hl
		pop bc
		ret
		
; ---- Get Byte ----
; IX -> DCF77 objekt
; B -> Anzahl bits
; A <- =0 0 gelesen, =1 1 gelsen
; CFL <- =0 neue Minute, =1 Bit gelesen

GetByte	push bc
		push de
		
		ld c,1
		ld e,0
GetByte1		
		call GetBit
		jr nc,GetByte3
		
		or a
		jr z,GetByte2
		
		ld a,e
		or c
		ld e,a
GetByte2
		sla c
		djnz GetByte1
		
		ld a,e
		
		pop de
		pop bc
		scf
		ret
GetByte3
		xor a
		pop de
		pop bc
		ret