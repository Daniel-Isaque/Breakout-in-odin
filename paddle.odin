package breakout

import "core:math"
import rl "vendor:raylib"

PADDLE_DEFAULT_SPAWN_X: f32 : 195
PADDLE_DEFAULT_SPAWN_Y: f32 : 450
PADDLE_DEFAULT_VISUAL_X: f32 : 195
PADDLE_DEFAULT_VISUAl_Y: f32 : 380
Paddle :: struct {
	x, y:           f32,
	width, height:  f32,
	speed:          f32,
	visual:         rl.Vector2,
	visual_size:    rl.Vector2,
	paddle_bounced: bool,
}
amplitude: f32 = 5
angle: f32 = 0
speedS: f32 = 0.06
DrawPaddle :: proc(p: Paddle, glorp: rl.Texture2D) {
	rl.DrawTexturePro(
		glorp,
		rl.Rectangle{0, 0, f32(glorp.width), f32(glorp.height)},
		rl.Rectangle{p.x, p.visual.y, p.visual_size.x, p.visual_size.y},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)
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
		p.x = f32(rl.GetScreenWidth()) - p.width - 10
	}
	p.visual.x = p.x

	if p.paddle_bounced {
		angle += speedS
		// squash: scale Y down to a min then back up
		t := math.sin(angle) // goes 0 -> 1 -> 0
		min_scale: f32 = 0.4 // how squashed it gets, tweak to taste
		scale := 1.0 - (t * (1.0 - min_scale))
		scale = math.max(scale, 0.3)

		p.visual_size.y = 100 * scale
		// keep it grounded by adjusting y so it doesnt float up
		p.visual.y = PADDLE_DEFAULT_VISUAl_Y + (t * amplitude) + (100 - p.visual_size.y)
		if angle > math.PI {
			angle = 0
			p.paddle_bounced = false
			p.visual_size.y = 100
			p.visual.y = PADDLE_DEFAULT_VISUAl_Y
		}
	}
}
CheckPaddleBounces :: proc(p: ^Paddle, b: ^Ball, world: ^World, s: rl.Sound) {
	if rl.CheckCollisionRecs(GetBallRect(b^), rl.Rectangle{p.x, p.y, p.width, p.height}) {
		if b.speed_y < 0 {
			return
		}
		SquashBall(world, b.id)
		rl.PlaySound(s)

		b.pos.y = p.y - b.height / 2
		b.speed_y *= -1
		b.speed_boost += BALL_SPEED_INCREMENT

		paddle_center := p.x + (p.width / 2.0)
		ball_center := b.pos.x

		if ball_center < paddle_center {
			b.speed_x = -math.abs(b.speed_x)
		} else {
			b.speed_x = math.abs(b.speed_x)
		}
	}
}

CheckVisualHit :: proc(p: ^Paddle, b: ^Ball) -> bool {
	if rl.CheckCollisionRecs(
		GetBallRect(b^),
		rl.Rectangle(rl.Rectangle{p.visual.x, p.visual.y, p.visual_size.x, p.visual_size.y}),
	) {
		if b.speed_y < 0 {
			return false
		}
		return true
	}
	return false
}
