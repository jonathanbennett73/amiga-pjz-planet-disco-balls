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


#include <devices/printer.h>
#include <datatypes/datatypesclass.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/alib_stdio_protos.h>
#include <clib/alib_protos.h>
#include <stdlib.h>

extern "C" void kprintf(const char *, ...);
extern "C" void HookEntry();

// *************************************************************

BPTR stdout;

static int consolehook(struct Hook *, struct IORequest *, struct PrtErrMsg *msg)
{
	kprintf("%s: %s\n",msg->pe_ES->es_Title,msg->pe_ES->es_TextFormat);
	puts(msg->pe_ES->es_Title);
	puts(": ");
	printf(msg->pe_ES->es_TextFormat,((ULONG *) msg->pe_ArgList)[0]);
	return 0;
}

static struct Hook ConsoleHook =
{
	{ NULL, NULL },
	(HOOKFUNC) HookEntry,
	(HOOKFUNC) consolehook,
	NULL
};

// *************************************************************

union IOPrinterReq
{
	struct IORequest ior;
	struct IOStdReq sio;
	struct IOPrtErrReq per;
	struct IOPrtPrefsReq prq;
	struct IODRPReq drp;
};

// *************************************************************

static BOOL Opened;
static UBYTE PrefsBuf[8192];
static ULONG PrefsLen;

static void ClosePrinter(union IOPrinterReq *ior)
{
	if (Opened)
	{
		ior->per.io_Command = PRD_SETERRHOOK;
		ior->per.io_Hook = PDHOOK_NONE;
		DoIO(&ior->ior);
		CloseDevice(&ior->ior);
		Opened = FALSE;
	}
}

static int OpenPrinter(union IOPrinterReq *ior, int unit, BOOL wb)
{
	int err;
	if (Opened)
		return 0;
	if (err = OpenDevice("printer.device",unit,&ior->ior,0))
		return err;
	ior->per.io_Command = PRD_SETERRHOOK;
	ior->per.io_Hook = wb ? PDHOOK_STD : &ConsoleHook;
	if (err = DoIO(&ior->ior))
	{
		CloseDevice(&ior->ior);
		return err;
	}
	Opened = TRUE;
	if (PrefsLen)
	{
		ior->sio.io_Command = PRD_WRITEPREFS;
		ior->sio.io_Length = PrefsLen;
		ior->sio.io_Data = PrefsBuf;
		if (err = DoIO(&ior->ior))
		{
			ClosePrinter(ior);
		}
	}
	return err;
}

// *************************************************************

int printfile(STRPTR file, union IOPrinterReq *ior, int unit, BOOL wb)
{
	Object *o;
	if (OpenPrinter(ior,unit,wb))
		return 0;
	o = NewDTObject(file,
		DTA_SourceType,DTST_FILE,
		TAG_END);
	if (!o)
	{
		ClosePrinter(ior);
		return IoErr();
	}
	DoMethod(o,
		DTM_PRINT,
		NULL,
		ior,
		NULL);
	DisposeDTObject(o);
	ClosePrinter(ior);
	return 0;
}

void main(void)
{
	LONG err = 0;
	LONG rc = 0;
	LONG args[5] = { };
	struct RDArgs *rdargs;
	stdout = Output();
	rdargs = ReadArgs("FILE/A/M,OPTIONS/S",args,NULL);
	if (rdargs)
	{
		struct MsgPort *port = CreateMsgPort();
		if (port)
		{
			union IOPrinterReq *ior = (union IOPrinterReq *) CreateIORequest(port,sizeof(union IOPrinterReq));
			if (ior)
			{
				if (!OpenPrinter(ior,0,FALSE))
				{
					STRPTR *files = (STRPTR *) args[0];
					if (args[1])
					{
						ior->prq.io_Command = PRD_EDITPREFS;
						ior->prq.io_TagList = NULL;
						if (err = DoIO(&ior->ior))
						{
							if (err != PDERR_CANCEL)
								rc = 10;
							err = 0;
							ClosePrinter(ior);
							goto abortprint;
						}
					}
					ior->sio.io_Command = PRD_READPREFS;
					ior->sio.io_Length = sizeof(PrefsBuf);
					ior->sio.io_Data = PrefsBuf;
					ior->sio.io_Offset = 0;
					if (DoIO(&ior->ior))
					{
						ClosePrinter(ior);
						goto abortprint;
					}
					PrefsLen = ior->sio.io_Actual;
					ClosePrinter(ior);
					while (*files)
					{
						if (err = printfile(*files,ior,0,FALSE))
							break;
						files++;
					}
abortprint:
					;
				}
				DeleteIORequest(&ior->ior);
			}
			DeleteMsgPort(port);
		}
	}
	else
	{
		err = IoErr();
		rc = 20;
	}
	if (err)
		PrintFault(err,NULL);
	exit(rc);
}
