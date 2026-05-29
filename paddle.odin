package breakout

import "core:math"
import rl "vendor:raylib"

PADDLE_DEFAULT_SPAWN_X: f32 : 195
PADDLE_DEFAULT_SPAWN_Y: f32 : 450

Paddle :: struct {
	x, y:          f32,
	width, height: f32,
	speed:         f32,
}

DrawPaddle :: proc(p: Paddle) {
	rl.DrawRectangle(i32(p.x), i32(p.y), i32(p.width), i32(p.height), rl.BLUE)
}

UpdatePaddle :: proc(p: ^Paddle) {
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

CheckPaddleBounces :: proc(p: ^Paddle, b: ^Ball, world: ^World, s: rl.Sound) {
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
		b.color = rl.ORANGE
		SquashBall(world, b.id)
		rl.PlaySound(s)

		b.pos.y = p.y - b.height
		b.speed_y *= -1
		b.speed_boost += BALL_SPEED_INCREMENT

		paddle_center := p.x + (p.width / 2.0)
		ball_center := b.pos.x + (b.width / 2.0)

		if ball_center < paddle_center {
			b.speed_x = -math.abs(b.speed_x)
		} else {
			b.speed_x = math.abs(b.speed_x)
		}
	}
}
