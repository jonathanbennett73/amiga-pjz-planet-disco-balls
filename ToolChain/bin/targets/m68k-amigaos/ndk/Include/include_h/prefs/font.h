#ifndef PREFS_FONT_H
#define PREFS_FONT_H
/*
**	$VER: font.h 38.2 (27.9.1991)
**	Includes Release 45.1
**
**	File format for font preferences
**
**	(C) Copyright 1991-2001 Amiga, Inc.
**	All Rights Reserved
*/

/*****************************************************************************/


#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

#ifndef LIBRARIES_IFFPARSE_H
#include <libraries/iffparse.h>
#endif

#ifndef GRAPHICS_TEXT_H
#include <graphics/text.h>
#endif


/*****************************************************************************/


#define ID_FONT MAKE_ID('F','O','N','T')


#define FONTNAMESIZE (128)

struct FontPrefs
{
    LONG	    fp_Reserved[3];
    UWORD	    fp_Reserved2;
    UWORD	    fp_Type;
    UBYTE	    fp_FrontPen;
    UBYTE	    fp_BackPen;
    UBYTE	    fp_DrawMode;
    struct TextAttr fp_TextAttr;
    BYTE	    fp_Name[FONTNAMESIZE];
};


/* constants for FontPrefs.fp_Type */
#define FP_WBFONT     0
#define FP_SYSFONT    1
#define FP_SCREENFONT 2


/*****************************************************************************/


#endif /* PREFS_FONT_H */
