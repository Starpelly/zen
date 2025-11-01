#include <zen.h>

typedef struct zen_Vector2 zen_Vector2;
typedef struct zen_Vector3 zen_Vector3;
typedef enum {
	zen_Color_Red,
	zen_Color_Orange,
	zen_Color_Yellow,
	zen_Color_Green,
	zen_Color_Blue,
	zen_Color_Purple
} zen_Color;
void zen_main();
int zen_math_fibonacci(int n);
int zen_math_fibonacci_recursive(int n);
struct zen_Vector2 {
	float x;
	float y;
};
struct zen_Vector3 {
	float x;
	float y;
	float z;
};
void zen_main()
{
	int fib = zen_math_fibonacci_recursive(10);
	printf("%i\n", fib);
	zen_Vector2 vec;
	vec.x = 0.0f;
	printf("%s\n", "Hello");
}
int zen_math_fibonacci(int n)
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
int zen_math_fibonacci_recursive(int n)
{
	if (n <= 1)
	{
		return n;
	}
	else
	{
		return zen_math_fibonacci_recursive(n - 1) + zen_math_fibonacci_recursive(n - 2);
	}
}

void main()
{
	zen_main();
}