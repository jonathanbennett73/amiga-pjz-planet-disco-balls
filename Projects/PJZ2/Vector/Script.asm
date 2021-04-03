
*****************************************************************************
* Included at the end of the code section (for (pc) data)
*****************************************************************************

; Objects
	include "Obj_Default.i"
	include	"Obj_Icosahedron20.i"

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

FX_LOAD_FLAG			rs.l	1
FX_MORPH_FLAG			rs.l	1
FX_CLONE_ROTATION_FLAG		rs.l	1
FX_CHANGE_ROT_DELTA_FLAG	rs.l	1
FX_CHANGE_ROT_FLAG		rs.l	1
FX_HORIZSINE_FLAG		rs.l	1
FX_MOVE_FLAG			rs.l	1
FX_MOVE2_FLAG			rs.l	1
FX_LIGHTS_ENABLE_FLAG		rs.l	1
FX_LIGHT_COLOR_FLAG		rs.l	1
FX_LIGHT_DISABLE_FLAG		rs.l	1
FX_LIGHT_POINT_FLAG		rs.l	1
FX_LIGHT_PLANAR_FLAG		rs.l	1
FX_LIGHT_ROT_DELTA_FLAG		rs.l	1
FX_LIGHT_DIMMING_FLAG		rs.l	1
FX_LIGHT_MOVE_FLAG		rs.l	1

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
		dc.l	\2		;new palette
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

FX_MOVE	MACRO
		dc.w	FX_MOVE_FLAG
		dc.w	\1		;speed
		dc.w	\2,\3,\4	;new coords
		ENDM

FX_MOVE2	MACRO
		dc.w	FX_MOVE2_FLAG
		dc.w	\1		;speed
		dc.w	\2,\3,\4	;new coords
		ENDM
		
FX_MORPH	MACRO
		dc.w	FX_MORPH_FLAG
		dc.w	\1		;speed
		dc.l	\2		;new pts
		ENDM

FX_LOAD	MACRO
		dc.w	FX_LOAD_FLAG
		dc.l	\1		;new object info
		ENDM

FX_CLONE_ROTATION	MACRO
		dc.w	FX_CLONE_ROTATION_FLAG
		dc.l	\1		;new object info
		ENDM

FX_CHANGE_ROT	MACRO
		dc.w	FX_CHANGE_ROT_FLAG
		dc.w	\1,\2,\3,\4
		ENDM

FX_CHANGE_ROT_DELTA	MACRO
		dc.w	FX_CHANGE_ROT_DELTA_FLAG
		dc.w	\1,\2,\3
		ENDM

FX_HORIZSINE	MACRO
		dc.w	FX_HORIZSINE_FLAG
		dc.w	\1,\2	;speed1,step1
		ENDM

FX_LIGHTS_ENABLE	MACRO
		dc.w	FX_LIGHTS_ENABLE_FLAG
		dc.w	\1		;frames wait for (local timing)
		ENDM

FX_LIGHT_COLOR	MACRO
		dc.w	FX_LIGHT_COLOR_FLAG
		dc.w	\1		;light 0-2 (or -1 to set scene ambient)
		dc.w	\2		;speed
		dc.w	\3		;main color
		dc.w	\4		;ambient color
		ENDM

FX_LIGHT_DISABLE	MACRO
		dc.w	FX_LIGHT_DISABLE_FLAG
		dc.w	\1		;light 0-2
		ENDM

FX_LIGHT_POINT	MACRO
		dc.w	FX_LIGHT_POINT_FLAG
		dc.w	\1		;light 0-2
		dc.w	\2,\3,\4	;pos of light (relative to object)
		ENDM

FX_LIGHT_PLANAR	MACRO
		dc.w	FX_LIGHT_PLANAR_FLAG
		dc.w	\1		;light 0-2
		dc.w	\2,\3,\4	;direction of light
		ENDM

FX_LIGHT_ROT_DELTA	MACRO
		dc.w	FX_LIGHT_ROT_DELTA_FLAG
		dc.w	\1		;light 0-2
		dc.w	\2,\3,\4
		ENDM

FX_LIGHT_DIMMING	MACRO
		dc.w	FX_LIGHT_DIMMING_FLAG
		dc.w	\1		;light 0-2
		dc.w	\2		;dimming level 0-255
		dc.w	\3 		;fade step value (0-16) >0 implies music syncing
		ENDM

FX_LIGHT_MOVE	MACRO
		dc.w	FX_LIGHT_MOVE_FLAG
		dc.w	\1		;light 0-2
		dc.w	\2		;speed
		dc.w	\3,\4,\5	;new coords
		ENDM



*****************************************************************************

; Default palette loaded at startup
;PAL_Default:		dc.w	$001,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
;			dc.w	$002,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0

PAL_Light_White:	dc.w	$001,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff,$fff

     
;TransOut1 is the fade, then TransOut2 is the transition to next effect so that masks any bitmap data
;PAL_TransOut1:		dc.w	$101,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0,$0
PAL_TransOut2:		dc.w	$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000,$000


*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE/FX_STARTWAIT_MASTERFRAME
	;before loading the IRQ/Copper.
	;Better to use FX_STARTWAIT_MASTERFRAME with 0 or higher to sync A500 with
	;faster machines

	;Init
	;----
;	FX_PALETTE		0,PAL_Default
	FX_MUSICSYNCMASK	$ff
	FX_LOAD			Obj_Default_Info	;Need a default object
	FX_START_MASTERFRAME	$525	;0
	
	;Run
	;----

	FX_LOAD			Obj_Icosahedron20_Info
	FX_MOVE			0,0,0,95
	FX_PALETTE		0,PAL_Light_White
	FX_LIGHTS_ENABLE	1
	FX_CHANGE_ROT_DELTA	-16,-8,-24
	;FX_CHANGE_ROT_DELTA	0,0,0
	;FX_HORIZSINE		16,2

	;Oldschool light show
	FX_LIGHT_PLANAR		3,0,0,127
	FX_LIGHT_COLOR		3,8,$f39,$000
	FX_PAUSE		8*16
	FX_LIGHT_COLOR		3,4,$ee3,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		3,4,$73d,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		3,4,$f93,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		3,4,$000,$000
	;FX_PAUSE		4*8

	;Introduce first light
	FX_LIGHT_POINT		0,0,0,124
	FX_LIGHT_ROT_DELTA	0,10,16,0
	FX_LIGHT_COLOR		0,0,$f29,$000
	FX_LIGHT_DIMMING	0,0,6

	FX_PAUSE		4*16
	FX_LIGHT_COLOR		0,4,$8c3,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		0,4,$72d,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		0,4,$f93,$000
	FX_PAUSE		4*16
	FX_LIGHT_COLOR		0,4,$86e,$000

	FX_PAUSE		50

	;moar lights
	FX_LIGHT_POINT		1,0,0,124
	FX_LIGHT_ROT_DELTA	1,12,14,0
	FX_LIGHT_COLOR		1,0,$ff6,$000
	FX_LIGHT_DIMMING	1,0,6

	FX_PAUSE		100
	FX_LIGHT_POINT		2,0,0,124
	FX_LIGHT_ROT_DELTA	2,14,12,0
	FX_LIGHT_COLOR		2,0,$9f4,$000
	FX_LIGHT_DIMMING	2,0,6

	FX_PAUSE		100
	FX_LIGHT_POINT		3,0,0,124
	FX_LIGHT_ROT_DELTA	3,16,10,0
	FX_LIGHT_COLOR		3,0,$f6a,$000
	FX_LIGHT_DIMMING	3,0,6

	FX_PAUSE		500

;	FX_LIGHT_COLOR		0,4,$f77,$000
;	FX_LIGHT_COLOR		1,4,$f7f,$000
;	FX_LIGHT_COLOR		2,4,$ff7,$000
;	FX_LIGHT_COLOR		3,4,$77f,$000

;	FX_PAUSE		500

	FX_LIGHT_COLOR		0,4,$000,$000
	FX_LIGHT_COLOR		1,4,$000,$000
	FX_LIGHT_COLOR		2,4,$000,$000
	FX_LIGHT_COLOR		3,4,$000,$000
	;FX_PALETTE		4,PAL_TransOut1

	FX_PAUSE		2*16
	FX_LIGHT_DIMMING	0,0,0
	FX_LIGHT_DIMMING	1,0,0
	FX_LIGHT_DIMMING	2,0,0
	FX_LIGHT_DIMMING	3,0,0
	FX_PAUSE		2*16

	FX_PALETTE		0,PAL_TransOut2
	FX_LIGHTS_ENABLE	0
	FX_PAUSE		1

	FX_END
