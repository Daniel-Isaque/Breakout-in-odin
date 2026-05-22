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

	ballArray: [dynamic]Ball = make([dynamic]Ball, 0, 32)

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

	blockArray: [MAX_BLOCKS]Block
	for &e in blockArray {
		e = default_block
	}

	for column in 0 ..< COLUMNS {
		for rows in 0 ..< ROWS {
			i := column * ROWS + rows
			blockArray[i].x = f32(2 + rows * (int(blockArray[i].width) + 5))
			blockArray[i].y = f32(column * int(blockArray[i].y) / 5 + 40)
		}
	}

	GiveNewBall(&ballArray)

	for !rl.WindowShouldClose() {

		for i := len(ballArray) - 1; i >= 0; i -= 1 {
			Update(&ballArray[i], win_sound)
			CheckPaddleBounces(&paddle, &ballArray[i], paddle_sound)
			for j in 0 ..< len(blockArray) {
				if !blockArray[j].active do continue
				CheckBlocks(&blockArray[j], &ballArray[i], boom_sound)
			}
			if ballArray[i].pos.y > SCREEN_HEIGHT {
				unordered_remove_dynamic_array(&ballArray, i)
				if len(ballArray) == 0 {
					lives -= 1
					GiveNewBall(&ballArray)
				}
			}
		}


		UpdatePaddle(&paddle)

		if len(ballArray) == 0 && lives < 0 {
			GiveNewBall(&ballArray)
		}

		if lives <= 0 {
			ResetGame(&paddle, &ballArray, &blockArray)
		}

		if win_condition {
			win_condition = false
			paddle.x = PADDLE_DEFAULT_SPAWN_X
			paddle.y = PADDLE_DEFAULT_SPAWN_Y
			lives = 5
			clear(&ballArray)
			GiveNewBall(&ballArray)
			round += 1

			clear(&ballArray)
			for i in 0 ..< round + 1 {
				GiveNewBall(&ballArray, f32(i) * 1.5 - f32(round) * 0.75)
			}

			for i in 0 ..< len(blockArray) {
				if !blockArray[i].active {
					blockArray[i].durability = 1 * round
					blockArray[i].active = true
				}
			}
		}


		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawText(rl.TextFormat("%d", lives), SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)
		rl.DrawText(rl.TextFormat("%d", player_score), 3 * SCREEN_WIDTH / 4 - 20, 20, 20, rl.WHITE)

		for ball in ballArray {
			Draw(ball)
		}
		DrawPaddle(paddle)

		for column in 0 ..< COLUMNS {
			for rows in 0 ..< ROWS {
				i := column * ROWS + rows
				if blockArray[i].active == true {
					rl.DrawRectangle(
						i32(blockArray[i].x),
						i32(blockArray[i].y),
						i32(blockArray[i].width),
						i32(blockArray[i].height),
						BlockColors[column],
					)
				}
			}
		}
		rl.EndDrawing()
	}
}
