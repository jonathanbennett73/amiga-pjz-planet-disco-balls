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

P0_SCANLINE_EOF		equ	P0_DIW_V+P0_DIW_HEIGHT	; Safe to starting clearing after this scanline
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

BACKGROUNDPIC_HEIGHT	equ	158
BACKGROUNDPIC_TOTALSIZE	equ	BACKGROUNDPIC_HEIGHT*BPL_BUF_BYTEWIDTH*3

BPL_BPLMOD		equ	BPL_BUF_MOD_LINE-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPTLINE	equ	-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPTPREVLINE	equ	(-BPL_BUF_MOD_LINE)-P0_DDF_BYTEWIDTH
BPL_BPLMOD_REPT2LINE	equ	BPL_BPLMOD_REPTPREVLINE-BPL_BUF_MOD_LINE
BPL_BPLMOD_SKIPLINE	equ	BPL_BPLMOD+(BPL_BUF_MOD_LINE)

; ----

;BPL_BUF_xxx is the underlying buffer, might not match visible
BPL_OVR_BUF_WIDTH	equ	320
BPL_OVR_BUF_BYTEWIDTH	equ	BPL_OVR_BUF_WIDTH/8
BPL_OVR_BUF_WORDWIDTH	equ	BPL_OVR_BUF_BYTEWIDTH/2
BPL_OVR_BUF_HEIGHT	equ	256
BPL_OVR_BUF_NUMPLANES	equ	2
BPL_OVR_BUF_NUMCOLS 	equ	(1<<BPL_OVR_BUF_NUMPLANES)
BPL_OVR_BUF_SIZE	equ	BPL_OVR_BUF_BYTEWIDTH*BPL_OVR_BUF_HEIGHT
BPL_OVR_BUF_TOTALSIZE	equ	BPL_OVR_BUF_SIZE*BPL_OVR_BUF_NUMPLANES
BPL_OVR_BUF_INTERLEAVED	equ	1

	ifne BPL_OVR_BUF_INTERLEAVED
BPL_OVR_BUF_MOD_LINE	equ	BPL_OVR_BUF_BYTEWIDTH*BPL_OVR_BUF_NUMPLANES
BPL_OVR_BUF_MOD_BPL	equ	BPL_OVR_BUF_BYTEWIDTH
	else
BPL_OVR_BUF_MOD_LINE	equ	BPL_OVR_BUF_BYTEWIDTH
BPL_OVR_BUF_MOD_BPL	equ	BPL_OVR_BUF_SIZE
	endif

;BPL_xxx is the visible size, might not always match buffer
BPL_OVR_WIDTH		equ	P0_DIW_WIDTH
BPL_OVR_HEIGHT		equ	P0_DIW_HEIGHT

BPL_OVR_BPLMOD			equ	BPL_OVR_BUF_MOD_LINE-P0_DDF_BYTEWIDTH
BPL_OVR_BPLMOD_REPTLINE		equ	-P0_DDF_BYTEWIDTH
BPL_OVR_BPLMOD_REPTPREVLINE	equ	(-BPL_OVR_BUF_MOD_LINE)-P0_DDF_BYTEWIDTH
BPL_OVR_BPLMOD_REPT2LINE	equ	BPL_OVR_BPLMOD_REPTPREVLINE-BPL_OVR_BUF_MOD_LINE
BPL_OVR_BPLMOD_SKIPLINE		equ	BPL_OVR_BPLMOD+(BPL_OVR_BUF_MOD_LINE)


*****************************************************************************

PERFORM_ENABLE_MUSICSYNC	equ	0
PERFORM_ENABLE_SINESET		equ	0
PERFORM_ENABLE_USERVALWAIT	equ	0

*****************************************************************************

PAL_NUMCOLS_MAIN	equ	32	; number of main colour entries in our palettes
PAL_NUMCOLS_ALT		equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_ALT)

*****************************************************************************

;Local font changes
FONT8PX_MIN_X		equ 	8
FONT8PX_MAX_X		equ	(BPL_OVR_BUF_WIDTH-1)-16

TEXT_Y_MIN		equ	32	;Starting Y pos for text
TEXT_Y_SPACING		equ	FONT8PX_HEIGHT+1
TEXT_PRINTCHAR_DELAY	equ	1	;Time between chars

*****************************************************************************

BOB_SINE_NUMENTRIES = LIB_GENSIN_16384_2048W_NUMWORDS	; Must be power of 2
BOB_SINE_OFFSET_MASK = ((LIB_GENSIN_16384_2048W_NUMWORDS*2)-2)	; Byte offset access into the table, forced to be even 

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

	xdef	CRD_Start
CRD_Start:
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
	;default lev3 irq is common so that easy to transition.
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
	xdef	CRD_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
CRD_PreCalc_IntroStart:
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
	xdef	CRD_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
CRD_P0_PreCalc:
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

	; Alloc CL
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

	;Sprite lists
	lea	CTRL_SPR_LIST_PTRS_PHYS(a5),a2
	lea	CTRL_SPR_LIST_PTRS_LOG1(a5),a3
	movem.l	a2-a3,CTRL_SPR_LISTS_PHYS_PTR(a5)

	;Physical sprite lists
CUR_CHIP_BUF set CUR_CHIP_BUF+(SPR_LIST_SIZEOF*8)	
	moveq	#8-1,d2
.slist1:
	move.l	#SPR_LIST_SIZEOF,d0		;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,(a2)+
	dbf	d2,.slist1

	;Logical sprite lists
CUR_CHIP_BUF set CUR_CHIP_BUF+(SPR_LIST_SIZEOF*8)	
	moveq	#8-1,d2
.slist2:
	move.l	#SPR_LIST_SIZEOF,d0		;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,(a3)+
	dbf	d2,.slist2

	;Alloc memory for sprite A and copy - need this for blitting bpl data
CUR_CHIP_BUF set CUR_CHIP_BUF+SPR_DISCOBALL_SIZEOF	
	move.l	#SPR_DISCOBALL_SIZEOF,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_SPRITE_A_PTR(a5)	;save allocated address
	lea	SPR_DiscoBall_A,a0		;src
	move.l	d0,a1				;destination
	move.w	#SPR_DISCOBALL_SIZEOF/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2


	;Alloc font in chip mem and copy
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_FONT8PX_TOTALSIZE	
	move.l	#BPL_FONT8PX_TOTALSIZE,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_BPL_FONT(a5)		;save allocated address
	lea	BPL_Font8px_Source,a0		;src
	move.l	d0,a1				;destination
	move.w	#BPL_FONT8PX_TOTALSIZE/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2


	;Bitplanes alloc last

	; Background is a static image so just alloc one buffer
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_BUF_TOTALSIZE	
	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_PHYS_PTR(a5)
	move.l	d0,CTRL_BPL_LOG1_PTR(a5)		;Single buffer

	;Overlay is double buffered
CUR_CHIP_BUF set CUR_CHIP_BUF+(BPL_OVR_BUF_TOTALSIZE*2)	
	move.l	#BPL_OVR_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_OVR_PHYS_PTR(a5)
	move.l	#BPL_OVR_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_OVR_LOG1_PTR(a5)		;Single buffer

	;Allocs sine table for barpos
;BOB_Sin_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
;BOB_Cos_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS	
CUR_PUB_BUF set CUR_PUB_BUF+LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4)
	move.l	#LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4),d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_SINETAB_BOB_PTR(a5)


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

	move.w	#-1,CTRL_TEXT_STATUS(a5)
	move.w	#TEXT_Y_MIN,CTRL_TEXT_Y(a5)
	move.l	#Scroller_Text,CTRL_TEXT_PTR(a5)

	; Clear all screen buffers (previous routine must have blanked screen/colors)
	bsr	Clear_ScreenBuffers_CPU

	;Static background
	lea	BPL_Pic_Source(pc),a0	
	move.l	CTRL_BPL_PHYS_PTR(a5),a1
	lea	((64)*BPL_BUF_MOD_LINE)(a1),a1	;160 high, so center
	move.w	#(BACKGROUNDPIC_TOTALSIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2


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

	bsr	Text_Run_Routine

	; Read new script lines and perform
	bsr	Controller_ReadCommands	;Read new commands
	bsr	Controller_Perform	;Do any ongoing time-based effects and update angles

	;Load current palette into CL if needed
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2

	bsr	Sprites_Draw



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
	;lea	P0_CL_Scr_Sprites,a0
	;moveq	#8,d0			;8 sprites
	;jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1

	; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

	;--------------------------------
	;Front buffer copper BPL pointers
	;--------------------------------
	move.l	CTRL_CL_PHYS_PTR(a5),a1
	lea	P0_CL_BPL_OFFSET(a1),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;I:d0-d2/a0, T:d0-d1/a0

	move.l	CTRL_CL_PHYS_PTR(a5),a1
	lea	P0_CL_BPL_OVR_OFFSET(a1),a0		;copper bpl pointer block
	moveq	#BPL_OVR_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_OVR_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_OVR_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;I:d0-d2/a0, T:d0-d1/a0

	;Setup sprite lists
	lea	P0_CL_SPRITES_OFFSET+2(a1),a0	;pth
	move.l	CTRL_SPR_LISTS_PHYS_PTR(a5),a1	;8 list ptrs
	moveq	#8-1,d2
.loop1
	move.l	(a1)+,d0		;sprite list
	move.w	d0,4(a0)		;ptl
	swap	d0
	move.w	d0,(a0)			;pth
	addq.l	#8,a0	
	dbf	d2,.loop1


	;--------------------------------
	;Back buffer copper BPL pointers
	;--------------------------------
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_BPL_OFFSET(a1),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_LOG1_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;I:d0-d2/a0, T:d0-d1/a0

	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_BPL_OVR_OFFSET(a1),a0		;copper bpl pointer block
	moveq	#BPL_OVR_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_OVR_LOG1_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_OVR_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;I:d0-d2/a0, T:d0-d1/a0

	;Setup sprite lists
	lea	P0_CL_SPRITES_OFFSET+2(a1),a0	;pth
	move.l	CTRL_SPR_LISTS_LOG1_PTR(a5),a1	;8 list ptrs
	moveq	#8-1,d2
.loop2
	move.l	(a1)+,d0		;sprite list
	move.w	d0,4(a0)		;ptl
	swap	d0
	move.w	d0,(a0)			;pth
	addq.l	#8,a0	
	dbf	d2,.loop2

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
;CTRL_BPL_PHYS_PTR		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
;CTRL_BPL_LOG1_PTR		rs.l	1	;Logical1
;CTRL_BPL_OVR_PHYS_PTR		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
;CTRL_BPL_OVR_LOG1_PTR		rs.l	1	;Logical1
;CTRL_CL_PHYS_PTR		rs.l	1	;Copper ptr - physical
;CTRL_CL_LOG1_PTR		rs.l	1	;Logical1
;CTRL_SPR_LISTS_PHYS_PTR		rs.l	1
;CTRL_SPR_LISTS_LOG1_PTR		rs.l	1
	lea	CTRL_BPL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1.l = physical

	;lea	CTRL_BPL_OVR_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1 is phys

	;lea	CTRL_CL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap CL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1 is phys

	; and activate next frame - d1 is physical
	move.l 	d1,cop1lch(a6)		; Active NEXT frame

	movem.l	(a0),d0-d1		;Swap SPR_LISTS ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+		;d1 is phys

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

Clear_WorkBuffer_Blitter_A6:

	move.l  CTRL_BPL_OVR_LOG1_PTR(a5),a0	;memory to clear
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((BPL_OVR_BUF_HEIGHT*BPL_OVR_BUF_NUMPLANES)*64)+BPL_OVR_BUF_WORDWIDTH,bltsize(a6)
	; Max height = 1024, made wordwidth = 64

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

	;Same buffer
	;move.l	CTRL_BPL_LOG1_PTR(a5),a0
	;move.w	#(BPL_BUF_TOTALSIZE/2),d0
	;jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	move.l	CTRL_BPL_OVR_PHYS_PTR(a5),a0
	move.w	#(BPL_OVR_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	move.l	CTRL_BPL_OVR_LOG1_PTR(a5),a0
	move.w	#(BPL_OVR_BUF_TOTALSIZE/2),d0
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

	;move.l	CTRL_SINETAB_BOB_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

	;change range from -16383 to 16383 to something usable.
	;For these 64px bobs in dual sine we need 0-91 range or -45 to 45. Div by 360 then add 45
.changerange:
	lea	GenSin_Table_16384_2048W,a0
	move.l	CTRL_SINETAB_BOB_PTR(a5),a1

	move.w	#(LIB_GENSIN_16384_2048W_NUMWORDS+(LIB_GENSIN_16384_2048W_NUMWORDS/4))-1,d1
	moveq	#0,d2
.cl:
	move.w	(a0)+,d3	
	ext.l	d3
	divs	#32767/(BPL_WIDTH-SPR_DISCOBALL_HEIGHT),d3
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
* Draws all the 4 sprite lists.
* IN:	a5, Controller_Info	
*
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Sprites_Draw:
	lea	SPROBJ_List_0_PTRS(pc),a0
	bsr	Sprites_Update_Pos	

	;Common blit values for all sprite copies
	WAITBLIT_NASTY_A6
	move.l	#$09f00000,bltcon0(a6)
	move.l	#-1,bltafwm(a6)
	move.l	#0,bltamod(a6)		;a+d mod

	lea	SPROBJ_List_0_PTRS(pc),a0
	move.l	CTRL_SPR_LISTS_LOG1_PTR(a5),a1	;8 sprite list pointers
	bsr	Sprite_Draw_List
	;rts

	lea	SPROBJ_List_1_PTRS(pc),a0
	bsr	Sprites_Update_Pos
	lea	SPROBJ_List_1_PTRS(pc),a0
	move.l	CTRL_SPR_LISTS_LOG1_PTR(a5),a1	;8 sprite list pointers
	addq.w	#8,a1				;next pair of ptrs
	bsr	Sprite_Draw_List
	;rts

	lea	SPROBJ_List_2_PTRS(pc),a0
	bsr	Sprites_Update_Pos
	lea	SPROBJ_List_2_PTRS(pc),a0
	move.l	CTRL_SPR_LISTS_LOG1_PTR(a5),a1	;8 sprite list pointers
	lea	16(a1),a1			;next pair of ptrs
	bsr	Sprite_Draw_List
	;rts

	lea	SPROBJ_List_3_PTRS(pc),a0
	bsr	Sprites_Update_Pos
	lea	SPROBJ_List_3_PTRS(pc),a0
	move.l	CTRL_SPR_LISTS_LOG1_PTR(a5),a1	;8 sprite list pointers
	lea	24(a1),a1			;next pair of ptrs
	bsr	Sprite_Draw_List

	rts


*****************************************************************************
* Draws the light sprite.
* IN:	a5, Controller_Info		
*	a0, bob list ptr
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Sprites_Update_Pos:
	lea	((SPROBJ_LIST_MAX-1)*4)(a0),a1	;ptr to last ptr
	move.l	a1,-(sp)			;save
	clr.w	CTRL_SORT_LIST(a5)		;clear flag for sorting

	move.l	CTRL_SINETAB_BOB_PTR(a5),a3
	move.w	#BOB_SINE_OFFSET_MASK,d6	;Used to keep the offset in range
	move.w	#SPROBJ_LIST_MAX-1,d7
.loop:
	;Get coords and update anim frame
	move.l	(a0)+,a2		;get ptr to a SPROBJ struct
	movem.w	(a2),d0-d1		;x,y

	;Update Y
	;check if gone off bottom of screen, if it has then need to 
	;rearrange ptrs so that the last entry is at the top. 
	add.w	SPROBJ_Y_SPEED(a2),d1	;add falling
	cmp.w	#(P0_DIW_V+P0_DIW_HEIGHT)*SPR_POS_SCALE,d1
	blt.s	.yok
	sub.w	#(P0_DIW_HEIGHT+SPR_DISCOBALL_HEIGHT)*SPR_POS_SCALE,d1
	move.w	#1,CTRL_SORT_LIST(a5)
.yok:
	move.w	d1,SPROBJ_Y(a2)

	;update X
	movem.w	SPROBJ_OFFSET1(a2),d2-d5
	add.w	d3,d2
	and.w	d6,d2
	add.w	d5,d4
	and.w	d6,d4
	move.w	d2,SPROBJ_OFFSET1(a2)
	move.w	d4,SPROBJ_OFFSET2(a2)
	move.w 	(a3,d2.w),d0		;sine 1
	add.w	(a3,d4.w),d0		;add sine 2
	asr.w	#1,d0			;back into range

	move.w	d0,d1			;save
	asr.w	#4,d1
	move.w	d1,SPROBJ_FRAME_SPEED(a2)
	add.w	#((BPL_WIDTH/2)-(SPR_DISCOBALL_HEIGHT/2))+P0_DIW_H,d0	;convert to screen coords
	move.w	d0,SPROBJ_X(a2)
	
	dbf	d7,.loop

	
	;Rearrange list if required, as all falling only one ball will ever drop
	;of the end of the screen and need moving up
	move.l	(sp)+,a0		;restore ptr to last ptr

	tst.w	CTRL_SORT_LIST(a5)	;Needs sorting?
	beq.s	.exit

	move.l	(a0),a1			;Last entry
	moveq	#SPROBJ_LIST_MAX-1-1,d2
.reloop:
	move.l	-4(a0),(a0)
	subq.l	#4,a0
	dbf	d2,.reloop
	move.l	a1,(a0)

.exit:
	rts

;0 2
;1 0
;2 1
;3 2


*****************************************************************************
* Populates an entire sprite list.
*
* IN:	a1, spritelist ptr, will read two ptrs from here for 2 spite lists (0+1, 2+3, etc)	
*	a0, bob list ptr
*
* OUT:		
* TRASHED:	d0-d6/a0-a3
*****************************************************************************

* Word1 SPRxPOS
*	Bits 15-8 contain the low 8 bits of VSTART
*	Bits 7-0 contain the high 8 bits of HSTART
*
* Word2 SPRxCTL
*	Bits 15-8	The low eight bits of VSTOP
*	Bit 7		(Used in attachment)
*	Bits 6-3	Unused (make zero)
*	Bit 2		The VSTART high bit
*	Bit 1		The VSTOP high bit
*	Bit 0		The HSTART low bit

;Sprite pos list
;SPROBJ_X		rs.w	1	;Sprite x pos (screen coords)
;SPROBJ_Y		rs.w	1	;y pos
;SPROBJ_FRAME_SPEED	rs.w	1	;Animation speed (<<1)
;SPROBJ_FRAME		rs.w	1	;Sprite frame 0-3

Sprite_Draw_List:
	move.l	(a1)+,a2		;spr0 list
	move.l	(a1)+,a1		;spr1 list

	moveq	#SPROBJ_LIST_MAX-1,d6
.loop:
	;Get coords and update anim frame
	move.l	(a0)+,a3		;get ptr to a SPROBJ struct
	movem.w	(a3),d0-d3		;x,y,frame,framespeed
	add.w	d3,d2			;Update frame
	move.w	d2,SPROBJ_FRAME(a3)
	lea	SPROBJ_SIZEOF(a3),a3	;next entry

	asr.w	#SPR_POS_SCALE_SHIFT,d1	;Y Scaling from *4 

	;Clip Min-Y values (X values always in range to allow 32 px sprite and clipping)
	cmpi.w	#26,d1			;Min Y is vblank, line 26
	blt	.nodraw

	;Get BPL data for 2 sprites for correct anim frame, for anim we are using
	;<<3 (*8) so we can have fast and slow anims
	and.w	#(SPR_DISCOBALL_FRAMES*8)-1,d2	;*8 to slow down anim
	;lsr.w	#3,d2			;/8 (slowing down anim)
	;add.w	d2,d2			;Correct kingcon frame offset
	;add.w	d2,d2
	lsr	#1,d2			;lsr #3, add.w d4,d4, add.w d4,d4
	and.w	#$fffc,d2		;Make even, because skipping lsr/add/add above

	move.l	CTRL_SPRITE_A_PTR(a5),a3
	movem.w	(a3,d2.w),d2-d3		;sprite 0 and 1 offset
	lea	(a3,d3.w),a4		;sprite 1 bpl ptr
	addq.l	#4,a4			;skip ctrl words
	lea	(a3,d2.w),a3		;sprite 0 bpl ptr
	addq.l	#4,a3			;skip ctrl words

	;Work out sprite control words for spr0
	moveq	#SPR_DISCOBALL_HEIGHT,d2	;height
	add.w	d1,d2     		;d2 is vstop
	moveq	#0,d3         
	lsl.w	#8,d1			;vstart low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstart high bit to d3
	lsl.w	#8,d2			;vstop low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstop high bit to d3 
	lsr.w	#1,d0			;shift out hstart low bit
	addx.b	d3,d3     		;left shift and h start low bit to d3
	move.b	d0,d1			;make first control word
	move.b	d3,d2			;second control word
	move.w	d1,(a2)+		;update spr0 control words
	move.w	d2,(a2)+

	;rept SPR_DISCOBALL_HEIGHT
	;move.l	(a3)+,(a2)+		;write bpl1+2 data
	;endr
	WAITBLIT_NASTY_A6
;	move.l	#$09f00000,bltcon0(a6)
;	move.l	#-1,bltafwm(a6)
	move.l	a3,bltapth(a6)
	move.l	a2,bltdpth(a6)
;	move.l	#0,bltamod(a6)		;a+d mod
	move.w	#((SPR_DISCOBALL_HEIGHT*1)*64)+2,bltsize(a6)
	lea	SPR_DISCOBALL_HEIGHT*4(a2),a2	;next entry in sprite list

	;second sprite is 16 pixels to the right, we can abuse the previous ctrl word calc
	addq.b	#8,d1			;x increased by 16 :)
	move.w	d1,(a1)+		;update spr1 control words
	move.w	d2,(a1)+

	;rept SPR_DISCOBALL_HEIGHT
	;move.l	(a4)+,(a1)+		;write bpl1+2 data
	;endr
	WAITBLIT_NASTY_A6
;	move.l	#$09f00000,bltcon0(a6)
;	move.l	#-1,bltafwm(a6)
	move.l	a4,bltapth(a6)
	move.l	a1,bltdpth(a6)
;	move.l	#0,bltamod(a6)		;a+d mod
	move.w	#((SPR_DISCOBALL_HEIGHT*1)*64)+2,bltsize(a6)
	lea	SPR_DISCOBALL_HEIGHT*4(a1),a1	;next entry in sprite list

.nodraw:				;If not drawing we just don't write ctrl words :)
	dbf	d6,.loop

.terminatelist:
	;terminate lists
	moveq	#0,d0
	move.l	d0,(a2)
	move.l	d0,(a1)

	rts


****************************************************************************
* Works out current text routine status and does the needful.
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a4
*****************************************************************************

Text_Run_Routine:
	move.w	CTRL_TEXT_STATUS(a5),d0	;Get state, will be a long offset which matches the bra.w xxx jmptable
	bmi	.exit			;-ve is not running
	jmp	.jmptable(pc,d0.w)	;Run routine, must preserve a4-a6

.jmptable:
	bra.w	.newscreen
	bra.w	.pause
	bra.w	.textcalclinedetails
	bra.w	.print
	bra.w	.pause
	bra.w	.wipe1setup
	bra.w	.wipe1
	bra.w	.pause
	bra.w	.reset

.newscreen:
	move.w	#TEXT_Y_MIN,CTRL_TEXT_Y(a5)	;Starting Y
	addq.w	#4,CTRL_TEXT_STATUS(a5)		;next status
	move.w	#1,CTRL_TEXT_PAUSE(a5)
	rts


.textcalclinedetails:
	bsr	Text_Calc_Line_Details
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	rts
.print:
	bsr	Text_Draw_BlitChars		;Will update status if needs to
	rts

.pause:
	subq.w	#1,CTRL_TEXT_PAUSE(a5)
	bge.s	.exit
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	rts

.wipe1setup:
	clr.w	CTRL_WIPE_TOP_Y(a5)
	move.w	#BPL_OVR_BUF_HEIGHT-1,CTRL_WIPE_BOTTOM_Y(a5)
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	rts
.wipe1:
	bsr	DoWipe1
	rts

.reset:
	clr.w	CTRL_TEXT_STATUS(a5)
	rts

.exit:
	rts



****************************************************************************
* Prepares a line of text, works out starting x value for centered text
* also gets the kingcon bobtable offsets for all the letters so don't need
* to repeat the calculation when blitting.
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a4
*****************************************************************************

Text_Calc_Line_Details:
	;lea	Mult_LIB_BOBTABLE_SIZEOF,a1	;premult
	lea	FAR_Font8px,a2		;char to bob number
	lea	BOB_Font8px,a3		;bob number to bpl

	move.l	CTRL_TEXT_PTR(a5),a0
	move.b	(a0)+,d0		;Get first letter of line or null
	bne.s	.new			;End of scroller?

	move.l	#Scroller_Text,CTRL_TEXT_PTR(a5)
	clr.w	CTRL_TEXT_STATUS(a5)	;Restart text
	rts

.new:
	moveq	#0,d1			;Initial width
	moveq	#0,d2			;Initial number of chars

.letterloop:
	addq.w	#1,d2			;numchars++
	cmp.b	#10,d0			;linefeed?
	beq.s	.linefeed
	cmp.b	#32,d0			;Space?
	bne.s	.notspace
	addq.w	#FONT8PX_SPACE_WIDTH,d1
	bra.s	.nextletter
.notspace:
	;Work out the size of text
	ext.w	d0
	move.b	(a2,d0.w),d0		;bob number (top d0 still clear)
	bmi.s	.nextletter		;is letter valid? ($ff is invalid, we assume >127 for bmi)

	mulu	#LIB_BOBTABLE_SIZEOF,d0
	;add.w	d0,d0			;bob num to word offset
	;move.w	(a1,d0.w),d0		;LIB_BOBTABLE_SIZEOF*bob num
	add.w	LIB_BOBTABLE_WIDTH(a3,d0.w),d1	;Increase X by width

.nextletter:
	move.b	(a0)+,d0
	cmp.b	#10,d0			;linefeed?
	beq.s	.linefeed

	IFNE FONT8PX_X_SPACING		;Additional spacing
	addq.w	#FONT8PX_X_SPACING,d1
	ENDC
	bra	.letterloop

.linefeed	
	;We have the width so work out the centered X start
	lsr.w	#1,d1			;W/2
	move.w	#BPL_OVR_BUF_WIDTH/2,d0
	sub.w	d1,d0
	move.w	d0,CTRL_TEXT_X(a5)	;Store starting X

	rts


****************************************************************************
* Draws a line of text to the text buffer. May be called multiple times
* until entire line is drawn.
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0/a2/a3
*****************************************************************************

Text_Draw_BlitChars:
	;time to print a new char?
	subq.w	#1,CTRL_TEXT_PRINTCHAR_DELAY(a5)
	bmi.s	.newchar
	rts

.newchar:
	move.w	#TEXT_PRINTCHAR_DELAY,CTRL_TEXT_PRINTCHAR_DELAY(a5)	;new delay for next char

	move.l	CTRL_TEXT_PTR(a5),a4
	move.b	(a4)+,d2		;Get first letter of line or null or lf
	bne.s	.notnull		;End of scroller
	
	lea	Scroller_Text,a4
	bra.s	.exit

.notnull:

	move.w	CTRL_TEXT_X(a5),d4	;Current X
.letterloop:
	cmp.b	#10,d2			;linefeed?
	beq.s	.newline
	cmp.b	#13,d2			;cr?
	beq.s	.cr
	cmp.b	#32,d2			;Space?
	bne.s	.notspace
	addq.w	#FONT8PX_SPACE_WIDTH,d4
	bra.s	.exit			
.notspace:

	cmp.w	#FONT8PX_MAX_X,d4
	bgt.s	.exit			;Overrun, just exit

.drawletter:
	move.w	d4,d0			;Current x
	move.w	CTRL_TEXT_Y(a5),d1	;Current y

	move.l	CTRL_BPL_OVR_LOG1_PTR(a5),a0
	movem.w	d0-d2,-(sp)
	bsr	Text_Blit_Letter	;I:d0-d2/a0/a5/a6, T:d0-d3/a0/a2/a3
	movem.w	(sp)+,d0-d2

	move.l	CTRL_BPL_OVR_PHYS_PTR(a5),a0
	bsr	Text_Blit_Letter	;I:d0-d2/a0/a5/a6, T:d0-d3/a0/a2/a3

	add.w	d0,d4			;next X based on previous letter
	bra.s	.exit

.newline:
	subq.w	#4,CTRL_TEXT_STATUS(a5)	;previous status (calc line details)
	add.w	#TEXT_Y_SPACING,CTRL_TEXT_Y(a5)
	
.exit:
	move.l	a4,CTRL_TEXT_PTR(a5)	;Save pointer for next time
	move.w	d4,CTRL_TEXT_X(a5)	;Save current X
	rts

.cr:
	;This moves to the next state
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	move.w	#75,CTRL_TEXT_PAUSE(a5)
	bra.s	.exit


****************************************************************************
* Draws a letter from font1 at given x,y using blitter copy.
* Note assumes BOB BPL is interleaved.
* This routine only plots at any x position. Slower than Aligned version.
* IN:		a6, custom
*		a5, Controller_Info
*		a0, screen
*		(a1, y premult)
*		d0.w, x
*		d1.w, y
*		d2.b, ascii value
* OUT:		d0.w, x increase
* TRASHED:	d0-d3/a0/a2/a3
*****************************************************************************

Text_Blit_Letter:
	lea	FAR_Font8px,a2
	ext.w	d2			;clear top
	move.b	(a2,d2.w),d2		;bob number (top d2 still clear)
	bmi	.badletter		;is letter valid? $ff = not valid, assume >127 bad with bmi

	lea	BOB_Font8px,a2
	mulu	#LIB_BOBTABLE_SIZEOF,d2	;find bob entry for this letter
	lea	(a2,d2.w),a2

	move.l	CTRL_BPL_FONT(a5),a3		;root bob bitplane data
	add.l	LIB_BOBTABLE_OFFSET(a2),a3	;offset to bob bpl

	;If premult table available, use it
	;add.w	d1,d1			;y value, access table in words
	;add.w	(a1,d1.w),a0		;add y value to screen adr
	mulu	#BPL_OVR_BUF_BYTEWIDTH*BPL_OVR_BUF_NUMPLANES,d1
	add.l	d1,a0

	ext.l	d0			;ensure top word clear
	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen 
	add.w	d0,a0			;add byte offset to y address
	swap	d0			;d0 word now contains shift value
	or.w	#BLT_SRC_ACD+(BLT_A|BLT_C),d0	;$bfa,D=A|C
	swap	d0			;d0=bltcon0 and bltcon1
	clr.w	d0			;bltcon1=0

	; Need to have an extra word for shifting, so artificially increased
	; bob size by 1 word (and -2 for modulos)
	IFEQ FONT8PX_MONO		;proportional, have to work out widths
		move.w	LIB_BOBTABLE_WIDTHINWORDS(a2),d3
		addq.w	#1,d3		;extra word for shifting
		
		move.w	d3,d1
		add.w	#FONT8PX_HEIGHT*FONT8PX_NUMPLANES*64,d1	;bltsize

		add.w	d3,d3		;bytewidth
		moveq	#BPL_OVR_BUF_BYTEWIDTH,d2	;ensure top of d2 is 0
		sub.w	d3,d2		;modulo
	ELSE
		move.w	#FONT8PX_BLTSIZE+1,d1		;same for all bobs (mono font)
		moveq	#BPL_OVR_BUF_BYTEWIDTH-(FONT8PX_BLT_BYTEWIDTH+2),d2	;modulo (top of d2 is 0)
							;+1/+2 extra word for shifting,
	ENDC

	WAITBLIT_NASTY_A6
	move.l	d0,bltcon0(a6)
	move.l	#$ffff0000,bltafwm(a6)	;mask last word as it part of next letter!
	move.w	d2,bltcmod(a6)
	move.w	#-2,bltamod(a6)	; interleaved (mod 0) but have extra word for shifting
	move.w	d2,bltdmod(a6)
	move.l	a0,bltcpth(a6)	;Screen
	move.l	a3,bltapth(a6)	;BOB data
	move.l	a0,bltdpth(a6)	;Screen
	move.w	d1,bltsize(a6)
.exit:
	move.w	LIB_BOBTABLE_WIDTH(a2),d0	;Actual pixel width we used
	
	IFNE FONT8PX_X_SPACING		;Additional spacing
	addq.w	#FONT8PX_X_SPACING,d0
	ENDC

	rts

.badletter:
	moveq	#0,d0		;Moved on 0 px
	rts


*****************************************************************************
* First stage of the wipe
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	d0-d7/a0-a5
*****************************************************************************

DoWipe1:
	move.w	CTRL_WIPE_TOP_Y(a5),d0
	addq.w	#2,d0
	cmp.w	#BPL_OVR_BUF_HEIGHT,d0
	blt.s	.ytopok
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	rts
.ytopok
	move.w	d0,CTRL_WIPE_TOP_Y(a5)
	mulu.w	#BPL_OVR_BUF_MOD_LINE,d0
	bsr.s	.clearline

	move.w	CTRL_WIPE_BOTTOM_Y(a5),d0
	subq.w	#2,d0
	bge.s	.ybotok
	addq.w	#4,CTRL_TEXT_STATUS(a5)	;next status
	rts
.ybotok
	move.w	d0,CTRL_WIPE_BOTTOM_Y(a5)
	mulu.w	#BPL_OVR_BUF_MOD_LINE,d0

.clearline:
	move.l  CTRL_BPL_OVR_PHYS_PTR(a5),a0	;memory to clear
	add.l	d0,a0
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((1*BPL_OVR_BUF_NUMPLANES)*64)+BPL_OVR_BUF_WORDWIDTH,bltsize(a6)

	move.l  CTRL_BPL_OVR_LOG1_PTR(a5),a0	;memory to clear
	add.l	d0,a0
	WAITBLIT_NASTY_A6
	move.l	a0,bltdpth(a6)
	move.w	#((1*BPL_OVR_BUF_NUMPLANES)*64)+BPL_OVR_BUF_WORDWIDTH,bltsize(a6)

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
