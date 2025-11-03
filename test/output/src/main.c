#include <zen.h>

typedef struct zen_game_GameManager zen_game_GameManager;
typedef struct zen_game_Player zen_game_Player;
typedef enum {
	zen_raylib_KeyboardKey_NULL = 0,
	zen_raylib_KeyboardKey_APOSTROPHE = 39,
	zen_raylib_KeyboardKey_COMMA = 44,
	zen_raylib_KeyboardKey_MINUS = 45,
	zen_raylib_KeyboardKey_PERIOD = 46,
	zen_raylib_KeyboardKey_SLASH = 47,
	zen_raylib_KeyboardKey_ZERO = 48,
	zen_raylib_KeyboardKey_ONE = 49,
	zen_raylib_KeyboardKey_TWO = 50,
	zen_raylib_KeyboardKey_THREE = 51,
	zen_raylib_KeyboardKey_FOUR = 52,
	zen_raylib_KeyboardKey_FIVE = 53,
	zen_raylib_KeyboardKey_SIX = 54,
	zen_raylib_KeyboardKey_SEVEN = 55,
	zen_raylib_KeyboardKey_EIGHT = 56,
	zen_raylib_KeyboardKey_NINE = 57,
	zen_raylib_KeyboardKey_SEMICOLON = 59,
	zen_raylib_KeyboardKey_EQUAL = 61,
	zen_raylib_KeyboardKey_A = 65,
	zen_raylib_KeyboardKey_B = 66,
	zen_raylib_KeyboardKey_C = 67,
	zen_raylib_KeyboardKey_D = 68,
	zen_raylib_KeyboardKey_E = 69,
	zen_raylib_KeyboardKey_F = 70,
	zen_raylib_KeyboardKey_G = 71,
	zen_raylib_KeyboardKey_H = 72,
	zen_raylib_KeyboardKey_I = 73,
	zen_raylib_KeyboardKey_J = 74,
	zen_raylib_KeyboardKey_K = 75,
	zen_raylib_KeyboardKey_L = 76,
	zen_raylib_KeyboardKey_M = 77,
	zen_raylib_KeyboardKey_N = 78,
	zen_raylib_KeyboardKey_O = 79,
	zen_raylib_KeyboardKey_P = 80,
	zen_raylib_KeyboardKey_Q = 81,
	zen_raylib_KeyboardKey_R = 82,
	zen_raylib_KeyboardKey_S = 83,
	zen_raylib_KeyboardKey_T = 84,
	zen_raylib_KeyboardKey_U = 85,
	zen_raylib_KeyboardKey_V = 86,
	zen_raylib_KeyboardKey_W = 87,
	zen_raylib_KeyboardKey_X = 88,
	zen_raylib_KeyboardKey_Y = 89,
	zen_raylib_KeyboardKey_Z = 90,
	zen_raylib_KeyboardKey_LEFT_BRACKET = 91,
	zen_raylib_KeyboardKey_BACKSLASH = 92,
	zen_raylib_KeyboardKey_RIGHT_BRACKET = 93,
	zen_raylib_KeyboardKey_GRAVE = 96,
	zen_raylib_KeyboardKey_SPACE = 32,
	zen_raylib_KeyboardKey_ESCAPE = 256,
	zen_raylib_KeyboardKey_ENTER = 257,
	zen_raylib_KeyboardKey_TAB = 258,
	zen_raylib_KeyboardKey_BACKSPACE = 259,
	zen_raylib_KeyboardKey_INSERT = 260,
	zen_raylib_KeyboardKey_DELETE = 261,
	zen_raylib_KeyboardKey_RIGHT = 262,
	zen_raylib_KeyboardKey_LEFT = 263,
	zen_raylib_KeyboardKey_DOWN = 264,
	zen_raylib_KeyboardKey_UP = 265,
	zen_raylib_KeyboardKey_PAGE_UP = 266,
	zen_raylib_KeyboardKey_PAGE_DOWN = 267,
	zen_raylib_KeyboardKey_HOME = 268,
	zen_raylib_KeyboardKey_END = 269,
	zen_raylib_KeyboardKey_CAPS_LOCK = 280,
	zen_raylib_KeyboardKey_SCROLL_LOCK = 281,
	zen_raylib_KeyboardKey_NUM_LOCK = 282,
	zen_raylib_KeyboardKey_PRINT_SCREEN = 283,
	zen_raylib_KeyboardKey_PAUSE = 284,
	zen_raylib_KeyboardKey_F1 = 290,
	zen_raylib_KeyboardKey_F2 = 291,
	zen_raylib_KeyboardKey_F3 = 292,
	zen_raylib_KeyboardKey_F4 = 293,
	zen_raylib_KeyboardKey_F5 = 294,
	zen_raylib_KeyboardKey_F6 = 295,
	zen_raylib_KeyboardKey_F7 = 296,
	zen_raylib_KeyboardKey_F8 = 297,
	zen_raylib_KeyboardKey_F9 = 298,
	zen_raylib_KeyboardKey_F10 = 299,
	zen_raylib_KeyboardKey_F11 = 300,
	zen_raylib_KeyboardKey_F12 = 301,
	zen_raylib_KeyboardKey_LEFT_SHIFT = 340,
	zen_raylib_KeyboardKey_LEFT_CONTROL = 341,
	zen_raylib_KeyboardKey_LEFT_ALT = 342,
	zen_raylib_KeyboardKey_LEFT_SUPER = 343,
	zen_raylib_KeyboardKey_RIGHT_SHIFT = 344,
	zen_raylib_KeyboardKey_RIGHT_CONTROL = 345,
	zen_raylib_KeyboardKey_RIGHT_ALT = 346,
	zen_raylib_KeyboardKey_RIGHT_SUPER = 347,
	zen_raylib_KeyboardKey_KB_MENU = 348,
	zen_raylib_KeyboardKey_KP_0 = 320,
	zen_raylib_KeyboardKey_KP_1 = 321,
	zen_raylib_KeyboardKey_KP_2 = 322,
	zen_raylib_KeyboardKey_KP_3 = 323,
	zen_raylib_KeyboardKey_KP_4 = 324,
	zen_raylib_KeyboardKey_KP_5 = 325,
	zen_raylib_KeyboardKey_KP_6 = 326,
	zen_raylib_KeyboardKey_KP_7 = 327,
	zen_raylib_KeyboardKey_KP_8 = 328,
	zen_raylib_KeyboardKey_KP_9 = 329,
	zen_raylib_KeyboardKey_KP_DECIMAL = 330,
	zen_raylib_KeyboardKey_KP_DIVIDE = 331,
	zen_raylib_KeyboardKey_KP_MULTIPLY = 332,
	zen_raylib_KeyboardKey_KP_SUBTRACT = 333,
	zen_raylib_KeyboardKey_KP_ADD = 334,
	zen_raylib_KeyboardKey_KP_ENTER = 335,
	zen_raylib_KeyboardKey_KP_EQUAL = 336,
	zen_raylib_KeyboardKey_BACK = 4,
	zen_raylib_KeyboardKey_MENU = 82,
	zen_raylib_KeyboardKey_VOLUME_UP = 24,
	zen_raylib_KeyboardKey_VOLUME_DOWN = 25
} zen_raylib_KeyboardKey;
void zen_main();
void zen_game_start_game();
void zen_game_update_game(zen_game_GameManager* gameManager);
void zen_game_draw_game(zen_game_GameManager* gameManager);
#define PLAYER_SPEED 500.0f
void zen_game_init_player(zen_game_Player* player);
void zen_game_update_player(zen_game_Player* player);
void zen_game_draw_player(zen_game_Player* player);
#define PI 3.14159265358979323846f
#define HALF_PI 1.57079632679489661923f
#define EPSILON 0.00001f
struct zen_game_GameManager {
	zen_game_Player* player;
	int frame;
	float time;
};
struct zen_game_Player {
	Vector2 pos;
	Color color;
};
void zen_main()
{
	zen_game_start_game();
}
void zen_game_start_game()
{
	Color black = {};
	black.r = 0;
	black.g = 0;
	black.b = 0;
	black.a = 255;
	InitWindow(1280, 720, "Zen");
	SetTargetFPS(60);
	zen_game_GameManager gameManager = {};
	zen_game_Player player = {};
	gameManager.player = &player;
	zen_game_init_player(gameManager.player);
	while (!WindowShouldClose())
	{
		zen_game_update_game(&gameManager);
		BeginDrawing();
		ClearBackground(black);
		zen_game_draw_game(&gameManager);
		DrawFPS(20, 20);
		EndDrawing();
	}
	CloseWindow();
}
void zen_game_update_game(zen_game_GameManager* gameManager)
{
	gameManager->frame += 1;
	gameManager->time += GetFrameTime();
	zen_game_update_player(gameManager->player);
}
void zen_game_draw_game(zen_game_GameManager* gameManager)
{
	zen_game_draw_player(gameManager->player);
	float sinx = sinf(gameManager->time * 8.0f) * 44.0f;
	float siny = cosf(gameManager->time * 8.0f) * 44.0f;
	DrawCircle((int)sinx + 400, (int)siny + 400, 32, gameManager->player->color);
	printf("%f\n", sinx);
}
void zen_game_init_player(zen_game_Player* player)
{
	player->color.r = 255;
	player->color.g = 255;
	player->color.b = 0;
	player->color.a = 255;
}
void zen_game_update_player(zen_game_Player* player)
{
	if (IsKeyDown(zen_raylib_KeyboardKey_LEFT))
	{
		player->pos.x -= PLAYER_SPEED * GetFrameTime();
	}
	if (IsKeyDown(zen_raylib_KeyboardKey_RIGHT))
	{
		player->pos.x += PLAYER_SPEED * GetFrameTime();
	}
	if (IsKeyDown(zen_raylib_KeyboardKey_UP))
	{
		player->pos.y -= PLAYER_SPEED * GetFrameTime();
	}
	if (IsKeyDown(zen_raylib_KeyboardKey_DOWN))
	{
		player->pos.y += PLAYER_SPEED * GetFrameTime();
	}
	if (player->pos.x >= 400)
	{
		player->color.r = 0;
	}
	else
	{
		player->color.r = 255;
	}
}
void zen_game_draw_player(zen_game_Player* player)
{
	DrawRectangle((int)player->pos.x, (int)player->pos.y, 32, 32, player->color);
	DrawText("pelly", (int)(player->pos.x - 8.0f), (int)(player->pos.y - 24.0f), 20, player->color);
	DrawCircle(GetMouseX(), GetMouseY(), 16, player->color);
}

void main()
{
	zen_main();
}