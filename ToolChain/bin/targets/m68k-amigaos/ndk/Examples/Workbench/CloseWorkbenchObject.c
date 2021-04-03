/*
 * $Id$
 *
 * :ts=4
 */

#include <exec/libraries.h>

#include <clib/wb_protos.h>
#include <pragmas/wb_pragmas.h>

/****************************************************************************/

extern struct Library * WorkbenchBase;

/****************************************************************************/

BOOL CloseWorkbenchObjectA( STRPTR name, struct TagItem *tags );
BOOL CloseWorkbenchObject( STRPTR name, ... );

#pragma libcall WorkbenchBase CloseWorkbenchObjectA 66 9802
#pragma tagcall WorkbenchBase CloseWorkbenchObject 66 9802

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		int i;

		for(i = 1 ; i < argc ; i++)
			CloseWorkbenchObjectA(argv[i],NULL);
	}

	return(0);
}
