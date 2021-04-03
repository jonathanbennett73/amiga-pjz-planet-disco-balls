; nrv2r decompression in 68000 assembly
; by ross
;
; They are both in-place, but differ in the memory layout:
; - forward in memory (nrv2s, standard) : slightly faster, but requires data to be loaded at the end of the buffer
; - backward in memory (nrv2r, reverse), slightly slower, usually compresses a few bytes better and allows data to be loaded at the beginning of the buffer (therefore d0 can be set = 0).
;
; Call the command line help for the packer, it indicates the parameters to be used.
; You will see that if you use the forward mode it give to you the value to be entered in d0 to load the file in the final part of the buffer.
;
; On entry:
;	a0	src pointer
;	[a1	dest pointer]
; (decompress also to a1=a0)
;
; On exit:
;	all preserved but
;	a1 = dest start
;
; Register usage:
;	a2	m_pos
;	a3	constant: $cff
;	a4	2nd src pointer (in stack)
;
;	d0	bit buffer
;	d1	m_off
;	d2	m_len or -1
;
;	d3	last_m_off
;	d4	constant: 2
;	d5	reserved space on stack
;
;
; Notes:
;	we have max_offset = 2^23, so we can use some word arithmetics on d1
;	we have max_match = 65535, so we can use word arithmetics on d2
;

nrv2r_unpack
		movem.l	d0-d5/a0-a4,-(sp)

;Antiriad: I added this to allow for inplace vs src to dest easily.
		cmp.l	a0,a1
		beq.s	.inplace
.srctodest:
		lea	(a0),a4
		adda.l	(a0),a0					; end of packed data
		move.l	-(a0),(a4)
		bra.s	.start
.inplace:
		move.l	(a0),d0
		adda.l	(a0),a0					; end of packed data
		move.l	-(a0),(a1)				; if (a1) move.l -(a0),(a4)
.start:
; -- End: Antiriad
		adda.l	-(a0),a1				; end of buffer
		
		move.b	-(a0),d1				; ~stack usage
		moveq	#-2,d5
		and.b	d1,d5
		adda.l	d5,sp					; reserve space
		lea	(sp),a4
.stk		move.b	-(a0),(a4)+
		addq.b	#1,d1
		bne.b	.stk

; ------------- setup constants -----------

		moveq	#-$80,d0				; d0.b = $80 (byte refill flag)
		moveq	#-1,d2
		moveq	#0,d3					; last_off = 0(1)
		moveq	#2,d4
		movea.w	#$cff,a3

; ------------- DECOMPRESSION -------------

.decompr_literal
		move.b	-(a0),-(a1)

.decompr_loop
		add.b	d0,d0
		bcc.b	.decompr_match
		bne.b	.decompr_literal
		move.b	-(a0),d0
		addx.b	d0,d0
		bcs.b	.decompr_literal

.decompr_match
		moveq	#1,d1
.decompr_gamma_1
		add.b	d0,d0
		bne.b	._g_1
		move.b	-(a0),d0
		addx.b	d0,d0
._g_1		addx.w	d1,d1					; max 2^23!

		add.b	d0,d0
		bcc.b	.decompr_gamma_1
		bne.b	.decompr_select
		move.b	-(a0),d0
		addx.b	d0,d0
		bcc.b	.decompr_gamma_1

.decompr_select
		subq.w	#3,d1
		bcs.b	.decompr_get_mlen			; last m_off
		bmi.b	.decompr_exit_token
		lsl.l	#8,d1
		move.b	-(a0),d1
		move.l	d1,d3					; last_m_off = m_off

.decompr_get_mlen						; implicit d2 = -1
		add.b	d0,d0
		bne.b	._e_1
		move.b	-(a0),d0
		addx.b	d0,d0

._e_1		addx.w	d2,d2
		add.b	d0,d0
		bne.b	._e_2
		move.b	-(a0),d0
		addx.b	d0,d0

._e_2		addx.w	d2,d2

		lea	1(a1,d3.l),a2
		addq.w	#2,d2
		bgt.b 	.decompr_gamma_2  

.decompr_tiny_mlen
		move.l	a3,d1
		sub.l	d3,d1
		addx.w	d4,d2

.L_copy2	move.b	-(a2),-(a1)
.L_copy1	move.b	-(a2),-(a1)
		dbra	d2,.L_copy1
.L_rep		bra.b	.decompr_loop

.decompr_gamma_2						; implicit d2 = 1
		add.b	d0,d0
		bne.b	._g_2
		move.b	-(a0),d0
		addx.b	d0,d0
._g_2		addx.w  d2,d2
		add.b	d0,d0
		bcc.b	.decompr_gamma_2
		bne.b	.decompr_large_mlen
		move.b	-(a0),d0
		addx.b	d0,d0
		bcc.b	.decompr_gamma_2

.decompr_large_mlen
		move.b	-(a2),-(a1)
		move.b	-(a2),-(a1)
		cmpa.l   d3,a3
		bcs.b   .L_copy2
		move.b	-(a2),-(a1)
		dbra	d2,.L_copy1

.decompr_exit_token
		lea	(a4),a0
		bclr	d2,d2					; ;)
		bne.b	.L_rep
		
		suba.l  d5,sp
		movem.l	(sp)+,d0-d5/a0-a4
		rts
