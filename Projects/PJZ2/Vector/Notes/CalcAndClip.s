*****************************************************************************
* For the entire object generate the clipped list of lines to draw along
* with their face color. Stores in VEC_Draw_Line_List
* points may be negative so can't use bmi for $8000
*
* IN:		
* OUT:		
* TRASHED:	d0-d7/a0-a3
*****************************************************************************

VEC_Object_Calc_And_Clip_Line_List:
	lea	Face_Visible_Buf,a1
	lea	VEC_RotXYZpts+2,a2	;skip numpts
	lea	VEC_Draw_Line_List,a3

	move.w	(a1)+,d7		;number of visible faces
	beq	.endclip		;no faces
	subq.w	#1,d7			;-1 for dbf
.clipfaceloop:
	swap	d7			;reuse d7 as num faces/num lines
	move.l	(a1)+,a0		;a0=adr of face data
	move.w	(a0),d7			;num lines (-1 for dbf)
	lea	VEC_FACE_VERTICES(a0),a0	;Skip to vertices

.cliplineloop:
	move.w	(a0)+,d0		;index1
	move.w	(a0),d1			;index2
	movem.w	(a2,d1.w),d2-d3		;x2.w,y2.w
	movem.w	(a2,d0.w),d0-d1		;x1.w,y1.w


	;We rearrange so that y2>y1 for ease of clipping. Also line draw likes it
	;like that.
	;Also for filled vectors we don't draw any lines where y1=y2
	;so we can completely clip those right away.
	cmp	d1,d3
	bgt.s	.cliptop		;y2>y1, d3>d1
	beq	.clip_entire_line	;clip totally when y1=y2
	exg	d1,d3			;swap x1,y1 with x2,y2
	exg	d0,d2

; --- CLIP TOP ---
.cliptop:
	moveq	#VEC_CLIPMINY,d4
	cmp.w	d4,d1		
	bgt.s	.clipbottom		;y1>=miny, don't clip
	cmp.w	d4,d3
	bgt.s	.cliptop_y1		;y1<miny && y2>miny, clip	
	bra	.clip_entire_line	;clip it all

.cliptop_y1:
	sub.w	d1,d4			;miny-y1
	move.w	d2,d5
	sub.w	d0,d5			;x2-x1		
	move.w	d3,d6
	sub.w	d1,d6			;y2-y1
	muls	d5,d4			;(x2-x1)*(miny-y1)
	divs	d6,d4			;/(y2-y1)
	add.w	d4,d0			;add to d0
	moveq	#VEC_CLIPMINY,d1	;set y1 to miny	

; --- CLIP BOTTOM ---
.clipbottom:
	move.w	#VEC_CLIPMAXY,d4
	cmp.w	d3,d4
	bgt.s	.clipright
	cmp.w	d1,d4
	bgt.s	.clipbottom_y2			
	bra	.clip_entire_line	;clip it all

.clipbottom_y2:
	sub.w	d3,d4			;maxy-y2
	move.w	d2,d5
	sub.w	d0,d5			;x2-x1
	move.w	d3,d6
	sub.w	d1,d6			;y2-y1
	muls	d5,d4			;(x2-x1)*(maxy-y2)
	divs	d6,d4			;/(y2-y1)
	add.w	d4,d2			;add 
	move.w	#VEC_CLIPMAXY,d3	;set y2 to maxy

; --- CLIP RIGHT ---
.clipright:
; X1<X2 
	move.w	#VEC_CLIPMAXX,d4		;d4=Maxx
	cmp	d0,d2			;If X2<X1
	beq.s	.CheckRStr		;Stop Division by 0
	blt.s	.XCSwap			;Then do reverse Calc
	cmp	d2,d4			;If x2<Maxx
	bgt	.clipleft		;Don't Clip
	cmp	d0,d4			;if x1>Maxx
	ble.s	.ClipRightWhole		;Clipwholeline
	sub	d2,d4			;(Maxx-x2)
	move	d2,d5			;Copy X2
	sub	d0,d5			;d5 = delta x
	move	d3,d6			;Copy y2
	sub	d1,d6			;d6 = delta y
	muls	d6,d4			;deltay*maxx-x2
	divs	d5,d4			;and divide by delta x
	move	d3,d5			;copy y2
	add	d4,d5			;add d4 to y2
	
	movem.w	d0-d1/d5,-(sp)		;Drawing two lines, save
	move	d5,d1
	cmp	d1,d3
	beq.s	.skip1
	move.w	#VEC_CLIPMAXX,d2
	move	d2,d0

	movem.w	d0-d3,(a3)		;NEW LINE
	addq.l	#4*2,a3			
.skip1	
	Movem.w	(sp)+,d0-d1/d3		;Note d5 restored into d3 intentionally

	move.w	#VEC_CLIPMAXX,d2
	Bra.b	.clipleft
.CheckRStr
	Cmp	d0,d4			;if x1>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Bra.s	.clipleft
.XCSwap
; X2<X1 
	Cmp	d0,d4			;if x1<d4
	Bgt.s	.clipleft		;don't clip
	Cmp	d2,d4			;if x2>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Sub	d0,d4			;(Maxx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y1
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Move	d1,d5			;copy y2
	Add	d4,d5			;add d4 to y1

	Movem	d2-d3,-(sp)		;Have to draw two lines
	Move	d5,d3
	Cmp	d1,d3
	Beq.s	.skip2
	move.w	#VEC_CLIPMAXX,d0
	move	d0,d2

	movem.w	d0-d3,(a3)		;NEW LINE
	addq.l	#4*2,a3				
.skip2	
	movem.w	(sp)+,d2-d3

	move.w	d5,d1
	move.w	#VEC_CLIPMAXX,d0
	bra.s	.clipleft
.ClipRightWhole	
	move.w	#VEC_CLIPMAXX,d2
	move	d2,d0
	bra	.clipstore

; --- CLIP LEFT ---
.clipleft:
; X1>X2 Left Boundary Clip
	move.w	#VEC_CLIPMINX,d4		;d4=Minx
	Cmp	d0,d2			;If X2<X1
	Beq.b	.CheckLStr		;Stop Division by 0
	Bgt.b	.XmCSwap		;Then do reverse Calc
	Cmp	d2,d4			;If x2>minx
	Blt.b	.clipstore		;Don't Clip
	Cmp	d0,d4			;if x1<minx
	;Bgt.b	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line	;Clipwholeline
	Sub	d2,d4			;(Minx-x2)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d3			;add d4 to y1
	move.w	#VEC_CLIPMINX,d2		;New x2 = Minx
	Bra.b	.clipstore
.CheckLStr
	Cmp	d0,d4			;if x1>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line	;Clipwholeline
	Bra.s	.clipstore
;.ClipWholeLeft
	; Not implmented on left for speed
;	bra.s	.NoDrawLine
.XmCSwap
; X2>X1 Left Boundary Clip
	Cmp	d0,d4			;if x1<d4
	Blt.s	.clipstore		;don't clip
	Cmp	d2,d4			;if x2>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line		;Clipwholeline
	Sub	d0,d4			;(Minx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*minx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d1			;add d4 to y1
	move.w	#VEC_CLIPMINX,d0		;New x1 = Minx

; --- CLIP STORE AND LOOP ---
.clipstore:
	movem.w	d0-d3,(a3)		;store new line 
	addq.l	#4*2,a3			

.clip_entire_line:
	dbf	d7,.cliplineloop	;next line

.clipnextface:
	move.w	#$8000,(a3)+		;end of face
	swap	d7			;num faces
	dbf	d7,.clipfaceloop

.endclip:

	rts


*****************************************************************************
* For the entire object draw the lines listed in VEC_Draw_Line_List
* At this point there should be no negative points so can check for $8000
* with bmi.s etc
* IN:		
* OUT:		
* TRASHED:	d0-d6/a0-a4
*****************************************************************************

VEC_Object_Draw_Line_List_Vars:
	dc.l	-1			;for BLTAFWM 
	dc.l	VEC_SCR_BYTEWIDTH*VEC_SCR_NUMPLANES	;for BLTCMOD
	dc.l	-$8000			;for BLTBDAT
	dc.l	VEC_Mult_SCR_Height_ByteWidth_NumPlanes	;a1
	dc.l	VEC_Draw_Line_List			;a2
	dc.l	Face_Visible_Buf			;a3, skip num faces

VEC_Object_Draw_Line_List:
	movem.l	VEC_Object_Draw_Line_List_Vars(pc),d0/d1/d2/a1/a2/a3
	move.l	VEC_Work_Ptr(pc),a4	;adr of screen

	move.w	(a3)+,d7		;num visible faces
	beq.s	.exit
	subq.w	#1,d7			;-1 for dbf

	;Setup line draw blit registers that don't change
	BLIT_NASTY_ON_A6
	WAITBLIT_A6
	BLIT_NASTY_OFF_A6
	move.l	d0,BLTAFWM(a6)		;mask
	move.w	d1,BLTCMOD(a6)		;modulo interleaved
	move.l	d2,BLTBDAT(a6)
	; --------

.drawfaceloop:
	move.l	(a3)+,a0		;a0=face data for getting color
	move.w	VEC_FACE_FLAG_BACKFACE(a0),d6	;VISIBLE_FACE_BACKFACE flag (0 = normal, 1 = backface)
	add.w	d6,d6			;offset to VEC_FACE_PAPER or VEC_FACE_PAPER_BACKFACE
	move.b	VEC_FACE_PAPER(a0,d6.w),d6	;get paper of front or back face

.drawlineloop:
	move.w	(a2)+,d0		;x1,y1,x2,y2 or $8000,xxx
	bmi.s	.drawnextface		;$8000?

	movem.w	(a2)+,d1-d3		;y1,x2,y2

	move.l	a4,a0			;screen adr
	move.w	d6,d4			;color
	bsr.s	VEC_LineDraw3_nBpl_DrawFilled	; trashes d0-d5/a0
	bra.s	.drawlineloop

.drawnextface:
	dbf	d7,.drawfaceloop

.fill:	

.exit:
	rts


*****************************************************************************
* For a single FACE generate the clipped list of lines to draw.
*
* IN:		a0, face adr
* OUT:		
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

VEC_Face_Calc_And_Clip_Line_List:
	lea	VEC_RotXYZpts+2,a1	;skip numpts
	lea	VEC_Draw_Line_List,a2

	move.w	(a0),d7			;num lines (-1 for dbf)
	lea	VEC_FACE_VERTICES(a0),a0	;Skip to vertices

.cliplineloop:
	move.w	(a0)+,d0		;index1
	move.w	(a0),d1			;index2
	movem.w	(a1,d1.w),d2-d3		;x2.w,y2.w
	movem.w	(a1,d0.w),d0-d1		;x1.w,y1.w

	;We rearrange so that y2>y1 for ease of clipping. Also line draw likes it
	;like that.
	;Also for filled vectors we don't draw any lines where y1=y2
	;so we can completely clip those right away.
	cmp	d1,d3
	bgt.s	.cliptop		;y2>y1, d3>d1
	beq	.clip_entire_line	;clip totally when y1=y2
	exg	d1,d3			;swap x1,y1 with x2,y2
	exg	d0,d2

; --- CLIP TOP ---
.cliptop:
	moveq	#VEC_CLIPMINY,d4
	cmp.w	d4,d1		
	bgt.s	.clipbottom		;y1>=miny, don't clip
	cmp.w	d4,d3
	bgt.s	.cliptop_y1		;y1<miny && y2>miny, clip	
	bra	.clip_entire_line	;clip it all

.cliptop_y1:
	sub.w	d1,d4			;miny-y1
	move.w	d2,d5
	sub.w	d0,d5			;x2-x1		
	move.w	d3,d6
	sub.w	d1,d6			;y2-y1
	muls	d5,d4			;(x2-x1)*(miny-y1)
	divs	d6,d4			;/(y2-y1)
	add.w	d4,d0			;add to d0
	moveq	#VEC_CLIPMINY,d1	;set y1 to miny	

; --- CLIP BOTTOM ---
.clipbottom:
	move.w	#VEC_CLIPMAXY,d4
	cmp.w	d3,d4
	bgt.s	.clipright
	cmp.w	d1,d4
	bgt.s	.clipbottom_y2			
	bra	.clip_entire_line	;clip it all

.clipbottom_y2:
	sub.w	d3,d4			;maxy-y2
	move.w	d2,d5
	sub.w	d0,d5			;x2-x1
	move.w	d3,d6
	sub.w	d1,d6			;y2-y1
	muls	d5,d4			;(x2-x1)*(maxy-y2)
	divs	d6,d4			;/(y2-y1)
	add.w	d4,d2			;add 
	move.w	#VEC_CLIPMAXY,d3	;set y2 to maxy

; --- CLIP RIGHT ---
.clipright:
; X1<X2 
	move.w	#VEC_CLIPMAXX,d4		;d4=Maxx
	cmp	d0,d2			;If X2<X1
	beq.s	.CheckRStr		;Stop Division by 0
	blt.s	.XCSwap			;Then do reverse Calc
	cmp	d2,d4			;If x2<Maxx
	bgt	.clipleft		;Don't Clip
	cmp	d0,d4			;if x1>Maxx
	ble.s	.ClipRightWhole		;Clipwholeline
	sub	d2,d4			;(Maxx-x2)
	move	d2,d5			;Copy X2
	sub	d0,d5			;d5 = delta x
	move	d3,d6			;Copy y2
	sub	d1,d6			;d6 = delta y
	muls	d6,d4			;deltay*maxx-x2
	divs	d5,d4			;and divide by delta x
	move	d3,d5			;copy y2
	add	d4,d5			;add d4 to y2
	
	movem.w	d0-d1/d5,-(sp)		;Drawing two lines, save
	move	d5,d1
	cmp	d1,d3
	beq.s	.skip1
	move.w	#VEC_CLIPMAXX,d2
	move	d2,d0

	movem.w	d0-d3,(a2)		;NEW LINE
	addq.l	#4*2,a2			
.skip1	
	Movem.w	(sp)+,d0-d1/d3		;Note d5 restored into d3 intentionally

	move.w	#VEC_CLIPMAXX,d2
	Bra.b	.clipleft
.CheckRStr
	Cmp	d0,d4			;if x1>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Bra.s	.clipleft
.XCSwap
; X2<X1 
	Cmp	d0,d4			;if x1<d4
	Bgt.s	.clipleft		;don't clip
	Cmp	d2,d4			;if x2>Maxx
	Blt.s	.ClipRightWhole		;Clipwholeline
	Sub	d0,d4			;(Maxx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y1
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Move	d1,d5			;copy y2
	Add	d4,d5			;add d4 to y1

	Movem	d2-d3,-(sp)		;Have to draw two lines
	Move	d5,d3
	Cmp	d1,d3
	Beq.s	.skip2
	move.w	#VEC_CLIPMAXX,d0
	move	d0,d2

	movem.w	d0-d3,(a2)		;NEW LINE
	addq.l	#4*2,a2				
.skip2	
	movem.w	(sp)+,d2-d3

	move.w	d5,d1
	move.w	#VEC_CLIPMAXX,d0
	bra.s	.clipleft
.ClipRightWhole	
	move.w	#VEC_CLIPMAXX,d2
	move	d2,d0
	bra	.clipstore

; --- CLIP LEFT ---
.clipleft:
; X1>X2 Left Boundary Clip
	move.w	#VEC_CLIPMINX,d4		;d4=Minx
	Cmp	d0,d2			;If X2<X1
	Beq.b	.CheckLStr		;Stop Division by 0
	Bgt.b	.XmCSwap		;Then do reverse Calc
	Cmp	d2,d4			;If x2>minx
	Blt.b	.clipstore		;Don't Clip
	Cmp	d0,d4			;if x1<minx
	;Bgt.b	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line	;Clipwholeline
	Sub	d2,d4			;(Minx-x2)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*maxx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d3			;add d4 to y1
	move.w	#VEC_CLIPMINX,d2		;New x2 = Minx
	Bra.b	.clipstore
.CheckLStr
	Cmp	d0,d4			;if x1>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line	;Clipwholeline
	Bra.s	.clipstore
;.ClipWholeLeft
	; Not implmented on left for speed
;	bra.s	.NoDrawLine
.XmCSwap
; X2>X1 Left Boundary Clip
	Cmp	d0,d4			;if x1<d4
	Blt.s	.clipstore		;don't clip
	Cmp	d2,d4			;if x2>Minx
	;Bgt.s	.ClipWholeLeft		;Clipwholeline
	Bgt	.clip_entire_line		;Clipwholeline
	Sub	d0,d4			;(Minx-x1)
	Move	d2,d5			;Copy X2
	Sub	d0,d5			;d5 = delta x
	Move	d3,d6			;Copy y2
	Sub	d1,d6			;d6 = delta y
	Muls	d6,d4			;deltay*minx-x1
	Divs	d5,d4			;and divide by delta x
	Add	d4,d1			;add d4 to y1
	move.w	#VEC_CLIPMINX,d0		;New x1 = Minx

; --- CLIP STORE AND LOOP ---
.clipstore:
	movem.w	d0-d3,(a2)		;store new line 
	addq.l	#4*2,a2			

.clip_entire_line:
	dbf	d7,.cliplineloop	;next line

.clipnextface:
	move.w	#$8000,(a2)+		;end of face

.endclip:

	rts





VEC_Object_Complex_Draw_Line_List:
	lea	Face_Visible_Buf,a4

	move.w	(a4)+,d7		;num visible faces
	beq.s	.exit
	subq.w	#1,d7			;-1 for dbf

.drawfaceloop:
	;calc clipped lines for this face
	move.w	d7,-(sp)
	move.l	(a4),a0			;get face adr
	bsr	VEC_Face_Calc_And_Clip_Line_List
	move.w	(sp)+,d7

	;Entire face lines may have been clipped, so check 
	lea	VEC_Draw_Line_List,a2
	move.w	(a2)+,d0		;x1,y1,x2,y2 or $8000
	bpl.s	.drawlineloopskipinit	;already have x1, skip init
	addq.l	#4,a4			;skip face
	bra.s	.drawnextface

.drawlineloop:
	move.w	(a2)+,d0		;x1,y1,x2,y2 or $8000,xxx
	bmi.s	.fillface

.drawlineloopskipinit:
	movem.w	(a2)+,d1-d3		;y1,x2,y2

	lea	VEC_Scr_Back_Scratch,a0		;screen adr
	lea	VEC_Mult_SCR_Height_ByteWidth,a1
	bsr	VEC_LineDraw3_1Bpl_DrawFilled	; trashes d0-d4/a0
	bra.s	.drawlineloop
.fillface:
	; Fill and copy the face
	move.l	(a4)+,a0		;a0=adr of face data for fill face function
	movem.l	a1-a4,-(sp)
	bsr	VEC_Fill_Face_And_Copy	;in a0/a1, trashed d0-d6/a0-a5
	movem.l	(sp)+,a1-a4

.drawnextface:
	dbf	d7,.drawfaceloop
.exit	
	rts


; Draw line list is color.w followed by vertex. A
; color.w (paper.b, ink.b)
; x1,y2
; x2,y2
; $8000 (next face)
; x1,y2
; x2,y2
; $8000 (next face)
; $8000 (end)
;
;Assuming MAX_FACES of ~3 verts
; Clipping could add a left/right/top/bottom vert in worst case = 7 verts
; MAXFACES * (color.w, (7*x, 7*y)) =
; MAXFACES * 15.w
VEC_DRAW_LINE_LIST_SIZEOF = VEC_MAX_FACES*15*2	;size in bytes
VEC_Draw_Line_List:
	ds.b	VEC_DRAW_LINE_LIST_SIZEOF

