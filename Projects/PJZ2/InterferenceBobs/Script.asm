
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
		dc.w	\2		;new palette OFFSET
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

;0001 - bpl1
;0010 - 2
;0011 - 1+2
;0100 - 1
;0101 - 1+1
;0110 - 1+2
;0111 - 1+1+2
;1000 - 2
;1001 - 2+1
;1010 - 2+2
;1011 - 2+2+1
;1100 - 2+1
;1101 - 2+1+1
;1110 - 2+1+2
;1111 - 2+2+1+1

PAL_PaletteStart:	;for offsets

; All black and white palettes used for fades/lightsources
PAL_AllBlack:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours
PAL_ALLBLACK	equ	PAL_AllBlack-PAL_PaletteStart

;PAL_AllWhite:		dcb.w	PAL_NUMCOLS_MAIN,$fff	;main colours
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
;PAL_ALLWHITE	equ	PAL_AllWhite-PAL_PaletteStart

; Just lots of colors for testing
;PAL_Default:		dc.w	$000
;			dc.w	$fff,$0f0,$00f,$ff0,$0ff,$f0f
;			dc.w	$f77,$7f7,$77f,$ff7,$7ff,$f7f
;			dc.w	$f73,$3f7,$37f,$ff3,$7ff,$f3f
;			dc.w	$f00,$7f4,$fff,$ff9,$9ff,$f9f
;			dcb.w	PAL_NUMCOLS_MAIN-1,$fff	;main colours
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours

c1 set $505
c2 set $f5f
c3 set $faf
c4 set $fff

s1 set $000
s2 set $f55
s3 set $fff
PAL_Purple:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3	;bpl
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4		;bpl
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_PURPLE	equ	PAL_Purple-PAL_PaletteStart

c1 set $500
c2 set $f55
c3 set $faa
c4 set $fff

s1 set $000
s2 set $ff5
s3 set $fff
PAL_Red:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_RED		equ	PAL_Red-PAL_PaletteStart


c1 set $f00
c2 set $ff5
c3 set $ffa
c4 set $fff

s1 set $000
s2 set $ff5
s3 set $fff
PAL_Flame:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_FLAME	equ	PAL_Flame-PAL_PaletteStart

c1 set $550
c2 set $ff5
c3 set $ffa
c4 set $fff

s1 set $000
s2 set $35f
s3 set $fff
;PAL_Yellow:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
;			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours

c1 set $005
c2 set $35f
c3 set $3af
c4 set $3ff

s1 set $000
s2 set $5f5
s3 set $fff
PAL_Blue:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_BLUE	equ	PAL_Blue-PAL_PaletteStart


c1 set $050
c2 set $5f5
c3 set $afa
c4 set $fff

s1 set $000
s2 set $5ff
s3 set $fff
PAL_Green:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dc.w	0,s1,s2,s3,0,s1,s2,s3		;spr
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_GREEN	equ	PAL_Green-PAL_PaletteStart

c1 set $055
c2 set $5ff
c3 set $aff
c4 set $fff

s1 set $000
s2 set $5ff
s3 set $fff
;PAL_Cyan:		dc.w	$101,c1,c1,c2,c1,c2,c2,c3
;			dc.w	c1,c2,c2,c3,c2,c3,c3,c4
;			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours


PAL_Blank:		dcb.w	PAL_NUMCOLS_MAIN,$101
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours
PAL_BLANK	equ	PAL_Blank-PAL_PaletteStart

*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE/FX_STARTWAIT_MASTERFRAME
	;before loading the IRQ/Copper.
	;Better to use FX_STARTWAIT_MASTERFRAME with 0 or higher to sync A500 with
	;faster machines

numbobs set 30
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs

	;Init
	;----
	FX_PALETTE		0,PAL_ALLBLACK
	FX_MUSICSYNCMASK	$00
	FX_USERVAL		CTRL_NUMBOBS,numbobs
	FX_USERVAL		CTRL_BOB_CURRENT,0	;Square
	FX_USERVAL		CTRL_SPRITE_CURRENT,0	;Optic

	FX_START_MASTERFRAME	$1087

	;Run
	;----
	
	;FX_USERVALWAIT		CTRL_USERVAL1,$ffff
	;FX_PALETTE		0,PAL_AllBlack

	;FX_MUSICSYNCMASKWAIT	$0f
	;FX_PALETTE		0,PAL_AllBlack

	;FX_SINE_SET	0,0,10*4,0,CTRL_SINE_X3
	;FX_SINE_SET	0,0,8*4,0,CTRL_SINE_X4
	;FX_SINE_SET	0,0,4*4,0,CTRL_SINE_Y3
	;FX_SINE_SET	0,0,12*4,0,CTRL_SINE_Y3


	;Circle pattern 1
numbobs set 28
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs	
;	FX_USERVAL	CTRL_NUMBOBS,numbobs
;	FX_USERVAL	CTRL_BOB_CURRENT,0	;Circle	
;	FX_SINE_SET	0,0,8*4,numbobsloop,CTRL_SINE_X1
;	FX_SINE_SET	0,0,8*4,numbobsloop,CTRL_SINE_X2
;	FX_SINE_SET	0,0,12*4,numbobsloop,CTRL_SINE_Y1
;	FX_SINE_SET	0,BOB_SINE_NUMENTRIES/2,12*4,numbobsloop,CTRL_SINE_Y2
;	FX_PAUSE	4

;	FX_PALETTE	2,PAL_FLAME
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_BLUE
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_GREEN
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_PURPLE
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_RED
;	FX_PAUSE	4*16
;	FX_PALETTE	2,PAL_BLANK
;	FX_PAUSE	2*16

	;Square pattern 2
numbobs set 28
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs	
	FX_USERVAL	CTRL_NUMBOBS,numbobs
	FX_USERVAL	CTRL_BOB_CURRENT,4	;Square
	FX_USERVAL	CTRL_SPRITE_CURRENT,0	;Optic

	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_X1
	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_X2
	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_Y1
	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_Y2

	FX_SINE_SET	0,0,8*4,0,CTRL_SINE_X3
	FX_SINE_SET	0,0,6*4,0,CTRL_SINE_X4
	FX_SINE_SET	0,0,2*4,0,CTRL_SINE_Y3
	FX_SINE_SET	0,0,10*4,0,CTRL_SINE_Y3

	FX_PAUSE	1

	FX_PALETTE	4,PAL_FLAME
	FX_PAUSE	6*15
	FX_MUSICSYNCMASK	$ff
	FX_PALETTE	6,PAL_BLUE
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_GREEN
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_PURPLE
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_RED
	FX_PAUSE	6*15
	FX_PALETTE	2,PAL_BLANK
	FX_MUSICSYNCMASK	$00
	FX_PAUSE	2*15


	;Circle changing sizes
numbobs set 28
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs	
;	FX_USERVAL	CTRL_NUMBOBS,numbobs
;	FX_USERVAL	CTRL_BOB_CURRENT,0	;Circle	
;	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_X1
;	FX_SINE_SET	0,0,10*4,numbobsloop,CTRL_SINE_X2
;	FX_SINE_SET	0,BOB_SINE_NUMENTRIES/2,16*4,numbobsloop,CTRL_SINE_Y1
;	FX_SINE_SET	0,BOB_SINE_NUMENTRIES/2,10*4,numbobsloop,CTRL_SINE_Y2
;	FX_PAUSE	4

;	FX_PALETTE	2,PAL_FLAME
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_BLUE
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_GREEN
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_PURPLE
;	FX_PAUSE	4*16
;	FX_PALETTE	4,PAL_RED
;	FX_PAUSE	4*16
;	FX_PALETTE	2,PAL_BLANK
;	FX_PAUSE	2*16
	
	;Square pattern 1
numbobs set 28
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs	
	FX_USERVAL	CTRL_NUMBOBS,numbobs
	FX_USERVAL	CTRL_BOB_CURRENT,0	;Square
	FX_USERVAL	CTRL_SPRITE_CURRENT,4	;Tecon

	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_X1
	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_X2
	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_Y1
	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_Y2

	FX_SINE_SET	0,0,10*4,0,CTRL_SINE_X3
	FX_SINE_SET	0,0,2*4,0,CTRL_SINE_X4
	FX_SINE_SET	0,0,4*4,0,CTRL_SINE_Y3
	FX_SINE_SET	0,0,6*4,0,CTRL_SINE_Y3

	FX_PAUSE	1

	FX_PALETTE	2,PAL_FLAME
	FX_PAUSE	6*15
	FX_MUSICSYNCMASK	$ff
	FX_PALETTE	6,PAL_BLUE
	FX_PAUSE	6*15
	FX_PALETTE	46,PAL_GREEN
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_PURPLE
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_RED
	FX_PAUSE	6*15
	FX_PALETTE	2,PAL_BLANK
	FX_MUSICSYNCMASK	$0
	FX_PAUSE	2*15

	;Star pattern 1
numbobs set 12
numbobsloop set (BOB_SINE_NUMENTRIES*2)/numbobs	
	FX_USERVAL	CTRL_NUMBOBS,numbobs
	FX_USERVAL	CTRL_BOB_CURRENT,8	;Star
	FX_USERVAL	CTRL_SPRITE_CURRENT,8	;Antiriad

	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_X1
	FX_SINE_SET	0,0,6*4,numbobsloop,CTRL_SINE_X2
	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_Y1
	FX_SINE_SET	0,0,4*4,numbobsloop,CTRL_SINE_Y2

	FX_SINE_SET	0,0,12*4,0,CTRL_SINE_X3
	FX_SINE_SET	0,0,2*4,0,CTRL_SINE_X4
	FX_SINE_SET	0,0,14*4,0,CTRL_SINE_Y3
	FX_SINE_SET	0,0,4*4,0,CTRL_SINE_Y3

	FX_PAUSE	1

	FX_PALETTE	4,PAL_FLAME
	FX_PAUSE	6*15
	FX_MUSICSYNCMASK	$ff
	FX_PALETTE	6,PAL_BLUE
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_GREEN
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_PURPLE
	FX_PAUSE	6*15
	FX_PALETTE	6,PAL_RED
	FX_PAUSE	6*15
	FX_PALETTE	4,PAL_BLANK
	FX_MUSICSYNCMASK	$00
	FX_PAUSE	4*15


	;FX_MUSICSYNCMASK	$00
	;FX_PALETTE	4,PAL_ALLBLACK
	;FX_PAUSE	4*15
	FX_END
