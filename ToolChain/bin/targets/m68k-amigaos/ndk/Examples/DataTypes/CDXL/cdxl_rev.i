VERSION		EQU	44
REVISION	EQU	16
DATE	MACRO
		dc.b	'10.5.99'
	ENDM
VERS	MACRO
		dc.b	'cdxl 44.16'
	ENDM
VSTRING	MACRO
		dc.b	'cdxl 44.16 (10.5.99)',13,10,0
	ENDM
VERSTAG	MACRO
		dc.b	0,'$VER: cdxl 44.16 (10.5.99)',0
	ENDM
