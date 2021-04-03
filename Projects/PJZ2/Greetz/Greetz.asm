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
;We just allocate a blank line and repeat it
BPL_BUF_WIDTH		equ	320
BPL_BUF_BYTEWIDTH	equ	BPL_BUF_WIDTH/8
BPL_BUF_WORDWIDTH	equ	BPL_BUF_BYTEWIDTH/2
BPL_BUF_HEIGHT		equ	256
BPL_BUF_NUMPLANES	equ	1
BPL_BUF_NUMCOLS 	equ	(1<<BPL_BUF_NUMPLANES)
BPL_BUF_SIZE		equ	BPL_BUF_BYTEWIDTH*1	;We just allocate a blank line and repeat it
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

;The scrolling font screen (2 screens high plus 2xTXT AREA)
BPL_BUF_VSCROLL_WIDTH		equ	BPL_BUF_WIDTH
BPL_BUF_VSCROLL_BYTEWIDTH	equ	BPL_BUF_VSCROLL_WIDTH/8
BPL_BUF_VSCROLL_WORDWIDTH	equ	BPL_BUF_VSCROLL_BYTEWIDTH/2
BPL_BUF_VSCROLL_HEIGHT		equ	(BPL_BUF_HEIGHT*2)+(BPL_BUF_TEXT_HEIGHT*3)
BPL_BUF_VSCROLL_NUMPLANES	equ	2
BPL_BUF_VSCROLL_NUMCOLS 	equ	(1<<BPL_BUF_VSCROLL_NUMPLANES)
BPL_BUF_VSCROLL_SIZE		equ	BPL_BUF_VSCROLL_BYTEWIDTH*BPL_BUF_VSCROLL_HEIGHT
BPL_BUF_VSCROLL_TOTALSIZE	equ	BPL_BUF_VSCROLL_SIZE*BPL_BUF_VSCROLL_NUMPLANES
BPL_BUF_VSCROLL_INTERLEAVED	equ	1

	ifne BPL_BUF_VSCROLL_INTERLEAVED
BPL_BUF_VSCROLL_MOD_LINE	equ	BPL_BUF_VSCROLL_BYTEWIDTH*BPL_BUF_VSCROLL_NUMPLANES
BPL_BUF_VSCROLL_MOD_BPL		equ	BPL_BUF_VSCROLL_BYTEWIDTH
	else
BPL_BUF_VSCROLL_MOD_LINE	equ	BPL_BUF_VSCROLL_BYTEWIDTH
BPL_BUF_VSCROLL_MOD_BPL		equ	BPL_BUF_VSCROLL_SIZE
	endif

BPL_VSCROLL_BPLMOD		equ	BPL_BUF_VSCROLL_MOD_LINE-P0_DDF_BYTEWIDTH
BPL_VSCROLL_BPLMOD_REPTLINE	equ	-P0_DDF_BYTEWIDTH
BPL_VSCROLL_BPLMOD_REPTPREVLINE	equ	(-BPL_BUF_VSCROLL_MOD_LINE)-P0_DDF_BYTEWIDTH
BPL_VSCROLL_BPLMOD_REPT2LINE	equ	BPL_VSCROLL_BPLMOD_REPTPREVLINE-BPL_BUF_VSCROLL_MOD_LINE
BPL_VSCROLL_BPLMOD_SKIPLINE	equ	BPL_VSCROLL_BPLMOD+(BPL_BUF_VSCROLL_MOD_LINE)

; Font screen buffer height, everything else is the same as scroller screen (modulos, width ,etc)
; Height implies the Y spacing
BPL_BUF_TEXT_HEIGHT		equ	FONT8PX_HEIGHT
BPL_BUF_TEXT_SIZE		equ	BPL_BUF_VSCROLL_BYTEWIDTH*BPL_BUF_TEXT_HEIGHT
BPL_BUF_TEXT_TOTALSIZE	equ	BPL_BUF_TEXT_SIZE*BPL_BUF_VSCROLL_NUMPLANES

VSCROLL_MIN		equ	BPL_BUF_TEXT_HEIGHT
VSCROLL_MAX		equ	VSCROLL_MIN+BPL_BUF_HEIGHT+BPL_BUF_TEXT_HEIGHT
VSCROLL_Y_SPACING	equ	FONT8PX_HEIGHT+(FONT8PX_HEIGHT/2)

; We limit how many char blits we do per frame to keep the time down. The frame cycle is
; Clear buffer, Blit chars * X, copy chars to screen. So that means we have this many frames free
; VSCROLL_MAX_CHARS_PER_LINE / (VSCROLL_Y_SPACING - 2)  (-2 is the clear, copy frames)
VSCROLL_MAX_CHARS_PER_LINE	equ	40	;~Widest line in chars (proportional so guess)
VSCROLL_MAX_CHARS_PER_FRAME	equ	VSCROLL_MAX_CHARS_PER_LINE/(VSCROLL_Y_SPACING-2)

*****************************************************************************

PERFORM_ENABLE_MUSICSYNC	equ	1
PERFORM_ENABLE_SINESET		equ	0
PERFORM_ENABLE_USERVALWAIT	equ	0

*****************************************************************************

PAL_NUMCOLS_MAIN	equ	1	; Only color 0, hadrcoded font colors
PAL_NUMCOLS_ALT		equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_ALT)

*****************************************************************************

;Local font changes
FONT8PX_MIN_X		equ 8
FONT8PX_MAX_X		equ (BPL_BUF_VSCROLL_WIDTH-1)-16

*****************************************************************************

ZOOM_BPLCON0_ON		equ	((BPL_BUF_NUMPLANES+BPL_BUF_VSCROLL_NUMPLANES)*$1000)|$0600
ZOOM_BPLCON0_OFF	equ	$0600	;0bpl screen

*****************************************************************************

BAR_MAX_Y		equ	(BPL_HEIGHT-1)


BAR_NUM_FADE_LEVELS	equ	31	;-15, 0, 15
BAR_FADE_LEVEL_MAX	equ	BAR_NUM_FADE_LEVELS-1
BAR_FADE_SPEED		equ	3	;Fade speed, 1= quicker

BAR_NUM_PAL		equ	2		;number of palettes to cycles
BAR_NUM_PAL_MASK	equ	BAR_NUM_PAL-1	;and mask

COLOR_NEON_PINK		equ $f09
COLOR_NEON_YELLOW	equ $ee1
COLOR_NEON_PURPLE	equ $70d
COLOR_NEON_GREEN	equ $8f3
COLOR_NEON_ORANGE	equ $f90
COLOR_NEON_RED		equ $f44
COLOR_NEON_BLUE		equ $33f


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

	xdef	GTZ1_Start
GTZ1_Start:
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
	xdef	GTZ1_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
GTZ1_PreCalc_IntroStart:
	tst.w	Controller_Info+CTRL_PRECALC_INTROSTART_DONE
	bne.s	.exit			;already done

	movem.l	d2-d7/a2-a6,-(sp)	;save
	lea	Controller_Info(pc),a5
	
	; Multiply LIB_BOBTABLE_SIZEOF
	lea	Mult_LIB_BOBTABLE_SIZEOF,a0
	move.w	#LIB_BOBTABLE_SIZEOF,d0
	move.w	#128,d1			;128 letters worth is fine
	jsr	FW_PreMultCreate_W

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
	xdef	GTZ1_P0_PreCalc
	endif

SubPart_P0_PreCalc:	
GTZ1_P0_PreCalc:
	movem.l	d2-d7/a2-a6,-(sp)	;save (not d0)
	lea	Controller_Info(pc),a5
	tst.w	CTRL_P0_PRECALC_DONE(a5)
	bne.s	.exit			;already done

	;Change color to show where this starts
	;move.w	#$fff,color00+_custom

	; Create bars
	lea	Bar_Definitions,a3
	lea	Bar_List,a2
	moveq	#NUM_BARS-1,d4
.barinitloop:
	move.l	(a2)+,a0		;Bar ptr
	movem.w	(a3)+,d0-d3		;col,musicmask,sine1/sine2 offset
	bsr	Bar_Init_Bar		;I:d0-d5/a0, T:d0-d1/a0-a1
	dbf	d4,.barinitloop

	;Generate sin table
	bsr	Ripple_Generate_Sine

	;Generate sin table
	bsr	Bar_Generate_Sine

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

	;Alloc font in chip mem and copy
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_FONT8PX_TOTALSIZE
	move.l	#BPL_FONT8PX_TOTALSIZE,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	d0,CTRL_BPL_FONT(a5)		;save allocated address
	lea	BPL_Font8px_Source,a0		;src
	move.l	d0,a1				;destination
	move.w	#BPL_FONT8PX_TOTALSIZE/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

	;Bitplane buffer, use single buffer
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_BUF_TOTALSIZE
	moveq	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_PHYS_PTR(a5)
	move.l	d0,CTRL_BPL_LOG1_PTR(a5)

	;Scroller is single buffer
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_BUF_VSCROLL_TOTALSIZE
	move.l	#BPL_BUF_VSCROLL_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_VSCROLL_PHYS_PTR(a5)	;no double buffer but use log1 for writing
	move.l	d0,CTRL_BPL_VSCROLL_LOG1_PTR(a5)	;to keep convention with other code

	;Font buffer is single buffer
CUR_CHIP_BUF set CUR_CHIP_BUF+BPL_BUF_TEXT_TOTALSIZE
	move.l	#BPL_BUF_TEXT_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CTRL_BPL_TEXT_PHYS_PTR(a5)	;no double buffer but use log1 for writing
	move.l	d0,CTRL_BPL_TEXT_LOG1_PTR(a5)	;to keep convention with other code

	;Allocate bars memory in public
CUR_PUB_BUF set CUR_PUB_BUF+(NUM_BARS*BAR_SIZEOF)
	moveq	#NUM_BARS-1,d2
	lea	Bar_List,a2
.baralloc:
	move.l	#BAR_SIZEOF,d0
	jsr	FW_Mem_Alloc_Public		;I:d0, T:d0-d1/a0-a1
	move.l	d0,(a2)+
	dbf	d2,.baralloc

	;Allocs sine table for barpos
;Bar_Sin_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
;Bar_Cos_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS	
CUR_PUB_BUF set CUR_PUB_BUF+LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4)
	move.l	#LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4),d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_SINETAB_BARPOS_PTR(a5)

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

	clr.w	CTRL_RIPPLE_ACTIVE(a5)

	clr.w	CTRL_TEXT_VSCROLL_DELAY(a5)
	clr.w	CTRL_TEXT_VSCROLL_STATUS(a5)
	clr.w	CTRL_TEXT_FINISHED(a5)
	move.l	#Scroller_Text,CTRL_TEXT_PTR(a5)
	move.w	#VSCROLL_MIN,CTRL_TEXT_VSCROLL(a5)
	move.w	#BPL_BUF_TEXT_HEIGHT,CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER(a5)

	;Start at max fade (dark bars)
	move.w	#BAR_FADE_LEVEL_MAX,CTRL_BAR_FADE_VAL(a5)

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

	;Clear screen bars in CL
	bsr	Bar_Clear_Bars_BLT	;I:a6, T:d0-d1/a0

	addq.w	#1,CTRL_FRAME_COUNT(a5)	;Update local frame count
	jsr	FW_VBlankProxy		;T:d0-d7/a0-a4

	;Skip routine if exiting
	tst.w	CTRL_FINISHED(a5)
	bne	.exit

	; Read new script lines and perform
	bsr	Controller_ReadCommands	;Read new commands
	bsr	Controller_Perform	;Do any ongoing time-based effects and update angles

	; Scroll the text and write a new line if needed
	bsr	Text_Scroll	;I:a5/a6, T:d0-d2/a0

	;Load current palette into CL if needed
	bsr	Copper_Write_Palette	;I:a5, T:d0/a0-a2
	bsr	Copper_Write_Ripple	;I:a5

	; Check if fully started, if not increase bar fade val
	tst.w	CTRL_BAR_FULLY_STARTED(a5)
	bne.s	.checkdone

	subq.w	#1,CTRL_BAR_FADE_COUNT(a5)	;Update fade?
	bpl.s	.checkdone
	move.w	#3,CTRL_BAR_FADE_COUNT(a5)
	subq.w	#1,CTRL_BAR_FADE_VAL(a5)
	bne.s	.checkdone
	move.w	#1,CTRL_BAR_FULLY_STARTED(a5)	;Fade is zero, fully started
	
.checkdone:
;	; Check if scroller has finished
	tst.w	CTRL_TEXT_FINISHED(a5)
	beq.s	.dobars

	; Text finished. Start exiting by fading down the colours
	subq.w	#1,CTRL_BAR_FADE_COUNT(a5)	;Update fade?
	bpl.s	.dobars
	move.w	#3,CTRL_BAR_FADE_COUNT(a5)
	addq.w	#1,CTRL_BAR_FADE_VAL(a5)
	cmpi.w	#BAR_FADE_LEVEL_MAX,CTRL_BAR_FADE_VAL(a5)
	blt.s	.dobars
	move.w	#1,CTRL_FINISHED(a5)	;Exit routine
.dobars:
	bsr	Bar_Animate_Bars	;I:a5, T:d0-d3/a0
	bsr	Bar_Draw_Bars		;T:d0-d7/a0-a2

	;Swap buffers and load copper for next frame
	;Let blitter finish before changing buffers. Important on super-fast machines
	;When using interrupts near end-of-frame.
	WAITBLIT_NASTY_A6
	bsr	P0_ScreenBufferSwap	;I:a5-a6, T:d0-d1/a0
.exit:
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

	;Setup items the same in front/back copper lists then copy the CL

	;Scroller screen is single buffered but is handled in scroll routine as well
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	lea	P0_CL_BPL_PF1_OFFSET(a0),a0		;copper bpl pointer block
	moveq	#BPL_BUF_VSCROLL_NUMPLANES,d0
	move.l	CTRL_BPL_VSCROLL_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_VSCROLL_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo
	
	;Background screen is single buffered
	move.l	CTRL_CL_PHYS_PTR(a5),a0
	lea	P0_CL_BPL_PF2_OFFSET(a0),a0		;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	CTRL_BPL_PHYS_PTR(a5),d1	;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2
	jsr	FW_InitCopperBplPtrs		;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo

	;Setup CL buffers and ptrs
	ifgt P0_CL_NUM_BUFFERS-1
		; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
		move.l	CTRL_CL_PHYS_PTR(a5),a0
		move.l	CTRL_CL_LOG1_PTR(a5),a1

		move.w	#(P0_CL_SIZE/2),d0	;size in words
		jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2	
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

	;If single CL buffer then don't swap the ptrs and leave cop1lch alone
	ifgt P0_CL_NUM_BUFFERS-1
		;Double buffered CL, just swap pointer
		lea	CTRL_CL_PHYS_PTR(a5),a0
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
* Clears all the buffers we will use. Done once at startup to ensure clean
* environment. Uses CPU for precalc routine.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Clear_ScreenBuffers_CPU:
	movem.l	d2-d7/a2-a6,-(sp)

	;Background buffers
	move.l	CTRL_BPL_PHYS_PTR(a5),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	;Same buffer
	;move.l	CTRL_BPL_LOG1_PTR(a5),a0
	;move.w	#(BPL_BUF_TOTALSIZE/2),d0
	;jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	;Scroller buffer
	move.l	CTRL_BPL_VSCROLL_PHYS_PTR(a5),a0
	move.w	#(BPL_BUF_VSCROLL_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6
	rts


*****************************************************************************
* Generate sine values between -16 and 16. Genrates an extra 256 words
* so can use for sine and cosine.
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Ripple_Generate_Sine:
	movem.l	d2-d3,-(sp)

	;move.l	CTRL_SINETAB_RIPPLE_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

;Note need to be a little careful when shifting right to change range as -16383 >> 1 = -8192
;so ranges change as follows when shifting right
;-8192 to 8191 etc
;-4096 to 4095
;If rounding with addx means this becomes:
;-8191 to 8192

	;change range from -16384 to 16383 to 0 to 256
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
	move.w	d3,(a1)+
	dbf	d1,.cl

	movem.l	(sp)+,d2-d3
	rts


*****************************************************************************
* Generate sine values between 0 and 256. Genrates an extra 256 words
* so can use for sine and cosine.
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Bar_Generate_Sine:
	movem.l	d2-d3,-(sp)

	;move.l	CTRL_SINETAB_BARPOS_PTR(a5),a0
	;jsr	LIB_GenSin_16384_2048W

;Note need to be a little careful when shifting right to change range as -16383 >> 1 = -8192
;so ranges change as follows when shifting right
;-8192 to 8191 etc
;-4096 to 4095
;If rounding with addx means this becomes:
;-8191 to 8192

	;change range from -16384 to 16384 to 0 to 256
.changerange:
	lea	GenSin_Table_16384_2048W,a0
	move.l	CTRL_SINETAB_BARPOS_PTR(a5),a1
	move.w	#128,d0
	move.w	#(LIB_GENSIN_16384_2048W_NUMWORDS+(LIB_GENSIN_16384_2048W_NUMWORDS/4))-1,d1
	moveq	#0,d2
.cl:
	move.w	(a0)+,d3	
	asr.w	#7,d3			;change range to -128 to 128
	addx.w	d2,d3			;round up
	add.w	d0,d3			;0-256
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
	move.w	(a4)+,d0		;Speed
	move.l	(a4)+,a0		;New pallete
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

.fx_ripple:
	move.w	(a4)+,d0		;enable/disable
	pea	.loop(pc)
	bra	Controller_FX_Ripple

	
*****************************************************************************
* Performs any time-based controller routines.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a2-a4
*****************************************************************************

Controller_Perform:
	;Note that routines are called in reverse order to avoid lots of jumping around
	pea	Controller_FX_Ripple_Perform

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

	;Is there a musicsyncmaskwait in progress that we can release?
	move.w	CTRL_MUSICSYNCMASKWAIT(a5),d1
	move.w	d0,d2
	and.w	d1,d2
	cmp.w	d1,d2
	bne.s	.nowait
	clr.w	CTRL_MUSICSYNCMASKWAIT(a5)	;wait is over
.nowait:

	;And with our mask, this gives our script the option to mask events
	;if needed without having to be complicated with other code
	and.w	CTRL_MUSICSYNCMASK(a5),d0
	move.w	d0,CTRL_MUSICSYNC(a5)

	;DO OTHER THINGS HERE
.exit:	
	rts
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

	lea	CTRL_SINE1(a5),a0
	bsr.s	.checksine
	lea	CTRL_BAR1_SINE1(a5),a0
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
* Ripple. 
* IN:		a5, vec controller info
* 		d0.w, enable/disable 1/0
* OUT:		
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

Controller_FX_Ripple:
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

	moveq	#0,d6			;num visible lines
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d3
	move.w	#RIPPLE_TABLE_NUMWORDS-1,d7
	move.w	(a0,d4.w),d0		;Do first iteration outside loop 
	bra.s	.show			;always show first line
.l0:	
	move.w	(a0,d4.w),d0		;-16 to 16
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
	;addq.w	#2,d6			;rept lines counts as 2
	bra.s	.write
.skip:	
	move.w	d0,d1
	;subq.w	#1,d6			;no visble line
	moveq	#-1,d0

.write:
	move.w	d0,(a1)+		;save value

	add.w	a2,d4			;Sine1 offset+=step
	and.w	d3,d4			;Ensure in range
	;add.w	a3,d5			;Sine1 offset+=step
	;and.w	d3,d5			;Ensure in range

	dbf	d7,.l0

	;Write number of visible lines
	;subq.w	#1,d6
	move.w	#BPL_BUF_HEIGHT-1,CTRL_RIPPLE_VISIBLE_LINES(a5)

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

Copper_Write_Ripple:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_RIPPLE_LOAD_FLAG(a5)
	beq	.exit
	subq.w	#1,CTRL_RIPPLE_LOAD_FLAG(a5)

	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_PATTERN_OFFSET+CL_PATTERN_BPLCON0+2(a0),a1
	move.w	#CL_PATTERN_SIZEOF,a2
	lea	Ripple_Table,a3

	move.w	#BPL_BUF_HEIGHT-1,d4
	move.w	#BPL_VSCROLL_BPLMOD_REPTLINE,d0
	move.w	#BPL_VSCROLL_BPLMOD,d1
	move.w	#BPL_VSCROLL_BPLMOD_SKIPLINE,d2
	move.w	#ZOOM_BPLCON0_ON,d3
	move.w	CTRL_RIPPLE_VISIBLE_LINES(a5),d5
	;move.w	d1,d0
	;move.w	d1,d2
	;move.w	#ZOOM_BPLCON0_ON,d0
.clearloop:
	;move.w	d0,(a1)			;bplcon0 (zoom routine may have changed)

	tst.w	(a3)+
	;bra.s	.show
	beq.s	.show
	bmi.s	.skip
.rept:
	move.w	d3,(a1)			;bplcon0
	move.w	d0,4(a1)		;bpl1mod
	;move.w	d0,8(a1)		;bpl2mod
	bra.s	.next
.show:
	move.w	d3,(a1)			;bplcon0
	move.w	d1,4(a1)
	;move.w	d1,8(a1)
	bra.s	.next
.skip:
	move.w	d3,(a1)			;bplcon0
	move.w	d2,4(a1)
	;move.w	d2,8(a1)
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


****************************************************************************
* Changes the scroll position of the text. And draws new text if needed
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	None
*****************************************************************************

Text_Scroll:
	;Scroll text?
	subq.w	#1,CTRL_TEXT_VSCROLL_DELAY(a5)
	bpl.s	.updatecopper		;Even if skipping, because double buffered
	move.w	#1,CTRL_TEXT_VSCROLL_DELAY(a5)

	move.w	CTRL_TEXT_VSCROLL(a5),d0

	addq.w	#1,d0
	cmp.w	#VSCROLL_MAX,d0
	blt.s	.vscrollok
	move.w	#VSCROLL_MIN,d0
.vscrollok:
	move.w	d0,CTRL_TEXT_VSCROLL(a5)

	;Time to draw text (line spacing counter)?
	subq.w	#1,CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER(a5)

.updatecopper:
	move.w	CTRL_TEXT_VSCROLL(a5),d0
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_BPL_PF1_OFFSET+2(a0),a0	;copper bpl pointer block	

	mulu	#BPL_BUF_VSCROLL_BYTEWIDTH*BPL_BUF_VSCROLL_NUMPLANES,d0
	add.l	CTRL_BPL_VSCROLL_LOG1_PTR(a5),d0

	moveq	#BPL_BUF_VSCROLL_BYTEWIDTH,d1
	moveq	#BPL_BUF_VSCROLL_NUMPLANES-1,d2
.l:	
	swap	d0			;Swap high & low words
	move.w	d0,(a0)			;High ptr
	swap	d0			;Swap high & low words
	move.w	d0,4(a0)		;Low ptr
	addq.l	#8,a0			;Next set of ptrs
	add.l	d1,d0			;Next bitplane
	dbf	d2,.l

	
	;Check current status for what to do with text
	;0=clear,1=draw,2=wait
	move.w	CTRL_TEXT_VSCROLL_STATUS(a5),d0
	beq.s	.clear
	cmp.w	#1,d0
	beq.s	.draw
	
	;fallthrough - wait until ready to copy line to screen
	tst.w	CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER(a5)
	ble.s	.copy

	;Have to clear a line as we allowing variable Y spacing
	bsr	Text_Draw_ClearLine

	rts

.clear:	
	;Have to clear a line as we allowing variable Y spacing
	bsr	Text_Draw_ClearLine
	bra	Text_Draw_ClearBuffer	;Clear font buffer
	;rts
.draw:
	;Have to clear a line as we allowing variable Y spacing
	bsr	Text_Draw_ClearLine
	bra	Text_Draw_BlitChars	;Blit a number of chars to current line
	rts
.copy:
	;reset line counter
	;move.w	#BPL_BUF_TEXT_HEIGHT,CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER(a5)
	move.w	#VSCROLL_Y_SPACING,CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER(a5)

	bra	Text_Draw_CopyBuffer	;Copy font buffer to screen
	;rts


****************************************************************************
* Clears the font draw buffer, and gets ready to draw new chars.
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0/a2/a3
*****************************************************************************

Text_Draw_ClearBuffer:
	;Clear the text draw area
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	CTRL_BPL_TEXT_LOG1_PTR(a5),bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((BPL_BUF_TEXT_HEIGHT*BPL_BUF_VSCROLL_NUMPLANES)*64)+BPL_BUF_VSCROLL_WORDWIDTH,bltsize(a6)

	;Work out number of chars and centering start X
	bsr	Text_Calc_Line_Details	;T:d0-d1/a0-a4

	addq.w	#1,CTRL_TEXT_VSCROLL_STATUS(a5)	;next stage is draw letters
	rts


****************************************************************************
* Copies the font buffer to the screen in two places for scrolling.
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0/a2/a3
*****************************************************************************

Text_Draw_CopyBuffer:

	;Source is easy, our font buffer
	move.l	CTRL_BPL_TEXT_LOG1_PTR(a5),a0

	;Top draw area
	move.w	CTRL_TEXT_VSCROLL(a5),d0
	sub.w	#BPL_BUF_TEXT_HEIGHT,d0
	mulu	#BPL_BUF_VSCROLL_MOD_LINE,d0
	move.l	CTRL_BPL_VSCROLL_LOG1_PTR(a5),a1
	add.l	d0,a1

	;Copy the text draw area
	WAITBLIT_NASTY_A6
	move.l	#$09f00000,bltcon0(a6)
	move.l	#-1,bltafwm(a6)	
	move.l	#0,bltamod(a6)		;A/DMOD
	move.l	a0,bltapth(a6)		;Font buffer
	move.l	a1,bltdpth(a6)		;Screen
	move.w	#((BPL_BUF_TEXT_HEIGHT*BPL_BUF_VSCROLL_NUMPLANES)*64)+BPL_BUF_VSCROLL_WORDWIDTH,bltsize(a6)

	;Also copy the text drawn to CTRL_TEXT_VSCROLL+BPL_BUF_HEIGHT as well, remember we subbed
	;BPL_BUF_TEXT_HEIGHT above so have to fix that with + BPL_BUF_TEXT_HEIGHT here
	lea	(BPL_BUF_HEIGHT+BPL_BUF_TEXT_HEIGHT)*BPL_BUF_VSCROLL_MOD_LINE(a1),a1
	WAITBLIT_NASTY_A6
	;move.l	#$09f00000,bltcon0(a6)
	;move.l	#-1,bltafwm(a6)	
	;move.l	#0,bltamod(a6)		;A/DMOD
	move.l	a0,bltapth(a6)		;Font buffer
	move.l	a1,bltdpth(a6)		;Screen
	move.w	#((BPL_BUF_TEXT_HEIGHT*BPL_BUF_VSCROLL_NUMPLANES)*64)+BPL_BUF_VSCROLL_WORDWIDTH,bltsize(a6)

	clr.w	CTRL_TEXT_VSCROLL_STATUS(a5)	;reset stage to clear
	rts


****************************************************************************
* Clears a single line so that we can do variable Y spacing much larger than font
* buffer. Must be done each frame unless running Text_Draw_CopyBuffer
* IN:		a6, custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0/a2/a3
*****************************************************************************

Text_Draw_ClearLine:
	;Top draw area
	move.w	CTRL_TEXT_VSCROLL(a5),d0
	;sub.w	#BPL_BUF_TEXT_HEIGHT,d0
	;Clearing just the LAST line in BPL_BUF_TEXT_HEIGHT buf just above top of visible
	subq.w	#1,d0	
	mulu	#BPL_BUF_VSCROLL_MOD_LINE,d0
	move.l	CTRL_BPL_VSCROLL_LOG1_PTR(a5),a0
	add.l	d0,a0

	;Clear the text draw area
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	move.w	#0,bltdmod(a6)
	move.w	#((1*BPL_BUF_VSCROLL_NUMPLANES)*64)+BPL_BUF_VSCROLL_WORDWIDTH,bltsize(a6)

	;Clear last line of bottom draw area. Last line of buffer is BPL_BUF_TEXT_HEIGHT-1
	;-1 above so have to fix that with +1 here. 
	;+1 +BPL_BUF_TEXT_HEIGHT -1 = BPL_BUF_TEXT_HEIGHT
	lea	(BPL_BUF_HEIGHT+BPL_BUF_TEXT_HEIGHT)*BPL_BUF_VSCROLL_MOD_LINE(a0),a0
	WAITBLIT_NASTY_A6
	;move.l	#$01000000,bltcon0(a6)
	move.l	a0,bltdpth(a6)
	;move.w	#0,bltdmod(a6)
	move.w	#((1*BPL_BUF_VSCROLL_NUMPLANES)*64)+BPL_BUF_VSCROLL_WORDWIDTH,bltsize(a6)

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
	tst.w	CTRL_TEXT_FINISHED(a5)
	beq.s	.notfinished
	rts
.notfinished:

	moveq	#VSCROLL_MAX_CHARS_PER_FRAME,d7

	move.l	CTRL_TEXT_PTR(a5),a4
	move.b	(a4)+,d2		;Get first letter of line or null or lf
	bne.s	.notnull		;End of scroller
	
	lea	Scroller_Text,a4
	move.w	#1,CTRL_TEXT_FINISHED(a5)
	bra.s	.endline		;Copy blank line cleared aboive

.notnull:

	move.w	CTRL_TEXT_X(a5),d4	;Current X
.letterloop:
	cmp.b	#10,d2			;linefeed?
	beq.s	.endline
	cmp.b	#32,d2			;Space?
	bne.s	.notspace
	addq.w	#FONT8PX_SPACE_WIDTH,d4
	bra.s	.nextletter		;Done for this letter
.notspace:

	cmp.w	#FONT8PX_MAX_X,d4
	bgt.s	.nextletter

.drawletter:
	subq.w	#1,d7			;Another blitted char
	move.w	d4,d0			;Current x
	;moveq	#0,d1			;Y is always 0
	move.l	CTRL_BPL_TEXT_LOG1_PTR(a5),a0
	bsr	Text_Blit_Letter	;I:a0/a6, O:d0, T:d0-d3/a0/a2/a3
	add.w	d0,d4			;next X based on previous letter

.nextletter:
	tst.w	d7
	beq.s	.exit			;Save pointer and rerun next frame

	move.b	(a4)+,d2		;Next letter
	bra.s	.letterloop

.endline:
	move.w	#2,CTRL_TEXT_VSCROLL_STATUS(a5)	;next stage is wait
.exit:
	move.l	a4,CTRL_TEXT_PTR(a5)	;Save pointer for next time
	move.w	d4,CTRL_TEXT_X(a5)	;Save current X

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
	tst.w	CTRL_TEXT_FINISHED(a5)
	beq.s	.notfinished
	rts
.notfinished:

	lea	Mult_LIB_BOBTABLE_SIZEOF,a1	;premult
	lea	FAR_Font8px,a2		;char to bob number
	lea	BOB_Font8px,a3		;bob number to bpl

	move.l	CTRL_TEXT_PTR(a5),a0
	move.b	(a0)+,d0		;Get first letter of line or null
	bne.s	.new			;End of scroller?

	clr.w	CTRL_TEXT_X(a5)
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

	;mulu	#LIB_BOBTABLE_SIZEOF,d0
	add.w	d0,d0			;bob num to word offset
	move.w	(a1,d0.w),d0		;LIB_BOBTABLE_SIZEOF*bob num
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
	move.w	#BPL_BUF_VSCROLL_WIDTH/2,d0
	sub.w	d1,d0
	move.w	d0,CTRL_TEXT_X(a5)	;Store starting X

	rts


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
* OUT:		
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
	;Removed as Y always 0
	;mulu	#BPL_BUF_VSCROLL_BYTEWIDTH*BPL_BUF_VSCROLL_NUMPLANES,d1
	;add.l	d1,a0

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
		moveq	#BPL_BUF_VSCROLL_BYTEWIDTH,d2	;ensure top of d2 is 0
		sub.w	d3,d2		;modulo
	ELSE
		move.w	#FONT8PX_BLTSIZE+1,d1		;same for all bobs (mono font)
		moveq	#BPL_BUF_VSCROLL_BYTEWIDTH-(FONT8PX_BLT_BYTEWIDTH+2),d2	;modulo (top of d2 is 0)
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
* Intialises a bar..
* IN:		a0, bar address
*		a5, Controller_Info
*		d0, colour
*		d1, pos
*		d2, vel
*		d3, music mask
*		d4, sine offset 1
*		d5, sine offset 1
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Bar_Init_Bar:
	movem.l	d2-d7/a2-a6,-(sp)
	move.w	d0,BAR_COL(a0)
	move.w	d1,BAR_MUSICSYNCMASK(a0)
	move.w	d2,BAR_SINE1_OFFSET(a0)
	move.w	d3,BAR_SINE2_OFFSET(a0)
	move.w	#BAR_FADE_LEVEL_MAX,BAR_FADE_LEVEL(a0)	;darkest
	clr.w	BAR_POS(a0)		;set by sine wave
	clr.w	BAR_COUNTER(a0)
	bsr	Bar_Create_Bar_Palette	;I:a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6
	rts


*****************************************************************************
* Clears the bar at given position (rather than clearing whole list)
* IN:		a0, bar address
** OUT:		
* TRASHED:	d0-d2/a0
*****************************************************************************

Bar_Clear_Bars_BLT:
;	move.l	CL_Log1_Ptr(pc),a0
;	lea	P0_CL_BAR_OFFSET+CL_BAR_CMOVE_COL+2(a0),a0	;Ptr to first COLOR value
;	moveq	#CL_PATTERN_SIZEOF,d1
;	moveq	#0,d2
;	move.w	#BPL_BUF_HEIGHT-1,d0
;.loop:
;	move.w	d2,(a0)
;	add.w	d1,a0
;	dbf	d0,.loop

	;For blit clear we are just clearing a single word (the color00 value)
	;and then using bltdmod to skip to next line
	move.l	CTRL_CL_LOG1_PTR(a5),a0
	lea	P0_CL_PATTERN_OFFSET+CL_BAR_CMOVE_COL+2(a0),a0	;Ptr to first COLOR value

	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)
	move.w	#CL_PATTERN_SIZEOF-2,bltdmod(a6)
	move.l	a0,bltdpth(a6)
	move.w	#(BPL_HEIGHT*64)+1,bltsize(a6)		;single word per line clear

	rts


*****************************************************************************
* Draws a bar at given position.
* IN:
* OUT:		
* TRASHED:	d0-d7/a1-a2
*****************************************************************************

Bar_Draw_Bars:
	lea	Bar_List,a3

	WAITBLIT_NASTY_A6		;Let bar clear finish

	;Draw first bar with less checks as screen is already black
	bsr	Bar_Draw_First_Bar		;T:d0-d5/a0-a2

	;draw the remaining bars (one less bar)
	moveq	#NUM_BARS-1-1,d7
.barloop:
	move.l	(a3)+,a0
	bsr	Bar_Draw_Bar		;T:d0-d5/a0-a2
	dbf	d7,.barloop
	rts


*****************************************************************************
* Draws a bar at given position.
* IN:		a0, bar address
* OUT:		
* TRASHED:	d0-d6/a1-a2
*****************************************************************************

Bar_Draw_First_Bar:
	; Get a pointer to the current palette
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_PATTERN_OFFSET+CL_BAR_CMOVE_COL+2(a1),a1	;Ptr to 1st COLOR value
	move.w	BAR_POS(a0),d0
	lea	BAR_PAL(a0),a2		;source palette
	moveq	#BAR_HEIGHT,d6

	;Check min and may values
	sub.w	#BAR_HEIGHT/2,d0	;Pos is the centre of bar
	bpl.s	.minyok
	add.w	d0,d6			;Subtract overflow from height
	neg.w	d0			;Have to skip this many bar entries
	add.w	d0,d0			;pal entries in words
	add.w	d0,a2
	moveq	#0,d0			;Start at CL pos 0
	bra.s	.draw			;No more checks needed
.minyok:
	move.w	d0,d1
	moveq	#BAR_HEIGHT,d2
	add.w	d2,d1			;Y+barheight
	sub.w	#BPL_HEIGHT-1,d1	;Check if overrun
	bmi.s	.maxyok
	sub.w	d1,d2			;How many entries to cut from end?
	sub.w	d1,d6
.maxyok:

	;For this bar position find the correct starting place in CL
	mulu	#CL_PATTERN_SIZEOF,d0
	add.l	d0,a1		
.draw:
	;If flicker on then force half brightness to simulate a flicker
	move.w	BAR_FADE_LEVEL(a0),d0	;level
	tst.w	BAR_FLICKER(a0)
	beq.s	.getpalette
	addq.w	#2,d0			;increase fade by 2
	cmp.w	#BAR_FADE_LEVEL_MAX,d0
	ble.s	.getpalette
	move.w	#BAR_FADE_LEVEL_MAX,d0
.getpalette:
	mulu	#BAR_PAL_SIZEOF,d0
	add.l	d0,a2			;Find palette for this level

	;We can blit this straight into the CL, d6 is number of lines to blit
	;Note: removed as it requires bars to be in chipmem at ~55KB
;	lsl.w	#6,d6			;*64
;	addq.w	#1,d6			;+1 word, d6 is bltsize
;	WAITBLIT_NASTY_A6
;	move.l	#$09f00000,bltcon0(a6)
;	move.l	#-1,bltafwm(a6)	
;	move.w	#0,bltamod(a6)		;no mod
;	move.w	#CL_PATTERN_SIZEOF-2,bltdmod(a6)
;	move.l	a2,bltapth(a6)		;bar colors
;	move.l	a1,bltdpth(a6)		;cl
;	move.w	d6,bltsize(a6)
;	rts

	subq.w	#1,d6			;-1 for dbf
	bmi.s	.exit
.line:
	move.w	(a2)+,(a1)		;Bar colour straight into CL
	lea	CL_PATTERN_SIZEOF(a1),a1	;next line
	dbf	d6,.line
.exit:
	rts


*****************************************************************************
* Draws a bar at given position.
* IN:		a0, bar address
* OUT:		
* TRASHED:	d0-d6/a1-a2
*****************************************************************************

Bar_Draw_Bar:
	; Get a pointer to the current palette
	move.l	CTRL_CL_LOG1_PTR(a5),a1
	lea	P0_CL_PATTERN_OFFSET+CL_BAR_CMOVE_COL+2(a1),a1	;Ptr to 1st COLOR value
	move.w	BAR_POS(a0),d0
	lea	BAR_PAL(a0),a2		;source palette
	moveq	#BAR_HEIGHT,d6

	;Check min and may values
	sub.w	#BAR_HEIGHT/2,d0	;Pos is the centre of bar
	bpl.s	.minyok
	add.w	d0,d6			;Subtract overflow from height
	neg.w	d0			;Have to skip this many bar entries
	add.w	d0,d0			;pal entries in words
	add.w	d0,a2
	moveq	#0,d0			;Start at CL pos 0
	bra.s	.draw			;No more checks needed
.minyok:
	move.w	d0,d1
	moveq	#BAR_HEIGHT,d2
	add.w	d2,d1			;Y+barheight
	sub.w	#BPL_HEIGHT-1,d1	;Check if overrun
	bmi.s	.maxyok
	sub.w	d1,d2			;How many entries to cut from end?
	sub.w	d1,d6
.maxyok:

	;For this bar position find the correct starting place in CL
	mulu	#CL_PATTERN_SIZEOF,d0
	add.l	d0,a1		
.draw:
	;If flicker on then force half brightness to simulate a flicker
	move.w	BAR_FADE_LEVEL(a0),d0	;level
	tst.w	BAR_FLICKER(a0)
	beq.s	.getpalette
	addq.w	#1,d0			;increase fade by 4
	cmp.w	#BAR_FADE_LEVEL_MAX,d0
	ble.s	.getpalette
	move.w	#BAR_FADE_LEVEL_MAX,d0
.getpalette:
	mulu	#BAR_PAL_SIZEOF,d0
	add.l	d0,a2			;Find palette for this level

	subq.w	#1,d6			;-1 for dbf
	bmi.s	.exit
.line:
	move.w	(a2)+,d0		;Bar colour
	beq.s	.nextloop		;No calc needed
	move.w	(a1),d1			;Screen colour
	bne.s	.notblack
	move.w	d0,(a1)			;Store new colour
	bra.s	.nextloop
.notblack:
	RGB12_ADD			;I:d0-d1, O:d0, T:d0-d5

	move.w	d0,(a1)			;Store new colour
.nextloop:	
	lea	CL_PATTERN_SIZEOF(a1),a1	;next line
	dbf	d6,.line
.exit:
	rts


*****************************************************************************
* Updates the animation and level for all bars.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0
*****************************************************************************

Bar_Animate_Bars:
	moveq	#NUM_BARS-1,d7
	lea	Bar_List,a4
.barloop:
	move.l	(a4)+,a0
	bsr	Bar_Animate		;I:a0/a5, T:d0-d2/a0
	dbf	d7,.barloop

	rts


*****************************************************************************
* Sets the bar level and moves position.
* IN:		a0, bar address
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0-a1
*****************************************************************************

Bar_Animate:
	move.w	#LIB_GENSIN_16384_2048W_OFFSET_MASK,d2

	move.w	BAR_SINE1_OFFSET(a0),a1		;get sine structure offset
	lea	(a5,a1.w),a1			;Get offset from Controller_Info
	move.w	CTRL_SINE_OFFSET(a1),d0		;Offset in words
	add.w	CTRL_SINE_SPEED(a1),d0		;Get speed (movement per frame)
	and.w	d2,d0	;Ensure in range
	move.w	d0,CTRL_SINE_OFFSET(a1)	;Save for next frame

	move.w	BAR_SINE2_OFFSET(a0),a1		;get sine structure offset
	lea	(a5,a1.w),a1			;Get offset from Controller_Info
	move.w	CTRL_SINE_OFFSET(a1),d1	;Offset in words
	add.w	CTRL_SINE_SPEED(a1),d1		;Get speed (movement per frame)
	and.w	d2,d1	;Ensure in range
	move.w	d1,CTRL_SINE_OFFSET(a1)	;Save for next frame

	move.l	CTRL_SINETAB_BARPOS_PTR(a5),a1
	move.w	(a1,d0.w),d0		;Get actual value
	add.w	(a1,d1.w),d0
	asr.w	#1,d0
	move.w	d0,BAR_POS(a0)	;save new pos

	;Animate new flashes in time with music
	move.w	CTRL_MUSICSYNC(a5),d0
	move.w	BAR_MUSICSYNCMASK(a0),d1
	and.w	d1,d0
	cmp.w	d1,d0
	bne.s	.checkflicker

	;Set bar to max current brightness on music sync
	move.w	CTRL_BAR_FADE_VAL(a5),BAR_FADE_LEVEL(a0)
	move.w	#BAR_FADE_SPEED,BAR_COUNTER(a0)
	clr.w	BAR_FLICKER(a0)
	rts

.checkflicker:
	;If currently set to flicker mode, turn it off
	tst.w	BAR_FLICKER(a0)
	beq.s	.randomflicker
	clr.w	BAR_FLICKER(a0)
.randomflicker:
	movem.l	.seed(pc),d1-d2
	move.l	d2,d3
	swap	d3
	add.l	d1,d2
	add.l	d3,d1
	movem.l	d1-d2,.seed
	cmp.w	#32767,d3		;65536/32767 chance of flicker
	bhi.s	.fade
	move.w	#1,BAR_FLICKER(a0)
.fade:
	move.w	BAR_COUNTER(a0),d0
	bgt.s	.dec

	move.w	#BAR_FADE_SPEED,BAR_COUNTER(a0)	;Quickness of fade
	move.w	BAR_FADE_LEVEL(a0),d1
	moveq	#BAR_FADE_LEVEL_MAX,d2
	cmp.w	d2,d1
	bge.s	.alreadydark
	addq.w	#1,d1			;increase fade
	cmp.w	d2,d1
	ble.s	.storelevel
	move.w	d2,d1
.storelevel:
	move.w	d1,BAR_FADE_LEVEL(a0)
.alreadydark:
	rts
.dec:
	subq.w	#1,d0			;update counter
	move.w	d0,BAR_COUNTER(a0)
	rts

.seed:	
	dc.l	$3E50B28C,$D461A7F9


*****************************************************************************
* Sets up the palette for a bar based on its brightness
* IN:		a0, bar address
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

;Pal_Mapping defines the colours of a bar from 15 to -15
;Take the base color, if fade level is +ve then this represents a fade 
;step to black. So 14 is almost completely black
;A negative value is a fade level to white. -14 is step 14 to white.
;0 is the base colour

; We then have a global fade level from 0 to 15 (black) so
; we create 16 versions of the palette from 0 (no fade) to
; 15 (black) we can then quickly take a bars current fade level
; and the palette.

	ifne 0
Bar_Create_Bar_Palette2:
	move.l	a0,-(sp)
	; Get a pointer to the current palette
	lea	BAR_PAL(a0),a1	;initial palette
	lea	PAL_Mapping,a2
	move.w	BAR_COL(a0),d5	;base colour
	moveq	#BAR_HEIGHT-1,d6
.bar:
	move.w	d5,d0			;source col
	move.w	(a2)+,d2		;step
	bpl.s	.positive
	neg.w	d2			;ASSERT: d2<=15
	move.w	#$fff,d1			;dest col is white
	jsr	LIB_RGB12_Interpolate_Fast	;trashes d0-d4
	bra.s	.store1
.positive:				;d0 is base colour or lightened base colour
	moveq	#0,d1			;dest col is black
	jsr	LIB_RGB12_Interpolate_Fast	;trashes d0-d4/a0
.store1:
	move.w	d0,(a1)+
	dbf	d6,.bar


	;a1 is pointer to next palette
	;We've just createed fade level 0 verion of the palette
	;Now we create BAR_NUM_FADE_LEVELS-1 more from 1-15

	moveq	#BAR_NUM_FADE_LEVELS-1-1,d7
	moveq	#1,d6			;Done step 0, start at 1
.fadepal:
	move.l	(sp),a0
	lea	BAR_PAL(a0),a2	;source palette
	moveq	#BAR_HEIGHT-1,d5
.fadebar:
	move.w	(a2)+,d0
	move.w	#0,d1			;dest col is black
	move.w	d6,d2			;current step
	jsr	LIB_RGB12_Interpolate_Fast	;trashes d0-d4
	move.w	d0,(a1)+		;Save new colour

	dbf	d5,.fadebar

	addq.w	#1,d6
	dbf	d7,.fadepal

	move.l	(sp)+,a0
	rts
	endif


Bar_Create_Bar_Palette:
	;clear down the cache
	lea	Bar_Palette_Cache,a4
	move.l	a4,a3
	moveq	#BAR_NUM_FADE_LEVELS-1,d1
	moveq	#-1,d0			;-1 is "no cached" value
.clearcache:
	move.w	d0,(a3)+
	dbf	d1,.clearcache	

	; Get a pointer to the current palette
	lea	BAR_PAL(a0),a1		;initial palette
	moveq	#0,d7			;starting step, 0-14
	move.w	BAR_COL(a0),d5		;base colour
.palette:
	moveq	#BAR_HEIGHT-1,d6
	lea	PAL_Mapping,a2
.loop
	move.w	d5,d0			;source col
	move.w	(a2)+,d2		;step -15 to 15
	add.w	d7,d2			;increase darkness by global step
	moveq	#15,d3
	cmp.w	d3,d2			;keep in range -15 to 15
	ble.s	.stepok
	move.w	d3,d2			;set to max
.stepok:
	move.w	d2,d3
	add.w	d3,d3			;cache access in words
	lea	((BAR_NUM_FADE_LEVELS/2)*2)(a4,d3.w),a3	;still in -15 to 15 range
	move.w	(a3),d3			;a3 is cache entry
	bmi.s	.calc	
	move.w	d3,d0
	bra.s	.store
.calc:
	tst.w	d2
	bpl.s	.darken
	neg.w	d2			;ASSERT: d2<=15
	move.w	#$fff,d1			;dest col is white
	jsr	LIB_RGB12_Interpolate_Fast	;T:d0-d4/a0
	move.w	d0,(a3)			;Store value in cache
	bra.s	.store
.darken:				;d0 is base colour or lightened base colour
	moveq	#0,d1			;dest col is black
	jsr	LIB_RGB12_Interpolate_Fast	;T:d0-d4/a0
	move.w	d0,(a3)			;Store value in cache
.store:	
	move.w	d0,(a1)+
	dbf	d6,.loop

	addq.w	#1,d7			;next step
	cmpi.w	#BAR_FADE_LEVEL_MAX,d7	;Fade levels 0-15
	ble.s	.palette

	rts


*****************************************************************************
*****************************************************************************
*****************************************************************************


	;Include additional public data
	include "SectionData_PublicData.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	;Include additional chip data
	include "SectionData_ChipData.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************
