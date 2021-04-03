*****************************************************************************
* Included at the end of the code section (for (pc) data)
*****************************************************************************

;DMA Sprite lists. One multiplexed list of up to 8 sprites, 4 lists. 32 sprites.
;Each entry is 2 control words followed by sprite data x 8
;Plus 2 final control words
; Need to allocate 8 lists (for double buffering) in chip ram

	rsreset
SPR_LIST_CTRL		rs.w	2			;2 control words
SPR_LIST_BPL		rs.w	SPR_DISCOBALL_HEIGHT*2	;2 bpl sprites use two words per line
SPR_LIST_CTRLEND	rs.w	2
SPR_LIST_SIZESINGLE	rs.w	0

SPR_LIST_SIZEOF		equ	SPR_LIST_SIZESINGLE*SPROBJ_LIST_MAX	;Allocate 8 lists of these sizes in chip mem

;SPR_DISCOBALL_HEIGHT equ 32
;SPR_DISCOBALL_CENTER equ 15	;15th pixel is center in both x and y
;SPR_DISCOBALL_FRAMES equ 4

; Keep track of 8 lists (1 for each sprite)
	rsreset
SPR_LIST_0_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_1_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_2_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_3_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_4_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_5_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_6_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_7_PTR		rs.l	1		;pointer to a sprite list
SPR_LIST_PTRS_SIZEOF	rs.w	0

*****************************************************************************

;Sprite object lists, the details of each sprite, pos, anim frame etc

SPROBJ_LIST_MAX		equ	8
SPR_POS_SCALE		equ	4	;Positions in fixed point for slower movement. 0-(255*8) rather than 0-255
SPR_POS_SCALE_SHIFT	equ	2	;asr value for this scale
SPR_SPACING_Y		equ	5	;How far apart on Y axis

	rsreset
SPROBJ_X		rs.w	1	;Sprite x pos (screen coords)
SPROBJ_Y		rs.w	1	;y pos
SPROBJ_FRAME		rs.w	1	;Sprite frame 0-3
SPROBJ_FRAME_SPEED	rs.w	1	;Animation speed (<<1)
SPROBJ_Y_SPEED		rs.w	1
SPROBJ_OFFSET1		rs.w	1
SPROBJ_SPEED1		rs.w	1
SPROBJ_OFFSET2		rs.w	1
SPROBJ_SPEED2		rs.w	1
SPROBJ_SIZEOF		rs.w	0

ypos set -442*SPR_POS_SCALE
xoffset set 123
SPROBJ_List_0:
	dc.w	0,ypos,0,0,6,xoffset*1,2,xoffset*2,8
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*3,18,xoffset*4,6
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*5,20,xoffset*6,6
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*7,12,xoffset*8,10
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*9,14,xoffset*10,2
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*11,16,xoffset*12,8
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*13,6,xoffset*14,14
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,6,xoffset*15,8,xoffset*16,24
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)

offset set 0
SPROBJ_List_0_PTRS:
	rept 	SPROBJ_LIST_MAX
	dc.l	SPROBJ_List_0+offset
offset set offset+SPROBJ_SIZEOF
	endr


ypos set -300*SPR_POS_SCALE
xoffset set xoffset*2
SPROBJ_List_1:
	dc.w	0,ypos,0,0,4,xoffset*1,20,xoffset*2,18
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*3,18,xoffset*4,10
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*5,4,xoffset*6,12
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*7,16,xoffset*8,18
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*9,8,xoffset*10,18
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*11,18,xoffset*12,10
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*13,10,xoffset*14,12
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,4,xoffset*15,14,xoffset*16,6
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)

offset set 0
SPROBJ_List_1_PTRS:
	rept 	SPROBJ_LIST_MAX
	dc.l	SPROBJ_List_1+offset
offset set offset+SPROBJ_SIZEOF
	endr


ypos set -224*SPR_POS_SCALE
xoffset set xoffset*2
SPROBJ_List_2:
	dc.w	0,ypos,0,0,2,xoffset*1,18,xoffset*2,-16
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*3,4,xoffset*4,6
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*5,14,xoffset*6,-24
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*7,10,xoffset*8,-4
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*9,18,xoffset*10,-16
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*11,4,xoffset*12,6
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*13,14,xoffset*14,-24
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,2,xoffset*15,10,xoffset*16,-4
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)

offset set 0
SPROBJ_List_2_PTRS:
	rept 	SPROBJ_LIST_MAX
	dc.l	SPROBJ_List_2+offset
offset set offset+SPROBJ_SIZEOF
	endr


ypos set -224*SPR_POS_SCALE
xoffset set xoffset*2
SPROBJ_List_3:
	dc.w	0,ypos,0,0,1,xoffset*1,8,xoffset*2,-24
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*3,20,xoffset*4,16
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*5,4,xoffset*6,-26
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*7,18,xoffset*8,-8
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*9,8,xoffset*10,-24
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*11,20,xoffset*12,16
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*13,4,xoffset*14,-26
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)
	dc.w	0,ypos,0,0,1,xoffset*15,18,xoffset*16,-8
ypos set ypos+(SPR_DISCOBALL_HEIGHT*SPR_POS_SCALE)+(SPR_SPACING_Y*SPR_POS_SCALE)

offset set 0
SPROBJ_List_3_PTRS:
	rept 	SPROBJ_LIST_MAX
	dc.l	SPROBJ_List_3+offset
offset set offset+SPROBJ_SIZEOF
	endr




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
CTRL_BPL_OVR_PHYS_PTR		rs.l	1	;bpl and cl ptrs must stay in order as accessed as group.
CTRL_BPL_OVR_LOG1_PTR		rs.l	1	;Logical1
CTRL_CL_PHYS_PTR		rs.l	1	;Copper ptr - physical
CTRL_CL_LOG1_PTR		rs.l	1	;Logical1
CTRL_SPR_LISTS_PHYS_PTR		rs.l	1
CTRL_SPR_LISTS_LOG1_PTR		rs.l	1

CTRL_USERVALWAIT_ACTIVE		rs.w	1	;0=inactive
CTRL_USERVALWAIT_OFFSET		rs.w	1	;Offset into CTRL_xxx for value to check
CTRL_USERVALWAIT_VAL		rs.w	1	;The value to wait for

CTRL_USERVAL1			rs.w	1	;Example general purpose value

CTRL_SINE1			rs.b	CTRL_SINE_SIZEOF
CTRL_SINE2			rs.b	CTRL_SINE_SIZEOF

CTRL_SPR_LIST_PTRS_PHYS		rs.b	SPR_LIST_PTRS_SIZEOF
CTRL_SPR_LIST_PTRS_LOG1		rs.b	SPR_LIST_PTRS_SIZEOF

CTRL_SPRITE_A_PTR		rs.l	1	;Ptr to a chipmem copy of sprite
CTRL_SORT_LIST			rs.w	1

CTRL_BPL_FONT			rs.l	1	;Chip mem ptr to font bpl data

CTRL_TEXT_PTR			rs.l	1	;The text message, 10=newline, 0=end
CTRL_TEXT_PRINTCHAR_DELAY	rs.w	1	;Time between letters printed
CTRL_TEXT_X			rs.w	1	;Current X value of next letter to print / wipe X position
CTRL_TEXT_Y			rs.w	1	;Current Y value
CTRL_TEXT_STATUS		rs.w	1	;State of the text routine, -1 is not running
CTRL_TEXT_PAUSE			rs.w	1	;Current pause counter

CTRL_WIPE_TOP_Y			rs.w	1
CTRL_WIPE_BOTTOM_Y		rs.w	1

CTRL_SINETAB_BOB_PTR		rs.l	1	;Ripple sine/cos table, LIB_GENSIN_16384_2048W_NUMWORDS/4 + LIB_GENSIN_16384_2048W_NUMWORDS


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

	even
BPL_Pic_Source:
	incbin "../AssetsConverted/EndLogo_320x158x3_inter.BPL"
	even

;PAL_Pic_Source:
;	include "../AssetsConverted/Logo1_320x160x3_inter.PAL_dcw.i"

*****************************************************************************

; # - star
; ~ - heart
; _ - train1
; ^ - train2
; & - train3
; Keep to around 37 chars 

; Using rs.l as the values will be used in a .l jmptable
	rsreset
TEXT_STATUS_NEWSCREEN		rs.l	1
TEXT_STATUS_PAUSE1		rs.l	1
TEXT_STATUS_CALCLINEDETAILS	rs.l	1
TEXT_STATUS_PRINT		rs.l	1
TEXT_STATUS_PAUSE2		rs.l	1
TEXT_STATUS_WIPE1SETUP		rs.l	1
TEXT_STATUS_WIPE1		rs.l	1
TEXT_STATUS_RESET		rs.l	1

;40 chars per line
;12 lines high

	EVEN
Scroller_Text:

	dc.b 10
	dc.b "Thanks for watching",10
	dc.b "our 64kb intro!",10
	dc.b 10
	dc.b "----------------",10
	dc.b "Planet Disco Balls",10
	dc.b "----------------",10
	dc.b 10
	dc.b "Released at Revision 2021!",10
	dc.b 10
	dc.b 10
	dc.b 13

	dc.b 10
	dc.b "Graphics: Optic",10
	dc.b "Music: Tecon",10
	dc.b "Code: Antiriad",10
	dc.b 10
	dc.b 10
	dc.b 10
	dc.b "Source code will be at:",10
	dc.b "https://github.com/jonathanbennett73",10
	dc.b 10
	dc.b 10
	dc.b 13


;Optic
	dc.b " # _^^^&^^^ # ",10
	dc.b 10
	dc.b "...optic on the keys...",10
	dc.b "As surprised as you, to find Planet.Jazz",10
	dc.b "back with another release.",10
	dc.b "Who'd have thought?!?",10
	dc.b 10
	dc.b "Much ~ love ~ to all my partners",10
	dc.b "in crime. Bringing some small ",10
	dc.b "semblance of normalcy to this weird",10
	dc.b "situation we are living through.",10
	dc.b 13

	dc.b "Can't wait for this whole thing to pass,",10
	dc.b "so we can all meet up, drink beers and",10
	dc.b "throw glenz vectors at each other again ~", 10
	dc.b 10
	dc.b "Special thanks to ~Antiriad~ for, yet again,",10
	dc.b "keeping up with the wishy-washy",10
	dc.b "Scandiwegians. You sir, are a # star #",10
	dc.b 10
	dc.b "Also doffing the cap to my friends out",10
	dc.b "there keeping the scene alive. Too many to",10
	dc.b "mention, but you know who you are ~~~",10
	dc.b 13

	dc.b "--------------------",10
	dc.b 10
	dc.b 10
	dc.b 10
	dc.b 10
	dc.b 10
	dc.b "... also ... Mygg makes mustaches look cool!",10
	dc.b "...not creepy...",10
	dc.b 10
	dc.b "optic out! ~",10
	dc.b " # _^^^&^^^ # ",10  
	dc.b 13

;Tecon
	dc.b "Slashing the keys now is Tecon!",10
	dc.b 10
	dc.b "Your dance master. Neon raster.",10
	dc.b "Groove blaster. Spell caster!",10
	dc.b 10
	dc.b "It has been my pleasure to make the",10
	dc.b "soundtrack for this tiny fraction of",10
	dc.b "your lives. ",10
	dc.b 10
	dc.b "_^^^& some messys coming up &^^&",10
	dc.b 13

	dc.b "Nectarine: Lovely musicdisk!",10
	dc.b "303BCN/Neuroflip: Cool AHX prod",10
	dc.b "Versus crew: Issue 9 was great",10
	dc.b "Spaceballs: Irregular Review pls",10
	dc.b "Desire: We want we want Chip Chop 17",10
	dc.b "Ephidrena: Wanna see your mirrorballs",10
	dc.b "Void: Thanks Puni!",10
	dc.b "Up Rough: Obese megamix! (late I know)",10
	dc.b "Insane: ..effort last yr! Thanks %~~",10
	dc.b 13

	dc.b "Frenzy, KWE, my groupmates and others:",10
	dc.b "Ive been out of touch for a while but",10
	dc.b "will soon reply! ..(sorry again)..",10
	dc.b "------------#------------",10
	dc.b 10
	dc.b "Stay tuned for another transmission",10
	dc.b "# another time - in another space #",10
	dc.b 10
	dc.b "I leave you now in the hands of",10
	dc.b "the block rocker.. the coder!",10
	dc.b 13

; Antiriad
	dc.b "Antiriad says:",10
	dc.b "Another day, another OCS intro :)",10
	dc.b 10
	dc.b "This came from wanting to do a",10
	dc.b "'proper' light-sourced vector",10
	dc.b "after being envious of the one",10
	dc.b "in Rink-a-Dink Redux!",10
	dc.b 10
	dc.b "Lots of math learning later",10
	dc.b "and I got something decent.",10
	dc.b "The rest of the intro just",10
	dc.b "came from that :)",10
	dc.b 13

	dc.b "~Big thanks~",10
	dc.b "Optic and Tecon.",10
	dc.b "",10
	dc.b "Virgill for Amigaklang",10
	dc.b "Frank Wille for vasm and ptplayer",10
	dc.b "prb28 - ASM extension for VSCode",10
	dc.b "",10
	dc.b "Denizens of EAB (in no order",10
	dc.b "and sorry if missed any):",10
	dc.b "ross, Dan, a/b, roondar, hooverphonique,",10
	dc.b "StringRay, morbid, mcgeezer, alpine9000",10
	dc.b "Galahad, Photon, meynaf, leonard",10
	dc.b 13

	dc.b "Source code is available at:",10
	dc.b "https://github.com/jonathanbennett73",10
	dc.b "",10
	dc.b "Effect notes for the geeks :) :",10
	dc.b "",10
	dc.b "Light-sourced vector:",10
	dc.b "This vector has four light sources",10
	dc.b "which can be a combination of",10
	dc.b "planar or point. I spent a lot",10
	dc.b "of time reading 'how to code vectors'",10
	dc.b "for this one. 32 x 32 animated",10
	dc.b "disco ball sprites make the lights.",10
	dc.b 13

	dc.b "Neons and greetz:",10
	dc.b "I ~love~ the neons!",10
	dc.b "",10
	dc.b "Just an upgrade of the code",10
	dc.b "from Sax Offender but bigger",10
	dc.b "and synced to the music.",10
	dc.b "",10
	dc.b "Code was a lot faster so",10
	dc.b "had time to have a scroller",10
	dc.b "with a sine effect (simple",10
	dc.b "bplmod effect)",10
	dc.b "",10
	dc.b 13

	dc.b "Interference BOBs:",10
	dc.b "1 bpl blitter-fill compatible shapes",10
	dc.b "are blitted to the screen using XOR.",10
	dc.b "The screen in filled in one pass",10
	dc.b "which creates a nice inverse effect",10
	dc.b "",10
	dc.b "The previous frames are combined on",10
	dc.b "a second bpl and then the copper",10
	dc.b "mirrors everything into 4 bpls.",10
	dc.b "",10
	dc.b "The credits are a 128px wide",10
	dc.b "bitmap overlay using 8 sprites.",10
	dc.b 13

	dc.b "Waves and dancer dude:",10
	dc.b "This is just a single line",10
	dc.b "that is generated using a",10
	dc.b "sine wave. Then each vertical",10
	dc.b "line shows that same line at",10
	dc.b "a different horizontal scroll.",10
	dc.b "The line is coloured to a value",10
	dc.b "depending on the scroll value.",10
	dc.b "",10
	dc.b "The background wave is just a",10
	dc.b "different horizontal scroll of",10
	dc.b "the same line.",10
	dc.b 13

	dc.b "These credits:",10
	dc.b "",10
	dc.b "Sprite multiplexing gone wild!",10
	dc.b "There are 32 disco balls and",10
	dc.b "each is 32 by 32 pixels. All",10
	dc.b "are using sprites.",10
	dc.b "",10
	dc.b "Yes, that is a lot of sprite",10
	dc.b "multiplexing. :D",10
	dc.b "",10
	dc.b 13

	dc.b	0

	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b "",10
	dc.b 13

	EVEN

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

	;CMOVE	fmode,MEMORYFETCHMODE	;Chip Ram fetch mode (0=OCS)
	CMOVE 	diwstrt,DIW_START
	CMOVE 	diwstop,DIW_STOP
	CMOVE 	ddfstrt,DDF_START
	CMOVE 	ddfstop,DDF_STOP
	CMOVE 	bplcon0,$5600		;5 bpl
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0042		;All sprites > PF2
	CMOVE 	bpl1mod,BPL_BPLMOD
	CMOVE 	bpl2mod,BPL_OVR_BPLMOD

	CMOVE	dmacon,DMAF_SETCLR|DMAF_SPRITE	;enable sprites

	;CWAIT	25-1,$7			;Time for altering Copperlist
	;CWAIT	P0_DIW_V-1,$7

P0_CL_Bpl:				;Bitplane pointers
	CMOVE	bpl1pth,$0
	CMOVE	bpl1ptl,$0
	CMOVE	bpl3pth,$0
	CMOVE	bpl3ptl,$0
	CMOVE	bpl5pth,$0
	CMOVE	bpl5ptl,$0

P0_CL_Bpl_Ovr:				;Bitplane pointers
	CMOVE	bpl2pth,$0
	CMOVE	bpl2ptl,$0
	CMOVE	bpl4pth,$0
	CMOVE	bpl4ptl,$0

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
	REPT	PAL_NUMCOLS_MAIN-1	
	CMOVE	a,$000
a set a+2
	ENDR


	; Trigger interrupt if P0_SCANLINE_EOF >0
	ifne FW_FRAME_IRQ_NEEDTRIG
		ifne P0_SCANLINE_EOF
			ifgt P0_SCANLINE_EOF-255
				CWAIT	255,$df
			endif
			CWAIT	((P0_SCANLINE_EOF-1)&$ff),$df
			CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
		endif
	endif

	COPPEREND
P0_CL_End:

P0_CL_BPL_OFFSET 	equ	(P0_CL_Bpl-P0_CL_Phys)
P0_CL_BPL_OVR_OFFSET	equ	(P0_CL_Bpl_Ovr-P0_CL_Phys)
P0_CL_SPRITES_OFFSET	equ	(P0_CL_Scr_Sprites-P0_CL_Phys)
P0_CL_COL_OFFSET	equ	(P0_CL_Cols-P0_CL_Phys)
P0_CL_SIZE		equ	P0_CL_End-P0_CL_Phys

*****************************************************************************

	; Include the intro script
	include "Script.asm"


*****************************************************************************
*****************************************************************************
*****************************************************************************

;	section	FW_PublicBss,bss

*****************************************************************************

;BOB_SINE_NUMENTRIES = LIB_GENSIN_16384_2048W_NUMWORDS	; Must be power of 2
;BOB_SINE_OFFSET_MASK = ((LIB_GENSIN_16384_2048W_NUMWORDS*2)-2)	; Byte offset access into the table, forced to be even 

;BOB_Sine_X:
	;INCLUDE "sine_0_92_512_words.i"
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4	;Sine part
;	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS		;Cosine part


*****************************************************************************
