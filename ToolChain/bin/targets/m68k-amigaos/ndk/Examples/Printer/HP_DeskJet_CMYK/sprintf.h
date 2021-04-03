/*
 * $Id: sprintf.h 44.1 1999/08/27 15:02:11 olsen Exp olsen $
 *
 * :ts=8
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

/****************************************************************************/

extern VOID VSPrintf(STRPTR buffer, STRPTR formatString, va_list varArgs);
extern VOID SPrintf(STRPTR buffer, STRPTR formatString, ...);

/****************************************************************************/
