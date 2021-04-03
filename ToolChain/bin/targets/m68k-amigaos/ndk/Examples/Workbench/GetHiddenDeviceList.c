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
		struct List * list = NULL;

		if(WorkbenchControl(NULL,
			WBCTRLA_GetHiddenDeviceList,&list,
		TAG_DONE))
		{
			struct Node * node;

			for(node = list->lh_Head ;
			    node->ln_Succ != NULL ;
			    node = node->ln_Succ)
			{
				Printf("%s\n",node->ln_Name);
			}

			WorkbenchControl(NULL,
				WBCTRLA_FreeOpenDrawerList,list,
			TAG_DONE);
		}
	}

	return(0);
}
