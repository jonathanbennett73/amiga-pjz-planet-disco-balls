/*
 * $Id: dispatch.c 1.1 1997/06/25 18:46:44 olsen Exp $
 *
 * ARexx sample library
 *
 * :ts=4
 */

#include "rexxsamplebase.h"

/****************************************************************************/

	/* StringToNumber(STRPTR String,struct RexxSampleBase *RexxSampleBase):
	 *
	 *	Convert a string into a number.
	 */

LONG
StringToNumber(
	STRPTR					String,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG Result;

		/* Uses the dos.library code. */

	StrToLong(String,&Result);

	return(Result);
}

	/* NumberToString(LONG Value,STRPTR String,struct RexxSampleBase *RexxSampleBase):
	 *
	 *	Convert a number into a string. This is done using the
	 *	utility.library integer math routines and thus looks a
	 *	bit bizarre...
	 */

VOID
NumberToString(
	LONG					Value,
	STRPTR					String,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG Sign;
	LONG Next;
	LONG Len;
	LONG i;
	UBYTE c;

	if(Value < 0)
	{
		Sign = -1;
		Value = (-Value);
	}
	else
	{
		Sign = 1;
	}

	Len = 0;

	while(Value > 0 && Len < 15)
	{
		Next = SDivMod32(Value,10);

		String[Len++] = (Value - SMult32(Next,10)) + '0';

		Value = Next;
	}

	if(Sign < 0)
		String[Len++] = '-';

	String[Len] = 0;

	if(Len > 1)
	{
		for(i = 0 ; i < Len / 2 ; i++)
		{
			c						= String[i];
			String[i]				= String[Len - (i + 1)];
			String[Len - (i + 1)]	= c;
		}
	}
}

/****************************************************************************/

LONG
Cmd_Add(
	STRPTR *				Args,
	LONG *					Error,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG a;
	LONG b;
	LONG result;

	a = StringToNumber(Args[0],RexxSampleBase);
	b = StringToNumber(Args[1],RexxSampleBase);

	result = a + b;

	return(result);
}

LONG
Cmd_Sub(
	STRPTR *				Args,
	LONG *					Error,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG a;
	LONG b;
	LONG result;

	a = StringToNumber(Args[0],RexxSampleBase);
	b = StringToNumber(Args[1],RexxSampleBase);

	result = a - b;

	return(result);
}

LONG
Cmd_Mul(
	STRPTR *				Args,
	LONG *					Error,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG a;
	LONG b;
	LONG result;

	a = StringToNumber(Args[0],RexxSampleBase);
	b = StringToNumber(Args[1],RexxSampleBase);

	result = SMult32(a,b);

	return(result);
}

LONG
Cmd_Div(
	STRPTR *				Args,
	LONG *					Error,
	struct RexxSampleBase *	RexxSampleBase)
{
	LONG a;
	LONG b;
	LONG result;

	a = StringToNumber(Args[0],RexxSampleBase);
	b = StringToNumber(Args[1],RexxSampleBase);

	if(b == 0)
	{
		result = 0;

		(*Error) = ERR10_018;	/* Invalid argument to function. */
	}
	else
	{
		result = SDivMod32(a,b);
	}

	return(result);
}

/****************************************************************************/

STATIC struct RexxCmd CommandTable[] =
{
	"ADD",	2,		Cmd_Add,
	"SUB",	2,		Cmd_Sub,
	"MUL",	2,		Cmd_Mul,
	"DIV",	2,		Cmd_Div,

	NULL,	NULL,	NULL
};

/****************************************************************************/

#define SAME	(0)
#define OK		(0)
#define NOT		!

/****************************************************************************/

	/* RexxDispatch():
	 *
	 *	This is the function dispatcher. For every ARexx script that has
	 *	added this library to its list of hosts to be searched the ARexx
	 *	resident process will pass each single command through here.
	 *	If we can handle one of the commands, we tell the resident process
	 *	by returning 0, indicating "no error, command was handled". If
	 *	the command is unknown to us, we *must* return error ERR10_001,
	 *	indicating "we do not know this command". In the latter case,
	 *	the resident process will pass the command on to the next host
	 *	in the list of hosts.
	 */

LONG ASM
RexxDispatch(
	REG(a0) struct RexxMsg *		RexxMsg,
	REG(a1) STRPTR *				Result,
	REG(a6) struct RexxSampleBase *	RexxSampleBase)
{
	LONG Error = ERR10_001;	/* Program not found. */
	BOOL Found = FALSE;
	LONG i;

		/* Search the table for the command. */

	for(i = 0 ; NOT Found && CommandTable[i].Name != NULL ; i++)
	{
			/* Does this one match? */

		if(Stricmp(RexxMsg->rm_Args[0],CommandTable[i].Name) == SAME)
		{
			Found = TRUE;

				/* Do the number of arguments match? The
				 * number is passed in the lower eight bits
				 * of the action field. Up to 15 arguments
				 * can be passed to your library. Each
				 * argument represents a pointer to a
				 * null-terminated string.
				 */

			if((RexxMsg->rm_Action & 0xFF) != CommandTable[i].NumArgs)
			{
				Error = ERR10_017;	/* Wrong number of arguments. */
			}
			else
			{
				UBYTE String[20];
				LONG Number;

					/* Clear the error value. */

				Error = OK;

					/* Invoke the command. */

				Number = (*CommandTable[i].Cmd)(&RexxMsg->rm_Args[1],
				                                &Error,
				                                RexxSampleBase);

					/* Did the command return without
					 * error?
					 */

				if(Error == OK)
				{
						/* Convert the number to a string.
						 * The library result has to be
						 * a standard ARexx string.
						 */

					NumberToString(Number,String,RexxSampleBase);

						/* Make a copy of the string. This
						 * is what we will return as the
						 * result to to the caller.
						 */

					(*Result) = CreateArgstring(String,strlen(String));

						/* If the result string could not
						 * be created, flag this as an error.
						 */

					if((*Result) == NULL)
						Error = ERR10_003;	/* No memory available. */
				}
			}
		}
	}

		/* Return the error if any. */

	return(Error);
}
