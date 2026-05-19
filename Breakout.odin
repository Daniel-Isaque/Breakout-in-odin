package main

import "core:fmt"
import "core:math/rand"
import rl "vendor:raylib"

playerScore: i32 = 0
lives: i32 = 5
round_old: i32 = 0
round: i32 = 1


Paddle_sound := rl.LoadSound("~/meu_jogo/jogo_2/assets/Audio/Blip.wav")

Ball :: struct {
	x, y:                                       f32,
	width, height:                              f32,
	old_speed_x, old_speed_y, speed_x, speed_y: f32,
}

Draw :: proc(b: Ball) {
	rl.DrawRectangle(i32(b.x), i32(b.y), i32(b.width), i32(b.height), rl.WHITE)
}

Update :: proc(b: ^Ball, s: rl.Sound) {
	b.x += b.speed_x + 0.2 * f32(round + 1)
	b.y += b.speed_y + 0.2 * f32(round)

	if i32(b.x + b.width) >= rl.GetScreenWidth() {
		b.x = f32(rl.GetScreenWidth()) - b.width + 0.1
		b.speed_x *= -1
		fmt.printf("colidiu")
	}
	if b.x <= 0 {
		b.x += 0.1
		b.speed_x *= -1
	}

	if b.y + b.height >= f32(rl.GetScreenHeight()) {
		lives -= 1
		b.speed_x *= -1
		ResetBall(&b^)
	}
	if b.y - b.height <= 0 {
		rl.PlaySound(s)
		round += 1

	}
}

ResetBall :: proc(b: ^Ball) {

	b.x = f32(rl.GetScreenWidth() / 2)
	b.y = f32(rl.GetScreenHeight() / 2)

	lista := [2]f32{-1, 1}

	decision: f32 = lista[rand.int_max(2)]
	b.speed_x *= decision

}


Paddle :: struct {
	x, y:          f32,
	width, height: f32,
	speed:         f32,
}

Draw_rec :: proc(p: Paddle) {
	rl.DrawRectangle(i32(p.x), i32(p.y), i32(p.width), i32(p.height), rl.BLUE)
}

Update_rec :: proc(p: ^Paddle) {
	if rl.IsKeyDown(rl.KeyboardKey.RIGHT) {
		p.x += p.speed
	}
	if rl.IsKeyDown(rl.KeyboardKey.LEFT) {
		p.x -= p.speed

	}
	if p.x <= 0 {
		p.x = 0
	}
	if p.x + p.width >= f32(rl.GetScreenWidth()) {
		p.x = f32(rl.GetScreenWidth()) - p.width - 1
	}
}

Check :: proc(p: ^Paddle, b: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{b.x, b.y, b.width, b.height},
		rl.Rectangle{p.x, p.y, p.width, p.height},
	) {
		rl.PlaySound(s)
		b.speed_y = b.old_speed_y
		b.speed_y *= -1
		b.y = p.y - b.height

	}

}
Check_jail :: proc(p: ^Jail, b: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{b.x, b.y, b.width, b.height},
		rl.Rectangle{p.x, p.y, p.width, p.height},
	) {
		b.speed_y *= -1
		p.durability -= 1
		if p.durability <= 0 {p.active = false
			rl.PlaySound(s)
			playerScore += 1}
		lista := [2]f32{-1, 1}
		ball.speed_y = ball.old_speed_y
		decision: f32 = lista[rand.int_max(2)]
		b.speed_x *= decision
		b.speed_y *= 1.2

	}

}


Jail :: struct {
	x, y:          f32,
	width, height: f32,
	active:        bool,
	cor:           []rl.Color,
	durability:    i32,
}

Reset_game :: struct {
	player_reset:       Paddle,
	ball_reset:         Ball,
	jail_reset:         Jail,
	playerScore, lives: i32,
}

ball: Ball
player: Paddle
jail: Jail
restart: Reset_game
main :: proc() {


	screen_width :: 450
	screen_height :: 500

	rl.InitWindow(screen_width, screen_height, "Breakout 1967 LOOP OF DEATH")
	rl.InitAudioDevice()
	rl.SetTargetFPS(60)

	defer rl.CloseWindow()
	defer rl.CloseAudioDevice()

	paddle_sound := rl.LoadSound("jogo_2/assets/Audio/Blip.wav")
	win_sound := rl.LoadSound("jogo_2/assets/Audio/Win_test.wav")
	boom_sound := rl.LoadSound("jogo_2/assets/Audio/Boom.wav")

	defer rl.UnloadSound(win_sound)
	defer rl.UnloadSound(paddle_sound)
	defer rl.UnloadSound(boom_sound)

	ball.width = 10
	ball.height = 10
	ball.x = screen_width / 2
	ball.y = screen_height / 2
	ball.speed_x = 4
	ball.speed_y = 8
	ball.old_speed_x = ball.speed_x
	ball.old_speed_y = ball.speed_y

	player.width = 30
	player.height = 10
	player.x = screen_width / 2 - 30
	player.y = screen_height - 50
	player.speed = 10

	jail.height = 10
	jail.width = 30
	jail.x = 0
	jail.y = 80
	jail.active = true
	jail.cor = {rl.RED, rl.ORANGE, rl.YELLOW, rl.DARKGREEN, rl.DARKBLUE, rl.PURPLE, rl.SKYBLUE}
	jail.durability = 1

	restart.ball_reset = ball
	restart.jail_reset = jail
	restart.player_reset = player
	restart.playerScore = 0
	restart.lives = 5


	block: [91]Jail
	for &e in block {
		e = jail
	}

	for collum in 0 ..< 7 {
		for size in 0 ..< 13 {
			i := collum * 13 + size
			block[i].x = f32(2 + size * (int(block[i].width) + 5))
			block[i].y = f32(collum * int(block[i].y) / 5 + 40)
		}
	}
	for !rl.WindowShouldClose() {

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawText(rl.TextFormat("%d", lives), screen_width / 4 - 20, 20, 20, rl.WHITE)

		rl.DrawText(rl.TextFormat("%d", playerScore), 3 * screen_width / 4 - 20, 20, 20, rl.WHITE)


		Update(&ball, win_sound)
		Draw(ball)
		Check(&player, &ball, paddle_sound)

		for i in 0 ..< len(block) {
			if !block[i].active do continue
			Check_jail(&block[i], &ball, boom_sound)
		}

		Update_rec(&player)
		Draw_rec(player)
		for collum in 0 ..< 7 {
			for size in 0 ..< 13 {
				i := collum * 13 + size
				if block[i].active == true {

					rl.DrawRectangle(
						i32(block[i].x),
						i32(block[i].y),
						i32(block[i].width),
						i32(block[i].height),
						jail.cor[collum],
					)
				}
			}
		}

		if lives <= 0 {
			player = restart.player_reset
			ball = restart.ball_reset
			lives = restart.lives
			playerScore = restart.playerScore

			for i in 0 ..< len(block) {
				if !block[i].active {
					block[i].active = true
				}
			}
		}
		if round > round_old {
			player = restart.player_reset
			ball = restart.ball_reset
			lives = restart.lives
			playerScore = restart.playerScore
			round_old = round

			for i in 0 ..< len(block) {
				if !block[i].active {
					block[i].durability = 1 * round
					block[i].active = true
				}
			}

		}
		rl.EndDrawing()
	}

}
