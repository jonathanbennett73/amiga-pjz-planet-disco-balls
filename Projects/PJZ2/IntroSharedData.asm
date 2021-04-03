
*****************************************************************************

; Name			: IntroSharedData.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Resources that need to be shared between parts.
;			  generally music files, screen buffers, and fonts.
; CPU Required		: MC68000 or better
; ChipSet Required	: OCS or better
				
*****************************************************************************


*****************************************************************************


	include "IntroConfig.i"
	include "Framework/CustomMacros.i"
	include "Framework/IntroLibrary.i"
	include "Framework/IntroLibrary_xref.i"


; Additional External symbols

; Include biggest data sections first so hunks are processed first.

*****************************************************************************

	section	FW_PublicCode,code	;Code section in Public memory

*****************************************************************************
* Does any shared data precalc at intro startup. For example generating a 
* multiply table in shared bss that may be used by multiple effects.
* IN:		a6, _custom
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

	xdef	SharedDataPreCalc_IntroStart
SharedDataPreCalc_IntroStart:

	movem.l	d2-d7/a2-a5,-(sp)

	lea	GenSin_Table_16384_2048W,a0
	jsr	LIB_GenSin_16384_2048W	;I:a0, T:d0-d1/a0-a1

	movem.l	(sp)+,d2-d7/a2-a5
	rts


*****************************************************************************
*****************************************************************************
*****************************************************************************
	
	ifne	FW_SHARED_CHIP_SIZE
	section	FW_ChipBss,bss_c	;bss Chip data section - screens etc

*****************************************************************************

	xdef FW_Chip_Buffer_1
	xdef FW_Chip_Buffer_1_End
FW_Chip_Buffer_1:
	ds.b	FW_SHARED_CHIP_SIZE
FW_Chip_Buffer_1_End:

	endif	;FW_SHARED_CHIP_SIZE

*****************************************************************************
*****************************************************************************
*****************************************************************************

	ifne	FW_SHARED_PUBLIC_SIZE
	section	FW_PublicBss,bss

*****************************************************************************

	xdef FW_Public_Buffer_1
	xdef FW_Public_Buffer_1_End
FW_Public_Buffer_1:
	ds.b	FW_SHARED_PUBLIC_SIZE
FW_Public_Buffer_1_End:

	endif	;FW_SHARED_PUBLIC_SIZE


*****************************************************************************
*****************************************************************************
*****************************************************************************

;P61 Music
	ifeq FW_MUSIC_TYPE-1		;p61

	section	FW_PublicCode,code	;Player code part of IntroFramework

	xdef	P61_End
	xdef	P61_Init
	xdef	P61_VBR
	xdef	P61_Music
	xdef	P61_Play
	xdef	P61_E8
	xdef	P61_visuctr0
	xdef	P61_visuctr1
	xdef	P61_visuctr2
	xdef	P61_visuctr3

	ifeq FW_MUSIC_VBLANK-0
P61mode	equ 1	;1=cia, 2=vblank
	else
P61mode	equ 2	;1=cia, 2=vblank
	endif
usecode	set 0
visuctrs set 1

	include	"Assets/discotransmission.p61.i"

	include	"Framework/P61Settings.i"
	include	"Framework/MusicReplay/P6112-Play_hr.asm"	;Because of usecode have to include player here


	section	FW_PublicData_Music,data	;Music module (public data)
	xdef	P61Module
P61Module:
	incbin	"Assets/discotransmission.p61"


	section	FW_ChipData_Music,data_c	;Music samples (chip data)
	xdef	P61Samples
P61Samples:
	incbin	"Assets/discotransmission.p61.smp"

	endif				;Music p61

*****************************************************************************
*****************************************************************************

;PHX_PTReplay Music
	ifeq FW_MUSIC_TYPE-2
ENABLE_VUMETER equ 1

	xdef	PHXPT_Module
	xdef	PHXPT_Samples

	section	FW_PublicCode,code	;Player code part of IntroFramework
	include	"Framework/MusicReplay/PHX-PTPlayer/ptplayer_minimal.asm"

	;nosfx=7558 bytes
	;minimal=

	section	FW_PublicData_Music,data	;Music module (public data)
PHXPT_Module:
	incbin	"AssetsConverted/discotransmission.mod.trk"
	even

	ifne FW_MUSIC_AMIGAKLANG

	section	FW_ChipBss_Music,bss_c	;Music buffers (chip data)
	include "AssetsConverted/discotransmission.mod.i"
PHXPT_Samples:
	ds.b	SPLITMOD_SMP_SIZE			;As per amigaklang gui or .smp file size
	even

	else

	section	FW_ChipData_Music,data_c	;Music samples (chip data)
PHXPT_Samples:
	incbin	"AssetsConverted/discotransmission.mod.smp"
	
	endif	;FW_MUSIC_AMIGAKLANG

	; AmigaKlang precalc extras
	ifne FW_MUSIC_AMIGAKLANG
	xdef	AMIGAKLANG_Init
	xdef	AMIGAKLANG_Isamp
	xdef	AMIGAKLANG_Temp
	xdef	AMIGAKLANG_Progress

	section	FW_PublicCode,code	;Player code part of IntroFramework

AMIGAKLANG_Init:
	incbin	"Assets/discotransmission.akl.bin"
	even
AMIGAKLANG_Isamp:
	incbin	"Assets/discotransmission.akl.raw"
	even	
AMIGAKLANG_Progress:
	ds.l	1	;Precalc progress - top byte is sample number
					
	endif				;AFW_MUSIC_AMIGAKLANG

	endif				;Music phx_ptreplay

*****************************************************************************
*****************************************************************************

;PRT music
	ifeq FW_MUSIC_TYPE-3		;prt

	xdef	prtPlayer
	xdef	prtSong
	xdef	prtSongBuf
	xdef	prtPlayerBuf
	xdef	prtChipBuf

	section	FW_PublicCode,code	;Player code part of IntroFramework

prtPlayer:
	incbin "Framework/MusicReplay/PreTracker_Replayer.bin"
	even

	section	FW_PublicData_Music,data	;Music module (public data)

prtSong:
	incbin "Assets/tsm-suntr.prt"
	even

	section	FW_PublicBss_Music,bss

prtSongBuf:	ds.w	16*1024/2	;16kb
prtPlayerBuf:	ds.l	16*1024/4	;16kb

	section	FW_ChipBss_Music,bss_c	;Data buffers (chip data)

prtChipBuf:
	;NOTE: This size must be larger than what is shown in pretracker UI
	;for required chipmem
	ds.b	48*1024			;48KB

	endif				;prt


*****************************************************************************
*****************************************************************************

	section	FW_PublicBss,bss

	xdef	GenSin_Table_16384_2048W
GenSin_Table_16384_2048W:
	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS/4
	ds.w	LIB_GENSIN_16384_2048W_NUMWORDS


*****************************************************************************
*****************************************************************************

	section	FW_PublicData,data	;Code section in Public memory

	;Sprite data is in kingcon format. We are using 32px wide ANIM sprites so the format is:
	;dc.w	offset-spr0-frame0,offset-spr1-frame0
	;dc.w	offset-spr0-frame1,offset-spr1-frame1
	;The add the offset and that will now be the correct sprite control words and data for that frame
	;each sprite ends with dc.w 0,0 "end of list" control words

	xdef	SPR_DiscoBall_A
SPR_DiscoBall_A:
	incbin "AssetsConverted/Disco_Sprite_32x32x2_4d_A_4frames.SPR"

	xdef	SPR_DiscoBall_B
SPR_DiscoBall_B:
	incbin "AssetsConverted/Disco_Sprite_32x32x2_4d_B_4frames.SPR"

	xdef	SPR_DiscoBall_C
SPR_DiscoBall_C:
	incbin "AssetsConverted/Disco_Sprite_32x32x2_4d_C_4frames.SPR"

*****************************************************************************

	EVEN
	xdef	BPL_Font8px_Source
BPL_Font8px_Source:
	incbin "../AssetsConverted/Greetz_Font_8x16x2.BPL"
	EVEN

; Font BOB structure and font ascii lookup, BOB and FAR in public
	xdef	BOB_Font8px
BOB_Font8px:
	include "../AssetsConverted/Greetz_Font_8x16x2.BOB_dcw.i"

	xdef	FAR_Font8px
FAR_Font8px:
	include "../AssetsConverted/Greetz_Font_8x16x2.FAR_dcb.i"

*****************************************************************************
*****************************************************************************
