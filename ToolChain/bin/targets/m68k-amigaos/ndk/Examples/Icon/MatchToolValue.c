#include <workbench/workbench.h>
#include <clib/icon_protos.h>
#include <clib/dos_protos.h>

int
main(int argc,char **argv)
{
	if(argc > 1)
	{
		BOOL result;
		int i;

		for(i = 2 ; i < argc ; i++)
		{
			result = MatchToolValue(argv[1],argv[i]);

			Printf("MatchToolValue(\"%s\",\"%s\") = %s\n",
				argv[1],argv[i],result ? "TRUE" : "FALSE");
		}
	}

	return(0);
}
