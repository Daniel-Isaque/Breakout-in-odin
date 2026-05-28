package breakout

import rat "rat-engine"

World :: struct {
	entity_manager: rat.EntityManager,
	timers:         [dynamic]rat.Timer,
	particles:      [dynamic]Particle,
	balls:          rat.SparseSet(Ball),
	blocks:         []Block,
	player_score:   i32,
	lives:          i32,
	round:          i32,
	win_condition:  bool,
}

create_world :: proc() -> World {
	return World {
		entity_manager = rat.create_entity_manager(),
		timers = make([dynamic]rat.Timer, 0, 32),
		particles = make([dynamic]Particle, 32),
		balls = rat.create_sparse_set(Ball, 1000),
		blocks = make([]Block, MAX_BLOCKS),
		player_score = 0,
		lives = 5,
		round = 0,
		win_condition = false,
	}
}

delete_world :: proc(world: ^World) {
	delete(world.particles)
	delete(world.timers)
	rat.delete_sparse_set(&world.balls)
}

create_object :: proc(world: ^World) -> rat.Id {
	id, ok := rat.entity_create(&world.entity_manager)
	assert(ok, "Failed to create entity, EntityManager is out of capacity.")

	return id
}
