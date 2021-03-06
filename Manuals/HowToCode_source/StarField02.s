????  ?  ?  ?  ?  ?  ?  ?  ?  ?  ?*******************************************************************************
*				 Definitions				      *
*******************************************************************************

********************************** Starfield **********************************

NrOfStars		= 256

***************************** Hardware Registers ******************************

COP1LCH			= $dff080

******************************** exec.library *********************************

ExecBase		= 4
_LVOAllocMem		= -198
_LVOFreeMem		= -210
_LVOFindTask		= -294
_LVOSetTaskPri		= -300
_LVOCloseLibrary	= -414
_LVOOpenLibrary		= -552
MEMF_CHIP		= $10002

****************************** graphics.library *******************************

GFXB_AA_ALICE		= 2
ActiView		= 34
copinit			= 38
DisplayFlags		= 206
ChipRevBits0		= 236
VBlankFrequency		= 530
_LVOLoadView		= -222
_LVOWaitTOF		= -270

*******************************************************************************
*				    Main				      *
*******************************************************************************

	bsr	Startup
	move.l	#CopperList,COP1LCH

Loop:	btst	#6,$bfe001
	beq	Closedown
	
	bsr	Starfield

	bra	Loop

*******************************************************************************
*				 Subroutines				      *
*******************************************************************************

****************************** StarField routine ******************************
;Move and project stars. Trashes: a0,d0-d2

Starfield:

	rts

******************************* Startup routine *******************************
;Check for aga and pal, if not present then exit. Else we shut down the
;system (in a system friendly manner...I think..) and prepare for our own code.
	
Startup:
	move.l	ExecBase,a6		;FindTask is an exec function
;	sub.l	a1,a1			;Clear a1. (Why? Read the exec.doc!)
;	jsr	_LVOFindTask(a6)	;Find our task (returns pointer in d0)

;	move.l	d0,a1			;Pointer to task in a1
;	moveq	#127,d0			;New (VERY HIGH) priority for task
;	jsr	_LVOSetTaskPri(a6)	;Duhuh! Do I've to comment every line?!

	lea	GfxName(pc),a1		;What library to open?
	moveq	#39,d0			;If we have 3.0 then we have V39 of graphics.library
	jsr	_LVOOpenLibrary(a6)	;Open graphics.library
	move.l	d0,GfxBase		;Store pointer to graphics.library
	beq	GfxError		;Ooupsy, something went wrong
	
	move.l	GfxBase(pc),a6
	move.l	ActiView(a6),OldView	;Store old view

	sub.l	a1,a1			;Clear a1.(Why? Read the graphics.doc!)
	jsr	_LVOLoadView(a6)	;Flush View to nada (Open a null view)
	jsr	_LVOWaitTOF(a6)		;Wait for vertical blank to occur
	jsr	_LVOWaitTOF(a6)		;And once again, incase of interlace

        move.l  ExecBase,a6
        cmp.b   #50,VBlankFrequency(a6)	;Check for pal
        bne	AgaPalError		;No pal? Then I'm out of here!

        move.l	GfxBase(pc),a6
	btst	#GFXB_AA_ALICE,ChipRevBits0(a6)	;Check for AGA
	beq	AgaPalError		;No aga!? ..are u realy a serious
					;Amiga owner?
	rts
	
****************************** Closedown routine ******************************
;Close down our own stuff and restore system.

Closedown:
	;If we fixed the V39 spritebug in startup, we should return sprites to
	; normal before we load the wbview. I'll add that later.

	move.l	GfxBase(pc),a6
	move.l	OldView(pc),a1		;Pointer to our old wb view
	jsr	_LVOLoadView(a6)	;Install it
	jsr	_LVOWaitTOF(a6)		;Wait for LoadView()
	jsr	_LVOWaitTOF(a6)		;And once again, incase of interlace
	
	move.l	copinit(a6),COP1LCH	;And pointer to wbcopper in COP1LCH

	;Maybe I should insert _LVORethinkDisplay() here?
	
AgaPalError:
	move.l	ExecBase,a6		;Oh, we don't want that
	move.l	GfxBase(pc),a1		;grapichs.library to hang
	jsr	_LVOCloseLibrary(a6)	;around in memory, do we?
	
GfxError:
	moveq	#0,d0			;Return code
	rts

*******************************************************************************
*			        Declarations				      *
*******************************************************************************

****************************** graphics.library *******************************

GfxBase:	dc.l	0
GfxName:	dc.b	'graphics.library',0
		EVEN
OldView:	dc.l 	0

*******************************************************************************
				   CopperList
*******************************************************************************

CopperList:
	dc.w	0
	dc.w	0
