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
#include <clib/graphics_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/graphics_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>

/****************************************************************************/

extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * UtilityBase;
extern struct Library * GfxBase;
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

UBYTE MagicWBPalette[8 * 3] =
{
	0x96,0x96,0x96,
	0x00,0x00,0x00,
	0xFF,0xFF,0xFF,
	0x3D,0x65,0xA2,
	0x79,0x79,0x79,
	0xAE,0xAE,0xAE,
	0xAA,0x92,0x7D,
	0xFF,0xAA,0x96
};

/****************************************************************************/

VOID
ImageToBitMap(
	struct Image *	image,
	struct BitMap *	bitMap)
{
	PLANEPTR plane;
	LONG pageSize;
	LONG i;

	memset(bitMap,0,sizeof(*bitMap));

	bitMap->BytesPerRow	= RASSIZE(image->Width,1);
	bitMap->Rows		= image->Height;
	bitMap->Depth		= image->Depth;

	pageSize = RASSIZE(image->Width,image->Height);
	plane = (PLANEPTR)image->ImageData;

	for(i = 0 ; i < image->Depth ; i++)
	{
		bitMap->Planes[i] = plane;

		plane += pageSize;
	}
}

/****************************************************************************/

int
main(int argc,char **argv)
{
	struct RDArgs * rda = NULL;
	struct AnchorPath * ap;
	STRPTR buffer = NULL;
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

	buffer = AllocVec(MAX_PATH_LEN,MEMF_ANY);
	if(buffer == NULL)
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
				int len;

				strcpy(buffer,ap->ap_Buf);
				len = strlen(buffer);

				error = MatchNext(ap);

				if(len < strlen(".info") || Stricmp(&buffer[len - strlen(".info")],".info") != SAME)
				{
					struct DiskObject * icon;
					LONG why;

					Printf("Getting icon for \"%s\"... ",buffer);
					Flush(Output());

					icon = GetIconTags(buffer,
						ICONA_ErrorCode,&why,
					TAG_DONE);

					if(icon != NULL)
					{
						LONG isPaletteMapped;

						IconControl(icon,
							ICONCTRLA_IsPaletteMapped,&isPaletteMapped,
						TAG_DONE);

						if(isPaletteMapped)
						{
							IconControl(icon,
								ICONCTRLA_SetFrameless,TRUE,
							TAG_DONE);

							Printf("writing it back... ");
							Flush(Output());
	
							if(PutIconTags(buffer,icon,
								ICONPUTA_DropNewIconToolTypes,TRUE,
								ICONPUTA_NotifyWorkbench,TRUE,
								ICONA_ErrorCode,&why,
							TAG_DONE))
							{
								Printf("ok.\n");
							}
						}
						else
						{
							Printf("not a palette mapped icon.\n");
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
	FreeVec(buffer);
	FreeArgs(rda);

	if(error != OK)
		PrintFault(error,FilePart(argv[0]));

	return(result);
}
