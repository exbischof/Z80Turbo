.define xyzq
segment xyzq


xdef Ex_hl_de
xdef Read_hl
xdef Divi
xdef Cmp_hl_bc
xdef Read_str
xdef Test_HL
xdef Test_BC
xdef Add_HL_A
xdef Tab_get
xdef Multi
xdef IoOut
xdef IoIn
xdef Menu_branch
xdef Reg_clr
xdef Invert_c
xdef Jmp_hl
xdef Read_de
xdef Write_bc
xdef Read_bc
xdef Write_de
xdef Ex_hl_bc
xdef Write_de_bc
xdef Ber_len
xdef Cmp_hl_de
xdef Bcd2bin
xdef Chksum_test
xdef Mem_fill
xdef Mem_move
xdef Read_bc_bc
xdef ByteGet
xdef StrLen

; ---- Vertausch HL und DE ----

Ex_hl_de        push af
		ld a,d
		ld d,h
		ld h,a
		ld a,e
		ld e,l
		ld l,a
		pop af
		ret

; ----
; BC <- (BC)

Read_bc_bc
		push hl
		ld hl,bc
		call Read_bc
		pop hl
		ret
		
; ---- Wort aus speicher lesen ----
;
; HL <-  (HL)

Read_hl         push af
		ld a,(hl)
		inc hl
		ld h,(hl)
		ld l,a
		pop af
		ret
; ---- Division mit Rest ---
;
; HL   -> Z„hler
; BC  <-> Nenner
; DE  <-  ganzzahligler Anteil des Quotienten
; HL  <-  Rest
; CFL <- EQU1 ok, EQU0 Division durch Null

Divi            push af

		ld a,b          ; Test auf division durch Null
		or c
		jr z,Divi_fehler

		xor a
		ld d,a
		ld e,a

Divi_1          call Cmp_hl_bc
		jr z,Divi_2
		jr c,Divi_2

		bit 7,b
		jr nz,Divi_2

		sla c
		rl  b
		inc a
		jr Divi_1

Divi_2          set 0,e
		or a
		sbc hl,bc
		jr nc,Divi_3
		add hl,bc
		res 0,e

Divi_3          or a
		scf
		jr z,Divi_ok

		sla e
		rl d
		srl b
		rr c
		dec a

		jr Divi_2

Divi_ok         pop af
		scf
		ret

Divi_fehler     pop af
		or a
		ret

; ---- Vergleiche HL und BC ----
;
; HL < BC: CFL=1, ZFLEQU0
; HL = BC: CFL=0, ZFL=1
; HL > BC: CFL=0, ZFL=0

Cmp_hl_bc       push hl
		or a
		sbc hl,bc
		pop hl
		ret

; ---- String ueberlesen ----
; (HL)  -> String
;  HL  <-  erstes Zeihen hinter dem 0-Byte

Read_str        push af
Read_str_1      ld a,(hl)
		inc hl
		or a
		jr nz,Read_str_1
		pop af
		ret

; ---- HL Register testen ----
; HL -> Eingabe
; Z  -> =1 HL==0, Z=0 HL!=0

Test_HL	push bc
		ld bc,0
		or a,a
		sbc hl,bc
		pop bc 
		ret

; ---- HL Register testen ----
; HL -> Eingabe
; Z  -> =1 HL==0, Z=0 HL!=0

Test_BC	push bc
		push hl
		ld hl,bc
		ld bc,0
		or a,a
		sbc hl,bc
		pop hl
		pop bc 
		ret

; ---- Akku zum HL Register addieren ----
; HL ->
; A  ->
; HL <- HL+A

Add_HL_A	push af
			add a,l
			ld l,a
			ld a,0
			adc a,h
			ld h,a
			pop af
			ret 
; ---- Eintag aus Tabelle hohlen ----
; HL  -> Zeiger auf Tabelle
; A   -> Index
; HL  <- Tabelleneintrag (=0 bei fehler)
; CFL <- =1 Ok =0 Fehler

Tab_get		push af
			push bc
			ld b,(hl)
			cp a,b
			jr nc,TabGet1
			ld c,a
			ld b,0
			sla c
			rl b
			inc hl
			add hl,bc
			call Read_hl
			pop bc
			pop af
			scf
			ret
TabGet1		ld hl,0
			pop bc
			pop af
			or a,a
			ret
			
; ---- Byte aus Tabelle hohlen ----
; HL -> Zeiger auf Tabelle
; B  -> Index
; A <- (HL+B)

ByteGet		push hl
			ld a,l
			add b
			ld l,a
			ld a,0
			adc h
			ld h,a
			ld a,(hl)
			pop hl
			ret
			
; ---- Augabe an IO Adresse ----
; BC -> Basisadresse
; D  -> Ooffset
; A -> Ausgabewert

IoOut		push bc
			push af
			ld a,c
			add	a,d
			ld c,a
			ld a,b
			adc a,0
			ld b,a
			pop af
			out (bc),a
			pop bc
			ret
			
; ---- Eingabe IO Adresse ----
; BC -> Basisadresse
; D  -> Ooffset
; A -> Ausgabewert

IoIn		push bc
			push af
			ld a,c
			add	a,d
			ld c,a
			ld a,b
			adc a,0
			ld b,a
			in a,(bc)
			ld b,a
			pop af
			ld a,b
			pop bc
			ret
			
; ---- 16 Bit Multiplikation ----
;
; HL   -> Zahl 1
; BC  <-> Zahl 2
; HL  <-  Ergebnis
; CFL <-  EQU1 OK, EQU0 Ueberlauf

Multi           push af
		push bc
		push de

		ld d,h     ; HL -> DE
		ld e,l
		ld hl,0

Multi_1         srl b     ; BC / 2
		rr c
		jr nc,Multi_2
		add hl,de
		jr c,Multi_3    ; Fehler ?

Multi_2         ld a,b   ; BC EQU 0 -> Ende
		or c
		jr z,Multi_4

		sla e
		rl d
		jr nc,Multi_1

Multi_3         pop de    ; Fehler
		pop bc
		pop af
		or a
		ret

Multi_4         pop de    ; Ergebnis OK
		pop bc
		pop af
		scf
		ret
			
; ---- Tabellenverzweigung ----
; (SP) -> Tabelle
; Aufbau der Tabelle:
;  Zeichen, Adresse, ... , 0, Default

Menu_branch     ex (sp),hl
		push bc
		ld c,a

Menu_branch_1   ld a,(hl)
		inc hl
		or a
		jr z,Menu_branch_2
		cp c
		jr z,Menu_branch_2
		inc hl
		inc hl
		jr Menu_branch_1

Menu_branch_2   call Read_hl
		ld a,c
		pop bc
		ex (sp),hl
		ret
; ---- alle Prozessorregister loeschen ----

Reg_clr         xor a
		ld b,a
		ld c,a
		ld d,a
		ld e,a
		ld h,a
		ld l,a
		push hl
		pop af

		ex af,af'
		exx
		xor a
		ld b,a
		ld c,a
		ld d,a
		ld e,a
		ld h,a
		ld l,a
		push hl
		pop af

		ld ix,0
		ld iy,0

		ret

; ---- Carry invertieren ----

Invert_c        jr c,Invert_c_1
		scf
		ret
Invert_c_1      or a
		ret

; ---- Spung auf (HL) ----

Jmp_hl	jp (hl)

; ---- Vertausch HL und BC ----

Ex_hl_bc        push af
		ld a,b
		ld b,h
		ld h,a
		ld a,c
		ld c,l
		ld l,a
		pop af
		ret

; ---- Vertausch BC und DE ----

Ex_bc_de        push af
		ld a,b
		ld b,d
		ld d,a
		ld a,c
		ld c,e
		ld e,a
		pop af
		ret

; ---- (HL) nach DE ----
;
; DE <-  (HL)

Read_de         ld e,(hl)
		inc hl
		ld d,(hl)
		dec hl
		ret

; ---- DE nach (HL) ----
;
; BC <-  (HL)

Write_de        ld (hl),e
		inc hl
		ld (hl),d
		dec hl
		ret

; ---- (HL) nach BC ----

Read_bc         ld c,(hl)
		inc hl
		ld b,(hl)
		dec hl
		ret

; ---- BC nach (HL) ----
;
; BC ->  (HL)

Write_bc        ld (hl),c
		inc hl
		ld (hl),b
		dec hl
		ret

; ---- (DE) nach BC ----
;
; BC <-  (de)

Read_de_bc      push af
		ld a,(de)
		ld c,a
		inc de
		ld a,(de)
		ld b,a
		dec de
		pop af
		ret

; ---- BC nach (DE) ----
;
; BC ->  (DE)

Write_de_bc     push af
		ld a,c
		ld (de),a
		inc de
		ld a,b
		ld (de),a
		dec de
		pop af
		ret
		
		; ---- Bereichsumrechnug ----
;
; HL  <- BC
; BC  <- DE - BC + 1
; CFL <- EQU0 leerer Bereich, sonst 1

Ber_len         ld h,d
		ld l,e
		or a
		sbc hl,bc
		inc hl
		call Ex_hl_bc
		call Invert_c
		ret

; ---- Vergleiche HL und DE ----
;
; HL < DE: CFLEQU1, ZFLEQU0
; HL EQU DE: CFLEQU0, ZFLEQU1
; HL > DE: CFLEQU0, ZFLEQU0

Cmp_hl_de       push hl
		or a
		sbc hl,de
		pop hl
		ret

; ---- BCD nach binaer wandeln ----
;
; A  -> BCD Zahl
; A <-  bin„re Zahl

Bcd2bin         push bc
		push de
		push hl

		ld l,a
		srl l
		srl l
		srl l
		srl l
		ld h,0
		ld bc,10
		call Multi

		and 1111b
		add a,l

		or a

		pop hl
		pop de
		pop bc

		ret

; ---- Speicher fllen ----
;
; A  -> Fllbyte
; BC -> Bereichsanfang
; DE -> Bereichsende

Mem_fill        push af
		push bc
		push de
		push hl

		call Ber_len
		jr nc,Mem_fill_2

		ld e,a

Mem_fill_1      ld (hl),e
		inc hl
		dec bc
		ld a,b
		or c
		jr nz,Mem_fill_1

Mem_fill_2      pop hl
		pop de
		pop bc
		pop af

		ret

; ---- Speicher verschieben, auch šberlappungen ----
;
; BC -> Anfang Quelle
; DE -> Ende Quelle
; HL -> Anfang Ziel

Mem_move        push af
		push bc
		push de
		push hl

		push hl
		or a
		sbc hl,bc

		jr nc,Mem_move_1

		; verschieben nach unten

		ld h,d    ; Ende Quelle -> HL
		ld l,e

		pop de    ; Anfang Ziel -> DE

		or a    ; Byteyazhl -> HL
		sbc hl,bc
		inc hl

		ld a,b    ; BC <-> HL
		ld b,h    ; Bytezahl -> BC
		ld h,a    ; Anfang Quelle -> HL
		ld a,c
		ld c,l
		ld l,a

		ldir    ; verschieben

		jr Mem_move_3

Mem_move_1      ; verschieben nach oben

		add hl,de ; Ende Ziel -> HL
		jr c,Mem_move_2 ; Bereichsueberschreitung

		pop bc    ; Anfang Ziel -> BC
		push hl   ; Ende Ziel -> (SP)

		or a    ; Bytes -> BC
		sbc hl,bc
		inc hl
		ld b,h
		ld c,l

		ld h,d    ; Ende Quelle -> HL
		ld l,e
		pop de    ; Ende Ziel -> DE

		lddr    ; verschiben

		jr Mem_move_3

Mem_move_2      ; verschieben bei Bereichsueberschreitung

		ld a,l    ; Ende Quelle -> HL
		cpl
		ld l,a
		ld a,0
		sbc a,h
		ld h,a
		add hl,de

		pop bc    ; Anfang Ziel -> BC
		ld a,c    ; Bytes EQU - Anfang Ziel -> BC
		neg
		ld c,a
		ld a,0
		sbc a,b
		ld b,a

		ld de,ffffh ; Ende Ziel -> DE

		lddr    ; verschieben

Mem_move_3      pop hl     ; Register zurueckhohlen
		pop de
		pop bc
		pop af

		ret

;---- Checksummentest ----
;
; A    -> Anfangswert fr Summe
; BC   -> Anfang des Bereichs
; DE   -> Ende des Bereichs ( DE EQU> BC )
; A   <-  Endwert fr Summe
; CFL <- EQU1 ok, EQU0 Fehler ( wenn Summe !EQU 0 )
;
; zerst”rt nur AF, BC, DE, HL
;

Chksum_test     call Ber_len
		call Invert_c
		ret c   ; Bereich leer

Chksum_test_1   add a,(hl)
		cpi     ; inc hl, dec bc
		jp pe,Chksum_test_1

Chksum_test_2   or a
		ret nz
		scf
		ret

; ---- Laenge eines String ermitteln
; HL -> Zeiger auf String
; HL <- Laenge ohne 0

StrLen	push af
		push de
		ld de,hl
		ld hl,0
StrLen1
		ld a,(de)
		inc de
		inc hl
		or a
		jr nz,StrLen1
		dec hl
		pop de
		pop af
		ret
		