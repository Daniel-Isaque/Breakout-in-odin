package breakout

import rl "vendor:raylib"

SCREEN_WIDTH :: 450
SCREEN_HEIGHT :: 500
COLUMNS :: 7
ROWS :: 13
MAX_BLOCKS :: 91

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
round_old: i32 = 0
round: i32 = 0

// FIXME: ¯\_(ツ)_/¯
ResetGame :: struct {
	paddle_reset:        Paddle,
	block_reset:         Block,
	player_score, lives: i32,
}

main :: proc() {

	paddle: Paddle = {
		width  = 70,
		height = 10,
		x      = SCREEN_WIDTH / 2 - 30,
		y      = SCREEN_HEIGHT - 50,
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

	restart: ResetGame = {
		block_reset  = default_block,
		paddle_reset = paddle,
		player_score = 0,
		lives        = 5,
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

		for i in 0 ..< len(blockArray) {
			if !blockArray[i].active do continue
			CheckBlocks(&blockArray[i], &ballArray[0], boom_sound)
		}

		Update(&ballArray[0], win_sound)

		for i := len(ballArray) - 1; i >= 0; i -= 1 {
			ball := &ballArray[i]
			CheckPaddleBounces(&paddle, ball, paddle_sound)
			if ball.pos.y > f32(SCREEN_HEIGHT) {
				unordered_remove(&ballArray, i)
			}
		}

		CheckPaddleBounces(&paddle, &ballArray[0], paddle_sound)
		UpdatePaddle(&paddle)

		if len(ballArray) == 0 && lives < 0 {
			GiveNewBall(&ballArray)
		}

		if lives <= 0 {
			paddle = restart.paddle_reset
			lives = restart.lives
			player_score = restart.player_score

			for i in 0 ..< len(blockArray) {
				if !blockArray[i].active {
					blockArray[i].active = true
				}
			}
		}

		if round > round_old {
			paddle = restart.paddle_reset
			lives = restart.lives
			GiveNewBall(&ballArray)
			round_old = round

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

		Draw(ballArray[0])
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
