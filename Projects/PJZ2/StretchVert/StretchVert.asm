*****************************************************************************

; Name			: Template.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Template routine.
; Date last edited	: 04/02/2020
				
*****************************************************************************

RasterTest set 0	;color00 timing bar, 0=off, 1=overall, 2=show blitwaits

	ifeq	RasterTest
tmpcolor00 set color00	;use tmpcolor00 in place of color00 everywhere so timing is easier
	else
tmpcolor00 set $1fe	;dummy
	endif

*****************************************************************************

	include "hardware/custom.i"
	include "hardware/intbits.i"	
	include "hardware/dmabits.i"

	include "../IntroConfig.i"
	include "../IntroSharedData.i"
	include "../IntroSharedData_xref.i"	
	include	"../Framework/CustomExtra.i"
	include "../Framework/CustomMacros.i"
	include "../Framework/IntroFramework_xref.i"
	include "../Framework/IntroLibrary.i"
	include "../Framework/IntroLibrary_xref.i"
	include "../Framework/IntroPrototype.i"
	include "../Framework/IntroPrototype_xref.i"

*****************************************************************************

	section	TMP_PublicCode,code	;Code section in Public memory

*****************************************************************************

; Photon:
; Best practice is to start with DDF 38,d0 and DIW 2c81,2cc1 and modify these 
; symmetrically and always in whole 16px steps for compatibility.
; Note DDF start of less than 30 and you start to lose sprites.

*** Display Window ***
P0_DIW_V		equ	$2c		;Hardware Vstart ($2c normal, $24 overscan)
P0_DIW_H		equ	$81		;Hardware Hstart ($81 normal, $71 overscan)
P0_DIW_WIDTH		equ	320		;Pixels		 (multiple of 16, 320 normal, 352 overscan)
P0_DIW_HEIGHT		equ	256		;Lines		 (256 normal PAL, 272 overscan)

P0_DDF_H		equ	$81		;Hardware Hstart ($81 normal, $71 overscan)
P0_DDF_WIDTH		equ	320		;Pixels		 (320 normal pal, 352 overscan)
P0_DDF_BYTEWIDTH	equ	P0_DDF_WIDTH/8
P0_DDF_WORDWIDTH	equ	P0_DDF_BYTEWIDTH/2

P0_SCANLINE_EOF		equ	0;P0_DIW_V+P0_DIW_HEIGHT	; Safe to starting clearing after this scanline
							; 0 is essentially vblank

; This value is used for loading the CL with colours and stuff, we might need
; to do it more than once, for example fading colours in a double-buffered CL
; we need to write the values twice so that after finishing both CLs have been updated
; Set to 1 for single CL, 2 for double-buffered, etc
P0_CL_NUM_BUFFERS	equ	2

*****************************************************************************

*** Screen Definitions ***

;BPL_BUF_xxx is the underlying buffer, might not match visible
BPL_BUF_WIDTH		equ	320
BPL_BUF_BYTEWIDTH	equ	BPL_BUF_WIDTH/8
BPL_BUF_WORDWIDTH	equ	BPL_BUF_BYTEWIDTH/2
BPL_BUF_HEIGHT		equ	256
BPL_BUF_NUMPLANES	equ	5
BPL_BUF_NUMCOLS 	equ	(1<<BPL_BUF_NUMPLANES)
BPL_BUF_SIZE		equ	BPL_BUF_BYTEWIDTH*BPL_BUF_HEIGHT
BPL_BUF_TOTALSIZE	equ	BPL_BUF_SIZE*BPL_BUF_NUMPLANES
BPL_BUF_INTERLEAVED	equ	1

	ifne BPL_BUF_INTERLEAVED
BPL_BUF_MOD_LINE	equ	BPL_BUF_BYTEWIDTH*BPL_BUF_NUMPLANES
BPL_BUF_MOD_BPL		equ	BPL_BUF_BYTEWIDTH
	else
BPL_BUF_MOD_LINE	equ	BPL_BUF_BYTEWIDTH
BPL_BUF_MOD_BPL		equ	BPL_BUF_SIZE
	endif

;BPL_xxx is the visible size, might not always match buffer
BPL_WIDTH		equ	P0_DIW_WIDTH
BPL_HEIGHT		equ	P0_DIW_HEIGHT

PIC_TOTALSIZE		equ	153*BPL_BUF_BYTEWIDTH*BPL_BUF_NUMPLANES

; For perfect reflection (interleaved):
; Modulo is added at DDFStop so need to set before then.
; Before DDFStart at last line of display set modulo to repeat that line
; -P0_DDF_BYTEWIDTH
; Then, before DDFStart on first line of reflection
; (-BPL_BUF_MOD_LINE)-P0_DDF_BYTEWIDTH
BPL_BPLMOD		equ	BPL_BUF_MOD_LINE-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPTLINE	equ	-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPTPREVLINE	equ	(-BPL_BUF_MOD_LINE)-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPT2LINE	equ	BPL_BPLMOD_REPTPREVLINE-BPL_BUF_MOD_LINE
BPL_BPLMOD_SKIPLINE	equ	BPL_BPLMOD+(BPL_BUF_MOD_LINE)

*****************************************************************************

PERFORM_ENABLE_MUSICSYNC	equ	0
PERFORM_ENABLE_SINESET		equ	0
PERFORM_ENABLE_USERVALWAIT	equ	0

*****************************************************************************

PAL_NUMCOLS_MAIN	equ	BPL_BUF_NUMCOLS	; number of main colour entries in our palettes
PAL_NUMCOLS_ALT		equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_ALT)


*****************************************************************************

ZOOM_BPLCON0_ON		equ	$5200	;5bpl screen
ZOOM_BPLCON0_OFF	equ	$0200	;0bpl screen

ZOOM_SHIFT		equ	4
ZOOM_MAX		equ	254<<ZOOM_SHIFT	;highest number to use in controller script
ZOOM_MIN		equ	(-254)<<ZOOM_SHIFT	;<<5 for increased precision


*****************************************************************************
* Start the effect (usually used for setting up the copper)
* This is called each time the effect is started
* IN:		a0, script ptr
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	ifeq _INTROWRAPPER
	xdef	SubPartStart
SubPartStart:	
	endif

	xdef	SVERT_Start
SVERT_Start:
	movem.l	d2-d7/a2-a6,-(sp)	;save
	lea	ControllerScript,a0

	lea	_custom,a6
	lea	Controller_Info(pc),a5

	;Save script pointer
	move.l	a0,CTRL_SCRIPT_PTR(a5)

	;Alloc memory
	bsr	P0_Alloc

	; Run intro startup precalc if not already done (only runs once)
	bsr	SubPartPreCalc_IntroStart	;T:None

	;Start the P0 routine irq and copper
	bsr	P0_Init			;I:a5-a6, T:d0-d1/a0-a1

	; Continue with main loop outside the irq
	bsr	P0_MainLoop		;I:a5-a6, T:d0-d1/a0-a1

	;May want to do various things here. Leave copperlist active, but use
	;default irq is common so that easy to transition.
	jsr	FW_SetBaseIrq

	movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts


*****************************************************************************
* To be called during INTRO startup to do any permanent precalc required.
* i.e. the buffers used are unique for this effect.
* CPU ONLY - No Blitter
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	;Only export one symbol depending if in demo or standalone mode
	ifeq _INTROWRAPPER
	xdef	SubPartPreCalc_IntroStart
	else
	xdef	SVERT_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
SVERT_PreCalc_IntroStart:
	tst.w	Controller_Info+CTRL_PRECALC_INTROSTART_DONE
	bne.s	.exit			;already done

	movem.l	d2-d7/a2-a6,-(sp)	;save
	lea	Controller_Info(pc),a5


	;Completed!
	move.w	#1,CTRL_PRECALC_INTROSTART_DONE(a5)

	movem.l	(sp)+,d2-d7/a2-a6	;restore
.exit:
	rts


*****************************************************************************
* To be called prior to a new phase for doing non permanent precalc.
* i.e. the buffers used may be only initialised just prior to effect running.
* This function should be reentrant if supports calling in batches and 
* only setting CTRL_P0_PRECALC_DONE when complete.
* CPU ONLY - No Blitter
* IN:		
* OUT:		d0, 1=precalc completed, 0=need to run again
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	;Only export one symbol depending if in demo or standalone mode
	ifeq _INTROWRAPPER
	xdef	SubPart_P0_PreCalc
	else
	xdef	SVERT_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
SVERT_P0_PreCalc:
	movem.l	d2-d7/a2-a6,-(sp)	;save (not d0)
	lea	Controller_Info(pc),a5
	tst.w	CTRL_P0_PRECALC_DONE(a5)
	bne.s	.exit			;already done

	;Change color to show where this starts
	;move.w	#$fff,color00+_custom

	;Generate sin table
	bsr	Ripple_Generate_Sine

	;Completed!
	move.w	#1,CTRL_P0_PRECALC_DONE(a5)
.exit:
	move.w	CTRL_P0_PRECALC_DONE(a5),d0
	movem.l	(sp)+,d2-d7/a2-a6	;restore (not d0)
	rts


*****************************************************************************
* Allocs memory for the effect. This will usually be called at effect start
* but may have to call it in previous effect if doing some funky precalc during
* previous effect.
* IN:		a6, _custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

P0_Alloc:
	;Switch memory allocation to opposite ends of shared buffer
	;Note may have to do the switch in previous effect if precalc is involved
CUR_CHIP_BUF set 0
CUR_PUB_BUF set 0
	jsr	FW_Mem_NewEffect_Public
	jsr	FW_Mem_NewEffect_Chip

	;Alloc mem and setup memory ptrs to static areas

	;Copper
CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE	
	move.l	#P0_CL_SIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_CL_PHYS_PTR(a5)

	lea	P0_CL_Phys,a0
	move.l	d0,a1
	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE
	move.l	#P0_CL_SIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_CL_LOG1_PTR(a5)

	;Bitplanes
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_BUF_TOTALSIZE	
	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_PHYS_PTR(a5)
	move.l	d0,CTRL_BPL_LOG1_PTR(a5)		;Single buffer

	;Allocs sine table for ripple
CUR_PUB_BUF set CUR_PUB_BUF+LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4)
	move.l	#LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4),d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_SINETAB_RIPPLE_PTR(a5)



	;Print out allocated memory usage
	ifne	_VERBOSE
	printt	""
	printt	"CUR_CHIP_BUF:"
	printv	CUR_CHIP_BUF

	printt	"CUR_PUB_BUF:"
	printv	CUR_PUB_BUF
	endif

	rts


*****************************************************************************
* Start the effect. Any precalc/slow ops should be done in the precalc code.
* Will also call PreCalc routes if not already been done (for safety)
* IN:		a6, _custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

P0_Init:
	movem.l	d2-d7/a2-a4,-(sp)

	; Run phase startup precalc if not already done - may be in batches
.precalc_effectstart:
	tst.w	CTRL_P0_PRECALC_DONE(a5)
	bne.s	.precalc_effectstart_done
	bsr	SubPart_P0_PreCalc	;O:d0, T:d0-d1/a0-a1
	bra.s	.precalc_effectstart
.precalc_effectstart_done:

	;Reset anything that needs resetting for subsequent runs (bss section will
	;be zero on first run - so only clear as required)
	clr.w	CTRL_PHASE(a5)	
	clr.w	CTRL_FINISHED(a5)
	clr.w	CTRL_FRAME_COUNT(a5)
	clr.w	CTRL_PAUSE_COUNTER(a5)
	clr.w	CTRL_PALETTE_ACTIVE(a5)
	clr.w	CTRL_MUSICSYNC(a5)
	clr.w	CTRL_MUSICSYNCMASK(a5)
	clr.w	CTRL_MUSICSYNCMASKWAIT(a5)

	clr.w	CTRL_ZOOM_ACTIVE(a5)
	clr.w	CTRL_RIPPLE_ACTIVE(a5)

	; Clear all screen buffers (previous routine must have blanked screen/colors)
	bsr	Clear_ScreenBuffers_CPU

	lea	BPL_Pic_Source(pc),a0	
	move.l	CTRL_BPL_PHYS_PTR(a5),a1
	lea	(58*BPL_BUF_MOD_LINE)(a1),a1	;160 high, so center
	move.w	#(PIC_TOTALSIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2


	;Run script up to the first FX_PAUSE command - use for setting base effect 
	;settings and palette rather than wasting code here on it
	bsr	Controller_ReadCommands	;I:a5, T:d0-d7/a0-a4

	;Setup phys/logical bpl and copperlist ptrs and load palette
	bsr	P0_CL_InitPtrs		;I:a5-a6, T:d0-d2/a0-a1
	bsr	Copper_Write_Zoom
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2

	;Swap buffers and load copper for next frame
	bsr	P0_ScreenBufferSwap	;I:a5-a6, T:d0-d1/a0

	;Initialise our new irq and ensure phys copper loaded (should have had palette loaded above)
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	lea	P0_FrameIrq(pc),a1
	jsr	FW_SetCopperIrq_A6	;I:a0/a1/a6, T:a0

	movem.l	(sp)+,d2-d7/a2-a4
	rts


*****************************************************************************
* Runs the effect.
* IN:		a6, _custom
*		a5, Controller_Info	
* OUT:		
* TRASHED:	d0-d1/a0-a1
*
*****************************************************************************

P0_MainLoop:
	movem.l	d2-d7/a2-a4,-(sp)

.Mainloop1:
	tst.w	CTRL_FINISHED(a5)	;Check if script ended itself
	bne.s	.exit

	jsr	FW_CheckUserQuitSignal_A6	;I:a6, O:d0, T:d0
	beq.s	.Mainloop1

	ifne	FW_RMB_QUIT_SECTION
	;If user initiated section/intro exit then load default CL/Irq
	;So that sprites/screen is blanked and next section will not have weird fx
	jsr	FW_SetBaseCopperIrq_A6	;T:a0
	jsr	FW_WaitTOF_A6		;T:None
	endif

.exit
	movem.l	(sp)+,d2-d7/a2-a4
	rts


*****************************************************************************

P0_FrameIrq:
	TIMERON
	movem.l	d0-d7/a0-a6,-(sp)

	lea	_custom,a6
	lea	Controller_Info(pc),a5

	;Clear screen
	;bsr	Clear_WorkBuffer_BlitterCPU_A6
	;bsr	Clear_WorkBuffer_Blitter_A6

	addq.w	#1,CTRL_FRAME_COUNT(a5)	;Update local frame count
	jsr	FW_VBlankProxy		;T:d0-d7/a0-a4

	; Read new script lines and perform
	bsr	Controller_ReadCommands	;Read new commands
	bsr	Controller_Perform	;Do any ongoing time-based effects and update angles


	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2
	bsr	Copper_Write_Zoom	;I:a5, T:d0-d7/a0-a4
	bsr	Copper_Write_Ripple	;I:a5

	;Swap buffers and load copper for next frame
	;Let blitter finish before changing buffers. Important on super-fast machines
	;When using interrupts near end-of-frame.
	WAITBLIT_NASTY_A6
	bsr	P0_ScreenBufferSwap	;I:a5-a6, T:d0-d1/a0

	;Reset interrupt
	moveq	#FW_FRAME_IRQ_TYPE,d0
	move.w	d0,intreq(a6)
	move.w	d0,intreq(a6)		;A4000 compat

	movem.l	(sp)+,d0-d7/a0-a6
	TIMEROFF
	rte


*****************************************************************************
* Inits ptrs in the copper list.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d2/a0-a1
*****************************************************************************

P0_CL_InitPtrs:

	;Setup items the same in front/back copper lists

	; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	move.l	CTRL_CL_LOG1_PTR(a5),a1

	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

	;
	;Front buffer copper BPL pointers
	;

	move.l	CTRL_CL_PHYS_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo

	;
	;Back buffer copper BPL pointers
	;

	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_LOG1_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	move.l	d1,CTRL_BPL_LOG1_PTR(a5)
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo


	rts


*****************************************************************************
* Swaps the frame buffers, copperlists, and activates the CL next frame.
* NOTE: Call before vblank so new copper takes effect next frame.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

P0_ScreenBufferSwap:
	; Swap double buffer screens then copper - assumes copper ptrs follow screen!
	;BPL_Phys_Ptr:		dc.l	0	;Screen buffers - physical
	;BPL_Log1_Ptr:		dc.l	0	;Logical1
	;CL_Phys_Ptr:		dc.l	0	;Copper ptr - physical
	;CL_Log1_Ptr:		dc.l	0	;Logical1	
	lea	CTRL_BPL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1.l = physical
	
	;lea	CTRL_CL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap CL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)			;d1 is phys

	; and activate next frame - d1 is physical
	move.l 	d1,cop1lch(a6)		; Active NEXT frame

	rts


*****************************************************************************
* Clears the entire work buffer screen. Every frame.
* Clears with the blitter and CPU.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

;Clear_WorkBuffer_BlitterCPU_A6:

; Tune this so that the very first WAITBLIT call AFTER this
; routine should take no time at all.
;	move.l  CTRL_BPL_LOG1_PTR(a5),a0	;memory to clear
;	move.w	#BPL_BUF_TOTALSIZE/2,d0		;size in words
;	move.w	#35150,d1
;	jsr	FW_ClearBuffer_BlitCPU_A6	;I:a6, T:d0-d7/a0-a4
;	rts


*****************************************************************************
* Clears the entire work buffer screen. Every frame.
* Clears with the blitter only.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a5
*****************************************************************************

;Clear_WorkBuffer_Blitter_A6:

;	move.l  CTRL_BPL_LOG1_PTR(a5),a0	;memory to clear
;	WAITBLIT_NASTY_A6
;	move.l	#$01000000,bltcon0(a6)
;	move.l	a0,bltdpth(a6)
;	move.w	#0,bltdmod(a6)
	;move.w	#((BPL_BUF_HEIGHT*BPL_BUF_NUMPLANES)*64)+BPL_BUF_WORDWIDTH,bltsize(a6)
	; Max height = 1024, made wordwidth = 64

;	rts


*****************************************************************************
* Clears all the buffers we will use. Done once at startup to ensure clean
* environment. Uses CPU for precalc routine.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Clear_ScreenBuffers_CPU:
	movem.l	d2-d7/a2-a6,-(sp)

	move.l	CTRL_BPL_PHYS_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	;Same buffer
	;move.l	CTRL_BPL_LOG1_PTR(a5),a0
	;move.w	#(BPL_BUF_TOTALSIZE/2),d0
	;jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6
	rts


*****************************************************************************
* Generate sine values between -8 and 8. Genrates an extra 256 words
* so can use for sine and cosine.
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Ripple_Generate_Sine:
	movem.l	d2-d3,-(sp)

	;move.l	CTRL_SINETAB_RIPPLE_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

	;change range from -16384 to 16384 to 0 to 256
.changerange:
	lea	GenSin_Table_16384_2048W,a0
	move.l	CTRL_SINETAB_RIPPLE_PTR(a5),a1
	;move.w	#128,d0
	move.w	#(LIB_GENSIN_16384_2048W_NUMWORDS+(LIB_GENSIN_16384_2048W_NUMWORDS/4))-1,d1
	moveq	#0,d2
.cl:
	move.w	(a0)+,d3	
	asr.w	#8,d3			;change range to -64 to 64
	asr.w	#2,d3			;change range to -16 to 16
	addx.w	d2,d3			;round up
	;add.w	d0,d3			;0-256
	move.w	d3,(a1)+
	dbf	d1,.cl

	movem.l	(sp)+,d2-d3
	rts


*****************************************************************************
* Runs the controller script.
* Note the commands are read until a FX_PAUSE command is reached. So beware
* of hogging the CPU with too many commands at once.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Controller_ReadCommands:

	move.l	CTRL_SCRIPT_PTR(a5),a4		;Get current script ptr

	;First check if any types of pause/wait are happening
	move.w	CTRL_PAUSE_COUNTER(a5),d0
	bne.s	.pausing

	ifne	PERFORM_ENABLE_MUSICSYNC
	tst.w	CTRL_MUSICSYNCMASKWAIT(a5)	;Are we waiting for a music sync signal?
	bne.s	.exit				;handled in Controller_MusicSync_Perform
	endif

	ifne	PERFORM_ENABLE_USERVALWAIT
	tst.w	CTRL_USERVALWAIT_ACTIVE(a5)
	bne	.uservalwait
	endif

	move.w	CTRL_ISFRAMEOVER_COUNTER(a5),d0
	bne.s	.isframeover

	move.w	CTRL_ISMASTERFRAMEOVER_COUNTER(a5),d0
	bne.s	.ismasterframeover

	tst.w	CTRL_FINISHED(a5)
	bne.s	.exit

.loop:
	move.w	(a4)+,d0		;Get script command, will be a long offset which matches the bra.w xxx jmptable
	jmp	.jmptable(pc,d0.w)	;Run routine, must preserve a4-a6

.jmptable:
	bra.w	.fx_end			;FX_END_FLAG
	bra.w	.fx_pause		;FX_PAUSE_FLAG
	bra.w	.fx_start_masterframe	;FX_STARTWAIT_MASTERFRAME_FLAG
	bra.w	.fx_get_masterframe	;FX_GET_MASTERFRAME_FLAG
	bra.w	.fx_ismasterframeover	;FX_ISMASTERFRAMEOVER_FLAG
	bra.w	.fx_isframeover		;FX_ISFRAMEOVER_FLAG
	bra.w	.fx_scriptjmp		;FX_SCRIPTJMP_FLAG
	bra.w	.fx_pallete		;FX_PALETTE_FLAG
	bra.w	.fx_next_phase		;FX_NEXT_PHASE_FLAG
	bra.w	.fx_musicsyncmask	;FX_MUSICSYNCMASK
	bra.w	.fx_musicsyncmaskwait	;FX_MUSICSYNCMASKWAIT
	bra.w	.fx_userval		;FX_USERVAL
	bra.w	.fx_uservalwait		;FX_USERVALWAIT
	bra.w	.fx_sineset		;FX_SINE_SET_FLAG
	bra.w	.fx_zoom		;FX_ZOOM_FLAG
	bra.w	.fx_zoomspring		;FX_ZOOMSPRING_FLAG
	bra.w	.fx_ripple		;FX_RIPPLE_FLAG

.fx_end:
	move.w	#1,CTRL_FINISHED(a5)	;exit entire effect
.exit:
	move.l	a4,CTRL_SCRIPT_PTR(a5)	;save current script position
	rts

.pausing:
	subq.w	#1,CTRL_PAUSE_COUNTER(a5)
	beq.s	.loop
	rts

.isframeover:
	cmp.w	CTRL_FRAME_COUNT(a5),d0
	bhi.s	.isframeover_exit
	clr.w	CTRL_ISFRAMEOVER_COUNTER(a5)	;finished
.isframeover_exit
	rts

.ismasterframeover:
	jsr	FW_IsFrameOver		;I:d0, O:d0 
	beq.s	.ismasterframeover_exit
	clr.w	CTRL_ISMASTERFRAMEOVER_COUNTER(a5)	;finished
.ismasterframeover_exit
	rts

.uservalwait:
	move.w	CTRL_USERVALWAIT_OFFSET(a5),d0
	move.w	(a5,d0.w),d0
	cmp.w	CTRL_USERVALWAIT_VAL(a5),d0
	bne.s	.uservalwait_exit
	clr.w	CTRL_USERVALWAIT_ACTIVE(a5)	;finished
.uservalwait_exit:	
	rts

.fx_pause:
	move.w	(a4)+,CTRL_PAUSE_COUNTER(a5)
	bra.s	.exit			;save script pos and exit

.fx_start_masterframe:
	move.w	(a4),d0			;frame to wait for
	jsr	FW_IsFrameOver		;I:d0, O:d0 
	beq.s	.fx_start_masterframe
	addq.l	#2,a4			;skip frame to wait for
	bra.s	.exit			;save script pos and exit

.fx_pallete:
	movem.w	(a4)+,d0-d1		;Speed,pal offset
	pea	.loop(pc)
	bra	Controller_FX_Palette	;I:d0/a0/a5, T:d0/a0-a1

.fx_ismasterframeover:
	move.w	(a4)+,d0		;frame to wait for
	move.w	d0,CTRL_ISMASTERFRAMEOVER_COUNTER(a5)
	bra.s	.exit			;save script pos and exit

.fx_isframeover:
	move.w	(a4)+,d0		;frame to wait for
	move.w	d0,CTRL_ISFRAMEOVER_COUNTER(a5)
	bra.s	.exit			;save script pos and exit

.fx_scriptjmp:
	move.l	(a4)+,a4		;New script
	bra	.loop

.fx_get_masterframe:
	jsr	FW_GetFrame		;Get master frame count
	tst.w	d0			;Set breakpoint here
	move.w	CTRL_FRAME_COUNT(a5),d0
	bra.s	.exit			;save script pos and exit

.fx_next_phase:
	addq.w	#1,CTRL_PHASE(a5)
	bra	.exit			;save script pos and exit

.fx_musicsyncmask:
	move.w	(a4)+,CTRL_MUSICSYNCMASK(a5)
	bra	.loop

.fx_musicsyncmaskwait:
	move.w	(a4)+,CTRL_MUSICSYNCMASKWAIT(a5)
	bra	.exit			;save script pos and exit

.fx_userval:
	move.w	(a4)+,d0		;CTRL_xxx offset
	move.w	(a4)+,(a5,d0.w)		;Write value into that CTRL offset
	bra	.loop

.fx_uservalwait:
	move.w	(a4)+,CTRL_USERVALWAIT_OFFSET(a5)	;CTRL_xxx offset
	move.w	(a4)+,CTRL_USERVALWAIT_VAL(a5)		;Value to wait for
	move.w	#1,CTRL_USERVALWAIT_ACTIVE(a5)
	bra	.exit			;save script pos and exit

.fx_sineset:				;sets a sine value in offset,speed,step ordering
	movem.w	(a4)+,d0-d4		;offset,speed,step,Controller_Info offset
	pea	.loop(pc)
	bra	Controller_FX_SineSet

.fx_zoom:
	movem.w	(a4)+,d0-d1		;speed,w
	bsr	Controller_FX_Zoom
	bra	.loop	

.fx_zoomspring:
	move.w	(a4)+,d0		;delta speed
	bsr	Controller_FX_ZoomSpring
	bra	.loop	

.fx_ripple:
	move.w	(a4)+,d0		;enable/disable
	bsr	Controller_FX_Ripple
	bra	.loop	


*****************************************************************************
* Performs any time-based controller routines.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a2-a4
*****************************************************************************

Controller_Perform:

	;Note that routines are called in reverse order to avoid lots of jumping around
	pea	Controller_FX_Ripple_Perform
	pea	Controller_FX_ZoomSpring_Perform
	pea	Controller_FX_Zoom_Perform
	
	ifne	PERFORM_ENABLE_SINESET
	pea	Controller_FX_SineSet_Perform(pc)	;I:a5, T:d0-d1/a0
	endif

	ifne	PERFORM_ENABLE_MUSICSYNC
	pea	Controller_MusicSync_Perform(pc)	;I:a5, T:d0-d2/a0
	endif	
	
	bra	Controller_FX_Palette_Perform		;I:a5, T:d0-d6/a0-a2
	
	;rts


*****************************************************************************
* Gets any music sync commands a sets up the response.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	ifne PERFORM_ENABLE_MUSICSYNC
Controller_MusicSync_Perform:
	;bits 0-3 are new note channels
	;bits 4-7 are E8x values shifted << 4
	;Values between $0-$ff
	jsr	FW_MusicGetSyncVal		;O:d0.w, T:d0/d1

	;And with our mask, this gives our script the option to mask events
	;if needed without having to be complicated with other code
	and.w	CTRL_MUSICSYNCMASK(a5),d0
	move.w	d0,CTRL_MUSICSYNC(a5)

	;Is there a musicsyncmaskwait in progress that we can release?
	move.w	CTRL_MUSICSYNCMASKWAIT(a5),d1
	beq.s	.nowait
	move.w	d0,d2
	and.w	d1,d2
	cmp.w	d1,d2
	bne.s	.nowait
	clr.w	CTRL_MUSICSYNCMASKWAIT(a5)	;wait is over
.nowait:

	;Are enough channels playing to trigger?
	;(Note you may wish to change this to lsr.w #4 if checking E8x bits)
	;lsr.w	#4,d0			;Get E8x bits into low nibble
	moveq	#$0f,d1
	and.w	d1,d0			;Ensure in range 0-f
	move.b	.triggers(pc,d0.w),d0
	beq.s	.exit

	;Have we triggered very recently?
	move.w	CTRL_FRAME_COUNT(a5),d0
	move.w	d0,d1
	sub.w	CTRL_MUSICSYNC_LASTFRAME(a5),d0
	cmp.w	#25,d0			;25 frame limit
	blt.s	.exit
	move.w	d1,CTRL_MUSICSYNC_LASTFRAME(a5)

	; DO TRIGGER OPERATION HERE

.exit:	
	rts

	;Trigger if 3 or 4 bits are set
.triggers:
	dc.b	0	;0
	dc.b	0	;1
	dc.b	0	;2
	dc.b	0	;3
	dc.b	0	;4
	dc.b	0	;5
	dc.b	0	;6
	dc.b	1	;7
	dc.b	0	;8
	dc.b	0	;9
	dc.b	0	;a
	dc.b	1	;b
	dc.b	0	;c
	dc.b	1	;d
	dc.b	1	;e
	dc.b	1	;f
	even

	endif				;PERFORM_ENABLE_MUSICSYNC


*****************************************************************************
* Sets up the palette change process.
* IN:		a5, Controller_Info
*		a0, new pallete
*		d0, speed
*		d1, palette offset
* OUT:		
* TRASHED:	d0/a0-a1
*****************************************************************************

Controller_FX_Palette:
	;Find palette ptr
	lea	PAL_PaletteStart,a0
	lea	(a0,d1.w),a0

	; If speed is 0 just instastransform
	tst.w	d0
	bne.s	.palette

	move.w	d0,CTRL_PALETTE_ACTIVE(a5)	;disable change, d0 is zero here
	move.w	#P0_CL_NUM_BUFFERS,CTRL_PALETTE_LOAD_FLAG(a5)	;request copper loads immediately twice for double buffer CL issues

	lea	PAL_Current(pc),a1

	rept PAL_NUMCOLS_ALL/2			;Number of longs
	move.l	(a0)+,(a1)+
	endr

	rts

.palette:
	move.l	a0,CTRL_PALETTE_PTR(a5)		; supplied pallete now the master
	move.w	d0,CTRL_PALETTE_COUNTER(a5)	; Setup counter and speed
	move.w	d0,CTRL_PALETTE_SPEED(a5)
	
	moveq	#1,d0				; Initial step is 1 (we run 1-15)
	move.w	d0,CTRL_PALETTE_STEP(a5)
	move.w	d0,CTRL_PALETTE_ACTIVE(a5)	; Set pallete flag to 1

	lea	PAL_Current(pc),a0			;current active colors
	lea	PAL_Current_Src(pc),a1		;store original active colors
	
	rept PAL_NUMCOLS_ALL/2			;Number of longs
	move.l	(a0)+,(a1)+
	endr

	rts


*****************************************************************************
* Performs the pallete change.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d6/a0-a3
*****************************************************************************

Controller_FX_Palette_Perform:
	tst.w	CTRL_PALETTE_ACTIVE(a5)
	bne.s	.active
	rts
.active:
	subq.w	#1,CTRL_PALETTE_COUNTER(a5)	;check counter
	bgt.s	.exit				;1 or greater we skip

	;Reset counter for next time
	move.w	CTRL_PALETTE_SPEED(a5),CTRL_PALETTE_COUNTER(a5)

	lea	PAL_Current_Src(pc),a0		;starting colors
	move.l	CTRL_PALETTE_PTR(a5),a1		;final colors
	lea	PAL_Current(pc),a2		;active colors
	moveq	#PAL_NUMCOLS_ALL,d0		;number of colours to touch
	move.w	CTRL_PALETTE_STEP(a5),d1	;step

	;In, d0=numcols, d1=step, a0-a2 palettes
	;Out, d1=step
	;trashes d0/d2-d7,a0-a2
	jsr	LIB_RGB12_Interpolate_Fast_Palette	;I:d0-d1/a0-a2, T:d0-d6/a0-a3

	;Request copper load this palette twice for double buffer cl issues
	move.w	#P0_CL_NUM_BUFFERS,CTRL_PALETTE_LOAD_FLAG(a5)

	; Increase step
	addq.w	#1,d1			;increase step
	move.w	d1,CTRL_PALETTE_STEP(a5)
	cmpi.w	#16,d1			;Was this the final step?
	blt.s	.exit	

	clr.w	CTRL_PALETTE_ACTIVE(a5)	;finish routine
.exit:
	rts


*****************************************************************************
* Sets up the pallet change process.
* IN:		a5, Controller_Info
*		d0, change speed (0 instant)
*		d1, offset
*		d2, speed
*		d3, step
*		d4, CTRL_SINE offset from a5
* OUT:		
* TRASHED:	d0/a0-a1
*****************************************************************************

Controller_FX_SineSet:
	lea	(a5,d4.w),a0		;Address of this sine structure

	; If speed is 0 just instastransform
	tst.w	d0
	bne.s	.gradual

.instant:
	move.w	d0,CTRL_SINESET_ACTIVE(a0)	;d0=0
	tst.w	d1
	bpl.s	.changeoffset
.keepoffset:
	movem.w	d2-d3,CTRL_SINE_SPEED(a0)	;leave current offset alone if d0 is -1
	rts
.changeoffset:
	movem.w	d1-d3,CTRL_SINE_OFFSET(a0)	;change all values
	rts

.gradual
	move.w	d0,CTRL_SINESET_ACTIVE(a0)	;active flag >0 and is the speed (initial counter value)
	movem.w	d2-d3,CTRL_SINE_SPEEDNEW(a0)	;leave current offset alone for gradual changes

	rts


*****************************************************************************
* Performs sine change.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d1/a0
*****************************************************************************

	ifne	PERFORM_ENABLE_SINESET
Controller_FX_SineSet_Perform:

	lea	CTRL_SINE1(a5),a0
	bsr.s	.checksine
	lea	CTRL_SINE2(a5),a0
	;bra.s	.checksine
	;fallthrough

.checksine:
	tst.w	CTRL_SINESET_ACTIVE(a0)
	bne.s	.active
	rts
.active:
	subq.w	#1,CTRL_SINESET_COUNTER(a0)	;check counter
	bgt.s	.exit				;1 or greater we skip

	moveq	#0,d1				;1 if still changing speed/step

	move.w	CTRL_SINE_SPEED(a0),d0
	cmp.w	CTRL_SINE_SPEEDNEW(a0),d0
	beq.s	.checkstep
	bgt.s	.speedgt
.speedlt:
	addq.w	#2,CTRL_SINE_SPEED(a0)		;2 is the smallest change value (a single even offset)
	moveq	#1,d1
	bra.s	.checkstep
.speedgt:
	subq.w	#2,CTRL_SINE_SPEED(a0)
	moveq	#1,d1

.checkstep
	move.w	CTRL_SINE_FREQ(a0),d0
	cmp.w	CTRL_SINE_FREQNEW(a0),d0
	beq.s	.checkdone
	bgt.s	.stepgt
.steplt:
	addq.w	#2,CTRL_SINE_FREQ(a0)
	moveq	#1,d1
	bra.s	.checkdone
.stepgt:
	subq.w	#2,CTRL_SINE_FREQ(a0)
	moveq	#1,d1

.checkdone:
	;Any changes left?
	tst.w	d1
	bne.s	.stillactive
	clr.w	CTRL_SINESET_ACTIVE(a0)		;finished
	rts

.stillactive
	;Reset counter for next time
	move.w	CTRL_SINESET_ACTIVE(a0),CTRL_SINESET_COUNTER(a0)	;using active as the initial count
.exit:
	rts
	endif

*****************************************************************************
* Zooms. Will do over time is speed >0
* IN:		a5, vec controller info
* 		d0-d1, speed,new w
* OUT:		
* TRASHED:	d0-d1
*****************************************************************************

Controller_FX_Zoom:
	;min/max zoom level is not limited here. It is limited in the copper routine

	clr.w	CTRL_ZOOMSPRING_ACTIVE(a5)	;can't be active at same time

	tst.w	d0
	bne.s	.slow
	;d0=0
	move.w	d1,CTRL_ZOOM(a5)		;change zoom immediately
	move.w	d0,CTRL_ZOOM_VEL(a5)		;reset velocities - hard stop	
	move.w	d0,CTRL_ZOOM_ACTIVE(a5)
	move.w	#P0_CL_NUM_BUFFERS,CTRL_ZOOM_LOAD_FLAG(a5)
	rts
.slow:
	move.w	#1,CTRL_ZOOM_ACTIVE(a5)
	move.w	d0,CTRL_ZOOM_MAXSPEED(a5)	
	move.w	d1,CTRL_ZOOM_REQ(a5)	
	;clr.w	CTRL_ZOOM_VEL(a5)		;no

	rts


*****************************************************************************
* Performs move change
* IN:		a5, VEC_Controller_Info
*		a0, current object info
* OUT:
* TRASHED:	d0-d6
*****************************************************************************

Controller_FX_Zoom_Perform:
	tst.w	CTRL_ZOOM_ACTIVE(a5)
	bne.s	.active
	rts
.active:
	;Request copper load this twice for double buffer cl issues
	move.w	#P0_CL_NUM_BUFFERS,CTRL_ZOOM_LOAD_FLAG(a5)

	;min/max zoom level is not limited here. It is limited in the copper routine
	move.w	CTRL_ZOOM(a5),d0	;current value
	move.w	CTRL_ZOOM_REQ(a5),d1	;final value
	move.w	CTRL_ZOOM_MAXSPEED(a5),d2	;speed
	move.w	CTRL_ZOOM_VEL(a5),d3	;vec

	;Move2_Coord is not for fixed point values so we need to reduce our zoom
	;TODO: Redo this lame code
	asr.w	#ZOOM_SHIFT,d0
	asr.w	#ZOOM_SHIFT,d1
	bsr	Move2_Coord_Towards
	asl.w	#ZOOM_SHIFT,d0

	move.w	d0,CTRL_ZOOM(a5)	;save value
	move.w	d3,CTRL_ZOOM_VEL(a5)	;save value
	cmp.w	CTRL_ZOOM_REQ(a5),d0	;finished?
	bne.s	.exit
	clr.w	CTRL_ZOOM_ACTIVE(a5)	;finished (double buffered)
.exit:
	rts


*****************************************************************************
* IN:		a5, vec controller info
* 		d0, delta speed
* OUT:		
* TRASHED:	d0-d1
*****************************************************************************

Controller_FX_ZoomSpring:
	;min/max zoom level is not limited here. It is limited in the copper routine
	clr.w	CTRL_ZOOM_ACTIVE(a5)		;can't be active at same time

	tst.w	CTRL_ZOOM(a5)
	bne.s	.setspeed
	
	;nothing to do, deactivate
	clr.w	CTRL_ZOOMSPRING_ACTIVE(a5)
	rts

.setspeed:
	move.w	#1,CTRL_ZOOMSPRING_ACTIVE(a5)
	move.w	d0,CTRL_ZOOM_DELTASPEED(a5)	
	rts


*****************************************************************************
* Performs Zoom Spring
* IN:		a5, VEC_Controller_Info
* OUT:
* TRASHED:	d0-d3
*****************************************************************************

Controller_FX_ZoomSpring_Perform:
	tst.w	CTRL_ZOOMSPRING_ACTIVE(a5)
	bne.s	.active
	rts
.active:
	;min/max zoom level is not limited here. It is limited in the copper routine
	;CTRL_ZOOM_VEL and CTRL_ZOOM_DELTASPEED are <<5

	move.w	CTRL_ZOOM(a5),d0
	move.w	CTRL_ZOOM_VEL(a5),d1
	move.w	CTRL_ZOOM_DELTASPEED(a5),d2

	;Once the velocity slows, check if its time close enough to end
	move.w	d2,d3
	asl.w	#4,d3			;Much less sensitive
	cmp.w	d3,d1
	bgt.s	.notfinished
	neg.w	d3
	cmp.w	d3,d1
	blt.s	.notfinished

	moveq	#1<<ZOOM_SHIFT,d3
	cmp.w	d3,d0
	bgt.s	.notfinished
	neg.w	d3
	cmp.w	d3,d0
	blt.s	.notfinished

.finished:
	clr.w	CTRL_ZOOM(a5)
	clr.w	CTRL_ZOOM_VEL(a5)		;Have to clear as not compatible with FX_ZOOM
	clr.w	CTRL_ZOOMSPRING_ACTIVE(a5)
	bra.s	.exit

.notfinished:
	move.w	d2,CTRL_ZOOM_DELTASPEED(a5)	;Save updated value
	bne.s	.deltaok
	moveq	#1,d2
.deltaok:
	tst.w	d0			;check direction
	bge.s	.shrinking
	blt.s	.stretching
	
.shrinking:
	neg.w	d2
	tst.w	d1			;if velocity =+ve we need to decelerate harder
	ble.s	.update
	move.w	d2,d3
	asr.w	#1,d3
	add.w	d3,d2
	bra.s	.update
.stretching:
	tst.w	d1			;if velocity =-ve we need to decelerate harder
	bge.s	.update
	move.w	d2,d3
	asr.w	#1,d3
	add.w	d3,d2

.update:
	add.w	d2,d1			;update velocity
	move.w	d1,CTRL_ZOOM_VEL(a5)	;save value

	add.w	d1,d0			;update zoom
	move.w	d0,CTRL_ZOOM(a5)	;save value
.exit:
	move.w	#P0_CL_NUM_BUFFERS,CTRL_ZOOM_LOAD_FLAG(a5)	;Load copper
	rts


*****************************************************************************
* Moves a coordinate towards a value at given speed.
* IN:		d0, current value
*		d1, target value
*		d2, max speed
*		d3, velocity
* OUT:		d0, new value
*		d3, new velocity
* TRASHED:	
*****************************************************************************

Move2_Coord_Towards:
VEC_MOVE2_ACCEL = 2	;value to slow down the acceleration per frame

	cmp.w	d1,d0
	bgt.s	.greater
	blt.s	.less

	;already there
	moveq	#0,d3			;new velocity is 0
	rts
.less:					
	;velocity should be +ve, if not then assume need to increase +ve vel
	;i.e. reverse direction slowly
	tst.w	d3
	bmi.s	.less_accel

	;distance to come to stop = (speed*speed)/(2*maxDecel)
	;maxAccel is essentially 1 per frame so 2*1 = 2 = asr.w #1
	move.w	d3,d4			;current velocity
	muls	d4,d4			;speed*speed
	asr.w	#1,d4			;d4=distance to come to stop 

	move.w	d1,d5			;save target
	sub.w	d0,d5			;distance
	asl.w	#VEC_MOVE2_ACCEL,d5	;scale up to match velocity/speeds
	cmp.w	d4,d5			;Do we need to start decelerating?
	bge.s	.less_accel		;carry on accelerating
.less_decel:	
	cmp.w	#(1<<VEC_MOVE2_ACCEL),d3	;keep vel above minimum for this scaling
	ble.s	.less_do_move		;don't change any more
	subq.w	#1,d3			;decelerate more
	bra.s	.less_do_move
.less_accel:				;still accelerating
	cmp.w	d2,d3
	beq.s	.less_do_move		;max vel?
	bgt.s	.less_accel_rev
	addq.w	#1,d3			;increase velocity
	bra.s	.less_do_move
.less_accel_rev:
	subq.w	#1,d3			;decrease velocity
.less_do_move:
	move.w	d3,d2			;save
	asr.w	#VEC_MOVE2_ACCEL,d2	;scale velocity down
	add.w	d2,d0			;add the velocity
	;cmp.w	d1,d0			;at target?
	;bge.s	.set_to_final		;finished or overshot?
	rts				;d0=new pt, d3=new vel

; -----

.greater:
	;velocity should be -ve, if not then assume need to increase -ve vel
	;i.e. reverse direction slowly
	neg.w	d2			;maxspeed is -ve
	tst.w	d3
	bpl.s	.greater_accel

	;distance to come to stop = (speed*speed)/(2*maxDecel)
	;maxAccel is essentially 1 per frame so 2*1 = 2 = asr.w #1
	move.w	d3,d4			;current velocity
	muls	d4,d4			;speed*speed (will be postive)
	asr.w	#1,d4			;d4=distance to come to stop 

	move.w	d0,d5			;save cur
	sub.w	d1,d5			;distance, 
	asl.w	#VEC_MOVE2_ACCEL,d5	;scale up to match velocity/speeds
	cmp.w	d4,d5			;Do we need to start decelerating?
	bge.s	.greater_accel		;carry on accelerating
.greater_decel:	
	cmp.w	#-(1<<VEC_MOVE2_ACCEL),d3	;keep vel above minimum for this scaling
	bge.s	.greater_do_move		;don't change any more
	addq.w	#1,d3			;decelerate more
	bra.s	.greater_do_move
.greater_accel:				;still accelerating
	cmp.w	d2,d3
	beq.s	.greater_do_move	;max vel?
	blt.s	.greater_accel_rev
	subq.w	#1,d3			;increase velocity
	bra.s	.greater_do_move
.greater_accel_rev:
	addq.w	#1,d3			;decrease velocity
.greater_do_move:
	move.w	d3,d2			;save
	neg	d2			;asr on negative numbers always gives at least -1
	asr.w	#VEC_MOVE2_ACCEL,d2	;scale velocity down
	sub.w	d2,d0			;sub the velocity (vel positive here)
	;cmp.w	d1,d0			;at target?
	;ble.s	.set_to_final		;finished or overshot?
	rts				;d0=new pt, d3=new vel

.set_to_final:
	move.w	d1,d0			;overshot, set value to final
	moveq	#0,d3			;new velocity is 0
	rts




*****************************************************************************
* Ripple. 
* IN:		a5, vec controller info
* 		d0.w, enable/disable 1/0
* OUT:		
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

Controller_FX_Ripple:
	clr.w	CTRL_ZOOMSPRING_ACTIVE(a5)	;can't be active at same time
	clr.w	CTRL_ZOOM_ACTIVE(a5)	;can't be active at same time
	move.w	d0,CTRL_RIPPLE_ACTIVE(a5)

	bne.s	.exit			;all done

	;To disable just change all entries to 0
	move.l	a4,-(sp)
	lea	Ripple_Table,a0
	move.w	#RIPPLE_TABLE_NUMWORDS,d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4
	move.w	#RIPPLE_TABLE_NUMWORDS,CTRL_RIPPLE_VISIBLE_LINES(a5)	;All lines visible
	move.l	(sp)+,a4
.exit:
	move.w	#P0_CL_NUM_BUFFERS,CTRL_RIPPLE_LOAD_FLAG(a5)
	rts


*****************************************************************************
* Performs move change
* IN:		a5, VEC_Controller_Info
*		a0, current object info
* OUT:
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

Controller_FX_Ripple_Perform:
	tst.w	CTRL_RIPPLE_ACTIVE(a5)
	bne.s	.active
	rts
.active:
	;Request copper load this twice for double buffer cl issues
	move.w	#P0_CL_NUM_BUFFERS,CTRL_RIPPLE_LOAD_FLAG(a5)

	move.l	CTRL_SINETAB_RIPPLE_PTR(a5),a0
	lea	Ripple_Table,a1

	; Sine 1
	lea	CTRL_SINE1(a5),a4		;get sine structure
	move.w	CTRL_SINE_OFFSET(a4),d4	;Offset in words
	add.w	CTRL_SINE_SPEED(a4),d4		;Get speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d4	;Ensure in range
	move.w	d4,CTRL_SINE_OFFSET(a4)	;Save for next frame
	move.w	CTRL_SINE_FREQ(a4),a2		;Get step (movement per pixel)
	;d2=cur offset, d3=step

	; Sine 2
	lea	CTRL_SINE2(a5),a4		;get sine structure
	move.w	CTRL_SINE_OFFSET(a4),d5	;Offset in words
	add.w	CTRL_SINE_SPEED(a4),d5		;Get speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d5	;Ensure in range
	move.w	d5,CTRL_SINE_OFFSET(a4)	;Save for next frame
	move.w	CTRL_SINE_FREQ(a4),a3		;Get step (movement per pixel)
	;d4=cur offset, a4=step

	moveq	#0,d6			;num visible lines
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d3
	move.w	#RIPPLE_TABLE_NUMWORDS-1,d7
	move.w	(a0,d4.w),d0		;Do first iteration outside loop 
	;add.w	(a0,d5.w),d0		;to seed "previous" value
	;asr.w	#2,d0			;-1 to 1
	bra.s	.show			;always show first line
.l0:	
	move.w	(a0,d4.w),d0		;-16 to 16
	;add.w	(a0,d5.w),d0		;-32 to 32
	;asr.w	#1,d0			;-8 to 8
	cmp.w	d1,d0
	blt.s	.skip
	bgt.s	.rept
.show:
	move.w	d0,d1
	moveq	#0,d0	
	;addq.w	#1,d6			;1 more visible line	
	bra.s	.write
.rept:	
	move.w	d0,d1
	moveq	#1,d0
	;addq.w	#1,d6			;rept lines counts as 2
	bra.s	.write
.skip:	
	move.w	d0,d1
	;subq.w	#1,d6			;no visble line
	moveq	#-1,d0

.write:
	move.w	d0,(a1)+		;save value

	add.w	a2,d4			;Sine1 offset+=step
	and.w	d3,d4			;Ensure in range
	;add.w	a3,d5			;Sine2 offset+=step
	;and.w	d3,d5			;Ensure in range

	dbf	d7,.l0

	;Write number of visible lines, seems to need -2 to avoid issues
	;TODO: work out why
	;subq.w	#1,d6
	move.w	#254,CTRL_RIPPLE_VISIBLE_LINES(a5)

.exit:
	rts


*****************************************************************************
* Loads the current colors into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0/a0-a1
*****************************************************************************

Copper_Write_Palette:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_PALETTE_LOAD_FLAG(a5)
	bne.s	.active
	rts
.active:	
	subq.w	#1,CTRL_PALETTE_LOAD_FLAG(a5)

	lea	PAL_Current(pc),a0
	move.l	CTRL_CL_LOG1_PTR(a5),a1

	;Normal colors
	lea	P0_CL_COL_OFFSET+2(a1),a1	

	rept	PAL_NUMCOLS_MAIN
	move.w	(a0)+,(a1)
	addq.l	#4,a1			;next color
	endr
.exit:	
	rts


*****************************************************************************
* Loads the current zoom into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Copper_Write_Zoom:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_ZOOM_LOAD_FLAG(a5)
	beq.s	.exit
	subq.w	#1,CTRL_ZOOM_LOAD_FLAG(a5)

	;Check zoom level, none, stretch or shrink
	move.w	CTRL_ZOOM(a5),d6	;0 is nozoom
	bgt	Do_Copper_Zoom_Stretch
	blt	Do_Copper_Zoom_Shrink

	; Unique case - no zoom
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_ZOOM_PATTERN_OFFSET+CL_PATTERN_BPLCON0+2(a0),a1

	; Clear vertical bplcon0 values (default is vector visible as normal)
	move.w	#BPL_BUF_HEIGHT-1,d3
	move.w	#ZOOM_BPLCON0_ON,d0
	move.w	#BPL_BPLMOD,d1
	moveq	#CL_PATTERN_SIZEOF,d2
.clearloop:
	move.w	d0,(a1)						;bplcon0
	move.w	d1,CL_PATTERN_BPL1MOD-CL_PATTERN_BPLCON0(a1)	;bpl1mod
	move.w	d1,CL_PATTERN_BPL2MOD-CL_PATTERN_BPLCON0(a1)	;bpl2mod
	add.l	d2,a1
	dbf	d3,.clearloop	

	;Set vertial scaling to 0
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_LOG1_PTR(a5),d1
	moveq 	#BPL_BUF_BYTEWIDTH,d2	;interleaved
	jsr	FW_InitCopperBplPtrs	;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo
.exit:
	rts


*****************************************************************************
* Loads the current zoom into the current copperlist if changed.
* This works by repeating lines as needed.
* IN:		a5, VEC_Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Do_Copper_Zoom_Stretch:
	move.w	CTRL_ZOOM(a5),d3	;0 is nozoom

	cmpi.w	#ZOOM_MAX,d3
	ble.s	.maxok
	move.w	#ZOOM_MAX,d3
.maxok:
	asr.w	#ZOOM_SHIFT,d3		;Scale down

	;zoom value is the new Y size DIFF. If size is 16 pixels larger then 
	;need to start the image 8 lines later
	move.w	d3,d1			;save zoom in d3
	lsr.w	#1,d1			;half, U1
;	beq.s	.zero
;.zero:	
	mulu	#BPL_BUF_MOD_LINE,d1	;offset pointer to first line to show
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0
	moveq	#BPL_BUF_NUMPLANES,d0
	add.l	CTRL_BPL_LOG1_PTR(a5),d1	;d1 offset from above in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_BYTEWIDTH,d2	;interleaved
	jsr	FW_InitCopperBplPtrs	;I:d0-d2/a0, T:d0-d1/a0

	; Now work out individual lines
	move.l	#BPL_BUF_HEIGHT,d1	;.l for divu later
	move.l	d1,d0			;.l for divu later
	sub.w	d3,d0			;U2-U1 (source height)
	lsl.l	#8,d0			;U2-U1 * 256 (fixed point)
	divu	d1,d0			;d0, dU = (U2-U1 / DestHeight (BPL_BUF_HEIGHT)

	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_ZOOM_PATTERN_OFFSET+CL_PATTERN_BPLCON0+2(a0),a0
	move.w	#CL_PATTERN_SIZEOF,a1
	move.w	#ZOOM_BPLCON0_ON,a2
	move.w	#BPL_BPLMOD_REPTLINE,a3	;show previous line
	move.w	#BPL_BPLMOD,a4		;show new line
	moveq	#-1,d1			;d1, lastline (impossible line to start)
	moveq	#0,d2			;d2, linevalue (add dU each line)


	move.w	#BPL_BUF_HEIGHT-1,d4			;-1 for dbf
.lineloop:
	move.w	a2,(a0)			;bplcon0 on

	add.w	d0,d2			;linevalue += dU
	move.w	d2,d3
	lsr.w	#8,d3			;/256
	cmp.w	d1,d3			;newline = lastline?
	beq.s	.reptline
.showline:
	move.w	a4,4(a0)		;bpl1mod
	move.w	a4,8(a0)		;bpl2mod
	add.l	a1,a0			;next copper entry
	move.w	d3,d1			;update lastline
	dbf	d4,.lineloop
	bra.s	.endloop
.reptline:
	move.w	a3,4(a0)		;bpl1mod
	move.w	a3,8(a0)		;bpl2mod
	add.l	a1,a0			;next copper entry
	move.w	d3,d1			;update lastline
	dbf	d4,.lineloop
.endloop:

	rts


*****************************************************************************
* Loads the current zoom into the current copperlist if changed.
* IN:		a5, VEC_Controller_Info
* OUT:
* TRASHED:	d0-d6/a0-a4
*****************************************************************************

Do_Copper_Zoom_Shrink:
	move.w	CTRL_ZOOM(a5),d3	;0 is nozoom

	cmpi.w	#ZOOM_MIN,d3
	bge.s	.minok
	move.w	#ZOOM_MIN,d3
.minok
	asr.w	#ZOOM_SHIFT,d3		;Scale down

	;zoom is the DIFF. i.e the number of lines to subtract from the image height
	neg.w	d3			;We can use the same table if we negate
	move.w	#BPL_BUF_HEIGHT,d4
	move.w	d4,d6			;save
	sub.w	d3,d4			;d4, new height
	lsr.w	#1,d3			;d3, Number of top lines to skip
	sub.w	d3,d6
	sub.w	d4,d6			;d6, Number of bottom lines to skip

	;Write screen ptrss
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_LOG1_PTR(a5),d1	;d1 offset from above in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_BYTEWIDTH,d2	;interleaved
	jsr	FW_InitCopperBplPtrs	;I:d0-d2/a0, T:d0-d1/a0

	; Turn off bplcon0 for top most lines
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_ZOOM_PATTERN_OFFSET+CL_PATTERN_BPLCON0+2(a0),a0
	move.w	#CL_PATTERN_SIZEOF,a1
	move.w	#BPL_BPLMOD_REPTLINE,a3	;show previous line
	move.w	#BPL_BPLMOD,a4		;show new line

	;d3=top lines to skip, d4=new height, d5=bottom lines to skip
	move.l	#BPL_BUF_HEIGHT*256,d0	;.l for divu later, U2-U1 is full image size
	divu	d4,d0			;d0, dU = (U2-U1 / DestHeight (BPL_BUF_HEIGHT)

	;For top lines turn bplcon0 off
.bplconoff:
	subq.w	#1,d3			;-1 for dbf
	bmi.s	.bplconon
	move.w	#ZOOM_BPLCON0_OFF,a2
	.bplconoffloop:
	move.w	a2,(a0)
	add.l	a1,a0			;next copper entry
	dbf	d3,.bplconoffloop

	;Turn on bplcon0 for remaining image lines (d4=new height) and scale 
.bplconon:
	subq.w	#1,d4			;-1 for dbf
	bmi.s	.bplconoff2

	moveq	#0,d1			;d1, lastline 
	moveq	#0,d2			;d2, linevalue (add dU each line)
	move.w	#ZOOM_BPLCON0_ON,a2
	move.w	#BPL_BPLMOD,a3		;default is to move to next line as normal
.bplcononloop:
	move.w	a2,(a0)			;bplcon0 on
	move.w	a3,a4			;default is to move to next line as normal

	add.w	d0,d2			;linevalue += dU
	move.w	d2,d3
	lsr.w	#8,d3			;/256
	move.w	d3,d5			;save
	sub.w	d1,d3			;newline-lastline
	subq.w	#1,d3			;(newline-lastline)-1
	blt.s	.write

	mulu	#BPL_BUF_MOD_LINE,d3	;TODO: Precalc
	add.w	d3,a4
.write:	
	move.w	d5,d1			;update lastline

	move.w	a4,4(a0)		;bpl1mod
	move.w	a4,8(a0)		;bpl2mod
	add.l	a1,a0			;next copper entry
	dbf	d4,.bplcononloop

	; For remaining lines just turn bplcon0 off
.bplconoff2:
	subq.w	#1,d6			;-1 for dbf
	bmi.s	.endloop
	move.w	#ZOOM_BPLCON0_OFF,a2

.bplconoffloop2:
	move.w	a2,(a0)			;bplcon0 off
	add.l	a1,a0			;next copper entry
	dbf	d6,.bplconoffloop2
.endloop:

	rts


*****************************************************************************
* Loads the current zoom into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Copper_Write_Ripple:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_RIPPLE_LOAD_FLAG(a5)
	beq	.exit
	subq.w	#1,CTRL_RIPPLE_LOAD_FLAG(a5)

	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_ZOOM_PATTERN_OFFSET+CL_PATTERN_BPLCON0+2(a0),a1
	move.w	#CL_PATTERN_SIZEOF,a2
	lea	Ripple_Table,a3

	move.w	#BPL_BUF_HEIGHT-1,d4
	move.w	#BPL_BPLMOD_REPTLINE,d0
	move.w	#BPL_BPLMOD,d1
	move.w	#BPL_BPLMOD_SKIPLINE,d2
	move.w	#ZOOM_BPLCON0_ON,d3
	move.w	CTRL_RIPPLE_VISIBLE_LINES(a5),d5
	;move.w	d1,d0
	;move.w	d1,d2
	;move.w	#ZOOM_BPLCON0_ON,d0
.clearloop:
	;move.w	d0,(a1)			;bplcon0 (zoom routine may have changed)

	tst.w	(a3)+
	beq.s	.show
	bmi.s	.skip
.rept:
	move.w	d3,(a1)			;bplcon0
	move.w	d0,4(a1)		;bpl1mod
	move.w	d0,8(a1)		;bpl2mod
	bra.s	.next
.show:
	move.w	d3,(a1)			;bplcon0
	move.w	d1,4(a1)
	move.w	d1,8(a1)
	bra.s	.next
.skip:
	move.w	d3,(a1)			;bplcon0
	move.w	d2,4(a1)
	move.w	d2,8(a1)
.next:
	;May need to turn off bplcon0 if number of visible lines is less than visible buf
	subq.w	#1,d5
	bgt.s	.nextloop
	move.w	#ZOOM_BPLCON0_OFF,d3
.nextloop:
	add.w	a2,a1
	dbf	d4,.clearloop	
.exit:
	rts


*****************************************************************************
*****************************************************************************
*****************************************************************************


	; Include additional public data
	include "SectionData_PublicData.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	;section	FW_ChipBss,bss_c
	include "SectionData_ChipData.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	ifne	_VERBOSE
	printt	""
	printt	"STRETCHVERT:"
	printt	"CHIPMEM:"
	printv	(P0_CL_SIZE*2)+BPL_BUF_TOTALSIZE

	;printt	"CUR_PUB_BUF:"
	;printv	CUR_PUB_BUF
	endif

*****************************************************************************
