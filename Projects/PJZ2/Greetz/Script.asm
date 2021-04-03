
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

FX_RIPPLE	MACRO
		dc.w	FX_RIPPLE_FLAG
		dc.w	\1		;0=off, 1=on
		ENDM


*****************************************************************************

ControllerScript:
	;During init will run everything up to first FX_PAUSE before starting
	FX_PALETTE	0,PAL_AllBlack
	FX_MUSICSYNCMASK	$ff
	FX_START_MASTERFRAME	$aaa	;0

	;----

	;Text sine
	FX_SINE_SET	0,0,-32,16,CTRL_SINE1
	
	;Bars sines
	FX_SINE_SET	0,0,8,0,CTRL_BAR1_SINE1
	FX_SINE_SET	0,0,22,0,CTRL_BAR1_SINE2

	FX_SINE_SET	0,0,16,0,CTRL_BAR2_SINE1
	FX_SINE_SET	0,0,10,0,CTRL_BAR2_SINE2

	FX_SINE_SET	0,0,2,0,CTRL_BAR3_SINE1
	FX_SINE_SET	0,0,20,0,CTRL_BAR3_SINE2

	FX_SINE_SET	0,0,8,0,CTRL_BAR4_SINE1
	FX_SINE_SET	0,0,12,0,CTRL_BAR4_SINE2

	FX_SINE_SET	0,0,14,0,CTRL_BAR5_SINE1
	FX_SINE_SET	0,0,24,0,CTRL_BAR5_SINE2

	FX_SINE_SET	0,0,12,0,CTRL_BAR6_SINE1
	FX_SINE_SET	0,0,12,0,CTRL_BAR6_SINE2

	FX_SINE_SET	0,0,-12,0,CTRL_BAR7_SINE1
	FX_SINE_SET	0,0,-12,0,CTRL_BAR7_SINE2

	FX_RIPPLE	1

	FX_PAUSE	32767

	FX_END
