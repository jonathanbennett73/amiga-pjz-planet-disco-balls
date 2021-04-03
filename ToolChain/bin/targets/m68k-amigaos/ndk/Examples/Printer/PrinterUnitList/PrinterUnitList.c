/*
 * COPYRIGHT:
 *
 *   Unless otherwise noted, all files are Copyright (c) 1999 Amiga, Inc.
 *   All rights reserved.
 *
 * DISCLAIMER:
 *
 *   This software is provided "as is". No representations or warranties
 *   are made with respect to the accuracy, reliability, performance,
 *   currentness, or operation of this software, and all use is at your
 *   own risk. Neither Amiga nor the authors assume any responsibility
 *   or liability whatsoever with respect to your use of this software.
 */


/* includes */
#include <dos/dos.h>
#include <libraries/iffparse.h>
#include <prefs/prefhdr.h>
#include <prefs/printertxt.h>

/* prototypes */
#include <clib/iffparse_protos.h>
#include <clib/dos_protos.h>
#include <clib/alib_protos.h>
#include <clib/alib_stdio_protos.h>
#include <string.h>

BPTR stdout;

/*****************************************************************************/

#define IFFPrefChunkCnt 2
static LONG IFFPrefChunks[] =
{
	ID_PREF, ID_PRHD,
	ID_PREF, ID_PDEV,
};

void ReadUnitName(char *filename, char name[], int unitnum)
{
	BPTR fp;
	BOOL ok;
	struct IFFHandle *iff;
	struct ContextNode *cn;
	struct PrefHeader phead;
	struct PrinterDeviceUnitPrefs pdev;

	sprintf(name,"Unit %ld",unitnum);
	if (fp = Open(filename, MODE_OLDFILE))
	{
		if (iff = AllocIFF())
		{
			iff->iff_Stream = fp;
			InitIFFasDOS(iff);

			if (!OpenIFF(iff, IFFF_READ))
			{
				if (!ParseIFF(iff, IFFPARSE_STEP))
				{
					cn = CurrentChunk(iff);
					if (cn->cn_ID == ID_FORM && cn->cn_Type == ID_PREF)
					{
						if (!StopChunks(iff, IFFPrefChunks, IFFPrefChunkCnt))
						{
							ok = TRUE;
							while (ok)
							{
								if (ParseIFF(iff, IFFPARSE_SCAN))
									break;
								cn = CurrentChunk(iff);
								if (cn->cn_Type == ID_PREF)
								{
									switch (cn->cn_ID)
									{
										case ID_PRHD:
											if (ReadChunkBytes(iff, &phead, sizeof(struct PrefHeader)) != sizeof(struct PrefHeader))
											{
												ok = FALSE;
												break;
											}
											if (phead.ph_Version != 0)
											{
												ok = FALSE;
												break;
											}
											break;
										case ID_PDEV:
											if (ReadChunkBytes(iff, &pdev, sizeof(pdev)) == sizeof(pdev))
											{
												if (pdev.pd_UnitName[0])
													strcpy(name,pdev.pd_UnitName);
											}
											break;
										default:
											break;
									}
								}
							}
						}
					}
				}
				CloseIFF(iff);
			}
			FreeIFF(iff);
		}
		Close(fp);
	}
}

void main(void)
{
	char filename[30];
	char name[UNITNAMESIZE];
	int i;

	stdout = Output();
	ReadUnitName("ENV:Sys/printer.prefs",name,0);
	printf("Printer Unit Names:\n 0: %s\n",name);
	strcpy(filename,"ENV:Sys/printerN.prefs");
	for (i = 1; i < 10; i++)
	{
		filename[15] = '0' + i;
		ReadUnitName(filename,name,i);
		printf(" %ld: %s\n",i,name);
	}
}
