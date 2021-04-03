	IFND _FRAMEWORKLIBRARY_I
_FRAMEWORKLIBRARY_I SET 1

*****************************************************************************

; Name			: IntroLibrary.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Shared library structures.
; Date last edited	: 24/05/2019
				
*****************************************************************************
*****************************************************************************

LIB_SIN_Q14_1024W_NUMWORDS	equ	1024
LIB_SIN_Q14_1024W_COS_OFFSET	equ	(LIB_SIN_Q14_1024W_NUMWORDS/4)*2
LIB_SIN_Q14_1024W_INDEX_MASK	equ	LIB_SIN_Q14_1024W_NUMWORDS-1
LIB_SIN_Q14_1024W_OFFSET_MASK	equ	((LIB_SIN_Q14_1024W_NUMWORDS*2)-2)

LIB_SIN_Q15_1024W_NUMWORDS	equ	1024
LIB_SIN_Q15_1024W_COS_OFFSET	equ	(LIB_SIN_Q15_1024W_NUMWORDS/4)*2
LIB_SIN_Q15_1024W_INDEX_MASK	equ	LIB_SIN_Q15_1024W_NUMWORDS-1
LIB_SIN_Q15_1024W_OFFSET_MASK	equ	((LIB_SIN_Q15_1024W_NUMWORDS*2)-2)

LIB_ARJM7_BUFFER_SIZE		equ	11312
LIB_PACKFIRE_BUFFER_SIZE	equ	15980

;2048 entries, index mask is 0-2047. offset mask is 0-4094
LIB_GENSIN_16384_2048W_NUMWORDS		equ	2048
LIB_GENSIN_16384_2048W_COS_OFFSET	equ	(LIB_GENSIN_16384_2048W_NUMWORDS/4)*2
LIB_GENSIN_16384_2048W_SIZEOF		equ	LIB_GENSIN_16384_2048W_NUMWORDS*2
LIB_GENSIN_16384_2048W_INDEX_MASK	equ	LIB_GENSIN_16384_2048W_NUMWORDS-1
LIB_GENSIN_16384_2048W_OFFSET_MASK	equ	((LIB_GENSIN_16384_2048W_NUMWORDS*2)-2)


; KingCon BOB and image structures
	rsreset
LIB_BOBTABLE_WIDTHINWORDS	rs.w	1	;Width of the BOB in words (see bob width notes below)
LIB_BOBTABLE_NUMSPRITES		equ	LIB_BOBTABLE_WIDTHINWORDS
LIB_BOBTABLE_HEIGHT		rs.w	1	;pixels
LIB_BOBTABLE_WIDTH		rs.w	1	;pixels
LIB_BOBTABLE_OFFSET		rs.l	1	;offset into BPL data
LIB_BOBTABLE_ANCHORX		rs.w	1	;??
LIB_BOBTABLE_ANCHORY		rs.w	1	;??
LIB_BOBTABLE_SIZEOF		rs.b	0	;Just an assembler value to indicate size of structure



*****************************************************************************

	ENDC				; _FRAMEWORKLIBRARY_I