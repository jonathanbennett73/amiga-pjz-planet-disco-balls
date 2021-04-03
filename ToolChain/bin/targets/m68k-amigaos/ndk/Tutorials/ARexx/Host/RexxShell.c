/****************************************************************************/

#include <dos/dosextens.h>
#include <dos/dostags.h>
#include <dos/rdargs.h>

#include <exec/execbase.h>

#include <rexx/rxslib.h>
#include <rexx/errors.h>

#include <clib/rexxsyslib_protos.h>
#include <clib/utility_protos.h>
#include <clib/exec_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/rexxsyslib_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>
#include <stdio.h>

/****************************************************************************/

struct CmdArgs
{
	STRPTR HostName;	/* Name of host to send commands to. */
	STRPTR Extension;	/* Default file name extension. */
	LONG String;		/* Input are short programs rather than
				 * program names.
				 */
};

/****************************************************************************/

	/* Defined and initialized by compiler startup code. */

extern struct Library * SysBase;
extern struct Library * DOSBase;

	/* To be initialized by this program. */

struct Library * RexxSysBase;
struct Library * UtilityBase;

/****************************************************************************/

int
main(int argc,char **argv)
{
	struct MsgPort *ReplyPort;
	struct MsgPort *RexxPort;
	struct RexxMsg *RexxMessage;
	struct RDArgs *Args;
	struct CmdArgs Parameters;
	UBYTE Command[256];
	UBYTE HostName[80];
	LONG Len;
	LONG i;
	BOOL Done;
	BOOL Sent;

		/* This program requires AmigaOS v2.04 or higher to run. */

	if(SysBase->lib_Version < 37)
	{
		printf("This program requires AmigaOS v2.04 or higher to run.\n");

		return(RETURN_FAIL);
	}

		/* Open the Rexx system library. */

	RexxSysBase = OpenLibrary(RXSNAME,0);

	if(RexxSysBase == NULL)
	{
		Printf("Error opening %s.\n",RXSNAME);

		return(RETURN_FAIL);
	}

		/* Open utility.library, we will need it for string
		 * comparison and to convert the host name to
		 * upper case characters.
		 */

	UtilityBase = OpenLibrary("utility.library",37);

	if(UtilityBase == NULL)
	{
		Printf("Error opening %s v37.\n","utility.library");

		CloseLibrary(RexxSysBase);

		return(RETURN_FAIL);
	}

		/* Create the message reply port. */

	ReplyPort = CreateMsgPort();

	if(ReplyPort == NULL)
	{
		Printf("Could not create message reply port.\n");

		CloseLibrary(RexxSysBase);
		CloseLibrary(UtilityBase);

		return(RETURN_FAIL);
	}

		/* Clear the command line argument storage. */

	Parameters.HostName = NULL;
	Parameters.Extension = NULL;
	Parameters.String = FALSE;

		/* Read the command line arguments. */

	Args = ReadArgs("HOST,EXTENSION,STRING/S",(LONG *)&Parameters,NULL);

	if(Args == NULL)
	{
			/* Print an error message. */

		PrintFault(IoErr(),"RexxShell");

		DeleteMsgPort(ReplyPort);

		CloseLibrary(RexxSysBase);
		CloseLibrary(UtilityBase);

		return(RETURN_FAIL);
	}

		/* If a default host name was provided, convert
		 * it to upper case characters.
		 */

	if(Parameters.HostName == NULL)
		strcpy(HostName,"REXX");
	else
	{
			/* We will truncate the name if it is
			 * longer than 79 characters.
			 */

		Len = strlen(Parameters.HostName);

		if(Len > 79)
			Len = 79;

		for(i = 0 ; i < Len ; i++)
			HostName[i] = ToUpper(Parameters.HostName[i]);

			/* Provide null-termination. */

		HostName[Len] = 0;
	}

		/* Print the welcome message. */

	Printf("Enter names of ARexx scripts to execute. To quit\n");
	Printf("just enter \"stop\".\n");

		/* Show our current parameters. */

	Printf("Default host name is \"%s\".\n",HostName);

	if(Parameters.Extension == NULL)
		Printf("Default file name extension is \"%s\".\n","REXX");
	else
		Printf("Default file name extension is \"%s\".\n",Parameters.Extension);

	if(Parameters.String == FALSE)
		Printf("Input is interpreted as names of commands to execute.\n");
	else
		Printf("Input is interpreted as short Rexx commands.\n");

	Done = FALSE;

		/* Loop until the user enters "stop" or
		 * closes the console window.
		 */

	do
	{
			/* Show the prompt. */

		Printf("RX> ");
		Flush(Output());

			/* Read the user input, stop if the console
			 * window gets closed.
			 */

		if(FGets(Input(),Command,sizeof(Command) - 1) == NULL)
			Done = TRUE;
		else
		{
				/* Chop off the trailing line feed
				 * character if any.
				 */

			Len = strlen(Command);

			if((Len > 0) && (Command[Len - 1] == '\n'))
				Command[--Len] = 0;

				/* Stop if the user wants us to stop. */

			if(Stricmp(Command,"stop") == 0)
				Done = TRUE;
		}

			/* Should we continue and do we have a
			 * command to execute?
			 */

		if((Done == FALSE) && (Len > 0))
		{
				/* Set up the RexxMsg we want to use.
				 *
				 * The extension tells the Rexx process how
				 * to construct the name of the file it
				 * is to execute. For example, if the
				 * extension were "demo" and the command
				 * were "test" it would look for a command
				 * file named "test.demo" and if this could
				 * not be found search for "test.rexx".
				 *
				 * The host name tells Rexx which host to
				 * address when it finds a command it does
				 * not know.
				 *
				 * If no extension or host name is provided,
				 * i.e. NULL parameters are given, the
				 * parameters default to "REXX".
				 */

			RexxMessage = CreateRexxMsg(ReplyPort,
				Parameters.Extension,HostName);

			if(RexxMessage == NULL)
				Printf("Error creating rexx message.\n");
			else
			{
					/* Make the command ready. */

				RexxMessage->rm_Args[0] = CreateArgstring(Command,Len);

				if(RexxMessage->rm_Args[0] == NULL)
					Printf("Error creating message argument.\n");
				else
				{
						/* Mark the message as a command. */

					RexxMessage->rm_Action = RXCOMM;

						/* The Rexx process can interprete
						 * the message arguments in two different
						 * ways. If the RXFF_STRING flag is not
						 * set and the first character of the
						 * command string is not a quote or
						 * double quote Rexx will try to find
						 * a program matching the command name.
						 * Otherwise, the command will be treated
						 * as a short Rexx program.
						 */

					if(Parameters.String != FALSE)
						RexxMessage->rm_Action |= RXFF_STRING;

						/* Now try to find the resident process
						 * communications port. We need to
						 * turn off multitasking while we look
						 * for it and send the message.
						 */

					Forbid();

					if(RexxPort = FindPort(RXSDIR))
					{
						PutMsg(RexxPort,RexxMessage);

						WaitPort(ReplyPort);
						GetMsg(ReplyPort);

						Sent = TRUE;
					}
					else
						Sent = FALSE;

					Permit();

						/* Was the message sent to Rexx? */

					if(Sent == FALSE)
						Printf("Could not send message, REXX host not found.\n");
					else
					{
						Printf("Command \"%s\" has returned with result %ld,%ld\n",
							Command,RexxMessage->rm_Result1,RexxMessage->rm_Result2);
					}

					DeleteArgstring(RexxMessage->rm_Args[0]);
				}

				DeleteRexxMsg(RexxMessage);
			}
		}
	}
	while(Done == FALSE);

		/* Clean up. */

	FreeArgs(Args);

	DeleteMsgPort(ReplyPort);

	CloseLibrary(RexxSysBase);
	CloseLibrary(UtilityBase);

	return(RETURN_OK);
}
