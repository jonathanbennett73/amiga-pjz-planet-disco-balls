
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

;1,2,4,8 - dim
;3,5,6,9,10,12 - brighter
;7,11,13,14 - brightest
;15

;0001
;0010
;0011
;0100
;0101
;0110
;0111
;1000
;1001
;1010
;1011
;1100
;1101
;1110
;1111

PAL_PaletteStart:	;for offsets

; All black and white palettes used for fades/lightsources
PAL_AllBlack:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_ALLBLACK	equ	PAL_AllBlack-PAL_PaletteStart

;PAL_AllWhite:		dcb.w	PAL_NUMCOLS_MAIN,$fff	;main colours
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
;PAL_ALLWHITE	equ	PAL_AllWhite-PAL_PaletteStart


PAL_Default:		dc.w	$101,0,0,0,0,0,0,0
			dc.w	0,0,0,0,0,0,0,0
PAL_DEFAULT	equ	PAL_Default-PAL_PaletteStart

			dcb.w	PAL_NUMCOLS_MAIN,$101	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

PAL_TransOut:
			dcb.w	PAL_NUMCOLS_MAIN,$001	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_TRANSOUT	equ	PAL_TransOut-PAL_PaletteStart

c1 set $505
c2 set $f5f
c3 set $faf
c4 set $fff
PAL_Purple:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_PURPLE	equ	PAL_Purple-PAL_PaletteStart

c1 set $500
c2 set $f55
c3 set $faa
c4 set $fff
PAL_Red:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_RED		equ	PAL_Red-PAL_PaletteStart

c1 set $f00
c2 set $ff5
c3 set $ffa
c4 set $fff
PAL_Flame:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_FLAME	equ	PAL_Flame-PAL_PaletteStart

c1 set $550
c2 set $ff5
c3 set $ffa
c4 set $fff
;PAL_Yellow:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
;			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours

c1 set $005
c2 set $35f
c3 set $3af
c4 set $3ff
PAL_Blue:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_BLUE	equ	PAL_Blue-PAL_PaletteStart

c1 set $050
c2 set $5f5
c3 set $afa
c4 set $fff
PAL_Green:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_GREEN	equ	PAL_Green-PAL_PaletteStart

c1 set $055
c2 set $5ff
c3 set $aff
c4 set $fff
;PAL_Cyan:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
;			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours


*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE/FX_STARTWAIT_MASTERFRAME
	;before loading the IRQ/Copper.
	;Better to use FX_STARTWAIT_MASTERFRAME with 0 or higher to sync A500 with
	;faster machines


	;Init
	;----
	FX_PALETTE		0,PAL_FLAME
	FX_MUSICSYNCMASK	$ff
	FX_START_MASTERFRAME	$29a	;0
	
	;Run
	;----
	;FX_PALETTE	4,PAL_FLAME

	;Pattern 1
	FX_SINE_SET	0,0,16,LINES_COMPLETE_LOOP,CTRL_SINE_X1
	FX_SINE_SET	0,0,-14,LINES_COMPLETE_LOOP,CTRL_SINE_X2

	FX_SINE_SET	0,0,6,LINES_COMPLETE_LOOP,CTRL_SINE_Y1
	FX_SINE_SET	0,0,8,LINES_COMPLETE_LOOP,CTRL_SINE_Y2

	FX_SINE_SET	0,0,-14,LINES_COMPLETE_LOOP,CTRL_SINE_X3
	FX_SINE_SET	0,0,12,LINES_COMPLETE_LOOP,CTRL_SINE_X4

	FX_SINE_SET	0,0,-14,LINES_COMPLETE_LOOP,CTRL_SINE_Y3
	FX_SINE_SET	0,0,-16,LINES_COMPLETE_LOOP,CTRL_SINE_Y4

	FX_PAUSE	(4*16)+70

	FX_PALETTE	2,PAL_BLUE
	FX_PAUSE	50

	FX_PALETTE	2,PAL_GREEN
	FX_PAUSE	50

	FX_PALETTE	2,PAL_PURPLE
	FX_PAUSE	50

	FX_PALETTE	2,PAL_RED
	FX_PAUSE	50

	FX_PALETTE	2,PAL_FLAME
	FX_PAUSE	50

	FX_PALETTE	2,PAL_BLUE
	FX_PAUSE	50

	FX_PALETTE	2,PAL_GREEN
	FX_PAUSE	50

	FX_PALETTE	2,PAL_PURPLE
	FX_PAUSE	50

	FX_PALETTE	2,PAL_RED
	FX_PAUSE	50

	FX_MUSICSYNCMASK	$00
	FX_PALETTE	4,PAL_TRANSOUT
	FX_PAUSE	(4*15)


	FX_END
