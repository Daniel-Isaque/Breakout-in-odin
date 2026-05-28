package breakout

import rat "rat-engine"
import "core:math/rand"
import rl "vendor:raylib"

Ball :: struct {
	pos:              [2]f32,
	width, height:    f32,
	speed_x, speed_y: f32,
}

DrawBall :: proc(b: Ball) {
	rl.DrawRectangle(i32(b.pos[0]), i32(b.pos[1]), i32(b.width), i32(b.height), rl.WHITE)
}

UpdateBall :: proc(world: ^World, b: ^Ball, s: rl.Sound) {
	b.pos[0] += b.speed_x + 0.2 * f32(world.round + 1)
	b.pos[1] += b.speed_y + 0.2 * f32(world.round)

	if i32(b.pos[0] + b.width) >= rl.GetScreenWidth() {
		b.pos[0] = f32(rl.GetScreenWidth()) - b.width
		b.speed_x = -BALL_SPEED_X
		//TriggerShake(0.5)
		AddShake(4)
	}
	if b.pos[0] <= 0 {
		b.pos[0] = 0
		b.speed_x = BALL_SPEED_X
		//TriggerShake(0.5)
		AddShake(4)
	}

	// o que eh pra ser isso, porque sair da tela por cima te aumenta um round?
	if b.pos[1] <= 0 {
		rl.PlaySound(s)
		world.win_condition = true
	}
}

ResetBall :: proc(b: ^Ball) {

	b.pos[0] = f32(rl.GetScreenWidth() / 2)
	b.pos[1] = f32(rl.GetScreenHeight() / 3)

	lista := [2]f32{-1, 1}

	decision: f32 = lista[rand.int_max(2)]
	b.speed_x *= decision
}

GiveNewBall :: proc(world: ^World, angle_offset: f32 = 0) {
	id := create_object(world)

	is_default_spawn: bool = (world.balls.count == 0)

	// isso aqui quebra quando eu saio da tela por cima! consertar!
	spawn_position: [2]f32 = {
		is_default_spawn ? BALL_DEFAULT_SPAWN_X : world.balls.data[0].pos.x,
		is_default_spawn ? BALL_DEFAULT_SPAWN_Y : world.balls.data[0].pos.y,
	}

	new_ball: Ball = {
		pos     = spawn_position,
		width   = BALL_DEFAULT_WIDTH,
		height  = BALL_DEFAULT_HEIGHT,
		speed_x = BALL_SPEED_X + angle_offset,
		speed_y = BALL_SPEED_Y,
	}

	rat.add(&world.balls, id, new_ball)
}
