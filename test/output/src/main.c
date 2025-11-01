#include <zen.h>

typedef struct zen_Vector2I zen_Vector2I;
void zen_main();
struct zen_Vector2I {
	int x;
	int y;
};
void zen_main()
{
	InitWindow(1280, 720, "Zen");
	zen_Vector2I playerPos = {};
	while (WindowShouldClose() == false)
	{
		BeginDrawing();
		Color black;
		black.r = 0;
		black.g = 0;
		black.b = 0;
		black.a = 255;
		ClearBackground(black);
		DrawFPS(20, 20);
		playerPos.x = GetMouseX();
		playerPos.y = GetMouseY();
		Color color;
		color.r = 255;
		color.g = 255;
		color.b = 0;
		color.a = 255;
		DrawRectangle(playerPos.x, playerPos.y, 32, 32, color);
		EndDrawing();
	}
	CloseWindow();
}

void main()
{
	zen_main();
}