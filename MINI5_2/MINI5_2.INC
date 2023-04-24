Betn_Ver_test    .EQU  0000h
Betn_Warmstart   .EQU  0001h
Betn_Char_out    .EQU  0004h
;Betn_Char_da     .EQU  0008h veraltet
Betn_Char_get    .EQU  0009h
Betn_Meld_out    .EQU  000ah
Betn_Line_get    .EQU  000bh
Betn_Time_in     .EQU  000ch
Betn_Int_dis     .EQU  000fh
Betn_Int_old     .EQU  0010h
Betn_Relocate    .EQU  0011h
Betn_Mem_max     .EQU  0012h
Betn_Mem_Alloc   .EQU  0013h
Betn_Mem_size    .EQU  0014h
Betn_Mem_shrink  .EQU  0015h
Betn_Mem_free    .EQU  0016h
Betn_Tagnummer   .EQU  0017h
Betn_Guru        .EQU  0018h
;Betn_Meld_obj_out .EQU  0019h veraltet
Betn_Tagnr2datum .EQU  001ah
Betn_Wait        .EQU  001bh
Betn_Bez_set     .EQU  001ch
Betn_Bez_get     .EQU  001dh
Betn_Bez_del     .EQU  001eh
Betn_Objekt_call .EQU  001fh
Betn_Tab_branch  .EQU  0020h
Betn_Bcd2bin     .EQU  0021h
Betn_Get_stdout  .EQU  0022h
Betn_Printf_obj  .EQU  0023h
Betn_Divi        .EQU  0024h
Betn_Multi       .EQU  0025h
Betn_Menu_branch .EQU  0026h
Betn_Get_lcdout  .EQU  0027h
Betn_Get_SerialOut  .EQU  0028h 
Betn_Printf      .EQU  0029h
;Betn_Wort_in     .EQU  002ah veraltet
Betn_Zahl_in     .EQU  002bh
Betn_Kom_add     .EQU  002ch
Betn_Mem_fill    .EQU  002dh
Betn_Mem_move    .EQU  002eh
Betn_Datum_in    .EQU  002fh
Betn_Calc_wochentag .EQU  0030h
;Betn_Sysint_set  .EQU  0031h veraltet
;Betn_Sysint_clr  .EQU  0032h veraltet
Betn_ObjektSuperJmp .EQU 33h
Betn_SetIntVek	.EQU 34h
Betn_ClrIntVek	.EQU 35h
Betn_Int_enable  .EQU 36h
Betn_GetStdOut   .EQU 37h
Betn_Char_get_non_blocking .EQU 38h
Betn_Pointprn	.EQU 39h
Betn_Set_AutoStart .EQU 3Ah
Betn_SetUserBreakVektor .EQU 3bh
Betn_ScheduleNow	EQU 3ch
Betn_Yield		EQU 3dh
Betn_Suspend	EQU 3eh
Betn_GetAktTask EQU 3fh
Betn_Timer		EQU 40h
Betn_GetRtc		EQU 41h
Betn_Get_PortB  EQU 42h
Betn_Get_Timer  EQU 43h
Betn_GetEncoder EQU 44h
Betn_Get_PortA  EQU 45h
Betn_Get_dcf	EQU 46h
Betn_Calc_DOW   EQU 47h
Betn_Int_ret    EQU 48h
Betn_Get_EspOut EQU 49h
Betn_Get_PortC  EQU 4Ah
Betn_Get_PortD  EQU 4Bh
Betn_Chancel_Task EQU 4ch
Betn_Get_WifiClient EQU 4dh
Betn_Space_ignore  EQU 4eh
Betn_Get_MqttClient EQU 4fh

Gpio_PortA	equ 0
Gpio_PortB	equ 1
Gpio_PortC	equ 2
Gpio_PortD	equ 3

ENC_A				equ 00001000b
ENC_B				equ 00010000b
ENC_BUTTON			equ 00000100b
ENC_BUTTON_MIRROR	equ 00100000b
BUTTON				equ 00000001b
BUTTON_MIRROR		equ 10000000b
DCF_77				equ 00000010b
DCF_77_MIRROR		equ 01000000b

ESP_RST				equ 00001000b

LED_GE			equ 00100000b
LCD_RESET		equ 01000000b
LED_GR			equ 10000000b

SEC_OFFSET		equ 0
MIN_OFFSET		equ 1
HOUR_OFFSET		equ 2
DOM_OFFSET      equ 3
MON_OFFSET      equ 4
YEAR_OFFSET     equ 5
DOW_OFFSET		equ 7
DATETIME_SIZE   equ 8
