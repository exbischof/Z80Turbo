.include "ez80f91.inc"

LedYelMask			.equ 00100000b
LedGreenMask		.equ 10000000b
NoInformation		.equ f8h
StartTransmitted	.equ 08h
RepeatedStartTransmitted .equ 10h
AddressWrtieTransmittedAckRec	.equ 18h
AddressWrtieTransmittedNackRec	.equ 20h
AddressReadTransmittedAckRec	.equ 40h
DataWrtieTransmittedAckRec	.equ 28h
DataReadTransmittedNack	.equ 58h

Address				.equ 1010000b
EepromAddress		equ 0000h

xdef			EEPROM

.assume ADL=0

EEPROM

				ld a,55h
				call WriteCmp
				jr nc,Ee1
				ld a,AAh
				call WriteCmp
				jr nc,Ee1
				scf
				ret
Ee1				or a
				ret
			
WriteCmp
				push af
				push de
				
				ld e,a
				
				ld a,0h
				out0 (I2C_SRR),a
				ld a,00010100b							; F_SCL = 100000kHz
				out0 (I2C_CCR),a
				ld a,01000000b							; I2C enable
				out0 (I2C_CTL),a
Eeprom0
				ld a,01100000b							; Start senden
				out0 (I2C_CTL),a				

Eeprom1			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom1

				in0 a,(I2C_SR)
				cp StartTransmitted
				jr nz,Fehler
				
				ld a,Address << 1
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom2			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom2

				in0 a,(I2C_SR)
				cp AddressWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,HIGH(EepromAddress)
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom3			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom3

				in0 a,(I2C_SR)
				cp DataWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,LOW(EepromAddress)
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom4			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom4

				in0 a,(I2C_SR)
				cp DataWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,e
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom5			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom5

				in0 a,(I2C_SR)
				cp DataWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,01010000b					; STOP senden
				out0 (I2C_CTL),a
				
Eeprom5a		in0 a,(I2C_CTL)
				and 00010000b
				jr nz,Eeprom5a
Eeprom5b				
				ld a,01100000b							; Start senden
				out0 (I2C_CTL),a				

Eeprom6			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom6

				in0 a,(I2C_SR)
				cp StartTransmitted
				jr nz,Fehler
				
				ld a,Address << 1
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom7			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom7

				in0 a,(I2C_SR)
				cp AddressWrtieTransmittedAckRec
				jr z,Eeprom7a
		
				cp 	AddressWrtieTransmittedNackRec
				jr nz,Fehler
				
				ld a,01010000b					; STOP senden
				out0 (I2C_CTL),a
				
Eeprom7b		in0 a,(I2C_CTL)
				and 00010000b
				jr nz,Eeprom7b
				
				jr Eeprom5b
				
Eeprom7a		ld a,HIGH(EepromAddress)
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom8			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom8

				in0 a,(I2C_SR)
				cp DataWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,LOW(EepromAddress)
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom9			in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom9

				in0 a,(I2C_SR)
				cp DataWrtieTransmittedAckRec
				jr nz,Fehler
				
				ld a,01010000b					; STOP senden
				out0 (I2C_CTL),a
				
Eeprom9a		in0 a,(I2C_CTL)
				and 00010000b
				jr nz,Eeprom9a
				
				ld a,01100000b							; Start senden
				out0 (I2C_CTL),a				

Eeprom10		in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom10

				in0 a,(I2C_SR)
				cp StartTransmitted
				jr nz,Fehler
				
				ld a,Address << 1 | 1
				out0 (I2C_DR),a

				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom11		in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom11

				in0 a,(I2C_SR)
				cp AddressReadTransmittedAckRec
				jr nz,Fehler
				
				ld a,01000000b
				out0 (I2C_CTL),a
				
Eeprom12		in0 a,(I2C_CTL)
				and 00001000b
				jr z,Eeprom12

				in0 a,(I2C_SR)
				cp DataReadTransmittedNack
				jr nz,Fehler
				
				in0 a,(I2C_DR)
				cp a,e
				jr nz,Fehler
				
				ld a,01010000b					; STOP senden
				out0 (I2C_CTL),a
				
Eeprom12a		in0 a,(I2C_CTL)
				and 00010000b
				jr nz,Eeprom12a
				
				pop de
				pop af
				scf
				ret

Fehler			pop de
				pop af
				or a
				ret