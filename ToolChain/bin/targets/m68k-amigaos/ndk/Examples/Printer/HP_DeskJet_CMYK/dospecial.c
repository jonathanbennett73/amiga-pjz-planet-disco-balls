/*
 * $Id: dospecial.c 44.4 1999/09/13 13:37:33 olsen Exp olsen $
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

/* This table will be used to translate ISO colours
 * into PCL colours.
 */
STATIC UBYTE ColourTable[10] =
{
	/* 0 = black */		1,
	/* 1 = red */		12,
	/* 2 = green */		10,
	/* 3 = yellow */	8,
	/* 4 = blue */		6,
	/* 5 = magenta */	4,
	/* 6 = cyan */		2,
	/* 7 = white */		0,
	/* 8 = NC */		1,	/* make it black */
	/* 9 = default */	1	/* we use black */
};

/****************************************************************************/

LONG __stdargs __saveds
DoSpecial(
	UWORD *	command,
	UBYTE	output_buffer[],
	BYTE *	current_line_position,
	BYTE *	current_line_spacing,
	BYTE *	crlf_flag,
	UBYTE	params[])
{
	STATIC LONG text_length,top_margin;

	LONG lines_per_inch;
	LONG page_size;
	LONG page_format;
	LONG pitch;
	LONG print_quality;
	LONG result = 0;
	LONG colour;

	switch((*command))
	{
		/* Initialize */
		case aRIN:

			/* Tell the printer what size paper to use. */
			if(PD->pd_Preferences.PrintSpacing == EIGHT_LPI)
				lines_per_inch = 8;
			else
				lines_per_inch = 6;

			/* NOTE: paper sizes are one inch smaller than the
			 *       real page size to account for the size of
			 *       the printable page area.
			 */
			switch(PD->pd_Preferences.PaperSize)
			{
				case US_LETTER:

					page_size = 10 * lines_per_inch;
					page_format = 2;
					break;

				case US_LEGAL:

					page_size = 13 * lines_per_inch;
					page_format = 3;
					break;

				case EURO_A3:

					page_size = 16 * lines_per_inch;
					page_format = 27;

					break;

				case EURO_A4:

					page_size = 11 * lines_per_inch;
					page_format = 26;

					break;

				default:

					page_size = 0;
					page_format = 0;

					break;
			}

			/* Select the page format and pick the right
			 * page length. For the CUSTOM paper size,
			 * don't set the page format.
			 */
			if(page_size != 0)
			{
				SPrintf(output_buffer,
					"\033&l"	/* select page size and format */
					"%ldA",		/* page format */
					page_format);

				text_length = page_size;
			}
			else
			{
				strcpy(output_buffer,"");

				text_length = PD->pd_Preferences.PaperLength;
			}

			if(PD->pd_Preferences.PrintPitch == ELITE)
				pitch = 12;
			else if (PD->pd_Preferences.PrintPitch == FINE)
				pitch = 15;
			else
				pitch = 10;

			if(PD->pd_Preferences.PrintQuality == LETTER)
				print_quality = 2;
			else
				print_quality = 1;

			top_margin = 2;

			SPrintf(&output_buffer[strlen(output_buffer)],
				"\033&d@"		/* disable underline */
				"\033&l"		/* select page size and format */
				"%ldD"			/* number of lines per inch */
				"\033(0N"		/* primary font encoding = ISO 8859-1 */
				"\033(s"		/* begin font selection */
				"0b"			/* primary font stroke weight = medium */
				"%ldh"			/* primary pitch */
				"%ldq"			/* print quality */
				"0p"			/* primary spacing = fixed */
				"0s"			/* primary style = upright */
				"3t"			/* primary font = courier */
				"0u"			/* font placement = normal */
				"12V"			/* point size = 12 */
				"\r"			/* return to start of line (carriage return) */
				"%s"			/* select text colour */
				"\033&l"		/* select page size and format */
				"1l"			/* enable perforation skip */
				"%lde"			/* set top margin */
				"%ldF"			/* set text length */
				"\033&a"		/* set horizontal margins */
				"%ldl"			/* set left margin */
				"%ldM"			/* set right margin */
				"\r",			/* return to start of line (carriage return) */
				lines_per_inch,
				pitch,
				print_quality,
				(CONFIG_SUPPORTS_COLOR) ? "\033*r-4U\033*v1S" : "", /* select black text */
				top_margin,
				text_length,
				MAX(1,PD->pd_Preferences.PrintLeftMargin) - 1,
				MAX(1,PD->pd_Preferences.PrintRightMargin) - 1);

			result = strlen(output_buffer);
			break;

		/* Set left and right margins */
		case aSLRM:

			SPrintf(output_buffer,
				"\033&a"				/* set horizontal margins */
				"%ldl"					/* set left margin */
				"%ldM"					/* set right margin */
				"\r",					/* return to start of line (carriage return) */
			   	MAX(1,params[0]) - 1,	/* left margin */
			   	MAX(1,params[1]) - 1);	/* right margin */

			result = strlen(output_buffer);
			break;

		/* Superscript on */
		case aSUS2:

			if((*current_line_position) == 0) /* Vertical position == normal? */
			{
				/* Partial line up */
				(*command) = aPLU;
				(*current_line_position) = 1;
			}
			else if((*current_line_position) < 0) /* Vertical position == lowered? */
			{
				/* Reverse line feed */
				(*command) = aRI;
				(*current_line_position) = 1;
			}

			break;

		/* Superscript off */
		case aSUS1:

			if((*current_line_position) > 0) /* Vertical position == raised? */
			{
				/* Partial line down */
				(*command) = aPLD;
				(*current_line_position) = 0;
			}

			break;

		/* Subscript on */
		case aSUS4:

			if((*current_line_position) == 0) /* Vertical position == normal? */
			{
				/* Partial line down */
				(*command) = aPLD;
				(*current_line_position) = -1;
			}
			else if ((*current_line_position) > 0) /* Vertical position == raised? */
			{
				/* Line feed */
				(*command) = aIND;
				(*current_line_position) = -1;
			}

			break;

		/* Subscript off */
		case aSUS3:

			if((*current_line_position) < 0) /* Vertical position = lowered? */
			{
				/* Partial line up */
				(*command) = aPLU;
				(*current_line_position) = 0;
			}

			break;

		/* Normalize the line */
		case aSUS0:

			if((*current_line_position) > 0) /* raised */
				(*command) = aPLD;	/* Partial line down */
			else if ((*current_line_position) < 0) /* lowered */
				(*command) = aPLU;	/* Partial line up */

			(*current_line_position) = 0;

			break;

		/* Partial line up. */
		case aPLU:

			(*current_line_position)++;
			break;

		/* Partial line down */
		case aPLD:

			(*current_line_position)--;
			break;

		/* Set top and bottom margins. */
		case aSTBM:

			if(params[0] == 0)
				params[0] = top_margin;
			else
				top_margin = params[0] - 1;

			if(params[1] == 0)
				params[1] = text_length;
			else
				text_length = params[1];

			SPrintf(output_buffer,
				"\033&l"				/* select page size and format */
				"%lde"					/* set top margin */
				"%ldF",					/* set text length */
				params[0],				/* top margin */
			   	params[1] - params[0]);	/* text length */

			result = strlen(output_buffer);
			break;

		/* Set form length */
		case aSLPP:

			/* Restore text length and top margin. */

			SPrintf(output_buffer,
				"\033&l"		/* select page size and format */
				"%lde"			/* set top margin */
				"%ldF",			/* set text length */
				top_margin,
			   	text_length);

			result = strlen(output_buffer);
			break;

		/* Reset */
		case aRIS:

			PD->pd_PWaitEnabled = 253;
			break;

		/* Select foreground colour */
		case aSFC:

			if(CONFIG_SUPPORTS_COLOR)
			{
				if(PD->pd_Preferences.PrintShade == SHADE_COLOR)
				{
					if (params[0] < 30)
						colour = 30;
					else if (params[0] > 39)
						colour = 39;
					else
						colour = params[0];
				}
				else
				{
					/* If not in colour mode, use the
					 * default foreground colour.
					 */
					colour = 39;
				}

				SPrintf(output_buffer,
					"\033*r-4U"
					"\033*v%ldS",
				   	ColourTable[colour - 30]);

				result = strlen(output_buffer);
			}

			break;
	}

	return(result);
}

/****************************************************************************/

LONG __stdargs __saveds
ConvFunc(
	UBYTE *	buf,
	UBYTE	c,
	LONG	crlf_flag) /* expand lf into lf/cr flag (0-yes, else no ) */
{
	if(c == '\f') /* if formfeed (page eject) */
		PED->ped_PrintMode = 0; /* no data to print */
	else if (c > ' ')
		PED->ped_PrintMode = 1; /* alpha data has been sent */

	return(-1); /* pass all chars back to the printer device */
}
