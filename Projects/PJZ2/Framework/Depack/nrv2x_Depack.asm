
; nrv2x decoder in pure 68k asm for Rygar AGA

; On entry:
;	a0	buffer start
;	d0	offset inside buffer for packed data

; On exit:
;	buffer filled with unpacked data
;	all registers preserved

nrv2x_decoder:
		movem.l	d0-d5/a0-a4,-(sp)

		move.l	d0,d3
		lea	(a0),a1
		adda.l	d0,a0

; common setup
		moveq	#-$80,d0
		moveq	#-1,d2
		moveq	#2,d4
		moveq	#-2,d5

; select between s/r algorithms
		tst.l	d3
		beq.w	nrv2r_unpack


; nrv2s decompression in pure 68k asm
; by ross
;
; On entry:
;	a0	src packed data pointer
;	a1	dest pointer
; (decompress from a0 to a1)
;
; On exit:
;	a0 = dest start
;	a1 = dest end
;
; Register usage:
;	a2	m_pos
;	a3	constant: -$d00
;	a4	2nd src pointer (in stack)
;
;	d0	bit buffer
;	d1	m_off
;	d2	m_len or -1
;
;	d3	last_m_off
;	d4	constant: 2
;	d5	reserved space on stack (max 256)
;
;
; Notes:
;	we have max_offset = 2^23, so we can use some word arithmetics on d1
;	we have max_match = 65535, so we can use word arithmetics on d2
;

nrv2s_unpack
;		movem.l	d0-d5/a1-a4,-(sp)

		move.b	(a0)+,d1				; ~stack usage
;		moveq	#-2,d5
		and.b	d1,d5
		lea	(sp),a4
		adda.l	d5,sp					; reserve space
._stk	move.b	(a0)+,-(a4)
		addq.b	#1,d1
		bne.b	._stk

; ------------- setup constants -----------

;		moveq	#-$80,d0				; d0.b = $80 (byte refill flag)
;		moveq	#-1,d2
		moveq	#-1,d3					; last_off = -1
;		moveq	#2,d4
		movea.w	#-$d00,a3

; ------------- DECOMPRESSION -------------

.decompr_literal
		move.b	(a0)+,(a1)+

.decompr_loop
		add.b	d0,d0
		bcc.b	.decompr_match
		bne.b	.decompr_literal
		move.b	(a0)+,d0
		addx.b	d0,d0
		bcs.b	.decompr_literal

.decompr_match
		moveq	#-2,d1
.decompr_gamma_1
		add.b	d0,d0
		bne.b	._g_1
		move.b	(a0)+,d0
		addx.b	d0,d0
._g_1	addx.w	d1,d1					; max 2^23!

		add.b	d0,d0
		bcc.b	.decompr_gamma_1
		bne.b	.decompr_select
		move.b	(a0)+,d0
		addx.b	d0,d0
		bcc.b	.decompr_gamma_1

.decompr_select
		addq.w	#3,d1
		beq.b	.decompr_get_mlen		; last m_off
		bpl.b	.decompr_exit_token
		lsl.l	#8,d1
		move.b	(a0)+,d1
		move.l	d1,d3					; last_m_off = m_off

.decompr_get_mlen						; implicit d2 = -1
		add.b	d0,d0
		bne.b	._e_1
		move.b	(a0)+,d0
		addx.b	d0,d0

._e_1	addx.w	d2,d2
		add.b	d0,d0
		bne.b	._e_2
		move.b	(a0)+,d0
		addx.b	d0,d0

._e_2	addx.w	d2,d2

		lea		(a1,d3.l),a2
		addq.w	#2,d2
		bgt.b 	.decompr_gamma_2  

.decompr_tiny_mlen
		move.l	d3,d1
		sub.l	a3,d1
		addx.w	d4,d2

.L_copy2	move.b	(a2)+,(a1)+
.L_copy1	move.b	(a2)+,(a1)+
		dbra	d2,.L_copy1
.L_rep	bra.b	.decompr_loop

.decompr_gamma_2							; implicit d2 = 1
		add.b	d0,d0
		bne.b	._g_2
		move.b	(a0)+,d0
		addx.b	d0,d0
._g_2	addx.w  d2,d2
		add.b	d0,d0
		bcc.b	.decompr_gamma_2
		bne.b	.decompr_large_mlen
		move.b	(a0)+,d0
		addx.b	d0,d0
		bcc.b	.decompr_gamma_2

.decompr_large_mlen
		move.b	(a2)+,(a1)+
		move.b	(a2)+,(a1)+
		cmp.l   a3,d3
		bcs.b   .L_copy2
		move.b	(a2)+,(a1)+
		dbra	d2,.L_copy1

.decompr_exit_token
		lea	(a4),a0
		bclr	d2,d2					; ;)
		bne.b	.L_rep
		
		bra.w	_common_exit
;		suba.l  d5,sp
;		movem.l	(sp)+,d0-d5/a0-a4
;		rts
		
		
; nrv2r decompression in 68000 assembly
; by ross
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
;		movem.l	d0-d5/a0/a2-a4,-(sp)

;		lea	(a0),a1						; if (a1) lea (a0),a4
		adda.l	(a0),a0					; end of packed data
		move.l	-(a0),(a1)				; if (a1) move.l -(a0),(a4)
		adda.l	-(a0),a1				; end of buffer
		
		move.b	-(a0),d1				; ~stack usage
;		moveq	#-2,d5
		and.b	d1,d5
		adda.l	d5,sp					; reserve space
		lea	(sp),a4
._stk	move.b	-(a0),(a4)+
		addq.b	#1,d1
		bne.b	._stk

; ------------- setup constants -----------

;		moveq	#-$80,d0				; d0.b = $80 (byte refill flag)
;		moveq	#-1,d2
;		moveq	#0,d3					; last_off = 0(1)
;		moveq	#2,d4
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
._g_1	addx.w	d1,d1					; max 2^23!

		add.b	d0,d0
		bcc.b	.decompr_gamma_1
		bne.b	.decompr_select
		move.b	-(a0),d0
		addx.b	d0,d0
		bcc.b	.decompr_gamma_1

.decompr_select
		subq.w	#3,d1
		bcs.b	.decompr_get_mlen		; last m_off
		bmi.b	.decompr_exit_token
		lsl.l	#8,d1
		move.b	-(a0),d1
		move.l	d1,d3					; last_m_off = m_off

.decompr_get_mlen						; implicit d2 = -1
		add.b	d0,d0
		bne.b	._e_1
		move.b	-(a0),d0
		addx.b	d0,d0

._e_1	addx.w	d2,d2
		add.b	d0,d0
		bne.b	._e_2
		move.b	-(a0),d0
		addx.b	d0,d0

._e_2	addx.w	d2,d2

		lea		1(a1,d3.l),a2
		addq.w	#2,d2
		bgt.b 	.decompr_gamma_2  

.decompr_tiny_mlen
		move.l	a3,d1
		sub.l	d3,d1
		addx.w	d4,d2

.L_copy2	move.b	-(a2),-(a1)
.L_copy1	move.b	-(a2),-(a1)
		dbra	d2,.L_copy1
.L_rep	bra.b	.decompr_loop

.decompr_gamma_2							; implicit d2 = 1
		add.b	d0,d0
		bne.b	._g_2
		move.b	-(a0),d0
		addx.b	d0,d0
._g_2	addx.w  d2,d2
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
		
_common_exit
		suba.l  d5,sp
		movem.l	(sp)+,d0-d5/a0-a4
		rts
