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
CTRL_BPL_LOG1_PTR		rs.l	1	;Logical1
CTRL_CL_PHYS_PTR		rs.l	1	;Copper ptr - physical
CTRL_CL_LOG1_PTR		rs.l	1	;Logical1

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_USERVAL1			rs.w	1	;Example general purpose value

CTRL_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE2			rs.b	CTRL_SINE_SIZEOF

CTRL_ZOOM			rs.w	1	;current zoom level
CTRL_ZOOM_ACTIVE		rs.w	1	;move active, final x,y,z,speed
CTRL_ZOOM_LOAD_FLAG		rs.w	1	;set to >1 to force zoom load
CTRL_ZOOM_REQ			rs.w	1	;Final zoom level
CTRL_ZOOM_MAXSPEED		rs.w	1	;Max speed (postive)
CTRL_ZOOM_VEL			rs.w	1	;Current velocity (postive/negative speed)
CTRL_ZOOM_DELTASPEED		rs.w	1	;Acceleration (postive)
CTRL_ZOOMSPRING_ACTIVE		rs.w	1	;move active, final x,y,z,speed

CTRL_RIPPLE_ACTIVE		rs.w	1	;ripple is active
CTRL_RIPPLE_VISIBLE_LINES	rs.w	1	;Number of visible lines
CTRL_RIPPLE_LOAD_FLAG		rs.w	1	;set to >1 to force load

CTRL_SINETAB_RIPPLE_PTR		rs.l	1	;Ripple sine/cos table, LIB_GENSIN_16384_2048W_NUMWORDS/4 + LIB_GENSIN_16384_2048W_NUMWORDS

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

	even
BPL_Pic_Source:
	incbin "../AssetsConverted/Logo1_320x153x5_inter.BPL"
	even

	;incbin "../AssetsConverted/EndScreen_320x256x5.BPL"

*****************************************************************************

; Copper horizontal blanking notes from Photon/Scoopex
; As established, positions $e7...$03 are not usable. If you're writing a simple 
; copperlist with no need for tight timing, positions $df and $07 are conventionally 
;used for the positions on either side of the horizontal blanking, and for 
; compatibility across chipsets use increments of 4 from these, resulting in 
;positions $db, $0b, and so on.

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

	;CMOVE	fmode,MEMORYFETCHMODE	;Chip Ram fetch mode (0=OCS)
	CMOVE 	diwstrt,DIW_START
	CMOVE 	diwstop,DIW_STOP
	CMOVE 	ddfstrt,DDF_START
	CMOVE 	ddfstop,DDF_STOP
	CMOVE 	bplcon0,$5200		;5 bpl
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0000
	CMOVE 	bpl1mod,BPL_BPLMOD
	CMOVE 	bpl2mod,BPL_BPLMOD

	CMOVE	dmacon,DMAF_SPRITE	;disable sprites

	;CWAIT	25-1,$7			;Time for altering Copperlist
	;CWAIT	P0_DIW_V-1,$7

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

P0_CL_Cols:
	CMOVE	tmpcolor00,$000
a set color01
	REPT	PAL_NUMCOLS_MAIN-1	
	CMOVE	a,$000
a set a+2
	ENDR

P0_CL_Pattern:
a set P0_DIW_V-1			;First wait is for end of previous line, so we don't need two waits per line
	REPT BPL_BUF_HEIGHT
	CWAIT	(a&$ff),$df
	CMOVE	bplcon0,$0		;need to turn off bitplanes when shrinking
	CMOVE 	bpl1mod,$0
	CMOVE 	bpl2mod,$0
a set a+1
	ENDR

	; Trigger interrupt if P0_SCANLINE_EOF >0
	ifne FW_FRAME_IRQ_NEEDTRIG
		ifne P0_SCANLINE_EOF
			;ifgt P0_SCANLINE_EOF-255
			;	CWAIT	255,$df
			;endif
			;CWAIT	((P0_SCANLINE_EOF-1)&$ff),$df
			CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
		endif
	endif

	COPPEREND
P0_CL_End:

P0_CL_BPL_OFFSET = (P0_CL_Bpl-P0_CL_Phys)
P0_CL_ZOOM_PATTERN_OFFSET = (P0_CL_Pattern-P0_CL_Phys)
P0_CL_COL_OFFSET = (P0_CL_Cols-P0_CL_Phys)
P0_CL_SIZE = P0_CL_End-P0_CL_Phys

	rsreset
CL_PATTERN		rs.w	0
CL_PATTERN_WAIT1	rs.w	2
CL_PATTERN_BPLCON0	rs.w	2	;need to turn off bitplanes when shrinking
CL_PATTERN_BPL1MOD	rs.w	2
CL_PATTERN_BPL2MOD	rs.w	2
CL_PATTERN_SIZEOF	rs.w	0


*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

*****************************************************************************

;Ripple sine table is -128 to 128
;Ripple_Sin_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
;Ripple_Cos_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS


;Ripple_Table is combined sine output of -1, 0, or 1 to represent skip,show,repeat lines
;BPL_BUF_HEIGHT must be a multiple of 16
RIPPLE_TABLE_NUMWORDS	equ	BPL_BUF_HEIGHT
Ripple_Table:
	ds.w	RIPPLE_TABLE_NUMWORDS

*****************************************************************************
