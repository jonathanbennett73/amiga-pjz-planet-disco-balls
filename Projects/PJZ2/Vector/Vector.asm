*****************************************************************************

; Name			: Vector.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Basic vector routines.
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
P0_DIW_V		equ	$2c+16		;Hardware Vstart ($2c normal, $24 overscan)
P0_DIW_H		equ	$81+32		;Hardware Hstart ($81 normal, $71 overscan)
P0_DIW_WIDTH		equ	320		;Pixels		 (multiple of 16, 320 normal, 352 overscan)
P0_DIW_HEIGHT		equ	256-32		;Lines		 (256 normal PAL, 272 overscan)

P0_DDF_H		equ	$81+32		;Hardware Hstart ($81 normal, $71 overscan)
P0_DDF_WIDTH		equ	320-32-32		;Pixels		 (320 normal pal, 352 overscan)
P0_DDF_BYTEWIDTH	equ	P0_DDF_WIDTH/8
P0_DDF_WORDWIDTH	equ	P0_DDF_BYTEWIDTH/2

P0_SCANLINE_EOF		equ	(P0_DIW_V+P0_DIW_HEIGHT)-32	; Safe to starting clearing after this scanline
						; 0 is essentially vblank

; This value is used for loading the CL with colours and stuff, we might need
; to do it more than once, for example fading colours in a double-buffered CL
; we need to write the values twice so that after finishing both CLs have been updated
; Set to 1 for single CL, 2 for double-buffered, etc
P0_CL_NUM_BUFFERS	equ	2

*****************************************************************************

*** Screen Definitions ***

;The visible screen area and back buffer
BPL_BUF_WIDTH		equ	320-32-32
BPL_BUF_BYTEWIDTH	equ	BPL_BUF_WIDTH/8
BPL_BUF_WORDWIDTH	equ	BPL_BUF_BYTEWIDTH/2
BPL_BUF_HEIGHT		equ	256-32			;Lines (1 extra line to go into reflection)
BPL_BUF_NUMPLANES	equ	4			;FILL ROUTINE RESTRICTED TO 3BPL or less
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

; Vertical scanline to start the reflection
DIW_V_REFLECTION	equ	P0_DIW_V+BPL_BUF_HEIGHT

VEC_HORIZ_SCROLL_NUMLINES = DIW_V_REFLECTION-P0_DIW_V-1
VEC_HORIZ_SCROLL_REFL_NUMLINES = (P0_DIW_V+P0_DIW_HEIGHT)-DIW_V_REFLECTION

*****************************************************************************

PERFORM_ENABLE_MUSICSYNC	equ	1
PERFORM_ENABLE_SINESET		equ	0
PERFORM_ENABLE_USERVALWAIT	equ	0
PERFORM_ENABLE_HORIZSCROLL	equ	0

*****************************************************************************

PAL_NUMCOLS_MAIN	equ	16		; number of main colour entries in our palettes
PAL_NUMCOLS_DARK	equ	0		; number of dark/refl cols
PAL_NUMCOLS_ALL		equ	(PAL_NUMCOLS_MAIN+PAL_NUMCOLS_DARK)

*****************************************************************************

VEC_Q14_GENSIN		equ	1		;1 for generating sin, 0 for use lib tables

VEC_XOFFSET		equ	BPL_BUF_WIDTH/2
VEC_YOFFSET		equ	BPL_BUF_HEIGHT/2
VEC_PERS_K_SHIFT	equ	8			;Shift for PERS_K. 8 (256) looks good, 7 is weird.
VEC_PERS_K		equ	(1<<VEC_PERS_K_SHIFT)	;Perspective screen constant to multiply by
VEC_PERS_DIST		equ	256

VEC_PERS_RECIP_NUMENTRIES	equ	2048
VEC_PERS_RECIP_SIZEOF		equ	VEC_PERS_RECIP_NUMENTRIES*2

VEC_PERS_RECIP_START_Z		equ	-512

VEC_UNITY_LEN_SHIFT	equ	8			;8=256, 14=16384
VEC_UNITY_LEN		equ	(1<<VEC_UNITY_LEN_SHIFT)

VEC_LIGHTS_NUMMAX	equ	4	;Routines setup for max 3 lights
LIGHTF_OFF		equ	0
LIGHTF_PLANAR		equ	1
LIGHTF_POINT		equ	2
LIGHTB_PLANAR		equ	0
LIGHTB_POINT		equ	1

LIGHT_MODEL_SURFACE_COLOR	equ	0	;0 assumes a white object which looks best anyway
LIGHT_DIM_VAL_MAX	equ	255
LIGHT_DIM_VAL_SHIFT	equ	4	;Dimmer value is 0-255 and we shift to get 0-15

VEC_CLIPMINX		equ	0
VEC_CLIPMAXX		equ	BPL_BUF_WIDTH-1
VEC_CLIPMINY		equ	0
VEC_CLIPMAXY		equ	BPL_BUF_HEIGHT-1

VEC_CLIPPING		equ	0	; Slighty quicker with no clipping
VEC_CLIPCHECK		equ	0	; Will write 1 into VEC_ClipCheck_Flag if clipping occured
VEC_DRAW_BOUNDING	equ	0	; Draw bounding box for debugging

VEC_NRML_CALC_LEN_ONCE	equ	1	; Only calc surface normal length once (rather than each rotation)

; Depending on size of verticies in object can soon overflow a word making squaring/dot products
; fail. This value scales down the non-unit normals by asr.l. Use 0 to disable.
; Points >= 256, shift 3
VEC_NRML_SHIFT_SCALE	equ	3

*****************************************************************************

	ifne VEC_Q14_GENSIN
ROT_SIN_TABLE_NUMWORDS		equ	LIB_GENSIN_16384_2048W_NUMWORDS
	else
ROT_SIN_TABLE_NUMWORDS		equ	LIB_SIN_Q14_1024W_NUMWORDS
	endif

ROT_SIN_TABLE_COS_OFFSET	equ	(ROT_SIN_TABLE_NUMWORDS/4)*2
ROT_SIN_TABLE_INDEX_MASK	equ	ROT_SIN_TABLE_NUMWORDS-1
ROT_SIN_TABLE_OFFSET_MASK	equ	((ROT_SIN_TABLE_NUMWORDS*2)-2)

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

	xdef	VEC_Start
VEC_Start:
	movem.l	d2-d7/a2-a6,-(sp)	;save
	lea	ControllerScript(pc),a0

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
	jsr	FW_SetBaseIrq		;default irq

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
	xdef	VEC_PreCalc_IntroStart
	endif
	
SubPartPreCalc_IntroStart:	
VEC_PreCalc_IntroStart:
	tst.w	Controller_Info+CTRL_PRECALC_INTROSTART_DONE
	bne.s	.exit			;already done

	movem.l	d2-d7/a2-a6,-(sp)	;save

	; Convert sine table to BPLCON shifts
	ifne	PERFORM_ENABLE_HORIZSCROLL
	bsr	Calc_HorizScroll_BPLCON	;T:d0-d2/a0
	endif

	; Multiply values by screen widths
	lea	Mult_SCR_Height_ByteWidth_NumPlanes,a0
	move.w	#BPL_BUF_MOD_LINE,d0
	move.w	#BPL_BUF_HEIGHT,d1
	jsr	FW_PreMultCreate_W

	move.w	#1,Controller_Info+CTRL_PRECALC_INTROSTART_DONE

	movem.l	(sp)+,d2-d7/a2-a6	;restore
.exit:
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

	;Copper lists
CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE	
	move.l	#P0_CL_SIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CL_Phys_Ptr

	lea	P0_CL_Phys(pc),a0
	move.l	d0,a1
	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

CUR_CHIP_BUF set CUR_CHIP_BUF+P0_CL_SIZE
	move.l	#P0_CL_SIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,CL_Log1_Ptr

	;Bitplanes
CUR_CHIP_BUF set CUR_CHIP_BUF+(BPL_BUF_TOTALSIZE*2)
	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,BPL_Phys_Ptr

	move.l	#BPL_BUF_TOTALSIZE,d0
	jsr	FW_Mem_Alloc_Chip
	move.l	d0,BPL_Log1_Ptr


CUR_PUB_BUF set CUR_PUB_BUF+LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4)
	move.l	#LIB_GENSIN_16384_2048W_SIZEOF+(LIB_GENSIN_16384_2048W_SIZEOF/4),d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_SINETAB_ROT_PTR(a5)

CUR_PUB_BUF set CUR_PUB_BUF+VEC_PERS_RECIP_SIZEOF
	move.l	#VEC_PERS_RECIP_SIZEOF,d0
	jsr	FW_Mem_Alloc_Public
	move.l	d0,CTRL_PERS_RECIP_TABLE_PTR(a5)


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

	;Reset anything that needs resetting
	clr.w	CTRL_PHASE(a5)	
	clr.w	CTRL_FINISHED(a5)
	clr.w	CTRL_FRAME_COUNT(a5)
	clr.w	CTRL_FRAME_SYNC(a5)
	clr.w	CTRL_PAUSE_COUNTER(a5)
	clr.w	CTRL_PALETTE_ACTIVE(a5)
	clr.w	CTRL_ROT_CHANGE_ACTIVE(a5)
	clr.w	CTRL_MOVE_ACTIVE(a5)
	clr.w	CTRL_MOVE2_ACTIVE(a5)
	clr.w	CTRL_LIGHTS_ENABLED(a5)
	clr.w	CTRL_MUSICSYNC(a5)
	clr.w	CTRL_MUSICSYNCMASK(a5)
	clr.w	CTRL_MUSICSYNCMASKWAIT(a5)
	move.w	#1,CTRL_FRAMES_MIN(a5)

	; Reset fill/clear buffers
	lea	SCR_Fill_Phys_Details(pc),a0
	clr.l	SCR_FILL_SRCPTR(a0)
	move.l	a0,SCR_Fill_Phys_Details_Ptr
	lea	SCR_Fill_Log_Details(pc),a0
	clr.l	SCR_FILL_SRCPTR(a0)
	move.l	a0,SCR_Fill_Log_Details_Ptr

	;Generate sin table
	ifne	VEC_Q14_GENSIN
		move.l	CTRL_SINETAB_ROT_PTR(a5),a0	;Sine
		jsr	LIB_GenSin_16384_2048W
	endif

	;Perspective 
	bsr	Perspective_Calc_ReciprocalTable

	; Clear all screen buffers
	bsr	Clear_ScreenBuffers_CPU	;T:d0-d1/a0-a1

	;Setup lights
	bsr	Lights_Set_Defaults

	;Run script up to the first FX_PAUSE command - use for setting base effect 
	;settings and palette rather than wasting code here on it
	bsr	Controller_ReadCommands	;I:a5, T:d0-d7/a0-a4

	;load current palette (default) into work CL and swap so that it's immediately live
	bsr	P0_CL_InitPtrs			;setup bpl ptrs and copperlists
	bsr	Lights_Color_Faces		;T:d0-d7/a2/a3/a4
	bsr	Copper_Write_Palette		;I:a5, T:d0/a0-a2

	;Ensure valid points in buffers prior to first loop
	;bsr	Object_Calc_Rotation_Matrix 	;I:a5, T:d0-d7/a0-a3
	;bsr 	Object_Rotate_And_Translate	;I:a5, T:d0-d7/a0-a4
	;bsr 	Object_Perspective		;I:a5, T:d0-d7/a0-a2
	;bsr	Object_Calc_Visible_Faces_2D	;I:a5, T:d0-d7/a0-a4
;	bsr	Object_Calc_Visible_Face_Normals_And_Store
;	bsr	Object_Calc_Visible_Face_Normals_And_Light	;I:a5, T:d0-d7/a0-a4

	;Swap buffers and load copper for next frame
	bsr	P0_ScreenBufferSwap	;I:a5-a6, T:d0-d1/a0

	;Initialise our new irq and ensure phys copper loaded (should have had palette loaded above)
	move.l	CL_Phys_Ptr(pc),a0
	lea	P0_Lev3Irq(pc),a1
	jsr	FW_SetCopperIrq_A6

	movem.l	(sp)+,d2-d7/a2-a4
	rts


*****************************************************************************
* Sets the lights default positions. Also allocates and copies the sprite data
* as a separate copy is requried for each light.
* IN:		a6, _custom
*		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Lights_Set_Defaults:
	;Setup base light ptrs
	lea	Light0_Info(pc),a0
	move.l	a0,CTRL_LIGHT0_PTR(a5)
	bsr	Lights_Set_Defaults_LightX	;I:a0, T:d0-d7/a0-a2

	lea	Light1_Info(pc),a0
	move.l	a0,CTRL_LIGHT1_PTR(a5)
	bsr	Lights_Set_Defaults_LightX	;I:a0, T:d0-d7/a0-a2

	lea	Light2_Info(pc),a0
	move.l	a0,CTRL_LIGHT2_PTR(a5)
	bsr	Lights_Set_Defaults_LightX	;I:a0, T:d0-d7/a0-a2

	lea	Light3_Info(pc),a0
	move.l	a0,CTRL_LIGHT3_PTR(a5)
	bsr	Lights_Set_Defaults_LightX	;I:a0, T:d0-d7/a0-a2
	
	rts

*****************************************************************************
* Sets the light default positions. Also allocates and copies the sprite data
* as a separate copy is requried for each light.
* IN:		a6, _custom
*		a5, Controller_Info
*		a0, LightX_Info
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

Lights_Set_Defaults_LightX:
	move.w	#32667,LIGHT_POS_Z(a0)		;unused lights at max distance
	clr.w	LIGHT_TYPE(a0)			;LIGHTF_OFF=0
	clr.w	LIGHT_ANIM_FRAME(a0)		;start at frame 0

	move.l	a0,-(sp)			;save light structure

	;Alloc memory for sprite A and copy
	move.l	#SPR_DISCOBALL_SIZEOF,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	(sp),a0				;restore light structure
	move.l	d0,LIGHT_SPRITE_A_PTR(a0)	;save allocated address

	lea	SPR_DiscoBall_A,a0		;src
	move.l	d0,a1				;destination
	move.w	#SPR_DISCOBALL_SIZEOF/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

	;Alloc memory for sprite B and copy
	move.l	#SPR_DISCOBALL_SIZEOF,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	(sp),a0				;restore light structure
	move.l	d0,LIGHT_SPRITE_B_PTR(a0)	;save allocated address

	lea	SPR_DiscoBall_B,a0		;src
	move.l	d0,a1				;destination
	move.w	#SPR_DISCOBALL_SIZEOF/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

	;Alloc memory for sprite C and copy
	move.l	#SPR_DISCOBALL_SIZEOF,d0	;number of BYTES
	jsr	FW_Mem_Alloc_Chip		;I:d0.l, O:d0.l, T:d0-d1/a0-a1
	move.l	(sp)+,a0			;restore light structure
	move.l	d0,LIGHT_SPRITE_C_PTR(a0)	;save allocated address

	lea	SPR_DiscoBall_C,a0		;src
	move.l	d0,a1				;destination
	move.w	#SPR_DISCOBALL_SIZEOF/2,d0	;number of WORDS
	jsr	FW_CopyBuffer_CPU		;I:d0/a0-a1, T:d0-d7,a0-a2

	;move.l	(sp)+,a0			;restore light structure

	rts


*****************************************************************************
* Runs the effect.
* IN:		a6, _custom
*		a5, Controller_Info	
* OUT:		
* TRASHED:	d0-d1/a0-a1
*
* The order of the operations in this loop looks odd. It is to optimize
* cpu processing during large blits.
*
* Simple:
* Two large blits, one clear screen and one fill screen. Split CPU use up between
* these. Fill screen is the bigger wait so move CPU code there.
*
* Complex:
* One large blit for clear screen. Lots of small but unpredicable blits 
* for each face. Put most CPU in the clear screen and a small routine after
* the last face is blit cleared.
*
* CPU Usage, high to low:
* Object_Rotate_And_Translate
* Object_Perspective
* Object_Calc_Visible_Face_Stats
* Object_Calc_Visible_Faces_2D
* Object_Calc_Rotation_Matrix
* Screen_Calc_Clr_Bounding
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

P0_Lev3Irq:				;Blank template VERTB/COP interrupt
	TIMERON
	movem.l	d0-d7/a0-a6,-(sp)

	lea	_custom,a6
	lea	Controller_Info(pc),a5

	bsr	Screen_Clear_Bounded_Blitter_A6	;I:a6, T:d0-d2/a0

	;Update frame sync
	addq.w	#1,CTRL_FRAME_COUNT(a5)	;Update local frame count
	addq.w	#1,CTRL_FRAME_SYNC(a5)	;constant fps sync
	jsr	FW_VBlankProxy		;T:d0-d7/a0-a4

	; Read new script lines and perform
	bsr	Controller_ReadCommands		;Read new commands
	bsr	Controller_Perform		;I:a0,a1

	bsr	Object_Calc_Rotation_Matrix	;I:a5, T:d0-d7/a0-a3
	bsr 	Object_Rotate_And_Translate	;I:a5, T:d0-d7/a0-a4
	bsr	Object_Perspective		;T:d0-d7/a0-a2
	bsr	Object_Calc_Visible_Faces_2D	;I:a5, T:d0-d7/a0-a4
	;;bsr	Object_Calc_Visible_Faces_3D	;I:a5, T:d0-d7/a0-a4

	; Work out the minmum size of fill and clr using post-pespective pts
	; Note must be before and in same frame (screen address) as Object_Draw_Lines/Fill
	bsr	Screen_Calc_Clr_Bounding	;T:d0-d7/a0-a2

	;If the bounding fill box indicates nothing on screen then skip!
	;move.l	SCR_Fill_Log_Details_Ptr(pc),a0
	;tst.l	SCR_FILL_SRCPTR(a0)
	;beq	.lighting			;nothing to draw on screen

	;simple vector specifics
	bsr	Object_Draw_Lines		;I:a6, T:d0-d7/a0-a4
	bsr	Screen_Fill_Bounded		;I:a6, T:d0-d3/a0

.lighting:
	bsr	Lights_Rotate_And_Translate	;I:a5, T:d0-d7/a0-a4
	bsr	Lights_Calc_Unit_Normal		;I:a5, T:d0-d7/a0-a4
	bsr	Lights_Sync_Brightness_With_Music
	bsr	Lights_Create_Light_Palette
	;;bsr	Object_Calc_Visible_Face_Normals_And_Light	;I:a5, T:d0-d7/a0-a4
	bsr	Object_Calc_Visible_Face_Normals_And_Store	;I:a5, T:d0-d7/a0-a4
	bsr	Object_Calc_Visible_Face_Lighting	;I:a5, T:d0-d7/a0-a4
	bsr	Lights_Color_Faces		;T:d0-d7/a0-a4
	bsr	Lights_Draw

	bsr	Copper_Write_Palette		;I:a5, T:a0-a2
	
	ifne PERFORM_ENABLE_HORIZSCROLL
	bsr	Do_Horiz_Scroll			;I:a5, T:d0-d4/d7/a0-a2
	endif


	;bsr	Object_Calc_Rotation_Matrix	;I:a5, T:d0-d7/a0-a3
	;bsr 	Object_Rotate_And_Translate	;I:a5, T:d0-d7/a0-a4
	;bsr 	Object_Perspective		;I:a5, T:d0-d7/a0-a2

	bsr	P0_ScreenBufferSwap		;I:a6, T:d0-d1/a0

	;Blitter nasty on while we finish off any blits
	WAITBLIT_NASTY_A6

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
	move.l	CL_Phys_Ptr(pc),a0
	lea	P0_CL_SPRITES_OFFSET(a0),a0
	moveq	#8,d0			;8 sprites
	jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1


	; Copper list buffers - copy screen list into 2nd buffer for doublebuffering
	move.l	CL_Phys_Ptr(pc),a0
	move.l	CL_Log1_Ptr(pc),a1
	move.w	#(P0_CL_SIZE/2),d0	;size in words
	jsr	FW_CopyBuffer_CPU	;I:d0/a0-a1, T:d0-d7/a0-a2

	;Screen copper BPL pointers
	move.l	CL_Phys_Ptr(pc),a0
	lea	P0_CL_BPL_OFFSET(a0),a0	;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	BPL_Phys_Ptr(pc),d1		;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2	;interleaved
	jsr	FW_InitCopperBplPtrs	;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo

	;Work copper BPL pointers
	move.l	CL_Log1_Ptr(pc),a0
	lea	P0_CL_BPL_OFFSET(a0),a0	;copper bpl pointer block
	moveq	#BPL_BUF_NUMPLANES,d0
	move.l	BPL_Log1_Ptr(pc),d1		;in d1 for InitCopperBplPtrs
	moveq 	#BPL_BUF_MOD_BPL,d2	;interleaved
	jsr	FW_InitCopperBplPtrs	;a0=bpl ptr block, d0=numplanes, d1=scr buffer, d2=modulo

	rts


*****************************************************************************
* Swaps the copperlist, screen and clr/fill pointers and activates the CL
* for the next frame. 
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
	lea	BPL_Phys_Ptr(pc),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+

	;lea	SCR_Fill_Phys_Details_Ptr(a5),a0
	movem.l	(a0),d0-d1		;Swap BPL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)+

	;lea	CTRL_CL_PHYS_PTR(a5),a0
	movem.l	(a0),d0-d1		;Swap CL ptrs
	move.l	d1,(a0)+
	move.l	d0,(a0)			;d1 is phys

	; and activate next frame - d1 is physical
	move.l 	d1,cop1lch(a6)		; Active NEXT frame

	rts


*****************************************************************************
* Modifies the horiz scroll sine table into bplcon1 shift values.
* Use for one-time setup
* IN:		
* OUT:		
* TRASHED:	d0-d2/a0
*****************************************************************************
	ifne PERFORM_ENABLE_HORIZSCROLL
Calc_HorizScroll_BPLCON:

	lea	HorizScroll_Table(pc),a0
	move.w	#HORIZSCROLL_TABLE_NUMWORDS-1,d2
.loop
	move.w	(a0),d0
	move.w	d0,d1
	lsl.w	#4,d1
	or.w	d0,d1		;change 000f to 00ff
	move.w	d1,(a0)+
	dbf	d2,.loop

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

	move.l	BPL_Phys_Ptr(pc),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	move.l	BPL_Log1_Ptr(pc),a0
	move.w	#(BPL_BUF_TOTALSIZE/2),d0
	jsr	FW_ClearBuffer_CPU	;I:d0/a0, T:d0-d7/a0-a4

	movem.l	(sp)+,d2-d7/a2-a6

	rts


*****************************************************************************
* Fills a bounded area of the screen.
* IN:		a6, _custom
* OUT:		
* TRASHED:	d0-d3/a0
*****************************************************************************

Screen_Fill_Bounded:
	; We only fill the box that we've drawn in.
	move.l	SCR_Fill_Log_Details_Ptr(pc),a0

	; Get start address of bottom right corner (fills are in descending mode so match with clear)
	; If the value is 0 then no valid fill was done, so skip the clear as well - happens at
	; start of routine
	move.l	SCR_FILL_SRCPTR(a0),d0
	beq.s	.exit

	move.w	SCR_FILL_BLTSIZE(a0),d2	;completed bltsize in d4
	move.w	SCR_FILL_BYTEMODULO(a0),d1

	lea 	bltapth(a6),a0
	moveq	#-1,d3
	WAITBLIT_NASTY_A6
	;move.l	#$09f00012,bltcon0(a6)	; Descending, exclusive fill mode
	move.l	#((BLT_SRC_AD+(BLT_A))<<16)|(BLT_FILL_XOR|BLT_BLITREVERSE),bltcon0(a6)

	move.l	d3,bltafwm(a6)
	move.w	d1,bltamod(a6)
	move.w	d1,bltdmod(a6)
	move.l	d0,(a0)+	; bltapth
	move.l	d0,(a0)+	; bltdpth
	move.w	d2,(a0)		; bltsize
.exit:
	rts


*****************************************************************************
* Clears the work buffer screen. Only clears the bounded area that was drawn in.
* IN:		a6, _custom
* OUT:		
* TRASHED:	d0-d2/a0
*****************************************************************************

Screen_Clear_Bounded_Blitter_A6:
	
	; We only fill the box that we've drawn in. 
	move.l	SCR_Fill_Log_Details_Ptr(pc),a0

	; Get start address of bottom right corner (fills are in descending mode so match with clear)
	; If the value is 0 then no valid fill was done, so skip the clear as well - happens at
	; start of routine
	move.l	SCR_FILL_SRCPTR(a0),d0
	beq.s	.exit

	move.w	SCR_FILL_BLTSIZE(a0),d2	;completed bltsize in d4
	move.w	SCR_FILL_BYTEMODULO(a0),d1

	WAITBLIT_A6
	move.l	#$01000002,bltcon0(a6)	;desending to match fill routine calculations
	move.w	d1,bltdmod(a6)
	move.l	d0,bltdpth(a6)
	move.w	d2,bltsize(a6)
.exit:
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
	bne	.pausing

	ifne	PERFORM_ENABLE_MUSICSYNC
	tst.w	CTRL_MUSICSYNCMASKWAIT(a5)	;Are we waiting for a music sync signal?
	bne	.exit				;handled in Controller_MusicSync_Perform
	endif

	ifne	PERFORM_ENABLE_USERVALWAIT
	tst.w	CTRL_USERVALWAIT_ACTIVE(a5)
	bne.s	.uservalwait
	endif

	move.w	CTRL_ISFRAMEOVER_COUNTER(a5),d0
	bne	.isframeover

	move.w	CTRL_ISMASTERFRAMEOVER_COUNTER(a5),d0
	bne	.ismasterframeover

	tst.w	CTRL_FINISHED(a5)
	bne	.exit

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
	bra.w	.fx_load		;FX_LOAD_FLAG
	bra.w	.fx_morph		;FX_MORPH_FLAG
	bra.w	.fx_clone_rotation	;FX_CLONE_ROTATION_FLAG
	bra.w	.fx_change_rot_delta	;FX_CHANGE_ROT_DELTA_FLAG
	bra.w	.fx_change_rot		;FX_CHANGE_ROT_FLAG
	bra.w	.fx_horizsine		;FX_HORIZSINE_FLAG
	bra.w	.fx_move		;FX_MOVE_FLAG
	bra.w	.fx_move2		;FX_MOVE2_FLAG
	bra.w	.fx_lights_enable	;FX_LIGHTS_ENABLE_FLAG
	bra.w	.fx_light_color		;FX_LIGHT_COLOR_FLAG
	bra.w	.fx_light_disable	;FX_LIGHT_DISABLE_FLAG
	bra.w	.fx_light_point		;FX_LIGHT_POINT_FLAG
	bra.w	.fx_light_planar	;FX_LIGHT_PLANAR_FLAG
	bra.w	.fx_light_rot_delta	;FX_LIGHT_ROT_DELTA_FLAG
	bra.w	.fx_light_dimming	;FX_LIGHT_DIMMING_FLAG
	bra.w	.fx_light_move		;FX_LIGHT_MOVE_FLAG

.fx_end:
	move.w	#1,CTRL_FINISHED(a5)	;exit entire effect
.exit:
	move.l	a4,CTRL_SCRIPT_PTR(a5)	;save current script position
	rts

.pausing:
	subq.w	#1,CTRL_PAUSE_COUNTER(a5)
	beq	.loop
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
	bra	.exit			;save script pos and exit

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

.fx_load:
	move.l	(a4)+,a0		;New object
	pea	.loop(pc)
	bra	Controller_FX_Load

.fx_morph:
	move.w	(a4)+,d0		;Speed
	move.l	(a4)+,a0		;New points
	pea	.loop(pc)
	bra	Controller_FX_Morph

.fx_clone_rotation:
	move.l	(a4)+,a0		;Object to clone from
	pea	.loop(pc)
	bra	Controller_FX_Clone_Rotation

.fx_change_rot_delta:
	movem.w	(a4)+,d0-d2
	pea	.loop(pc)
	bra	Controller_FX_Change_Rot_Delta

.fx_change_rot:
	movem.w	(a4)+,d0-d3		;speed,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Change_Rot

.fx_horizsine:
	movem.w	(a4)+,d0-d1		;speed,step
	pea	.loop(pc)
	bra	Controller_FX_HorizSine

.fx_move:
	movem.w	(a4)+,d0-d3		;speed,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Move

.fx_move2:
	movem.w	(a4)+,d0-d3		;speed,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Move2

.fx_lights_enable:
	move.w	(a4)+,CTRL_LIGHTS_ENABLED(a5)	;boolean
	bra	.loop

.fx_light_color:
	movem.w	(a4)+,d0-d3		;light,color,ambient
	pea	.loop(pc)
	bra	Controller_FX_Light_Set_Color

.fx_light_disable:
	move.w	(a4)+,d0		;light
	pea	.loop(pc)
	bra	Controller_FX_Light_Disable

.fx_light_point:
	movem.w	(a4)+,d0-d3		;light,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Light_Set_Point

.fx_light_planar:
	movem.w	(a4)+,d0-d3		;light,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Light_Set_Planar

.fx_light_rot_delta:
	movem.w	(a4)+,d0-d3		;light,x,y,z
	pea	.loop(pc)
	bra	Controller_FX_Light_Set_Rotation

.fx_light_dimming:
	movem.w	(a4)+,d0-d2		;light,dim val,step val
	pea	.loop(pc)
	bra	Controller_FX_Light_Set_Dimming

.fx_light_move:
	bra	.loop


*****************************************************************************
* Performs any time-based controller routines.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a2-a4
*****************************************************************************

Controller_Perform:

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	; Update current angles
	movem.w	VEC_OBJ_THETA_X(a0),d0-d5	;current d0-d2, delta d3-d5
	move.w	#ROT_SIN_TABLE_OFFSET_MASK,d6
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2
	and.w	d6,d0				;ensure in range
	and.w	d6,d1
	and.w	d6,d2
	movem.w d0-d2,VEC_OBJ_THETA_X(a0)	;save new values

	; Calls are in reverse order to avoid unneeded bsr/rts use
	pea	Controller_FX_Light_Set_Color_Perform(pc)	;
	pea	Controller_FX_Morph_Perform(pc)		;I:a5, T:d0-d7/a1/a2
	pea	Controller_FX_Move2_Perform(pc)		;I:a5, T:d0-d6/a0
	pea	Controller_FX_Move_Perform(pc)		;I:a5, T:d0-d6/a0
	pea	Controller_FX_Change_Rot_Perform(pc)	;I:a5, T:d0-d7/a0

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
*		a0, new pallete
*		d0, speed
* OUT:		
* TRASHED:	d0-d2/a0
*****************************************************************************

	ifne PERFORM_ENABLE_MUSICSYNC
Controller_MusicSync_Perform:
	;For this routine we are using bits 0-3 for lights 0-3.
	;bits 4-7 are E8x values shifted << 4
	;if all channels play we reverse rotation
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
	cmp.w	#50,d0			;50 frame limit
	blt.s	.exit
	move.w	d1,CTRL_MUSICSYNC_LASTFRAME(a5)

	; Do the trigger operation
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	movem.w	VEC_OBJ_THETA_DX(a0),d0-d2
	exg	d0,d1
	exg 	d1,d2
	neg.w	d0
	neg.w	d1
	neg.w	d2
	movem.w	d0-d2,VEC_OBJ_THETA_DX(a0)
.exit:
	rts

.lastcount:
	dc.w	0

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
* Loads a new object.
* IN:		a5, Controller_Info
*		a0, new object info (Obj_Glenz24_Info for example)
* OUT:		
* TRASHED:	d0-d3/a0-a3
*****************************************************************************

Controller_FX_Load:
	; Test if new object has been initialised already, if so skip
	; the inintial face/pts copy and just change current pointer
	tst.w	VEC_OBJ_INITIALIZED(a0)
	bne.s	.changecurrent	

	; Points - ASSUMPTION: Points buffer must be large enough to hold!
	move.l	VEC_OBJ_PTS_PTR(a0),a1
	move.l 	VEC_OBJ_PTSINITIAL_PTR(a0),a2

	; Copy the initial points into the pts buffer
	move.w	(a2)+,d3	; num points-1 
	move.w	d3,(a1)+
.copypts
	movem.w	(a2)+,d0-d2
	movem.w	d0-d2,(a1)
	addq.l	#6,a1
	dbf	d3,.copypts

	; Mark as initialised
	move.w	#1,VEC_OBJ_INITIALIZED(a0)

.changecurrent:
	; Change current object
	move.l	a0,CTRL_OBJECTINFO_PTR(a5)

	;Update frame target based on object
	move.w VEC_OBJ_NUMFRAMES(a0),CTRL_FRAMES_MIN(a5)
	
	;Work out magnitudes if only doing it once
	ifne	VEC_NRML_CALC_LEN_ONCE
		move.l	a4,-(sp)
		bsr	Calc_Surface_Normal_Lengths	;T:d0-d7/a0-a4
		move.l	(sp)+,a4
	endif

	rts


*****************************************************************************
* Copies the rotation from one object to another.
* IN:		a5, Controller_Info
*		a0, object definition to clone (Obj_Glenz24_Info for example)
* OUT:		
* TRASHED:	d0-d2/a1
*****************************************************************************

Controller_FX_Clone_Rotation:
	move.l	CTRL_OBJECTINFO_PTR(a5),a1	;Current object

	movem.w	VEC_OBJ_THETA_X(a0),d0-d2
	movem.w	d0-d2,VEC_OBJ_THETA_X(a1)

	movem.w	VEC_OBJ_THETA_DX(a0),d0-d2
	movem.w	d0-d2,VEC_OBJ_THETA_DX(a1)

	rts


*****************************************************************************
* Changes rot delta.
* IN:		a5, Controller_Info
*		d0-d2, new x,y,z
* OUT:		
* TRASHED:	a0
*****************************************************************************

Controller_FX_Change_Rot_Delta:

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	movem.w	d0-d2,VEC_OBJ_THETA_DX(a0)

	rts


*****************************************************************************
* Changes rot values. Will do over time is speed >0
* IN:		a5, Controller_Info
* 		d0-d3, speed,new x,y,z
* OUT:		
* TRASHED:	d0-d3/a0
*****************************************************************************

Controller_FX_Change_Rot:
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	tst.w	d0
	bne.s	.slow
	move.w	#0,CTRL_ROT_CHANGE_ACTIVE(a5)	;disable change
	movem.w	d1-d3,VEC_OBJ_THETA_X(a0)		;change rot
	rts

.slow:
	move.w	#1,CTRL_ROT_CHANGE_ACTIVE(a5)	;enable change
	movem.w	d0-d3,CTRL_ROT_CHANGE_SPEED(a5)	;store params in controller info

	; If doing slow transform also have to zero rot delta
	moveq	#0,d0
	moveq	#0,d1
	moveq	#0,d2

	movem.w	d0-d2,VEC_OBJ_THETA_DX(a0)

	rts


*****************************************************************************
* Performs rot change
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0
*****************************************************************************

Controller_FX_Change_Rot_Perform:
	tst.w	CTRL_ROT_CHANGE_ACTIVE(a5)
	bne.s	.active
	rts
.active:

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	movem.w	CTRL_ROT_CHANGE_X(a5),d0-d2
	movem.w	VEC_OBJ_THETA_X(a0),d3-d5
	
	;TODO: fix this lame code, should be working out the best direction

	moveq   #0,d6			;flag

	move.w	CTRL_ROT_CHANGE_SPEED(a5),d7
.x	cmp.w	d3,d0
	beq.s	.y
	moveq	#1,d6			;set flag
	addq.w	#2,d3			;mext offset
	andi.w	#ROT_SIN_TABLE_OFFSET_MASK,d3
	dbf	d7,.x

	move.w	CTRL_ROT_CHANGE_SPEED(a5),d7
.y	cmp.w	d4,d1
	beq.s	.z
	moveq	#1,d6			;set flag
	addq.w	#2,d4			;next offset
	andi.w	#ROT_SIN_TABLE_OFFSET_MASK,d4
	dbf	d7,.y

	move.w	CTRL_ROT_CHANGE_SPEED(a5),d7
.z	cmp.w	d5,d2
	beq.s	.q
	moveq	#1,d6			;set flag
	addq.w	#2,d5			;next offset
	andi.w	#ROT_SIN_TABLE_OFFSET_MASK,d5
	dbf	d7,.z

.q
	tst.w	d6
	bne.s	.bye
	clr.w	CTRL_ROT_CHANGE_ACTIVE(a5)	;finished
.bye
	;store changes
	movem.w	d3-d5,VEC_OBJ_THETA_X(a0)

	rts


*****************************************************************************
* Moves. Will do over time is speed >0
* IN:		a5, Controller_Info
* 		d0-d3, speed,new x,y,z
* OUT:		
* TRASHED:	d0-d3
*****************************************************************************

Controller_FX_Move:
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	clr.w	CTRL_MOVE2_ACTIVE(a5)	;disable change move2

	tst.w	d0			;instant?
	bne.s	.slow
	move.w	d0,CTRL_MOVE_ACTIVE(a5)	;d0=0, disable change
	movem.w	d1-d3,VEC_OBJ_POSX(a0)	;change pos
	rts

.slow:
	move.w	#1,CTRL_MOVE_ACTIVE(a5)	;enable change
	movem.w	d0-d3,CTRL_MOVE_SPEED(a5)	;store params in controller info

	rts


*****************************************************************************
* Performs move change
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d6/a0
*****************************************************************************

Controller_FX_Move_Perform:
	tst.w	CTRL_MOVE_ACTIVE(a5)
	bne.s	.active
	rts
.active:

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	moveq	#0,d6				;flag

	move.w	CTRL_MOVE_X(a5),d1	;final value
	move.w	VEC_OBJ_POSX(a0),d0	;current value
	move.w	CTRL_MOVE_SPEED(a5),d2	;speed
	bsr.s	Move_Coord_Towards
	move.w	d0,VEC_OBJ_POSX(a0)	;save value
	cmp.w	d0,d1
	sne.b	d6			;set to $ff if ne
.y:
	move.w	CTRL_MOVE_Y(a5),d1	;final value
	move.w	VEC_OBJ_POSY(a0),d0	;current value
	move.w	CTRL_MOVE_SPEED(a5),d2	;speed
	bsr.s	Move_Coord_Towards
	move.w	d0,VEC_OBJ_POSY(a0)	;save value
	cmp.w	d0,d1
	sne.b	d6			;set to $ff if ne
.z:
	move.w	CTRL_MOVE_Z(a5),d1	;final value
	move.w	VEC_OBJ_POSZ(a0),d0	;current value
	move.w	CTRL_MOVE_SPEED(a5),d2	;speed
	bsr.s	Move_Coord_Towards
	move.w	d0,VEC_OBJ_POSZ(a0)	;save value
	cmp.w	d0,d1
	sne.b	d6			;set to $ff if ne

	tst.b	d6
	bne.s	.exit			;test flag, if not zero not finished
	clr.w	CTRL_MOVE_ACTIVE(a5)	;finished
.exit:
	rts


*****************************************************************************
* Moves a coordinate towards a value at given speed.
* IN:		d0, current value
*		d1, target value
*		d2, speed
* OUT:		d0, new value
* TRASHED:	
*****************************************************************************

Move_Coord_Towards:
	cmp.w	d1,d0
	beq.s	.next			; already there
	bgt.s	.greater
.less:
	add.w	d2,d0			;add the speed
	cmp.w	d1,d0			;how about now?
	ble.s	.next			;still moving in right direction
.less_now_greater:
	move.w	d1,d0			;overshot, set value to final
	bra.s	.next

.greater:
	sub.w	d2,d0			;sub the speed
	cmp.w	d1,d0			;how about now?
	bge.s	.next			;still moving in right direction
.greater_now_less:
	move.w	d1,d0			;overshot, set value to final
.next
	rts


*****************************************************************************
* Moves. Will do over time is speed >0
* IN:		a5, Controller_Info
* 		d0-d3, speed,new x,y,z
* OUT:		
* TRASHED:	d0-d4/a0
*****************************************************************************

Controller_FX_Move2:
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	moveq	#0,d4
	move.w	d4,CTRL_MOVE_ACTIVE(a5)		;disable change move1

	tst.w	d0
	bne.s	.slow
	move.w	d4,CTRL_MOVE2_ACTIVE(a5)	;disable change
	movem.w	d1-d3,VEC_OBJ_POSX(a0)		;change pos

	move.w	d4,CTRL_MOVE2_XVEL(a5)		;reset velocities - hard stop
	move.w	d4,CTRL_MOVE2_YVEL(a5)
	move.w	d4,CTRL_MOVE2_ZVEL(a5)
	
	rts

.slow:
	move.w	#1,CTRL_MOVE2_ACTIVE(a5)	;enable change
	movem.w	d0-d3,CTRL_MOVE2_SPEED(a5)	;store speed,x,y,z

	;clr.w	CTRL_MOVE2_XVEL(a1)		;reset velocities - no!
	;clr.w	CTRL_MOVE2_YVEL(a1)
	;clr.w	CTRL_MOVE2_ZVEL(a1)

	rts


*****************************************************************************
* Performs move change
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d6/a0
*****************************************************************************

Controller_FX_Move2_Perform:
	tst.w	CTRL_MOVE2_ACTIVE(a5)
	bne.s	.active
	rts
.active:

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	moveq	#0,d6			;clear flag

	move.w	CTRL_MOVE2_X(a5),d1	;final value
	move.w	VEC_OBJ_POSX(a0),d0	;current value
	move.w	CTRL_MOVE2_SPEED(a5),d2	;speed
	move.w	CTRL_MOVE2_XVEL(a5),d3	;current vel
	bsr.s	Move2_Coord_Towards
	move.w	d0,VEC_OBJ_POSX(a0)	;save value
	move.w	d3,CTRL_MOVE2_XVEL(a5)
	cmp.w	d0,d1
	sne.b	d6			;set to $ff if ne
.y:
	move.w	CTRL_MOVE2_Y(a5),d1	;final value
	move.w	VEC_OBJ_POSY(a0),d0	;current value
	move.w	CTRL_MOVE2_SPEED(a5),d2	;speed
	move.w	CTRL_MOVE2_YVEL(a5),d3	;current vel
	bsr.s	Move2_Coord_Towards
	move.w	d0,VEC_OBJ_POSY(a0)	;save value
	move.w	d3,CTRL_MOVE2_YVEL(a5)
	cmp.w	d0,d1
	sne.b	d6
.z:
	move.w	CTRL_MOVE2_Z(a5),d1	;final value
	move.w	VEC_OBJ_POSZ(a0),d0	;current value
	move.w	CTRL_MOVE2_SPEED(a5),d2	;speed
	move.w	CTRL_MOVE2_ZVEL(a5),d3	;current vel
	bsr.s	Move2_Coord_Towards
	move.w	d0,VEC_OBJ_POSZ(a0)	;save value
	move.w	d3,CTRL_MOVE2_ZVEL(a5)
	cmp.w	d0,d1
	sne.b	d6			

	tst.b	d6
	bne.s	.exit			;test flag, if not zero not finished
	clr.w	CTRL_MOVE2_ACTIVE(a5)	;finished
.exit:
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
* Changes the horizontal scroll effect
* IN:		a5, Controller_Info
* 		d0-d3, speed,step,speed,step
* OUT:		
* TRASHED:	
*****************************************************************************

Controller_FX_HorizSine:

	;2 because when we deactivate we use this as a count for coping
	;with doublebuffered copper
	move.w	#P0_CL_NUM_BUFFERS,CTRL_HORIZSCROLL_ACTIVE(a5)
	movem.w	d0-d1,CTRL_HORIZSCROLL_SIN1_SPEED(a5)

	rts


*****************************************************************************
* Sets up the morph process.
* IN:		a5, Controller_Info
*		a0, new pts
*		d0, speed
* OUT:		
* TRASHED:	d0-d3/a1-a2
*****************************************************************************

Controller_FX_Morph:
	move.l	CTRL_OBJECTINFO_PTR(a5),a2	;Current object

	; set new initial points which the morph will use
	move.l	a0,VEC_OBJ_PTSINITIAL_PTR(a2)

	; If speed is 0 just instastransform
	tst.w	d0
	bne.s	.morph

	clr.w	VEC_OBJ_MORPH_ACTIVE(a2)	;disable morph

	move.l	VEC_OBJ_PTS_PTR(a2),a1

	move.w	(a0)+,d3	; num points-1 
	move.w	d3,(a1)+
.copypts
	movem.w	(a0)+,d0-d2
	move.w	d0,(a1)+
	move.w	d1,(a1)+
	move.w	d2,(a1)+
	dbf	d3,.copypts

	rts

.morph:
	; Setup counter 
	move.w	d0,VEC_OBJ_MORPH_COUNTER(a2)
	move.w	d0,VEC_OBJ_MORPH_SPEED(a2)

	; Set morph flag
	move.w	#1,VEC_OBJ_MORPH_ACTIVE(a2)

	rts


*****************************************************************************
* Performs the morph.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a1/a2
*****************************************************************************

Controller_FX_Morph_Perform:
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	tst.w	VEC_OBJ_MORPH_ACTIVE(a0)
	bne.s	.active
	rts
.active:

	;check counter
	subq.w	#1,VEC_OBJ_MORPH_COUNTER(a0)
	bgt.s	.exit			;1 or greater we skip

	;new counter for next time
	move.w	VEC_OBJ_MORPH_SPEED(a0),VEC_OBJ_MORPH_COUNTER(a0)

	move.l	VEC_OBJ_PTSINITIAL_PTR(a0),a1
	move.l	VEC_OBJ_PTS_PTR(a0),a2
	moveq	#0,d6	

	;ASSERT: Num points in current and new buffers are the same.
	move.w	(a1)+,d7	; num points-1 
	addq.l	#2,a2		; skip num points
.morphpts:
	movem.w	(a1)+,d0-d2	;x,y,z
	movem.w	(a2),d3-d5	;x,y,z

	cmp	d0,d3
	beq.s	.xequal
	ble.s	.xless
	subq.w	#1,d3
	moveq	#1,d6		;flag
	bra.s	.xequal
.xless:		
	addq.w	#1,d3
	moveq	#1,d6		;flag
.xequal:
	cmp	d1,d4
	beq.s	.yequal
	ble.s	.yless
	subq.w	#1,d4
	moveq	#1,d6		;flag
	bra.s	.yequal
.yless:		
	addq.w	#1,d4
	moveq	#1,d6		;flag
.yequal:
	cmp	d2,d5
	beq.s	.zequal
	ble.s	.zless
	subq.w	#1,d5
	moveq	#1,d6		;flag
	bra.s	.zequal
.zless:		
	addq.w	#1,d5
	moveq	#1,d6		;flag
.zequal:

	; save pts
	move.w	d3,(a2)+
	move.w	d4,(a2)+
	move.w	d5,(a2)+
	dbf	d7,.morphpts

	; Reset morph flag if no changes made
	tst.w	d6
	bne.s	.exit

	clr.w	VEC_OBJ_MORPH_ACTIVE(a0)

.exit:
	rts


*****************************************************************************
* Turns on planar light in a given direction.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
*		d1-d3.w, planar light direction
* OUT:		
* TRASHED:	d0-d6/a0
*****************************************************************************

Controller_FX_Light_Set_Planar:
	;Convert light number into the relevant CTRL_LIGHTX_PTR
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr

	; Get unit vector for light source, scaled by VEC_UNITY_LEN
	move.w	d1,d0
	move.w	d2,d1
	move.w	d3,d2
	bsr	Vec3_Normalize		;I:d0-d2.w, O:d0-d2.w, T:d0-d6
	movem.w	d0-d2,LIGHT_NORMAL_X(a0)
	move.w	#VEC_UNITY_LEN,LIGHT_NORMAL_LEN(a0)

	move.w	#LIGHTF_PLANAR,LIGHT_TYPE(a0)

	rts


*****************************************************************************
* Turns on a point light at a given position in space.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
*		d1-d3.w, light point position
* OUT:		
* TRASHED:	d0/a0
*****************************************************************************

Controller_FX_Light_Set_Point:
	;Convert light number into the relevant CTRL_LIGHTX_PTR, 
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr

	; Sety light position, the actual light vector needs to be generated
	; For each object on the fly (if object or light can move)
	movem.w	d1-d3,LIGHT_BASEPOS_X(a0)

	move.w	#LIGHTF_POINT,LIGHT_TYPE(a0)

	rts


*****************************************************************************
* Turns on a point light at a given position in space.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
*		d1-d3.w, light point position
* OUT:		
* TRASHED:	d0/a0
*****************************************************************************

Controller_FX_Light_Set_Rotation:
	;Convert light number into the relevant CTRL_LIGHTX_PTR, 
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr

	movem.w	d1-d3,LIGHT_THETA_DX(a0)

	rts


*****************************************************************************
* Disables a given light.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
* OUT:		
* TRASHED:	d0/a0
*****************************************************************************

Controller_FX_Light_Disable:
	;Convert light number into the relevant CTRL_LIGHTX_PTR, 
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr
	clr.w	LIGHT_TYPE(a0)
	move.w	#32767,LIGHT_POS_Z(a0)		;Unused lights set to max distance

	rts


*****************************************************************************
* Sets the main and ambient colors for a light.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
*		d1.w, speed
*		d2.w, main color
*		d3.w, ambient color
* OUT:		
* TRASHED:	d0-d7/a0-a1
*****************************************************************************

Controller_FX_Light_Set_Color:
	;If light number is -1 then just set the scene ambient light
	tst.w	d0
	bmi.s	.ambient

	;Convert light number into the relevant CTRL_LIGHTX_PTR, 
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr

	; If speed is 0 just instastransform
	tst.w	d1
	bne.s	.slow

	move.w	d2,LIGHT_COLOR(a0)
	move.w	d3,LIGHT_COLOR_AMBIENT(a0)

	;Set flag that this light has changed color and needs a palette generating
	;If music sync is enabled then that will also request regen so don't waste time
	;doing it here. WIll be done in Light_Create_Light_Palette
	move.w	#1,LIGHT_COLOR_GENPALETTE(a0)
	rts

.slow:
	move.w	LIGHT_COLOR(a0),LIGHT_COLOR_SRC(a0)
	move.w	d2,LIGHT_COLOR_DEST(a0)

	move.w	LIGHT_COLOR_AMBIENT(a0),LIGHT_COLOR_AMBIENT_SRC(a0)
	move.w	d3,LIGHT_COLOR_AMBIENT_DEST(a0)

	move.w	d1,LIGHT_COLOR_CHANGE_COUNTER(a0)
	move.w	d1,LIGHT_COLOR_CHANGE_SPEED(a0)

	moveq	#1,d0				; Initial step is 1 (we run 1-15)
	move.w	d0,LIGHT_COLOR_CHANGE_STEP(a0)
	move.w	d0,LIGHT_COLOR_CHANGE_ACTIVE(a0)

	rts

.ambient
	move.w	d2,CTRL_LIGHT_AMBIENT(a5)
	rts

*****************************************************************************
* Performs the pallete change.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d6/a0-a3
*****************************************************************************

Controller_FX_Light_Set_Color_Perform:

	lea	CTRL_LIGHT0_PTR(a5),a3	;Light ptr
	moveq	#VEC_LIGHTS_NUMMAX-1,d5
.loop:
	move.l	(a3)+,a2			;light ptr
	
	tst.w	LIGHT_COLOR_CHANGE_ACTIVE(a2)
	beq.s	.next

	subq.w	#1,LIGHT_COLOR_CHANGE_COUNTER(a2)	;check counter
	bgt.s	.next	
	
	;Reset counter for next time
	move.w	LIGHT_COLOR_CHANGE_SPEED(a2),LIGHT_COLOR_CHANGE_COUNTER(a2)

	move.w	LIGHT_COLOR_CHANGE_STEP(a2),d2
	addq.w	#1,LIGHT_COLOR_CHANGE_STEP(a2)
	cmp.w	#15,d2				;last step?
	blt.s	.notlast
	clr.w	LIGHT_COLOR_CHANGE_ACTIVE(a2)	;finish routine for this light
.notlast:
	move.w	LIGHT_COLOR_SRC(a2),d0		;main color
	move.w	LIGHT_COLOR_DEST(a2),d1
	move.w	d2,d6				;save step
	jsr	LIB_RGB12_Interpolate_Fast	;I:d0-d2, T:d0-d4/a0
	move.w	d0,LIGHT_COLOR(a2)
	move.w	d6,d2				;restore step

	move.w	LIGHT_COLOR_AMBIENT_SRC(a2),d0	;ambient color
	move.w	LIGHT_COLOR_AMBIENT_DEST(a2),d1
	jsr	LIB_RGB12_Interpolate_Fast	;I:d0-d2, T:d0-d4/a0
	move.w	d0,LIGHT_COLOR_AMBIENT(a2)

	move.w	#1,LIGHT_COLOR_GENPALETTE(a2)	;needs palette regen
.next:
	dbf	d5,.loop

	rts


*****************************************************************************
* Sets the fade/music sync for a light.
* IN:		a5, Controller_Info
*		d0.w, light number 0-2 (not bounds checked)
*		d1.w, Dim value (0=no dimming, 255=max dimming)
*		d2.w, Dim fade value (0-32, added to Dim value each frame)
* OUT:		
* TRASHED:	d0-d7/a0-a1
*****************************************************************************

Controller_FX_Light_Set_Dimming:
	;Convert light number into the relevant CTRL_LIGHTX_PTR, 
	add.w	d0,d0
	add.w	d0,d0			;Longs
	move.l	CTRL_LIGHT0_PTR(a5,d0.w),a0	;Light ptr

	move.w	d1,LIGHT_FADE_VAL(a0)
	move.w	d2,LIGHT_FADE_STEP(a0)

	rts


*****************************************************************************
* Loads the current colors into the current copperlist. The number of colours
* we write to the copper is based on the BPL_BUF_NUMCOLS rather than the 
* palette size.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	a0-a2
*****************************************************************************

Copper_Write_Palette:

	;If lightsource we have to load copper each frame
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq.s	.nolight

	lea	PAL_Current_LightSourced(pc),a0	;Use modified light source palette
	bra.s	.write

.nolight:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_PALETTE_LOAD_FLAG(a5)
	beq	.exit
	subq.w	#1,CTRL_PALETTE_LOAD_FLAG(a5)

	lea	PAL_Current(pc),a0	;Use normal source palette
.write:
	move.l	CL_Log1_Ptr(pc),a1

	;Normal colors
	lea	P0_CL_COL_OFFSET+2(a1),a2	

	rept	BPL_BUF_NUMCOLS
	move.w	(a0)+,(a2)
	addq.l	#4,a2			;next color
	endr
	
.exit:
	rts


*****************************************************************************
* Does the sine based horizontal scroll effect
* IN:		a6, _custom
* OUT:		
* TRASHED:	d0-d4/d7/a0-a2
*****************************************************************************

; Format of the horizontal scroll entries in copper:
;CWAIT x,x (4 bytes)
;CMOVE bplcon1,x (4 bytes) we want byte 6 for the value

	ifne PERFORM_ENABLE_HORIZSCROLL
Do_Horiz_Scroll:
	;Load flag may be > 1 if using double buffered CL or changing between CLs
	tst.w	CTRL_HORIZSCROLL_ACTIVE(a5)
	beq	.exit
	subq.w	#1,CTRL_HORIZSCROLL_ACTIVE(a5)

	; Active, but do we need to shut it off? (speed and step = 0)
	movem.w	CTRL_HORIZSCROLL_SIN1_SPEED(a5),d0/d1
	add.w	d0,d1
	bne.s	.active

	; Shut it off
	moveq	#0,d0			;bplcon shift = 0, and flag = 0
	;Get work address of the horiz scroll part of the copper list
	move.l	CL_Log1_Ptr(pc),a1
	lea	P0_CL_HORIZSCROLL_OFFSET+CL_HORIZSCROLL_BPLCON1+2(a1),a1
	move.w	#VEC_HORIZ_SCROLL_NUMLINES-1,d1
.offloop:
	move.w	d0,(a1)
	addq.l	#CL_HORIZSCROLL_SIZEOF,a1			;next bplcon1 entry
	dbf	d1,.offloop

	rts


.active:
	;Get the speed (movement per frame) and adjust based on the object's num frames so that
	;effect runs at same speed for fast and slow vector objects
	move.w	CTRL_HORIZSCROLL_SIN1_SPEED(a5),d3
	move.w	CTRL_HORIZSCROLL_SIN1_OFFSET(a5),d4	;offset in words
	add.w	d3,d3				;speed to word offset
	add.w	d3,d4				;add speed to offset (movement per frame)
	and.w	#HORIZSCROLL_TABLE_OFFSET_MASK,d4	;keep in range
	move.w	d4,CTRL_HORIZSCROLL_SIN1_OFFSET(a5)	;save for next frame
	move.w	CTRL_HORIZSCROLL_SIN1_STEP(a5),d3	;step, movement per line
	add.w	d3,d3				;step to word offset

	;Get work address of the horiz scroll part of the copper list
	;for the work copper list
	;format is
	;CWAIT x,x (4 bytes)
	;CMOVE bplcon1,x (4 bytes) we want byte 6 for the value
	move.l	CL_Log1_Ptr(pc),a1
	lea	P0_CL_HORIZSCROLL_OFFSET+CL_HORIZSCROLL_BPLCON1+2(a1),a1

	;Sine table has been modified into bplcon shift values like 00ff
	lea	HorizScroll_Table(pc),a0
	move.w	#HORIZSCROLL_TABLE_OFFSET_MASK,d2

;	move.w	#VEC_HORIZ_SCROLL_NUMLINES-1,d7
;.loop:
	rept	VEC_HORIZ_SCROLL_NUMLINES
	move.w	(a0,d4.w),(a1)
	addq.l	#CL_HORIZSCROLL_SIZEOF,a1			;next bplcon1 entry
	add.w	d3,d4			;increase by step value
	and.w	d2,d4			;ensure in range
	endr
;	dbf	d7,.loop

.exit:
	rts
	endif

*****************************************************************************

;Rotation stuff for matrix

;Object rotation

VEC_MROT11 = 0
VEC_MROT12 = 2
VEC_MROT13 = 4
VEC_MROT21 = 6
VEC_MROT22 = 8
VEC_MROT23 = 10
VEC_MROT31 = 12
VEC_MROT32 = 14
VEC_MROT33 = 16

VEC_MatrixRotObject:
	ds.w	1			;0
	ds.w	1			;2
	ds.w	1			;4

	ds.w	1			;6
	ds.w	1			;8
	ds.w	1			;10

	ds.w	1			;12
	ds.w	1			;14
	ds.w	1			;16


*****************************************************************************
* Precreates rotation matrix for the given object.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

Object_Calc_Rotation_Matrix:
	; Get current angles
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	movem.w	VEC_OBJ_THETA_X(a0),d0-d2	;angles
	lea	VEC_MatrixRotObject(pc),a0	;adr of matrix
	bra	Calc_Rotation_Matrix		;init matrix

	;rts


*****************************************************************************
* Creates a rotation matrix. General purpose routine for angles and a given matrix.
* IN:		d0-d2, x,y,z thetas
*		a0, Adr of rotation matrix
*		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

Calc_Rotation_Matrix:

	ifne	VEC_Q14_GENSIN
		move.l	CTRL_SINETAB_ROT_PTR(a5),a1	;Sine
		lea	ROT_SIN_TABLE_COS_OFFSET(a1),a2	;Cosine
	else
		lea	LIB_SIN_Q14_1024W_Table,a1		;Sine
		lea	LIB_COS_Q14_1024W_Table,a2		;Cosine
	endif
	
	move.w	(a1,d0.w),a3
	move.w	(a2,d0.w),d6
	move.w	(a1,d1.w),d5
	move.w	(a2,d1.w),d4
	move.w	(a1,d2.w),d3
	move.w	(a2,d2.w),d2

;all thetas have been taken care of - now init rot matrix

	;SinX = a3 , CosX = d6
	;SinY = d5 , CosY = d4
	;SinZ = d3 , CosZ = d2


; 3D composite rotation in ZYX order

; ( CosYCosZ		    -CosYSinZ		    SinY      )	 1
; ( SinXSinYCosZ+CosXSinZ   -SinXSinYSinZ+CosXCosZ  -SinXCosY )  2
; ( -CosXSinYCosZ+SinXSinZ  CosXSinYSinZ+SinXCosZ   CosXCosY  )  3
;             1                       2                 3

	moveq	#0,d7			;For improving rounding error with addx.w d7,xxx
;rot11
	move.w	d4,d0			;cosY
	muls	d2,d0			;cosYcosZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding
	
	move.w	d0,(a0)+		;Rot11

;rot12
	move.w	d4,d0			;cosY
	neg.w	d0			;-CosY
	muls	d3,d0			;-cosYsinZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	d0,(a0)+		;Rot12

;rot13
	move.w	d5,(a0)+		;Rot13   (SinY)

;rot21
	move.w	a3,d0			;sinX
	muls	d5,d0     		;sinXsinY	

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	muls	d2,d0			;sinXsinYCosZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	d6,d1			;cosX
	muls	d3,d1			;cosXSinZ

	add.l	d1,d1
	add.l	d1,d1
	add.w	d1,d1			;Improve rounding
	swap	d1			;/16384
	addx.w	d7,d1			;Improve rounding

	add.w	d1,d0
	move.w	d0,(a0)+		;Rot21

;rot22
	move.w	a3,d0			;sinX
	neg.w	d0			;-sinX
	muls	d5,d0			;-sinXsinY

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	muls	d3,d0			;-sinXsinYsinZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	d6,d1			;cosX
	muls	d2,d1			;cosXCosZ

	add.l	d1,d1
	add.l	d1,d1
	add.w	d1,d1			;Improve rounding
	swap	d1			;/16384
	addx.w	d7,d1			;Improve rounding

	add.w	d1,d0
	move.w	d0,(a0)+		;Rot22

;rot23
	move.w	a3,d0			;sinX
	neg.w	d0			;-sinX
	muls	d4,d0			;-sinXcosY

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	d0,(a0)+		;Rot23

;rot31
	move.w	d6,d0			;cosX
	neg.w	d0			;-cosX
	muls	d5,d0			;-cosXsinY

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	muls	d2,d0			;-cosXsinYcosZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	a3,d1			;sinX
	muls	d3,d1			;sinXsinZ

	add.l	d1,d1
	add.l	d1,d1
	add.w	d1,d1			;Improve rounding
	swap	d1			;/16384
	addx.w	d7,d1			;Improve rounding

	add.w	d1,d0
	move.w	d0,(a0)+		;Rot31

;rot32
	move.w	d6,d0			;cosX
	muls	d5,d0			;cosXsinY	

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	muls	d3,d0			;cosXsinYsinZ

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	a3,d1			;sinX
	muls	d2,d1			;sinXcosZ

	add.l	d1,d1
	add.l	d1,d1
	add.w	d1,d1			;Improve rounding
	swap	d1			;/16384
	addx.w	d7,d1			;Improve rounding

	add.w	d1,d0
	move.w	d0,(a0)+		;Rot32

;rot33
	move.w	d6,d0			;cosX
	muls	d4,d0			;cosXcosY

	add.l	d0,d0
	add.l	d0,d0
	add.w	d0,d0			;Improve rounding
	swap	d0			;/16384
	addx.w	d7,d0			;Improve rounding

	move.w	d0,(a0)+		;Rot33
	
;rotation matrix is done

	rts


*****************************************************************************
* Rotates and translates an object using a precalculated rotation matrix to
* perform rotate in 9 multiplies rather than 12. Best for more than 3 points.
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Rotate_And_Translate:
	move.l	a5,-(sp)
	move.l	a6,-(sp)

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object

	movem.w	VEC_OBJ_POSX(a0),a4-a6	;get object position
	move.l	VEC_OBJ_PTS_PTR(a0),a0	;Unrotated pts

	lea	Vert_XYZ_Buf(pc),a1
	lea	VEC_MatrixRotObject(pc),a2

	moveq	#0,d7			;We use top word of d7 as 0 for addx rounding improvement
	move.w	(a0)+,d7		;number of points
	move.w	d7,(a1)+
	subq.w	#1,d7			;-1 for dbf
.rotloop
	swap	d7			;d7.w=0
	movem.w	(a0)+,d0-d2

	move.l	a2,a3			;save a2

	move.w	d0,d4
	move.w	d1,d5
	move.w	d2,d6

	muls	(a3)+,d4		;rot11
	muls	(a3)+,d5		;rot12
	muls	(a3)+,d6		;rot13
	add.l	d4,d5
	add.l	d5,d6
	add.l	d6,d6			;*4 and swap = divide by 16384
	add.l	d6,d6
	add.w	d6,d6			;Improve rounding
	swap	d6			;d6=new x coord
	addx.w	d7,d6			;Improve rounding
	
	add.w	a4,d6			;add x pos
	move.w	d6,(a1)+


	move.w	d0,d4
	move.w	d1,d5
	move.w	d2,d6

	muls	(a3)+,d4		;rot21
	muls	(a3)+,d5		;rot22
	muls	(a3)+,d6		;rot23
	add.l	d4,d5
	add.l	d5,d6
	add.l	d6,d6			;*4 and swap = divide by 16384
	add.l	d6,d6
	add.w	d6,d6			;Improve rounding
	swap	d6			;d6=new y coord
	addx.w	d7,d6			;Improve rounding

	add.w	a5,d6			;add y pos
	move.w	d6,(a1)+


	muls	(a3)+,d0		;rot31
	muls	(a3)+,d1		;rot32
	muls	(a3)+,d2		;rot33
	add.l	d0,d1
	add.l	d1,d2
	add.l	d2,d2			;*4 and swap = divide by 16384
	add.l	d2,d2
	add.w	d2,d2			;Improve rounding
	swap	d2			;d2=new z coord
	addx.w	d7,d2			;Improve rounding

	add.w	a6,d2			;add z pos
	move.w	d2,(a1)+

	swap	d7			;d7=counter
	dbf	d7,.rotloop

	move.l	(sp)+,a6
	move.l	(sp)+,a5

	rts


*****************************************************************************
* Performs perspective.
*
*    New Y = VEC_YOFFSET + (k*y) / (z+dist)
*        X = VEC_XOFFSET + (k*x) / (z+dist)
* (where k is a constant for this screen, dist is the distance from the 
* ROTATION point to the EYE on the Z-axis)
*
* For this routine, k=256, dist=256
*
* IN:
* OUT:
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

	ifne	0
Object_Perspective:
	move.w	#VEC_XOFFSET,d4
	move.w	#VEC_YOFFSET,d5
	move.w	#VEC_PERS_DIST,d6	;"dist"
	move.l	#VEC_PERS_K*256,a2	;*256 for 24.8 fixed point
	
	lea	Vert_XYZ_Buf(pc),a0		;rot pts 3d
	lea	Vert_XYZ_Pers_Buf(pc),a1	;perspective pts 2d

	move.w	(a0)+,d7		;num pts
	move.w	d7,(a1)+
	subq.w	#1,d7			;-1 for dbf
.persloop1:
	movem.w	(a0)+,d0-d2		;get x,y,z pts (movem extends to .l)

	add.w	d6,d2			;z+dist
	ble.s	.store			;trap div by zero and too close

	move.l	a2,d3			;VEC_PERS_K*256, *256 for 24.8 fixed point
	divu	d2,d3

	muls	d3,d0
	muls	d3,d1
	asr.l	#8,d0			;24.8 to integer
	asr.l	#8,d1
.store:	
	add.w	d4,d0			;add x offset
	neg.w	d1			;flip y axis for screen coords
	add.w	d5,d1			;add y axis
	
	move.w	d0,(a1)+		;store x
	move.w	d1,(a1)+		;store y
	addq.l	#2,a1			;skip z (don't need it)

	dbf	d7,.persloop1		;next pt

	rts
	endif


	ifne	0
Object_Perspective:
	move.w	#VEC_XOFFSET,d4
	move.w	#VEC_YOFFSET,d5
	move.w	#VEC_PERS_DIST,d6	;"dist"
	lea	Vert_XYZ_Buf(pc),a0		;rot pts 3d
	lea	Vert_XYZ_Pers_Buf(pc),a1	;perspective pts 2d

	move.w	(a0)+,d7		;num pts
	move.w	d7,(a1)+
	subq.w	#1,d7			;-1 for dbf
.persloop1:
	movem.w	(a0)+,d0-d2		;get x,y,z pts (movem extends to .l)

	add.w	d6,d2			;z+dist
	ble.s	.store			;trap div by zero and too close

	asl.l	#VEC_PERS_K_SHIFT,d0	;*256, k*x
	asl.l	#VEC_PERS_K_SHIFT,d1	;*256, k*y
	divs	d2,d0			;new x & y values
	divs	d2,d1
.store:	
	add.w	d4,d0			;add x offset
	neg.w	d1			;flip y axis for screen coords
	add.w	d5,d1			;add y axis
	
	move.w	d0,(a1)+		;store x
	move.w	d1,(a1)+		;store y
	addq.l	#2,a1			;skip z (don't need it)

	dbf	d7,.persloop1		;next pt

	rts
	endif


*****************************************************************************
* Does some precalcs for perspective to change two divs into 2 muls.
*    New Y = VEC_YOFFSET + (k*y) / (z+dist)
*        X = VEC_XOFFSET + (k*x) / (z+dist)
* For this routine, k=256, dist=256
*
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d3/a0
*****************************************************************************

; Our normal perspective is
; (256(scale) * x) / z + 256(screen dist)
; example x = 100, z = 500
; x * 256 / 500 = 51
; example x = 50, z = 2000
; x * 256 / 2000 = 6

; In our table z 500 = 32768 / 500 = 65
; example x = 100, z = 500
; 100 * 65 = 6500, then right shift 7 (/128) = 50
; In our table z 2000 = 32768 / 2000 = 16
; example x = 50, z = 2000
; 50 * 16= 400, then right shift 7 (/128) = 6

Perspective_Calc_ReciprocalTable:

	move.l	CTRL_PERS_RECIP_TABLE_PTR(a5),a0

	; If first z entry is 0, use the max value as it breaks div
	move.l	#16384,d2
	move.w	#(VEC_PERS_RECIP_NUMENTRIES)-1,d4
	move.w	#VEC_PERS_RECIP_START_Z,d0	
.loop	
	move.l	d2,d1			;16384
	divs	d0,d1			;16384 / z
	move.w	d1,(a0)+
	addq.w	#1,d0			;next z
	bne.s	.next
.zero:
	move.w	d2,(a0)+		;trap div by zero
	subq.w	#1,d4
	addq.w	#1,d0
.next:
	dbf	d4,.loop

	rts


*****************************************************************************
* Performs perspective using reciprocal table.
* Note have to keep the x,y values <127 to avoid overruns
*
*    New Y = VEC_YOFFSET + (k*y) / (z+dist)
*        X = VEC_XOFFSET + (k*x) / (z+dist)
* (where k is a constant for this screen, dist is the distance from the 
* ROTATION point to the EYE on the Z-axis)
*
* For this routine, k=256, dist=256
*
* IN:		
* OUT:		
* TRASHED:	d0-d3/a0
*****************************************************************************

	ifne	1
Object_Perspective:
	move.w	#VEC_XOFFSET,d4
	move.w	#VEC_YOFFSET,d5
	move.w	#VEC_PERS_DIST+(-1*VEC_PERS_RECIP_START_Z),d6	;"dist" plus 512 so that z=-512 is first table entry
	lea	Vert_XYZ_Buf(pc),a0		;rot pts 3d
	lea	Vert_XYZ_Pers_Buf(pc),a1	;perspective pts 2d
	move.l	CTRL_PERS_RECIP_TABLE_PTR(a5),a2

	move.w	(a0)+,d7		;num pts
	move.w	d7,(a1)+
	subq.w	#1,d7			;-1 for dbf
.persloop1:
	movem.w	(a0)+,d0-d2		;get x,y,z pts (movem extends to .l)
	
	asl.w	#VEC_PERS_K_SHIFT,d0	;*256, k*x
	asl.w	#VEC_PERS_K_SHIFT,d1	;*256, k*y

	add.w	d6,d2			;z+dist
	add.w	d2,d2			;word offset in table
	move.w	(a2,d2.w),d2		;16834 / z
	muls	d2,d0
	muls	d2,d1

	add.l	d0,d0
	add.l	d0,d0
	swap	d0			;/16384

	add.l	d1,d1
	add.l	d1,d1
	swap	d1			;/16384
.store:
	add.w	d4,d0			;add screen x offset
	neg.w	d1			;flip y axis for screen coords
	add.w	d5,d1			;add screen y offset

	move.w	d0,(a1)+		;store x
	move.w	d1,(a1)+		;store y
	addq.l	#2,a1			;skip z (don't need it)

	dbf	d7,.persloop1		;next pt

	rts
	endif

*****************************************************************************
* Calculates the bounding rectange of the rotated points. Points are expected to
* be in screen coordinates just prior to drawing.
* This uses the overall shape of an object so is used for clearing or filling
* the whole screen.
*
* IN:		
* OUT:
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

Screen_Calc_Clr_Bounding:
	lea	Vert_XYZ_Pers_Buf(pc),a0	;perspertive pts 2d

	move.w	(a0)+,d7		;num pts
	subq.w	#1,d7			;-1 for dbf

	move.w	(a0)+,d4		;first x
	move.w	(a0)+,d5		;first y
	addq.l	#2,a0			;skip z to next x,y,z

	; First coords, use these as the initial clip/fill values
	move.w	d4,d0			;min x
	move.w	d5,d1			;min y
	move.w	d4,d2			;max x
	move.w	d5,d3			;max y
	bra.s	.nextpt	
.loop
	move.w	(a0)+,d4		;x
	move.w	(a0)+,d5		;y
	addq.l	#2,a0			;skip to next x,y,z
.skipinit	
	cmp.w	d4,d0
	ble.s	.minx_nochange
	move.w	d4,d0			;new min x
	bra.s	.maxx_nochange		;therefore can't be new maxx
.minx_nochange:
	cmp.w	d4,d2
	bge.s	.maxx_nochange
	move.w	d4,d2			;new max x
.maxx_nochange:
	cmp.w	d5,d1
	ble.s	.miny_nochange
	move.w	d5,d1			;new min y
	bra.s	.maxy_nochange		;therefore can't be new maxy
.miny_nochange:
	cmp.w	d5,d3
	bge.s	.maxy_nochange
	move.w	d5,d3			;new max y
.maxy_nochange:

.nextpt:
	dbf	d7,.loop		;next pt
	;d0=minx, d1=miny, d2=maxx, d3=maxy


	move.l	SCR_Fill_Log_Details_Ptr(pc),a0
	lea	LineDraw3_nBpl_Vars(pc),a1


	ifne VEC_CLIPPING

	;Check if any points on the screen (object might be completely off screen)
	;also check that minx >= CLIPMINX, maxx <= CLIPMAXX etc
	move.w	LINEDRAW_CLIP_MINX(a1),d4
	move.w	LINEDRAW_CLIP_MINY(a1),d5

	cmp.w	d4,d2			;maxx < clipminx
	blt.s	.exitnofill		;off scr
	cmp.w	d5,d3			;maxy < clipminy
	blt.s	.exitnofill		;off scr

	cmp.w	d4,d0			;minx > clipminx
	bge.s	.minxok
	move.w	d4,d0			;clip minx
	ifne VEC_CLIPCHECK
		move.w	#1,.clip_flag	;flag clip
	endif
.minxok:
	cmp.w	d5,d1			;miny > clipminy
	bge.s	.minyok
	move.w	d5,d1			;reset miny
	ifne VEC_CLIPCHECK
		move.w	#1,.clip_flag	;flag clip
	endif
.minyok:

	move.w	LINEDRAW_CLIP_MAXX(a1),d4
	move.w	LINEDRAW_CLIP_MAXY(a1),d5

	cmp.w	d4,d0			;minx > clipmaxx
	bgt.s	.exitnofill		;off scr
	cmp.w	d5,d1			;miny < clipmaxy
	bgt.s	.exitnofill		;off scr

	cmp.w	d4,d2			;maxx < clipmaxx
	ble.s	.maxxok
	move.w	d4,d2			;clip maxx
	ifne VEC_CLIPCHECK
		move.w	#1,.clip_flag	;flag clip
	endif
.maxxok:
	cmp.w	d5,d3			;maxy < clipmaxy
	ble.s	.maxyok
	move.w	d5,d3			;reset maxy
	ifne VEC_CLIPCHECK
		move.w	#1,.clip_flag	;flag clip
	endif
.maxyok:
	endif				; VEC_CLIPPING

	; Store the new bounding box values in required regs

	;movem.w	d0-d3,VEC_SCR_FILL_MINX(a0)	;save min/maxy details
	bra.s	Calc_Screen_Clr_Bounding_BlitVars	;I:d0-d3/a0-a1 T:d0-d7/a0-a2
	;rts

.exitnofill:
	; No valid fill possible. Reset fill/clear buffers
	clr.l	SCR_FILL_SRCPTR(a0)
	rts

	ifne VEC_CLIPCHECK
.clip_flag:
	dc.w 	0
	endif


*****************************************************************************
* Calculates the bounding rectange of the rotated points. Points are expected to
* be in screen coordinates just prior to drawing.
* This uses the overall shape of an object so is used for clearing or filling
* the whole screen.
*
* IN:		a6, custom
*		a0, SCR_Fill_Log_Details_Ptr 
*		a1, LineDraw_Vars (for premult table)
*		d0-d3,minx,y,maxx,y
* OUT:
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

Calc_Screen_Clr_Bounding_BlitVars:

	;movem.w	SCR_FILL_MINX(a0),d0-d3

	;ASSERT: Our line draw routine does not draw the BOTTOM scanline so that
	;blitter fills work correctly. So we have to sub 1 to our maxy. This may
	;cause miny>maxy so have to handle that below in height calcs.
	subq.w	#1,d3

	ifne	VEC_DRAW_BOUNDING
		; Draw bounding box for debugging
		movem.l	d0-d7/a0-a6,-(sp)
		WAITBLIT_NASTY_A6
		move.l	#-1,bltafwm(a6)		;mask
		move.w	#BPL_BUF_MOD_LINE,bltcmod(a6)	;modulo interleaved
		move.l	#-$8000,bltbdat(a6)
		; --------
		move.l	BPL_Log1_Ptr(pc),a0
		lea	LineDraw3_nBpl_Vars(pc),a1
		move.w  #1,LINEDRAW_COLOR(a1)	;save color for linedraw routine
		bsr	LineDraw3_nBpl_ClipAndDrawFilled
		movem.l	(sp)+,d0-d7/a0-a6
	endif


; ***
; Now work out the blitter values for use in full screen fill/clear
; ***
	; minx = 3, maxy = 15
	; minx&-16 = 0, maxx&-16 = 0, width = 1 word
	moveq	#-16,d4
	and.w	d4,d0			;leftx on word boundary
	and.w	d4,d2			;rightx on word boundary
	move.w	d2,d5			;don't trash max x 
	sub.w	d0,d5			;width in pixels (word aligned)
	lsr.w	#4,d5			;width in words
	addq.w	#1,d5			;width+1, 0 to 304 is 20 words not 19 as calculated
	;move.w	d5,SCR_FILL_WORDWIDTH(a0)	;save for clear routine

	move.w	d3,d4			;don't trash max y
	sub.w	d1,d4			;height (miny may be >= maxy see notes above)
	bpl.s	.heightok
	clr.l	SCR_FILL_SRCPTR(a0)	;no fill
	rts

.heightok:
	addq.w	#1,d4			;height+1,  255-0 = 255, but height should be 256

	;move.w	d4,SCR_FILL_HEIGHT(a0)	;save for clear routine
	
	;moveq	#BPL_BUF_NUMPLANES,d0
	;mulu.w	d0,d4			
	;height * num bpl for interleaved
	ifeq	2-BPL_BUF_NUMPLANES
		add.w	d4,d4
	endif
	ifeq	3-BPL_BUF_NUMPLANES
		move.w	d4,d0
		add.w	d4,d4
		add.w	d0,d4
	endif
	ifeq	4-BPL_BUF_NUMPLANES
		add.w	d4,d4
		add.w	d4,d4
	endif
	ifeq	5-BPL_BUF_NUMPLANES
		move.w	d4,d0
		add.w	d4,d4
		add.w	d4,d4
		add.w	d0,d4
	endif

	lsl.w	#6,d4			;*64 = height portion of bltsize
	add.w	d5,d4			;Add word width, completed bltsize in d4
	move.w	d4,SCR_FILL_BLTSIZE(a0)	;save for clear routine

	;d2 = max x in pixels (on word boundary)
	;d3 = max y
	;d4 = bltsize
	;d5 = fill width in words

	add.w	d5,d5			;d5=width in bytes
	moveq	#BPL_BUF_BYTEWIDTH,d1	;screen width in bytes
	sub.w	d5,d1			;modulo
	move.w	d1,SCR_FILL_BYTEMODULO(a0)	;save for clear routine

	; our Blitter source has to be the last word on the last bitplane (desending mode)
	; For line 100
	; 100 * (ScreenByteWidth * NumBitplanes)
	; + (ScreenByteWidth * (NumBitplanes-1))
	; + rightx in bytes

	move.l	BPL_Log1_Ptr(pc),a2
	add.w	d3,d3			;access y mult table in words
	moveq	#0,d0
	move.w	LINEDRAW_MULT(a1,d3.w),d0
	add.l	d0,a2			;Can't use add.w if d0 may be > 32768
	;mulu	#BPL_BUF_MOD_LINE,d3
	;add.l	d3,a2				;Have to use add.l if d3 > 32767 bytes

	lsr.w	#3,d2			;rightx in bytes
	lea 	BPL_BUF_BYTEWIDTH*(BPL_BUF_NUMPLANES-1)(a2,d2.w),a2	;starting position is last word in block (descending mode)
	move.l	a2,SCR_FILL_SRCPTR(a0)	;save for clear routine
	rts


*****************************************************************************
* Calculates the what faces are visible. Uses final screen draw coords.
*
* c = (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1)			    
* Sign of c indicate visibility.
* This is just the z component of the 3d cross product. See notes.
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Calc_Visible_Faces_2D:
	move.l	CTRL_OBJECTINFO_PTR(a5),a2	;Current object
	move.l	VEC_OBJ_FACELIST_PTR(a2),a2	;Facelist for this object

	move.w	(a2)+,d6		;num faces
	ble.s	.exit			;no faces?
	subq.w	#1,d6			;-1 for dbf

	lea	Vert_XYZ_Pers_Buf+2(pc),a1	;skip numpts, x coords
	lea	Face_Visible_Buf+2(pc),a0	;skip numfaces

	moveq	#0,d7			;counter for visible faces
.hloop:	
	move.l	(a2)+,a3		;a3=adr of face data
	
	movem.w	VEC_FACE_VERTICES(a3),d0-d2	;indexes for x1,y1,x2,y2,x3,y3

	move.w	(a1,d1.w),d3		;x2
	sub.w	(a1,d0.w),d3		;(x2-x1)
	move.w	2(a1,d2.w),d4		;y3
	sub.w	2(a1,d0.w),d4		;(y3-y1)
	muls	d4,d3			;(x2-x1)(y3-y1)
	
	move.w	2(a1,d1.w),d4		;y2		
	sub.w	2(a1,d0.w),d4		;(y2-y1)
	move.w	(a1,d2.w),d5		;x3
	sub.w	(a1,d0.w),d5		;(x3-x1)
	muls	d5,d4			;(x3-x1)(y2-y1)
	
	sub.l	d4,d3			;d3=sign indicates visibility
	ble.b	.backface		;back face

.frontface:
	clr.w	VEC_FACE_FLAG_BACKFACE(a3)	;store front face flag
	move.l	a3,(a0)+		;store face adr in visble faces buffer
	addq.w	#1,d7			;inc num of faces
	dbf	d6,.hloop	
	bra.s	.updatecount

.backface:
	; If backface check the backface paper col, if negative then cull it
	; otherwise add it to the draw list so it can be drawn with alt colors
	; Note: leave color00, can do interesting things when used in complex vectors
	move.w	VEC_FACE_PAPER_BACKFACE(a3),d0
	bmi.s	.cull
	move.w	#1,VEC_FACE_FLAG_BACKFACE(a3)		;store back face flag
	move.l	a3,(a0)+		;store face adr in visble faces buffer
	addq.w	#1,d7			;inc num of faces
.cull:
	dbf	d6,.hloop	

.updatecount:
	move.w	d7,Face_Visible_Buf	;store num faces at start of Visible_Face_Buffer

.exit:
	rts


*****************************************************************************
* Calculates the what faces are visible. Uses the rotated 3d points.
* Calculates surface normal
* Does dot product of a vertex on the surface and the viewpoint
* Checks if visible
* If visible works out light
*
* This routine left in source just to prove can do visibiliy checks in object
* space. :)
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

	ifne	0
Object_Calc_Visible_Faces_3D:
	move.l	a6,-(sp)

	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	move.l	VEC_OBJ_FACELIST_PTR(a0),a0	;Facelist for this object

	lea	Vert_XYZ_Buf+2(pc),a1		;skip numpts, 3d coords
	lea	Face_Visible_Buf+2(pc),a6	;Output list of visible faces, skip num faces

	moveq	#0,d7			;d7 will be used for dbf and also counting visible faces
	move.w	(a0)+,d7		;number of faces 
	ble	.exit			;quit if no faces visible
	subq.w	#1,d7			;-1 for dbf
.faceloop:
	swap	d7			;save face counter, now visible face count

	move.l	(a0)+,a2		;face adr

; V12=(x2-x1,y2-y1,z2-z1)
; V13=(x3-x1,y3-y1,z3-z1)
;
; N of face:             nx                                      ny                                nz
; V12xV13 = ( (y2-y1)*(z3-z1)-(y3-y1)*(z2-z1), (x2-x1)*(z3-z1)-(x3-x1)*(z2-z1), (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1) )

	move.w	VEC_FACE_VERTICES(a2),a3	;1st vertex index
	move.w	VEC_FACE_VERTICES+2(a2),a4	;2nd vertex index

	move.w	0(a1,a4.w),d1		;x2
	sub.w	0(a1,a3.w),d1		;x2-x1 = V12x
	move.w	2(a1,a4.w),d2		;y2
	sub.w	2(a1,a3.w),d2		;y2-y1 = V12y
	move.w	4(a1,a4.w),d3		;z2
	sub.w	4(a1,a3.w),d3		;z2-z1 = V12z

	move.w	VEC_FACE_VERTICES+4(a2),a4	;3rd vertex index (a3=1st, a4=3rd vertex)

	move.w	0(a1,a4.w),d4		;x3
	sub.w	0(a1,a3.w),d4		;x3-x1 = V13x
	move.w	2(a1,a4.w),d5		;y3
	sub.w	2(a1,a3.w),d5		;y3-y1 = V13y
	move.w	4(a1,a4.w),d6		;z3
	sub.w	4(a1,a3.w),d6		;z3-z1 = V13z

	;nx
	move.w	d2,a3			;save
	move.w	d3,a4			;save
	muls	d6,d2			;(y2-y1)*(z3-z1)
	muls	d5,d3			;(y3-y1)*(z2-z1)
	sub.l	d3,d2			;nx = (y2-y1)*(z3-z1) - (y3-y1)*(z2-z1)
	move.l	d2,-(sp)		;save to stack
	move.w	a3,d2			;restore
	move.w	a4,d3			;restore

	;ny	
	move.w	d1,a4			;save
	muls	d6,d1			;(x2-x1)*(z3-z1)
	muls	d4,d3			;(x3-x1)*(z2-z1)
	sub.l	d3,d1			;ny = (x2-x1)*(z3-z1) - (x3-x1)*(z2-z1)
	move.l	d1,-(sp)		;save it
	move.w	a4,d1			;restore
	
	;nz
	muls   d5,d1			;(x2-x1)*(y3-y1)
	muls   d4,d2			;(x3-x1)*(y2-y1)
	sub.l  d2,d1			;nz = (y3-y1)*(x2-x1) - (x3-x1)*(y2-y1)
	
	move.l	d1,d2			;nz
	move.l	(sp)+,d1		;ny
	neg.l	d1			;negate ny (see notes.txt for LHS)
	move.l	(sp)+,d0		;nx

	;d0-d2 are x,y,z of normal. Our faces are defined in clockwise order in LHS
	;system. And the normal we have here is OUTWARD facing.

	;Get first vertex of surface, adjust the z for viewpoint distance and 
	;take the dot product to determine visibilty.
	;We dont' need the unit vector for this to work.
	move.w	VEC_FACE_VERTICES(a2),d3
	movem.w	(a1,d3.w),d3-d5		;x,y,z
	add.w	#VEC_PERS_DIST,d5	;adjust for viewpoint
	muls	d0,d3			;dot product
	muls	d1,d4
	muls	d2,d5
	add.l	d3,d4
	add.l	d4,d5
	bge.s	.nextface		;Not visible, don't store

	;Get unit vector size (multipled by 16384) for lighting
	ifne	VEC_NRML_SHIFT_SCALE
		;Keep in word range so we can square/dot product
		asr.l	#VEC_NRML_SHIFT_SCALE,d0		
		asr.l	#VEC_NRML_SHIFT_SCALE,d1
		asr.l	#VEC_NRML_SHIFT_SCALE,d2
	endif
	;bsr	Vec3_Normalize		;I:d0-d2.w, O:d0-d2.w, T:d0-d6

	;d0-d2 is the unit vector (scaled to 16384)
	;Do the dot product with the light unit vector (already scaled to 16384)
;	muls	CTRL_LIGHT_VEC_X(a5),d0
;	muls	CTRL_LIGHT_VEC_Y(a5),d1
;	muls	CTRL_LIGHT_VEC_Z(a5),d2
;	add.l	d2,d1
;	add.l	d1,d0			;dot product (needs scaling down by 16384)
;	ble.s	.lit
.notlit:
	;Not lit, store light value as 0
;	moveq	#0,d0
;	clr.w	VEC_FACE_LIGHT0_VAL(a2)
;	move.w	#1,VEC_FACE_FLAG_BACKFACE(a2)
;	bra.s	.nextface
.lit
	;Lit, scale value down so it's in 0-16384 range and store
;	add.l	d0,d0
;	add.l	d0,d0
;	swap	d0			;/16384
;	neg.w	d0
;	move.w	d0,VEC_FACE_LIGHT0_VAL(a2)
	move.l	a2,(a6)+		;store face adr in visble faces buffer
	move.w	#0,VEC_FACE_FLAG_BACKFACE(a2)		;store frontface flag
	addq.w	#1,d7			;inc num of faces

.nextface:
	swap	d7			;change counter
	dbf	d7,.faceloop		;next face

	swap	d7			;change counter
	move.w	d7,Face_Visible_Buf	;store number of visible faces

.exit:
	move.l	(sp)+,a6
	rts

	endif


*****************************************************************************
* Draw a simple object.
*
* IN:		a6
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Draw_Lines:
	move.l	a5,-(sp)

	lea 	Face_Visible_Buf(pc),a4

	move.w	(a4)+,d7		;num faces
	beq.s	.exit			;no faces to draw
	subq.w	#1,d7			;correct counter for dbf

	lea	LineDraw3_nBpl_Vars(pc),a1
	move.l	BPL_Log1_Ptr(pc),a2	;adr of screen
	lea	Vert_XYZ_Pers_Buf+2(pc),a5	;skip numpts

	;Setup line draw blit registers that don't change
	moveq	#-1,d0
	WAITBLIT_NASTY_A6
	move.l	d0,bltafwm(a6)		;mask
	move.w	#BPL_BUF_MOD_LINE,bltcmod(a6)	;modulo interleaved
	move.l	#$ffff8000,bltbdat(a6)
	; --------

.faceloop:	
	swap	d7			;save face counter

	move.l	(a4)+,a3		;a3=adr of face data
	move.w	VEC_FACE_FLAG_BACKFACE(a3),d0		;VISIBLE_FACE_BACKFACE flag (0 = normal, 1 = backface)
	add.w	d0,d0			;offset to VEC_FACE_PAPER or VEC_FACE_PAPER_BACKFACE
	add.w	d0,d0			;4 bytes away if backface colour
	move.w	VEC_FACE_PAPER(a3,d0.w),LINEDRAW_COLOR(a1) 

	;Num vertices. It's closed loop, with the last vertex the same as the first
	;so number of lines to draw is num verticies-1
	move.w	(a3),d7
	subq.w	#2,d7			;-1 for num lines, -1 for dbf
	lea	VEC_FACE_VERTICES(a3),a3	;Skip to Connections
.lineloop:
	move.w	(a3)+,d1		;index1
	move.w	(a3),d3			;index2
	movem.w	(a5,d1.w),d0-d1		;x1,y1
	movem.w	(a5,d3.w),d2-d3		;x2,y2

	move.l	a2,a0			;restore screen ptr
	bsr.s	LineDraw3_nBpl_ClipAndDrawFilled	; trashes d0-d6/a0

	dbf	d7,.lineloop		;more lines

	swap	d7			;restore face counter
	dbf	d7,.faceloop		;next face

.exit	
	move.l	(sp)+,a5
	rts				;byebye


*****************************************************************************
* LineDraw3 For filled vectors. Best when only drawing a line once.
* Single bitplanes / inconvex etc. 
* Coords are not saved as assumes that the next line will be different anyway.
*****************************************************************************

*****************************************************************************
* Original clipping coded by Prophet/Goldfire (Thomas Szirtes), 
* Bug fixed by Antiriad/Goldfire (Jonathan Bennett)
* Note: the left side isn't fill clipped. So use 0, or ensure you align
* The left side to the region being filled (word aligned minx essentially)
* This may draw a new vertical line at maxx to ensure filling works.
*
* IN:		a6, _custom
*		a0, screen address
*		a1, linedraw vars
*		d0-d3, x,y,x2,y2 of the line to draw
* OUT:		
* TRASHED:	d0-d6/a0 (linedraw on its own is d0-d4/a0)
*****************************************************************************

LineDraw3_nBpl_ClipAndDrawFilled:
	ifne VEC_CLIPPING

	cmp	d1,d3
	bgt.s	.ClipTop		;and always draw top to Bottom, y2>y1
	beq	.NoDrawLine
	exg	d1,d3
	exg	d0,d2
.ClipTop
	move.w	LINEDRAW_CLIP_MINY(a1),d4
	cmp	d4,d1
	bgt.b	.ClipBottom
	cmp	d4,d3
	bgt.s	.miss1			
	bra	.NoDrawLine		;Clip it all

.miss1	Sub	d1,d4			;Miny-Y1
	Move	d2,d5
	Sub	d0,d5			;x2-x1		
	Move	d3,d6
	Sub	d1,d6			;y2-y1
	Muls	d5,d4			;(x2-x1)*(miny-y1)
	Divs	d6,d4			;/(y2-y1)
	Add	d4,d0			;add to d0
	move.w	LINEDRAW_CLIP_MINY(a1),d1	;Clip d1

.ClipBottom
	move.w	LINEDRAW_CLIP_MAXY(a1),d4
	Cmp	d3,d4
	Bgt.s	.ClipRight
	Cmp	d1,d4
	Bgt.s	.miss2			
	bra	.NoDrawLine		;clip it all

.miss2	Sub	d3,d4			;MaxY-y2
	Move	d2,d5
	Sub	d0,d5			;x2-x1
	Move	d3,d6
	Sub	d1,d6			;y2-y1
	Muls	d5,d4			;(x2-x1)*(maxy-y2)
	Divs	d6,d4			;/(y2-y1)
	Add	d4,d2			;add 
	move.w	LINEDRAW_CLIP_MAXY(a1),d3
.ClipRight
; X1<X2 
	move.w	LINEDRAW_CLIP_MAXX(a1),d4		;d4=Maxx
	Cmp	d0,d2			;If X2<X1
	Beq.s	.CheckRStr		;Stop Division by 0
	Blt.s	.XCSwap			;Then do reverse Calc
	Cmp	d2,d4			;If x2<Maxx
	Bgt	.ClipLeft		;Don't Clip
	Cmp	d0,d4			;if x1>Maxx
	Ble.s	.ClipRightWhole		;Clipwholeline
	Sub	d2,d4			;(Maxx-x2)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x2
	Divs	d5,d4			;and divide by delta x
	Move	d3,d5			;copy y2
	Add	d4,d5			;add d4 to y2
	
	Movem	d0-d1/d5,-(sp)		;Drawing two lines, save
	move.l	a0,-(sp)
	Move	d5,d1
	Cmp	d1,d3
	Beq.s	.skip1
	move.w	LINEDRAW_CLIP_MAXX(a1),d2
	Move	d2,d0
	bsr	.DrawLine		;LINE DRAW CALL. Trashes d0-d4/a0
.skip1	
	move.l	(sp)+,a0
	Movem	(sp)+,d0-d1/d3		;Note d5 restored into d3 intentionally

	move.w	LINEDRAW_CLIP_MAXX(a1),d2
	Bra.b	.ClipLeft
.CheckRStr
	Cmp	d0,d4			;if x1>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Bra.s	.ClipLeft
.XCSwap
; X2<X1 
	Cmp	d0,d4			;if x1<d4
	Bgt.s	.ClipLeft		;don't clip
	Cmp	d2,d4			;if x2>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Sub	d0,d4			;(Maxx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y1
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Move	d1,d5			;copy y2
	Add	d4,d5			;add d4 to y1

	Movem	d2-d3,-(sp)		;Have to draw two lines
	move.l	a0,-(sp)
	Move	d5,d3
	Cmp	d1,d3
	Beq.s	.skip2
	move.w	LINEDRAW_CLIP_MAXX(a1),d0
	move	d0,d2
	bsr.s	.DrawLine		;LINE DRAW CALL. Trashes d0-d4/a0
.skip2	
	move.l	(sp)+,a0
	Movem	(sp)+,d2-d3

	move.w	d5,d1
	move.w	LINEDRAW_CLIP_MAXX(a1),d0
	Bra.s	.ClipLeft
.ClipRightWhole	
	move.w	LINEDRAW_CLIP_MAXX(a1),d2
	Move	d2,d0
	bra.b	.DrawLine
	
.ClipLeft
; X1>X2 Left Boundary Clip
	move.w	LINEDRAW_CLIP_MINX(a1),d4		;d4=Minx
	Cmp	d0,d2			;If X2<X1
	Beq.b	.CheckLStr		;Stop Division by 0
	Bgt.b	.XmCSwap		;Then do reverse Calc
	Cmp	d2,d4			;If x2>minx
	Blt.b	.DrawLine		;Don't Clip
	Cmp	d0,d4			;if x1<minx
	;Bgt.b	.ClipLeftWhole		;Clipwholeline
	Bgt	.NoDrawLine		;Clipwholeline
	Sub	d2,d4			;(Minx-x2)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d3			;add d4 to y1
	move.w	LINEDRAW_CLIP_MINX(a1),d2	;New x2 = Minx
	Bra.b	.DrawLine
.CheckLStr
	Cmp	d0,d4			;if x1>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.NoDrawLine		;Clipwholeline
	Bra.s	.DrawLine
;.ClipLeftWhole
	; Not implmented on left for speed
;	bra.s	.NoDrawLine
.XmCSwap
; X2>X1 Left Boundary Clip
	Cmp	d0,d4			;if x1<d4
	Blt.s	.DrawLine		;don't clip
	Cmp	d2,d4			;if x2>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.NoDrawLine		;Clipwholeline
	Sub	d0,d4			;(Minx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*minx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d1			;add d4 to y1
	move.w	LINEDRAW_CLIP_MINX(a1),d0	;New x1 = Minx

;.DrawLine	
;	bra	VEC_LineDraw3_DrawFilled	* CALL LINE DRAW
;.NoDrawLine
;	rts
	; ****
	; Fall through to line draw
	; ****

	endif	;VEC_CLIPPING


*****************************************************************************
* Calcs and draws a line in one go. Multiple bitplanes.
* Routine ensures that y2>y1 and draws from top of screen to bottom.
* Two ways of removing a corner (for blitter fill):
* - Point bltdpth to a blank word. This causes the FIRST pixel (top) to be
* not written to screen. In this case first scanline is never touched.
* - Reduce dy by one, which seems a kludge but seems to work. In this case
* the last scanline (bottom) is not drawn and is also slightly faster (one less y).
*
* IN:		a6, _custom)
*		a0, screen address
*		a1, linedraw vars
*			linedraw premult table must match the modulo
*		d0-d3, x,y,x2,y2 of the line to draw
* OUT:		
* TRASHED:	d0-d4/a0
*****************************************************************************

.DrawLine:
;LineDraw3_nBpl_DrawFilled:

	;The linedraw routine draws from top of screen to bottom. We want
	;y2 > y1 for the logic used.
	sub.w 	d1,d3			;dy
	beq	.NoDrawLine		;skip when y1=y2
	bpl.b	.line1			;ensure y2>y1
	exg	d0,d2				
	neg.w	d3			
	sub.w	d3,d1			
.line1:
	subq	#1,d3			;dy-1 for blit corner fix
					;replaced with bltdpth scratch space

	move.l	#$a4a0000f,d4		;$4a=inverted line, $ca=normal
	and.w	d0,d4			;x & 15
	ror.l	#4,d4			;get shift value in top of word for bltcon0, low word cleared for move.b later

	sub.w	d0,d2			;dx
	bpl.b	.line2
	neg.w	d2			;make dx postive
	addq	#2,d4
.line2:					

	; Mulu y version, ;ASSERT: d0 is positive.
;	lsr.w	#3,d0			;x1 to byte offset,odd address ignored
;	mulu	#BPL_BUF_MOD_LINE,d1
;	add.l	d1,a0			;update with yoffset, y maybe > 32767 so need to use add.l
;	add.w	d0,a0			;
	; ----
	; Table y lookup version, ;ASSERT: d0/d1 are positive.
	lsr.w	#3,d0			;x1 to byte offset, odd address ignored
	add.w	d1,d1			;y table access offset in words
	add.w	LINEDRAW_MULT(a1,d1.w),a0	;update with yoffset
	add.w	d0,a0			;update with xoffset, a0 is final screen address
	; ----

	cmp.w	d2,d3
	bmi.b	.line3
	addq	#1,d4					
	exg	d2,d3
.line3:
	move.w	d3,d1			;dy
	add.w	d1,d1			;2*dy; bltbmod
	swap	d1			;bltbmod in top word
	move.w	d3,d1
	sub.w	d2,d1			;dy-dx
	add.w	d1,d1			;2*(dy-dx) ; bltamod	
					;d1.l = bltbmod/bltamod
	add.w	d3,d3
	sub.w	d2,d3			;(2*dy)-dx ; bltaptl
	addx.w	d4,d4
	move.b	LINEDRAW_OCTANTS(a1,d4.w),d4	;d4.l now bltcon0/1 (d4.w is 0 before this)

	addq.w	#1,d2			;dx+1
	lsl.w	#6,d2			;move to bits 15-6
	addq.w	#2,d2			;bltsize

	move.w  LINEDRAW_COLOR(a1),d0	;get required color
	lsr.w	#1,d0			;Color bit set?
	bcc.s	.nextbpl		;No, next bpl
.colorloop
	WAITBLIT_A6

	; NOTE: These three lines can be moved out if drawing loads of lines at once
	;move.l	#-1,bltafwm(a6)		;mask
	;move.w	#BPL_BUF_MOD_LINE,bltcmod(a6)	;modulo, DMOD NOT required
	;move.l	#$ffff8000,bltbdat(a6)
	; --------
		
	move.l	d4,bltcon0(a6)		;bltcon0/bltcon1
	move.l	d1,bltbmod(a6) 		;bltbmod/bltamod
	move.l  a0,bltcpth(a6) 
	move.w	d3,bltaptl(a6)
	move.l	a0,bltdpth(a6) 
	;move.l	#FW_LineDraw_Scratch,bltdpth(a6) ;First pixel is written here (offscreen)
	move.w	d2,bltsize(a6)
.nextbpl:
	lea     BPL_BUF_MOD_BPL(a0),a0	;next bitplane
	lsr.w   #1,d0				;check next bit 
	bcs.s   .colorloop			;bit set?
	bne.s	.nextbpl			;any color left?
.NoDrawLine:	
	rts

;Linedraw variable structure
	rsreset
LINEDRAW_OCTANTS:	rs.b 8			;8 Octant byte values
LINEDRAW_COLOR:		rs.w 1			;Color of lines
LINEDRAW_CLIP_MINX	rs.w 1
LINEDRAW_CLIP_MINY	rs.w 1
LINEDRAW_CLIP_MAXX	rs.w 1
LINEDRAW_CLIP_MAXY	rs.w 1
LINEDRAW_MULT:		rs.w BPL_BUF_HEIGHT	;Mult table

	EVEN
LineDraw3_nBpl_Vars:
.octantbase = 3				;1=normal,3=1px per line (fill)
.octanttab:
	dc.b	$10+.octantbase		;LINEDRAW_OCTANTS
	dc.b	$50+.octantbase
	dc.b	$00+.octantbase
	dc.b	$40+.octantbase
	dc.b	$14+.octantbase
	dc.b	$54+.octantbase
	dc.b	$08+.octantbase
	dc.b	$48+.octantbase

	dc.w    0       		; LINEDRAW_COLOR

	dc.w	VEC_CLIPMINX		; LINEDRAW_CLIP_MINX
	dc.w	VEC_CLIPMINY		; LINEDRAW_CLIP_MINY
	dc.w	VEC_CLIPMAXX		; LINEDRAW_CLIP_MAXX
	dc.w	VEC_CLIPMAXY		; LINEDRAW_CLIP_MAXY

Mult_SCR_Height_ByteWidth_NumPlanes:
	ds.w	BPL_BUF_HEIGHT		;LINEDRAW_MULT_NBPL


*****************************************************************************
* Rotates and translates an object in 12 multiplies. For use on a very small
* number of pts. Otherwise use Object_Rotate_And_Translate.
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Lights_Rotate_And_Translate:
	tst.w	CTRL_LIGHTS_ENABLED(a5)	;lights enabled?
	beq	.exit

	move.l	a6,-(sp)			;save
	move.l	CTRL_OBJECTINFO_PTR(a5),a6	;Current object for translating position

	lea	CTRL_LIGHT0_PTR(a5),a0
	moveq	#VEC_LIGHTS_NUMMAX-1,d7	;-1 for dbf
.lightloop:
	move.l	(a0)+,a1		;light ptr
	cmp.w	#LIGHTF_POINT,LIGHT_TYPE(a1)	;Only rotating enabled and point lights
	bne	.nextlight

	;Update angles, must be stored THETA_X,YZ,DX,DY,DZ
	movem.w	LIGHT_THETA_X(a1),d0-d5	; current d0-d2, delta d3-d5

	; have to increase the rotation speed if not a one frame vector
	; so that 1 frame, 2 frame,3 frame vectors move at same apparent speed
	add.w	d3,d0
	add.w	d4,d1
	add.w	d5,d2

	move.w	#ROT_SIN_TABLE_OFFSET_MASK,d3
	and.w	d3,d0				;ensure in range
	and.w	d3,d1
	and.w	d3,d2
	movem.w d0-d2,LIGHT_THETA_X(a1)		;save new values

	ifne	VEC_Q14_GENSIN
		move.l	CTRL_SINETAB_ROT_PTR(a5),a2	;Sine
		lea	ROT_SIN_TABLE_COS_OFFSET(a2),a3	;Cosine

	else
		lea	LIB_SIN_Q14_1024W_Table,a2
		lea	LIB_COS_Q14_1024W_Table,a3
	endif

	;Order of ZSIN to XCOS is fixed
	lea	CTRL_TMP_ZSIN(a5),a4
	move.w	(a2,d2.w),(a4)+		;ZSIN
	move.w	(a3,d2.w),(a4)+		;ZCOS
	move.w	(a2,d1.w),(a4)+		;YSIN
	move.w	(a3,d1.w),(a4)+		;YCOS
	move.w	(a2,d0.w),(a4)+		;XSIN
	move.w	(a3,d0.w),(a4)+		;XCOS

	lea	CTRL_TMP_ZSIN(a5),a2	;Quick access
	move.l	a2,a3

	;Get our light position x,y,z
	movem.w	LIGHT_BASEPOS_X(a1),d4-d6

.rotatez:
	move.w	d4,d0			;x
	move.w	d5,d1			;y

	move.w	d0,d2			;x	
	move.w	d1,d3			;y
	
	muls	(a2)+,d3		;zsin*y
	muls	(a2)+,d0		;zcos*x
	sub.l	d3,d0
	add.l	d0,d0			;*4 and swap = divide by 16384
	add.l	d0,d0
	swap	d0			;new x
	
	muls	(a3)+,d2		;zsin*x
	muls	(a3)+,d1		;zcos*y
	add.l	d2,d1
	add.l	d1,d1			;*4 and swap = divide by 16384
	add.l	d1,d1
	swap	d1			;new y

	move.w	d0,d4			;save x
	move.w	d1,d5			;save y
.rotatey:
	move.w	d6,d1			;z
	
	move.w	d0,d2			;x
	move.w	d1,d3			;z
	
	muls	(a2)+,d3		;ysin*z
	muls	(a2)+,d0		;ycos*x
	sub.l	d3,d0			
	add.l	d0,d0			;*4 and swap = divide by 16384
	add.l	d0,d0
	swap	d0			;new x
	
	muls	(a3)+,d2		;ysin*x
	muls	(a3)+,d1		;ycos*z
	add.l	d2,d1
	add.l	d1,d1			;*4 and swap = divide by 16384
	add.l	d1,d1
	swap	d1			;new z

	move.w	d0,d4			;save x
	move.w	d1,d6			;save z
.rotatex:
	move.w	d5,d0			;y
	
	move.w	d0,d2			;y
	move.w	d1,d3			;z
	
	muls	(a2)+,d3		;xsin*z
	muls	(a2)+,d0		;xcos*y
	sub.l	d3,d0
	add.l	d0,d0			;*4 and swap = divide by 16384
	add.l	d0,d0
	swap	d0			;new y
	
	muls	(a3)+,d2		;xsin*y
	muls	(a3)+,d1		;xcos*z
	add.l	d2,d1
	add.l	d1,d1			;*4 and swap = divide by 16384
	add.l	d1,d1
	swap	d1			;new z

	;write out final coords, translate them to object space
	add.w	VEC_OBJ_POSX(a6),d4
	move.w	d4,LIGHT_POS_X(a1)	;new x

	add.w	VEC_OBJ_POSY(a6),d0
	move.w	d0,LIGHT_POS_Y(a1)	;new y

	move.w	d1,LIGHT_POS_Z_NOTRANS(a1)	;new z without object z trans
	add.w	VEC_OBJ_POSZ(a6),d1
	move.w	d1,LIGHT_POS_Z(a1)	;new z

.nextlight:
	dbf	d7,.lightloop		;next light

	move.l	(sp)+,a6		;restore

.exit:
	rts	


*****************************************************************************
* Regenerates the light vector information if needed (object moved and using 
* point light etc)
* Get object position and subtract from light position then create the unit normal.
*
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

Lights_Calc_Unit_Normal:
	tst	CTRL_LIGHTS_ENABLED(a5)	;Any lights?
	beq.s	.exit

	move.l	CTRL_OBJECTINFO_PTR(a5),a0
	lea	CTRL_LIGHT0_PTR(a5),a1	
	moveq	#VEC_LIGHTS_NUMMAX-1,d7	;-1 for dbf
.lightloop:
	move.l	(a1)+,a2		;Get next light info
	cmp.w	#LIGHTF_POINT,LIGHT_TYPE(a2)	;Check type, we don't care about disabled
	bne.s	.nextlight			;or planar lights (already calculated at setup)

	;Enabled point light, work out vector to object position
	movem.w	VEC_OBJ_POSX(a0),d0-d2

	sub.w	LIGHT_POS_X(a2),d0
	sub.w	LIGHT_POS_Y(a2),d1
	sub.w	LIGHT_POS_Z(a2),d2

	bsr	Vec3_Normalize		;I:d0-d2.w, O:d0-d2.w, T:d0-d6
	movem.w	d0-d2,LIGHT_NORMAL_X(a2)
	move.w	#VEC_UNITY_LEN,LIGHT_NORMAL_LEN(a2)
.nextlight:
	dbf	d7,.lightloop
.exit:
	rts



*****************************************************************************
* Syncs the brightness of the lights along with a value (can be used with music)
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Lights_Sync_Brightness_With_Music:
	;lightsource?
	;rts
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	bne.s	.active
	rts
.active:
	lea	CTRL_LIGHT0_PTR(a5),a2

	move.w	CTRL_MUSICSYNC(a5),a4		;Get E8x value

	moveq	#VEC_LIGHTS_NUMMAX-1,d7
.loop:
	move.w	d7,a3				;save
	move.l	(a2)+,a1			;next light ptr

	move.w	a4,d0				;restore music sync

	;Is this enabled for light fading/music syncing?
	tst.w	LIGHT_FADE_STEP(a1)
	bne.s	.syncenabled
	lsr.w	#1,d0				;drop unused sync bit
	move.w	d0,a4				;resave
	bra.s	.next				;next light

.syncenabled:
	lsr.w	#1,d0				;set carry bit if sync received
	move.w	d0,a4
	bcc.s	.nosync

	moveq	#0,d2				;sync, reset to max brightness
	bra.s	.l0ok
.nosync
	move.w	LIGHT_FADE_VAL(a1),d2
	add.w	LIGHT_FADE_STEP(a1),d2

	move.w	#LIGHT_DIM_VAL_MAX,d1
	cmp.w	d1,d2
	bls.s	.l0ok
	move.w	d1,d2				;Stay at maximum dimness
.l0ok:
	move.w	d2,LIGHT_FADE_VAL(a1)

	move.w	LIGHT_COLOR(a1),d0		;source color
	move.w	LIGHT_COLOR_AMBIENT(a1),d1	;dest color
	lsr.w	#LIGHT_DIM_VAL_SHIFT,d2		;get into 0-15 range for fade step
	jsr	LIB_RGB12_Interpolate_Fast	;I:d0-d2, T:d0-d4/a0
	
	;Mark as generated already so not repeated in Lights_Create_Light_Palette
	clr.w	LIGHT_COLOR_GENPALETTE(a1)	

	move.w	d0,d1				;Dest color
	move.w	LIGHT_COLOR_AMBIENT(a1),d0	;source color
	lea	LIGHT_COLOR_PALETTE(a1),a0
	jsr	LIB_RGB12_Interpolate_Fast_AllSteps	;I:d0-d2/a0, T:d0-d7/a0-a1

.next:
	move.w	a3,d7				;restore count
	dbf	d7,.loop

.exit:
	rts


*****************************************************************************
* Works out the 15 steps of brightness for each light. 
* Lights_Sync_Brightness_With_Music may have already done this and will have
* cleared LIGHT_COLOR_GENPALETTE to avoid repeating.
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Lights_Create_Light_Palette:
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	bne.s	.active
	rts
.active:
	lea	CTRL_LIGHT0_PTR(a5),a2

	moveq	#VEC_LIGHTS_NUMMAX-1,d2
.loop:
	move.l	(a2)+,a0			;next light ptr

	tst.w	LIGHT_COLOR_GENPALETTE(a0)
	beq.s	.next
	clr.w	LIGHT_COLOR_GENPALETTE(a0)	;Mark as generated

	;Generate a 16 color palette from LIGHT_COLOR_AMBIENT to LIGHT_COLOR
	move.w	LIGHT_COLOR_AMBIENT(a0),d0
	move.w	LIGHT_COLOR(a0),d1

	lea	LIGHT_COLOR_PALETTE(a0),a0
	move.l	a0,a4

	move.w	d2,a3
	jsr	LIB_RGB12_Interpolate_Fast_AllSteps	;T:d0-d7/a0-a1
	move.w	a3,d2

	;move.w	#$00f,(a4)
	;move.w	#$fff,15*2(a4)

.next:
	dbf	d2,.loop

	rts


*****************************************************************************
* Calculates illumination details for visible faces. Uses the rotated pts 
* before perspective.
*  - Works out surface normal vector for the face
*  - Works out dot product of surface normal and light source vector
* Uses precalculated surface normal length. Lightsource must be unity length (16384)
*
* This routine is only useful with 1 light. Otherwise it's best to calculate the normals
* in another routine and store with face data for further light processing.
*
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Calc_Visible_Face_Normals_And_Light:
	move.l	a5,-(sp)

	;Are we using lights?
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq	.exit

	move.l	CTRL_LIGHT0_PTR(a5),a5	;Note a5 no longer is Controller_Info

	; Calc each face
	lea	Face_Visible_Buf(pc),a0	;visible faces (already determined)
	lea	Vert_XYZ_Buf+2(pc),a1	;skip numpts, 3d coords

	move.w	(a0)+,d7		;number of visible faces 
	ble	.exit			;quit if no faces visible
	subq.w	#1,d7			;-1 for dbf
.faceloop:
	move.l	(a0)+,a2		;face adr

	; Is it a backface? Don't mess with those
	tst.w	VEC_FACE_FLAG_BACKFACE(a2)
	bne	.notlit

; V12=(x2-x1,y2-y1,z2-z1)
; V13=(x3-x1,y3-y1,z3-z1)
; N of face:             nx                                      ny                                nz
; V12xV13 = ( (y2-y1)*(z3-z1)-(y3-y1)*(z2-z1), (x2-x1)*(z3-z1)-(x3-x1)*(z2-z1), (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1) )

	move.w	VEC_FACE_VERTICES(a2),a3	;1st vertex index
	move.w	VEC_FACE_VERTICES+2(a2),a4	;2nd vertex index

	move.w	0(a1,a4.w),d1		;x2
	sub.w	0(a1,a3.w),d1		;x2-x1 = V12x
	move.w	2(a1,a4.w),d2		;y2
	sub.w	2(a1,a3.w),d2		;y2-y1 = V12y
	move.w	4(a1,a4.w),d3		;z2
	sub.w	4(a1,a3.w),d3		;z2-z1 = V12z

	move.w	VEC_FACE_VERTICES+4(a2),a4	;3rd vertex index (a3=1st, a4=3rd vertex)

	move.w	0(a1,a4.w),d4		;x3
	sub.w	0(a1,a3.w),d4		;x3-x1 = V13x
	move.w	2(a1,a4.w),d5		;y3
	sub.w	2(a1,a3.w),d5		;y3-y1 = V13y
	move.w	4(a1,a4.w),d6		;z3
	sub.w	4(a1,a3.w),d6		;z3-z1 = V13z

	;nx
	move.w	d2,a3			;save
	move.w	d3,a4			;save
	muls	d6,d2			;(y2-y1)*(z3-z1)
	muls	d5,d3			;(y3-y1)*(z2-z1)
	sub.l	d3,d2			;nx = (y2-y1)*(z3-z1) - (y3-y1)*(z2-z1)
	move.l	d2,-(sp)		;save to stack
	move.w	a3,d2			;restore
	move.w	a4,d3			;restore

	;ny	
	move.w	d1,a4			;save
	muls	d6,d1			;(x2-x1)*(z3-z1)
	muls	d4,d3			;(x3-x1)*(z2-z1)
	sub.l	d3,d1			;ny = (x2-x1)*(z3-z1) - (x3-x1)*(z2-z1)
	move.l	d1,-(sp)		;save it
	move.w	a4,d1			;restore
	
	;nz
	muls   d5,d1			;(x2-x1)*(y3-y1)
	muls   d4,d2			;(x3-x1)*(y2-y1)
	sub.l  d2,d1			;nz = (y3-y1)*(x2-x1) - (x3-x1)*(y2-y1)
	
	move.l	d1,d2			;nz
	move.l	(sp)+,d1		;ny
	neg.l	d1			;negate ny (see notes.txt for LHS)
	move.l	(sp)+,d0		;nx

	;d0-d2 are x,y,z of normal. Our faces are defined in clockwise order in LHS
	;system. And the normal we have here is OUTWARD facing.

	ifne	VEC_NRML_SHIFT_SCALE
		;Keep in word range so we can square/dot product
		asr.l	#VEC_NRML_SHIFT_SCALE,d0		
		asr.l	#VEC_NRML_SHIFT_SCALE,d1
		asr.l	#VEC_NRML_SHIFT_SCALE,d2
	endif

	movem.w	d0-d2,VEC_FACE_NORMAL_X(a2)

	ifne	VEC_NRML_CALC_LEN_ONCE
		;Check if we have a valid surface normal magnitude, if not calculate and store now
		;Only working out the normal magnitude once seems to lead to flickering issues.
		tst.w	VEC_FACE_NORMAL_LEN(a2)
		bgt.s	.nextface
	endif

	movem.l	d0-d3,-(sp)
	muls	d0,d0			;squares
	muls	d1,d1
	muls	d2,d2
	add.l	d2,d1			;sum of squares
	add.l	d1,d0
	jsr	LIB_Sqrt_FastNewton	;I:d0.l, O:d0.w, T:d0-d3
	
	tst.w	d0
	bne.s	.notzero
	moveq	#1,d0			;Stop future div by zero
.notzero
	move.w	d0,VEC_FACE_NORMAL_LEN(a2)
	movem.l	(sp)+,d0-d3

.havelength:
	;d0-d2 is the NON-unit vector
	;Do the dot product with the light unit vector (already scaled to 16384)
	;Angle = N.L / |N| * |L|
	;|L| is VEC_UNITY_LEN (unity) which is too large to multiply by for a word
	;Instead we do:
	;A = (N.L / |L|) / |N|
	;A is -1 to 1 so at the same time we want to get it in the range 0-16 for a
	;colour table. This is the weird lsr.l #VEC_UNITY_LEN_SHIFT-4 part below.
	;If surface normal was unity then this dot product would be all we need to calculate
	;the light value.
	muls	LIGHT_NORMAL_X(a5),d0
	muls	LIGHT_NORMAL_Y(a5),d1
	muls	LIGHT_NORMAL_Z(a5),d2
	add.l	d2,d1
	add.l	d1,d0			;dot product
	blt.s	.lit			;Already from the sign we know if it's lit
.notlit:
	clr.w	VEC_FACE_LIGHT0_VAL(a2)
	bra.s	.nextface
.lit:	
	neg.l	d0			;Make positive
	divu	VEC_FACE_NORMAL_LEN(a2),d0	;/ |N|
	moveq	#VEC_UNITY_LEN_SHIFT-4,d1
	lsr.w	d1,d0			;/VEC_UNITY_LEN/16( |L| )

	;In range 0-16 (barely) so make it 0 to 15
	moveq	#15,d1
	cmp.w	d1,d0
	ble.s	.rangeok
	move.w	d1,d0
.rangeok:
	add.w	d0,d0
	move.w	LIGHT_COLOR_PALETTE(a5,d0.w),VEC_FACE_LIGHT0_VAL(a2)	;Final light color for surface

.nextface:
	dbf	d7,.faceloop		;next face

.exit:
	move.l	(sp)+,a5
	rts


*****************************************************************************
* Calculates and stores the visible face normals and lengths.
* 
*  - Calc surface normal vector for the face
*  - Calc normal length if needed (static if not transforming)
*  - Stores normal and length
*
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Calc_Visible_Face_Normals_And_Store:
	;Are we using lights?
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq	.exit

	move.l	a5,-(sp)
	move.l	a6,-(sp)

	; Calc each face
	lea	Face_Visible_Buf(pc),a0	;visible faces (already determined)
	lea	Vert_XYZ_Buf+2(pc),a1	;skip numpts, 3d coords

	move.w	(a0)+,d7		;number of visible faces 
	ble	.exit			;quit if no faces visible
	subq.w	#1,d7			;-1 for dbf
.faceloop:
	move.l	(a0)+,a2		;face adr

	; Is it a backface? Don't mess with those
	tst.w	VEC_FACE_FLAG_BACKFACE(a2)
	bne	.nextface

; V12=(x2-x1,y2-y1,z2-z1)
; V13=(x3-x1,y3-y1,z3-z1)
; N of face:             nx                                      ny                                nz
; V12xV13 = ( (y2-y1)*(z3-z1)-(y3-y1)*(z2-z1), (x2-x1)*(z3-z1)-(x3-x1)*(z2-z1), (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1) )

	move.w	VEC_FACE_VERTICES(a2),a3	;1st vertex index
	move.w	VEC_FACE_VERTICES+2(a2),a6	;2nd vertex index
	movem.w	(a1,a6.w),d0-d2		;x2,y2,z2
	movem.w	(a1,a3.w),a3-a5		;x1,y1,z1
	sub.w	a3,d0			;d0 = x2-x1 = V12x 
	sub.w	a4,d1			;d1 = y2-y1 = V12y
	sub.w	a5,d2			;d2 = z2-z1 = V12z

	move.w	VEC_FACE_VERTICES+4(a2),a6	;3rd vertex index (a3=1st, a4=3rd vertex)
	movem.w	(a1,a6.w),d3-d5		;x3
	sub.w	a3,d3			;d3 = x3-x1 = V13x
	sub.w	a4,d4			;d4 = y3-y1 = V13y
	sub.w	a5,d5			;d5 = z3-z1 = V13z

	;nx
	move.w	d1,a3			;save
	move.w	d2,a4			;save
	muls	d5,d1			;(y2-y1)*(z3-z1)
	muls	d4,d2			;(y3-y1)*(z2-z1)
	sub.l	d2,d1			;nx = (y2-y1)*(z3-z1) - (y3-y1)*(z2-z1)
	move.l	d1,a5			;save to stack
	move.w	a3,d1			;restore
	move.w	a4,d2			;restore

	;ny	
	move.w	d0,a4			;save
	muls	d5,d0			;(x2-x1)*(z3-z1)
	muls	d3,d2			;(x3-x1)*(z2-z1)
	sub.l	d2,d0			;ny = (x2-x1)*(z3-z1) - (x3-x1)*(z2-z1)
	move.l	d0,a6			;save it
	move.w	a4,d0			;restore
	
	;nz
	muls   d4,d0			;(x2-x1)*(y3-y1)
	muls   d3,d1			;(x3-x1)*(y2-y1)
	sub.l  d1,d0			;nz = (y3-y1)*(x2-x1) - (x3-x1)*(y2-y1)
	
	move.l	d0,d2			;nz
	move.l	a5,d0			;nx
	move.l	a6,d1			;ny
	neg.l	d1			;negate ny (see notes.txt for LHS)

	;d0-d2 are x,y,z of normal. Our faces are defined in clockwise order in LHS
	;system. And the normal we have here is OUTWARD facing.
	
	ifne	VEC_NRML_SHIFT_SCALE
		;Keep in word range so we can square/dot product
		asr.l	#VEC_NRML_SHIFT_SCALE,d0		
		asr.l	#VEC_NRML_SHIFT_SCALE,d1
		asr.l	#VEC_NRML_SHIFT_SCALE,d2
	endif

	movem.w	d0-d2,VEC_FACE_NORMAL_X(a2)

	ifne	VEC_NRML_CALC_LEN_ONCE
		;Check if we have a valid surface normal magnitude, if not calculate and store now
		;Only working out the normal magnitude once seems to lead to flickering issues.
		tst.w	VEC_FACE_NORMAL_LEN(a2)
		bgt.s	.nextface
	endif

	muls	d0,d0			;squares
	muls	d1,d1
	muls	d2,d2
	add.l	d2,d1			;sum of squares
	add.l	d1,d0
	jsr	LIB_Sqrt_FastNewton	;I:d0.l, O:d0.w, T:d0-d3
	
	tst.w	d0
	bne.s	.notzero
	moveq	#1,d0			;Stop future div by zero
.notzero
	move.w	d0,VEC_FACE_NORMAL_LEN(a2)
.nextface:
	dbf	d7,.faceloop		;next face

	move.l	(sp)+,a6
	move.l	(sp)+,a5
.exit:
	rts


*****************************************************************************
* Pre-calculates surface normal magnitudes for all surfaces and stores with
* face data. Must be run at first object load and whenever an object is 
* transforming.
*
* Note that we use the original pts for this. Not the rotated points.
*
* Having the magnitude eliminates the need to do square roots constantly 
* during light sourcing.
*
* IN:		
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

	ifne	VEC_NRML_CALC_LEN_ONCE
Calc_Surface_Normal_Lengths:
	move.l	CTRL_OBJECTINFO_PTR(a5),a0	;Current object
	move.l	VEC_OBJ_PTS_PTR(a0),a1		;Unrotated pts
	addq.l	#2,a1				;Skip numpts
	move.l	VEC_OBJ_FACELIST_PTR(a0),a0	;Facelist for this object

	move.w	(a0)+,d7		;number of faces 
	ble	.exit			;quit if no faces
	subq.w	#1,d7			;-1 for dbf
.faceloop:
	move.l	(a0)+,a2		;face adr

; Cross product
; V12=(x2-x1,y2-y1,z2-z1)
; V13=(x3-x1,y3-y1,z3-z1)
;
; N of face:             nx                                      ny                                nz
; V12xV13 = ( (y2-y1)*(z3-z1)-(y3-y1)*(z2-z1), (x2-x1)*(z3-z1)-(x3-x1)*(z2-z1), (x2-x1)*(y3-y1)-(x3-x1)*(y2-y1) )

	move.w	VEC_FACE_VERTICES(a2),a3	;1st vertex index
	move.w	VEC_FACE_VERTICES+2(a2),a4	;2nd vertex index

	move.w	0(a1,a4.w),d1		;x2
	sub.w	0(a1,a3.w),d1		;x2-x1 = V12x
	move.w	2(a1,a4.w),d2		;y2
	sub.w	2(a1,a3.w),d2		;y2-y1 = V12y
	move.w	4(a1,a4.w),d3		;z2
	sub.w	4(a1,a3.w),d3		;z2-z1 = V12z

	move.w	VEC_FACE_VERTICES+4(a2),a4	;3rd vertex index (a3=1st, a4=3rd vertex)

	move.w	0(a1,a4.w),d4		;x3
	sub.w	0(a1,a3.w),d4		;x3-x1 = V13x
	move.w	2(a1,a4.w),d5		;y3
	sub.w	2(a1,a3.w),d5		;y3-y1 = V13y
	move.w	4(a1,a4.w),d6		;z3
	sub.w	4(a1,a3.w),d6		;z3-z1 = V13z

	;nx
	move.w	d2,a3			;save
	move.w	d3,a4			;save
	muls	d6,d2			;(y2-y1)*(z3-z1)
	muls	d5,d3			;(y3-y1)*(z2-z1)
	sub.l	d3,d2			;nx = (y2-y1)*(z3-z1) - (y3-y1)*(z2-z1)
	move.l	d2,-(sp)		;save to stack
	move.w	a3,d2			;restore
	move.w	a4,d3			;restore

	;ny	
	move.w	d1,a4			;save
	muls	d6,d1			;(x2-x1)*(z3-z1)
	muls	d4,d3			;(x3-x1)*(z2-z1)
	sub.l	d3,d1			;ny = (x2-x1)*(z3-z1) - (x3-x1)*(z2-z1)
	move.l	d1,-(sp)		;save it
	move.w	a4,d1			;restore
	
	;nz
	muls   d5,d1			;(x2-x1)*(y3-y1)
	muls   d4,d2			;(x3-x1)*(y2-y1)
	sub.l  d2,d1			;nz = (y3-y1)*(x2-x1) - (x3-x1)*(y2-y1)
	
	move.l	d1,d2			;nz
	move.l	(sp)+,d1		;ny
	neg.l	d1			;negate ny (see notes.txt for LHS)
	move.l	(sp)+,d0		;nx

	;d0-d2 are x,y,z of normal. Our faces are defined in clockwise order in LHS
	;system. And the normal we have here is OUTWARD facing.

	ifne	VEC_NRML_SHIFT_SCALE
		;Keep in word range so we can square/dot product
		asr.l	#VEC_NRML_SHIFT_SCALE,d0		
		asr.l	#VEC_NRML_SHIFT_SCALE,d1
		asr.l	#VEC_NRML_SHIFT_SCALE,d2
	endif

;cos(a) = <N.L> / (|N| * |L|)
;(nx means the x-coordinate of N, ny the y-coordinate and so on, and 
;the same thing with L.)
;( nx*lx + ny*ly + ny*ly ) / ( sqr(nx*nx+ny*ny+nz*nz) * sqr(lx*lx+ly*ly+lz*lz) )

	; sum of squares
	muls	d0,d0
	muls	d1,d1
	muls	d2,d2
	add.l	d1,d0
	add.l	d2,d0

	; calculate the magnitude
	jsr	LIB_Sqrt_FastNewton		;I:d0.l, O:d0.l, T:d0-d3
	tst.w	d0
	bne.s	.notzero
	moveq	#1,d0			;Stop future div by zero
.notzero
	move.w	d0,VEC_FACE_NORMAL_LEN(a2)

.nextface:
	dbf	d7,.faceloop		;next face

.exit:
	rts
	endif


*****************************************************************************
* Calculates illumination details for visible faces. Uses the rotated pts 
* before perspective. 
* Must be run after :
*  - Lights_Calc_Unit_Normal  (works out light vectors)
*  - Object_Calc_Visible_Face_Normals_And_Store (works out surface normals and lengths)
* And then this routine does the following:
*  - Takes visible face list and surface normals, and normal lengths
*  - Works out dot product of surface normal and light source vector
* Uses precalculated surface normal length. Lightsource must be unity length (16384)
*
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Object_Calc_Visible_Face_Lighting:
	;Are we using lights?
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq	.exit

	; Calc each face
	lea	Face_Visible_Buf(pc),a0	;visible faces (already determined)

	move.w	(a0)+,d7		;number of visible faces 
	ble	.exit			;quit if no faces visible
	subq.w	#1,d7			;-1 for dbf
.faceloop:
	move.l	(a0)+,a1		;face adr
	lea	VEC_FACE_LIGHT0_VAL(a1),a4
	
	; Is it a backface? Don't mess with those
	tst.w	VEC_FACE_FLAG_BACKFACE(a1)
	beq	.frontface
	moveq	#0,d0
	move.l	d0,(a4)+		;VEC_FACE_LIGHT0_VAL and VEC_FACE_LIGHT1_VAL
	move.l	d0,(a4)			;VEC_FACE_LIGHT2_VAL, VEC_FACE_LIGHT3_VAL
	bra	.nextface

.frontface:
	moveq	#VEC_LIGHTS_NUMMAX-1,d6	;-1 for dbf
	lea	CTRL_LIGHT0_PTR(a5),a2
	movem.w	VEC_FACE_NORMAL_X(a1),d3-d5	;save normal x,y,z
.lightloop:
	move.l	(a2)+,a3		;Get light ptr 
	tst.w	LIGHT_TYPE(a3)		;Is light enabled?
	bne.s	.enabled
	clr.w	(a4)+			;No ambient color for non-enabled
	bra	.nextlight
.enabled:
	;d3-d5 are x,y,z of face non unit normal.

	;We do:
	;A = (N.L / |L|) / |N|
	; |L| = 1 (scaled to VEC_UNITY_LEN for quick shift div)
	;A is -1 to 1 so at the same time we want to get it in the range 0-16 for a
	;colour table. This is the weird lsr.l #VEC_UNITY_LEN_SHIFT-4 part below.
	movem.w	LIGHT_NORMAL_X(a3),d0-d2
	muls	d3,d0
	muls	d4,d1
	muls	d5,d2
	add.l	d2,d1
	add.l	d1,d0			;dot product of light unit normal and face non-unit normal
	ble.s	.lit			;Already from the sign we know if it's lit
;.notlit:
;	clr.w	(a4)+
;	bra.s	.nextlight
.ambient:
	move.w	LIGHT_COLOR_PALETTE(a3),(a4)+	;Add ambient color of this light
	bra.s	.nextlight
.lit:	
	neg.l	d0				;Make positive
	divu	VEC_FACE_NORMAL_LEN(a1),d0	;/ |N|, result now in range 0-VEC_UNITY_LEN
	subq.w	#1,d0				;in range 0-(VEC_UNITY_LEN-1)
	ble.s	.ambient

	moveq	#VEC_UNITY_LEN_SHIFT-4,d1
	lsr.w	d1,d0			;/VEC_UNITY_LEN/16( |L| ), result in range 0-15

	add.w	d0,d0
	move.w	LIGHT_COLOR_PALETTE(a3,d0.w),(a4)+	;Final light color for surface
.nextlight:
	dbf	d6,.lightloop

.nextface:
	dbf	d7,.faceloop		;next face

.exit:
	rts



*****************************************************************************
* Creates a palette for lightsourcing. Only useful on objects where the number
* unique face colors fits in with the number of bitplanes. For example a cube
* can be made so that it only uses 3 colors and therefore fits in a 2bpl palette.
*
* If lightsource not active then it just copies the palette.
*
* IN:		a5, Controller_Info
* OUT:
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Lights_Color_Faces:

	;lightsource?
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq	.copy

	; Read each face and set the palette colors based on lightsource values
	lea	PAL_Current(pc),a0
	lea	PAL_Current_LightSourced(pc),a1
	move.w	(a0),(a1)		;color00 is untouched

	lea	Face_Visible_Buf(pc),a2
	move.w	(a2)+,d7		;num faces
	beq	.exit			;No faces
	subq.w	#1,d7			;dbf and color00

.facel:
	move.l	(a2)+,a3		;a3=adr of face data

	;Add together all the lights first, using some ace 4 color add at once code from
	;Morbid, https://eab.abime.net/showpost.php?p=1446739&postcount=14
	movem.l	VEC_FACE_LIGHT0_VAL(a3),d0-d1	;4 light colors

	move.l #$88888888,d4

	; Add color1+3, 2+4 
	move.l	d0,d2
	eor.l	d1,d2
	and.l	d4,d2

	move.l	d1,d3
	and.l	d0,d3
	and.l	d4,d3
	
	not.l	d4
	and.l	d4,d0
	and.l	d4,d1
	
	add.l	d1,d0
	
	move.l	d2,d1
	and.l	d0,d1
	or.l	d1,d3

	move.l	d3,d1
	lsr.l	#3,d1
	add.l	d3,d3
	sub.l	d1,d3

	eor.l	d2,d0
	or.l	d3,d0
	
	; Now add color1+2 to color 3+4
	move.w	d0,d1
	swap	d0
	not.w	d4	;return d4 to $8888
	
	move.w	d0,d2
	eor.w	d1,d2
	and.w	d4,d2

	move.w	d1,d3
	and.w	d0,d3
	and.w	d4,d3
	
	not.w	d4
	and.w	d4,d0
	and.w	d4,d1
	
	add.w	d1,d0
	
	move.w	d2,d1
	and.w	d0,d1
	or.w	d1,d3

	move.w	d3,d1
	lsr.w	#3,d1
	add.w	d3,d3
	sub.w	d1,d3

	eor.w	d2,d0
	or.w	d3,d0	;d0.w is result

	;Add the ambient light, RGB12_ADD will skip if no ambient light
	move.w	CTRL_LIGHT_AMBIENT(a5),d1
	beq.s	.noambient
	RGB12_ADD			;I:d0-d1, O:d0, T:d0-d4
.noambient:

	ifne LIGHT_MODEL_SURFACE_COLOR
		;Get the surface color, invert it and subtract it from light color
		move.w	d0,d5			;save
		move.w	VEC_FACE_PAPER(a3),d6	;(top is clear)
		add.w	d6,d6			;access pal in words
		move.w	(a0,d6.w),d0		;face color
		RGB12_INVERT			;I:d0, O:d0, T:d0-d3
		move.w	d0,d1			;Inverted face color
		move.w	d5,d0			;Light color
		RGB12_SUB			;Sub d1 from d0, I:d0-d1, O:d0, T:d0-d5
		move.w	d0,(a1,d6.w)		;store new color
	else
		;Assumes a white surface - which generally looks the best
		move.w	VEC_FACE_PAPER(a3),d6	;(top is clear)
		add.w	d6,d6			;access pal in words
		move.w	d0,(a1,d6.w)		;face color
	endif

	dbf	d7,.facel
.exit:
	rts

.copy:
	lea	PAL_Current(pc),a0
	lea	PAL_Current_LightSourced(pc),a1
	rept	PAL_NUMCOLS_ALL/2		;Num longs
	move.l	(a0)+,(a1)+
	endr

	rts	


*****************************************************************************
* Draws the lights with sprites. Can be done after the main scene is drawn
* as we use sprites that can be drawn in front/behind the playfield.
* IN:		a5, Controller_Info
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

Lights_Draw:
	; Clear existing sprite list as we may reorder new lights or skip sprites
	move.l	CL_Log1_Ptr(pc),a0
	lea	P0_CL_SPRITES_OFFSET(a0),a0	;copper spr pointer block
	moveq	#VEC_LIGHTS_NUMMAX*2,d0	;Each light is 2 sprites for 32x32
	jsr	FW_ClrCopperSprPtrs	;I:d0/a0, T:d0-d2/a0-a1

	;Any lights enabled
	tst.w	CTRL_LIGHTS_ENABLED(a5)
	beq	.exit

	;Sort lights into order light0=nearest, light2=furthest
	;Unused lights or planar lights should be set to distance 32767 so they 
	;are furthest always and don't mess up this sort
	;can sort 4 items in 5 comparisons
	;if(num0>num1) swap(&num0,&num1);
	;if(num2>num3) swap(&num2,&num3);
	;if(num0>num2) swap(&num0,&num2);
	;if(num1>num3) swap(&num1,&num3);
	;if(num1,num2) swap(&num1,&num2);

	movem.l	CTRL_LIGHT0_PTR(a5),a0-a3
	move.w	LIGHT_POS_Z(a0),d0
	move.w	LIGHT_POS_Z(a1),d1
	move.w	LIGHT_POS_Z(a2),d2
	move.w	LIGHT_POS_Z(a3),d3
	cmp.w	d0,d1			;Compare 0 and 1
	bge.s	.noswap0
	exg	a0,a1
	exg	d0,d1
.noswap0:
	cmp.w	d2,d3			;Compare 2 and 3
	bge.s	.noswap1
	exg	a2,a3
	exg	d2,d3
.noswap1:
	cmp.w	d0,d2			;Compare 0 and 2
	bge.s	.noswap2
	exg	a0,a2
	exg	d0,d2
.noswap2:
	cmp.w	d1,d3			;Compare 1 and 3
	bge.s	.noswap3
	exg	a1,a3
	exg	d1,d3
.noswap3:
	cmp.w	d1,d2			;Compare 1 and 2
	bge.s	.noswap4
	exg	a1,a2
	exg	d1,d2
.noswap4:

	movem.l	a0-a3,CTRL_LIGHT0_SORTED_PTR(a5)	;Save new order
	;d0-d3 is are the z-values of sprites in order from near to far
	;a0-a3 are ptrs to the sorted lights

	;Write the colors of the sorted lights into the CL
	move.l	CL_Log1_Ptr(pc),a4

	move.w	LIGHT_COLOR_PALETTE+7*2(a0),P0_CL_COL_SPR01_OFFSET+2(a4)	;col17
	move.w	LIGHT_COLOR_PALETTE+10*2(a0),P0_CL_COL_SPR01_OFFSET+6(a4)
	move.w	LIGHT_COLOR_PALETTE+15*2(a0),P0_CL_COL_SPR01_OFFSET+10(a4)

	move.w	LIGHT_COLOR_PALETTE+7*2(a1),P0_CL_COL_SPR23_OFFSET+2(a4)	;col21
	move.w	LIGHT_COLOR_PALETTE+10*2(a1),P0_CL_COL_SPR23_OFFSET+6(a4)
	move.w	LIGHT_COLOR_PALETTE+15*2(a1),P0_CL_COL_SPR23_OFFSET+10(a4)

	move.w	LIGHT_COLOR_PALETTE+7*2(a2),P0_CL_COL_SPR45_OFFSET+2(a4)	;col25
	move.w	LIGHT_COLOR_PALETTE+10*2(a2),P0_CL_COL_SPR45_OFFSET+6(a4)
	move.w	LIGHT_COLOR_PALETTE+15*2(a2),P0_CL_COL_SPR45_OFFSET+10(a4)

	move.w	LIGHT_COLOR_PALETTE+7*2(a3),P0_CL_COL_SPR67_OFFSET+2(a4)	;col29
	move.w	LIGHT_COLOR_PALETTE+10*2(a3),P0_CL_COL_SPR67_OFFSET+6(a4)
	move.w	LIGHT_COLOR_PALETTE+15*2(a3),P0_CL_COL_SPR67_OFFSET+10(a4)

	;Find position of object - the playfield and set bplcon2 value
	move.l	CTRL_OBJECTINFO_PTR(a5),a0
	move.w	VEC_OBJ_POSZ(a0),d4
	
	cmp.w	d0,d4
	bgt.s	.tst1
	clr.w	P0_CL_BPLCON2_OFFSET+2(a4)		;PF->SPR0->SPR2->SPR4->SPR6
	bra.s	.tstdone
.tst1
	cmp.w	d1,d4
	bgt.s	.tst2
	move.w	#$0008,P0_CL_BPLCON2_OFFSET+2(a4)	;SPR0->PF->SPR2->SPR4->SPR6
	bra.s	.tstdone
.tst2
	cmp.w	d2,d4
	bgt.s	.tst3
	move.w	#$0010,P0_CL_BPLCON2_OFFSET+2(a4)	;SPR0->SPR2->PF->SPR4->SPR6
	bra.s	.tstdone
.tst3
	cmp.w	d3,d4
	bgt.s	.tst4
	move.w	#$0018,P0_CL_BPLCON2_OFFSET+2(a4)	;SPR0->SPR2->SPR4->PF->SPR6
	bra.s	.tstdone
.tst4:
	move.w	#$0020,P0_CL_BPLCON2_OFFSET+2(a4)	;SPR0->SPR2->SPR4->SPR6->PF
.tstdone

	; Loop through the lights and draw the sprites for point lights, a1=CL_Log1_Ptr
	lea	P0_CL_SPRITES_OFFSET+2(a4),a1	;copper spr pointer block, skip to pth word

	moveq	#VEC_LIGHTS_NUMMAX-1,d7
	lea	CTRL_LIGHT0_SORTED_PTR(a5),a4
.lightloop:
	move.l	(a4)+,a0		;Light ptr
	cmp.w	#LIGHTF_POINT,LIGHT_TYPE(a0)	;Only draw enabled point lights
	bne.s	.nextlight

	bsr	Lights_Draw_Sprite	;I:a0-a1, T:d0-d3/a2
.nextlight:
	dbf	d7,.lightloop
.exit:
	rts


*****************************************************************************
* Draws the light sprite.
* IN:		a0, Light structure ptr
*		a1, Copper sprite block, pointing to pth word
*		a5, Controller_Info
*
*	dc.w	spr2pth,$PTR_TO_THIS_WORD
*	dc.w	spr2ptl,$0
*
* OUT:		a1=sprptr in cl
* TRASHED:	d0-d5/a2-a3
*****************************************************************************

Lights_Draw_Sprite:
	;Do perspective calc 
	move.l	CTRL_PERS_RECIP_TABLE_PTR(a5),a2
	movem.w	LIGHT_POS_X(a0),d0-d2	;get x,y,z pts (movem extends to .l)
	move.w	d2,d3			;save for later
	asl.w	#VEC_PERS_K_SHIFT,d0	;*256, k*x
	asl.w	#VEC_PERS_K_SHIFT,d1	;*256, k*y
	add.w	#VEC_PERS_DIST+(-1*VEC_PERS_RECIP_START_Z),d2	;pers+z
	add.w	d2,d2			;word offset in table
	move.w	(a2,d2.w),d2		;16834 / z
	muls	d2,d0
	muls	d2,d1
	add.l	d0,d0
	add.l	d0,d0
	swap	d0			;/16384
	add.l	d1,d1
	add.l	d1,d1
	swap	d1			;/16384
	add.w	#VEC_XOFFSET-SPR_DISCOBALL_CENTER,d0	;add x offset
	neg.w	d1			;flip y axis for screen coords
	add.w	#VEC_YOFFSET-SPR_DISCOBALL_CENTER,d1	;add y axis



;	movem.w	LIGHT_POS_X(a0),d0-d2	;get x,y,z pts (movem extends to .l)
;	move.w	d2,d3			;save
;	asl.l	#VEC_PERS_K_SHIFT,d0	;*256, k*x
;	asl.l	#VEC_PERS_K_SHIFT,d1	;*256, k*y
;	add.w	#VEC_PERS_DIST,d2	;pers+z
;	beq.s	.div1			;trap div by zero
;	divs	d2,d0			;new x & y values
;	divs	d2,d1
;.div1:	add.w	#VEC_XOFFSET-SPR_DISCOBALL_CENTER,d0		;add x offset
;	neg.w	d1			;flip y axis for screen coords
;	add.w	#VEC_YOFFSET-SPR_DISCOBALL_CENTER,d1		;add y axis

	;d0=screenx, d1=screeny
	;d3=z

	;note that Z has been translated to the object space, so we need to 

	move.w	LIGHT_POS_Z_NOTRANS(a0),d3

	;sprite has 3 frames
	;For anything near -ve to 0 we use frame 0 of the sprite
	;For anything 0-256 we use 2 frames, 1,2  (/ by 128)
	;sub.w	#95,d3
	tst.w	d3
	bpl.s	.ok1
	moveq	#0,d3			;frame 0
	bra.s	.ok3
.ok1:
	lsr	#7,d3			;/ by 128
	addq.w	#1,d3			;frame 1-2
	cmp.w	#2,d3
	ble.s	.ok3
	moveq	#2,d3			;frame 2 also for anything further
.ok3:
	;Sprite data is in kingcon format. We are using 32px wide ANIM sprites so the format is:
	;dc.w	offset-spr0-frame0,offset-spr1-frame0
	;dc.w	offset-spr0-frame1,offset-spr1-frame1
	;The add the offset and that will now be the correct sprite control words and data for that frame
	
.updatepth:
	move.w	LIGHT_ANIM_FRAME(a0),d4	;Get animation frame number

	addq.w	#1,d4
	and.w	#(SPR_DISCOBALL_FRAMES*4)-1,d4	;*4 to slow down anim

.animok:
	move.w	d4,LIGHT_ANIM_FRAME(a0)	;Frame * 4, see above
	;lsr.w	#2,d4			;/4 to undo the *4 above, which means we can ditch next two add.w
	;add.w	d4,d4			;Correct kingcon frame offset
	;add.w	d4,d4
	and.w	#$fffc,d4		;Because skipping lsr #2/add/add

	add.w	d3,d3			;distance to long word offset (to select LIGHT_SPRITE_A_PTR to LIGHT_SPRITE_C_PTR)
	add.w	d3,d3
	move.l	LIGHT_SPRITE_A_PTR(a0,d3.w),a0	;Select correct sprite set LIGHT_SPRITE_A_PTR to LIGHT_SPRITE_C_PTR, then retrieve sprite set ptr 
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
	moveq	#SPR_DISCOBALL_HEIGHT,d2	;height

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
* Gets the magnitude of a vector.
* sqrt( x*x + y*y + z*z )
*
* IN:		d0-d2.w, x,y,z components
* OUT:		d0.w, magnitude
* TRASHED:	d0-d6
*****************************************************************************

Vec3_Magnitude:
	; sum of squares
	muls	d0,d0
	muls	d1,d1
	muls	d2,d2
	add.l	d1,d0
	add.l	d2,d0

	; square root
	jmp	LIB_Sqrt_FastNewton		;I:d0.l, O:d0.l, T:d0-d3
	
	;rts


*****************************************************************************
* Normalise (give unit vector) a 3d vector. Returns unit vector multipied by VEC_UNITY_LEN.
* To return to normal scale /VEC_UNITY_LEN:
*
* IN:		d0-d2.w, x,y,z components
* OUT:		d0-d2.w, normalised components multipled by VEC_UNITY_LEN
* TRASHED:	d0-d6
*****************************************************************************

Vec3_Normalize:
	; save the component squares
	move.w	d0,d4
	move.w	d1,d5
	move.w	d2,d6
	
	; sum of squares
	muls	d0,d0
	muls	d1,d1
	muls	d2,d2
	add.l	d1,d0
	add.l	d2,d0

	; calculate the magnitude
	jsr	LIB_Sqrt_FastNewton		;I:d0.l, O:d0.w, T:d0-d3

	; Catch potential div by zero
	tst.w	d0
	bne.s	.divok
	moveq	#1,d0		;Divide by 1
.divok:
	; multiply the components by 2^14 (VEC_UNITY_LEN)
	ext.l	d4
	ext.l	d5
	ext.l	d6

	ifgt	VEC_UNITY_LEN_SHIFT-8
		moveq	#VEC_UNITY_LEN_SHIFT,d1
		lsl.l	d1,d4
		lsl.l	d1,d5
		lsl.l	d1,d6
	else
		lsl.l	#VEC_UNITY_LEN_SHIFT,d4
		lsl.l	#VEC_UNITY_LEN_SHIFT,d5
		lsl.l	#VEC_UNITY_LEN_SHIFT,d6
	endif
	
	; divide by magnitude to derive normalised components
	divs	d0,d4
	divs	d0,d5
	divs	d0,d6
	
	; return normalised components
	move.w	d4,d0
	move.w	d5,d1
	move.w	d6,d2
	
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
