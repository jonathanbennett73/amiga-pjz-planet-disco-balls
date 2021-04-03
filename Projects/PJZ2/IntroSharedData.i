	IFND _INTROSHAREDDATA_I
_INTROSHAREDDATA_I SET 1

*****************************************************************************

; Name			: IntroLibrary.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Shared library structures.
; Date last edited	: 24/05/2019
				
*****************************************************************************
*****************************************************************************

;Light sprite data
SPR_DISCOBALL_HEIGHT equ 31
SPR_DISCOBALL_CENTER equ 15	;15th pixel is center in both x and y
SPR_DISCOBALL_FRAMES equ 4

;This is the filesize of the .spr file for when we copy into chipram
;TODO: Create a "filesize <filename> <define>" to automate this
SPR_DISCOBALL_SIZEOF equ 1072		;Set to same size as Disco_Sprite_32x32x2_4c_A_4frames.SPR

*****************************************************************************

; Size to allocate for font, set to filesize of .BPL
;TODO: create code to define this automatically
BPL_FONT8PX_TOTALSIZE equ 5248

; This is the actual font
; Have to declare font sizes at top to avoid assembler issues.
; Set MONO to 0 (proportional fonts) to work out on the fly. Much slower.
FONT8PX_MONO 		equ 0
FONT8PX_SPACE_WIDTH 	equ 4
FONT8PX_NUMPLANES 	equ 2
FONT8PX_HEIGHT		equ 16
FONT8PX_WIDTH		equ 8		;Actual max width of font in pixels (visible pixels)

;These values are for mono-width blits. Propoptional sizes are worked out
;on-the-fly. But the the max width is used for working out the largest X plot
;Note, even if a font is 1-15px wide, that would be a minimum blit of 1 word
;(we also add on a word for shifting when drawing, not shown here)
;All these widths must be 16px/word aligned
FONT8PX_BLT_WIDTH 	equ ((FONT8PX_WIDTH+16)/16)*16	;Round up to nearest 16px
FONT8PX_BLT_BYTEWIDTH	equ FONT8PX_BLT_WIDTH/8
FONT8PX_BLT_WORDWIDTH	equ FONT8PX_BLT_BYTEWIDTH/2
FONT8PX_BLTSIZE		equ ((FONT8PX_HEIGHT*FONT8PX_NUMPLANES*64)+FONT8PX_BLT_WORDWIDTH)

; Max x is width minus size of blt, minus 16px (extra word for shifting)
FONT8PX_X_SPACING	equ 1

*****************************************************************************

	ENDC				; _INTROSHAREDDATA_I