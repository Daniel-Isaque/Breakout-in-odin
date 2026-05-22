package breakout

import "core:math"
import "core:math/rand"

// returns a random f32 in range. inclusive.
random_range :: #force_inline proc(min, max: f32) -> f32 {
    return min + rand.float32() * (max - min)
}

// helpers that translate polar to cartesian velocity. to be used on particle spawn.
FromPolarDeg :: #force_inline proc(speed: f32, angle_degrees: f32) -> [2]f32 {
	angle_radians := math.to_radians_f32(angle_degrees)
    return [2]f32{
        math.cos(angle_radians) * speed,
        math.sin(angle_radians) * speed,
    }
}

FromPolarRad :: #force_inline proc(speed: f32, angle_radians: f32) -> [2]f32 {
    return [2]f32{
        math.cos(angle_radians) * speed,
        math.sin(angle_radians) * speed,
    }
}