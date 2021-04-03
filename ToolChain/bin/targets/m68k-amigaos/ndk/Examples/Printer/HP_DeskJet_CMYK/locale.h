/*
 * $Id: locale.h 44.2 1999/09/29 13:42:51 olsen Exp olsen $
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

#define PRINTER_HP_DESKJET
#include "devs.h"

/****************************************************************************/

VOID LocaleSetup(VOID);
VOID LocaleCleanup(VOID);
STRPTR Quote(LONG id);

/****************************************************************************/
