Pf_s		EQU C0h

Pf_nn		EQU 00100000b
Pf_ind		EQU 00010000b

Pf_clrscr	EQU  0
Pf_home		EQU  1
Pf_up		EQU  2
Pf_down		EQU  3
Pf_rigth	EQU  4
Pf_left		EQU  5
Pf_clrl		EQU  6
Pf_clrs  	EQU  7
Pf_upscroll	EQU  8
Pf_pos		EQU  9
Pf_ein		EQU 10 ; Cursor ein
Pf_aus		EQU 11 ; Cursor aus

Pf_bin		EQU 01000000b
Pf_dez		EQU 01000100b
Pf_hex		EQU 01001000b
Pf_byte		EQU 00000010b
Pf_fuell	EQU 00000001b
Pf_pf_s		EQU 01001100b
Pf_str		EQU 01001101b
Pf_taste	EQU 01001110b
Pf_wt		EQU 10001000b
Pf_dt		EQU 10000100b
Pf_hhmm		EQU 10000010b
Pf_ss		EQU 10000001b

PrintfObj_Free			.equ 0
PrintfObj_Pointprn		.equ 1
PrintfObj_MeldOut		.equ 2
PrintfObj_CharOut		.equ 3
PrintfObj_TermCmd		.equ 4

xref PrintfObj