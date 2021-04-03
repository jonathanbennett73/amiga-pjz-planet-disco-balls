*****************************************************************************
* Included at the end of the code section (for (pc) data)
*****************************************************************************

*****************************************************************************

; Screen buffer and copper ptrs, must stay in this order as accessed as a group
BPL_Phys_Ptr:			dc.l	0
BPL_Log1_Ptr:			dc.l	0
SCR_Fill_Phys_Details_Ptr:	dc.l 	0
SCR_Fill_Log_Details_Ptr:	dc.l 	0
CL_Phys_Ptr:			dc.l	0
CL_Log1_Ptr:			dc.l	0


*****************************************************************************

	rsreset
CTRL_SINE_OFFSET		rs.w	1
CTRL_SINE_SPEED			rs.w	1
CTRL_SINE_FREQ			rs.w	1
CTRL_SINE_SPEEDNEW		rs.w	1
CTRL_SINE_FREQNEW		rs.w	1
CTRL_SINESET_ACTIVE		rs.w	1	;>0 if sine values are being changed over time
CTRL_SINESET_COUNTER		rs.w	1	;Change counter speed
CTRL_SINE_SIZEOF		rs.w	0

	rsreset
CTRL_SCRIPT_PTR			rs.l	1	;Script Ptr
CTRL_FINISHED			rs.w	1	;1 if quitting
CTRL_PRECALC_INTROSTART_DONE	rs.w	1	;1 if intro precalc done
CTRL_PHASE			rs.w	1	;Current phase
CTRL_FRAME_COUNT		rs.w	1	;Local (effect) frame counter
CTRL_PAUSE_COUNTER		rs.w	1	;Pause counter, 0=running
CTRL_ISFRAMEOVER_COUNTER	rs.w	1	;Waiting for frame, 0=inactive
CTRL_ISMASTERFRAMEOVER_COUNTER	rs.w	1	;Waiting for frame, 0=inactive
CTRL_MUSICSYNC			rs.w	1	;Value returned from music E8x (may be further processed)
CTRL_MUSICSYNCMASK		rs.w	1	;The music sync value will be anded with this mask to allow script to "hide" events
CTRL_MUSICSYNCMASKWAIT		rs.w	1	;A music mask to wait for before continuing, if 00 then no wait
CTRL_MUSICSYNC_LASTFRAME	rs.w	1	;The CTRL_FRAME_COUNT value of the last music trigger
CTRL_FRAME_SYNC			rs.w	1	;For keeping track of frames (1 frame, 2 frame effects etc)
CTRL_FRAMES_MIN			rs.w	1	;Minimum frames to run (to avoid skipping between 1 and 2+ frames)
CTRL_OBJECTINFO_PTR		rs.l	1	;Current object

CTRL_PALETTE_LOAD_FLAG		rs.w	1	;set to >1 to force palette load
CTRL_PALETTE_ACTIVE		rs.w	1	;Palette change active
CTRL_PALETTE_PTR		rs.l	1	;src Palette ptr (16 words of colors)
CTRL_PALETTE_COUNTER		rs.w	1	;Palette counter, speed
CTRL_PALETTE_SPEED		rs.w	1	;How often to update, higher is slower, 0 = instant
CTRL_PALETTE_STEP		rs.w	1	;Current step to interpolate between current color and final 0-15

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_USERVAL1			rs.w	1	;Example general purpose value

;CTRL_SINE1			rs.b	CTRL_SINE_SIZEOF
;CTRL_SINE2			rs.b	CTRL_SINE_SIZEOF

CTRL_ROT_CHANGE_ACTIVE		rs.w	1	;Rotation change active,final x,y,z,speed
CTRL_ROT_CHANGE_SPEED		rs.w	1
CTRL_ROT_CHANGE_X		rs.w	1
CTRL_ROT_CHANGE_Y		rs.w	1
CTRL_ROT_CHANGE_Z		rs.w	1

CTRL_MOVE_ACTIVE		rs.w	1	;move active, final x,y,z,speed
CTRL_MOVE_SPEED			rs.w	1
CTRL_MOVE_X			rs.w	1
CTRL_MOVE_Y			rs.w	1
CTRL_MOVE_Z			rs.w	1

CTRL_HORIZSCROLL_ACTIVE		rs.w	1
CTRL_HORIZSCROLL_SIN1_OFFSET	rs.w	1
CTRL_HORIZSCROLL_SIN1_SPEED	rs.w	1
CTRL_HORIZSCROLL_SIN1_STEP	rs.w	1

CTRL_MOVE2_ACTIVE		rs.w	1	;move active, final x,y,z,speed
CTRL_MOVE2_SPEED		rs.w	1
CTRL_MOVE2_X			rs.w	1
CTRL_MOVE2_Y			rs.w	1
CTRL_MOVE2_Z			rs.w	1
CTRL_MOVE2_XVEL			rs.w	1
CTRL_MOVE2_YVEL			rs.w	1
CTRL_MOVE2_ZVEL			rs.w	1

CTRL_TMP_ZSIN:			rs.w	1	;ZSIN->XCOS order must be maintained.
CTRL_TMP_ZCOS:			rs.w	1
CTRL_TMP_YSIN:			rs.w	1
CTRL_TMP_YCOS:			rs.w	1
CTRL_TMP_XSIN:			rs.w	1	
CTRL_TMP_XCOS:			rs.w	1

CTRL_LIGHTS_ENABLED:		rs.w	1
CTRL_LIGHT0_PTR:		rs.l	1	;ptr to light structures
CTRL_LIGHT1_PTR:		rs.l	1
CTRL_LIGHT2_PTR:		rs.l	1
CTRL_LIGHT3_PTR:		rs.l	1
CTRL_LIGHT0_SORTED_PTR:		rs.l	1	;ptr to light structures
CTRL_LIGHT1_SORTED_PTR:		rs.l	1
CTRL_LIGHT2_SORTED_PTR:		rs.l	1
CTRL_LIGHT3_SORTED_PTR:		rs.l	1
CTRL_LIGHT_AMBIENT:		rs.w	1	;Ambient light to add to the scene

	ifne VEC_Q14_GENSIN
CTRL_SINETAB_ROT_PTR		rs.l	1	;rotation sine table
	endif

CTRL_PERS_RECIP_TABLE_PTR	rs.l	1	;Perspective Reciprocal table

CTRL_ZERODATA_SIZE		rs.w	0	;size of all zeroed data - START OF NONZERO

CTRL_SIZE:			rs.w	0

Controller_Info:
	dcb.b	CTRL_ZERODATA_SIZE,0	;Init all to zero by default


*****************************************************************************

; Master palette poked into the copperlist each frame
PAL_Current:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_DARK,0	;dark/reflection colours

; This holds the old source palette used during transitions in FX_PALETTE. The
; source value is interpolated from this value to the destination value + step size.
PAL_Current_Src:	dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_DARK,0	;dark/reflection colours

; All black and white palettes used for fades/lightsources
PAL_AllBlack:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_DARK,0	;dark/reflection colours

PAL_AllWhite:		dcb.w	PAL_NUMCOLS_MAIN,$fff	;main colours
			dcb.w	PAL_NUMCOLS_DARK,$fff	;dark/reflection colours

; This is the actual palette poked into the copperlist. PAL_Current is used as a source
; and any lightsourcing may modify the values and generate this final version. If no
; lightsourcing then PAL_Current is just copied directly into here.
PAL_Current_LightSourced:	dcb.w	PAL_NUMCOLS_MAIN,0		;main colours
			dcb.w	PAL_NUMCOLS_DARK,0		;reflection colours


*****************************************************************************

	rsreset
SCR_FILL_MINX		rs.w	1
SCR_FILL_MINY		rs.w	1
SCR_FILL_MAXX		rs.w	1
SCR_FILL_MAXY		rs.w	1
SCR_FILL_HEIGHT		rs.w	1
SCR_FILL_WORDWIDTH	rs.w	1
SCR_FILL_BYTEMODULO	rs.w	1
SCR_FILL_SRCPTR		rs.l	1	;if 0 then do not use
SCR_FILL_BLTSIZE	rs.w	1
SCR_FILL_SIZE		rs.w	0

SCR_Fill_Phys_Details:
	dc.w	0,0,0,0	;minx,y,maxx,y
	dc.w	0	;height in lines to clear
	dc.w	0	;width in words to clear
	dc.w	0	;modulo for next line
	dc.l	0	;screen ptr for bottom right src (descending) INIT AS 0
	dc.w	0	;bltsize

SCR_Fill_Log_Details:
	dc.w	0,0,0,0	;minx,y,maxx,y
	dc.w	0	;height in lines to clear
	dc.w	0	;width in words to clear
	dc.w	0	;modulo for next line
	dc.l	0	;screen ptr for bottom right src (descending) INIT AS 0
	dc.w	0	;bltsize


*****************************************************************************

	rsreset
LIGHT_TYPE			rs.w	1	;LIGHTF_OFF,LIGHTF_PLANAR,LIGHTF_POINT
LIGHT_BASEPOS_X			rs.w	1	;Original points
LIGHT_BASEPOS_Y			rs.w	1
LIGHT_BASEPOS_Z			rs.w	1
LIGHT_POS_X			rs.w	1	;Rotated and translated points
LIGHT_POS_Y			rs.w	1
LIGHT_POS_Z			rs.w	1
LIGHT_POS_Z_NOTRANS		rs.w	1
LIGHT_THETA_X			rs.w	1
LIGHT_THETA_Y			rs.w	1
LIGHT_THETA_Z			rs.w	1
LIGHT_THETA_DX			rs.w	1
LIGHT_THETA_DY			rs.w	1
LIGHT_THETA_DZ			rs.w	1
LIGHT_NORMAL_X			rs.w	1
LIGHT_NORMAL_Y			rs.w 	1
LIGHT_NORMAL_Z			rs.w	1
LIGHT_NORMAL_LEN		rs.w	1
LIGHT_SPRITE_A_PTR		rs.l	1	;A sprite closest
LIGHT_SPRITE_B_PTR		rs.l	1	;
LIGHT_SPRITE_C_PTR		rs.l	1	;
LIGHT_ANIM_FRAME		rs.w	1	;Animation frame number
LIGHT_FADE_VAL			rs.w	1	;0-255, 0=no dimming, 255=full dim (black), >>4
LIGHT_FADE_STEP			rs.w	1	;+ve value to add to FADE_VAL each frame
LIGHT_COLOR			rs.w	1	;0,col15, master color for full brightness
LIGHT_COLOR_AMBIENT		rs.w	1	;2,col0, color for no brightness (ambient)
LIGHT_COLOR_GENPALETTE		rs.w	1	;1 if needs to regen light palette
LIGHT_COLOR_PALETTE		rs.w	16	;col0-15, colors for this light, LIGHT_COLOR_AMBIENT to LIGHT_COLOR
LIGHT_COLOR_SRC			rs.w	1	;0,Source colour for transitions
LIGHT_COLOR_DEST		rs.w	1	;2,Dest colour for transitions
LIGHT_COLOR_AMBIENT_SRC		rs.w	1	;0,Source colour for transitions
LIGHT_COLOR_AMBIENT_DEST	rs.w	1	;2,Dest colour for transitions
LIGHT_COLOR_CHANGE_ACTIVE	rs.w	1	;0,Current step of a colour change
LIGHT_COLOR_CHANGE_COUNTER	rs.w	1	;2,Current step of a colour change
LIGHT_COLOR_CHANGE_SPEED	rs.w	1	;4,Current step of a colour change
LIGHT_COLOR_CHANGE_STEP		rs.w	1	;6,Current step of a colour change

LIGHT_SIZEOF			rs.w	0

Light0_Info:
	dcb.b	LIGHT_SIZEOF,0
Light1_Info:
	dcb.b	LIGHT_SIZEOF,0
Light2_Info:
	dcb.b	LIGHT_SIZEOF,0
Light3_Info:
	dcb.b	LIGHT_SIZEOF,0


*****************************************************************************

	ifne	PERFORM_ENABLE_HORIZSCROLL
;bplcon1 scroll values
HORIZSCROLL_TABLE_NUMWORDS = 256
;HORIZSCROLL_TABLE_OFFSET_MASK = HORIZSCROLL_TABLE_NUMWORDS-1
HORIZSCROLL_TABLE_OFFSET_MASK = ((HORIZSCROLL_TABLE_NUMWORDS*2)-2)	; Byte offset access into the table, forced to be even 

	EVEN
HorizScroll_Table:
	include "Sine_0_6_256_words.i"
	EVEN
	endif


*****************************************************************************

; Object definition

;Obj_Glenz24_Info:
;	dc.w	0			; initialised (happens on first load)
;	dc.w	0,0,0			; pos, x,y,z
;	dc.w	0,0,0			; current rotation, x,y,z
;	dc.w	1,2,3			; Rotation step, x,y,z
;	dc.w	0			; Complex 1/0
;	dc.w	1			; Num frames max
;	dc.l	Obj_Glenz24_PtsBuffer	; Pts ptr (in use/buffer)
;	dc.l	Obj_Glenz24_Pts		; Initial points ptr
;	dc.l	Obj_Glenz24_Facelist	; Facelist ptr
;	dc.w	0,0,0			; Morph active flag, counter, speed

	rsreset
VEC_OBJ_INITIALIZED:	rs.w	1
VEC_OBJ_POSX:		rs.w	1
VEC_OBJ_POSY:		rs.w	1
VEC_OBJ_POSZ:		rs.w	1
VEC_OBJ_THETA_X:	rs.w	1
VEC_OBJ_THETA_Y:	rs.w	1
VEC_OBJ_THETA_Z:	rs.w	1
VEC_OBJ_THETA_DX:	rs.w	1
VEC_OBJ_THETA_DY:	rs.w	1
VEC_OBJ_THETA_DZ:	rs.w	1
VEC_OBJ_COMPLEX:	rs.w	1
VEC_OBJ_NUMFRAMES:	rs.w	1
VEC_OBJ_PTS_PTR:	rs.l	1
VEC_OBJ_PTSINITIAL_PTR:	rs.l	1
VEC_OBJ_FACELIST_PTR:	rs.l	1
VEC_OBJ_MORPH_ACTIVE:	rs.w	1
VEC_OBJ_MORPH_COUNTER	rs.w	1
VEC_OBJ_MORPH_SPEED:	rs.w	1
VEC_OBJ_SIZEOF:		rs.w	0


*****************************************************************************

; Face definition

VEC_FACE	MACRO			;define face pts,col
		dc.w	\1		;number of vertices
		dc.w	\2,\3		;paper, ink (visible)
		dc.w	\4,\5		;paper, ink (backface), paper=-1 to just cull
		dc.w	0		;0/1 - is currently a backface after hidden line calc
		dc.w	0,0,0,0		;minx,y,maxx,y (2d screen coords)
		dc.w	0		;current average z for this face
		dc.w	0,0,0,0		;surface normal x,y,z,magnitude
		dc.w	0,0,0,0		;VEC_FACE_LIGHT0_VAL (4 lights)
		ENDM

;Final face definition would look like:
;Obj_ExplodeCube6_f2:		;front
;	VEC_FACE	5,1,1,-1,-1
;	VEC_VERTEX5	4,5,6,7,4
;
; Most routines assume a closed poly so last vertex must match the first

	rsreset
VEC_FACE_NUMVERTICES:	rs.w	1
VEC_FACE_PAPER		rs.w	1
VEC_FACE_INK		rs.w	1
VEC_FACE_PAPER_BACKFACE	rs.w	1
VEC_FACE_INK_BACKFACE	rs.w	1
VEC_FACE_FLAG_BACKFACE	rs.w	1
VEC_FACE_MINX		rs.w	1
VEC_FACE_MINY		rs.w	1
VEC_FACE_MAXX		rs.w	1
VEC_FACE_MAXY		rs.w	1
VEC_FACE_AVG_Z		rs.w	1
VEC_FACE_NORMAL_X	rs.w	1
VEC_FACE_NORMAL_Y	rs.w	1
VEC_FACE_NORMAL_Z	rs.w	1
VEC_FACE_NORMAL_LEN	rs.w	1
VEC_FACE_LIGHT0_VAL	rs.w	1
VEC_FACE_LIGHT1_VAL	rs.w	1
VEC_FACE_LIGHT2_VAL	rs.w	1
VEC_FACE_LIGHT3_VAL	rs.w	1
VEC_FACE_VERTICES	rs.w	0

;connect pt 1 to pt 2, *6 is the byte offset in the Rotated pts struct. (x,y,z = 0,2,4)

VEC_VERTEX4	MACRO					;Closed triangle
		dc.w	\1*6,\2*6,\3*6,\4*6
		ENDM

VEC_VERTEX5	MACRO
		dc.w	\1*6,\2*6,\3*6,\4*6,\5*6	;Closed rectangle
		ENDM

VEC_VERTEX6	MACRO
		dc.w	\1*6,\2*6,\3*6,\4*6,\5*6,\6*6	;Closed pentagon
		ENDM


; Note: Fastest colors are 1,2,4, then 3,5,6, then 7
; Also features stipple colours, that is, when you
; define a face 2 colours are entered first the
; PAPER & then the INK!
; n.b. if a stipple with col00 is needed then
; make sure that the PAPER is set to 0 and not
; the INK as it is slightly faster this way!

*****************************************************************************

;Vert data accessed as (pc) a lot so leave in data section
VEC_MAX_PTS	= 64
VEC_MAX_FACES	= 48

;rotated pts 3d
Vert_XYZ_Buf:
	ds.w	VEC_MAX_PTS*3			

;2d pts in perspective (z is left undefined because using same vertex indexing offsets)
Vert_XYZ_Pers_Buf:
	ds.w	VEC_MAX_PTS*3			

; Visible face buffer is a list of pointer to face data structures.
Face_Visible_Buf:
	ds.w	1		; num faces
	ds.l	VEC_MAX_FACES	; face ptr.l

*****************************************************************************

; Copper horizontal blanking notes from Photon/Scoopex
; As established, positions $e7...$03 are not usable. If you're writing a simple 
; copperlist with no need for tight timing, positions $df and $07 are conventionally 
;used for the positions on either side of the horizontal blanking, and for 
; compatibility across chipsets use increments of 4 from these, resulting in 
;positions $db, $0b, and so on.

MEMORYFETCHMODE		=	0		;0 (OCS),1 or 3 

	ifeq	MEMORYFETCHMODE
DDF_INCREMENT	=	1
	else
DDF_INCREMENT	=	(MEMORYFETCHMODE+1)&$fffe
	endif	

*****************************************************************************

DIW_VSTART set (P0_DIW_V&$ff)<<8
DIW_VSTOP set ((P0_DIW_V+P0_DIW_HEIGHT)&$ff)<<8
DIW_HSTART set P0_DIW_H&$ff
DIW_HSTOP set (DIW_HSTART+P0_DIW_WIDTH)&$ff
DIW_START set DIW_VSTART!DIW_HSTART
DIW_STOP set DIW_VSTOP!DIW_HSTOP
DDF_START set (P0_DDF_H/2)-8
DDF_STOP set DDF_START+((P0_DDF_WORDWIDTH-DDF_INCREMENT)*8)

P0_CL_Phys:
	; Trigger copper interrupt if P0_SCANLINE_EOF = 0
	ifne FW_FRAME_IRQ_NEEDTRIG
	ifeq P0_SCANLINE_EOF
		CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
	endif
	endif

	CMOVE 	diwstrt,DIW_START
	CMOVE 	diwstop,DIW_STOP
	CMOVE 	ddfstrt,DDF_START
	CMOVE 	ddfstop,DDF_STOP
	CMOVE 	bplcon0,(BPL_BUF_NUMPLANES*$1000)|$0200
	CMOVE 	bplcon1,$0000

;bplcon2, pf2p2-0 are used when in single playfield mode
;000 000 PF   SPO1 SP23 SP45 SP67
;001 000 SP01 PF   SP23 SP45 SP67 
;010 000 SP01 SP23 PF   SP45 SP67 
;011 000 SP01 SP23 SP45 PF   SP67 
;100 000 SP01 SP23 SP45 SP67 PF 
P0_CL_BPLCON2:
	CMOVE	bplcon2,$0008		;spr01 -> PF , xxnn|nxxx

	CMOVE 	bpl1mod,BPL_BPLMOD	;interleaved mode
	CMOVE 	bpl2mod,BPL_BPLMOD

P0_CL_Scr_Sprites_Enable:
	CMOVE	dmacon,DMAF_SETCLR|DMAF_SPRITE	;enable sprites

	;CWAIT	25-1,$7		;Time for altering Copperlist

P0_CL_Bpl:			;Bitplane pointers
a set bpl1pth
	rept BPL_BUF_NUMPLANES	
	CMOVE	a,$0
	CMOVE	a+2,$0
a set a+4
	endr

P0_CL_Scr_Sprites:		;We use all sprites for 4 32x32 sprites
	CMOVE	spr0pth,$0
	CMOVE	spr0ptl,$0
	CMOVE	spr1pth,$0
	CMOVE	spr1ptl,$0
	CMOVE	spr2pth,$0
	CMOVE	spr2ptl,$0
	CMOVE	spr3pth,$0
	CMOVE	spr3ptl,$0
	CMOVE	spr4pth,$0
	CMOVE	spr4ptl,$0
	CMOVE	spr5pth,$0
	CMOVE	spr5ptl,$0
	CMOVE	spr6pth,$0
	CMOVE	spr6ptl,$0
       	CMOVE	spr7pth,$0
	CMOVE	spr7ptl,$0

P0_CL_Cols:
	CMOVE	tmpcolor00,$000
a set color01
	rept BPL_BUF_NUMCOLS-1
	CMOVE	a,$000
a set a+2
	endr

P0_CL_Spr01_Cols:
	CMOVE	color17,$000	
	CMOVE	color18,$000
	CMOVE	color19,$000
P0_CL_Spr23_Cols:
	CMOVE	color21,$000	
	CMOVE	color22,$000
	CMOVE	color23,$000
P0_CL_Spr45_Cols:
	CMOVE	color25,$000	
	CMOVE	color26,$000
	CMOVE	color27,$000
P0_CL_Spr67_Cols:
	CMOVE	color29,$000	
	CMOVE	color30,$000
	CMOVE	color31,$000


P0_CL_HorizScoll:
	ifne PERFORM_ENABLE_HORIZSCROLL
a set P0_DIW_V-1
	rept VEC_HORIZ_SCROLL_NUMLINES
	CWAIT	a&$ff,$df
	CMOVE	bplcon1,$0000
a set a+1
	endr
	endif

	; Trigger interrupt if P0_SCANLINE_EOF >0
	; Note no need to wait due to above horizscroll code
	ifne FW_FRAME_IRQ_NEEDTRIG
		ifne P0_SCANLINE_EOF
			ifeq PERFORM_ENABLE_HORIZSCROLL
				ifgt P0_SCANLINE_EOF-255
					CWAIT	255,$df
				endif
				
				CWAIT	((P0_SCANLINE_EOF-1)&$ff),$df
				CMOVE	bplcon0,$1200	;Save DMA but leave sprites visible
			endif
			CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
		endif
	endif

	COPPEREND
P0_CL_End:

P0_CL_BPL_OFFSET = (P0_CL_Bpl-P0_CL_Phys)
P0_CL_BPLCON2_OFFSET = (P0_CL_BPLCON2-P0_CL_Phys)
P0_CL_COL_OFFSET = (P0_CL_Cols-P0_CL_Phys)
P0_CL_SPRITES_OFFSET = (P0_CL_Scr_Sprites-P0_CL_Phys)
P0_CL_SPRITES_ENABLE_OFFSET	equ	(P0_CL_Scr_Sprites_Enable-P0_CL_Phys)
P0_CL_COL_SPR01_OFFSET = (P0_CL_Spr01_Cols-P0_CL_Phys)
P0_CL_COL_SPR23_OFFSET = (P0_CL_Spr23_Cols-P0_CL_Phys)
P0_CL_COL_SPR45_OFFSET = (P0_CL_Spr45_Cols-P0_CL_Phys)
P0_CL_COL_SPR67_OFFSET = (P0_CL_Spr67_Cols-P0_CL_Phys)
P0_CL_HORIZSCROLL_OFFSET = (P0_CL_HorizScoll-P0_CL_Phys)
P0_CL_SIZE = P0_CL_End-P0_CL_Phys

	rsreset
CL_HORIZSCROLL_WAIT1	rs.w	2
CL_HORIZSCROLL_BPLCON1	rs.w	2
CL_HORIZSCROLL_SIZEOF	rs.w	0


*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_PublicBss,bss

*****************************************************************************


;	ifne VEC_Q14_GENSIN
;Rotate_Sin_Table:
;	ds.w	ROT_SIN_TABLE_NUMWORDS/4
;Rotate_Cos_Table:
;	ds.w	ROT_SIN_TABLE_NUMWORDS
;	endif


;Perspective_ReciprocalTable:
;	dcb.w	VEC_PERS_RECIP_NUMENTRIES,0


*****************************************************************************
