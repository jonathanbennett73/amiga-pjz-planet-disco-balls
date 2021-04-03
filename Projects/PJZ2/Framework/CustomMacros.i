	IFND _CUSTOMMACROS_I
_CUSTOMMACROS_I SET 1

*********************************************
* Custom Macro File (c)1989-2019 Antiriad / *
* Jonathan Bennett <jon@autoitscript.com    *
*********************************************

;Macros. Coded to work with customextra.i and CBM includes.

;RasterTest colours defaults
	IFND RasterTest
RasterTest set 0	
	ENDC

	IFND RASTERTEST_COL_BLITWAIT
RASTERTEST_COL_BLITWAIT set $600
	ENDC

	IFND RASTERTEST_COL_ON
RASTERTEST_COL_ON set $111
	ENDC

	IFND RASTERTEST_COL_OFF
RASTERTEST_COL_OFF set $000
	ENDC

;to stop here in WinUAE, enter "w 4 4 4 w" in the debugger window (shift+f12) 
;to place the breakpoint, and enter "w 4" to remove it
WinUAEBreakpoint	MACRO
			move.l	4.w,4.w
			ENDM

TIMERON		MACRO
		IFNE	RasterTest
		move.w	#RASTERTEST_COL_ON,color00+_custom
		ENDC
		ENDM

TIMEROFF	MACRO
		IFNE	RasterTest
		move.w	#0,color00+_custom
		ENDC
		ENDM

TIMERON2	MACRO
		IFNE	RasterTest
		move.w	#\1,color00+_custom
		ENDC
		ENDM


SAVEREGS	MACRO
		movem.l	a0-a6/d0-d7,-(sp)
		ENDM
		
LOADREGS	MACRO
		movem.l	(sp)+,a0-a6/d0-d7
		ENDM

WAITBLIT_A1000_A6	MACRO
		tst.w	dmaconr(a6)		;for compatibility on A1000 with fastmem
.bw\@		btst.b	#6,dmaconr(a6)		;=bit 14 of dmaconr!
		bne.s	.bw\@
		ENDM

WAITBLIT_A1000	MACRO
		tst.w	dmaconr+_custom		;for compatibility on A1000 with fastmem
.bw\@		btst.b	#6,dmaconr+_custom	;=bit 14 of dmaconr!
		bne.s	.bw\@
		ENDM

BLIT_NASTY_ON_A6	MACRO
		move.w	#$8400,dmacon(a6)	;Blitter nasty on
		ENDM

BLIT_NASTY_OFF_A6	MACRO
		move.w	#$0400,dmacon(a6)	;Blitter nasty off
		ENDM

BLIT_NASTY_ON	MACRO
		move.w	#$8400,dmacon+_custom	;Blitter nasty on
		ENDM

BLIT_NASTY_OFF	MACRO
		move.w	#$0400,dmacon+_custom	;Blitter nasty off
		ENDM


WAITBLIT_A6	MACRO
		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_BLITWAIT,color00(a6)
		ENDC

.bw\@		btst.b	#6,dmaconr(a6)		;=bit 14 of dmaconr!
		bne.s	.bw\@

		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_ON,color00(a6)
		ENDC
		ENDM

WAITBLIT_NASTY_A6	MACRO
		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_BLITWAIT,color00(a6)
		ENDC

		move.w	#$8400,dmacon(a6)	;Blitter nasty on
.bw\@		btst.b	#6,dmaconr(a6)		;=bit 14 of dmaconr!
		bne.s	.bw\@
		move.w	#$0400,dmacon(a6)	;Blitter nasty off

		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_ON,color00(a6)
		ENDC
		ENDM

WAITBLIT_NASTY	MACRO
		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_BLITWAIT,color00+_custom
		ENDC

		move.w	#$8400,dmacon+_custom	;Blitter nasty on
.bw\@		btst.b	#6,dmaconr+_custom	;=bit 14 of dmaconr!
		bne.s	.bw\@
		move.w	#$0400,dmacon+_custom	;Blitter nasty off

		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_ON,color00+_custom
		ENDC
		ENDM

WAITBLIT_NASTY_EARLYEXIT_A6	MACRO
		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_BLITWAIT,color00(a6)
		ENDC

		btst.b	#6,dmaconr(a6)		;=bit 14 of dmaconr!
		beq.s	.earlyexit\@
		move.w	#$8400,dmacon(a6)	;Blitter nasty on
.bw\@		btst.b	#6,dmaconr(a6)		;=bit 14 of dmaconr!
		bne.s	.bw\@
		move.w	#$0400,dmacon(a6)	;Blitter nasty off
.earlyexit\@:
		IFEQ RasterTest-2
		move.w	#RASTERTEST_COL_ON,color00(a6)
		ENDC
		ENDM

WAITBLIT	MACRO
.bw\@		btst.b	#6,dmaconr+_custom	;=bit 14 of dmaconr!
		bne.s	.bw\@
		ENDM

WAITRASTER	MACRO
.lo\@:		move.l	vposr+_custom,d0	;Wait for scanline or greater. trashes d0
		lsr.l	#1,d0
		lsr.w	#7,d0
		cmp.w	\1,d0
		blt.s	.lo\@			;wait until it matches (eq)

WAITRASTER_A6	MACRO
.lo\@:		move.l	vposr(a6),d0		;Wait for scanline or greater. trashes d0
		lsr.l	#1,d0
		lsr.w	#7,d0
		cmp.w	\1,d0
		blt.s	.lo\@			;wait until it matches (eq)

WAITRASTER_EXACT	MACRO				;trashes d0
.wr\@		move.l	vposr+_custom,d0
		andi.l	#$1ff00,d0
		cmpi.l	#(\1)<<8,d0
		bne.s	.wr\@			;wait until it matches (eq)
		ENDM

WAITRASTER_EXACT_A6	MACRO			;trashes d0
.wr\@		move.l	vposr(a6),d0
		andi.l	#$1ff00,d0
		cmpi.l	#(\1)<<8,d0
		bne.s	.wr\@			;wait until it matches (eq)
		ENDM

WAITTOF_A6	MACRO
.vsync\@:	
	btst	#0,vposr+1(a6)
	beq.b	.vsync\@			;wait while in 0-255 range if bit is 0
.vsync2\@: 
	btst	#0,vposr+1(a6)			;wait while in 256+ range
	bne.b	.vsync2\@
		ENDM

AllocMem	MACRO				;SIZE, TYPE, WHERE
		move.l	(_ExecBase).w,a6
		move.l	\1,d0
		move.l	\2,d1			;TYPE
		jsr	_LVOAllocMem(a6)
		move.l	d0,\3
		ENDM

AllocAbs	MACRO				;SIZE, ADR, WHERE
		move.l	(_ExecBase).w,a6
		move.l	\1,d0
		move.l	\2,a1
		jsr	_LVOAllocAbs(a6)
		move.l	d0,\3
		ENDM

FreeMem		MACRO				;SIZE,WHERE
		move.l	(_ExecBase).w,a6
		move.l	\1,d0
		move.l	\2,a1
		jsr	_LVOFreeMem(A6)
		ENDM

LEFTMOUSEWAIT	MACRO
.wait\@		btst.b	#6,$bfe001
		bne.s	.wait\@
		ENDM

RIGHTMOUSEWAIT	MACRO
.wait\@		btst.b	#10-8,$dff016
		bne.s	.wait\@
		ENDM

NO_BLITMASK_A6	MACRO
		move.l	#-1,bltafwm(a6)
		ENDM

ENABLE_COPPER_DANGER_A6	MACRO
		move.w	#2,copcon(a6)
		ENDM

ENABLE_INT_VERTB_A6	MACRO
		move.w	#$c020,intena(a6)
		ENDM

DISABLE_INT_VERTB_A6	MACRO
		move.w	#$0020,intena(a6)
		ENDM

ENABLE_INT_VERTB	MACRO
		move.w	#$c020,intena+_custom
		ENDM

DISABLE_INT_VERTB	MACRO
		move.w	#$0020,intena+_custom
		ENDM

RESET_INT_VERTB	MACRO
		move.w	#$0020,intreq+_custom
		move.w	#$0020,intreq+_custom	;twice for A4000 compat
		ENDM

RESET_INT_VERTB_A6	MACRO
		move.w	#$0020,intreq(a6)
		move.w	#$0020,intreq(a6)	;twice for A4000 compat
		ENDM
		

;(Kalms explained the method itself in the other thread.) Now, to use that you'd simply 
;enter the macro like any other instruction, specifying a source register, a destination
; register and an available scratch register like so:
; ABS_W d1,d2,d6 ; d2.w <- abs(d1.w-d2.w), trashes d6.w
ABS_W	MACRO
	sub.w \1,\2
	subx.w \3,\3
	eor.w \3,\2
	sub.w \3,\2
	ENDM

*****************************************************************************
* Returns the signed max of two values.
* IN:		\1,\2.w , two values
* OUT:		d1, max value
* TRASHED:	
*****************************************************************************

MAX_W	MACRO
	cmp.w	\1,\2
	ble.s	.less\@
	move.w	\2,\1
.less\@
	ENDM

UMAX_W	MACRO
	cmp.w	\1,\2
	bls.s	.less\@
	move.w	\2,\1
.less\@
	ENDM

; sgn - returns d1=0 if d0=0, d1=1 if d0>0, or d1=-1 if d0<0
;At first glimpse, this makes absolutely no sense. Most glaringly, there are no conditional jumps, 
;while the original code was made of nothing but conditional jumps. Some closer analysis reveals what is actually going on.
;ADD.L D0,D0 doubles D0. This is unimportant, as it will not be referenced again, but it takes 
;advantage of a peculiarity of 2s-complement notation, which is used to store number in registers in 
;binary. Any negative number will be stored as a bit string beginning with 1; thus, when it is doubled, 
;it will overflow, and the carry bit on the processor will be set. SUBX.L D1,D1 clears D1 (by subtracting 
;it from itself), then subtracts the carry bit from it. Since this was set by the previous instruction, 
;D1 is now -1 if the original number was negative, and 0 otherwise. NEGX.L D0 negates D0, which is not important, 
;and sets the carry bit to 1 if and only if D0 was not originally equal to zero. ADDX.L D1,D1 now puts this 
;entire process together by adding D1 to itself, then adding the carry bit. If D0 was originally positive, 
;D1 will be zero and the carry bit will be set. Thus, 0 + 0 + 1 = 1, and D1 will contain 1. If D0 was equal to zero, 
;D1 will be equal to zero and the carry bit will not be set, so 0 + 0 + 0 =0. If D0 was negative, D1 will 
;equal -1 and the carry bit will be set, so -1 + -1 + 1 = -1.
SGN_L	MACRO
	add.l d0,d0
	subx.l d1,d1
	negx.l d0
	addx.l d1,d1
	ENDM

; Aligns a value to a 64KB boundary. You need to allocate MEM+65536 for this to work.
ALIGN_64KB_DX_L	MACRO
	add.l #65536,\1
	and.l #$3ff0000,\1
	ENDM

;T:d0-d1/a0-a1/a6
CACHEFLUSH	MACRO
	move.l	$4.w,a6
	cmp.w	#37,SU_lib_Version(a6)
	blo.b	.noflush\@
	jsr	_LVOCacheClearU(a6)
.noflush\@:
	ENDM

;Copper macros

CWAIT		MACRO
		dc.w	(\1&$ff)*256+(\2&$fe|1)
		dc.w	$fffe
		ENDM

CWAITBLIT	MACRO
		dc.w    $0001,$7ffe
		ENDM
		
COPPEREND	MACRO
		dc.w $ffff,$fffe
		ENDM

CSKIP		MACRO
		dc.b	\1,\2,$ff,$ff	
		ENDM
		
CMOVE		MACRO
		dc.w	\1,\2			
		ENDM

COPPERNOP	MACRO
		dc.w	$1fe,$0
		ENDM


*****************************************************************************
* Interpolates between a and b in different common step sizes
* LERP256_FAST src,dest,steps (shift value of 1-8 for 2-256 steps)
* LERP256_FAST d0,d1,8  (256 steps)
*
* Returns d1 which is the value to add each "step". Note for screen space
* coords (approx 0-256) you need to use scaled inputs of around << 4). Depending
* on the use case you may be able to use less/more precision.
*
* IN:		src,dest (start and end points are dx registers)
*		shift 
* OUT:		d1, delta value to add for each step
* TRASHED:	d1
*****************************************************************************

LERP_FAST_W	MACRO
	sub.w	\1,\2
	asr.w	#\3,\2
	ENDM

LERP_FAST_L	MACRO
	sub.l	\1,\2
	asr.l	#\3,\2
	ENDM


*****************************************************************************
* Interpolates between a and b with a step from 0-256.
* LERP256_SLOW a,b,step,scratch
* LERP256_SLOW d0,d1,d2,d3
*
*Interpolate a,b,step
*((a * step) >> 8) + ((b * (256-step)) >> 8)
*
* This uses 2 multiplies so is sloooow.
*
* IN:		a b, start and end points dx registers
*		step, 0-256 dx register
*		scratch, a dx register to use as scratch space
* OUT:		a/Dx, new value
* TRASHED:	All inputs.
*****************************************************************************

LERP256_SLOW	MACRO		;step=0-256
	;d0=a,d1=b,d2=step,d3=scratch
;	muls	d2,d0	
;	asr.w	#8,d0
;	move.w	#256,d3
;	sub.w	d2,d3
;	muls	d3,d1
;	asr.w	#8,d1
;	add.w	d1,d0
	
	muls	\3,\1	
	asr.w	#8,\1
	move.w	#256,\4
	sub.w	\3,\4
	muls	\4,\2
	asr.w	#8,\2
	add.w	\2,\1	
	ENDM

LERP128_SLOW	MACRO		;step=0-128
	muls	\3,\1	
	asr.w	#7,\1
	move.w	#128,\4
	sub.w	\3,\4
	muls	\4,\2
	asr.w	#7,\2
	add.w	\2,\1	
	ENDM

LERP64_SLOW	MACRO		;step=0-64
	muls	\3,\1	
	asr.w	#6,\1
	moveq	#64,\4
	sub.w	\3,\4
	muls	\4,\2
	asr.w	#6,\2
	add.w	\2,\1	
	ENDM

LERP32_SLOW	MACRO		;step=0-32
	muls	\3,\1	
	asr.w	#5,\1
	moveq	#32,\4
	sub.w	\3,\4
	muls	\4,\2
	asr.w	#5,\2
	add.w	\2,\1	
	ENDM

LERP16_SLOW	MACRO		;step=0-16
	muls	\3,\1	
	asr.w	#4,\1
	moveq	#16,\4
	sub.w	\3,\4
	muls	\4,\2
	asr.w	#4,\2
	add.w	\2,\1	
	ENDM


*****************************************************************************
* Adds two RGB12 colours together.
* Thanks Morbid, https://eab.abime.net/showpost.php?p=1446763&postcount=17
* IN:		d0/d1.w, two colors
* OUT:		d0.w, new color
* TRASHED:	d0-d4
*****************************************************************************

RGB12_ADD	MACRO
	;92 cycles from here

	move.w #$8888,d4	;MSB mask, must match the lsr.l #3 at the end
	
	move.w	d0,d2
	eor.w	d1,d2		;32 half adder sum => a xor b
	and.w	d4,d2		;wherever there is a 1 in d2 we might get an overflow but we only care about the MSB

	move.w	d1,d3
	and.w	d0,d3		;32 half adder carry => a and b
	and.w	d4,d3		;wherever there is a 1 in d3 we know we have an overflow but we only care about the MSB
	
	not.w	d4		;$8888 to $7777
	and.w	d4,d0		;remove MSB
	and.w	d4,d1		;remove MSB
	
	add.w	d1,d0		;add a and b. Since we removed the MSB this can never overflow but we might get a new 1 in bit 3
	
	move.w	d2,d1		;t1 |= t0 & x
	and.w	d0,d1		;if we got a 1 from the eor above (half adder sum) and a 1 from the add above we have an overflow
	or.w	d1,d3		;set bits in d3 for each new overflow

	; saturate on overflow
	move.w	d3,d1
	; shift overflow bit down to LSB
	; shift overflow up one bit
	; this will make the sub below
	; set all bits to one i.e. %10000 - %0001 = %1111
	lsr.w	#3,d1
	add.w	d3,d3
	sub.w	d1,d3

	eor.w	d2,d0		;now we need to adjust the MSB, do an add without carry, the half adder again
	or.w	d3,d0		;and finally insert the saturated bits
	;d0.w is result

	ENDM


*****************************************************************************
* Adds two RGB12 colours together.
*
* IN:		d0/d1, two colors
* OUT:		d0, new color
* TRASHED:	d0-d5
*****************************************************************************

RGB12_ADD_OLD	MACRO
	;160 cycles from here
	;blue
	moveq	#$f,d5
	move.w	d0,d4
	move.w	d1,d3
	and.w	d5,d4
	and.w	d5,d3
	add.w	d3,d4
	cmp.w	d5,d4
	ble.s	.bok\@
	move.w	d5,d4
.bok\@:

	;green
	move.w	#$f0,d5
	move.w	d0,d2
	move.w	d1,d3
	and.w	d5,d2
	and.w	d5,d3
	add.w	d2,d3
	cmp.w	d5,d3
	ble.s	.gok\@
	move.w	d5,d3
.gok\@:
	or.w	d3,d4			;merge with final

	;red
	move.w	#$f00,d5
	and.w	d5,d0
	and.w	d5,d1
	add.w	d1,d0
	cmp.w	d5,d0
	ble.s	.rok\@
	move.w	d5,d0
.rok\@:
	or.w	d4,d0			;merge with final
.exit\@:
	ENDM


*****************************************************************************
* Subtracts RGB12 colors.
*
* IN:		d0/d1, two colors. d1 is subtracted from d0
* OUT:		d0, new color
* TRASHED:	d0-d5
*****************************************************************************

RGB12_SUB	MACRO
	;blue
	moveq	#$f,d5
	move.w	d0,d4
	move.w	d1,d3
	and.w	d5,d4
	and.w	d5,d3
	sub.w	d3,d4
	bpl.s	.bok\@
	moveq	#0,d4
.bok\@:

	;green
	move.w	#$f0,d5
	move.w	d0,d2
	move.w	d1,d3
	and.w	d5,d2
	and.w	d5,d3
	sub.w	d3,d2
	bpl.s	.gok\@
	moveq	#0,d2
.gok\@:
	or.w	d2,d4			;merge with final

	;red
	move.w	#$f00,d5
	and.w	d5,d0
	and.w	d5,d1
	sub.w	d1,d0
	bpl.s	.rok\@
	moveq	#0,d0
.rok\@:
	or.w	d4,d0			;merge with final

	ENDM


*****************************************************************************
* Inverts a color.  $1ff becomes $e00
*
* IN:		d0, color to invert
* OUT:		d0, new color
* TRASHED:	d0-d3
*****************************************************************************

RGB12_INVERT	MACRO
	;blue
	moveq	#$f,d3
	move.w	d0,d1
	and.w	d3,d1
	sub.w	d1,d3

	;green
	move.w	#$f0,d2
	move.w	d0,d1
	and.w	d2,d1
	sub.w	d1,d2
	or.w	d2,d3	

	;red
	move	#$f00,d2
	and.w	d2,d0
	exg	d0,d2
	sub.w	d2,d0
	or.w	d3,d0

	ENDM


*****************************************************************************
* Gets average of two colors.
*
* IN:		d0/d1.w, two colors.
* OUT:		d0.w, new color
* TRASHED:	d0-d3
*****************************************************************************

RGB12_AVERAGE	MACRO
	move.w  d0,d2
	and.w   #$0f0f,d2		; r0b
	eor.w   d2,d0			; 0g0

	move.w  d1,d3
	and.w   #$0f0f,d3		; r0b
	eor.w   d3,d1			; 0g0

	add.w   d1,d0			; 000000000000000ggggggggg00000000
	add.w   d3,d2			; 0000000rrrrrrrrr0000000bbbbbbbbb

	and.w   #$0f0*2,d0
	and.w   #$f0f*2,d2
	or.w    d2,d0
	lsr.w   #1,d0
	ENDM


*****************************************************************************
* Gets average of two colors fast but less accurate.
*
* IN:		d0/d1.w, two colors.
* OUT:		d0.w, new color
* TRASHED:	d0-d1
*****************************************************************************

RGB12_AVERAGE_FAST	MACRO
	and.w   #$eee,d0
	and.w   #$eee,d1
	add.w   d1,d0
	lsr.w   #1,d0
	ENDM


*****************************************************************************
* Converts a RGB 8bit component value to 4 bit.
*
* https://eab.abime.net/showpost.php?p=1461321&postcount=6
*
*      0  1  2  3  4  5  6  7   8  9  A  B  C  D  E  F
* 00   00 00 00 00 00 00 00 00  01 01 01 01 01 01 01 01                   
* 10   01 01 01 01 01 01 01 01  01 02 02 02 02 02 02 02                   
* 20   02 02 02 02 02 02 02 02  02 02 03 03 03 03 03 03                   
* 30   03 03 03 03 03 03 03 03  03 03 03 04 04 04 04 04                   
* 40   04 04 04 04 04 04 04 04  04 04 04 04 05 05 05 05                   
* 50   05 05 05 05 05 05 05 05  05 05 05 05 05 06 06 06                   
* 60   06 06 06 06 06 06 06 06  06 06 06 06 06 06 07 07                   
* 70   07 07 07 07 07 07 07 07  07 07 07 07 07 07 07 08                   
* 80   08 08 08 08 08 08 08 08  08 08 08 08 08 08 08 08                   
* 90   08 09 09 09 09 09 09 09  09 09 09 09 09 09 09 09                   
* A0   09 09 0A 0A 0A 0A 0A 0A  0A 0A 0A 0A 0A 0A 0A 0A                   
* B0   0A 0A 0A 0B 0B 0B 0B 0B  0B 0B 0B 0B 0B 0B 0B 0B                   
* C0   0B 0B 0B 0B 0C 0C 0C 0C  0C 0C 0C 0C 0C 0C 0C 0C                   
* D0   0C 0C 0C 0C 0C 0D 0D 0D  0D 0D 0D 0D 0D 0D 0D 0D                   
* E0   0D 0D 0D 0D 0D 0D 0E 0E  0E 0E 0E 0E 0E 0E 0E 0E                   
* F0   0E 0E 0E 0E 0E 0E 0E 0F  0F 0F 0F 0F 0F 0F 0F 0F
*
* IN:		d0.b, 8 bit component
* OUT:		d0.b, 4 bit
* TRASHED:	d0-d1
*****************************************************************************

RGB_COMP_8TO4	MACRO
	move.b  d0,d1
	lsr.b   #4,d1
	sub.b   d1,d0
	addq.b  #8,d0
	lsr.b   #4,d0
	ENDM


*****************************************************************************
* Gets the 2 control words for a sprite given x,y,height (given in DIW display coords)
* X 0 to 447
* Y 0 to 262
*
* VSTART,VSTOP,HSTART are 9 bit values.
*
* Word1 SPRxPOS
*	Bits 15-8 contain the low 8 bits of VSTART
*	Bits 7-0 contain the high 8 bits of HSTART
*
* Word2 SPRxCTL
*	Bits 15-8	The low eight bits of VSTOP
*	Bit 7		(Used in attachment)
*	Bits 6-3	Unused (make zero)
*	Bit 2		The VSTART high bit
*	Bit 1		The VSTOP high bit
*	Bit 0		The HSTART low bit
*
* IN:		d0-d2, x,y,height  (x,y in DIW/display values)
* OUT:		d1,d2, control words
* TRASHED:	d0-d3
*****************************************************************************

GET_SPRITE_CTRL_WORDS	MACRO		
	;add.w	#(\1),d0
	;add.w	#(\2),d1 

	add.w	d1,d2     		;d2 is vstop
	moveq	#0,d3         

	lsl.w	#8,d1			;vstart low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstart high bit to d3

	lsl.w	#8,d2			;vstop low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstop high bit to d3 

	lsr.w	#1,d0			;shift out hstart low bit
	addx.b	d3,d3     		;left shift and h start low bit to d3

	move.b	d0,d1			;make first control word
	move.b	d3,d2			;second control word
	ENDM

;Same as previous version except that if a sprite would be out of bounds it returns 0,0 ctrl words
;Out of bounds is done for a normal 352x272 overscan screen
;Hardware Hstart ($81 normal, $71 overscan) 0 272
;Hardware Vstart ($2c normal, $24 overscan) - 352
GET_SPRITE_CTRL_WORDS_BOUNDS_CHECK	MACRO		

	cmp.w	#($71+352),d0		;overscan x 352 values
	bhs.s	.nodraw\@
	cmp.w	#($24+272),d1		;overscan y 272 values
	bhs.s	.nodraw\@

	add.w	d1,d2     		;d2 is vstop
	moveq	#0,d3         

	lsl.w	#8,d1			;vstart low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstart high bit to d3

	lsl.w	#8,d2			;vstop low 8 bits to top of word
	addx.b	d3,d3     		;left shift and vstop high bit to d3 

	lsr.w	#1,d0			;shift out hstart low bit
	addx.b	d3,d3     		;left shift and h start low bit to d3

	move.b	d0,d1			;make first control word
	move.b	d3,d2			;second control word
	bra.s	.exit\@

.nodraw\@:
	moveq	#0,d1
	moveq	#0,d2
.exit\@:

	ENDM


		
		
	ENDC	;CUSTOMMACROS_I