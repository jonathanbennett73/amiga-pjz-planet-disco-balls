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

#define WBCTRLA_GetTitleBarEnabled WBA_Reserved20
#define WBCTRLA_SetTitleBarEnabled WBA_Reserved21

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		LONG mode = -1;

		if(WorkbenchControl(NULL,
			WBCTRLA_GetTitleBarEnabled,&mode,
		TAG_DONE) && mode != -1)
		{
			WorkbenchControl(NULL,
				WBCTRLA_SetTitleBarEnabled, !mode,
			TAG_DONE);
		}
	}

	return(0);
}
