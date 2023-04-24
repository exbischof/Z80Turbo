; abstarct Printf Object

.include "mini5_2.inc"
.include "PrintfObj.inc"

xdef PrintfObj

xref Ex_hl_de
xref Read_hl
xref Divi
xref Hex4bit
xref Cmp_hl_bc
xref Read_str

.define PrintfObjCode


MethodTab	equ 0
		
DataEnd		equ 2

segment PrintfObjCode

PrintfObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		.byte 3
		.word Free
		.word Pointprn_obj
		.word Meld_obj_out
; BC -> benoutigter Speicher der Subklasse
; HL <- Zeiger au objekt
; CFL <- =1 OK =0 Fehler

Start
		push de
		ld hl,DataEnd
		add hl,bc
		rst 08h
		.byte Betn_Mem_Alloc
		
		ld de,0
		ld (hl),de
		pop de
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
		
; ---- formatierte Ausgabe auf Standartausgabe ----
;
; HL   -> Argument
; (SP) -> String

Printf		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		call Pointprn_obj

		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		ret

; ---- formatierte Ausgabe auf ein Objekt ----
;
; IX -> Objekt
; DE -> Zeiger auf String
; HL -> Argument
; DE <- Zeiger auf Stringende + 1

Pointprn_obj	push af
		push bc

Pointprn_obj_1	ld a,(de)
		inc de

		or a
		jp z,Pointprn_obj_end

		cp Pf_s
		jr z,Pointprn_obj_2

		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_CharOut
		
		jr Pointprn_obj_1

Pointprn_obj_2  ; Auszugbenden Werte -> HL

		push hl

		ld a,(de)
		ld b,a
		inc de

		and Pf_nn
		jr z,Pointprn_obj_3

		ld h,d
		ld l,e
		call Read_hl
		inc de
		inc de

Pointprn_obj_3  ld a,b
		and Pf_ind
		call nz,Read_hl

		ld a,b
		and 10000000b
		jp nz,Pointprn_obj_12

		; Maske 0xxxxxxxb

		ld a,b
		and 01000000b
		jr nz,Pointprn_obj_4

		; Maske 00xxtttt Terminalsteuerung

		ld a,b
		and 00001111b

		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_TermCmd

		jp Pointprn_obj_16

Pointprn_obj_4	; Maske 01xxxxxxb

		ld a,b
		and 00001100b

		jr nz,Pointprn_obj_5

		; Maske 01xx00xxb Ausgabe bin„r

		push de
		ld d,16
		ld e,'0'
		ld c,2
		jr Pointprn_obj_7

Pointprn_obj_5  cp 00000100b
		jr nz,Pointprn_obj_6

		; Maske 01xx01xxb Ausgabe dezimal

		push de
		ld d,0
		ld c,10
		jr Pointprn_obj_7

Pointprn_obj_6  cp 00001000b
		jr nz,Pointprn_obj_10

		; Maske 01xx10xxb Ausgabe hexadezimal

		push de
		ld d,4
		ld e,'0'
		ld c,16

Pointprn_obj_7  ld a,b          ; Ausgabe als Byte ?
		and Pf_byte
		jr z,Pointprn_obj_8

		srl d           ; ja, dann Stellen halbieren
		ld h,0          ; und High-Byte EQU 0

Pointprn_obj_8  ld a,b
		and Pf_fuell
		jr z,Pointprn_obj_9

		ex (sp),hl	; Fllzeichen holen
		ld d,(hl)
		inc hl
		ld e,(hl)
		inc hl
		ex (sp),hl

Pointprn_obj_9  call Zahl_obout

		pop de

		jp Pointprn_obj_16

Pointprn_obj_10 ; Maske 00xx11xxb

		ld a,b
		and 00000011b

		jr nz,Pointprn_obj_11

		; Maske 01xx1100b ; Startflag ausgeben

		ld a,Pf_s
		rst 08h
		.byte Betn_Objekt_call ; Zeichen ausgeben
		.byte PrintfObj_CharOut

		jp Pointprn_obj_16

Pointprn_obj_11	cp 00000001b
		jp nz,Pointprn_obj_17

		; Maske 01xx1101b ; String ausgeben

		call Ex_hl_de
		ex (sp),hl
		call Pointprn_obj
		ex (sp),hl
		call Ex_hl_de

		jp Pointprn_obj_16

Pointprn_obj_17	cp 00000010b
		jp nz,Pointprn_obj_18

		; Maske 01xx1110b

; TODO
;		call Clr_inpuff ; warten auf Tastendruck
;		call Char_get

		jp Pointprn_obj_16

Pointprn_obj_18	jp Pointprn_obj_err

Pointprn_obj_12 ; Maske 10000000b

		ld a,b
		and 01000000b
		jp nz,Pointprn_obj_err

		; Maske 01xxddddb Wochentag Datum und Zeit ausgeben

		ld a,b
		and 00001000b
		jr z,Pointprn_obj_13

		push hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		inc hl
		ld a,(hl)
		ld hl,Tag_tab
		call Meld_obj_out
		pop hl

		ld a,b
		and 00000111b
		jr z,Pointprn_obj_13

		ld a,' ' ; Leerzeichen ausgeben
		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_CharOut

Pointprn_obj_13	ld a,b
		and 00000100b
		jr z,Pointprn_obj_14

		push hl
		inc hl
		inc hl
		inc hl

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_byte | Pf_fuell,2,'0',".",0

		inc hl

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_byte | Pf_fuell,2,'0',".",0

		inc hl

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_fuell,2,'0',0

		pop hl

		ld a,b
		and 00000011b
		jr z,Pointprn_obj_14

		ld a,' ' ; Leerzeichen ausgeben
		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_CharOut

Pointprn_obj_14	ld a,b
		and 00000010b
		jr z,Pointprn_obj_15

		inc hl
		inc hl

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_byte | Pf_fuell,2,'0',":",0

		dec hl

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_byte | Pf_fuell,2,'0',0

		dec hl

		ld a,b
		and 00000001b
		jr z,Pointprn_obj_15

		ld a,':' ; Doppelpunkt ausgeben
		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_CharOut

Pointprn_obj_15 ld a,b
		and 00000001b
		jr z,Pointprn_obj_16

		call Printf
		.byte Pf_s,Pf_ind | Pf_dez | Pf_byte | Pf_fuell,2,'0',0

Pointprn_obj_16 pop hl

		jp Pointprn_obj_1

Tag_tab         .byte "??",0
		.byte "Mo",0
		.byte "Di",0
		.byte "Mi",0
		.byte "Do",0
		.byte "Fr",0
		.byte "Sa",0
		.byte "So",0
		.byte 0

Pointprn_obj_err ld a,'?'
		rst 08h
		.byte Betn_Objekt_call ; Fragezeichen ausgeben
		 .byte PrintfObj_CharOut
		 pop hl

Pointprn_obj_end pop bc
		 pop af

		ret
; ---- Zahl auf Objekt ausgeben ----
;
; IX -> Objekt
; HL -> Zahl
; C  -> Basis des Zahlensystems
; D  -> Breite
; E  -> Fllzeichen

Zahl_obout      push af
		push bc
		push de
		push hl
		ld b,0
		call Zahl_obout_1
		pop hl
		pop de
		pop bc
		pop af

		ret

; ---- Unterprogramm zur Zahlenausgabe auf Objekt ----
;
; IX -> Objekt
; HL -> Zahl
; BC -> Basis
; D  -> Breite
; E  -> Fllzeichen
;
; Register werden ver„ndert

Zahl_obout_1    push de                        ; HL / B -> HL, Rest -> A
		call Divi
		ld a,l
		ld h,d
		ld l,e
		pop de

		push af

		ld a,d                          ; Zahl der Fllzeichen - 1
		or a
		jr z,Zahl_obout_3
		dec d

Zahl_obout_3    ld a,h
		or l
		jr nz,Zahl_obout_4

Zahl_obout_2    ld a,d                          ; Fllzeichen ausgeben
		or a
		jr z,Zahl_obout_5
		ld a,e
		rst 08h
		.byte Betn_Objekt_call		; Zeichen ausgben
         .byte PrintfObj_CharOut
		dec d
		jr Zahl_obout_2

Zahl_obout_4    call Zahl_obout_1

Zahl_obout_5    pop af

		call Hex4bit
		rst 08h
		.byte Betn_Objekt_call		; Zeichen ausgben
         .byte PrintfObj_CharOut

		ret

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
