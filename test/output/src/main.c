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
typedef struct zen_game_Tile zen_game_Tile;
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
const int32 GAME_WIDTH = 320;
const int32 GAME_HEIGHT = 180;
const int32 GAME_ZOOM = 4;
const int32 CELL_WIDTH = 16;
const int32 CELL_HEIGHT = 16;
void zen_game_start_game();
void zen_game_game_update(zen_game_GameManager* gameManager);
void zen_game_game_draw(zen_game_GameManager* gameManager);
void zen_game_entity_update(zen_game_Entity* e);
const float PLAYER_SPEED = 500.0f;
void zen_game_player_init(zen_game_Player* player);
void zen_game_player_update(zen_game_Player* player);
void zen_game_player_draw(zen_game_Player* player);
void zen_game_crate_init(zen_game_Crate* crate);
void zen_game_crate_draw(zen_game_Crate* crate);
const int MAP_WIDTH = 12;
const int MAP_HEIGHT = 6;
void zen_game_map_load();
void zen_game_map_draw();
void zen_game_draw_line(float x1, float y1, float x2, float y2, Color color);
void zen_game_draw_rect(float x, float y, float w, float h, Color color);
void zen_game_draw_rect_lines(float x, float y, float w, float h, Color color);
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
struct zen_game_Tile {
	bool active;
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
	InitWindow(GAME_WIDTH * GAME_ZOOM, GAME_HEIGHT * GAME_ZOOM, "Zen");
	SetTargetFPS(185);
	zen_game_GameManager gameManager = {};
	zen_game_Player player = {};
	Camera2D cam = {};
	cam.target.x = -(float)(58);
	cam.target.y = -(float)(32);
	cam.zoom = (float)GAME_ZOOM;
	gameManager.player = &player;
	zen_game_player_init(gameManager.player);
	zen_game_map_load();
	while (!WindowShouldClose())
	{
		zen_game_game_update(&gameManager);
		BeginDrawing();
		ClearBackground(black);
		BeginMode2D(cam);
		zen_game_game_draw(&gameManager);
		EndMode2D();
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
	zen_game_map_draw();
	zen_game_player_draw(gameManager->player);
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
	DrawRectangle((int)(player->entity.visualX * (float)CELL_WIDTH), (int)(player->entity.visualY * (float)CELL_HEIGHT), CELL_WIDTH, CELL_WIDTH, player->color);
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
zen_game_Tile map_tiles[72];
void zen_game_map_load()
{
	for (int i = 0; i < MAP_WIDTH * MAP_HEIGHT; i += 1)
	{
		map_tiles[i].active = false;
	}
	for (int i = 0; i < 2; i += 1)
	{
		map_tiles[i].active = true;
	}
}
void zen_game_map_draw()
{
	for (int y = 0; y < MAP_WIDTH; y += 1)
	{
		for (int x = 0; x < MAP_HEIGHT; x += 1)
		{
			zen_game_Tile tile = map_tiles[y * MAP_HEIGHT + x];
			Color tileColor = {};
			tileColor.a = 255;
			if (tile.active == true)
			{
				tileColor.r = 255;
			}
			if (tile.active == true)
			{
				DrawRectangle(x * CELL_WIDTH, y * CELL_HEIGHT, CELL_WIDTH, CELL_HEIGHT, tileColor);
			}
		}
	}
	Color white = {};
	white.r = 255;
	white.g = 255;
	white.b = 255;
	white.a = 255;
	zen_game_draw_rect_lines(0.0f, 0.0f, (float)(MAP_WIDTH * CELL_WIDTH), (float)(MAP_HEIGHT * CELL_HEIGHT), white);
}
void zen_game_draw_line(float x1, float y1, float x2, float y2, Color color)
{
	DrawLine((int)x1, (int)y1, (int)x2, (int)y2, color);
}
void zen_game_draw_rect(float x, float y, float w, float h, Color color)
{
	DrawRectangle((int)x, (int)y, (int)w, (int)h, color);
}
void zen_game_draw_rect_lines(float x, float y, float w, float h, Color color)
{
	DrawLine((int)x, (int)y, (int)w, (int)y, color);
	DrawLine((int)x, (int)h, (int)w, (int)h, color);
	DrawLine((int)x, (int)y, (int)x, (int)h, color);
	DrawLine((int)w, (int)y, (int)w, (int)h, color);
}

void main()
{
	zen_main();
}