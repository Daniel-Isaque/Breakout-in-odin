# Rat Engine — Quick Start (for Breakout)

You're using three small pieces of a friend's game engine. They exist to solve
**one problem**: in a game, things (balls, particles, timers) get created and
destroyed constantly. If you hold a raw pointer to one of them and it gets
destroyed, your pointer now points at garbage — that's a *dangling pointer*, and
it causes random crashes that are painful to track down.

These three tools let you avoid that entirely.

## 1. The `Id` — a safe "handle" to an object

Instead of passing around a pointer to a ball, you pass around an `Id` (just a
number).

```odin
id := create_object(&world)   // gives you back an Id
```

The clever part: an `Id` is **generational**. If ball #5 dies and slot #5 gets
reused by a brand-new ball, the new ball gets a *different* `Id` even though it
reuses the same memory. So an old `Id` can never accidentally point at the wrong
object — the engine detects it's stale and tells you "that's gone."

**Rule of thumb:** store `Id`s, not pointers. Pointers are fine to use *right
now, this frame*. Never save a pointer for later.

## 2. The `SparseSet` — a bag of objects you look up by `Id`

A `SparseSet` holds a bunch of the same kind of thing (e.g. all your balls). You
add/remove/look-up by `Id`:

```odin
world.balls : rat.SparseSet(Ball)        // a bag of Balls

rat.add(&world.balls, id, new_ball)      // put a ball in
ball, ok := rat.get(&world.balls, id)    // look one up by id
if ok {
    ball.speed_x = -4                    // safe to use right here
}
rat.remove(&world.balls, id)             // take one out
```

`get` returns `ok = false` when the `Id` is stale or the object is gone — so you
always check `ok` before touching it. That check is what saves you from dangling
pointers.

Other handy calls:

- `rat.has(&world.balls, id)` → true/false, "is this still alive?"
- `rat.entities(&world.balls)` → the list of live ids, for looping
- `rat.clear_sparse_set(&world.balls)` → empty the whole bag (you use this on game reset)

> ⚠️ **One gotcha:** the pointer from `get` is only good until the next
> `add`/`remove` on that set. If you remove something, any pointer you were
> holding may now point at a *different* object (the set shuffles things to stay
> packed). Just call `get` again after you change the set.

## 3. The `Timer` — "run this code in N frames"

This is exactly what you're already doing with the ball squash effect. You want
to squash the ball, then un-squash it 3 frames later:

```odin
// schedule it
append(&world.timers, rat.Timer{
    frame_target = 3,            // fire after 3 frames
    data         = my_data,      // anything the callback needs
    onComplete   = ResetScale,   // the function to run
})

// the callback
ResetScale :: proc(raw: rawptr) { ... }

// tick all timers once per frame (you do this in main)
rat.UpdateTimers(&world.timers)
```

**Why this matters for you specifically:** your timer callback often needs to
touch a ball that might have died during those 3 frames. That's why `ResetScale`
looks the ball up by `Id` and checks `ok`:

```odin
ball, ok := rat.get(&data.world.balls, data.id)
if ok {
    ball.target_scale = {...}   // only if the ball is still alive
}
```

If the ball is gone, the timer just does nothing instead of crashing. That's the
whole point of the system working together.

## The one mental model to remember

> **Don't keep pointers. Keep `Id`s. Look up the pointer fresh each time, and
> check `ok`.**

Anything that lives across multiple frames — balls, anything a timer touches —
should be referenced by `Id`. Things that live and die within a single frame
(like your particles) don't need this; they're fine as plain structs in an array.
