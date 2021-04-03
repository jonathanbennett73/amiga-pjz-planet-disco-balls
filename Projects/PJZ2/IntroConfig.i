	ifnd _INTROCONFIG_I
_INTROCONFIG_I set 1

*****************************************************************************

; Name			: IntroConfig.i
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Global config.
				
*****************************************************************************

	;include "IntroFramework.i"

*****************************************************************************

; Configure things that control how the framework is setup.

FW_PRECALC_LONG		equ	1	;Do we use a long precalc routine?
FW_RMB_QUIT_SECTION	equ	0	;Allow right mouse to quit section?
FW_EXCEPTION_HANDLER	equ	0	;Enable exception handlers
FW_ALLOCMEM_CHECK	equ	1	;Yellow screen if memory overallocated
FW_TOPAZ8		equ	0	;Make topaz8 functions available?
PRO_ENABLE		equ	0	;Enable prototyping libs (unoptimized but safe functions)

; Cause WinUAE breakpoint on calling FW_IsFrameOver and FW_GetFrame
; (enter "w 4 4 4 w" in the debugger to catch)
FW_GETFRAME_BREAKPOINT	equ	0

*****************************************************************************

; Shared memory areas - must be large enough to be used in all intro parts

; Alloc enough memory for all parts plus 8KB overlap buffer for copperlists
FW_SHARED_CHIP_SIZE	equ	(94+8)*1024	;~320 is max on 512/512 config and cold boot

;Amigaklang needs 65536 bytes, the framework will use the last 65536 bytes
;of the public buffer during FW_MusicInit so make sure you have a big enough public buffer
;here if you are sharing this buffer during precalc/FW_MusicInit code.
FW_SHARED_PUBLIC_SIZE	equ	64*1024

*****************************************************************************

; Music player type and timing

FW_MUSIC_TYPE		equ	2	;0=none,1=p61,2=phx_ptreplay,3=prt	
FW_MUSIC_AMIGAKLANG	set	1	;0=no klang,1=amigaklang (phx_ptreplay only)
FW_MUSIC_VBLANK		set	0	;0=CIA,1=VBlank

; Configure variables based on choice
	ifeq FW_MUSIC_TYPE
FW_MUSIC_VBLANK set 0			; Save CPU in FW_VblankProxy if no music
	endif

	ifne FW_MUSIC_TYPE-2
FW_MUSIC_AMIGAKLANG set	0		;Amigaklang only valid with PHXPT
	endif

	ifeq FW_MUSIC_TYPE-2
FW_MUSIC_VBLANK set 0			; PHXPT only uses CIA
	endif

	ifeq FW_MUSIC_TYPE-3
FW_MUSIC_VBLANK set 1			; PRT only uses VBlank
	endif


*****************************************************************************

; Enable LIB functions (reduce size by commenting out unused)

LIB_ENABLE_RGB12_LERP		equ	1	;RBG12 interpolation (fast color fades etc)
;LIB_ENABLE_SIN_Q14		equ	1	;Q14 SIN/COS table (3d vector tables)
;LIB_ENABLE_SIN_Q15		equ	1	;Q15 SIN/COS table (3d vector tables)
LIB_ENABLE_SQRT			equ	1	;Square root functions
;LIB_ENABLE_BLT_FILL_GEN		equ	1	;Blitter fill sillouette generation
LIB_ENABLE_GENSINE_2048		equ	1	;Sine generation functions

;Compression libraries
;Compression (best to worst): PKF,SHR,AM7,NRV2R,NRV2S,DOY,CRA,LZ4
;Speed (quickest to slowest): LZ4,CRA,DOY,NRV2S,NRV2R,AM7,SHR,PKF
;Notes: nrv2s/nrv2r/cra/shr can do in-place with offset.

;Packers available, lz4 is reference for speed/size comparison
;LZ4		(1x speed, 100% size)
;Cranker	(1.3x, 93%)
;Doynamite68k	(1.8x, 88%)
;nrv2r/s	(2.0x, 85%)
;Arj m7		(3.4x, 79%)
;Shrinkler	(23x, 71%)
;PackFire	(46x, 70%)
;
;All basic routines take parameters
;a0, source/packed data
;a1, destination

;LIB_ENABLE_LZ4			equ	1	;(LZ4) LZ4 
;LIB_ENABLE_CRANKER		equ	1	;(CRA) LZO depacking
;LIB_ENABLE_DOYNAMITE68K	equ	1	;(DOY) Doynamite68k
;LIB_ENABLE_NRV2S		equ	1	;(NRV) Ross's nrv2s
;LIB_ENABLE_NRV2R		equ	1	;(NRV) Ross's nrv2r (in place no offset)
;LIB_ENABLE_ARJM7		equ	1	;(AM7) Arj m7
;LIB_ENABLE_PACKFIRE_LARGE	equ	1	;(PKF) Packfire LZMA depacking
;LIB_ENABLE_SHRINKLER		equ	1	;(SHR) Shrinkler LZMA


*****************************************************************************

; Setup the DEFAULT irq - this is what the "SetBase" functions use. You can change
; this in invidual routines by saving INTENA and carefully switching to what you need
; then switch back at the end of routine. Generally though you can choose SOFTINT and 
; forget about it. In all cases you need to call FW_VBlankProxy every frame when using
; your own irq handlers.
; Using SOFTINT allows you to interrupt your lev1 handler with lev3 blit interrupts :)
; Use actual INTF values for our flags so we can use them for writing to INTENA
FW_FRAME_IRQ_NONE	equ	0	;No irq
FW_FRAME_IRQ_SOFTINT	equ	(1<<2)	;lev1 irq, have to trigger INTF_SOFTINT in copper
FW_FRAME_IRQ_COPER	equ	(1<<4)	;lev3 irq, have to trigger INTF_COPER in copper
FW_FRAME_IRQ_VERTB	equ	(1<<5)	;lev3 irq, automatically triggered by INTF_VERTB

FW_FRAME_IRQ_TYPE	equ	FW_FRAME_IRQ_SOFTINT	;required irq type

; Create some useful defines based on the choice
FW_FRAME_IRQ_LEV1	set	0	;default
FW_FRAME_IRQ_LEV3	set	0	;default
FW_FRAME_IRQ_NEEDTRIG	set	0	;default

	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_SOFTINT
FW_FRAME_IRQ_LEV1 set 1
FW_FRAME_IRQ_NEEDTRIG set 1
	endif
	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_COPER
FW_FRAME_IRQ_LEV3 set 1
FW_FRAME_IRQ_NEEDTRIG set 1
	endif
	ifeq FW_FRAME_IRQ_TYPE-FW_FRAME_IRQ_VERTB
FW_FRAME_IRQ_LEV3 set 1
	endif


*****************************************************************************

; To avoid syntax errors if not assembled from makefile
	ifnd _INTROWRAPPER
_INTROWRAPPER set 0		
	endif

	ifnd _DEBUG
_DEBUG set 0		
	endif

	ifnd _VERBOSE
_VERBOSE set 0		
	endif

*****************************************************************************

	endif				; _INTROCONFIG_I
