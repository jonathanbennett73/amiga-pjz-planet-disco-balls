*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music

*****************************************************************************

Sprite0:
	dc.w	0,0			;CTRL words
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	$aaaa,$aaaa
	dc.w	0,0			;STOP

*****************************************************************************

BOB_WIDTH	equ	16
BOB_BYTEWIDTH	equ	BOB_WIDTH/8
BOB_WORDWIDTH	equ	BOB_BYTEWIDTH/2
BOB_HEIGHT	equ	16
BOB_NUMPLANES	equ	3
BOB_SIZE	equ	BOB_BYTEWIDTH*BOB_HEIGHT
BOB_TOTALSIZE	equ	BOB_SIZE*BOB_NUMPLANES

;BOB in kingcon format, interleaved and masked
BOB_BPL:
	incbin "../AssetsConverted/ball4_16x16x3_inter.BPL"

*****************************************************************************

; Copper horizontal blanking notes from Photon/Scoopex
; As established, positions $e7...$03 are not usable. If you're writing a simple 
; copperlist with no need for tight timing, positions $df and $07 are conventionally 
; used for the positions on either side of the horizontal blanking, and for 
; compatibility across chipsets use increments of 4 from these, resulting in 
; positions $db, $0b, and so on.
; During horizontal blanking, MOVEs take 8 cycles (pixels) to execute. During DMA activity, 
; MOVEs will take 12 or 16 (but no more than 16). A typical example is between DDFSTRT 
; and DDFSTOP when bitplane DMA has to be read and output to the screen. Here, 3 
; bitplanes will increase the timing to 12px and 4 (or more) bitplanes will increase it to 16.
;
; The horizontal beam position has a value of $0 to $E2. The least
; significant bit is not used in the comparison, so there are 113 positions
; available for Copper operations. This corresponds to 4 pixels in low
; resolution and 8 pixels in high resolution. Horizontal blanking falls in
; the range of $0F to $35. The standard screen (320 pixels wide) has an
; unused horizontal portion of $04 to $47 (during which only the background
; color is displayed).
;
; $3e and $dc are the hpos for changing color at edges of 320 screen
; $3e+2 is 4 pixels to the right
;
; 1 copper move = 2 DMA slots
; 1 bitplane = 1 DMA slot per 16 pixels
; hence:
; 3 copper moves per 32 pixels =
; 3 * 2 DMA slots per 32 pixels =
; 3 * 2 / 2 DMA slots per 32 / 2 pixels =
; 3 DMA slots per 16 pixels =
; 3 bitplanes

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
	CMOVE 	bplcon0,(BPL_BUF_NUMPLANES*$1000)|$0200
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0000
	CMOVE 	bpl1mod,BPL_BPLMOD
	CMOVE 	bpl2mod,BPL_BPLMOD

	CMOVE	dmacon,DMAF_SETCLR|DMAF_SPRITE	;enable sprites

	;If we have a single CL then allow some time for changing ptrs
	ifeq	P0_CL_NUM_BUFFERS-1
	CWAIT	25-1,$7			;25 is end of vblank
	;CWAIT	P0_DIW_V-1,$7
	endif

P0_CL_Bpl:				;Bitplane pointers
	CMOVE	bpl1pth,$0
	CMOVE	bpl1ptl,$0
	CMOVE	bpl2pth,$0
	CMOVE	bpl2ptl,$0
	CMOVE	bpl3pth,$0
	CMOVE	bpl3ptl,$0
	CMOVE	bpl4pth,$0
	CMOVE	bpl4ptl,$0
	CMOVE	bpl5pth,$0
	CMOVE	bpl5ptl,$0

P0_CL_Scr_Sprites:
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

	CMOVE	color17,$f00
	CMOVE	color18,$0f0
	CMOVE	color19,$00f

	;multiplexed sprite example
a set P0_DIW_V				;v pos for cwait
	rept 16
b set ((P0_DIW_H>>1)-8)			;h pos for sprxpos (drop the LSB) so hpos of $81 = $40
	CWAIT	a,b
b set b+8				;8 is the next 16 pixels because of no LSB
	CMOVE	spr0pos,((a<<8)|b)
	COPPERNOP
b set b+8
	CMOVE	spr0pos,((a<<8)|b)
a set a+1	
	endr

P0_CL_Pattern:
a set P0_DIW_V-1			;First wait is for end of previous line, so we don't need two waits per line
	rept BPL_HEIGHT
;	CWAIT	(a&$ff),$df
;	CMOVE	bplcon0,$0		;need to turn off bitplanes when shrinking
;	CMOVE 	bpl1mod,$0
;	CMOVE 	bpl2mod,$0
a set a+1
	endr

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

P0_CL_BPL_OFFSET 	equ	P0_CL_Bpl-P0_CL_Phys
P0_CL_SPRITES_OFFSET	equ	P0_CL_Scr_Sprites-P0_CL_Phys
P0_CL_COL_OFFSET	equ	P0_CL_Cols-P0_CL_Phys
P0_CL_PATTERN_OFFSET	equ	P0_CL_Pattern-P0_CL_Phys
P0_CL_SIZE		equ	P0_CL_End-P0_CL_Phys


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_ChipBss,bss_c

*****************************************************************************

;CUR_CHIP_BUF set FW_Chip_Buffer_1

;BPL_Phys:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Phys	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;BPL_Log1:	ds.b	BPL_BUF_TOTALSIZE
;BPL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+BPL_BUF_TOTALSIZE

;P0_CL_Log1:	ds.b	P0_CL_SIZE
;P0_CL_Log1	equ	CUR_CHIP_BUF
;CUR_CHIP_BUF	set	CUR_CHIP_BUF+P0_CL_SIZE

