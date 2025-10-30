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
// --------------------------------------------------------------
// Forward Declarations
// --------------------------------------------------------------
static void main ();
static void print_tests ();
static int fibonacci (int n);
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
static void main ()
{
	int fib = fibonacci(10);
	print_tests();
	while (true)
	{
	}
	for (int i = 0; i < 20; i = i + 1)
	{
	}
}
static void print_tests ()
{
	int val_int = 1;
	float val_float = 1.0;
	bool val_bool = false;
	printf("%i", val_int );
	printf("%f\n", val_float );
	printf("%s\n", val_bool  ? "true" : "false");
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