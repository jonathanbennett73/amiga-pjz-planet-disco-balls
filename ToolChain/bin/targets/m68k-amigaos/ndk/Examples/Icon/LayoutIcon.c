/*
 * $Id$
 *
 * :ts=4
 */

#include <intuition/intuition.h>

#include <graphics/modeid.h>

#include <dos/dosextens.h>
#include <dos/dosasl.h>
#include <dos/rdargs.h>

#include <exec/memory.h>

#include <workbench/workbench.h>

#include <clib/exec_protos.h>
#include <clib/intuition_protos.h>
#include <clib/graphics_protos.h>
#include <clib/utility_protos.h>
#include <clib/layers_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/intuition_pragmas.h>
#include <pragmas/graphics_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/layers_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>

/****************************************************************************/

extern struct Library * IntuitionBase;
extern struct Library * GfxBase;
extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * UtilityBase;
extern struct Library * IconBase;
extern struct Library * LayersBase;

/****************************************************************************/

#include "/icon.h"
#include "/PROTOS/public_icon_protos.h"
#include "/PRAGMAS/public_icon_pragmas.h"

/****************************************************************************/

#define OK (0)
#define SAME (0)

/****************************************************************************/

#define MAX_PATH_LEN 1024

/****************************************************************************/

#define FIB_IS_DRAWER(fib)	((fib)->fib_DirEntryType > 0)
#define FIB_IS_FILE(fib)	((fib)->fib_DirEntryType < 0)

/****************************************************************************/

int
main(int argc,char **argv)
{
	static ULONG states[] =
	{
		IDS_NORMAL,
		IDS_SELECTED,
		IDS_DISABLED,
		IDS_SELECTEDDISABLED
	};
	int numStates = sizeof(states) / sizeof(states[0]);
	int state = 0;
	struct RDArgs * rda = NULL;
	int result = RETURN_FAIL;
	LONG error = OK;
	STRPTR name = NULL;
	struct Screen * screen = NULL;
	struct Window * window = NULL;
	struct DiskObject * icon = NULL;
	UWORD pens[] = { (UWORD)~0 };
	struct IntuiMessage * imsg;
	BOOL relayout;
	BOOL done;

	if(IconBase->lib_Version < 44)
	{
		Printf("Could not open icon.library V44\n");
		goto out;
	}

	rda = ReadArgs("FILE/A",(LONG *)&name,NULL);
	if(rda == NULL)
	{
		error = IoErr();
		goto out;
	}

	icon = GetIconTags(name,
		ICONGETA_RemapIcon,FALSE,
		ICONA_ErrorCode,&error,
	TAG_DONE);
	if(icon == NULL)
		goto out;

	screen = OpenScreenTags(NULL,
		SA_DisplayID,	DEFAULT_MONITOR_ID | HIRESLACE_KEY,
		SA_Depth,		4,
		SA_Title,		"icon layout test",
		SA_SysFont,		1,
		SA_Pens,		pens,
		SA_SharePens,	TRUE,
		SA_Interleaved,	TRUE,
	TAG_DONE);
	if(screen == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	LayoutIconA(icon,NULL,NULL);

	window = OpenWindowTags(NULL,
		WA_CustomScreen,	screen,
		WA_Activate,		TRUE,
		WA_DepthGadget,		TRUE,
		WA_DragBar,			TRUE,
		WA_CloseGadget,		TRUE,
		WA_SizeGadget,		TRUE,
		WA_InnerWidth,		10 + icon->do_Gadget.Width,
		WA_InnerHeight,		10 + icon->do_Gadget.Height,
		WA_IDCMP,			IDCMP_CLOSEWINDOW | IDCMP_NEWSIZE | IDCMP_VANILLAKEY,
		WA_MaxWidth,		screen->Width,
		WA_MaxHeight,		screen->Height,
	TAG_DONE);
	if(window == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	WindowLimits(window,
		window->BorderLeft + 10 + window->BorderRight,
		window->BorderTop + 10 + window->BorderBottom,
		0,0);

	relayout = TRUE;
	done = FALSE;

	do
	{
		if(relayout)
		{
/*			if(LayoutIcon(icon,screen,OBP_Precision,PRECISION_EXACT,TAG_DONE))*/
			if(LayoutIconA(icon,NULL,NULL))
			{
				struct Region * newRegion;

				newRegion = NewRegion();
				if(newRegion != NULL)
				{
					struct Rectangle rect;
					
					LockLayerRom(window->WLayer);

					rect.MinX = window->BorderLeft;
					rect.MinY = window->BorderTop;
					rect.MaxX = window->Width - (window->BorderRight + 1);
					rect.MaxY = window->Height - (window->BorderBottom + 1);

					if(OrRectRegion(newRegion,&rect))
					{
						struct Region * oldRegion;

						oldRegion = InstallClipRegion(window->WLayer,newRegion);
						DrawIconStateA(window->RPort,icon,NULL,window->BorderLeft,window->BorderTop,states[state],NULL);
						InstallClipRegion(window->WLayer,oldRegion);
					}

					UnlockLayerRom(window->WLayer);

					DisposeRegion(newRegion);
				}
			}

			relayout = FALSE;
		}

		WaitPort(window->UserPort);

		while((imsg = (struct IntuiMessage *)GetMsg(window->UserPort)) != NULL)
		{
			if(imsg->Class == IDCMP_CLOSEWINDOW)
				done = TRUE;

			if(imsg->Class == IDCMP_NEWSIZE)
				relayout = TRUE;

			if(imsg->Class == IDCMP_VANILLAKEY)
			{
				state = (state + 1) % numStates;

				relayout = TRUE;
			}

			ReplyMsg((struct Message *)imsg);
		}
	}
	while(NOT done);

	result = RETURN_OK;

 out:

	if(icon != NULL)
		FreeDiskObject(icon);

	if(window != NULL)
		CloseWindow(window);

	if(screen != NULL)
		CloseScreen(screen);

	FreeArgs(rda);

	if(error != OK)
		PrintFault(error,FilePart(argv[0]));

	return(result);
}
