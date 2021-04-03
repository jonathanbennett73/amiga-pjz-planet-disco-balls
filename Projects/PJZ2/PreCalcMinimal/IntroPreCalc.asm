*****************************************************************************

; Name			: IntroSharedData.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Resources that need to be shared between parts.
;			  generally music files, screen buffers, and fonts.
; CPU Required		: MC68000 or better
; ChipSet Required	: OCS or better
				
*****************************************************************************

RasterTest set 0	;color00 timing bar, 0=off, 1=overall, 2=show blitwaits

	ifeq	RasterTest
tmpcolor00 set color00
	else
tmpcolor00 set $1fe	;dummy
	endif

*****************************************************************************

	include "hardware/custom.i"
	include "hardware/intbits.i"	

	include "../IntroConfig.i"
	include	"../Framework/CustomExtra.i"
	include "../Framework/CustomMacros.i"
	include "../Framework/IntroFramework_xref.i"
	include "../Framework/IntroLibrary.i"
	include "../Framework/IntroLibrary_xref.i"

	ifne FW_MUSIC_AMIGAKLANG
		xref	AMIGAKLANG_Progress
	endif

*****************************************************************************

	;Only assemble this file if enabled
	ifne	FW_PRECALC_LONG		

*****************************************************************************

	section	FW_PublicCode,code	;Code section in Public memory

*****************************************************************************
* Starts the precalc routine lev3 and then returns.
* Doesn't touch Dma so set separately.
* IN:
* OUT:
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	PRC_Init
PRC_Init:
	movem.l	d2-d7/a2-a6,-(sp)

	lea	_custom,a6

	; Activate copper and irq next frame
	lea	P0_CL_Phys,a0
	lea	P0_FrameIrq(pc),a1
	jsr	FW_SetCopperIrq_A6

	movem.l	(sp)+,d2-d7/a2-a6
	
	rts


*****************************************************************************

P0_FrameIrq:				;Blank template VERTB/COP interrupt
	TIMERON
	movem.l	d0-d7/a0-a6,-(sp)

	lea 	_custom,a6
	lea	Controller_Info(pc),a5

	jsr	FW_VBlankProxy		;Update frame counter

.checkdone:
	; Check if all precalc finished
	tst.w	FW_Precalc_Done
	beq.s	.stillprecalcing

	; Set base irq (leave screen on)
	jsr	FW_SetBaseIrq
	move.w	#1,CTRL_FINISHED(a5)
	move.w	#100,FW_Precalc_Progress
	bra.s	.draw
	
.stillprecalcing:
	;If running amigaklang precalc work out the progress
	ifne FW_MUSIC_AMIGAKLANG
		;Progress is stored in first byte as $0-1f (num samples)
		moveq	#0,d0
		move.b	AMIGAKLANG_Progress,d0
		mulu	#100,d0
		lsr.w	#5,d0		;/32, Percentage
		move.w	d0,FW_Precalc_Progress
	endif

.draw:
	bsr	Progress_Draw

.exit:
	;Reset interrupt
	moveq	#FW_FRAME_IRQ_TYPE,d0
	move.w	d0,intreq(a6)
	move.w	d0,intreq(a6)		;A4000 compat

	movem.l	(sp)+,d0-d7/a0-a6
	TIMEROFF
	rte


*****************************************************************************
* Draws a progress each frame.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0-a1
*****************************************************************************

Progress_Draw:
	moveq	#0,d0				;clear hiword
	move.w	FW_Precalc_Progress,d0
	lsl.w	#5,d0				;*32
	divu	#100,d0				;/100. Range is 0-32
	
	lea	P0_CL_Cols+2,a0			;first color
	lea	P0_CL_Cols2+2,a1		;first color
	moveq	#32,d1
	sub.w	d0,d1				;d0=light,d1=dark
.light
	subq.w	#1,d0				;-1 for dbf
	bmi.s	.dark
	move.w	#PROGRESSCOLLIGHT,d2
.l1:
	move.w	d2,(a0)
	move.w	d2,(a1)
	addq.w	#4,a0				;next color
	addq.w	#4,a1				;next color
	dbf	d0,.l1

.dark:
	subq.w	#1,d1				;-1 for dbf
	bmi.s	.exit
	move.w	#PROGRESSCOLDARK,d2
.d1:
	move.w	d2,(a0)
	move.w	d2,(a1)
	addq.w	#4,a0				;next color
	addq.w	#4,a1				;next color
	dbf	d1,.d1

.exit
	rts


*****************************************************************************

	xdef	PRC_Finished

	rsreset
CTRL_ZERODATA_SIZE	rs.w	0	;size of all zeroed data - START OF NONZERO

CTRL_FINISHED		rs.w	1
CTRL_SIZE		rs.w	0

Controller_Info:
	dcb.b	CTRL_ZERODATA_SIZE,0	;Init all to zero by default
PRC_Finished:				;xdef for outside access
	dc.w	0			;CTRL_FINISHED


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music

*****************************************************************************

PROGRESSCOLDARK		equ $333
PROGRESSCOLLIGHT	equ $fff
PROGRESSCOLBKG		equ $001

P0_CL_Phys:
	; Trigger copper interrupt if P0_SCANLINE_EOF = 0
	ifne FW_FRAME_IRQ_NEEDTRIG
		CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
	endif
	
	CMOVE 	bplcon0,$0200		;bpl off

	CWAIT	$ab,$4f
P0_CL_Cols:	
	rept 32
	CMOVE	tmpcolor00,PROGRESSCOLDARK
	endr
	CMOVE	tmpcolor00,PROGRESSCOLBKG

	CWAIT	$ac,$4f
P0_CL_Cols2:
	rept 32
	CMOVE	tmpcolor00,PROGRESSCOLDARK
	endr
	CMOVE	tmpcolor00,PROGRESSCOLBKG

	COPPEREND
P0_CL_End:

	rsreset
CL_PROGRESS_BPLCON0	rs.l	1
CL_PROGRESS_WAIT1	rs.l	1
CL_PROGRESS_COL		rs.l	32
CL_PROGRESS_BKG		rs.l	1
CL_PROGRESS_WAIT2	rs.l	1
CL_PROGRESS_COL2	rs.l	32
CL_PROGRESS_BKG2	rs.l	1
CL_PROGRESS_COPPEREND	rs.l	1
CL_PROGRESS_SIZEOF	rs.w	0


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_ChipBss,bss_c

*****************************************************************************

;CUR_CHIP_BUF set FW_Chip_Buffer_1

;BPL_Phys	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set CUR_CHIP_BUF+BPL_BUF_SIZE	;1bpl

;BPL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set CUR_CHIP_BUF+BPL_BUF_TOTALSIZE	;5bpl

;P0_CL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set CUR_CHIP_BUF+P0_CL_SIZE


*****************************************************************************
*****************************************************************************
*****************************************************************************

	ifne	_VERBOSE
	;This actually prints the size as at print time FW_Chip_Buffer_1 = 0
	;printt	"CUR_CHIP_BUF:"
	;printv	CUR_CHIP_BUF

	;This actually prints the size as at print time FW_Chip_Buffer_1 = 0
	;printt	"CUR_PUB_BUF:"
	;printv	CUR_PUB_BUF
	endif

*****************************************************************************

	endif	;FW_PRECALC_LONG	