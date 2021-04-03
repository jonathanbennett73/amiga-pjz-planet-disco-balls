/*
 * $Id: sprintf.c 44.1 1999/08/27 18:32:42 olsen Exp olsen $
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

/*****************************************************************************/

VOID
VSPrintf(STRPTR buffer, STRPTR formatString, va_list varArgs)
{
	RawDoFmt(formatString,varArgs,(VOID (*)())"\x16\xC0\x4E\x75",buffer);
}

VOID
SPrintf(STRPTR buffer, STRPTR formatString, ...)
{
	va_list varArgs;

	va_start(varArgs,formatString);
	VSPrintf(buffer, formatString, varArgs);
	va_end(varArgs);
}
