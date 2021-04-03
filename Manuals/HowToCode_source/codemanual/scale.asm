;
; NOTE! This code is not CJ approved! It is purely here to accompany
; the article Reading_C
;


;******SET TABS TO 8*********

	include 'exec/types.i'
	include 'exec/exec_lib.i'
	include 'dos/dos_lib.i'
	include 'intuition/intuition.i'
	include 'intuition/intuition_lib.i'
	include 'graphics/graphics_lib.i'
	include 'graphics/scale.i'
	include 'graphics/gfx.i'
	include 'graphics/rastport.i'

;-------------------------------

OPENLIB MACRO
	lea	\1,a1
	move.l	#\2,d0
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,\3
	ENDM

CLOSELIB MACRO
 	 movea.l	(4).w,a6	
	 movea.l	\1,a1
	 jsr	_LVOCloseLibrary(a6)
	 ENDM

;-------------------------------

Start:
	
        movea.l (4).w,a6
	OPENLIB	dosname,37,dosbase
	tst.l	d0
	beq	nodos
	OPENLIB	intname,37,intbase
	tst.l	d0
	beq	closedos
	OPENLIB	gfxname,37,gfxbase
	tst.l	d0
	bne	main
	bra	closeInt
main:	
	movea.l intbase,a6
	sub.l	a0,a0
	lea	WindowTags,A1
	jsr	_LVOOpenWindowTagList(a6)
	move.l	d0,WindowHD

	movea.l	gfxbase,a6
	lea     MyBitMap,a0
	moveq	#3,d0
	move.l	#400,d1
	move.l	#200,d2
	jsr	_LVOInitBitMap(a6)
	lea	MyBitMap,a0
	adda.l	#bm_Planes,a0
	move.l	#dat,(a0)+
	move.l	#dat+10000,(a0)+
	move.l	#dat+20000,(a0)+
	
	movea.l	WindowHD,a2
	movea.l	wd_RPort(a2),a1
	moveq	#0,d2
	moveq	#0,d3
	move.b	wd_BorderLeft(a2),d2
	move.b	wd_BorderTop(a2),d3
	lea     bsa,a0
	move.w	d2,bsa_DestX(a0)
	move.w	d3,bsa_DestY(a0)

	
	movea.l	wd_RPort(a2),a2
	move.l	rp_BitMap(a2),bsa_DestBitMap(a0)

	move.l	#4,d7
	bra	.pt
.loop:
	jsr	_LVOBitMapScale(a6)
.pt	lea 	bsa,a0
	addi.w	#47,bsa_XDestFactor(a0)
	addi.w   #9,bsa_YDestFactor(a0)
	dbf	d7,.loop


	move.l	#12,d7
	bra   .pt2
.loop2
	jsr	_LVOBitMapScale(a6)
.pt2:	lea 	bsa,a0
	subi.w	#47,bsa_XDestFactor(a0)
	subi.w   #15,bsa_YDestFactor(a0)
	dbf	d7,.loop2

	lea (bsa),a0
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#100,bsa_XSrcFactor(a0)
	move.w	#100,bsa_YSrcFactor(a0)
	move.w	#100,bsa_SrcWidth(a0)
	move.w	#100,bsa_SrcHeight(a0)

	jsr	_LVOBitMapScale(a6)

	move.l	#50,d1		;OUR DELAY ROUTINE
	bsr	del

	lea 	bsa,a0
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#40,bsa_XSrcFactor(a0)
	move.w	#40,bsa_YSrcFactor(a0)
	move.w	#40,bsa_SrcWidth(a0)
	move.w	#40,bsa_SrcHeight(a0)
	move.w	#100,bsa_SrcX(a0)
	move.w	#100,bsa_SrcY(a0)

	jsr	_LVOBitMapScale(a6)
	move.l	#50,d1
	bsr	del

	lea 	bsa,a0
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#90,bsa_XSrcFactor(a0)
	move.w	#90,bsa_YSrcFactor(a0)
	move.w	#90,bsa_SrcWidth(a0)
	move.w	#90,bsa_SrcHeight(a0)
	move.w	#230,bsa_SrcX(a0)
	move.w	#50,bsa_SrcY(a0)

	jsr	_LVOBitMapScale(a6)
	move.l	#50,d1
	bsr	del

	lea 	bsa,a0
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#200,bsa_XSrcFactor(a0)
	move.w	#200,bsa_YSrcFactor(a0)
	move.w	#200,bsa_SrcWidth(a0)
	move.w	#200,bsa_SrcHeight(a0)
	move.w	#2000,bsa_SrcX(a0)
	move.w	#0,bsa_SrcY(a0)

	jsr	_LVOBitMapScale(a6)
	move.l	#50,d1
	bsr	del

	lea 	bsa,a0
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#12,bsa_XSrcFactor(a0)
	move.w	#12,bsa_YSrcFactor(a0)
	move.w	#12,bsa_SrcWidth(a0)
	move.w	#12,bsa_SrcHeight(a0)
	move.w	#350,bsa_SrcX(a0)
	move.w	#180,bsa_SrcY(a0)

	jsr	_LVOBitMapScale(a6)
	move.l	#50,d1
	bsr	del


	lea bsa,a0
	move.w	#0,bsa_SrcX(a0)
	move.w	#0,bsa_SrcY(a0)
	move.w	#600,bsa_XDestFactor(a0)
	move.w	#250,bsa_YDestFactor(a0)
	move.w	#400,bsa_XSrcFactor(a0)
	move.w	#200,bsa_YSrcFactor(a0)
	move.w	#400,bsa_SrcWidth(a0)
	move.w	#200,bsa_SrcHeight(a0)

	jsr	_LVOBitMapScale(a6)

	move.l	#150,d1
	bsr	del

	movea.l	intbase,a6
	movea.l	WindowHD,a0
	jsr	_LVOCloseWindow(a6)

closegfx:	
	movea.l	(4).w,a6
	movea.l	gfxbase,a1	
	jsr	_LVOCloseLibrary(a6)
closeInt:	
	movea.l	(4).w,a6
	movea.l	intbase,a1
	jsr	_LVOCloseLibrary(a6)
closedos:	
	movea.l	(4).w,a6
	movea.l	dosbase,a1
	jsr	_LVOCloseLibrary(a6)

nodos:	rts
del:
	movem.l d0/a0/a6,-(sp)
	movea.l	dosbase,a6
	jsr	_LVODelay(a6)
	movem.l (Sp)+,d0/a0/a6
	rts

;--------------------------------------------------

intname:
		dc.b	'intuition.library',0
gfxname:	
		dc.b	'graphics.library',0
dosname:	
		dc.b	'dos.library',0
		even
intbase: 	dc.l	0
WindowHD: 	dc.l	0
dosbase:	dc.l 	0
gfxbase: 	dc.l	0
WindowTags:	dc.l	WA_Left,0
		dc.l    WA_Top,0
                dc.l    WA_InnerWidth,600
                dc.l    WA_InnerHeight,250
		dc.l	WA_Flags
		dc.l    0
		dc.l	WA_Title
		dc.l	titletext
		dc.l	0               ;TAG_DONE
titletext:
  		dc.b 'Scaling some bitmaps Dude! Do ME on an 8 color WB ',0
		even
MyBitMap:
		ds.b  bm_SIZEOF
bsa:
	;		STRUCTURE	;BitScaleArgs,0
	dc.w 0		;UWORD	bsa_SrcX		; source origin
	dc.w 0		;UWORD	bsa_SrcY
	dc.w 400	;UWORD	bsa_SrcWidth	; source size
	dc.w 200	;UWORD	bsa_SrcHeight
	dc.w 400	;UWORD	bsa_XSrcFactor	; scale factor denominators
	dc.w 200	;UWORD	bsa_YSrcFactor
	dc.w 0		;UWORD	bsa_DestX	; destination origin
	dc.w 0		;UWORD	bsa_DestY
	dc.w 0		;UWORD	bsa_DestWidth	; destination size result
	dc.w 0		;UWORD	bsa_DestHeight
	dc.w 400	;UWORD	bsa_XDestFactor	; scale factor numerators
	dc.w 200	;UWORD	bsa_YDestFactor
	dc.l MyBitMap	;APTR	bsa_SrcBitMap	; source BitMap
WDBM: 	dc.l 0		;APTR	bsa_DestBitMap	; destination BitMap
	dc.l 0		;ULONG	bsa_Flags		; reserved.  Must be zero!
	dc.w 0		;UWORD	bsa_XDDA		; reserved
	dc.w 0		;UWORD	bsa_YDDA
	dc.l 0		;LONG	bsa_Reserved1
	dc.l 0		;LONG	bsa_Reserved2
			;LABEL	bsa_SIZEOF
	

	section nn,data_c

dat:	incbin 'Bmap'
