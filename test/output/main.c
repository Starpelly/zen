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
static int add (int x, int y);
static void abc_test ();
static void loop_test ();
static void print_test ();
static int fibonacci (int n);
// --------------------------------------------------------------
// Functions
// --------------------------------------------------------------
static void main ()
{
	int fib = fibonacci(10);
	printf("%s\n", "Hello world!");
	print_test();
	while (true)
	{
	}
	for (int i = 0; i < 20; i = i + 1)
	{
	}
}
static int add (int x, int y)
{
	return x + y;
}
static void abc_test ()
{
	int a = add(1, 1);
	int b = a + a;
	int c = a + b;
	printf("%i", c);
}
static void loop_test ()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%s", "welcome to zen!");
	}
}
static void print_test ()
{
	int val_int = 1;
	float val_float = 1.0;
	bool val_bool = false;
	printf("%i\n", val_int);
	printf("%f\n", val_float);
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