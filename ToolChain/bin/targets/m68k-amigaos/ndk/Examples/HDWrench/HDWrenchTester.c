/*	tester.c	test hdwrench.library for some basic functions.
 */
char ver[] = "$VER: HDWrenchTester.c 44.8 (25.11.2000) © Wizardess Designs and Joanne Dow 1999-2000 All rights reserved";
/*
 *		© Copyright 1999-2000 by Joanne Dow, Wizardess Designs
 *		All Rights Reserved
 *
 *	Tester.c can be taken both as a test program and as an example of usage,
 *	in spite of its cut and paste, overblown and ugly coding style, of usage
 *	for each of the "hdwrench.library" API entry points.
 *
 *	Functions:
 *		Support:
 *		1) Open device and close device
 *			BU baseunit.
 *		Translations:
 *
 *		2) Read RDB from <file>.list and write as mountfile to <file>..list.
 *		3) Read RDB from <file>.list and write as RDBs to <file>..rdb.
 *		4) Read RDB from <file>.rdb and write as mountfile to <file>..list.
 *		5) Read RDB from <file>.rdb and write as RDBs to <file>..rdb.
 *		6) Read Mountfile from memory and write as Mountfile to memory.
 *			(uses 000.list for input and writes to "foo" and screen.)
 *		7) Read Mountfile from memory and write as RDB Structs to memory.
 *			(uses 000.list for input and writes to "foo".)
 *		8)  Read RDBStructs memory and write as RDB Structs to memory.
 *			(uses 000..rdb for input and writes to "bar".)
 *
 *		Basic Disk acccesses:
 *		9) Read RDB from disk and write as mountfile to <file>...list.
 *		10) Perform SCSI Inquiry and report results up to 40 bytes.
 *		11) Perform SCSI ModeSense  and report results up to 255 bytes.
 *		12) Perform SCSI Read Capacity and report disk size.
 *		13) Perform SCSI Test Unit Ready and report device readiness.
 *
 *		Complex Disk Accesses...
 *		14) Find Disk Name returning in string variable.
 *		15) Find Controller self-ID returning in ULONG (which Commododo fails!).
 *		16) Report last available block on the drive.
 *		17) Generate default drive parameters.
 *		18) Read and report raw sector 'MS'.	(Not really complex but...)
 *		19) Find all valid disks on a given controller
 *
 *		Dangerous disk accesses:
 *		20) Raw write to a block of low disk. (Safe write - I hope!)
 *		21) Write with checksum to a block of low disk. (Safe write - I hope!)
 *		22) Read RDBs from <file.list> and write to disk. (The biggie!)
 *		23) Read RDBs from disk and write to RDBStructs to <file>.rdb.
 *		24) Read RDBStructs from <file>.rdb and write to <file>...rdb.
 *		25) Verify data on disk.
 *		26) Read RDBStructs from <file>...rdb and write to Disk.
 *		27) Read RDBs from disk and write RDB Structs memory thence to file
 *			 and console as hex.
 *		100) Format Drive - VERY DANGEROUS!
 *
 *		Presumes "scsi.device" else enter "DEVICE devicename".
 */
#include	<stdio.h>
#include	<stdarg.h>
#include	<string.h>
#include	<ctype.h>
#include	<stdlib.h>
#include	<math.h>
#include	<dos.h>
#include	<exec/types.h>
#include	<exec/ports.h>
#include	<exec/libraries.h>
#include	<exec/io.h>
#include	<exec/nodes.h>
#include	<exec/lists.h>
#include	<exec/tasks.h>
#include	<exec/memory.h>
#include	<exec/execbase.h>
#include	<devices/trackdisk.h>
#include	<libraries/dos.h>
#include	<libraries/dosextens.h>
#include	<dos/filehandler.h>
#include	<devices/hardblocks.h>
#include	<devices/scsidisk.h>
#include	<intuition/intuition.h>
#include	<workbench/workbench.h>
#include	<workbench/icon.h>
#include	<workbench/startup.h>
#include	<dos/rdargs.h>
#include	<dos/dostags.h>

#include	<proto/dos.h>
#include	<proto/exec.h>
#include	<pragmas/exec_pragmas.h>
#include	<pragmas/disk_pragmas.h>
#include	<pragmas/dos_pragmas.h>

#include	"libraries/HDWrench.h"
#include	"pragmas/HDWrench_pragmas.h"
#define		USE_SUGGESTED_MESSAGES
#include	"libraries/HDW_CallbackMsgs.h"

struct HDWLibrary	*HDWBase = NULL;

#define TEMPLATE "TEST/N/A,BU/N/K,FILE/K,MS/N/K,DEVICE/K"
#define NUM_ARGS 5

char hexits [] = "0123456789abcdef";
char spaces [] = "                                                ";

enum { ARG_TEST, ARG_BU, ARG_FILE, ARG_MS, ARG_DEVICE };

LONG			 ArgArray [ NUM_ARGS ];

char			*inmembuffer	= NULL;
char			*outmembuffer	= NULL;
BOOL			 deviceopen		= FALSE;
struct RDArgs	*Args 			= NULL;
BOOL			 aborted		= FALSE;
ULONG			 testnum;

long __stdargs __saveds __asm CallBack ( register __a0 HDWCallbackMsg *msg );

void usage ( void )
{
	printf ( "tester %s\n", TEMPLATE );
	printf ( "Gotta have a test number!\n" );
	printf ( "1)  Basic Open and Close Device\n" );
	printf ( "2)  Read RDB from <file>.list and write as mountfile to <file>..list.\n");
	printf ( "3)  Read RDB from <file>.list and write as RDBs to <file>..rdb.\n" );
	printf ( "4)  Read RDBs from <file>..rdb and write Mountfile to <file>...list.\n" );
	printf ( "5)  Read Mountfile from disk and write as mountfile to memory.\n");
	printf ( "6)  Read Mountfile from memory and write as Mountfile to memory.\n");
	printf ( "7)  Read Mountfile from memory and write as RDB Structs to memory.\n");
	printf ( "8)  Read RDBStructs memory and write as RDB Structs to memory.\n");
	printf ( "9)  Read RDB from disk and write as mountfile to <file>...list.\n");
	printf ( "10) Perform SCSI Inquiry and report results up to 40 (56) bytes.\n");
	printf ( "11) Perform SCSI ModeSense  and report results up to 256 bytes.\n");
	printf ( "12) Perform SCSI Read Capacity and report disk size.\n");
	printf ( "13) Perform SCSI Test Unit Ready and report device readiness.\n");
	printf ( "14) Find Disk Name returning in string variable.\n" );
	printf ( "15) Find Controller self-ID returning in ULONG (which Commododo fails!).\n" );
	printf ( "16) Report last available block on the drive.\n");
	printf ( "17) Generate default drive parameters.\n" );
	printf ( "18) Read and report raw sector 'MS'.\n");
	printf ( "19) Find all valid disks on a given controller.\n");
	printf ( "20) Raw write to a block of low disk. (Safe write - I hope!)\n");
	printf ( "21) Write with checksum to a block of low disk. (Safe write - I hope!)\n");
	printf ( "22) Read RDBs from <file.list> and write to disk. (The biggie!)\n" );
	printf ( "23) Read RDBs from disk and write to file <file>.rdb\n");
	printf ( "24) Read RDBStructs from <file>.rdb and write to <file>...rdb.\n");
	printf ( "25) Verify data on disk.\n" );
	printf ( "26) Read RDBStructs from <file>...rdb and write to Disk.\n");
	printf ( "27) Read RDBs from disk. Write RDB Structs to memory thence to file and console as hex.\n\n" );
	printf ( "100) Format Drive - VERY DANGEROUS!\n" );
}

int btrap ( void )
{
	printf ( "\n***BREAK***\n" );
	if (( testnum != 25 ) && ( testnum != 100 ))
		exit(20);
	aborted = TRUE;
	return 0;
}

void gone ( void )
{
	if ( deviceopen )
	{
		printf ( "Closing opened device\n" );
		HDWCloseDevice();
		deviceopen = FALSE;
	}

	if ( outmembuffer )
	{
		free ( outmembuffer );
		outmembuffer = NULL;
	}

	if ( inmembuffer )
	{
		free ( inmembuffer );
		inmembuffer = NULL;
	}

	if ( Args )
		FreeArgs ( Args );

	if ( HDWBase )
		CloseLibrary ( ( struct Library *) HDWBase );
	HDWBase = NULL;

	printf ("Aw gone!\n");
}

void printhex ( BYTE * buf, int size )
{
	int i;
	int j;
	char c;

	for ( i=0, j = 0; i < size; i++)
	{
		if (( i & 0x0f ) == 0 )
			printf ( "%c%c%c%c: ",
					 hexits [( i >> 12 ) & 0xf ],
					 hexits [( i >> 8  ) & 0xf ],
					 hexits [( i >> 4  ) & 0xf ],
					 hexits [  i         & 0xf ] );
		c = buf [ i ];
		printf ( "%c%c ", hexits [( c>>4 ) & 0xf], hexits [ c & 0xf ]);
		if ( ( i & 0x3 )  == 3 )
		{
			if ( ( i & 0xf ) == 15 )
			{
				for ( ; j <= i; j++ )
				{
					c = buf [ j ];
					if ( isalnum ( c ) || c == ' ' )
						printf ( "%c", c );
					else
						printf ( "." );

//					if ( ( j & 0x7 )  == 7 )
//						printf ( " " );
				}
				printf ( "\n" );
			}
			else
				printf ( " " );
		}
	}
	if ( j != i )
	{
		int k = (( i - 1 ) & 0xf ) + 1;

		k = k * 3 + ( k > 8 );
		printf ( "%s", &spaces [ k ] );

		for ( ; j < i; j++ )
		{
			c = buf [ j ];
			if ( isalnum ( c ) )
				printf ( "%c ", c );
			else
				printf ( ". " );

//			if ( ( j & 0x7 )  == 7 )
//				printf ( "  " );
		}
		printf ( "\n" );
	}
}

int
main ( int argc, char **argv)
{
	char			 *filename;
	char			  devicename[60];
	FILE			 *workfile;
	ULONG			  baseunit;
	ULONG			  mspage;
	ULONG			  sizeb;
	ULONG			  sizememneeded;

	char			  realfilename[256];
	ULONG			  rsuccess;
	USHORT			  rwsuccess;

	ArgArray [ 0 ] =
	ArgArray [ 1 ] =
	ArgArray [ 2 ] =
	ArgArray [ 3 ] =
	ArgArray [ 4 ] = 0;

	printf( "%s,\nthe HDWrench test program.\n", ver );

	atexit( gone );
	if ( onbreak ( &btrap ))
	{
		printf ( "Break trap not installed!" );
		exit ( 20 );
	}

	Args = ReadArgs( TEMPLATE, ArgArray, NULL );
	if ( Args )
	{
		//	ARG_TEST, ARG_BU, ARG_FILE, ARG_MS, ARG_DEVICE
		testnum		= (ULONG)	ArgArray [ ARG_TEST ];
		baseunit	= (ULONG)	ArgArray [ ARG_BU ];
		filename	= (char *)	ArgArray [ ARG_FILE ];
		mspage		= (ULONG)	ArgArray [ ARG_MS ];
		memset ( devicename, 0, 60 );
		if ( ArgArray [ ARG_DEVICE ] != NULL )
			strncpy ( devicename, (char *)	ArgArray [ ARG_DEVICE ], 59 );
		else
			strncpy ( devicename, "scsi.device", 59 );

		if ( testnum )
			testnum = *(ULONG*) testnum;
		else
			testnum = 0;

		if ( baseunit)
			baseunit = *(ULONG*) baseunit;
		else
			baseunit = (ULONG) -1L;

		if ( mspage )
			mspage = *(ULONG*) mspage;

		printf ( "Test Num	= %ld\n", testnum );
		printf ( "Base Unit	= %ld\n", baseunit );
		if ( filename )
			printf ( "Filename	= %s\n", filename );
		else
			printf ( "Filename	= <none>\n" );
		printf ( "MS Page		= %ld\n", mspage);
		printf ( "Devicename	= %s\n\n\n", devicename);

		if (( HDWBase = ( struct HDWLibrary *) OpenLibrary ( HDWBaseName, 0)) == NULL )
		{
			printf( "Failed to open HDWBase!\n");
			exit ( 10 );
		}

		switch ( testnum )
		{
		case 0:		/* No test! */
		default:
			usage();
			break;

/******************************************
 *
 *	1
 *		BASIC OPENDEVICE/CLOSEDEVICE TEST
 *
 *****************************************/
		case 1:	// Basic Open and Close Device
			printf ( "1) Basic Open and Close Device\n\n" );
//	BOOL __saveds __asm		 HDWOpenDevice ( register __a0 char *DevName,
//											 register __d0 ULONG unit );
//	void __saveds __asm		 HDWCloseDevice ( void );
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "You must enter a BU, Base Unit, number\n");
				break;
			}
			// Open device here.
			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			else
				printf ( "No device was opened!\n");
			break;

/******************************************
 *
 *	2-4
 *		BASIC READ/WRITE FILE TESTS
 *
 *****************************************/
		case 2:	// Read RDB from <file>.list and write as mountfile to <file>..list.
//	ULONG __saveds __asm
//	ReadMountfile ( register __d0 ULONG unit,
//					register __a0 char * filename,
//					register __a1 char *controller )
/* HDW_ReadMountfile()
 *	Description:
 *		Parse a mounfile into internal RDB structures.
 *
 *	Direct Inputs:
 *		filename		Pointer to mountfile in memory null terminated
 *		unit			Unit number to masquarade as.
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		RDB structures built in memory
 *
 *	Local Calls:
 *		parse ()
 *
 *	OS Calls:
 *		fclose ()
 *		fopen ()
 *
 *	Algorithm:
 *		If RDBs open then fail
 *		If file open close it.
 *		NULL memp
 *		if filename null then fail
 *		if Open filename fails then fail
 *		parse data as it comes until null character.
 *		return errors encountered in parse
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
/* HDW_WriteMountfile()
 *	Description:
 *		Write to filename given from internal RDB structures in mountfile
 *		format. Check for matching files if filename entry is present in
 *		RDB structures and write appropriate FS and DriveInit code files.
 *
 *	Direct Inputs:
 *		filename	pointer to the name of the file to be written.
 *		flags		Flag what should be written to files.
 *		ldir		L: directory path to use or NULL. (Use "L:" if null.)
 *
 *	Indirect Inputs:
 *		Mountfile and any filesystem files or device init files written.
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		Internal file structures written to disk in mountfile format.
 *
 *	Local Calls:
 *		print ()
 *
 *	OS Calls:
 *		fclose ()
 *		fopen ()
 *
 *	Algorithm:
 *		If no RDBs stored or file open fails exit with error
 *		print () mountfile to file.
 *		return accumulated error
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//	ULONG __saveds __asm
//	WriteMountfile ( register __a0 char *filename,
//					 register __a1 char *ldir,
//					 register __d0 ULONG unit )
			printf ( "2) Read RDB from <file>.list and write as mountfile to <file>..list.\n\n");
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			rsuccess = ReadMountfile ( baseunit, realfilename, devicename );
			if ( rsuccess == 0 )
			{
				sprintf ( realfilename, "%s%s", filename, "..list" );
				rsuccess = WriteMountfile ( realfilename, "sys:", baseunit );
				if ( rsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "Mountfile write failed: %d\n", rsuccess );
			}
			else
			{
					printf ( "Mountfile read failed: %d\n", rsuccess );
					break;
			}
			break;

		case 3:
//	ULONG __saveds __asm
//	ReadMountfile ( register __d0 ULONG unit,
//					register __a0 char * filename,
//					register __a1 char *controller )
/* HDW_WriteRDBStructs()
 *	Description:
 *		(Write RDBs to file instead of RDB area of disk.)
 *		Write the internal RDB structures to disk exactly as in memory.
 *
 *	Direct Inputs:
 *		Filename		Name of file to write. NB: This will clobber duplicates
 *
 *	Indirect Inputs:
 *		RDB structures in memory
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		File written
 *
 *	Local Calls:
 *
 *	OS Calls:
 *		fclose ()
 *		fopen ()
 *		fwrite ()
 *
 *	Algorithm:
 *		if no RDBs in memory of file open fails exit with error
 *		else
 *			pointer = Basepointer->next
 *			while pointer
 *				translate and write block to disk file
 *				pointer = pointer->next
 *			endwhile
 *		endif
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//	ULONG __saveds __asm
//	WriteRDBStructs ( register __a0 char *filename )
			printf ( "3)  Read RDB from <file>.list and write as RDBs to <file>..rdb.\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			rsuccess = ReadMountfile ( baseunit, realfilename, devicename );
			if ( rsuccess == 0 )
			{
				sprintf ( realfilename, "%s%s", filename, "..rdb" );

				rsuccess = WriteRDBStructs ( realfilename );
				if ( rsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "RDBfile write failed: %d\n", rsuccess );
			}
			else
			{
					printf ( "Mountfile read failed: %d\n", rsuccess );
					break;
			}
			break;

		case 4:
/* HDW_ReadRDBStructs()
 *	Description
 *		(Read RDBs from file instead of RDB area of disk.)
 *		Read the dumped RDB file structures from the file into internal
 *		memory. (NB: Only actual declared RDB areas are included in the
 *		structures as written.)
 *		NB: The RDB structures read MUST have their relative block numbers
 *		written correctly.  They are used when writing to disk, even if
 *		changed in writing.
 *
 *	Direct Inputs:
 *		filename	pointer to the name of the file to be written. This
 *					file will be unconditionally overwritten if present.
 *
 *	Indirect Inputs:
 *		Internal RDB structures as loaded.
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		Internal RDB structures written to the filename indicated.
 *
 *	Local Calls:
 *		ClearBlockList ()
 *		ScanList ()
 *
 *	OS Calls:
 *		fclose ()
 *		fopen ()
 *		fread ()
 *
 *	Algorithm:
 *		If RDBs in memory or file open fails return error code
 *		else
 *			while ( not end of file )
 *				allocate block
 *				block read the block from disk file
 *				switch type
 *				  case RDSK		Add to front of list
 *				  case PART		Add after RDSK entry and other PART entries
 *								if any else front of list
 *				  case BADB		Add just after RDSK if any.
 *				  case FSHD		Add after last PART entries if any
 *				  case LSEG		Add to end of list in order encountered
 *				  otherwise		Ignore!!!!
 *				endswitch
 *			endwhile
 *		endif
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm
//HDW_ReadRDBStructs ( register __a0 char *filename, register __d0 unit )
			printf ( "4)  Read RDBs from <file>..rdb and write Mountfile to <file>...list.\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, "..rdb" );
			rsuccess = ReadRDBStructs ( realfilename, baseunit );
			if ( rsuccess == 0 )
			{
				sprintf ( realfilename, "%s%s", filename, "...list" );

				rsuccess = WriteMountfile ( realfilename, "sys:", baseunit );
				if ( rsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "MountFile write failed: %d\n", rsuccess );
			}
			else
			{
					printf ( "RDB file read failed: %d\n", rsuccess );
					break;
			}
			break;


/******************************************
 *
 *	5-8
 *		BASIC INMEMORY READ/WRITE TESTS
 *
 *****************************************/
		case 5:
/*
 * HDW_OutMemMountfile()
 *	Description:
 *		Write RDBs into a block of memory as null terminated mountfile text.
 *		If block supplied is too small fail. If memp = NULL return size needed
 *		but no written data.
 *
 *	Direct Inputs:
 *		memp		Pointer to block of memory
 *		sizeb		size of block of memory
 *		sizew		Pointer to size written
 *
 *	Indirect Inputs:
 *		RDB structures in memory
 *
 *	Direct Outputs:
 *		ret			error code
 *		sizew		size written
 *
 *	Indirect Outputs:
 *		Block of memory written
 *
 *	Local Calls:
 *		print ()
 *
 *	OS Calls:
 *		fclose ()
 *
 *	Algorithm:
 *		if file open then close it.
 *		if memory open then null it.
 *		if RDBs not open then fail
 *		set memp to input vector (NULL is legitimate for returning size)
 *		Set maximum sze value per passed in value or "huge" of memp == NULL
 *		Call print() to generate the RDBs into the memory block
 *		set size written value
 *		return accumulated errors.
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm
//HDW_OutMemMountfile ( register __a0 char *mfp,
//					  register __a1 ULONG *sizew,
//					  register __d0 ULONG sizeb,		// Size of buffer
//					  register __d1 ULONG unit )
			printf ( "5) Read Mountfile from disk and write as mountfile to memory.\n\n");
			/* More specifically read Mountfile from disk and write as mountfile to
			 * printing results to stdout.
			 */
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			rsuccess = ReadMountfile ( baseunit, realfilename, devicename );
			if ( rsuccess == 0 )
			{
				rsuccess = OutMemMountfile ( NULL, &sizememneeded, 0, baseunit );

				if ( rsuccess == 0 )
				{
					printf ( "5) Need %ld bytes of buffer for mountfile.\n", sizememneeded );
					outmembuffer = malloc ( sizememneeded + 256 );
					if ( outmembuffer )
					{
						rsuccess = OutMemMountfile ( outmembuffer, &sizememneeded, sizememneeded + 255, baseunit );
						if ( rsuccess == 0 )
						{
							FILE *foofile = NULL;

							outmembuffer [ sizememneeded + 255 ] = 0;
							printf ( "Actual use = %d\n", strlen( outmembuffer ));
							printf ( outmembuffer );

							foofile = fopen ( "foo", "wb" );
							if ( foofile )
							{
								fwrite ( outmembuffer, sizememneeded, 1, foofile );
								fclose ( foofile );
								foofile = NULL;
							}
						}
						else
						{
							printf ( "Could not write the file: %d\n", rsuccess );
						}
					}
				}
				else
					printf ( "Mountfile size write failed: %d\n", rsuccess );
			}
			else
			{
					printf ( "Mountfile read failed: %d\n", rsuccess );
					break;
			}
			break;

		case 6:
/* HDW_InMemMountfile()
 *	Description:
 *		Parse a block of memory as if it were a disk file feeding through
 *		HDW_ReadMountfile().
 *
 *	Direct Inputs:
 *      unit        unit number of device for which this is intended
 *		mfdata		Pointer to mountfile in memory null terminated
 *		controller  Pointer to "controller ID" information
 *
 *	Indirect Inputs:
 *		BootBlocks	rdb list
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		RDB structures built in memory
 *
 *	Local Calls:
 *		parse ()
 *
 *	OS Calls:
 *		fclose ()
 *
 *	Algorithm:
 *		If file open close it.
 *		NULL memp.
 *		if data pointer is real use it.
 *		If RDBs not already open
 *			parse data as it comes until null character.
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm
//HDW_InMemMountfile ( register __d0 ULONG unit,
//					 register __a0 char *mfdata,
//					 register __a1 char *controller )
			printf ( "6) Read Mountfile from memory and write as Mountfile to memory.\n\n");
			/* More specifically read Mountfile from disk and write as mountfile to
			 * printing results to stdout.
			 */
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			workfile = fopen ( realfilename, "rb" );
			if ( !workfile )
			{
				printf ( "Failed to open %s\n", realfilename );
				goto cleanup;
			}
			fseek ( workfile, 0, SEEK_END );
			sizeb = ftell ( workfile );
			fseek ( workfile, 0, 0 );
			inmembuffer = malloc ( sizeb + 1 );
			printf ( "Read %d blocks of %d bytes\n", fread ( inmembuffer, sizeb, 1, workfile ), sizeb);
			fclose ( workfile );
			inmembuffer [ sizeb ] = 0;
			printf ( inmembuffer );	// For reference

			rsuccess = InMemMountfile ( baseunit, inmembuffer, devicename );
			if ( rsuccess == 0 )
			{
				rsuccess = OutMemMountfile ( NULL, &sizememneeded, 0, baseunit );

				if ( rsuccess == 0 )
				{
					printf ( "6) Need %ld bytes of buffer for mountfile.\n", sizememneeded );
					outmembuffer = malloc ( sizememneeded + 256 );
					if ( outmembuffer )
					{
						rsuccess = OutMemMountfile ( outmembuffer, &sizememneeded, sizememneeded + 255, baseunit );
						if ( rsuccess == 0 )
						{
							FILE *foofile = NULL;

							outmembuffer [ sizememneeded + 255 ] = 0;
							printf ( "Actual use = %d\n", strlen( outmembuffer ));
							printf ( outmembuffer );

							foofile = fopen ( "foo", "wb" );
							if ( foofile )
							{
								fwrite ( outmembuffer, sizememneeded, 1, foofile );
								fclose ( foofile );
								foofile = NULL;
							}
						}
						else
						{
							printf ( "Could not write the file: %d\n", rsuccess );
						}
					}
				}
				else
					printf ( "Mountfile size write failed: %d\n", rsuccess );
			}
			else
				printf ( "InMemMountfile failed, %ld\n", rsuccess );

			break;

		case 7:
/* HDW_OutMemRDBStructs()
 *	Description:
 *		(Write RDBs to memory area instead of RDB area of disk.)
 *		Write RDB structs into external memory if large enough as if
 *		writing to disk. If size = 4L return number of bytes required in
 *		*memp.
 *
 *	Direct Inputs:
 *		memp		Pointer to block of memory to be written
 *		sizeb		Size of each block to be written
 *		sizew		pointer to returned number of BLOCKS written
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *		sizew		zeroed then incremented by one for each block written
 *
 *	Indirect Outputs:
 *		RDBs written to memory as if to disk
 *
 *	Local Calls:
 *		none
 *
 *	OS Calls:
 *		fclose ()
 *		memcpy ()
 *
 *	Algorithm:
 *		if file open then close it.
 *		NULL memp.
 *		if RDBs not loaded then fail
 *		Figure out block size from existing RDB structures.
 *		Walk the list to determine total size needed using "sizew" variable.
 *		if rdbp entered is NULL then
 *			do not write anything and return size calculated.
 *		Walk the list again writing RDBs to memory using memcpy.
 *		return 0;
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm
//HDW_OutMemRDBStructs ( register __a0 char *rdbp,
//					   register __a1 LONG *sizew,		// Size written
//					   register __d0 LONG sizeb )		// Size of buffer
			printf ( "7) Read Mountfile from memory and write as RDB Structs to memory.\n\n");
			/* More specifically read Mountfile from disk and write from memory
			 * to "foo" as one block of RDB Structs.
			 */
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			workfile = fopen ( realfilename, "rb" );
			if ( !workfile )
			{
				printf ( "Failed to open %s\n", realfilename );
				goto cleanup;
			}
			fseek ( workfile, 0, SEEK_END );
			sizeb = ftell ( workfile );
			fseek ( workfile, 0, 0 );
			inmembuffer = malloc ( sizeb + 1 );
			printf ( "Read %d blocks of %d bytes\n", fread ( inmembuffer, sizeb, 1, workfile ), sizeb);
			fclose ( workfile );
			inmembuffer [ sizeb ] = 0;

			rsuccess = InMemMountfile ( baseunit, inmembuffer, devicename );
			if ( rsuccess == 0 )
			{
				sizememneeded = 0;
				rsuccess = OutMemRDBStructs ( NULL, &sizememneeded, 0 );

				if ( rsuccess == 0 )
				{
					printf ( "7) Need %ld bytes of buffer for mountfile.\n", sizememneeded );
					outmembuffer = malloc ( sizememneeded + 256 );
					if ( outmembuffer )
					{
//						int i;
//						for ( i = sizememneeded; i < sizememneeded + 256; i++)
//							outmembuffer[i] = 'A';
						rsuccess = OutMemRDBStructs ( outmembuffer, &sizememneeded, sizememneeded + 255 );
						if ( rsuccess == 0 )
						{
							FILE *foofile = NULL;

							outmembuffer [ sizememneeded + 255 ] = 0;
							printhex ( &outmembuffer[sizememneeded-16], 256 );

							foofile = fopen ( "foo", "wb" );
							if ( foofile )
							{
								fwrite ( outmembuffer, sizememneeded, 1, foofile );
								fclose ( foofile );
								foofile = NULL;
							}
						}
						else
						{
							printf ( "Could not write the file: %d\n", rsuccess );
						}
					}
				}
				else
					printf ( "Mountfile size write failed: %d\n", rsuccess );
			}
			else
				printf ( "InMemMountfile failed, %ld\n", rsuccess );

			break;

		case 8:
/* HDW_InMemRDBStructs()
 *	Description:
 *		(Read RDBs from memory instead of RDB area of disk.)
 *		Read the dumped RDB structure format into internal memory as if from
 *		disk from an external memory block.
 *
 *	Direct Inputs:
 *		rdbp		Pointer to RDBs in memory
 *		sizeb		Block size
 *		startb		start block number
 *		endp		end memory pointer
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		BootBlock list filled
 *
 *	Local Calls:
 *		none
 *
 *	OS Calls:
 *		fclose ()
 *		memcpy ()
 *
 *	Algorithm:
 *		if RDBs already open then fail
 *		if file open then close it
 *		If memory pointer open then close it.
 *		if pointer not valid then fail
 *		set memory base to memory pointer
 *		Set memory end pointer to memory pointer plus input size.
 *		If fails simple consitency checks then fail
 *		// Note - RDSK block *MUST* be first
 *		Determine "blocksize" from first RDB in list as RDSK.
 *		Set base block number to rdb_RDBBlocksLo
 *		While ( still in passed memory block )
 *			if not a legitimate RDB block then fail
 *			Allocate a block for the list
 *			Setup overhead data and increment bnum
 *			Directly copy block data into allocated block
 *			Increment memory pointer by block size discovered
 *		return no error
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG  __saveds __asm
//HDW_InMemRDBStructs ( register __a0 char *rdbp,			// Start of RDB buffer
//					  register __d0 ULONG sizerdb,		// Size of source buffer
//					  register __d1 ULONG unit )		// Presumed unit
			printf ( "8) Read RDBStructs memory and write as RDB Structs to memory.\n\n");
			/* More specifically read Mountfile from disk and write from memory
			 * to "foo" as one block of RDB Structs.
			 */
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, "..rdb" );
			workfile = fopen ( realfilename, "rb" );
			if ( !workfile )
			{
				printf ( "Failed to open %s\n", realfilename );
				goto cleanup;
			}
			fseek ( workfile, 0, SEEK_END );
			sizeb = ftell ( workfile );
			fseek ( workfile, 0, 0 );
			inmembuffer = malloc ( sizeb + 1 );
			printf ( "Read %d blocks of %d bytes\n", fread ( inmembuffer, sizeb, 1, workfile ), sizeb);
			fclose ( workfile );

			rsuccess = InMemRDBStructs ( inmembuffer,	// Start of RDB buffer
										 sizeb,			// Size of source buffer
										 baseunit );	// Presumed unit
			if ( rsuccess == 0 )
			{
				sizememneeded = 0;
				rsuccess = OutMemRDBStructs ( NULL, &sizememneeded, 0 );

				if ( rsuccess == 0 )
				{
					printf ( "8) Need %ld bytes of buffer for mountfile.\n", sizememneeded );
					outmembuffer = malloc ( sizememneeded + 256 );
					if ( outmembuffer )
					{
						rsuccess = OutMemRDBStructs ( outmembuffer, &sizememneeded, sizememneeded + 255 );
						if ( rsuccess == 0 )
						{
							FILE *foofile = NULL;

							outmembuffer [ sizememneeded + 255 ] = 0;

							foofile = fopen ( "bar", "wb" );
							if ( foofile )
							{
								fwrite ( outmembuffer, sizememneeded, 1, foofile );
								fclose ( foofile );
								foofile = NULL;
							}
						}
						else
						{
							printf ( "Could not write the file: %d\n", rsuccess );
						}
					}
				}
				else
					printf ( "Mountfile size write failed: %d\n", rsuccess );
			}
			else
				printf ( "InMemMountfile failed, %ld\n", rsuccess );

			break;



/******************************************
 *
 *	9
 *		BASIC RDB READ TEST
 *
 *****************************************/
		case 9:
/* HDW_ReadRDBs
 *	Description:
 *		Read the entire RDB structure into RAM. Pay NO attention to decodes.
 *
 *	Direct Inputs:
 *		none
 *
 *	Indirect Inputs:
 *		none except in functions called
 *
 *	Direct Outputs:
 *		USHORT with the "worst" success or fail value
 *
 *	Indirect Outputs:
 *		Completely loaded image of the disk's RDBs in a traceable structure
 *
 *	Local Calls:
 *		ClearBlockList ()
 *		AllocBlock ()
 *		HDW_RawRead ()
 *		ScanList ()
 *
 *	OS Calls:
 *		none
 *
 *	Algorithm:
 *		scan blocks 0 through 16 until we have found an RDSK block.
 *		mark AllocLimitLo = RDSK block number;	??
 *		ScanList ( RDSK_block->bb_Longs [ 6 ]);	/* BadBlocks */
 *		ScanList ( RDSK_block->bb_Longs [ 7 ]);	/* Partitions */
 *		ScanList ( RDSK_block->bb_Longs [ 8 ]);	/* FileSystems */
 *		ScanList ( RDSK_block->bb_Longs [ 9 ]);	/* DriveInits */
 *		Then can scanlist for any others that may appear from 6 reserved.
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//USHORT __saveds __asm
//HDW_ReadRDBs ( void )
			printf ( "9) Read RDB from disk and write as mountfile to <file>...list.\n\n");
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}


			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			rwsuccess = ReadRDBs ( );


			if ( rwsuccess == success )
			{
				sprintf ( realfilename, "%s%s", filename, "...list" );
				rwsuccess = WriteMountfile ( realfilename, "sys:", baseunit );
				if ( rwsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "Mountfile write failed: %d\n", rwsuccess );
			}
			else
			{
					printf ( "RDB read failed: %d\n", rwsuccess );
					break;
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}

			break;


		case 10:
/* HDW_QueryInquiry
 *	Description:
 *		Issue a SCSI "INQUIRY" command and return results
 *	Direct Inputs:
 *		errorcode		Pointer to error code storage
 *	Indirect Inputs:
 *		none
 *	Direct Outputs:
 *		returns result codes lightly massaged
 *	Indirect Outputs:
 *		SC data field filled with inquiry data.
 *	Local Calls:
 *		none
 *	OS Calls:
 *		DoIO ()
 *	Algorithm:
 *		Fill out SCMD for an INQUIRY command
 *		Issue the command
 *		return lightly massaged results
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL __saveds __asm
//HDW_QueryInquiry ( register __a0 BYTE *inqbuf, register __a1 int *errorcode )
			printf ( "10) Perform SCSI Inquiry and report results up to 40 (56) bytes.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				BYTE inqbuf [ MAGC_INQBUFSIZE ];
				int	 errorcode;

				memset ( inqbuf, 0xff, MAGC_INQBUFSIZE );
				*(unsigned long *)&inqbuf = 0x4d616763L;
				if ( QueryInquiry ( inqbuf, &errorcode ))
				{
					printf ( "SCSI inquiry returns:\n" );
					printhex ( inqbuf, MAGC_INQBUFSIZE );
				}
				else
					printf ( "SCSI inquiry failed: %d\n", errorcode );

				memset ( inqbuf, 0xff, INQBUFSIZE );
				if ( QueryInquiry ( inqbuf, &errorcode ))
				{
					printf ( "SCSI inquiry returns:\n" );
					printhex ( inqbuf, INQBUFSIZE );
				}
				else
					printf ( "SCSI inquiry failed: %d\n", errorcode );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			break;

		case 11:
/* HDW_QueryModeSense ()
 *	Description:
 *
 *	Direct Inputs:
 *		page			mode sense page requested
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *
 *	OS Calls:
 *		DoIO ()
 *	Algorithm:
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL __saveds __asm
//HDW_QueryModeSense ( register __d0 int		 page,
//					 register __d1 int		 msbsize,
//					 register __a0 BYTE		*msbuf,
//					 register __a1 int		*errorcode )
			printf ( "11) Perform SCSI ModeSense  and report results up to 256 bytes.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				BYTE msbuf [ 256 ];
				int	 errorcode;

				memset ( msbuf, 0xff, 256 );
				if ( QueryModeSense ( (BYTE) mspage, 256, msbuf, &errorcode ))	// All sets page 0
				{
					printf ( "SCSI ModeSense returns:\n" );
					printhex ( msbuf, 256 );
				}
				else
					printf ( "SCSI ModeSense failed: %d\n", errorcode );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			break;

		case 12:

/* HDW_QueryCapacity
 *	Description:
 *
 *	Direct Inputs:
 *		none
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *
 *	OS Calls:
 *		DoIO ()
 *	Algorithm:
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL __saveds __asm
//HDW_QueryCapacity( register __a0 ULONG *capacity )
			printf ( "12) Perform SCSI Read Capacity and report disk size.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				ULONG capacity;
				ULONG blocksize;

				if ( QueryCapacity ( &capacity, &blocksize ))	// All sets page 0
					printf ( "SCSI Read Capacity returns: %ld blocks of %ld bytes.\n",
							 capacity,
							 blocksize );
				else
					printf ( "SCSI Read Capacity failed\n" );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 13:
/* HDW_QueryReady
 *	Description:
 *		Issue a SCSI "TEST UNIT READY" command and return results
 *	Direct Inputs:
 *		errorcode		pointer to an error code return
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		returns TRUE for ready and FALSE for not ready
 *	Indirect Outputs:
 *		errorcode		contains the (massaged) IO error codes on return
 *	Local Calls:
 *		none
 *	OS Calls:
 *		DoIO ()
 *	Algorithm:
 *		Fill out SCMD for a TEST UNIT READY command
 *		Issue the command
 *		fill out errorcode
 *		return Ready or not ready
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL __saveds __asm
//HDW_QueryReady ( register __a0 int * errorcode )
			printf ( "13) Perform SCSI Test Unit Ready and report device readiness.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				int errorcode;

				if ( QueryReady ( &errorcode ))	// All sets page 0
					printf ( "SCSI Test Unit Ready indicates ready.\n" );
				else
					printf ( "SCSI Test Unit Ready indicates not ready: %ld\n", errorcode );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 14:
/* HDW_FindDiskName ()
 *	Description:
 *		Reads manufacturer data from Inquiry command and installs in supplied
 *		string space. Should be a valid device.
 *
 *	Direct Inputs:
 *		diskname		A pointer to a disk name storage array
 *
 *	Indirect Inputs:
 *		Already opened device
 *
 *	Direct Outputs:
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *		Calls global QueryInquiry function
 *
 *	OS Calls:
 *
 *	Algorithm:
 *		if device not open or diskname is null return failure
 *		call HDW_QueryInquiry
 *		Copy disk name into provided storage for exactly 28 bytes using memcpy.
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL __saveds __asm /* error */
//HDW_FindDiskName ( register __a0 *diskname )
			printf ( "14) Find Disk Name returning in string variable.\n\n" );
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				char diskname[32];

				memset ( diskname, 0xff, 32 );
				if ( FindDiskName ( diskname ))
					printhex ( diskname, 32 );
				else
					printf ( "FindDiskName failed!\n" );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 15:
/* HDW_FindControllerID()
 *	Description:
 *		Test open devices until find SelfID error
 *		( Of course, this does not work on Commododo "scsi.device". <bleah!> )
 *
 *	Direct Inputs:
 *		ULONG	*selfid	pointer to selfid result field. Contains a Unit number
 *						with a valid board number field.
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		Unit number for controller's SCSI ID.
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *
 *	OS Calls:
 *
 *	Algorithm:
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//BOOL16 Apr 1999 __saveds __asm /* error */
//HDW_FindControllerID ( register __a0 char *devname, register __a1 ULONG *selfid )
			printf ( "15) Find Controller self-ID returning in ULONG.\n\n" );
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			{
				ULONG selfid = baseunit;

				if ( FindControllerID ( devicename, &selfid ))
					printf ( "Controller ID is %ld.\n", selfid );
				else
					printf ( "FindControllerID failed!\n" );
			}
			break;

		case 16:
/* HDW_FindLastSector()	( Made available chiefly for diagnostic purposes.)
 *	Description:
 *		Determine last available sector on disk WITH tests.
 *
 *	Direct Inputs:
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *		Last block on the disk numbered 1 through n. (This was done so that
 *		the TotalBlocks report and the FindLastSector report are congruent.)
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *
 *	OS Calls:
 *
 *	Algorithm:
 *		HDW_QueryCapacity
 *		Test what should be last block.
 *		If ( Read the rated last block is OK )
 *			if ( Read the block past rated last block is bad )
 *				return no error and last sector number confirmed.
 *			else
 *				Search upwards binary search until find real last bad
 *				sector. Return error "Last Sector to low" and found top block.
 *		else
 *			Step downwards one block then two then four until read one OK.
 *			Then step upwards binary search for actual top block.
 *			Return error "Last sector too high" and found top block.
 *		endif
 *		exit
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm /* error */
//HDW_FindLastSector ( void )
			printf ( "16) Report last available block on the drive.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			printf ( "Find Last Sector returns: %ld\n", FindLastSector());

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 17:
/* HDW_FindDefaults ()
 *	Description:
 *		Determine default blocking for device.
 *
 *	Direct Inputs:
 *		Optimize		A flag array for optimization values
 *		Return			Pointer to a DefaultsArray structure for return values
 *
 *	Indirect Inputs:
 *		Opened IO device
 *
 *	Direct Outputs:
 *		Error return value passing back informational and fatal errors.
 *		The DefaultsArray passed in is filled in
 *
 *	Indirect Outputs:
 *		Many internal values are filled in which will be overridden when
 *		reading RDBs or Mountfiles.
 *
 *	Local Calls:
 *		HDW_FindLastSector ()
 *		HDW_QueryInquiry ()
 *		HDW_QueryModeSense ()
 *
 *	OS Calls:
 *
 *	Algorithm:
 *		HDW_QueryCapacity
 *		HDW_FindLastBlock () // Test what should be last block.
 *		Division routines....
 *		exit
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//ULONG __saveds __asm
//HDW_FindDefaults ( register __d0 BOOL Optimize,
//				   register __a0 struct DefaultsArray Return )
/*struct DefaultsArray
 *{
 *	UWORD	BytesPerBlock;
 *	UWORD	BlocksPerSurface;
 *	UWORD	Surfaces;
 *	UWORD	Cylinders;				// note: MaxCyl = Cylinders - 1;
 *};
 */
			printf ( "17) Generate default drive parameters.\n\n" );
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				struct	DefaultsArray defaults;
				ULONG	errorcode;

				memset ( &defaults, 0, sizeof ( struct DefaultsArray) );
				errorcode = FindDefaults ( 0, &defaults );	// No optimize
				if ( errorcode == 0 )
				{
					printf ( "TotalBlocks:         %d\n", defaults.TotalBlocks );
					printf ( "BytesPerBlock:       %d\n", defaults.BytesPerBlock );
					printf ( "BlocksPerSurface:    %d\n", defaults.BlocksPerSurface );
					printf ( "Surfaces:            %d\n", defaults.Surfaces );
					printf ( "Cylinders:           %d\n", defaults.Cylinders );
					printf ( "Unused Blocks:       %d\n", defaults.UnusedBlocks );
				}
				else
					printf ( "FindDefaults failed!\n" );

				printf ( "\nAttempting Optimized Defaults.\n" );
				memset ( &defaults, 0, sizeof ( struct DefaultsArray) );
				errorcode = FindDefaults ( DA_OPTIMIZE, &defaults );
				if ( errorcode < DA_FAILED )
				{
					printf ( "TotalBlocks:         %d\n", defaults.TotalBlocks );
					printf ( "BytesPerBlock:       %d\n", defaults.BytesPerBlock );
					printf ( "BlocksPerSurface:    %d\n", defaults.BlocksPerSurface );
					printf ( "Surfaces:            %d\n", defaults.Surfaces );
					printf ( "Cylinders:           %d\n", defaults.Cylinders );
					printf ( "Unused Blocks:       %d\n", defaults.UnusedBlocks );
				}
				else
					printf ( "FindDefaults failed!\n" );

				printf ( "\nAttempting HardFrame Defaults.\n" );
				memset ( &defaults, 0, sizeof ( struct DefaultsArray) );
				errorcode = FindDefaults ( DA_HF_WAY, &defaults );
				if ( errorcode == 0 )
				{
					printf ( "TotalBlocks:         %d\n", defaults.TotalBlocks );
					printf ( "BytesPerBlock:       %d\n", defaults.BytesPerBlock );
					printf ( "BlocksPerSurface:    %d\n", defaults.BlocksPerSurface );
					printf ( "Surfaces:            %d\n", defaults.Surfaces );
					printf ( "Cylinders:           %d\n", defaults.Cylinders );
					printf ( "Unused Blocks:       %d\n", defaults.UnusedBlocks );
				}
				else
					printf ( "FindDefaults failed!\n" );

				printf ( "\nAttempting 1Meg Cylinder size Defaults.\n" );
				memset ( &defaults, 0, sizeof ( struct DefaultsArray) );
				errorcode = FindDefaults ( DA_HUGE, &defaults );
				if ( errorcode == 0 )
				{
					printf ( "TotalBlocks:         %d\n", defaults.TotalBlocks );
					printf ( "BytesPerBlock:       %d\n", defaults.BytesPerBlock );
					printf ( "BlocksPerSurface:    %d\n", defaults.BlocksPerSurface );
					printf ( "Surfaces:            %d\n", defaults.Surfaces );
					printf ( "Cylinders:           %d\n", defaults.Cylinders );
					printf ( "Unused Blocks:       %d\n", defaults.UnusedBlocks );
				}
				else
					printf ( "FindDefaults failed!\n" );

				printf ( "\nAttempting Optimized Defaults with a huge disk.\n" );
				memset ( &defaults, 0, sizeof ( struct DefaultsArray) );
				errorcode = FindDefaults ( DA_OPTIMIZE | DA_HUGE, &defaults );
				if ( errorcode == 0 
				||   errorcode == DA_NO_OPTIMIZE )
				{
					printf ( "TotalBlocks:         %d\n", defaults.TotalBlocks );
					printf ( "BytesPerBlock:       %d\n", defaults.BytesPerBlock );
					printf ( "BlocksPerSurface:    %d\n", defaults.BlocksPerSurface );
					printf ( "Surfaces:            %d\n", defaults.Surfaces );
					printf ( "Cylinders:           %d\n", defaults.Cylinders );
					printf ( "Unused Blocks:       %d\n", defaults.UnusedBlocks );
				}
				else
					printf ( "FindDefaults failed!\n" );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 18:
/* HDW_RawRead
 *	Description:
 *		Read a block from the disk into the provided BootBlock structure at
 *		the block number stored in the BootBlock structure.
 *
 *	Direct Inputs:
 *		bb				pointer to an array of ULONG of indefinate size.
 *		blocknum		The number of the block to read.
 *
 *	Indirect Inputs:
 *		SC			Global utility SCSI direct command field
 *		SCCmd		Global utility SCSI command field
 *		IOR			IO Request block for a presumed opened device
 *		ddBlockBytes	Block size as determined from the first (good) disk read
 *						On first read use 16384. On success this is updated from
 *						SCSI.actual.
 *	Direct Output:
 *		USHORT Success or failure per enum...
 *
 *	Indirect Output:
 *		bb 				filled with data and errorcode from the read.
 *		ddBlockBytes	updated as appropriate for size of actual read.
 *
 *	Local Calls:
 *		None
 *
 *	OS Calls:
 *		DoIO ()
 *
 *	Algorithm:
 *		If block less than 2097152, 2^21, use the 6 byte command sequence,
 *		else use the 10 byte read command sequence. (This is an arbitrary choice.)
 *
 *		Ascertain device is open
 *		allocate temporary read block per size of ddBlockBytes
 *		Build the command
 *		issue the command
 *		If command good
 *			if ddBlockBytes == 16384 set ddBlockBytes to actual xfersize
 *			copy actual transfer size bytes into bb
 *		if blocksize not power of two >= 512L <= 16384L
 *			errorcode = invalid_block_size
 *		return error codes as appropriate.
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//USHORT __saveds __asm
//HDW_RawRead ( register __a0 BootBlock *bbk, register __d0 USHORT size )
			printf ( "18) Read and report raw sector 'MS'.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}


			{
				BootBlock	*bb;
				ULONG		 capacity;
				ULONG		 blocksize;
				USHORT		 ecode;

				if ( QueryCapacity ( &capacity, &blocksize ))	// All sets page 0
					printf ( "SCSI Read Capacity returns: %ld blocks of %ld bytes.\n",
							 capacity,
							 blocksize );
				else
				{
					printf ( "SCSI Read Capacity failed\n" );
					blocksize = 16384L;			// Better use a safe blocksize!
				}

				bb = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				if ( bb == NULL )
				{
					printf ( "BootBlock allocation failed!\n" );
					break;
				}

				bb->bb_BlockNum = mspage;	// Only value really needed
				ecode = RawRead ( bb, blocksize );
				if ( ecode == success )
					printhex ( bb->bb_Data.bd_Bytes, blocksize );
				else
					printf ( "RawRead failed %d!", ecode );

			}


			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 19:
/* HDW_QueryFindValid
 *	Description:
 *		Attempt to determine all valid configureable units on devicename
 *		according to an acceptable types bitmap supplied on entry. Data is
 *		filled into a 16 word of 16 bits each bitmap with pointer supplied
 *		on entry. "BoardNumber" to be tested is supplied by the calling
 *		routine.
 *	Direct Inputs:
 *		ValidIDs			Pointer ValidIDstruct
 *		devicename			device name for testing
 *		board				Board ID to test
 *		types				ULONG bitmap of valid device typese
 *		widescsi			BOOLEAN set TRUE if wide scsi used.
 *		CallBack			Pointer to callback handler
 *
 *	Indirect Inputs:
 *
 *	Direct Outputs:
 *
 *	Indirect Outputs:
 *
 *	Local Calls:
 *
 *	OS Calls:
 *
 *	Algorithm:
 *		Clear the supplied bitmap array
 *		For all IDs on the SCSI bus
 *			For all LUNs on each ID
 *				HW_OpenDevice ( Board, ID, LUN, devicename )
 *				TestUnitReady()
 *				Inquiry()
 *				if in valid types
 *					Mark as valid
 *				if LUN 0 fails to open
 *					break - skipping remaining LUNs
 *				if self-id for controller
 *					break - skipping controller
 *		return completion status
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//void __saveds __asm
//HDW_QueryFindValid ( register __a0 ValidIDstruct *ValidIDs,
//					   register __a1 char * devicename,
//					   register __d0 int board,
//					   register __d1 ULONG types,
//					   register __d2 BOOL wide_scsi,
//					   register __a2 long ( *__asm CallBack)
//										   ( register __a0 HDWCallbackMsg msg ));
			printf ( "19) Find all valid disks on a given controller.\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			{
				ULONG			 types;
				int				 board = baseunit;
				ValidIDstruct	 ValidIDs;

				printf ( "Trying for hard disks only.\n" );
				types = 1;	// Only disk drives!
				QueryFindValid ( &ValidIDs, devicename, board, types, FALSE, NULL );
				printhex ( (BYTE *) ValidIDs.there, 16 * sizeof (USHORT ));
				printhex ( (BYTE *) ValidIDs.ready, 16 * sizeof (USHORT ));

				printf ( "\nTrying for ALL drive types.\n" );
				types = (ULONG) -1L;	// All devices!
				QueryFindValid ( &ValidIDs, devicename, board, types, FALSE, CallBack );
				printf ("\n\n");
				printhex ( (BYTE *) ValidIDs.there, 16 * sizeof (USHORT ));
				printhex ( (BYTE *) ValidIDs.ready, 16 * sizeof (USHORT ));
			}
		break;

		case 20:
/* HDW_RawWrite
 *	Description:
 *		Write the data section of a BootBlock to the disk at the block number
 *		stored within the BootBlock structure.
 *
 *	Direct Inputs:
 *		bb				pointer to a BootBlock structure of indefinate size.
 *						Note that bb includes the block ID
 *
 *	Indirect Inputs:
 *		SC			Global utility SCSI direct command field
 *		SCCmd		Global utility SCSI command field
 *		IOR			IO Request block for a presumed opened device
 *		ddBlockBytes	Block size as determined from the first (good) disk read
 *						On first read use 16384. On success this is updated from
 *						SCSI.actual.
 *
 *	Direct Output:
 *		UHSORT Success or failure per enum...
 *
 *	Indirect Output:
 *		bb 				data field written to disk.
 *
 *	Local Calls:
 *		None
 *
 *	OS Calls:
 *		DoIO ()
 *
 *	Algorithm:
 *		Make sure IOR is legitimately opened
 *		blocknum = bb->bb_BlockNum
 *		if blocknum = -1
 *			find in bitmap first unassigned block and assign it
 *			repair bb->BlockNum and blocknum to reflect this
 *		Build the SCSI command
 *		Issue IO command
 *		return massaged error code.
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//USHORT __saveds __asm
//HDW_RawWrite ( register __a0 BootBlock *bb )
			printf ( "20) Raw write to a block of low disk. (Safe write - I hope!)\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}


			{
				BootBlock	*bb;
				BootBlock	*bbt;
				BootBlock	*bbtr;
				ULONG		 capacity;
				ULONG		 blocksize;
				USHORT		 ecode;

				if ( QueryCapacity ( &capacity, &blocksize ))	// All sets page 0
					printf ( "SCSI Read Capacity returns: %ld blocks of %ld bytes.\n",
							 capacity,
							 blocksize );
				else
				{
					printf ( "SCSI Read Capacity failed\n" );
					blocksize = 16384L;			// Better use a safe blocksize!
				}

				bb   = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				bbt  = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				bbtr = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				if (( bb == NULL ) || ( bbt == NULL ) || ( bbtr == NULL ))
				{
					printf ( "BootBlock allocation failed!\n" );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				bb->bb_BlockNum   = mspage;	// Only value really needed
				bbt->bb_BlockNum  = mspage;	// Only value really needed
				bbtr->bb_BlockNum = mspage;	// Only value really needed

				ecode = RawRead ( bb, blocksize );
				if ( ecode == success )
					printhex ( bb->bb_Data.bd_Bytes, 32 );
				else
				{
					printf ( "RawRead failed %d!", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				printf ( "This IS dangerous. Continue? ");
				gets ( bbt->bb_Data.bd_Bytes );
				if ( bbt->bb_Data.bd_Bytes [ 0 ] != 'Y' )
				{
					printf ( "OK, I'm GONE Kemosabe!\n" );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				// OK guys - this is the BIG doodoo if we get it wrong!
				// Write exactly the same data back....
				ecode = RawWrite ( bb );
				if ( ecode != success )
				{
					printf ( "RawWrite failed, %d\n", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				else
					printf ( "Block written = %d\n", bb->bb_RWErrors.block_written );

				// Now fill the data block with OTHER data!
				//
				for ( ecode = 0; ecode < blocksize; ecode++ )
					bbt->bb_Data.bd_Bytes [ ecode ] = (UBYTE) (ecode & 0xff);

				// OK guys - this is the REAL BIG doodoo if we get it wrong!
				// Write exactly the same data back....
				ecode = RawWrite ( bbt );
				if ( ecode != success )
				{
					printf ( "RawWrite failed, %d\n", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				else
					printf ( "Block written = %d\n", bbt->bb_RWErrors.block_written );

				// Reread it for confirmation it was written
				ecode = RawRead ( bbtr, blocksize );
				if ( ecode == success )
					printhex ( bbtr->bb_Data.bd_Bytes, 32 );
				else
				{
					printf ( "RawRead failed %d!", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				// IMMEDIATELY restore the original block!
				ecode = RawWrite ( bb );
				if ( ecode != success )
				{
					printf ( "RawWrite failed, %d\n", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				else
					printf ( "Block written = %d\n", bb->bb_RWErrors.block_written );

				for ( ecode = 0; ecode < blocksize; ecode++ )
				{
					if ( bbt->bb_Data.bd_Bytes [ ecode ] != bbtr->bb_Data.bd_Bytes [ ecode ] )
					{
						printf ( "Compare error at %d: %x vs %x\n",
								 ecode,
								 bbt->bb_Data.bd_Bytes [ ecode ],
								 bbtr->bb_Data.bd_Bytes [ ecode ] );
						break;
					}
				}
				if ( ecode == blocksize )
					printf ( "Completely successful compare here, too.\n" );

				if ( bb )
					free ( bb );
				if ( bbt )
					free ( bbt );
				if ( bbtr )
					free ( bbtr );
			}


			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 21:
/* HDW_WriteBlock
 *	Description:
 *		Write a BootBlock's data to the disk at the block number stored in the
 *		structure. Readback to verify the written data. Repeat a few times on
 *		initial failure.
 *
 *	Direct Inputs:
 *		bb				pointer to a BootBlock structure of indefinate size.
 *						Note that bb includes the block ID
 *	Indirect Inputs:
 *		SC			Global utility SCSI direct command field
 *		SCCmd		Global utility SCSI command field
 *		IOR			IO Request block for a presumed opened device
 *		ddBlockBytes	Block size as determined from the first (good) disk read
 *						On first read use 16384. On success this is updated from
 *						SCSI.actual.
 *
 *	Direct Output:
 *		USHORT Success or failure per enum...
 *
 *	Indirect Output:
 *		bb 				data field written to disk.
 *
 *	Local Calls:
 *		HDW_RawWrite ()
 *		HDW_RawRead ()
 *
 *	OS Calls:
 *		none
 *
 *	Algorithm:
 *		Allocate temporary BootBlock structure
 *		repeat several tries:
 *			Write block
 *			Read block 1000 to try to flush disk caches slightly
 *			Read back written block to a scratchpad
 *			Compare block to scratchpad
 *			if error repeat
 *		Free temporary bootblock structure
 *		massage error codes.
 *		return massaged error code.
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//USHORT __saveds __asm
//HDW_WriteBlock( register __a0 BootBlock *bb )
			printf ( "21) Write with checksum to a block of low disk. (Safe write - I hope!)\n\n");
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			{
				BootBlock	*bb;
				BootBlock	*bbt;
				BootBlock	*bbtr;
				ULONG		 capacity;
				ULONG		 blocksize;
				USHORT		 ecode;

				if ( QueryCapacity ( &capacity, &blocksize ))	// All sets page 0
					printf ( "SCSI Read Capacity returns: %ld blocks of %ld bytes.\n",
							 capacity,
							 blocksize );
				else
				{
					printf ( "SCSI Read Capacity failed\n" );
					blocksize = 16384L;			// Better use a safe blocksize!
				}

				bb   = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				bbt  = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				bbtr = malloc ( sizeof ( BootBlock ) - 512 + blocksize );
				if (( bb == NULL ) || ( bbt == NULL ) || ( bbtr == NULL ))
				{
					printf ( "BootBlock allocation failed!\n" );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				bb->bb_BlockNum   = mspage;	// Only value really needed
				bbt->bb_BlockNum  = mspage;	// Only value really needed
				bbtr->bb_BlockNum = mspage;	// Only value really needed

				ecode = RawRead ( bb, blocksize );
				if ( ecode == success )
					printhex ( bb->bb_Data.bd_Bytes, 32 );
				else
				{
					printf ( "RawRead failed %d!", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				printf ( "This IS dangerous. Continue? ");
				gets ( bbt->bb_Data.bd_Bytes );
				if ( bbt->bb_Data.bd_Bytes [ 0 ] != 'Y' )
				{
					printf ( "OK, I'm GONE Kemosabe!\n" );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				// Now fill the data block with OTHER data!
				//
				for ( ecode = 0; ecode < blocksize; ecode++ )
					bbt->bb_Data.bd_Bytes [ ecode ] = (UBYTE) (ecode & 0xff);

				bbt->bb_Data.bd_RDB.rdb_SummedLongs = blocksize >> 2;
				bbt->bb_Data.bd_RDB.rdb_ID = 0x57495045;
				// OK guys - this is the REAL BIG doodoo if we get it wrong!
				// Write exactly the same data back....
				ecode = WriteBlock ( bbt );
				if ( ecode != success )
				{
					printf ( "WriteBlock failed, %d\n", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				else
					printf ( "Block written = %d\n", bbt->bb_RWErrors.block_written );

				// Reread it for confirmation it was written
				ecode = RawRead ( bbtr, blocksize );
				if ( ecode == success )
					printhex ( bbtr->bb_Data.bd_Bytes, 32 );
				else
				{
					printf ( "RawRead failed %d!", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}

				// IMMEDIATELY restore the original block!
				ecode = RawWrite ( bb );
				if ( ecode != success )
				{
					printf ( "RawWrite failed, %d\n", ecode );
					if ( bb )
						free ( bb );
					if ( bbt )
						free ( bbt );
					if ( bbtr )
						free ( bbtr );
					break;
				}
				else
					printf ( "Block written = %d\n", bb->bb_RWErrors.block_written );

				for ( ecode = 0; ecode < blocksize; ecode++ )
				{
					if ( bbt->bb_Data.bd_Bytes [ ecode ] != bbtr->bb_Data.bd_Bytes [ ecode ] )
					{
						printf ( "Compare error at %d: %x vs %x\n",
								 ecode,
								 bbt->bb_Data.bd_Bytes [ ecode ],
								 bbtr->bb_Data.bd_Bytes [ ecode ] );
						break;
					}
				}
				if ( ecode == blocksize )
					printf ( "Completely successful compare here, too.\n" );

				if ( bb )
					free ( bb );
				if ( bbt )
					free ( bbt );
				if ( bbtr )
					free ( bbtr );
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
		break;

		case 22:
/* HDW_WriteRDBs
 *	Description:
 *		Traverse "BootBlocks" RDB structures given.
 *		Write them to disk in the order the structures exist in the structure
 *		linked list.
 *
 *	Direct Inputs:
 *		none
 *
 *	Indirect Inputs:
 *		BlockLists		List head for the RDB blocklists to be written
 *
 *	Direct Outputs:
 *		Cumulative error code
 *
 *	Indirect Outputs:
 *		RDBs written to disk as RDBs.
 *
 *	Local Calls:
 *		HDW_BlockWrite ()
 *
 *	OS Calls:
 *		None
 *
 *	Algorithm:
 *		Trace the blocklist via the .Succ nodes writing the data segment
 *		of every BootBlock encountered to disk.
 *			If complete failure
 *				return
 *			if error worse than prior errors
 *				set new return value.
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
//USHORT __saveds __asm
//HDW_WriteRDBs ( void )
			printf ( "22) Read RDBs from <file.list> and write to disk. (The biggie!)\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}
			sprintf ( realfilename, "%s%s", filename, ".list" );
			rsuccess = ReadMountfile ( baseunit, realfilename, devicename );
			if ( rsuccess != 0 )
			{
				printf ( "Mountfile read failed: %d\n", rsuccess );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}

			printf ( "Beginning to write RDBs.\n" );

			rwsuccess = WriteRDBs (  );
			if ( rwsuccess == 0 )
				printf ( "You should have a new RDBs waiting on the disk.\n" );
			else
				if ( rwsuccess != 0xffff )
					printf ( "DOODOO CITY! RDB Write failed: %d\n", rwsuccess );
				else
					printf ( "RDB Write failed because this version does not have it supported.\n" );

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			break;

/* HDW_WriteRDBStructs()
 *	Description:
 *		(Write RDBs to file instead of RDB area of disk.)
 *		Write the internal RDB structures to disk exactly as in memory.
 *
 *	Direct Inputs:
 *		Filename		Name of file to write. NB: This will clobber duplicates
 *
 *	Indirect Inputs:
 *		RDB structures in memory
 *
 *	Direct Outputs:
 *		ret			error 0 if success else error indication
 *
 *	Indirect Outputs:
 *		File written
 *
 *	Local Calls:
 *
 *	OS Calls:
 *		fclose ()
 *		fopen ()
 *		fwrite ()
 *
 *	Algorithm:
 *		if no RDBs in memory of file open fails exit with error
 *		else
 *			pointer = Basepointer->next
 *			while pointer
 *				translate and write block to disk file
 *				pointer = pointer->next
 *			endwhile
 *		endif
 *
 *	Code:
 *		Joanne Dow, Wizardess Designs, Jan 1999
 */
		case 23:
			printf ( "23) Read RDBs from disk and write RDB Structs to file.\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}
			printf ( "Attempting to read RDBs into library.\n");

			rwsuccess = ReadRDBs ( );

			if ( rwsuccess == success )
			{
				sprintf ( realfilename, "%s%s", filename, ".rdb" );
				rwsuccess = WriteRDBStructs ( realfilename );
				if ( rwsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "Mountfile write failed: %d\n", rwsuccess );
			}
			else
			{
					printf ( "RDB read failed: %d\n", rwsuccess );
					break;
			}

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			break;


		case 24:
			printf ( "24) Read RDB Structs from file and write RDB Structs to file.\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			sprintf ( realfilename, "%s%s", filename, ".rdb" );
			rsuccess = ReadRDBStructs ( realfilename, baseunit );

			if ( rsuccess == 0 )
			{
				sprintf ( realfilename, "%s%s", filename, "...rdb" );
				rwsuccess = WriteRDBStructs ( realfilename );
				if ( rwsuccess == 0 )
					printf ( "You should have a new %s waiting.\n", realfilename );
				else
					printf ( "RDBfile write failed: %d\n", rwsuccess );
			}
			else
			{
					printf ( "RDB read failed: %d\n", rwsuccess );
					break;
			}

			break;

		case 25:	// Verify Data On Drive
			{
				LONG ok;

				printf ( "25) Verify data on disk.\n\n" );
				if ( baseunit == (ULONG) -1L )
				{
					printf ( "You must enter a BU, Base Unit, number\n");
					break;
				}
				// Open device here.
				printf ( "Attempting to open: %s\n", devicename );
				deviceopen = HDWOpenDevice ( devicename, baseunit );
				if ( !deviceopen )
				{
					printf ("%s unit %ld failed to open\n", devicename, baseunit );
					break;
				}

				ok = VerifyDrive ( CallBack );
				printf ( "ok = %d\n", ok );

				if ( deviceopen )
				{
					printf ( "Closing opened device\n" );
					HDWCloseDevice();
					deviceopen = FALSE;
				}
			}
			break;

		case 26:
			printf ( "26) Read RDBStructs from <file>...rdb and write to Disk.\n");
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			sprintf ( realfilename, "%s%s", filename, ".rdb" );
			rsuccess = ReadRDBStructs ( realfilename, baseunit );

			if ( rsuccess == 0 )
			{
				printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
				deviceopen = HDWOpenDevice ( devicename, baseunit );
				if ( !deviceopen )
				{
					printf ( "No device was opened!\n");
					break;
				}

				printf ( "Beginning to write RDBs.\n" );

				rwsuccess = WriteRDBs (  );
				if ( rwsuccess == 0 )
					printf ( "You should have a new RDBs waiting on the disk.\n" );
				else
					if ( rwsuccess != 0xffff )
						printf ( "DOODOO CITY! RDB Write failed: %d\n", rwsuccess );
					else
						printf ( "RDB Write failed because this version does not have it supported.\n" );

				if ( deviceopen )
				{
					printf ( "Closing opened device\n" );
					HDWCloseDevice();
					deviceopen = FALSE;
				}
			}
			break;

		case 27:
			printf ( "27) Read RDBs from disk and write RDB Structs memory thence to file and console as hex.\n\n" );
			if ( !filename )
			{
				printf ( "Need a filename\n" );
				break;
			}
			if ( strlen( filename ) > 248 )
			{
				printf ( "Filename: %s is too long!\n", filename );
				break;
			}
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "Need a base unit for this command.\n" );
				break;
			}

			printf ( "Attempting to open: %s:%d\n", devicename, baseunit );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ( "No device was opened!\n");
				break;
			}
			printf ( "Attempting to read RDBs into library.\n");

			rwsuccess = ReadRDBs ( );

			if ( rwsuccess == 0 )
			{
				sizememneeded = 0;
				rsuccess = OutMemRDBStructs ( NULL, &sizememneeded, 0 );

				if ( rsuccess == 0 )
				{
					printf ( "7) Need %ld bytes of buffer for mountfile.\n", sizememneeded );
					outmembuffer = malloc ( sizememneeded + 256 );
					if ( outmembuffer )
					{
//						int i;
//						for ( i = sizememneeded; i < sizememneeded + 256; i++)
//							outmembuffer[i] = 'A';
						rsuccess = OutMemRDBStructs ( outmembuffer, &sizememneeded, sizememneeded + 255 );
						if ( rsuccess == 0 )
						{
							FILE *foofile = NULL;
							ULONG	foo;
							ULONG	offset = *(ULONG *) &outmembuffer[ 128 ];

							outmembuffer [ sizememneeded + 255 ] = 0;
							for ( foo = 0; foo < sizememneeded; foo+= 512L)
							{
								printf ( "Block %2.2x:\n", (foo >> 9) + offset);
								printhex ( &outmembuffer[foo], 512 );
							}
//							printhex ( &outmembuffer[sizememneeded-16], 256 );

							foofile = fopen ( filename, "wb" );
							if ( foofile )
							{
								fwrite ( outmembuffer, sizememneeded, 1, foofile );
								fclose ( foofile );
								foofile = NULL;
							}
						}
						else
						{
							printf ( "Could not write the file: %d\n", rsuccess );
						}
					}
				}
				else
					printf ( "Mountfile size write failed: %d\n", rsuccess );
			}
			else
				printf ( "InMemMountfile failed, %ld\n", rsuccess );

			if ( deviceopen )
			{
				printf ( "Closing opened device\n" );
				HDWCloseDevice();
				deviceopen = FALSE;
			}
			break;

		case 28:
#if 0
			if ( baseunit == (ULONG) -1L )
			{
				printf ( "You must enter a BU, Base Unit, number\n");
				break;
			}
			// Open device here.
			printf ( "Attempting to open: %s\n", devicename );
			deviceopen = HDWOpenDevice ( devicename, baseunit );
			if ( !deviceopen )
			{
				printf ("%s unit %ld failed to open\n", devicename, baseunit );
				break;
			}
#endif
			printf ( "Not implemented yet!\n" );
			break;

		case 100:
//ULONG __saveds __asm LowlevelFormat ( register __a0 long ( * __asm CallBack)
//									  ( register __a0 HDWCallbackMsg *msg ))
			{
				LONG ok;

				printf ( "100) Format Drive - VERY DANGEROUS!\n\n" );
				if ( baseunit == (ULONG) -1L )
				{
					printf ( "You must enter a BU, Base Unit, number\n");
					break;
				}
				// Open device here.
				printf ( "Attempting to open: %s\n", devicename );
				deviceopen = HDWOpenDevice ( devicename, baseunit );
				if ( !deviceopen )
				{
					printf ("%s unit %ld failed to open\n", devicename, baseunit );
					break;
				}

				ok = LowlevelFormat ( CallBack );
				printf ( "ok = %d\n", ok );

				if ( deviceopen )
				{
					printf ( "Closing opened device\n" );
					HDWCloseDevice();
					deviceopen = FALSE;
				}
			}
			break;
		}
	}
	else
	{
		usage ();
	}

cleanup:

	exit ( 0 );
}

/*
typedef struct
{
	STRPTR	devicename;
	LONG	board;
	LONG	address;
	LONG	lun;
	STRPTR	messagestring;
	LONG	extra;
} HDWCallbackMsg;
*/
long __stdargs __saveds __asm CallBack ( register __a0 HDWCallbackMsg *msg )
{
	char	  str[80];
	char	  och = *msg->messagestring;
	char	  ch = och;
	char	 *string;

	if (( ch < MIN_MESSAGE )
	 || ( ch > MAX_MESSAGE ))
		ch = 'c';
	string = callback_messages [ ch - 'A' ];

	switch ( msg->extra )
	{
	  case EXTRA_BEFORE_TEST:	// before scan
		sprintf ( str,
				  callback_messages[0],		// Always "Scanning: " or equivalent
				  msg->devicename,
				  msg->board,
				  msg->lun,
				  msg->address );
		printf ( "%s[%dD", str, strlen( str ) );
		flushall();
		break;

	  case EXTRA_AFTER_TEST:
		printf ( "[%d%d%d] ", msg->board, msg->lun, msg->address );
		flushall();
		break;

	  case EXTRA_BEFORE_VERIFY:		// Validate Drive
		// Print messagestring plus other data.
		// Perform an ARE YOU SURE function.
		printf ( callback_messages[2],
				 msg->lun, msg->address, msg->board );
		str[0] = 0;
		while ( 1 )
		{
			fgets ( str, 79, stdin);
			ch = tolower( str[0] );
			if ( ch == 'y' )
				break;
			if ( ch == 'n' )
				return FALSE;
			printf ( "Do you wish to continue?" );
		}
		break;

	  case EXTRA_BEFORE_FORMAT:		// Format Drive
		// Print messagestring plus other data.
		// Perform an *BIG* ARE YOU SURE function.
		printf ( callback_messages[1],
				 msg->lun,
				 msg->address,
				 msg->board );
		str[0] = 0;
		while ( 1 )
		{
			fgets ( str, 79, stdin);
			ch = tolower( str[0] );
			if ( ch == 'y' )
				break;
			if ( ch == 'n' )
				return FALSE;
			printf ( "Are you VERY sure you want to do this?\n" );
		}
		while ( 1 )
		{
			printf ( "Let's try again, do you really want to destroy all your data?\n" );
			fgets ( str, 79, stdin);
			ch = str [ 0 ];
			if ( ch == 'y' )
				break;
			if ( ch == 'n' )
				return FALSE;
		}
		break;

	  case EXTRA_UPDATE_VERIFY:		// 4
	  	chkabort();
		if ( aborted )			// Note we do NOT clear the aborted flag.
			return FALSE;
		printf ( "LUN %d on drive %d on board %d: ",
				 msg->lun, msg->address, msg->board );

		switch ( ch )
		{
		  case 'E':
			printf ( string, &msg->messagestring [ 2 ] );
			break;

		  case 'O':
			printf ( string, msg->param1, msg->param2, msg->param3 );
			break;

		  case 'R':
		  case 'U':
		  case 'X':
		  case 'Y':
		  case 'Z':
		  case '[':
		  case '\\':
		  case ']':
		  case '^':
		  case '_':
		  case '`':
		  case 'b':
		  	printf ( string );
		  	break;

		  case 'S':
		  case 'T':
		  case 'V':
		  case 'a':
			printf ( string, msg->param1 );
		  	break;

		  case 'W':
			printf ( string, msg->param1, msg->param2 );
		  	break;

		  default:
			printf ( string, och );
		  	break;
		}
		flushall();
	  	break;

	  case EXTRA_VERIFY_REASSIGN:
		while ( 1 )
		{
			printf ( string, msg->param1 );
			fgets ( str, 79, stdin);
			ch = str [ 0 ];
			if ( ch == 'y' )
				break;
			if ( ch == 'n' )
				return FALSE;
		}
	  	break;

	  case EXTRA_VERIFY_FINISHED:
	  	printf ( "LUN %d on Drive %d on board %d:\n",
				 msg->lun, msg->address, msg->board );
		switch ( ch )
		{
		  case 'D':
		  case 'H':
		  case 'I':
		  case 'J':
		  case 'K':
		  case 'L':
		  case 'M':
		  case 'N':
		  	printf ( string );
		  	break;

		  case 'F':
		  	printf ( string, &msg->messagestring [ 2 ] );
		  	break;

		  case 'G':
		  	printf ( string, msg->param1 );
		  	break;

		  case 'Q':
		  	printf ( string, msg->param1, msg->param2, msg->param3 );
			break;

		  default:
			printf ( string, och );
		  	break;
		}

		printf ( "OK\n" );
		fgets ( str, 79, stdin);
	  	break;

	  default:
	  	break;
	}

	return TRUE;
}
