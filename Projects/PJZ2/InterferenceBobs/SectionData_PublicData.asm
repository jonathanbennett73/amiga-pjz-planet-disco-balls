*****************************************************************************
* Included at the end of the code section (for (pc) data)
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
CTRL_P0_PRECALC_DONE		rs.w	1	;1 if effect precalc done

CTRL_PALETTE_LOAD_FLAG		rs.w	1	;set to >1 to force palette load
CTRL_PALETTE_ACTIVE		rs.w	1	;Palette change active
CTRL_PALETTE_PTR		rs.l	1	;src Palette ptr (16 words of colors)
CTRL_PALETTE_COUNTER		rs.w	1	;Palette counter, speed
CTRL_PALETTE_SPEED		rs.w	1	;How often to update, higher is slower, 0 = instant
CTRL_PALETTE_STEP		rs.w	1	;Current step to interpolate between current color and final 0-15

CTRL_BPL_PHYS_PTR		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_LOG1_PTR		rs.l	1	;visible bpl1
CTRL_BPL_LOG2_PTR		rs.l	1	;Logical2
CTRL_BPL_LOG3_PTR		rs.l	1	;Logical3 
CTRL_BPL_LOG4_PTR		rs.l	1	;Logical3 
CTRL_CL_PHYS_PTR		rs.l	1	;Copper ptr - physical
CTRL_CL_LOG1_PTR		rs.l	1	;Logical1

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_USERVAL1			rs.w	1	;Example general purpose value

CTRL_SINE_X1			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_X2			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_Y1			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_Y2			rs.b	CTRL_SINE_SIZEOF

CTRL_SINE_X3			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_Y3			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_X4			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_Y4			rs.b	CTRL_SINE_SIZEOF

CTRL_NUMBOBS			rs.w	1
CTRL_BOB1_BPL			rs.l	1	;Bob data in chip
CTRL_BOB2_BPL			rs.l	1	;Bob data in chip
CTRL_BOB3_BPL			rs.l	1	;Bob data in chip
CTRL_BOB_CURRENT		rs.w	1	;0,4,8 to select BOB image

CTRL_SINETAB_PTR		rs.l	1	;rotation sine table

CTRL_SPRITE1_PTR		rs.l	1
CTRL_SPRITE2_PTR		rs.l	1
CTRL_SPRITE3_PTR		rs.l	1
CTRL_SPRITE_CURRENT		rs.w	1	;0,4,8 to select sprite image

CTRL_MUSIC_FADE_STEP		rs.w	1	;Fade from 0-15

CTRL_ZERODATA_SIZE		rs.w	0	;size of all zeroed data - START OF NONZERO

CTRL_SIZE			rs.w	0

	even
Controller_Info:
	dcb.b	CTRL_ZERODATA_SIZE,0		;Init all to zero by default
	even

*****************************************************************************

; Master palette poked into the copperlist each frame
PAL_Current:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

; This holds the old source palette used during transitions in FX_PALETTE. The
; source value is interpolated from this value to the destination value + step size.
PAL_Current_Src:	dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

*****************************************************************************

BOB_WIDTH	equ	64
BOB_BYTEWIDTH	equ	BOB_WIDTH/8
BOB_WORDWIDTH	equ	BOB_BYTEWIDTH/2
BOB_HEIGHT	equ	63
BOB_NUMPLANES	equ	1
BOB_SIZE	equ	BOB_BYTEWIDTH*BOB_HEIGHT
BOB_TOTALSIZE	equ	BOB_SIZE*BOB_NUMPLANES

BOB_BPL_Source1:
	incbin "../AssetsConverted/CircleFill_64x63x1.BPL"
BOB_BPL_Source2:
	incbin "../AssetsConverted/SquareFill_64x63x1.BPL"
BOB_BPL_Source3:
	incbin "../AssetsConverted/StarFill_64x63x1.BPL"

*****************************************************************************

;Srite data
SPR_WIDTH equ 128
SPR_HEIGHT equ 96

;This is the filesize of the .spr file. 
;TODO: Create a "filesize <filename> <define>" to automate this
SPR_SIZEOF equ 3152		;Set to same size as Credit_Antiriad_128x96x2.SPR

SPR_Antiriad_Source:
	incbin "../AssetsConverted/Credit_Antiriad_128x96x2.SPR"

SPR_Optic_Source:
	incbin "../AssetsConverted/Credit_Optic_128x96x2.SPR"

SPR_Tecon_Source:
	incbin "../AssetsConverted/Credit_Tecon_128x96x2.SPR"

*****************************************************************************

MEMORYFETCHMODE	equ	0		;0 (OCS),1 or 3 
	ifeq	MEMORYFETCHMODE
DDF_INCREMENT	equ	1
	else
DDF_INCREMENT	equ	(MEMORYFETCHMODE+1)&$fffe
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
	CMOVE 	bplcon0,(4*$1000)|$0200
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0020		;All sprites > PF2
	CMOVE 	bpl1mod,BPL_BPLMOD
	CMOVE 	bpl2mod,BPL_BPLMOD_REPTPREVLINE

	CMOVE	dmacon,DMAF_SETCLR|DMAF_SPRITE	;enable sprites

	;If we have a single CL then allow some time for changing ptrs
	ifeq	P0_CL_NUM_BUFFERS-1
	CWAIT	25-1,$7			;25 is end of vblank
	;CWAIT	P0_DIW_V-1,$7
	endif

P0_CL_Bpl:				;Bitplane pointers
	CMOVE	bpl1pth,$0
	CMOVE	bpl1ptl,$0
	CMOVE	bpl2pth,$0
	CMOVE	bpl2ptl,$0
	CMOVE	bpl3pth,$0
	CMOVE	bpl3ptl,$0
	CMOVE	bpl4pth,$0
	CMOVE	bpl4ptl,$0
	CMOVE	bpl5pth,$0
	CMOVE	bpl5ptl,$0

P0_CL_Scr_Sprites:		;We use all sprites
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
	rept	PAL_NUMCOLS_MAIN-1	
	CMOVE	a,$000
a set a+2
	endr

P0_CL_Pattern:
a set P0_DIW_V-1	;First wait is for end of previous line, so we don't need two waits per line
b set $0007		;pf1 scroll 7 to center
	rept	BPL_BUF_HEIGHT
;	CWAIT	a,$df
;	CMOVE	bplcon1,b
b set b+$0040		;update pf2 scroll
b set (b&$00ff)
a set a+1
	endr

	; Trigger interrupt if P0_SCANLINE_EOF >0
	ifne FW_FRAME_IRQ_NEEDTRIG
		ifne P0_SCANLINE_EOF
			ifgt P0_SCANLINE_EOF-255
				CWAIT	255,$df
			endif
			CWAIT	((P0_SCANLINE_EOF-1)&$ff),$df
			CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
		endif
	endif

	COPPEREND
P0_CL_End:

P0_CL_BPL_OFFSET 	equ	P0_CL_Bpl-P0_CL_Phys
P0_CL_SPRITES_OFFSET	equ	P0_CL_Scr_Sprites-P0_CL_Phys
P0_CL_COL_OFFSET	equ	P0_CL_Cols-P0_CL_Phys
P0_CL_PATTERN_OFFSET	equ	P0_CL_Pattern-P0_CL_Phys
P0_CL_SIZE		equ	P0_CL_End-P0_CL_Phys


*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

*****************************************************************************

;BOB is 32px wide and we need extra word for shifting so max X value
;for 320 wide screen uses byte 34,35,36,37,38,39. Max X for byte 34 is 287 (rsh 4, *2)
;287 will give a shift of 15 so 32px bob will end up right border.
;0-287 range
;Half because we adding two sines together = 143
;0-143 = 0-318

;BOB_Sine_X:
;	;INCLUDE "sine_0_92_512_words.i"
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4	;Sine part
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS		;Cosine part

; list contains x,y values
; X in pixels
; Y in Y*Screen_ByteWidth (for speed)
BOBSnake_DrawList:
	ds.w	BOB_NUMBOBS_MAX*2

*****************************************************************************
