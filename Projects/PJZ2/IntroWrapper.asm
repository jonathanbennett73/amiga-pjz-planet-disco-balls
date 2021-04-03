*****************************************************************************

; Name			: IntroWrapper.s
; Coded by		: Antiriad (Jonathan Bennett <jon@autoitscript.com)
; Description		: The main wrapper for the entire intro.
; Date last edited	: 24/05/2019

				
*****************************************************************************

WBStartupCode	=	0	;Add startup code from icon (needs amigaos includes)
				;NOTE: Crashes on KS1.3 with cranker packing

*****************************************************************************

	ifne WBStartupCode
		include "exec\exec_lib.i"
		include	"exec\exec.i"
		include	"libraries\dosextens.i"
	endif

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

	xref	VEC_Start
	xref	VEC_PreCalc_IntroStart

	xref	SVERT_Start
	xref	SVERT_PreCalc_IntroStart

	xref	PARA_Start
	xref	PARA_PreCalc_IntroStart

	xref	BKG1_Start
	xref	BKG1_PreCalc_IntroStart

	xref	GTZ1_Start
	xref	GTZ1_PreCalc_IntroStart

	xref	IBOB_Start
	xref	IBOB_PreCalc_IntroStart

	xref	CRD_Start
	xref	CRD_PreCalc_IntroStart

*****************************************************************************

	section	FW_PublicCode,code	;Code section in Public memory

*****************************************************************************

IntroIconStartup:
	ifne WBStartupCode
	;This handles startup from an icon cleanly.
	movem.l	d0/a0,-(sp)

	sub.l	a1,a1
	move.l  4.w,a6
	jsr	_LVOFindTask(a6)

	move.l	d0,a4

	tst.l	pr_CLI(a4)		; was it called from CLI?
	bne.s   .fromCLI		; if so, skip out this bit...

	lea	pr_MsgPort(a4),a0
	move.l  4.w,a6
	jsr	_LVOWaitPort(A6)
	lea	pr_MsgPort(a4),a0
	jsr	_LVOGetMsg(A6)
	move.l	d0,.returnMsg

.fromCLI
	movem.l	(sp)+,d0/a0
	endif

	bsr.s	IntroStartup           	; Calls your code..
	
	ifne WBStartupCode
	move.l	d0,-(sp)
	tst.l	.returnMsg		; Is there a message?
	beq.s	.exitToDOS		; if not, skip...

	move.l	4.w,a6
        jsr	_LVOForbid(a6)          ; note! No Permit needed!
	move.l	.returnMsg(pc),a1
	jsr	_LVOReplyMsg(a6)
.exitToDOS:
	move.l	(sp)+,d0		; exit code
	endif

	rts

.returnMsg:	dc.l	0

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
	bsr	FW_WaitFrame		;wait 1 frame
	
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

	jsr	VEC_PreCalc_IntroStart
	jsr	SVERT_PreCalc_IntroStart
	jsr	GTZ1_PreCalc_IntroStart
	jsr	BKG1_PreCalc_IntroStart
	jsr	PARA_PreCalc_IntroStart
	jsr	IBOB_PreCalc_IntroStart
	jsr	CRD_PreCalc_IntroStart
	rts

*****************************************************************************

IntroMain:

	clr.w	FW_Quit_Flag		;Don't quit just yet
.MainLoop1
	tst.w	FW_Quit_Flag
	bne.w	.quit
	
	lea	Controller_Info(pc),a5
	move.l	CTRL_SCRIPT_PTR(a5),a1

	;Get a new command from the script
	move.w	(a1)+,d0
	move.l	.jmptable(pc,d0.w),a0
	jmp	(a0)			;Run routine, must preserve a4-a6

.jmptable:
	dc.l	.quit
	dc.l	.fx_pause
	dc.l	.fx_stretchvert
	dc.l	.fx_vector
	dc.l	.fx_paralines
	dc.l	.fx_backdrop1
	dc.l	.fx_greetz
	dc.l	.fx_ibob
	dc.l	.fx_credits

	;assume end
	bra.s	.quit

.restartscript
	move.l	#ControllerScript,CTRL_SCRIPT_PTR(a5)
	bra.s	.tstmouse

.fx_pause:
	move.w	(a1)+,d0		;pause time in frames
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	bsr	FW_WaitFrames
	bra.s	.tstmouse

.fx_vector:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	VEC_Start
	bra.s	.tstmouse

.fx_stretchvert:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	SVERT_Start
	bra.s	.tstmouse

.fx_paralines:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	PARA_Start
	bra.s	.tstmouse

.fx_backdrop1:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	BKG1_Start
	bra.s	.tstmouse

.fx_greetz:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	GTZ1_Start
	bra.s	.tstmouse

.fx_ibob:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	IBOB_Start
	bra.s	.tstmouse

.fx_credits:
	move.l	a1,CTRL_SCRIPT_PTR(a5)	;Store script ptr
	jsr	CRD_Start
	;bra.s	.tstmouse

;---
.tstmouse
	ifne FW_RMB_QUIT_SECTION
	btst.b	#10-8,potgor+_custom	;rmb quits section so stay here until it is released
	beq.s	.tstmouse		
	endif

	btst.b 	#6,$bfe001		;L.m.b. pressed?
	bne.w 	.MainLoop1

.quit	
	rts				;exit
			

*****************************************************************************
*****************************************************************************


*****************************************************************************
*****************************************************************************

;	section	FW_PublicData,data	;Public data section for variables
	
*****************************************************************************

*** Demo Sequencing ***
; Has to go last to have all the labels from the individual parts available

	rsreset
FX_END			rs.l	1
FX_PAUSE		rs.l	1
FX_STRETCHVERT		rs.l	1
FX_VEC			rs.l	1
FX_PARALINES		rs.l	1
FX_BACKDROP1		rs.l	1
FX_GREETZ		rs.l	1
FX_IBOB			rs.l	1
FX_CREDITS		rs.l	1

	rsreset
CTRL_SCRIPT_PTR:		rs.l 1		;0 - Script Ptr
CTRL_SIZE:			rs.w 0

	even
Controller_Info:
	dc.l	ControllerScript	;CTRL_SCRIPT_PTR


ControllerScript:
	dc.w	FX_STRETCHVERT
	dc.w	FX_PARALINES
	dc.w	FX_VEC
	dc.w	FX_GREETZ
	dc.w	FX_IBOB
	dc.w	FX_BACKDROP1
	dc.w	FX_CREDITS


;	dc.w	FX_PAUSE,50
;	dc.w	FX_PAUSE,50
;	dc.w	FX_PAUSE,50

ControllerScriptEnd:
	dc.w	FX_END

