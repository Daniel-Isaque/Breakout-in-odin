package breakout

import "core:fmt"
import "core:math"
import rat "rat-engine"
import rl "vendor:raylib"

SCREEN_WIDTH :: 450
SCREEN_HEIGHT :: 500
COLUMNS :: 7
ROWS :: 13
MAX_BLOCKS :: 91

ResetGame :: proc(pad: ^Paddle, world: ^World) {
	//reset paddle
	pad.x = PADDLE_DEFAULT_SPAWN_X
	pad.y = PADDLE_DEFAULT_SPAWN_Y

	// reset balls
	rat.clear_sparse_set(&world.balls)
	GiveNewBall(world)

	// reset blocks
	for &block in world.blocks {
		block.active = true
		block.durability = 1
	}

	//globals
	world.lives = 5
	world.round = 0
	world.player_score = 0
	world.bg_counter = 0
	world.bg_index = 0
}

GameAssets :: struct {
	glorp:        rl.Texture2D,
	bg:           [4]rl.Texture2D,
	paddle_sound: rl.Sound,
	boom_sound:   rl.Sound,
	win_sound:    rl.Sound,
}

MenuOptions :: enum {
	Play,
	Settings,
	Close,
	Count,
}


GameState :: enum {
	Menu,
	Loop,
}

unload_assets :: proc(assets: ^GameAssets) {
	rl.UnloadTexture(assets^.glorp)
	for i in 0 ..< 4 {
		rl.UnloadTexture(assets^.bg[i])
	}
	rl.UnloadSound(assets^.paddle_sound)
	rl.UnloadSound(assets^.boom_sound)
	rl.UnloadSound(assets^.win_sound)
}

main :: proc() {

	game_camera = {
		offset   = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		target   = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2},
		rotation = 0,
		zoom     = 1,
	}

	default_block: Block = {
		height     = 10,
		width      = 25,
		x          = 0,
		y          = 80,
		active     = true,
		durability = 1,
	}

	world1 := create_world()

	SpawnPlayer(&world1)
	player := &world1.player.data[0]

	world1.game_state = GameState.Menu
	world1.cursor = 0

	FillBlockArray(&world1.blocks, default_block)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Breakout 1967 LOOP OF DEATH")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	asset := GameAssets {
		glorp        = rl.LoadTexture("assets/Sprites/glorp.png"),
		bg           = {
			rl.LoadTexture("assets/Sprites/Space_bg.png"),
			rl.LoadTexture("assets/Sprites/Space_bg(1).png"),
			rl.LoadTexture("assets/Sprites/Space_bg(2).png"),
			rl.LoadTexture("assets/Sprites/Space_bg(3).png"),
		},
		paddle_sound = rl.LoadSound("assets/Audio/Boing_sound.wav"),
		boom_sound   = rl.LoadSound("assets/Audio/Boom.wav"),
		win_sound    = rl.LoadSound("assets/Audio/Win_test.wav"),
	}

	defer rl.CloseAudioDevice()
	defer rl.CloseWindow()
	defer unload_assets(&asset)
	defer delete_world(&world1)

	rl.SetSoundVolume(asset.boom_sound, 0.6)
	rl.SetSoundVolume(asset.paddle_sound, 1)


	GiveNewBall(&world1)

	for !rl.WindowShouldClose() && !world1.should_close {

		switch (world1.game_state) {
		case .Menu:
			UpdateMenu(&world1)
		case .Loop:
			UpdateGame(&world1, asset)
		}

		//loop for checking any trauma alteraiont make ScreenShake(do something)
		// re: you don't need to run this based on a branch.
		/*if trauma > 0 {
			shake := trauma * trauma // calculate first
			game_camera.offset = {
				SCREEN_WIDTH / 2 + 10 * shake * random_range(-1, 1),
				SCREEN_HEIGHT / 2 + 10 * shake * random_range(-1, 1),
			}
			trauma -= (1.0 / 1) * rl.GetFrameTime() // reduce after
			if trauma < 0 do trauma = 0
		} else {
			game_camera.offset = {SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2}
		}*/
		rl.BeginDrawing()
		rl.DrawTexture(asset.bg[world1.bg_index], 0, 0, rl.WHITE)

		switch (world1.game_state) {
		case .Menu:
			itens := [3]cstring{"START", "SETTINGS", "CLOSE"}
			cursor_size: i32 = 20
			font_size: i32 = 40
			spacing: i32 = 10
			item_count: i32 = len(itens)
			for i in 0 ..< len(itens) {
				text_width := rl.MeasureText(itens[i], font_size)
				x := (SCREEN_WIDTH - text_width) / 2

				menu_height := item_count * font_size + (i32(item_count - 1) * spacing)
				start_y := (SCREEN_HEIGHT - menu_height) / 2
				y := start_y + i32(i) * (font_size + spacing)

				rl.DrawText(itens[i], i32(x), i32(y), 40, rl.YELLOW)
				if i32(i) == world1.cursor {
					rl.DrawText(itens[i], i32(x), i32(y), 40, rl.PINK)
				}

				cursor_y :=
					start_y + world1.cursor * (font_size + spacing) + (font_size - cursor_size) / 2
				cursor_x :=
					(SCREEN_WIDTH - rl.MeasureText(itens[world1.cursor], font_size)) / 2 - 30

				rl.DrawRectangle(cursor_x, cursor_y, cursor_size, cursor_size, rl.WHITE)

			}


		case .Loop:
			rl.DrawText(rl.TextFormat("%d", world1.lives), SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)
			rl.DrawText(
				rl.TextFormat("%d", world1.player_score),
				3 * SCREEN_WIDTH / 4 - 20,
				20,
				20,
				rl.WHITE,
			)

			rl.BeginMode2D(game_camera)

			for i in 0 ..< world1.balls.count {
				DrawBall(world1.balls.data[i])
			}

			DrawPaddle(player^, asset.glorp)
			DrawBlocks(world1.blocks)
			draw_particles(&world1.particles)

			rl.EndMode2D()
		}

		rl.EndDrawing()
	}
}
