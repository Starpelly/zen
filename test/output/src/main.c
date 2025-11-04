#include <zen.h>

typedef struct zen_game_GameManager zen_game_GameManager;
typedef enum {
	zen_game_EntityType_None = 0,
	zen_game_EntityType_Player = 1,
	zen_game_EntityType_Crate = 2
} zen_game_EntityType;
typedef struct zen_game_Entity zen_game_Entity;
typedef struct zen_game_Player zen_game_Player;
typedef struct zen_game_Crate zen_game_Crate;
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
#define GAME_WIDTH 320
#define GAME_HEIGHT 180
#define CELL_WIDTH 32
#define CELL_HEIGHT 32
void zen_game_start_game();
void zen_game_game_update(zen_game_GameManager* gameManager);
void zen_game_game_draw(zen_game_GameManager* gameManager);
void zen_game_entity_update(zen_game_Entity* e);
#define PLAYER_SPEED 500.0f
void zen_game_player_init(zen_game_Player* player);
void zen_game_player_update(zen_game_Player* player);
void zen_game_player_draw(zen_game_Player* player);
void zen_game_crate_init(zen_game_Crate* crate);
void zen_game_crate_draw(zen_game_Crate* crate);
#define PI 3.14159265358979323846f
#define HALF_PI 1.57079632679489661923f
#define EPSILON 0.00001f
struct zen_game_GameManager {
	zen_game_Player* player;
};
struct zen_game_Entity {
	zen_game_EntityType type;
	int x;
	int y;
	float visualX;
	float visualY;
};
struct zen_game_Player {
	zen_game_Entity entity;
	Color color;
};
struct zen_game_Crate {
	zen_game_Entity entity;
};
void zen_main()
{
	zen_game_start_game();
}
float delta_time = 0.0f;
float game_time = 0.0f;
uint64 game_frame = 0;
void zen_game_start_game()
{
	Color black = {};
	black.r = 0;
	black.g = 0;
	black.b = 0;
	black.a = 255;
	InitWindow(GAME_WIDTH * 4, GAME_HEIGHT * 4, "Zen");
	SetTargetFPS(185);
	zen_game_GameManager gameManager = {};
	zen_game_Player player = {};
	gameManager.player = &player;
	zen_game_player_init(gameManager.player);
	int width = 32;
	int height = 32;
	bool tiles[128];
	while (!WindowShouldClose())
	{
		zen_game_game_update(&gameManager);
		BeginDrawing();
		ClearBackground(black);
		zen_game_game_draw(&gameManager);
		DrawFPS(20, 20);
		EndDrawing();
	}
	CloseWindow();
}
void zen_game_game_update(zen_game_GameManager* gameManager)
{
	delta_time = GetFrameTime();
	game_time += delta_time;
	game_frame += 1;
	zen_game_player_update(gameManager->player);
}
void zen_game_game_draw(zen_game_GameManager* gameManager)
{
	zen_game_player_draw(gameManager->player);
	float sinx = sinf(game_time * 8.0f) * 44.0f;
	float siny = cosf(game_time * 8.0f) * 44.0f;
	DrawCircle((int)sinx + 400, (int)siny + 400, 32, gameManager->player->color);
	printf("%f\n", sinx);
}
void zen_game_entity_update(zen_game_Entity* e)
{
	float targetX = (float)e->x;
	float targetY = (float)e->y;
	float dx = targetX - e->visualX;
	float dy = targetY - e->visualY;
	e->visualX += dx * 30.0f * delta_time;
	e->visualY += dy * 30.0f * delta_time;
}
void zen_game_player_init(zen_game_Player* player)
{
	player->color.r = 255;
	player->color.g = 255;
	player->color.b = 0;
	player->color.a = 255;
}
void zen_game_player_update(zen_game_Player* player)
{
	zen_game_entity_update(&player->entity);
	int dx = 0;
	int dy = 0;
	if (IsKeyPressed(zen_raylib_KeyboardKey_LEFT))
	{
		dx -= 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_RIGHT))
	{
		dx += 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_UP))
	{
		dy -= 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_DOWN))
	{
		dy += 1;
	}
	int nx = player->entity.x + dx;
	int ny = player->entity.y + dy;
	player->entity.x = nx;
	player->entity.y = ny;
}
void zen_game_player_draw(zen_game_Player* player)
{
	DrawRectangle((int)(player->entity.visualX * (float)CELL_WIDTH), (int)(player->entity.visualY * (float)CELL_HEIGHT), 32, 32, player->color);
}
void zen_game_crate_init(zen_game_Crate* crate)
{
}
void zen_game_crate_draw(zen_game_Crate* crate)
{
	Color color = {};
	color.r = 0;
	color.g = 0;
	color.b = 255;
	color.a = 255;
	DrawRectangle((int)(crate->entity.visualX * (float)CELL_WIDTH), (int)(crate->entity.visualY * (float)CELL_HEIGHT), 32, 32, color);
}

void main()
{
	zen_main();
}