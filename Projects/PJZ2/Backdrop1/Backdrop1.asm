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

P0_DDF_H		equ	$71		;Hardware Hstart ($81 normal, $71 overscan)
P0_DDF_WIDTH		equ	320+16		;Pixels		 (320 normal pal, 352 overscan)
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

;BPL_xxx is the visible size, might not always match buffer
BPL_WIDTH		equ	P0_DIW_WIDTH
BPL_HEIGHT		equ	P0_DIW_HEIGHT

BPL_LINE_MAX_SINE	equ	256	;0-64

;The single line we render, the buffer is 32 px wider at the right for easy drawing
BPL_LINE_WIDTH		equ	P0_DDF_WIDTH+BPL_LINE_MAX_SINE
BPL_LINE_BYTEWIDTH	equ	BPL_LINE_WIDTH/8
BPL_LINE_WORDWIDTH	equ	BPL_LINE_BYTEWIDTH/2
BPL_LINE_HEIGHT		equ	1
BPL_LINE_SIZE		equ	BPL_LINE_BYTEWIDTH

BPL_LINE_BUF_WIDTH	equ	BPL_LINE_WIDTH+32
BPL_LINE_BUF_BYTEWIDTH	equ	BPL_LINE_BUF_WIDTH/8
BPL_LINE_BUF_WORDWIDTH	equ	BPL_LINE_BUF_BYTEWIDTH/2
BPL_LINE_BUF_HEIGHT	equ	1
BPL_LINE_BUF_SIZE	equ	BPL_LINE_BUF_BYTEWIDTH


*****************************************************************************

PERFORM_ENABLE_MUSICSYNC	equ	1
PERFORM_ENABLE_SINESET		equ	1
PERFORM_ENABLE_USERVALWAIT	equ	1

*****************************************************************************

; We need sprite 0/1 colors as well 16,17,18,19
PAL_NUMCOLS_MAIN	equ	20 ;BPL_BUF_NUMCOLS	; number of main colour entries in our palettes
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

	xdef	BKG1_Start
BKG1_Start:
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
	;jsr	FW_SetBaseIrq		;default irq
	jsr	FW_SetBaseCopperIrq_A6	;T:a0
	jsr	FW_WaitTOF_A6		;T:None

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
	xdef	BKG1_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
BKG1_PreCalc_IntroStart:
	tst.w	Controller_Info+CTRL_PRECALC_INTROSTART_DONE
	bne.s	.exit			;already done

	movem.l	d2-d7/a2-a6,-(sp)	;save
	lea	Controller_Info(pc),a5

	;Create 2bpl palette
	lea	PAL_256_Col1_Overlap,a0
	move.w	#$fff,d0		;white
	move.w	#256-1,d1
.pl:	move.w	d0,(a0)+
	dbf	d1,.pl

	lea	PAL_256_Col1_Src,a0
	lea	PAL_256_Col1_Overlap,a1
	lea	PAL_256_Col1_Overlap,a2
	move.w	#256,d0
	moveq	#2,d1			;3 steps brighter
	jsr	LIB_RGB12_Interpolate_Fast_Palette


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
	xdef	BKG1_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
BKG1_P0_PreCalc:
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

	;Copperlists
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

	;Alloc sprite in chip mem and copy
CUR_CHIP_BUF set CUR_CHIP_BUF+SPR_SIZEOF	
	move.l	#SPR_SIZEOF,d0			;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_SPRITE_PTR(a5)	;save allocated address
	lea	SPR_Dancer_Source(pc),a0	;src
	move.l	d0,a1				;destination
	move.w	#SPR_SIZEOF/2,d0		;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2	

	;Our lines must be in a 64kb block so we can just use the ptl values in copper routine
CUR_CHIP_BUF set CUR_CHIP_BUF+(BPL_LINE_BUF_SIZE*2)+65536
	move.l	#(BPL_LINE_BUF_SIZE*2)+65536,d0
	jsr	FW_Mem_Alloc_Chip
	ALIGN_64KB_DX_L	d0

	moveq	#BPL_LINE_BUF_SIZE,d1
	move.l	d0,CTRL_BPL_LINE1_PHYS_PTR(a5)
	add.l	d1,d0
	move.l	d0,CTRL_BPL_LINE1_LOG1_PTR(a5)


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

	move.w	#1,CTRL_SPRITE_ANIM_STEP(a5)

	;Run script up to the first FX_PAUSE command - use for setting base effect 
	;settings and palette rather than wasting code here on it
	bsr	Controller_ReadCommands	;I:a5, T:d0-d7/a0-a4

	;Setup phys/logical bpl and copperlist ptrs and load palette
	bsr	P0_CL_InitPtrs			;I:a5-a6, T:d0-d2/a0-a1
	bsr	Line1_Generate			;I:a5, T:d0-d7/a0-a4
	bsr	Copper_Write_BPL_Line1_Pattern	;I:a5, T:d0-d7/a0-a4
	bsr	Copper_Write_BPL_Line2_Pattern	;I:a5, T:d0-d7/a0-a4

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

	;Clear our render line
	bsr	Clear_BPL_Line_BLT	

	addq.w	#1,CTRL_FRAME_COUNT(a5)	;Update local frame count
	jsr	FW_VBlankProxy		;T:d0-d7/a0-a4

	; Read new script lines and perform
	bsr	Controller_ReadCommands	;Read new commands
	bsr	Controller_Perform	;Do any ongoing time-based effects and update angles

	;Load current palette into CL if needed
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2

	;Draw sprite in CL
	bsr	Sprite_Draw_Dancer

	;Write the funky background pattern
	WAITBLIT_NASTY_A6		;Clear_BPL_Line_BLT
	bsr	Line1_Generate			;I:a5, T:d0-d7/a0-a4
	bsr	Copper_Write_BPL_Line1_Pattern	;I:a5, T:d0-d7/a0-a4
	bsr	Copper_Write_BPL_Line2_Pattern	;I:a5, T:d0-d7/a0-a4

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
	move.l	CTRL_CL_PHYS_PTR(a5),a0	
	lea	P0_CL_SPRITES_OFFSET(a0),a0
	moveq	#8,d0			;8 sprites
	jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1

	; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
	move.l	CTRL_CL_PHYS_PTR(a5),a0		;source
	move.l	CTRL_CL_LOG1_PTR(a5),a1		;dest
	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

	;Bitplane ptrs are done in ripple routine

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

	lea	CTRL_CL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap CL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)			;d1 is phys

	; and activate next frame - d1 is physical
	move.l 	d1,cop1lch(a6)		; Active NEXT frame

	rts


*****************************************************************************
* Clears the single line buffer.
* Clears with the blitter only.
* IN:		a5, Controller_Info
*		a6, _custom
* OUT:		
* TRASHED:	a0
*****************************************************************************

Clear_BPL_Line_BLT:

	move.l  CTRL_BPL_LINE1_LOG1_PTR(a5),a0
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((BPL_LINE_BUF_HEIGHT)*64)+BPL_LINE_BUF_WORDWIDTH,bltsize(a6)
	; Max height = 1024, made wordwidth = 64

	rts


*****************************************************************************
* Generate sine values 2048 between -16384 and 16384. Generates an extra 
* 256 words so can use for sine and cosine.
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

;-8192 to 8191 etc
;-4096 to 4095
;If rounding with addx means this becomes:
;-8191 to 8192

GenSin_Generate_Sine:
	movem.l	d2-d3,-(sp)

	;move.l	CTRL_SINETAB_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

	;change range from -16383 to 16383 to 0 to 255.
.changerange:
	lea	GenSin_Table_16384_2048W,a0
	move.l	CTRL_SINETAB_PTR(a5),a1
	move.w	#128,d0
	move.w	#(LIB_GENSIN_16384_2048W_NUMWORDS+(LIB_GENSIN_16384_2048W_NUMWORDS/4))-1,d1
	moveq	#0,d2
.cl:
	move.w	(a0)+,d3	
	asr.w	#7,d3			;change range to -128 to 127
	add.w	d0,d3			;0-255
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

	;Switch dancer direction
	neg.w	CTRL_SPRITE_ANIM_STEP(a5)

	;Set color fade to max 
	;move.w	#15*4,CTRL_MUSIC_FADE_STEP(a5)	;Max is 15 scaled by 4

	; DO TRIGGER OPERATION HERE
	move.l	.sineptr(pc),a0
	lea	CTRL_SINE_LAST(a5),a1	;last sine entry for bounds check
	lea	CTRL_SINE_SIZEOF(a0),a0	;next entry
	cmp.l	a1,a0
	ble.s	.sineinrange
	lea	CTRL_SINE_FIRST(a5),a0	;first sine entry
.sineinrange:
	neg.w	CTRL_SINE_SPEED(a0)
	move.l	a0,.sineptr

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

.sineptr:
	dc.l	Controller_Info+CTRL_SINE_FIRST

	endif				;PERFORM_ENABLE_MUSICSYNC


*****************************************************************************
* Sets up the palette change process.
* IN:		a5, Controller_Info
*		a0, new pallete
*		d0, speed
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
* Performs the pallete change.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d1/a0
*****************************************************************************

	ifne	PERFORM_ENABLE_SINESET
Controller_FX_SineSet_Perform:

	lea	CTRL_BPL_SINE1(a5),a0
	bsr.s	.checksine
	lea	CTRL_BPL_SINE2(a5),a0
	bsr.s	.checksine
	lea	CTRL_BPL_SINE3(a5),a0
	bsr.s	.checksine
	lea	CTRL_BPL_SINE4(a5),a0
	bsr.s	.checksine
	lea	CTRL_LINE_SINE1(a5),a0
	bsr.s	.checksine
	lea	CTRL_LINE_SINE2(a5),a0
	;bra.s	.checksine
	;fallthrough

.checksine:
	tst.w	CTRL_SINESET_ACTIVE(a0)
	bne.s	.active
	rts
.active:
	subq.w	#1,CTRL_SINESET_COUNTER(a0)	;check counter
	bgt.s	.exit				;1 or greater we skip

	moveq	#0,d2				;1 if still changing speed/step

	move.w	CTRL_SINE_SPEED(a0),d0
	cmp.w	CTRL_SINE_SPEEDNEW(a0),d0
	beq.s	.checkstep
	bgt.s	.speedgt
.speedlt:
	addq.w	#2,CTRL_SINE_SPEED(a0)		;2 is the smallest change value (a single even offset)
	moveq	#1,d2
	bra.s	.checkstep
.speedgt:
	subq.w	#2,CTRL_SINE_SPEED(a0)
	moveq	#1,d2

.checkstep
	move.w	CTRL_SINE_FREQ(a0),d0
	cmp.w	CTRL_SINE_FREQNEW(a0),d0
	beq.s	.checkdone
	bgt.s	.stepgt
.steplt:
	addq.w	#2,CTRL_SINE_FREQ(a0)
	moveq	#1,d2
	bra.s	.checkdone
.stepgt:
	subq.w	#2,CTRL_SINE_FREQ(a0)
	moveq	#1,d2

.checkdone:
	;Any changes left?
	tst.w	d2
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
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

LINE1_GENERATE_MINCPU equ 0
LINE1_GENERATE_32PX equ 1		;16px by default

Line1_Generate:
	movem.l	a5-a6,-(sp)

	move.l	CTRL_BPL_LINE1_LOG1_PTR(a5),a0	;Start address
	move.l	CTRL_SINETAB_PTR(a5),a1

	; Sine 1
	move.w	CTRL_LINE_SINE1+CTRL_SINE_OFFSET(a5),d4	;Offset in words
	add.w	CTRL_LINE_SINE1+CTRL_SINE_SPEED(a5),d4	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d4	;Ensure in range
	move.w	d4,CTRL_LINE_SINE1+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_LINE_SINE1+CTRL_SINE_FREQ(a5),d5	;Get step (movement per pixel)
	;d4=cur offset, d5=step

	; Sine 2
	move.w	CTRL_LINE_SINE2+CTRL_SINE_OFFSET(a5),d6	;Offset in words
	add.w	CTRL_LINE_SINE2+CTRL_SINE_SPEED(a5),d6	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d6	;Ensure in range
	move.w	d6,CTRL_LINE_SINE2+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_LINE_SINE2+CTRL_SINE_FREQ(a5),a4	;Get step (movement per pixel)
	;d6=cur offset, a4=step

	;We keep the current x pos in the range of the sine table which is much
	;smoother. -128 to 127 and we convert to final screen coords with >>4.
	;However we are doing dual sine so that ends up as -256 to 255 so we
	;have to do >>5.

	moveq	#0,d3			;always zero for precision/addx ops
	move.w	d3,a3			;current x is 0 (<<4)
	move.w	#BPL_LINE_WIDTH<<4,a5	;<<4
	move.w	#31,a6			;additional spacing
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d7
.l
	move.w	(a1,d4.w),d2		;0 to 255
	add.w	(a1,d6.w),d2		;0 to 511

	ifeq	LINE1_GENERATE_32PX
	asr.w	#1,d2			;0 to 255, use this if using 16x wide
	endif

	addx.w	d3,d2			;extra precision - not critical

	move.w	a3,d1			;save current x (<<4 range)
	add.w	d2,a3			;next x position
	
	ifne LINE1_GENERATE_MINCPU
	add.w	d2,a3			;next x position (spacing)
	add.w	a6,a3			;extra spacing to avoid too close
	endif

	asr.w	#4,d1			;<<4 to screen range

	asr.w	#4,d2			;>>4 for 0 to 31 (32 "images" for pattern), or 0-15 if 16pix wide above
	sub.w	Controller_Info+CTRL_BLINDSFADE(pc),d2
	bmi.s	.skipdraw		;nothing to draw
	add.w	d2,d2			;to word table offset
	add.w	d2,d2			;to long table offset

	moveq	#16-1,d0
	and.w	d1,d0			;pixel shift value
	lsr.w	#4,d1			;byte offset
	add.w	d1,d1			;even byte offset
	lea	(a0,d1.w),a2		;a2 is screen address

	;word 1
	moveq	#0,d1			;clear top of d1 for swaps
	move.w	.images(pc,d2.w),d1
	swap	d1			;move data to top of long for shifting
	lsr.l	d0,d1			;do the shift
	or.l	d1,(a2)			;merge with screen

	ifne	LINE1_GENERATE_32PX
		;word 2
		moveq	#0,d1			;clear top of d1 for swaps
		move.w	.images+2(pc,d2.w),d1
		swap	d1			;move data to top of long for shifting
		lsr.l	d0,d1			;do the shift
		or.l	d1,2(a2)		;merge with screen
	endif

.skipdraw:
	add.w	d5,d4			;next sine value
	and.w	d7,d4			;Ensure in range
	add.w	a4,d6			;next sine value
	and.w	d7,d6			;Ensure in range


	;Also use the sine for spacing - it looks nicer
	ifeq LINE1_GENERATE_MINCPU
	move.w	(a1,d4.w),d2		;0 to 256
	add.w	(a1,d6.w),d2		;0 to 512
	asr.w	#1,d2			;0 to 256
	addx.w	d3,d2			;extra precision - not critical
	add.w	a6,d2			;extra spacing to avoid too close
	add.w	d2,a3			;next x position

	add.w	d5,d4			;next sine value
	and.w	d7,d4			;Ensure in range
	add.w	a4,d6			;next sine value
	and.w	d7,d6			;Ensure in range
	endif

	;Past end of line (there are 4 bytes overrun protection)
	cmp.w	a5,a3
	blt.s	.l

	movem.l	(sp)+,a5-a6
	rts

.images
	dc.w	%1000000000000000,%0000000000000000	;0
	dc.w	%1100000000000000,%0000000000000000
	dc.w	%1110000000000000,%0000000000000000
	dc.w	%1111000000000000,%0000000000000000
	dc.w	%1111100000000000,%0000000000000000
	dc.w	%1111110000000000,%0000000000000000
	dc.w	%1111111000000000,%0000000000000000
	dc.w	%1111111100000000,%0000000000000000
	dc.w	%1111111110000000,%0000000000000000
	dc.w	%1111111111000000,%0000000000000000
	dc.w	%1111111111100000,%0000000000000000
	dc.w	%1111111111110000,%0000000000000000
	dc.w	%1111111111111000,%0000000000000000
	dc.w	%1111111111111100,%0000000000000000
	dc.w	%1111111111111110,%0000000000000000
	dc.w	%1111111111111111,%0000000000000000	;15

	dc.w	%1111111111111111,%1000000000000000	;16
	dc.w	%1111111111111111,%1100000000000000
	dc.w	%1111111111111111,%1110000000000000
	dc.w	%1111111111111111,%1111000000000000
	dc.w	%1111111111111111,%1111100000000000
	dc.w	%1111111111111111,%1111110000000000
	dc.w	%1111111111111111,%1111111000000000
	dc.w	%1111111111111111,%1111111100000000
	dc.w	%1111111111111111,%1111111110000000
	dc.w	%1111111111111111,%1111111111000000
	dc.w	%1111111111111111,%1111111111100000
	dc.w	%1111111111111111,%1111111111110000
	dc.w	%1111111111111111,%1111111111111000
	dc.w	%1111111111111111,%1111111111111100
	dc.w	%1111111111111111,%1111111111111110
	dc.w	%1111111111111111,%1111111111111111	;31


*****************************************************************************
* Loads the current colors into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Copper_Write_BPL_Line1_Pattern:
	movem.l	a5-a6,-(sp)

	move.l	CTRL_CL_LOG1_PTR(a5),a0

	;Write the hiword of bplpth - memory is in a 64KB boundary so don't
	;need to write the pth every line
	move.l	CTRL_BPL_LINE1_LOG1_PTR(a5),a2
	move.l	a2,d0
	swap	d0				
	move.w	d0,P0_CL_BPL_OFFSET+2(a0)	;bpl1pth

	lea	P0_CL_PATTERN_OFFSET+CL_PATTERN_COLOR01+2(a0),a0
	move.w	#CL_PATTERN_SIZEOF,a1
	
	;In our line buffer we need to select the last half leaving
	;enough room for P0_DFF_BYTEWIDTH to be displayed
	lea	BPL_LINE_BYTEWIDTH-P0_DDF_BYTEWIDTH(a2),a2
	move.l	CTRL_SINETAB_PTR(a5),a3

	; Sine 1
	move.w	CTRL_BPL_SINE1+CTRL_SINE_OFFSET(a5),d2	;Offset in words
	add.w	CTRL_BPL_SINE1+CTRL_SINE_SPEED(a5),d2	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d2	;Ensure in range
	move.w	d2,CTRL_BPL_SINE1+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_BPL_SINE1+CTRL_SINE_FREQ(a5),d3	;Get step (movement per pixel)
	;d2=cur offset, d3=step

	; Sine 2
	move.w	CTRL_BPL_SINE2+CTRL_SINE_OFFSET(a5),d4	;Offset in words
	add.w	CTRL_BPL_SINE2+CTRL_SINE_SPEED(a5),d4	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d4	;Ensure in range
	move.w	d4,CTRL_BPL_SINE2+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_BPL_SINE2+CTRL_SINE_FREQ(a5),a4	;Get step (movement per pixel)
	;d4=cur offset, a4=step

	;Update each line
	move.w	#BPL_HEIGHT-1,d7
	moveq	#0,d6			;used for precision/addx
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d5
	lea	PAL_256_Col1_Src,a5
	;lea	PAL_256_Col1_Overlap,a6
.loop:
	move.w	(a3,d2.w),d0		;sine 1, 0 to 255
	add.w	(a3,d4.w),d0		;add sine2, 0 to 511
	asr.w	#1,d0			;fix range, 0 to 255
	;addx.w	d6,d0			;extra precision - not critical

	move.w	d0,d1			;0-256
	add.w	d1,d1			;word access
	;move.w	(a5,d1.w),CL_PATTERN_COLOR01-CL_PATTERN_COLOR01(a0)	;CL_PATTERN_COLOR01

	;d0.w = x pos in bpl
	moveq	#$f,d1
	and.w	d0,d1			;convert x value to 0-15 (for shift val)
	add.w	d1,d1			;table lookup in words
	move.w	.bplcon1_tab(pc,d1.w),CL_PATTERN_BPLCON1-CL_PATTERN_COLOR01(a0)	;bplcon1

	lsr.w	#4,d0			;number of words
	add.w	d0,d0			;EVEN number of bytes offset into bpl (also word table offset lookup!)

	neg.w	d0			;We need to subtract
	;ext.l	d0			;clear top
	add.w	a2,d0			;d0=bpl address. Only need add.w because of 64KB boundary
	move.w	d0,CL_PATTERN_BPL1PTL-CL_PATTERN_COLOR01(a0)	;bplptl
	;swap	d0				;TODO: could remove bplpth if on 64KB boundary
	;move.w	d0,CL_PATTERN_BPL1PTH-CL_PATTERN_COLOR01(a0)	;bplpth
	add.w	a1,a0				;next copper entry

	add.w	d3,d2			;Sine1 offset+=step
	and.w	d5,d2			;Ensure in range
	add.w	a4,d4			;Sine1 offset+=step
	and.w	d5,d4			;Ensure in range

	dbf	d7,.loop	

	movem.l	(sp)+,a5-a6
	rts

.bplcon1_tab:
	dc.w	$0000,$0001,$0002,$0003,$0004,$0005,$0006,$0007
	dc.w	$0008,$0009,$000a,$000b,$000c,$000d,$000e,$000f


*****************************************************************************
* Loads the current colors into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Copper_Write_BPL_Line2_Pattern:
	movem.l	a5-a6,-(sp)

	move.l	CTRL_CL_LOG1_PTR(a5),a0

	;Write the hiword of bplpth - memory is in a 64KB boundary so don't
	;need to write the pth every line
	move.l	CTRL_BPL_LINE1_LOG1_PTR(a5),a2
	move.l	a2,d0
	swap	d0				
	move.w	d0,P0_CL_BPL_OFFSET+10(a0)	;bpl2pth

	lea	P0_CL_PATTERN_OFFSET+CL_PATTERN_COLOR01+2(a0),a0
	move.w	#CL_PATTERN_SIZEOF,a1
	
	;In our line buffer we need to select the last half leaving
	;enough room for P0_DFF_BYTEWIDTH to be displayed
	lea	BPL_LINE_BYTEWIDTH-P0_DDF_BYTEWIDTH(a2),a2
	move.l	CTRL_SINETAB_PTR(a5),a3

	; Sine 1
	move.w	CTRL_BPL_SINE3+CTRL_SINE_OFFSET(a5),d2	;Offset in words
	add.w	CTRL_BPL_SINE3+CTRL_SINE_SPEED(a5),d2	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d2	;Ensure in range
	move.w	d2,CTRL_BPL_SINE3+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_BPL_SINE3+CTRL_SINE_FREQ(a5),d3	;Get step (movement per pixel)
	;d2=cur offset, d3=step

	; Sine 2
	move.w	CTRL_BPL_SINE4+CTRL_SINE_OFFSET(a5),d4	;Offset in words
	add.w	CTRL_BPL_SINE4+CTRL_SINE_SPEED(a5),d4	;Add speed (movement per frame)
	and.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d4	;Ensure in range
	move.w	d4,CTRL_BPL_SINE4+CTRL_SINE_OFFSET(a5)	;Save for next frame
	move.w	CTRL_BPL_SINE4+CTRL_SINE_FREQ(a5),a4	;Get step (movement per pixel)
	;d4=cur offset, a4=step

	;Update each line
	move.w	#BPL_HEIGHT-1,d7
	moveq	#0,d6			;used for precision/addx
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d5
	lea	PAL_256_Col1_Src,a5
	lea	PAL_256_Col1_Overlap,a6	
.loop:
	move.w	(a3,d2.w),d0		;sine 1, 0 to 255
	add.w	(a3,d4.w),d0		;add sine2, 0 to 511
	asr.w	#1,d0			;fix range, 0 to 255
	;addx.w	d6,d0			;extra precision - not critical

	;select color02 (background) and color03 (1+2 overlap)
	move.w	d0,d1			;0-255
	add.w	d1,d1			;word access
	move.w	(a5,d1.w),CL_PATTERN_COLOR01-CL_PATTERN_COLOR01(a0)	;CL_PATTERN_COLOR01
	move.w	(a6,d1.w),CL_PATTERN_COLOR03-CL_PATTERN_COLOR01(a0)	;CL_PATTERN_COLOR03

	;d0.w = x pos in bpl
	moveq	#$f,d1
	and.w	d0,d1				;convert x value to 0-15 (for shift val)
	add.w	d1,d1				;table lookup in words
	move.w	.bplcon1_tab(pc,d1.w),d1	;d1=bplcon1
	or.w	d1,CL_PATTERN_BPLCON1-CL_PATTERN_COLOR01(a0)	;MERGE bplcon1

	lsr.w	#4,d0			;number of words
	add.w	d0,d0			;EVEN number of bytes offset into bpl (also word table offset lookup!)

	neg.w	d0			;We need to subtract
	;ext.l	d0			;clear top
	add.w	a2,d0			;d0=bpl address. Only need add.w because of 64KB boundary
	
	move.w	d0,CL_PATTERN_BPL2PTL-CL_PATTERN_COLOR01(a0)	;bplptl
	;swap	d0				;TODO: could remove bplpth if on 64KB boundary
	;move.w	d0,CL_PATTERN_BPL1PTH-CL_PATTERN_COLOR01(a0)	;bplpth
	add.w	a1,a0				;next copper entry

	add.w	d3,d2			;Sine1 offset+=step
	and.w	d5,d2			;Ensure in range
	add.w	a4,d4			;Sine1 offset+=step
	and.w	d5,d4			;Ensure in range

	dbf	d7,.loop	

	movem.l	(sp)+,a5-a6
	rts

.bplcon1_tab:
	dc.w	$0000,$0010,$0020,$0030,$0040,$0050,$0060,$0070
	dc.w	$0080,$0090,$00a0,$00b0,$00c0,$00d0,$00e0,$00f0


*****************************************************************************
* Loads the current colors into the current copperlist if changed.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0/a0-a2
*****************************************************************************

;Changed to write 

Copper_Write_Palette:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_PALETTE_LOAD_FLAG(a5)
	beq.s	.musicsync
.active:
	subq.w	#1,CTRL_PALETTE_LOAD_FLAG(a5)

	lea	PAL_Current(pc),a0
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_COL_OFFSET+2(a1),a1
;	move.l	a1,a2			;save

	rept	PAL_NUMCOLS_MAIN
	move.w	(a0)+,(a1)
	addq.l	#4,a1			;next color
	endr
.musicsync:	
	rts
;	move.w	CTRL_MUSIC_FADE_STEP(a5),d2
;	beq.s	.alreadyzero
	
	;Colour 2 can always be lightened in time with music
;	lea	PAL_Current(pc),a0
;	move.w	(2*2)(a0),d0			;Source col is 2
;	move.w	#$fff,d1			;Dest col

;	subq.w	#1,d2
;	move.w	d2,CTRL_MUSIC_FADE_STEP(a5)
;	lsr.w	#2,d2				;Scale down by 4
;	jsr	LIB_RGB12_Interpolate_Fast	;trashes d0-d4
;	move.w	d0,8(a2)			;Col2 in CL

.alreadyzero:	
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

Sprite_Draw_Dancer:

	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_SPRITES_OFFSET+2(a1),a1	;copper spr pointer block, skip to pth word


	move.w	#320-(32+8),d0
	move.w	#256-(64+8),d1
	;d0=screenx, d1=screeny

	;Sprite data is in kingcon format. We are using 32px wide ANIM sprites so the format is:
	;dc.w	offset-spr0-frame0,offset-spr1-frame0
	;dc.w	offset-spr0-frame1,offset-spr1-frame1
	;The add the offset and that will now be the correct sprite control words and data for that frame
	
.updatepth:
	move.w	CTRL_SPRITE_ANIM_FRAME(a5),d4	;Get animation frame number
	add.w	CTRL_SPRITE_ANIM_STEP(a5),d4
	and.w	#(SPR_ANIM_FRAMES*4)-1,d4	;*4 to slow down anim
	move.w	d4,CTRL_SPRITE_ANIM_FRAME(a5)	
	;lsr.w	#2,d4			;/4 (slowing down anim)
	;add.w	d4,d4			;Correct kingcon frame offset
	;add.w	d4,d4
	and.w	#$fffc,d4		;Because skipping lsr #2/add/add

	move.l	CTRL_SPRITE_PTR(a5),a0	;Select correct sprite set LIGHT_SPRITE_A_PTR to LIGHT_SPRITE_D_PTR, then retrieve sprite set ptr 
	movem.w	(a0,d4.w),d2-d3		;sprite 0 and 1 offset
	lea	(a0,d3.w),a2		;sprite 1 ptr
	lea	(a0,d2.w),a0		;sprite 0 ptr

	;a1=spr0pth in cl, a0=spr0, a2=spr1
	;d0/d1, x/y

	;Update sprite ptrs
	move.l	a0,d2
	move.w	d2,4(a1)		;spr0 ptl
	swap	d2
	move.w	d2,(a1)			;pth
	addq.l	#8,a1			;next set of ptrs
	move.l	a2,d2
	move.w	d2,4(a1)		;spr1 ptl
	swap	d2
	move.w	d2,(a1)			;pth
	addq.l	#8,a1			;next set of ptrs

	add.w	#P0_DIW_H,d0		;xpos to sprite coords
	add.w	#P0_DIW_V,d1		;ypos to sprite coords
.spr0:
	;Write sprite control words
	moveq	#SPR_HEIGHT,d2		;height
	GET_SPRITE_CTRL_WORDS_BOUNDS_CHECK	;I:d0-d2, O:d1-d2, T:d0-d3
	move.w	d1,(a0)+		;update spr0 control words
	move.w	d2,(a0)
	
	;second sprite is 16 pixels to the right, we can abuse the previous ctrl word calc
	addq.b	#8,d1			;x increased by 16 :)
	move.w	d1,(a2)+		;update spr0 control words
	move.w	d2,(a2)

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
