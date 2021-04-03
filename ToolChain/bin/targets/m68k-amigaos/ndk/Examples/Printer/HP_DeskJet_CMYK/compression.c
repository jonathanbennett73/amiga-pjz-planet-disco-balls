/*
 * $Id: compression.c 44.1 1999/09/02 11:08:00 olsen Exp olsen $
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

LONG
StripWhiteSpace(BYTE * source,LONG size)
{
	LONG i;

	/* Optimization: strip all trailing zero bytes. */
	for(i = size ; i > 0 ; i--)
	{
		if(source[i-1] != 0)
		{
			size = i;
			break;
		}
	}

	return(size);
}

/*****************************************************************************/

/* PCL compression method #2, also known as "TIFF packbits" or ByteRun1. */
LONG
CompressMethod2(
	UBYTE * src,
	UBYTE * dest,
	LONG count)
{
	UBYTE *	last = dest + count;

	UBYTE * outptr;
	UBYTE * inptr;
	UBYTE * saveptr;

	UBYTE	data;		/* data byte */
	UBYTE	lastbyte;	/* last byte */
	LONG	repcount;	/* repeat count */
	LONG	litcount;	/* literal count */

	inptr = src;
	outptr = dest;

	/* Start loop through data. Check for possible repeat at beginning. */
	while(count > 0)
	{
		/* get value to work with */
		data = (*inptr++);
		count--;

		/* no repeat count yet */
		repcount = 0;

		/* Check for repeat, since we are not in the middle
		 * of a literal run, it does not have to be more than
		 * two bytes of similar data.
		 */
		while(count > 0 && (*inptr) == data)
		{
			repcount++;
			inptr++;

			count--;
		}

		/* Now, if we are out of data (count == 0), then
		 * if the repeated byte was zero, then ignore it
		 * completely (don't bother outputing the trailing zeros).
		 */
		if(count == 0 && data == 0)
			break; /* done */

		/* If there was a repeat (repcount > 0), then we
		 * can output the command here, otherwise, we
		 * need to go into literal run mode.
		 *
		 * Note:  This is a while loop because the repeat count
		 * may actually be greater than 127.
		 */

		if(repcount >= 1) /* repeat mode */
		{
			while(repcount > 127)
			{
				if(outptr + 2 > last)
					return(-1);

				(*outptr++) = 129;	/* count 127 */
				(*outptr++) = data;	/* value */
				repcount -= 128;	/* offset */
			}

			if(repcount > 0)
			{
				if(outptr + 2 > last)
					return(-1);

				(*outptr++) = 256 - repcount;	/* count */
				(*outptr++) = data;		/* value */

				/* Now pop to the top of the loop 
				 * looking for more repeat counts.
				 */

				continue; /* top of loop */
			}

			/* Special case.  If we have arrived at this point,
			 * then repcount is now equal to 0.  This means
			 * that when we entered this section, repcount
			 * was a multiple of 128 (i.e. 128 :-).
			 *
			 * This means that there were 129 identical bytes,
			 * so the output does a replicate of 127 which
			 * gives 128 bytes, and we now have one byte left
			 * over which should NOT be output as a repeat
			 * run, rather it should be merged into the following
			 * literal run (if it exists).
			 *
			 * So, we will simply fall thru to the next section
			 * of code which assumes that we are working on 
			 * a literal run.
			 */
		}

		/* Literal run.  At this point, the current data byte
		 * does NOT match the following byte.  We will transfer
		 * these non-identical bytes until:
		 *
		 *      1)  we run out of input data (count == 0).
		 *      2)  we run out of room in this output block (128)
		 *      3)  we come across a value which occurs at least
		 *          three times in a row.  A value occuring only
		 *          twice in a row does NOT justify dropping
		 *          out of a literal run.
		 *
		 * Special case:  If we run out of room in the output block
		 * (which is 128 bytes), the last two values are the same,
		 * AND there is more input, it makes sense to restart
		 * the repeat detector in case the following bytes are
		 * repeats of the two.  A simple check of the following
		 * byte will determine this.
		 * (This case falls out with the test for triples below).
		 *
		 * Special case:  If we run out of room in the output block
		 * (which is 128 bytes), the last value is the same as
		 * the next one on the input, then it is better to let
		 * that byte be used in a possible replicate run following
		 * the literal run.  If the last byte matches ONLY the
		 * following byte, (and not the one after that, it is
		 * a wash, but for best results, we will test the
		 * following two bytes.
		 */

		litcount = 0;
		saveptr = outptr++;	/* save location of the command byte */

		if(outptr + 1 > last)
			return(-1);

		(*outptr++) = data;	/* save the first byte. */

		lastbyte = data;	/* remember for testing */

		while(count > 0 && litcount < 127)
		{
			data = (*inptr++);
			count--;
			litcount++;

			if(outptr + 1 > last)
				return(-1);

			(*outptr++) = data;

			/* Test to see if this byte matched the last one.
			 * If so, check the next one for a triple.
			 */
			if(lastbyte == data && count > 0 && (*inptr) == data)
			{
				/* We have a triple, adjust accordingly.
				 * Add two bytes back onto the input.
				 */

				count += 2;
				inptr -= 2;
				outptr -= 2;
				litcount -= 2;

				break; /* out of loop */
			}

			lastbyte = data; /* save data byte */
		}

		/* Check the special case number 2 above. */
		if(litcount == 127 && count > 1 && data == (*inptr) && data == inptr[1])
		{
			/*  Restore the last byte to the input stream */
			count += 1;
			inptr -= 1;
			outptr -= 1;
			litcount -= 1;
		}

		/* Save the literal run count. */
		(*saveptr) = litcount;
	}

	return(outptr - dest);
}
