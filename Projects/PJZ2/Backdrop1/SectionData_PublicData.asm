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

CTRL_BPL_PHYS_PTR:		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_LOG1_PTR:		rs.l	1	;Logical1
CTRL_BPL_LINE1_PHYS_PTR:	rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_LINE1_LOG1_PTR:	rs.l	1	;Logical1
CTRL_CL_PHYS_PTR:		rs.l	1	;Copper ptr - physical
CTRL_CL_LOG1_PTR:		rs.l	1	;Logical1

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_BLINDSFADE			rs.w	1

CTRL_SINE_FIRST			rs.b	0
CTRL_LINE_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_LINE_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BPL_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BPL_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BPL_SINE3			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE_LAST			rs.b	0
CTRL_BPL_SINE4			rs.b	CTRL_SINE_SIZEOF

CTRL_SPRITE_PTR			rs.l	1
CTRL_SPRITE_ANIM_FRAME		rs.w	1
CTRL_SPRITE_ANIM_STEP		rs.w	1

CTRL_SINETAB_PTR		rs.l	1	;sine table

CTRL_MUSIC_FADE_STEP		rs.w	1	;Fade from 0-15

CTRL_ZERODATA_SIZE		rs.w	0	;size of all zeroed data - START OF NONZERO

CTRL_SIZE			rs.w	0

Controller_Info:
	dcb.b	CTRL_ZERODATA_SIZE,0	;Init all to zero by default

*****************************************************************************

; Master palette poked into the copperlist each frame
PAL_Current:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

; This holds the old source palette used during transitions in FX_PALETTE. The
; source value is interpolated from this value to the destination value + step size.
PAL_Current_Src:	dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

*****************************************************************************

PAL_256_Col1_Src:
	dc.w		$805,$805,$805,$805,$805,$805,$805,$805
	dc.w		$905,$915,$915,$915,$915,$915,$915,$915
	dc.w		$915,$915,$915,$915,$915,$915,$915,$915
	dc.w		$a14,$a14,$a14,$a24,$a24,$a24,$a24,$a24
	dc.w		$a24,$a24,$a24,$a24,$a24,$a24,$a24,$a24
	dc.w		$b24,$b24,$b24,$b24,$b24,$b34,$b34,$b34
	dc.w		$b34,$b34,$b34,$b34,$b34,$b34,$b34,$b34
	dc.w		$c34,$c34,$c34,$c34,$c34,$c34,$c34,$c44
	dc.w		$c44,$c44,$c44,$c44,$c44,$c44,$c44,$c45
	dc.w		$c45,$c45,$c45,$c45,$c55,$c55,$c56,$c56
	dc.w		$c56,$c56,$d56,$d56,$d57,$d57,$d57,$d57
	dc.w		$d67,$d67,$d67,$d68,$d68,$d68,$d68,$d68
	dc.w		$d68,$d68,$d69,$d69,$d79,$d79,$d79,$d79
	dc.w		$d79,$d7a,$d7a,$d7a,$d7a,$d7a,$d7a,$d7a
	dc.w		$d8b,$d8b,$d8b,$d8b,$d8b,$e8b,$e8c,$e8c
	dc.w		$e8c,$e8c,$e8c,$e8c,$e8c,$e9d,$e9d,$e9d
	dc.w		$e9d,$e9d,$e9d,$e9d,$e9c,$e8c,$e8c,$e8c
	dc.w		$e8c,$e8c,$e8c,$e8b,$d8b,$d8b,$d8b,$d8b
	dc.w		$d8b,$d7b,$d7b,$d7a,$d7a,$d7a,$d7a,$d7a
	dc.w		$d7a,$d7a,$d79,$d79,$d79,$d79,$d69,$d69
	dc.w		$d69,$d68,$d68,$d68,$d68,$d68,$d68,$d68
	dc.w		$d67,$d67,$d67,$d57,$d57,$d57,$d57,$d56
	dc.w		$d56,$d56,$c56,$c56,$c56,$c56,$c56,$c55
	dc.w		$c45,$c45,$c45,$c45,$c45,$c45,$c44,$c44
	dc.w		$c44,$c44,$c44,$c44,$c44,$c44,$c34,$c34
	dc.w		$c34,$c34,$c34,$c34,$b34,$b34,$b34,$b34
	dc.w		$b34,$b34,$b34,$b34,$b34,$b34,$b24,$b24
	dc.w		$b24,$b24,$b24,$a24,$a24,$a24,$a24,$a24
	dc.w		$a24,$a24,$a24,$a24,$a24,$a24,$a24,$a14
	dc.w		$a14,$915,$915,$915,$915,$915,$915,$915
	dc.w		$915,$915,$915,$915,$915,$915,$915,$905
	dc.w		$805,$805,$805,$805,$805,$805,$805,$805

PAL_256_Col1_Src2:
	dc.w		$98f,$98f,$98f,$88f,$88f,$88f,$88f,$87f
	dc.w		$87f,$77f,$77f,$77f,$77f,$78f,$78f,$78f
	dc.w		$78f,$88f,$88f,$89f,$89f,$89f,$89f,$89f
	dc.w		$89f,$8af,$8af,$8af,$8af,$8af,$9af,$9af
	dc.w		$9bf,$9bf,$9bf,$9bf,$9bf,$9bf,$9bf,$9bf
	dc.w		$9cf,$9cf,$9cf,$9cf,$9cf,$9cf,$9cf,$9cf
	dc.w		$9df,$adf,$adf,$adf,$adf,$adf,$adf,$adf
	dc.w		$adf,$aef,$aef,$aef,$aef,$aef,$aef,$aef
	dc.w		$aef,$aef,$aef,$aef,$aef,$aef,$aee,$aee
	dc.w		$aee,$aee,$ade,$ade,$ade,$ade,$ade,$ade
	dc.w		$ade,$bdd,$bdd,$bdd,$bdd,$bdd,$bcd,$bcd
	dc.w		$bcd,$bcd,$bcd,$bcd,$bcc,$bcc,$bcc,$bcc
	dc.w		$bcc,$bbc,$bbc,$bbc,$bbc,$bbc,$bbb,$bbb
	dc.w		$bbb,$bbb,$bbc,$cbc,$ccc,$cbb,$cbb,$cbb
	dc.w		$cbb,$cbb,$cbb,$cbb,$cbb,$cbb,$caa,$caa
	dc.w		$caa,$caa,$caa,$caa,$caa,$c99,$d99,$d99
	dc.w		$d99,$d99,$c99,$c99,$caa,$caa,$caa,$caa
	dc.w		$caa,$caa,$caa,$caa,$cbb,$cbb,$cbb,$bbb
	dc.w		$bbb,$bbb,$bbb,$bbb,$bbb,$bbb,$bbb,$bbb
	dc.w		$bbb,$bbb,$bbc,$bcc,$bcc,$bcc,$bcc,$bcc
	dc.w		$bcc,$bcc,$bcc,$bcc,$bdc,$bdd,$bdd,$bdd
	dc.w		$bdd,$bdd,$bdd,$bdd,$bdd,$bdd,$bdd,$aed
	dc.w		$aed,$aed,$aee,$aee,$aee,$aee,$aee,$aee
	dc.w		$aee,$aee,$aee,$afe,$afe,$afe,$afe,$afe
	dc.w		$aff,$aff,$aff,$aff,$aff,$aff,$aff,$aff
	dc.w		$aef,$aef,$aef,$aef,$aef,$aef,$aef,$aef
	dc.w		$adf,$adf,$adf,$adf,$9df,$9df,$9df,$9df
	dc.w		$9cf,$9cf,$9cf,$9cf,$9cf,$9cf,$9cf,$9bf
	dc.w		$9bf,$9bf,$9bf,$9bf,$9bf,$8af,$8af,$8af
	dc.w		$8af,$8af,$8af,$89f,$89f,$89f,$89f,$89f
	dc.w		$88f,$78f,$78f,$78f,$78f,$77f,$77f,$77f
	dc.w		$77f,$87f,$88f,$88f,$88f,$98f,$98f,$98f


*****************************************************************************

;Light sprite data
SPR_WIDTH equ 32
SPR_HEIGHT equ 64
SPR_ANIM_FRAMES	equ 8
SPR_ANIM_FRAMES_MASK equ SPR_ANIM_FRAMES-1

;This is the filesize of the .spr file. We must allocate 4 lights worth of this
;for 4 lights in chip ram, ABC versions of the sprite set. 4*3*828 bytes
;TODO: Create a "filesize <filename> <define>" to automate this
SPR_SIZEOF equ 4256		;Set to same size as Disco_Sprite_32x32x2_A_3frames.SPR

SPR_Dancer_Source:
	incbin "../AssetsConverted/Dancer_Sprite_32x64x2_8frames.SPR"

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

	CMOVE 	diwstrt,DIW_START
	CMOVE 	diwstop,DIW_STOP
	CMOVE 	ddfstrt,DDF_START
	CMOVE 	ddfstop,DDF_STOP
	CMOVE 	bplcon0,$2200
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0020		;All sprites > PF2
	CMOVE 	bpl1mod,0
	CMOVE 	bpl2mod,0
	
P0_CL_Scr_Sprites_Enable:	
	CMOVE	dmacon,DMAF_SETCLR|DMAF_SPRITE	;enable sprites

	;CWAIT	25-1,$7			;Time for altering Copperlist
	;CWAIT	P0_DIW_V-1,$7

P0_CL_Bpl:				;Bitplane pointers
	CMOVE	bpl1pth,$0
	CMOVE	bpl1ptl,$0
	CMOVE	bpl2pth,$0
	CMOVE	bpl2ptl,$0


P0_CL_Scr_Sprites:		;We use all sprites for 4 32x32 sprites
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
a set P0_DIW_V-1
	REPT BPL_HEIGHT
	CWAIT	(a&$ff),$df
	CMOVE	bplcon1,$0000
	CMOVE	bpl1ptl,$0
	CMOVE	bpl2ptl,$0
	CMOVE 	color01,$000
	CMOVE 	color03,$000
	
	;CWAIT	(a&$ff),$3f
	;CMOVE	tmpcolor00,$000

	;CWAIT	(a&$ff),$df
	;CMOVE	tmpcolor00,$000

	;CWAIT	(a&$ff),$df	;If doing color00 changes then don't need this
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

P0_CL_BPL_OFFSET	equ	(P0_CL_Bpl-P0_CL_Phys)
P0_CL_SPRITES_OFFSET	equ	(P0_CL_Scr_Sprites-P0_CL_Phys)
P0_CL_SPRITES_ENABLE_OFFSET	equ	(P0_CL_Scr_Sprites_Enable-P0_CL_Phys)
P0_CL_PATTERN_OFFSET	equ	(P0_CL_Pattern-P0_CL_Phys)
P0_CL_COL_OFFSET	equ	(P0_CL_Cols-P0_CL_Phys)
P0_CL_SIZE		equ	P0_CL_End-P0_CL_Phys

	rsreset
CL_PATTERN_START	rs.w	0
CL_PATTERN_WAIT1	rs.w	2
CL_PATTERN_BPLCON1	rs.w	2
CL_PATTERN_BPL1PTL	rs.w	2
CL_PATTERN_BPL2PTL	rs.w	2
CL_PATTERN_COLOR01	rs.w	2
CL_PATTERN_COLOR03	rs.w	2

;CL_PATTERN_WAIT2	rs.w	2
;CL_PATTERN_COLOR00_1	rs.w	2
;CL_PATTERN_WAIT3	rs.w	2
;CL_PATTERN_COLOR00_2	rs.w	2

;CL_PATTERN_WAIT4	rs.w	2	;If doing color00 changes then don't need this
CL_PATTERN_SIZEOF	rs.w	0


*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

*****************************************************************************

; Screen height mult by screen bytewidth and number of bitplanes (interleaved)
;Mult_SCR_Height_ByteWidth_NumPlanes:
;	ds.w	BPL_BUF_HEIGHT
;Mult_SCR_Height_ByteWidth_NumPlanes	equ	CUR_PUB_BUF
;CUR_PUB_BUF	set	CUR_PUB_BUF+(BPL_BUF_HEIGHT*2)

;GenSin_Sin_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
;GenSin_Cos_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS

PAL_256_Col1_Overlap:	;need 257 entries as our sine table gives 0-256 (257 entries)
	ds.w		256

*****************************************************************************
