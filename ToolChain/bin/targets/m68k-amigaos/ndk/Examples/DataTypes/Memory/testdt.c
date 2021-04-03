/*
 * $Id$
 *
 * :ts=4
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
 */

#include <dos/dos.h>

#include <intuition/intuition.h>
#include <intuition/icclass.h>

#include <datatypes/datatypesclass.h>
#include <libraries/amigaguide.h>
#include <datatypes/pictureclass.h>

#include <clib/amigaguide_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/intuition_protos.h>
#include <clib/utility_protos.h>
#include <clib/alib_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include <stdlib.h>

extern struct Library * IntuitionBase;
extern struct Library * AmigaGuideBase;
extern struct Library * DataTypesBase;
extern struct Library * UtilityBase;

/*#define PDTA_WhichPicture	(DTA_Dummy + 219)*/
/*#define PDTA_GetNumPictures	(DTA_Dummy + 220)*/

void
TestIt(STRPTR Name,int which)
{
	struct Window *Window;

	Window = OpenWindowTags(NULL,
		WA_Title,			"Test window",
		WA_InnerWidth,		400,
		WA_InnerHeight,		400,
		WA_SizeBRight,		TRUE,
		WA_SizeBBottom,		TRUE,
		WA_CloseGadget,		TRUE,
		WA_DepthGadget,		TRUE,
		WA_DragBar,			TRUE,
		WA_SizeGadget,		TRUE,
		WA_RMBTrap,			TRUE,
		WA_Activate,		TRUE,
		WA_SimpleRefresh,	TRUE,
		WA_IDCMP,			IDCMP_CLOSEWINDOW | IDCMP_REFRESHWINDOW | IDCMP_NEWSIZE |
							IDCMP_GADGETUP | IDCMP_GADGETDOWN | IDCMP_MOUSEBUTTONS |
							IDCMP_MOUSEMOVE | IDCMP_VANILLAKEY | IDCMP_IDCMPUPDATE |
							IDCMP_RAWKEY,
	TAG_DONE);
	if(Window != NULL)
	{
		Object *Item;
		APTR memory = NULL;
		LONG size = 0;
		BPTR fileLock;


		fileLock = Lock(Name,SHARED_LOCK);
		if(fileLock != NULL)
		{
			struct FileInfoBlock __aligned fib;
			BOOL good = FALSE;

			if(Examine(fileLock,&fib) && fib.fib_DirEntryType < 0 && fib.fib_Size > 0)
			{
				size = fib.fib_Size;
				memory = AllocVec(size,MEMF_ANY|MEMF_PUBLIC);
				if(memory != NULL)
				{
					BPTR fileHandle;

					fileHandle = Open(Name,MODE_OLDFILE);
					if(fileHandle != NULL)
					{
						if(Read(fileHandle,memory,size) == size)
							good = TRUE;

						Close(fileHandle);
					}
				}
			}

			UnLock(fileLock);

			if(NOT good)
			{
				FreeVec(memory);
				memory = NULL;

				size = 0;
			}
		}


		WindowLimits(Window,
			Window->BorderLeft + 100 + Window->BorderRight,Window->BorderTop + 100 + Window->BorderBottom,
			Window->WScreen->Width,Window->WScreen->Height);

		if(memory != NULL)
		{
			ULONG howmany = 0;

			Item = NewDTObject(Name,
				PDTA_WhichPicture,	which,
				PDTA_GetNumPictures,&howmany,
				DTA_SourceType,		DTST_MEMORY,
				DTA_SourceAddress,	memory,
				DTA_SourceSize,		size,
				GA_Immediate,		TRUE,
				GA_RelVerify,		TRUE,
				DTA_TextAttr,		Window->WScreen->Font,
				GA_Left,			Window->BorderLeft,
				GA_Top,				Window->BorderTop,
				GA_RelWidth,		-(Window->BorderLeft + Window->BorderRight),
				GA_RelHeight,		-(Window->BorderTop + Window->BorderBottom),
				ICA_TARGET,			ICTARGET_IDCMP,
			TAG_DONE);

			Printf("howmany = %ld\n",howmany);
		}
		else
		{
			Item = NewDTObject(Name,
				/*
				DTA_SourceType,DTST_FILE,
				DTA_GroupID,GID_PICTURE,
				PDTA_Remap,TRUE,
				OBP_Precision,PRECISION_IMAGE,
				*/
				GA_Immediate,	TRUE,
				GA_RelVerify,	TRUE,
				DTA_TextAttr,	Window->WScreen->Font,
				GA_Left,		Window->BorderLeft,
				GA_Top,			Window->BorderTop,
				GA_RelWidth,	-(Window->BorderLeft + Window->BorderRight),
				GA_RelHeight,	-(Window->BorderTop + Window->BorderBottom),
				ICA_TARGET,		ICTARGET_IDCMP,
			TAG_DONE);
		}

		if(Item != NULL)
		{
			struct IntuiMessage *Message;
			ULONG MsgClass;
			UWORD MsgCode;
			struct TagItem *MsgTags,*List,*This;
			BOOL Done;
			WORD Direction;

			AddDTObject(Window,NULL,Item,-1);
			RefreshDTObjects(Item,Window,NULL,NULL);

			Done = FALSE;

			do
			{
				WaitPort(Window->UserPort);

				while((Message = (struct IntuiMessage *)GetMsg(Window->UserPort)) != NULL)
				{
					MsgClass = Message->Class;
					MsgCode = Message->Code;
					MsgTags = Message->IAddress;

					switch(MsgClass)
					{
						case IDCMP_VANILLAKEY:

							Direction = 0;

							switch(MsgCode)
							{
								case '/':

									DoDTMethod(Item,Window,NULL,DTM_TRIGGER,NULL,STM_RETRACE,NULL);
									break;

								case '\t':

									DoDTMethod(Item,Window,NULL,DTM_TRIGGER,NULL,STM_NEXT_FIELD,NULL);
									break;

								case '\r':

									DoDTMethod(Item,Window,NULL,DTM_TRIGGER,NULL,STM_ACTIVATE_FIELD,NULL);
									break;

								case '<':

									DoDTMethod(Item,Window,NULL,DTM_TRIGGER,NULL,STM_BROWSE_PREV,NULL);
									break;

								case '>':

									DoDTMethod(Item,Window,NULL,DTM_TRIGGER,NULL,STM_BROWSE_NEXT,NULL);
									break;

								case ' ':

									Direction = 1;
									break;

								case '\b':

									Direction = -1;
									break;
							}

							if(Direction != 0)
							{
								LONG otopv, topv, visv, totv;

								GetDTAttrs (Item,
									DTA_TopVert,		&topv,
									DTA_VisibleVert,	&visv,
									DTA_TotalVert,		&totv,
								TAG_DONE);
								
								otopv = topv;

								topv += Direction * (visv - 1);

								if (topv < 0)
									topv = 0;
								if (topv > totv - visv)
									topv = totv - visv;
						
								if (topv != otopv)
								{
									SetDTAttrs (Item, Window, NULL,
										DTA_TopVert,	topv,
										DTA_Sync,		TRUE,
									TAG_DONE);
								}
							}

							break;

						case IDCMP_IDCMPUPDATE:

							List = MsgTags;

							while((This = NextTagItem(&List)) != NULL)
							{
								switch(This->ti_Tag)
								{
									case DTA_Busy:

										if(This->ti_Data)
										{
											SetWindowPointer(Window,
												WA_BusyPointer,	TRUE,
											TAG_DONE);
										}
										else
										{
											SetWindowPointerA(Window,NULL);
										}

										break;

									case DTA_Sync:

										RefreshDTObjects(Item,Window,NULL,NULL);
										break;
								}
							}

							break;

						case IDCMP_CLOSEWINDOW:

							Done = TRUE;
							break;

						case IDCMP_REFRESHWINDOW:

							ReplyMsg((struct Message *)Message);

							BeginRefresh(Window);
							EndRefresh(Window,TRUE);

							Message = NULL;

							break;
					}

					if(Message != NULL)
						ReplyMsg((struct Message *)Message);
				}
			}
			while(NOT Done);

			RemoveDTObject(Window,Item);

			DisposeDTObject(Item);
		}

		CloseWindow(Window);

		FreeVec(memory);
	}
}

int
main(int argc,char **argv)
{
	if(argc > 1)
		TestIt(argv[1],(argc > 2) ? atoi(argv[2]) : 0);

	return(0);
}
