; abstarct Printf Object

.include "mini5_2.inc"
.include "PrintfObj.inc"
.include "helper.inc"

.assume ADL=0

xdef FifoObj

xref Ex_hl_de
xref Read_hl
xref Divi
xref Hex4bit
xref Cmp_hl_bc
xref Read_str
xref Cmp_hl_bc

.define xyz
segment xyz

Class		equ 0
Size		equ 2
WritePos	equ 4
ReadPos     equ 6
InTask		equ 8
DataEnd		equ 10

; --- Konstruktor ----
; BC -> Groesse des FIFOs
; HL <- Adresse des FIFO Onbjekts

FifoObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		.byte 7
		
		.word Free
		.word Put
		.word Get
		.word ElementAvailable
		.word Clear
		.word GetBlocking
		.word InTaskPending
		
; ---- Konstruktor ----
; BC  -> Grösse des Fifos
; HL  <- Addresse des Objekts (0 bei Fehler)
; CFL <- =1 OK =0 Fehler

Start
		push af
		push bc
		push de
		
		inc bc
		
		ld hl,DataEnd
		add hl,bc
		push bc
		ld bc,hl
		
		rst 08h
		.byte Betn_Mem_Alloc
		pop bc
		jr nc,Start1
		push hl
		push bc
		
		ld bc,FifoObj
		ld (hl),bc
		inc hl
		inc hl
		
		pop bc
		
		ld (hl),bc
		inc hl
		inc hl
		ld bc,0
		ld (hl),bc
		inc hl
		inc hl
		ld (hl),bc
		
		pop hl
		
		push ix
		ld ix,hl
		xor a
		ld (ix+InTask),a
		ld (ix+InTask+1),a
		pop ix
		
		pop de
		pop bc
		pop af
		scf
		ret
		
Start1	pop de
		pop bc
		pop af
		or a,a
		ret

; ---- Objekt freigeben ----
; IX -> Zeiger auf Objekt

Free		push af
			push hl
			
			ld hl,ix
			rst 08h
			.byte Betn_Mem_free
			pop hl
			pop af
			ret
 		
; ---------------
; IX -> Zeiger auf Objekt
; HL -> relativer Zeiger auf FIFO Position
; HL <- Heiger um eins erhöht m it warp aound

IncPointer
		push af
		push bc
		inc hl
		ld c,(ix+Size)
		ld b,(ix+(Size+1))
		call Cmp_hl_bc
		jr c,IncPointer1
		ld hl,0
IncPointer1
		pop bc
		pop af
		ret
		
; ----
; IX -> Zeiger auf Objekt
; HL -> relativer Zeiger auf FIFO Position
; HL <- absolute FIFO Position

GetAbsPos
		push af
		push bc
		ld a,DataEnd
		call Add_HL_A
		ld bc,ix
		add hl,bc
		pop bc
		pop af
		ret


; ----
; IX  -> Zeiger auf Objekt
; CFL <- =1 Zeichen verfügbar, sonst =0

ElementAvailable		
		push af
		push bc
		ld a,(Ix+WritePos)
		ld b,(Ix+ReadPos)
		cp a,b
		jr z,ElementAvailable1
		pop bc
		pop af
		scf
		ret
ElementAvailable1
		pop bc
		pop af
		or a,a
		ret
; ----
; IX  -> Zeiger auf Objekt
; A   -> Zeichen
; CFL <- =1 Zeichen geschrieben =0 FIFO voll
Put		push hl
		push bc

		rst 08h
		.byte Betn_Int_dis

		ld l,(ix+InTask)
		ld h,(ix+(InTask+1))
		call Test_HL
		jr z,Put2
		
		rst 08h
		.byte Betn_ScheduleNow
		
		ld hl,0
		ld (ix+InTask),l
		ld (ix+(InTask+1)),h
Put2
		ld l,(ix+WritePos)
		ld h,(ix+(WritePos+1))
		push hl
		call IncPointer
		ld c,(ix+ReadPos)
		ld b,(ix+(ReadPos+1))
		call Cmp_hl_bc
		jr z,Put1
		ld (ix+WritePos),l
		ld (ix+(WritePos+1)),h
		pop hl
		call GetAbsPos
		ld (Hl),a
		rst 08h
		.byte Betn_Int_old
		pop bc
		pop hl
		scf
		ret
Put1	pop hl
		rst 08h
		.byte Betn_Int_old
		pop bc
		pop hl
		or a,a
		ret
		
; ----
; IX  -> Zeiger auf Objekt
; A   <- Zeichen
; CFL <- =1 Zeichen geleseb =0 FIFO leer

Get		push hl
		push bc
		rst 08h
		.byte Betn_Int_dis
		ld l,(ix+ReadPos)
		ld h,(ix+(ReadPos+1))
		ld c,(ix+WritePos)
		ld b,(ix+(WritePos+1))
		call Cmp_hl_bc
		jr z,Get1
		push hl
		call IncPointer
		ld (ix+ReadPos),l
		ld (ix+(ReadPos+1)),h
		pop hl
		call GetAbsPos
		ld a,(Hl)
		rst 08h
		.byte Betn_Int_old
		pop bc
		pop hl
		scf
		ret
Get1	rst 08h
		.byte Betn_Int_old
		pop bc
		pop hl
		or a,a
		ret

; --- Zeichen holen ----

GetBlocking	push bc
			push hl

GetBlocking1			
			rst 08h
			.byte Betn_Int_dis
			
			call Get
			jr c,GetBlocking3
			
			rst 08h
			.byte Betn_GetAktTask
			
			call Test_HL
			jr nz,GetBlocking2

			rst 08h
			.byte Betn_Int_old
			jr GetBlocking1
			
GetBlocking2
			ld (ix+InTask),l
			ld (ix+(InTask+1)),h

			ld hl,InTaskChancel
			
			rst 08h
			.byte Betn_Suspend
		
			jr GetBlocking1
			
GetBlocking3
			pop hl
			pop bc
			
			rst 08h
			.byte Betn_Int_old
			ret

; ----

InTaskPending
			push hl
			ld l,(ix+InTask)
			ld h,(ix+InTask+1)
			call Test_HL
			pop hl
			jr z,InTaskPending1
			scf
			ret
InTaskPending1
			or a
			ret
			
; ---- FIFO loeschen ----
; IX  -> Zeiger auf Objekt

Clear	push af
		ld a,0
		rst 08h
		.byte Betn_Int_dis
		ld (ix+WritePos),a
		ld(ix+(WritePos+1)),a
		ld (ix+ReadPos),a
		ld(ix+(ReadPos+1)),a
		rst 08h
		.byte Betn_Int_old
		pop af
		ret
		
; ----- Task Chanceln ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Task

InTaskChancel
		push af
		ld a,(ix+InTask)
		cp l
		jr nz,InTaskChancel1
		ld a,(ix+InTask+1)
		cp h
		jr nz,InTaskChancel1
		xor a
		ld (ix+InTask),a
		ld (ix+InTask+1),a
InTaskChancel1
		pop af
		ret
