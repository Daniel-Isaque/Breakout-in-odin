package breakout

import rl "vendor:raylib"

SCREEN_WIDTH :: 450
SCREEN_HEIGHT :: 500
COLUMNS :: 7
ROWS :: 13
MAX_BLOCKS :: 91

PADDLE_DEFAULT_SPAWN_X: f32 : 195
PADDLE_DEFAULT_SPAWN_Y: f32 : 450
BALL_DEFAULT_SPAWN_X: f32 : 225
BALL_DEFAULT_SPAWN_Y: f32 : 166
BALL_DEFAULT_WIDTH: f32 : 10
BALL_DEFAULT_HEIGHT: f32 : 10
BALL_HEIGHT: i32 : 10
BALL_SPEED_X: f32 : 4.0
BALL_SPEED_Y: f32 : 5.0

// Globals
player_score: i32 = 0
lives: i32 = 5
round: i32 = 0
win_condition: bool = false

ResetGame :: proc(pad: ^Paddle, ballArray: ^[dynamic]Ball, blocks: ^[MAX_BLOCKS]Block) {
	//reset paddle
	pad.x = PADDLE_DEFAULT_SPAWN_X
	pad.y = PADDLE_DEFAULT_SPAWN_Y

	// reset balls
	clear(ballArray)
	GiveNewBall(ballArray)

	// reset blocks
	for &block in blocks {
		block.active = true
		block.durability = 1
	}

	//globals
	lives = 5
	round = 0
	player_score = 0
}

// we need to centralize state at some point.
/*GameState :: proc {
	ball_array : [dynamic]Ball,
	particle_array : [dynamic]Particle,
	block_array : [MAX_BLOCKS]Block,
	//...
}*/

main :: proc() {

	paddle: Paddle = {
		width  = 60,
		height = 10,
		x      = PADDLE_DEFAULT_SPAWN_X,
		y      = PADDLE_DEFAULT_SPAWN_Y,
		speed  = 12,
	}

	default_block: Block = {
		height     = 10,
		width      = 30,
		x          = 0,
		y          = 80,
		active     = true,
		durability = 1,
	}

	ball_array: [dynamic]Ball = make([dynamic]Ball, 0, 32)
	particle_array : [dynamic]Particle = make([dynamic]Particle, 0, 128)
	
	defer delete(ball_array)
	defer delete(particle_array)
	
	block_array: [MAX_BLOCKS]Block
	FillBlockArray(&block_array, default_block)

	rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Breakout 1967 LOOP OF DEATH")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	defer rl.CloseWindow()
	defer rl.CloseAudioDevice()

	paddle_sound := rl.LoadSound("assets/Audio/Blip.wav")
	win_sound := rl.LoadSound("assets/Audio/Win_test.wav")
	boom_sound := rl.LoadSound("assets/Audio/Boom.wav")

	defer rl.UnloadSound(win_sound)
	defer rl.UnloadSound(paddle_sound)
	defer rl.UnloadSound(boom_sound)

	GiveNewBall(&ball_array)

	for !rl.WindowShouldClose() {

		for i := len(ball_array) - 1; i >= 0; i -= 1 {
			UpdateBall(&ball_array[i], win_sound)
			CheckPaddleBounces(&paddle, &ball_array[i], paddle_sound)
			for j in 0 ..< len(block_array) {
				if !block_array[j].active do continue
				CheckBlocks(&block_array[j], &ball_array[i], &particle_array, boom_sound)
			}
			if ball_array[i].pos.y > SCREEN_HEIGHT {
				unordered_remove_dynamic_array(&ball_array, i)
				if len(ball_array) == 0 {
					lives -= 1
					GiveNewBall(&ball_array)
				}
			}
		}

		UpdatePaddle(&paddle)

		if len(ball_array) == 0 && lives < 0 {
			GiveNewBall(&ball_array)
		}

		if lives <= 0 {
			ResetGame(&paddle, &ball_array, &block_array)
		}

		if win_condition {
			win_condition = false
			paddle.x = PADDLE_DEFAULT_SPAWN_X
			paddle.y = PADDLE_DEFAULT_SPAWN_Y
			lives = 5
			clear(&ball_array)
			GiveNewBall(&ball_array)
			round += 1

			clear(&ball_array)
			for i in 0 ..< round + 1 {
				GiveNewBall(&ball_array, f32(i) * 1.5 - f32(round) * 0.75)
			}

			for i in 0 ..< len(block_array) {
				if !block_array[i].active {
					block_array[i].durability = 1 * round
					block_array[i].active = true
				}
			}
		}

		UpdateParticles(&particle_array)

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawText(rl.TextFormat("%d", lives), SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)
		rl.DrawText(rl.TextFormat("%d", player_score), 3 * SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)

		for ball in ball_array {
			DrawBall(ball)
		}
		
		DrawPaddle(paddle)
		DrawBlocks(&block_array)
		DrawParticles(&particle_array)

		rl.EndDrawing()
	}
}
