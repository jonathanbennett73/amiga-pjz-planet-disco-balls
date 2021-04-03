#ifndef EUROCALCFRAMECD_H
#define EUROCALCFRAMECD_H


/****************************************************************************/


/* This file was created automatically by CatComp.
 * Do NOT edit by hand!
 */


#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif

#ifdef CATCOMP_ARRAY
#undef CATCOMP_NUMBERS
#undef CATCOMP_STRINGS
#define CATCOMP_NUMBERS
#define CATCOMP_STRINGS
#endif

#ifdef CATCOMP_BLOCK
#undef CATCOMP_STRINGS
#define CATCOMP_STRINGS
#endif


/****************************************************************************/


#ifdef CATCOMP_NUMBERS

#define TX_WinTitle 257
#define TX_TitleIconify 274
#define TX_GAD_DM 278
#define TX_GAD_BFR 279
#define TX_GAD_FMK 280
#define TX_GAD_FF 281
#define TX_GAD_IRF 282
#define TX_GAD_LIT 283
#define TX_GAD_LFR 284
#define TX_GAD_HFL 285
#define TX_GAD_OES 286
#define TX_GAD_ESC 287
#define TX_GAD_PTA 288
#define TX_GAD_EUROPE 289
#define TX_GAD_EUR 290
#define TX_GAD_GERMANY 291
#define TX_GAD_BELGIUM 292
#define TX_GAD_FINLAND 293
#define TX_GAD_FRANCE 294
#define TX_GAD_IRELAND 295
#define TX_GAD_ITALY 296
#define TX_GAD_LUXEMBURG 297
#define TX_GAD_NETHERLAND 298
#define TX_GAD_AUSTRIA 299
#define TX_GAD_PORTUGAL 300
#define TX_GAD_SPAIN 301

#endif /* CATCOMP_NUMBERS */


/****************************************************************************/


#ifdef CATCOMP_STRINGS

#define TX_WinTitle_STR "Euro-Calculator"
#define TX_TitleIconify_STR "Euro-Calculator.iconified"
#define TX_GAD_DM_STR "DM"
#define TX_GAD_BFR_STR "BFR"
#define TX_GAD_FMK_STR "FMK"
#define TX_GAD_FF_STR "FF"
#define TX_GAD_IRF_STR "IRF"
#define TX_GAD_LIT_STR "LIT"
#define TX_GAD_LFR_STR "LFR"
#define TX_GAD_HFL_STR "HFL"
#define TX_GAD_OES_STR "OES"
#define TX_GAD_ESC_STR "ESC"
#define TX_GAD_PTA_STR "PTA"
#define TX_GAD_EUROPE_STR "Europe:"
#define TX_GAD_EUR_STR "EUR"
#define TX_GAD_GERMANY_STR "Germany:"
#define TX_GAD_BELGIUM_STR "Belgium:"
#define TX_GAD_FINLAND_STR "Finland:"
#define TX_GAD_FRANCE_STR "France:"
#define TX_GAD_IRELAND_STR "Ireland:"
#define TX_GAD_ITALY_STR "Italy:"
#define TX_GAD_LUXEMBURG_STR "Luxemburg:"
#define TX_GAD_NETHERLAND_STR "Netherland:"
#define TX_GAD_AUSTRIA_STR "Austria:"
#define TX_GAD_PORTUGAL_STR "Portugal:"
#define TX_GAD_SPAIN_STR "Spain:"

#endif /* CATCOMP_STRINGS */


/****************************************************************************/


#ifdef CATCOMP_ARRAY

struct CatCompArrayType
{
    LONG   cca_ID;
    STRPTR cca_Str;
};

static const struct CatCompArrayType CatCompArray[] =
{
    {TX_WinTitle,(STRPTR)TX_WinTitle_STR},
    {TX_TitleIconify,(STRPTR)TX_TitleIconify_STR},
    {TX_GAD_DM,(STRPTR)TX_GAD_DM_STR},
    {TX_GAD_BFR,(STRPTR)TX_GAD_BFR_STR},
    {TX_GAD_FMK,(STRPTR)TX_GAD_FMK_STR},
    {TX_GAD_FF,(STRPTR)TX_GAD_FF_STR},
    {TX_GAD_IRF,(STRPTR)TX_GAD_IRF_STR},
    {TX_GAD_LIT,(STRPTR)TX_GAD_LIT_STR},
    {TX_GAD_LFR,(STRPTR)TX_GAD_LFR_STR},
    {TX_GAD_HFL,(STRPTR)TX_GAD_HFL_STR},
    {TX_GAD_OES,(STRPTR)TX_GAD_OES_STR},
    {TX_GAD_ESC,(STRPTR)TX_GAD_ESC_STR},
    {TX_GAD_PTA,(STRPTR)TX_GAD_PTA_STR},
    {TX_GAD_EUROPE,(STRPTR)TX_GAD_EUROPE_STR},
    {TX_GAD_EUR,(STRPTR)TX_GAD_EUR_STR},
    {TX_GAD_GERMANY,(STRPTR)TX_GAD_GERMANY_STR},
    {TX_GAD_BELGIUM,(STRPTR)TX_GAD_BELGIUM_STR},
    {TX_GAD_FINLAND,(STRPTR)TX_GAD_FINLAND_STR},
    {TX_GAD_FRANCE,(STRPTR)TX_GAD_FRANCE_STR},
    {TX_GAD_IRELAND,(STRPTR)TX_GAD_IRELAND_STR},
    {TX_GAD_ITALY,(STRPTR)TX_GAD_ITALY_STR},
    {TX_GAD_LUXEMBURG,(STRPTR)TX_GAD_LUXEMBURG_STR},
    {TX_GAD_NETHERLAND,(STRPTR)TX_GAD_NETHERLAND_STR},
    {TX_GAD_AUSTRIA,(STRPTR)TX_GAD_AUSTRIA_STR},
    {TX_GAD_PORTUGAL,(STRPTR)TX_GAD_PORTUGAL_STR},
    {TX_GAD_SPAIN,(STRPTR)TX_GAD_SPAIN_STR},
};

#endif /* CATCOMP_ARRAY */


/****************************************************************************/


#ifdef CATCOMP_BLOCK

static const char CatCompBlock[] =
{
    "\x00\x00\x01\x01\x00\x10"
    TX_WinTitle_STR "\x00"
    "\x00\x00\x01\x12\x00\x1A"
    TX_TitleIconify_STR "\x00"
    "\x00\x00\x01\x16\x00\x04"
    TX_GAD_DM_STR "\x00\x00"
    "\x00\x00\x01\x17\x00\x04"
    TX_GAD_BFR_STR "\x00"
    "\x00\x00\x01\x18\x00\x04"
    TX_GAD_FMK_STR "\x00"
    "\x00\x00\x01\x19\x00\x04"
    TX_GAD_FF_STR "\x00\x00"
    "\x00\x00\x01\x1A\x00\x04"
    TX_GAD_IRF_STR "\x00"
    "\x00\x00\x01\x1B\x00\x04"
    TX_GAD_LIT_STR "\x00"
    "\x00\x00\x01\x1C\x00\x04"
    TX_GAD_LFR_STR "\x00"
    "\x00\x00\x01\x1D\x00\x04"
    TX_GAD_HFL_STR "\x00"
    "\x00\x00\x01\x1E\x00\x04"
    TX_GAD_OES_STR "\x00"
    "\x00\x00\x01\x1F\x00\x04"
    TX_GAD_ESC_STR "\x00"
    "\x00\x00\x01\x20\x00\x04"
    TX_GAD_PTA_STR "\x00"
    "\x00\x00\x01\x21\x00\x08"
    TX_GAD_EUROPE_STR "\x00"
    "\x00\x00\x01\x22\x00\x04"
    TX_GAD_EUR_STR "\x00"
    "\x00\x00\x01\x23\x00\x0A"
    TX_GAD_GERMANY_STR "\x00\x00"
    "\x00\x00\x01\x24\x00\x0A"
    TX_GAD_BELGIUM_STR "\x00\x00"
    "\x00\x00\x01\x25\x00\x0A"
    TX_GAD_FINLAND_STR "\x00\x00"
    "\x00\x00\x01\x26\x00\x08"
    TX_GAD_FRANCE_STR "\x00"
    "\x00\x00\x01\x27\x00\x0A"
    TX_GAD_IRELAND_STR "\x00\x00"
    "\x00\x00\x01\x28\x00\x08"
    TX_GAD_ITALY_STR "\x00\x00"
    "\x00\x00\x01\x29\x00\x0C"
    TX_GAD_LUXEMBURG_STR "\x00\x00"
    "\x00\x00\x01\x2A\x00\x0C"
    TX_GAD_NETHERLAND_STR "\x00"
    "\x00\x00\x01\x2B\x00\x0A"
    TX_GAD_AUSTRIA_STR "\x00\x00"
    "\x00\x00\x01\x2C\x00\x0A"
    TX_GAD_PORTUGAL_STR "\x00"
    "\x00\x00\x01\x2D\x00\x08"
    TX_GAD_SPAIN_STR "\x00\x00"
};

#endif /* CATCOMP_BLOCK */


/****************************************************************************/


struct LocaleInfo
{
    APTR li_LocaleBase;
    APTR li_Catalog;
};


#ifdef CATCOMP_CODE

STRPTR GetString(struct LocaleInfo *li, LONG stringNum)
{
LONG   *l;
UWORD  *w;
STRPTR  builtIn;

    l = (LONG *)CatCompBlock;

    while (*l != stringNum)
    {
        w = (UWORD *)((ULONG)l + 4);
        l = (LONG *)((ULONG)l + (ULONG)*w + 6);
    }
    builtIn = (STRPTR)((ULONG)l + 6);

#undef LocaleBase
#define LocaleBase li->li_LocaleBase
    
    if (LocaleBase)
        return(GetCatalogStr(li->li_Catalog,stringNum,builtIn));
#undef LocaleBase

    return(builtIn);
}


#endif /* CATCOMP_CODE */


/****************************************************************************/


#endif /* EUROCALCFRAMECD_H */
