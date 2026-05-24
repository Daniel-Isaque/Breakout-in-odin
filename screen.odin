package breakout

import "core:math/rand"
import rl "vendor:raylib"

game_camera: rl.Camera2D
trauma: f32 = 0
seconds: f32 = 0

TriggerShake :: proc(trauma_value: f32) {
	trauma = trauma_value
}

ScreenShake :: proc(cam: ^rl.Camera2D, maxOffset: f32) {

	//simple clock maybe dumb but will work
	if trauma >= 0 {
		shake: f32
		shake = trauma * trauma

		//trauma must be a value between 0 and 1 also shake is trauma^2 or trauma^3
		//this define how much the camera will move
		offsetX: f32 = SCREEN_WIDTH / 2 + maxOffset * shake * random_range(-1, 1)
		offsetY: f32 = SCREEN_HEIGHT / 2 + maxOffset * shake * random_range(-1, 1)
		cam.offset = {offsetX, offsetY}
	} else {
		// Resets at center
		cam.offset.x = f32(rl.GetScreenWidth()) / 2
		cam.offset.y = f32(rl.GetScreenHeight()) / 2
	}
}

// vlambeer screenshake

screenshake: f32 = 0
center: [2]f32 = {SCREEN_WIDTH / 2.0, SCREEN_HEIGHT / 2.0}

AddShake :: #force_inline proc(amount: f32) {
	screenshake += amount
}

UpdateScreenshake :: proc(cam: ^rl.Camera2D) {
	if screenshake >= 10.0 do screenshake *= 0.8
	if screenshake > 0.0 do screenshake -= 1.0
	else do screenshake = 0.0

	shake_offset := [2]f32{0, 0}
	if screenshake > 0.0 {
		shake_offset = {
			rand.float32() * screenshake - screenshake / 2.0,
			rand.float32() * screenshake - screenshake / 2.0,
		}
	}

	cam.offset = center + shake_offset
}
