*
* COPYRIGHT:
*
*   Unless otherwise noted, all files are Copyright (c) 1999 Amiga, Inc.
*   All rights reserved.
*
* DISCLAIMER:
*
*   This software is provided "as is". No representations or warranties
*   are made with respect to the accuracy, reliability, performance,
*   currentness, or operation of this software, and all use is at your
*   own risk. Neither Amiga nor the authors assume any responsibility
*   or liability whatsoever with respect to your use of this software.
*

	SECTION	text,code

;---------------------------------------------------------------------------

	NOLIST

	INCLUDE	"exec/types.i"
	INCLUDE	"exec/libraries.i"
	INCLUDE	"exec/lists.i"
	INCLUDE	"exec/alerts.i"
	INCLUDE	"exec/initializers.i"
	INCLUDE	"exec/resident.i"
	INCLUDE	"exec/macros.i"
	INCLUDE	"libraries/dos.i"

	INCLUDE "locale/languagedrivers.i"

	INCLUDE	"english.language_rev.i"

	LIST

;---------------------------------------------------------------------------

	XDEF	LibInit
	XDEF	LibOpen
	XDEF	LibClose
	XDEF	LibExpunge
	XDEF	LibReserved

;---------------------------------------------------------------------------

   STRUCTURE DriverBase,LIB_SIZE
	ULONG   db_SegList
	ULONG   db_SysLib
   LABEL DriverBase_SIZEOF

;---------------------------------------------------------------------------

; First executable location, must return an error to the caller
Start:
	moveq   #-1,d0
	rts

;-----------------------------------------------------------------------

ROMTAG:
	DC.W    RTC_MATCHWORD		; UWORD RT_MATCHWORD
	DC.L    ROMTAG			; APTR  RT_MATCHTAG
	DC.L    ENDTAG			; APTR  RT_ENDSKIP
	DC.B    RTF_AUTOINIT		; UBYTE RT_FLAGS
	DC.B    VERSION			; UBYTE RT_VERSION
	DC.B    NT_LIBRARY		; UBYTE RT_TYPE
	DC.B    LibPriority		; BYTE  RT_PRI
	DC.L    LibName			; APTR  RT_NAME
	DC.L    LibId			; APTR  RT_IDSTRING
	DC.L    LibInitTable		; APTR  RT_INIT

LibName     DC.B "english.language",0
LibId       VSTRING
LibPriority EQU -100

	CNOP	0,4

LibInitTable:
	DC.L	DriverBase_SIZEOF ; size of library base data space
	DC.L	LibFuncTable
	DC.L	LibDataTable
	DC.L	LibInit

LibFuncTable:
	DC.W	-1
	DC.W	LibOpen-LibFuncTable
	DC.W	LibClose-LibFuncTable
	DC.W	LibExpunge-LibFuncTable
	DC.W	LibReserved-LibFuncTable

	DC.W	GetDriverInfo-LibFuncTable	; GetDriverInfo()
	DC.W	ConvToLower-LibFuncTable	; ConvToLower()
	DC.W	ConvToUpper-LibFuncTable	; ConvToUpper()
	DC.W	GetCodeSet-LibFuncTable		; GetCodeSet()
	DC.W	GetLocaleStr-LibFuncTable	; GetLocaleStr()
	DC.W	IsAlNum-LibFuncTable		; IsAlNum()
	DC.W	IsAlpha-LibFuncTable		; IsAlpha()
	DC.W	IsCntrl-LibFuncTable		; IsCntrl()
	DC.W	IsDigit-LibFuncTable		; IsDigit()
	DC.W	IsGraph-LibFuncTable		; IsGraph()
	DC.W	IsLower-LibFuncTable		; IsLower()
	DC.W	IsPrint-LibFuncTable		; IsPrint()
	DC.W	IsPunct-LibFuncTable		; IsPunct()
	DC.W	IsSpace-LibFuncTable		; IsSpace()
	DC.W	IsUpper-LibFuncTable		; IsUpper()
	DC.W	IsXDigit-LibFuncTable		; IsXDigit()
	DC.W	StrConvert-LibFuncTable		; StrConvert()
	DC.W	StrnCmp-LibFuncTable		; StrnCmp()

	DC.W   -1

LibDataTable:
	INITBYTE   LN_PRI,LibPriority
	INITBYTE   LN_TYPE,NT_LIBRARY
	INITLONG   LN_NAME,LibName
	INITBYTE   LIB_FLAGS,(LIBF_SUMUSED!LIBF_CHANGED)
	INITWORD   LIB_VERSION,VERSION
	INITWORD   LIB_REVISION,REVISION
	INITLONG   LIB_IDSTRING,LibId
	DC.W       0

	CNOP	0,4

;-----------------------------------------------------------------------

; Library Init entry point called when library is first loaded in memory
; On entry, D0 points to library base, A0 has lib seglist, A6 has SysBase
; Returns 0 for failure or the library base for success.
LibInit:
	move.l	d0,a1
        move.l	a0,db_SegList(a1)
        move.l	a6,db_SysLib(a1)
	rts

;-----------------------------------------------------------------------

; Library open entry point called every OpenLibrary()
; On entry, A6 has DriverBase, task switching is disabled
; Returns 0 for failure, or DriverBase for success.
LibOpen:
	addq.w	#1,LIB_OPENCNT(a6)
	bclr	#LIBB_DELEXP,LIB_FLAGS(a6)
	move.l	a6,d0
	rts

;-----------------------------------------------------------------------

; Library close entry point called every CloseLibrary()
; On entry, A6 has DriverBase, task switching is disabled
; Returns 0 normally, or the library seglist when lib should be expunged
;   due to delayed expunge bit being set
LibClose:
	subq.w	#1,LIB_OPENCNT(a6)

	; if delayed expunge bit set, then try to get rid of the library
	btst	#LIBB_DELEXP,LIB_FLAGS(a6)
	bne.s	CloseExpunge
	moveq	#0,d0
	rts

CloseExpunge:
	; if no library users, then just remove the library
	tst.w	LIB_OPENCNT(a6)
	beq.s	DoExpunge

	; still some library users, so just return
	moveq	#0,d0
	rts

;-----------------------------------------------------------------------

; Library expunge entry point called whenever system memory is lacking
; On entry, A6 has LocaleBase, task switching is disabled
; Returns the library seglist if the library open count is 0, returns 0
; otherwise and sets the delayed expunge bit.
LibExpunge:
	tst.w	LIB_OPENCNT(a6)
	beq.s	DoExpunge

	bset	#LIBB_DELEXP,LIB_FLAGS(a6)
	moveq	#0,d0
	rts

DoExpunge:
	movem.l	d2/a5/a6,-(sp)
	move.l	a6,a5
	move.l	db_SysLib(a5),a6
	move.l	db_SegList(a5),d2

	move.l  a5,a1
	REMOVE

	move.l	a5,a1
	moveq	#0,d0
	move.w	LIB_NEGSIZE(a5),d0
	sub.l	d0,a1
	add.w	LIB_POSSIZE(a5),d0
	JSRLIB	FreeMem

	move.l	d2,d0
	movem.l	(sp)+,d2/a5/a6
	rts

;---------------------------------------------------------------------------

LibReserved:
	moveq	#0,d0
	rts

;---------------------------------------------------------------------------

GetCodeSet:
	moveq	#0,d0	; that's what we need, codeset #0
	rts

;---------------------------------------------------------------------------

GetDriverInfo:
	move.l	#ALL_FUNCS,d0
	rts

;---------------------------------------------------------------------------

*	result = StrnCmp(driver,string1,string2,length,type);
*	D0               A0     A1      A2      D0     D1
*
*	LONG StrnCmp(struct DriverBase *,STRPTR,STRPTR,LONG,ULONG);
*

StrnCmp:

	tst.l	d0			; if length = 0, then exit
	bne.s	Ascii
	rts

Ascii:
	tst.l	d1
	bne.s	Collate1

	movem.l	a2/d2,-(sp)		; save work registers
	lea	LowerToUpper(pc),a0	; conversion table address
	moveq.l	#0,d2			; clear all bits
1$:	move.b	(a1)+,d1		; get next character from 1st string
	move.b	(a2)+,d2		; get next character from 2nd string
2$:	move.b	0(a0,d1.w),d1		; get sort value
	cmp.b	0(a0,d2.w),d1		; compare chars
	bne.s	4$			; if they're not the same, exit loop
	tst.b	d1			; they're the same, now check if they are NULL
	beq.s	3$			; if they are NULL, then exit with a result of 0
	subq.l	#1,d0			; remove one from length
	bne.s	1$			; if length > 0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

3$:	moveq.l	#0,d0			; strings are equal
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

4$:	bhi.s	5$
	moveq.l	#-1,d0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

5$:	moveq.l	#1,d0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

Collate1:
	subq.l	#1,d1
	bne.s	Collate2

	movem.l	a2/d2,-(sp)		; save work registers
	lea	Collate1Table(pc),a0	; conversion table address
	moveq.l	#0,d2			; clear all bits
1$:	move.b	(a1)+,d1		; get next character from 1st string
	move.b	(a2)+,d2		; get next character from 2nd string
2$:	move.b	0(a0,d1.w),d1		; get sort value
	cmp.b	0(a0,d2.w),d1		; compare chars
	bne.s	4$			; if they're not the same, exit loop
	tst.b	d1			; they're the same, now check if they are NULL
	beq.s	3$			; if they are NULL, then exit with a result of 0
	subq.l	#1,d0			; remove one from length
	bne.s	1$			; if length > 0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

3$:	moveq.l	#0,d0			; strings are equal
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

4$:	bhi.s	5$
	moveq.l	#-1,d0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

5$:	moveq.l	#1,d0
	movem.l	(sp)+,a2/d2		; restore saved registers
	rts				; bye

Collate2:
	subq.l	#1,d1
	bne.s	Nothing

	movem.l	a2/d2/d3,-(sp)		; save work registers
	lea	Collate1Table(pc),a0	; conversion table address
	moveq.l	#0,d2			; clear all bits
	moveq.l	#0,d3

1$:	move.b	(a1)+,d1		; get next character from 1st string
	beq.s	11$			; if char is NULL, exit
	move.b	(a2)+,d2		; get next character from 2nd string
	cmp.b	d2,d1			; are the chars different
	bne.s	10$			; if so, then exit loop
	subq.l	#1,d0			; remove one from length
	bne.s	1$			; if length > 0
	movem.l	(sp)+,a2/d2/d3		; restore saved registers
	rts				; bye

11$:	cmp.b	(a2)+,d1		; are the chars different
	bne.s	10$
	movem.l	(sp)+,a2/d2/d3		; restore saved registers
	moveq.l	#0,d0
	rts

10$:	bhi.s	2$
	moveq.l	#-1,d3
	bra.s	4$

2$:	moveq.l	#1,d3
	bra.s	4$

3$:     move.b	(a1)+,d1		; get next character from 1st string
	move.b	(a2)+,d2		; get next character from 2nd string
4$:	move.b	0(a0,d1.w),d1		; get sort value
	cmp.b	0(a0,d2.w),d1		; compare chars
	bne.s	6$			; if they're not the same, exit loop
	tst.b	d1			; they're the same, now check if they are NULL
	beq.s	5$			; if they are NULL, then exit with a result of 0
	subq.l	#1,d0			; remove one from length
	bne.s	3$			; if length > 0

5$:	move.l	d3,d0			; strings are equal
	movem.l	(sp)+,a2/d2/d3		; restore saved registers
	rts				; bye

6$:	bhi.s	7$
	moveq.l	#-1,d0
	movem.l	(sp)+,a2/d2/d3		; restore saved registers
	rts				; bye

7$:	moveq.l	#1,d0
	movem.l	(sp)+,a2/d2/d3		; restore saved registers
	rts				; bye

Nothing:
	moveq	#0,d0
	rts


;---------------------------------------------------------------------------

*	length = StrConvert(driver,string,buffer,bufferSize,type);
*	D0                  A0     A1     A2     D0         D1
*
*	ULONG StrConvert(struct DriverBase *,STRPTR,APTR,ULONG,ULONG);
*

StrConvert:

	move.l	d0,-(sp)		; save buffer size
 	bne.s	XAscii			; if bufferSize > 0, keep going
	addq.l	#4,sp			; clear stack
	rts

XAscii:
	tst.l	d1			; is d1 = 0?
	bne.s	XCollate1		; if not, then not SC_ASCII compare
	move.l	a2,-(sp)		; save a2 cause we need to use it
	lea	LowerToUpper(pc),a0	; conversion table
	bra.s	XEndCollLoop		; enter copy loop

XCollate1:
	subq.l	#1,d1			; remove 1 from compare type
	bne.s	XCollate2		; if d1 is not 0, then not SC_COLLATE1 compare
	move.l	a2,-(sp)		; save a2 cause we need to use it
	lea	Collate1Table(pc),a0    ; conversion table
	bra.s	XEndCollLoop		; enter loop

XCollLoop:
	move.b	(a1)+,d1		; get next character
	beq.s	XAfterCollLoop		; if null, then exit
	move.b	0(a0,d1.w),(a2)+	; convert char to uppercase and put in dest array
XEndCollLoop:
	subq.l	#1,d0			; remove one from bufferSize
	bne.s	XCollLoop		; if bufferSize > 0, keep looping
XAfterCollLoop:
	clr.b	(a2)			; clear last byte
	move.l	(sp)+,a2		; restore original value
	move.l	(sp)+,d1		; obtain original bufferSize value
	sub.l	d0,d1			; subtract current bufferSize value
	move.l	d1,d0			; put result in d0
	rts				; bye

XCollate2:
	subq.l	#1,d1
	bne.s	XNothing
	movem.l	a2/a3/d2,-(sp)		; save these dudes for later

	; get length of input string
	move.l	a1,a0			; address of string
0$:	tst.b	(a0)+
	bne.s	0$
	sub.l	a1,a0			; length = adr of NUL - adr of start - 1
	subq.l	#1,a0
	move.l	a2,a3			; a3 has dest buffer
	add.l	a0,a3			; a3 has dest buffer + length which is
					; the second half of the buffer

	lea	Collate1Table(pc),a0    ; conversion table
	bra.s	2$			; enter loop

1$:	move.b	(a1)+,d1		; get next character
	beq.s	3$			; if null, then exit
	move.b	0(a0,d1.w),d2	 	; convert char to uppercase and put in d2
	move.b  d2,(a2)+		; move converted char to dest
	cmp.b	d2,d1			; does converted char match original?
	beq.s	2$			; if so, then forget it
	move.b	d1,(a3)+		; put original char in second half of buffer
	subq.l	#1,d0			; remove one from bufferSize
	beq.s	3$

2$:	subq.l	#1,d0			; remove one from bufferSize
	bne.s	1$			; if bufferSize > 0, keep looping

3$:	clr.b	(a3)			; clear last byte
	movem.l (sp)+,d2/a3/a2          ; restore original values
	move.l	(sp)+,d1		; obtain original bufferSize value
	sub.l	d0,d1			; subtract current bufferSize value
	move.l	d1,d0			; put result in d0
	rts				; bye

XNothing:
	moveq	#0,d0
	rts

Collate1Table:
C000 DC.B   0
C001 DC.B   1
C002 DC.B   2
C003 DC.B   3
C004 DC.B   4
C005 DC.B   5
C006 DC.B   6
C007 DC.B   7
C008 DC.B   8
C009 DC.B   9
C010 DC.B   10
C011 DC.B   11
C012 DC.B   12
C013 DC.B   13
C014 DC.B   14
C015 DC.B   15
C016 DC.B   16
C017 DC.B   17
C018 DC.B   18
C019 DC.B   19
C020 DC.B   20
C021 DC.B   21
C022 DC.B   22
C023 DC.B   23
C024 DC.B   24
C025 DC.B   25
C026 DC.B   26
C027 DC.B   27
C028 DC.B   28
C029 DC.B   29
C030 DC.B   30
C031 DC.B   31
C032 DC.B   32  ; " "
C033 DC.B   33  ; "!"
C034 DC.B   34  ; '"'
C035 DC.B   35  ; "#"
C036 DC.B   36  ; "$"
C037 DC.B   37  ; "%"
C038 DC.B   38  ; "&"
C039 DC.B   39  ; "'"
C040 DC.B   40  ; "("
C041 DC.B   41  ; ")"
C042 DC.B   42  ; "*"
C043 DC.B   43  ; "+"
C044 DC.B   44  ; ","
C045 DC.B   45  ; "-"
C046 DC.B   46  ; "."
C047 DC.B   47  ; "/"
C048 DC.B   48  ; "0"
C049 DC.B   49  ; "1"
C050 DC.B   50  ; "2"
C051 DC.B   51  ; "3"
C052 DC.B   52  ; "4"
C053 DC.B   53  ; "5"
C054 DC.B   54  ; "6"
C055 DC.B   55  ; "7"
C056 DC.B   56  ; "8"
C057 DC.B   57  ; "9"
C058 DC.B   58  ; ":"
C059 DC.B   59  ; ";"
C060 DC.B   60  ; "<"
C061 DC.B   61  ; "="
C062 DC.B   62  ; ">"
C063 DC.B   63  ; "?"
C064 DC.B   64  ; "@"
C065 DC.B   65  ; "A"
C066 DC.B   66  ; "B"
C067 DC.B   67  ; "C"
C068 DC.B   68  ; "D"
C069 DC.B   69  ; "E"
C070 DC.B   70  ; "F"
C071 DC.B   71  ; "G"
C072 DC.B   72  ; "H"
C073 DC.B   73  ; "I"
C074 DC.B   74  ; "J"
C075 DC.B   75  ; "K"
C076 DC.B   76  ; "L"
C077 DC.B   77  ; "M"
C078 DC.B   78  ; "N"
C079 DC.B   79  ; "O"
C080 DC.B   80  ; "P"
C081 DC.B   81  ; "Q"
C082 DC.B   82  ; "R"
C083 DC.B   83  ; "S"
C084 DC.B   84  ; "T"
C085 DC.B   85  ; "U"
C086 DC.B   86  ; "V"
C087 DC.B   87  ; "W"
C088 DC.B   88  ; "X"
C089 DC.B   89  ; "Y"
C090 DC.B   90  ; "Z"
C091 DC.B   91  ; "["
C092 DC.B   92  ; "\"
C093 DC.B   93  ; "]"
C094 DC.B   94  ; "^"
C095 DC.B   95  ; "_"
C096 DC.B   96  ; "`"
C097 DC.B   65  ; "a"
C098 DC.B   66  ; "b"
C099 DC.B   67  ; "c"
C100 DC.B   68  ; "d"
C101 DC.B   69  ; "e"
C102 DC.B   70  ; "f"
C103 DC.B   71  ; "g"
C104 DC.B   72  ; "h"
C105 DC.B   73  ; "i"
C106 DC.B   74  ; "j"
C107 DC.B   75  ; "k"
C108 DC.B   76  ; "l"
C109 DC.B   77  ; "m"
C110 DC.B   78  ; "n"
C111 DC.B   79  ; "o"
C112 DC.B   80  ; "p"
C113 DC.B   81  ; "q"
C114 DC.B   82  ; "r"
C115 DC.B   83  ; "s"
C116 DC.B   84  ; "t"
C117 DC.B   85  ; "u"
C118 DC.B   86  ; "v"
C119 DC.B   87  ; "w"
C120 DC.B   88  ; "x"
C121 DC.B   89  ; "y"
C122 DC.B   90  ; "z"
C123 DC.B   97  ; "{"
C124 DC.B   98  ; "|"
C125 DC.B   99  ; "}"
C126 DC.B   100 ; "~"
C127 DC.B   101 ; DEL
C128 DC.B   224
C129 DC.B   225
C130 DC.B   226
C131 DC.B   227
C132 DC.B   228
C133 DC.B   229
C134 DC.B   230
C135 DC.B   231
C136 DC.B   232
C137 DC.B   233
C138 DC.B   234
C139 DC.B   235
C140 DC.B   236
C141 DC.B   237
C142 DC.B   238
C143 DC.B   239
C144 DC.B   240
C145 DC.B   241
C146 DC.B   242
C147 DC.B   243
C148 DC.B   244
C149 DC.B   245
C150 DC.B   246
C151 DC.B   247
C152 DC.B   248
C153 DC.B   249
C154 DC.B   250
C155 DC.B   251
C156 DC.B   252
C157 DC.B   253
C158 DC.B   254
C159 DC.B   255
C160 DC.B   32  ; "�" (hard space)
C161 DC.B   33  ; "�"
C162 DC.B   36  ; "�"
C163 DC.B   36  ; "�"
C164 DC.B   103 ; "�"
C165 DC.B   104 ; "�"
C166 DC.B   105 ; "�"
C167 DC.B   83  ; "�"
C168 DC.B   106 ; "�"
C169 DC.B   107 ; "�"
C170 DC.B   108 ; "�"
C171 DC.B   34  ; "�"
C172 DC.B   109 ; "�"
C173 DC.B   110 ; "�"
C174 DC.B   111 ; "�"
C175 DC.B   112 ; "�"
C176 DC.B   113 ; "�"
C177 DC.B   114 ; "�"
C178 DC.B   115 ; "�"
C179 DC.B   116 ; "�"
C180 DC.B   117 ; "�"
C181 DC.B   118 ; "�"
C182 DC.B   119 ; "�"
C183 DC.B   120 ; "�"
C184 DC.B   121 ; "�"
C185 DC.B   122 ; "�"
C186 DC.B   123 ; "�"
C187 DC.B   34  ; "�"
C188 DC.B   124 ; "�"
C189 DC.B   125 ; "�"
C190 DC.B   126 ; "�"
C191 DC.B   63  ; "�"
C192 DC.B   65  ; "�"
C193 DC.B   65  ; "�"
C194 DC.B   65  ; "�"
C195 DC.B   65  ; "�"
C196 DC.B   65  ; "�"
C197 DC.B   65  ; "�"
C198 DC.B   65  ; "�"
C199 DC.B   67  ; "�"
C200 DC.B   69  ; "�"
C201 DC.B   69  ; "�"
C202 DC.B   69  ; "�"
C203 DC.B   69  ; "�"
C204 DC.B   73  ; "�"
C205 DC.B   73  ; "�"
C206 DC.B   73  ; "�"
C207 DC.B   73  ; "�"
C208 DC.B   68  ; "�"
C209 DC.B   78  ; "�"
C210 DC.B   79  ; "�"
C211 DC.B   79  ; "�"
C212 DC.B   79  ; "�"
C213 DC.B   79  ; "�"
C214 DC.B   79  ; "�"
C215 DC.B   42  ; "�"
C216 DC.B   79  ; "�"
C217 DC.B   85  ; "�"
C218 DC.B   85  ; "�"
C219 DC.B   85  ; "�"
C220 DC.B   85  ; "�"
C221 DC.B   89  ; "�"
C222 DC.B   80  ; "�"
C223 DC.B   89  ; "�"
C224 DC.B   65  ; "�"
C225 DC.B   65  ; "�"
C226 DC.B   65  ; "�"
C227 DC.B   65  ; "�"
C228 DC.B   65  ; "�"
C229 DC.B   65  ; "�"
C230 DC.B   65  ; "�"
C231 DC.B   67  ; "�"
C232 DC.B   69  ; "�"
C233 DC.B   69  ; "�"
C234 DC.B   69  ; "�"
C235 DC.B   69  ; "�"
C236 DC.B   73  ; "�"
C237 DC.B   73  ; "�"
C238 DC.B   73  ; "�"
C239 DC.B   73  ; "�"
C240 DC.B   68  ; "�"
C241 DC.B   78  ; "�"
C242 DC.B   79  ; "�"
C243 DC.B   79  ; "�"
C244 DC.B   79  ; "�"
C245 DC.B   79  ; "�"
C246 DC.B   79  ; "�"
C247 DC.B   47  ; "�"
C248 DC.B   79  ; "�"
C249 DC.B   85  ; "�"
C250 DC.B   85  ; "�"
C251 DC.B   85  ; "�"
C252 DC.B   85  ; "�"
C253 DC.B   89  ; "�"
C254 DC.B   80  ; "�"
C255 DC.B   89  ; "�"

;---------------------------------------------------------------------------

*	char = ConvToUpper(driver,character);
*	D0	           A0     D0
*
*	ULONG ConvToUpper(struct DriverBase *,ULONG);
*
*   NOTE
*	This function requires a full 32-bit character be passed-in in order
*	to support multi-byte character sets.
*

ConvToUpper:
	move.b	LowerToUpper(pc,d0.w),d0
	rts

LowerToUpper:
L000 DC.B	0
L001 DC.B	1
L002 DC.B	2
L003 DC.B	3
L004 DC.B	4
L005 DC.B	5
L006 DC.B	6
L007 DC.B	7
L008 DC.B	8
L009 DC.B	9
L010 DC.B	10
L011 DC.B	11
L012 DC.B	12
L013 DC.B	13
L014 DC.B	14
L015 DC.B	15
L016 DC.B	16
L017 DC.B	17
L018 DC.B	18
L019 DC.B	19
L020 DC.B	20
L021 DC.B	21
L022 DC.B	22
L023 DC.B	23
L024 DC.B	24
L025 DC.B	25
L026 DC.B	26
L027 DC.B	27
L028 DC.B	28
L029 DC.B	29
L030 DC.B	30
L031 DC.B	31
L032 DC.B	" "
L033 DC.B	"!"
L034 DC.B	'"'
L035 DC.B	"#"
L036 DC.B       "$"
L037 DC.B       "%"
L038 DC.B       "&"
L039 DC.B       "'"
L040 DC.B       "("
L041 DC.B       ")"
L042 DC.B       "*"
L043 DC.B       "+"
L044 DC.B       ","
L045 DC.B       "-"
L046 DC.B       "."
L047 DC.B       "/"
L048 DC.B       "0"
L049 DC.B       "1"
L050 DC.B       "2"
L051 DC.B       "3"
L052 DC.B       "4"
L053 DC.B       "5"
L054 DC.B       "6"
L055 DC.B       "7"
L056 DC.B       "8"
L057 DC.B       "9"
L058 DC.B       ":"
L059 DC.B       ";"
L060 DC.B       "<"
L061 DC.B       "="
L062 DC.B       ">"
L063 DC.B       "?"
L064 DC.B       "@"
L065 DC.B       "A"
L066 DC.B       "B"
L067 DC.B       "C"
L068 DC.B       "D"
L069 DC.B       "E"
L070 DC.B       "F"
L071 DC.B       "G"
L072 DC.B       "H"
L073 DC.B       "I"
L074 DC.B       "J"
L075 DC.B       "K"
L076 DC.B       "L"
L077 DC.B       "M"
L078 DC.B       "N"
L079 DC.B       "O"
L080 DC.B       "P"
L081 DC.B       "Q"
L082 DC.B       "R"
L083 DC.B       "S"
L084 DC.B       "T"
L085 DC.B       "U"
L086 DC.B       "V"
L087 DC.B       "W"
L088 DC.B       "X"
L089 DC.B       "Y"
L090 DC.B       "Z"
L091 DC.B       "["
L092 DC.B       "\"
L093 DC.B       "]"
L094 DC.B       "^"
L095 DC.B       "_"
L096 DC.B       "`"
L097 DC.B       "A"
L098 DC.B       "B"
L099 DC.B       "C"
L100 DC.B       "D"
L101 DC.B       "E"
L102 DC.B       "F"
L103 DC.B       "G"
L104 DC.B       "H"
L105 DC.B       "I"
L106 DC.B       "J"
L107 DC.B       "K"
L108 DC.B       "L"
L109 DC.B       "M"
L110 DC.B       "N"
L111 DC.B       "O"
L112 DC.B       "P"
L113 DC.B       "Q"
L114 DC.B       "R"
L115 DC.B       "S"
L116 DC.B       "T"
L117 DC.B       "U"
L118 DC.B       "V"
L119 DC.B       "W"
L120 DC.B       "X"
L121 DC.B       "Y"
L122 DC.B       "Z"
L123 DC.B       "{"
L124 DC.B       "|"
L125 DC.B       "}"
L126 DC.B       "~"
L127 DC.B	127
L128 DC.B	128
L129 DC.B	129
L130 DC.B	130
L131 DC.B	131
L132 DC.B	132
L133 DC.B	133
L134 DC.B	134
L135 DC.B	135
L136 DC.B	136
L137 DC.B	137
L138 DC.B	138
L139 DC.B	139
L140 DC.B	140
L141 DC.B	141
L142 DC.B	142
L143 DC.B	143
L144 DC.B	144
L145 DC.B	145
L146 DC.B	146
L147 DC.B	147
L148 DC.B	148
L149 DC.B	149
L150 DC.B	150
L151 DC.B	151
L152 DC.B	152
L153 DC.B	153
L154 DC.B	154
L155 DC.B	155
L156 DC.B	156
L157 DC.B	157
L158 DC.B	158
L159 DC.B	159
L160 DC.B       "�"
L161 DC.B       "�"
L162 DC.B       "�"
L163 DC.B       "�"
L164 DC.B       "�"
L165 DC.B       "�"
L166 DC.B       "�"
L167 DC.B       "�"
L168 DC.B       "�"
L169 DC.B       "�"
L170 DC.B       "�"
L171 DC.B       "�"
L172 DC.B       "�"
L173 DC.B       "�"
L174 DC.B       "�"
L175 DC.B       "�"
L176 DC.B       "�"
L177 DC.B       "�"
L178 DC.B       "�"
L179 DC.B       "�"
L180 DC.B       "�"
L181 DC.B       "�"
L182 DC.B       "�"
L183 DC.B       "�"
L184 DC.B       "�"
L185 DC.B       "�"
L186 DC.B       "�"
L187 DC.B       "�"
L188 DC.B       "�"
L189 DC.B       "�"
L190 DC.B       "�"
L191 DC.B       "�"
L192 DC.B       "�"
L193 DC.B       "�"
L194 DC.B       "�"
L195 DC.B       "�"
L196 DC.B       "�"
L197 DC.B       "�"
L198 DC.B       "�"
L199 DC.B       "�"
L200 DC.B       "�"
L201 DC.B       "�"
L202 DC.B       "�"
L203 DC.B       "�"
L204 DC.B       "�"
L205 DC.B       "�"
L206 DC.B       "�"
L207 DC.B       "�"
L208 DC.B       "�"
L209 DC.B       "�"
L210 DC.B       "�"
L211 DC.B       "�"
L212 DC.B       "�"
L213 DC.B       "�"
L214 DC.B       "�"
L215 DC.B       "�"
L216 DC.B       "�"
L217 DC.B       "�"
L218 DC.B       "�"
L219 DC.B       "�"
L220 DC.B       "�"
L221 DC.B       "�"
L222 DC.B       "�"
L223 DC.B       "�"
L224 DC.B       "�"
L225 DC.B       "�"
L226 DC.B       "�"
L227 DC.B       "�"
L228 DC.B       "�"
L229 DC.B       "�"
L230 DC.B       "�"
L231 DC.B       "�"
L232 DC.B       "�"
L233 DC.B       "�"
L234 DC.B       "�"
L235 DC.B       "�"
L236 DC.B       "�"
L237 DC.B       "�"
L238 DC.B       "�"
L239 DC.B       "�"
L240 DC.B       "�"
L241 DC.B       "�"
L242 DC.B       "�"
L243 DC.B       "�"
L244 DC.B       "�"
L245 DC.B       "�"
L246 DC.B       "�"
L247 DC.B       "�"
L248 DC.B       "�"
L249 DC.B       "�"
L250 DC.B       "�"
L251 DC.B       "�"
L252 DC.B       "�"
L253 DC.B       "�"
L254 DC.B       "�"
L255 DC.B       "�"

;---------------------------------------------------------------------------

*	char = ConvToLower(driver,character);
*	D0	           A0     D0
*
*	ULONG ConvToLower(struct DriverBase *,ULONG);
*
*   NOTE
*	This function requires a full 32-bit character be passed-in in order
*	to support multi-byte character sets.
*

ConvToLower:
	move.b	UpperToLower(pc,d0.w),d0
	rts

UpperToLower:
U000 DC.B	0
U001 DC.B	1
U002 DC.B	2
U003 DC.B	3
U004 DC.B	4
U005 DC.B	5
U006 DC.B	6
U007 DC.B	7
U008 DC.B	8
U009 DC.B	9
U010 DC.B	10
U011 DC.B	11
U012 DC.B	12
U013 DC.B	13
U014 DC.B	14
U015 DC.B	15
U016 DC.B	16
U017 DC.B	17
U018 DC.B	18
U019 DC.B	19
U020 DC.B	20
U021 DC.B	21
U022 DC.B	22
U023 DC.B	23
U024 DC.B	24
U025 DC.B	25
U026 DC.B	26
U027 DC.B	27
U028 DC.B	28
U029 DC.B	29
U030 DC.B	30
U031 DC.B	31
U032 DC.B	" "
U033 DC.B	"!"
U034 DC.B	'"'
U035 DC.B	"#"
U036 DC.B       "$"
U037 DC.B       "%"
U038 DC.B       "&"
U039 DC.B       "'"
U040 DC.B       "("
U041 DC.B       ")"
U042 DC.B       "*"
U043 DC.B       "+"
U044 DC.B       ","
U045 DC.B       "-"
U046 DC.B       "."
U047 DC.B       "/"
U048 DC.B       "0"
U049 DC.B       "1"
U050 DC.B       "2"
U051 DC.B       "3"
U052 DC.B       "4"
U053 DC.B       "5"
U054 DC.B       "6"
U055 DC.B       "7"
U056 DC.B       "8"
U057 DC.B       "9"
U058 DC.B       ":"
U059 DC.B       ";"
U060 DC.B       "<"
U061 DC.B       "="
U062 DC.B       ">"
U063 DC.B       "?"
U064 DC.B       "@"
U065 DC.B       "a"
U066 DC.B       "b"
U067 DC.B       "c"
U068 DC.B       "d"
U069 DC.B       "e"
U070 DC.B       "f"
U071 DC.B       "g"
U072 DC.B       "h"
U073 DC.B       "i"
U074 DC.B       "j"
U075 DC.B       "k"
U076 DC.B       "l"
U077 DC.B       "m"
U078 DC.B       "n"
U079 DC.B       "o"
U080 DC.B       "p"
U081 DC.B       "q"
U082 DC.B       "r"
U083 DC.B       "s"
U084 DC.B       "t"
U085 DC.B       "u"
U086 DC.B       "v"
U087 DC.B       "w"
U088 DC.B       "x"
U089 DC.B       "y"
U090 DC.B       "z"
U091 DC.B       "["
U092 DC.B       "\"
U093 DC.B       "]"
U094 DC.B       "^"
U095 DC.B       "_"
U096 DC.B       "`"
U097 DC.B       "a"
U098 DC.B       "b"
U099 DC.B       "c"
U100 DC.B       "d"
U101 DC.B       "e"
U102 DC.B       "f"
U103 DC.B       "g"
U104 DC.B       "h"
U105 DC.B       "i"
U106 DC.B       "j"
U107 DC.B       "k"
U108 DC.B       "l"
U109 DC.B       "m"
U110 DC.B       "n"
U111 DC.B       "o"
U112 DC.B       "p"
U113 DC.B       "q"
U114 DC.B       "r"
U115 DC.B       "s"
U116 DC.B       "t"
U117 DC.B       "u"
U118 DC.B       "v"
U119 DC.B       "w"
U120 DC.B       "x"
U121 DC.B       "y"
U122 DC.B       "z"
U123 DC.B       "{"
U124 DC.B       "|"
U125 DC.B       "}"
U126 DC.B       "~"
U127 DC.B	127
U128 DC.B	128
U129 DC.B	129
U130 DC.B	130
U131 DC.B	131
U132 DC.B	132
U133 DC.B	133
U134 DC.B	134
U135 DC.B	135
U136 DC.B	136
U137 DC.B	137
U138 DC.B	138
U139 DC.B	139
U140 DC.B	140
U141 DC.B	141
U142 DC.B	142
U143 DC.B	143
U144 DC.B	144
U145 DC.B	145
U146 DC.B	146
U147 DC.B	147
U148 DC.B	148
U149 DC.B	149
U150 DC.B	150
U151 DC.B	151
U152 DC.B	152
U153 DC.B	153
U154 DC.B	154
U155 DC.B	155
U156 DC.B	156
U157 DC.B	157
U158 DC.B	158
U159 DC.B	159
U160 DC.B       "�"
U161 DC.B       "�"
U162 DC.B       "�"
U163 DC.B       "�"
U164 DC.B       "�"
U165 DC.B       "�"
U166 DC.B       "�"
U167 DC.B       "�"
U168 DC.B       "�"
U169 DC.B       "�"
U170 DC.B       "�"
U171 DC.B       "�"
U172 DC.B       "�"
U173 DC.B       "�"
U174 DC.B       "�"
U175 DC.B       "�"
U176 DC.B       "�"
U177 DC.B       "�"
U178 DC.B       "�"
U179 DC.B       "�"
U180 DC.B       "�"
U181 DC.B       "�"
U182 DC.B       "�"
U183 DC.B       "�"
U184 DC.B       "�"
U185 DC.B       "�"
U186 DC.B       "�"
U187 DC.B       "�"
U188 DC.B       "�"
U189 DC.B       "�"
U190 DC.B       "�"
U191 DC.B       "�"
U192 DC.B       "�"
U193 DC.B       "�"
U194 DC.B       "�"
U195 DC.B       "�"
U196 DC.B       "�"
U197 DC.B       "�"
U198 DC.B       "�"
U199 DC.B       "�"
U200 DC.B       "�"
U201 DC.B       "�"
U202 DC.B       "�"
U203 DC.B       "�"
U204 DC.B       "�"
U205 DC.B       "�"
U206 DC.B       "�"
U207 DC.B       "�"
U208 DC.B       "�"
U209 DC.B       "�"
U210 DC.B       "�"
U211 DC.B       "�"
U212 DC.B       "�"
U213 DC.B       "�"
U214 DC.B       "�"
U215 DC.B       "�"
U216 DC.B       "�"
U217 DC.B       "�"
U218 DC.B       "�"
U219 DC.B       "�"
U220 DC.B       "�"
U221 DC.B       "�"
U222 DC.B       "�"
U223 DC.B       "�"
U224 DC.B       "�"
U225 DC.B       "�"
U226 DC.B       "�"
U227 DC.B       "�"
U228 DC.B       "�"
U229 DC.B       "�"
U230 DC.B       "�"
U231 DC.B       "�"
U232 DC.B       "�"
U233 DC.B       "�"
U234 DC.B       "�"
U235 DC.B       "�"
U236 DC.B       "�"
U237 DC.B       "�"
U238 DC.B       "�"
U239 DC.B       "�"
U240 DC.B       "�"
U241 DC.B       "�"
U242 DC.B       "�"
U243 DC.B       "�"
U244 DC.B       "�"
U245 DC.B       "�"
U246 DC.B       "�"
U247 DC.B       "�"
U248 DC.B       "�"
U249 DC.B       "�"
U250 DC.B       "�"
U251 DC.B       "�"
U252 DC.B       "�"
U253 DC.B       "�"
U254 DC.B       "�"
U255 DC.B       "�"

;---------------------------------------------------------------------------

*	state = IsXXXX(driver,character);
*	D0	       A0     D0
*
*	BOOL IsXXXX(struct DriverBase *,ULONG);
*
*   NOTE
*	These functions require full 32-bit characters be passed-in in order
*	to support multi-byte character sets.
*

* Order of these flags are important!
CNTRL  EQU 0
XDIGIT EQU 1
SPACE  EQU 2
PUNCT  EQU 3
DIGIT  EQU 4
UPPER  EQU 5
LOWER  EQU 6

CNTRLF  EQU 1
XDIGITF EQU 2
SPACEF  EQU 4
PUNCTF  EQU 8
DIGITF  EQU 16
UPPERF  EQU 32
LOWERF  EQU 64

IsAlpha:
	moveq	#UPPERF,d1
	cmp.b	CharAttr(pc,d0.w),d1		 ; >= UPPERF means either UPPER or LOWER
	sls	d0
	rts

IsAlNum:
	moveq	#DIGITF,d1
	cmp.b	CharAttr(pc,d0.w),d1
	sls	d0
	rts

IsGraph:
	moveq   #PUNCTF,d1
	cmp.b	CharAttr(pc,d0.w),d1
	sls	d0
	rts

IsPrint:
	moveq	#SPACEF,d1
	cmp.b	CharAttr(pc,d0.w),d1
	sls	d0
	rts

IsCntrl:
	btst	#CNTRL,CharAttr(pc,d0.w)
	sne	d0
	rts

IsDigit:
	btst	#DIGIT,CharAttr(pc,d0.w)
	sne	d0
	rts

IsLower:
	btst	#LOWER,CharAttr(pc,d0.w)
	sne	d0
	rts

IsPunct:
	btst	#PUNCT,CharAttr(pc,d0.w)
	sne	d0
	rts

IsSpace:
	btst	#SPACE,CharAttr(pc,d0.w)
	sne	d0
	rts

IsUpper:
	btst	#UPPER,CharAttr(pc,d0.w)
	sne	d0
	rts

IsXDigit:
	btst	#XDIGIT,CharAttr(pc,d0.w)
	sne	d0
	rts

;---------------------------------------------------------------------------

CharAttr:
A000 DC.B	CNTRLF
A001 DC.B	CNTRLF
A002 DC.B	CNTRLF
A003 DC.B	CNTRLF
A004 DC.B	CNTRLF
A005 DC.B	CNTRLF
A006 DC.B	CNTRLF
A007 DC.B	CNTRLF
A008 DC.B	CNTRLF
A009 DC.B	CNTRLF!SPACEF
A010 DC.B	CNTRLF!SPACEF
A011 DC.B	CNTRLF!SPACEF
A012 DC.B	CNTRLF|SPACEF
A013 DC.B	CNTRLF!SPACEF
A014 DC.B	CNTRLF
A015 DC.B	CNTRLF
A016 DC.B	CNTRLF
A017 DC.B	CNTRLF
A018 DC.B	CNTRLF
A019 DC.B	CNTRLF
A020 DC.B	CNTRLF
A021 DC.B	CNTRLF
A022 DC.B	CNTRLF
A023 DC.B	CNTRLF
A024 DC.B	CNTRLF
A025 DC.B	CNTRLF
A026 DC.B	CNTRLF
A027 DC.B	CNTRLF
A028 DC.B	CNTRLF
A029 DC.B	CNTRLF
A030 DC.B	CNTRLF
A031 DC.B	CNTRLF
A032 DC.B	SPACEF		; " "
A033 DC.B	PUNCTF		; "!"
A034 DC.B	PUNCTF		; '"'
A035 DC.B	PUNCTF		; "#"
A036 DC.B       PUNCTF		; "$"
A037 DC.B       PUNCTF		; "%"
A038 DC.B       PUNCTF		; "&"
A039 DC.B       PUNCTF		; "'"
A040 DC.B       PUNCTF		; "("
A041 DC.B       PUNCTF		; ")"
A042 DC.B       PUNCTF		; "*"
A043 DC.B       PUNCTF		; "+"
A044 DC.B       PUNCTF		; ","
A045 DC.B       PUNCTF		; "-"
A046 DC.B       PUNCTF		; "."
A047 DC.B       PUNCTF		; "/"
A048 DC.B       DIGITF!XDIGITF  ; "0"
A049 DC.B       DIGITF!XDIGITF  ; "1"
A050 DC.B       DIGITF!XDIGITF  ; "2"
A051 DC.B       DIGITF!XDIGITF  ; "3"
A052 DC.B       DIGITF!XDIGITF  ; "4"
A053 DC.B       DIGITF!XDIGITF  ; "5"
A054 DC.B       DIGITF!XDIGITF  ; "6"
A055 DC.B       DIGITF!XDIGITF  ; "7"
A056 DC.B       DIGITF!XDIGITF  ; "8"
A057 DC.B       DIGITF!XDIGITF  ; "9"
A058 DC.B       PUNCTF		; ":"
A059 DC.B       PUNCTF		; ";"
A060 DC.B       PUNCTF		; "<"
A061 DC.B       PUNCTF		; "="
A062 DC.B       PUNCTF		; ">"
A063 DC.B       PUNCTF		; "?"
A064 DC.B       PUNCTF		; "@"
A065 DC.B       UPPERF!XDIGITF  ; "A"
A066 DC.B       UPPERF!XDIGITF  ; "B"
A067 DC.B       UPPERF!XDIGITF  ; "C"
A068 DC.B       UPPERF!XDIGITF  ; "D"
A069 DC.B       UPPERF!XDIGITF  ; "E"
A070 DC.B       UPPERF!XDIGITF  ; "F"
A071 DC.B       UPPERF 		; "G"
A072 DC.B       UPPERF 		; "H"
A073 DC.B       UPPERF 		; "I"
A074 DC.B       UPPERF 		; "J"
A075 DC.B       UPPERF 		; "K"
A076 DC.B       UPPERF 		; "L"
A077 DC.B       UPPERF 		; "M"
A078 DC.B       UPPERF 		; "N"
A079 DC.B       UPPERF 		; "O"
A080 DC.B       UPPERF 		; "P"
A081 DC.B       UPPERF 		; "Q"
A082 DC.B       UPPERF 		; "R"
A083 DC.B       UPPERF 		; "S"
A084 DC.B       UPPERF 		; "T"
A085 DC.B       UPPERF 		; "U"
A086 DC.B       UPPERF 		; "V"
A087 DC.B       UPPERF 		; "W"
A088 DC.B       UPPERF 		; "X"
A089 DC.B       UPPERF 		; "Y"
A090 DC.B       UPPERF 		; "Z"
A091 DC.B       PUNCTF		; "["
A092 DC.B       PUNCTF		; "\"
A093 DC.B       PUNCTF		; "]"
A094 DC.B       PUNCTF		; "^"
A095 DC.B       PUNCTF		; "_"
A096 DC.B       PUNCTF		; "`"
A097 DC.B       LOWERF!XDIGITF  ; "a"
A098 DC.B       LOWERF!XDIGITF  ; "b"
A099 DC.B       LOWERF!XDIGITF  ; "c"
A100 DC.B       LOWERF!XDIGITF  ; "d"
A101 DC.B       LOWERF!XDIGITF  ; "e"
A102 DC.B       LOWERF!XDIGITF  ; "f"
A103 DC.B       LOWERF		; "g"
A104 DC.B       LOWERF		; "h"
A105 DC.B       LOWERF		; "i"
A106 DC.B       LOWERF		; "j"
A107 DC.B       LOWERF		; "k"
A108 DC.B       LOWERF		; "l"
A109 DC.B       LOWERF		; "m"
A110 DC.B       LOWERF		; "n"
A111 DC.B       LOWERF		; "o"
A112 DC.B       LOWERF		; "p"
A113 DC.B       LOWERF		; "q"
A114 DC.B       LOWERF		; "r"
A115 DC.B       LOWERF		; "s"
A116 DC.B       LOWERF		; "t"
A117 DC.B       LOWERF		; "u"
A118 DC.B       LOWERF		; "v"
A119 DC.B       LOWERF		; "w"
A120 DC.B       LOWERF		; "x"
A121 DC.B       LOWERF		; "y"
A122 DC.B       LOWERF		; "z"
A123 DC.B       PUNCTF		; "{"
A124 DC.B       PUNCTF          ; "|"
A125 DC.B       PUNCTF		; "}"
A126 DC.B       PUNCTF		; "~"
A127 DC.B	CNTRLF
A128 DC.B	CNTRLF
A129 DC.B	CNTRLF
A130 DC.B	CNTRLF
A131 DC.B	CNTRLF
A132 DC.B	CNTRLF
A133 DC.B	CNTRLF
A134 DC.B	CNTRLF
A135 DC.B	CNTRLF
A136 DC.B	CNTRLF
A137 DC.B	CNTRLF
A138 DC.B	CNTRLF
A139 DC.B	CNTRLF
A140 DC.B	CNTRLF
A141 DC.B	CNTRLF
A142 DC.B	CNTRLF
A143 DC.B	CNTRLF
A144 DC.B	CNTRLF
A145 DC.B	CNTRLF
A146 DC.B	CNTRLF
A147 DC.B	CNTRLF
A148 DC.B	CNTRLF
A149 DC.B	CNTRLF
A150 DC.B	CNTRLF
A151 DC.B	CNTRLF
A152 DC.B	CNTRLF
A153 DC.B	CNTRLF
A154 DC.B	CNTRLF
A155 DC.B	CNTRLF
A156 DC.B	CNTRLF
A157 DC.B	CNTRLF
A158 DC.B	CNTRLF
A159 DC.B	CNTRLF
A160 DC.B       SPACEF     ; "�"
A161 DC.B       PUNCTF     ; "�"
A162 DC.B       PUNCTF     ; "�"
A163 DC.B       PUNCTF     ; "�"
A164 DC.B       PUNCTF     ; "�"
A165 DC.B       PUNCTF     ; "�"
A166 DC.B       PUNCTF     ; "�"
A167 DC.B       PUNCTF     ; "�"
A168 DC.B       PUNCTF     ; "�"
A169 DC.B       PUNCTF     ; "�"
A170 DC.B       PUNCTF     ; "�"
A171 DC.B       PUNCTF     ; "�"
A172 DC.B       PUNCTF     ; "�"
A173 DC.B       PUNCTF     ; "�"
A174 DC.B       PUNCTF     ; "�"
A175 DC.B       PUNCTF     ; "�"
A176 DC.B       PUNCTF     ; "�"
A177 DC.B       PUNCTF     ; "�"
A178 DC.B       PUNCTF     ; "�"
A179 DC.B       PUNCTF     ; "�"
A180 DC.B       PUNCTF     ; "�"
A181 DC.B       PUNCTF     ; "�"
A182 DC.B       PUNCTF     ; "�"
A183 DC.B       PUNCTF     ; "�"
A184 DC.B       PUNCTF     ; "�"
A185 DC.B       PUNCTF     ; "�"
A186 DC.B       PUNCTF     ; "�"
A187 DC.B       PUNCTF     ; "�"
A188 DC.B       PUNCTF     ; "�"
A189 DC.B       PUNCTF     ; "�"
A190 DC.B       PUNCTF     ; "�"
A191 DC.B       PUNCTF     ; "�"
A192 DC.B       UPPERF     ; "�"
A193 DC.B       UPPERF     ; "�"
A194 DC.B       UPPERF     ; "�"
A195 DC.B       UPPERF     ; "�"
A196 DC.B       UPPERF     ; "�"
A197 DC.B       UPPERF     ; "�"
A198 DC.B       UPPERF     ; "�"
A199 DC.B       UPPERF     ; "�"
A200 DC.B       UPPERF     ; "�"
A201 DC.B       UPPERF     ; "�"
A202 DC.B       UPPERF     ; "�"
A203 DC.B       UPPERF     ; "�"
A204 DC.B       UPPERF     ; "�"
A205 DC.B       UPPERF     ; "�"
A206 DC.B       UPPERF     ; "�"
A207 DC.B       UPPERF     ; "�"
A208 DC.B       UPPERF     ; "�"
A209 DC.B       UPPERF     ; "�"
A210 DC.B       UPPERF     ; "�"
A211 DC.B       UPPERF     ; "�"
A212 DC.B       UPPERF     ; "�"
A213 DC.B       UPPERF     ; "�"
A214 DC.B       UPPERF     ; "�"
A215 DC.B       UPPERF     ; "�"
A216 DC.B       UPPERF     ; "�"
A217 DC.B       UPPERF     ; "�"
A218 DC.B       UPPERF     ; "�"
A219 DC.B       UPPERF     ; "�"
A220 DC.B       UPPERF     ; "�"
A221 DC.B       UPPERF     ; "�"
A222 DC.B       UPPERF     ; "�"
A223 DC.B       UPPERF!LOWERF ; "�"
A224 DC.B       LOWERF     ; "�"
A225 DC.B       LOWERF     ; "�"
A226 DC.B       LOWERF     ; "�"
A227 DC.B       LOWERF     ; "�"
A228 DC.B       LOWERF     ; "�"
A229 DC.B       LOWERF     ; "�"
A230 DC.B       LOWERF     ; "�"
A231 DC.B       LOWERF     ; "�"
A232 DC.B       LOWERF     ; "�"
A233 DC.B       LOWERF     ; "�"
A234 DC.B       LOWERF     ; "�"
A235 DC.B       LOWERF     ; "�"
A236 DC.B       LOWERF     ; "�"
A237 DC.B       LOWERF     ; "�"
A238 DC.B       LOWERF     ; "�"
A239 DC.B       LOWERF     ; "�"
A240 DC.B       LOWERF     ; "�"
A241 DC.B       LOWERF     ; "�"
A242 DC.B       LOWERF     ; "�"
A243 DC.B       LOWERF     ; "�"
A244 DC.B       LOWERF     ; "�"
A245 DC.B       LOWERF     ; "�"
A246 DC.B       LOWERF     ; "�"
A247 DC.B       PUNCTF     ; "�"
A248 DC.B       LOWERF     ; "�"
A249 DC.B       LOWERF     ; "�"
A250 DC.B       LOWERF     ; "�"
A251 DC.B       LOWERF     ; "�"
A252 DC.B       LOWERF     ; "�"
A253 DC.B       LOWERF     ; "�"
A254 DC.B       LOWERF     ; "�"
A255 DC.B       LOWERF     ; "�"

;---------------------------------------------------------------------------

Strings:
S000 DC.B       "",0
S001 DC.B	"Sunday",0
S002 DC.B	"Monday",0
S003 DC.B	"Tuesday",0
S004 DC.B	"Wednesday",0
S005 DC.B	"Thursday",0
S006 DC.B	"Friday",0
S007 DC.B	"Saturday",0

S008 DC.B	"Sun",0
S009 DC.B	"Mon",0
S010 DC.B	"Tue",0
S011 DC.B	"Wed",0
S012 DC.B	"Thu",0
S013 DC.B	"Fri",0
S014 DC.B	"Sat",0

S015 DC.B	"January",0
S016 DC.B	"February",0
S017 DC.B	"March",0
S018 DC.B	"April",0
S019 DC.B	"May",0
S020 DC.B	"June",0
S021 DC.B	"July",0
S022 DC.B	"August",0
S023 DC.B	"September",0
S024 DC.B	"October",0
S025 DC.B	"November",0
S026 DC.B	"December",0

S027 DC.B	"Jan",0
S028 DC.B	"Feb",0
S029 DC.B	"Mar",0
S030 DC.B	"Apr",0
S031 DC.B	"May",0
S032 DC.B	"Jun",0
S033 DC.B	"Jul",0
S034 DC.B	"Aug",0
S035 DC.B	"Sep",0
S036 DC.B	"Oct",0
S037 DC.B	"Nov",0
S038 DC.B	"Dec",0

S039 DC.B	"Yes",0
S040 DC.B	"No",0

S041 DC.B	"AM",0
S042 DC.B	"PM",0

S043 DC.B	"-",0
S044 DC.B	"-",0

S045 DC.B	'"',0
S046 DC.B	'"',0

S047 DC.B	"Yesterday",0
S048 DC.B	"Today",0
S049 DC.B	"Tomorrow",0
S050 DC.B	"Future",0

;---------------------------------------------------------------------------

*	string = GetLocaleStr(driver,stringNum);
*	D0                    A0     D0
*
*	STRPTR GetLocaleStr(struct DriverBase *,ULONG);
*

GetLocaleStr:
	cmp.l	#51,d0     ; 50 being the maximum # of strings
	bcc.s	1$
	asl.w	#2,d0
	move.l  StringTable(pc,d0.w),d0
	rts

1$	moveq	#0,d0
	rts

StringTable:
P000 DC.L S000
P001 DC.L S001
P002 DC.L S002
P003 DC.L S003
P004 DC.L S004
P005 DC.L S005
P006 DC.L S006
P007 DC.L S007
P008 DC.L S008
P009 DC.L S009
P010 DC.L S010
P011 DC.L S011
P012 DC.L S012
P013 DC.L S013
P014 DC.L S014
P015 DC.L S015
P016 DC.L S016
P017 DC.L S017
P018 DC.L S018
P019 DC.L S019
P020 DC.L S020
P021 DC.L S021
P022 DC.L S022
P023 DC.L S023
P024 DC.L S024
P025 DC.L S025
P026 DC.L S026
P027 DC.L S027
P028 DC.L S028
P029 DC.L S029
P030 DC.L S030
P031 DC.L S031
P032 DC.L S032
P033 DC.L S033
P034 DC.L S034
P035 DC.L S035
P036 DC.L S036
P037 DC.L S037
P038 DC.L S038
P039 DC.L S039
P040 DC.L S040
P041 DC.L S041
P042 DC.L S042
P043 DC.L S043
P044 DC.L S044
P045 DC.L S045
P046 DC.L S046
P047 DC.L S047
P048 DC.L S048
P049 DC.L S049
P050 DC.L S050

;---------------------------------------------------------------------------

ENDTAG:

;---------------------------------------------------------------------------

	END
