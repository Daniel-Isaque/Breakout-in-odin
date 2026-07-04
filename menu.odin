package breakout

import f "core:fmt"
import "core:math"
import rat "rat-engine"
import rl "vendor:raylib"

UpdateMenu :: proc(world: ^World, assets: GameAssets) {
	option_count: int = 0
	switch (world.menu_state) {
	case .Main:
		option_count = int(MenuOptions.Count)
	case .Settings:
		option_count = int(SettingsOptions.Count)
	}
	if rl.IsKeyPressed(.DOWN) && (world.cursor + i32(1)) < i32(option_count) {
		world.cursor += i32(1)
		rl.PlaySound(assets.menu_swap)
	}
	if rl.IsKeyPressed(.UP) && (world.cursor - i32(1)) >= 0 {
		world.cursor -= i32(1)
		rl.PlaySound(assets.menu_swap)
	}
	switch (world.menu_state) {
	case .Main:
		if rl.IsKeyPressed(.ENTER) {
			rl.PlaySound(assets.menu_select)
			#partial switch (MenuOptions(world.cursor)) {
			case .Play:
				world.game_state = .Loop
			case .Settings:
				world.cursor = 0
				world.menu_state = .Settings
			case .Close:
				f.printfln("Bye")
				world.should_close = true
			}
		}
	case .Settings:
		if rl.IsKeyPressed(.LEFT) && (world.volume - 1) >= 0 {
			world.volume -= 1
			rl.PlaySound(assets.menu_swap)
			rl.SetMasterVolume(f32(world.volume / 10))
		}
		if rl.IsKeyPressed(.RIGHT) && (world.volume + 1) < 11 {
			world.volume += 1
			rl.PlaySound(assets.menu_swap)
			rl.SetMasterVolume(world.volume / 10)
		}

		if rl.IsKeyPressed(.BACKSPACE) {
			world.cursor = 0
			world.menu_state = .Main

		}
	}

}
UpdateGame :: proc(world: ^World, assets: GameAssets) {
	player := &world.player.data[0]
	if rl.IsKeyPressed(.ENTER) {
		rl.PlaySound(assets.menu_select)
		world.game_state = .Menu
	}
	world.bg_counter += 1
	if world.bg_counter >= 5 {
		world.bg_counter = 0
		world.bg_index += 1
		if world.bg_index >= 4 do world.bg_index = 0
	}

	UpdatePaddle(player, world)

	for i := int(world.balls.count) - 1; i >= 0; i -= 1 {
		id := world.balls.dense[i]
		ball := &world.balls.data[i]

		UpdateBallVisuals(world, ball)

		vel_x := ball.speed_x + (math.sign(ball.speed_x) * ball.speed_boost)
		vel_y := ball.speed_y + (math.sign(ball.speed_y) * ball.speed_boost)
		max_vel := math.max(math.abs(vel_x), math.abs(vel_y))

		sub_steps := int(math.ceil(max_vel / 4.0))
		if sub_steps < 1 do sub_steps = 1
		step_dt := 1.0 / f32(sub_steps)

		for s in 0 ..< sub_steps {
			UpdateBallPhysics(world, ball, assets.win_sound, step_dt)

			if !player.paddle_bounced && CheckVisualHit(player, ball) {
				angle = math.PI * 0.1
				player.paddle_bounced = true
			}

			CheckPaddleBounces(player, ball, world, assets.paddle_sound)

			for j in 0 ..< len(world.blocks) {
				if !world.blocks[j].active do continue
				CheckBlocks(world, &world.blocks[j], ball, assets.boom_sound)
			}
		}

		if ball.pos.y > SCREEN_HEIGHT {
			rat.remove(&world.balls, id)
			if world.balls.count == 0 {
				world.lives -= 1
				GiveNewBall(world)
			}
		}
	}

	rat.UpdateTimers(&world.timers)

	if world.balls.count == 0 && world.lives < 0 {
		GiveNewBall(world)
	}

	if world.lives <= 0 {
		ResetGame(player, world)
	}

	if world.win_condition {
		world.win_condition = false
		player.x = PADDLE_DEFAULT_SPAWN_X
		player.y = PADDLE_DEFAULT_SPAWN_Y
		world.lives = 5
		world.round += 1

		rat.clear_sparse_set(&world.balls)
		for i in 0 ..< world.round + 1 {
			GiveNewBall(world, f32(i) * 1.5 - f32(world.round) * 0.75)
		}

		for i in 0 ..< len(world.blocks) {
			if !world.blocks[i].active {
				world.blocks[i].durability = 1 * world.round
				world.blocks[i].active = true
			}
		}
	}
	update_particles(&world.particles)
	UpdateScreenshake(&game_camera)
}
