/*
 * $Id: data.h 44.7 1999/09/16 09:20:01 olsen Exp olsen $
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

typedef LONG (* __stdargs PWRITE_T)(char *str,int len);
typedef VOID (* PBOTHREADY_T)(VOID);

/****************************************************************************/

extern PWRITE_T PWrite;
extern PBOTHREADY_T PBothReady;

/****************************************************************************/

extern struct Library * SysBase;
extern struct Library * UtilityBase;

/****************************************************************************/

extern struct PrinterExtendedData * PED;
extern struct PrinterData * PD;

/****************************************************************************/

extern STRPTR CommandTable[aRAW+1];
extern STRPTR ExtendedCharTable[96];
extern STRPTR DensityNames[8];
extern struct TagItem PropertyTagList[];
extern UBYTE GammaTables[15][256];

/****************************************************************************/
