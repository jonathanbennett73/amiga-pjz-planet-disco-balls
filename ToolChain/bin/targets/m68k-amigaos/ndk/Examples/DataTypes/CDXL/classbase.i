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

	IFND CLASSBASE_I
CLASSBASE_I SET	1

;-----------------------------------------------------------------------

	INCLUDE "exec/types.i"
	INCLUDE "exec/libraries.i"
	INCLUDE "exec/lists.i"
	INCLUDE "exec/semaphores.i"
	INCLUDE "dos/dos.i"
	INCLUDE	"utility/tagitem.i"

;-----------------------------------------------------------------------

   STRUCTURE ClassBase,LIB_SIZE
   	UWORD	cb_Pad
   	APTR	cb_Class
	APTR	cb_SysBase
	APTR	cb_DOSBase
	APTR	cb_IntuitionBase
	APTR	cb_GfxBase
	APTR	cb_UtilityBase
	APTR	cb_DataTypesBase
	APTR	cb_SuperClassBase
	APTR	cb_SoundClassBase
	BPTR	cb_SegList
	STRUCT	cb_Lock,SS_SIZE
   LABEL ClassBase_SIZEOF

;-----------------------------------------------------------------------

	LIBINIT

	LIBDEF	_LVODispatch

;---------------------------------------------------------------------------

CALL MACRO <Function_Name>
	xref _LVO\1
 	jsr _LVO\1(A6)
     ENDM

;---------------------------------------------------------------------------

GO   MACRO <Function_Name>
	xref _LVO\1
 	jmp _LVO\1(A6)
     ENDM

;---------------------------------------------------------------------------

	ENDC	; CLASSBASE_I
