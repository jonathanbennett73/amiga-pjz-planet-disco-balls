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


*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

*****************************************************************************

;CUR_PUB_BUF set FW_Public_Buffer_1

; Screen height mult by screen bytewidth and number of bitplanes (interleaved)
Mult_SCR_Height_ByteWidth_NumPlanes:
	ds.w	BPL_BUF_HEIGHT
;Mult_SCR_Height_ByteWidth_NumPlanes	equ	CUR_PUB_BUF
;CUR_PUB_BUF	set	CUR_PUB_BUF+(BPL_BUF_HEIGHT*2)

*****************************************************************************
