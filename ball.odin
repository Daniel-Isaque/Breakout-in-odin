package breakout

import "core:math"
import "core:math/rand"
import rat "rat-engine"
import rl "vendor:raylib"

BALL_DEFAULT_SPAWN_X: f32 : 225
BALL_DEFAULT_SPAWN_Y: f32 : 166
BALL_DEFAULT_WIDTH: f32 : 10
BALL_DEFAULT_HEIGHT: f32 : 10
BALL_HEIGHT: i32 : 10
BALL_SPEED_X: f32 : 4.0
BALL_SPEED_Y: f32 : 5.0

BALL_SPEED_INCREMENT: f32 : 0.05

trail_palette: []rl.Color = {rl.GRAY, rl.ORANGE, rl.YELLOW, rl.WHITE}

Ball :: struct {
	id:               rat.Id,
	pos:              [2]f32,
	width, height:    f32,
	target_scale:     [2]f32,
	visual_scale:     [2]f32,
	speed_x, speed_y: f32,
	speed_boost:      f32,
	color:            rl.Color,
}

GetBallRect :: proc(b: Ball) -> rl.Rectangle {
	return {b.pos.x - b.width / 2, b.pos.y - b.height / 2, b.width, b.height}
}

DrawBall :: proc(b: Ball) {
	aura_factor := math.clamp(b.speed_boost, 0, 1.0)
	if aura_factor > 0.05 {
		aura_color := b.color
		aura_color.a = u8(125.0 * aura_factor)
		radius := (b.width / 2.0) + (b.width / 2.0 * aura_factor)
		rl.DrawCircleV(b.pos, radius, aura_color)
	}

	rl.DrawRectangle(
		i32(b.pos.x - b.visual_scale.x / 2),
		i32(b.pos.y - b.visual_scale.y / 2),
		i32(b.visual_scale.x),
		i32(b.visual_scale.y),
		b.color,
	)
}

UpdateBallVisuals :: proc(world: ^World, b: ^Ball) {
	if b.visual_scale != b.target_scale {
		b.visual_scale.x = math.lerp(b.visual_scale.x, b.target_scale.x, f32(0.1))
		b.visual_scale.y = math.lerp(b.visual_scale.y, b.target_scale.y, f32(0.1))
	}

	factor := math.clamp(b.speed_boost, 0, 1.0)
	val := u8(255.0 * (1.0 - factor))
	b.color = rl.Color{255, val, val, 255}

	arbitrary_speed_value: f32 = BALL_SPEED_X * 1.25
	current_speed_x := math.abs(b.speed_x) + b.speed_boost
	if current_speed_x > arbitrary_speed_value {
		create_particle_rad(
			&world.particles,
			ParticleDto {
				pos = b.pos + [2]f32{random_range(-2, 2), random_range(-2, 2)},
				angle = 0,
				color = rl.WHITE,
				lifetime = 16,
				scale = {4, 4},
				shape = .CIRCLE,
				shrink = true,
				shrink_factor = 0.1,
				speed = 0,
				color_fade = true,
				color_palette = &trail_palette,
			},
		)

	}
}

UpdateBallPhysics :: proc(world: ^World, b: ^Ball, s: rl.Sound, step: f32) {
	if i32(b.pos.x + b.width / 2) >= rl.GetScreenWidth() {
		b.pos.x = f32(rl.GetScreenWidth()) - b.width / 2
		b.speed_x *= -1
		b.speed_boost += BALL_SPEED_INCREMENT
		AddShake(4)
		SquashBall(world, b.id)
	}

	if b.pos.x - b.width / 2 <= 0 {
		b.pos.x = b.width / 2
		b.speed_x *= -1
		b.speed_boost += BALL_SPEED_INCREMENT
		AddShake(4)
		SquashBall(world, b.id)
	}

	b.pos.x += (b.speed_x + (math.sign(b.speed_x) * b.speed_boost)) * step
	b.pos.y += (b.speed_y + (math.sign(b.speed_y) * b.speed_boost)) * step

	if b.pos.y - b.height / 2 <= 0 {
		rl.PlaySound(s)
		world.win_condition = true
	}
}

ResetBall :: proc(b: ^Ball) {

	b.pos.x = f32(rl.GetScreenWidth() / 2)
	b.pos.y = f32(rl.GetScreenHeight() / 3)

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

	if is_default_spawn {
		spawn_position.x += BALL_DEFAULT_WIDTH / 2
		spawn_position.y += BALL_DEFAULT_HEIGHT / 2
	}

	new_ball: Ball = {
		id           = id,
		pos          = spawn_position,
		width        = BALL_DEFAULT_WIDTH,
		height       = BALL_DEFAULT_HEIGHT,
		visual_scale = [2]f32{BALL_DEFAULT_WIDTH, BALL_DEFAULT_HEIGHT},
		target_scale = [2]f32{BALL_DEFAULT_WIDTH, BALL_DEFAULT_HEIGHT},
		speed_x      = BALL_SPEED_X + angle_offset,
		speed_y      = BALL_SPEED_Y,
		speed_boost  = 0,
		color        = rl.WHITE,
	}

	rat.add(&world.balls, id, new_ball)
}

BallScaleHelper :: struct {
	world: ^World,
	id:    rat.Id,
}

ResetScale :: proc(raw: rawptr) {
	data := (^BallScaleHelper)(raw)
	defer free(data)

	ball, ok := rat.get(&data.world.balls, data.id)
	if ok {
		ball.target_scale = [2]f32{BALL_DEFAULT_WIDTH, BALL_DEFAULT_HEIGHT}
	}
}

SquashBall :: proc(world: ^World, ball_id: rat.Id) {
	ball, ok := rat.get(&world.balls, ball_id)
	if !ok do return

	ball.visual_scale = [2]f32{BALL_DEFAULT_WIDTH * 1.5, BALL_DEFAULT_HEIGHT * 1.3}
	ball.target_scale = [2]f32{BALL_DEFAULT_WIDTH * 1.5, BALL_DEFAULT_HEIGHT * 1.3}

	data := new(BallScaleHelper)
	data.world = world
	data.id = ball_id

	append(
		&world.timers,
		rat.Timer{counter = 0, data = data, frame_target = 3, onComplete = ResetScale},
	)
}
