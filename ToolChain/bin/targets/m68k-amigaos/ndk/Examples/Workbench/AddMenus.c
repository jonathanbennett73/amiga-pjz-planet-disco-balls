/*
 * $Id$
 *
 * :ts=8
 */

#include "/workbench.h"
#include <workbench/startup.h>

#include <dos/dos.h>

#include <clib/dos_protos.h>
#include <clib/exec_protos.h>
#include <clib/wb_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/dos_pragmas.h>
#include <pragmas/wb_pragmas.h>

/****************************************************************************/

extern struct Library *SysBase;
extern struct Library *DOSBase;

/****************************************************************************/

struct Library * WorkbenchBase;

/****************************************************************************/

int
main(int argc,char ** argv)
{
	struct MsgPort * mp = NULL;
	struct AppMenuItem * item = NULL;
	struct AppMenuItem * sub = NULL;
	struct AppMenuItem * sub2 = NULL;
	struct AppMessage * am;
	ULONG key;
	BOOL done;

	WorkbenchBase = OpenLibrary("workbench.library",44);
	if(WorkbenchBase == NULL)
	{
		Printf("Couldn't open workbench.library V44.\n");
		goto out;
	}

	mp = CreateMsgPort();
	if(mp == NULL)
	{
		Printf("Couldn't create MsgPort.\n");
		goto out;
	}

	key = 0;

	item = AddAppMenuItem(0,
		(ULONG)"regular menu item",
		"AppMenu with a sub menu",
		mp,
		WBAPPMENUA_GetKey,&key,
		TAG_DONE);
	if(item == NULL)
	{
		Printf("Couldn't create 1st level menu item.\n");
		goto out;
	}

	if(key == 0)
	{
		Printf("Can't get a key for the sub menu item\n");
		goto out;
	}

	sub = AddAppMenuItem(1,
		(ULONG)"sub menu item",
		"and this is the sub menu",
		mp,
		WBAPPMENUA_UseKey,key,
		TAG_DONE);
	if(sub == NULL)
	{
		Printf("Couldn't create 2nd level menu item.\n");
		goto out;
	}

	sub2 = AddAppMenuItem(2,
		(ULONG)"sub menu item 2",
		"and this is another sub menu",
		mp,
		WBAPPMENUA_UseKey,key,
		TAG_DONE);
	if(sub2 == NULL)
	{
		Printf("Couldn't create 2nd level menu item.\n");
		goto out;
	}

	done = FALSE;
	do
	{
		WaitPort(mp);

		while((am = (struct AppMessage *)GetMsg(mp)) != NULL)
		{
			if(am->am_UserData != (ULONG)NULL)
				Printf("%s\n",am->am_UserData);

			if(am->am_ID == 1)
				done = TRUE;
		}
	}
	while(NOT done);

	RemoveAppMenuItem(sub);
	sub = NULL;

	RemoveAppMenuItem(sub2);
	sub2 = NULL;

	Printf("removing the two; press ^C to continue... ");
	Flush(Output());
	Wait(SIGBREAKF_CTRL_C);

	sub = AddAppMenuItem(1,
		(ULONG)"sub menu item",
		"and this is the sub menu",
		mp,
		WBAPPMENUA_UseKey,key,
		TAG_DONE);
	if(sub == NULL)
	{
		Printf("Couldn't create 2nd level menu item.\n");
		goto out;
	}

	Printf("Added another one; try again.\n");

	done = FALSE;
	do
	{
		WaitPort(mp);

		while((am = (struct AppMessage *)GetMsg(mp)) != NULL)
		{
			if(am->am_UserData != (ULONG)NULL)
				Printf("%s\n",am->am_UserData);

			if(am->am_ID == 1)
				done = TRUE;
		}
	}
	while(NOT done);

 out:

	if(sub2 != NULL)
		RemoveAppMenuItem(sub2);

	if(sub != NULL)
		RemoveAppMenuItem(sub);

	if(item != NULL)
		RemoveAppMenuItem(item);

	if(mp != NULL)
	{
		while((am = (struct AppMessage *)GetMsg(mp)) != NULL)
			ReplyMsg((struct Message *)am);

		DeleteMsgPort(mp);
	}

	if(WorkbenchBase != NULL)
	{
		CloseLibrary(WorkbenchBase);
		WorkbenchBase = NULL;
	}

	return(0);
}
