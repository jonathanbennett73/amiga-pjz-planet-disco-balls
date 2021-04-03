/*
 * $Id$
 *
 * :ts=4
 */

#include "workbench.h"

#include <exec/libraries.h>

#include <clib/dos_protos.h>
#include <clib/wb_protos.h>

#include <pragmas/dos_pragmas.h>
#include <pragmas/wb_pragmas.h>

/****************************************************************************/

extern struct Library * DOSBase;
extern struct Library * WorkbenchBase;

/****************************************************************************/

BOOL WorkbenchControlA( STRPTR name, struct TagItem *tags );
BOOL WorkbenchControl( STRPTR name, ... );

#pragma libcall WorkbenchBase WorkbenchControlA 6c 9802
#pragma tagcall WorkbenchBase WorkbenchControl 6c 9802

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		int i;

		for(i = 1 ; i < argc ; i++)
		{
			WorkbenchControl(NULL,
				WBCTRLA_AddHiddenDeviceName,argv[i],
			TAG_DONE);
		}
	}

	return(0);
}
