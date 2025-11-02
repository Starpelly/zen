#include <zen.h>

typedef struct zen_Vector2I zen_Vector2I;
typedef struct zen_Player zen_Player;
void zen_main();
void zen_draw_game();
struct zen_Vector2I {
	int x;
	int y;
};
struct zen_Player {
	zen_Vector2I pos;
};
zen_Player player = {};
void zen_main()
{
	for (int i = 0; i < 10; i = i + 1)
	{
		printf("%i\n", i);
	}
	InitWindow(1280, 720, "Zen");
	SetTargetFPS(60);
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
		zen_draw_game();
		EndDrawing();
	}
	CloseWindow();
}
void zen_draw_game()
{
	player.pos.x = GetMouseX();
	Color color;
	color.r = 255;
	color.g = 255;
	color.b = 0;
	color.a = 255;
	if (IsKeyDown(32))
	{
		color.r = 0;
		player.pos.y += 1;
		printf("%s\n", "space key!");
	}
	DrawRectangle(player.pos.x, player.pos.y, 32, 32, color);
}

void main()
{
	zen_main();
}