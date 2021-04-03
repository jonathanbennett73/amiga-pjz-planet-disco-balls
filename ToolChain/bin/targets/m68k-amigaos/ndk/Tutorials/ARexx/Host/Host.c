/*
 * $Id$
 *
 * ARexx host demo
 *
 * :ts=8
 */

/****************************************************************************/

#include <dos/dosextens.h>
#include <dos/dostags.h>
#include <dos/rdargs.h>

#include <exec/execbase.h>
#include <exec/memory.h>

#include <rexx/rxslib.h>
#include <rexx/errors.h>

#include <clib/rexxsyslib_protos.h>
#include <clib/utility_protos.h>
#include <clib/exec_protos.h>
#include <clib/alib_protos.h>
#include <clib/dos_protos.h>

#include <pragmas/rexxsyslib_pragmas.h>
#include <pragmas/utility_pragmas.h>
#include <pragmas/exec_pragmas.h>
#include <pragmas/dos_pragmas.h>

#include <string.h>
#include <stdio.h>

/****************************************************************************/

	/* We define a bunch of data structures here. While the basic work
	 * of maintaining the Rexx host will work without wrapping it neatly
	 * into a special data structure, it certainly helps.
	 */

struct RexxHost
{
	APTR			UserData;
	struct CmdFunc *	CommandTable;

	struct MsgPort *	GlobalPort;
	UBYTE			PortName[1];
};

	/* This is for parsing commands the ARexx port receives. We employ
	 * the dos.library/ReadArgs parser for this purpose.
	 */

struct RexxParseData
{
	struct RDArgs *	ReadArgs;
	UBYTE		Line[512];	/* We allow for commands to be up to
					 * 511 characters long. This is far
					 * below the maximum string length
					 * limit ARexx imposed (32768
					 * characters) but should be more
					 * than sufficient for normal
					 * applications.
					 */
	STRPTR		Args[32];	/* Up to 32 command arguments are
					 * allowed.
					 */
};

	/* A table to map command names to functions which
	 * will handle them.
	 */

struct CmdFunc
{
	STRPTR CommandName;	/* Name of the command. */
	STRPTR Template;	/* The command template in standard
				 * AmigaDOS syntax.
				 */

		/* Pointer to the function which implements this command. */

	LONG (*Function)(APTR,struct RexxMsg *,STRPTR *);
};

	/* The local data used by the functions the host supports. */

struct LocalData
{
	struct CmdFunc *	CommandTable;	/* Pointer to table of commands. */
	struct MsgPort *	GlobalPort;	/* Copied from RexxHost. */
	STRPTR			PortName;	/* Copied from RexxHost. */
	ULONG			Usage;		/* Usage count for Rx command. */
	BOOL			Terminate;	/* Set to TRUE if host should exit. */
};

	/* This is a custom message the Rx command will need if the
	 * "CONSOLE" keyword is used.
	 */

struct ChildMessage
{
	struct Message		Message;	/* Common message header. */

	struct RexxMsg *	RexxMsg;	/* The client message. */
	STRPTR			PortName;	/* Copied from LocalData. */
	UBYTE			Command[1];	/* Command to execute. */
};

/****************************************************************************/

	/* Defined and initialized by compiler startup code. */

extern struct Library *	SysBase;
extern struct Library *	DOSBase;

	/* To be initialized by this program. */

struct Library * RexxSysBase;
struct Library * UtilityBase;

/****************************************************************************/

/****** Host/CreateRexxHost **************************************************
*
*   NAME
*       CreateRexxHost -- Create a public message port for use as an ARexx
*           host address.
*
*   SYNOPSIS
*       Host = CreateRexxHost(BaseName,Index,CommandTable,UserData)
*
*       struct RexxHost *CreateRexxHost(const STRPTR BaseName,ULONG Index,
*           const struct CmdFunc *CommandTable,const APTR UserData);
*
*   FUNCTION
*       You supply a name and a project index, this routine will set up
*       a public message port for use as an ARexx host address for you
*       with the name you provided. The name will be checked for validity
*       (it may not hold blank spaces or tabs) and converted to all
*       upper case letters. If a non-zero project index number is provided,
*       a numeric extension will be added to the message port name.
*       This routine will try to make sure that the message port will bear
*       a unique name. For your convenience, you can have the host data
*       structure with a user data pointer.
*
*       Please keep the length of the port name down to up to 20 characters,
*       many users prefer short host names. This routine will reject names
*       longer than 80 characters.
*
*       The name is converted to all upper case characters to make it easier
*       to access the host name in ARexx scripts. Lower case names require
*       quoting whereas upper case names do not.
*
*   INPUTS
*       BaseName - Name of message port to create; the name may not
*           contain blank spaces or tabs and will be converted to
*           all upper case letters. The name you provide may be up to
*           80 characters long.
*
*       Index - Project index number; if nonzero will cause a numeric
*           extension to be added to the port name, i.e. for an index
*           number of 1 the name "BASENAME" will become "BASENAME.1".
*
*       CommandTable - Points to the first element of the array in
*           which command names, templates and functions are stored.
*
*       UserData - User data pointer which will be copied into the
*           RexxHost structure.
*
*   RESULT
*       Host - Pointer to RexxHost created or NULL if creation failed.
*           If NULL is returned you can retrieve an error code through
*           dos.library/IoErr.
*
*   SEE ALSO
*       exec.library/AddPort
*       exec.library/CreateMsgPort
*       dos.library/IoErr
*
******************************************************************************
*
*/

struct RexxHost *
CreateRexxHost(
	const STRPTR		BaseName,
	ULONG			Index,
	const struct CmdFunc *	CommandTable,
	const APTR		UserData)
{
	struct Process * ThisProcess;
	struct RexxHost * Host;
	UBYTE PortName[90];
	LONG Error;
	LONG Size;
	LONG Len;
	LONG i;

		/* No host created yet. */

	Host = NULL;

		/* No error so far. */

	Error = 0;

		/* Check for NULL name. */

	if(BaseName == NULL)
		Error = ERROR_REQUIRED_ARG_MISSING;

		/* Check for illegal characters. */

	if(Error == 0)
	{
		Len = strlen(BaseName);

		for(i = 0 ; (Error == 0) && (i < Len) ; i++)
		{
			if(BaseName[i] == ' ' || BaseName[i] == '\t')
				Error = ERROR_INVALID_COMPONENT_NAME;
		}
	}

		/* Check the name length. */

	if(Error == 0)
	{
		if(Len > 80)
			Error = ERROR_OBJECT_TOO_LARGE;
	}

		/* Create the RexxHost data. */

	if(Error == 0)
	{
			/* Add the index number if provided. */

		if(Index != 0)
			sprintf(PortName,"%s.%ld",BaseName,Index);
		else
			strcpy(PortName,BaseName);

			/* Convert the port name to all upper case
			 * characters.
			 */

		for(i = 0 ; i < Len ; i++)
			PortName[i] = ToUpper(PortName[i]);

			/* Allocate space for the RexxHost. The name
			 * requires a terminating 0-byte which is included
			 * in the RexxHost structure.
			 */

		Size = sizeof(struct RexxHost) + strlen(PortName);

		Host = (struct RexxHost *)AllocVec(Size,
			MEMF_ANY|MEMF_CLEAR|MEMF_PUBLIC);

			/* Did we get the memory we wanted? */

		if(Host == NULL)
			Error = ERROR_NO_FREE_STORE;
		else
		{
				/* Set up the message port. */

			Host->GlobalPort = CreateMsgPort();

				/* Did we get the port? If the creation
				 * failed we either ran out of free
				 * signal bits or memory.
				 */

			if(Host->GlobalPort == NULL)
				Error = ERROR_NO_FREE_STORE;
			else
			{
					/* Fill in the host data. Since the
					 * port will be searched for often
					 * by the ARexx resident process we
					 * assign it a priority of 1.
					 */

				strcpy(Host->PortName,PortName);

				Host->GlobalPort->mp_Node.ln_Name =
					Host->PortName;

				Host->GlobalPort->mp_Node.ln_Pri = 1;

				Host->CommandTable = CommandTable;
				Host->UserData = UserData;
			}
		}
	}

		/* Try to add the message port. */

	if(Error == 0)
	{
			/* We need to turn off multitasking for a moment
			 * while we access the global message port list.
			 */

		Forbid();

			/* Check if there already is a message port by
			 * the name we just used.
			 */

		if(FindPort(Host->PortName))
			Error = ERROR_OBJECT_EXISTS;

			/* If there is no such port yet, add the new
			 * message port to the public list.
			 */

		if(Error == 0)
			AddPort(Host->GlobalPort);

			/* Enable multitasking again. */

		Permit();
	}

		/* Did we succeed? */

	if(Error == 0)
		return(Host);
	else
	{
			/* Clean up the host data. */

		if(Host != NULL)
		{
				/* Delete the message port. This call
				 * will succeed even if the pointer is
				 * NULL.
				 */

			DeleteMsgPort(Host->GlobalPort);

				/* Free the memory allocated for the
				 * host data.
				 */

			FreeVec(Host);
		}

			/* Obtain the control structure for this Process
			 * or Task. We need to set an error code, but the
			 * system call we will make can only be made by
			 * a Process.
			 */

		ThisProcess = (struct Process *)FindTask(NULL);

			/* If a process is making the call, set the
			 * error code so it can later be retrieved
			 * through IoErr().
			 */

		if(ThisProcess->pr_Task.tc_Node.ln_Type == NT_PROCESS)
			SetIoErr(Error);

			/* Return failure. */

		return(NULL);
	}
}

/****** Host/DeleteRexxHost **************************************************
*
*   NAME
*       DeleteRexxHost -- Remove a rexx host port previously created by
*           CreateRexxHost.
*
*   SYNOPSIS
*       DeleteRexxHost(Host)
*
*       VOID DeleteRexxHost(struct RexxHost *);
*
*   FUNCTION
*       Before your application exits, call this routine on every rexx host
*       environment you created with CreateRexxHost(). If you forget to do so
*       your application will leave unused memory and, in case it was
*       run from Shell, signal bits allocated which can never be reclaimed.
*
*   INPUTS
*       Host - Result of CreateRexxHost() call. May be NULL in which case
*           this routine will do nothing.
*
*   RESULT
*       None
*
*   SEE ALSO
*       exec.library/DeleteMsgPort
*       exec.library/RemPort
*       CreateRexxHost
*
******************************************************************************
*
*/

VOID
DeleteRexxHost(struct RexxHost * Host)
{
	struct RexxMsg * Message;

		/* Did we get a valid host pointer? */

	if(Host != NULL)
	{
			/* Turn off multitasking while we remove the
			 * public message port.
			 */

		Forbid();

			/* Remove the message port. */

		RemPort(Host->GlobalPort);

			/* Now enable multitasking again. */

		Permit();

			/* Remove all pending rexx messages from the
			 * port and reply them to their owners.
			 */

		while((Message = (struct RexxMsg *)GetMsg(Host->GlobalPort))
			!= NULL)
		{
				/* Reject all messages. */

			Message->rm_Result1 = RC_FATAL;

			ReplyMsg((struct Message *)Message);
		}

			/* Delete the message port. */

		DeleteMsgPort(Host->GlobalPort);

			/* Free the memory allocated. */

		FreeVec(Host);
	}
}

/****************************************************************************/

/****** Host/CreateRexxParseData *********************************************
*
*   NAME
*       CreateRexxParseData -- Create working data for command parsing.
*
*   SYNOPSIS
*       Data = CreateRexxParseData()
*
*       struct RexxParseData *CreateRexxParseData(VOID);
*
*   FUNCTION
*       The commands the host receives from the Rexx resident process will
*       need further processing. This is what the command parser will do,
*       but it needs environment data to work with. This routine allocates
*       the work space it needs.
*
*   INPUTS
*       None
*
*   RESULT
*       Data - Pointer to RexxParseData structure or NULL if it could not
*           be allocated. If NULL is returned the error code can be
*           obtained through IoErr().
*
*   SEE ALSO
*       dos.library/AllocDosObject
*       dos.library/IoErr
*
******************************************************************************
*
*/

struct RexxParseData *
CreateRexxParseData(VOID)
{
	struct Process * ThisProcess;
	struct RexxParseData * Data;
	LONG Error;

		/* No data was allocated yet. */

	Data = NULL;

		/* No error has occured yet. */

	Error = 0;

		/* Allocate the basic parser data. */

	Data = AllocVec(sizeof(struct RexxParseData),MEMF_ANY|MEMF_CLEAR);

		/* Did we get the memory? */

	if(Data == NULL)
		Error = ERROR_NO_FREE_STORE;

		/* Allocate the ReadArgs data. */

	if(Error == 0)
	{
			/* AllocDosObjectTagList is a dos.library call which
			 * can be made by a Task.
			 */

		Data->ReadArgs = AllocDosObjectTagList(DOS_RDARGS,NULL);

			/* Did we get the data? */

		if(Data->ReadArgs == NULL)
			Error = ERROR_NO_FREE_STORE;
	}

		/* Did we succeed? */

	if(Error == 0)
		return(Data);
	else
	{
			/* Clean up the parser data; in this case failure
			 * means either the ReadArgs data or the data
			 * structure itself could not be allocated. Thus,
			 * we only need to take care of the data, a single
			 * call to FreeVec() is sufficient. Since FreeVec()
			 * can be called with a NULL parameter we do not
			 * need to check if the data pointer is valid.
			 */

		FreeVec(Data);

			/* Obtain the control structure for this Process
			 * or Task. We need to set an error code, but the
			 * system call we will make can only be made by
			 * a Process.
			 */

		ThisProcess = (struct Process *)FindTask(NULL);

			/* If a process is making the call, set the
			 * error code so it can later be retrieved
			 * through IoErr().
			 */

		if(ThisProcess->pr_Task.tc_Node.ln_Type == NT_PROCESS)
			SetIoErr(Error);

			/* Return failure. */

		return(NULL);
	}
}

/****** Host/DeleteRexxParseData *********************************************
*
*   NAME
*       DeleteRexxParseData -- Free data allocated by CreateRexxParseData.
*
*   SYNOPSIS
*       DeleteRexxParseData(Data)
*
*       VOID DeleteRexxParseData(struct RexxParseData *);
*
*   FUNCTION
*       Before your program exits it should call this routine to release
*       all the memory allocated for command parsing. Otherwise it will lose
*       memory that can never be reclaimed.
*
*   INPUTS
*       Data - Pointer to RexxParseData structure created by
*           CreateRexxParseData. May be NULL in which case this routine
*           does nothing.
*
*   RESULT
*       None
*
*   SEE ALSO
*       dos.library/FreeDosObject
*
******************************************************************************
*
*/

VOID
DeleteRexxParseData(struct RexxParseData * Data)
{
		/* Did we get a valid data pointer? */

	if(Data != NULL)
	{
			/* Clean up the parser data. */

		if(Data->ReadArgs != NULL)
			FreeDosObject(DOS_RDARGS,Data->ReadArgs);

			/* Free the memory. */

		FreeVec(Data);
	}
}

/****** Host/ReturnRexxMsg ***************************************************
*
*   NAME
*       ReturnRexxMsg -- Return a Rexx command message to the sender,
*           including a result code.
*
*   SYNOPSIS
*       ErrorCode = ReturnRexxMsg(Message,Result)
*
*       LONG ReturnRexxMsg(struct RexxMsg *Message,const STRPTR Result);
*
*   FUNCTION
*       Clients addressing the host send special messages carrying the
*       commands and command arguments to the host message port. After
*       processing the commands the host needs to return these messages.
*
*       This routine cannot be used to return error or failure messages
*       to the client. For this purpose use ReturnErrorMsg() instead.
*
*   INPUTS
*       Message - Pointer to RexxMsg received from client.
*
*       Result - Pointer to string that should be transmitted to
*           the client as the command result. This may be NULL in
*           which case no result string will be transmitted.
*
*   RESULT
*       Error - 0 for success, any other value indicates failure.
*
*   SEE ALSO
*       exec.library/ReplyMsg
*       rexxsyslib.library/CreateArgstring
*       ReturnErrorMsg
*
******************************************************************************
*
*/

LONG
ReturnRexxMsg(struct RexxMsg * Message,const STRPTR Result)
{
	STRPTR ResultString;
	LONG ErrorCode;

		/* No error has occured yet. */

	ErrorCode = 0;

		/* Set up the RexxMsg to return no error. */

	Message->rm_Result1 = RC_OK;
	Message->rm_Result2 = 0;

		/* Check if the command should return a result. */

	if((Message->rm_Action & RXFF_RESULT) && Result != NULL)
	{
			/* To return the result string we need to make
			 * a copy for ARexx to use.
			 */

		if(ResultString = CreateArgstring(Result,strlen(Result)))
		{
				/* Put the string into the secondary
				 * result field.
				 */

			Message->rm_Result2 = (LONG)ResultString;
		}
		else
		{
				/* No memory available. */

			ErrorCode = ERR10_003;
		}
	}

		/* Reply the message, regardless of the error code. */

	ReplyMsg((struct Message *)Message);

	return(ErrorCode);
}

/****** Host/ReturnErrorMsg **************************************************
*
*   NAME
*       ReturnErrorMsg -- Return a Rexx command message to the sender and
*           indicate that the command failed.
*
*   SYNOPSIS
*       ReturnErrorMsg(Message,PortName,Error)
*
*       VOID ReturnErrorMsg(struct RexxMsg *Message,const STRPTR PortName,
*           LONG Error)
*
*   FUNCTION
*       This routine permits to return a command message sent by a client
*       and set an error code the client to send the message can query.
*       The error code is stored in a variable whose name is made up from
*       the name of the host name and the prefix ".LASTERROR". Thus,
*       for the host name "HOST" the variable becomes "HOST.LASTERROR".
*
*   INPUTS
*       Message - Pointer to RexxMsg received from client.
*
*       PortName - Name of the host the message was sent to.
*
*       Error - Error code to return.
*
*   RESULT
*       None
*
*   SEE ALSO
*       exec.library/ReplyMsg
*       amiga.lib/SetRexxVar
*
******************************************************************************
*
*/

VOID
ReturnErrorMsg(
	struct RexxMsg *	Message,
	const STRPTR		PortName,
	LONG			Error)
{
	UBYTE VarName[90];
	UBYTE Value[12];

		/* To signal an error the rc_Result1
		 * entry of the RexxMsg needs to be set to
		 * RC_ERROR. Unfortunately, we cannot convey
		 * the more meaningful error code through
		 * this interface which is why we set a
		 * Rexx variable to the error number. The
		 * Rexx script can then take a look at this
		 * variable and decide which further steps
		 * it should take.
		 */

	Message->rm_Result1 = RC_ERROR;

		/* Turn the error number into a string as
		 * ARexx only deals with strings.
		 */

	sprintf(Value,"%ld",Error);

		/* Build the name of the variable to set to
		 * the error number. We will use the name of
		 * the host name and append ".LASTERROR".
		 */

	sprintf(VarName,"%s.%s",PortName,"LASTERROR");

		/* Now set the variable to the error code.
		 * We use the RVI (Rexx Variables Interface)
		 * routine for this purpose.
		 */

	SetRexxVar(Message,VarName,Value,strlen(Value));

	ReplyMsg((struct Message *)Message);
}

/****** Host/HandleRexxMsg ***************************************************
*
*   NAME
*       HandleRexxMsg -- Process incoming rexx message and invoke the
*           apropriate function handler.
*
*   SYNOPSIS
*       HandleRexxMsg(Host,Data,Message)
*
*       VOID HandleRexxMsg(const struct RexxHost *Host,
*           struct RexxParseData *Data,struct RexxMsg *Message);
*
*   FUNCTION
*       This routine prepares the ground for the final command execution.
*       It tries to find the command the Rexx message should invoke and
*       parses the command arguments. If a matching command could be found
*       and the arguments are correct the corresponding function is invoked.
*       When control has passed through this routine the Rexx message will
*       have been replied.
*
*   INPUTS
*       Host - ARexx Host environment as created by CreateRexxHost
*
*       Data - Parser data as created by CreateParseData
*
*       Message - Pointer to RexxMsg received from client.
*
*   NOTES
*       This routine should only be called by a Process.
*
*   RESULT
*       None
*
*   SEE ALSO
*       dos.library/ReadArgs
*       CreateParseData
*       CreateRexxHost
*
******************************************************************************
*
*/

VOID
HandleRexxMsg(
	const struct RexxHost *	Host,
	struct RexxParseData *	Data,
	struct RexxMsg *	Message)
{
	struct CmdFunc * Table;
	struct CmdFunc * CmdFunc;
	STRPTR Command;
	STRPTR Arguments;
	LONG Error;
	LONG Len;
	LONG i;

		/* This is where the entire command string is stored,
		 * including following arguments.
		 */

	Command = Message->rm_Args[0];

		/* Skip leading blanks. */

	while(*Command == ' ' || *Command == '\t')
		Command++;

		/* Now determine the length of the command. */

	Len = 0;

	while(Command[Len])
	{
		if(Command[Len] == '\t' || Command[Len] == ' ')
			break;
		else
			Len++;
	}

		/* Now we need to check if the command we received
		 * can be handled by one of the routines in the
		 * command table.
		 */

	Table = Host->CommandTable;
	CmdFunc = NULL;

	for(i = 0 ; Table[i].CommandName != NULL ; i++)
	{
		if((strlen(Table[i].CommandName) == Len) && (Strnicmp(Command,Table[i].CommandName,Len) == 0))
		{
			CmdFunc = &Table[i];
			break;
		}
	}

		/* If no matching command could be found, return
		 * an error.
		 */

	if(CmdFunc == NULL)
		Error = ERROR_OBJECT_NOT_FOUND;
	else
	{
			/* Reset the argument pointers. */

		memset(Data->Args,0,sizeof(Data->Args));

			/* Separate the arguments from the command;
			 * first skip the leading blanks.
			 */

		Arguments = &Command[Len];

		while(*Arguments == '\t' || *Arguments == ' ')
			Arguments++;

			/* Remove trailing blanks. */

		Len = strlen(Arguments);

		while((Len > 0) &&
			(Arguments[Len - 1] == '\t' || Arguments[Len - 1] == ' '))
				Len--;

			/* We only allow for 510 characters of argument data. */

		if(Len > 510)
			Len = 510;

			/* Put the arguments into the parser buffer. */

		if(Len > 0)
			CopyMem(Arguments,Data->Line,Len);

			/* Add the line feed and the null-termination. */

		Data->Line[Len] = '\n';
		Data->Line[Len+1] = 0;

			/* Set up the parser to read from the argument
			 * buffer.
			 */

		Data->ReadArgs->RDA_Source.CS_Buffer = Data->Line;
		Data->ReadArgs->RDA_Source.CS_Length = Len + 1;
		Data->ReadArgs->RDA_Source.CS_CurChr = 0;
		Data->ReadArgs->RDA_Flags |= RDAF_NOPROMPT;

			/* Run the arguments through the parser. This will
			 * set up the Data->Args array.
			 */

		if(ReadArgs(CmdFunc->Template,(LONG *)Data->Args,Data->ReadArgs))
		{
				/* Invoke the command. */

			Error = (*CmdFunc->Function)(Host->UserData,Message,Data->Args);

				/* Free the parser data. */

			FreeArgs(Data->ReadArgs);
		}
		else
			Error = IoErr();
	}

		/* If an error occured, return the message now.
		 * In any other case the command handler will have
		 * taken care of it already.
		 */

	if(Error)
		ReturnErrorMsg(Message,Host->PortName,Error);
}

/****************************************************************************/

	/* The following routines implement the 15 mandatory ARexx commands
	 * every ARexx host should support, as per the "Amiga User Interface
	 * Style Guide". With the exception of the FAULT, HELP, QUIT and RX
	 * commands none of the example commands do any real work. They just
	 * print their arguments and return an error code.
	 *
	 * Every routine is invoked with three parameters:
	 *
	 * UserData -- The user data pointer passed to CreateRexxHost.
	 *
	 * Message -- Pointer to the RexxMsg received from the client.
	 *
	 * Args -- Pointer to an array of 32 string pointers, as set up
	 *         by the dos.library/ReadArgs parser.
	 *
	 * Each routine has to return an error code. If the code returned
	 * is nonzero the command dispatcher in HandleRexxMsg() will
	 * reply the RexxMsg. If the code is zero, the routine is
	 * responsible for replying the RexxMsg.
	 */

LONG
Cmd_Fault(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_NUMBER };

	UBYTE ErrorText[100];
	LONG Number;

	Number = *(LONG *)Args[ARG_NUMBER];

	Printf("FAULT %d",Number);
	Printf("\n");

		/* Obtain the AmigaDOS error text corresponding
		 * to the error code. In your own applications
		 * you would want to supply descriptive texts
		 * for each error code your program supports
		 * in addition to the standard AmigaDOS set.
		 */

	if(Fault(Number,"",ErrorText,99) > 0)
	{
		ReturnRexxMsg(Message,&ErrorText[2]);

		return(0);
	}
	else
		return(ERROR_OBJECT_NOT_FOUND);
}

LONG
Cmd_Help(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_COMMAND,ARG_PROMPT };

	struct LocalData *LocalData;
	struct CmdFunc *Table;
	STRPTR String;
	STRPTR Command;
	LONG Len;
	LONG i;

	Printf("HELP");

	if(Args[ARG_PROMPT] != NULL)
		Printf(" PROMPT");

	Printf("\n");

		/* The "PROMPT" switch should activate a graphical
		 * help system, which this implementation does not
		 * support yet.
		 */

	if(Args[ARG_PROMPT])
		return(ERROR_ACTION_NOT_KNOWN);
	else
	{
		LocalData = (struct LocalData *)UserData;

		Table = LocalData->CommandTable;

			/* If no command is specified then we should
			 * return a list of all the commands this host
			 * supports.
			 */

		if(Args[ARG_COMMAND] == NULL)
		{
				/* Count the number of bytes to allocate
				 * for a list of all commands.
				 */

			for(i = 0, Len = 1 ; Table[i].CommandName ; i++)
				Len += strlen(Table[i].CommandName) + 1;

				/* Make room for the command list. */

			String = AllocVec(Len,MEMF_ANY);

			if(String == NULL)
				return(ERROR_NO_FREE_STORE);
			else
			{
					/* Start with an empty string. */

				String[0] = 0;

					/* Add all the commands to the list. */

				for(i = 0 ; Table[i].CommandName ; i++)
				{
					strcat(String,Table[i].CommandName);
					strcat(String," ");
				}

					/* Terminate the string. */

				String[Len - 1] = 0;

					/* Reply the RexxMsg and return the
					 * command list as the command result.
					 */

				ReturnRexxMsg(Message,String);

					/* Dispose of the temporary storage. */

				FreeVec(String);

				return(0);
			}
		}
		else
		{
				/* So we should return the argument template
				 * of a specific command.
				 */

			Command = Args[ARG_COMMAND];

				/* Try to find the command in the table. */

			for(i = 0 ; Table[i].CommandName ; i++)
			{
					/* Is this the command we are
					 * looking for?
					 */

				if(Stricmp(Table[i].CommandName,Command) == 0)
				{
						/* Get the argument template. */

					String = Table[i].Template;

						/* Is the template an empty
						 * string?
						 */

					if(String[0] == '\0')
					{
						/* Provide an empty template. */

						String = ",";
					}

						/* Reply the RexxMsg and return
						 * the template as the command
						 * result.
						 */

					ReturnRexxMsg(Message,String);

					return(0);
				}
			}

				/* No matching command was found. */

			return(ERROR_OBJECT_NOT_FOUND);
		}
	}
}

LONG
Cmd_Quit(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_FORCE };

	struct LocalData *LocalData;

	Printf("QUIT");

	if(Args[ARG_FORCE] != NULL)
		Printf(" FORCE");

	Printf("\n");

	LocalData = (struct LocalData *)UserData;

		/* Flag the main message loop to exit. */

	LocalData->Terminate = TRUE;

	ReturnRexxMsg(Message,NULL);

	return(0);
}

/****** Host/DoRexxCommand ***************************************************
*
*   NAME
*       DoRexxCommand -- Send a command to the Rexx resident process.
*
*   SYNOPSIS
*       Error = DoRexxCommand(Command)
*
*       LONG DoRexxCommand(const STRPTR Command);
*
*   FUNCTION
*       A command is sent to the Rexx resident process. In this context
*       "command" either means the name of an ARexx script the resident
*       process is to load and execute or a small one-line program.
*
*   INPUTS
*       Command - Name of command to execute.
*
*   RESULT
*       Error - 0 for success, otherwise an error code.
*
*   SEE ALSO
*       rexxsyslib.library/CreateArgstring
*       rexxsyslib.library/DeleteArgstring
*       rexxsyslib.library/CreateRexxMsg
*       rexxsyslib.library/DeleteRexxMsg
*       exec.library/CreateMsgPort
*       exec.library/DeleteMsgPort
*       exec.library/FindPort
*       exec.library/PutMsg
*       exec.library/WaitPort
*
******************************************************************************
*
*/

LONG
DoRexxCommand(const STRPTR Command)
{
	struct MsgPort *ReplyPort;
	struct MsgPort *RexxPort;
	struct RexxMsg *RexxMsg;
	LONG Error;

		/* Create a temporary reply port for the RexxMsg
		 * to build.
		 */

	if(ReplyPort = CreateMsgPort())
	{
			/* Build a RexxMsg we can use. */

		if(RexxMsg = CreateRexxMsg(ReplyPort,NULL,NULL))
		{
				/* The command goes into the first
				 * message argument.
				 */

			if(RexxMsg->rm_Args[0] = CreateArgstring(Command,strlen(Command)))
			{
					/* Mark the message as a command. */

				RexxMsg->rm_Action = RXCOMM;

					/* Now try to find the resident process
					 * communications port. We need to
					 * turn off multitasking while we look
					 * for it and send the message.
					 */

				Forbid();

				if(RexxPort = FindPort(RXSDIR))
				{
					PutMsg(RexxPort,RexxMsg);

					WaitPort(ReplyPort);
					GetMsg(ReplyPort);

					Error = 0;
				}
				else
					Error = ERROR_OBJECT_NOT_FOUND;

				Permit();

				DeleteArgstring(RexxMsg->rm_Args[0]);
			}
			else
				Error = ERROR_NO_FREE_STORE;

			DeleteRexxMsg(RexxMsg);
		}
		else
			Error = ERROR_NO_FREE_STORE;

		DeleteMsgPort(ReplyPort);
	}
	else
		Error = ERROR_NO_FREE_STORE;

	return(Error);
}

	/* RxEntry(VOID):
	 *
	 *	This is the entry point of a process that will get launched
	 *	if the RX command is invoked with the "CONSOLE" parameter.
	 */

VOID __saveds
RxEntry(VOID)
{
	struct Process *ThisProcess;
	BPTR Stream;
	struct ChildMessage *ChildMessage;
	struct RexxMsg *SyncMsg;
	LONG Error;

		/* Obtain current process identifier. */

	ThisProcess = (struct Process *)FindTask(NULL);

		/* Pick up the startup message. */

	WaitPort(&ThisProcess->pr_MsgPort);
	ChildMessage = (struct ChildMessage *)GetMsg(&ThisProcess->pr_MsgPort);

		/* Remember the RexxMsg if any. If nonzero, the RX command
		 * was invoked without the ASYNC parameter and the message
		 * still need to be replied.
		 */

	SyncMsg = ChildMessage->RexxMsg;

		/* No error has occured so far. */

	Error = 0;

		/* Redirect process output to the console window. */

	if(Stream = Open("CONSOLE:",MODE_NEWFILE))
	{
		SelectOutput(Stream);

			/* Send the command to the Rexx process. */

		Error = DoRexxCommand(ChildMessage->Command);

			/* Close the output stream. */

		SelectOutput(NULL);
		Close(Stream);
	}
	else
		Error = IoErr();

		/* Do we need to reply the RexxMsg? */

	if(SyncMsg)
	{
		if(Error)
			ReturnErrorMsg(SyncMsg,ChildMessage->PortName,Error);
		else
			ReturnRexxMsg(SyncMsg,0);
	}

	ReplyMsg(ChildMessage);
}

	/* DeleteChildMessage(struct ChildMessage *ChildMessage):
	 *
	 *	Dispose of a message created by CreateChildMessage().
	 */

VOID
DeleteChildMessage(struct ChildMessage *ChildMessage)
{
	FreeMem(ChildMessage,ChildMessage->Message.mn_Length);
}

	/* CreateChildMessage():
	 *
	 *	This routine sets up a custom message to send to a
	 *	child process which gets launched if the RX command
	 *	is invoked with the CONSOLE keyword.
	 */

struct ChildMessage *
CreateChildMessage(struct MsgPort *ReplyPort,const STRPTR Command,struct RexxMsg *RexxMessage)
{
	UWORD Length;
	struct ChildMessage *ChildMessage;

		/* Make room for the message plus the command string. */

	Length = sizeof(struct ChildMessage) + strlen(Command);

	ChildMessage = (struct ChildMessage *)AllocMem(Length,MEMF_CLEAR|MEMF_PUBLIC);

	if(ChildMessage != NULL)
	{
			/* Initialize the message. */

		ChildMessage->Message.mn_Length = Length;
		ChildMessage->Message.mn_ReplyPort = ReplyPort;

		strcpy(ChildMessage->Command,Command);
	}

	return(ChildMessage);
}

LONG
Cmd_Rx(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_CONSOLE,ARG_ASYNC,ARG_COMMAND };

	struct LocalData *LocalData;
	struct ChildMessage *ChildMessage;
	BPTR Stream;
	struct Process *Child;
	struct FileHandle *Handle;
	LONG Error;

	Printf("RX");

	if(Args[ARG_CONSOLE] != NULL)
		Printf(" CONSOLE");

	if(Args[ARG_ASYNC] != NULL)
		Printf(" ASYNC");

	if(Args[ARG_COMMAND] != NULL)
		Printf(" COMMAND=\"%s\"",Args[ARG_COMMAND]);

	Printf("\n");

		/* If no command was invoked, return without
		 * doing any real work.
		 */

	if(Args[ARG_COMMAND] == NULL)
	{
		ReturnRexxMsg(Message,0);
		return(0);
	}

	LocalData = (struct LocalData *)UserData;

		/* Should we open a console output window? */

	if(Args[ARG_CONSOLE])
	{
		LocalData = (struct LocalData *)UserData;

			/* Create the process startup message. */

		ChildMessage = CreateChildMessage(LocalData->GlobalPort,Args[ARG_COMMAND],Message);

		if(ChildMessage != NULL)
		{
				/* Fill in the name of the Rexx host. */

			ChildMessage->PortName = LocalData->PortName;

				/* If the command should execute synchronously,
				 * store the RexxMsg pointer in the startup
				 * message. The background process will then
				 * return the message after executing the
				 * command.
				 */

			if(Args[ARG_ASYNC] == NULL)
				ChildMessage->RexxMsg = Message;

				/* Open the output console; you may want to substitute
				 * the title "Host" in your own programs.
				 */

			if(Stream = Open("CON:0/25/640/150/Host/AUTO/WAIT",MODE_NEWFILE))
			{
					/* Turn the BPTR to the file handle into a
					 * pointer to the file handle.
					 */

				Handle = (struct FileHandle *)BADDR(Stream);

					/* Create the background process. */

				Child = CreateNewProcTags(
					NP_Input,	Stream,
					NP_CloseInput,	FALSE,
					NP_Output,	NULL,
					NP_ConsoleTask,	Handle->fh_Type,
					NP_WindowPtr,	-1,
					NP_Entry,	RxEntry,
				TAG_DONE);

				if(Child != NULL)
				{
						/* Send the startup message. */

					PutMsg(&Child->pr_MsgPort,ChildMessage);

						/* Increment the number of outstanding
						 * startup messages.
						 */

					LocalData->Usage++;

						/* If the command was to be executed
						 * asynchronously, return the message
						 * now so the calling program can
						 * continue running while the process
						 * is dealing with the command.
						 */

					if(Args[ARG_ASYNC] != NULL)
						ReturnRexxMsg(Message,0);

					return(0);
				}
				else
					Error = IoErr();

				Close(Stream);
			}
			else
				Error = IoErr();

			DeleteChildMessage(ChildMessage);
		}
		else
			Error = IoErr();
	}
	else
	{
			/* If the command should execute asynchronously,
			 * reply the RexxMsg now.
			 */

		if(Args[ARG_ASYNC] != NULL)
			ReturnRexxMsg(Message,0);

			/* Execute the command. */

		Error = DoRexxCommand(Args[ARG_COMMAND]);

			/* If the RexxMsg was already replied,
			 * return now.
			 */

		if(Args[ARG_ASYNC] != NULL)
			return(0);

			/* If no error occured, return the RexxMsg. */

		if(Error == 0)
		{
			ReturnRexxMsg(Message,0);
			return(0);
		}
	}

	return(Error);
}


LONG
Cmd_New(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_PORTNAME };

	Printf("NEW");

	if(Args[ARG_PORTNAME] != NULL)
		Printf(" PORTNAME=\"%s\"",Args[ARG_PORTNAME]);

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Clear(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_FORCE };

	Printf("CLEAR");

	if(Args[ARG_FORCE] != NULL)
		Printf(" FORCE");

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Open(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_FILENAME,ARG_FORCE };

	Printf("OPEN");

	if(Args[ARG_FILENAME] != NULL)
		Printf(" FILENAME=\"%s\"",Args[ARG_FILENAME]);

	if(Args[ARG_FORCE] != NULL)
		Printf(" FORCE");

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Save(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	Printf("SAVE");
	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_SaveAs(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_NAME };

	Printf("SAVEAS");

	if(Args[ARG_NAME] != NULL)
		Printf(" NAME=\"%s\"",Args[ARG_NAME]);

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Close(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_FORCE };

	Printf("CLOSE");

	if(Args[ARG_FORCE] != NULL)
		Printf(" FORCE");

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Print(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_PROMPT };

	Printf("PRINT");

	if(Args[ARG_PROMPT] != NULL)
		Printf(" PROMPT");

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Cut(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	Printf("CUT");
	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Copy(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	Printf("COPY");
	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

LONG
Cmd_Paste(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	Printf("PASTE");
	Printf("\n");

	return(0);
}

LONG
Cmd_Erase(APTR UserData,struct RexxMsg *Message,STRPTR *Args)
{
	enum	{ ARG_FORCE };

	Printf("ERASE");

	if(Args[ARG_FORCE] != NULL)
		Printf(" FORCE");

	Printf("\n");

	return(ERROR_ACTION_NOT_KNOWN);
}

/****************************************************************************/

	/* This is the table which lists the single commands this ARexx
	 * host implements. Each entry lists the name of the command to
	 * invoke, the argument template and the pointer to the routine
	 * which implements the command. The table is terminated by a
	 * NULL command name.
	 */

struct CmdFunc CommandTable[] =
{
	"NEW",		"PORTNAME/K",				Cmd_New,
	"CLEAR",	"FORCE/S",				Cmd_Clear,
	"OPEN",		"FILENAME/K,FORCE/S",			Cmd_Open,
	"SAVE",		"",					Cmd_Save,
	"SAVEAS",	"NAME/K",				Cmd_SaveAs,
	"CLOSE",	"FORCE/S",				Cmd_Close,
	"PRINT",	"PROMPT/S",				Cmd_Print,
	"QUIT",		"FORCE/S",				Cmd_Quit,
	"CUT",		"",					Cmd_Cut,
	"COPY",		"",					Cmd_Copy,
	"PASTE",	"",					Cmd_Paste,
	"ERASE",	"FORCE/S",				Cmd_Erase,
	"HELP",		"COMMAND,PROMPT/S",			Cmd_Help,
	"FAULT",	"NUMBER/A/N",				Cmd_Fault,
	"RX",		"CONSOLE/S,ASYNC/S,COMMAND/F",		Cmd_Rx,

	NULL,		NULL,					NULL
};

int
main(int argc,char **argv)
{
	struct RexxParseData * ParseData;
	struct RexxHost * Host;
	struct LocalData LocalData;
	struct RexxMsg * RexxMessage;
	ULONG Signals;

		/* This program requires AmigaOS v2.04 or higher to run. */

	if(SysBase->lib_Version < 37)
	{
		printf("This program requires AmigaOS v2.04 or higher to run.\n");

		return(RETURN_FAIL);
	}

		/* Open the rexx system library. */

	RexxSysBase = OpenLibrary(RXSNAME,0);

	if(RexxSysBase == NULL)
	{
		Printf("Could not open %s.\n",RXSNAME);

		return(RETURN_FAIL);
	}

		/* Open the utility library. */

	UtilityBase = OpenLibrary("utility.library",37);

	if(UtilityBase == NULL)
	{
		Printf("Could not open utility.library v37.\n");

		CloseLibrary(RexxSysBase);

		return(RETURN_FAIL);
	}

		/* Create the command parser data. */

	ParseData = CreateRexxParseData();

	if(ParseData == NULL)
	{
		Printf("Error creating rexx parse data.\n");

		CloseLibrary(RexxSysBase);
		CloseLibrary(UtilityBase);

		return(RETURN_FAIL);
	}

		/* Finally create the Rexx host. */

	Host = CreateRexxHost("HOSTDEMO",0,CommandTable,&LocalData);

	if(Host == NULL)
	{
		Printf("Error creating rexx host.\n");

		DeleteRexxParseData(ParseData);

		CloseLibrary(RexxSysBase);
		CloseLibrary(UtilityBase);

		return(RETURN_FAIL);
	}

		/* Set up the local data. This must be done
		 * before the first Rexx command is processed.
		 */

	LocalData.CommandTable	= CommandTable;
	LocalData.Usage		= 0;
	LocalData.GlobalPort	= Host->GlobalPort;
	LocalData.PortName	= Host->PortName;
	LocalData.Terminate	= FALSE;

	Printf("Host name is \"%s\", waiting for commands.\n",Host->PortName);

		/* Loop until either the QUIT command is executed or
		 * Ctrl-C is pressed.
		 */

	do
	{
			/* Wait for Ctrl-C or an incoming Message. */

		Signals = Wait(SIGBREAKF_CTRL_C | (1L << Host->GlobalPort->mp_SigBit));

			/* Ctrl-C signal received? */

		if(Signals & SIGBREAKF_CTRL_C)
			LocalData.Terminate = TRUE;

			/* Message received? */

		if(Signals & (1L << Host->GlobalPort->mp_SigBit))
		{
				/* Process all incoming messages. */

			while((RexxMessage = (struct RexxMsg *)GetMsg(Host->GlobalPort)) != NULL)
			{
					/* If the incoming message is indeed
					 * a RexxMsg, process the command
					 */

				if(IsRexxMsg(RexxMessage))
					HandleRexxMsg(Host,ParseData,RexxMessage);
				else
				{
						/* Otherwise it is a startup message
						 * sent to a background process. We
						 * need to delete this message and
						 * decrement the number of outstanding
						 * startup messages.
						 */

					DeleteChildMessage((struct ChildMessage *)RexxMessage);

					LocalData.Usage--;
				}
			}
		}

		/* The loop will be terminated when the "Terminate" flag changes
		 * to TRUE and no further startup messages are outstanding.
		 */
	}
	while(LocalData.Usage > 0 || LocalData.Terminate == FALSE);

		/* That's all, folks... */

	Printf("Cleaning up.\n");

	DeleteRexxHost(Host);
	DeleteRexxParseData(ParseData);

	CloseLibrary(RexxSysBase);
	CloseLibrary(UtilityBase);

	return(RETURN_OK);
}
