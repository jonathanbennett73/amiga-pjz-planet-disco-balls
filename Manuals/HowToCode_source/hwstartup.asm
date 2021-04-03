;
; input & display disabling startup code v1.0.2
;
; minimum requirements: 68000, OCS, Kickstart 1.2
; compiles with genam and phxass.
;
; Written by Harry Sintonen. Public Domain.
; thanks to _jackal & odin-_ for testing.
;

FROMC	EQU	0

	include "exec/types.i"
	include "exec/nodes.i"
	include "exec/ports.i"
	include "exec/lists.i"
	include "devices/input.i"
	include "devices/inputevent.i"
	include "graphics/gfxbase.i"
	include "dos/dosextens.i"
	include "dos/dos.i"

_LVODisable		EQU	-120
_LVOEnable		EQU	-126
_LVOForbid		EQU	-132
_LVOPermit		EQU	-138
_LVOFindTask		EQU	-294
_LVOAllocSignal		EQU	-330
_LVOFreeSignal		EQU	-336
_LVOGetMsg		EQU	-372
_LVOReplyMsg		EQU	-378
_LVOWaitPort		EQU	-384
_LVOCloseLibrary	EQU	-414
_LVOOpenDevice		EQU	-444
_LVOCloseDevice		EQU	-450
_LVODoIO		EQU	-456
_LVOOpenLibrary		EQU	-552

_LVOLoadView		EQU	-222
_LVOWaitBlit		EQU	-228
_LVOWaitTOF		EQU	-270

	IF	FROMC
	XREF	_main
	ENDC

_entry:
	movem.l	d0/a0,_args
	move.l	4.w,a6
	moveq	#RETURN_FAIL,d7

	; handle wb startup
	sub.l	a1,a1
	jsr	_LVOFindTask(a6)
	move.l	d0,a2
	tst.l	pr_CLI(a2)
	bne.s	.iscli
	lea	pr_MsgPort(a2),a0
	jsr	_LVOWaitPort(a6)
	lea	pr_MsgPort(a2),a0
	jsr	_LVOGetMsg(a6)
	move.l	d0,_WBenchMsg
.iscli:
	; init msgport
	moveq	#-1,d0
	jsr	_LVOAllocSignal(a6)
	move.b	d0,_sigbit
	bmi	.nosignal
	move.l	a2,_sigtask

	; hide possible requesters since user has no way to
	; see or close them.
	moveq	#-1,d0
	move.l	pr_WindowPtr(a2),_oldwinptr
	move.l	d0,pr_WindowPtr(a2)

	; open input.device
	lea	.inputname(pc),a0
	moveq	#0,d0
	moveq	#0,d1
	lea	_ioreq(pc),a1
	jsr	_LVOOpenDevice(a6)
	tst.b	d0
	bne	.noinput

	; install inputhandler
	lea	_ioreq(pc),a1
	move.w	#IND_ADDHANDLER,IO_COMMAND(a1)
	move.l	#_ih_is,IO_DATA(a1)
	jsr	_LVODoIO(a6)

	; open graphics.library
	lea	.gfxname(pc),a1
	moveq	#33,d0			; Kickstart 1.2 or higher
	jsr	_LVOOpenLibrary(a6)
	move.l	d0,_GfxBase
	beq	.nogfx
	move.l	d0,a6

	; save old view
	move.l	gb_ActiView(a6),_oldview

	; flush view
	sub.l	a1,a1
	jsr	_LVOLoadView(a6)
	jsr	_LVOWaitTOF(a6)
	jsr	_LVOWaitTOF(a6)

	; do the stuff
	movem.l	_args(pc),d0/a0
	bsr	_main
	move.l	d0,d7

	move.l	_GfxBase,a6

	; restore view & copper ptr
	sub.l	a1,a1
	jsr	_LVOLoadView(a6)
	move.l	_oldview(pc),a1
	jsr	_LVOLoadView(a6)
	move.l	gb_copinit(a6),$DFF080
	jsr	_LVOWaitTOF(a6)
	jsr	_LVOWaitTOF(a6)

	; close graphics.library
	move.l	a6,a1
	move.l	4.w,a6
	jsr	_LVOCloseLibrary(a6)

.nogfx:
	; remove inputhandler
	lea	_ioreq(pc),a1
	move.w	#IND_REMHANDLER,IO_COMMAND(a1)
	move.l	#_ih_is,IO_DATA(a1)
	jsr	_LVODoIO(a6)

	lea	_ioreq(pc),a1
	jsr	_LVOCloseDevice(a6)

.noinput:
	move.l	_sigtask(pc),a0
	move.l	_oldwinptr(pc),pr_WindowPtr(a0)

	moveq	#0,d0
	move.b	_sigbit(pc),d0
	jsr	_LVOFreeSignal(a6)

.nosignal:
	move.l	_WBenchMsg(pc),d0
	beq.s	.notwb
	move.l	a0,a1
	jsr	_LVOForbid(a6)
	jsr	_LVOReplyMsg(a6)

.notwb:
	move.l	d7,d0
	rts


.inputname:
	dc.b	'input.device',0
.gfxname:
	dc.b	'graphics.library',0


	CNOP	0,4

_args:
	dc.l	0,0
_oldwinptr:
	dc.l	0
_WBenchMsg:
	dc.l	0
_GfxBase:
	dc.l	0
_oldview:
	dc.l	0

_msgport:
	dc.l	0,0		; LN_SUCC, LN_PRED
	dc.b	NT_MSGPORT,0	; LN_TYPE, LN_PRI
	dc.l	0		; LN_NAME
	dc.b	PA_SIGNAL	; MP_FLAGS
_sigbit:
	dc.b	-1		; MP_SIGBIT
_sigtask:
	dc.l	0		; MP_SIGTASK
.head:
	dc.l	.tail		; MLH_HEAD
.tail:
	dc.l	0		; MLH_TAIL
	dc.l	.head		; MLH_TAILPRED

_ioreq:
	dc.l	0,0		; LN_SUCC, LN_PRED
	dc.b	NT_REPLYMSG,0	; LN_TYPE, LN_PRI
	dc.l	0		; LN_NAME
	dc.l	_msgport	; MN_REPLYPORT
	dc.w	IOSTD_SIZE	; MN_LENGTH
	dc.l	0		; IO_DEVICE
	dc.l	0		; IO_UNIT
	dc.w	0		; IO_COMMAND
	dc.b	0,0		; IO_FLAGS, IO_ERROR
	dc.l	0		; IO_ACTUAL
	dc.l	0		; IO_LENGTH
	dc.l	0		; IO_DATA
	dc.l	0		; IO_OFFSET

_ih_is:
	dc.l	0,0		; LN_SUCC, LN_PRED
	dc.b	NT_INTERRUPT,127	; LN_TYPE, LN_PRI ** highest priority ** 
	dc.l	.ih_name	; LN_NAME
	dc.l	0		; IS_DATA
	dc.l	.ih_code	; IS_CODE

.ih_code:
	move.l	a0,d0
.loop:
	move.b	#IECLASS_NULL,ie_Class(a0)
	move.l	(a0),a0
	move.l	a0,d1
	bne.b	.loop

	; d0 is the original a0
	rts

.ih_name:
	dc.b	'eat-events inputhandler',0

	CNOP	0,4

;
; _main can poke display registers and copper. all user input
; is swallowed, but task scheduling and system interrupts are
; running normally.
;
; _main MUST allocate further hardware resources it uses:
; blitter, audio, potgo, cia registers (timers, mouse &
; joystick). do not make any assumptations about the initial
; value of any hardware register.
;
; if full interrupt control is desired, _main must _LVODisable,
; save intenar and disable all interrupts by writing $7fff to
; intena. to restore, write $7fff to intena, or $8000 to saved
; intenar value and write it to intena, and finally _LVOEnable.
;
; if dma register control is desired, the same procedure is
; required, but this time for dmaconr and dmacon.
;
; the code poking interrupt-vectors must be aware of 68010+ VBR
; register. interrupt code satisfying an interrupt request must
; write the intreq and 'nop' to avoid problems with fast 040 and
; 060 systems.
;
; selfmodifying code must be aware of 020/030 and 040 caches
; (040 cacheflush handles 060 too).
;

	IF	FROMC

	XDEF	_WBenchMsg

	ELSE

;
;  in: a0.l  UBYTE *argstr
;      d0.l  LONG   arglen
; out: d0.l  LONG   returncode
;
_main:
	move.l	#2000000-1,d0
.delay:
	move.w	d0,$dff180
	subq.l	#1,d0
	bne.b	.delay

	moveq	#RETURN_OK,d0
	rts

	ENDC
