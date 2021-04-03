/*
 * $Id: rexxsamplebase.h 1.1 1997/06/25 18:46:44 olsen Exp $
 *
 * ARexx sample library
 *
 * :ts=4
 */

	/* Header files we require. */

#include <exec/execbase.h>
#include <exec/resident.h>
#include <dos/dosextens.h>

#include <rexx/rxslib.h>
#include <rexx/errors.h>

#include <clib/rexxsyslib_protos.h>
#include <clib/utility_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/rexxsyslib_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>
#include <stddef.h>

/****************************************************************************/

	/* The sample library base. */

struct RexxSampleBase
{
	struct Library			rsb_Library;

	struct SignalSemaphore	rsb_Semaphore;
	BPTR					rsb_Segment;

	struct Library *		rsb_SysBase;
	struct Library *		rsb_DOSBase;
	struct Library *		rsb_UtilityBase;
	struct Library *		rsb_RexxSysBase;
};

#define SysBase		RexxSampleBase->rsb_SysBase
#define DOSBase		RexxSampleBase->rsb_DOSBase
#define UtilityBase	RexxSampleBase->rsb_UtilityBase
#define RexxSysBase	RexxSampleBase->rsb_RexxSysBase

/****************************************************************************/

	/* Function table entry. */

typedef LONG (* REXXCMD)(STRPTR *,LONG *,struct RexxSampleBase *);

struct RexxCmd
{
	STRPTR	Name;		/* Function name. */
	LONG	NumArgs;	/* Number of arguments required. */

	REXXCMD	Cmd;		/* Handler function. */
};

/****************************************************************************/

	/* Handy macros. */

#define ASM		__asm
#define REG(x)	register __ ## x
