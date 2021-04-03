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

BOOL MakeWorkbenchObjectVisibleA( STRPTR name, struct TagItem *tags );
BOOL MakeWorkbenchObjectVisible( STRPTR name, ... );

#pragma libcall WorkbenchBase MakeWorkbenchObjectVisibleA 84 9802
#pragma tagcall WorkbenchBase MakeWorkbenchObjectVisible 84 9802

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		int i;

		for(i = 1 ; i < argc ; i++)
			MakeWorkbenchObjectVisibleA(argv[i],NULL);
	}

	return(0);
}
