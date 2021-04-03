/*
 * $Id$
 *
 * :ts=4
 *
 * sc link cpu=any utillib optimize opttime optschedule params=r nodebug nostackcheck GlowIcon.c
 */

#include <intuition/gadgetclass.h>

#include <datatypes/datatypes.h>
#include <datatypes/pictureclass.h>

#include <graphics/gfxmacros.h>

#include <hardware/blit.h>

#include <exec/memory.h>

#include <dos/dosextens.h>
#include <dos/rdargs.h>
#include <dos/dosasl.h>

#include <clib/intuition_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/graphics_protos.h>
#include <clib/utility_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/alib_protos.h>

#include <pragmas/intuition_pragmas.h>
#include <pragmas/datatypes_pragmas.h>
#include <pragmas/graphics_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/dos_pragmas.h>

#define USE_BUILTIN_MATH
#include <string.h>
#include <stdio.h>

/****************************************************************************/

typedef LONG	SWITCH;
typedef STRPTR	KEY;
typedef LONG *	NUMBER;

/****************************************************************************/

#define MINTERM_ZERO		0
#define MINTERM_COPY		ABC | ABNC | NABC | NABNC
#define MINTERM_NOT_B_AND_C	ANBC | NANBC
#define MINTERM_B_OR_C		ABC | ABNC | NABC | NABNC | ANBC | NANBC

/****************************************************************************/

#define ZERO ((BPTR)0L)

/****************************************************************************/

#define FIB_IS_FILE(fib)	((fib)->fib_DirEntryType < 0)
#define FIB_IS_DRAWER(fib)	((fib)->fib_DirEntryType >= 0 && (fib)->fib_DirEntryType != ST_SOFTLINK)

/****************************************************************************/

#define OK (0)
#define SAME (0)
#define CANNOT !

/****************************************************************************/

const STRPTR GlowSuffix = ".glow";
const STRPTR PadSuffix = ".pad";
const int MatchLen = 512;

/****************************************************************************/

extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * IntuitionBase;
extern struct Library * GfxBase;
extern struct Library * UtilityBase;
extern struct Library * DataTypesBase;

/****************************************************************************/

#define MM 2147483647	/* a Mersenne prime */
#define AA 48271		/* this does well in the spectral test */
#define QQ 44488		/* (long)(MM/AA) */
#define RR 3399			/* MM % AA; it is important that RR < QQ */

STATIC LONG X;

VOID
SetRandomSeed(LONG seed)
{
	X = (seed % MM);
}

LONG
Random(LONG maxValue)
{
	X = AA * (X % QQ) - RR * (LONG)(X / QQ);
	if(X < 0)
		X += MM;

	return(X % maxValue);
}

/****************************************************************************/

VOID
SafeBltBitMap(
	struct BitMap * src,LONG srcX,LONG srcY,
	struct BitMap * dst,LONG dstX,LONG dstY,
	LONG width,LONG height,
	LONG minTerm,LONG mask)
{
	LONG dstWidth,dstHeight;

	dstWidth	= GetBitMapAttr(dst,BMA_WIDTH);
	dstHeight	= GetBitMapAttr(dst,BMA_HEIGHT);

	if(dstX + width > dstWidth)
		width = dstWidth - dstX;

	if(dstY + height > dstHeight)
		height = dstHeight - dstY;

	if(0 <= dstX && dstX < dstWidth &&
	   0 <= dstY && dstY < dstHeight &&
	   width > 0 &&
	   height > 0)
	{
		LONG dstMask = (1UL << GetBitMapAttr(dst,BMA_DEPTH)) - 1;

		BltBitMap(src,srcX,srcY,dst,dstX,dstY,width,height,minTerm,mask & dstMask,NULL);
	}
}

/****************************************************************************/

VOID
DeleteBitMap(struct BitMap * bm)
{
	if(bm != NULL)
	{
		LONG i;

		WaitBlit();

		for(i = 0 ; i < bm->Depth ; i++)
			FreeVec(bm->Planes[i]);

		FreeVec(bm);
	}
}

struct BitMap *
CreateBitMap(LONG depth,LONG width,LONG height)
{
	struct BitMap * result = NULL;
	struct BitMap * bm;
	LONG i,bytesPerPlane;

	bm = AllocVec(sizeof(*bm),MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR);
	if(bm == NULL)
		goto out;

	InitBitMap(bm,depth,width,height);

	bytesPerPlane = bm->BytesPerRow * bm->Rows;

	for(i = 0 ; i < bm->Depth ; i++)
	{
		bm->Planes[i] = AllocVec(bytesPerPlane,MEMF_PUBLIC|MEMF_CHIP);
		if(bm->Planes[i] == NULL)
			goto out;
	}

	SafeBltBitMap(bm,0,0,bm,0,0,bm->BytesPerRow * 8,bm->Rows,MINTERM_ZERO,0xFF);

	result = bm;

 out:

	if(result == NULL)
		DeleteBitMap(bm);

	return(result);
}

/****************************************************************************/

struct BitMap *
CreateOutlineBitMap(struct BitMap * source)
{
	struct BitMap * result = NULL;
	struct BitMap * mask = NULL;
	struct BitMap * bm;
	LONG width,height;
	LONG i;

	width	= GetBitMapAttr(source,BMA_WIDTH);
	height	= GetBitMapAttr(source,BMA_HEIGHT);

	bm = CreateBitMap(1,1 + width + 1,1 + height + 1);
	if(bm == NULL)
		goto out;

	mask = CreateBitMap(1,width,height);
	if(mask == NULL)
		goto out;

	mask->Depth = 8;
	for(i = 1 ; i < 8 ; i++)
		mask->Planes[i] = mask->Planes[0];

	SafeBltBitMap(source,0,0,mask,0,0,width,height,MINTERM_B_OR_C,0xFF);

	mask->Depth = 1;

	SafeBltBitMap(mask,0,0,bm,0,1,width,height,MINTERM_B_OR_C,0xFF);
	SafeBltBitMap(mask,0,0,bm,2,1,width,height,MINTERM_B_OR_C,0xFF);
	SafeBltBitMap(mask,0,0,bm,1,0,width,height,MINTERM_B_OR_C,0xFF);
	SafeBltBitMap(mask,0,0,bm,1,2,width,height,MINTERM_B_OR_C,0xFF);

	SafeBltBitMap(mask,0,0,bm,1,1,width,height,MINTERM_NOT_B_AND_C,0xFF);

	result = bm;

 out:

	if(result == NULL)
		DeleteBitMap(bm);

	DeleteBitMap(mask);

	return(result);
}

/****************************************************************************/

BOOL
ComposeBitMap(struct BitMap * source,struct BitMap * destination,LONG left,LONG top)
{
	struct BitMap * mask;
	BOOL result = FALSE;
	LONG width,height;
	LONG i;

	width	= GetBitMapAttr(source,BMA_WIDTH);
	height	= GetBitMapAttr(source,BMA_HEIGHT);

	mask = CreateBitMap(1,width,height);
	if(mask == NULL)
		goto out;

	mask->Depth = 8;
	for(i = 1 ; i < 8 ; i++)
		mask->Planes[i] = mask->Planes[0];

	SafeBltBitMap(source,0,0,mask,0,0,width,height,MINTERM_B_OR_C,0xFF);

	SafeBltBitMap(mask,0,0,destination,left,top,width,height,MINTERM_NOT_B_AND_C,0xFF);
	SafeBltBitMap(source,0,0,destination,left,top,width,height,MINTERM_B_OR_C,0xFF);

	mask->Depth = 1;

	result = TRUE;

 out:

	DeleteBitMap(mask);

	return(result);
}

/****************************************************************************/

BOOL
ColourBitMap(struct BitMap * source,LONG colour,struct BitMap * destination,LONG left,LONG top)
{
	struct BitMap * mask;
	BOOL result = FALSE;
	struct BitMap single;
	LONG width,height;
	LONG i;

	width	= GetBitMapAttr(source,BMA_WIDTH);
	height	= GetBitMapAttr(source,BMA_HEIGHT);

	single = (*source);
	single.Depth = 8;
	for(i = 1 ; i < 8 ; i++)
		single.Planes[i] = single.Planes[0];

	mask = CreateBitMap(1,width,height);
	if(mask == NULL)
		goto out;

	mask->Depth = 8;
	for(i = 1 ; i < 8 ; i++)
		mask->Planes[i] = mask->Planes[0];

	SafeBltBitMap(source,0,0,mask,0,0,width,height,MINTERM_B_OR_C,0xFF);

	SafeBltBitMap(mask,0,0,destination,left,top,width,height,MINTERM_NOT_B_AND_C,0xFF);
	SafeBltBitMap(&single,0,0,destination,left,top,width,height,MINTERM_B_OR_C,colour);

	mask->Depth = 1;

	result = TRUE;

 out:

	DeleteBitMap(mask);

	return(result);
}

/****************************************************************************/

LONG
FindBestMatch(struct ColorRegister * cmap,LONG numColours,LONG r,LONG g,LONG b)
{
	LONG bestPen;
	LONG bestDelta;
	LONG pen;
	LONG delta;

	bestPen = 0;
	bestDelta = 0;

	for(pen = 1 ; pen < numColours ; pen++)
	{
		delta = abs((int)cmap[pen].red - r) + abs((int)cmap[pen].green - g) + abs((int)cmap[pen].blue - b);
		if(pen == 1 || delta < bestDelta)
		{
			bestDelta = delta;
			bestPen = pen;
		}
	}

	return(bestPen);
}

/****************************************************************************/

struct RGBDelta
{
	LONG red;
	LONG green;
	LONG blue;
};

/****************************************************************************/

STATIC int __inline
clamp(int x)
{
	if (x < 0)
		return(0);
	else if (x > 255)
		return(255);
	else
		return(x);
}

/****************************************************************************/

VOID
AddGlow(STRPTR fileName,STRPTR nameBuffer,STRPTR to,BOOL dither,LONG darken)
{
	STATIC UWORD CheckPattern[2] =
	{
		0x5555,
		0xAAAA
	};

	struct dtFrameBox dtf;
	struct FrameInfo fri;
	struct BitMapHeader * bmh;
	struct BitMapHeader * bmh2;
	ULONG modeID;
	struct gpLayout gpl;
	struct BitMap * srcBitMap;
	struct BitMap * dstBitMap = NULL;
	struct BitMap * bm1 = NULL;
	struct BitMap * bm2 = NULL;
	struct BitMap * outline1 = NULL;
	struct BitMap * outline2 = NULL;
	struct BitMap * outline3 = NULL;
	struct BitMap * outline4 = NULL;
	LONG dstBitMapWidth;
	LONG dstBitMapHeight;
	struct ColorRegister * cmap;
	struct ColorRegister * cmap2;
	ULONG * cregs;
	ULONG * cregs2;
	LONG numColours;
	Object * obj;
	Object * out = NULL;
	LONG error = OK;
	struct RastPort rp;
	LONG x,y;
	LONG pen;
	BPTR file = ZERO;
	LONG r,g,b;
	LONG r2,g2,b2;
	int white,yellow,brightOrange;
	struct RGBDelta * rows[2];
	struct RGBDelta * row1;
	struct RGBDelta * row2;
	struct RGBDelta * swap;

	memset(rows,0,sizeof(rows));

	Printf("Checking file \"%s\"... ",fileName);
	Flush(Output());

	obj = NewDTObject(fileName,
		DTA_SourceType,	DTST_FILE,
		DTA_GroupID,	GID_PICTURE,
		PDTA_Remap,		FALSE,
	TAG_DONE);
	if(obj == NULL)
	{
		error = IoErr();
		goto out;
	}

	memset(&dtf,0,sizeof(dtf));

	memset(&fri,0,sizeof(fri));

	dtf.MethodID			= DTM_FRAMEBOX;
	dtf.dtf_FrameInfo		= &fri;
	dtf.dtf_ContentsInfo	= &fri;
	dtf.dtf_SizeFrameInfo	= sizeof(fri);

	if(CANNOT DoMethodA(obj,(Msg)&dtf))
	{
		Printf("could not frame object\n");
		error = -1;
		goto out;
	}

	if(fri.fri_Dimensions.Depth < 1 || fri.fri_Dimensions.Depth > 8)
	{
		Printf("unsupported depth (%ld)\n",fri.fri_Dimensions.Depth);
		error = -1;
		goto out;
	}

	if((fri.fri_PropertyFlags & DIPF_IS_HAM) ||
	   (fri.fri_PropertyFlags & DIPF_IS_EXTRAHALFBRITE))
	{
		Printf("cannot handle HAM/Extra Halfbrite\n");
		error = -1;
		goto out;
	}

	memset(&gpl,0,sizeof(gpl));

	gpl.MethodID	= DTM_PROCLAYOUT;
	gpl.gpl_GInfo	= NULL;
	gpl.gpl_Initial	= 1;

	if(CANNOT DoMethodA(obj,(Msg)&gpl))
	{
		Printf("could not layout object\n");
		error = -1;
		goto out;
	}

	modeID = INVALID_ID;
	cregs = NULL;
	numColours = 0;
	bmh = NULL;
	srcBitMap = NULL;
	cmap = NULL;

	GetDTAttrs(obj,
		PDTA_ModeID,		&modeID,
		PDTA_CRegs,			&cregs,
		PDTA_NumColors,		&numColours,
		PDTA_ColorRegisters,&cmap,
		PDTA_BitMapHeader,	&bmh,
		PDTA_BitMap,		&srcBitMap,
	TAG_DONE);

	if(modeID == INVALID_ID || cregs == NULL || numColours == 0 || bmh == NULL || srcBitMap == NULL || cmap == NULL)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	dstBitMapWidth	= 4 + bmh->bmh_Width + 4;
	dstBitMapHeight	= 4 + bmh->bmh_Height + 4;

	dstBitMap = CreateBitMap(bmh->bmh_Depth,dstBitMapWidth,dstBitMapHeight);
	if(dstBitMap == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	rows[0] = AllocVec(sizeof(*rows[0]) * (2 + dstBitMapWidth),MEMF_ANY|MEMF_CLEAR);
	rows[1] = AllocVec(sizeof(*rows[1]) * (2 + dstBitMapWidth),MEMF_ANY|MEMF_CLEAR);

	if(rows[0] == NULL || rows[1] == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	row1 = rows[0] + 1;
	row2 = rows[1] + 1;

	bm1 = CreateBitMap(bmh->bmh_Depth,dstBitMapWidth,dstBitMapHeight);
	if(bm1 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	bm2 = AllocBitMap(dstBitMapWidth,dstBitMapHeight,bmh->bmh_Depth,BMF_CLEAR,NULL);
	if(bm2 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	SafeBltBitMap(srcBitMap,0,0,dstBitMap,4,4,bmh->bmh_Width,bmh->bmh_Width,MINTERM_COPY,0xFF);

	InitRastPort(&rp);
	rp.BitMap = dstBitMap;
	SetABPenDrMd(&rp,0,0,JAM2);

	if(dither)
	{
		Printf("dithering... ");
		Flush(Output());

		for(x = 0 ; x < bmh->bmh_Width ; x++)
		{
			row1[x].red		= Random(127) - 63;
			row1[x].green	= Random(127) - 63;
			row1[x].blue	= Random(127) - 63;
		}

		for(y = 0 ; y < bmh->bmh_Height ; y++)
		{
			if((y % 2) == 0)
			{
				for(x = 0 ; x < bmh->bmh_Width ; x++)
				{
					pen = ReadPixel(&rp,x+4,y+4);
					if(pen != 0)
					{
						r = cmap[pen].red;
						g = cmap[pen].green;
						b = cmap[pen].blue;
	
						r = clamp(max(0,r - darken) + row1[x].red	/ 16);
						g = clamp(max(0,g - darken) + row1[x].green	/ 16);
						b = clamp(max(0,b - darken) + row1[x].blue	/ 16);
	
						pen = FindBestMatch(cmap,numColours,r,g,b);
	
						SetAPen(&rp,pen);
						WritePixel(&rp,x+4,y+4);
	
						r2 = cmap[pen].red;
						g2 = cmap[pen].green;
						b2 = cmap[pen].blue;

						row1[x+1].red	+= (r - r2) * 7;
						row1[x+1].green	+= (g - g2) * 7;
						row1[x+1].blue	+= (b - b2) * 7;
	
						row2[x-1].red	+= (r - r2) * 3;
						row2[x-1].green	+= (g - g2) * 3;
						row2[x-1].blue	+= (b - b2) * 3;
	
						row2[x  ].red	+= (r - r2) * 5;
						row2[x  ].green	+= (g - g2) * 5;
						row2[x  ].blue	+= (b - b2) * 5;
	
						row2[x+1].red	+= (r - r2);
						row2[x+1].green	+= (g - g2);
						row2[x+1].blue	+= (b - b2);
					}
				}
			}
			else
			{
				for(x = bmh->bmh_Width - 1 ; x >= 0 ; x--)
				{
					pen = ReadPixel(&rp,x+4,y+4);
					if(pen != 0)
					{
						r = cmap[pen].red;
						g = cmap[pen].green;
						b = cmap[pen].blue;
	
						r = clamp(max(0,r - darken) + row1[x].red	/ 16);
						g = clamp(max(0,g - darken) + row1[x].green	/ 16);
						b = clamp(max(0,b - darken) + row1[x].blue	/ 16);
	
						pen = FindBestMatch(cmap,numColours,r,g,b);
	
						SetAPen(&rp,pen);
						WritePixel(&rp,x+4,y+4);
	
						r2 = cmap[pen].red;
						g2 = cmap[pen].green;
						b2 = cmap[pen].blue;
	
						row1[x-1].red	+= (r - r2) * 7;
						row1[x-1].green	+= (g - g2) * 7;
						row1[x-1].blue	+= (b - b2) * 7;
	
						row2[x+1].red	+= (r - r2) * 3;
						row2[x+1].green	+= (g - g2) * 3;
						row2[x+1].blue	+= (b - b2) * 3;
	
						row2[x  ].red	+= (r - r2) * 5;
						row2[x  ].green	+= (g - g2) * 5;
						row2[x  ].blue	+= (b - b2) * 5;
	
						row2[x-1].red	+= (r - r2);
						row2[x-1].green	+= (g - g2);
						row2[x-1].blue	+= (b - b2);
					}
				}
			}

			swap = row1;
			row1 = row2;
			row2 = swap;

			memset(row2,0,sizeof(*row2) * dstBitMapWidth);
		}
	}
	else
	{
		Printf("remapping... ");
		Flush(Output());

		for(y = 0 ; y < bmh->bmh_Height ; y++)
		{
			for(x = 0 ; x < bmh->bmh_Width ; x++)
			{
				pen = ReadPixel(&rp,x+4,y+4);
				if(pen != 0)
				{
					r = cmap[pen].red;
					g = cmap[pen].green;
					b = cmap[pen].blue;

					r = max(0,r - darken);
					g = max(0,g - darken);
					b = max(0,b - darken);

					pen = FindBestMatch(cmap,numColours,r,g,b);

					SetAPen(&rp,pen);
					WritePixel(&rp,x+4,y+4);
				}
			}
		}
	}

	Printf("making outlines... ");
	Flush(Output());

	outline1 = CreateOutlineBitMap(srcBitMap);	/* 1+1 */
	if(outline1 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	outline2 = CreateOutlineBitMap(outline1);	/* 2+2 */
	if(outline2 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	outline3 = CreateOutlineBitMap(outline2);	/* 3+3 */
	if(outline3 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	outline4 = CreateOutlineBitMap(outline3);	/* 4+4 */
	if(outline4 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	SetAfPt(&rp,CheckPattern,1);
	rp.BitMap = outline4;
	SetABPenDrMd(&rp,0,0,JAM1);

	RectFill(&rp,0,0,(4+bmh->bmh_Width+4)-1,(4+bmh->bmh_Height+4)-1);

	Printf("composing... ");
	Flush(Output());

	white			= FindBestMatch(cmap,numColours,0xFF,0xFF,0xFF);
	yellow			= FindBestMatch(cmap,numColours,0xEF,0xE7,0x14);
	brightOrange	= FindBestMatch(cmap,numColours,0xDF,0xBA,0x45);

	if(CANNOT ColourBitMap(outline4,brightOrange,bm1,0,0))
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(CANNOT ColourBitMap(outline3,brightOrange,bm1,1,1))
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(CANNOT ColourBitMap(outline2,yellow,bm1,2,2))
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(CANNOT ColourBitMap(outline1,white,bm1,3,3))
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(CANNOT ComposeBitMap(dstBitMap,bm1,0,0))
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	WaitBlit();

	Printf("creating picture... ");
	Flush(Output());

	out = NewDTObject(FilePart(fileName),
		DTA_SourceType,		DTST_RAM,
		DTA_GroupID,		GID_PICTURE,
		PDTA_NumColors,		numColours,
		PDTA_BitMap,		bm2,
		PDTA_ModeID,		modeID,
	TAG_DONE);
	if(out == NULL)
	{
		error = IoErr();
		goto out;
	}

	SafeBltBitMap(bm1,0,0,bm2,0,0,dstBitMapWidth,dstBitMapHeight,MINTERM_COPY,0xFF);
	WaitBlit();

	bm2 = NULL;

	if(GetDTAttrs(out,
		PDTA_BitMapHeader,		&bmh2,
		PDTA_ColorRegisters,	&cmap2,
		PDTA_CRegs,				&cregs2,
	TAG_DONE) != 3)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	memset(bmh2,0,sizeof(*bmh2));

	bmh2->bmh_Left			= bmh->bmh_Left;
	bmh2->bmh_Top			= bmh->bmh_Top;
	bmh2->bmh_Width			= dstBitMapWidth;
	bmh2->bmh_Height		= dstBitMapHeight;
	bmh2->bmh_Depth			= bmh->bmh_Depth;
	bmh2->bmh_PageWidth		= max(bmh2->bmh_Width,bmh->bmh_PageWidth);
	bmh2->bmh_PageHeight	= max(bmh2->bmh_Height,bmh->bmh_PageHeight);
	bmh2->bmh_Transparent	= 0;
	bmh2->bmh_Masking		= mskHasTransparentColor;
	bmh2->bmh_XAspect		= 1;
	bmh2->bmh_YAspect		= 1;

	memcpy(cregs2,cregs,numColours * 3 * sizeof(ULONG));
	memcpy(cmap2,cmap,numColours * sizeof(*cmap));

	if(to != NULL)
	{
		strcpy(nameBuffer,to);
		AddPart(nameBuffer,FilePart(fileName),MatchLen);
		strcat(nameBuffer,GlowSuffix);
	}
	else
	{
		strcpy(nameBuffer,fileName);
		strcat(nameBuffer,GlowSuffix);
	}

	Printf("writing file \"%s\"... ",nameBuffer);
	Flush(Output());

	file = Open(nameBuffer,MODE_NEWFILE);
	if(file == ZERO)
	{
		error = IoErr();
		goto out;
	}

	if(CANNOT DoMethod(out,DTM_WRITE,NULL,file,DTWM_IFF,NULL))
	{
		error = IoErr();
		Close(file);
		file = ZERO;
		DeleteFile(nameBuffer);
		goto out;
	}

 out:

	FreeVec(rows[0]);
	FreeVec(rows[1]);

	if(file != ZERO)
		Close(file);

	FreeBitMap(bm2);

	DeleteBitMap(outline1);
	DeleteBitMap(outline2);
	DeleteBitMap(outline3);
	DeleteBitMap(outline4);

	DeleteBitMap(dstBitMap);
	DeleteBitMap(bm1);

	DisposeDTObject(obj);
	DisposeDTObject(out);

	if(error != -1)
	{
		if(error == OK)
		{
			Printf("Ok\n");
		}
		else
		{
			if(error < 2000)
			{
				UBYTE buffer[100];

				Fault(error,NULL,buffer,sizeof(buffer));
				Printf("%s\n",buffer);
			}
			else
			{
				Printf("%s\n",GetDTString(error));
			}
		}
	}
}

/****************************************************************************/

VOID
AddPadding(STRPTR fileName,STRPTR nameBuffer,STRPTR to)
{
	struct dtFrameBox dtf;
	struct FrameInfo fri;
	struct BitMapHeader * bmh;
	struct BitMapHeader * bmh2;
	ULONG modeID;
	struct gpLayout gpl;
	struct BitMap * srcBitMap;
	struct BitMap * dstBitMap = NULL;
	LONG dstBitMapWidth;
	LONG dstBitMapHeight;
	struct ColorRegister * cmap;
	struct ColorRegister * cmap2;
	ULONG * cregs;
	ULONG * cregs2;
	LONG numColours;
	Object * obj;
	Object * out = NULL;
	LONG error = OK;
	BPTR file = ZERO;

	Printf("Checking file \"%s\"... ",fileName);
	Flush(Output());

	obj = NewDTObject(fileName,
		DTA_SourceType,	DTST_FILE,
		DTA_GroupID,	GID_PICTURE,
		PDTA_Remap,		FALSE,
	TAG_DONE);
	if(obj == NULL)
	{
		error = IoErr();
		goto out;
	}

	memset(&dtf,0,sizeof(dtf));

	memset(&fri,0,sizeof(fri));

	dtf.MethodID			= DTM_FRAMEBOX;
	dtf.dtf_FrameInfo		= &fri;
	dtf.dtf_ContentsInfo	= &fri;
	dtf.dtf_SizeFrameInfo	= sizeof(fri);

	if(CANNOT DoMethodA(obj,(Msg)&dtf))
	{
		Printf("could not frame object\n");
		error = -1;
		goto out;
	}

	if(fri.fri_Dimensions.Depth < 1 || fri.fri_Dimensions.Depth > 8)
	{
		Printf("unsupported depth (%ld)\n",fri.fri_Dimensions.Depth);
		error = -1;
		goto out;
	}

	if((fri.fri_PropertyFlags & DIPF_IS_HAM) ||
	   (fri.fri_PropertyFlags & DIPF_IS_EXTRAHALFBRITE))
	{
		Printf("cannot handle HAM/Extra Halfbrite\n");
		error = -1;
		goto out;
	}

	memset(&gpl,0,sizeof(gpl));

	gpl.MethodID	= DTM_PROCLAYOUT;
	gpl.gpl_GInfo	= NULL;
	gpl.gpl_Initial	= 1;

	if(CANNOT DoMethodA(obj,(Msg)&gpl))
	{
		Printf("could not layout object\n");
		error = -1;
		goto out;
	}

	modeID = INVALID_ID;
	cregs = NULL;
	numColours = 0;
	bmh = NULL;
	srcBitMap = NULL;
	cmap = NULL;

	GetDTAttrs(obj,
		PDTA_ModeID,		&modeID,
		PDTA_CRegs,			&cregs,
		PDTA_NumColors,		&numColours,
		PDTA_ColorRegisters,&cmap,
		PDTA_BitMapHeader,	&bmh,
		PDTA_BitMap,		&srcBitMap,
	TAG_DONE);

	if(modeID == INVALID_ID || cregs == NULL || numColours == 0 || bmh == NULL || srcBitMap == NULL || cmap == NULL)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	dstBitMapWidth	= 4 + bmh->bmh_Width + 4;
	dstBitMapHeight	= 4 + bmh->bmh_Height + 4;

	dstBitMap = AllocBitMap(dstBitMapWidth,dstBitMapHeight,bmh->bmh_Depth,BMF_CLEAR,NULL);
	if(dstBitMap == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	Printf("padding... ");
	Flush(Output());

	SafeBltBitMap(srcBitMap,0,0,dstBitMap,4,4,bmh->bmh_Width,bmh->bmh_Width,MINTERM_COPY,0xFF);
	WaitBlit();

	Printf("creating picture... ");
	Flush(Output());

	out = NewDTObject(FilePart(fileName),
		DTA_SourceType,		DTST_RAM,
		DTA_GroupID,		GID_PICTURE,
		PDTA_NumColors,		numColours,
		PDTA_BitMap,		dstBitMap,
		PDTA_ModeID,		modeID,
	TAG_DONE);
	if(out == NULL)
	{
		error = IoErr();
		goto out;
	}

	dstBitMap = NULL;

	if(GetDTAttrs(out,
		PDTA_BitMapHeader,		&bmh2,
		PDTA_ColorRegisters,	&cmap2,
		PDTA_CRegs,				&cregs2,
	TAG_DONE) != 3)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	memset(bmh2,0,sizeof(*bmh2));

	bmh2->bmh_Left			= bmh->bmh_Left;
	bmh2->bmh_Top			= bmh->bmh_Top;
	bmh2->bmh_Width			= dstBitMapWidth;
	bmh2->bmh_Height		= dstBitMapHeight;
	bmh2->bmh_Depth			= bmh->bmh_Depth;
	bmh2->bmh_PageWidth		= max(bmh2->bmh_Width,bmh->bmh_PageWidth);
	bmh2->bmh_PageHeight	= max(bmh2->bmh_Height,bmh->bmh_PageHeight);
	bmh2->bmh_Transparent	= 0;
	bmh2->bmh_Masking		= mskHasTransparentColor;
	bmh2->bmh_XAspect		= 1;
	bmh2->bmh_YAspect		= 1;

	memcpy(cregs2,cregs,numColours * 3 * sizeof(ULONG));
	memcpy(cmap2,cmap,numColours * sizeof(*cmap));

	if(to != NULL)
	{
		strcpy(nameBuffer,to);
		AddPart(nameBuffer,FilePart(fileName),MatchLen);
		strcat(nameBuffer,PadSuffix);
	}
	else
	{
		strcpy(nameBuffer,fileName);
		strcat(nameBuffer,PadSuffix);
	}

	Printf("writing file \"%s\"... ",nameBuffer);
	Flush(Output());

	file = Open(nameBuffer,MODE_NEWFILE);
	if(file == ZERO)
	{
		error = IoErr();
		goto out;
	}

	if(CANNOT DoMethod(out,DTM_WRITE,NULL,file,DTWM_IFF,NULL))
	{
		error = IoErr();
		Close(file);
		file = ZERO;
		DeleteFile(nameBuffer);
		goto out;
	}

 out:

	if(file != ZERO)
		Close(file);

	FreeBitMap(dstBitMap);

	DisposeDTObject(obj);
	DisposeDTObject(out);

	if(error != -1)
	{
		if(error == OK)
		{
			Printf("Ok\n");
		}
		else
		{
			if(error < 2000)
			{
				UBYTE buffer[100];

				Fault(error,NULL,buffer,sizeof(buffer));
				Printf("%s\n",buffer);
			}
			else
			{
				Printf("%s\n",GetDTString(error));
			}
		}
	}
}

/****************************************************************************/

int
main(int argc,char ** argv)
{
	struct
	{
		KEY *	Files;
		KEY		To;
		SWITCH	Dither;
		NUMBER	Darken;
		SWITCH	Pad;
	} args;
	STRPTR argsTemplate =
		"FILES/M,"
		"TO/K,"
		"DITHER/S,"
		"DARKEN/K/N,"
		"PAD/S";

	struct AnchorPath * ap = NULL;
	BOOL matched = FALSE;
	struct RDArgs * rda = NULL;
	STRPTR * files;
	STRPTR file;
	int result = RETURN_FAIL;
	LONG error = OK;
	STRPTR altBuffer = NULL;
	STRPTR name = NULL;
	BOOL isFile;
	LONG darken;
	ULONG a,b;

	if(SysBase->lib_Version < 39)
	{
		printf("AmigaOS 3.0 required.\n");
		goto out;
	}

	memset(&args,0,sizeof(args));

	ap = AllocVec(sizeof(*ap) + MatchLen,MEMF_ANY|MEMF_PUBLIC);
	if(ap == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	memset(ap,0,sizeof(*ap));
	ap->ap_Strlen		= MatchLen;
	ap->ap_BreakBits	= SIGBREAKF_CTRL_C;

	altBuffer = AllocVec(MatchLen + 40,MEMF_ANY|MEMF_PUBLIC);
	if(altBuffer == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	name = AllocVec(MatchLen + 1,MEMF_ANY|MEMF_PUBLIC);
	if(name == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	rda = ReadArgs(argsTemplate,(LONG *)&args,NULL);
	if(rda == NULL)
	{
		error = IoErr();
		goto out;
	}

	files = args.Files;
	if(files == NULL)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	CurrentTime(&a,&b);

	SetRandomSeed(a+b);

	if(args.Darken != NULL)
		darken = (*args.Darken);
	else
		darken = 40;

	while((file = (*files++)) != NULL)
	{
		if(matched)
		{
			MatchEnd(ap);

			memset(ap,0,sizeof(*ap));
			ap->ap_Strlen		= MatchLen;
			ap->ap_BreakBits	= SIGBREAKF_CTRL_C;
		}

		error = MatchFirst(file,ap);
		matched = TRUE;

		if(FIB_IS_DRAWER(&ap->ap_Info))
			ap->ap_Flags |= APF_DODIR;

		while(error == OK)
		{
			isFile = FIB_IS_FILE(&ap->ap_Info);
			if(isFile)
				strcpy(name,ap->ap_Buf);

			error = MatchNext(ap);

			if(isFile)
			{
				int len = strlen(name);

				if(args.Pad)
				{
					if(len > strlen(PadSuffix) && Stricmp(&name[len - strlen(PadSuffix)],(STRPTR)PadSuffix) == SAME)
						continue;

					AddPadding(name,altBuffer,args.To);
				}
				else
				{
					if(len > strlen(GlowSuffix) && Stricmp(&name[len - strlen(GlowSuffix)],(STRPTR)GlowSuffix) == SAME)
						continue;

					AddGlow(name,altBuffer,args.To,args.Dither,darken);
				}
			}
		}

		if(error == ERROR_NO_MORE_ENTRIES)
			error = OK;

		if(error != OK && error != ERROR_NO_MORE_ENTRIES)
			break;
	}

	if(error == OK || error == ERROR_BREAK)
		result = RETURN_OK;

 out:

	if(error != OK)
		PrintFault(error,FilePart(argv[0]));

	if(altBuffer != NULL)
		FreeVec(altBuffer);

	if(name != NULL)
		FreeVec(name);

	if(ap != NULL)
	{
		if(matched)
			MatchEnd(ap);

		FreeVec(ap);
	}

	if(rda != NULL)
		FreeArgs(rda);

	return(result);
}
