/*
 * $Id: transfer.c 44.6 1999/09/17 19:03:43 olsen Exp olsen $
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

/* Parameters of a pseudo-random-number generator from Knuth's
 * "The Art of Computer Programming, Volume 2: Seminumerical
 *  Algorithms" (3rd edition). We need a generator with a large
 * repeat cycle to avoid introducing artefacts into the dithering
 * process.
 */

#define MM 2147483647	/* a Mersenne prime */
#define AA 48271		/* this does well in the spectral test */
#define QQ 44488		/* (long)(MM/AA) */
#define RR 3399			/* MM % AA; it is important that RR < QQ */

/****************************************************************************/

DITHERDATA_T *
CreateDitherData(LONG samplesPerLine,LONG numLines,LONG pad)
{
	DITHERDATA_T * result = NULL;
	DITHERDATA_T * dd;

	dd = AllocVec(sizeof(*dd) +
	              numLines * sizeof(SAMPLE_T *) +
	              numLines * (pad + samplesPerLine + pad) * sizeof(SAMPLE_T),
	              MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR);

	if(dd != NULL)
	{
		LONG i;

		dd->dd_SamplesPerLine	= samplesPerLine;
		dd->dd_NumLines			= numLines;
		dd->dd_Lines			= (SAMPLE_T **)(dd + 1);

		dd->dd_Lines[0] = (SAMPLE_T *)&dd->dd_Lines[numLines];

		for(i = 1 ; i < numLines ; i++)
			dd->dd_Lines[i] = dd->dd_Lines[i-1] + (pad + samplesPerLine + pad);

		for(i = 0 ; i < numLines ; i++)
			dd->dd_Lines[i] += pad;

		/* Use the address of the line as the seed for our
		 * pseudo-random-number generator.
		 */
		dd->dd_Seed = (LONG)dd;

		result = dd;
	}

	return(result);
}

VOID
DeleteDitherData(DITHERDATA_T * dd)
{
	FreeVec(dd);
}

/****************************************************************************/

STATIC VOID
RotateDitherLines(DITHERDATA_T * dd)
{
	SAMPLE_T * swap;
	LONG i;

	swap = dd->dd_Lines[0];

	for(i = 0 ; i < dd->dd_NumLines-1 ; i++)
		dd->dd_Lines[i] = dd->dd_Lines[i+1];

	dd->dd_Lines[dd->dd_NumLines-1] = swap;

	memset(dd->dd_Lines[dd->dd_NumLines-1],0,sizeof(SAMPLE_T) * dd->dd_SamplesPerLine);

	dd->dd_Reverse ^= TRUE;
}

/****************************************************************************/

STATIC VOID
TransferBlueNoise(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,DITHERDATA_T * dd)
{
	SAMPLE_T threshold,error,e1,e3,e5,e7,weight,err2;
	SAMPLE_T * this = dd->dd_Lines[0];
	SAMPLE_T * next = dd->dd_Lines[1];
	LONG X = dd->dd_Seed;
	LONG x;

	if(dd->dd_Reverse)
	{
		ColorInt += (width-1);

		for(x = width-1 ; x >= 0 ; x--)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (this[x] / 16) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt--; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							e1 = error;
			error += err2;	e3 = error;
			error += err2;	e5 = error;
			error += err2;	e7 = error;

			/* Crank out another pseudo random number... */
			X = AA * (X % QQ) - RR * (LONG)(X / QQ);
			if(X < 0)
				X += MM;

			/* Calculate the random weight. */
			weight = X % max(1,min(e5,e7));

			/* Skew the large errors with the weight. */
			e5 -=           weight/2;
			e7 += weight - (weight/2);

			/* Crank out another pseudo random number... */
			X = AA * (X % QQ) - RR * (LONG)(X / QQ);
			if(X < 0)
				X += MM;

			/* Calculate the random weight. */
			weight = X % max(1,min(e1,e3));

			/* Skew the small errors with the weight. */
			e1 -=           weight/2;
			e3 += weight - (weight/2);

			next[x-1] += e1;	/* 1 x error */
			next[x+1] += e3;	/* 3 x error */
			next[x  ] += e5;	/* 5 x error */
			this[x-1] += e7;	/* 7 x error */
		}
	}
	else
	{
		for(x = 0 ; x < width ; x++)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (this[x] / 16) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt++; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							e1 = error;
			error += err2;	e3 = error;
			error += err2;	e5 = error;
			error += err2;	e7 = error;

			/* Crank out another pseudo random number... */
			X = AA * (X % QQ) - RR * (LONG)(X / QQ);
			if(X < 0)
				X += MM;

			/* Calculate the random weight. */
			weight = X % max(1,min(e5,e7));

			/* Skew the large errors with the weight. */
			e5 -=           weight/2;
			e7 += weight - (weight/2);

			/* Crank out another pseudo random number... */
			X = AA * (X % QQ) - RR * (LONG)(X / QQ);
			if(X < 0)
				X += MM;

			/* Calculate the random weight. */
			weight = X % max(1,min(e1,e3));

			/* Skew the small errors with the weight. */
			e1 -=           weight/2;
			e3 += weight - (weight/2);

			next[x+1] += e1;	/* 1 x error */
			next[x-1] += e3;	/* 3 x error */
			next[x  ] += e5;	/* 5 x error */
			this[x+1] += e7;	/* 7 x error */
		}
	}

	dd->dd_Seed = X;

	/* Swap the dithering buffers and reset the buffer
	 * for the next line.
	 */
	RotateDitherLines(dd);
}

STATIC VOID
TransferFloydSteinberg(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,DITHERDATA_T * dd)
{
	LONG x,threshold,error,err2;
	SAMPLE_T * this = dd->dd_Lines[0];
	SAMPLE_T * next = dd->dd_Lines[1];

	if(dd->dd_Reverse)
	{
		ColorInt += (width-1);

		for(x = width-1 ; x >= 0 ; x--)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (this[x] / 16) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt--; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							next[x-1] += error;	/* 1 x error */
			error += err2;	next[x+1] += error;	/* 3 x error */
			error += err2;	next[x  ] += error;	/* 5 x error */
			error += err2;	this[x-1] += error;	/* 7 x error */
		}
	}
	else
	{
		for(x = 0 ; x < width ; x++)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (this[x] / 16) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt++; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							next[x+1] += error;	/* 1 x error */
			error += err2;	next[x-1] += error;	/* 3 x error */
			error += err2;	next[x  ] += error;	/* 5 x error */
			error += err2;	this[x+1] += error;	/* 7 x error */
		}
	}

	/* Swap the dithering buffers and reset the buffer
	 * for the next line.
	 */
	RotateDitherLines(dd);
}

STATIC VOID
TransferStucki(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,DITHERDATA_T * dd)
{
	LONG x,threshold,error;
	SAMPLE_T * l0 = dd->dd_Lines[0];
	SAMPLE_T * l1 = dd->dd_Lines[1];
	SAMPLE_T * l2 = dd->dd_Lines[2];

	if(dd->dd_Reverse)
	{
		ColorInt += (width-1);

		for(x = width-1 ; x >= 0 ; x--)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (l0[x] / 42) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt--; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */

							l2[x+2]	+= error;	/* 1 x error */
							l2[x-2]	+= error;	/* 1 x error */
			error += error;	l2[x+1] += error;	/* 2 x error */
							l2[x-1] += error;	/* 2 x error */
							l1[x+2] += error;	/* 2 x error */
							l1[x-2] += error;	/* 2 x error */
			error += error;	l2[x  ] += error;	/* 4 x error */
							l1[x+1] += error;	/* 4 x error */
							l1[x-1] += error;	/* 4 x error */
							l0[x-2] += error;	/* 4 x error */
			error += error;	l1[x  ] += error;	/* 8 x error */
							l0[x-1] += error;	/* 8 x error */
		}
	}
	else
	{
		for(x = 0 ; x < width ; x++)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (l0[x] / 42) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt++; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */

							l2[x-2]	+= error;	/* 1 x error */
							l2[x+2]	+= error;	/* 1 x error */
			error += error;	l2[x-1] += error;	/* 2 x error */
							l2[x+1] += error;	/* 2 x error */
							l1[x-2] += error;	/* 2 x error */
							l1[x+2] += error;	/* 2 x error */
			error += error;	l2[x  ] += error;	/* 4 x error */
							l1[x-1] += error;	/* 4 x error */
							l1[x+1] += error;	/* 4 x error */
							l0[x+2] += error;	/* 4 x error */
			error += error;	l1[x  ] += error;	/* 8 x error */
							l0[x+1] += error;	/* 8 x error */
		}
	}

	/* Swap the dithering buffers and reset the buffer
	 * for the next line.
	 */
	RotateDitherLines(dd);
}

STATIC VOID
TransferJarvisJudiceNinke(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,DITHERDATA_T * dd)
{
	LONG x,threshold,error,err2;
	SAMPLE_T * l0 = dd->dd_Lines[0];
	SAMPLE_T * l1 = dd->dd_Lines[1];
	SAMPLE_T * l2 = dd->dd_Lines[2];

	if(dd->dd_Reverse)
	{
		ColorInt += (width-1);

		for(x = width-1 ; x >= 0 ; x--)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (l0[x] / 48) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt--; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							l2[x+2]	+= error;	/* 1 x error */
							l2[x-2]	+= error;	/* 1 x error */
			error += err2;	l2[x+1] += error;	/* 3 x error */
							l2[x-1] += error;	/* 3 x error */
							l1[x+2] += error;	/* 3 x error */
							l1[x-2] += error;	/* 3 x error */
			error += err2;	l2[x  ] += error;	/* 5 x error */
							l1[x+1] += error;	/* 5 x error */
							l1[x-1] += error;	/* 5 x error */
							l0[x-2] += error;	/* 5 x error */
			error += err2;	l1[x  ] += error;	/* 7 x error */
							l0[x-1] += error;	/* 7 x error */
		}
	}
	else
	{
		for(x = 0 ; x < width ; x++)
		{
			/* Add the intensity (the greater the darker) and the error for
			 * the current line.
			 */
			threshold = (l0[x] / 48) + ColorInt->colorByte[component];

			/* Make sure that the resulting value is within
			 * valid bounds.
			 */
			if(threshold < 0)
				threshold = 0;
			else if (threshold > 255)
				threshold = 255;

			ColorInt++; /* bump ptr for next time */

			/* Now check if this pixel should come out black
			 * or white (0 = white, 255 = black).
			 */
			if(threshold < 128)
			{
				/* White pixel */
				error = threshold - 0;
			}
			else
			{
				/* Black pixel */
				error = threshold - 255;

				ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */
			}

			/* Now distribute the error. */
			err2 = error + error;

							l2[x-2]	+= error;	/* 1 x error */
							l2[x+2]	+= error;	/* 1 x error */
			error += err2;	l2[x-1] += error;	/* 3 x error */
							l2[x+1] += error;	/* 3 x error */
							l1[x-2] += error;	/* 3 x error */
							l1[x+2] += error;	/* 3 x error */
			error += err2;	l2[x  ] += error;	/* 5 x error */
							l1[x-1] += error;	/* 5 x error */
							l1[x+1] += error;	/* 5 x error */
							l0[x+2] += error;	/* 5 x error */
			error += err2;	l1[x  ] += error;	/* 7 x error */
							l0[x+1] += error;	/* 7 x error */
		}
	}

	/* Swap the dithering buffers and reset the buffer
	 * for the next line.
	 */
	RotateDitherLines(dd);
}

/****************************************************************************/

STATIC VOID
TransferBayer(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,LONG y)
{
	const int matrix_width	= 16;
	const int matrix_height	= 16;

	STATIC const UBYTE BayerMatrix[16 * 16] =
	{
		0x01,0xEB,0x3B,0xDB,0x0F,0xE7,0x37,0xD7,0x02,0xE8,0x38,0xD8,0x0C,0xE4,0x34,0xD4,
		0x81,0x41,0xBB,0x7B,0x8F,0x4F,0xB7,0x77,0x82,0x42,0xB8,0x78,0x8C,0x4C,0xB4,0x74,
		0x21,0xC1,0x11,0xFB,0x2F,0xCF,0x1F,0xF7,0x22,0xC2,0x12,0xF8,0x2C,0xCC,0x1C,0xF4,
		0xA1,0x61,0x91,0x51,0xAF,0x6F,0x9F,0x5F,0xA2,0x62,0x92,0x52,0xAC,0x6C,0x9C,0x5C,
		0x09,0xE1,0x31,0xD1,0x05,0xEF,0x3F,0xDF,0x0A,0xE2,0x32,0xD2,0x06,0xEC,0x3C,0xDC,
		0x89,0x49,0xB1,0x71,0x85,0x45,0xBF,0x7F,0x8A,0x4A,0xB2,0x72,0x86,0x46,0xBC,0x7C,
		0x29,0xC9,0x19,0xF1,0x25,0xC5,0x15,0xFE,0x2A,0xCA,0x1A,0xF2,0x26,0xC6,0x16,0xFC,
		0xA9,0x69,0x99,0x59,0xA5,0x65,0x95,0x55,0xAA,0x6A,0x9A,0x5A,0xA6,0x66,0x96,0x56,
		0x03,0xE9,0x39,0xD9,0x0D,0xE5,0x35,0xD5,0x00,0xEA,0x3A,0xDA,0x0E,0xE6,0x36,0xD6,
		0x83,0x43,0xB9,0x79,0x8D,0x4D,0xB5,0x75,0x80,0x40,0xBA,0x7A,0x8E,0x4E,0xB6,0x76,
		0x23,0xC3,0x13,0xF9,0x2D,0xCD,0x1D,0xF5,0x20,0xC0,0x10,0xFA,0x2E,0xCE,0x1E,0xF6,
		0xA3,0x63,0x93,0x53,0xAD,0x6D,0x9D,0x5D,0xA0,0x60,0x90,0x50,0xAE,0x6E,0x9E,0x5E,
		0x0B,0xE3,0x33,0xD3,0x07,0xED,0x3D,0xDD,0x08,0xE0,0x30,0xD0,0x04,0xEE,0x3E,0xDE,
		0x8B,0x4B,0xB3,0x73,0x87,0x47,0xBD,0x7D,0x88,0x48,0xB0,0x70,0x84,0x44,0xBE,0x7E,
		0x2B,0xCB,0x1B,0xF3,0x27,0xC7,0x17,0xFD,0x28,0xC8,0x18,0xF0,0x24,0xC4,0x14,0xFE,
		0xAB,0x6B,0x9B,0x5B,0xA7,0x67,0x97,0x57,0xA8,0x68,0x98,0x58,0xA4,0x64,0x94,0x54
	};

	UBYTE const * const matrix_row = &BayerMatrix[(y % matrix_height) * matrix_width];
	LONG x;

	for(x = 0 ; x < width ; x++)
	{
		/* Check if we should render Black */
		if(ColorInt->colorByte[component] > matrix_row[x % matrix_width])
			ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */

		ColorInt++; /* bump ptr for next time */
	}
}

STATIC VOID
TransferHalftone(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,LONG y)
{
	const int matrix_width	= 8;
	const int matrix_height	= 8;

	STATIC const UBYTE HalftoneMatrix[8 * 8] =
	{
		0x90,0xA0,0x98,0x80,0x6C,0x5C,0x64,0x7C,
		0xD8,0xE0,0xE8,0xB0,0x24,0x1C,0x14,0x4C,
		0xD0,0xF8,0xF0,0xA8,0x2C,0x04,0x0C,0x54,
		0xB8,0xC8,0xC0,0x88,0x44,0x34,0x3C,0x74,
		0x68,0x58,0x60,0x78,0x94,0xA4,0x9C,0x84,
		0x20,0x18,0x10,0x48,0xDC,0xE4,0xEC,0xB4,
		0x28,0x00,0x08,0x50,0xD4,0xFC,0xF4,0xAC,
		0x40,0x30,0x38,0x70,0xBC,0xCC,0xC4,0x8C
	};

	UBYTE const * const matrix_row = &HalftoneMatrix[(y % matrix_height) * matrix_width];
	LONG x;

	for(x = 0 ; x < width ; x++)
	{
		/* Check if we should render Black */
		if(ColorInt->colorByte[component] > matrix_row[x % matrix_width])
			ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */

		ColorInt++; /* bump ptr for next time */
	}
}

STATIC VOID
TransferThreshold(UBYTE * ptr,LONG width,union colorEntry *ColorInt,int component,UBYTE threshold)
{
	LONG x;

	for(x = 0 ; x < width ; x++)
	{
		/* Check if we should render Black */
		if(ColorInt->colorByte[component] > threshold)
			ptr[x / 8] |= (1 << (7 - (x % 8))); /* set bit */

		ColorInt++; /* bump ptr for next time */
	}
}

/****************************************************************************/

VOID
Transfer(
	struct PrtInfo *	PInfo,
	union colorEntry *	ColorInt,		/* colour data to process */
	LONG				y,				/* row # */
	UBYTE *				ptr,			/* ptr to buffer */
	DITHERDATA_T *		dd,				/* Auxiliary data for error dispersion dithering */
	int					component)		/* Which colour component */
{
	/* Are we thresholding? */
	if(PInfo->pi_threshold > 0)
	{
		TransferThreshold(ptr,PInfo->pi_width,ColorInt,component,255 - PInfo->pi_threshold);
	}
	else
	{
		/* Ok, so we are dithering; which dithering technique is it? */
		switch(PD->pd_Preferences.PrintFlags & DITHERING_MASK)
		{
			/* Ordered dithering using the Bayer matrix (256 shades of grey). */
			case ORDERED_DITHERING:

				TransferBayer(ptr,PInfo->pi_width,ColorInt,component,y);
				break;

			/* Ordered dithering using the halftone screen matrix (64 shades of grey). */
			case HALFTONE_DITHERING:

				TransferHalftone(ptr,PInfo->pi_width,ColorInt,component,y);
				break;

			/* Dithering with error dispersion using the Floyd-Steinberg filter (256 shades of grey). */
			case FLOYD_DITHERING:

				TransferFloydSteinberg(ptr,PInfo->pi_width,ColorInt,component,dd);
			/*	TransferBlueNoise(ptr,PInfo->pi_width,ColorInt,component,dd);	*/
			/*	TransferStucki(ptr,PInfo->pi_width,ColorInt,component,dd);	*/
			/*	TransferJarvisJudiceNinke(ptr,PInfo->pi_width,ColorInt,component,dd);	*/
				break;
		}
	}
}
