VERSION		EQU	38
REVISION	EQU	3
DATE	MACRO
		dc.b	'3.3.92'
	ENDM
VERS	MACRO
		dc.b	'dansk.language 38.3'
	ENDM
VSTRING	MACRO
		dc.b	'dansk.language 38.3 (3.3.92)',13,10,0
	ENDM
VERSTAG	MACRO
		dc.b	0,'$VER: dansk.language 38.3 (3.3.92)',0
	ENDM
