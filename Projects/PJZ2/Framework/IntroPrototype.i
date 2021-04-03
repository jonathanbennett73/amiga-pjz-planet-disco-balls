	ifnd _FRAMEWORKPROTOTYPE_I
_FRAMEWORKPROTOTYPE_I set 1

*****************************************************************************

; Name			: IntroLibrary.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Shared library structures.
; Date last edited	: 24/05/2019
				
*****************************************************************************
*****************************************************************************

;Linedraw variable structure
	rsreset
PRO_LINE_COLOR:		rs.w 1			;Color of lines
PRO_LINE_CLIP_MINX	rs.w 1
PRO_LINE_CLIP_MINY	rs.w 1
PRO_LINE_CLIP_MAXX	rs.w 1
PRO_LINE_CLIP_MAXY	rs.w 1
PRO_LINE_TEXTURE	rs.w 1
PRO_LINE_MOD_LINE	rs.w 1
PRO_LINE_MOD_BPL	rs.w 1

*****************************************************************************

;BOB Draw structure
	rsreset
PRO_BOB_MOD_LINE	rs.w 1
PRO_BOB_BLTFWM		rs.w 1
PRO_BOB_BLTLWM		rs.w 1
PRO_BOB_BLTCMOD		rs.w 1
PRO_BOB_BLTBMOD		rs.w 1
PRO_BOB_BLTAMOD		rs.w 1
PRO_BOB_BLTDMOD		rs.w 1
PRO_BOB_BLTSIZE		rs.w 1

*****************************************************************************

	endif				; _FRAMEWORKPROTOTYPE_I