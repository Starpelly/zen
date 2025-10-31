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
int add(int x, int y);
void abc_test();
void loop_test();
void print_test();
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
void main()
{
	Vector2 vec2;
	vec2.x = 4.0f;
	vec2.y = 2.0f;
	printf("%f\n", vec2.y);
	printf("%s\n", "Hello world!");
	print_test();
}
int add(int x, int y)
{
	return x + y;
}
void abc_test()
{
	int a = add(1, 1);
	int b = a + a;
	int c = a + b;
	printf("%i", c);
}
void loop_test()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%s", "welcome to zen!");
	}
}
void print_test()
{
	int val_int = 1;
	float val_float = 1.0f;
	bool val_bool = false;
	printf("%i\n", val_int);
	printf("%f\n", val_float);
	printf("%s\n", val_bool  ? "true" : "false");
}