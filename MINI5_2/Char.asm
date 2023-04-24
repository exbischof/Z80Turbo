.define CharSeg
segment CharSeg

xdef Hex2bin
xdef Hex4bit
xdef Space_test
xdef Print_test
xdef Upper
xdef Char_cmp
xdef Is_literal
xdef Is_num
xdef Is_alpha

Esc				EQU 1bh
Cr              EQU 0dh   ; Wagenrcklauf
Lf              EQU 0ah   ; Linefeed
Ht              EQU 09h   ; horizontel Tab
Vt              EQU 0bh   ; vertical Tab
Ff              EQU 0ch   ; Formfeed
Backspace       EQU 7fh
Esc             EQU 1bh
Ctrl_u          EQU 15h
Ctrl_z          EQU 1ah
Strich          EQU 27h

Min_char        EQU 20h
Max_char        EQU 7eh

; ---- untere vier Bits nach hex ----

Hex4bit         and 00001111b
		cp 10
		jr c,Hex4bit_1
		add a,7    ; ASCI("A") - 10 - ASCI("0")
Hex4bit_1       add a,48   ; ASCI("0")
		ret

; ---- ASCI Hex Zeichen nach bin„r wandeln ----
;
; A   -> ASCI Zeichen
; A   <- bin„rer Wert, bei fehler Zeichen
; CFL <- 1: OK, 0 kein Hex-Zeichen

Hex2bin         push af
		call Upper

		sub 30h   ; A - "0"
		jr c,Hex2bin_2

		cp 10
		jr c,Hex2bin_1    ; OK ( < 10 )

		cp 11h    ; A < "A" - "0"
		jr c,Hex2bin_2    ; ja, dann Fehler
		sub 7     ; A EQU A - ( "A" - "0" ) + 10

		cp 16     ; <16
		jr nc,Hex2bin_2   ; nein, dann Fehler

Hex2bin_1       inc sp      ; AF vom Stack l”schen
		inc sp
		ret

Hex2bin_2       pop af      ; Fehler
		or a      ; 0 -> CFL
		ret

; ---- Test auf Leerzeichen ----
;
;   A -> Zeichen
; CFL <- =1 wenn A=' ',Ff,Cr,Lf,Tab,Vt sonst =0


Space_test
		cp a,' '
		jr z,Space_test_1
		cp a,Ff
		jr z,Space_test_1
		cp a,Cr
		jr z,Space_test_1
		cp a,Lf
		jr z,Space_test_1
		cp a,Vt
		jr z,Space_test_1
		or a,a
		ret

Space_test_1
		scf
		ret

; ---- Test auf druckbares Zeichen ----
;
;   A -> Zeichen
; CFL <- EQU1 Zeichen druckbar, EQU0 nicht druckbar
; kein Register wir ver„ndert

Print_test      push af
		cp Min_char
		jr c,Print_test_1
		cp Max_char+1
		jr nc,Print_test_1
		pop af
		scf
		ret

Print_test_1    pop af
		or a    ; CFLEQU0
		ret


; ---- nach Grossbuchstabe wandeln ----
;
;  A -> Zeichen
;  A <- umbewandeltes Zeichen

Upper           cp 61h    ; < ASC("a") ( EQU 60h )
		ret c
		cp 7bh    ; > ASC("z") ( EQU 7ah )
		ret nc
		sub 20h
		ret

; ---- Zeichen vergleichen ohne Grož- und Kleinschreibung ----
;
;   A -> 1. Zeichen
;   B -> 2. Zeichen
; CFL <- EQU1 Zeichen gleich, EQU0 Zeichen ungleich
; kein Register wird ver„ndert

Char_cmp       push bc
		ld c,a         ; Oirginal -> C
		ld a,b         ; B -> grož
		call Upper
		ld b,a
		ld a,c         ; Original -> grož
		call Upper
		cp b         ; Vergleich
		ld a,c         ; Original -> A
		pop bc
		jr z,Char_cmp_1
		or a         ; CFL EQU 0
		ret
Char_cmp_1     scf
		ret


; ---- Test ob Zeichen Buchstabe ist ----

Is_literal      push af
		call Upper
		cp 'A'
		jr c,Is_literal_1
		cp 'Z'+1
		jr nc,Is_literal_1

		pop af
		scf
		ret

Is_literal_1    pop af
		or a
		ret

; ---- Test ob Zeichen eine Ziffer ist ----

Is_num          cp '9'+1
		ret nc
		cp '0'
		ccf
		ret

; ---- Test ob das Zeichen zum Zahl oder Ziffer ist  ----
;

Is_alpha        call Is_num
		ret c
		call Is_literal
		ret
