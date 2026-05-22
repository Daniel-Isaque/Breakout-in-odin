package main

import "core:math/rand"
import rl "vendor:raylib"

playerScore: i32 = 0
lives: i32 = 5
round_old: i32 = 0
round: i32 = 0

BALL_DEFAULT_SPAWN_X: f32 : 225
BALL_DEFAULT_SPAWN_Y: f32 : 166
BALL_DEFAULT_WIDTH: f32 : 10
BALL_DEFAULT_HEIGHT: f32 : 10
BALL_SPEED_X: f32 : 4.0
BALL_SPEED_Y: f32 : 5.0

Ball :: struct {
	pos:              [2]f32,
	width, height:    f32,
	speed_x, speed_y: f32,
	active:           bool,
}

Draw :: proc(b: Ball) {
	rl.DrawRectangle(i32(b.pos[0]), i32(b.pos[1]), i32(b.width), i32(b.height), rl.WHITE)
}

Update :: proc(b: ^Ball, s: rl.Sound) {
	b.pos[0] += b.speed_x + 0.2 * f32(round + 1)
	b.pos[1] += b.speed_y + 0.2 * f32(round)

	if i32(b.pos[0] + b.width) >= rl.GetScreenWidth() {
		b.pos[0] = f32(rl.GetScreenWidth()) - b.width
		b.speed_x = -BALL_SPEED_X

	}
	if b.pos[0] <= 0 {
		b.pos[0] = 0
		b.speed_x = BALL_SPEED_X
	}

	if b.pos[1] >= f32(rl.GetScreenHeight()) {
		lives -= 1
		ResetBall(&b^)
	}

	// o que eh pra ser isso, porque sair da tela por cima te aumenta um round?
	if b.pos[1] <= 0 {
		rl.PlaySound(s)
		// aqui voce deveria refletir pra baixo, mas como nao fez isso, nao sei se descomentar
		// b.speed = BALL_SPEED_Y
		round += 1
	}
}

ResetBall :: proc(b: ^Ball) {

	b.pos[0] = f32(rl.GetScreenWidth() / 2)
	b.pos[1] = f32(rl.GetScreenHeight() / 3)

	lista := [2]f32{-1, 1}

	decision: f32 = lista[rand.int_max(2)]
	b.speed_x *= decision

}


Paddle :: struct {
	x, y:          f32,
	width, height: f32,
	speed:         f32,
}

DrawRec :: proc(p: Paddle) {
	rl.DrawRectangle(i32(p.x), i32(p.y), i32(p.width), i32(p.height), rl.BLUE)
}

UpdateRec :: proc(p: ^Paddle) {
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

Check_Bounces :: proc(p: ^Paddle, b: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{b.pos[0], b.pos[1], b.width, b.height},
		rl.Rectangle{p.x, p.y, p.width, p.height},
	) {
		paddle_mid_y := p.y + (p.height / 2.0)
		ball_bottom := b.pos[1] + b.height

		// checando isso pq a bola se salva o tempo todo
		if ball_bottom > paddle_mid_y {
			return
		}

		rl.PlaySound(s)

		b.pos[1] = p.y - b.height
		b.speed_y = -BALL_SPEED_Y

		paddle_center := p.x + (p.width / 2.0)
		ball_center := b.pos[0] + (b.width / 2.0)

		if ball_center < paddle_center {
			b.speed_x = -BALL_SPEED_X
		} else {
			b.speed_x = BALL_SPEED_X
		}
	}
}

CheckJail :: proc(p: ^Jail, b: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{b.pos[0], b.pos[1], b.width, b.height},
		rl.Rectangle{p.x, p.y, p.width, p.height},
	) {

		/*
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
		*/

		p.durability -= 1
		if p.durability <= 0 {
			p.active = false
			rl.PlaySound(s)
			playerScore += 1
		}

		// mais simples. se quiser reimplementar o bgl, deixei comentado ali a versao velha.
		if b.speed_y < 0 {
			b.speed_y = BALL_SPEED_Y
		} else {
			b.speed_y = -BALL_SPEED_Y
		}
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

GiveNewBall :: proc(balls: ^[dynamic]Ball) {
	is_default_spawn: bool = (len(balls) == 0)

	// isso aqui quebra quando eu saio da tela por cima! consertar!
	spawn_position: [2]f32 = {
		is_default_spawn ? BALL_DEFAULT_SPAWN_X : balls[0].pos.x,
		is_default_spawn ? BALL_DEFAULT_SPAWN_Y : balls[0].pos.y,
	}

	for &ball in balls {
		if !ball.active {
			ball.pos = spawn_position
			ball.active = true
			ball.width = BALL_DEFAULT_WIDTH
			ball.height = BALL_DEFAULT_HEIGHT
			ball.speed_x = BALL_SPEED_X
			ball.speed_y = BALL_SPEED_Y
			return
		}
	}

	new_ball: Ball = {
		pos     = spawn_position,
		active  = true,
		width   = BALL_DEFAULT_WIDTH,
		height  = BALL_DEFAULT_HEIGHT,
		speed_x = BALL_SPEED_X,
		speed_y = BALL_SPEED_Y,
	}

	append(balls, new_ball)
}

block: Ball
player: Paddle
jail: Jail
restart: Reset_game
main :: proc() {
	block.pos = {BALL_DEFAULT_SPAWN_X, BALL_DEFAULT_SPAWN_Y}
	block.height = 10
	block.active = true
	block.speed_x = BALL_SPEED_X
	block.speed_y = BALL_SPEED_Y

	ball: [dynamic]Ball = make([dynamic]Ball, 0, 32)

	screen_width :: 450
	screen_height :: 500

	rl.InitWindow(screen_width, screen_height, "Breakout 1967 LOOP OF DEATH")
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

	player.width = 70
	player.height = 10
	player.x = screen_width / 2 - 30
	player.y = screen_height - 50
	player.speed = 12

	jail.height = 10
	jail.width = 30
	jail.x = 0
	jail.y = 80
	jail.active = true
	jail.cor = {rl.RED, rl.ORANGE, rl.YELLOW, rl.DARKGREEN, rl.DARKBLUE, rl.PURPLE, rl.SKYBLUE}
	jail.durability = 1

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


	GiveNewBall(&ball)
	for !rl.WindowShouldClose() {

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)

		rl.DrawText(rl.TextFormat("%d", lives), screen_width / 4 - 20, 20, 20, rl.WHITE)

		rl.DrawText(rl.TextFormat("%d", playerScore), 3 * screen_width / 4 - 20, 20, 20, rl.WHITE)
		for i in 0 ..< len(block) {
			if !block[i].active do continue
			CheckJail(&block[i], &ball[0], boom_sound)
		}
		Draw(ball[0])
		Update(&ball[0], win_sound)

		for i := len(ball) - 1; i >= 0; i -= 1 {
			balls := &ball[i]
			if !balls.active do return
			Check_Bounces(&player, balls, paddle_sound)
			if balls.pos[1] > f32(rl.GetScreenHeight()) {
				unordered_remove(&ball, i)
			}
		}

		Check_Bounces(&player, &ball[0], paddle_sound)

		UpdateRec(&player)
		DrawRec(player)
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
		if len(ball) == 0 && lives < 0 {
			GiveNewBall(&ball)
		}
		if lives <= 0 {
			player = restart.player_reset
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
			lives = restart.lives
			GiveNewBall(&ball)
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
