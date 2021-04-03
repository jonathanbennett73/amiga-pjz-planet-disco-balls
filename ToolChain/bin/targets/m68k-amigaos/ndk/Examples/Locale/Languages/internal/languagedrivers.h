#ifndef LOCALE_LANGUAGEDRIVERS_H
#define LOCALE_LANGUAGEDRIVERS_H
/*
**      $VER: languagedrivers.h 38.1 (26.10.1991)
**
**      language driver stuff for locale.library
**
**      (C) Copyright 1991-1999 Amiga, Inc.
**          All Rights Reserved
*/

/*****************************************************************************/


/* Functions implemented by a driver. These values are used in the longword
 * returned by the GetDriverInfo() entry point of a language driver.
 *
 * The value returned by GetDriverInfo() specifies which function this driver
 * implements. If any functions are not implemented, then the equivalent
 * functions in locale.library are used instead. These built-in functions
 * are for the english language.
 */
#define GDIB_CONVTOLOWER    0
#define GDIB_CONVTOUPPER    1
#define GDIB_GETCODESET     2
#define GDIB_GETLOCALESTR   3
#define GDIB_ISALNUM        4
#define GDIB_ISALPHA        5
#define GDIB_ISCNTRL        6
#define GDIB_ISDIGIT        7
#define GDIB_ISGRAPH        8
#define GDIB_ISLOWER        9
#define GDIB_ISPRINT        10
#define GDIB_ISPUNCT        11
#define GDIB_ISSPACE        12
#define GDIB_ISUPPER        13
#define GDIB_ISXDIGIT       14
#define GDIB_STRCONVERT     15
#define GDIB_STRNCMP        16

#define GDIF_CONVTOLOWER    (1<<0)
#define GDIF_CONVTOUPPER    (1<<1)
#define GDIF_GETCODESET     (1<<2)
#define GDIF_GETLOCALESTR   (1<<3)
#define GDIF_ISALNUM        (1<<4)
#define GDIF_ISALPHA        (1<<5)
#define GDIF_ISCNTRL        (1<<6)
#define GDIF_ISDIGIT        (1<<7)
#define GDIF_ISGRAPH        (1<<8)
#define GDIF_ISLOWER        (1<<9)
#define GDIF_ISPRINT        (1<<10)
#define GDIF_ISPUNCT        (1<<11)
#define GDIF_ISSPACE        (1<<12)
#define GDIF_ISUPPER        (1<<13)
#define GDIF_ISXDIGIT       (1<<14)
#define GDIF_STRCONVERT     (1<<15)
#define GDIF_STRNCMP        (1<<16)

#define ALL_FUNCS	    0x0001ffff

/*****************************************************************************/


#endif  /* LOCALE_LANGUAGEDRIVERS_H */
