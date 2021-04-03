/*   Open a window & scale a bitmap   
*/ SET TABS TO 8
/* PLEASE TAKE NOTE  I DO NOT EVEN OWN A C COMPILER!!
IT MOST PROBABLY DOES NOT WORK BUT ITS FAIRLY CLOSE I THINK. IT IS FOR
DEMONSTRATION PURPOSES ONLY FOR THE ENCONN.CODEMANUAL VOLUME2!!!!!!!!

AS WITH THE CODEMANUAL, LINES MARKED WITH "!" are Additions or
Corrections added in by Andrew Patterson.

*/

#include <exec/types.h>
#include <intuition/intuition.h>
#include <graphics/scale.h>
#include <graphics/gfx.h>
#include <graphics/rastport.h>

struct IntuitionBase *IntuitionBase;
struct GfxBase *GfxBase;

/*************************************/

/*
Mydat = incbin 'dh0:bmap' HEEHEE. This is wrong. I thing they are supposed
to link in binary files later MAKE SURE ITS IN CHIP RAM
*/

/*
! If only you could. the actual code is something like
! extern UBYTE MyDat[];
! And the person has to compile mydat seperately and link it in later.
*/

extern UBYTE MyDat[];

/*****************************/

void main()
{
struct Window *win;
struct BitMap bm;
struct TagItem wdtags =
 {
 WA_Top, 20,
 WA_Left, 100,
 WA_InnerWidth, 100,
 WA_InnerHeight, 100,
 WA_Flags, WFLG_DRAGBAR | WFLG_ACTIVATE | 
           WFLG_DEPTHGADGET,
 WA_Title, "Scaling",
 }
struct BitScaleArgs bsa;


    if (IntuitionBase = OpenLibrary("intuition.library", 37))
    {
        if (GfxBase = OpenLibrary("graphics.library", 37))
	 {
		if (win = OpenWindowTagList(NULL,&wdtags)
		{
		InitBitMap(&bm,3,400,200);

                bm.Planes[0] = &MyDat[0];
                bm.Planes[1] = &MyDat[10000];
                bm.Planes[2] = &MyDat[20000];

		bsa.SrcX = 0;
		bsa.SrcY = 0;
		bsa.SrcWidth = 400;
 		bsa.SrcHeight = 200;
                bsa.XSrcFactor = 400;
		bsa.YSrcFactor = 200;
                bsa.DestX = win->BorderLeft;
		bsa.DestY = win->BorderTop;
                bsa.DestWidth = 0;
		bsa.DestHeight = 0;
 		bsa.XDestFactor = 400;
                bsa.YDestFactor = 200;
		bsa.SrcBitMap = &bm;
		bsa.DestBitMap = win->Rport.BitMap;
		bsa.Flags = 0;
                bsa.XDDA = 0;
                bsa.YDDA = 0;

		BitMapScale(&bsa);

		Delay(50);
/*
!		How about a SetRast(win->Rport,0) so that the window is
!		cleared before the next bitmap scale
*/
		bsa.XDestFactor = 650;
                bsa.YDestFactor = 250;

		BitMapScale(&bsa);

		Delay(50);

		bsa.XDestFactor = 650;
                bsa.YDestFactor = 250;

		BitMapScale(&bsa);

		Delay(50);

		
		bsa.XDestFactor = 100;
                bsa.YDestFactor = 100;

		BitMapScale(&bsa);

		Delay(50);

		
		CloseWindow(win);
		}

	   CloseLibrary(GfxBase);
	 }
    CloseLibrary(IntuitionBase);
    }
}