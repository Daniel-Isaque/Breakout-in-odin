package breakout

import rl "vendor:raylib"

BlockColors: []rl.Color = {
	rl.RED,
	rl.ORANGE,
	rl.YELLOW,
	rl.DARKGREEN,
	rl.DARKBLUE,
	rl.PURPLE,
	rl.SKYBLUE,
}

Block :: struct {
	x, y:          f32,
	width, height: f32,
	active:        bool,
	durability:    i32,
}

CheckBlocks :: proc(p: ^Block, b: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{b.pos.x, b.pos.y, b.width, b.height},
		rl.Rectangle{p.x, p.y, p.width, p.height},
	) {

		p.durability -= 1
		if p.durability <= 0 {
			p.active = false
			rl.PlaySound(s)
			player_score += 1
		}

		// mais simples. se quiser reimplementar o bgl, deixei comentado ali a versao velha.
		if b.speed_y < 0 {
			b.speed_y = BALL_SPEED_Y
		} else {
			b.speed_y = -BALL_SPEED_Y
		}
	}
}
