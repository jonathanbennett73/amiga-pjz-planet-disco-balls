/*
 * $Id$
 *
 * :ts=4
 */

#include <dos/dosextens.h>
#include <dos/dosasl.h>
#include <dos/rdargs.h>

#include <exec/memory.h>

#include <workbench/workbench.h>

#include <intuition/gadgetclass.h>

#include <datatypes/datatypes.h>
#include <datatypes/pictureclass.h>

#include <clib/exec_protos.h>
#include <clib/intuition_protos.h>
#include <clib/datatypes_protos.h>
#include <clib/utility_protos.h>
#include <clib/graphics_protos.h>
#include <clib/dos_protos.h>
#include <clib/alib_protos.h>

#include <pragmas/exec_sysbase_pragmas.h>
#include <pragmas/intuition_pragmas.h>
#include <pragmas/datatypes_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/graphics_pragmas.h>
#include <pragmas/dos_pragmas.h>

#define USE_BUILTIN_MATH
#include <string.h>

/****************************************************************************/

extern struct Library * SysBase;
extern struct Library * DOSBase;
extern struct Library * UtilityBase;
extern struct Library * DataTypesBase;
extern struct Library * IntuitionBase;
extern struct Library * GfxBase;
extern struct Library * IconBase;

/****************************************************************************/

#include "/icon.h"
#include "/PROTOS/public_icon_protos.h"
#include "/PRAGMAS/public_icon_pragmas.h"

/****************************************************************************/

#define CANNOT !
#define OK (0)
#define SAME (0)

/****************************************************************************/

UBYTE Default4Palette[4][3] =
{
	0xAA,0xAA,0xAA,
	0x00,0x00,0x00,
	0xFF,0xFF,0xFF,
	0x65,0x8A,0xBA
};

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
ImageToBitMap(
	struct Image *	image,
	struct BitMap *	bitMap)
{
	PLANEPTR plane;
	LONG pageSize;
	LONG i;

	memset(bitMap,0,sizeof(*bitMap));

	bitMap->BytesPerRow	= RASSIZE(image->Width,1);
	bitMap->Rows		= image->Height;
	bitMap->Depth		= image->Depth;

	pageSize = RASSIZE(image->Width,image->Height);
	plane = (PLANEPTR)image->ImageData;

	for(i = 0 ; i < image->Depth ; i++)
	{
		bitMap->Planes[i] = plane;

		plane += pageSize;
	}
}

/****************************************************************************/

VOID
DeleteImage(struct Image * image)
{
	if(image != NULL)
	{
		if(image->ImageData)
		{
			LONG numBytes = RASSIZE(image->Width,image->Height) * image->Depth;

			WaitBlit();

			FreeMem(image->ImageData,numBytes);
		}

		FreeVec(image);
	}
}

struct Image *
CreateImage(LONG depth,LONG width,LONG height)
{
	struct Image * result = NULL;
	struct Image * image;

	image = AllocVec(sizeof(*image),MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR);
	if(image != NULL)
	{
		LONG numBytes;

		image->Width		= width;
		image->Height		= height;
		image->Depth		= depth;
		image->PlanePick	= (1L<<depth)-1;

		numBytes = RASSIZE(width,height) * depth;
		image->ImageData = AllocMem(numBytes,MEMF_CHIP);
		if(image->ImageData != NULL)
		{
			BltClear((PLANEPTR)image->ImageData,numBytes,1);
			result = image;
		}
	}

	if(result == NULL)
		DeleteImage(image);

	return(result);
}

/****************************************************************************/

typedef STRPTR	KEY;
typedef LONG	SWITCH;

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

LONG
DitherToImage(struct BitMap * bmap,struct ColorRegister * cmap,LONG numColours,LONG width,LONG height,struct Image * image)
{
	struct RastPort rp;
	struct RastPort rp2;
	struct BitMap bmap2;
	int x,y,i,pen,d,delta,best,r,g,b,r2,g2,b2;
	struct RGBDelta * rows[2];
	struct RGBDelta * row1;
	struct RGBDelta * row2;
	struct RGBDelta * swap;
	LONG error = OK;

	memset(rows,0,sizeof(rows));

	rows[0] = AllocVec(sizeof(*rows[0]) * (2 + width),MEMF_ANY|MEMF_CLEAR);
	rows[1] = AllocVec(sizeof(*rows[1]) * (2 + width),MEMF_ANY|MEMF_CLEAR);

	if(rows[0] == NULL || rows[1] == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	row1 = rows[0] + 1;
	row2 = rows[1] + 1;

	InitRastPort(&rp);
	rp.BitMap = bmap;

	ImageToBitMap(image,&bmap2);
	InitRastPort(&rp2);
	rp2.BitMap = &bmap2;

	SetABPenDrMd(&rp2,0,0,JAM2);

	for(x = 0 ; x < width ; x++)
	{
		row1[x].red		= Random(127) - 63;
		row1[x].green	= Random(127) - 63;
		row1[x].blue	= Random(127) - 63;
	}

	for(y = 0 ; y < height ; y++)
	{
		if((y % 2) == 0)
		{
			for(x = 0 ; x < width ; x++)
			{
				pen = ReadPixel(&rp,x,y);

				r = clamp(cmap[pen].red		+ row1[x].red	/ 16);
				g = clamp(cmap[pen].green	+ row1[x].green	/ 16);
				b = clamp(cmap[pen].blue	+ row1[x].blue	/ 16);

				best = delta = 0;

				for(i = 0 ; i < 4 ; i++)
				{
					d = abs(r - Default4Palette[i][0]) +
					    abs(g - Default4Palette[i][1]) +
					    abs(b - Default4Palette[i][2]);

					if(i == 0 || d < delta)
					{
						delta = d;
						best = i;
					}
				}

				SetAPen(&rp2,best);
				WritePixel(&rp2,x,y);

				r2 = Default4Palette[best][0];
				g2 = Default4Palette[best][1];
				b2 = Default4Palette[best][2];

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
		else
		{
			for(x = width - 1 ; x >= 0 ; x--)
			{
				pen = ReadPixel(&rp,x,y);

				r = clamp(cmap[pen].red		+ row1[x].red	/ 16);
				g = clamp(cmap[pen].green	+ row1[x].green	/ 16);
				b = clamp(cmap[pen].blue	+ row1[x].blue	/ 16);

				best = delta = 0;

				for(i = 0 ; i < 4 ; i++)
				{
					d = abs(r - Default4Palette[i][0]) +
					    abs(g - Default4Palette[i][1]) +
					    abs(b - Default4Palette[i][2]);

					if(i == 0 || d < delta)
					{
						delta = d;
						best = i;
					}
				}

				SetAPen(&rp2,best);
				WritePixel(&rp2,x,y);

				r2 = Default4Palette[best][0];
				g2 = Default4Palette[best][1];
				b2 = Default4Palette[best][2];

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

		swap = row1;
		row1 = row2;
		row2 = swap;

		memset(row2,0,sizeof(*row2) * width);
	}

 out:

	FreeVec(rows[0]);
	FreeVec(rows[1]);

	return(error);
}

VOID
RemapToImage(struct BitMap * bmap,struct ColorRegister * cmap,LONG numColours,LONG width,LONG height,struct Image * image)
{
	struct RastPort rp;
	struct RastPort rp2;
	struct BitMap bmap2;
	int x,y,i,pen,d,delta,best,r,g,b;

	InitRastPort(&rp);
	rp.BitMap = bmap;

	ImageToBitMap(image,&bmap2);
	InitRastPort(&rp2);
	rp2.BitMap = &bmap2;

	SetABPenDrMd(&rp2,0,0,JAM2);

	for(y = 0 ; y < height ; y++)
	{
		for(x = 0 ; x < width ; x++)
		{
			pen = ReadPixel(&rp,x,y);

			r = cmap[pen].red;
			g = cmap[pen].green;
			b = cmap[pen].blue;

			best = delta = 0;

			for(i = 0 ; i < 4 ; i++)
			{
				d = abs(r - Default4Palette[i][0]) +
				    abs(g - Default4Palette[i][1]) +
				    abs(b - Default4Palette[i][2]);

				if(i == 0 || d < delta)
				{
					delta = d;
					best = i;
				}
			}

			SetAPen(&rp2,best);
			WritePixel(&rp2,x,y);
		}
	}
}

/****************************************************************************/

int
main(int argc,char **argv)
{
	struct { STRPTR Name; LONG ID; } TypeTable[] =
	{
		"DISK",		WBDISK,
		"DRAWER",	WBDRAWER,
		"TOOL",		WBTOOL,
		"PROJECT",	WBPROJECT,
		"TRASH",	WBGARBAGE,
		"TRASHCAN",	WBGARBAGE,
		"GARBAGE",	WBGARBAGE,
		"DEVICE",	WBDEVICE,
		NULL
	};

	struct { KEY Image1; KEY Image2; KEY To; SWITCH Borderless; SWITCH Dither; KEY Type; } args;
	struct RDArgs * rda = NULL;
	int result = RETURN_FAIL;
	Object * picture1 = NULL;
	Object * picture2 = NULL;
	LONG error = OK;
	struct dtFrameBox dtf;
	struct FrameInfo fri;
	struct BitMapHeader * bmh1 = NULL;
	struct BitMapHeader * bmh2 = NULL;
	struct ColorRegister * cmap1 = NULL;
	struct ColorRegister * cmap2 = NULL;
	struct BitMap * bmap1 = NULL;
	struct BitMap * bmap2 = NULL;
	LONG numColours1 = 0;
	LONG numColours2 = 0;
	struct gpLayout gpl;
	struct DiskObject * icon = NULL;
	UBYTE * buffer1 = NULL;
	UBYTE * buffer2 = NULL;
	struct Image * image1 = NULL;
	struct Image * image2 = NULL;
	int x,y;
	struct RastPort rp;
	UBYTE * t;
	LONG type;
	int i;
	ULONG a,b;

	if(IconBase->lib_Version < 44)
	{
		Printf("Could not open icon.library V44\n");
		goto out;
	}

	CurrentTime(&a,&b);
	SetRandomSeed(a+b);

	memset(&args,0,sizeof(args));

	rda = ReadArgs("IMAGE1,IMAGE2,TO/A,BORDERLESS/S,DITHER/S,TYPE/K",(LONG *)&args,NULL);
	if(rda == NULL)
	{
		error = IoErr();
		goto out;
	}

	type = WBTOOL;

	if(args.Type != NULL)
	{
		for(i = 0 ; TypeTable[i].Name != NULL ; i++)
		{
			if(Stricmp(TypeTable[i].Name,args.Type) == SAME)
			{
				type = TypeTable[i].ID;
				break;
			}
		}
	}

	if(args.Image1 == NULL)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	picture1 = NewDTObject(args.Image1,
		DTA_SourceType,	DTST_FILE,
		DTA_GroupID,	GID_PICTURE,
		PDTA_Remap,		FALSE,
	TAG_DONE);
	if(picture1 == NULL)
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

	if(CANNOT DoMethodA(picture1,(Msg)&dtf))
	{
		Printf("%s: Could not frame object\n",args.Image1);
		error = -1;
		goto out;
	}

	if(fri.fri_Dimensions.Depth < 1 || fri.fri_Dimensions.Depth > 8)
	{
		Printf("%s: Unsupported depth (%ld)\n",args.Image1,fri.fri_Dimensions.Depth);
		error = -1;
		goto out;
	}

	if((fri.fri_PropertyFlags & DIPF_IS_HAM) ||
	   (fri.fri_PropertyFlags & DIPF_IS_EXTRAHALFBRITE))
	{
		Printf("%s: Cannot handle HAM/Extra Halfbrite\n",args.Image1);
		error = -1;
		goto out;
	}

	memset(&gpl,0,sizeof(gpl));

	gpl.MethodID	= DTM_PROCLAYOUT;
	gpl.gpl_GInfo	= NULL;
	gpl.gpl_Initial	= 1;

	if(CANNOT DoMethodA(picture1,(Msg)&gpl))
	{
		Printf("%s: Could not layout object\n",args.Image1);
		error = -1;
		goto out;
	}

	GetDTAttrs(picture1,
		PDTA_NumColors,		&numColours1,
		PDTA_ColorRegisters,&cmap1,
		PDTA_BitMapHeader,	&bmh1,
		PDTA_BitMap,		&bmap1,
	TAG_DONE);

	if(numColours1 == 0 || cmap1 == NULL || bmh1 == NULL || bmap1 == NULL)
	{
		Printf("%s: Invalid object data\n",args.Image1);
		error = -1;
		goto out;
	}

	if(args.Image2 != NULL)
	{
		picture2 = NewDTObject(args.Image2,
			DTA_SourceType,	DTST_FILE,
			DTA_GroupID,	GID_PICTURE,
			PDTA_Remap,		FALSE,
		TAG_DONE);
		if(picture2 == NULL)
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

		if(CANNOT DoMethodA(picture2,(Msg)&dtf))
		{
			Printf("%s: Could not frame object\n",args.Image2);
			error = -1;
			goto out;
		}

		if(fri.fri_Dimensions.Depth < 1 || fri.fri_Dimensions.Depth > 8)
		{
			Printf("%s: Unsupported depth (%ld)\n",args.Image2,fri.fri_Dimensions.Depth);
			error = -1;
			goto out;
		}

		if((fri.fri_PropertyFlags & DIPF_IS_HAM) ||
		   (fri.fri_PropertyFlags & DIPF_IS_EXTRAHALFBRITE))
		{
			Printf("%s: Cannot handle HAM/Extra Halfbrite\n",args.Image2);
			error = -1;
			goto out;
		}

		memset(&gpl,0,sizeof(gpl));

		gpl.MethodID	= DTM_PROCLAYOUT;
		gpl.gpl_GInfo	= NULL;
		gpl.gpl_Initial	= 1;

		if(CANNOT DoMethodA(picture2,(Msg)&gpl))
		{
			Printf("%s: Could not layout object\n",args.Image2);
			error = -1;
			goto out;
		}

		GetDTAttrs(picture2,
			PDTA_NumColors,		&numColours2,
			PDTA_ColorRegisters,&cmap2,
			PDTA_BitMapHeader,	&bmh2,
			PDTA_BitMap,		&bmap2,
		TAG_DONE);

		if(numColours2 == 0 || cmap2 == NULL || bmh2 == NULL || bmap2 == NULL)
		{
			Printf("%s: Invalid object data\n",args.Image2);
			error = -1;
			goto out;
		}

		if(numColours1 != numColours2)
		{
			Printf("%s: \"%s\" and \"%s\" do not use the same number of colours\n",FilePart(argv[0]),args.Image1,args.Image2);
			error = -1;
			goto out;
		}

		if(bmh1->bmh_Width != bmh2->bmh_Width || bmh1->bmh_Height != bmh2->bmh_Height)
		{
			Printf("%s: \"%s\" and \"%s\" are not the same size\n",FilePart(argv[0]),args.Image1,args.Image2);
			error = -1;
			goto out;
		}

		buffer2 = AllocVec(bmh1->bmh_Width * bmh1->bmh_Height,MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR);
		if(buffer2 == NULL)
		{
			error = ERROR_NO_FREE_STORE;
			goto out;
		}

		image2 = CreateImage(2,bmh1->bmh_Width,bmh1->bmh_Height);
		if(image2 == NULL)
		{
			error = ERROR_NO_FREE_STORE;
			goto out;
		}
	}

	image1 = CreateImage(2,bmh1->bmh_Width,bmh1->bmh_Height);
	if(image1 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	if(args.Dither)
	{
		error = DitherToImage(bmap1,cmap1,numColours1,bmh1->bmh_Width,bmh1->bmh_Height,image1);
		if(error != OK)
			goto out;

		if(image2 != NULL)
		{
			error = DitherToImage(bmap2,cmap2,numColours2,bmh1->bmh_Width,bmh1->bmh_Height,image2);
			if(error != OK)
				goto out;
		}
	}
	else
	{
		RemapToImage(bmap1,cmap1,numColours1,bmh1->bmh_Width,bmh1->bmh_Height,image1);

		if(image2 != NULL)
			RemapToImage(bmap2,cmap2,numColours2,bmh1->bmh_Width,bmh1->bmh_Height,image2);
	}

	buffer1 = AllocVec(bmh1->bmh_Width * bmh1->bmh_Height,MEMF_ANY|MEMF_PUBLIC|MEMF_CLEAR);
	if(buffer1 == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	icon = GetDefDiskObject(type);
	if(icon == NULL)
	{
		error = IoErr();
		goto out;
	}

	InitRastPort(&rp);
	rp.BitMap = bmap1;

	t = buffer1;

	for(y = 0 ; y < bmh1->bmh_Height ; y++)
	{
		for(x = 0 ; x < bmh1->bmh_Width ; x++)
			(*t++) = ReadPixel(&rp,x,y);
	}

	if(picture2 != NULL)
	{
		rp.BitMap = bmap2;
	
		t = buffer2;
	
		for(y = 0 ; y < bmh1->bmh_Height ; y++)
		{
			for(x = 0 ; x < bmh1->bmh_Width ; x++)
				(*t++) = ReadPixel(&rp,x,y);
		}
	}

	IconControl(icon,
		ICONCTRLA_SetWidth,			bmh1->bmh_Width,
		ICONCTRLA_SetHeight,		bmh1->bmh_Height,
		ICONCTRLA_SetAspectRatio,	PACK_ICON_ASPECT_RATIO(1,1),
		ICONCTRLA_SetImageData1,	buffer1,
		ICONCTRLA_SetPaletteSize1,	numColours1,
		ICONCTRLA_SetPalette1,		cmap1,
		ICONCTRLA_SetTransparentColor1,(bmh1->bmh_Masking == mskHasTransparentColor) ? bmh1->bmh_Transparent : -1,
		ICONCTRLA_SetFrameless,		args.Borderless,
		ICONA_ErrorCode,			&error,
	TAG_DONE);
	if(error != OK)
		goto out;

	if(picture2 != NULL)
	{
		IconControl(icon,
			ICONCTRLA_SetImageData2,	buffer2,
			ICONCTRLA_SetPaletteSize2,	numColours2,
			ICONCTRLA_SetPalette2,		cmap2,
			ICONCTRLA_SetTransparentColor2,(bmh2->bmh_Masking == mskHasTransparentColor) ? bmh2->bmh_Transparent : -1,
			ICONA_ErrorCode,			&error,
		TAG_DONE);
		if(error != OK)
			goto out;
	}

	icon->do_Gadget.Width			= image1->Width;
	icon->do_Gadget.Height			= image1->Height;
	icon->do_Gadget.GadgetRender	= image1;

	if(image2 != NULL)
	{
		icon->do_Gadget.Flags = (icon->do_Gadget.Flags & ~GFLG_GADGHIGHBITS) | GFLG_GADGHIMAGE;
		icon->do_Gadget.SelectRender = image2;
	}
	else
	{
		icon->do_Gadget.Flags = (icon->do_Gadget.Flags & ~GFLG_GADGHIGHBITS) | GFLG_GADGHCOMP;
		icon->do_Gadget.SelectRender = NULL;
	}

	PutIconTags(args.To,icon,
		ICONA_ErrorCode,&error,
		ICONPUTA_NotifyWorkbench,TRUE,
	TAG_DONE);
	if(error != OK)
		goto out;

	result = RETURN_OK;

 out:

	if(picture1 != NULL)
		DisposeDTObject(picture1);

	if(picture2 != NULL)
		DisposeDTObject(picture2);

	FreeVec(buffer1);
	FreeVec(buffer2);

	if(icon != NULL)
		FreeDiskObject(icon);

	DeleteImage(image1);
	DeleteImage(image2);

	FreeArgs(rda);

	if(error != OK && error != -1)
		PrintFault(error,FilePart(argv[0]));

	return(result);
}
