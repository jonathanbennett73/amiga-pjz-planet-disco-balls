#include <workbench/workbench.h>
#include <clib/icon_protos.h>
#include <clib/dos_protos.h>

int
main(int argc,char **argv)
{
	struct DiskObject *icon = NULL;

	if(argc > 1)
	{
		icon = GetDiskObject(argv[1]);
		if(icon != NULL)
		{
			STRPTR found;
			int i;

			for(i = 2 ; i < argc ; i++)
			{
				found = FindToolType(icon->do_ToolTypes,argv[i]);
				if(found != NULL)
					Printf("%s = \"%s\"\n",argv[i],found);
				else
					Printf("%s not found.\n",argv[i]);
			}
		}
	}

	FreeDiskObject(icon);

	return(0);
}
