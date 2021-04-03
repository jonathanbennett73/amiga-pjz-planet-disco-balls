VERSION		EQU	44
REVISION	EQU	1

DATE	MACRO
		dc.b '30.10.1999'
		ENDM

VERS	MACRO
		dc.b 'aiff.datatype 44.1'
		ENDM

VSTRING	MACRO
		dc.b 'aiff.datatype 44.1 (30.10.1999)',13,10,0
		ENDM

VERSTAG	MACRO
		dc.b 0,'$VER: aiff.datatype 44.1 (30.10.1999)',0
		ENDM
