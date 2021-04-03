
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
PAL_Default:		dc.w	$000
			dc.w	$fff,$0f0,$00f,$ff0,$0ff,$f0f
			dc.w	$f77,$7f7,$77f,$ff7,$7ff,$f7f
			dc.w	$f73,$3f7,$37f,$ff3,$7ff,$f3f
			dc.w	$f00,$7f4,$fff,$ff9,$9ff,$f9f
			dcb.w	PAL_NUMCOLS_MAIN-1,$fff	;main colours
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours

PAL_DEFAULT	equ	PAL_Default-PAL_PaletteStart

*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE/FX_STARTWAIT_MASTERFRAME
	;before loading the IRQ/Copper.
	;Better to use FX_STARTWAIT_MASTERFRAME with 0 or higher to sync A500 with
	;faster machines

	;Init
	;----
	FX_PALETTE		0,PAL_DEFAULT
	FX_MUSICSYNCMASK	$ff
	FX_START_MASTERFRAME	0
	
	;Run
	;----
	
	;FX_USERVALWAIT		CTRL_USERVAL1,$ffff
	;FX_PALETTE		0,PAL_AllBlack

	FX_MUSICSYNCMASKWAIT	$0f
	FX_PALETTE		0,PAL_ALLBLACK


	FX_PAUSE		32767

	FX_END
