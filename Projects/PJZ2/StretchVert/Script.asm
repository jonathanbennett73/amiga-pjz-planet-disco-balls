
*****************************************************************************
* Included at the end of the code section (for (pc) data)
*****************************************************************************

; Values must match .jmptable in Controller_ReadCommands
; Using rs.l as the values will be used in a .l jmptable
	rsreset
FX_END_FLAG			rs.l	1
FX_PAUSE_FLAG			rs.l	1
FX_START_MASTERFRAME_FLAG	rs.l	1
FX_GET_MASTERFRAME_FLAG		rs.l	1
FX_ISMASTERFRAMEOVER_FLAG	rs.l	1
FX_ISFRAMEOVER_FLAG		rs.l	1
FX_SCRIPTJMP_FLAG		rs.l	1
FX_PALETTE_FLAG			rs.l	1
FX_NEXT_PHASE_FLAG		rs.l	1
FX_MUSICSYNCMASK_FLAG		rs.l	1
FX_MUSICSYNCMASKWAIT_FLAG	rs.l	1
FX_USERVAL_FLAG			rs.l	1
FX_USERVALWAIT_FLAG		rs.l	1
FX_SINE_SET_FLAG		rs.l	1
FX_ZOOM_FLAG			rs.l	1
FX_ZOOMSPRING_FLAG		rs.l	1
FX_RIPPLE_FLAG			rs.l	1

FX_END		MACRO
		dc.w	FX_END_FLAG
		ENDM

FX_PAUSE	MACRO
		dc.w	FX_PAUSE_FLAG
		dc.w	\1		;frames to pause
		ENDM

FX_START_MASTERFRAME	MACRO
		dc.w	FX_START_MASTERFRAME_FLAG
		dc.w	\1		;frames wait for (global timing)
		ENDM

FX_GET_MASTERFRAME	MACRO
		dc.w	FX_GET_MASTERFRAME_FLAG
		ENDM

FX_ISMASTERFRAMEOVER	MACRO
		dc.w	FX_ISMASTERFRAMEOVER_FLAG
		dc.w	\1		;frames wait for (global timing)
		ENDM

FX_ISFRAMEOVER	MACRO
		dc.w	FX_ISFRAMEOVER_FLAG
		dc.w	\1		;frames wait for (local timing)
		ENDM

FX_SCRIPTJMP	MACRO
		dc.w	FX_SCRIPTJMP_FLAG
		dc.l	\1		;new script address
		ENDM

FX_PALETTE	MACRO
		dc.w	FX_PALETTE_FLAG
		dc.w	\1		;speed
		dc.w	\2		;palette offset
		ENDM

FX_NEXT_PHASE	MACRO
		dc.w	FX_NEXT_PHASE_FLAG
		ENDM

FX_MUSICSYNCMASK	MACRO
		dc.w	FX_MUSICSYNCMASK_FLAG
		dc.w	\1		;mask 0-$ff
		ENDM

FX_MUSICSYNCMASKWAIT	MACRO
		dc.w	FX_MUSICSYNCMASKWAIT_FLAG
		dc.w	\1		;mask 0-$ff
		ENDM
		
FX_USERVAL	MACRO
		dc.w	FX_USERVAL_FLAG
		dc.w	\1		;Offset to a CTRL_xxx variable
		dc.w	\2		;value to write
		ENDM

FX_USERVALWAIT	MACRO
		dc.w	FX_USERVALWAIT_FLAG
		dc.w	\1		;Offset to a CTRL_xxx variable
		dc.w	\2		;value to wait for
		ENDM

FX_SINE_SET	MACRO			
		dc.w	FX_SINE_SET_FLAG	;Note most routines require even values to avoid the need to add.w d0,d0 for table lookups
		dc.w	\1		;change speed
		dc.w	\2,\3,\4	;offset (-1 leaves alone), speed, step
		dc.w	\5		;offset of sine variables in Controller_Info
		ENDM

FX_ZOOM		MACRO
		dc.w	FX_ZOOM_FLAG
		dc.w	\1		;speed
		dc.w	\2		;new zoom (0-1023)
		ENDM

FX_ZOOMSPRING	MACRO
		dc.w	FX_ZOOMSPRING_FLAG
		dc.w	\1		;delta speed (acceleration)
		ENDM

FX_RIPPLE	MACRO
		dc.w	FX_RIPPLE_FLAG
		dc.w	\1		;0=off, 1=on
		ENDM

*****************************************************************************

PAL_PaletteStart:	;for offsets

; All black and white palettes used for fades/lightsources
PAL_AllBlack:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_ALLBLACK	equ	PAL_AllBlack-PAL_PaletteStart

;PAL_AllWhite:		dcb.w	PAL_NUMCOLS_MAIN,$fff	;main colours
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
;PAL_ALLWHITE	equ	PAL_AllWhite-PAL_PaletteStart


; Just lots of colors for testing
PAL_Default:		
	include "../AssetsConverted/Logo1_320x153x5_inter.PAL_dcw.i"

PAL_DEFAULT	equ	PAL_Default-PAL_PaletteStart

PAL_TransIn:
			dcb.w	PAL_NUMCOLS_MAIN,$001	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_TRANSIN	equ	PAL_TransIn-PAL_PaletteStart

PAL_TransOut:
			dcb.w	PAL_NUMCOLS_MAIN,$101	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_TRANSOUT	equ	PAL_TransOut-PAL_PaletteStart

*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE before starting
	FX_PALETTE	0,PAL_TRANSIN
	FX_ZOOM		0,0
	FX_PAUSE	1
	;----

	FX_PALETTE	4,PAL_DEFAULT
	FX_ZOOM		0,ZOOM_MIN
	FX_ZOOMSPRING	4
	FX_PAUSE	375

	FX_SINE_SET	0,0,-16,16,CTRL_SINE1
	;FX_SINE_SET	0,0,-64,64,CTRL_SINE2
	FX_RIPPLE	1

	FX_PAUSE	200


	FX_PALETTE	4,PAL_TRANSOUT
	FX_PAUSE	(4*15)+25
	FX_END

