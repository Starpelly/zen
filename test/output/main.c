#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>

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
#include <windows.h>

	/*
	void message_box(string text)
	{
		MessageBox(
			NULL,
			text,
			"Title",
			MB_OK | MB_ICONINFORMATION
		);
	}
	*/
#endif

// #include <raylib.h>

// --------------------------------------------------------------
// Enums
// --------------------------------------------------------------
typedef enum {
	Color_Red,
	Color_Orange,
	Color_Yellow,
	Color_Cyan
} Color;
// --------------------------------------------------------------
// Structs
// --------------------------------------------------------------
typedef struct {
	float x;
	float y;
} Vector2;
// --------------------------------------------------------------
// Constants
// --------------------------------------------------------------
// --------------------------------------------------------------
// Forward Declarations
// --------------------------------------------------------------
void main();
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
void main()
{
	Color color;
	color = Color_Red;
	float a = Color_Red;
	float b = "";
}