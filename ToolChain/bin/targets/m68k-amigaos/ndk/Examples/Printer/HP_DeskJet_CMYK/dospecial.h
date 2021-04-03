/*
 * $Id: dospecial.h 44.1 1999/08/27 18:31:24 olsen Exp olsen $
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

LONG __stdargs __saveds DoSpecial(UWORD * command,UBYTE output_buffer[],
                                  BYTE * current_line_position,
                                  BYTE * current_line_spacing,BYTE * crlf_flag,
                                  UBYTE params[]);
LONG __stdargs __saveds ConvFunc(UBYTE * buf,UBYTE c,LONG crlf_flag);

/****************************************************************************/
