#include <zen.h>

typedef struct zen_PointerStruct zen_PointerStruct;
void zen_main();
void zen_print_x(zen_PointerStruct vec2);
struct zen_PointerStruct {
	float x;
	float y;
};
void zen_main()
{
	zen_PointerStruct a;
	a.x = 32.0f;
	a.y = 64.0f;
	zen_print_x(a);
}
void zen_print_x(zen_PointerStruct vec2)
{
	float x = vec2.x;
	printf("%f\n", x);
}

void main()
{
	zen_main();
}