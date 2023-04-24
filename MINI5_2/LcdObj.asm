; abstarct Printf Object

.include "helper.inc"
.include "PrintfObj.inc"
.include "mini5_2.inc"
.include "GpioPortObj.inc"

.assume ADL=0

xdef LcdObj

.define SerialObjSeg
segment SerialObjSeg

Esc		EQU 1bh
Cr              EQU 0dh   ; Wagenrcklauf
Lf              EQU 0ah   ; Linefeed
Ht              EQU 09h   ; horizontel Tab
Backspace       EQU 08h
Lcd_blk			EQU 6		; Gr”sse des LCD-Objekts
Lcd_Crsr_ein	EQU 00000010b     ; Cursor einschalten
Lcd_Crsr_blk    EQU 00000001b     ; Cursor blinken
Lcd_spalten     EQU 20
Lcd_zeilen      EQU 4
Lcd_cursormode  EQU 00000001h ; Cursor bliken

Class		equ 0
Base		equ 2
Buffer		equ 4
Zeile		equ 6
Spalte	    equ 7
DataEnd		equ 8+Lcd_spalten


; ---- Konstruktor ----
; BC -> Basisadresse
; CFL <- =1 Ok, =0 Fehler

LcdObj
		jr Start
		
		.word PrintfObj	; Superklasse
		.byte 5
		.word Free
		.word Pointprn_obj
		.word MeldOut
		.word Lcd_out
		.word Lcd_term		

Start
		push ix
		push af
		push de
		push bc

		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		jr nc,StartErr
 
		ld bc,LcdObj
		ld ix,hl
		ld (ix+Class),c
		ld (ix+(Class+1)),b

		pop bc
		
		ld (ix+Base),c
		ld (ix+(Base+1)),b
		
		call Lcd_init
		
		pop de
		pop af
		pop ix
		scf
		ret
		
StartErr	
		pop bc
		pop de
		pop af
		pop ix
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
			
Pointprn_obj	rst 08h
			.byte Betn_ObjektSuperJmp
			.byte PrintfObj_Pointprn
			
MeldOut		rst 08h
			.byte Betn_ObjektSuperJmp
			.byte PrintfObj_MeldOut
		
; ---- Zeichen ausgeben ----

Lcd_out  call Menu_branch
		.byte Cr
		.word Lcd_cr
		.byte Lf
		.word Lcd_lf
		.byte Backspace
		.word Lcd_backspace
		.byte Ht
		.word Lcd_tabulator
		.byte 0
		.word Lcd_out_1

Lcd_out_1
		push de
		push af

		call Lcd_get_cursor

		inc e
		
		ld a,e
		cp a,Lcd_spalten
		jr c,Lcd_out_2

		ld e,0
		inc d
		
		ld a,d
		cp a,Lcd_zeilen
		jr c,Lcd_out_2
		
		ld d,Lcd_zeilen-1
		call Lcd_scroll_up
Lcd_out_2
		pop af
		call Lcd_write
		call Lcd_set_cursor
		pop de
		ret
		
Lcd_cr	push de
 		call Lcd_get_cursor
		ld e,0
		call Lcd_set_cursor
		pop de
		ret
		
Lcd_lf  push af
		push de
 		call Lcd_get_cursor
		inc d
		ld a,d
		cp a,Lcd_zeilen
		jr c,Lcd_lf1
		ld d,Lcd_zeilen-1
		call Lcd_scroll_up
Lcd_lf1
		call Lcd_set_cursor
		pop de
		pop af
		ret
		
Lcd_backspace  push af
		push de
 		call Lcd_get_cursor
		ld a,e
		or a
		jr z,Lcd_backspace_1

		dec d
		call Lcd_set_cursor
		ld a,' '
		call Lcd_write
		call Lcd_set_cursor
Lcd_backspace_1
		pop de
		pop af
		ret
		
Lcd_tabulator   
		call Lcd_term_rigth
		ret

; ---- LCD Terminalkomando ----
;
; A  <-> Code
; IX <-> LCD Objekt

Lcd_term        
		push hl
		ld hl,Lcd_term_tab
		push af
		call Tab_get
		jr nc,Lcd_term_err
		pop af
		ex (sp),hl
		ret
Lcd_term_err
		pop af
		pop hl
		ret
		
Lcd_term_tab    .byte 12
		.word Lcd_term_cls
		.word Lcd_term_home
		.word Lcd_term_up
		.word Lcd_term_down
		.word Lcd_term_rigth
		.word Lcd_term_left
		.word Lcd_term_clrl
		.word Lcd_term_clrs
		.word Lcd_term_upsc
		.word Lcd_term_pos
		.word Lcd_term_ein
		.word Lcd_term_aus

Lcd_term_cls    
		call Lcd_cls
		call Lcd_term_home
		ret

Lcd_term_home	
		push de
		ld de,0
		call Lcd_set_cursor
		pop de
		ret

Lcd_term_up     
		push af
		push de
		call Lcd_get_cursor
		ld a,d
		or a
		jr z,Lcd_term_up_1
		dec d
		call Lcd_set_cursor
Lcd_term_up_1	
		pop de
		pop af
		ret

Lcd_term_down	
		push af
		push de
		call Lcd_get_cursor
		ld a,d
		cp Lcd_zeilen-1
		jr nc,Lcd_term_down_1
		inc d
		call Lcd_set_cursor
Lcd_term_down_1	
		POP DE
		pop af
		ret

Lcd_term_rigth
		push af
		push de
		call Lcd_get_cursor
		ld a,e
		cp Lcd_zeilen-1
		jr nc,Lcd_term_rigth_1
		inc e
		call Lcd_set_cursor
Lcd_term_rigth_1 
		pop de
		pop af
		ret

Lcd_term_left	
		push af
		push de
		call Lcd_get_cursor
		ld a,e
		or a
		jr z,Lcd_term_left_1
		dec e
		call Lcd_set_cursor
Lcd_term_left_1	
		pop de
		pop af
		ret

Lcd_term_clrl
		push af
		push de
		call Lcd_get_cursor
		push de
Lcd_term_clrl_1	
		ld a,e
		cp Lcd_spalten
		jr nc,Lcd_term_clrl_2
		inc e
		ld a,' '
		call Lcd_wait
		call Datareg_out
		jr Lcd_term_clrl_1
Lcd_term_clrl_2	
		pop de
		call Lcd_set_cursor
		pop de
		pop af
		ret

Lcd_term_clrs   push af
		push de
		call Lcd_term_clrl
		call Lcd_get_cursor
Lcd_term_clrs_1	inc d
		ld a,e
		cp Lcd_zeilen-1
		jr nc,Lcd_term_clrs_2
		call Lcd_erase
		inc e
		jr Lcd_term_clrs_1

Lcd_term_clrs_2	call Lcd_set_cursor
		pop de
		pop af
		ret

Lcd_term_upsc   
		push af
		push de
		call Lcd_get_cursor
		ld a,d
		or a
		jr nz,Lcd_term_upsc_1
		call Lcd_scroll_dn
		inc d
Lcd_term_upsc_1 
		call Lcd_set_cursor
		pop de
		pop af

		ret

Lcd_term_pos
		push de
		ld d,h
		ld e,l
		call Lcd_set_cursor
		pop de
		ret

Lcd_term_ein	
		push af
		ld a,Lcd_cursormode
		call Lcd_mode
		pop af
		ret

Lcd_term_aus	
		push af
		xor a
		call Lcd_mode
		pop af
		ret

; ---- Lcd Hardware ialisieren ----
; IX  -> Zeiger auf Objekt
; CFL <-  EQU1 ok, EQU0 Fehler

Lcd_init        push hl
		push af
		push bc
		
		push ix
		
		rst 08
		.byte Betn_Get_PortB
		
		ld a,GpioModeOutput
		ld b,LCD_RESET
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMode
		
		ld b,LCD_RESET
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ClrMask
		
		ld hl,20*20
		call Wait

		ld b,LCD_RESET
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMask
		
		ld hl,20*20
		call Wait

		pop ix
		
		ld a,34h ; 8 Bit Datenl„nge
		call Cmdreg_out
		
		ld hl,5 ; 5ms auf LCD-Diaplay warten
		call Wait

		ld a,34h ; 8 Bit Datenl„nge
		call Cmdreg_out

		ld hl,5 ; 1ms auf LCD-Diaplay warten
		call Wait

		ld a,34h ; 8 Bit Datenl„nge
		call Cmdreg_out

		call Lcd_wait
		ld a,09h 
		call Cmdreg_out

		call Lcd_wait
		ld a,30h 
		call Cmdreg_out

		call Lcd_wait
		ld a,0fh 
		call Cmdreg_out

		call Lcd_wait
		ld a,01h 
		call Cmdreg_out

		call Lcd_wait
		ld a,06h 
		call Cmdreg_out

		pop af
		call Lcd_test
		push af

		call Lcd_wait
		ld a,01h 
		call Cmdreg_out

		ld a,0
		ld (ix+Zeile),a
		ld (ix+Spalte),a
		
		pop bc
		pop af
		pop hl

		ret

; ---- Lcd test ----
;
; CFL <-  EQU1 ok, EQU0 Fehler

Lcd_test	push af
		
		call Lcd_wait ; DD-Addresse auf Anfang
		ld a,10000000b
		call Cmdreg_out

		ld a,55h     ; Testmuster schreiben
		call Lcd_write
		ld a,aah
		call Lcd_write

		call Lcd_wait ; DD-Addresse auf Anfang
		ld a,10000000b
		call Cmdreg_out

		call Lcd_read ; Dummy read
		call Lcd_read ; Testmuster lesen
		cp 55h
		jr nz,Lcd_test_1
		call Lcd_read
		cp aah
		jr nz,Lcd_test_1

		pop af
		scf
		ret

Lcd_test_1	
		pop af
		or a
		ret

; ---- Lcd abschalten ----
;
; C  -> Basisadresse

Lcd_exit        push af
		push bc
		call Lcd_wait
		ld a,08h	; Anzeige aus
		call Cmdreg_out
		pop af

		ret

; ---- Wait ----
;
; HL -> Zei in ms ( HLEQU0 EQU> 65,536 s )

Wait            push af
		push bc
		push hl

Wait_0          ld b,232        ;      7 Zyklen

Wait_1          nop             ;      4 Zyklen
		nop             ;      4 Zyklen
		djnz Wait_1     ;  B !EQU 0 : 13 Zyklen
				;  B EQUEQU 0 : 10 Zyklen
				; innere Schleife gesamt:
				; 21*232+10 EQU 4882 Zyklen

		dec hl          ;      6 Zyklen
		ld a,h          ;      4 Zyklen
		or l            ;      4 Zyklen
		jr nz,Wait_0    ; HL !EQU 0 : 12 Zyklen
				; 1 mal „užere Schleife:
				;   4915 Zyklen EQU 0.99996 ms

		pop hl
		pop bc
		pop af

		ret
		
; ---- Set Cursormode ----
; IX -> zeiger auf Objekt
; A -> Bit 0 EQU bliken, Bit 1 EQU Strich

Lcd_mode	push af
		and 00000011b
		or  00001100b
		call Lcd_wait
		call Cmdreg_out
		pop bc
		ret

; ---- Lcd l”schen ----
;
; C  -> Basisadresse

Lcd_cls		push af
		push hl
		call Lcd_wait
		ld a,01h
		call Cmdreg_out
		push bc
		ld hl,5		; 5ms warten bis Anzeige fertig
		call Wait
		pop bc
		pop hl
		pop af
		ret

; ---- Zeichen schreiben ----
;
; A <-> Zeichen
; C  -> Basisadresse

Lcd_write
		call Lcd_wait
		call Datareg_out
		ret

; ---- Zeichen lesen ----
;
; A <-> Zeichen
; C  -> Basisadresse

Lcd_read
		call Lcd_wait
		call Datareg_in
		ret

; ---- LCD DD-Ramadresse setzen ----
;
; Die linke obere Ecke hat die Koordinaten (0,0)
;
; D -> Zeile
; E -> Spalte

Lcd_set_cursor
		push af
		ld a,d
		sla a
		sla a
		sla a
		sla a
		sla a
		add e
		
		and 01111111b		; Adresse setzen
		or  10000000b
		call Lcd_wait
		call Cmdreg_out

		ld (ix+Zeile),d
		ld (ix+Spalte),e

		pop af

		ret

; ---- Cursorposition hohlen ----
;
; Die linke obere Ecke hat die Koordinaten (0,0)
;
; D <- Zeile
; E <- Spalte

Lcd_get_cursor
		ld d,(ix+Zeile)
		ld e,(ix+Spalte)
		ret
		
; ---- Cursorposition hohlen ----
;
; Die linke obere Ecke hat die Koordinaten (0,0)
;
; D <- Zeile
; E <- Spalte

Lcd_get_cursor_freom_device
		push af
		call Lcd_wait
		call Cmdreg_in
		and a,01111111b
		ld d,a
		ld e,a
		srl d
		srl d
		srl d
		srl d
		srl d
		ld a,e
		and a,00011111b
		ld e,a
		pop af
		ret
		
; ---- LCD-Zeile l”schen ----
; IX -> Zeiger auf Objekt
; D -> Zeile ( EQU0 fr erste Zeile )

Lcd_erase       push af
		push de

		ld e,0
		call Lcd_set_cursor

		ld a,' '
		ld b,Lcd_spalten

Lcd_erase_1	call Lcd_write
		djnz Lcd_erase_1

		pop de
		pop af

		ret

; ---- LCD Zeile kopieren
;
; IX -> Zeiger auf Objekt
; H  -> Quellzeile
; L  -> Zielzeile

Lcd_copy    
		push af
		push bc
		push de

		push hl
		ld hl,ix
		ld bc,Buffer
		add hl,bc
		ld bc,hl
		pop hl
			
		ld e,0
		ld d,h
		call Lcd_set_cursor
		ld b,Lcd_spalten
		call Datareg_in  ; Dummy read
Lcd_copy_1
		call Lcd_read	; Zeichen lesen
		ld (bc),a
		inc bc
		djnz Lcd_copy_1
		
		push hl
		ld hl,ix
		ld bc,Buffer
		add hl,bc
		ld bc,hl
		pop hl
			
		ld e,0
		ld d,l
		call Lcd_set_cursor
		ld b,Lcd_spalten
		
Lcd_copy_2
		ld a,(bc)
		call Lcd_write   ; Zeichen schreiben
		inc bc
		djnz Lcd_copy_2

		pop de
		pop bc
		pop af

		ret

; ---- Anzeige nach oben scrollen ----
;
; IX -> Zeiger auf Objekt

Lcd_scroll_up   push af
		push bc
		push de
		push hl

		ld b,Lcd_zeilen-1
		ld h,1
		ld l,0

Lcd_scroll_up_1	call Lcd_copy
		inc h
		inc l
		djnz Lcd_scroll_up_1

		ld d,Lcd_zeilen-1
		ld e,0
		call Lcd_erase

		pop hl
		pop de
		pop bc
		pop af

		ret

; ---- Anzeige nach unten scrollen ----
;
; IX -> Zeiger auf Objekt

Lcd_scroll_dn   push af
		push bc
		push de
		push hl

		ld b,Lcd_zeilen-1
		ld h,Lcd_zeilen-2
		ld l,Lcd_zeilen-1

Lcd_scroll_dn_1	call Lcd_copy
		dec h
		dec l
		djnz Lcd_scroll_dn_1

		ld d,0
		ld e,0
		call Lcd_erase

		pop hl
		pop de
		pop bc
		pop af

		ret

; ---- Warten bis LCD fertig ----
;
; IX -> Zeiger auf Objekt

Lcd_wait	
		push af
		push bc
		ld b,0

		; 256 * 39 Zyklen EQU max. 2ms warten

Lcd_wait_1 
		push bc
		call Cmdreg_in
		pop bc
		
		bit 7,a                 ;  8 Zyklen
		jr z,Lcd_wait_2        ;  7 Zyklen
		djnz Lcd_wait_1		; 12 Zyklen

Lcd_wait_2
		pop bc
		pop af

		ret

; ---- Komandoregister schreiben ----
; IX -> Zeiger auf Onjekt
; A -> Wert

Cmdreg_out
		push bc
		push de
		ld c,(ix+Base)
		ld b,(ix+(Base+1))
		ld d,0
		call IoOut
		pop de
		pop bc
		ret
		
; ---- Komandoregister schreiben ----
; IX -> Zeiger auf Onjekt
; A -> Wert

Datareg_out
		push bc
		push de
		ld c,(ix+Base)
		ld b,(ix+(Base+1))
		ld d,1
		call IoOut
		pop de
		pop bc
		ret
		
; ---- Komandoregister lesen ----
; IX -> Zeiger auf Onjekt
; A  <- Wert

Cmdreg_in
		push bc
		push de
		ld c,(ix+Base)
		ld b,(ix+(Base+1))
		ld d,0
		call IoIn
		pop de
		pop bc
		ret

; ---- datenegister lesen ----
; IX -> Zeiger auf Onjekt
; A  <- Wert

Datareg_in
		push bc
		push de
		ld c,(ix+Base)
		ld b,(ix+(Base+1))
		ld d,1
		call IoIn
		pop de
		pop bc
		ret;
