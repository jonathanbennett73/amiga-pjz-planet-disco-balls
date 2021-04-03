#include <workbench/workbench.h>
#include <clib/icon_protos.h>
#include <clib/dos_protos.h>

int
main(int argc,char **argv)
{
	if(argc > 1)
	{
		char buffer[40];
		int i;

		for(i = 1 ; i < argc ; i++)
		{
			BumpRevision(buffer,argv[i]);

			Printf("BumpRevision(..,\"%s\") = \"%s\"\n",
				argv[i],buffer);
		}
	}

	return(0);
}
