; WifiClient Object

.include "mini5_2.inc"
.include "helper.inc"
.include "Char.inc"
.include "SerialObj.inc"
.include "PrintfObj.inc"
.include "GpioPortObj.inc"
.include "Task.inc"
.include "FifoObj.inc"
.include "config.inc"

.assume ADL=0

xdef WifiClientObj

.define xyz
segment xyz

ParserPriority			equ 40h
ParserStackSize			equ 100h
TokenFifoLen			equ 5
BufferSize				equ 50

RET_STR_OK				equ 0
RET_STR_ERROR			equ 1
RET_STR_WIFI_CONNECTED	equ 2
RET_STR_WIFI_GOT_IP		equ 3
RET_STR_WIFI_DISCONNECT	equ 4
RET_STR_CONNECT			equ 5
RET_STR_CLOSED			equ 6
RET_STR_IPD				equ 7
RET_STR_RECV			equ 8
RET_STR_SEND_OK			equ 9
RET_STR_AT				equ 10
RET_STR_PROMT			equ 11
RET_STR_PLUS_I			equ 12
RET_STR_UNKOWN			equ 255

Class			equ 0
Wifi_Connected	equ 2
Wifi_GotIp		equ 3
Tcp_Connected	equ 4
BytesToRead		equ 5
ParserTask		equ 7
TokenFifo		equ 9
ReadTask		equ 11
Buffer			equ 13
DataEnd			equ Buffer+BufferSize

; --- Konstruktor ----
; HL <- Adresse des Onjekts

WifiClientObj
		jr Start
		
		.word 0000h 	; keine Superklasse
		
		.byte 7
		.word Connect
		.word BeginWrite
		.word Write
		.word EndWrite
		.word Read
		.word Flush
		.word Connected
		
Start
		push af
		push bc
		push de
		push ix
		
		ld bc,DataEnd
		rst 08h
		.byte Betn_Mem_Alloc
		
		jr nc,Err
		
		call EspReset

		ld ix,hl

		ld bc,WifiClientObj
		ld (ix+Class),c
		ld (ix+(Class+1)),b
		
		xor a
		ld (ix+BytesToRead),a
		ld (ix+BytesToRead+1),a
		ld (ix+ReadTask),a
		ld (ix+ReadTask+1),a
		
		ld bc,TokenFifoLen
		call FifoObj
		ld (ix+TokenFifo),l
		ld (ix+(TokenFifo+1)),h

		xor a
		ld (ix+Wifi_Connected),a
		ld (ix+Wifi_GotIp),a
		ld (ix+Tcp_Connected),a
		
		ld a,ParserPriority
		ld hl,Parser
		ld bc,ParserStackSize
		call TaskObj
		ld (ix+ParserTask),l
		ld (ix+ParserTask+1),h
		
		rst 08h
		.byte Betn_ScheduleNow

		push ix
		
		rst 08h
		.byte Betn_Get_PortC
		
		ld a,GpioModeOutput
		ld b,ESP_RST
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMode
		
		pop ix
		
		ld hl,ix
		
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

; ----
; IX -> Zeiger auf Objekt
; HL -> Zeiger auf IP Addresse
; BC -> Portnummer

Connect		
			push af
			push hl
		
			call SendCmd
			.byte "AT+CWMODE_CUR=1",Cr,Lf,0

			call ReadToken
			
			cp a,RET_STR_OK
			jr nz,Connect_Err

			push hl

			ld hl,SSID

			call SendCmd
			.byte "AT+CWJAP_CUR=",'"',Pf_s,Pf_str,'"',",",'"',0

			ld hl,WIFIPW
			
			call SendCmd
			.byte Pf_s,Pf_str,'"',Cr,Lf,0

			pop hl
			
			call ReadToken

			cp a,RET_STR_OK
			jr nz,Connect_Err

			call SendCmd
			.byte "AT+CIPSTART=",'"',"TCP",'"',",",'"',Pf_s,Pf_str,'"',",",0
			
			ld hl,bc
			
			call SendCmd
			.byte Pf_s,Pf_dez,Cr,Lf,0

			call ReadToken
			
			cp a,RET_STR_OK
			jr nz,Connect_Err
Connect6
			pop hl
			pop af
			scf
			ret

Connect_Err	pop hl
			pop af
			or a
			ret
			
; ---- Beginnen Daten ueber TCP-Verbindung schreiben ----
; IX -> Zeiger auf Objekt
; BC -> Anzahl der Bytes


BeginWrite
			push af
			push hl
			
			ld hl,bc

			call SendCmd
			.byte "AT+CIPSEND=",Pf_s,Pf_dez,Cr,Lf,0

			call ReadToken
			cp RET_STR_OK
			jr nz,BeginWrite1
			
			call ReadToken
			cp RET_STR_PROMT
			jr nz,BeginWrite1

			pop hl
			pop af
			scf
			ret
BeginWrite1
			pop hl
			pop af
			or a
			ret
			
; ---- TCP-Verbindung schreiben ----
; IX -> Zeiger auf Objekt
; A -> Byte


Write
			push ix
			
			rst 08h
			.byte Betn_Get_EspOut
			
			rst 08h
			.byte Betn_Objekt_call
			.byte SerialObj_CharOut

			pop ix

			ret
			
; ---- Ende des Schreibens über TCP-Verbindung ----
; IX -> Zeiger auf Objekt
; CFL -> =1 OK =0 Fehler


EndWrite
			push af
			
			call ReadToken
			cp RET_STR_RECV
			jr nz,EndWrite1

			call ReadToken
			cp RET_STR_SEND_OK
			jr nz,EndWrite1

			pop af
			scf
			ret

EndWrite1	pop af
			or a
			ret

; ---- aus TCP-Verbindung lesen ----
; IX -> Zeiger auf Objekt
; A <- Byte


Read
 			push hl
			push ix
			
			ld l,(ix+BytesToRead)
			ld h,(ix+BytesToRead+1)
			call Test_HL
			jr nz,Read1
			
			rst 08h
			.byte Betn_GetAktTask
			
			ld (ix+ReadTask),l
			ld (ix+ReadTask+1),h
			
			rst 08h
			.byte Betn_Suspend
Read1
			rst 08h
			.byte Betn_Get_EspOut
			
			rst 08h
			.byte Betn_Objekt_call
			.byte SerialObj_Char_get

			pop ix

			ld l,(ix+BytesToRead)
			ld h,(ix+BytesToRead+1)
			dec hl
			ld (ix+BytesToRead),l
			ld (ix+BytesToRead+1),h
			
			call Test_HL
			jr nz,Read2
			ld l,(ix+ParserTask)
			ld h,(ix+ParserTask+1)
			rst 08h
			.byte Betn_ScheduleNow
Read2
			pop hl
			
			ret

; ---- Einagbepuffer leeren ----

Flush		push af
			push hl
			push ix

			ld l,(ix+BytesToRead)
			ld h,(ix+BytesToRead+1)
			
			rst 08h
			.byte Betn_Get_EspOut
Flush1			
			call Test_HL
			jr z,Flush2

			rst 08h
			.byte Betn_Objekt_call
			.byte SerialObj_Char_get

			dec hl
			jr Flush1
Flush2
			pop ix
			pop hl
			pop af
			ret
			
; --- Test ob TCP Verbing besteht ----
; IX -> Zeiger auf Objekt
; CFL <- =1 >verbunden =0 nicht verbunden

Connected	push af
			ld a,(ix+Tcp_Connected)
			or a
			jr z,Connected1
			pop af
			scf
			ret
Connected1	pop af
			or a
			ret
			
; ---- Parser Task

Parser		
			call ParseReturnString

			cp a,RET_STR_WIFI_CONNECTED
			jr nz,Parser2
			
			ld a,1
			ld (ix+Wifi_Connected),a
			jr Parser
Parser2
			cp a,RET_STR_WIFI_GOT_IP
			jr nz,Parser3
			
			ld a,1
			ld (ix+Wifi_GotIp),a
			jr Parser
Parser3
			cp a,RET_STR_CONNECT
			jr nz,Parser4
			
			ld a,1
			ld (ix+Tcp_Connected),a
			jr Parser
Parser4
			cp a,RET_STR_WIFI_DISCONNECT
			jr nz,Parser5
			
			xor a
			ld (ix+Wifi_Connected),a
			ld (ix+Wifi_GotIp),a
			ld (ix+Tcp_Connected),a
			
			jr Parser
Parser5
			cp a,RET_STR_CLOSED
			jr nz,Parser6
			
			xor a
			ld (ix+Tcp_Connected),a
			
			jr Parser
Parser6
			cp RET_STR_IPD
			jr nz,Parser7

			ld c,10
			rst 08h
			.byte Betn_Zahl_in
			jr nc,Parser

			ld a,(hl)
			cp ':'
			jr nz,Parser
			
			ld (ix+BytesToRead),e
			ld (ix+BytesToRead+1),d

			ld l,(ix+ReadTask)
			ld h,(ix+ReadTask+1)
			call Test_HL
			jr z,Parser8
			
			rst 08h
			.byte Betn_ScheduleNow
Parser8
			rst 08h
			.byte Betn_Suspend

			jr Parser
Parser7
			ld l,(ix+TokenFifo)
			ld h,(ix+TokenFifo+1)
			push ix
			ld ix,hl
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_Put
			pop ix
			
			jr Parser
			
; ----

ReadToken	push ix
			push hl
			ld l,(ix+TokenFifo)
			ld h,(ix+TokenFifo+1)
			ld ix,hl
			rst 08h
			.byte Betn_Objekt_call
			.byte FifoObj_GetBlocking
			pop hl
			pop ix
			ret
			
; ---- Rückgabestring von ESP-01 Modul bearbeiten ----
; IX -> Zeiger auf Objekt
; A <-  enum mit Ergebniss
; HL <- Zeiger auf naechstes Zeichen

ParseReturnString
			push bc
ParseReturnString0
			ld bc,Buffer					; Pufferadresse -> HL
			ld hl,ix
			add hl,bc
ParseReturnString1
			call CharRead					; erstes Zeichen lesen
			cp Lf
			jr z,ParseReturnString0
			ld (hl),a
			inc hl
			call CharRead					; zweites Zeichen lesen
			cp Lf
			jr z,ParseReturnString0
			ld (hl),a
			inc hl							; ersten beiden Zeichen im Puffer mi 0x00 abschliessen
			xor a
			ld (hl),a
						
			push hl

			ld bc,Buffer					; Pufferadresse -> HL
			ld hl,ix
			add hl,bc

			ld bc,StartTab					; Anfangs-String suchen
			rst 08h
			.byte Betn_Kom_add

			pop hl
			
			ld b,2

			jr nc,ParseReturnString5
			
			ld a,c
			
			cp RET_STR_PROMT
			jr z,ParseReturnString7
			
			cp RET_STR_AT
			jr nz,ParseReturnString3
			
ParseReturnString2							; fängt String mit "AT" and, dann bis Lf lesen
			call CharRead
			cp Lf
			jr nz,ParseReturnString2
			jr ParseReturnString0
			
ParseReturnString3
			cp RET_STR_PLUS_I
			jr nz,ParseReturnString5
			
ParseReturnString4							; fängt String mit "+I" and, dann bis ':' lesen
			ld a,b
			cp BufferSize-1
			jr nc,ParseReturnString6		; Puffer voll, dann Fehler ausgeben
			call CharRead
			cp Lf
			jr z,ParseReturnString6
			ld (hl),a
			inc hl
			inc b
			push af							; Ende der Eingabe miz 0x00 anschliessen
			xor a
			ld (hl),a
			pop af
			cp ':'
			jr nz,ParseReturnString4
			jr ParseReturnString8	

ParseReturnString5
			ld a,b
			cp BufferSize-1
			jr nc,ParseReturnString6		; Puffer voll, dann Fehler ausgeben
			call CharRead
			cp Lf
			jr z,ParseReturnString8

			ld (hl),a
			inc hl
			inc b
			push af							; Ende der Eingabe miz 0x00 anschliessen
			xor a
			ld (hl),a
			pop af
			jr ParseReturnString5
ParseReturnString8							; Eingabe analysieren
			ld bc,Buffer
			ld hl,ix
			add hl,bc
			rst 08h
			.byte Betn_Space_ignore
			ld a,(hl)
			or a
			jr z,ParseReturnString0			; Leerzeile ignorieren
			ld bc,ReturnStringTab
			rst 08h
			.byte Betn_Kom_add
			ld a,c
			jr c,ParseReturnString7
ParseReturnString6
			ld a,RET_STR_UNKOWN				; String nicht gefunden dann Fehlermeldung
ParseReturnString7
			pop bc
			ret
			
ReturnStringTab
			.byte "OK",0
			.word RET_STR_OK
			.byte "ERROR",0
			.word RET_STR_ERROR
			.byte "WIFI CONNECTED",0
			.word RET_STR_WIFI_CONNECTED
			.byte "WIFI GOT IP",0
			.word RET_STR_WIFI_GOT_IP
			.byte "WIFI DISCONNECT",0
			.word RET_STR_WIFI_DISCONNECT
			.byte "CONNECT",0
			.word RET_STR_CONNECT
			.byte "CLOSED",0
			.word RET_STR_CLOSED
			.byte "+IPD,",0
			.word RET_STR_IPD
			.byte "Recv",0
			.word RET_STR_RECV
			.byte "SEND OK",0
			.word RET_STR_SEND_OK
			.byte 0
			
StartTab	.byte "AT",0
			.word RET_STR_AT
			.byte "> ",0
			.word RET_STR_PROMT
			.byte "+I",0
			.word RET_STR_PLUS_I
			.byte 0
			
; ---- ESP 01 resetten ----

EspReset
		push af
		push bc
		push hl
		push ix

		rst 08h
		.byte Betn_Get_PortC
		
		ld b,ESP_RST
		
		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_ClrMask
		
		ld hl,10
		rst 08h
		.byte Betn_Timer

		rst 08h
		.byte Betn_Objekt_call
		.byte GpioPortObj_SetMask
		
		ld hl,1000
		rst 08h
		.byte Betn_Timer

		rst 08h
		.byte Betn_Get_EspOut
		
		rst 08h
		.byte Betn_Objekt_call
		.byte SerialObj_ClrInBuffer
		
		pop ix
		pop hl
		pop bc
		pop af
		ret
		
; --- Kommando ausgeben ----

SendCmd	call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		push ix
		rst 08h
		.byte Betn_Get_EspOut

		rst 08h
		.byte Betn_Objekt_call
		.byte PrintfObj_Pointprn
		pop ix
		
		call Ex_hl_de
		ex (Sp),hl
		call Ex_hl_de

		ret

; --- Zeichen lesen ----

CharRead
		push ix
		
		rst 08h
		.byte Betn_Get_EspOut
		rst 08h
		.byte Betn_Objekt_call
		.byte SerialObj_Char_get
		
		pop ix
		
		ret
		
	
