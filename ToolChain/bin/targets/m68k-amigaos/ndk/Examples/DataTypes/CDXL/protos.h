/*
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
 */

/* Prototypes for functions defined in
classbase.c
 */

Class * __asm ObtainCDXLEngine(register __a6 struct ClassBase * );

struct Library * __asm LibInit(register __d0 struct ClassBase * , register __a0 BPTR , register __a6 struct Library * );

LONG __asm LibOpen(register __a6 struct ClassBase * );

LONG __asm LibClose(register __a6 struct ClassBase * );

LONG __asm LibExpunge(register __a6 struct ClassBase * );

/* Prototypes for functions defined in
dispatch.c
 */

Class * initClass(struct ClassBase * );



