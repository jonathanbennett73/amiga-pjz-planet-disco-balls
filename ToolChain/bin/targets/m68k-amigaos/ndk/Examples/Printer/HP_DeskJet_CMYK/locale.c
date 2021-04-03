/*
 * $Id: locale.c 44.2 1999/09/29 14:03:20 olsen Exp olsen $
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

#define CATCOMP_ARRAY
#include "global.h"

/****************************************************************************/

struct Library * LocaleBase;
struct Catalog * Catalog;

/****************************************************************************/

VOID
LocaleCleanup(VOID)
{
	if(LocaleBase != NULL)
	{
		CloseCatalog(Catalog);
		Catalog = NULL;

		CloseLibrary(LocaleBase);
		LocaleBase = NULL;
	}
}

/****************************************************************************/

VOID
LocaleSetup(VOID)
{
	LONG i;

	LocaleBase = OpenLibrary("locale.library",38);
	if(LocaleBase != NULL)
		Catalog = OpenCatalog(NULL,"sys/devs.catalog",NULL);

	for(i = 1 ; i <= 7 ; i++)
		DensityNames[i] = Quote(MSG_HPDJ_DENSITY1_TXT+i-1);
}

/****************************************************************************/

STRPTR
Quote(LONG id)
{
	STRPTR result = NULL;
	LONG i;

	for(i = 0 ; i < NUM_ENTRIES(CatCompArray) ; i++)
	{
		if(CatCompArray[i].cca_ID == id)
		{
			result = CatCompArray[i].cca_Str;
			break;
		}
	}

	if(result != NULL)
	{
		if(LocaleBase != NULL && Catalog != NULL)
			result = GetCatalogStr(Catalog,id,result);
	}
	else
	{
		result = "";
	}

	return(result);
}
