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

BOOL OpenWorkbenchObjectA( STRPTR name, struct TagItem *tags );
BOOL OpenWorkbenchObject( STRPTR name, ... );

#pragma libcall WorkbenchBase OpenWorkbenchObjectA 60 9802
#pragma tagcall WorkbenchBase OpenWorkbenchObject 60 9802

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		int i;

		for(i = 1 ; i < argc ; i++)
			OpenWorkbenchObjectA(argv[i],NULL);
	}

	return(0);
}
