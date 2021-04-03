*
* $Id: printertag.asm 44.2 1999/09/13 17:11:50 olsen Exp olsen $
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


	SECTION	text,code

*------ Included Files -----------------------------------------------

	INCLUDE	"exec/types.i"
	INCLUDE	"exec/nodes.i"
	INCLUDE	"exec/strings.i"

	INCLUDE	"devices/prtbase.i"

	INCLUDE	"config.i"

*------ Imported Names -----------------------------------------------

	XREF	_DriverInit
	XREF	_DriverExpunge
	XREF	_DriverOpen
	XREF	_DriverClose
	XREF	_CommandTable
	XREF	_DoSpecial
	XREF	_Render
	XREF	_ExtendedCharTable
	XREF	_ConvFunc
	XREF	_PropertyTagList

*------ Exported Names -----------------------------------------------

	XDEF	_PEDData

**********************************************************************

	MOVEQ	#0,D0
	RTS

**********************************************************************

	DC.W	CONFIG_VERSION
	DC.W	CONFIG_REVISION

_PEDData:
	DC.L	printerName
	DC.L	_DriverInit
	DC.L	_DriverExpunge
	DC.L	_DriverOpen
	DC.L	_DriverClose
	DC.B	CONFIG_PRINTER_CLASS!PPCF_EXTENDED	; PrinterClass
	DC.B	CONFIG_COLOR_CLASS			; ColorClass
	DC.B	0					; MaxColumns
	DC.B	0					; NumCharSets
	DC.W	1					; NumRows
	DC.L	600					; MaxXDots
	DC.L	795					; MaxYDots
	DC.W	75					; XDotsInch
	DC.W	75					; YDotsInch
	DC.L	_CommandTable				; Commands
	DC.L	_DoSpecial
	DC.L	_Render
	DC.L	30					; Timeout
	DC.L	_ExtendedCharTable			; 8BitChars
	DC.L	0					; PrintMode
	DC.L	_ConvFunc				; ptr to char conversion function
	DC.L	_PropertyTagList			; List of driver properties
	DC.L	0					; Preferences hook (unused)
	DC.L	0					; Error hook (unused)

printerName:
	CONFIG_NAME

	CONFIG_VERSTAG

	END
