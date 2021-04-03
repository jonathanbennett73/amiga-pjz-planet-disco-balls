/*
 * $Id: dispatch.c 44.6 1999/05/08 08:40:09 olsen Exp olsen $
 *
 * :ts=4
 *
 * CDXL datatype
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

/*#define DEBUG*/
#include "classbase.h"

/*****************************************************************************/

#include "cdxl.h"

/*****************************************************************************/

#define CANNOT !
#define OK (0)
#define SAME (0)

/*****************************************************************************/

/* this macro lets us long-align structures on the stack */
#define D_S(type,name) char a_##name[sizeof(type)+3]; \
                       type *name = (type *)((LONG)(a_##name+3) & ~3);

/*****************************************************************************/

struct localData
{
	BPTR					lod_FH;				/* File handle */

	UBYTE *					lod_Buffer;			/* Frame buffer */

	struct BitMap *			lod_KeyFrame;		/* Key frame */

	UBYTE *					lod_Sample;
	ULONG					lod_SampleLength;
	ULONG					lod_Period;

	UWORD *					lod_LastFrameColours;
	ULONG					lod_NumColours;
	BOOL					lod_IsStereo;
	UWORD					lod_Pad;

	struct PanFrame			lod_Header;			/* Descriptor */
	LONG					lod_NextFrame;

	ULONG *					lod_Methods;
};

/*****************************************************************************/

#define G(o) ((struct Gadget *)o)

/*****************************************************************************/

#define INTDIV(a, b)		(((a) + ((b) / 2)) / (b))
#define DEFAULT_XLSPEED		75
#define DEFAULT_SECTOR_SIZE	2048

/*****************************************************************************/

static void
CopyBitMap (
	struct ClassBase *cb,
	struct BitMap *bm1,
	struct BitMap *bm2,
	ULONG width)
{
	ULONG bpr1 = bm1->BytesPerRow;
	ULONG bpr2 = bm2->BytesPerRow;
	UBYTE *src;
	UBYTE *dst;
	LONG r;
	LONG p;

	for (p = bm1->Depth - 1; p >= 0; p--)
	{
		src = (BYTE *) bm1->Planes[p];
		dst = (BYTE *) bm2->Planes[p];

		for (r = bm1->Rows - 1; r >= 0; r--)
		{
			CopyMem (src, dst, width);
			src += bpr1;
			dst += bpr2;
		}
	}
}

/*****************************************************************************/

static BOOL
GetCDXL(struct ClassBase * cb,Class * cl,Object * o,struct TagItem * attrs)
{
	struct localData *lod = INST_DATA (cl, o);
	struct PanFrame *first_pan = &lod->lod_Header;
	struct BitMap keyFrameBitMap;
	struct ColorRegister *cmap;
	char varBuffer[20];
	ULONG i;
	ULONG fps;
	UWORD *colors;
	UBYTE *buffer;
	ULONG modeid;
	STRPTR title;
	WORD ncolors;
	ULONG frames;
	ULONG fsize;
	ULONG psize;
	ULONG *cregs;
	ULONG speed;
	LONG sourceType;
	LONG error = OK;
	BPTR fh;
	D_S(struct FileInfoBlock,fib);

	title = (STRPTR)GetTagData (DTA_Name, NULL, attrs);

	GetDTAttrs(o,
		DTA_Handle, &fh,
		DTA_SourceType, &sourceType,
	TAG_DONE);

	if(fh == NULL || sourceType != DTST_FILE)
	{
		error = ERROR_OBJECT_WRONG_TYPE;
		goto out;
	}

	lod->lod_FH = fh;

	/* Read the animation header */
	if(Read(fh, first_pan, PAN_SIZE) != PAN_SIZE)
	{
		error = IoErr();
		goto out;
	}

	/* olsen: perform some simple error checking. */
	if(first_pan->Type != PAN_STANDARD ||
	   first_pan->Size < sizeof(PAN_SIZE) ||
	   first_pan->XSize == 0 ||
	   first_pan->YSize == 0 ||
	   first_pan->PixelSize < 1 ||
	   first_pan->PixelSize > 8 ||
	   CMAP_SIZE(first_pan) == 0 ||
	   PI_VIDEO(first_pan) < PIV_STANDARD ||
	   PI_VIDEO(first_pan) > PIV_HAM ||
	   PI_PIXEL(first_pan) != PIF_PLANES)
	{
		error = DTERROR_INVALID_DATA;
		goto out;
	}

	/* Come up with the mode id */
	ncolors = 1 << first_pan->PixelSize;
	if(ncolors > CMAP_SIZE(first_pan))
		ncolors = CMAP_SIZE(first_pan);

	if (first_pan->XSize >= 640)
		modeid = HIRES_KEY;
	else
		modeid = LORES_KEY;

	if (first_pan->YSize >= 400)
		modeid |= LACE;

	if(PI_VIDEO(first_pan) == PIV_HAM)
	{
		modeid |= HAM;

		if(first_pan->PixelSize == 6)
		{
			ncolors = 16; /* olsen: 16, not 32! */
		}
		else if (first_pan->PixelSize == 8)
		{
			ncolors = 64;
		}
		else
		{
			error = DTERROR_INVALID_DATA;
			goto out;
		}
	}

	lod->lod_NumColours = ncolors;

	/* Make room for the colour palette. */
	lod->lod_LastFrameColours = AllocVec(sizeof(UWORD) * lod->lod_NumColours,MEMF_ANY|MEMF_PUBLIC);
	if(lod->lod_LastFrameColours == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if (CANNOT ExamineFH (lod->lod_FH, fib))
	{
		error = IoErr();
		goto out;
	}

	fsize = fib->fib_Size;
	Seek(fh,0,OFFSET_BEGINNING);

	/* Compute the number of frames */
	frames = fsize / first_pan->Size;

	/* Get the speed; normally first_pan->Reserved==0 which indicates
	 * single speed playback.
	 */
	speed = (first_pan->Reserved+1) * DEFAULT_XLSPEED * DEFAULT_SECTOR_SIZE;

	/* Compute the frames per second */
	fps = INTDIV(speed,first_pan->Size);

	/* Allocate the frame buffer */
	lod->lod_Buffer = AllocVec(first_pan->Size, MEMF_ANY|MEMF_PUBLIC);
	if(lod->lod_Buffer == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	/* Allocate the bitmap for the key frame */
	lod->lod_KeyFrame = AllocBitMap(first_pan->XSize,first_pan->YSize,first_pan->PixelSize,BMF_INTERLEAVED,NULL);
	if(lod->lod_KeyFrame == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	/* Read the first frame of the animation */
	if(Read(fh,lod->lod_Buffer,first_pan->Size) != first_pan->Size)
	{
		error = IoErr();
		goto out;
	}

	lod->lod_NextFrame = 1;

	/* Convert the frame to a bitmap */
	InitBitMap (&keyFrameBitMap, first_pan->PixelSize, first_pan->XSize, first_pan->YSize);
	buffer = (UBYTE *) ((ULONG) lod->lod_Buffer + PAN_SIZE + CMAP_SIZE (first_pan));
	psize = ROW_SIZE(first_pan->XSize) * first_pan->YSize;
	for (i = 0; i < first_pan->PixelSize; i++)
		keyFrameBitMap.Planes[i] = &buffer[(i * psize)];

	/* Blit the frame to the keyframe */
	CopyBitMap(cb,&keyFrameBitMap,lod->lod_KeyFrame,ROW_SIZE(first_pan->XSize));

	lod->lod_SampleLength = 0;
	lod->lod_Period = 0;
	lod->lod_Sample = NULL;

	if(first_pan->AudioSize > 0)
	{
		BOOL forceStereo = FALSE;
		ULONG audioRate;
		UWORD audioSize;

		/* olsen: for those few CDXL files recorded in stereo
		 *        which don't say in the header that they are
		 *        really in stereo, allow the user to override
		 *        the defaults.
		 */
		/*
		if(GetVar("classes/datatypes/animation/cdxl/stereo",varBuffer,sizeof(varBuffer),0) > 0)
		{
			LONG val;

			if(StrToLong(varBuffer,&val) > 0)
				forceStereo = (BOOL)(val != 0);
		}
		*/

		/* olsen: stereo sample data is twice as long
		 *        as mono data (obviously). This really
		 *        messes up the replay rate calculation
		 *        below unless we take care of it.
		 */
		if(PI_AUDIO(first_pan) == PIA_STEREO || forceStereo)
		{
			audioSize = first_pan->AudioSize / 2;

			lod->lod_IsStereo = TRUE;
		}
		else
		{
			audioSize = first_pan->AudioSize;
		}

		/* Compute audio information */
		audioRate = INTDIV((speed * audioSize),first_pan->Size);
		if(audioRate > 0)
		{
			/* olsen: audio timing is bound to be more accurate,
			 *        and besides, the user is more sensitive to
			 *        audio stutter than to stuttering video
			 *        playback (at least, that's the strategy
			 *        Apple's QuickTime uses).
			 */
			fps = INTDIV(audioRate,audioSize);

			lod->lod_SampleLength = audioSize;
			lod->lod_Period = INTDIV((((struct ExecBase *)SysBase)->ex_EClockFrequency * 5),audioRate);
			lod->lod_Sample = (UBYTE *) ((ULONG) lod->lod_Buffer + PAN_SIZE + CMAP_SIZE (first_pan) + IMAGE_SIZE(first_pan));
		}
	}

	/* Tell the super class about our attributes */
	SetDTAttrs (o, NULL, NULL,
		DTA_ObjName,			title,
		DTA_NominalHoriz,		first_pan->XSize,
		DTA_NominalVert,		first_pan->YSize,
		ADTA_Width,				first_pan->XSize,
		ADTA_Height,			first_pan->YSize,
		ADTA_Depth,				first_pan->PixelSize,
		ADTA_Frames,			frames,
		ADTA_KeyFrame,			lod->lod_KeyFrame,
		ADTA_ModeID,			modeid,
		ADTA_NumColors,			ncolors,
		ADTA_FramesPerSecond,	fps,
		ADTA_SampleLength,		lod->lod_SampleLength,
		ADTA_Period,			lod->lod_Period,

		lod->lod_IsStereo ? ADTA_LeftSample : ADTA_Sample, lod->lod_Sample,
		lod->lod_IsStereo ? ADTA_RightSample : TAG_IGNORE, lod->lod_Sample + lod->lod_SampleLength,
	TAG_DONE);

	cmap = NULL;
	cregs = NULL;

	GetDTAttrs (o,
		ADTA_ColorRegisters,	&cmap,
		ADTA_CRegs,				&cregs,	/* For screen */
	TAG_DONE);

	if(cmap == NULL || cregs == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	colors = (UWORD *) ((ULONG) lod->lod_Buffer + PAN_SIZE);

	memcpy(lod->lod_LastFrameColours,colors,sizeof(UWORD) * ncolors);

	for(i = 0 ; i < ncolors ; i++)
	{
		cmap[i].red		= 0x11 * ((colors[i] >> 8) & 0xF);
		cmap[i].green	= 0x11 * ((colors[i] >> 4) & 0xF);
		cmap[i].blue	= 0x11 * ((colors[i]     ) & 0xF);

		cregs[i * 3 + 0] = 0x01010101L * cmap[i].red;
		cregs[i * 3 + 1] = 0x01010101L * cmap[i].green;
		cregs[i * 3 + 2] = 0x01010101L * cmap[i].blue;
	}

 out:

	SetIoErr(error);

	return((BOOL)(error == OK));
}

/*****************************************************************************/

static struct BitMap *
loadframe(struct ClassBase *cb,Class *cl,Object *o,struct adtNewFormatFrame *msg)
{
	struct localData *lod = INST_DATA (cl, o);
	struct PanFrame *first_pan = &lod->lod_Header;
	struct PanFrame *this_pan;
	struct BitMap *bm;
	struct BitMap * result;
	LONG error = OK;
	UBYTE *sample = NULL;
	BOOL bufferAllocated = FALSE;
	UBYTE *buffer;

	/* See if there is a frame already allocated */
	buffer = (UBYTE *)msg->alf_UserData;
	if(buffer != NULL)
	{
		bm = msg->alf_BitMap;
		if(bm == NULL)
			bm = (struct BitMap *)((ULONG)buffer + first_pan->Size);

		if(lod->lod_SampleLength > 0)
			sample = (UBYTE *) ((ULONG)buffer + PAN_SIZE + CMAP_SIZE (first_pan) + IMAGE_SIZE(first_pan));

		D(("reusing old buffer 0x%08lx",buffer));
	}
	/* No, there wasn't so allocate a new frame */
	else if ((buffer = AllocVec (first_pan->Size + sizeof (struct BitMap), MEMF_ANY|MEMF_PUBLIC)) != NULL)
	{
		ULONG i, psize;
		char *buff;

		D(("allocating new buffer 0x%08lx",buffer));

		bufferAllocated = TRUE;

		bm = (struct BitMap *)((ULONG)buffer + first_pan->Size);
		InitBitMap (bm, first_pan->PixelSize, first_pan->XSize, first_pan->YSize);
		buff = (UBYTE *)((ULONG)buffer + PAN_SIZE + CMAP_SIZE (first_pan));
		psize = ROW_SIZE(first_pan->XSize) * first_pan->YSize;
		for (i = 0; i < (ULONG)first_pan->PixelSize; i++)
			bm->Planes[i] = &buff[(i * psize)];

		if(lod->lod_SampleLength > 0)
			sample = (UBYTE *) ((ULONG)buffer + PAN_SIZE + CMAP_SIZE (first_pan) + IMAGE_SIZE(first_pan));

		/* Remember the buffer */
		msg->alf_UserData = buffer;
	}
	else
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(lod->lod_NextFrame != msg->alf_Frame)
	{
		LONG offset;

		offset = msg->alf_Frame * first_pan->Size;
		if(Seek(lod->lod_FH,offset,OFFSET_BEGINNING) < 0)
		{
			lod->lod_NextFrame = -1;
			error = IoErr();
			goto out;
		}

		lod->lod_NextFrame = msg->alf_Frame;
	}

	/* Read the frame */
	if(Read(lod->lod_FH,buffer,first_pan->Size) != first_pan->Size)
	{
		lod->lod_NextFrame = -1;
		error = IoErr();
		goto out;
	}

	/* olsen: do some more error checking. */
	this_pan = (struct PanFrame *)buffer;
	if(this_pan->Size != first_pan->Size ||
	   this_pan->XSize != first_pan->XSize ||
	   this_pan->YSize != first_pan->YSize ||
	   this_pan->PixelSize != first_pan->PixelSize ||
	   PI_VIDEO(this_pan) != PI_VIDEO(first_pan) ||
	   PI_PIXEL(this_pan) != PI_PIXEL(first_pan) ||
	   PI_AUDIO(this_pan) != PI_AUDIO(first_pan))
	{
		lod->lod_NextFrame = -1;
		error = DTERROR_INVALID_DATA;
		goto out;
	}

	if(CMAP_SIZE(this_pan) > 0)
	{
		UWORD * colours = (UWORD *)((ULONG)this_pan + PAN_SIZE);
		LONG numColours = min(lod->lod_NumColours,CMAP_SIZE(this_pan));

		if(memcmp(lod->lod_LastFrameColours,colours,sizeof(UWORD) * numColours) != SAME)
		{
			int i;

			memcpy(lod->lod_LastFrameColours,colours,sizeof(UWORD) * numColours);

			if(msg->alf_CMap == NULL)
				msg->alf_CMap = GetColorMap(numColours);

			if(msg->alf_CMap == NULL)
			{
				lod->lod_NextFrame = -1;
				error = ERROR_NO_FREE_STORE;
				goto out;
			}

			for(i = 0 ; i < numColours ; i++)
			{
				SetRGB4CM(msg->alf_CMap,i,
					((colours[i] >> 8) & 0xF),
					((colours[i] >> 4) & 0xF),
					((colours[i]     ) & 0xF));
			}
		}
	}

	lod->lod_NextFrame++;

	msg->alf_BitMap			= bm;
	msg->alf_SampleLength	= lod->lod_SampleLength;
	msg->alf_Period			= lod->lod_Period;

	if(sample != NULL && lod->lod_IsStereo && msg->MethodID == ADTM_LOADNEWFORMATFRAME)
	{
		msg->alf_LeftSample		= sample;
		msg->alf_RightSample	= sample + lod->lod_SampleLength;
	}
	else
	{
		msg->alf_Sample	= sample;
	}

 out:

	if(error != OK)
	{
		if(bufferAllocated)
		{
			msg->alf_UserData = NULL;
			FreeVec(buffer);
		}

		SetIoErr(error);
		result = NULL;
	}
	else
	{
		result = msg->alf_BitMap;
	}

	return(result);
}

/*****************************************************************************/

static ULONG
unloadframe(struct ClassBase *cb,struct adtFrame *msg)
{
	/* Unloading while playing seems to be a problem... */

	if(msg->alf_CMap != NULL)
	{
		FreeColorMap(msg->alf_CMap);
		msg->alf_CMap = NULL;
	}

	D(("unloading; freeing buffer 0x%08lx",msg->alf_UserData));

	FreeVec(msg->alf_UserData);
	msg->alf_UserData = NULL;

	return(0);
}

/*****************************************************************************/

/* Inquire attribute of an object */
ULONG
getAttrMethod(struct ClassBase * cb,Class * cl,Object * o,struct opGet * msg)
{
	struct localData *lod = INST_DATA (cl, o);

	switch(msg->opg_AttrID)
	{
		/* Method information */
		case DTA_Methods:
			(*msg->opg_Storage) = (ULONG)lod->lod_Methods;
			break;

		default:
			return(DoSuperMethodA(cl,o,(Msg)msg));
	}

	return(1);
}

/*****************************************************************************/

static ULONG ASM
Dispatch(REG(a0) Class * cl, REG(a2) Object * o, REG(a1) Msg msg)
{
	struct ClassBase *cb = (struct ClassBase *) cl->cl_UserData;
	struct localData *lod;
	ULONG result;

	switch(msg->MethodID)
	{
		case ADTM_LOADNEWFORMATFRAME:
		case ADTM_LOADFRAME:

			result = (ULONG) loadframe (cb, cl, o, (struct adtNewFormatFrame *)msg);
			break;

		case ADTM_UNLOADNEWFORMATFRAME:
		case ADTM_UNLOADFRAME:

			result = (ULONG) unloadframe (cb, (struct adtFrame *)msg);
			break;

		case OM_GET:

			result = getAttrMethod(cb,cl,o,(struct opGet *)msg);
			break;

		case OM_NEW:

			result = DoSuperMethodA (cl, o, msg);
			if(result != NULL)
			{
				struct localData *lod = INST_DATA (cl, result);
				ULONG * methods;
				struct opGet opg;

				memset(&opg,0,sizeof(opg));
				opg.MethodID = DTA_Methods;
				opg.opg_AttrID = OM_GET;
				opg.opg_Storage = (ULONG *)&methods;

				methods = NULL;
				DoSuperMethodA(cl,(Object *)result,(Msg)&opg);

				if(methods != NULL)
				{
					const ULONG terminator = ~0UL;
					ULONG * m = methods;
					LONG total = 4+1;

					while((*m++) != terminator)
						total++;

					lod->lod_Methods = AllocVec(sizeof(ULONG) * total,MEMF_ANY|MEMF_PUBLIC);
					if(lod->lod_Methods != NULL)
					{
						ULONG * n = lod->lod_Methods;

						m = methods;

						while((*m) != terminator)
							(*n++) = (*m++);

						(*n++) = ADTM_LOADNEWFORMATFRAME;
						(*n++) = ADTM_UNLOADNEWFORMATFRAME;
						(*n++) = ADTM_LOADFRAME;
						(*n++) = ADTM_UNLOADFRAME;
						(*n++) = terminator;
					}
				}

				if(CANNOT GetCDXL(cb,cl,(Object *)result,((struct opSet *)msg)->ops_AttrList))
				{
					CoerceMethod(cl,(Object *)result,OM_DISPOSE);
					result = NULL;
				}
			}
			break;

		case OM_DISPOSE:

			lod = INST_DATA (cl, o);

			WaitBlit();
			FreeBitMap (lod->lod_KeyFrame);
			FreeVec (lod->lod_Buffer);
			FreeVec(lod->lod_LastFrameColours);
			FreeVec(lod->lod_Methods);

			/* FALLS THROUGH TO */

		default:

			/* Let the superclass handle everything else */
			result = DoSuperMethodA (cl, o, msg);
			break;
	}

	return(result);
}

/*****************************************************************************/

Class *
initClass(struct ClassBase * cb)
{
	Class *cl;

	if (cl = MakeClass (CDXLDTCLASS, ANIMATIONDTCLASS, NULL, sizeof (struct localData), 0L))
	{
		cl->cl_Dispatcher.h_Entry = (ULONG (*)()) Dispatch;
		cl->cl_UserData = (ULONG) cb;
		AddClass (cl);
	}

	return (cl);
}
