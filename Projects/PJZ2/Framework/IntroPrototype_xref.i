
	include "../IntroConfig.i"

	;Only assemble this file if enabled
	ifne	PRO_ENABLE

	xref	PRO_Line_Fill_Draw_Init
	xref	PRO_Line_Fill_Draw
	xref	PRO_Line_Fill_Vars
	
	xref	PRO_Line_Draw_Init
	xref	PRO_Line_Draw
	xref	PRO_Line_Vars

	xref	PRO_Dot_Plot_3BPL
	xref	PRO_Dot_Plot_1BPL

	xref	PRO_BOB_Draw_Copy
	xref	PRO_BOB_Draw_Copy_Vars

	xref	PRO_BOB_Draw_OR
	xref	PRO_BOB_Draw_OR_Vars

	xref	PRO_BOB_Draw_Cookie
	xref	PRO_BOB_Draw_Cookie_Vars

	endif	;PRO_ENABLE