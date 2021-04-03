/*
 * $Id$
 *
 * :ts=4
 */

#include <dos/dosextens.h>
#include <dos/dosasl.h>
#include <dos/rdargs.h>

#include <exec/memory.h>

#include <workbench/workbench.h>

#include <clib/exec_protos.h>
#include <clib/utility_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>

/****************************************************************************/

extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * UtilityBase;
extern struct Library * IconBase;

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
	struct RDArgs * rda = NULL;
	struct AnchorPath * ap;
	int result = RETURN_FAIL;
	STRPTR * names = NULL;
	BOOL matched = FALSE;
	LONG error = OK;
	STRPTR str;

	if(IconBase->lib_Version < 44)
	{
		Printf("Could not open icon.library V44\n");
		goto out;
	}

	rda = ReadArgs("FILES/A/M",(LONG *)&names,NULL);
	if(rda == NULL)
	{
		error = IoErr();
		goto out;
	}

	ap = AllocVec(sizeof(*ap) + MAX_PATH_LEN,MEMF_ANY);
	if(ap == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	while((error == OK) && (str = (*names++)) != NULL)
	{
		memset(ap,0,sizeof(*ap));

		ap->ap_BreakBits = SIGBREAKF_CTRL_C;	
		ap->ap_Strlen = MAX_PATH_LEN;

		matched = TRUE;

		error = MatchFirst(str,ap);
		if(error == OK)
		{
			if(FIB_IS_DRAWER(&ap->ap_Info))
			{
				ap->ap_Flags |= APF_DODIR;

				error = MatchNext(ap);
				ap->ap_Flags &= ~APF_DIDDIR;
			}

			while(error == OK)
			{
				STRPTR name;
				int len;

				name = ap->ap_Buf;
				len = strlen(name);

				if(len < strlen(".info") || Stricmp(&name[len - strlen(".info")],".info") != SAME)
				{
					struct DiskObject * icon;
					LONG why;

					Printf("Getting icon for \"%s\"... ",name);
					Flush(Output());

					icon = GetIconTags(name,
						ICONA_ErrorCode,&why,
					TAG_DONE);

					if(icon != NULL)
					{
						Printf("writing it back... ");
						Flush(Output());

						if(PutIconTags(name,icon,
							ICONPUTA_DropNewIconToolTypes,TRUE,
							ICONPUTA_DropChunkyIconImage,TRUE,
							ICONPUTA_NotifyWorkbench,TRUE,
							ICONA_ErrorCode,&why,
						TAG_DONE))
						{
							Printf("ok.\n");
						}

						FreeDiskObject(icon);
					}

					if(why != OK)
					{
						UBYTE errorString[100];
						int len;

						Fault(why,NULL,errorString,sizeof(errorString));

						len = strlen(errorString);
						while(len > 0 && errorString[len-1] == '\n')
							errorString[--len] = '\0';

						Printf("failed (%s).\n",errorString);
					}
				}

				error = MatchNext(ap);
			}
		}

		if(error == ERROR_NO_MORE_ENTRIES)
			error = OK;

		MatchEnd(ap);
		matched = FALSE;
	}

	if(error == OK)
		result = RETURN_OK;
	else if (error == ERROR_BREAK)
		result = RETURN_WARN;
	else
		result = RETURN_ERROR;

 out:

	if(matched)
		MatchEnd(ap);

	FreeVec(ap);
	FreeArgs(rda);

	if(error != OK)
		PrintFault(error,FilePart(argv[0]));

	return(result);
}
