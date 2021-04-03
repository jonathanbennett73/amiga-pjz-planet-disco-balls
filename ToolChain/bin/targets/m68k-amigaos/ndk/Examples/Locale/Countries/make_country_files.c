/*
 * $Id: make_country_files.c 1.1 1999/10/20 17:22:51 olsen Exp olsen $
 *
 * :ts=4
 *
 * $VER: make_country_files 44.2 (28.9.1999)
 *
 * Copyright © 1999 Amiga, Inc.  All Rights Reserved
 *
 * This program contains the definitions of all country files used by the
 * AmigaOS locale.library subsystem. Each definition consists of three
 * parts: the country name (e.g. "australia"), the country file
 * version (e.g. "44.2 (28.9.1999)") and the actual country data as
 * defined in <prefs/locale.h>. What actually makes up the country data is
 * difficult to explain. If you don't know how to put one together you
 * probably shouldn't try to add a new one.
 *
 * If you really want to add a new country definition, first make sure that
 * you know what it takes to fill in the country data. Then decide upon a
 * name and make a copy of an existing entry and modify it. When you are
 * finished, fill in the version string, add a pointer in the countries[]
 * table and recompile this program, then start it. It should create a new
 * .country file which should then be copied to "LOCALE:countries". Now fire
 * up the Locale preferences editor and pick your new country definition.
 *
 * If you add a new definition for a country which is a member of the
 * European Community and which will have the Euro currency introduced in
 * the year 2000, please also add another Euro specific entry and update
 * the euro_countries[] table.
 *
 * For more information, contact Olaf Barthel <olsen@logicalline.com>
 */

#include <libraries/iffparse.h>
#include <libraries/locale.h>

#include <prefs/prefhdr.h>
#include <prefs/locale.h>

#include <dos/dos.h>

#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/iffparse_protos.h>
#include <clib/utility_protos.h>

#include <string.h>

/****************************************************************************/

#define ID_FVER MAKE_ID('F','V','E','R')

/****************************************************************************/

#define OK (0)
#define ZERO ((BPTR)NULL)

/****************************************************************************/

struct CountryData
{
	STRPTR				cd_Name;
	STRPTR				cd_Version;
	struct CountryPrefs	cd_Prefs;
};

/****************************************************************************/

struct Library * IFFParseBase;
struct Library * UtilityBase;

/****************************************************************************/

struct CountryData australia_prefs =
{
	"australia",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('A','U','S',0),
	/* cp_TelephoneCode         */ 61,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %B %e %Y %I:%M%p",
	/* cp_DateFormat            */ "%A %B %e %Y",
	/* cp_TimeFormat            */ "%I:%M:%S%p",
	/* cp_ShortDateTimeFormat   */ "%e/%m/%Y %I:%M%p",
	/* cp_ShortDateFormat       */ "%e/%m/%Y",
	/* cp_ShortTimeFormat       */ "%I:%M%p",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ " ",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ " ",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "$",
	/* cp_MonSmallCS            */ "c",
	/* cp_MonIntCS              */ "AUD",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PARENS,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData belgie_prefs =
{
	"belgie",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('B',0,0,0),
	/* cp_TelephoneCode         */ 32,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%b-%Y %H:%M:%S",
	/* cp_DateFormat            */ "%e-%b-%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "BEF",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "BFR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData belgique_prefs =
{
	"belgique",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('B',0,0,0),
	/* cp_TelephoneCode         */ 32,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%b-%Y %Hh%M",
	/* cp_DateFormat            */ "%e-%b-%Y",
	/* cp_TimeFormat            */ "%Hh%M",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %Hh%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%Hh%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "FB",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "BFR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData canada_prefs =
{
	"canada",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('C','A','N',0),
	/* cp_TelephoneCode         */ 1,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %B %e %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A %B %e %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ " ",
	/* cp_FracGroupSeparator    */ " ",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ " ",
	/* cp_MonFracGroupSeparator */ " ",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "$",
	/* cp_MonSmallCS            */ "¢",
	/* cp_MonIntCS              */ "CDN",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData canada_francais_prefs =
{
	"canada_français",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('C','A','N',0),
	/* cp_TelephoneCode         */ 1,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %e %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%Y-%m-%d %H:%M:%S",
	/* cp_ShortDateFormat       */ "%Y-%m-%d",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ " ",
	/* cp_FracGroupSeparator    */ " ",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ " ",
	/* cp_MonFracGroupSeparator */ " ",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "$",
	/* cp_MonSmallCS            */ "¢",
	/* cp_MonIntCS              */ "CDN",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData danmark_prefs =
{
	"danmark",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('D','K',0,0),
	/* cp_TelephoneCode         */ 45,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e. %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%Y/%m/%d %H:%M:%S",
	/* cp_ShortDateFormat       */ "%Y/%m/%d",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ ".",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "kr.",
	/* cp_MonSmallCS            */ "øre",
	/* cp_MonIntCS              */ "DKR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData deutschland_prefs =
{
	"deutschland",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('D',0,0,0),
	/* cp_TelephoneCode         */ 49,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e. %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d.%m.%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%d.%m.%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ ".",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "DM",
	/* cp_MonSmallCS            */ "Pf",
	/* cp_MonIntCS              */ "DM",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData espana_prefs =
{
	"españa",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('E',0,0,0),
	/* cp_TelephoneCode         */ 34,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%m-%Y %H:%M:%S",
	/* cp_DateFormat            */ "%e-%m-%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e-%m-%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e-%m-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ "'",
	/* cp_GroupSeparator        */ ",",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Pesetas",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "ESB",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData france_prefs =
{
	"france",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('F',0,0,0),
	/* cp_TelephoneCode         */ 33,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %e %B %Y %Hh%M",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%Hh%M",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %Hh%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%Hh%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ " ",
	/* cp_FracGroupSeparator    */ " ",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ " ",
	/* cp_MonFracGroupSeparator */ " ",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 4,
	/* cp_MonCS                 */ "F",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "FRF",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData great_britain_prefs =
{
	"great_britain",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('G','B',0,0),
	/* cp_TelephoneCode         */ 44,
	/* cp_MeasuringSystem       */ MS_BRITISH,
	/* cp_DateTimeFormat        */ "%A %e %B %Y  %H:%M",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %H:%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ ",",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ ",",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "£",
	/* cp_MonSmallCS            */ "p",
	/* cp_MonIntCS              */ "GPB",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PARENS,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData italia_prefs =
{
	"italia",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('I','T','A',0),
	/* cp_TelephoneCode         */ 39,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%q:%M:%S %d/%m/%Y",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%q:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%H:%M:%S %d/%m/%Y",
	/* cp_ShortDateFormat       */ "%e-%b-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 255 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 0,
	/* cp_MonIntFracDigits      */ 3,
	/* cp_MonCS                 */ "Lire",
	/* cp_MonSmallCS            */ "£",
	/* cp_MonIntCS              */ "LIT",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_CURR,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData nederland_prefs =
{
	"nederland",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('N','L',0,0),
	/* cp_TelephoneCode         */ 31,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e %B,%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e-%m-%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e-%m-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "fl",
	/* cp_MonSmallCS            */ "c",
	/* cp_MonIntCS              */ "DFL",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData norge_prefs =
{
	"norge",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('N',0,0,0),
	/* cp_TelephoneCode         */ 47,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e %B %Y %H.%M.%S",
	/* cp_DateFormat            */ "%e %B %Y",
	/* cp_TimeFormat            */ "%H.%M.%S",
	/* cp_ShortDateTimeFormat   */ "%e.%b.%Y %H.%M.%S",
	/* cp_ShortDateFormat       */ "%e.%b.%Y",
	/* cp_ShortTimeFormat       */ "%H.%M.%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 255 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 255 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "kr.",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "NOK",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData osterreich_prefs =
{
	"österreich",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('A',0,0,0),
	/* cp_TelephoneCode         */ 43,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e. %B %Y, %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%Y-%m-%d %H:%M:%S",
	/* cp_ShortDateFormat       */ "%Y-%m-%d",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "ÖS",
	/* cp_MonSmallCS            */ "g",
	/* cp_MonIntCS              */ "ATS",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData portugal_prefs =
{
	"portugal",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('P','O',0,0),
	/* cp_TelephoneCode         */ 351,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e de %B de %Y, %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e de %B de %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e %b %Y, %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e %b %Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ "'",
	/* cp_FracGroupSeparator    */ "'",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 3,
	/* cp_MonCS                 */ "ESP",
	/* cp_MonSmallCS            */ "",
	/* cp_MonIntCS              */ "",
	/* cp_MonPositiveSign       */ "+",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData schweiz_prefs =
{
	"schweiz",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('C','H',0,0),
	/* cp_TelephoneCode         */ 41,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e. %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e.%m.%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e.%m.%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ "'",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ "'",
	/* cp_MonFracGroupSeparator */ "'",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "SFr.",
	/* cp_MonSmallCS            */ "Rp.",
	/* cp_MonIntCS              */ "SRF",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_CURR,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData suisse_prefs =
{
	"suisse",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('C','H',0,0),
	/* cp_TelephoneCode         */ 41,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %e %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e.%m.%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e.%m.%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ "'",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ "'",
	/* cp_MonFracGroupSeparator */ "'",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "SFr.",
	/* cp_MonSmallCS            */ "ct.",
	/* cp_MonIntCS              */ "SRF",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_CURR,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData sverige_prefs =
{
	"sverige",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('S',0,0,0),
	/* cp_TelephoneCode         */ 46,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%Y-%m-%d kl %H.%M.%S",
	/* cp_DateFormat            */ "%Y-%m-%d",
	/* cp_TimeFormat            */ "%H.%M.%S",
	/* cp_ShortDateTimeFormat   */ "%Y-%m-%d kl %H.%M.%S",
	/* cp_ShortDateFormat       */ "%Y-%m-%d",
	/* cp_ShortTimeFormat       */ "%H.%M.%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 2 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "kr",
	/* cp_MonSmallCS            */ "öre",
	/* cp_MonIntCS              */ "SEK",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData svizzera_prefs =
{
	"svizzera",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('C','H',0,0),
	/* cp_TelephoneCode         */ 41,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %e %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e.%m.%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e.%m.%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ "'",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ "'",
	/* cp_MonFracGroupSeparator */ "'",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "SFr.",
	/* cp_MonSmallCS            */ "ct.",
	/* cp_MonIntCS              */ "SRF",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_CURR,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData united_kingdom_prefs =
{
	"united_kingdom",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('U','K',0,0),
	/* cp_TelephoneCode         */ 44,
	/* cp_MeasuringSystem       */ MS_BRITISH,
	/* cp_DateTimeFormat        */ "%A %e %B %Y  %H:%M",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %H:%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ ",",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ ",",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "£",
	/* cp_MonSmallCS            */ "p",
	/* cp_MonIntCS              */ "UKS",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PARENS,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData united_states_prefs =
{
	"united_states",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('U','S','A',0),
	/* cp_TelephoneCode         */ 1,
	/* cp_MeasuringSystem       */ MS_AMERICAN,
	/* cp_DateTimeFormat        */ "%A %B %e %Y %Q:%M %p",
	/* cp_DateFormat            */ "%A %B %e %Y",
	/* cp_TimeFormat            */ "%Q:%M:%S %p",
	/* cp_ShortDateTimeFormat   */ "%m/%d/%Y %Q:%M %p",
	/* cp_ShortDateFormat       */ "%m/%d/%Y",
	/* cp_ShortTimeFormat       */ "%Q:%M %p",
	/* cp_DecimalPoint          */ ".",
	/* cp_GroupSeparator        */ ",",
	/* cp_FracGroupSeparator    */ ",",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ ",",
	/* cp_MonFracGroupSeparator */ ",",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "$",
	/* cp_MonSmallCS            */ "¢",
	/* cp_MonIntCS              */ "USD",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData * regular_countries[] =
{
	&australia_prefs,
	&belgie_prefs,
	&belgique_prefs,
	&canada_prefs,
	&canada_francais_prefs,
	&danmark_prefs,
	&deutschland_prefs,
	&espana_prefs,
	&france_prefs,
	&great_britain_prefs,
	&italia_prefs,
	&nederland_prefs,
	&norge_prefs,
	&osterreich_prefs,
	&portugal_prefs,
	&schweiz_prefs,
	&suisse_prefs,
	&sverige_prefs,
	&svizzera_prefs,
	&united_kingdom_prefs,
	&united_states_prefs,
	NULL
};

/****************************************************************************/

struct CountryData belgie_euro_prefs =
{
	"belgie",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('B',0,0,0),
	/* cp_TelephoneCode         */ 32,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%b-%Y %H:%M:%S",
	/* cp_DateFormat            */ "%e-%b-%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData belgique_euro_prefs =
{
	"belgique",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('B',0,0,0),
	/* cp_TelephoneCode         */ 32,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%b-%Y %Hh%M",
	/* cp_DateFormat            */ "%e-%b-%Y",
	/* cp_TimeFormat            */ "%Hh%M",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %Hh%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%Hh%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData deutschland_euro_prefs =
{
	"deutschland",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('D',0,0,0),
	/* cp_TelephoneCode         */ 49,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e. %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%d.%m.%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%d.%m.%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ ".",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData espana_euro_prefs =
{
	"españa",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('E',0,0,0),
	/* cp_TelephoneCode         */ 34,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%e-%m-%Y %H:%M:%S",
	/* cp_DateFormat            */ "%e-%m-%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e-%m-%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e-%m-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ "'",
	/* cp_GroupSeparator        */ ",",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData france_euro_prefs =
{
	"france",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('F',0,0,0),
	/* cp_TelephoneCode         */ 33,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A %e %B %Y %Hh%M",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%Hh%M",
	/* cp_ShortDateTimeFormat   */ "%d/%m/%Y %Hh%M",
	/* cp_ShortDateFormat       */ "%d/%m/%Y",
	/* cp_ShortTimeFormat       */ "%Hh%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ " ",
	/* cp_FracGroupSeparator    */ " ",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ " ",
	/* cp_MonFracGroupSeparator */ " ",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 4,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_NOSPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_SUCCEEDS,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_NOSPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData italia_euro_prefs =
{
	"italia",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('I','T','A',0),
	/* cp_TelephoneCode         */ 39,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%q:%M:%S %d/%m/%Y",
	/* cp_DateFormat            */ "%A %e %B %Y",
	/* cp_TimeFormat            */ "%q:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%H:%M:%S %d/%m/%Y",
	/* cp_ShortDateFormat       */ "%e-%b-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M:%S",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 255 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 3,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_CURR,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7SUN
	}
};

struct CountryData nederland_euro_prefs =
{
	"nederland",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('N','L',0,0),
	/* cp_TelephoneCode         */ 31,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e %B %Y %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e %B,%Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e-%m-%Y %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e-%m-%Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_SUCC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData osterreich_euro_prefs =
{
	"österreich",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('A',0,0,0),
	/* cp_TelephoneCode         */ 43,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e. %B %Y, %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e. %B %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%Y-%m-%d %H:%M:%S",
	/* cp_ShortDateFormat       */ "%Y-%m-%d",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ ".",
	/* cp_FracGroupSeparator    */ "",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 0 },
	/* cp_MonDecimalPoint       */ ",",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ "",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 0 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 2,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_PRECEDES,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData portugal_euro_prefs =
{
	"portugal",
	"44.2 (28.9.1999)",

	{
	/* cp_Reserved              */ { 0 },
	/* cp_CountryCode           */ MAKE_ID('P','O',0,0),
	/* cp_TelephoneCode         */ 351,
	/* cp_MeasuringSystem       */ MS_ISO,
	/* cp_DateTimeFormat        */ "%A, %e de %B de %Y, %H:%M:%S",
	/* cp_DateFormat            */ "%A, %e de %B de %Y",
	/* cp_TimeFormat            */ "%H:%M:%S",
	/* cp_ShortDateTimeFormat   */ "%e %b %Y, %H:%M:%S",
	/* cp_ShortDateFormat       */ "%e %b %Y",
	/* cp_ShortTimeFormat       */ "%H:%M",
	/* cp_DecimalPoint          */ ",",
	/* cp_GroupSeparator        */ "'",
	/* cp_FracGroupSeparator    */ "'",
	/* cp_Grouping              */ { 3 },
	/* cp_FracGrouping          */ { 3 },
	/* cp_MonDecimalPoint       */ ".",
	/* cp_MonGroupSeparator     */ ".",
	/* cp_MonFracGroupSeparator */ ".",
	/* cp_MonGrouping           */ { 3 },
	/* cp_MonFracGrouping       */ { 3 },
	/* cp_MonFracDigits         */ 2,
	/* cp_MonIntFracDigits      */ 3,
	/* cp_MonCS                 */ "Euro",
	/* cp_MonSmallCS            */ "Cent",
	/* cp_MonIntCS              */ "EUR",
	/* cp_MonPositiveSign       */ "+",
	/* cp_MonPositiveSpaceSep   */ SS_SPACE,
	/* cp_MonPositiveSignPos    */ SP_PREC_ALL,
	/* cp_MonPositiveCSPos      */ CSP_PRECEDES,
	/* cp_MonNegativeSign       */ "-",
	/* cp_MonNegativeSpaceSep   */ SS_SPACE,
	/* cp_MonNegativeSignPos    */ SP_PREC_ALL,
	/* cp_MonNegativeCSPos      */ CSP_SUCCEEDS,
	/* cp_CalendarType          */ CT_7MON
	}
};

struct CountryData * euro_countries[] =
{
	&belgie_euro_prefs,
	&belgique_euro_prefs,
	&deutschland_euro_prefs,
	&espana_euro_prefs,
	&france_euro_prefs,
	&italia_euro_prefs,
	&nederland_euro_prefs,
	&osterreich_euro_prefs,
	&portugal_euro_prefs,
	NULL
};

/****************************************************************************/

LONG
WriteOne(struct CountryData * cd)
{
	UBYTE versionString[100];
	UBYTE fileName[100];
	struct PrefHeader ph;
	struct IFFHandle * iff = NULL;
	BOOL opened = FALSE;
	BPTR file = ZERO;
	LONG error = OK;

	strcpy(fileName,cd->cd_Name);
	strcat(fileName,".country");

	iff = AllocIFF();
	if(iff == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	file = Open(fileName,MODE_NEWFILE);
	if(file == ZERO)
	{
		error = IoErr();
		goto out;
	}

	iff->iff_Stream = (ULONG)file;

	InitIFFasDOS(iff);

	error = OpenIFF(iff,IFFF_WRITE);
	if(error != OK)
		goto out;

	opened = TRUE;

	error = PushChunk(iff,ID_PREF,ID_FORM,IFFSIZE_UNKNOWN);
	if(error != OK)
		goto out;


	error = PushChunk(iff,0,ID_PRHD,sizeof(ph));
	if(error != OK)
		goto out;

	memset(&ph,0,sizeof(ph));

	error = WriteChunkBytes(iff,&ph,sizeof(ph));
	if(error > 0)
		error = OK;

	if(error != OK)
		goto out;

	error = PopChunk(iff);
	if(error != OK)
		goto out;


	error = PushChunk(iff,0,ID_CTRY,sizeof(cd->cd_Prefs));
	if(error != OK)
		goto out;

	error = WriteChunkBytes(iff,&cd->cd_Prefs,sizeof(cd->cd_Prefs));
	if(error > 0)
		error = OK;

	if(error != OK)
		goto out;

	error = PopChunk(iff);
	if(error != OK)
		goto out;


	error = PushChunk(iff,0,ID_FVER,IFFSIZE_UNKNOWN);
	if(error != OK)
		goto out;

	strcpy(versionString,"$VER: ");
	strcat(versionString,fileName);
	strcat(versionString," ");
	strcat(versionString,cd->cd_Version);
	strcat(versionString,"\r\n");

	error = WriteChunkBytes(iff,versionString,strlen(versionString)+1);
	if(error > 0)
		error = OK;

	if(error != OK)
		goto out;

	error = PopChunk(iff);


	error = PopChunk(iff);
	if(error != OK)
		goto out;


 out:

	if(opened)
		CloseIFF(iff);

	if(file != ZERO)
		Close(file);

	if(iff != NULL)
		FreeIFF(iff);

	if(error != OK && file != ZERO)
		DeleteFile(fileName);
	else
		SetProtection(fileName,FIBF_EXECUTE);

	return(error);
}

/****************************************************************************/

LONG
WriteCountries(struct CountryData ** table)
{
	LONG error = OK;

	while((*table) != NULL)
	{
		error = WriteOne((*table++));
		if(error != OK)
			break;
	}

	return(error);
}

/****************************************************************************/

int
main(void)
{
	BPTR dir;

	IFFParseBase = OpenLibrary("iffparse.library",37);
	if(IFFParseBase == NULL)
		goto out;

	UtilityBase = OpenLibrary("utility.library",37);
	if(UtilityBase == NULL)
		goto out;

	UnLock(CreateDir("countries"));
	dir = Lock("countries",SHARED_LOCK);
	if(dir != ZERO)
	{
		BPTR oldDir;

		oldDir = CurrentDir(dir);
		WriteCountries(regular_countries);
		CurrentDir(oldDir);

		UnLock(dir);
	}

	UnLock(CreateDir("countries.euro"));
	dir = Lock("countries.euro",SHARED_LOCK);
	if(dir != ZERO)
	{
		BPTR oldDir;

		oldDir = CurrentDir(dir);
		WriteCountries(euro_countries);
		CurrentDir(oldDir);

		UnLock(dir);
	}

 out:

	if(UtilityBase != NULL)
		CloseLibrary(UtilityBase);

	if(IFFParseBase != NULL)
		CloseLibrary(IFFParseBase);

	return(0);
}
