
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

PAL_Default:		dc.w	$000,$000,$000,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_DEFAULT	equ	PAL_Default-PAL_PaletteStart


PAL_Blue:		dc.w	$000,$000,$33f,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_BLUE	equ	PAL_Blue-PAL_PaletteStart

PAL_Red:		dc.w	$000,$000,$f44,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_RED		equ	PAL_Red-PAL_PaletteStart

PAL_Purple:		dc.w	$000,$000,$70d,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_PURPLE	equ	PAL_Purple-PAL_PaletteStart

PAL_Orange:		dc.w	$000,$000,$f90,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_ORANGE	equ	PAL_Orange-PAL_PaletteStart

PAL_Yellow:		dc.w	$000,$000,$ee1,$000
			dc.w	0,0,0,0,0,0,0,0,0,0,0,0
			dc.w	0,$000,$444,$aaa
PAL_YELLOW	equ	PAL_Yellow-PAL_PaletteStart

*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE/FX_STARTWAIT_MASTERFRAME
	;before loading the IRQ/Copper.
	;Better to use FX_STARTWAIT_MASTERFRAME with 0 or higher to sync A500 with
	;faster machines

	;Init
	;----
	FX_PALETTE		0,PAL_ALLBLACK
	FX_MUSICSYNCMASK	$ff
	FX_USERVAL		CTRL_BLINDSFADE,32
	FX_START_MASTERFRAME	$164a	;0
	
	;Run
	;----
	FX_PALETTE	4,PAL_DEFAULT
	FX_PAUSE	1

	FX_SINE_SET	0,0,18,24,CTRL_LINE_SINE1
	FX_SINE_SET	0,0,-8,64,CTRL_LINE_SINE2
	FX_SINE_SET	0,0,14,4,CTRL_BPL_SINE1
	FX_SINE_SET	0,0,20,10,CTRL_BPL_SINE2
	FX_SINE_SET	0,0,-10,2,CTRL_BPL_SINE3
	FX_SINE_SET	0,0,-22,16,CTRL_BPL_SINE4

	FX_PAUSE	25

a set 31
	rept 32
	FX_USERVAL	CTRL_BLINDSFADE,a
	FX_PAUSE	4
a set a-1		;31 to 0
	endr

	FX_PAUSE	15*16

	FX_PALETTE	4,PAL_ORANGE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_BLUE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_RED
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_PURPLE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_YELLOW
	FX_PAUSE	(4*15)+25

	FX_SINE_SET	2,-1,-18,24,CTRL_LINE_SINE1
	FX_SINE_SET	4,-1,8,64,CTRL_LINE_SINE2
	FX_SINE_SET	2,-1,-14,4,CTRL_BPL_SINE1
	FX_SINE_SET	4,-1,-20,10,CTRL_BPL_SINE2
	FX_SINE_SET	2,-1,10,2,CTRL_BPL_SINE3
	FX_SINE_SET	4,-1,22,16,CTRL_BPL_SINE4

	FX_PALETTE	4,PAL_ORANGE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_BLUE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_RED
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_PURPLE
	FX_PAUSE	(4*15)+25
	FX_PALETTE	4,PAL_YELLOW
	FX_PAUSE	(4*15)+25

	FX_PALETTE	4,PAL_DEFAULT

a set 0
	rept 33
	FX_USERVAL	CTRL_BLINDSFADE,a
	FX_PAUSE	2
a set a+1		;0 to 32
	endr

	FX_PALETTE	4,PAL_ALLBLACK
	FX_PAUSE	4*15

	FX_END
