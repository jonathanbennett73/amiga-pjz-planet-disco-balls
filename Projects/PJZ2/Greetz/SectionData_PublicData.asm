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
CTRL_BPL_VSCROLL_PHYS_PTR	rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_VSCROLL_LOG1_PTR	rs.l	1	;Logical1
CTRL_BPL_TEXT_PHYS_PTR		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_TEXT_LOG1_PTR		rs.l	1	;Logical1

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_USERVAL1			rs.w	1	;Example general purpose value

CTRL_SINE1			rs.b	CTRL_SINE_SIZEOF

CTRL_BAR1_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR1_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR2_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR2_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR3_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR3_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR4_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR4_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR5_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR5_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR6_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR6_SINE2			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR7_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_BAR7_SINE2			rs.b	CTRL_SINE_SIZEOF

CTRL_TEXT_FINISHED		rs.w	1	;1 if scroller has finished
CTRL_TEXT_PTR			rs.l	1	;The text message, 10=newline, 0=end
CTRL_TEXT_X			rs.w	1	;Current X value of next letter to print
CTRL_TEXT_VSCROLL		rs.w	1	;Upwards scroll. 0=no scroll.	
CTRL_TEXT_VSCROLL_NEXTLINE_COUNTER	rs.w	1	;Tracks when to draw new line
CTRL_TEXT_VSCROLL_DELAY		rs.w	1	;Only scroll every other frame
CTRL_TEXT_VSCROLL_STATUS	rs.w	1	;0=clear,1=draw,2=wait,3=copy

CTRL_RIPPLE_ACTIVE		rs.w	1	;ripple is active
CTRL_RIPPLE_VISIBLE_LINES	rs.w	1	;Number of visible lines
CTRL_RIPPLE_LOAD_FLAG		rs.w	1	;set to >1 to force load

CTRL_BAR_FULLY_STARTED		rs.w	1
CTRL_BAR_FADE_VAL		rs.w	1
CTRL_BAR_FADE_COUNT		rs.w	1

CTRL_BPL_FONT			rs.l	1	;Chip mem ptr to font bpl data

CTRL_SINETAB_RIPPLE_PTR		rs.l	1	;Ripple sine/cos table, LIB_GENSIN_16384_2048W_NUMWORDS/4 + LIB_GENSIN_16384_2048W_NUMWORDS
CTRL_SINETAB_BARPOS_PTR		rs.l	1	;Bar position sine/cos table, LIB_GENSIN_16384_2048W_NUMWORDS/4 + LIB_GENSIN_16384_2048W_NUMWORDS

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

; All black and white palettes used for fades/lightsources
PAL_AllBlack:		dcb.w	PAL_NUMCOLS_MAIN,0	;main colours
			dcb.w	PAL_NUMCOLS_ALT,0	;dark/reflection colours

PAL_AllWhite:		dcb.w	PAL_NUMCOLS_MAIN,$fff	;main colours
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours

; Just lots of colors for testing
PAL_Default:		
			dcb.w	PAL_NUMCOLS_MAIN-1,$fff	;main colours
			dcb.w	PAL_NUMCOLS_ALT,$fff	;dark/reflection colours


*****************************************************************************


; # - star
; ~ - heart
; % - train1
; ^ - train2
; & - train3
; Keep to around 37 chars 

	EVEN
Scroller_Text:
	dc.b "Abyss    Accession    Alcatraz",10
	dc.b "Arsenic    Bitbendaz    The Black Lotus",10
	dc.b "Boozoholics    BooZombies    Brainstorm ",10
	dc.b "Calamity    Da Jormas    Damones",10
	dc.b "The Deadliners    Dekadence    Depth",10
	dc.b "Desire    Dreamweb    Ephidrena",10
	dc.b "Fairlight    Fluffysoft    Flush",10
	dc.b "Focus Design   The Gang   Genesis Project",10
	dc.b "Ghostown    Haujobb    Hoaxers",10
	dc.b "Hokuto Force    Insane    Jumalauta",10
	dc.b "Lemon.    Loonies    Moods Plateau",10
	dc.b "Nah Kolor    Nature    Nukleus",10
	dc.b "Oxygene    Oxyron    Pacif!c",10
	dc.b "Panda Design    Powerline    Primitive",10
	dc.b "Proxima    Rebels    Resistance",10
	dc.b "Retro    Rift    Saunagroup",10
	dc.b "Scarab    Scoopex    Spaceballs",10
	dc.b "Talent    TEK    Traktor",10
	dc.b "TRSi    Tulou    Unique",10
	dc.b "Unstable Label    Up Rough    Y-Crew",10
	dc.b	10,10,10,10,10,10,10,10,10
	dc.b	0
	EVEN

*****************************************************************************

	;Maps a palette entry to a line of the bar
PAL_Mapping:
	dc.w	14,14,14
	dc.w	14,14,14

	dc.w	13,13,13
	dc.w	13,13,13

	dc.w	12,12,12
	dc.w	12,12,12

	dc.w	11,11,11
	dc.w	11,11,11

	dc.w	10,10,10
	dc.w	10,10,10

	dc.w	9,9,9
	dc.w	9,9,9

	dc.w	8,8,8
	dc.w	8,8,8

	dc.w	7
	dc.w	7

	dc.w	7
	dc.w	7

	dc.w	6
	dc.w	6

	dc.w	6
	dc.w	6

	dc.w	0
	dc.w	0

	dc.w	-7
	dc.w	-7

	dc.w	-13
	dc.w	-13

	dc.w	-13
	dc.w	-13

	dc.w	-13
	dc.w	-13

	dc.w	-13
	dc.w	-13

	dc.w	-13
	dc.w	-13

	dc.w	-13
	dc.w	-13

	dc.w	-7
	dc.w	-7

	dc.w	0
	dc.w	0

	dc.w	6
	dc.w	6

	dc.w	6
	dc.w	6

	dc.w	7
	dc.w	7

	dc.w	7
	dc.w	7

	dc.w	8,8,8
	dc.w	8,8,8

	dc.w	9,9,9
	dc.w	9,9,9

	dc.w	10,10,10
	dc.w	10,10,10

	dc.w	11,11,11
	dc.w	11,11,11

	dc.w	12,12,12
	dc.w	12,12,12

	dc.w	13,13,13
	dc.w	13,13,13

	dc.w	14,14,14
	dc.w	14,14,14
PAL_Mapping_End
BAR_HEIGHT = (PAL_Mapping_End-PAL_Mapping)/2

	RSRESET
BAR_POS			rs.w	1		;Pos 0-255 -Bar height
BAR_COL			rs.w	1		;The base color
BAR_FADE_LEVEL		rs.w	1		;Current level, 0-14, 0=full, 14=almost black
BAR_COUNTER		rs.w	1		
BAR_PAL			rs.w	BAR_HEIGHT*BAR_NUM_FADE_LEVELS	;Current palette, starting with brightest
BAR_MUSICSYNCMASK	rs.w	1
BAR_SINE1_OFFSET	rs.w	1		;Offset to Controller_Info CTRL_BARx_SINEx offset
BAR_SINE2_OFFSET	rs.w	1
BAR_FLICKER		rs.w	1
BAR_SIZEOF		rs.w	0

BAR_PAL_SIZEOF = BAR_HEIGHT*2	;distance in bytes between each palette


; Bar definitions used to setup final structures
Bar_Definitions:	;barptr, color, pos, music mask
	dc.w	COLOR_NEON_PINK
	dc.w	$01
	dc.w	CTRL_BAR1_SINE1
	dc.w	CTRL_BAR1_SINE2

	dc.w	COLOR_NEON_YELLOW
	dc.w	$04
	dc.w	CTRL_BAR2_SINE1
	dc.w	CTRL_BAR2_SINE2

	dc.w	COLOR_NEON_PURPLE
	dc.w	$02
	dc.w	CTRL_BAR3_SINE1
	dc.w	CTRL_BAR3_SINE2

	dc.w	COLOR_NEON_GREEN
	dc.w	$08
	dc.w	CTRL_BAR4_SINE1
	dc.w	CTRL_BAR4_SINE2

	dc.w	COLOR_NEON_ORANGE
	dc.w	$09	;channel 1+4
	dc.w	CTRL_BAR5_SINE1
	dc.w	CTRL_BAR5_SINE2

	dc.w	COLOR_NEON_RED
	dc.w	$06	;channel 2+3
	dc.w	CTRL_BAR6_SINE1
	dc.w	CTRL_BAR6_SINE2

	;dc.w	COLOR_NEON_BLUE
	;dc.w	$0f	;channel all
	;dc.w	CTRL_BAR7_SINE1
	;dc.w	CTRL_BAR7_SINE2

Bar_Definitions_End:
NUM_BARS = (Bar_Definitions_End-Bar_Definitions)/8	;8 bytes per definition


*****************************************************************************

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
	CMOVE 	bplcon0,((BPL_BUF_NUMPLANES+BPL_BUF_VSCROLL_NUMPLANES)*$1000)|$0600	;dual plf
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0000		;PF1 on top
	CMOVE 	bpl1mod,BPL_VSCROLL_BPLMOD
	CMOVE 	bpl2mod,BPL_BPLMOD_REPTLINE	;just repeat a single line to save mem on background

	CMOVE	dmacon,DMAF_SPRITE	;disable sprites

	;If we have a single CL then allow some time for changing ptrs
	ifeq	P0_CL_NUM_BUFFERS-1
	CWAIT	25-1,$7			;25 is end of vblank
	endif

P0_CL_Bpl_PF1:
P0_CL_Bpl:				;Scroller 
	CMOVE	bpl1pth,$0
	CMOVE	bpl1ptl,$0
	CMOVE	bpl3pth,$0
	CMOVE	bpl3ptl,$0

P0_CL_Bpl_PF2:				;background, single bpl, repeated line to save mem
	CMOVE	bpl2pth,$0
	CMOVE	bpl2ptl,$0

P0_CL_Cols:
	CMOVE	tmpcolor00,$000
	CMOVE	color01,$000
	CMOVE	color02,$9ef
	CMOVE	color03,$3cf

P0_CL_Pattern:
a set P0_DIW_V;-1			;First wait is for end of previous line, so we don't need two waits per line
	REPT BPL_BUF_HEIGHT
	CWAIT	(a&$ff),$7
	CMOVE	bplcon0,$0		;need to turn off bitplanes when shrinking
	CMOVE 	bpl1mod,$0
	;CMOVE 	bpl2mod,$0
	CMOVE	tmpcolor00,$0
	CWAIT	(a&$ff),$df
a set a+1
	ENDR

	;background back to $000 for wrap around
	CWAIT	(a+1),$7
	CMOVE	tmpcolor00,$0

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

P0_CL_BPL_PF1_OFFSET	equ	(P0_CL_Bpl_PF1-P0_CL_Phys)
P0_CL_BPL_PF2_OFFSET	equ	(P0_CL_Bpl_PF2-P0_CL_Phys)
P0_CL_PATTERN_OFFSET	equ	(P0_CL_Pattern-P0_CL_Phys)
P0_CL_COL_OFFSET	equ	(P0_CL_Cols-P0_CL_Phys)
P0_CL_SIZE		equ	P0_CL_End-P0_CL_Phys

	rsreset
CL_PATTERN		rs.w	0
CL_PATTERN_WAIT1	rs.w	2
CL_PATTERN_BPLCON0	rs.w	2	;need to turn off bitplanes when shrinking
CL_PATTERN_BPL1MOD	rs.w	2
;CL_PATTERN_BPL2MOD	rs.w	2
CL_BAR_CMOVE_COL	rs.w	2
CL_PATTERN_WAIT2	rs.w	2
CL_PATTERN_SIZEOF	rs.w	0

*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

*****************************************************************************

Mult_LIB_BOBTABLE_SIZEOF:
	ds.w	128		;Only need 128 letters

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

;Bar_Sin_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
;Bar_Cos_Table:
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS

*****************************************************************************

Bar_List:
	ds.l	NUM_BARS

Bar_Palette_Cache:
	ds.w	BAR_NUM_FADE_LEVELS

;Bar_Data:
;	ds.b	NUM_BARS*BAR_SIZEOF

*****************************************************************************
