#include <zen.h>

typedef struct zen_Vector2;
typedef struct zen_Vector3;
typedef enum {
	zen_Color_Red,
	zen_Color_Orange,
	zen_Color_Yellow,
	zen_Color_Green,
	zen_Color_Blue,
	zen_Color_Purple
} zen_Color;
typedef enum {
	zen_tests_Color_Red,
	zen_tests_Color_Orange,
	zen_tests_Color_Yellow,
	zen_tests_Color_Cyan
} zen_tests_Color;
typedef struct zen_math_Hello;
void zen_main();
int zen_tests_add(int x, int y);
void zen_tests_abc();
void zen_tests_loop();
void zen_tests_prints();
void zen_tests_enums();
int zen_math_fibonacci(int n);
struct zen_Vector2 {
	float x;
	float y;
};
struct zen_Vector3 {
	float x;
	float y;
	float z;
};
struct zen_math_Hello {
};
void zen_main()
{
	int fib = zen_math_fibonacci(10);
	int x = zen_tests_add(1, 1);
	printf("%i\n", fib);
	int i = 50;
	while (i > 10)
	{
		i = i - 1;
	}
	printf("%s\n", "Hello");
}
int zen_tests_add(int x, int y)
{
	return x + y;
}
void zen_tests_abc()
{
	int a = zen_tests_add(1, 1);
	int b = a + a;
	int c = a + b;
	printf("%i", c);
}
void zen_tests_loop()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%s", "welcome to zen!");
	}
}
void zen_tests_prints()
{
	int val_int = 1;
	float val_float = 1.0f;
	bool val_bool = false;
	printf("%i\n", val_int);
	printf("%f\n", val_float);
	printf("%s\n", val_bool  ? "true" : "false");
}
void zen_tests_enums()
{
	zen_tests_Color color;
	color = zen_tests_Color_Red;
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

void main()
{
	zen_main();
}