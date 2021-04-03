*****************************************************************************

; Name			: IntroFramework.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Shared framework.
; Date last edited	: 04/02/2020
				
*****************************************************************************

	include "hardware/custom.i"
	include "hardware/cia.i"
	include "hardware/dmabits.i"
	include "hardware/intbits.i"

	include "exec/execbase.i"
	include "exec/exec_lib.i"
	include "graphics/gfxbase.i"
	include "graphics/graphics_lib.i"
	include "graphics/text.i"

	include "../IntroConfig.i"
	include "IntroFramework.i"
	include	"CustomExtra.i"
	include "CustomMacros.i"

*****************************************************************************

	ifeq FW_MUSIC_TYPE-1		;p61
		xref	P61_End
		xref	P61_Init
		xref	P61_VBR
		xref	P61_Play
		xref	P61_E8		;word
		xref	P61_visuctr0	;words
		xref	P61_visuctr1	;words
		xref	P61_visuctr2	;words
		xref	P61_visuctr3	;words
		xref	P61Module
		xref	P61Samples
		ifeq FW_MUSIC_VBLANK-1
			xref	P61_Music
		endif
	endif

	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay
		xref	_mt_install_cia
		xref	_mt_remove_cia
		xref	_mt_init
		xref	_mt_end
		;xref	_mt_music
		xref	_mt_E8Trigger	;byte
		xref	_mt_Enable
		xref	_mt_VUMeter	;byte
		xref	PHXPT_Module
		xref	PHXPT_Samples
	endif

	ifne FW_MUSIC_AMIGAKLANG
		xref	AMIGAKLANG_Init
		xref	AMIGAKLANG_Temp
		xref	AMIGAKLANG_Isamp
		xref	AMIGAKLANG_Progress
	endif

	ifeq FW_MUSIC_TYPE-3		;prt
		include "MusicReplay/PreTracker_Offsets.i"

		; Song/buffers from IntroSharedData.s
		xref	prtPlayer
		xref	prtChipBuf
		xref	prtPlayerBuf
		xref	prtSong
		xref	prtSongBuf
	endif

	;Shared buffers
	xref	FW_Chip_Buffer_1
	xref	FW_Chip_Buffer_1_End
	xref	FW_Public_Buffer_1
	xref	FW_Public_Buffer_1_End

*****************************************************************************

	section	FW_PublicCode,code	;Code section in Public memory

*****************************************************************************

*****************************************************************************
* Gets sys details like VBR on 68010+ and if AA chipset. Run first as it gets
* critical details like VBR.
* IN:		
* OUT:
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_Init
FW_Init:
	movem.l	d2-d7/a2-a6,-(sp)	;save

	lea	FW_Vars(pc),a4

	;Kickstart check
	move.l	(_ExecBase).w,a6
	cmp.w   #37,LIB_VERSION(a6)     ;Check for Kickstart 2.04+ (A600) or later. For Cache functions
	sge	FW_KICKSTART2ORLATER(a4)

	;AA check
	cmpi.b	#$f8,lisaid+1+_custom	;$fc=ECS, $f8=AA
	seq	FW_AA_CHIPSET(a4)

	;VBR check
	move.l	(_ExecBase).w,a6
	moveq	#0,d0			;default VBR at $0
	btst.b	#0,AttnFlags+1(a6)	;68000 CPU?
	beq.s	.yes68k
	lea	.GetVBR(pc),a5		;else fetch vector base address
	jsr	_LVOSupervisor(a6)	;Go Supervisor mode to run a5 and return VBR
.yes68k:
	move.l	d0,FW_VBRPTR(a4)	;d0 is vbr

	movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts

	; From call to Supervisor()
	; Get VBR in d0.l
.GetVBR		
	;dc.w $4e7a,$c801		; movec vbr,a4
	dc.w $4e7a,$0801 		; movec vbr,d0

	;moveq   #0,d0
	;dc.l	$4e7b0002		;movec d0,cacr #disable all cache
	;dc.l	$f4784e71		;cpusha dc #Flush dirty cache lines 
	;dc.l	$4e7b0808		;!! movec d0,pcr #>=68060 only!

	rte


*****************************************************************************
* Kills the system.
*
* MUST RUN FW_GetSysDetails first!
*
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_KillSys
FW_KillSys:
	movem.l	d2-d7/a2-a6,-(sp)	;save

	move.l	(_ExecBase).w,a6
	jsr	_LVOForbid(a6)		;Disable multitasking

	lea	FW_Vars(pc),a5		;Storage
	lea	FW_GfxName(pc),a1	;open graphics.library
	jsr	_LVOOldOpenLibrary(a6)	;open
	move.l	d0,a6
	move.l	a6,FW_GFXBASE(a5)	;Save adr	

	move.l	gb_ActiView(a6),FW_GFXVIEW(a5)	;save active view

	ifne	FW_TOPAZ8
		lea	FW_Topaz_TextAttr(pc),a0
		move.l	#FW_TopazName,ta_Name(a0)
		jsr	_LVOOpenFont(a6)	;I:a0, O:d0 (TextFont)
		move.l	d0,FW_Topaz_TextFont_Ptr
	endif

	jsr	_LVOOwnBlitter(a6)	;Take over blitter
	jsr	_LVOWaitBlit(a6)	;and let it finish

	sub.l	a1,a1			;null view
	jsr	_LVOLoadView(a6)	;reset display
	jsr	_LVOWaitTOF(a6)		;twice to let interlaced displays stop
	jsr	_LVOWaitTOF(a6)
	
	;Stop interrupts before waiting for TOF and killing system as vblank interrupt 
	;processing may mean we get sprite corruption if interrupt takes too long. Toni Wilen
	;suggested its safer to store the custom registers after interrupts disabled.
	lea	_custom,a6		
	move.w	intenar(a6),FW_SYSINTENA(a5)	;save
	move.w	#$7fff,d0
	move.w	d0,intena(a6)		;Disable interrupts
	move.w	d0,intreq(a6)
	bsr	FW_WaitTOF_A6		;T:None

	move.w	dmaconr(a6),FW_SYSDMACON(a5)	;save
	move.w	adkconr(a6),FW_SYSADKCON(a5)	
	move.w	d0,dmacon(a6)			;disable 
	move.w	d0,adkcon(a6)

	;Save irq handlers
	move.l	FW_VBRPTR(a5),a0
	movem.l	VEC_LEVEL1(a0),d0-d5	;save lev1-6 irqs
	movem.l	d0-d5,FW_VEC_LEVEL1(a5)

	;Exception handlers	
	ifne FW_EXCEPTION_HANDLER
		move.l	VEC_BUSERR(a0),FW_VEC_BUSERR(a5)
		move.l	VEC_ADDRERR(a0),FW_VEC_ADDRERR(a5)
		move.l	VEC_ILLEGAL(a0),FW_VEC_ILLEGAL(a5)
		move.l	VEC_ZERODIV(a0),FW_VEC_ZERODIV(a5)
		lea	FW_ExceptionHandler(pc),a1
		move.l	a1,VEC_BUSERR(a0)
		move.l	a1,VEC_ADDRERR(a0)
		move.l	a1,VEC_ILLEGAL(a0)
		move.l	a1,VEC_ZERODIV(a0)
	endif

	;Write base CL/IRQ and then wait a frame to be sure it's active, then safe to turn on CDANG
	;without risk of blitter being triggered (seems to happen on real a1200). When copper dma is turned
	;on the last STROBED list from cop1lch immediately starts running. We need to be sure that is our 
	;new list.
	bsr	FW_SetBaseCopperIrq_A6
	bsr	FW_WaitTOF_A6		;T:None
	;move.w	#$0002,copcon(a6)	;Enable copper controlled blits, be sure custom CL installed first
	;move.w	#$8000,vposw(a6)	;Ensure using long frame 

	movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts


*****************************************************************************
* Restores the system.
*
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_RestoreSys
FW_RestoreSys:
	movem.l	d2-d7/a2-a6,-(sp)	;save

	lea	_custom,a6
	lea	FW_Vars(pc),a5		;Storage

	;Fix up set/clr bit 
	move.w	#$8000,d0		
	or.w	d0,FW_SYSADKCON(a5)
	or.w	d0,FW_SYSDMACON(a5)		
	or.w	d0,FW_SYSINTENA(a5)

	;Stop interrupts before waiting for EOF as slow music players running
	;in the lev3 irq can cause line position checks to never finish.
	subq.w	#1,d0			;$8000 to $7fff
	move.w	d0,intena(a6)
	move.w	d0,intreq(a6)

	;Wait for any blits and TOF to safely disable sprite DMA
	bsr	FW_WaitBlit_A6		;I:a6, T:None
	bsr	FW_WaitTOF_A6		;I:a6, T:None

	;Disable everything else
	;move.w	#$7fff,d0		;d0 is already $7fff
	move.w	d0,dmacon(a6)
	move.w	d0,adkcon(a6)

	;Restore irq handlers 
	move.l	FW_VBRPTR(a5),a0
	movem.l	FW_VEC_LEVEL1(a5),d0-d5
	movem.l	d0-d5,VEC_LEVEL1(a0)

	;Restore exception handlers
	ifne FW_EXCEPTION_HANDLER
		move.l	FW_VEC_BUSERR(a5),VEC_BUSERR(a0)
		move.l	FW_VEC_ADDRERR(a5),VEC_ADDRERR(a0)
		move.l	FW_VEC_ILLEGAL(a5),VEC_ILLEGAL(a0)
		move.l	FW_VEC_ZERODIV(a5),VEC_ZERODIV(a0)
	endif

	;Write the system copper lists first. But gotcha here is that this new list will only run at next
	;vblank so the sprite dma disable code in our framework/previous CL is at risk of running when we turn DMA back
	;on which would then cause issues with OS sprites. Easiest solution stobe copjmp1 before
	;renabling DMA.
	move.l	FW_GFXBASE(a5),a4		;gfx library
	move.l	gb_copinit(a4),cop1lch(a6)	;Startup copper list in cop1lc
	move.l	gb_LOFlist(a4),cop2lch(a6)	;Long frame copper list in cop2lc
	move.w	d0,copjmp1(a6)

	move.w	FW_SYSINTENA(a5),intena(a6)
	move.w	FW_SYSDMACON(a5),dmacon(a6)
	move.w	FW_SYSADKCON(a5),adkcon(a6)

	move.l	a4,a6			;gfx base
	move.l	FW_GFXVIEW(a5),a1	;get old view
	jsr	_LVOLoadView(a6)	;activate view

	jsr	_LVODisownBlitter(a6)	;free the blitter

	;Apparently, topaz and gfx library are always open, so can save some code here by not trying to close
	ifne	FW_TOPAZ8
		move.l	FW_Topaz_TextFont_Ptr(pc),a1
		jsr	_LVOCloseFont(a6)	;I:a1 (TextFont)
	endif

	move.l	a6,a1			;gfx base
	move.l	(_ExecBase).w,a6	;DO NOT COMMENT OUT - NEEDED FOR PERMIT()
	jsr	_LVOCloseLibrary(a6)	;close, not really needed as GFX is always open

	jsr	_LVOPermit(a6)		;multitask on

	movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts


*****************************************************************************
* Init music routines that can be done after system killed. P61 etc
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_MusicInit
FW_MusicInit:
	movem.l	d2-d7/a2-a6,-(sp)	;save

	ifeq FW_MUSIC_TYPE-1		;p61
		clr.b	FW_Vars+FW_MUSICPLAYING
		clr.w	P61_Play	;Default is not playing until we enable

		move.l	FW_Vars+FW_VBRPTR(pc),P61_VBR
		lea	P61Module,a0
		lea	P61Samples,a1
		sub.l	a2,a2		;Packed samples address
		moveq	#1,d0		;PAL
		jsr	P61_Init

		st	FW_Vars+FW_MUSICINITIALISED
	endif				;p61


	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay (with optional amigaklag)

		;Amigaklang samples precalc
		ifne FW_MUSIC_AMIGAKLANG
			;a0: startaddress where to render the samples to (chipram, see amigaklanggui for size)
			;a1: startaddress of a temporary render buffer (65536 bytes, public ram)
			;a2: startaddress of external samples (if used. Include Ismp.raw, can be public ram)
			;a4: address where the synth puts the rendering progress (e.g. for a progressbar, a long in public ram)
			lea	PHXPT_Samples,a0
			lea	FW_Public_Buffer_1_End-65536,a1	;needs 64KB buffer
			lea	AMIGAKLANG_Isamp,a2
			lea	AMIGAKLANG_Progress,a4
			jsr	AMIGAKLANG_Init

		endif

		clr.b	FW_Vars+FW_MUSICPLAYING
		clr.b	_mt_Enable	;Starts paused

		;_mt_install_cia(a6=CUSTOM, a0=VectorBase, d0=PALflag.b)
		lea	_custom,a6
		move.l	FW_Vars+FW_VBRPTR,a0	;VBR
		moveq	#1,d0			;PAL
		jsr	_mt_install_cia		;I:a0/a6/d0 T:d0-d7/a0-a5

 		;_mt_init(a6=CUSTOM, a0=TrackerModule, a1=Samples|NULL, d0=InitialSongPos.b)
		lea	PHXPT_Module,a0
		lea	PHXPT_Samples,a1
		moveq	#0,d0
		jsr	_mt_init

		st	FW_Vars+FW_MUSICINITIALISED
	endif				;PHX_PTReplay


	ifeq FW_MUSIC_TYPE-3		;prt
		clr.b	FW_Vars+FW_MUSICPLAYING

		lea	prtPlayer,a6
		lea	prtPlayerBuf,a0
		lea	prtSongBuf,a1
		lea	prtSong,a2
		add.l	(prtSongInit,a6),a6
		jsr	(a6)		; songInit

		lea	prtPlayer,a6
		lea	prtPlayerBuf,a0
		lea	prtChipBuf,a1
		lea	prtSongBuf,a2
		add.l	(prtPlayerInit,a6),a6
		jsr	(a6)		; playerInit

		st	FW_Vars+FW_MUSICINITIALISED
	endif				;prt


	movem.l	(sp)+,d2-d7/a2-a6	;restore

	rts


*****************************************************************************
* Starts playing music if not started yet or has been paused.
* IN:		
* OUT:		
* TRASHED:	d0-a1/a0-a1
*****************************************************************************

	xdef	FW_MusicPlay
FW_MusicPlay:
	;movem.l	d2-d7/a2-a6,-(sp)	;save

	ifeq FW_MUSIC_TYPE-1		;p61
		move.w	#1,P61_Play	;Default is not playing until we enable
		st	FW_Vars+FW_MUSICPLAYING
	endif				;p61

	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay (with optional amigaklag)
		move.b	#1,_mt_Enable	;Start playing
		st	FW_Vars+FW_MUSICPLAYING
	endif				;PHX_PTReplay

	ifeq FW_MUSIC_TYPE-3		;prt
		st	FW_Vars+FW_MUSICPLAYING
	endif				;prt

	;movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts


*****************************************************************************
* Starts playing music if not started yet or has been paused.
* IN:		
* OUT:		
* TRASHED:	d0-a1/a0-a1
*****************************************************************************

	xdef	FW_MusicPause
FW_MusicPause:
	;movem.l	d2-d7/a2-a6,-(sp)	;save

	ifeq FW_MUSIC_TYPE-1		;p61
		clr.w	P61_Play	;Stop playing
		clr.b	FW_Vars+FW_MUSICPLAYING
	endif				;p61

	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay (with optional amigaklag)
		clr.b	_mt_Enable	;Stop playing
		clr.b	FW_Vars+FW_MUSICPLAYING
	endif				;PHX_PTReplay

	ifeq FW_MUSIC_TYPE-3		;prt
		clr.b	FW_Vars+FW_MUSICPLAYING
	endif				;prt

	;movem.l	(sp)+,d2-d7/a2-a6	;restore
	rts


*****************************************************************************
* Gets a bit mask for new notes on a channel for VU meters.
* 1=chan1, 2=chan2, 4=chan3, 8=chan4
* E8x values are shifted 4 bits so we have bits 0-3 for new notes, and bits
* 4-7 being the E8x value (shifted 4 bits)
*
* Note: Visualiser functions have to be enabled in P61/PHXPtplayer for this to assemble.
*
* IN:		
* OUT:		d0.w mask value
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef	FW_MusicGetSyncVal
FW_MusicGetSyncVal:

	ifeq FW_MUSIC_TYPE-1		;p61
		; Bits 0-3 are just the VUmeter
		moveq	#0,d0

		; These are counters since last trigger, so 0 is just triggered
		lea	P61_visuctr0,a0
.vu1:
		tst.w	(a0)+
		bne.s	.vu2
		addq.w	#1,d0
.vu2:
		tst.w	(a0)+
		bne.s	.vu3
		addq.w	#2,d0
.vu3:
		tst.w	(a0)+
		bne.s	.vu4
		addq.w	#4,d0
.vu4:
		tst.w	(a0)+
		bne.s	.vuwrite
		addq.w	#8,d0
.vuwrite:
		;bits 4-7 is the E8x value shifted << 4
		move.w	P61_E8,d1
		clr.w	P61_E8
		lsl.w	#4,d1
		or.w	d1,d0

	endif				;p61


	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay

		; Bits 0-3 are just the VUmeter
		moveq	#0,d0
		move.b	_mt_VUMeter,d0
		clr.b	_mt_VUMeter

		;bits 4-7 is the E8x value shifted << 4
		moveq	#0,d1
		move.b	_mt_E8Trigger,d1
		clr.b	_mt_E8Trigger
		lsl.b	#4,d1
		or.b	d1,d0

	endif				;PHX_PTReplay

	rts


*****************************************************************************
* Stop music routines that can be done after system killed. P61 etc
* Runs any cleanup as well.
* IN:		
* OUT:		
* TRASHED:	d0-a1/a0-a1
*****************************************************************************

	xdef	FW_MusicEnd
FW_MusicEnd:
	movem.l	d2-d7/a2-a6,-(sp)	;save

	; Finish music
	ifeq FW_MUSIC_TYPE-1		;p61
		jsr	P61_End
		clr.b	FW_Vars+FW_MUSICPLAYING
		clr.b	FW_Vars+FW_MUSICINITIALISED
	endif

	ifeq FW_MUSIC_TYPE-2		;PHX_PTReplay
		lea	_custom,a6
		jsr	_mt_end
		jsr	_mt_remove_cia
		clr.b	FW_Vars+FW_MUSICPLAYING
		clr.b	FW_Vars+FW_MUSICINITIALISED
	endif
	
	ifeq FW_MUSIC_TYPE-3		;prt
		clr.b	FW_Vars+FW_MUSICPLAYING
		clr.b	FW_Vars+FW_MUSICINITIALISED
	endif
	
	movem.l	(sp)+,d2-d7/a2-a6	;restore

	rts

	
*****************************************************************************

; Normal 320x320 starting at line 44($2c) means EOF would be 44+256 = 300
; Overscan 352x272 starting at line 36($24) means EOF would be 36+272 = 308
; For interlaced PAL:
;   vblank begins at vpos 312 hpos 1 and ends at vpos 25 hpos 1
;   vblank begins at vpos 311 hpos 1 and ends at vpos 25 hpos 1
; So safest last visible line to wait for before vblank interrupt would be 310
; I like to start clearing the screen as soon as possible after the last visible line
; which means that the blitter is usually clearing already by the time the vblank happens
; and then there is a nice mix of CPU code happening while clearing.
;
	xdef	FW_WaitEOFExact_A6
FW_WaitEOFExact_A6:			;wait for end of frame, IN: a6=_custom, trashes d0
.lo:	move.l	vposr(a6),d0
	andi.l	#$1ff00,d0		;16
	cmpi.l	#303<<8,d0		;14		
	bne.s	.lo			;wait until it matches (eq)
	rts

	xdef	FW_WaitEOF_A6		
FW_WaitEOF_A6:				;wait for end of frame or greater, IN: a6=_custom, trashes d0
.lo:	move.l	vposr(a6),d0
	lsr.l	#1,d0			;10
	lsr.w	#7,d0			;20
	cmpi.w	#303,d0			
	blt.s	.lo			;EOF or later
	rts

	xdef	FW_WaitRasterExact_A6
FW_WaitRasterExact_A6:		
.lo:	move.l	vposr(a6),d1		;Wait for scanline. IN: A6=custom, d0=scanline, trashes d1
	lsr.l	#1,d1
	lsr.w	#7,d1
	cmp.w	d0,d1
	bne.s	.lo			;wait until it matches (eq)
	rts

	xdef	FW_WaitRaster_A6
FW_WaitRaster_A6:
.lo:	move.l	vposr(a6),d1		;Wait for scanline or greater. IN: A6=custom, d0=scanline, trashes d1
	lsr.l	#1,d1
	lsr.w	#7,d1
	cmp.w	d0,d1
	blt.s	.lo			;wait until it matches or later
	rts

	xdef	FW_WaitTOF
FW_WaitTOF:
.vsync:	
	btst	#0,_custom+vposr+1
	beq.b	.vsync			;wait while in 0-255 range if bit is 0
.vsync2: 
	btst	#0,_custom+vposr+1	;wait while in 256+ range
	bne.b	.vsync2

	;just started new frame, and will only really return after any VBL processing
	;because the code will be blocked during that.
	rts				

	xdef	FW_WaitTOF_A6
FW_WaitTOF_A6:
.vsync:	
	btst	#0,vposr+1(a6)
	beq.b	.vsync			;wait while in 0-255 range if bit is 0
.vsync2: 
	btst	#0,vposr+1(a6)		;wait while in 256+ range
	bne.b	.vsync2

	;just started new frame, and will only really return after any VBL processing
	;because the code will be blocked during that.
	rts	

	
*****************************************************************************
	
	xdef	FW_WaitBlit_A6
FW_WaitBlit_A6:				;wait until blitter is finished, IN: A5=_custom
	tst.w	dmaconr(a6)		;for compatibility with A1000
.loop:	btst.b	#6,dmaconr(a6)
	bne.s	.loop
	rts


*****************************************************************************
* Clears a buffer using the Blitter and CPU.
* Adapted from source from Photon/Scoopex.
* Max 256KB
* IN:		a6, _custom/$dff000
*		a0 (buffer to clear) (even address)
*		d0.w, number of words to clear
*		d1.w, number of bytes to clear with blitter (tune to suit)
*			0=all CPU, 65535=99% blitter
* OUT:		a0, next address after the cleared buffer
*		a6, _custom
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

FW_ClearBuffer_BlitCPU_BlkSize	equ	2	;movem-repetitions, 2*13.l = 104 bytes per loop

	xdef	FW_ClearBuffer_BlitCPU_A6
FW_ClearBuffer_BlitCPU_A6:
	move.l	a5,-(sp)		;save

	moveq	#0,d2
	move.w	d0,d2
	mulu	d1,d0			;blit part of the clr, 34250/65536 for 6bpdma
	swap	d0
	move.l	d2,d1

	and.w	#-64,d0			;bltsize
	beq.s	.skipb
	sub.w	d0,d1			;rest (words)
	
	;Start the blit
	WAITBLIT_NASTY_A6
	move.l	#$01000000,bltcon0(a6)	;Clear
	clr.w	bltdmod(a6)
	move.l	a0,bltdpth(a6)
	move.w	d0,bltsize(a6)
.skipb:	
	; Work out how many movem loops we need
	divu	#13*2*FW_ClearBuffer_BlitCPU_BlkSize,d1
.cpu:	
	add.l	d2,d2			;words to bytes
	add.l	d2,a0			;find end of buffer for pre-decrement
	movem.l FW_ClearBuffer_Zero13,d0/d2-d7/a1-a6	;zeroes, 13 regs
	subq.w	#1,d1			;-1 for dbf
	bmi.s	.nor2
.mvml:	
	REPT 	FW_ClearBuffer_BlitCPU_BlkSize
	movem.l	d0/d2-d7/a1-a6,-(a0)		;13 regs (52 bytes)
	ENDR
	dbf 	d1,.mvml
.nor2:
	;Clear any remaining in single 13 long blocks
	swap	d1				;rest
	bra.s	.cont1
.bigl:	
	movem.l	d0/d2-d7/a1-a6,-(a0)	;13 regs
.cont1:	
	sub.w	#13*2,d1		;13 regs
	bpl.s	.bigl
	add.w	#13*2,d1		;13 regs

      	;Clear final remaining in single long/word loop
	lsr.w	#1,d1
	bcc.s	.now
	move.w	d0,-(a0)
.now:	subq.w	#1,d1
	bmi.s	.nor1
.l:	move.l	d0,-(a0)
	dbf	d1,.l
.nor1:
	lea	_custom,a6		;restore a6
	move.l	(sp)+,a5

	rts


*****************************************************************************
* Clears a buffer using the CPU.
* Adapted from source from Photon/Scoopex.
* Max 256KB
* IN:		a0 (buffer to clear) (even address)
*		d0.w, number of words to clear
* OUT:		a0, next address after the cleared buffer
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

	xdef	FW_ClearBuffer_CPU
FW_ClearBuffer_CPU:
	move.l	a5,-(sp)		;save
	move.l	a6,-(sp)

	moveq	#0,d2			;clear top of d2
	move.w	d0,d2			;d2=words to clr (cleared top)
	move.l	d2,d1			;d1=words to clr (cleared top)

	; Work out how many movem loops we need (how many words per loop)
	divu	#13*2*FW_ClearBuffer_BlitCPU_BlkSize,d1
.cpu:	
	add.l	d2,d2			;words to bytes
	add.l	d2,a0			;find end of buffer for pre-decrement
	movem.l FW_ClearBuffer_Zero13,d0/d2-d7/a1-a6	;zeroes, 13 regs, d0 already 0
	subq.w	#1,d1			;-1 for dbf
	bmi.s	.nor2
.mvml:	
	REPT 	FW_ClearBuffer_BlitCPU_BlkSize
	movem.l	d0/d2-d7/a1-a6,-(a0)		;13 regs (52 bytes)
	ENDR
	dbf 	d1,.mvml
.nor2:
	;Clear any remaining in single 13 long blocks
	swap	d1				;rest
	bra.s	.cont1
.bigl:	
	movem.l	d0/d2-d7/a1-a6,-(a0)	;13 regs
.cont1:	
	sub.w	#13*2,d1		;13 regs
	bpl.s	.bigl
	add.w	#13*2,d1		;13 regs

      	;Clear final remaining in single long/word loop
	lsr.w	#1,d1
	bcc.s	.now
	move.w	d0,-(a0)
.now:	subq.w	#1,d1
	bmi.s	.nor1
.l:	move.l	d0,-(a0)
	dbf	d1,.l
.nor1:
	move.l	(sp)+,a6		;restore
	move.l	(sp)+,a5

	rts


*****************************************************************************
* Copies a buffer using the CPU.
* Max 256KB
* IN:		a0 (source) (even address)
*		a1 (dest)
*		d0.w, number of words to copy
* OUT:		
* TRASHED:	d0-d7/a0-a2
*****************************************************************************

	xdef	FW_CopyBuffer_CPU
FW_CopyBuffer_CPU:
FW_CopyBuffer_BlkSize	equ	4	;movem-repetitions, 4*8.l = 128 bytes per loop

	;Copying 8 longs at a time
	ext.l	d0			;clear top
	divu.w	#8*2*FW_CopyBuffer_BlkSize,d0
	subq.w	#1,d0			;dbf
	bmi.s	.nor2

.copy:	
	REPT	FW_CopyBuffer_BlkSize
	movem.l	(a0)+,d1-d7/a2
	movem.l	d1-d7/a2,(a1)
	lea	8*4(a1),a1
	ENDR
	dbf	d0,.copy

.nor2:
	;Clear any remaining (get remainder from highword)
	swap	d0	

	;Copy final remaining in single long/word loop
	lsr.w	#1,d0
	bcc.s	.now
	move.w	(a0)+,(a1)+
.now:	subq.w	#1,d0
	bmi.s	.nor1
.l:	move.l	(a0)+,(a1)+
	dbf	d0,.l
.nor1:
	rts


*****************************************************************************
* Sets all colors to $000 (for startup or non-copper list routines)
* IN:
* OUT:
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef	FW_SetColorsBlack_A6
FW_SetColorsBlack_A6:
	lea	color00(a6),a0
	moveq	#32-1,d0
	moveq	#0,d1
.loop:	
	move.w	d1,(a0)+
	dbf	d0,.loop

	rts


*****************************************************************************
* Sets Lev1 IRQ safely on 68000+. Sets it immediately so handle any
* timing/waiting externally.
* IN:		a0, new Irq
* OUT:
* TRASHED:	a1
*****************************************************************************

	xdef	FW_SetLev1Irq
FW_SetLev1Irq:
	move.l	FW_Vars+FW_VBRPTR(pc),a1
	move.l	a0,VEC_LEVEL1(a1)

	rts


*****************************************************************************
* Sets Lev3 IRQ safely on 68000+. Sets it immediately so handle any
* timing/waiting externally.
* IN:		a0, new Irq
* OUT:
* TRASHED:	a1
*****************************************************************************

	xdef	FW_SetLev3Irq
FW_SetLev3Irq:
	move.l	FW_Vars+FW_VBRPTR(pc),a1
	move.l	a0,VEC_LEVEL3(a1)

	rts


*****************************************************************************
* Sets the copper list and default IRQ
*
* IN:		a6, _custom
*		a0, ptr to new copperlist
*		a1, ptr to lev3 irq
* OUT:		
* TRASHED:	a0
*****************************************************************************

	xdef	FW_SetCopperIrq_A6
FW_SetCopperIrq_A6:
	move.l 	a0,cop1lch(a6)
	move.l	FW_Vars+FW_VBRPTR(pc),a0

	ifne FW_FRAME_IRQ_LEV3
	move.l	a1,VEC_LEVEL3(a0)
	endif

	ifne FW_FRAME_IRQ_LEV1
	move.l	a1,VEC_LEVEL1(a0)
	endif

	rts


*****************************************************************************
* Sets the base CL.
* Doesn't touch Dma so set separately.
* IN:		a6, _custom
* OUT:
* TRASHED:	a0
*****************************************************************************

	xdef	FW_SetBaseCopper_A6
FW_SetBaseCopper_A6:
	move.l 	#FW_CL,cop1lch(a6)

	rts


*****************************************************************************
* Sets the base CL and Lev3 Irq.
* Doesn't touch Dma so set separately.
* IN:		a6, _custom
* OUT:
* TRASHED:	a0
*****************************************************************************

	xdef	FW_SetBaseCopperIrq_A6
FW_SetBaseCopperIrq_A6:
	bsr.s	FW_SetBaseCopper_A6
	bsr.s	FW_SetBaseIrq

	rts


*****************************************************************************
* Sets Lev3 IRQ safely on 68000+. Sets to FW default (just music player)
* IN:		
* OUT:
* TRASHED:	a0
*****************************************************************************

	xdef	FW_SetBaseIrq
FW_SetBaseIrq:
	move.l	FW_Vars+FW_VBRPTR(pc),a0

	ifne FW_FRAME_IRQ_LEV3
	move.l	#FW_IrqHandlerLev3,VEC_LEVEL3(a0)
	endif

	ifne FW_FRAME_IRQ_LEV1
	move.l	#FW_IrqHandlerLev1,VEC_LEVEL1(a0)
	endif

	rts


*****************************************************************************
* Sets the copper list and enables DMA (Blitter,Copper,Bitplane)
* Use after exiting a subpart to ensure blank screen. 
* IN:		a6, _custom
* OUT:
* TRASHED:	d0/a0-a1
*****************************************************************************

	xdef	FW_SetBaseCopperIrqDma_A6
FW_SetBaseCopperIrqDma_A6:

	;move.w	#INTF_INTEN,intena(a6)	;Interrupts off while we switch
	;bsr	FW_WaitBlit_A6		;Finish off blits

	;Can't use a EOF vposr check here as music player may run over the frame
	;Also can't use framesync counter as irq may not be running yet.
	;Instead just check for going into the 256+ (bit V8 is bit 0 of vposr)
	;territory and then back to 0-255.
	;this usually handles IRQs that are waiting for line 0, or 256+
	;without clashing with long running music players
	;bsr	FW_WaitTOF

	move.l	FW_Vars+FW_VBRPTR(pc),a0
	move.l 	#FW_CL,cop1lch(a6)

	; Enable DMA and interrupts
BaseDMA set DMAF_SETCLR|DMAF_MASTER|DMAF_RASTER|DMAF_COPPER|DMAF_BLITTER

	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_NONE
BaseINT set INTF_SETCLR|INTF_INTEN
	endif

	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_COPER
BaseINT set INTF_SETCLR|INTF_INTEN|INTF_COPER
	move.l	#FW_IrqHandlerLev3,VEC_LEVEL3(a0)
	endif

	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_VERTB
BaseINT set INTF_SETCLR|INTF_INTEN|INTF_VERTB
	move.l	#FW_IrqHandlerLev3,VEC_LEVEL3(a0)
	endif

	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_SOFTINT
BaseINT set INTF_SETCLR|INTF_INTEN|INTF_SOFTINT
	move.l	#FW_IrqHandlerLev1,VEC_LEVEL1(a0)
	endif

	move.w 	#BaseDMA,dmacon(a6)	
	move.w	#BaseINT,intena(a6)
	;move.w	#0,COPJMP1(a6)

	rts


*****************************************************************************
* Safely disable sprite DMA. Can be used outside of a vblank with no garbage.
* Note: ross approved :)
* IN:		a6, _custom
* OUT:		
* TRASHED:	d0
*****************************************************************************

	xdef	FW_SafeDisableSpriteDma_A6
FW_SafeDisableSpriteDma_A6
	move.w	#DMAF_SPRITE,dmacon(a6)
	moveq	#0,d0
	move.w	d0,spr0ctl(a6)		;SPRxCTL
	move.w	d0,spr1ctl(a6)
	move.w	d0,spr2ctl(a6)
	move.w	d0,spr3ctl(a6)
	move.w	d0,spr4ctl(a6)
	move.w	d0,spr5ctl(a6)
	move.w	d0,spr6ctl(a6)
	move.w	d0,spr7ctl(a6)

	rts


*****************************************************************************
* Pokes the bitplane pointers in the copperlist
* IN:		a0, CopperPtr to bpl1pth
*		d1, ScreenPtr
*		d0, num bitplanes
*		d2, modulo in bytes, screen_bytewidth for interleaved)
*		screen_size for normal) Optional if d0=1
* OUT:		
* TRASHED:	d0-d1/a0
*****************************************************************************

	xdef	FW_InitCopperBplPtrs
FW_InitCopperBplPtrs:
	subq.w	#1,d0			;-1 for dbf
	ext.l	d2			;Make d2 safe for longword addition
	addq.l	#2,a0			;Skip bplpth to save time below (a0) instead of 2(a0)
.makecl
	swap	d1			;Swap high & low words
	move.w	d1,(a0)			;High ptr
	swap	d1			;Swap high & low words
	move.w	d1,4(a0)		;Low ptr
	addq.l	#8,a0			;Next set of ptrs
	add.l	d2,d1			;Next bitplane
	dbf	d0,.makecl

	rts


*****************************************************************************
* Clears copper list block of n sprites
* IN:		a0, ptr to block of n sprites in copperlist
*			CMOVE	spr0pth,$0
*			CMOVE	spr0ptl,$0
*			CMOVE	spr1pth,$0
*			CMOVE	spr1ptl,$0
*		d0.w, number of sprites to clear, 1-8
*
* OUT:		
* TRASHED:	d0-d2/a0-a1
*****************************************************************************

	xdef	FW_ClrCopperSprPtrs
FW_ClrCopperSprPtrs:

	subq.w	#1,d0			;-1 for dbf
	addq.l	#2,a0			;PTH
	move.l	#FW_Blank_Sprite,d1	;Blank sprite
	move.l	d1,d2
	swap	d1			;d1=high, d2=low
.loop
	move.w	d1,(a0)			;PTH
	move.w	d2,4(a0)		;PTL
	addq.l	#8,a0			;Next sprite
	dbf	d0,.loop

	rts


*****************************************************************************
* Init copper list block of sprites
* IN:		a0, ptr to block of 8 sprites in copperlist
*			CMOVE	spr0pth,$0
*			CMOVE	spr0ptl,$0
*			CMOVE	spr1pth,$0
*			CMOVE	spr1ptl,$0
*		a1, ptr to 8 longwords which point to sprites
*		d0.w, number of sprites
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_InitCopperSprPtrs
FW_InitCopperSprPtrs:
	addq.l	#2,a0			;PTH
	subq.w	#1,d0			;dbf
.loop
	move.l	(a1)+,d1
	move.w	d1,4(a0)
	swap	d1
	move.w	d1,(a0)
	addq.l	#8,a0
	dbf	d0,.loop

	rts


*****************************************************************************
* Waits for a new frame.
* IN:		
* OUT:		
* TRASHED:	d0	
*****************************************************************************

	xdef	FW_WaitFrame
FW_WaitFrame:
	;If not running any irqs then we have to manually wait for new frames
	;and call VW_BlankProxy to play music and update frame count
	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_NONE
		bsr	FW_WaitTOF
		bsr	FW_VBlankProxy
	else
		move.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0
.loop	
		cmp.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0
		beq.s	.loop
	endif

	rts


*****************************************************************************
* Waits for a vertical blank for a number of frames (to get constant 25fps for example)
* If the period has already been missed when it starts it will wait for the next vblank.
* IN:		d0.w (number of frames to wait, 1=50fps,2=25fps)	
* OUT:		
* TRASHED:	d0
*****************************************************************************

	xdef	FW_WaitFrames
FW_WaitFrames:
	add.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0	;count to wait for
.loop	
	;If not running any irqs then we have to manually wait for new frames
	;and call VW_BlankProxy to play music and update frame count
	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_NONE
		move.w	d0,-(sp)
		bsr	FW_WaitTOF
		bsr	FW_VBlankProxy
		move.w	(sp)+,d0
	endif

	cmp.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0
	bhi.s	.loop
	rts


*****************************************************************************
* Returns 1 if the frame counter has passed given frame number. Unsigned word
* so range of 36 mins. 
* IN:		d0.w the frame number to check for
* OUT:		d0.w, 0=not yet, 1=yes
* TRASHED:	d0
*****************************************************************************

	xdef	FW_IsFrameOver
FW_IsFrameOver:
	ifne	FW_GETFRAME_BREAKPOINT
		move.w	d0,-(sp)
		move.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0
		WinUAEBreakpoint
		move.w	(sp)+,d0
	endif

	cmp.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0
	bhi.s	.notyet
	moveq	#1,d0
	rts
.notyet:
	moveq	#0,d0
	rts


*****************************************************************************
* Returns current frame number for demo timing.
* IN:		
* OUT:		d0.w, frame number
* TRASHED:	d0
*****************************************************************************

	xdef	FW_GetFrame
FW_GetFrame:
	move.w	FW_Vars+FW_MASTERFRAMECOUNTER(pc),d0

	ifne	FW_GETFRAME_BREAKPOINT
		WinUAEBreakpoint
	endif

	rts


*****************************************************************************
* Resets the current frame number for demo timing. Use after a long precalc
* intro
* IN:		
* OUT:		
* TRASHED:	
*****************************************************************************

	xdef	FW_ResetFrame
FW_ResetFrame:
	clr.w	FW_Vars+FW_MASTERFRAMECOUNTER

	rts


*****************************************************************************
* VBI happens at line 0 and lasts for 25 lines on PAL. Last visible line is 311
* If you need more processing time you can make the copper trigger an interrupt 
* after the last visible line instead. For example if using normal 320x256
* starting at line 44($2c) then you could trigger interrupt at line 300 instead.
*****************************************************************************

; General Irq used by FW_SetBase... - designed to be used in between
; parts for minimal distruption. Setup to handle all combinations of VERTB vs
; COPER vs BLIT irqs and music players.

	ifne FW_FRAME_IRQ_LEV3
FW_IrqHandlerLev3:			;Blank template VERTB interrupt
	movem.l	d0-d7/a0-a6,-(sp)

	lea	_custom,a6

	move.w	intreqr(a6),d0
	btst	#INTB_VERTB,d0
	bne.s	.vertb
	btst	#INTB_COPER,d0
	bne.s	.coper

.blit:
	moveq	#INTF_BLIT,d0
	bra.s	.exit

.coper:
	ifeq	FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_COPER
	bsr.s	FW_VBlankProxy		;T:d0-d7/a0-a4
	endif

	moveq	#INTF_COPER,d0
	bra.s	.exit

.vertb:
	ifeq	FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_VERTB
	bsr.s	FW_VBlankProxy		;T:d0-d7/a0-a4
	endif

	moveq	#INTF_VERTB,d0

; ----

.exit	;a6=_custom, d0.w = interrupt to reset
	move.w	d0,intreq(a6)
	move.w	d0,intreq(a6)		;A4000 compat
	movem.l	(sp)+,d0-d7/a0-a6	;restore
	rte

	endif	;FW_FRAME_IRQ_LEV3

*****************************************************************************

	ifne FW_FRAME_IRQ_LEV1
FW_IrqHandlerLev1:			;Blank template SOFTINT interrupt
	movem.l	d0-d7/a0-a6,-(sp)

	lea	_custom,a6

	ifeq	FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_SOFTINT
	bsr.s	FW_VBlankProxy		;T:d0-d7/a0-a4
	endif

	moveq	#INTF_SOFTINT,d0

.exit	;a6=_custom, d0.w = interrupt to reset
	move.w	d0,intreq(a6)
	move.w	d0,intreq(a6)		;A4000 compat
	movem.l	(sp)+,d0-d7/a0-a6	;restore
	rte


	endif	;FW_FRAME_IRQ_LEV1

*****************************************************************************
* Call this every frame in VBL or Copper interrupt. Will update the frame
* counter and call music routine if vblank based player routine.
* TRASHES ALL BUT a5/a6 REGS - THIS IS FOR SPEED 
* In most of my code I'll usually have a5/a6 in use when
* calling this so don't want to lose cycles saving all.
* IN:		
* OUT:		
* TRASHED:	d0-d7/a0-a4
*****************************************************************************

	xdef	FW_VBlankProxy
FW_VBlankProxy:

	;If no vblank based music then smallest possible code
	ifeq FW_MUSIC_VBLANK
		addq.w	#1,FW_Vars+FW_MASTERFRAMECOUNTER
		rts
	else

		move.l	a5,-(sp)
		move.l	a6,-(sp)

		lea	FW_Vars(pc),a5
		addq.w	#1,FW_MASTERFRAMECOUNTER(a5)	;Increase master frame counter

		;Is our music actually fully initialised?
		ifne FW_MUSIC_TYPE
		tst.b	FW_MUSICINITIALISED(a5)
		beq.s	.exit		;nope
		endif

		; P61 Vblank music - pauses handled by P61_Music
		ifeq FW_MUSIC_TYPE-1
		ifeq FW_MUSIC_VBLANK-1
			lea	_custom,a6
			jsr	P61_Music	;IN: a6=custom
		endif
		endif

		; PRT VBlank music - pauses handled manually
		ifeq FW_MUSIC_TYPE-3
			tst.b	FW_MUSICPLAYING(a5)	;paused?
			beq.s	.exit			;yep

			lea	prtPlayer,a1
			lea	prtPlayerBuf,a0
			add.l	(prtPlayerTick,a1),a1
			jsr	(a1)	; playerTick
		endif

.exit:
		move.l	(sp)+,a6
		move.l	(sp)+,a5
		rts
	endif


*****************************************************************************
* Check for a user quit signal. RMB quits section, lmb quits intro.
* IN:		a6, _custom
* OUT:		d0, 0=ok, 1=quit (zero flag will be set appropriately)
* TRASHED:	d0
*****************************************************************************
	
	xdef	FW_CheckUserQuitSignal_A6
FW_CheckUserQuitSignal_A6:
	ifne FW_RMB_QUIT_SECTION
	btst.b	#10-8,potgor(a6)	;rmb quits section
	beq.s	.section_quit
	endif

	btst.b 	#6,_ciaa		;lmb quits intro
	beq.s 	.intro_quit
.ok:
	moveq	#0,d0			;clr d0
	rts

.intro_quit:
	move.w	#1,FW_Quit_Flag		;quit entire intro
.section_quit:
	moveq	#1,d0
	rts


*****************************************************************************
* Creates a premult table. It's used so often added to framework.
* IN:		d0.w, modulo 
*		d1.w, number of entries
*		a0, Table locations 
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	FW_PreMultCreate_W
FW_PreMultCreate_W:
	move.l	d2,-(sp)

	moveq	#0,d2
	subq.w	#1,d1			;-1 for dbf
.loop:
	move.w	d2,(a0)+
	add.w	d0,d2
	dbf	d1,.loop

	move.l	d2,(sp)+
	rts

	xdef	FW_PreMultCreate_L
FW_PreMultCreate_L:
	move.l	d2,-(sp)

	ext.l	d0

	moveq	#0,d2
	subq.w	#1,d1			;-1 for dbf
.loop:
	move.l	d2,(a0)+
	add.l	d0,d2
	dbf	d1,.loop

	move.l	d2,(sp)+
	rts


*****************************************************************************
* Draws using topaz8 rom font. font is 8x8px. Caller must position by passing
* correct address in a0. Only draws on byte boundaries for simplicity.
* IN:		d0.w, ascii char
*		d1.w, screen modulo
*		a0, Screen address
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	ifne	FW_TOPAZ8

	xdef	FW_Topaz8PrintLetter
FW_Topaz8PrintLetter:
	movem.l	d0-d7/a0-a6,-(sp)

	move.l	FW_Topaz_TextFont_Ptr(pc),a1
	move.l	tf_CharData(a1),a2	;Font bitmap data
	sub.b	tf_LoChar(a1),d0	;Adjust ascii to font range (it's 32)
	move.w	tf_Modulo(a1),d2	;Font bitmap width (it's 192)
	;move.w	tf_XSize(a1),d0		;8 for topaz8
	add.w	d0,a2			;Address of char

	moveq	#8-1,d3			;8 lines
.loop:
	move.b	(a2),(a0)
	add.w	d2,a2			;Next line of font
	add.w	d1,a0			;Next line on screen
	dbf	d3,.loop

	movem.l	(sp)+,d0-d7/a0-a6
	rts

	endif


*****************************************************************************
* This routine is called on any exception. To find the PC at time of crash
* just check SP-8.
* In WinUAE:
*  - m isp+2
*  - d <value from above>
* IN:
* OUT:
* TRASHED:
*****************************************************************************
	
FW_ExceptionHandler:
	move.w	#$f00,_custom+color00
	bra.s	FW_ExceptionHandler


*****************************************************************************
* Allocates chip ram from shared buffer
* IN:		d0.l, size in bytes
* OUT:		d0.l, new address or 0 if error
* TRASHED:	d0-d1/a0-a1
*****************************************************************************
	
	xdef	FW_Mem_Alloc_Chip
FW_Mem_Alloc_Chip:
	lea	FW_Mem_Chip(pc),a0
	bra.s	FW_Mem_Alloc


*****************************************************************************
* Allocates public ram from shared buffer
* IN:		d0.l, size in bytes
* OUT:		d0.l, new address or 0 if error
* TRASHED:	d0-d1/a0-a1
*****************************************************************************
	
	xdef	FW_Mem_Alloc_Public
FW_Mem_Alloc_Public:
	lea	FW_Mem_Public(pc),a0
	bra.s	FW_Mem_Alloc


*****************************************************************************
* Allocates ram from structure in a0 (chip or public buffer)
* IN:		a0, memory structure (FW_Mem_Chip or FW_Mem_Public)
*		d0.l, size in bytes
* OUT:		d0.l, new address or 0 if error
* TRASHED:	d0-d1/a1
*****************************************************************************

FW_Mem_Alloc:
	;Don't allow odd number allocation so everything stays even
	addq.l	#1,d0
	moveq	#-2,d1
	and.w	d1,d0

	;Alloc is different depending on forward or reverse
	tst.w	FW_MEM_DIRECTION(a0)
	bmi.s	.reverse
.forward:
	;current ptr is the next new address
	move.l	FW_MEM_CURRENT(a0),a1	;save ptr
	move.l	d0,d1			;save size for checking overrun
	move.l	a1,d0			;return address (assuming no error)
	add.l	d1,a1			;new ptr
	cmp.l	FW_MEM_END(a0),a1
	bgt.s	.error			;overrun

	move.l	a1,FW_MEM_CURRENT(a0)	;save new ptr
	rts

.reverse:
	;current ptr is the previous address
	move.l	FW_MEM_CURRENT(a0),a1	;save ptr
	sub.l	d0,a1			;new ptr

	cmp.l	FW_MEM_START(a0),a1
	blt.s	.error

	move.l	a1,FW_MEM_CURRENT(a0)	;save new ptr
	move.l	a1,d0			;return address

	rts

.error:
	ifne FW_ALLOCMEM_CHECK
		move.w	#$ff0,_custom+color00
		bra.s	.error
	else
		moveq	#0,d0
	endif

	rts


*****************************************************************************
* Frees all chip memory and switches back to default forward mode.
* IN:		
* OUT:		
* TRASHED:	a0
*****************************************************************************
	
	xdef	FW_Mem_Free_Chip
FW_Mem_Free_Chip:
	lea	FW_Mem_Chip(pc),a0
	bra.s	FW_Mem_Free


*****************************************************************************
* Frees all public memory and switches back to default forward mode.
* IN:		
* OUT:		
* TRASHED:	a0
*****************************************************************************
	
	xdef	FW_Mem_Free_Public
FW_Mem_Free_Public:
	lea	FW_Mem_Chip(pc),a0
	bra.s	FW_Mem_Free


*****************************************************************************
* Frees all memory and switches back to default forward mode.
* IN:		a0, memory structure (FW_Mem_Chip or FW_Mem_Public)
* OUT:		
* TRASHED:	-
*****************************************************************************
	
FW_Mem_Free:
	move.l	FW_MEM_START(a0),FW_MEM_CURRENT(a0)
	move.w	#1,FW_MEM_DIRECTION(a0)

	rts


*****************************************************************************
* Switches to allocate memory from start/end of buffer. Used for switching between
* effects. Need to make sure you have a big enough shared buffer to accomodate both
* effects. Allocate critical memory first (copper lists, data, bitmaps last)
* IN:
* OUT:		
* TRASHED:	a0
*****************************************************************************
	
	xdef	FW_Mem_NewEffect_Chip
FW_Mem_NewEffect_Chip:
	lea	FW_Mem_Chip(pc),a0
	bra.s	FW_Mem_NewEffect

	rts


*****************************************************************************
* Switches to allocate memory from start/end of buffer. Used for switching between
* effects. Need to make sure you have a big enough shared buffer to accomodate both
* effects. Allocate critical memory first (copper lists, data, bitmaps last)
* IN:
* OUT:		
* TRASHED:	a0
*****************************************************************************

	xdef	FW_Mem_NewEffect_Public
FW_Mem_NewEffect_Public:
	lea	FW_Mem_Public(pc),a0
	bra.s	FW_Mem_NewEffect

	rts


*****************************************************************************
* Switches to allocate memory from start/end of buffer. Used for switching between
* effects. Need to make sure you have a big enough shared buffer to accomodate both
* effects. Allocate critical memory first (copper lists, data, bitmaps last)
* IN:		a0, memory structure (FW_Mem_Chip or FW_Mem_Public)
* OUT:		
* TRASHED:	-
*****************************************************************************
	
	xdef	FW_Mem_NewEffect
FW_Mem_NewEffect:
	tst.w	FW_MEM_DIRECTION(a0)
	bmi.s	FW_Mem_Free		;can reuse default mem free code to switch
	;rts
.forward:
	;Switch to backwards
	move.l	FW_MEM_END(a0),FW_MEM_CURRENT(a0)
	move.w	#-1,FW_MEM_DIRECTION(a0)

	rts


*****************************************************************************

	rsreset
FW_MEM_START		rs.l	1	;Start of memory range
FW_MEM_END		rs.l	1	;byte after end of memory range
FW_MEM_SIZE		rs.l	1	;size of memory block
FW_MEM_CURRENT		rs.l	1	;current address for next alloc
FW_MEM_DIRECTION	rs.w	1	;-1 reverse, +1 forwards

FW_Mem_Chip:	
	dc.l	FW_Chip_Buffer_1
	dc.l	FW_Chip_Buffer_1_End
	dc.l	FW_SHARED_CHIP_SIZE
	dc.l	FW_Chip_Buffer_1
	dc.w	1

FW_Mem_Public:
	dc.l	FW_Public_Buffer_1
	dc.l	FW_Public_Buffer_1_End
	dc.l	FW_SHARED_PUBLIC_SIZE
	dc.l	FW_Public_Buffer_1
	dc.w	1

*****************************************************************************

FW_GfxName:
	dc.b	"graphics.library",0,0

	;Topaz font stuff
	ifne FW_TOPAZ8
FW_TopazName:
	dc.b	'topaz.font',0,0

FW_Topaz_TextFont_Ptr:
	dc.l	0			;FW_TOPAZ_TEXTFONT_PTR

FW_Topaz_TextAttr:
	dc.l	0			;FW_TEXTATTR, APTR ta_Name
	dc.w	8			;ta_YSize
	dc.b	0			;ta_Style
	dc.b	0			;ta_Flags

	endif	;FW_TOPAZ8

*****************************************************************************

;Framework vars. Keep all the zero-inits together to make easier for exe packers.
;Could put in bss section but lots of framework code using FW_Vars(pc) so loses out
;eventually.

	rsreset
FW_GFXBASE		rs.l	1	;Address of Gfx Library
FW_GFXVIEW		rs.l	1	;Address of Old Viewport
FW_VBRPTR		rs.l	1	;0 or VBR on 68010+
FW_VEC_LEVEL1		rs.l	1
FW_VEC_LEVEL2		rs.l	1
FW_VEC_LEVEL3		rs.l	1
FW_VEC_LEVEL4		rs.l	1
FW_VEC_LEVEL5		rs.l	1
FW_VEC_LEVEL6		rs.l	1
FW_SYSDMACON		rs.w	1
FW_SYSADKCON		rs.w	1
FW_SYSINTENA		rs.w	1
FW_KICKSTART2ORLATER	rs.b	1	;0=1.2/1.3, $ff=KS2+
FW_AA_CHIPSET		rs.b	1	;0=ECS/OCS, $ff=AA
FW_MUSICINITIALISED	rs.b	1	;0=music not ready, $ff=music ready
FW_MUSICPLAYING		rs.b	1	;0=paused, $ff=play
FW_MASTERFRAMECOUNTER	rs.w	1	;Number of VBlank interrupts since startup (unsigned, 36mins demo timing)
	
	ifne FW_EXCEPTION_HANDLER
FW_VEC_BUSERR		rs.l	1
FW_VEC_ADDRERR		rs.l	1
FW_VEC_ILLEGAL		rs.l	1
FW_VEC_ZERODIV		rs.l	1
	endif

FW_ZERODATA_SIZE	rs.w	0	;size of all zeroed data - START OF NONZERO

FW_VARS_SIZEOF		rs.b	0

FW_Vars:
	dcb.b	FW_ZERODATA_SIZE,0	;Init all to zero by default
	;END FW_Vars


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss	;BSS section in Public memory (zeroed by OS)

*****************************************************************************

	xdef	FW_ClearBuffer_Zero13
FW_ClearBuffer_Zero13:	
	ds.l	13			;Buffer of zeros used for CPU clear, 13 long words

	xdef	FW_Public_Scratch_Long
FW_Public_Scratch_Long: 
	ds.l	1			;Public temp area

	xdef	FW_Quit_Flag
FW_Quit_Flag:	
	ds.w	1			;1=Quit

	ifne FW_PRECALC_LONG
	xdef	FW_Precalc_Progress
	xdef	FW_Precalc_Done
FW_Precalc_Progress:
	ds.w	1		;Percentage progress
FW_Precalc_Done:
	ds.w	1		;1 if precalc complete
	endif

*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_ChipData_Copper,data_c	;Chip Data Section for gfx/music

*****************************************************************************

FW_MemoryFetchMode	equ	0	;0,1 or 3 	
	
; Copper horizontal blanking notes from Photon/Scoopex
; Best practice is to start with DDF 38,d0 and DIW 2c81,2cc1 and modify these 
; symmetrically and always in whole 16px steps for compatibility.
; Note DDF start of less than 30 and you start to lose sprites.
; As established, positions $e7...$03 are not usable. If you're writing a simple 
; copperlist with no need for tight timing, positions $df and $07 are conventionally 
; used for the positions on either side of the horizontal blanking, and for 
; compatibility across chipsets use increments of 4 from these, resulting in 
; positions $db, $0b, and so on.

; The FW_CL sets the basic custom registers. It has bitplanes turned off.
; It is used during initial intro startup and shutdown and can also be 
; triggered between routines provide a safe transition screen.
FW_CL:
	;Trigger relevant interrupts if needed
	ifne FW_FRAME_IRQ_NEEDTRIG
		CMOVE	intreq,INTF_SETCLR|FW_FRAME_IRQ_TYPE
	endif

	CMOVE	fmode,FW_MemoryFetchMode	;Chip Ram fetch mode (0=OCS)
	
	CMOVE	beamcon0,$0020		;Pal mode ( $0000=NTSC )
	CMOVE 	diwstrt,$2c81
	CMOVE 	diwstop,$2cc1
	CMOVE 	ddfstrt,$0038
	CMOVE 	ddfstop,$00d0
	CMOVE 	bplcon0,$0200		;Bitplanes off
	CMOVE 	bplcon1,$0000
	CMOVE	bplcon2,$0000
	CMOVE	bplcon3,$0c00		;AGA compat, dual playfield related
	CMOVE	bplcon4,$0011
	CMOVE 	bpl1mod,0
	CMOVE 	bpl2mod,0

	CMOVE	dmacon,DMAF_SPRITE	;Disable sprite DMA

FW_CL_Blank:				;Ptr to empty CL
	COPPEREND


*****************************************************************************
*****************************************************************************
*****************************************************************************

	section	FW_ChipBss,bss_c	;bss Chip data section - screens etc

*****************************************************************************

	xdef	FW_Blank_Sprite
FW_Blank_Sprite:
	ds.l	1

; This is a scratch word that we use for bltdpth in blitter linedraws. The first
; pixel of a blitter linedraw is written to bltdpth. We use this quirk to reduce
; the line length by 1 which allows the object to be blitter filled correctly.
	xdef	FW_Chip_Scratch_Long
FW_Chip_Scratch_Long:
	ds.l	1

*****************************************************************************
