*****************************************************************************

; Name			: IntroPrototype.asm
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com>)
; Description		: Shared useful functions that can be turned on from IntroConfig.i.
; Date last edited	: 04/02/2020
				
*****************************************************************************

	include "hardware/custom.i"
	include "hardware/intbits.i"	

	include "../IntroConfig.i"
	include	"../Framework/CustomExtra.i"
	include "../Framework/CustomMacros.i"
	include "../Framework/IntroFramework_xref.i"
	include "../Framework/IntroLibrary.i"
	include "../Framework/IntroLibrary_xref.i"
	include "../Framework/IntroPrototype.i"

;RasterTest set 2

*****************************************************************************

	;Only assemble this file if enabled
	ifne	PRO_ENABLE		

*****************************************************************************

	section	PRO_PublicCode,CODE	;Code section in Public memory

*****************************************************************************
*****************************************************************************


*****************************************************************************
* Calcs and draws a line in one go. Multiple bitplanes.
* Routine ensures that y2>y1 and draws from top of screen to bottom.
* Two ways of removing a corner (for blitter fill):
* - Point bltdpth to a blank word. This causes the FIRST pixel (top) to be
* not written to screen. In this case first scanline is never touched.
* - Reduce dy by one, which seems a kludge but seems to work. In this case
* the last scanline (bottom) is not drawn and is also slightly faster (one less y).
*
* IN:		a6, _custom)
*		a0, screen address
*		a1, linedraw vars
*			linedraw premult table must match the modulo
*		d0-d3, x,y,x2,y2 of the line to draw
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef PRO_Line_Fill_Draw_Init
PRO_Line_Fill_Draw_Init:				;T:d0/a0
	lea	PRO_Line_Fill_Vars(pc),a0
	moveq	#-1,d0
	WAITBLIT_NASTY_A6
	move.l	d0,bltafwm(a6)				;mask
	move.w	PRO_LINE_MOD_LINE(a0),bltcmod(a6)	;modulo, DMOD NOT required
	move.w	PRO_LINE_TEXTURE(a0),bltbdat(a6)	;texture
	move.w	#$8000,bltadat(a6)
	rts

	xdef PRO_Line_Fill_Draw
PRO_Line_Fill_Draw:
	movem.l	d2-d4,-(sp)

	;The linedraw routine draws from top of screen to bottom. We want
	;y2 > y1 for the logic used.
	sub.w 	d1,d3			;dy
	beq	.NoDrawLine		;skip when y1=y2
	bpl.b	.line1			;ensure y2>y1
	exg	d0,d2				
	neg.w	d3			
	sub.w	d3,d1			
.line1:
	subq	#1,d3			;dy-1 for blit corner fix
					;replaced with bltdpth scratch space

	move.l	#$a4a0000f,d4		;$4a=inverted line, $ca=normal
	and.w	d0,d4			;x & 15
	ror.l	#4,d4			;get shift value in top of word for bltcon0, low word cleared for move.b later

	sub.w	d0,d2			;dx
	bpl.b	.line2
	neg.w	d2			;make dx postive
	addq.w	#2,d4
.line2:					
	; Mulu y version
	lsr.w	#3,d0			;x1 to byte offset, odd address ignored
	mulu	.vars+PRO_LINE_MOD_LINE(pc),d1
	add.l	d1,a0			;update with yoffset, y maybe > 32767 so need to use add.l
	add.w	d0,a0			;update with xoffset, a0 is final screen address
	; ----
	; Table y lookup version, ;ASSERT: d0/d1 are positive.
;	lsr.w	#3,d0			;x1 to byte offset, odd address ignored
;	add.w	d1,d1			;y table access offset in words
;	add.w	LINEDRAW_MULT(a1,d1.w),d1	;pdate with yoffset
;	add.w	d0,a0			;update with xoffset, a0 is final screen address
	;---

	cmp.w	d2,d3
	bmi.b	.line3
	addq.w	#1,d4					
	exg	d2,d3
.line3:
	move.w	d3,d1			;dy
	add.w	d1,d1			;2*dy; bltbmod
	swap	d1			;bltbmod in top word
	move.w	d3,d1
	sub.w	d2,d1			;dy-dx
	add.w	d1,d1			;2*(dy-dx) ; bltamod	
					;d1.l = bltbmod/bltamod
	add.w	d3,d3
	sub.w	d2,d3			;(2*dy)-dx ; bltaptl
	addx.w	d4,d4
	move.b	.octants(pc,d4.w),d4	;d4.l now bltcon0/1 (top of d4.w is 0 before this)

	addq.w	#1,d2			;dx+1
	lsl.w	#6,d2			;move to bits 15-6
	addq.w	#2,d2			;bltsize

	move.w  .vars+PRO_LINE_COLOR(pc),d0	;get required color
	lsr.w	#1,d0			;Color bit set?
	bcc.s	.nextbpl		;No, next bpl
.colorloop
	WAITBLIT_A6

	; NOTE: These three lines can be moved out if drawing loads of lines at once
	;move.l	#-1,bltafwm(a6)		;mask
	;move.w	.vars+PRO_LINE_MOD_LINE(pc),bltcmod(a6)	;modulo, DMOD NOT required
	;move.w	.vars+PRO_LINE_TEXTURE(pc),bltbdat(a6)	;texture
	;move.w	#$8000,bltadat(a6)
	; --------
		
	move.l	d4,bltcon0(a6)		;bltcon0/bltcon1
	move.l	d1,bltbmod(a6) 		;bltbmod/bltamod
	move.l  a0,bltcpth(a6) 
	move.w 	d3,bltaptl(a6)
	move.l  a0,bltdpth(a6) 
	;move.l	#FW_LineDraw_Scratch,bltdpth(a6) ;First pixel is written here (offscreen)
	move.w	d2,bltsize(a6)
.nextbpl:
	add.w	.vars+PRO_LINE_MOD_BPL(pc),a0	;next bitplane
	lsr.w	#1,d0				;check next bit 
	bcs.s	.colorloop			;bit set?
	bne.s	.nextbpl			;any color left?
.NoDrawLine:	

	movem.l	(sp)+,d2-d4
	rts

.octantbase equ 3				;1=normal,3=1px per line (fill)
.octants:
	dc.b	$10+.octantbase
	dc.b	$50+.octantbase
	dc.b	$00+.octantbase
	dc.b	$40+.octantbase
	dc.b	$14+.octantbase
	dc.b	$54+.octantbase
	dc.b	$08+.octantbase
	dc.b	$48+.octantbase

	xdef PRO_Line_Fill_Vars
.vars
PRO_Line_Fill_Vars:
	dc.w    0       		;PRO_LINE_COLOR
	dc.w	0			;PRO_LINE_CLIP_MINX
	dc.w	0			;PRO_LINE_CLIP_MINY
	dc.w	319			;PRO_LINE_CLIP_MAXX
	dc.w	255			;PRO_LINE_CLIP_MAXY
	dc.w	$ffff			;PRO_LINE_TEXTURE	
	dc.w	0			;PRO_LINE_MOD_LINE
	dc.w	0			;PRO_LINE_MOD_BPL

;PRO_LINE_COLOR:		rs.w 1			;Color of lines
;PRO_LINE_CLIP_MINX	rs.w 1
;PRO_LINE_CLIP_MINY	rs.w 1
;PRO_LINE_CLIP_MAXX	rs.w 1
;PRO_LINE_CLIP_MAXY	rs.w 1
;PRO_LINE_TEXTURE	rs.w 1
;PRO_LINE_MOD_LINE	rs.w 1
;PRO_LINE_MOD_BPL	rs.w 1


*****************************************************************************
* Calcs and draws a line in one go. Multiple bitplanes.
* Routine ensures that y2>y1 and draws from top of screen to bottom.
* Two ways of removing a corner (for blitter fill):
* - Point bltdpth to a blank word. This causes the FIRST pixel (top) to be
* not written to screen. In this case first scanline is never touched.
* - Reduce dy by one, which seems a kludge but seems to work. In this case
* the last scanline (bottom) is not drawn and is also slightly faster (one less y).
*
* IN:		a6, _custom)
*		a0, screen address
*		a1, linedraw vars
*			linedraw premult table must match the modulo
*		d0-d3, x,y,x2,y2 of the line to draw
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef PRO_Line_Draw_Init
PRO_Line_Draw_Init:					;T:d0/a0
	lea	PRO_Line_Vars(pc),a0
	moveq	#-1,d0
	WAITBLIT_NASTY_A6
	move.l	d0,bltafwm(a6)				;mask
	move.w	PRO_LINE_MOD_LINE(a0),bltcmod(a6)	;modulo, DMOD NOT required
	move.w	PRO_LINE_TEXTURE(a0),bltbdat(a6)	;texture
	move.w	#$8000,bltadat(a6)
	rts


	xdef PRO_Line_Draw		;T:d0-d1/a0
PRO_Line_Draw:
	movem.l	d2-d4,-(sp)

	;The linedraw routine draws from top of screen to bottom. We want
	;y2 > y1 for the logic used.
	sub.w 	d1,d3			;dy
	;beq	.NoDrawLine		;skip when y1=y2
	bpl.b	.line1			;ensure y2>y1
	exg	d0,d2				
	neg.w	d3			
	sub.w	d3,d1			
.line1:
	move.l	#$aca0000f,d4		;$4a=inverted line, $ca=normal
	and.w	d0,d4			;x & 15
	ror.l	#4,d4			;get shift value in top of word for bltcon0, low word cleared for move.b later

	sub.w	d0,d2			;dx
	bpl.b	.line2
	neg.w	d2			;make dx postive
	addq.w	#2,d4
.line2:					
	; Mulu y version
	lsr.w	#3,d0			;x1 to byte offset, odd address ignored
	mulu	.vars+PRO_LINE_MOD_LINE(pc),d1
	add.l	d1,a0			;update with yoffset, y maybe > 32767 so need to use add.l
	add.w	d0,a0			;update with xoffset, a0 is final screen address
	; ----
	; Table y lookup version, ;ASSERT: d0/d1 are positive.
;	lsr.w	#3,d0			;x1 to byte offset
;	add.w	d1,d1			;y table access offset in words
;	add.w	LINEDRAW_MULT(a1,d1.w),d1	;pdate with yoffset
;	add.w	d0,a0			;update with xoffset, a0 is final screen address
	;---

	cmp.w	d2,d3
	bmi.b	.line3
	addq.w	#1,d4					
	exg	d2,d3
.line3:
	move.w	d3,d1			;dy
	add.w	d1,d1			;2*dy; bltbmod
	swap	d1			;bltbmod in top word
	move.w	d3,d1
	sub.w	d2,d1			;dy-dx
	add.w	d1,d1			;2*(dy-dx) ; bltamod	
					;d1.l = bltbmod/bltamod
	add.w	d3,d3
	sub.w	d2,d3			;(2*dy)-dx ; bltaptl
	addx.w	d4,d4
	move.b	.octants(pc,d4.w),d4	;d4.l now bltcon0/1 (top of d4.w is 0 before this)

	addq.w	#1,d2			;dx+1
	lsl.w	#6,d2			;move to bits 15-6
	addq.w	#2,d2			;bltsize

	move.w  .vars+PRO_LINE_COLOR(pc),d0	;get required color
	lsr.w	#1,d0			;Color bit set?
	bcc.s	.nextbpl		;No, next bpl
.colorloop
	WAITBLIT_A6
	move.l	d4,bltcon0(a6)		;bltcon0/bltcon1
	move.l	d1,bltbmod(a6) 		;bltbmod/bltamod
	move.l  a0,bltcpth(a6) 
	move.w 	d3,bltaptl(a6)
	move.l  a0,bltdpth(a6) 
	move.w	d2,bltsize(a6)
.nextbpl:
	add.w	.vars+PRO_LINE_MOD_BPL(pc),a0	;next bitplane
	lsr.w	#1,d0				;check next bit 
	bcs.s	.colorloop			;bit set?
	bne.s	.nextbpl			;any color left?
.NoDrawLine:	

	movem.l	(sp)+,d2-d4
	rts

.octantbase equ 1			;1=normal,3=1px per line (fill)
.octants:
	dc.b	$10+.octantbase
	dc.b	$50+.octantbase
	dc.b	$00+.octantbase
	dc.b	$40+.octantbase
	dc.b	$14+.octantbase
	dc.b	$54+.octantbase
	dc.b	$08+.octantbase
	dc.b	$48+.octantbase

	xdef PRO_Line_Vars
.vars
PRO_Line_Vars:
	dc.w    0       		;PRO_LINE_COLOR
	dc.w	0			;PRO_LINE_CLIP_MINX
	dc.w	0			;PRO_LINE_CLIP_MINY
	dc.w	319			;PRO_LINE_CLIP_MAXX
	dc.w	255			;PRO_LINE_CLIP_MAXY
	dc.w	$ffff			;PRO_LINE_TEXTURE
	dc.w	0			;PRO_LINE_MOD_LINE
	dc.w	0			;PRO_LINE_MOD_BPL

;PRO_LINE_COLOR:		rs.w 1			;Color of lines
;PRO_LINE_CLIP_MINX	rs.w 1
;PRO_LINE_CLIP_MINY	rs.w 1
;PRO_LINE_CLIP_MAXX	rs.w 1
;PRO_LINE_CLIP_MAXY	rs.w 1
;PRO_LINE_TEXTURE	rs.w 1
;PRO_LINE_MOD_LINE	rs.w 1
;PRO_LINE_MOD_BPL	rs.w 1


*****************************************************************************
* Draws a BOB.
*
* IN:		a0, bob
*		a1, screen
*		a6, _custom
*		d0.w/d1.w, x,y
* OUT:		
* TRASHED:	d0-d1/a1
*****************************************************************************

	xdef	PRO_BOB_Draw_Copy
PRO_BOB_Draw_Copy:
	ext.l	d0			;ensure top word clear
	mulu	.vars+PRO_BOB_MOD_LINE(pc),d1	;line offset

	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen (x / 8)
	add.w	d0,d1			;add byte offset to y offset (WARNING: possible 64k overflow)
	add.w	d1,a0			;Add offset to screen ptr

	swap	d0			;d0.w now contains shift value in top nibble
	;move.w	d0,d2			;save B shift
	or.w	#BLT_SRC_AD+BLT_A,d0	;add minterm - $09f0
	swap	d0			;d0.l=bltcon0 in high word
	;move.w	d2,d0			;d0.l=bltcon0 and bltcon1
	clr.w	d0

	WAITBLIT_NASTY_A6
	move.l	d0,bltcon0(a6)		;bltcon0/1
	move.l	.vars+PRO_BOB_BLTFWM(pc),bltafwm(a6)
	move.w	.vars+PRO_BOB_BLTAMOD(pc),bltamod(a6)	
	move.w	.vars+PRO_BOB_BLTDMOD(pc),bltdmod(a6)	
	move.l	a1,bltapth(a6)		;BLTAPTH ($50)
	move.l	a0,bltdpth(a6)		;BLTDPTH ($54)
	move.w	.vars+PRO_BOB_BLTSIZE(pc),bltsize(a6)		;BLTSIZE ($58)

	rts

	xdef	PRO_BOB_Draw_Copy_Vars
.vars
PRO_BOB_Draw_Copy_Vars:
	dc.w	0			;PRO_BOB_MOD_LINE
	dc.w	0			;PRO_BOB_BLTFWM
	dc.w	0			;PRO_BOB_BLTLWM
	dc.w	0			;PRO_BOB_BLTCMOD
	dc.w	0			;PRO_BOB_BLTBMOD
	dc.w	0			;PRO_BOB_BLTAMOD
	dc.w	0			;PRO_BOB_BLTDMOD
	dc.w	0			;PRO_BOB_BLTSIZE

;	rsreset
;PRO_BOB_MOD_LINE	rs.w 1
;PRO_BOB_BLTFWM		rs.w 1
;PRO_BOB_BLTLWM		rs.w 1
;PRO_BOB_BLTCMOD		rs.w 1
;PRO_BOB_BLTBMOD		rs.w 1
;PRO_BOB_BLTAMOD		rs.w 1
;PRO_BOB_BLTDMOD		rs.w 1
;PRO_BOB_BLTSIZE		rs.w 1


*****************************************************************************
* Draws a BOB using OR. $bfa (A or B)
*
* IN:		a0, screen
*		a1, bob
*		a6, _custom
*		d0.w/d1.w, x,y
* OUT:		
* TRASHED:	d0-d1/a1
*****************************************************************************

	xdef	PRO_BOB_Draw_OR
PRO_BOB_Draw_OR:
	ext.l	d0			;ensure top word clear
	mulu	.vars+PRO_BOB_MOD_LINE(pc),d1	;line offset

	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen (x / 8)
	add.w	d0,d1			;add byte offset to y offset (WARNING: possible 64k overflow)
	add.w	d1,a0			;Add offset to screen ptr

	swap	d0			;d0.w now contains shift value in top nibble
	;move.w	d0,d2			;save B shift
	or.w	#BLT_SRC_ABD+(BLT_A|BLT_B),d0	;add minterm - $0dfc
	swap	d0			;d0.l=bltcon0 in high word
	;move.w	d2,d0			;d0.l=bltcon0 and bltcon1
	clr.w	d0

	WAITBLIT_NASTY_A6
	move.l	d0,bltcon0(a6)		;bltcon0/1
	move.l	.vars+PRO_BOB_BLTFWM(pc),bltafwm(a6)
	move.w	.vars+PRO_BOB_BLTAMOD(pc),bltamod(a6)
	move.w	.vars+PRO_BOB_BLTBMOD(pc),bltbmod(a6)		
	move.w	.vars+PRO_BOB_BLTDMOD(pc),bltdmod(a6)
	move.l	a1,bltapth(a6)		;BLTAPTH ($50)
	move.l	a0,bltbpth(a6)		;BLTCPTH ($48)
	move.l	a0,bltdpth(a6)		;BLTDPTH ($54)
	move.w	.vars+PRO_BOB_BLTSIZE(pc),bltsize(a6)		;BLTSIZE ($58)

	rts

	xdef	PRO_BOB_Draw_OR_Vars
.vars
PRO_BOB_Draw_OR_Vars:
	dc.w	0			;PRO_BOB_MOD_LINE
	dc.w	0			;PRO_BOB_BLTFWM
	dc.w	0			;PRO_BOB_BLTLWM
	dc.w	0			;PRO_BOB_BLTCMOD
	dc.w	0			;PRO_BOB_BLTBMOD
	dc.w	0			;PRO_BOB_BLTAMOD
	dc.w	0			;PRO_BOB_BLTDMOD
	dc.w	0			;PRO_BOB_BLTSIZE

;	rsreset
;PRO_BOB_MOD_LINE	rs.w 1
;PRO_BOB_BLTFWM		rs.w 1
;PRO_BOB_BLTLWM		rs.w 1
;PRO_BOB_BLTCMOD		rs.w 1
;PRO_BOB_BLTBMOD		rs.w 1
;PRO_BOB_BLTAMOD		rs.w 1
;PRO_BOB_BLTDMOD		rs.w 1
;PRO_BOB_BLTSIZE		rs.w 1


*****************************************************************************
* Draws a BOB using XOR. $b3c (A eor B)
*
* IN:		a0, screen
*		a1, bob
*		a6, _custom
*		d0.w/d1.w, x,y
* OUT:		
* TRASHED:	d0-d1/a1
*****************************************************************************

	xdef	PRO_BOB_Draw_XOR
PRO_BOB_Draw_XOR:
	ext.l	d0			;ensure top word clear
	mulu	.vars+PRO_BOB_MOD_LINE(pc),d1	;line offset

	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen (x / 8)
	add.w	d0,d1			;add byte offset to y offset (WARNING: possible 64k overflow)
	add.w	d1,a0			;Add offset to screen ptr

	swap	d0			;d0.w now contains shift value in top nibble
	;move.w	d0,d2			;save B shift
	or.w	#BLT_SRC_ABD+(BLT_A^BLT_B),d0	;add minterm
	swap	d0			;d0.l=bltcon0 in high word
	;move.w	d2,d0			;d0.l=bltcon0 and bltcon1
	clr.w	d0

	WAITBLIT_NASTY_A6
	move.l	d0,bltcon0(a6)		;bltcon0/1
	move.l	.vars+PRO_BOB_BLTFWM(pc),bltafwm(a6)
	move.w	.vars+PRO_BOB_BLTAMOD(pc),bltamod(a6)
	move.w	.vars+PRO_BOB_BLTBMOD(pc),bltbmod(a6)		
	move.w	.vars+PRO_BOB_BLTDMOD(pc),bltdmod(a6)
	move.l	a1,bltapth(a6)		;BLTAPTH ($50)
	move.l	a0,bltbpth(a6)		;BLTCPTH ($48)
	move.l	a0,bltdpth(a6)		;BLTDPTH ($54)
	move.w	.vars+PRO_BOB_BLTSIZE(pc),bltsize(a6)		;BLTSIZE ($58)

	rts

	xdef	PRO_BOB_Draw_XOR_Vars
.vars
PRO_BOB_Draw_XOR_Vars:
	dc.w	0			;PRO_BOB_MOD_LINE
	dc.w	0			;PRO_BOB_BLTFWM
	dc.w	0			;PRO_BOB_BLTLWM
	dc.w	0			;PRO_BOB_BLTCMOD
	dc.w	0			;PRO_BOB_BLTBMOD
	dc.w	0			;PRO_BOB_BLTAMOD
	dc.w	0			;PRO_BOB_BLTDMOD
	dc.w	0			;PRO_BOB_BLTSIZE

;	rsreset
;PRO_BOB_MOD_LINE	rs.w 1
;PRO_BOB_BLTFWM		rs.w 1
;PRO_BOB_BLTLWM		rs.w 1
;PRO_BOB_BLTCMOD		rs.w 1
;PRO_BOB_BLTBMOD		rs.w 1
;PRO_BOB_BLTAMOD		rs.w 1
;PRO_BOB_BLTDMOD		rs.w 1
;PRO_BOB_BLTSIZE		rs.w 1


*****************************************************************************
* Draws a BOB using Cookie cut. $$fca
*
* IN:		a0, screen
*		a1, bob
*		a2, mask
*		a6, _custom
*		d0.w/d1.w, x,y
* OUT:		
* TRASHED:	d0-d1/a1
*****************************************************************************

	xdef	PRO_BOB_Draw_Cookie
PRO_BOB_Draw_Cookie:
	ext.l	d0			;ensure top word clear
	mulu	.vars+PRO_BOB_MOD_LINE(pc),d1	;line offset

	ror.l	#4,d0			;hiword of d0 contains shift in highest nibble
	add.w	d0,d0			;loword d0 contains byte offset into screen (x / 8)
	add.w	d0,d1			;add byte offset to y offset (WARNING: possible 64k overflow)
	add.w	d1,a0			;Add offset to screen ptr

	swap	d0			;d0.w now contains shift value in top nibble
	move.w	d0,d2			;save B shift
	or.w	#BLT_SRC_ABCD+((BLT_A&BLT_B)|(BLT_C&(~BLT_A))),d0	;add minterm - $0ca
	swap	d0			;d0.l=bltcon0 in high word
	move.w	d2,d0			;d0.l=bltcon0 and bltcon1

	WAITBLIT_NASTY_A6
	move.l	d0,bltcon0(a6)		;bltcon0/1
	move.l	.vars+PRO_BOB_BLTFWM(pc),bltafwm(a6)
	move.w	.vars+PRO_BOB_BLTAMOD(pc),bltamod(a6)
	move.w	.vars+PRO_BOB_BLTBMOD(pc),bltbmod(a6)
	move.w	.vars+PRO_BOB_BLTCMOD(pc),bltcmod(a6)		
	move.w	.vars+PRO_BOB_BLTDMOD(pc),bltdmod(a6)
	move.l	a2,bltapth(a6)		;BLTAPTH
	move.l	a1,bltbpth(a6)		;BLTBPTH
	move.l	a0,bltcpth(a6)		;BLTDPTH
	move.l	a0,bltdpth(a6)		;BLTDPTH
	move.w	.vars+PRO_BOB_BLTSIZE(pc),bltsize(a6)		;BLTSIZE ($58)

	rts

	xdef	PRO_BOB_Draw_Cookie_Vars
.vars
PRO_BOB_Draw_Cookie_Vars:
	dc.w	0			;PRO_BOB_MOD_LINE
	dc.w	0			;PRO_BOB_BLTFWM
	dc.w	0			;PRO_BOB_BLTLWM
	dc.w	0			;PRO_BOB_BLTCMOD
	dc.w	0			;PRO_BOB_BLTBMOD
	dc.w	0			;PRO_BOB_BLTAMOD
	dc.w	0			;PRO_BOB_BLTDMOD
	dc.w	0			;PRO_BOB_BLTSIZE

;	rsreset
;PRO_BOB_MOD_LINE	rs.w 1
;PRO_BOB_BLTFWM		rs.w 1
;PRO_BOB_BLTLWM		rs.w 1
;PRO_BOB_BLTCMOD		rs.w 1
;PRO_BOB_BLTBMOD		rs.w 1
;PRO_BOB_BLTAMOD		rs.w 1
;PRO_BOB_BLTDMOD		rs.w 1
;PRO_BOB_BLTSIZE		rs.w 1


*****************************************************************************
* Plots a dot in 1BPL. Even with jsr/rts can do ~430 dots on A500.
*
* IN:		a0, screen address
*		d0.w/d1.w, x,y
*		d2.w, line modulo
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef PRO_Dot_Plot_1BPL
PRO_Dot_Plot_1BPL:
	move.w	d2,-(sp)

	mulu	d2,d1			;get y line offset
	move.w	d0,d2			;save x
	asr.w	#3,d0			;x to byte offset
	add.w	d0,d1			;x offset to line offset
	add.w	d1,a0			;get final screen byte offset
	not.w	d2			;convert to bset value (bset.b is modulo 8)
	
	bset.b	d2,(a0)

	move.w	(sp)+,d2
	rts


*****************************************************************************
* Plots a dot in color in up to 3BPL. Even with jsr/rts can do ~430 dots on A500.
*
* IN:		a0, screen address
*		d0.w/d1.w, x,y
*		d2.w, color (1-x)
*		d3.w, line modulo
*		d4.w, bitplane modulo
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef PRO_Dot_Plot_3BPL
PRO_Dot_Plot_3BPL:
	move.w	d3,-(sp)

	mulu	d3,d1			;get y line offset
	move.w	d0,d3			;save x
	asr.w	#3,d0			;x to byte offset
	add.w	d0,d1			;x offset to line offset
	add.w	d1,a0			;get final screen byte offset
	not.w	d3			;convert to bset value (bset.b is modulo 8)
	
	btst	#0,d2
	beq.s	.bpl1
	bset.b	d3,(a0)
.bpl1:
	add.w	d4,a0			;next bpl
	btst	#1,d2
	beq.s	.bpl2
	bset.b	d3,(a0)
.bpl2:
	add.w	d4,a0			;next bpl
	btst	#2,d2
	beq.s	.bpl3
	bset.b	d3,(a0)
.bpl3:

	move.w	(sp)+,d3
	rts


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	PRO_PublicBss,bss	;BSS section in Public memory

*****************************************************************************


*****************************************************************************

	endif	;PRO_ENABLE	