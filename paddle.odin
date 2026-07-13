package breakout

import "core:math"
import ti "core:time"
import rat "rat-engine"
import box "vendor:box2d"
import rl "vendor:raylib"

PADDLE_DEFAULT_SPAWN_X: f32 : 195
PADDLE_DEFAULT_SPAWN_Y: f32 : 450
PADDLE_DEFAULT_VIRTUAL_X: f32 : 195
PADDLE_DEFAULT_VIRTUAl_Y: f32 : 400
PADDLE_DEFAULT_VISUAL_X: f32 : 65
PADDLE_DEFAULT_VISUAL_Y: f32 : 100
Paddle :: struct {
	id:             rat.Id,
	x, y:           f32,
	width, height:  f32,
	speed:          f32,
	virtual_pos:    rl.Vector2,
	visual_size:    rl.Vector2,
	visual_target:  rl.Vector2,
	paddle_bounced: bool,
	parry_active:   bool,
}
amplitude: f32 = 10
angle: f32 = 0
speedS: f32 = 0.06
DrawPaddle :: proc(p: Paddle, glorp: rl.Texture2D) {
	rl.DrawTexturePro(
		glorp,
		rl.Rectangle{0, 0, f32(glorp.width), f32(glorp.height)},
		rl.Rectangle{p.virtual_pos.x, p.virtual_pos.y, p.visual_size.x, p.visual_size.y},
		rl.Vector2{0, 0},
		0,
		rl.WHITE,
	)
}

SpawnPlayer :: proc(world: ^World) {
	id := create_object(world)

	new_paddle: Paddle = {
		id            = id,
		width         = 60,
		height        = 10,
		x             = PADDLE_DEFAULT_SPAWN_X,
		y             = PADDLE_DEFAULT_SPAWN_Y - 10,
		speed         = 12,
		virtual_pos   = {PADDLE_DEFAULT_VIRTUAL_X, PADDLE_DEFAULT_VIRTUAl_Y},
		visual_size   = {65, 100},
		visual_target = {PADDLE_DEFAULT_VISUAL_X, PADDLE_DEFAULT_VISUAL_Y},
		parry_active  = false,
	}
	rat.add(&world.player, id, new_paddle)
}

UpdatePaddle :: proc(p: ^Paddle, world: ^World) {


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
		p.x = f32(rl.GetScreenWidth()) - p.width
	}
	p.virtual_pos.x = p.x - 2

	if p.paddle_bounced {
		SquashPaddle(world, p.id)
		p.paddle_bounced = false
	}

	if rl.IsKeyPressed(.SPACE) && !p.parry_active {
		p.parry_active = true

		data_parry := new(PaddleHelper)
		data_parry.world = world
		data_parry.id = p.id

		append(
			&world.timers,
			rat.Timer{counter = 0, frame_target = 10, data = data_parry, onComplete = Parry},
		)

	}

}

Parry :: proc(raw: rawptr) {
	data := (^PaddleHelper)(raw)
	defer free(data)

	player, ok := rat.get(&data.world.player, data.id)
	if ok {
		player.parry_active = false
	}

}

BallSparkReset :: proc(raw: rawptr) {
	data := (^BallScaleHelper)(raw)
	defer free(data)

	ball, ok := rat.get(&data.world.balls, data.id)
	if ok {
		ball.ball_spark = false
	}
}

CheckPaddleBounces :: proc(p: ^Paddle, b: ^Ball, world: ^World, s: rl.Sound, parry: rl.Sound) {
	if rl.CheckCollisionRecs(GetBallRect(b^), rl.Rectangle{p.x, p.y, p.width, p.height}) {
		if b.speed_y < 0 {
			return
		}
		if p.parry_active && !b.ball_spark {
			b.ball_spark = true
			b.speed_boost += BALL_SPEED_INCREMENT * 10
			rl.PlaySound(parry)
			ti.sleep(ti.Second / 3)

			data_ball := new(BallScaleHelper)
			data_ball.world = world
			data_ball.id = b.id

			append(
				&world.timers,
				rat.Timer {
					counter = 0,
					frame_target = 60,
					data = data_ball,
					onComplete = BallSparkReset,
				},
			)
		}
		SquashBall(world, b.id)
		PlaySoundWithRandomPitch(s, 0.5, 0.8)

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
		rl.Rectangle(
			rl.Rectangle{p.virtual_pos.x, p.virtual_pos.y, p.visual_size.x, p.visual_size.y},
		),
	) {
		if b.speed_y < 0 {
			return false
		}
		return true
	}
	return false
}

ResetScaleP :: proc(raw: rawptr) {
	data := (^PaddleHelper)(raw)
	defer free(data)

	player, ok := rat.get(&data.world.player, data.id)
	if ok {
		player.visual_size.y = math.lerp(
			player.visual_size.y,
			player.visual_target.y + 20,
			f32(0.1),
		)

	}
}


PaddleHelper :: struct {
	world: ^World,
	id:    rat.Id,
}

SquashPaddle :: proc(world: ^World, paddle_id: rat.Id) {
	player, ok := rat.get(&world.player, paddle_id)
	if !ok do return

	// squash: scale Y down to a min then back up
	player.visual_size.y = math.lerp(player.visual_size.y, player.visual_target.y - 20, f32(0.1))


	data := new(PaddleHelper)
	data.world = world
	data.id = paddle_id

	append(
		&world.timers,
		rat.Timer{counter = 0, data = data, frame_target = 20, onComplete = ResetScaleP},
	)
}
