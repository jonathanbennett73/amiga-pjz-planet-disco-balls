/*
 * $Id: global.h 44.3 1999/09/16 09:25:15 olsen Exp olsen $
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

#include <exec/memory.h>

#include <devices/prtgfx.h>
#include <devices/prtbase.h>
#include <devices/printer.h>

#include <libraries/locale.h>

#include <clib/exec_protos.h>
#include <clib/utility_protos.h>
#include <clib/locale_protos.h>
#include <clib/macros.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/locale_pragmas.h>

#define USE_BUILTIN_MATH
#include <string.h>
#include <stdarg.h>

/****************************************************************************/

#define NUM_ENTRIES(t) (sizeof(t) / sizeof(t[0]))

/****************************************************************************/

#define OK (0)
#define ERROR (-1)

/****************************************************************************/

extern void kprintf(const char *,...);

/****************************************************************************/

#include "compression.h"
#include "data.h"
#include "density.h"
#include "dospecial.h"
#include "init.h"
#include "locale.h"
#include "printertag.h"
#include "render.h"
#include "sprintf.h"
#include "transfer.h"
