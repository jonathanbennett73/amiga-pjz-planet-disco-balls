#ifndef LOCALESTR_DEVS_H
#define LOCALESTR_DEVS_H


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


#ifdef PRINTER_HP_DESKJET
#define MSG_HPDJ_DENSITY1_TXT 5000
#define MSG_HPDJ_DENSITY2_TXT 5001
#define MSG_HPDJ_DENSITY3_TXT 5002
#define MSG_HPDJ_DENSITY4_TXT 5003
#define MSG_HPDJ_DENSITY5_TXT 5004
#define MSG_HPDJ_DENSITY6_TXT 5005
#define MSG_HPDJ_DENSITY7_TXT 5006
#endif /* PRINTER_HP_DESKJET */

#endif /* CATCOMP_NUMBERS */


/****************************************************************************/


#ifdef CATCOMP_STRINGS


#ifdef PRINTER_HP_DESKJET
#define MSG_HPDJ_DENSITY1_TXT_STR "No depletion, no shingling"
#define MSG_HPDJ_DENSITY2_TXT_STR "No depletion, no shingling"
#define MSG_HPDJ_DENSITY3_TXT_STR "No depletion, no shingling"
#define MSG_HPDJ_DENSITY4_TXT_STR "25% depletion, no shingling"
#define MSG_HPDJ_DENSITY5_TXT_STR "25% depletion, 50% shingling"
#define MSG_HPDJ_DENSITY6_TXT_STR "25% depletion, 25% shingling"
#define MSG_HPDJ_DENSITY7_TXT_STR "No depletion, 25% shingling"
#endif /* PRINTER_HP_DESKJET */

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

#ifdef PRINTER_HP_DESKJET
    {MSG_HPDJ_DENSITY1_TXT,(STRPTR)MSG_HPDJ_DENSITY1_TXT_STR},
    {MSG_HPDJ_DENSITY2_TXT,(STRPTR)MSG_HPDJ_DENSITY2_TXT_STR},
    {MSG_HPDJ_DENSITY3_TXT,(STRPTR)MSG_HPDJ_DENSITY3_TXT_STR},
    {MSG_HPDJ_DENSITY4_TXT,(STRPTR)MSG_HPDJ_DENSITY4_TXT_STR},
    {MSG_HPDJ_DENSITY5_TXT,(STRPTR)MSG_HPDJ_DENSITY5_TXT_STR},
    {MSG_HPDJ_DENSITY6_TXT,(STRPTR)MSG_HPDJ_DENSITY6_TXT_STR},
    {MSG_HPDJ_DENSITY7_TXT,(STRPTR)MSG_HPDJ_DENSITY7_TXT_STR},
#endif /* PRINTER_HP_DESKJET */
};

#endif /* CATCOMP_ARRAY */


/****************************************************************************/


struct LocaleInfo
{
    APTR li_LocaleBase;
    APTR li_Catalog;
};



#endif /* LOCALESTR_DEVS_H */
