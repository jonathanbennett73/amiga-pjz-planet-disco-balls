

/* 
*
* COPYRIGHT:
*
*   Unless otherwise noted, all files are Copyright (c) 1999 Amiga, Inc.
*   All rights reserved.
*
* DISCLAIMER:
*
*   This software is provided "as is". No representations or warranties
*   are made with respect to the accuracy, reliability, performance,
*   currentness, or operation of this software, and all use is at your
*   own risk. Neither Amiga nor the authors assume any responsibility
*   or liability whatsoever with respect to your use of this software.
*

	Reaction Inter-Connection Notification Example
 */

#include <exec/types.h>
#include <libraries/gadtools.h>
#include <intuition/icclass.h>
#include <intuition/classes.h>
#include <dos/dos.h>

#include <clib/macros.h>
#include <clib/alib_protos.h>

#include <proto/exec.h>
#include <proto/intuition.h>
#include <proto/layout.h>
#include <proto/palette.h>
#include <proto/label.h>
#include <proto/window.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <classes/window.h>
#include <gadgets/layout.h>
#include <gadgets/button.h>
#include <gadgets/palette.h>
#include <images/label.h>

#include <reaction/reaction.h>
#include <reaction/reaction_macros.h>

#define ID_BUTTON   	1
#define ID_FOREGROUND  	2
#define ID_BACKGROUND	3

struct Library *WindowBase = NULL;
struct Library *LayoutBase = NULL;
struct Library *LabelBase = NULL;
struct Library *ButtonBase = NULL;
struct Library *PaletteBase = NULL;

void openlibs(void) 
{
	/* Open the classes - typically not required to be done manually.
	 * SAS/C or DICE AutoInit can do this for you if linked with the
	 * supplied classact.lib
	 */
	WindowBase = OpenLibrary("window.class",44);
	LayoutBase = OpenLibrary("gadgets/layout.gadget",44);
	ButtonBase = OpenLibrary("gadgets/button.gadget",44);
	PaletteBase = OpenLibrary("gadgets/palette.gadget",44);
	LabelBase = OpenLibrary("images/label.image",44);
}

void closelibs(void) 
{
	/* Close the classes.
	 */
	CloseLibrary( LabelBase );
	CloseLibrary( PaletteBase );
	CloseLibrary( ButtonBase );
	CloseLibrary( LayoutBase );
	CloseLibrary( WindowBase );
}

int main( int argc, char *argv[] )
{
	struct Window *window;
	Object *But_Object, *Pal_Object1, *Pal_Object2;
	Object *Win_Object;

	/* Palette Color To Button ForeGround mapping.
	 */
	struct TagItem MapFG2Button[] =
	{
		PALETTE_Color, BUTTON_TextPen,
		TAG_END
	};

	/* Palette Color To Button BackGround mapping.
	 */
	struct TagItem MapBG2Button[] =
	{
		PALETTE_Color, BUTTON_BackgroundPen,
		TAG_END
	};

	openlibs();
	if(WindowBase && LayoutBase && ButtonBase && PaletteBase && LabelBase)
	{
		/* Create the window object.
		 */
		Win_Object = (Object *)WindowObject,
			WA_ScreenTitle, "ReAction, Amiga Development LLC.",
			WA_Title, "ReAction Example",
			WA_SizeGadget, TRUE,
			WA_Left, 40,
			WA_Top, 30,
			WA_DepthGadget, TRUE,
			WA_DragBar, TRUE,
			WA_CloseGadget, TRUE,
			WA_Activate, TRUE,
			WA_SmartRefresh, TRUE,
			WINDOW_ParentGroup, VLayoutObject,
				LAYOUT_SpaceOuter, TRUE,
				LAYOUT_DeferLayout, TRUE,
				LAYOUT_BevelStyle, GroupFrame,
				LAYOUT_Label, "InterConnection",
				StartMember, But_Object = ButtonObject,
					GA_Text, "_Inter-Connection Example",
					GA_ID, ID_BUTTON,
				EndMember,
				CHILD_WeightedHeight, 0,

				StartMember, HLayoutObject,
					LAYOUT_SpaceOuter, FALSE,
					StartMember, Pal_Object1 = PaletteObject,
						GA_ID, ID_FOREGROUND,
						PALETTE_NumColors, 8,
						PALETTE_Color, 1,
						ICA_MAP, MapFG2Button, /* tag mapping array */
					EndMember,
					CHILD_Label, LabelObject, LABEL_Text, "_ForeGround", LabelEnd,
					CHILD_MinWidth, 90,
					CHILD_MinHeight, 20,
	
					StartMember, Pal_Object2 = PaletteObject,
						GA_ID, ID_BACKGROUND,
						PALETTE_NumColors, 8,
						PALETTE_Color, 0,
						ICA_MAP, MapBG2Button, /* tag mapping array */
					EndMember,
					CHILD_Label, LabelObject, LABEL_Text, "_BackGround", LabelEnd,
					CHILD_MinWidth, 90,
					CHILD_MinHeight, 20,
				EndMember,
			EndMember,
		EndWindow;

		/*  Object creation sucessful?
		 */
		if( Win_Object )
		{
			SetAttrs(Pal_Object1,
				ICA_TARGET, But_Object, /* object to connect to */
				TAG_END);
			SetAttrs(Pal_Object2,
				ICA_TARGET, But_Object, /* object to connect to */
				TAG_END);
			/*  Open the window.
			 */
			if( window = (struct Window *) RA_OpenWindow(Win_Object) )
			{
				ULONG wait, signal, result, done = FALSE;
				WORD Code;
				
				/* Obtain the window wait signal mask.
				 */
				GetAttr( WINDOW_SigMask, Win_Object, &signal );

				/* Input Event Loop
				 */
				while( !done )
				{
					wait = Wait(signal|SIGBREAKF_CTRL_C);
					
					if (wait & SIGBREAKF_CTRL_C) done = TRUE;
					else

					while ((result = RA_HandleInput(Win_Object,&Code)) != WMHI_LASTMSG)
					{
						switch (result & WMHI_CLASSMASK)
						{
							case WMHI_CLOSEWINDOW:
								done = TRUE;
								break;

							case WMHI_GADGETUP:
								switch(result & WMHI_GADGETMASK)
								{
									case ID_BUTTON:
										break;
								}
								break;
						}
					}
				}
			}

			/* Disposing of the window object will
			 * also close the window if it is
			 * already opened and it will dispose of
			 * all objects attached to it.
			 */
			DisposeObject( Win_Object );
		}
	}
	closelibs();
}

#ifdef __STORM__
int wbmain( struct WBStartup *wbs )
{
        return( main( 0, NULL ));
}
#endif
