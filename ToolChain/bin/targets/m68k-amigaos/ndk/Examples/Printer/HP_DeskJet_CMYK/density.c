/*
 * $Id: density.c 44.6 1999/09/13 13:36:55 olsen Exp olsen $
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

#include "config.h"

/****************************************************************************/

VOID
SetDensity(ULONG density_code)
{
	STATIC const UWORD color_dpi[7] = CONFIG_COLOR_DPI;
	STATIC const UWORD bw_dpi[7]    = CONFIG_BW_DPI;

	/* Paper sizes in dots at 300 DPI */
	STATIC const ULONG PaperSizes[10][2] =
	{
		{ 2400, 3200 },	/* US_LETTER (8" x 10") */
		{ 2400, 4100 },	/* US_LEGAL (8" x 13") */
		{ 2400, 3200 },	/* N_TRACTOR = US_LETTER */
		{ 2400, 3200 },	/* W_TRACTOR = US_LETTER */
		{ 2400, 3200 },	/* CUSTOM = US_LETTER */

		{    0,    0 },	/* EURO_A0 (ignored) */
		{    0,    0 },	/* EURO_A1 (ignored) */
		{    0,    0 },	/* EURO_A2 (ignored) */
		{ 3365, 4860 },	/* EURO_A3 (11" x 16") */
		{ 2338, 3407 }	/* EURO_A4 ( 7" x 11") */
	};

	/* Calculate max dots based on paper size selection */
	ULONG max_width,max_height;
	LONG paper_size;
	LONG density_index;
	LONG paper_index;

	/* Don't allow for a page size beyond A4. */
	paper_size = (PD->pd_Preferences.PaperSize & 0xFF);
	if(paper_size > EURO_A4)
		paper_size = EURO_A4;
	else if (paper_size < EURO_A3 && EURO_A0 <= paper_size)
		paper_size = EURO_A3;

	paper_index = paper_size >> 4;

	max_width  = PaperSizes[paper_index][0];
	max_height = PaperSizes[paper_index][1];

	/* Map the density (SPECIAL_DENSITY1..SPECIAL_DENSITY7)
	 * to a table index (0..6).
	 */
	density_index = ((density_code & SPECIAL_DENSITYMASK) >> 8) - 1;

	if(CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR)
	{
		PED->ped_XDotsInch = color_dpi[density_index];
		PED->ped_YDotsInch = color_dpi[density_index];
	}
	else
	{
		PED->ped_XDotsInch = bw_dpi[density_index];
		PED->ped_YDotsInch = bw_dpi[density_index];
	}

	/* Calculate the page sizes; defaults are given for 300 DPI
	 * which will need to be scaled for different resolutions.
	 */
	PED->ped_MaxXDots = (max_width	* PED->ped_XDotsInch) / 300;
	PED->ped_MaxYDots = (max_height	* PED->ped_YDotsInch) / 300;

	/* Increase timeout for 300/600 DPI dumps */
	if(PED->ped_MaxXDots == 600)
		PED->ped_TimeoutSecs = 120;
	else if (PED->ped_MaxXDots == 300)
		PED->ped_TimeoutSecs = 60;
	else
		PED->ped_TimeoutSecs = 30;
}
