.include "mini5_2.inc"
.include "PrintfObj.inc"
.include "EncoderObj.inc"
.include "RtcObj.inc"
.include "GpioPortObj.inc"
.include "Char.inc"
.include "Dcf77Obj.inc"
.include "config.inc"
.include "MqttObj.inc"

xdef UserIf

.define DataSeg
segment DataSeg

Date			.block DATETIME_SIZE

.define UserIfSeg
segment UserIfSeg

; ---- Clock Task ----

UserIf
		call GetBackButton
		jr nc,UserIf
MainMenu
		rst 08h
		.byte Betn_Get_lcdout
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Pf_s,Pf_clrscr
		.byte "Hauptmenu",Cr,Lf,0
		
		ld hl,MainMenuTab
UserIf1
		call Menu
		jr nc,MainMenu

		ld hl,de
		jp (hl)

; ---- Clock ----

Clock		
		rst 08h
		.byte Betn_GetRtc
		
		ld hl,Date
		rst 08h
		.byte Betn_Objekt_call
		.byte RtcObj_GetTime
		
		rst 08h
		.byte Betn_Get_lcdout
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Pf_s,Pf_home
		.byte "RTC: "
		.byte Pf_s,Pf_nn|Pf_dt|Pf_wt
		.word Date
		.byte Cr,Lf,"     "
		.byte Pf_s,Pf_nn|Pf_hhmm|Pf_ss
		.word Date
		.byte Cr,Lf,0

		rst 08h
		.byte Betn_Get_dcf
		
		ld hl,Date
		rst 08h
		.byte Betn_Objekt_call
		.byte Dcf77Obj_GetTime
		
		rst 08h
		.byte Betn_Get_lcdout
		
		rst 08h
		.byte Betn_Printf_obj
		.byte "DCF: "
		.byte Pf_s,Pf_nn|Pf_dt|Pf_wt
		.word Date
		.byte Cr,Lf,"     "
		.byte Pf_s,Pf_nn|Pf_hhmm|Pf_ss
		.word Date
		.byte 0

		rst 08h
		.byte Betn_Get_PortA
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ReadPort
		
		rst 08h
		.byte Betn_Get_PortB
		
		and DCF_77
		
		ld b,LED_GE
		
		jr z,Clock1
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ClrMask
		
		jr Clock2
Clock1
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMask
Clock2
		ld hl,10
		
		rst 08h
		.byte Betn_Timer

		call GetBackButton
		jr c,MainMenu
	
		jr Clock

; ---- Neustart ----

Neustart	jp 0
; ----

GetBackButton
		push af
		push ix
		
		rst 08h
		.byte Betn_Get_PortA
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ReadPort
		
		and BUTTON
		jr nz,GetBackButton1
		
		pop ix
		pop af
		scf
		ret
GetBackButton1
		pop ix
		pop af
		or a
		ret

; ----

GetEncButton
		push af
		push ix
		
		rst 08h
		.byte Betn_Get_PortA
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ReadPort
		
		and ENC_BUTTON
		jr nz,GetEncButton1
		
		pop ix
		pop af
		scf
		ret
GetEncButton1
		pop ix
		pop af
		or a
		ret

; --- Encoder Menu ----
; HL -> Menu
Menu 	push af
		push bc
		push de
		push hl
		push ix
		
Menu0	call GetEncButton
		jr c,Menu0
		call GetBackButton
		jr c,Menu0
	
		call MenuCount

		rst 08h
		.byte Betn_GetEncoder
		
		ld c,0
		dec b
		rst 08h
		.byte Betn_Objekt_call
		.byte EncoderObj_SetMaxVal

		rst 08h
		.byte Betn_Objekt_call
		.byte EncoderObj_GetAktVal
Menu1
		push hl
		
		ld c,a
		call MenuGet
		
		rst 08h
		.byte Betn_Get_lcdout
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Cr
		.byte Pf_s,Pf_clrl
		.byte Pf_s,Pf_str,0
		
		pop hl
		
		rst 08h
		.byte Betn_GetEncoder
Menu2		
		rst 08h
		.byte Betn_Objekt_call
		.byte EncoderObj_GetAktVal

		call GetEncButton
		jr c,Menu3
		
		call GetBackButton
		jr c,Menu4
		
		cp a,c
		jr z,Menu2
		
		jr Menu1

Menu3	pop ix
		pop hl
		pop bc
		pop bc
		pop af
		scf
		ret
		
Menu4	pop ix
		pop hl
		pop de
		ld de,0
		pop bc
		pop af
		or a
		ret
	
; ---- Anzahl der menu Eintraege ermitteln ----
; HL -> zeiger Auf Menu
; B  <- Anzahl der Eintraege

MenuCount
		push af
		push hl
		
		ld b,0
MenuCount1
		ld a,(hl)
		or a
		jr z,MenuCount3
MenuCount2
		inc hl
		ld a,(hl)
		or a
		jr nz,MenuCount2
		
		inc b
		inc hl
		inc hl
		inc hl
		
		jr MenuCount1
MenuCount3
		pop hl
		pop af
		ret
		
; ---- Menueintrag hohlen ----
; HL -> Menu
; C -> Nummer des Eintrags
; HL <-Zeiget auf Eintrag
; DE <- Adresse

MenuGet	push af
		push bc
MenuGet1
		ld a,c
		or a
		jr z,MenuGet3
MenuGet2
		ld a,(hl)
		inc hl
		or a
		jr nz,MenuGet2
		inc hl
		inc hl
		dec c
		jr MenuGet1
MenuGet3
		push hl
MenuGet4
		ld a,(hl)
		inc hl
		or a
		jr nz,MenuGet4
		ld e,(hl)
		inc hl
		ld d,(hl)
		pop hl
		pop bc
		pop af
		ret
		
; ---- Rollladen ----

Rollladen
		rst 08h
		.byte Betn_Get_lcdout
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Pf_s,Pf_clrscr
		.byte "Rollladen",Cr,Lf,0
		
		ld hl,RollladenTab

		call Menu
		jp nc,MainMenu

		ld hl,de
		
		rst 08h
		.byte Betn_Printf_obj
		.byte Cr,Lf,0
Rollladen1
		push hl

		ld hl,PayloadTab
		call Menu
		
		pop hl
		
		jr nc,Rollladen
		
		ld bc,de
		
		rst 08h
		.byte Betn_Get_MqttClient
		
		rst 08h
		.byte Betn_Objekt_call
		.byte MqttObj_Connected

		jr c,Rollladen2
		
		push hl
		
		ld hl,BROKER
		
		rst 08h
		.byte Betn_Objekt_call
		.byte MqttObj_Connect

		pop hl
	
Rollladen2
		rst 08h
		.byte Betn_Objekt_call
		.byte MqttObj_Publish
		
		jr Rollladen1
		
RollladenTab	
All				.byte "all",0
				.word All
Arbeitszimmer	.byte "Arbeitszimmer",0
				.word Arbeitszimmer
Schafzimmer		.byte "Schlafzimmer",0
				.word Schafzimmer
Terassenfenster	.byte "Terassenfenster",0
				.word Terassenfenster
Terassentuer	.byte "Terassentuer",0
				.word Terassentuer
Badezimmer		.byte "Badezimmer",0
				.word Badezimmer
Wohnzimmerfenster .byte "Wohnzimmerfenster",0
				.word Wohnzimmerfenster
KuecheRechts	.byte "KuecheRechts",0
				.word KuecheRechts
KuecheLinks		.byte "KuecheLinks",0
				.word KuecheLinks
				.byte 0
				
PayloadTab		
Down			.byte "down",0
				.word Down
Up				.byte "up",0
				.word Up
Stop			.byte "stop",0
				.word Stop
				.byte 0
				
MainMenuTab	.byte "Uhrzeit",0
			.word  Clock
			.byte "Neustart",0
			.word  Neustart
			.byte "Rollladen",0
			.word Rollladen
			.byte 0
