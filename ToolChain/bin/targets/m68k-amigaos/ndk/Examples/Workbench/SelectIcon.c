/*
 * $Id$
 *
 * :ts=4
 */

#include "workbench.h"

#include <exec/libraries.h>

#include <utility/hooks.h>

#include <clib/utility_protos.h>
#include <clib/dos_protos.h>
#include <clib/wb_protos.h>

#include <pragmas/utility_pragmas.h>
#include <pragmas/dos_pragmas.h>
#include <pragmas/wb_pragmas.h>

#include <string.h>

/****************************************************************************/

extern struct Library * WorkbenchBase;
extern struct Library * UtilityBase;
extern struct Library * DOSBase;

/****************************************************************************/

BOOL ChangeWorkbenchSelectionA( STRPTR name, struct Hook *hook, struct TagItem *tags );
BOOL ChangeWorkbenchSelection( STRPTR name, struct Hook *hook, ... );

#pragma libcall WorkbenchBase ChangeWorkbenchSelectionA 7e A9803
#pragma tagcall WorkbenchBase ChangeWorkbenchSelection 7e A9803

/****************************************************************************/

ULONG __saveds __asm
HookFunc(
	register __a0 struct Hook * hook,
	register __a2 APTR reserved,
	register __a1 struct IconSelectMsg * ism)
{
	STRPTR name = hook->h_Data;
	ULONG result = ISMACTION_Ignore;

	if(Stricmp(name,ism->ism_Name) == 0)
		result = ISMACTION_Select;

	return(result);
}

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(WorkbenchBase->lib_Version >= 44)
	{
		if(argc > 2)
		{
			struct Hook hook;

			memset(&hook,0,sizeof(hook));

			hook.h_Entry = (HOOKFUNC)HookFunc;
			hook.h_Data = argv[2];

			ChangeWorkbenchSelectionA(argv[1],&hook,NULL);
		}
	}

	return(0);
}
