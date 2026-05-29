package rat

CallbackAction :: proc(_: rawptr)

Timer :: struct {
	frame_target: i32,
	counter:      i32,
	data:         rawptr,
	onComplete:   CallbackAction,
}

AddTimer :: proc(timers: ^[dynamic]Timer, timer: Timer) {
	append(timers, timer)
}

UpdateTimers :: proc(timers: ^[dynamic]Timer) {
	for i := len(timers) - 1; i >= 0; i -= 1 {
		timer := &timers[i]

		if timer.counter < timer.frame_target {
			timer.counter += 1
		}

		if timer.counter >= timer.frame_target {
			// Copy off the array, then remove, then fire — so a callback that
			// schedules another timer (and may realloc this array) can't dangle.
			t := timer^
			unordered_remove_dynamic_array(timers, i)
			if t.onComplete != nil do t.onComplete(t.data)
		}
	}
}
