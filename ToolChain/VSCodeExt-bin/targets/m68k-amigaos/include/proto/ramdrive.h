#ifndef _PROTO_RAMDRIVE_H
#define _PROTO_RAMDRIVE_H

#ifndef EXEC_TYPES_H
#include <exec/types.h>
#endif
#if !defined(CLIB_RAMDRIVE_PROTOS_H) && !defined(__GNUC__)
#include <clib/ramdrive_protos.h>
#endif

#ifndef __NOLIBBASE__
extern struct Library *RamdriveDevice;
#endif

#ifdef __GNUC__
#ifdef __AROS__
#include <defines/ramdrive.h>
#else
#include <inline/ramdrive.h>
#endif
#elif defined(__VBCC__)
#include <inline/ramdrive_protos.h>
#else
#include <pragma/ramdrive_lib.h>
#endif

#endif	/*  _PROTO_RAMDRIVE_H  */
