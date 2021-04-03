/*
 * $Id$
 *
 * :ts=4
 */

#include <exec/libraries.h>

#include <clib/wb_protos.h>
#include <clib/dos_protos.h>
#include <pragmas/wb_pragmas.h>
#include <pragmas/dos_pragmas.h>

/****************************************************************************/

extern struct Library * WorkbenchBase;
extern struct Library * DOSBase;

/****************************************************************************/

VOID UpdateWorkbench( STRPTR name, ULONG lock, LONG flag );
#pragma libcall WorkbenchBase UpdateWorkbench 1e 09803

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		BPTR parent;
		BPTR lock;
		int i;

		for(i = 1 ; i < argc ; i++)
		{
			lock = Lock(argv[i],SHARED_LOCK);
			if(lock != (BPTR)NULL)
			{
				parent = ParentDir(lock);
				UnLock(lock);

				if(parent != (BPTR)NULL)
				{
					UpdateWorkbench(FilePart(argv[i]),parent,FALSE);

					UnLock(parent);
				}
			}			
		}
	}

	return(0);
}
