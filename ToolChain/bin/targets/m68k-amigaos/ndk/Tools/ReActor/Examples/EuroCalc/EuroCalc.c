/* Michael Christoph Software */
/* EuroCalc - Euro-Währungsrechner */
/* EuroCalc.c: Main-Routinen */ 
/* V1.00: 17.07.-18.08.1999, created */
/* V1.01: 25.10.1999, updated + localized */

/* !!!!! Published with the Amiga NDK are welcome !!!!! */

/******************************* ERKLÄRUNG *************************************
**
** Ländernamen / Fahnendateien / Hymnendateien:
** 
** Europa       europe.iff       -
** Deutschland  germany.iff      germany.mid
** Belgien      belgium.iff      belgium.mid
** Finnland     finland.iff      finland.mid
** Frankreich   france.iff       france.mid
** Irland       ireland.iff      ireland.mid
** Italien      italy.iff        italy.mid
** Luxemburg    luxemburg.iff    luxemburg.mid
** Niederlande  netherland.iff   netherland.mid
** Österreich   austria.iff      austria.mid
** Portugal     portugal.iff     portugal.mid
** Spanien      spain.iff        spain.mid
** 
** --------------------------------------------------------------------------------
** 
** Alle Kommentare sind deutsch und darunter englisch angegeben.
** Im Programm werden nur englische Bezeichnungen und Variablennamen verwendet.
** Hier die Übersetzungstabelle:
**   Total        = Betrag
**   Currency     = Währung
**   Currencymark = Währungskennzeichen
**   Exchange     = Wechselkurs
** Übersetzung der Oberflächenelemente als Catalogdatei.
** 
** All comments are first in german an then in english given.
** Only english names and variablenames will used.
** Translation from the gui to other countries with catalog-files.
** 
** --------------------------------------------------------------------------------
**
** Das Programm ist nicht vollständig !
** Beliebige Änderungen und Erweiterungen des Sources sind erwünscht.
**
** The program is not complete !
** Any changes and extensions of the source are welcome.
** - graphic print of the complete window
** - printing texttable (1,5,10,...) of one currency
** - arexxport (easy with ReActor)
** - ... our own ideas ...
**
*******************************************************************************/

/*
** Result for the shell:
**  0 - RETURN_OK     arguments ok or gui was used
**  5 - RETURN_WARN   unused
**  8 - RETURN_BREAK  gui was closed with CTRL-C
** 10 - RETURN_ERROR  error in arguments (e.g. unknown currency)
** 20 - RETURN_FAIL   no AmigaOS 3.5, open failed from library, window, ect.
*/

/************************** PROGRAMM-PARAMETER ********************************/

#define PROGNAME "EuroCalc"
#define VERSIONR "1.01"
#define PROGDATE "25.10.1999"
#define COPYRIGT "Copyright © Jul.1999 by Meicky-Soft"

const char *version = "\0$VER: " PROGNAME " " VERSIONR " (" PROGDATE ") - " COPYRIGT "\n";

/******************************* INCLUDES *************************************/

#include "EuroCalcFrame.h"

#include <exec/types.h>
#include <exec/alerts.h>
#include <dos/dos.h>
#define RETURN_BREAK 8    /* Ergänzung zu den Defines in dos.h */
                          /* Additional to the defines in dos.h */
#include <intuition/intuition.h>
#include <intuition/gadgetclass.h>
#include <intuition/classusr.h>
#include <libraries/gadtools.h>
#include <classes/window.h>
//#include <classes/arexx.h>
#include <workbench/startup.h>
#include <workbench/icon.h>
#include <reaction/reaction.h>
#include <reaction/reaction_macros.h>

#include <clib/alib_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>
#include <clib/intuition_protos.h>
#include <clib/gadtools_protos.h>
#include <clib/locale_protos.h>
#include <clib/icon_protos.h>
#include <clib/resource_protos.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/************************ VARIABLEN DEKLARATIONEN *****************************/

UBYTE gb_ArgTemplate[]="TOTAL,CURRENCY,TO/K/M,PUBSCREEN/K";
enum { ARG_total, ARG_currency, ARG_to, ARG_pubscreen, ARG_MAX };
LONG gb_Args[ARG_MAX]={ 0,0,0,NULL };

/************************ VARIABLEN DEKLARATIONEN *****************************/

struct Library       *ResourceBase;
struct IntuitionBase *IntuitionBase;
struct Library       *GadToolsBase;
struct Library       *LocaleBase;
struct Library       *IconBase;

struct Screen        *gb_Screen;
struct Window        *gb_Window;
struct Gadget       **gb_Gadgets;
struct Menu          *gb_Menus;
struct Catalog       *gb_Catalog;
struct MsgPort       *gb_IDCMPort;
struct MsgPort       *gb_AppPort;
RESOURCEFILE          gb_Resource;
Object               *gb_WindowObj;
UBYTE                 gb_ProgName[30];

/************************ VARIABLEN DEKLARATIONEN *****************************/

struct CountryList
{
  UWORD  ll_GadID;       /* GadgetID */
  UBYTE  ll_Currency[5]; /* Währungskennzeichen / Currencymark */
  DOUBLE ll_Exchange;    /* Wechselkurs / rate of exchange */
  UBYTE  ll_Country[20]; /* Ländername / Name of the country */
};

struct CountryList gb_Countries[] =
{
  0,"",0,"",                                    /* unused */
  0,"",0,"",                                    /* unused */
  GAD_ID_EUR, "EURO",   1.0     , "Europe"    , /*"Europa"     */
  GAD_ID_DM , "DM"  ,   1.95583 , "Germany"   , /*"Deutschland"*/
  GAD_ID_BFR, "BFR" ,  40.3399  , "Belgium"   , /*"Belgien"    */
  GAD_ID_FMK, "FMK" ,   5.94573 , "Finland"   , /*"Finnland"   */
  GAD_ID_FF , "FF"  ,   6.55957 , "France"    , /*"Frankreich" */
  GAD_ID_IRF, "IRF" ,   0.787564, "Ireland"   , /*"Irland"     */
  GAD_ID_LIT, "LIT" ,1936.27    , "Italy"     , /*"Italien"    */
  GAD_ID_LFR, "LFR" ,  40.3399  , "Luxemburg" , /*"Luxemburg"  */
  GAD_ID_HFL, "HFL" ,   2.20371 , "Netherland", /*"Niederlande"*/
  GAD_ID_OES, "OES" ,  13.7603  , "Austria"   , /*"Österreich" */
  GAD_ID_ESC, "ESC" , 200.482   , "Portugal"  , /*"Portugal"   */
  GAD_ID_PTA, "PTA" , 166.386   , "Spain"     , /*"Spanien"    */
};

/*
** der derzeitige Arrayaufbau und die Gadget-IDs ermöglichen es, daß
** z.B. per gb_Countries[GAD_ID_EUR] auf die Werte zugegriffen werden kann.
*/
/*
** the actual arraysort and gadgetids can simple use to get the values
** from the structure with e.g. gb_Countries[GAD_ID_EUR].
*/

/* niedriegste benutze Länder-ID und Anzahl Array-Einträge */
/* first used country-id and numbers of array-elements */
#define COUNTRY_FIRST GAD_ID_EUR
#define COUNTRY_MAX   (GAD_ID_PTA + 1)

/* Ergebniswerte; Array 0 und 1 unbenutzt, wie bei gb_Countires */
/* resultvalues; array 0 and 1 unused, as gb_Countries */
DOUBLE gb_Total[COUNTRY_MAX];

/* Ausgabeformat für die Ergebniswerte */
/* Outputstring to format the resultvalues */
#define FMT_CurrencyOutput "%0.2f"

/************************ VARIABLEN DEKLARATIONEN *****************************/

/* Localisierung der programmeigenen Elemente/Texte */
/* localized of the internal elements and texts */

const STRPTR STR_TX_Ok            = "Ok";
const STRPTR STR_TX_SureToQuit    = "\nSure to quit program ?";
const STRPTR STR_TX_QuitYesNo     = "Yes|No";
const STRPTR STR_TX_From          = "from";

const STRPTR STR_TX_MENU_Project  = "Project";
const STRPTR STR_TX_MENU_Manual   = "M\0Manual...";
const STRPTR STR_TX_MENU_Print    = "P\0Print";
const STRPTR STR_TX_MENU_Info     = "I\0Info...";
const STRPTR STR_TX_MENU_Quit     = "Q\0Quit...";

const STRPTR STR_TX_MENU_Edit     = "Edit";
const STRPTR STR_TX_MENU_ClearAll = "X\0Clear all fields";
const STRPTR STR_TX_MENU_Exchange = "E\0Change exchange...";

enum LocaleIDs
{
  TX_Ok                = 1001,
  TX_SureToQuit,
  TX_QuitYesNo,
  TX_From,

  TX_MENU_Project      = 1011,
  TX_MENU_Manual,
  TX_MENU_Print,
  TX_MENU_Info,
  TX_MENU_Quit,
  TX_MENU_Edit,
  TX_MENU_ClearAll,
  TX_MENU_Exchange,
};

#define CATSTR(id)        GetCatalogStr(gb_Catalog,id,(STRPTR)STR_ ## id)
#define CATSTRSTR(id,str) GetCatalogStr(gb_Catalog,id,(STRPTR)str)

/************************ VARIABLEN DEKLARATIONEN *****************************/

static struct NewMenu gb_MenuDescribe[] =
{
  NM_TITLE, (STRPTR)STR_TX_MENU_Project,  NULL, 0, 0, (APTR)TX_MENU_Project,  /* "Project" */
  NM_ITEM,  (STRPTR)STR_TX_MENU_Manual,   NULL, 0, 0, (APTR)TX_MENU_Manual,   /* "M\0Manual..." */
  NM_ITEM,  (STRPTR)STR_TX_MENU_Print,    NULL, 0, 0, (APTR)TX_MENU_Print,    /* "P\0Print" */
  NM_ITEM,  (STRPTR)STR_TX_MENU_Info,     NULL, 0, 0, (APTR)TX_MENU_Info,     /* "I\0Info..." */
  NM_ITEM,  NM_BARLABEL,                  NULL, 0, 0, (APTR)0,
  NM_ITEM,  (STRPTR)STR_TX_MENU_Quit,     NULL, 0, 0, (APTR)TX_MENU_Quit,     /* "Q\0Quit..." */

  NM_TITLE, (STRPTR)STR_TX_MENU_Edit,     NULL, 0, 0, (APTR)TX_MENU_Edit,     /* "Edit" */
  NM_ITEM,  (STRPTR)STR_TX_MENU_ClearAll, NULL, 0, 0, (APTR)TX_MENU_ClearAll, /* "X\0Clear all field" */
  NM_ITEM,  (STRPTR)STR_TX_MENU_Exchange, NULL, 0, 0, (APTR)TX_MENU_Exchange, /* "E\0Change exchange..." */

  NM_END, NULL, NULL, 0, 0, NULL
};

/* Menüdefines zur einfacheren Benutzung */
/* Menuedefines for easier used */
#define MENU_ID_Manual    FULLMENUNUM(0,0,NOSUB)
#define MENU_ID_Print     FULLMENUNUM(0,1,NOSUB)
#define MENU_ID_Info      FULLMENUNUM(0,2,NOSUB)
#define MENU_ID_Quit      FULLMENUNUM(0,4,NOSUB)
#define MENU_ID_ClearAll  FULLMENUNUM(1,0,NOSUB)
#define MENU_ID_Exchange  FULLMENUNUM(1,1,NOSUB)

/******************************************************************************/

const STRPTR FormatCurrency(DOUBLE total)
{
  /* ACHTUNG:
  ** Funktion ist nicht reentrant !
  ** und darf daher nicht mehrfach gleichzeitig aufgerufen werden
  */
  /* Functions in not reentrant ! */

  static UBYTE totalstr[10];
  sprintf(totalstr,FMT_CurrencyOutput,total);
  return( totalstr );
}

/******************************************************************************/

void UpdateGadgets()
{
  /* in allen Gadgets den aktuellen Wert anzeigen */
  /* display in all gadgets the actual values */

  ULONG i;
  for(i=COUNTRY_FIRST; i<COUNTRY_MAX; i++)
  {
    SetGadgetAttrs(gb_Gadgets[gb_Countries[i].ll_GadID],gb_Window,NULL,
                   STRINGA_TextVal,FormatCurrency(gb_Total[i]),
                   TAG_DONE);
  }
}

/******************************************************************************/

void ClearAllGadgets()
{
  /* alle Eingabefelder löschen */
  /* empty all inputgadgets */

  ULONG i;
  for(i=COUNTRY_FIRST; i<COUNTRY_MAX; i++)
  {
    gb_Total[i] = 0.0;

    SetGadgetAttrs(gb_Gadgets[gb_Countries[i].ll_GadID],gb_Window,NULL,
                   STRINGA_TextVal,"",
                   TAG_DONE);
  }
}

/******************************************************************************/

DOUBLE Calculate(UWORD currency, DOUBLE input)
{ 
  /* Währungs-Umrechnung vornehmen */
  /* 'input' enthält den Zahlenwert und 'currency' die zugehörige Basiswährung */
  /* zurückgeliefert wird der berechnete Eurokurs */

  ULONG i;

  /* calculate given value to euro */
  const DOUBLE ineuro = input / gb_Countries[currency].ll_Exchange;

  /* then calculate from euro to all other currencies */
  for(i=COUNTRY_FIRST; i<COUNTRY_MAX; i++)
    gb_Total[i] = ineuro * gb_Countries[i].ll_Exchange;

  return( ineuro );
}

/******************************************************************************/

struct Menu *CreateMenu(struct NewMenu *newmenu)
{
  /* menu => Menübeschreibung */
  /* <= übergebene Menübeschreibung aber mit den neuen Texten */

  struct Menu *menu=NULL;
  APTR visualinfo;

  struct NewMenu *item;
  for(item = newmenu; item->nm_Type != NM_END; item++)
  {
    if(item->nm_UserData)
    {
      /*
      ** falls der String nicht aus dem Catalog ermittelt werden kann,
      ** wird der interne String zurückgegeben.
      */
      const STRPTR str = CATSTRSTR((ULONG)item->nm_UserData,item->nm_Label);

      if(item->nm_Type == NM_TITLE)
      {
        item->nm_Label = (STRPTR)str;   /* Title-Strings werden ohne Shortcut angegeben */
      }
      else
      {
        item->nm_Label = (STRPTR)&str[2];
        if(str[0] != ' ') item->nm_CommKey = (STRPTR)str;  /* im ersten Byte steht der Shortcut */
      }
    }
  }

  if((visualinfo = GetVisualInfoA(gb_Screen,NULL)))
  {
    if((menu = CreateMenusA(newmenu,NULL)))
    {
      if((LayoutMenus(menu,visualinfo,GTMN_NewLookMenus,TRUE,TAG_DONE)))
      {
      }
      else { fprintf(stderr,"ERROR: can't layout menu.\n"); FreeMenus(menu); menu=NULL; }
    }
    else { fprintf(stderr,"ERROR: can't create menu.\n"); }

    FreeVisualInfo(visualinfo); 
  }
  else printf("ERROR: can't get visualinfo from screen.\n");

  return( menu );
}
 
/******************************************************************************/

void DeleteMenu(struct Menu *menu)
{
  if(menu) FreeMenus(menu);
}

/******************************************************************************/

LONG EasyRequester(const STRPTR text, const STRPTR button, ...)
{
  struct EasyStruct easyreq = { sizeof(struct EasyStruct),0,NULL,NULL,NULL };

  easyreq.es_Title        = (UBYTE *)PROGNAME;
  easyreq.es_TextFormat   = (UBYTE *)text;
  easyreq.es_GadgetFormat = (UBYTE *)button;

  return( EasyRequestArgs(gb_Window,&easyreq,NULL,(ULONG*)((&button)+1)) );
}

/******************************************************************************/

ULONG messageloop(void)
{
  /* Nachrichtenschleife */

  ULONG res=RETURN_FAIL;

  ULONG windowsignal, signals;

  /* Signalbit für das Fenster besorgen */
  /* get the signalbit for the windowmessages */
  GetAttr(WINDOW_SigMask,gb_WindowObj,&windowsignal);

  while(res == RETURN_FAIL)
  {
    /* auf das Eintreffen von Nachrichten warten oder CTRL-C für Abbruch */
    /* wait for a message or CTRL-C for user break */
    signals = Wait(windowsignal | SIGBREAKF_CTRL_C);

    /* Fenster-Nachrichten behandeln */
    /* handle the window-messages */
    if(signals & windowsignal) 
    {
      ULONG result, code;

      /* nächste Nachricht auslesen */
      /* get next message */

      /* result: oberes Word enthält die Classe, unteres Word die Event-Beschreibung */
      /* result: high word is the class, in low word is the event-describe */

      while((result = RA_HandleInput(gb_WindowObj,&code)) != WMHI_LASTMSG)  
      {
        switch(result & WMHI_CLASSMASK)
        {
          case WMHI_CLOSEWINDOW:
               res = RETURN_OK;
               break;

          case WMHI_GADGETUP:
               {
                 /* Gruppen-ID ermitteln, wir haben nur eine Gruppe, daher brauchen wir sie nicht weiter */
                 /* build group-id, we have only one group, so we need it */
                 const UWORD groupid = RL_GROUPID(result);

                 /* Gadget-ID ermitteln */
                 /* build gadget-id */
                 const UWORD gadid = RL_GADGETID(result);

                 if(gadid >= COUNTRY_FIRST && gadid < COUNTRY_MAX)
                 {
                   /* 
                   ** Es wurde eine Eingabe vorgenommen.
                   ** Den Wert auslesen (in eine Flieskommazhal umwandeln),
                   ** in die anderen Währungen umrechnen und anzeigen.
                   */
                   /*
                   ** The user has given a new input.
                   ** Read the value (convert to floatingpoint),
                   ** calculate to the other currencies and display it.
                   */
                   UBYTE *val;
                   if(GetAttr(STRINGA_TextVal,gb_Gadgets[gadid],(ULONG*)&val))
                     gb_Total[gadid] = atof(val);

                   Calculate(gadid,gb_Total[gadid]);
                   UpdateGadgets();
                 }

                 /* andere Gadgets behandeln */
                 /* handle the other gadgets */
                 switch(gadid)
                 {
                   default:
                     break;
                 }
               }
               break;

          case WMHI_ICONIFY:
               /* Fenster iconifizieren und Window-Pointer löschen */
               /* iconify window and clear window-pointer */
               RA_Iconify(gb_WindowObj); gb_Window = NULL;
               break;

          case WMHI_UNICONIFY:
               /* Fenster wieder vollständig anzeigen, Window-Pointer ermitteln */
               /* uniconify window and get the actual window-pointer */
               gb_Window = RA_OpenWindow(gb_WindowObj);
               break;

          case WMHI_MENUPICK:
               switch(result & WMHI_MENUMASK)
               {
                 case MENU_ID_Manual:
                      Execute("RUN >NIL: MultiView EuroCalc.guide",NULL,NULL);
                      break;

                 case MENU_ID_Print:
                      /* not jet implemented */
                      break;

                 case MENU_ID_Info:
                      EasyRequester("%s V%s %s %s\n\n"
                                    "%s\n\n"
                                    "Michael Christoph\n"
                                    "Irring 3\n"
                                    "94113 Tiefenbach\n"
                                    "<michael@meicky-soft.de>"
                                    ,CATSTR(TX_Ok)
                                    ,PROGNAME,VERSIONR,CATSTR(TX_From),PROGDATE,COPYRIGT 
                                   );
                      break;

                 case MENU_ID_Quit:
                      /* "\nSure to quit program ?","Yes|No" */
                      if(EasyRequester(CATSTR(TX_SureToQuit),CATSTR(TX_QuitYesNo)))
                        res = RETURN_OK;
                      break;

                 case MENU_ID_ClearAll:
                      /* Berechnung von 0 Euros löscht alle Felder */
                      /* calculation with 0 euros clear all fields */
                      ClearAllGadgets();
                      break;

                 case MENU_ID_Exchange:
                      /* not jet implemented */
                      break;
               }
               break;

          case WMHI_RAWKEY:
               /* RawKey Nachricht, unteres Byte enthält den Tastencode, Qualifier nur in der Hook-Routine */
               /* raw key event, lower byte are the keycode, qualifiers only in hook-routine */
               break;

          case WMHI_VANILLAKEY:
               /* ASCII-Tastencode im unteren Byte (siehe RawKey) */
               /* ASCII-code in the lower byte (see RawKey) */
               break;
        }
      }
    }

    /* CTRL-C behandeln */
    /* handle CTRL-C signal */
    if(signals & SIGBREAKF_CTRL_C)
      res = RETURN_BREAK;
  }

  return( res );
}

/******************************************************************************/

ULONG rungui(void)
{
  ULONG res = RETURN_FAIL;

  /* Zur Prüfung, ob AmigaOS 3.5 vorhanden ist, überprüfen wir die resource.library */
  /* as indicator if AmigaOS 3.5 is here, we will check the resource.library */

  if((ResourceBase = OpenLibrary("resource.library",44)))
  {
    /* alle benötigten Libraries öffnen */
    /* open all needed libraries */
    IntuitionBase = (struct IntuitionBase *) OpenLibrary("intuition.library",39);
    GadToolsBase = OpenLibrary("gadtools.library",38);
    LocaleBase = OpenLibrary("locale.library",38);
    IconBase = OpenLibrary("icon.library",39);

    if(IntuitionBase && GadToolsBase && LocaleBase && IconBase)
    {
      /* Catalog muß nicht zwingend vorhanden sein */
      /* catalog is not must and can be null */
      gb_Catalog = OpenCatalogA(NULL,PROGNAME ".catalog",NULL);

      /* Default-Public-Screen locken, normalerweise die Workbench */
      /* lock default-public-screen, normal the workbench */
      if((gb_Screen = LockPubScreen((UBYTE *) gb_Args[ARG_pubscreen])))
      {
        /* zwei Nachrichtenports für die (interne) Kommunikation anlegen */
        /* create two messageports for the (internal) communication */
        if((gb_IDCMPort = CreateMsgPort()))
        {
          if((gb_AppPort = CreateMsgPort()))
          {
            /* Resource-Verwaltung anlegen */
            /* create resource-manager */
            if((gb_Resource = RL_OpenResource(RCTResource,gb_Screen,gb_Catalog)))
            {
              /* Localisiertes menü erzeugen */
              /* create localized menu */
              if((gb_Menus = CreateMenu(gb_MenuDescribe)))
              {
                /* Neues Objekt erzeugen: das Hauptfenster */
                /* create new object: the mainwindow */
                if((gb_WindowObj = RL_NewObject(gb_Resource,WIN_ID_Main,
                                                WINDOW_SharedPort,   gb_IDCMPort,
                                                WINDOW_AppPort,      gb_AppPort,
                                                WINDOW_MenuStrip,    gb_Menus,
                                                WINDOW_MenuUserData, WGUD_IGNORE,
                                                /* Icon wird automatisch freigegeben */
                                                /* Icon will free qutomaticly */
                                                WINDOW_Icon,         GetDiskObject(gb_ProgName),
                                                TAG_DONE)))
                {
                  /* Array der Gadget-Zeiger für die Oberflächenelemente ermitteln */
                  /* get the array with the gadget-pointer to the guielementes */
                  gb_Gadgets = (struct Gadget **) RL_GetObjectArray(gb_Resource,gb_WindowObj,GROUP_ID_Main);

                  /* das Fenster öffnen und den Window-Pointer ermitteln */
                  /* open the window and get the window-pointer */
                  if((gb_Window = RA_OpenWindow(gb_WindowObj)))
                  {
                    /* nicht nutzbare Menüeinträge sperren */
                    /* disable unusable menuentries */
                    OffMenu(gb_Window,MENU_ID_Print);
                    OffMenu(gb_Window,MENU_ID_Exchange);

                    /* 1 Euro als Vorgabe ausgeben */
                    /* set 1 Euro as default */
                    gb_Total[GAD_ID_EUR] = 1.0;
                    Calculate(GAD_ID_EUR,gb_Total[GAD_ID_EUR]);
                    UpdateGadgets();

                    /* Programmschleife - Nachrichtenbehandlung */
                    /* programmloop - messagehandling */
                    res = messageloop();

                    /* Fenster schließen */
                    /* close window */
                    DoMethod(gb_WindowObj,WM_CLOSE);
                  }
                  else fprintf(stderr,"ERROR: can't open window.\n");
                }
                else fprintf(stderr,"ERROR: can't generate window object.\n");

                DeleteMenu(gb_Menus);
              }
              /* error was printed from CreateMenu() */

              /* Resource-Verwaltung schließen, gibt alle anderen Objekte frei */
              /* close resourcemanager, freed all other objects */
              RL_CloseResource(gb_Resource);
            }
            else fprintf(stderr,"ERROR: can't open resources.\n");

            /* Nachrichtenports freigeben */
            /* freed messageports */
            DeleteMsgPort(gb_AppPort);
          }
          else fprintf(stderr,"ERROR: can't create msgport.\n");

          DeleteMsgPort(gb_IDCMPort);
        }
        else fprintf(stderr,"ERROR: can't create msgport.\n");

        /* Bildschirmlock freigeben */
        /* freed screenlock */
        UnlockPubScreen(NULL,gb_Screen);
      }
      else if(gb_Args[ARG_pubscreen]) fprintf(stderr,"ERROR: can't look default public screen.\n");
           else                       fprintf(stderr,"ERROR: can't look public screen \"%s\".\n",gb_Args[ARG_pubscreen]);

      if(gb_Catalog) CloseCatalog(gb_Catalog);
    }
    else fprintf(stderr,"ERROR: can't open intuition/gadtools/locale/icon.library.\n");

    /* geöffnete Libraries schließen */
    /* closed all open libraries */
    if(IconBase)      CloseLibrary(IconBase);
    if(LocaleBase)    CloseLibrary(LocaleBase);
    if(GadToolsBase)  CloseLibrary(GadToolsBase);
    if(IntuitionBase) CloseLibrary((struct Library *)IntuitionBase);

    CloseLibrary(ResourceBase);
  }
  else fprintf(stderr,"Program required AmigaOS 3.5 !!\nERROR: can't open resource.library V44.\n");

  return( res );
}

/******************************************************************************/

UWORD Currency2GadID(const STRPTR currency)
{
  /* wandelt die Währungsbezeichnung in die korespondierende GadgetID um */
  /* get the gadgetid for the koresponding currency */
  UWORD res=0;
  ULONG i;

  for(i=1; i<COUNTRY_MAX; i++)
  {
    if(stricmp(currency,gb_Countries[i].ll_Currency) == 0)
      { res = gb_Countries[i].ll_GadID; break; }
  }

  return( res );
}

/******************************************************************************/

/***** StormC/MaxonC Workbench start *****/

#ifdef __cplusplus
extern "C"
#endif
void wbmain(struct WBStartup *WBenchMsg)
{
  BPTR olddir;

  /* eine Ausgabeconsole für die Fehlermeldungen öffnen */
  /* open an outputconsole for errormessages */

  if(!freopen("CON:10/25/500/188/EuroCalc Output/AUTO/CLOSE", "w+", stdout))
  {
    /* Ein/Ausgabekanal konnte nicht neu eingerichtet werden */
    /* in/outputchannel can't reopen */
    Alert(AT_Recovery | AG_IOError | AO_DOSLib);  /* Alert 0006 8007 */
    return;
  }


  /* ins Programmverzeichnis wechseln */
  /* change directory to the program dir */
  olddir = CurrentDir(WBenchMsg->sm_ArgList->wa_Lock) ;
  strcpy(gb_ProgName,WBenchMsg->sm_ArgList->wa_Name);

  /* Tooltypes auswerten */
  /* extract tooltypes */
  if((IconBase = OpenLibrary("icon.library",37)))
  {
    struct DiskObject *dobj;

    if((dobj = GetDiskObject(WBenchMsg->sm_ArgList->wa_Name)))  /* Wir haben ein Icon! */
    {                                                           /* We have an icon */
      gb_Args[ARG_pubscreen] = (ULONG) FindToolType((STRPTR *) dobj->do_ToolTypes,"PUBSCREEN");
    }

    CloseLibrary(IconBase); IconBase = NULL;
  }
  else Alert(AT_Recovery | AG_OpenLib | AO_IconLib);  /* 0003 8009 */

  rungui();

  /* zurück ins Aufrufverzeichnis */
  /* back to the startdir */
  CurrentDir(olddir);
}

/***** Shell start *****/

void main(void)
{
  ULONG res = RETURN_FAIL;
  BPTR olddir;
  UBYTE progname[100];

  DOUBLE eurores = 0.0;
  DOUBLE total = 0.0;
  const UBYTE *currency = "";
  struct RDArgs *rda = NULL;

  /* ins Programmverzeichnis wechseln und Programmnamen ermitteln */
  /* change directory to the program dir and get programname */
  olddir = CurrentDir(GetProgramDir());
  GetProgramName(progname,100);
  strcpy(gb_ProgName,FilePart(progname));  /* evtl. Pfadangabe entfernen */
                                           /* skip path when available */

  if((rda=ReadArgs(gb_ArgTemplate,gb_Args,NULL)))
  {
    if(gb_Args[ARG_total])
    {
      res = RETURN_OK;

      /*
      ** es wurde eine Betrag übergeben:
      ** dieser wird sofort in die angegebenen Zielwährungen
      ** umgerechnet und die Ergebnisse ausgegeben.
      */
      /*
      ** user will give arguments:
      ** calculate it to the zielcurrency and print it out
      */
      if(gb_Args[ARG_total])    total    = atof((UBYTE*)gb_Args[ARG_total]);
      if(gb_Args[ARG_currency]) currency = (UBYTE*) gb_Args[ARG_currency];

//      eurores = Calculate(currency,total);

      if(gb_Args[ARG_to])
      {
        /* alle Währungskennzeichen; für Argument "ALL" */
        /* all -Währungskennzeichen-; for argument "ALL" */
        const STRPTR gb_AllCurrencies[] =
        {
          "EURO", "DM", "BFR", "FMK", "FF", "IRF", "LIT", "LFR", "HFL", "OES", "ESC", "PTA", NULL
        };

        /* Zielwährung wurde angegeben */
        /* zielcurrency will given */
        UBYTE **toarg = (stricmp(((UBYTE**)gb_Args[ARG_to])[0],"ALL")==0 ?
                                (UBYTE**)gb_AllCurrencies :
                                (UBYTE**)gb_Args[ARG_to]);
        for(; *toarg; toarg++)
        {
          UWORD currencyid;
          if((currencyid = Currency2GadID(*toarg)))
          {
            Calculate(currencyid,total);
            printf(FMT_CurrencyOutput " %s\n",*toarg);
          }
          else
          {
            fprintf(stderr,"unknown currency '%s'.\n",*toarg);
            res = RETURN_ERROR;
          }
        }
      }
      else printf(FMT_CurrencyOutput " EURO\n",eurores);
    }
    else
    {
      /* ohne Parameter die Oberfläche darstellen */
      /* without arguments the gui will opend */
      res = rungui();
    }

    FreeArgs(rda);
  }
  else
  {
    PrintFault(IoErr(),gb_ProgName);
    res = RETURN_ERROR;
  }

  /* zurück ins Aufrufverzeichnis */
  /* back to the startdir */
  CurrentDir(olddir);

  exit( res );
}

/******************************************************************************/

