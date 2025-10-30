#include <stdio.h>
#include <stdlib.h>

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
#define FIB_TEST 10
// --------------------------------------------------------------
// Forward Declarations
// --------------------------------------------------------------
static void main ();
static void test ();
static void print (string text);
static int fibonacci (int n);
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
static void main ()
{
	int fib = fibonacci(FIB_TEST);
}
static void test ()
{
	print("hello!");
}
static void print (string text)
{
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