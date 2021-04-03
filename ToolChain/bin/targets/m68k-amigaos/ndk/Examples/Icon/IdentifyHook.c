/*
 * $Id$
 *
 * :ts=4
 */

#include <datatypes/datatypes.h>

#include <dos/dosextens.h>
#include <dos/dosasl.h>

#include <exec/memory.h>

#include <workbench/workbench.h>

#include <clib/exec_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/utility_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/datatypes_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>

/****************************************************************************/

extern struct Library * DataTypesBase;
extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * IconBase;

/****************************************************************************/

#include "/icon.h"
#include "/PROTOS/public_icon_protos.h"
#include "/PRAGMAS/public_icon_pragmas.h"

/****************************************************************************/

struct DiskObject * __saveds __asm
IdentifyHookFunc(
	register __a0 struct Hook *				h,
	register __a2 APTR						unused,
	register __a1 struct IconIdentifyMsg *	iim)
{
	struct DiskObject * icon = NULL;
	struct DataType * dtn;

	dtn = ObtainDataTypeA(DTST_FILE,(APTR)iim->iim_FileLock,NULL);
	if(dtn != NULL)
	{
		const struct DataTypeHeader * dth = dtn->dtn_Header;
		STRPTR type;

		switch(dth->dth_GroupID)
		{
			case GID_SYSTEM:

				type = "system";
				break;

			case GID_TEXT:

				type = "text";
				break;

			case GID_DOCUMENT:

				type = "document";
				break;

			case GID_SOUND:

				type = "sound";
				break;

			case GID_INSTRUMENT:

				type = "instrument";
				break;

			case GID_MUSIC:

				type = "music";
				break;

			case GID_PICTURE:

				type = "picture";
				break;

			case GID_ANIMATION:

				type = "animation";
				break;

			case GID_MOVIE:

				type = "movie";
				break;

			default:

				type = NULL;
				break;
		}

		ReleaseDataType(dtn);

		if(type != NULL)
		{
			icon = GetIconTags(NULL,
				ICONGETA_GetDefaultName,type,
			TAG_MORE,iim->iim_Tags);
		}
	}

	return(icon);
}

struct Hook IdentifyHook =
{
	{NULL},
	(HOOKFUNC)IdentifyHookFunc
};

/****************************************************************************/

int
main(int argc,char **argv)
{
	if(IconBase->lib_Version < 44)
	{
		Printf("Could not open icon.library V44\n");
		goto out;
	}

	IconControl(NULL,
		ICONCTRLA_SetGlobalIdentifyHook,&IdentifyHook,
	TAG_DONE);

	Printf("Icon identification hook installed; ^C to remove.");
	Flush(Output());
	Wait(SIGBREAKF_CTRL_C);

	IconControl(NULL,
		ICONCTRLA_SetGlobalIdentifyHook,NULL,
	TAG_DONE);

	Printf(" Done.\n");

 out:

	return(0);
}
