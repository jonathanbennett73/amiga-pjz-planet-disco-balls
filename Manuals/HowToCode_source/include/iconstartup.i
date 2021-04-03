;
; Iconstartup.i
;
; include this to allow startup from icon.
; Just code the rest of your program as if you were writing for CLI.
;
; You should also add these lines to your code:
;
;	include "exec/exec_lib.i"
;	include	"exec/exec.i"
;	include	"libraries/dosextens.i
;
; or similar code for your assembler...
;
; If your assembler won't assemble this, throw it away and buy
; the excellent HISOFT DEVPAC 3.0 from Hisoft Software.


	movem.l	d0/a0,-(sp)

	sub.l	a1,a1
	move.l  4.w,a6
	jsr	_LVOFindTask(a6)

; Could use ThisTask(a6) here, but we won't. The general rule
; is that if there is a system function to read a structure, use
; that rather than peeking the structure directly. This gives
; Commodore greater freedom to change things in the future...

	move.l	d0,a4

	tst.l	pr_CLI(a4)	; was it called from CLI?
	bne.s   fromCLI		; if so, skip out this bit...

	lea	pr_MsgPort(a4),a0
	move.l  4.w,a6
	jsr	_LVOWaitPort(A6)
	lea	pr_MsgPort(a4),a0
	jsr	_LVOGetMsg(A6)
	move.l	d0,returnMsg

fromCLI
	movem.l	(sp)+,d0/a0

go_program


	bsr.s	_main           	; Calls your code..

; If your code does not allow exit, the following lines are
; not required

	move.l	d0,-(sp)

	tst.l	returnMsg		; Is there a message?
	beq.s	exitToDOS		; if not, skip...

	move.l	4.w,a6
        jsr	_LVOForbid(a6)          ; note! No Permit needed!

	move.l	returnMsg(pc),a1
	jsr	_LVOReplyMsg(a6)

exitToDOS
	move.l	(sp)+,d0		; exit code
	rts

; These next lines are required whether you want to exit or not!


returnMsg dc.l	0

	even				;(or cnop 0,2)
_main
