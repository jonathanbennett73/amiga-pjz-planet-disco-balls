/*
 * $Id: ClassBase.c 44.2 1999/03/12 18:53:16 olsen Exp olsen $
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

#include "Data.h"

/****************************************************************************/

#include "aiff.datatype_rev.h"

/****************************************************************************/

	// Functions in Dispatch.c

BOOL	CreateClass(struct ClassBase *ClassBase);
Class *	GetClassPointer(struct ClassBase *ClassBase);
BOOL	AttemptFreeClass(struct ClassBase *ClassBase);

/****************************************************************************/

	// First executable routine of this library; must return an error
	// to the unsuspecting caller

LONG
ReturnError(VOID)
{
	return(-1);
}

/****************************************************************************/

	/* LibraryCleanup(struct ClassBase *ClassBase):
	 *
	 *	Closes all the libraries opened by LibrarySetup().
	 */

STATIC VOID
CloseLibraries(struct ClassBase *ClassBase)
{
	if(DataTypesBase != NULL)
	{
		CloseLibrary(DataTypesBase);
		DataTypesBase = NULL;
	}

	if(UtilityBase != NULL)
	{
		CloseLibrary(UtilityBase);
		UtilityBase = NULL;
	}

	if(IFFParseBase != NULL)
	{
		CloseLibrary(IFFParseBase);
		IFFParseBase = NULL;
	}

	if(IntuitionBase != NULL)
	{
		CloseLibrary(IntuitionBase);
		IntuitionBase = NULL;
	}

	if(DOSBase != NULL)
	{
		CloseLibrary(DOSBase);
		DOSBase = NULL;
	}
}

	/* LibrarySetup(struct ClassBase *ClassBase):
	 *
	 *	Sets up all the libraries this class requires to work.
	 */

STATIC BOOL
OpenLibraries(struct ClassBase *ClassBase)
{
	BOOL Result = TRUE;

	DOSBase = OpenLibrary("dos.library", 39);
	if(DOSBase == NULL)
		Result = FALSE;

	IntuitionBase = OpenLibrary("intuition.library", 39);
	if(IntuitionBase == NULL)
		Result = FALSE;

	UtilityBase = OpenLibrary("utility.library", 39);
	if(UtilityBase == NULL)
		Result = FALSE;

	IFFParseBase = OpenLibrary("iffparse.library", 39);
	if(IFFParseBase == NULL)
		Result = FALSE;

	DataTypesBase = OpenLibrary("datatypes.library", 39);
	if(DataTypesBase == NULL)
		Result = FALSE;

	return(Result);
}

	/* LibInit():
	 *
	 *	Initialize the library.
	 */

STATIC struct ClassBase * ASM
LibInit(
	REG(d0) struct ClassBase *	ClassBase,
	REG(a0) BPTR				LibrarySegment,
	REG(a6) struct ExecBase *	ExecBase)
{
		// Remember the exec library base pointer

	SysBase = ExecBase;

		// Remember the segment pointer

	Segment = LibrarySegment;

		// Set up the header data; everything that doesn't get set
		// up here will have been set up by InitResident().

	ClassBase->LibNode.lib_Revision = REVISION;

		// Initialize the shared data access semaphore

	InitSemaphore(&LockSemaphore);

	SETPROGRAMNAME(ClassBase->LibNode.lib_Node.ln_Name);

	return(ClassBase);
}

	/* LibOpen(REG(a6) struct ClassBase *ClassBase):
	 *
	 *	Open the library, as called via OpenLibrary()
	 */

STATIC struct ClassBase * ASM
LibOpen(REG(a6) struct ClassBase *ClassBase)
{
	struct ClassBase *Result = NULL;
	UWORD OpenCount;

		// Get the current open count; we'll have to
		// modify it in a minute

	OpenCount = ClassBase->LibNode.lib_OpenCnt;

		// Increment the user count and prevent delayed expunge

	ClassBase->LibNode.lib_OpenCnt++;
	ClassBase->LibNode.lib_Flags &= ~LIBF_DELEXP;

		// We are going to modify data while in multitasking,
		// so watch out

	ObtainSemaphore(&LockSemaphore);

		// Is this the first initialization?

	if(OpenCount == 0)
	{
		BOOL failed = TRUE;

		if(OpenLibraries(ClassBase))
		{
			if(CreateClass(ClassBase))
				failed = FALSE;
		}

		if(failed)
			CloseLibraries(ClassBase);
	}

	if(DataTypesBase != NULL)
		Result = ClassBase;

		// Release the lock

	ReleaseSemaphore(&LockSemaphore);

		// Back up the open count if the initialization failed.

	if(Result == NULL)
		ClassBase->LibNode.lib_OpenCnt--;

		// Return the library base, if any

	return(Result);
}

	/* LibExpunge(REG(a6) struct ClassBase *ClassBase):
	 *
	 *	Expunge the library, remove it from memory
	 */

STATIC BPTR ASM
LibExpunge(REG(a6) struct ClassBase *ClassBase)
{
	BPTR Result = NULL;

		// Can we get away with this?

	if(ClassBase->LibNode.lib_OpenCnt == 0 && GetClassPointer(ClassBase) == NULL)
	{
			// Return the segment, so it can be unloaded

		Result = Segment;

			// Remove the library from the public list

		Remove(ClassBase);

			// Free the vector table and the library data

		FreeMem((BYTE *)ClassBase - ClassBase->LibNode.lib_NegSize,
		        ClassBase->LibNode.lib_NegSize + ClassBase->LibNode.lib_PosSize);
	}
	else
	{
			// Expunge it later

		ClassBase->LibNode.lib_Flags |= LIBF_DELEXP;
	}

		// Return the segment pointer, if any

	return(Result);
}

	/* LibClose(REG(a6) struct ClassBase *ClassBase):
	 *
	 *	Close the library, as called by CloseLibrary()
	 */

STATIC BPTR ASM
LibClose(REG(a6) struct ClassBase *ClassBase)
{
	BPTR Result = NULL;

		// We are going to modify shared data,
		// so watch out

	ObtainSemaphore(&LockSemaphore);

		// Check how many customers we still have

	if(ClassBase->LibNode.lib_OpenCnt == 1)
	{
			// Clean up; note that if AttemptFreeClass()
			// fails the behaviour of this library is
			// somewhat undefined. The best the code can
			// do is try not to crash the machine due to
			// this kind of error.

		if(AttemptFreeClass(ClassBase))
			CloseLibraries(ClassBase);
	}

		// Decrement the usage count

	ClassBase->LibNode.lib_OpenCnt--;

		// Release the lock

	ReleaseSemaphore(&LockSemaphore);

		// Can we remove ourselves?

	if((ClassBase->LibNode.lib_OpenCnt == 0) && (ClassBase->LibNode.lib_Flags & LIBF_DELEXP))
		Result = LibExpunge(ClassBase);

	return(Result);
}

	/* GetClassEngine(REG(a6) struct ClassBase *ClassBase):
	 *
	 *	Get access to the class this library implements.
	 */

STATIC Class * ASM
GetClassEngine(REG(a6) struct ClassBase *ClassBase)
{
	Class *Result;

		// Access shared data

	ObtainSemaphoreShared(&LockSemaphore);

		// Remember the class pointer

	Result = GetClassPointer(ClassBase);

		// Release the lock

	ReleaseSemaphore(&LockSemaphore);

		// Return the pointer

	return(Result);
}

	/* LibReserved(VOID):
	 *
	 *	The mandatory reserved library function.
	 */

STATIC LONG
LibReserved(VOID)
{
	return(0);
}

/****************************************************************************/

	// This is the table of functions that make up the library. The first
	// four are mandatory, everything following it are user callable
	// routines. The table is terminated by the value -1.

STATIC const APTR LibVectors[] =
{
	LibOpen,
	LibClose,
	LibExpunge,
	LibReserved,

	GetClassEngine,

	(APTR) -1
};

	// The following data structures and data are responsible for
	// setting up the Library base data structure and the library
	// function vector.

struct LibraryInitTable
{
	ULONG	lit_BaseSize;		// Size of the base data structure
	APTR *	lit_VectorTable;	// Points to the function vector
	APTR	lit_InitTable;		// Library base data structure setup table
	APTR	lit_InitRoutine;	// The address of the routine to do the setup
};

	// This finally sets up the library base data structure and the
	// function vector.

STATIC const struct LibraryInitTable LibInitTable =
{
	sizeof(struct ClassBase),
	LibVectors,
	NULL,
	LibInit
};

/****************************************************************************/

	// The library loader looks for this marker in the memory
	// the library code and data will occupy. It is responsible
	// setting up the Library base data structure.

const struct Resident RomTag =
{
	RTC_MATCHWORD,		// Marker value.
	&RomTag,			// This points back to itself.
	&RomTag + 1,		// This points behind this marker.
	RTF_AUTOINIT,		// The Library should be set up according to the given table.
	VERSION,			// The version of this Library.
	NT_LIBRARY,			// This defines this module as a Library.
	0,					// Initialization priority of this Library; unused.
	"aiff.datatype",	// Points to the name of the Library.
	VSTRING,			// The identification string of this Library.
	&LibInitTable		// This table is for initializing the Library.
};
