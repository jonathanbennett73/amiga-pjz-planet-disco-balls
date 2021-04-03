/*
 * $Id: libbase.c 1.1 1997/06/25 18:46:44 olsen Exp $
 *
 * ARexx sample library
 *
 * :ts=4
 */

#include "rexxsamplebase.h"
#include "rexxsample.library_rev.h"

/****************************************************************************/

	/* This will be the first function of this library. It must return
	 * an error to the caller.
	 */

LONG ReturnError(VOID) { return(-1); }

/****************************************************************************/

	/* LibInit():
	 *
	 *	This is a standard library initialization routine written
	 *	in `C'. It opens two rom-resident libraries (dos.library
	 *	and utility.library), the third required library being
	 *	disk-based. It will be opened in LibOpen().
	 */

STATIC struct RexxSampleBase * ASM
LibInit(
	REG(d0) struct RexxSampleBase *	RexxSampleBase,
	REG(a0) BPTR					Segment,
	REG(a6) struct ExecBase *		ExecBase)
{
	struct RexxSampleBase * result = NULL;

		/* We must initialize this for the library open calls to work. */

	SysBase = ExecBase;

	DOSBase		= OpenLibrary("dos.library",37);
	UtilityBase	= OpenLibrary("utility.library",37);

		/* Did the two libraries open? */

	if(DOSBase != NULL && UtilityBase != NULL)
	{
		result = RexxSampleBase;

			/* Initialize the revision number; all other information
			 * will have been initialized by the library loader,
			 * using the data in the Resident tag.
			 */

		RexxSampleBase->rsb_Library.lib_Revision = REVISION;

		RexxSampleBase->rsb_Segment = Segment;

		InitSemaphore(&RexxSampleBase->rsb_Semaphore);
	}
	else
	{
		if(DOSBase != NULL)
			CloseLibrary(DOSBase);

		if(UtilityBase != NULL)
			CloseLibrary(UtilityBase);

			/* Important: The library base and the jump table
			 *            vector must be freed if this auto-init
			 *            routine fails.
			 */

		FreeMem((BYTE *)RexxSampleBase - RexxSampleBase->rsb_Library.lib_NegSize,
		        RexxSampleBase->rsb_Library.lib_NegSize + RexxSampleBase->rsb_Library.lib_PosSize);
	}

	return(result);
}

	/* LibOpen():
	 *
	 *	The library open routine; the first caller to open the
	 *	library will also open the disk-resident rexxsyslib.library.
	 */

STATIC struct RexxSampleBase * ASM
LibOpen(REG(a6) struct RexxSampleBase * RexxSampleBase)
{
	struct RexxSampleBase * result = NULL;
	UWORD openCnt;

	openCnt = RexxSampleBase->rsb_Library.lib_OpenCnt;

	RexxSampleBase->rsb_Library.lib_Flags &= ~LIBF_DELEXP;
	RexxSampleBase->rsb_Library.lib_OpenCnt++;

		/* Start of critical section. */

	ObtainSemaphore(&RexxSampleBase->rsb_Semaphore);

	if(openCnt == 0)
		RexxSysBase = OpenLibrary(RXSNAME,0);

	ReleaseSemaphore(&RexxSampleBase->rsb_Semaphore);

		/* End of critical section. */

	if(RexxSysBase != NULL)
	{
		result = RexxSampleBase;
	}
	else
	{
		RexxSampleBase->rsb_Library.lib_OpenCnt--;
	}

	return(result);
}

STATIC BPTR ASM
LibExpunge(REG(a6) struct RexxSampleBase *RexxSampleBase)
{
	BPTR result = NULL;

	if(RexxSampleBase->rsb_Library.lib_OpenCnt == 0)
	{
		result = RexxSampleBase->rsb_Segment;

		CloseLibrary(DOSBase);
		CloseLibrary(UtilityBase);

		Remove(RexxSampleBase);

		FreeMem((BYTE *)RexxSampleBase - RexxSampleBase->rsb_Library.lib_NegSize,
		        RexxSampleBase->rsb_Library.lib_NegSize + RexxSampleBase->rsb_Library.lib_PosSize);
	}
	else
	{
		RexxSampleBase->rsb_Library.lib_Flags |= LIBF_DELEXP;
	}

	return(result);
}

STATIC BPTR ASM
LibClose(REG(a6) struct RexxSampleBase *RexxSampleBase)
{
	BPTR result = NULL;

		/* Start of critical section. */

	ObtainSemaphore(&RexxSampleBase->rsb_Semaphore);

		/* Close rexxsyslib.library if this the
		 * last customer.
		 */

	if(RexxSampleBase->rsb_Library.lib_OpenCnt == 1)
	{
		if(RexxSysBase != NULL)
		{
			CloseLibrary(RexxSysBase);
			RexxSysBase = NULL;
		}
	}

	ReleaseSemaphore(&RexxSampleBase->rsb_Semaphore);

		/* End of critical section. */

	RexxSampleBase->rsb_Library.lib_OpenCnt--;

	if(RexxSampleBase->rsb_Library.lib_OpenCnt == 0 && (RexxSampleBase->rsb_Library.lib_Flags & LIBF_DELEXP))
		result = LibExpunge(RexxSampleBase);

	return(result);
}

STATIC LONG
LibNull(VOID)
{
	return(NULL);
}

/****************************************************************************/

	/* Defined in glue.a */

LONG ASM RexxDispatchGlue(REG(a0) struct RexxMsg *);

/****************************************************************************/

	/* Library initialization table data; first the four mandatory
	 * functions, then the only user function.
	 */

APTR LibVectors[] =
{
	LibOpen,
	LibClose,
	LibExpunge,
	LibNull,

	RexxDispatchGlue,

	(APTR)-1
};

	/* This will allocate memory for the library base and make
	 * the library ready to use before the init routine is called.
	 */

typedef struct Library * (* LIBINIT)();

struct LibInit
{
	ULONG				li_StructureSize;		/* Size of the library structure. */
	APTR *				li_FunctionTable;		/* Library function table. */
	struct LibData *	li_StructureInitTable;	/* Library base initialization table. */
	LIBINIT				li_InitRoutine;			/* Library initialization routine. */
};

STATIC struct LibInit LibraryInit =
{
	sizeof(struct RexxSampleBase),
	LibVectors,
	NULL,
	(LIBINIT)LibInit
};

	/* The library loader searches for the following data
	 * structure. It is responsible for initializing and
	 * configuring the library base and library function table.
	 */

struct Resident LibraryTag =
{
	RTC_MATCHWORD,
	&LibraryTag,
	&LibraryTag + 1,
	RTF_AUTOINIT,
	VERSION,
	NT_LIBRARY,
	0,
	"rexxsample.library",
	VSTRING,
	&LibraryInit
};
