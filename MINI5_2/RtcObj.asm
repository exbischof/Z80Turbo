; ---- RTC Objekt ----

.include "ez80f91.inc"
.include "helper.inc"
.include "mini5_2.inc"

Class			equ 0
DataEnd			equ 2

xdef RtcObj

RtcObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 2
		.word GetTime
		.word SetTime
		
Start
		push af
		push bc
		push de
		push ix
		
		ld a,00000000b
		out0 (RTC_CTRL),a

		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		
		jr nc,Err
		
		push hl
		ld ix,hl
		ld hl,RtcObj
		ld (ix+Class),l
		ld (ix+(Class+1)),h
		pop hl
		
		pop ix
		pop de
		pop bc
		pop af
		scf
		ret
Err
		pop ix
		pop de
		pop bc
		pop af
		or a
		ret
		
; ---- Zeit hohlen ----		
; HL -> Puffer

GetTime	push af
		push hl
		in0 a,(RTC_SEC)
		ld (hl),a
		inc hl
		in0 a,(RTC_MIN)
		ld (hl),a
		inc hl
		in0 a,(RTC_HRS)
		ld (hl),a
		inc hl
		in0 a,(RTC_DOM)
		ld (hl),a
		inc hl
		in0 a,(RTC_MON)
		ld (hl),a
		inc hl
		in0 a,(RTC_CEN)
		ld c,a
		ld b,0
		push hl
		ld hl,100
		call Multi
		in0 a,(RTC_YR)
		ld b,0
		ld c,a
		add hl,bc
		ld bc,hl
		pop hl
		ld (hl),c
		inc hl
		ld (hl),b
		inc hl
		in0 a,(RTC_DOW)
		dec a
		ld (hl),a
		pop hl
		pop af
		ret

; ---- Zeit setzen ----		
; HL -> Puffer

SetTime	push af
		push hl
		ld a,00000001b
		out0 (RTC_CTRL),a
		ld a,(HL)
		out0 (RTC_SEC),a
		inc hl
		ld a,(HL)
		out0 (RTC_MIN),a
		inc hl
		ld a,(HL)
		out0 (RTC_HRS),a
		inc hl
		ld a,(HL)
		out0 (RTC_DOM),a
		inc hl
		ld a,(HL)
		out0 (RTC_MON),a
		inc hl
		ld a,(hl)
		inc hl
		push hl
		ld h,(hl)
		ld l,a
		ld bc,100
		call Divi
		ld a,l
		out0 (RTC_YR),a
		ld a,e
		out0 (RTC_CEN),a
		pop hl
		inc hl
		ld a,(hl)
		inc a
		out0 (RTC_DOW),a
		ld a,00000000b
		out0 (RTC_CTRL),a
		pop hl
		pop af
		ret