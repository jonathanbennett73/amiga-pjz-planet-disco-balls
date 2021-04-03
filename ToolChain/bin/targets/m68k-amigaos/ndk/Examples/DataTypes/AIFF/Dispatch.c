/*
 * $Id: Dispatch.c 44.3 1999/03/12 19:02:25 olsen Exp olsen $
 *
 * :ts=4
 *
 * AIFF datatype
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
 */

#include "Data.h"

/****************************************************************************/

#define OK		(0)
#define NOT		!
#define CANNOT	!

/****************************************************************************/

#define IS_ODD(v) (((v) & 1) != 0)

/****************************************************************************/

	// The minimum sample rate we will allow when scaling a sound down

#define MIN_SAMPLE_RATE 5563

	// How many bytes to read in one piece

#define MIN_FRAME_RATE	(2048 * 8)

	// 80 bit SANE floating point number

typedef struct {
	unsigned short	exponent;			// Exponent, bit #15 is sign bit for mantissa
	unsigned long	mantissa[2];		// 64 bit mantissa
} extended;

	// Audio Interchange Format chunk data

#define ID_AIFF MAKE_ID('A', 'I', 'F', 'F')
#define ID_AIFC MAKE_ID('A', 'I', 'F', 'C')

#define ID_FVER MAKE_ID('F', 'V', 'E', 'R')
#define ID_COMM MAKE_ID('C', 'O', 'M', 'M')
#define ID_SSND MAKE_ID('S', 'S', 'N', 'D')

	// "COMM" chunk header

typedef struct {
	short			numChannels;		// Number of channels
	unsigned long	numSampleFrames;	// Number of sample frames
	short			sampleSize;			// Number of bits per sample point
	extended		sampleRate;			// Replay rate in samples per second
} CommonChunk;

	// The same for "AIFC" type files; this should be longer, but we don't
	// need the name of the compression format

typedef struct {
	short			numChannels;		// Number of channels
	unsigned long	numSampleFrames;	// Number of sample frames
	short			sampleSize;			// Number of bits per sample point
	extended		sampleRate;			// Replay rate in samples per second
	unsigned long	compressionType;	// Compression type
} ExtCommonChunk;

#define NO_COMPRESSION MAKE_ID('N', 'O', 'N', 'E') // No sound compression

	// "SSND" chunk header

typedef struct {
	unsigned long	offset,				// Offset to sound data, for block alignment
					blockSize;			// Size of block data is aligned to
} SampledSoundHeader;

	// "FVER" chunk header

typedef struct {
	long			timestamp;			// Format version creation date
} FormatVersionHeader;

#define AIFCVersion1 0xA2805140			// "AIFC" file format version #1

/****************************************************************************/

#define VOLUME_Unity 0x10000L		// Unity = Fixed 1.0 = maximum volume

/****************************************************************************/

	/* extended2long():
	 *
	 *	Convert an 80 bit SANE floating point number
	 *	into an integer value.
	 */

static long
extended2long(const extended *ex)
{
	unsigned long	mantissa;
	short			exponent;
	long			sign;

		// We only need 32 bits precision

	mantissa = ex->mantissa[0];

		// Is the mantissa positive or negative?

	exponent = ex->exponent;

	if(exponent & (1 << 15))
		sign = -1;
	else
		sign =	1;

		// Unbias the exponent (strip the sign bit; the
		// exponent is 15 bits wide)

	exponent = (exponent & ~(1 << 15)) - ((1 << 14) - 1);

		// If the exponent is negative, set the mantissa to zero.
		// We cannot represent integer values between 0 and 1.

	if(exponent < 0)
	{
		mantissa = 0;
	}
	else
	{
			// We used only the upper 32 bits of the mantissa,
			// which is what we have to make up for. Subtracting
			// 31 from the exponent is actually dividing by
			// 2^32.

		exponent -= 31;

			// If the exponent is not negative, then the value
			// the number represents will be larger than the
			// original 64 bits of the mantissa would hold.

		if(exponent > 0)
			mantissa = (1L << 31) - 1;	// == MAXINT
		else
			mantissa >>= -exponent;		// Keep the integer part of the number
	}

		// That's all...

	return(sign * (long)mantissa);
}

	/* ulong2extended():
	 *
	 *	Convert an unsigned integer value into an 80
	 *	bit SANE floating point number.
	 */

static void
ulong2extended(
	unsigned long	value,
	extended *		ex)
{
	ex->exponent = 31 + 16383;

	while((value & 0x80000000) == 0)
	{
		value <<= 1;

		ex->exponent--;
	}

	ex->mantissa[0] = value;
	ex->mantissa[1] = 0;
}

/****************************************************************************/

	/* WriteAIFF():
	 *
	 *	Store sound data in an AIFF format file.
	 */

STATIC LONG
WriteAIFF(
	struct ClassBase *	ClassBase,
	Object *			object,
	struct dtWrite *	msg)
{
	BYTE * twoChannelBuffer = NULL;
	struct VoiceHeader * vh = NULL;
	BYTE * sample = NULL;
	BYTE * sampleLeft = NULL;
	BYTE * sampleRight = NULL;
	ULONG sampleLength = 0;
	LONG numChannels;
	struct IFFHandle * handle;
	SampledSoundHeader sampleHeader;
	CommonChunk common;
	LONG error;

	handle = AllocIFF();
	if(handle == NULL)
	{
		error = ERROR_NO_FREE_STORE;
		goto out;
	}

	handle->iff_Stream = (ULONG)msg->dtw_FileHandle;
	if(handle->iff_Stream == NULL)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}

	GetDTAttrs(object,
		SDTA_VoiceHeader,	&vh,
		SDTA_Sample,		&sample,
		SDTA_LeftSample,	&sampleLeft,
		SDTA_RightSample,	&sampleRight,
		SDTA_SampleLength,	&sampleLength,
	TAG_DONE);

	if(vh == NULL ||
	   vh->vh_SamplesPerSec == 0 ||
	   (sample == NULL && sampleLeft == NULL && sampleRight == NULL) ||
	   sampleLength == 0)
	{
		error = ERROR_REQUIRED_ARG_MISSING;
		goto out;
	}
	
	InitIFFasDOS(handle);

	error = OpenIFF(handle, IFFF_WRITE);
	if(error != OK)
		goto out;

	if(sample != NULL)
	{
		sampleLeft	= sample;
		sampleRight	= NULL;
	}
	else
	{
		if(sampleLeft == NULL && sampleRight != NULL)
		{
			sampleLeft	= sampleRight;
			sampleRight	= NULL;
		}
	}

	if(sampleLeft != NULL && sampleRight != NULL)
		numChannels = 2;
	else
		numChannels = 1;

	if(numChannels == 2)
	{
		BYTE * b;
		LONG i;

		twoChannelBuffer = AllocVec(2 * sampleLength,MEMF_ANY);
		if(twoChannelBuffer == NULL)
		{
			error = ERROR_NO_FREE_STORE;
			goto out;
		}

		b = twoChannelBuffer;

		for(i = 0 ; i < sampleLength ; i++)
		{
			(*b++) = (*sampleLeft++);
			(*b++) = (*sampleRight++);
		}
	}

	error = PushChunk(handle, ID_AIFF, ID_FORM, IFFSIZE_UNKNOWN);
	if(error != OK)
		goto out;

	error = PushChunk(handle, 0, ID_COMM, sizeof(CommonChunk));
	if(error != OK)
		goto out;

	memset(&common,0,sizeof(common));

	common.numChannels		= numChannels;
	common.numSampleFrames	= sampleLength;
	common.sampleSize		= 8;

	ulong2extended(vh->vh_SamplesPerSec, &common.sampleRate);

	error = WriteChunkBytes(handle, &common, sizeof(common));
	if(error < 0)
		goto out;

	error = PopChunk(handle);
	if(error != OK)
		goto out;

	error = PushChunk(handle, 0, ID_SSND, sizeof(sampleHeader) + numChannels * sampleLength);
	if(error != OK)
		goto out;

	memset(&sampleHeader,0,sizeof(sampleHeader));

	error = WriteChunkBytes(handle, &sampleHeader, sizeof(sampleHeader));
	if(error < 0)
		goto out;

	if(numChannels == 2)
		error = WriteChunkBytes(handle, twoChannelBuffer, numChannels * sampleLength);
	else
		error = WriteChunkBytes(handle, sample, sampleLength);

	if(error < 0)
		goto out;

	error = PopChunk(handle);
	if(error != OK)
		goto out;

	error = PopChunk(handle);
	if(error != OK)
		goto out;

 out:

	if(handle != NULL)
	{
		CloseIFF(handle);
		FreeIFF(handle);
	}

	FreeVec(twoChannelBuffer);

	return(error);
}

/****************************************************************************/

	/* Flatten():
	 *
	 *	Flatten the "AIFF"/"AIFC" sound data, i.e. blend all the channels
	 *	into a single monophonic chunk and crop the data to eight bits per
	 *	sample.
	 */

STATIC VOID
Flatten(
	UBYTE *	Src,			// Sample data
	LONG	BytesPerPoint,	// Number of bytes that make up a single sample
	LONG	NumChannels,	// Number of channels in this sample data
	LONG	NumFrames,		// Number of sample frames in this sample data
	LONG	SamplesToBlend,	// Number of samples to blend into a single sample
	BYTE *	DstLeft,		// Where to store the processed data (left channel)
	BYTE *	DstRight)		// Where to store the processed data (left channel)
{
	LONG Value;
	LONG SamplesBlended;
	LONG FrameIndex;
	LONG MidIndex,RightIndex;
	LONG LeftSum,RightSum;
	LONG SamplesPerChannel;
	LONG i,j;

	if(IS_ODD(NumChannels))
	{
		MidIndex			= NumChannels / 2;
		RightIndex			= MidIndex+1;
		SamplesPerChannel	= (NumChannels / 2) + 1;
	}
	else
	{
		MidIndex			= -1;
		RightIndex			= NumChannels / 2;
		SamplesPerChannel	= NumChannels / 2;
	}

		// Convert all the frames if possible

	SamplesBlended = 0;

	for(FrameIndex = 0 ; FrameIndex < NumFrames ; FrameIndex++)
	{
			// Add up the channel data

		LeftSum = RightSum = 0;

		for(i = 0; i < NumChannels ; i++)
		{
				// The audio data is always stored left adjusted.

			Value = 0;

			for(j = 0 ; j < BytesPerPoint ; j++)
				Value |= (LONG)Src[j] << ((3 - j) * 8);

				// Move up to the next sample

			Src += BytesPerPoint;

				// Add the new sample, 16 bits only

			Value /= (1L << 16);

			if(i == MidIndex)
			{
				LeftSum		+= Value;
				RightSum	+= Value;
			}
			else if (i < RightIndex)
			{
				LeftSum += Value;
			}
			else
			{
				RightSum += Value;
			}
		}

			// We store this sample value if it is the
			// very first one or if enough samples
			// have been merged already. Note that
			// SamplesToBlend > 0.

		SamplesBlended++;
		if(SamplesBlended == SamplesToBlend || FrameIndex == 0)
		{
				// Calculate the monophonic sample data and
				// crop it to eight bits

			if(DstRight != NULL)
			{
				LeftSum		= (LeftSum	/ SamplesPerChannel) / (1L << 8);
				RightSum	= (RightSum	/ SamplesPerChannel) / (1L << 8);

					// Make sure that the values are in range
	
				if(LeftSum < -128)
					LeftSum = -128;
				else if(LeftSum > 127)
					LeftSum = 127;

				if(RightSum < -128)
					RightSum = -128;
				else if(RightSum > 127)
					RightSum = 127;

					// Keep these samples

				(*DstLeft++)	= (BYTE)LeftSum;
				(*DstRight++)	= (BYTE)RightSum;
			}
			else
			{
				LeftSum = ((LeftSum + RightSum) / (NumChannels * 2)) / (1L << 8);

					// Make sure that the value is in range
	
				if(LeftSum < -128)
					LeftSum = -128;
				else if(LeftSum > 127)
					LeftSum = 127;

					// Keep this sample

				(*DstLeft++) = (BYTE)LeftSum;
			}

				// Blend the next samples if necessary

			SamplesBlended = 0;
		}
	}
}

	/* ConvertAIFF():
	 *
	 *	Convert "AIFF"/"AIFC" audio data into plain 8 bit audio data.
	 */

STATIC LONG
ConvertAIFF(
	struct ClassBase *		ClassBase,
	struct IFFHandle *		IFFHandle,
	ULONG					MemFlags,
	LONG					MaxChannels,
	BYTE **					LeftSamplePtr,
	BYTE **					RightSamplePtr,
	LONG *					NumChannelsPtr,
	struct VoiceHeader *	VoiceHeader)
{
	STATIC const LONG Stops[] =
	{
		ID_AIFF, ID_COMM,	// AIFF chunks
		ID_AIFF, ID_SSND,

		ID_AIFC, ID_FVER,	// AIFC chunks
		ID_AIFC, ID_COMM,
		ID_AIFC, ID_SSND
	};

	UBYTE * SrcBuffer = NULL;
	BYTE * LeftSample = NULL;
	BYTE * RightSample = NULL;
	LONG Error;

		// There are only two/three mandatory chunks to look for

	Error = StopChunks(IFFHandle, (LONG *) Stops, sizeof(Stops) / (sizeof(Stops[0]) * 2));
	if(Error == OK)
	{
		LONG SrcFrames = 0;
		LONG DstFrames = 0;
		LONG DstRate = 0;
		LONG DstSkip = 0;
		LONG Size;
		FormatVersionHeader FormatHeader;
		SampledSoundHeader SampleHeader;
		LONG SrcBufferSize = 0;
		LONG MaxSampleRate;
		ExtCommonChunk Common;
		struct ContextNode * Chunk;
		LONG BytesPerPoint = 0;
		LONG Status;
		BOOL Done;

		memset(&Common,0,sizeof(Common));

		Done = FALSE;

		while(NOT Done && (Error = ParseIFF(IFFHandle, IFFPARSE_SCAN)) == OK)
		{
			Chunk = CurrentChunk(IFFHandle);

			switch(Chunk->cn_ID)
			{
					// This is the file format version ID

				case ID_FVER:

					Status = ReadChunkBytes(IFFHandle, &FormatHeader, sizeof(FormatHeader));
					if(Status != sizeof(FormatHeader))
					{
						Error = Status;

						break;
					}

						// Does this reader support this format?

					if(FormatHeader.timestamp != AIFCVersion1)
					{
						Error = ERROR_NOT_IMPLEMENTED;

						break;
					}

					break;

					// This chunk is common for all "AIFF" variants

				case ID_COMM:

						// Determine how many bytes to read

					if(Chunk->cn_Type == ID_AIFF)
						Size = sizeof(CommonChunk);
					else
						Size = sizeof(ExtCommonChunk);

					Status = ReadChunkBytes(IFFHandle, &Common, Size);
					if(Status != Size)
					{
						Error = Status;

						break;
					}

						// Is this a compressed "AIFC" file?

					if(Chunk->cn_Type == ID_AIFC && Common.compressionType != NO_COMPRESSION)
					{
						Error = DTERROR_UNKNOWN_COMPRESSION;

						break;
					}

						// Keep the basic data

					DstFrames	= Common.numSampleFrames;
					DstRate		= extended2long(&Common.sampleRate);
					DstSkip		= 1;

						// The current Amiga audio hardware has a fixed
						// replay speed limit. We will compensate for it
						// by cropping the audio data if necessary.

					MaxSampleRate = (SysBase->ex_EClockFrequency * 5) / 124;
					while(DstRate > MaxSampleRate)
					{
						DstFrames = (DstFrames + 1) / 2;

						DstRate	/= 2;
						DstSkip	*= 2;
					}

						// See how many bytes make up one sample point

					BytesPerPoint = (Common.sampleSize + 7) / 8;

						// Just to be sure we accept multiple "COMM" chunks

					FreeVec(SrcBuffer);

					FreeVec(LeftSample);
					LeftSample = NULL;

					FreeVec(RightSample);
					RightSample = NULL;

						// Don't waste too much memory for loading

					if(Common.numSampleFrames < MIN_FRAME_RATE)
						SrcFrames = Common.numSampleFrames;
					else
						SrcFrames = MIN_FRAME_RATE;

						// Allocate the decoding buffer

					SrcBufferSize = BytesPerPoint * Common.numChannels * SrcFrames;

					SrcBuffer = AllocVec(SrcBufferSize, MEMF_ANY);
					if(SrcBuffer == NULL)
					{
						Error = ERROR_NO_FREE_STORE;
						break;
					}

					if(Common.numChannels > 1 && MaxChannels == 2)
					{
						LeftSample	= AllocVec(DstFrames, MemFlags | MEMF_CLEAR);
						RightSample	= AllocVec(DstFrames, MemFlags | MEMF_CLEAR);

						if(LeftSample == NULL || RightSample == NULL)
						{
							Error = ERROR_NO_FREE_STORE;
							break;
						}
					}
					else
					{
						LeftSample = AllocVec(DstFrames, MemFlags | MEMF_CLEAR);
						if(LeftSample == NULL)
						{
							Error = ERROR_NO_FREE_STORE;
							break;
						}
					}

					break;

					// Here follows the sampled sound; this chunk is somewhat
					// equivalent to the "8SVX"/"BODY" chunk.

				case ID_SSND:

						// Sanity check

					if(SrcBufferSize == 0 || SrcBuffer == NULL)
					{
						Error = IFFERR_MANGLED;
						break;
					}

						// Read the data header

					Status = ReadChunkBytes(IFFHandle, &SampleHeader, sizeof(SampleHeader));
					if(Status != sizeof(SampleHeader))
					{
						Error = Status;
					}
					else
					{
							// Is the data block aligned?

						if(SampleHeader.offset)
						{
							LONG Needed = SampleHeader.offset, Skip;

								// Skip the padding data

							while(Needed > 0)
							{
								if(SrcBufferSize > Needed)
									Skip = Needed;
								else
									Skip = SrcBufferSize;

								Status = ReadChunkBytes(IFFHandle, SrcBuffer, Skip);
								if(Status != Skip)
								{
									Error = Status;
									break;
								}
								else
								{
									Needed -= Skip;
								}
							}
						}

						if(Error == OK)
						{
							LONG FrameSize, TotalFrames, Frames;
							BYTE * Left = LeftSample;
							BYTE * Right = RightSample;

							FrameSize	= BytesPerPoint * Common.numChannels;
							TotalFrames	= Common.numSampleFrames;

								// Initialize the voice header

							memset(VoiceHeader, 0, sizeof(struct VoiceHeader));

							VoiceHeader->vh_OneShotHiSamples	= DstFrames;
							VoiceHeader->vh_SamplesPerSec		= DstRate;
							VoiceHeader->vh_Octaves				= 1;
							VoiceHeader->vh_Compression			= CMP_NONE;
							VoiceHeader->vh_Volume				= VOLUME_Unity;

								// Read the audio data frame by frame

							while(TotalFrames > 0)
							{
								if(SrcFrames > TotalFrames)
									Frames = TotalFrames;
								else
									Frames = SrcFrames;

								Status = ReadChunkRecords(IFFHandle, SrcBuffer, FrameSize, Frames);
								if(Status != Frames)
								{
									Error = Status;

									break;
								}
								else
								{
									Flatten(SrcBuffer, BytesPerPoint, Common.numChannels, Frames, DstSkip, Left, Right);

									if(Left != NULL)
										Left += Frames / DstSkip;

									if(Right != NULL)
										Right += Frames / DstSkip;

									TotalFrames -= Frames;
								}
							}

							Done = TRUE;
						}
					}

					break;
			}

			if(Error != OK)
				break;
		}

		if(Done && Error == IFFERR_EOF)
			Error = OK;
	}

		// Clean up...

	FreeVec(SrcBuffer);

	if(Error != OK)
	{
		FreeVec(LeftSample);
		LeftSample = NULL;

		FreeVec(RightSample);
		RightSample = NULL;
	}

	(*LeftSamplePtr) = LeftSample;
	(*RightSamplePtr) = RightSample;

	return(Error);
}

	/* GetAIFF(Object *object, struct TagItem *Tags, struct ClassBase *ClassBase):
	 *
	 *	Create a datatypes object from an "AIFF"/"AIFC" file suitable for
	 *	MultiView, etc. to display or replay.
	 */

STATIC LONG
GetAIFF(
	struct ClassBase *	ClassBase,
	Object *			object,
	struct TagItem *	Tags)
{
	struct VoiceHeader *	VoiceHeader = NULL;
	struct IFFHandle *		Handle = NULL;
	LONG					SourceType = -1;
	LONG					Error;
	STRPTR					FileName;

	/* Get the object data */
	FileName = (STRPTR)GetTagData(DTA_Name, (ULONG)"Untitled", Tags);

	GetDTAttrs(object,
		SDTA_VoiceHeader,	&VoiceHeader,
		DTA_Handle,			&Handle,
		DTA_SourceType,		&SourceType,
	TAG_DONE);

	/* Do we have everything we need? */
	if(VoiceHeader != NULL && Handle != NULL && (SourceType == DTST_FILE || SourceType == DTST_CLIPBOARD))
	{
		BYTE *	LeftSample	= NULL;
		BYTE *	RightSample	= NULL;
		LONG	NumChannels;
		LONG	MaxChannels;
		ULONG	MemFlags;

		/* sound.datatype v40 no longer requires
		 * the entire sample to reside in chip memory
		 */
		if(SuperClassBase->lib_Version >= 40)
			MemFlags = MEMF_ANY;
		else
			MemFlags = MEMF_CHIP;

		/* sound.datatype V44 allows up to two stereo channels
		 * to be used.
		 */
		if(SuperClassBase->lib_Version >= 44)
			MaxChannels = 2;
		else
			MaxChannels = 1;

		/* Convert the audio file. */
		Error = ConvertAIFF(ClassBase, Handle, MemFlags, MaxChannels, &LeftSample, &RightSample, &NumChannels, VoiceHeader);
		if(Error == OK)
		{
			BYTE * Sample = NULL;

			if(LeftSample == NULL || RightSample == NULL)
			{
				if(LeftSample != NULL)
					Sample = LeftSample;
				else
					Sample = RightSample;
			}

			/* Fill in the remaining information. */
			SetDTAttrs(object, NULL, NULL,
				DTA_ObjName,		FilePart(FileName),
				SDTA_Sample,		Sample,
				SDTA_LeftSample,	LeftSample,
				SDTA_RightSample,	RightSample,
				SDTA_SampleLength,	VoiceHeader->vh_OneShotHiSamples,
				SDTA_Period,		(ULONG)(SysBase->ex_EClockFrequency * 5) / (ULONG)VoiceHeader->vh_SamplesPerSec,
				SDTA_Volume,		64,
				SDTA_Cycles,		1,
			TAG_DONE);
		}
	}
	else
	{
		Error = ERROR_OBJECT_NOT_FOUND;
	}

	return(Error);
}

	/* ClassDispatch():
	 *
	 *	The class dispatcher routine.
	 */

STATIC ULONG ASM
ClassDispatch(
	REG(a0) Class *		class,
	REG(a2) Object *	object,
	REG(a1) Msg			msg)
{
	struct ClassBase *	ClassBase;
	ULONG				Result;

	ClassBase = (struct ClassBase *)class->cl_UserData;

		// What message is it?

	switch(msg->MethodID)
	{
			// Create a new instance

		case OM_NEW:

			Result = (ULONG)DoSuperMethodA(class, object, msg);
			if(Result != NULL)
			{
				LONG error;

				error = GetAIFF(ClassBase, (Object *)Result, ((struct opSet *)msg)->ops_AttrList);
				if(error != OK)
				{
					CoerceMethod(class, (Object *)Result, OM_DISPOSE);

					Result = NULL;

					SetIoErr(error);
				}
			}

			break;

			// Store object data

		case DTM_WRITE:

				// Check whether we should store the data in our
				// native file format.

			if(((struct dtWrite *)msg)->dtw_Mode == DTWM_RAW)
			{
				LONG error;

				error = WriteAIFF(ClassBase, object, (struct dtWrite *)msg);
				if(error == OK)
				{
					Result = TRUE;
				}
				else
				{
					SetIoErr(error);

					Result = FALSE;
				}

				break;
			}
			// Falls through to...

			// Let the superclass handle the rest

		default:

			Result = (ULONG)DoSuperMethodA(class, object, msg);
			break;
	}

	return(Result);
}

/****************************************************************************/

	/* CreateClass(struct ClassBase *ClassBase):
	 *
	 *	Create the new class and make it public.
	 */

BOOL
CreateClass(struct ClassBase *ClassBase)
{
	BOOL Result = FALSE;

		// We need the super class for version checking

	SuperClassBase = OpenLibrary("datatypes/sound.datatype", 39);
	if(SuperClassBase != NULL)
	{
			// Create the new class

		SoundClass = MakeClass(ClassBase->LibNode.lib_Node.ln_Name,
		                       SOUNDDTCLASS, NULL, 0, NULL);

		if(SoundClass != NULL)
		{
			Result = TRUE;

				// Link the class dispatcher into it
				// and keep a pointer to the library
				// base

			SoundClass->cl_Dispatcher.h_Entry	= (HOOKFUNC)ClassDispatch;
			SoundClass->cl_UserData				= (ULONG)ClassBase;

				// Make the class publicly available

			AddClass(SoundClass);
		}
		else
		{
			CloseLibrary(SuperClassBase);
			SuperClassBase = NULL;
		}
	}

	return(Result);
}

	/* GetClassPointer(struct ClassBase *ClassBase):
	 *
	 *	Return a pointer to the class base this
	 *	library implements.
	 */

Class *
GetClassPointer(struct ClassBase *ClassBase)
{
	return(SoundClass);
}

	/* AttemptFreeClass(struct ClassBase *ClassBase):
	 *
	 *	Try to remove the class from the public list.
	 *	Note that when this function is called, it
	 *	should always succeed. If it does not, a user
	 *	of this class must have made a programming error.
	 */

BOOL
AttemptFreeClass(struct ClassBase *ClassBase)
{
	BOOL Result = TRUE;

		// This routine will return success even
		// if the class has already been removed.

	if(SoundClass != NULL)
	{
			// Attempt to remove the class from
			// the public list.

		if(CANNOT FreeClass(SoundClass))
		{
			Result = FALSE;
		}
		else
		{
			SoundClass = NULL;

			CloseLibrary(SuperClassBase);
			SuperClassBase = NULL;
		}
	}

	return(Result);
}
