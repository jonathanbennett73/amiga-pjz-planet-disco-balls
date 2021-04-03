*****************************************************************************

; Name			: IntroStandalone.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: Simulates framework so individual parts can be tested.
; Date last edited	: 04/02/2020
				
*****************************************************************************

	include "hardware/custom.i"
	include "hardware/cia.i"

	include "../IntroConfig.i"
	include	"../Framework/CustomExtra.i"
	include "../Framework/CustomMacros.i"
	include "../Framework/IntroFramework_xref.i"
	include "../Framework/IntroLibrary.i"
	include "../Framework/IntroLibrary_xref.i"	

	;additional externals
	xref	PRC_Init
	xref	PRC_Finished
	xref	PRC_PreCalc_Done
	xref	SubPartStart
	xref	SubPartPreCalc_IntroStart
	xref	SharedDataPreCalc_IntroStart

*****************************************************************************

	section	FW_PublicCode,code	;Code section in Public memory

*****************************************************************************

IntroStartup:
	bsr	FW_Init			;Get VBR/AA details
	bsr	FW_KillSys		;Kill system	

	lea	_custom,a6
	bsr	FW_SetBaseCopperIrqDma_A6 ;Blank screen and copper but DMA on
	bsr	FW_WaitFrame		;Let it become active
	bsr	FW_SetColorsBlack_A6	;So black...

	;Shared library precalcs. The PRC_Init routine also requires these 
	bsr	LIB_PreCalc		;T:d0-d1/a0-a1

	;Execute precalc routine if needed (runs in VBL while we continue here)
	ifne	FW_PRECALC_LONG
		jsr	PRC_Init	;T:d0-d1/a0-a1
	endif

	;Do intro start precalcs
	bsr.s	PreCalc			;T:d0-d1/a0-a1

	;Init musicroutines that work with no system (P61) - this is where the 
	;big precalcs are done
	bsr	FW_MusicInit		;T:d0-d1/a0-a1

	;Close down precalc routine
	ifne FW_PRECALC_LONG
	move.w	#1,FW_Precalc_Done	;Signal precalc routine to finish
.wait:
	tst.w	PRC_Finished		;Has it finished?
	beq.s	.wait

	moveq	#10,d0			;wait 1/5 second (100% on screen)
	bsr	FW_WaitFrames
	endif

	; Blackout ready for main intro
	bsr	FW_SetBaseCopperIrq_A6
	;bsr	FW_SetBaseLev3Irq
	bsr	FW_WaitFrame		;Wait 1 frame
	
	bsr	FW_MusicPlay		;Start playing

	bsr	FW_ResetFrame		;Frame timing starts now
	
	bsr.s	IntroMain		;Run the intro
;.l
;	jsr	FW_WaitFrame
;	bra.s	.l

	bsr	FW_MusicEnd		;Stop music and cleanup for players that work with no system
	bsr	FW_RestoreSys		;Restore system

	moveq	#0,d0			;Keep cli happy
.exit:
	rts				;Return code in d0


*****************************************************************************
* Does any intro start precalcs by calling external precalc routines.
* All precalc routines must preserve d2-d7/a2-a6
* IN:		
* OUT:		
* TRASHED:	d0-d1/a0-a1
*****************************************************************************

PreCalc:
	bsr	SharedDataPreCalc_IntroStart

	jsr	SubPartPreCalc_IntroStart
	rts

*****************************************************************************

IntroMain:

	;clr.w	FW_Quit_Flag		;Don't quit just yet
.MainLoop1

	jsr	SubPartStart	

	;tst.w	FW_Quit_Flag
	;beq.s	.MainLoop1

	rts				;exit


*****************************************************************************
*****************************************************************************
