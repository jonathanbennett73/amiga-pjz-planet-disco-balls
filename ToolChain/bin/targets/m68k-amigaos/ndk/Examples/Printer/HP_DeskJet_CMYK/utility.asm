*
* $Id: utility.asm 44.2 1999/09/13 16:02:18 olsen Exp olsen $
*
* :ts=8
*
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


	section	text,code

	include	"exec/macros.i"

*******************************************************************************

	xref	_UtilityBase

*******************************************************************************
*
* __CXD33 replacement that uses utility.library
*
*******************************************************************************

	xdef	__CXD33			; Signed divide

__CXD33:
	move.l	a6,-(sp)		; Save your base pointer
	move.l	_UtilityBase(a4),a6	; Get utility base pointer
	JSRLIB	SDivMod32		; Do the divide
	move.l	(sp)+,a6		; Restore a6
	rts				; And we are done.

*******************************************************************************
*
* __CXD22 replacement that uses utility.library
*
*******************************************************************************

	xdef	__CXD22			; Unsigned divide

__CXD22:
	move.l	a6,-(sp)		; Save your base pointer
	move.l	_UtilityBase(a4),a6	; Get utility base pointer
	JSRLIB	UDivMod32		; Do the divide
	move.l	(sp)+,a6		; Restore a6
	rts				; And we are done.

*******************************************************************************
*
* __CXM33 replacement that uses utility.library
*
*******************************************************************************

	xdef	__CXM33			; Signed multiply

__CXM33:
	move.l	a6,-(sp)		; Save your base pointer
	move.l	_UtilityBase(a4),a6	; Get utility base pointer
	JSRLIB	SMult32			; Do the multiply
	move.l	(sp)+,a6		; Restore a6
	rts				; And we are done.

*******************************************************************************
*
* __CXM22 replacement that uses utility.library
*
*******************************************************************************

	xdef	__CXM22			; Unsigned multiply

__CXM22:
	move.l	a6,-(sp)		; Save your base pointer
	move.l	_UtilityBase(a4),a6	; Get utility base pointer
	JSRLIB	UMult32			; Do the multply
	move.l	(sp)+,a6		; Restore a6
	rts				; And we are done.

*******************************************************************************

	end
