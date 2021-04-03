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

; classinit.asm
;
;       OPTIMON

	SECTION text,code

;---------------------------------------------------------------------------

        NOLIST

        INCLUDE "exec/types.i"
        INCLUDE "exec/libraries.i"
        INCLUDE "exec/lists.i"
        INCLUDE "exec/alerts.i"
        INCLUDE "exec/initializers.i"
        INCLUDE "exec/resident.i"
        INCLUDE "libraries/dos.i"

        INCLUDE "cdxl_rev.i"
        INCLUDE "classbase.i"

        LIST

;---------------------------------------------------------------------------

	XREF	_LibInit
	XREF	_LibOpen
	XREF	_LibClose
	XREF	_LibExpunge

	XREF	_ObtainCDXLEngine

;---------------------------------------------------------------------------

        XDEF    LibReserved

;---------------------------------------------------------------------------

; First executable location, must return an error to the caller
Start:
        moveq   #-1,d0
        rts

;-----------------------------------------------------------------------

ROMTAG:
        DC.W    RTC_MATCHWORD           ; UWORD RT_MATCHWORD
        DC.L    ROMTAG                  ; APTR  RT_MATCHTAG
        DC.L    ENDTAG                  ; APTR  RT_ENDSKIP
        DC.B    RTF_AUTOINIT            ; UBYTE RT_FLAGS
        DC.B    VERSION                 ; UBYTE RT_VERSION
        DC.B    NT_LIBRARY              ; UBYTE RT_TYPE
        DC.B    0                       ; BYTE  RT_PRI
        DC.L    LibName                 ; APTR  RT_NAME
        DC.L    LibId                   ; APTR  RT_IDSTRING
        DC.L    LibInitTable            ; APTR  RT_INIT
ENDTAG:

LibName DC.B 'cdxl.datatype',0
LibId   VSTRING

        CNOP    0,4

LibInitTable:
        DC.L    ClassBase_SIZEOF
        DC.L    LibFuncTable
        DC.L    LibDataTable
        DC.L    _LibInit

V_DEF	MACRO
	DC.W	\1+(*-LibFuncTable)
	ENDM

LibFuncTable:
	DC.W	-1
        V_DEF	_LibOpen
        V_DEF	_LibClose
        V_DEF	_LibExpunge
        V_DEF	LibReserved

	V_DEF	_ObtainCDXLEngine

        DC.W   -1

LibDataTable:
        INITWORD   LIB_REVISION,REVISION
        DC.W       0

        CNOP    0,4

;-----------------------------------------------------------------------

LibReserved:
        moveq   #0,d0
        rts

;-----------------------------------------------------------------------

        END
