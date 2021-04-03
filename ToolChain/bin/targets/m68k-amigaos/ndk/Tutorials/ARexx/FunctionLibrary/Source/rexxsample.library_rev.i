VERSION		EQU	1
REVISION	EQU	2
DATE	MACRO
		dc.b	'25.6.97'
	ENDM
VERS	MACRO
		dc.b	'rexxsample.library 1.2'
	ENDM
VSTRING	MACRO
		dc.b	'rexxsample.library 1.2 (25.6.97)',13,10,0
	ENDM
VERSTAG	MACRO
		dc.b	0,'$VER: rexxsample.library 1.2 (25.6.97)',0
	ENDM
