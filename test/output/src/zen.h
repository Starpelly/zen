#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <math.h>

typedef char* string;

typedef unsigned long long 	uint64;
typedef unsigned int 		uint32;
typedef unsigned short		uint16;
typedef unsigned char		uint8;
typedef			 long long	int64;
typedef			 int		int32;
typedef			 short		int16;
typedef			 char		int8;
typedef			 float		float32;
typedef			 double		float64;

#if defined(_WIN32)
#define ZEN_PLATFORM_WINDOWS
	#ifdef _WIN64
		#define ZEN_X64
	#endif
#elif defined(__linux__)
	#define ZEN_PLATFORM_LINUX
#else
	#error "Unknown platform!"
#endif

#ifdef ZEN_PLATFORM_WINDOWS
// #include <windows.h>
#endif

#include <raylib.h>