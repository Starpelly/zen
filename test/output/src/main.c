#include <zen.h>

// --------------------------------------------------------------
// Symbol declarations
// --------------------------------------------------------------
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
// --------------------------------------------------------------
// Function declarations
// --------------------------------------------------------------
void zen_main();
void zen_game_start_game();
void zen_game_game_update(zen_game_GameManager* zen_game_gameManager);
void zen_game_game_draw(zen_game_GameManager* zen_game_gameManager);
void zen_game_entity_update(zen_game_Entity* zen_game_e);
void zen_game_player_init(zen_game_Player* zen_game_player);
void zen_game_player_update(zen_game_Player* zen_game_player);
void zen_game_player_draw(zen_game_Player* zen_game_player);
void zen_game_crate_init(zen_game_Crate* zen_game_crate);
void zen_game_crate_draw(zen_game_Crate* zen_game_crate);
void zen_game_map_load();
void zen_game_map_draw();
void zen_game_map_update();
void zen_game_map_move_entity(zen_game_Entity* zen_game_e, int zen_game_dx, int zen_game_dy);
bool zen_game_map_add_entity(zen_game_Entity* zen_game_e);
void zen_game_draw_line(float zen_game_x1, float zen_game_y1, float zen_game_x2, float zen_game_y2, Color zen_game_color);
void zen_game_draw_rect(float zen_game_x, float zen_game_y, float zen_game_w, float zen_game_h, Color zen_game_color);
void zen_game_draw_rect_lines(float zen_game_x, float zen_game_y, float zen_game_w, float zen_game_h, Color zen_game_color);
void zen_game_assets_load();
void zen_game_assets_unload();
float zen_math_lerp(float zen_math_x, float zen_math_y, float zen_math_pct);
float zen_math_distance(float zen_math_dx, float zen_math_dy);
// --------------------------------------------------------------
// Symbol implementations
// --------------------------------------------------------------
struct zen_game_GameManager {
	float t;
};
struct zen_game_Entity {
	zen_game_EntityType type;
	int x;
	int y;
	float visualX;
	float visualY;
	bool player;
};
struct zen_game_Player {
	zen_game_Entity entity;
	Color color;
};
struct zen_game_Crate {
	zen_game_Entity entity;
};
struct zen_game_Tile {
	zen_game_Entity* entity;
};
// --------------------------------------------------------------
// Global constants
// --------------------------------------------------------------
#define zen_game_GAME_WIDTH 320
#define zen_game_GAME_HEIGHT 180
#define zen_game_GAME_ZOOM 4
#define zen_game_CELL_WIDTH 16
#define zen_game_CELL_HEIGHT 16
#define zen_game_PLAYER_SPEED 500.0f
#define zen_game_MAP_WIDTH 12
#define zen_game_MAP_HEIGHT 6
#define zen_game_LEVEL \
"############"\
"#..........#"\
"#@c......o.#"\
"#..c.....o.#"\
"#..........#"\
"##########D#"
#define zen_raylib_LightGray CLITERAL(Color){ 200, 200, 200, 255 }
#define zen_raylib_Gray CLITERAL(Color){ 130, 130, 130, 255 }
#define zen_raylib_DarkGray CLITERAL(Color){ 80, 80, 80, 255 }
#define zen_raylib_Yellow CLITERAL(Color){ 253, 249, 0, 255 }
#define zen_raylib_Gold CLITERAL(Color){ 255, 203, 0, 255 }
#define zen_raylib_Orange CLITERAL(Color){ 255, 161, 0, 255 }
#define zen_raylib_Pink CLITERAL(Color){ 255, 109, 194, 255 }
#define zen_raylib_Red CLITERAL(Color){ 230, 41, 55, 255 }
#define zen_raylib_Maroon CLITERAL(Color){ 190, 33, 55, 255 }
#define zen_raylib_Green CLITERAL(Color){ 0, 228, 48, 255 }
#define zen_raylib_Lime CLITERAL(Color){ 0, 158, 47, 255 }
#define zen_raylib_DarkGreen CLITERAL(Color){ 0, 117, 44, 255 }
#define zen_raylib_SkyBlue CLITERAL(Color){ 102, 191, 255, 255 }
#define zen_raylib_Blue CLITERAL(Color){ 0, 121, 241, 255 }
#define zen_raylib_DarkBlue CLITERAL(Color){ 0, 82, 172, 255 }
#define zen_raylib_Purple CLITERAL(Color){ 200, 122, 255, 255 }
#define zen_raylib_Violet CLITERAL(Color){ 135, 60, 190, 255 }
#define zen_raylib_DarkPurple CLITERAL(Color){ 112, 31, 126, 255 }
#define zen_raylib_Beige CLITERAL(Color){ 211, 176, 131, 255 }
#define zen_raylib_Brown CLITERAL(Color){ 127, 106, 79, 255 }
#define zen_raylib_DarkBrown CLITERAL(Color){ 76, 63, 47, 255 }
#define zen_raylib_White CLITERAL(Color){ 255, 255, 255, 255 }
#define zen_raylib_Black CLITERAL(Color){ 0, 0, 0, 255 }
#define zen_raylib_Blank CLITERAL(Color){ 0, 0, 0, 0 }
#define zen_raylib_Magenta CLITERAL(Color){ 255, 0, 255, 255 }
#define zen_raylib_RayWhite CLITERAL(Color){ 245, 245, 245, 255 }
#define zen_raylib_RealGray CLITERAL(Color){ 21, 12, 13, 255 }
#define zen_math_PI 3.14159265358979323846f
#define zen_math_HALF_PI 1.57079632679489661923f
#define zen_math_EPSILON 0.00001f
// --------------------------------------------------------------
// Global variables
// --------------------------------------------------------------
float zen_game_delta_time;
float zen_game_game_time;
uint64 zen_game_game_frame;
zen_game_Tile zen_game_map_tiles[72];
zen_game_Player zen_game_player;
zen_game_Crate zen_game_testCrate;
Texture2D zen_game_sprite_player;
Texture2D zen_game_sprite_crate;
void zencg_initglobals()
{
	zen_game_delta_time = 0.0f;
	zen_game_game_time = 0.0f;
	zen_game_game_frame = 0;
	zen_game_player = CLITERAL(zen_game_Player){ .color = zen_raylib_Yellow };
	zen_game_testCrate = CLITERAL(zen_game_Crate){ 0 };
	zen_game_sprite_player = CLITERAL(Texture2D){ 0 };
	zen_game_sprite_crate = CLITERAL(Texture2D){ 0 };
}
// --------------------------------------------------------------
// Function implementations
// --------------------------------------------------------------
void zen_main()
{
	zen_game_start_game();
}
void zen_game_start_game()
{
	InitWindow(zen_game_GAME_WIDTH * zen_game_GAME_ZOOM, zen_game_GAME_HEIGHT * zen_game_GAME_ZOOM, "Zen");
	zen_game_assets_load();
	zen_game_GameManager zen_game_gameManager = CLITERAL(zen_game_GameManager){ 0 };
	zen_game_map_load();
	Camera2D zen_game_cam = CLITERAL(Camera2D){ 0 };
	zen_game_cam.target.x = -(float)(58);
	zen_game_cam.target.y = -(float)(32);
	zen_game_cam.zoom = (float)zen_game_GAME_ZOOM;
	while (!WindowShouldClose())
	{
		zen_game_game_update(&zen_game_gameManager);
		BeginDrawing();
		ClearBackground(zen_raylib_RayWhite);
		BeginMode2D(zen_game_cam);
		zen_game_game_draw(&zen_game_gameManager);
		EndMode2D();
		DrawFPS(20, 20);
		EndDrawing();
	}
	zen_game_assets_unload();
	CloseWindow();
}
void zen_game_game_update(zen_game_GameManager* zen_game_gameManager)
{
	zen_game_delta_time = GetFrameTime();
	zen_game_game_time += zen_game_delta_time;
	zen_game_game_frame += 1;
	zen_game_map_update();
}
void zen_game_game_draw(zen_game_GameManager* zen_game_gameManager)
{
	zen_game_map_draw();
}
void zen_game_entity_update(zen_game_Entity* zen_game_e)
{
	float zen_game_targetX = (float)zen_game_e->x;
	float zen_game_targetY = (float)zen_game_e->y;
	zen_game_e->visualX = zen_math_lerp(zen_game_e->visualX, zen_game_targetX, 30.0f * zen_game_delta_time);
	zen_game_e->visualY = zen_math_lerp(zen_game_e->visualY, zen_game_targetY, 30.0f * zen_game_delta_time);
}
void zen_game_player_init(zen_game_Player* zen_game_player)
{
	zen_game_player->entity.player = true;
}
void zen_game_player_update(zen_game_Player* zen_game_player)
{
	zen_game_entity_update(&zen_game_player->entity);
	int zen_game_dx = 0;
	int zen_game_dy = 0;
	if (IsKeyPressed(zen_raylib_KeyboardKey_LEFT))
	{
		zen_game_dx -= 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_RIGHT))
	{
		zen_game_dx += 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_UP))
	{
		zen_game_dy -= 1;
	}
	if (IsKeyPressed(zen_raylib_KeyboardKey_DOWN))
	{
		zen_game_dy += 1;
	}
	if (zen_game_dx == 0 && zen_game_dy == 0)
	{
		return;
	}
	zen_game_map_move_entity(&zen_game_player->entity, zen_game_dx, zen_game_dy);
}
void zen_game_player_draw(zen_game_Player* zen_game_player)
{
	float zen_game_x = zen_game_player->entity.visualX * (float)zen_game_CELL_WIDTH;
	float zen_game_y = zen_game_player->entity.visualY * (float)zen_game_CELL_HEIGHT;
	Rectangle zen_game_src = CLITERAL(Rectangle){ 0.0f, 0.0f, (float)zen_game_sprite_player.width, (float)zen_game_sprite_player.height };
	Rectangle zen_game_dest = CLITERAL(Rectangle){ zen_game_x, zen_game_y, (float)zen_game_CELL_WIDTH, (float)zen_game_CELL_HEIGHT };
	Vector2 zen_game_origin = CLITERAL(Vector2){ 0.0f, 0.0f };
	DrawTexturePro(zen_game_sprite_player, zen_game_src, zen_game_dest, zen_game_origin, 0.0f, zen_raylib_White);
}
void zen_game_crate_init(zen_game_Crate* zen_game_crate)
{
}
void zen_game_crate_draw(zen_game_Crate* zen_game_crate)
{
	float zen_game_x = zen_game_crate->entity.visualX * (float)zen_game_CELL_WIDTH;
	float zen_game_y = zen_game_crate->entity.visualY * (float)zen_game_CELL_HEIGHT;
	Rectangle zen_game_src = CLITERAL(Rectangle){ 0.0f, 0.0f, (float)zen_game_sprite_crate.width, (float)zen_game_sprite_crate.height };
	Rectangle zen_game_dest = CLITERAL(Rectangle){ zen_game_x, zen_game_y, (float)zen_game_CELL_WIDTH, (float)zen_game_CELL_HEIGHT };
	Vector2 zen_game_origin = CLITERAL(Vector2){ 0.0f, 0.0f };
	DrawTexturePro(zen_game_sprite_crate, zen_game_src, zen_game_dest, zen_game_origin, 0.0f, zen_raylib_White);
}
void zen_game_map_load()
{
	for (int zen_game_i = 0; zen_game_i < zen_game_MAP_WIDTH * zen_game_MAP_HEIGHT; zen_game_i += 1)
	{
		zen_game_map_tiles[zen_game_i].entity = null;
	}
	zen_game_player_init(&zen_game_player);
	zen_game_map_move_entity(&zen_game_testCrate.entity, 4, 2);
}
void zen_game_map_draw()
{
	#define zen_game_checker1 CLITERAL(Color){ 0, 0, 0, 15 }
	#define zen_game_checker2 CLITERAL(Color){ 21, 24, 31, 28 }
	for (int zen_game_y = 0; zen_game_y < zen_game_MAP_HEIGHT; zen_game_y += 1)
	{
		for (int zen_game_x = 0; zen_game_x < zen_game_MAP_WIDTH; zen_game_x += 1)
		{
			zen_game_Tile zen_game_tile = zen_game_map_tiles[zen_game_y * zen_game_MAP_HEIGHT + zen_game_x];
			Color zen_game_tileColor = zen_game_checker1;
			if ((zen_game_x - zen_game_y) % 2 == 0)
			{
				zen_game_tileColor = zen_game_checker2;
			}
			DrawRectangle(zen_game_x * zen_game_CELL_WIDTH, zen_game_y * zen_game_CELL_HEIGHT, zen_game_CELL_WIDTH, zen_game_CELL_HEIGHT, zen_game_tileColor);
		}
	}
	zen_game_draw_rect_lines(0.0f, 0.0f, (float)(zen_game_MAP_WIDTH * zen_game_CELL_WIDTH), (float)(zen_game_MAP_HEIGHT * zen_game_CELL_HEIGHT), zen_raylib_LightGray);
	zen_game_crate_draw(&zen_game_testCrate);
	zen_game_player_draw(&zen_game_player);
}
void zen_game_map_update()
{
	zen_game_entity_update(&zen_game_testCrate.entity);
	zen_game_player_update(&zen_game_player);
}
void zen_game_map_move_entity(zen_game_Entity* zen_game_e, int zen_game_dx, int zen_game_dy)
{
	if (zen_game_dx == 0 && zen_game_dy == 0)
	{
		return;
	}
	if (zen_game_e == null)
	{
		return;
	}
	int zen_game_nx = zen_game_e->x + zen_game_dx;
	int zen_game_ny = zen_game_e->y + zen_game_dy;
	zen_game_Entity* zen_game_destE = zen_game_map_tiles[zen_game_nx + (zen_game_ny * zen_game_MAP_WIDTH)].entity;
	if (zen_game_destE != null)
	{
		if (zen_game_e->player == true)
		{
			zen_game_map_move_entity(zen_game_destE, zen_game_dx, zen_game_dy);
		}
	}
	zen_game_map_tiles[zen_game_e->x + (zen_game_e->y * zen_game_MAP_WIDTH)].entity = null;
	zen_game_map_tiles[zen_game_nx + (zen_game_ny * zen_game_MAP_WIDTH)].entity = zen_game_e;
	zen_game_e->x = zen_game_nx;
	zen_game_e->y = zen_game_ny;
}
bool zen_game_map_add_entity(zen_game_Entity* zen_game_e)
{
	if (zen_game_e == null)
	{
		return false;
	}
	zen_game_map_tiles[zen_game_e->x + zen_game_e->y * zen_game_MAP_WIDTH].entity = zen_game_e;
	return true;
}
void zen_game_draw_line(float zen_game_x1, float zen_game_y1, float zen_game_x2, float zen_game_y2, Color zen_game_color)
{
	DrawLine((int)zen_game_x1, (int)zen_game_y1, (int)zen_game_x2, (int)zen_game_y2, zen_game_color);
}
void zen_game_draw_rect(float zen_game_x, float zen_game_y, float zen_game_w, float zen_game_h, Color zen_game_color)
{
	DrawRectangle((int)zen_game_x, (int)zen_game_y, (int)zen_game_w, (int)zen_game_h, zen_game_color);
}
void zen_game_draw_rect_lines(float zen_game_x, float zen_game_y, float zen_game_w, float zen_game_h, Color zen_game_color)
{
	DrawLine((int)zen_game_x, (int)zen_game_y, (int)zen_game_w, (int)zen_game_y, zen_game_color);
	DrawLine((int)zen_game_x, (int)zen_game_h, (int)zen_game_w, (int)zen_game_h, zen_game_color);
	DrawLine((int)zen_game_x, (int)zen_game_y, (int)zen_game_x, (int)zen_game_h, zen_game_color);
	DrawLine((int)zen_game_w, (int)zen_game_y, (int)zen_game_w, (int)zen_game_h, zen_game_color);
}
void zen_game_assets_load()
{
	zen_game_sprite_player = LoadTexture("C:/Users/Braedon/Pictures/socialmedia/24588691.jpg");
	zen_game_sprite_crate = LoadTexture("C:/Users/Braedon/Downloads/crate.png");
}
void zen_game_assets_unload()
{
	UnloadTexture(zen_game_sprite_player);
	UnloadTexture(zen_game_sprite_crate);
}
float zen_math_lerp(float zen_math_x, float zen_math_y, float zen_math_pct)
{
	return zen_math_x + (zen_math_y - zen_math_x) * zen_math_pct;
}
float zen_math_distance(float zen_math_dx, float zen_math_dy)
{
	return sqrtf(zen_math_dx * zen_math_dx + zen_math_dy * zen_math_dy);
}

// --------------------------------------------------------------
// Entry point
// --------------------------------------------------------------
void main()
{
	zencg_initglobals();
	zen_main();
}