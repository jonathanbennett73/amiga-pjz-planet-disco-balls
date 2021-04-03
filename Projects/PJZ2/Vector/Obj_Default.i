	IFND _OBJ_DEFAULT
_OBJ_DEFAULT SET 1
	ELSE
_OBJ_DEFAULT SET _OBJ_DEFAULT+1
	ENDC


OBJ_DEFAULT_NUMPTS = 4
Obj_Default_Info:
	dc.w	0			; initialised (happens on first load)
	dc.w	0,0,0			; pos, x,y,z
	dc.w	0,0,0			; current rotation, x,y,z
	dc.w	0,1,0			; Rotation step, x,y,z
	dc.w	0			; Complex 1/0
	dc.w	1			; Num frames min
	dc.l	Obj_Default_PtsBuffer	; Pts ptr (in use/buffer)
	dc.l	Obj_Default_Pts		; Initial points ptr
	dc.l	Obj_Default_Facelist	; Facelist ptr
	dc.w	0,0,0			; Morph active flag, counter, speed

; Points are loaded to here from Ob1_Pts. So can do transforms without
; trashing original points.
Obj_Default_PtsBuffer:
	ds.w	1
	ds.w	3*OBJ_DEFAULT_NUMPTS

Obj_Default_Pts:
	dc.w	OBJ_DEFAULT_NUMPTS
	dc.w -50,50,-50		;0	;LHS
	dc.w 50,50,-50		;1
	dc.w 50,-50,-50		;2
	dc.w -50,-50,-50		;3

;	dc.w -50,50,50		;0	;RHS
;	dc.w 50,50,50		;1
;	dc.w 50,-50,50		;2
;	dc.w -50,-50,50		;3

Obj_Default_Facelist:
	dc.w	1
	dc.l	Obj_Default_f1

Obj_Default_f1		;single plane
	VEC_FACE	5,1,1,1,1
	VEC_VERTEX5	0,1,2,3,0

