; Heap Object

.include "mini5_2.inc"
.include "helper.inc"

.assume ADL=0

xdef HeapObj

.define xyz
segment xyz

Class			equ 0
ElementSize	equ 2
ElementMax		equ 3
ElementCount	equ 4
CompareFunktion equ 5
DataEnd			equ 7

; --- Konstruktor ----
; HL -> Vergleichsfunktion
; B -> Anazhl der Elemente
; C -> Größe eines Elements
; HL <- Adresse des FIFO Onbjekts

HeapObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 6
		.word Free
		.word Put
		.word Get
		.word Top
		.word Replace
		.word Remove
		
; ---- Konstruktor ----

Start	push af
		push de
		push bc
		
		ld de,hl
		
		ld h,0
		ld l,b
		ld b,0
		
		call Multi
		
		ld bc,DataEnd
		add hl,bc
		ld bc,hl
		
		push de
		rst 08h
		.byte Betn_Mem_Alloc
		pop de
		
		jr nc,Err
		
		pop bc
		
		push ix
		ld ix,hl
		push hl
		ld hl,HeapObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		ld (ix+CompareFunktion),e
		ld (ix+(CompareFunktion+1)),d
		pop hl
		ld (ix+ElementSize),c
		ld (ix+ElementMax),b
		ld a,0
		ld (ix+ElementCount),a
		pop ix
		
		pop de
		pop af
		scf
		ret
		
Err		pop de
		pop af
		or a,a
		ret
		
; ---- Objekt freigeben ----
; IX -> Zeiger auf Objekt

Free	push af
		push hl
			
		ld hl,ix
		rst 08h
		.byte Betn_Mem_free
		pop hl
		pop af
		ret

; ---- Eiement eingeben ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Daten
; CFL <- =1 Ok =0 Fehler

Put		push af
		push bc
		push de
		push hl
		call MakeSpace
		jr nc,Put1
		ld a,0
		push hl
		call GetAddress
		ld de,hl
		pop hl
		call CopyData
		call Reheap
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
Put1
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret

; ---- Eiement eingeben ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Daten
; CFL <- =1 Ok =0 Fehler

Get		push af
		push bc
		push de
		push hl
		
		push hl
		ld a,0
		call GetAddress
		pop de
		
		jr nc,Get2
		
		call CopyData

		ld a,(ix+ElementCount)
		dec a
		or a,a
		jr z,Get3

		ld de,hl
		call GetAddress
		call CopyData
		ld (ix+ElementCount),a
		call Reheap
		
Get1
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
		
Get2	pop hl
		pop de
		pop bc
		pop af
		or a
 		ret
Get3
		ld (ix+ElementCount),a
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret

; ---- Paltz schaffen ----
; IX -> Zeiger auf Objekt
; CFL <- =1 Ok =0 Fehler
MakeSpace
		push af
		push bc
		push de
		push hl
		ld a,(ix+ElementCount)
		ld b,(ix+ElementMax)
		cp a,b
		jr nc,MakeSpace3
		push af
		inc a
		ld (ix+ElementCount),a
		pop af
		call GetAddress
		ld de,hl
MakeSpace1
		or a,a
		jr z,MakeSpace2
		inc a
		srl a
		dec a
		call GetAddress
		push hl
		call CopyData
		pop de
		jr MakeSpace1
MakeSpace2
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
MakeSpace3
		pop hl
		pop de
		pop bc
		pop af
		or a,a
		ret
		
; ---- Get Address ----
; IX -> Zeiger auf Objekt
; A  -> Index
; CFL <- =1 Ok =0 Fehler
; HL <- Addresse

GetAddress
		push af
		push bc
		
		cp a,(ix+ElementCount)
		jr nc,GetAddress1
		
		ld b,0
		ld c,(ix+ElementSize)
		ld h,0
		ld l,a
		call Multi
		
		ld bc,ix
		add hl,bc
		
		ld bc,DataEnd
		adc hl,bc
		
		pop bc
		pop af
		scf
		ret
GetAddress1
		pop bc
		pop af
		or a,a
		ret
		
; ---- Daten kopieren ----
; IX -> Zeiger auf Objekt
; HL -> Quelladresse
; DE -> Zieladresse

CopyData
		push bc
		push de
		push hl
		ld b,0
		ld c,(ix+ElementSize)
		ldir
		pop hl
		pop de
		pop bc
		ret
		
GetLeftChild
		push bc
		sla a
		jr c,GetLeftChild1
		inc a
		or a,a
		jr z,GetLeftChild1
		ld b,(ix+ElementCount)
		cp a,b
		jr nc,GetLeftChild1
		scf
		pop bc
		ret
GetLeftChild1
		ld a,0
		pop bc
		or a,a
		ret
		
GetRightChild
		push bc
		sla a
		jr c,GetLeftChild1
		add a,2
		jr c,GetLeftChild1
		ld b,(ix+ElementCount)
		cp a,b
		jr nc,GetRightChild1
		pop bc
		scf
		ret
GetRightChild1
		ld a,0
		pop bc
		or a,a
		ret

Swap	push af
		push bc
		push de
		push hl
		
		ld a,d
		call GetAddress
		ld a,e
		ld de,hl
		call GetAddress
		ld b,(ix+ElementSize)
Swap1	ld a,(de)
		push af
		ld a,(hl)
		ld (de),a
		pop af
		ld (hl),a
		inc hl
		inc de
		djnz Swap1
		
		pop hl
		pop de
		pop bc
		pop af
		ret
		
; ---- Zwei Eintraege vergleichen ----
; IX -> Zeiger auf Objekt
; D -> index2
; E -> index2
; CFL <- =1 (D)<(E); =0 (D)>=(E)

Compare	push af
		push bc
		push de
		push hl
		ld a,e
		call GetAddress
		ld bc,hl
		ld a,d
		call GetAddress

		call Compare2
		jr nc,Compare1
		
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
Compare1
		pop hl
		pop de
		pop bc
		pop af
		or a,a
		ret

Compare2
		push hl
		ld l,(ix+CompareFunktion)
		ld h,(ix+(CompareFunktion+1))
		ex (sp),hl
		ret

; ---- oberstets Elemenz in den Heap einsinken lasse ----
; IX -> Zeiger auf Objekt

Reheap	push af
		push bc
		push de
		ld b,0
Reheap1	ld a,b
		call GetLeftChild		; linkes Kind holen
		jr nc,Reheap3			; wenn es kein linkes Kind gib, dann Ende
		ld d,a					; linkes Kind -> D
		
		ld a,b					; rechtes Kind -> E
		call GetRightChild
		ld e,a
		
		jr nc,Reheap2			
		call Compare
		jr c,Reheap2 			; Ist (rechtes Kind)>=(linkes Kind)
		ld d,e					; ja, rechtes Kind -> D
Reheap2	ld e,b					; Vater nach E
		call Compare			; ist (Vater)<=(kleinstes Kind)
		jr nc,Reheap3			; Ja, dann Ende
		call Swap
		ld b,d
		jr Reheap1
Reheap3 pop de
		pop bc
		pop af
		ret
		
; ---- obrestes Element holen ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Puffer
; CFL <- =1 Ok =0 Fehler

Top		push af
		push hl
		push de
		ld de,hl
		ld a,0
		call GetAddress
		jr nc,Top1
		call CopyData
		pop de
		pop hl
		pop af
		scf
		ret
Top1	pop de
		pop hl
		pop af
		or a,a
		ret
		
; ---- oberstes Eleemnt holen und neues Element einfuegen ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf Puffer
; CFL <- =1 Ok =0 Fehler (heap leer)

Replace	push af
		push bc
		push de
		push hl
		
		ld de,hl
		ld a,0
		call GetAddress
		jr nc,Replace2

		ld b,(ix+ElementSize)
Replace1
		ld a,(hl)
		push af
		ld a,(de)
		ld (hl),a
		pop af
		ld (de),a
		inc hl
		inc de
		djnz Replace1
		
		call Reheap
		
		pop hl
		pop de
		pop bc
		pop af
		scf
		ret
Replace2
		pop hl
		pop de
		pop bc
		pop af
		or a,a
		ret
		
; ---- Elemenz loeschen ----
; IX -> Zeiger auf Heap
; HL -> Inhalt

Remove	push af
		push bc
		push de
		push hl
		
		ld de,hl
		
		ld a,0
		call GetAddress
	
		ld b,(ix+ElementCount)
		ld c,0
Remove1
		ld a,b
		or a
		jr z,Remove6
		
		ld a,(hl)
		cp e
		jr nz,Remove2
		
		inc hl
		ld a,(hl)
		dec hl
		cp d
		jr z,Remove3
Remove2
		ld a,(ix+ElementSize)
		add l
		ld l,a
		ld a,0
		adc h
		ld h,a
		dec b
		inc c
		jr Remove1
Remove3
		ld a,c
Remove4	or a
		jr z,Remove5
		srl a
		ld de,hl
		call GetAddress
		call CopyData
		jr Remove4
Remove5
		ld a,0
		call GetAddress
		ld de,hl
		ld a,(ix+ElementCount)
		dec a
		call GetAddress
		ld (ix+ElementCount),a
		call CopyData
		call Reheap
Remove6
		pop hl
		pop de
		pop bc
		pop af
		ret
		
