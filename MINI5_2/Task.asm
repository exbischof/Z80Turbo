; Task Object

.include "mini5_2.inc"
.include "helper.inc"

.assume ADL=0

xdef TaskObj

.define xyz
segment xyz

Class			equ 0
StackPointer	equ 2
ChancelCallbac  equ 4
ChancelEnv		equ 6
Priority		equ 8
DataEnd			equ 9

; --- Konstruktor ----
; BC -> Groesse des FIFOs
; HL <- Adresse des FIFO Onbjekts

TaskObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		.byte 2
		
		.word Free
		.word Resume
		
; ---- Konstruktor ----
; A   -> Prioritaet
; HL  -> Startadresse
; BC  -> Stckgroesse
; CFL <- =1 OK =0 Fehler

Start
		push bc
		push de
		push ix
		push hl
		push af
		
		ld hl,DataEnd
		add hl,bc
		ld bc,hl
		rst 08h
		.byte Betn_Mem_Alloc
		
		jr nc,Start1
		
		ld ix,hl
		
		add hl,bc
		ld de,hl
		dec de
		
		ld bc,ix
		ld a,0
		call Mem_fill

		pop af
		
		ld (ix+Priority),a
		ld hl,TaskObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		
		pop hl
		call Ex_hl_de
		
		dec hl
		ld (hl),de
		dec hl
		dec hl
		
		pop de
		ld (hl),de
		push de
		
		or a,a
		ld bc,2*9
		sbc hl,bc
		
		ld (ix+StackPointer),l
		ld (ix+(StackPointer+1)),h
		
		ld hl,ix

		pop ix
		pop de
		pop bc
		scf
		ret
		
Start1	pop af
		pop hl
		pop ix
		pop de
		pop bc
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
 		
; -----

Resume		ld l,(ix+StackPointer)
			ld h,(ix+(StackPointer+1))
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
			ret
			
