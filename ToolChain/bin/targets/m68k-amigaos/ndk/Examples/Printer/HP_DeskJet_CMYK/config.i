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

CONFIG_NAME MACRO
 DC.B 'HP DeskJet 880C',0
 ENDM
CONFIG_PRINTER_CLASS EQU PPC_COLORGFX
CONFIG_COLOR_CLASS EQU PCC_YMCB
CONFIG_VERSION EQU 44
CONFIG_REVISION EQU 1
CONFIG_VERSTAG MACRO
 DC.B '$VER: HP_DeskJet_880C (20.10.1999)',0
 ENDM
