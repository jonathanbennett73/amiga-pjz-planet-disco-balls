/*
 * $Id: classbase.c 44.1 1999/03/12 11:07:47 olsen Exp olsen $
 *
 * :ts=4
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

#include "classbase.h"

/****** cdxl.datatype/cdxl.datatype ****************************************
*
*	 NAME
*		cdxl.datatype -- data type for CDXL movies.
*
*	 FUNCTION
*		The cdxl data type, a sub-class of the movie.datatype, is used
*		to load CDXL files.
*
*	 METHODS
*		OM_NEW -- Create a new movie object from an CDXL.  The
*			source must be a file.
*
*	 SEE ALSO
*		animation.datatype
*
*******************************************************************************
*
* Created:	27-Feb-92, David N. Junod
*
*/

/*****************************************************************************/

Class *ASM ObtainCDXLEngine (REG (a6) struct ClassBase *cb)
{
	return (cb->cb_Class);
}

/*****************************************************************************/

struct Library *ASM LibInit (REG (d0) struct ClassBase *cb, REG (a0) BPTR seglist, REG (a6) struct Library * sysbase)
{
	SysBase = sysbase;

	cb->cb_SegList = seglist;
	InitSemaphore (&cb->cb_Lock);

	if (SysBase->lib_Version >= 40)
	{
		IntuitionBase = OpenLibrary ("intuition.library",40);
		GfxBase		  = OpenLibrary ("graphics.library", 40);
		DOSBase		  = OpenLibrary ("dos.library",		 40);
		UtilityBase	  = OpenLibrary ("utility.library",	 40);

		return cb;
	}
	else
	{
		FreeMem ((APTR)((ULONG)(cb) - (ULONG)(cb->cb_Lib.lib_NegSize)), cb->cb_Lib.lib_NegSize + cb->cb_Lib.lib_PosSize);

		return NULL;
	}
}

/*****************************************************************************/

LONG ASM LibOpen (REG (a6) struct ClassBase *cb)
{
	LONG retval = (LONG) cb;
	BOOL success = TRUE;

	ObtainSemaphore (&cb->cb_Lock);

	/* Use an internal use counter */
	cb->cb_Lib.lib_OpenCnt++;
	cb->cb_Lib.lib_Flags &= ~LIBF_DELEXP;

	if (cb->cb_Lib.lib_OpenCnt == 1)
	{
		if (cb->cb_Class == NULL)
		{
			success = FALSE;
			if (DataTypesBase = OpenLibrary ("datatypes.library", 0))
			{
				if (cb->cb_SuperClassBase = OpenLibrary ("datatypes/animation.datatype", 44))
				{
					if (cb->cb_SoundClassBase = OpenLibrary ("datatypes/sound.datatype", 44))
					{
						if (cb->cb_Class = initClass (cb))
							success = TRUE;
					}
				}
			}
		}
	}

	if (!success)
	{
		CloseLibrary (cb->cb_SoundClassBase);
		CloseLibrary (cb->cb_SuperClassBase);
		CloseLibrary (DataTypesBase);
		cb->cb_Lib.lib_OpenCnt--;
		retval = NULL;
	}

	ReleaseSemaphore (&cb->cb_Lock);

	return (retval);
}

/*****************************************************************************/

LONG ASM LibClose (REG (a6) struct ClassBase *cb)
{
	LONG retval = NULL;

	ObtainSemaphore (&cb->cb_Lock);

	if (cb->cb_Lib.lib_OpenCnt)
		cb->cb_Lib.lib_OpenCnt--;

	if ((cb->cb_Lib.lib_OpenCnt == 0) && cb->cb_Class)
	{
		if (FreeClass (cb->cb_Class))
		{
			CloseLibrary (cb->cb_SoundClassBase);
			CloseLibrary (cb->cb_SuperClassBase);
			CloseLibrary (DataTypesBase);
			cb->cb_Class = NULL;
		}
		else
		{
			cb->cb_Lib.lib_Flags |= LIBF_DELEXP;
		}
	}

	if (cb->cb_Lib.lib_Flags & LIBF_DELEXP)
		retval = LibExpunge (cb);

	ReleaseSemaphore (&cb->cb_Lock);

	return (retval);
}

/*****************************************************************************/

LONG ASM LibExpunge (REG (a6) struct ClassBase *cb)
{
	BPTR seg = cb->cb_SegList;

	if (cb->cb_Lib.lib_OpenCnt)
	{
		cb->cb_Lib.lib_Flags |= LIBF_DELEXP;
		return (NULL);
	}

	Remove ((struct Node *) cb);

	CloseLibrary (UtilityBase);
	CloseLibrary (DOSBase);
	CloseLibrary (GfxBase);
	CloseLibrary (IntuitionBase);

	FreeMem ((APTR)((ULONG)(cb) - (ULONG)(cb->cb_Lib.lib_NegSize)), cb->cb_Lib.lib_NegSize + cb->cb_Lib.lib_PosSize);

	return ((LONG) seg);
}
