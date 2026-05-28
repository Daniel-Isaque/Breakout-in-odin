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
	color_id:      int,
}

CheckBlocks :: proc(world: ^World, block: ^Block, ball: ^Ball, s: rl.Sound) {
	if rl.CheckCollisionRecs(
		rl.Rectangle{ball.pos.x, ball.pos.y, ball.width, ball.height},
		rl.Rectangle{block.x, block.y, block.width, block.height},
	) {
		//		TriggerShake(0.8)
		AddShake(6)
		block.durability -= 1
		if block.durability <= 0 {
			block.active = false
			PlaySoundWithRandomPitch(s, 0.8, 1.2)
			CreateRadialParticleExplosion(
				&world.particles,
				ParticleDto {
					pos           = [2]f32{block.x, block.y},
					scale         = {8, 8},
					speed         = 2,
					color         = BlockColors[block.color_id],
					lifetime      = 45, // in frames
					shrink        = true,
					shrink_factor = 0.03,
					shape         = .RECTANGLE,
				},
				10,
				true,
			)


			world.player_score += 1
		}

		if ball.speed_y < 0 {
			ball.speed_y = BALL_SPEED_Y
		} else {
			ball.speed_y = -BALL_SPEED_Y
		}
	}
}

DrawBlocks :: proc(block_array: []Block) {
	for column in 0 ..< COLUMNS {
		for rows in 0 ..< ROWS {
			i := column * ROWS + rows
			if block_array[i].active == true {
				rl.DrawRectangle(
					i32(block_array[i].x),
					i32(block_array[i].y),
					i32(block_array[i].width),
					i32(block_array[i].height),
					BlockColors[column],
				)
			}
		}
	}
}

FillBlockArray :: proc(block_array: ^[]Block, default_block: Block) {
	for &e in block_array {
		e = default_block
	}

	for column in 0 ..< COLUMNS {
		for rows in 0 ..< ROWS {
			i := column * ROWS + rows
			block_array[i].color_id = column // set it here to make it easier to color explosions.
			block_array[i].x = f32(2 + rows * (int(block_array[i].width) + 5))
			block_array[i].y = f32(column * int(block_array[i].y) / 5 + 40)
		}
	}
}
