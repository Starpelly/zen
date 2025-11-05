#include <zen.h>

void zen_main();
void zen_main()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%i\n", i);
	}
}

void main()
{
	zen_main();
}