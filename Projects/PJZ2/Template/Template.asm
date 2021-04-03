*****************************************************************************

; Name			: Template.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Template routine.
; Date last edited	: 04/02/2020
				
*****************************************************************************

RasterTest set 2	;color00 timing bar, 0=off, 1=overall, 2=show blitwaits

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

P0_SCANLINE_EOF		equ	P0_DIW_V+P0_DIW_HEIGHT	; Safe to starting clearing after this scanline
							; 0 is essentially vblank

; This value is used for loading the CL with colours and stuff, we might need
; to do it more than once, for example fading colours in a double-buffered CL
; we need to write the values twice so that after finishing both CLs have been updated
; Set to 1 for single CL, 2 for double-buffered, etc
P0_CL_NUM_BUFFERS	equ	1

*****************************************************************************

*** Screen Definitions ***

;BPL_BUF_xxx is the underlying buffer, might not match visible
BPL_BUF_WIDTH		equ	320
BPL_BUF_BYTEWIDTH	equ	BPL_BUF_WIDTH/8
BPL_BUF_WORDWIDTH	equ	BPL_BUF_BYTEWIDTH/2
BPL_BUF_HEIGHT		equ	256
BPL_BUF_NUMPLANES	equ	3
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

PERFORM_ENABLE_MUSICSYNC	equ	1
PERFORM_ENABLE_SINESET		equ	0
PERFORM_ENABLE_USERVALWAIT	equ	0

*****************************************************************************

PAL_NUMCOLS_MAIN	equ	BPL_BUF_NUMCOLS	; number of main colour entries in our palettes
PAL_NUMCOLS_ALT		equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_ALT)


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

	xdef	TMP_Start
TMP_Start:
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
	xdef	TMP_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
TMP_PreCalc_IntroStart:
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
	xdef	TMP_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
TMP_P0_PreCalc:
	movem.l	d2-d7/a2-a6,-(sp)	;save (not d0)
	lea	Controller_Info(pc),a5
	tst.w	CTRL_P0_PRECALC_DONE(a5)
	bne.s	.exit			;already done

	;Change color to show where this starts
	;move.w	#$fff,color00+_custom


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
	jsr	FW_Mem_NewEffect_Public
	jsr	FW_Mem_NewEffect_Chip

	;Alloc mem and setup memory ptrs to static areas
	;For maximum overlap protection between parts allocate in this order for chipmem
	;Copperlists,Sprite data,effect data,bitplanes

	ifgt P0_CL_NUM_BUFFERS-1
		move.l	#P0_CL_Phys,CTRL_CL_PHYS_PTR(a5)	;Static

		move.l	#P0_CL_SIZE,d0
		jsr	FW_Mem_Alloc_Chip
		move.l	d0,CTRL_CL_LOG1_PTR(a5)
	else
		lea	P0_CL_Phys,a0
		move.l	a0,CTRL_CL_PHYS_PTR(a5)
		move.l	a0,CTRL_CL_LOG1_PTR(a5)	
	endif	;P0_CL_NUM_BUFFERS>1

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_PHYS_PTR(a5)

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_LOG1_PTR(a5)

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
	bsr.s	SubPart_P0_PreCalc	;O:d0, T:d0-d1/a0-a1
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

	; Clear all screen buffers (previous routine must have blanked screen/colors)
	bsr	Clear_ScreenBuffers_CPU

	; Multiply sine values by screen widths
	lea	Mult_SCR_Height_ByteWidth_NumPlanes,a0
	move.w	#BPL_BUF_MOD_LINE,d0
	move.w	#BPL_BUF_HEIGHT,d1
	jsr	FW_PreMultCreate_W

	;Run script up to the first FX_PAUSE command - use for setting base effect 
	;settings and palette rather than wasting code here on it
	bsr	Controller_ReadCommands	;I:a5, T:d0-d7/a0-a4

	;Setup phys/logical bpl and copperlist ptrs and load palette
	bsr	P0_CL_InitPtrs		;I:a5-a6, T:d0-d2/a0-a1
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

	bsr	NoiseTest		;Test noise
	bsr	BOBTest			;Test BOB output
	bsr	DotTest			;Test dots

	;Load current palette into CL if needed
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2

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

	; Point sprites at dummy sprite in base copper list
	lea	P0_CL_Scr_Sprites,a0
	moveq	#8,d0			;8 sprites
	jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1

	lea	Sprite0,a0
	move.w	#P0_DIW_H+30,d0
	move.w	#P0_DIW_V,d1
	moveq	#16,d2
	GET_SPRITE_CTRL_WORDS		;I:d0-d2, O:d1-d2, T:d0-d3
	move.w	d1,(a0)			;update control words
	move.w	d2,2(a0)
	
	move.l	a0,d0
	lea	P0_CL_Scr_Sprites+2,a0
	move.w	d0,4(a0)		;ptl
	swap	d0
	move.w	d0,(a0)			;pth

	
	;Setup BPL ptrs (assuming double buffered usually)
	;move.l	#BPL_Phys,CTRL_BPL_PHYS_PTR(a5)
	;move.l	#BPL_Log1,CTRL_BPL_LOG1_PTR(a5)

	;Setup CL buffers and ptrs
	ifgt P0_CL_NUM_BUFFERS-1
		; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
		move.l	CTRL_CL_PHYS_PTR(a5),a0
		move.l	CTRL_CL_LOG1_PTR(a5),a1

		move.w	#(P0_CL_SIZE/2),d0	;size in words
		jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2	
	endif	;P0_CL_NUM_BUFFERS>1
	
	;Front buffer copperlist (or single buffer)
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	lea	P0_CL_BPL_OFFSET(a0),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo

	;Back buffer copperlist
	ifgt P0_CL_NUM_BUFFERS-1
		move.l	CTRL_CL_LOG1_PTR(a5),a0
		lea	P0_CL_BPL_OFFSET(a0),a0		;copper bpl pointer block
		moveq	#BPL_BUF_NUMPLANES,d0
		move.l	CTRL_BPL_LOG1_PTR(a5),d1	;in d1 for InitCopperBplPtrs
		moveq 	#BPL_BUF_MOD_BPL,d2
		jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo
	endif	;P0_CL_NUM_BUFFERS>1

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

	; Swap screen buffer details - different ways left here
	; as a reminder which is fastest

	; Double buffer
;	lea	BPL_Phys_Ptr(pc),a0	;8 (2/0)
;	move.l	(a0),d0			;12 (3/0)
;	move.l 	4(a0),d1		;16 (4/0)
;	exg	d0,d1			;6 (1/0)
;	move.l	d0,(a0)+		;12 (1/2)
;	move.l	d1,(a0)			;12 (1/2)
					;66 (12/4)

;	lea	BPL_Phys_Ptr(pc),a0	;8 (2/0)
;	movem.l	(a0),d0-d1		;12+8n (3+2n/0) = 28 (7/0)
;	exg	d0,d1			;6 (1/0)
;	movem.l	d0-d1,(a0)		;8+8n (2/2n) = 24 (2/4)
					;66 (12/4)
	
;	lea	BPL_Phys_Ptr(pc),a0	;8 (2/0)
;	movem.l	(a0),d0-d1		;12+8n (3+2n/0) = 28 (7/0)
;	move.l	d1,(a0)+		;12 (1/2)
;	move.l	d0,(a0)			;12 (1/2)
					;60 (11/4)
	;Triple buffer
;	lea	BPL_Phys_Ptr(pc),a0	;8 (2/0)
;	movem.l	(a0),d0-d2		;12+8n (3+2n/0) = 28 (7/0)
;	exg	d0,d1			;6 (1/0)
;	exg	d1,d2			;6 (1/0)
;	movem.l	d0-d2,(a0)		;8+8n (2/2n) = 32 (2/6)
					;80 (13/6)

;	lea	BPL_Phys_Ptr(pc),a0	;8 (2/0)
;	movem.l	(a0),d0-d2		;12+8n (3+2n/0) = 28 (7/0)
;	movem.l	d1-d2,(a0)		;8+8n (2/2n) = 24 (2/4)
;	move.l 	d0,8(a0)		;16 (2/2)
					;76 (13/6)

	; Swap double buffer screens then copper - assumes copper ptrs follow screen!
	;BPL_Phys_Ptr:		dc.l	0	;Screen buffers - physical
	;BPL_Log1_Ptr:		dc.l	0	;Logical1
	;CL_Phys_Ptr:		dc.l	0	;Copper ptr - physical
	;CL_Log1_Ptr:		dc.l	0	;Logical1	
	lea	CTRL_BPL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1.l = physical
	
	;If single CL buffer then don't swap the ptrs and leave cop1lch alone
	ifgt P0_CL_NUM_BUFFERS-1
		;Double buffered CL, just swap pointer
		;lea	CTRL_CL_PHYS_PTR(a5),a0
		movem.l	(a0),d0-d1		;Swap CL ptrs
		move.l	d1,(a0)+
		move.l	d0,(a0)			;d1 is phys

		; and activate next frame - d1 is physical
		move.l 	d1,cop1lch(a6)		; Active NEXT frame
	else
		;d1.l = physical screen
		lea 	P0_CL_Bpl+2,a0		;Adr of phys copper pointers PTH
		move.l	#BPL_BUF_MOD_BPL,d0	;next bpl 

		REPT	BPL_BUF_NUMPLANES
		swap	d1			;Swap high & low words
		move.w	d1,(a0)			;High ptr
		swap	d1			;Swap high & low words
		move.w	d1,4(a0)		;Low ptr
		addq.l	#8,a0			;Next set of ptrs
		add.l	d0,d1			;Next bitplane (interleaved)
		ENDR

	endif

	rts


*****************************************************************************
* Clears the entire work buffer screen. Every frame.
* Clears with the blitter and CPU.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Clear_WorkBuffer_BlitterCPU_A6:

; Tune this so that the very first WAITBLIT call AFTER this
; routine should take no time at all.
	move.l  CTRL_BPL_LOG1_PTR(a5),a0	;memory to clear
	move.w	#BPL_BUF_TOTALSIZE/2,d0		;size in words
	move.w	#35250,d1
	jmp	FW_ClearBuffer_BlitCPU_A6	;I:a6, T:d0-d7/a0-a4
	;rts


*****************************************************************************
* Clears the entire work buffer screen. Every frame.
* Clears with the blitter only.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a5
*****************************************************************************

Clear_WorkBuffer_Blitter_A6:

	move.l  CTRL_BPL_LOG1_PTR(a5),a0	;memory to clear
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((BPL_BUF_HEIGHT*BPL_BUF_NUMPLANES)*64)+BPL_BUF_WORDWIDTH,bltsize(a6)
	; Max height = 1024, max wordwidth = 64

	rts


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

	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6
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
	bne.s	.uservalwait
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


*****************************************************************************
* Performs any time-based controller routines.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a2-a4
*****************************************************************************

Controller_Perform:
	;Note that routines are called in reverse order to avoid lots of jumping around
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
	lea	PAL_PaletteStart(pc),a0
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
* Some example BOBs
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0/a0-a1
*****************************************************************************

BOBTest:
	movem.l	d2-d7/a2-a4,-(sp)

	;BOB
	;Bob is in kingcon interleaved and mask format where mask is interleaved with bob
	;COPY
	lea 	PRO_BOB_Draw_Copy_Vars,a0
	move.l	#$ffff0000,PRO_BOB_BLTFWM(a0)
	move.w	#BPL_BUF_MOD_LINE,PRO_BOB_MOD_LINE(a0)
	move.w	#BOB_BYTEWIDTH-2,PRO_BOB_BLTAMOD(a0)	;Skip the mask and we are blitting an extra word that doesn't exist (-2)
	move.w	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),PRO_BOB_BLTDMOD(a0)
	move.w	#((BOB_HEIGHT*BOB_NUMPLANES)*64)+BOB_WORDWIDTH+1,PRO_BOB_BLTSIZE(a0)	;bltsize

	lea	BOB_BPL,a1
	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	move.w	#100,d0
	move.w	#100,d1
	jsr	PRO_BOB_Draw_Copy		;I:d0-d1/a0/a1/a6, T:d0-d1/a1

	;OR
	lea 	PRO_BOB_Draw_OR_Vars,a0
	move.l	#$ffff0000,PRO_BOB_BLTFWM(a0)
	move.w	#BPL_BUF_MOD_LINE,PRO_BOB_MOD_LINE(a0)
	move.w	#BOB_BYTEWIDTH-2,PRO_BOB_BLTAMOD(a0)	;Skip the mask and we are blitting an extra word that doesn't exist (-2)
	move.w	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),PRO_BOB_BLTBMOD(a0)
	move.w	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),PRO_BOB_BLTDMOD(a0)
	move.w	#((BOB_HEIGHT*BOB_NUMPLANES)*64)+BOB_WORDWIDTH+1,PRO_BOB_BLTSIZE(a0)	;bltsize

	lea	BOB_BPL,a1
	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	move.w	#108,d0
	move.w	#108,d1
	jsr	PRO_BOB_Draw_OR			;I:d0-d1/a0/a1/a6, T:d0-d1/a1

	;Cookie
	lea 	PRO_BOB_Draw_Cookie_Vars,a0
	move.l	#$ffff0000,PRO_BOB_BLTFWM(a0)
	move.w	#BPL_BUF_MOD_LINE,PRO_BOB_MOD_LINE(a0)
	move.w	#BOB_BYTEWIDTH-2,PRO_BOB_BLTAMOD(a0)	;Skip the mask and we are blitting an extra word that doesn't exist (-2)
	move.w	#BOB_BYTEWIDTH-2,PRO_BOB_BLTBMOD(a0)	;Skip the mask and we are blitting an extra word that doesn't exist (-2)
	move.w	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),PRO_BOB_BLTCMOD(a0)
	move.w	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),PRO_BOB_BLTDMOD(a0)
	move.w	#((BOB_HEIGHT*BOB_NUMPLANES)*64)+BOB_WORDWIDTH+1,PRO_BOB_BLTSIZE(a0)	;bltsize

	lea	BOB_BPL,a1
	lea	2(a1),a2				;mask is next word
	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	move.w	#116,d0
	move.w	#116,d1
	jsr	PRO_BOB_Draw_Cookie			;I:d0-d1/a0/a1/a6, T:d0-d1/a1

	movem.l	(sp)+,d2-d7/a2-a4
	rts


*****************************************************************************
* Some example Dots
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0/a0-a1
*****************************************************************************

DotTest:
	movem.l	d2-d7/a2-a4,-(sp)

	;Dots
	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	moveq	#0,d0
	moveq	#64,d1
	move.w	#1,d2
	move.w	#BPL_BUF_MOD_LINE,d3
	move.w	#BPL_BUF_MOD_BPL,d4
	jsr	PRO_Dot_Plot_3BPL

	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	moveq	#2,d0
	moveq	#64,d1
	move.w	#BPL_BUF_MOD_LINE,d2
	jsr	PRO_Dot_Plot_1BPL

	movem.l	(sp)+,d2-d7/a2-a4
	rts


*****************************************************************************
* Some example Noise
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0/a0-a1
*****************************************************************************

NoiseTest:
	movem.l	d2-d7/a2-a4,-(sp)

	; Spam random noise
	move.l	CTRL_BPL_LOG1_PTR(a5),a0
	move.w	#BPL_BUF_TOTALSIZE/8,d0
	movem.l  .noiseseed(pc),d1/d2
	jsr	LIB_GenNoise_W		;I:d0.w, O:d1/d2.l, T:d0-d2/a0
	movem.l	d1/d2,.noiseseed

	movem.l	(sp)+,d2-d7/a2-a4
	rts

.noiseseed:
	dc.l	$3E50B28C,$D461A7F9


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
	printt	"TEMPLATE:"
	printt	"CHIPMEM:"
	printv	P0_CL_SIZE+BPL_BUF_TOTALSIZE+BPL_BUF_TOTALSIZE

	;printt	"FASTMEM:"
	;printv	CUR_PUB_BUF
	endif

*****************************************************************************
