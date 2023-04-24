xref GpioPortObj

GpioPortObj_SetMode		equ 0
GpioPortObj_SetMask		equ 1
GpioPortObj_ClrMask		equ 2
GpioPortObj_InvertMask  equ 3
GpioPortObj_WriteMask   equ 4
GpioPortObj_ReadPort    equ 5
GpioPortObj_Readlatch   equ 6
GpioPortObj_RestInterrupt equ 7
GpioPortObj_SetInterruptVektor equ 8

GpioModeOutput				equ 1
GpioModeInput				equ 2
GpioModeAlternateFunctiuon	equ 7
GpioModeDualEdge     		equ 6
GpioModeEdgeTriggert		equ 9
GpioRisingEdge				equ 1
GpioFallingEdge				equ 0