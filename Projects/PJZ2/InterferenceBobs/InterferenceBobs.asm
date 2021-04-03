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

P0_DDF_H		equ	$81+16+16		;Hardware Hstart ($81 normal, $71 overscan)
P0_DDF_WIDTH		equ	256		;Pixels		 (320 normal pal, 352 overscan)
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
BPL_BUF_WIDTH		equ	256
BPL_BUF_BYTEWIDTH	equ	BPL_BUF_WIDTH/8
BPL_BUF_WORDWIDTH	equ	BPL_BUF_BYTEWIDTH/2
BPL_BUF_HEIGHT		equ	256
BPL_BUF_NUMPLANES	equ	1
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
BPL_WIDTH		equ	BPL_BUF_WIDTH
BPL_HEIGHT		equ	BPL_BUF_HEIGHT

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

;We use 16 colours for bobs and upper 16 for all the sprites
PAL_NUMCOLS_MAIN	equ	32;BPL_BUF_NUMCOLS	; number of main colour entries in our palettes
PAL_NUMCOLS_ALT		equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_ALT)

*****************************************************************************

BOB_NUMBOBS_MAX		equ	32
BOBS_COMPLETE_LOOP	equ	(BOB_SINE_NUMENTRIES*2)/BOB_NUMBOBS_MAX

BOB_SINE_NUMENTRIES	equ	LIB_GENSIN_16384_2048W_NUMWORDS	; Must be power of 2
BOB_SINE_OFFSET_MASK	equ	((LIB_GENSIN_16384_2048W_NUMWORDS*2)-2)	; Byte offset access into the table, forced to be even 

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

	xdef	IBOB_Start
IBOB_Start:
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
	xdef	IBOB_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
IBOB_PreCalc_IntroStart:
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
	xdef	IBOB_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
IBOB_P0_PreCalc:
	movem.l	d2-d7/a2-a6,-(sp)	;save (not d0)
	lea	Controller_Info(pc),a5
	tst.w	CTRL_P0_PRECALC_DONE(a5)
	bne.s	.exit			;already done

	;Change color to show where this starts
	;move.w	#$fff,color00+_custom
	
	;Generate sin table
	bsr	GenSin_Generate_Sine

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

	ifgt P0_CL_NUM_BUFFERS-1
CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE	
		move.l	#P0_CL_SIZE,d0
		jsr	FW_Mem_Alloc_Chip
		move.l	d0,CTRL_CL_PHYS_PTR(a5)

		lea	P0_CL_Phys(pc),a0
		move.l	d0,a1
		move.w	#(P0_CL_SIZE/2),d0	;size in words
		jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE
		move.l	#P0_CL_SIZE,d0
		jsr	FW_Mem_Alloc_Chip
		move.l	d0,CTRL_CL_LOG1_PTR(a5)
	else
CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE
		move.l	#P0_CL_SIZE,d0
		jsr	FW_Mem_Alloc_Chip
		move.l	d0,CTRL_CL_PHYS_PTR(a5)
		move.l	d0,CTRL_CL_LOG1_PTR(a5)

		lea	P0_CL_Phys,a0
		move.l	d0,a1
		move.w	#(P0_CL_SIZE/2),d0	;size in words
		jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2
	endif	;P0_CL_NUM_BUFFERS>1


	;Bobs
CUR_CHIP_BUF set CUR_CHIP_BUF+(BOB_TOTALSIZE*3)
	move.l	#BOB_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BOB1_BPL(a5)
	lea	BOB_BPL_Source1(pc),a0		;src
	move.l	d0,a1				;destination
	move.w	#BOB_TOTALSIZE/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2	

	move.l	#BOB_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BOB2_BPL(a5)
	lea	BOB_BPL_Source2(pc),a0		;src
	move.l	d0,a1				;destination
	move.w	#BOB_TOTALSIZE/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2	

	move.l	#BOB_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BOB3_BPL(a5)
	lea	BOB_BPL_Source3(pc),a0		;src
	move.l	d0,a1				;destination
	move.w	#BOB_TOTALSIZE/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2	

	;Alloc sprite in chip mem and copy
CUR_CHIP_BUF set CUR_CHIP_BUF+SPR_SIZEOF	
	move.l	#SPR_SIZEOF,d0			;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_SPRITE1_PTR(a5)		;save allocated address
	lea	SPR_Optic_Source(pc),a0		;src
	move.l	d0,a1				;destination
	move.w	#SPR_SIZEOF/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

CUR_CHIP_BUF set CUR_CHIP_BUF+SPR_SIZEOF	
	move.l	#SPR_SIZEOF,d0			;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_SPRITE2_PTR(a5)	;save allocated address
	lea	SPR_Tecon_Source(pc),a0	;src
	move.l	d0,a1				;destination
	move.w	#SPR_SIZEOF/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

CUR_CHIP_BUF set CUR_CHIP_BUF+SPR_SIZEOF	
	move.l	#SPR_SIZEOF,d0			;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_SPRITE3_PTR(a5)	;save allocated address
	lea	SPR_Antiriad_Source(pc),a0	;src
	move.l	d0,a1				;destination
	move.w	#SPR_SIZEOF/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2


	;Bitplanes
CUR_CHIP_BUF set CUR_CHIP_BUF+(BPL_BUF_TOTALSIZE*5)	
	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_PHYS_PTR(a5)

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_LOG1_PTR(a5)

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_LOG2_PTR(a5)

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_LOG3_PTR(a5)

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_LOG4_PTR(a5)

	;Sine table
CUR_PUB_BUF set CUR_PUB_BUF+LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4)
	move.l	#LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4),d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_SINETAB_PTR(a5)


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

	clr.w	CTRL_BOB_CURRENT(a5)
	clr.w	CTRL_SPRITE_CURRENT(a5)

	; Clear all screen buffers (previous routine must have blanked screen/colors)
	bsr	Clear_ScreenBuffers_CPU

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
	bsr	Clear_WorkBuffer_BlitterCPU_A6
	;bsr	Clear_WorkBuffer_Blitter_A6

	addq.w	#1,CTRL_FRAME_COUNT(a5)	;Update local frame count
	jsr	FW_VBlankProxy		;T:d0-d7/a0-a4


	bsr	BOB_Update_BOBs
	WAITBLIT_NASTY_A6		;For checking clrscreen timing
	bsr	BOB_Draw_BOBs

	; Read new script lines and perform during fill
	bsr	Controller_ReadCommands	;Read new commands
	bsr	Controller_Perform	;Do any ongoing time-based effects and update angles

	;Load current palette into CL if needed
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2
	
	;Update sprite
	bsr	Sprite_Draw_Credits

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

	move.l	CTRL_CL_PHYS_PTR(a5),a0	
	lea	P0_CL_SPRITES_OFFSET(a0),a0
	moveq	#8,d0			;8 sprites
	jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1

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
	
	;ScreenSwap routine will setup bpl ptrs

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
;CTRL_BPL_PHYS_PTR:		rs.l	1	;visible bpl2
;CTRL_BPL_LOG1_PTR:		rs.l	1	;visible bpl1
;CTRL_BPL_LOG2_PTR:		rs.l	1	;Logical2
;CTRL_BPL_LOG3_PTR:		rs.l	1	;Logical3 (clear and draw)
;CTRL_CL_PHYS_PTR:		rs.l	1	;Copper ptr - physical
;CTRL_CL_LOG1_PTR:		rs.l	1	;Logical1

	;5 buffers to swap
	lea	CTRL_BPL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d4
	exg	d0,d1		;phys
	exg	d1,d2		;log1
	exg	d2,d3		;log2
	exg	d3,d4		;log3
	movem.l	d0-d4,(a0)

	;If single CL buffer then don't swap the ptrs and leave cop1lch alone
	ifgt P0_CL_NUM_BUFFERS-1
		;Double buffered CL, just swap pointer
		lea	CTRL_CL_PHYS_PTR(a5),a0
		movem.l	(a0),d0-d1		;Swap CL ptrs
		move.l	d1,(a0)+
		move.l	d0,(a0)			;d1 is phys
		;move.l 	d1,cop1lch(a6)		;Active NEXT frame

	endif

	;Populate CL ptrs
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	move.l 	a0,cop1lch(a6)		;Active NEXT frame
	lea 	P0_CL_BPL_OFFSET+2(a0),a0	;Adr of phys copper pointers PTH

	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;Next bpl ptr
	move.w	d1,4(a0)			;Low ptr
	swap	d1			;Swap high & low words
	move.w	d1,(a0)			;High ptr
	addq.l	#8,a0			;Next set of ptrs

	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;Next bpl ptr
	add.l	#BPL_BUF_SIZE-BPL_BUF_BYTEWIDTH,d1	;Select last line (mirrored effect)
	move.w	d1,4(a0)			;Low ptr
	swap	d1			;Swap high & low words
	move.w	d1,(a0)			;High ptr
	addq.l	#8,a0			;Next set of ptrs

	move.l	CTRL_BPL_LOG3_PTR(a5),d1	;Next bpl ptr
	move.w	d1,4(a0)			;Low ptr
	swap	d1			;Swap high & low words
	move.w	d1,(a0)			;High ptr
	addq.l	#8,a0			;Next set of ptrs

	move.l	CTRL_BPL_LOG3_PTR(a5),d1	;Next bpl ptr
	add.l	#BPL_BUF_SIZE-BPL_BUF_BYTEWIDTH,d1	;Select last line (mirrored effect)
	move.w	d1,4(a0)			;Low ptr
	swap	d1			;Swap high & low words
	move.w	d1,(a0)			;High ptr
	addq.l	#8,a0			;Next set of ptrs


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
	move.l  CTRL_BPL_LOG4_PTR(a5),a0	;memory to clear
	move.w	#BPL_BUF_TOTALSIZE/2,d0		;size in words
	move.w	#49000,d1
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

	ifne	0
Clear_WorkBuffer_Blitter_A6:

	move.l  CTRL_BPL_LOG4_PTR(a5),a0	;memory to clear
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((BPL_BUF_HEIGHT*BPL_BUF_NUMPLANES)*64)+BPL_BUF_WORDWIDTH,bltsize(a6)
	; Max height = 1024, max wordwidth = 64

	rts

	endif


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

	move.l	CTRL_BPL_LOG2_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	move.l	CTRL_BPL_LOG3_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	move.l	CTRL_BPL_LOG4_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6
	rts


*****************************************************************************
* Generate sine values 2048 between -16383 and 16383. Generates an extra 
* 256 words so can use for sine and cosine.
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

;Note need to be a little careful when shifting right to change range as -16383 >> 1 = -8192
;so ranges change as follows when shifting right
;-8192 to 8191 etc
;-4096 to 4095
;If rounding with addx means this becomes:
;-8191 to 8192

GenSin_Generate_Sine:
	movem.l	d2-d3,-(sp)

	;move.l	CTRL_SINETAB_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

	;change range from -16383 to 16383 to something usable.
	;For these 64px bobs in dual sine we need 0-91 range or -45 to 45. Div by 360 then add 45
.changerange:
	lea	GenSin_Table_16384_2048W,a0
	move.l	CTRL_SINETAB_PTR(a5),a1
	;move.w	#32,d0			;change from -64 to 63
	;add.w	#16,d0			;centering

	move.w	#(LIB_GENSIN_16384_2048W_NUMWORDS+(LIB_GENSIN_16384_2048W_NUMWORDS/4))-1,d1
	moveq	#0,d2
.cl:
	move.w	(a0)+,d3	
	ext.l	d3
	;divs	#BPL_WIDTH-BOB_WIDTH,d3	;Get in range for screen size and bob size
	divs	#32767/(BPL_WIDTH-BOB_WIDTH),d3
	;add.w	#90,d3

	;asr.w	#8,d3			;change range to -64 to 63
	;asr.w	#1,d3			;-32 to 31
	;addx.w	d2,d3			;round up (no: will change range to -127 to 128)
	;add.w	d0,d3			;0-63
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
	cmp.w	#100,d0			;25 frame limit
	blt.s	.exit
	move.w	d1,CTRL_MUSICSYNC_LASTFRAME(a5)

	; DO TRIGGER OPERATION HERE
	;Set color fade to max 
	move.w	#15*2,CTRL_MUSIC_FADE_STEP(a5)	;Max is 15 scaled by 2

	lea	CTRL_SINE_X1(a5),a0
	neg.w	CTRL_SINE_SPEED(a0)
	lea	CTRL_SINE_SIZEOF(a0),a0
	neg.w	CTRL_SINE_SPEED(a0)
;	lea	CTRL_SINE_SIZEOF(a0),a0
;	neg.w	CTRL_SINE_SPEED(a0)
;	lea	CTRL_SINE_SIZEOF(a0),a0
;	neg.w	CTRL_SINE_SPEED(a0)
	rts

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

	lea	CTRL_SINE_X1(a5),a0
	bsr.s	.checksine
	lea	CTRL_SINE_Y1(a5),a0
	bsr.s	.checksine
	lea	CTRL_SINE_X2(a5),a0
	bsr.s	.checksine
	lea	CTRL_SINE_Y2(a5),a0
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
	move.w	CTRL_MUSIC_FADE_STEP(a5),d6
	bne	.fade

;Just copy the colours
	lea	PAL_Current(pc),a0
.copy:
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_COL_OFFSET+2(a1),a1	

	rept	PAL_NUMCOLS_MAIN
	move.w	(a0)+,(a1)
	addq.l	#4,a1			;next color
	endr

	rts

.fade:
	subq.w	#1,d6
	move.w	d6,CTRL_MUSIC_FADE_STEP(a5)
	lsr.w	#1,d6				;Scale down by 2

	;Colour 2 can always be lightened in time with music
	lea	PAL_Current(pc),a1
	move.l	CTRL_CL_LOG1_PTR(a5),a2
	lea	P0_CL_COL_OFFSET+6(a2),a2	;Color01

	moveq	#((PAL_NUMCOLS_MAIN/2)-1)-1,d7	;Skip color 0
.loop:
	move.w	(a1)+,d0
	move.w	#$fff,d1			;Dest col
	move.w	d6,d2				;restore step
	jsr	LIB_RGB12_Interpolate_Fast	;trashes d0-d4/a0
	move.w	d0,(a2)				;Col2 in CL
	addq.l	#4,a2				;next color

	dbf	d7,.loop
	rts



*****************************************************************************
* Creates the bob draw list. CPU routine to be used during blit/screen clear
* IN:		
* OUT:		
* TRASHED:	d1/d3-d7/a0-a1
*****************************************************************************

BOB_Update_BOBs:
	move.l	a5,-(sp)
	move.l	a6,-(sp)

	;Get sine speed and steps
	move.w	#BOB_SINE_OFFSET_MASK,d5	;Used to keep the offset in range

	; Sine X1
	move.w	CTRL_SINE_X1+CTRL_SINE_OFFSET(a5),d1	;Offset in words
	add.w	CTRL_SINE_X1+CTRL_SINE_SPEED(a5),d1	;add speed (movement per frame)
	and.w	d5,d1					;Ensure in range
	move.w	d1,CTRL_SINE_X1+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_SINE_X1+CTRL_SINE_FREQ(a5),a1	;Get step (movement per pixel)

	; Sine X2
	move.w	CTRL_SINE_X2+CTRL_SINE_OFFSET(a5),d2	;Offset in words
	add.w	CTRL_SINE_X2+CTRL_SINE_SPEED(a5),d2	;Get speed (movement per frame)
	and.w	d5,d2					;Ensure in range
	move.w	d2,CTRL_SINE_X2+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_SINE_X2+CTRL_SINE_FREQ(a5),a2	;Get step (movement per pixel)

	; Sine Y1
	move.w	CTRL_SINE_Y1+CTRL_SINE_OFFSET(a5),d3	;Offset in words
	add.w	CTRL_SINE_Y1+CTRL_SINE_SPEED(a5),d3	;add speed (movement per frame)
	and.w	d5,d3					;Ensure in range
	move.w	d3,CTRL_SINE_Y1+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_SINE_Y1+CTRL_SINE_FREQ(a5),a3	;Get step (movement per pixel)

	; Sine Y2
	move.w	CTRL_SINE_Y2+CTRL_SINE_OFFSET(a5),d4	;Offset in words
	add.w	CTRL_SINE_Y2+CTRL_SINE_SPEED(a5),d4	;Get speed (movement per frame)
	and.w	d5,d4					;Ensure in range
	move.w	d4,CTRL_SINE_Y2+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_SINE_Y2+CTRL_SINE_FREQ(a5),a4	;Get step (movement per pixel)

	move.w	CTRL_NUMBOBS(a5),d7
	subq.w	#1,d7

	move.l	CTRL_SINETAB_PTR(a5),a5
	lea	BOBSnake_DrawList,a0

	;rept BOB_NUMBOBS
.loopx:
	move.w 	(a5,d1.w),d0		;sine 1
	add.w	(a5,d2.w),d0		;add sine 2
	asr.w	#1,d0			;back into range
	add.w	#(BPL_WIDTH/2)-(BOB_WIDTH/2),d0	;convert to screen coords

	move.w	d0,(a0)+		;save X
	add.w	a1,d1			;Increase offsets and mask to 0-2047 (1024 sine entries, in words)
	add.w	a2,d2
	and.w	d5,d1
	and.w	d5,d2

	move.w 	(a5,d3.w),d0		;sine 1
	add.w	(a5,d4.w),d0		;add sine 2
	asr.w	#1,d0			;back into range
	add.w	#(BPL_HEIGHT/2)-(BOB_HEIGHT/2),d0	;convert to screen coords
	asl.w	#5,d0			;Y is 32 bytes per line

	move.w	d0,(a0)+		;save Y
	add.w	a3,d3			;Increase offsets and mask to 0-2047 (1024 sine entries, in words)
	add.w	a4,d4
	and.w	d5,d3
	and.w	d5,d4

	dbf	d7,.loopx
	;endr

	move.l	(sp)+,a6
	move.l	(sp)+,a5

	rts



*****************************************************************************
* Draws the previously plotted BOBs.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

BOB_Draw_BOBs:
	move.l	a5,-(sp)
	move.l	a6,-(sp)

	lea	dmaconr(a6),a6

	lea	BOBSnake_DrawList,a2	; x 
	move.w	CTRL_NUMBOBS(a5),d7
	subq.w	#1,d7


	move.l	CTRL_BPL_LOG4_PTR(a5),a4	;save
	lea	CTRL_BOB1_BPL(a5),a1		;First bob ptr 
	add.w	CTRL_BOB_CURRENT(a5),a1		;0,4,8
	move.l	(a1),a1				;Relevant bob BPL

	;A and B OR NotA and C
	move.w	#BLT_SRC_ABD+(BLT_A^BLT_B),d3	;a xor b
	move.w	#((BOB_HEIGHT*BOB_NUMPLANES)*64)+BOB_WORDWIDTH+1,d4	;bltsize
	moveq	#6,d5				;for blitwait btst
	move.w	#$8400,a5			;blitnasty on
	move.w	#$0400,d6			;blitnasty off

	; Our BOB is 16 pixels wide, but we need to shift right by 16
	; to position it. So blit it an extra word wide and mask off the result.
	; Need to have -2 in modulos to accomodate this.
	moveq	#-2,d0			;We are blitting an extra word that doesn't exist (-2)
	moveq	#BPL_BUF_BYTEWIDTH-(BOB_BYTEWIDTH+2),d1

	;WAITBLIT_NASTY_A6
	move.w	a5,dmacon-dmaconr(a6)	;Blitter nasty on
.bw:	btst.b	d5,(a6)			;blitwait
	bne.s	.bw
	move.w	d6,dmacon-dmaconr(a6)	;Blitter nasty off

	move.l	#$ffff0000,bltafwm-dmaconr(a6)	;mask last word as it's not there
	move.w	d0,bltamod-dmaconr(a6)	
	move.w	d1,bltbmod-dmaconr(a6)
	move.w	d1,bltdmod-dmaconr(a6)	

.loop
	movem.w	(a2)+,d0-d1		;also clears top of d0 and d1 (important)

	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen (x / 8)
	add.w	d0,d1			;add byte offset to y offset (WARNING: possible 64k overflow)
	swap	d0			;d0.w now contains shift value in top nibble
	;move.w	d0,d2			;save B shift
	or.w	d3,d0			;add minterm
	swap	d0			;d0.l=bltcon0 in high word
	;move.w	d2,d0			;d0.l=bltcon0 and bltcon1
	clr.w	d0
					;d1.w=byte offset into screen
	add.l	a4,d1			;Add screen ptr to offset
	move.l	d1,a3			;For optimizing movem

	;WAITBLIT_NASTY_A6
	move.w	a5,dmacon-dmaconr(a6)	;Blitter nasty on
.bw2:	btst.b	d5,(a6)			;blitwait
	bne.s	.bw2
	move.w	d6,dmacon-dmaconr(a6)	;Blitter nasty off

	move.l	d0,bltcon0-dmaconr(a6)	;bltcon0/1
	;move.l	d1,bltbpth-dmaconr(a6)	;BLTBPTH ($4c)
	;move.l	a1,bltapth-dmaconr(a6)	;BLTAPTH ($50)
	;move.l	a3,bltdpth-dmaconr(a6)	;BLTDPTH ($54)
	movem.l	d1/a1/a3,bltbpth-dmaconr(a6)
	
	move.w	d4,bltsize-dmaconr(a6)	;BLTSIZE ($58)

	dbf	d7,.loop


	move.l	(sp)+,a6
	move.l	(sp)+,a5


	;FILL
	move.l	CTRL_BPL_LOG4_PTR(a5),a0
	lea	BPL_BUF_SIZE-2(a0),a0

	WAITBLIT_NASTY_A6
	move.l	#((BLT_SRC_AD+(BLT_A))<<16)|(BLT_FILL_OR|BLT_BLITREVERSE),bltcon0(a6)
	move.l	#-1,bltafwm(a6)
	move.w	#0,bltamod(a6)
	move.w	#0,bltdmod(a6)
	move.l	a0,bltapth(a6)
	move.l	a0,bltdpth(a6)
	move.w	#((BPL_BUF_HEIGHT*BPL_BUF_NUMPLANES)*64)+BPL_BUF_WORDWIDTH,bltsize(a6)
	

	rts

*****************************************************************************
* Draws the light sprite.
* IN:		
*
*	dc.w	spr2pth,$PTR_TO_THIS_WORD
*	dc.w	spr2ptl,$0
*
* OUT:		a1=sprptr in cl
* TRASHED:	d0-d5/a2-a3
*****************************************************************************

Sprite_Draw_Credits:
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_SPRITES_OFFSET+2(a0),a0	;copper spr pointer block, skip to pth word

	move.l	CTRL_SINETAB_PTR(a5),a1

	move.w	#BOB_SINE_OFFSET_MASK,d5	;Used to keep the offset in range

	; Sine X
	move.w	CTRL_SINE_X3+CTRL_SINE_OFFSET(a5),d2	;Offset in words
	add.w	CTRL_SINE_X3+CTRL_SINE_SPEED(a5),d2	;add speed (movement per frame)
	and.w	d5,d2					;Ensure in range
	move.w	d2,CTRL_SINE_X3+CTRL_SINE_OFFSET(a5)	;Save for next frame

	move.w	CTRL_SINE_X4+CTRL_SINE_OFFSET(a5),d3	;Offset in words
	add.w	CTRL_SINE_X4+CTRL_SINE_SPEED(a5),d3	;Get speed (movement per frame)
	and.w	d5,d3					;Ensure in range
	move.w	d3,CTRL_SINE_X4+CTRL_SINE_OFFSET(a5)	;Save for next frame

	move.w 	(a1,d2.w),d0		;sine 1
	add.w	(a1,d3.w),d0		;add sine 2
	asr.w	#4,d0
	;add.w	#(BPL_WIDTH/2)-(SPR_WIDTH/2)+P0_DIW_H+32,d0	
	add.w	#P0_DIW_H+(BPL_WIDTH-64),d0

	; Sine Y
	move.w	CTRL_SINE_Y3+CTRL_SINE_OFFSET(a5),d2	;Offset in words
	add.w	CTRL_SINE_Y3+CTRL_SINE_SPEED(a5),d2	;add speed (movement per frame)
	and.w	d5,d2					;Ensure in range
	move.w	d2,CTRL_SINE_Y3+CTRL_SINE_OFFSET(a5)	;Save for next frame

	move.w	CTRL_SINE_Y4+CTRL_SINE_OFFSET(a5),d3	;Offset in words
	add.w	CTRL_SINE_Y4+CTRL_SINE_SPEED(a5),d3	;Get speed (movement per frame)
	and.w	d5,d3					;Ensure in range
	move.w	d3,CTRL_SINE_Y4+CTRL_SINE_OFFSET(a5)	;Save for next frame

	move.w 	(a1,d2.w),d1		;sine 1
	add.w	(a1,d3.w),d1		;add sine 2
	asr.w	#4,d1
	;add.w	#(BPL_HEIGHT/2)-(SPR_HEIGHT/2)+P0_DIW_V,d1
	add.w	#P0_DIW_V+(BPL_HEIGHT-90),d1

	moveq	#SPR_HEIGHT,d2		;height
	GET_SPRITE_CTRL_WORDS		;I:d0-d2, O:d1-d2, T:d0-d3
	move.w	d1,d3			;Save control words
	move.w	d2,d4

	;Sprite data is in kingcon format. We are using 128px wide sprites so the format is:
	;dc.w	offset-spr0-frame0,offset-spr1-frame0,
	;The add the offset and that will now be the correct sprite control words and data for that frame

	lea	CTRL_SPRITE1_PTR(a5),a1		;First bob ptr 
	add.w	CTRL_SPRITE_CURRENT(a5),a1	;0,4,8
	move.l	(a1),a1				;Relevant bob BPL

	move.l	a1,a2
	moveq	#8-1,d7			;all 8 sprites needed
.updatepth:
	move.w	(a2)+,d2		;sprx offset
	lea	(a1,d2.w),a3		;Address of sprites control words

	;Update sprite ptrs
	move.l	a3,d2
	move.w	d2,4(a0)		;spr0 ptl
	swap	d2
	move.w	d2,(a0)			;pth
	addq.l	#8,a0			;next set of ptrs

	;a0=spr0pth in cl, a2=sprx control words
	;d0/d1, x/y
	move.w	d3,(a3)+		;update sprx control words
	move.w	d4,(a3)
	addq.w	#8,d3			;Update x pos ctrl word for 16 pixels to right

	dbf	d7,.updatepth

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
