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
	CZEN_tests_Color_Red,
	CZEN_tests_Color_Orange,
	CZEN_tests_Color_Yellow,
	CZEN_tests_Color_Cyan
} CZEN_tests_Color;
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
void CZEN_main();
int CZEN_tests_add(int x, int y);
void CZEN_tests_abc();
void CZEN_tests_loop();
void CZEN_tests_prints();
void CZEN_tests_enums();
int CZEN_math_fibonacci(int n);
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
void main()
{
	CZEN_main();
}
void CZEN_main()
{
	int fib = CZEN_math_fibonacci(10);
	int x = CZEN_tests_add(1, 1);
	printf("%i\n", fib);
}
int CZEN_tests_add(int x, int y)
{
	return x + y;
}
void CZEN_tests_abc()
{
	int a = add(1, 1);
	int b = a + a;
	int c = a + b;
	printf("%i", c);
}
void CZEN_tests_loop()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%s", "welcome to zen!");
	}
}
void CZEN_tests_prints()
{
	int val_int = 1;
	float val_float = 1.0f;
	bool val_bool = false;
	printf("%i\n", val_int);
	printf("%f\n", val_float);
	printf("%s\n", val_bool  ? "true" : "false");
}
void CZEN_tests_enums()
{
	Color color;
	color = CZEN_Color_Red;
}
int CZEN_math_fibonacci(int n)
{
	if (n <= 1)
	{
		return n;
	}
	int prev = 0;
	int result = 1;
	for (int i = 2; i <= n; i = i + 1)
	{
		int sum = result + prev;
		prev = result;
		result = sum;
	}
	return result;
}