package breakout

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

	world := create_world()
	defer delete_world(&world)

	SpawnPlayer(&world)
	player := &world.player.data[0]

	FillBlockArray(&world.blocks, default_block)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Breakout 1967 LOOP OF DEATH")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	defer rl.CloseWindow()
	defer rl.CloseAudioDevice()

	glorp := rl.LoadTexture("assets/Sprites/glorp.png")
	defer rl.UnloadTexture(glorp)

	bg: [4]rl.Texture2D = {
		rl.LoadTexture("assets/Sprites/Space_bg.png"),
		rl.LoadTexture("assets/Sprites/Space_bg(1).png"),
		rl.LoadTexture("assets/Sprites/Space_bg(2).png"),
		rl.LoadTexture("assets/Sprites/Space_bg(3).png"),
	}
	defer rl.UnloadTexture(bg[0])
	defer rl.UnloadTexture(bg[1])
	defer rl.UnloadTexture(bg[2])
	defer rl.UnloadTexture(bg[3])

	paddle_sound := rl.LoadSound("assets/Audio/Boing_sound.wav")
	win_sound := rl.LoadSound("assets/Audio/Win_test.wav")
	boom_sound := rl.LoadSound("assets/Audio/Boom.wav")

	rl.SetSoundVolume(boom_sound, 0.6)
	rl.SetSoundVolume(paddle_sound, 1)

	defer rl.UnloadSound(win_sound)
	defer rl.UnloadSound(paddle_sound)
	defer rl.UnloadSound(boom_sound)

	GiveNewBall(&world)

	for !rl.WindowShouldClose() {

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
		world.bg_counter += 1
		if world.bg_counter >= 5 {
			world.bg_counter = 0
			world.bg_index += 1
			if world.bg_index >= 4 do world.bg_index = 0
		}
		UpdatePaddle(player, &world)
		for i := int(world.balls.count) - 1; i >= 0; i -= 1 {
			id := world.balls.dense[i]
			ball := &world.balls.data[i]
			UpdateBallVisuals(&world, ball)

			vel_x := ball.speed_x + (math.sign(ball.speed_x) * ball.speed_boost)
			vel_y := ball.speed_y + (math.sign(ball.speed_y) * ball.speed_boost)
			max_vel := math.max(math.abs(vel_x), math.abs(vel_y))

			sub_steps := int(math.ceil(max_vel / 4.0))
			if sub_steps < 1 do sub_steps = 1

			step_dt := 1.0 / f32(sub_steps)

			for s in 0 ..< sub_steps {
				UpdateBallPhysics(&world, ball, win_sound, step_dt)
				if !player.paddle_bounced && CheckVisualHit(player, ball) {
					angle = math.PI * 0.1
					player.paddle_bounced = true // still need a trigger for UpdatePaddle...
				}
				CheckPaddleBounces(player, ball, &world, paddle_sound)
				for j in 0 ..< len(world.blocks) {
					if !world.blocks[j].active do continue
					CheckBlocks(&world, &world.blocks[j], ball, boom_sound)
				}
			}

			if ball.pos.y > SCREEN_HEIGHT {
				rat.remove(&world.balls, id)
				if world.balls.count == 0 {
					world.lives -= 1
					GiveNewBall(&world)
				}
			}

		}

		rat.UpdateTimers(&world.timers)

		if world.balls.count == 0 && world.lives < 0 {
			GiveNewBall(&world)
		}

		if world.lives <= 0 {
			ResetGame(player, &world)
		}

		if world.win_condition {

			world.win_condition = false
			player.x = PADDLE_DEFAULT_SPAWN_X
			player.y = PADDLE_DEFAULT_SPAWN_Y
			world.lives = 5
			world.round += 1

			rat.clear_sparse_set(&world.balls)
			for i in 0 ..< world.round + 1 {
				GiveNewBall(&world, f32(i) * 1.5 - f32(world.round) * 0.75)
			}

			for i in 0 ..< len(world.blocks) {
				if !world.blocks[i].active {
					world.blocks[i].durability = 1 * world.round
					world.blocks[i].active = true
				}
			}
		}
		update_particles(&world.particles)
		UpdateScreenshake(&game_camera)

		rl.BeginDrawing()
		rl.DrawTexture(bg[world.bg_index], 0, 0, rl.WHITE)

		rl.DrawText(rl.TextFormat("%d", world.lives), SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)
		rl.DrawText(
			rl.TextFormat("%d", world.player_score),
			3 * SCREEN_WIDTH / 4 - 20,
			20,
			20,
			rl.WHITE,
		)

		rl.BeginMode2D(game_camera)

		for i in 0 ..< world.balls.count {
			DrawBall(world.balls.data[i])
		}

		DrawPaddle(player^, glorp)
		DrawBlocks(world.blocks)
		draw_particles(&world.particles)

		rl.EndMode2D()

		rl.EndDrawing()
	}
}
