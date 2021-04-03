	IFND _OBJ_ICOSAHEDRON20
_OBJ_ICOSAHEDRON20 SET 1
	ELSE
_OBJ_ICOSAHEDRON20 SET _OBJ_ICOSAHEDRON20+1
	ENDC

;Glenz vectors
;3 bitplanes
;
; color01 := $eef = off white    
; color02 := $306 = dark blue
; color05 := $fff = pure white    
; color06 := $63d = light blue    
;
;Front white face:
; overlapping with back transparent faces is off white   - color01  bpl 1 0 0
; overlapping with back white face is pure white         - color05  bpl 1 0 1
; DRAW ON BPL 1 (color01)
;
;Back white face
; overlapping with front transparent face is light blue  - color06  bpl 0 1 1
; overlapping with front white face is pure white        - color05  bpl 1 0 1
; DRAW ON BPL 3 (color04)
;
;Front transparent face: = 0 1 0 = 2
; overlapping back transparent is dark blue              - color02  bpl 0 1 0
; overlapping back white face is light blue              - color06  bpl 0 1 1
; DRAW ON BPL 2 (color02)
;
;Back transparent face: = 0 0 0 = 0
; overlapping front transparent is dark blue             - color02  bpl 0 1 0
; overlapping front white faceis off white               - color01  bpl 1 0 0
; DON'T DRAW

;Use color 1 (white), 2 (trans) for visible faces
;Use color 4 (undefined), 0 for back faces

;This means that each face is actually drawn on ONE bitplane.

;My vector routine allows a different colour to be set for front/back faces
;instead of just culling. Makes it easy to turn it into a glenz routine.

;80 pt at 192width, z pos = -6 without clipping
;80 pt at 224 width, z pos = -37 without clipping 
;85 pt at 224 width,  z pos = -37 without clipping 
OBJ_ICOSAHEDRON20_NUMPTS = 12
Obj_Icosahedron20_Info:
	dc.w	0			; initialised (happens on first load)
	dc.w	0,0,0			; pos, x,y,z
	dc.w	0,0,0			; current rotation, x,y,z
	dc.w	0,0,0			; Rotation step, x,y,z
	dc.w	0			; Complex 1/0
	dc.w	1			; Num frames max
	dc.l	Obj_Icosahedron20_PtsBuffer	; 22 - Pts ptr (in use/buffer)
	dc.l	Obj_Icosahedron20_Pts_Classic	; 26 - Initial points ptr
	dc.l	Obj_Icosahedron20_Facelist	; 30 - Facelist ptr
	dc.w	0,0,0			; Morph active flag, counter, speed

; Points are loaded to here from Obj_Icosahedron20_Pts. So can do transforms without
; trashing original points.
Obj_Icosahedron20_PtsBuffer:
	ds.w	1
	ds.w	3*OBJ_ICOSAHEDRON20_NUMPTS

;(0, 1, ϕ)
;(0, -1, ϕ)
;(0, 1, -ϕ)
;(0, -1, -ϕ)

;(ϕ, 0, 1)
;(-ϕ, 0, 1)
;(ϕ, 0, -1)
;(-ϕ, 0, -1)

;(1, ϕ, 0 )
;(-1, ϕ, 0 )
;(1, -ϕ, 0 )
;(-1, -ϕ, 0 )

;1
;ϕ = 1.618
;p1 set 400
;p2 set 650
p1 set 56
p2 set 90

Obj_Icosahedron20_Pts_Classic:
	dc.w	OBJ_ICOSAHEDRON20_NUMPTS

	dc.w	-p1,p2,0		;0
	dc.w	p1,p2,0			;1
	dc.w	p1,-p2,0		;2
	dc.w	-p1,-p2,0		;3

	dc.w	0,p1,p2			;4
	dc.w	0,p1,-p2		;5
	dc.w	0,-p1,-p2		;6
	dc.w	0,-p1,p2		;7

	dc.w	-p2,0,p1		;8
	dc.w	p2,0,p1			;9
	dc.w	p2,0,-p1		;10
	dc.w	-p2,0,-p1		;11


Obj_Icosahedron20_Facelist:
	dc.w	20
	dc.l	Obj_Icosahedron20_f1
	dc.l	Obj_Icosahedron20_f2
	dc.l	Obj_Icosahedron20_f3
	dc.l	Obj_Icosahedron20_f4
	dc.l	Obj_Icosahedron20_f5
	dc.l	Obj_Icosahedron20_f6
	dc.l	Obj_Icosahedron20_f7
	dc.l	Obj_Icosahedron20_f8
	dc.l	Obj_Icosahedron20_f9
	dc.l	Obj_Icosahedron20_f10
	dc.l	Obj_Icosahedron20_f11
	dc.l	Obj_Icosahedron20_f12
	dc.l	Obj_Icosahedron20_f13
	dc.l	Obj_Icosahedron20_f14
	dc.l	Obj_Icosahedron20_f15
	dc.l	Obj_Icosahedron20_f16
	dc.l	Obj_Icosahedron20_f17
	dc.l	Obj_Icosahedron20_f18
	dc.l	Obj_Icosahedron20_f19
	dc.l	Obj_Icosahedron20_f20

; Connections should be defined in as if you were facing that side in clockwise order
Obj_Icosahedron20_f1:
	VEC_FACE	4,1,1,-1,-1
	VEC_VERTEX4	0,1,5,0

Obj_Icosahedron20_f18:
	VEC_FACE	4,1,1,-1,-1
	VEC_VERTEX4	7,3,2,7

Obj_Icosahedron20_f2:
	VEC_FACE	4,2,2,-1,-1
	VEC_VERTEX4	1,10,5,1

Obj_Icosahedron20_f19:
	VEC_FACE	4,2,2,-1,-1
	VEC_VERTEX4	8,3,7,8

Obj_Icosahedron20_f5:
	VEC_FACE	4,3,3,-1,-1
	VEC_VERTEX4	4,1,0,4

Obj_Icosahedron20_f14:
	VEC_FACE	4,3,3,-1,-1
	VEC_VERTEX4	6,2,3,6

Obj_Icosahedron20_f3:
	VEC_FACE	4,4,4,-1,-1
	VEC_VERTEX4	1,9,10,1

Obj_Icosahedron20_f20:
	VEC_FACE	4,4,4,-1,-1
	VEC_VERTEX4	8,11,3,8

Obj_Icosahedron20_f6:
	VEC_FACE	4,5,5,-1,-1
	VEC_VERTEX4	4,0,8,4

Obj_Icosahedron20_f15:
	VEC_FACE	4,5,5,-1,-1
	VEC_VERTEX4	6,10,2,6

Obj_Icosahedron20_f7:
	VEC_FACE	4,6,6,-1,-1
	VEC_VERTEX4	0,11,8,0

Obj_Icosahedron20_f16:
	VEC_FACE	4,6,6,-1,-1
	VEC_VERTEX4	10,9,2,10

Obj_Icosahedron20_f4:
	VEC_FACE	4,8,8,-1,-1
	VEC_VERTEX4	1,4,9,1

Obj_Icosahedron20_f13:
	VEC_FACE	4,8,8,-1,-1
	VEC_VERTEX4	11,6,3,11

Obj_Icosahedron20_f8:
	VEC_FACE	4,9,9,-1,-1
	VEC_VERTEX4	0,5,11,0

Obj_Icosahedron20_f17:
	VEC_FACE	4,9,9,-1,-1
	VEC_VERTEX4	9,7,2,9

Obj_Icosahedron20_f9:
	VEC_FACE	4,10,10,-1,-1
	VEC_VERTEX4	11,5,6,11

Obj_Icosahedron20_f11:
	VEC_FACE	4,10,10,-1,-1
	VEC_VERTEX4	4,7,9,4

Obj_Icosahedron20_f10:
	VEC_FACE	4,12,12,-1,-1
	VEC_VERTEX4	5,10,6,5

Obj_Icosahedron20_f12:
	VEC_FACE	4,12,12,-1,-1
	VEC_VERTEX4	4,8,7,4


