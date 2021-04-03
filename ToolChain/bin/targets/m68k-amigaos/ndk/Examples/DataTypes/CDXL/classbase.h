/*
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
 */

/*****************************************************************************/

#include <dos/dos.h>
#include <dos/dosextens.h>
#include <exec/types.h>
#include <exec/ports.h>
#include <exec/memory.h>
#include <exec/lists.h>
#include <exec/devices.h>
#include <exec/semaphores.h>
#include <exec/execbase.h>
#include <devices/audio.h>
#include <intuition/classes.h>
#include <intuition/classusr.h>
#include <intuition/cghooks.h>
#include <intuition/gadgetclass.h>
#include <utility/tagitem.h>
#include <graphics/gfx.h>
#include <graphics/text.h>

#include "datatypes/soundclass.h"
#include "datatypes/animationclass.h"

#include <datatypes/datatypes.h>
#include <datatypes/datatypesclass.h>
#define USE_BUILTIN_MATH
#include <string.h>
#include <dos.h>

#include <clib/macros.h>
#include <clib/dos_protos.h>
#include <clib/exec_protos.h>
#include <clib/intuition_protos.h>
#include <clib/graphics_protos.h>
#include <clib/utility_protos.h>
#include <clib/datatypes_protos.h>
/*#include <clib/dtclass_protos.h>*/
#include <clib/alib_protos.h>

#include <pragmas/dos_pragmas.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/intuition_pragmas.h>
#include <pragmas/graphics_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/datatypes_pragmas.h>
/*#include <pragmas/dtclass_pragmas.h>*/

/*****************************************************************************/

#define	CDXLDTCLASS		"cdxl.datatype"

/*****************************************************************************/

struct ClassBase
{
    struct Library		cb_Lib;
    UWORD			cb_Pad;
    Class *			cb_Class;

    struct Library *		cb_SysBase;
    struct Library *		cb_DOSBase;
    struct Library *		cb_IntuitionBase;
    struct Library *		cb_GfxBase;
    struct Library *		cb_UtilityBase;
    struct Library *		cb_DataTypesBase;
    struct Library *		cb_SuperClassBase;
    struct Library *		cb_SoundClassBase;

    BPTR			cb_SegList;
    struct SignalSemaphore	cb_Lock;		/* Access lock */
};

/*****************************************************************************/

#define MEMORY_FOLLOWING(ptr)	((void *)((ptr)+1))
#define MEMORY_N_FOLLOWING(ptr,n)  ((void *)( ((ULONG)ptr) + n ))
#define ASM			__asm
#define REG(x)			register __ ## x

/*****************************************************************************/

#define SysBase			cb->cb_SysBase
#define DOSBase			cb->cb_DOSBase
#define UtilityBase		cb->cb_UtilityBase
#define	IntuitionBase		cb->cb_IntuitionBase
#define	GfxBase			cb->cb_GfxBase
#define	DataTypesBase		cb->cb_DataTypesBase

/*****************************************************************************/

void kprintf(const char *, ...);

/*****************************************************************************/

#include "Assert.h"

/*****************************************************************************/

#include "protos.h"
