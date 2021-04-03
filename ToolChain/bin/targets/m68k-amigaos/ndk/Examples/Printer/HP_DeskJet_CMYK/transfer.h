/*
 * $Id: transfer.h 44.4 1999/09/06 15:36:05 olsen Exp olsen $
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

/****************************************************************************/

typedef short SAMPLE_T;

/****************************************************************************/

typedef struct
{
	LONG		dd_SamplesPerLine;
	SAMPLE_T **	dd_Lines;
	LONG		dd_NumLines;
	LONG		dd_Seed;
	BOOL		dd_Reverse;
} DITHERDATA_T;

/****************************************************************************/

VOID Transfer(struct PrtInfo * PInfo,union colorEntry *	ColorInt,LONG y,UBYTE * ptr,DITHERDATA_T * dd,int component);

/****************************************************************************/

DITHERDATA_T * CreateDitherData(LONG samplesPerLine,LONG numLines,LONG pad);
VOID DeleteDitherData(DITHERDATA_T * dd);
