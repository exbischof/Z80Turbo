; MQTT Object

.include "helper.inc"
.include "SerialObj.inc"
.include "PrintfObj.inc"
.include "mini5_2.inc"
.include "Char.inc"
.include "WifiClientObj.inc"
.include "Task.inc"

.assume ADL=0

xdef MqttObj

.define MqttObjSeg
segment MqttObjSeg

ReadStackSize	equ 100h
ReadPriority	equ 20h

PingStackSize	equ 100h
PingPriority	equ 15h

MQTT_VERSION	equ 4
CLEAN_SESSION   equ 02h
MQTT_KEEPALIVE  equ 15
MQTTCONNECT     equ 1 << 4
MQTTPUBLISH     equ 3 << 4
MQTTCONNACK     equ 2 << 4
MQTTPINGREQ		equ 12 << 4
MQTTPINGRESP	equ 13 << 4

Class			equ 0
ConnectedFlag	equ 2
ConnectResult   equ 3
ConnectTask		equ 4
DataEnd			equ 6

MqttObj
			jr Start
		
			.word 0000h 	; keine Superklasse
		
			.byte 3
			.word Connect
			.word Publish
			.word Connected
Start
			push af
			push bc
			push ix
			
			ld bc,DataEnd
			rst 08h
			.byte Betn_Mem_Alloc

			jr nc,Err

			ld ix,hl

			ld bc,MqttObj
			ld (ix+Class),c
			ld (ix+(Class+1)),b
		
			xor a
			ld (ix+ConnectedFlag),a
			ld (ix+ConnectTask),a
			ld (ix+ConnectTask+1),a
			
			ld a,ReadPriority
			ld hl,ReadTask
			ld bc,ReadStackSize
			call TaskObj
			rst 08h
			.byte Betn_ScheduleNow	

			ld a,PingPriority
			ld hl,PingTask
			ld bc,PingStackSize
			call TaskObj
			rst 08h
			.byte Betn_ScheduleNow	

			ld hl,ix
			
			pop ix
			pop bc
			pop af
			scf
			ret

Err			pop ix
			pop bc
			pop af
			or a
			ret
			
; ---- MQTT Verbindung aufbauen ----
; HL -> Zeiger auf IP Adresse

Connect
			push af
			push bc
			push hl
			
			push ix
			
			rst 08h
			.byte Betn_Get_WifiClient
			
			ld bc,1883
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Connect

			pop ix
			
			ld a,ffh
			ld (ix+ConnectResult),a
			
			jr nc,ConnectErr
			
			ld hl,MqttProtokoll
			call StrLen
			ld bc,8
			add hl,bc
			ld bc,hl
			ld hl,MqttClientId
			call StrLen
			adc hl,bc
			ld bc,hl
			
			push bc
			
			call GetHeaderLen
			adc hl,bc
			ld bc,hl

			push ix
			
			rst 08h
			.byte Betn_Get_WifiClient
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_BeginWrite			

			pop ix

			pop bc

			jr nc,ConnectErr
			
			ld a,MQTTCONNECT
			call WriteHeader
			
			ld hl,MqttProtokoll
			call WriteString
			
			push ix

			rst 08h
			.byte Betn_Get_WifiClient

			ld a,MQTT_VERSION
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld a,CLEAN_SESSION
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld a,HIGH(MQTT_KEEPALIVE)
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld a,LOW(MQTT_KEEPALIVE)
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld hl,MqttClientId
			call WriteString
						
			rst 08h
			.byte Betn_Get_WifiClient
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_EndWrite			

			pop ix
			
			jr nc,ConnectErr
			
			rst 08h
			.byte Betn_GetAktTask

			rst 08h
			.byte Betn_Int_dis
			
			ld a,(ix+ConnectResult)
			cp ffh
			jr z,Connect1
			
			xor a
			ld (ix+ConnectTask),a
			ld (ix+ConnectTask+1),a

			rst 08h
			.byte Betn_Int_old
			
			jr Connect2
Connect1
			ld (ix+ConnectTask),l
			ld (ix+ConnectTask+1),h
			
			rst 08h
			.byte Betn_Suspend
Connect2	
			ld a,(ix+ConnectResult)
			or a
			jr nz,ConnectErr
			
			ld a,1
			ld (ix+ConnectedFlag),a
			
			pop hl
			pop bc
			pop af
			scf
			ret
ConnectErr	
			xor a
			ld (ix+ConnectedFlag),a

			pop hl
			pop bc
			pop af
			or a
			ret
			
			
; ---- Publish nachricht senden ----
; HL -> Zeiger auf topic
; BC -> Zeiger auf Payload

Publish		push af
			push bc
			push hl
			push ix
			
			push hl
			push bc
			
			rst 08h
			.byte Betn_Get_WifiClient
			
			call StrLen
			ld bc,2
			add hl,bc
			ld bc,hl
			
			pop hl
			push hl
			
			call StrLen
			adc hl,bc
			ld bc,hl
			
			push bc

			call GetHeaderLen
			adc hl,bc
			ld bc,hl

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_BeginWrite			

			pop bc
			
			ld a,MQTTPUBLISH
			call WriteHeader
			
			pop bc
			pop hl
			
			call WriteString
			
			ld hl,bc
Publish1
			ld a,(hl)
			or a
			jr z,Publish2

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			inc hl
			jr Publish1

Publish2	rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_EndWrite			

			pop ix
			pop hl
			pop bc
			pop af
			ret
			
; ---- test Ob Mqtt Verbinung besteht ----

Connected	push af
			push ix
			ld a,(ix+ConnectedFlag)
			or a
			jr z,Connected1
			
			rst 08h
			.byte Betn_Get_WifiClient
			
			rst 08h
			byte Betn_Objekt_call
			.byte WifiClient_Connected
			jr nc,Connected1
			
			pop ix
			pop af
			scf
			ret
			
Connected1	pop ix
			pop af
			or a
			ret
			
; ---- Laenge des Header berechenen -----
; BC -> Lange des Telegramms
; HL <- Laenge des Headers

GetHeaderLen	ld hl,2
				ret
				
; ---- Mqtt-Header schreiben ----
; A -> fixed Header
; BC -> Laenge

WriteHeader	push af
			push ix

			rst 08h
			.byte Betn_Get_WifiClient

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld a,c
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			pop ix
			pop af
			
			ret
			
; ---- String ausdgeben ----
; HL -> Zeiger auf String

WriteString
			push af
			push hl
			push ix
			
			push hl
			
			call StrLen
			
			rst 08h
			.byte Betn_Get_WifiClient

			ld a,h

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			ld a,l

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			pop hl
WriteString1
			ld a,(hl)
			or a
			jr z,WriteString2
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write

			inc hl
			jr WriteString1
WriteString2
			pop ix
			pop hl
			pop af
			ret
			
; ---- MQTT Contgrol Packet schreiben ----
; A  -> Header
; HL -> Zeiger auf Puffer
; BC -> Laenge (muss kleiner sein als <128)

MqttWrite	push af
			push bc
			push hl
			push ix
			
			rst 08h
			.byte Betn_Get_WifiClient
MqttWrite1
			call Test_BC
			jr z,MqttWrite2
			
			ld a,(hl)
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Write
			
			dec bc
			inc hl
			jr MqttWrite1
MqttWrite2
			pop ix
			pop hl
			pop bc
			pop af
			ret

; ---- Read Task ----

ReadTask
			call ReadHeader
			
			and f0h
			
			cp MQTTCONNACK
			jr nz,ReadTask1
			
			push ix
			
			rst 08h
			.byte Betn_Get_WifiClient

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Read

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Read

			pop ix

			ld (ix+ConnectResult),a
			
			ld l,(ix+ConnectTask)
			ld h,(ix+ConnectTask+1)

			xor a
			ld (ix+ConnectTask),a
			ld (ix+ConnectTask+1),a
			
			call Test_HL
			jr z,ReadTask
			
			rst 08h
			.byte Betn_ScheduleNow
			
			jr ReadTask
			
ReadTask1	cp MQTTPINGRESP
			jr nz,ReadTask
			jr ReadTask
ReadIgnore
			ld hl,bc
			
			rst 08h
			.byte Betn_Get_WifiClient
ReadIgnore1
			call Test_HL
			jr z,ReadTask

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Read

			dec hl
			
			jr ReadIgnore1
			
; ---- Header lesen -----

ReadHeader
			push ix
			
			rst 08h
			.byte Betn_Get_WifiClient

			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Read

			push af
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_Read

			ld b,0
			ld c,a
			
			pop af
			
			pop ix
			
			ret

; ---- Ping Task ----

PingTask	ld hl,MQTT_KEEPALIVE*1000
			rst 08h
			.byte Betn_Timer
			
			call Connected
			jr nc,PingTask

			rst 08h
			.byte Betn_Get_WifiClient

			ld bc,0
			call GetHeaderLen
			ld bc,hl
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_BeginWrite			

			ld a,MQTTPINGREQ
			ld bc,0
			
			call WriteHeader
			
			rst 08h
			.byte Betn_Objekt_call
			.byte WifiClient_EndWrite			

			jr PingTask

MqttProtokoll
			.byte "MQTT",0
MqttClientId
			.byte "abc",0