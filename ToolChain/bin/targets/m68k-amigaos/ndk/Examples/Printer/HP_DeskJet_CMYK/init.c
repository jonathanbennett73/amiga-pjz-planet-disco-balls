/*
 * $Id: init.c 44.2 1999/09/16 09:18:27 olsen Exp olsen $
 *
 * :ts=4
 *
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
 *
 */

#include "global.h"

/****************************************************************************/

VOID __stdargs __saveds
DriverExpunge(VOID)
{
	LocaleCleanup();

	if(UtilityBase != NULL)
	{
		CloseLibrary(UtilityBase);
		UtilityBase = NULL;
	}
}

VOID __stdargs __saveds
DriverInit(struct PrinterData * pd)
{
	SysBase			= AbsExecBase;
	UtilityBase		= OpenLibrary("utility.library",37);
	PED				= &PEDData;
	PD				= pd;
	PWrite			= (PWRITE_T)pd->pd_PWrite;
	PBothReady		= (PBOTHREADY_T)pd->pd_PBothReady;

	LocaleSetup();
}

VOID __stdargs __saveds
DriverClose(struct printerIO *ior)
{
	/* if data has been printed */
	if(PED->ped_PrintMode)
	{
		(*PWrite)("\014",1);	/* eject page */
		(*PBothReady)();		/* wait for it to finish */
		PED->ped_PrintMode = 0;	/* no data to print */
	}
}

LONG __stdargs __saveds
DriverOpen(struct printerIO *ior)
{
	LONG result = ERROR;

	if(UtilityBase != NULL && PD->pd_Device.dd_Device.lib_Version >= 44)
		result = OK;

	return(result);
}
