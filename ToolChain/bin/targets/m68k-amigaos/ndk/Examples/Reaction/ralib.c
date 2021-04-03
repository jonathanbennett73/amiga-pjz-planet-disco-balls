/*
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


   After SetGadgetAttrsA() a BOOPSI gadget returns 0 if it does not need
   refreshing and returns a value != 0 if it needs refreshing.

   But GADGETCLASS breaks this rule: It always returns 0. But especially
   after setting GA_Disabled the gadget needs refreshing most time.

   The following 4 function encapsulate this:

   1. RefreshSetGadgetAttrsA() set the gadget attributes and refreshs the
      gadget if it says so or if the disable flag changed.

   2. RefreshSetGadgetAttrs() is a tag stub function
      for RefreshSetGadgetAttrsA().

   3. RefreshSetPageGadgetAttrsA() is like RefreshSetGadgetAttrsA() but needs
      the parent page object also. It must be used if the gadget is part of
      a page object and may or may not be visible.

   4. RefreshSetPageGadgetAttrs() is a tag stub function
      for RefreshSetPageGadgetAttrsA().

	Note: If a gadget does handle GA_Disabled itself and does refresh itself
	      it is refreshed a second time using this function. In that case you
	      should not use these function but SetGadgetAttrsA() and
	      SetPageGadgetAttrsA().

*/

#include <intuition/gadgetclass.h>

#include <clib/utility_protos.h>
#include <clib/intuition_protos.h>
#include <clib/layout_protos.h>

ULONG
RefreshSetGadgetAttrsA(struct Gadget *g, struct Window *w, struct Requester *r, struct TagItem *tags)
{
	ULONG retval;
	BOOL changedisabled = FALSE;
	BOOL disabled;

	if (w)
	{
		if (FindTagItem(GA_Disabled,tags))
		{
			changedisabled = TRUE;
 			disabled = g->Flags & GFLG_DISABLED;
 		}
 	}
	retval = SetGadgetAttrsA(g,w,r,tags);
	if (w && (retval || (changedisabled && disabled != (g->Flags & GFLG_DISABLED))))
	{
		RefreshGList(g,w,r,1);
		retval = 1;
	}
	return retval;
}

ULONG
RefreshSetGadgetAttrs(struct Gadget *g, struct Window *w, struct Requester *r, Tag tag1, ...)
{
	return RefreshSetGadgetAttrsA(g,w,r,(struct TagItem *) &tag1);
}

ULONG
RefreshSetPageGadgetAttrsA(struct Gadget *g, Object *p, struct Window *w, struct Requester *r, struct TagItem *tags)
{
	ULONG retval;
	BOOL changedisabled = FALSE;
	BOOL disabled;
	if (w)
	{
		if (FindTagItem(GA_Disabled,tags))
		{
			changedisabled = TRUE;
 			disabled = g->Flags & GFLG_DISABLED;
 		}
 	}
	retval = SetPageGadgetAttrsA(g,p,w,r,tags);
	if (w && (retval || (changedisabled && disabled != (g->Flags & GFLG_DISABLED))))
	{
		RefreshPageGadget(g,p,w,r);
		retval = 1;
	}
	return retval;
}

ULONG
RefreshSetPageGadgetAttrs(struct Gadget *g, Object *p, struct Window *w, struct Requester *r, Tag tag1, ...)
{
	return RefreshSetPageGadgetAttrsA(g,p,w,r,(struct TagItem *) &tag1);
}
