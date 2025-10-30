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

// --------------------------------------------------------------
// Constants
// --------------------------------------------------------------
#define PI 3.141592653589793
#define TWO_PI 6.283185307179587
#define HALF_PI 1.570796326794897
#define EPSILON 0.00001
// --------------------------------------------------------------
// Forward Declarations
// --------------------------------------------------------------
static void main ();
static void test ();
static int fibonacci (int n);
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
static void main ()
{
	int fib = fibonacci(10);
	test();
	for (;;)
	{
	}
}
static void test ()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("hello!");
		printf("welcome to zen!");
	}
}
static int fibonacci (int n)
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