/*
 * $Id: render.c 44.7 1999/09/22 19:48:18 olsen Exp olsen $
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

/* These are for dithering with error dispersion; we reserve space for up to
 * four colour components. For the monochrome driver, only one will
 * be used, though.
 */
STATIC DITHERDATA_T * dither_data[PCMBLACK-PCMYELLOW+1];

/****************************************************************************/

/* These buffers are for transferring the raster data to the printer. */
STATIC UBYTE * print_buffers[2 * (PCMBLACK-PCMYELLOW+1)];
STATIC LONG current_print_buffer;
STATIC LONG num_print_buffers;

/****************************************************************************/

/* This buffer will be used for colour correction. */
union colorEntry * colour_correction_buffer;

/****************************************************************************/

/* Number of bytes in a row of raster data. */
STATIC LONG num_bytes_per_row;

/****************************************************************************/

/* Source buffers for doing data compression; must be large enough to
 * hold a single line of bitmap graphics. We reserve space for up to
 * four colour components. For the monochrome driver, only one will
 * be used, though.
 */
STATIC UBYTE * render_buffer[PCMBLACK-PCMYELLOW+1];

/****************************************************************************/

/* For composing the printer commands. */
#define COMMAND_BUFFER_SIZE 256

STATIC UBYTE command_buffers[2][COMMAND_BUFFER_SIZE];
STATIC LONG current_command_buffer;

/****************************************************************************/

/* Gamma correction table to use. */
STATIC UBYTE * gamma_table;

/****************************************************************************/

/* Send a command to the printer; this uses one of two
 * buffers, to take advantage of double-buffer I/O.
 */
STATIC LONG
SendPrinterCommand(UBYTE * fmt,...)
{
	UBYTE * buffer = command_buffers[current_command_buffer];
	va_list varArgs;
	LONG error;

	va_start(varArgs,fmt);
	VSPrintf(buffer,fmt,varArgs);
	va_end(varArgs);

	error = (*PWrite)(buffer,strlen(buffer));

	current_command_buffer = (1 - current_command_buffer);

	return(error);
}

/****************************************************************************/

/* This routine makes a local copy of the colour data and applies
 * gamma correction to it.
 */
STATIC VOID
CorrectColours(struct PrtInfo * pi,UBYTE * gamma_table,union colorEntry * colour_buffer)
{
	LONG x,c;

	/* Make a copy of the colour data. */
	memcpy(colour_buffer,pi->pi_ColorInt,sizeof(*colour_buffer) * pi->pi_width);

	for(x = 0 ; x < pi->pi_width ; x++)
	{
		for(c = PCMYELLOW ; c <= PCMBLACK ; c++)
			colour_buffer->colorByte[c] = gamma_table[colour_buffer->colorByte[c]];

		colour_buffer++;
	}
}

/****************************************************************************/

/* Clear each CMY pixel if there is a K pixel which
 * would cover it.
 */
STATIC VOID
ClearColour(UBYTE * render_buffer[],LONG num_bytes_per_row)
{
	UBYTE k;
	LONG i,j;

	for(i = 0 ; i < num_bytes_per_row ; i++)
	{
		k = ~render_buffer[PCMBLACK][i];

		for(j = PCMYELLOW ; j <= PCMCYAN ; j++)
			render_buffer[j][i] &= k;
	}
}

/****************************************************************************/

LONG __stdargs __saveds
Render(LONG ct,LONG x,LONG y,LONG status)
{
	LONG err = PDERR_NOERR;
	LONG i;
	int shingling;
	int depletion;
	int threshold;
	int num_components;
	struct PrtInfo * pi;
	union colorEntry * colour_buffer;

	switch(status)
	{
		/* Master Initialization */
		case 0 :
			/*	ct	- pointer to IODRPReq structure.
			 *	x	- width of printed picture in pixels.
			 *	y	- height of printed picture in pixels.
			 */
			num_bytes_per_row = (x + 7) / 8;

			/* Allocate memory for the buffer we will render into and
			 * whose contents will be compressed before they are
			 * transferred to the printer.
			 */
			if(CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR)
			{
				for(i = PCMYELLOW ; i <= PCMBLACK ; i++)
				{
					render_buffer[i] = AllocVec(num_bytes_per_row,MEMF_ANY|MEMF_PUBLIC);
					if(render_buffer[i] == NULL)
					{
						err = PDERR_BUFFERMEMORY; /* not enough memory */
						break;
					}
				}
			}
			else
			{
				render_buffer[PCMBLACK] = AllocVec(num_bytes_per_row,MEMF_ANY|MEMF_PUBLIC);
				if(render_buffer[PCMBLACK] == NULL)
				{
					err = PDERR_BUFFERMEMORY; /* not enough memory */
					break;
				}
			}

			if(err != PDERR_NOERR)
				break;

			/* Number of buffers to allocate for printing; we need
			 * twice as many as there are colour components to work
			 * with (for double-buffering).
			 */
			num_components = (CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR) ? 4 : 1;
			num_print_buffers = 2 * num_components;

			/* Now allocate the data transfer buffers. */
			for(i = 0 ; i < num_print_buffers ; i++)
			{
				print_buffers[i] = AllocVec(num_bytes_per_row,MEMF_ANY|MEMF_PUBLIC);
				if(print_buffers[i] == NULL)
				{
					err = PDERR_BUFFERMEMORY; /* not enough memory */
					break;
				}
			}

			if(err != PDERR_NOERR)
				break;

			/* If we are going to use the Floyd-Steinberg filter
			 * we'd better set up the line buffers.
			 */
			if((PD->pd_Preferences.PrintFlags & DITHERING_MASK) == FLOYD_DITHERING)
			{
				if(CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR)
				{
					for(i = PCMYELLOW ; i <= PCMBLACK ; i++)
					{
						dither_data[i] = CreateDitherData(x,2,1);
					/*	dither_data[i] = CreateDitherData(x,3,2);	*/
						if(dither_data[i] == NULL)
						{
							err = PDERR_BUFFERMEMORY; /* not enough memory */
							break;
						}
					}
				}
				else
				{
					dither_data[PCMBLACK] = CreateDitherData(x,2,1);
				/*	dither_data[PCMBLACK] = CreateDitherData(x,3,2);	*/
					if(dither_data[PCMBLACK] == NULL)
					{
						err = PDERR_BUFFERMEMORY; /* not enough memory */
						break;
					}
				}

				if(err != PDERR_NOERR)
					break;
			}

			/* Set shingling and depletion according
			 * to density:
			 *
			 * 1-3: No  depletion, no  shingling
			 *   4: 25% depletion, no  shingling
			 *   5: 25% depletion, 50% shingling
			 *   6: 25% depletion, 25% shingling
			 *   7: No  depletion, 25% shingling
			 *
			 * Case 7 is meant for transparencies.
			 *
			 * Depletion is ignored in B&W mode
			 */
			switch(PD->pd_Preferences.PrintDensity)
			{
				/* Standard */
				case 4:
					depletion = 2;
					shingling = 0;
					break;

				/* Normal */
				case 5:
					depletion = 2;
					shingling = 1;
					break;

				/* Best */
				case 6:
					depletion = 2;
					shingling = 2;
					break;

				/* Best for transparencies */
				case 7:
					depletion = 1;
					shingling = 2;
					break;

				/* Anything else */
				default:
					depletion = 1;
					shingling = 0;
					break;
			}

			/* Now pick the gamma correction table to use. */
			threshold = PD->pd_Preferences.PrintThreshold;
			if(threshold < 1)
				threshold = 1;
			else if (threshold > 15)
				threshold = 15;

			/* Threshold value 1 stands for uncorrected
			 * data. It maps the input data 1:1 to the
			 * output. To save time and memory, we won't
			 * bother to deal with this special case.
			 */
			if(CONFIG_SUPPORTS_COLOR && threshold > 1)
			{
				gamma_table = GammaTables[threshold - 2];

				/* This buffer will be used for colour correction later. */
				colour_correction_buffer = AllocVec(sizeof(*colour_correction_buffer) * x,MEMF_ANY|MEMF_PUBLIC);
				if(colour_correction_buffer == NULL)
				{
					err = PDERR_BUFFERMEMORY; /* not enough memory */
					break;
				}
			}
			else
			{
				/* Don't perform colour correction. */
				gamma_table = NULL;
				colour_correction_buffer = NULL;
			}

			if(CONFIG_SUPPORTS_COLOR)
			{
				err = SendPrinterCommand(
					"\033*o"
					"%ldq"			/* shingling */
					"%ldD",			/* depletion */
					shingling,
					depletion);

				if(err != PDERR_NOERR)
					break;
			}

			err = SendPrinterCommand(
				"\033&l0L"	/* perforation skip mode off */
				"\033*p0X"	/* set cursor to left edge */
				"\033*r0F"	/* raster image prints in orientation of logical page */
				"\033*t"
				"%ldR"		/* set raster graphics resolution */
				"\033*r"
				"%ldt"		/* set raster height */
				"%lds"		/* set raster width */
				"%ldu"		/* number of raster data components per line */
				"0A",		/* start raster graphics */
				PED->ped_XDotsInch,
				y,
				x,
				(num_components == 1) ? 1 : (-num_components));

			break;

		/* Scale, Dither and Render */
		case 1:
			/*	ct	- pointer to PrtInfo structure.
			 *	x	- 0.
			 *	y	- row # (0 to Height - 1).
			 */

			pi = (struct PrtInfo *)ct;

			/* Perform gamma correction on the colours. */
			if(CONFIG_SUPPORTS_COLOR && gamma_table != NULL)
			{
				CorrectColours(pi,gamma_table,colour_correction_buffer);
				colour_buffer = colour_correction_buffer;
			}
			else
			{
				/* Use the uncorrected data. */
				colour_buffer = pi->pi_ColorInt;
			}

			if(CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR)
			{
				/* Transfer the pixels. */
				for(i = PCMYELLOW ; i <= PCMBLACK ; i++)
					Transfer(pi,colour_buffer,y,render_buffer[i],dither_data[i],i);

				/* This is a CMYK printer, we don't need to mix
				 * CMY to make black. This is why we clear the
				 * CMY components if there are corresponding
				 * black components for each pixel.
				 */
				ClearColour(render_buffer,num_bytes_per_row);
			}
			else
			{
				Transfer(pi,colour_buffer,y,render_buffer[PCMBLACK],dither_data[PCMBLACK],PCMBLACK);
			}

			break;

		/* Dump Buffer to Printer */
		case 2:
			/*	ct	- 0.
			 *	x	- 0.
			 *	y	- # of rows sent (1 to NumRows).
			 */

			if(CONFIG_SUPPORTS_COLOR && PD->pd_Preferences.PrintShade == SHADE_COLOR)
			{
				UBYTE * buffer = NULL;
				LONG size,method;

				for(i = PCMBLACK ; i >= PCMYELLOW ; i--)
				{
					/* Strip all trailing white space. */
					size = StripWhiteSpace(render_buffer[i],num_bytes_per_row);
					if(size > 0)
					{
						LONG compressed_size;
	
						/* Use the current output buffer. */
						buffer = print_buffers[current_print_buffer];
						current_print_buffer = (current_print_buffer + 1) % num_print_buffers;
	
						/* Compress the raster data. */
						compressed_size = CompressMethod2(render_buffer[i],buffer,size);
	
						/* Check for buffer overflow. */
						if(compressed_size < 0)
						{
							/* Compression did not result in space savings; reuse
							 * the uncompressed data buffer.
							 */
							memcpy(buffer,render_buffer[i],size);
							method = 0;
						}
						else
						{
							size = compressed_size;
							method = 2;
						}
					}
					else
					{
						/* No data to transfer, so we might as
						 * well consider this "uncompressed"
						 * raster data.
						 */
						method = 0;
					}
	
					/* Transfer raster data. */
					err = SendPrinterCommand("\033*b%ldm%ld%lc",method,size,(i == PCMYELLOW) ? 'W' : 'V');
					if(err == PDERR_NOERR && size > 0)
						err = (*PWrite)(buffer,size);

					if(err != PDERR_NOERR)
						break;
				}
			}
			else
			{
				UBYTE * buffer = NULL;
				LONG size,method;

				/* Strip all trailing white space. */
				size = StripWhiteSpace(render_buffer[PCMBLACK],num_bytes_per_row);
				if(size > 0)
				{
					LONG compressed_size;
		
					/* Use the current output buffer. */
					buffer = print_buffers[current_print_buffer];
					current_print_buffer = (current_print_buffer + 1) % num_print_buffers;
		
					/* Compress the raster data. */
					compressed_size	= CompressMethod2(render_buffer[PCMBLACK],buffer,size);
		
					/* Check for buffer overflow. */
					if(compressed_size < 0)
					{
						/* Compression did not result in space savings; reuse
						 * the uncompressed data buffer.
						 */
						memcpy(buffer,render_buffer[PCMBLACK],size);
						method = 0;
					}
					else
					{
						size = compressed_size;
						method = 2;
					}
				}
				else
				{
					/* No data to transfer, so we might as
					 * well consider this "uncompressed"
					 * raster data.
					 */
					method = 0;
				}

				/* Transfer raster data. */
				err = SendPrinterCommand("\033*b%ldm%ldW",method,size);
				if(err == PDERR_NOERR && size > 0)
					err = (*PWrite)(buffer,size);
			}

			break;

		/* Clear and Init Buffer */
		case 3:
			/*	ct	- 0.
			 *	x	- 0.
			 *	y	- 0.
			 */
			for(i = 0 ; i < NUM_ENTRIES(render_buffer) ; i++)
			{
				if(render_buffer[i] != NULL)
					memset(render_buffer[i],0,num_bytes_per_row);
			}

			break;

		/* Close Down */
		case 4:
			/*	ct	- error code.
			 *	x	- io_Special flag from IODRPReq struct
			 *	y	- 0.
			 */

			/* If user did not cancel the print... */
			if (ct != PDERR_CANCEL)
			{
				/* End raster graphics, perforation skip mode on */
				err = SendPrinterCommand("\033*rC\033&l1L");
				if (err == PDERR_NOERR)
				{
					/* If want to unload paper */
					if (!(x & SPECIAL_NOFORMFEED))
					{
						/* Eject paper */
						err = SendPrinterCommand("\014");
					}
				}
			}

			/* Flag that there is no alpha data waiting that
			 * needs a formfeed (since we just did one).
			 */
			PED->ped_PrintMode = 0;

			/* Wait for both buffers to empty. */
			(*PBothReady)();

			/* Free the dithering and printing buffers. */
			for(i = 0 ; i < NUM_ENTRIES(dither_data) ; i++)
			{
				DeleteDitherData(dither_data[i]);
				dither_data[i] = NULL;
			}

			for(i = 0 ; i < num_print_buffers ; i++)
			{
				FreeVec(print_buffers[i]);
				print_buffers[i] = NULL;
			}

			for(i = 0 ; i < NUM_ENTRIES(render_buffer) ; i++)
			{
				FreeVec(render_buffer[i]);
				render_buffer[i] = NULL;
			}

			FreeVec(colour_correction_buffer);
			colour_correction_buffer = NULL;

			break;

		/* Pre-Master Initialization */
		case 5:
			/*	ct	- 0 or pointer to IODRPReq structure.
			 *	x	- io_Special flag from IODRPReq struct
			 *	y	- 0.
			 */

			/* Select density */
			SetDensity(x & SPECIAL_DENSITYMASK);
			break;
	}

	return(err);
}
