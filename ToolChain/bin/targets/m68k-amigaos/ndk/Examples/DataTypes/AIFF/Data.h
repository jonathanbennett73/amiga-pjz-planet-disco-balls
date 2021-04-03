/*
 * $Id: Data.h 44.2 1999/03/12 16:59:09 olsen Exp olsen $
 *
 * :ts=4
 *
 * AIFF datatype
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
 */

/******************************************************************************/

#include <intuition/intuition.h>
#include <intuition/gadgetclass.h>
#include <intuition/classes.h>
#include <intuition/cghooks.h>

#include <dos/dosextens.h>

#include <exec/execbase.h>
#include <exec/resident.h>
#include <exec/memory.h>

#include <devices/clipboard.h>

#include "datatypes/soundclass.h"

#include <clib/intuition_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/iffparse_protos.h>
#include <clib/utility_protos.h>
#include <clib/alib_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/intuition_pragmas.h>
#include <pragmas/datatypes_pragmas.h>
#include <pragmas/iffparse_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>

/******************************************************************************/

	// Our custom library structure

struct ClassBase
{
	struct Library			LibNode;		// Exec link
	UWORD					Pad;			// Longword alignment
	Class *					SoundClass;		// The class this library implements

	struct ExecBase *		SysBase;		// Exec library
	struct Library *		DOSBase;		// Dos library
	struct Library *		IntuitionBase;	// Intuition library
	struct Library *		UtilityBase;	// Utility library
	struct Library *		IFFParseBase;	// IFFParse library
	struct Library *		DataTypesBase;	// DataTypes library
	struct Library *		SuperClassBase;	// Sound datatype

	struct SignalSemaphore	LockSemaphore;	// Shared access semaphore
	BPTR					Segment;		// Library segment pointer
};

	// Redirect references to global data into the library base

#define SysBase			ClassBase->SysBase
#define DOSBase			ClassBase->DOSBase
#define IntuitionBase	ClassBase->IntuitionBase
#define UtilityBase		ClassBase->UtilityBase
#define IFFParseBase	ClassBase->IFFParseBase
#define DataTypesBase	ClassBase->DataTypesBase
#define SuperClassBase	ClassBase->SuperClassBase
#define LockSemaphore	ClassBase->LockSemaphore
#define SoundClass		ClassBase->SoundClass
#define Segment			ClassBase->Segment

/******************************************************************************/

	// Preprocessor tricks

#define REG(x)	register __ ## x
#define ASM		__asm

/******************************************************************************/

#include "Assert.h"

/******************************************************************************/

	// For debugging

void kprintf(const char *,...);
