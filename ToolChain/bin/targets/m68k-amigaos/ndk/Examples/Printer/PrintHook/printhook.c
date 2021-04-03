/*
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
 */


#include <devices/printer.h>
#include <utility/hooks.h>

#include <clib/exec_protos.h>

static void readpixels(register __a0 struct Hook *hook,
	register __a2 APTR object, register __a1 struct DRPSourceMsg *msg)
{
	LONG x, width = msg->width, r = msg->y << 16;
	ULONG *buf = msg->buf;
	for (x = 0; x < width; x++)
		buf[x] = (r | x) ^ 0x00ffffff;
}

struct Hook hook =
{
	{ NULL, NULL },
	(HOOKFUNC) readpixels,
	NULL,
	NULL
};

void main()
{
	struct MsgPort *replyport;
	struct IODRPTagsReq *ior;
	static struct TagItem tags[] =
	{
		DRPA_SourceHook, (ULONG) &hook,
		DRPA_AspectX, 1,
		DRPA_AspectY, 1,
		TAG_END
	};

	if (replyport = CreateMsgPort())
	{
		if (ior = (struct IODRPTagsReq *) CreateIORequest(replyport,sizeof(*ior)))
		{
			if (!OpenDevice("printer.device",0,(struct IORequest *) ior, 0))
			{
				ior->io_Command = PRD_DUMPRPORTTAGS;
				ior->io_Flags = 0;
				ior->io_Error = 0;
				ior->io_RastPort = NULL;
				ior->io_ColorMap = NULL;
				ior->io_Modes = 0;
				ior->io_SrcX = 0;
				ior->io_SrcY = 0;
				ior->io_SrcWidth = 256;
				ior->io_SrcHeight = 256;
				ior->io_DestCols = 256;
				ior->io_DestRows = 256;
				ior->io_Special = 0;
				ior->io_TagList = tags;
				DoIO((struct IORequest *) ior);
				CloseDevice((struct IORequest *) ior);
			}
			DeleteIORequest((struct IORequest *) ior);
		}
		DeleteMsgPort(replyport);
	}
}
