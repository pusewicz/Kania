# Phase 1: Kania over CF

Started 2026-09-28. Plan: [Kania Framework Plan](https://claude.ai/artifact/Kw2QXw8pMyzb2q3T8GV71Y), phase 1.

Phase 1 ships Kania's Swift API over CF. From the end of this phase the API is the fixed contract,
and its tests are the oracle for every later phase, so the decisions below are made here and not
deferred to the phases that later rewrite each subsystem.

## Decisions (2026-09-28)

| Question | Decision |
|---|---|
| How games consume Kania | **CMake.** Kania is a CMake project that builds CF as a subproject and Kania's Swift targets with CMake's Swift support. Games are CMake projects that pull Kania in with `FetchContent`. `Package.swift`, `Scripts/build-cf.sh` and the `unsafeFlags` link line go once CMake builds CF, the samples and the benchmarks. SwiftPM support may come back later as its own task. |
| Isolation | **`@MainActor`.** SDL3 wants windowing and events on the main thread, and CF's state is global. The public API is annotated explicitly rather than through a module-wide default-isolation flag, so the isolation shows in the interface whatever the build system. |
| GPU and audio handles | **`~Copyable` owners plus `Hashable` IDs.** `Texture`, `Canvas`, `Shader`, `Mesh`, `Material`, `Audio` and the other types CF makes you destroy are `~Copyable` structs whose `deinit` queues the destroy. Each has a copyable, `Hashable` `ID` for dictionary keys and non-owning references. Types with nothing to destroy (`Sprite`, `Color`, vectors, transforms) stay copyable. |
| Errors | **Typed `throws`** in place of `CF_Result`. Swift 6.4's typed-throwing `Task` initializers carry the same error type across `async` code. |
| Draw path | **Value-type sprites, mutated in place.** The API is expected to take `inout [Sprite]` and iterate through `mutableSpan` inside. That is pending the benchmark below. |

## What the decisions imply

- **Destroys wait for the end of the frame.** CF releases GPU objects through `SDL_ReleaseGPU*`, which
  waits until the GPU is done with them. But CF's draw batch keeps texture ids until
  `cf_app_draw_onto_screen` flushes it, so a texture destroyed mid-frame after being drawn is a
  use-after-free at the flush. `deinit` therefore queues the destroy, and the app loop drains the
  queue after the flush. An explicit `destroy()` would need the same queue.
- **The frame loop has to let main-actor tasks run, on the main thread.** A synchronous `while` loop
  on the main thread never returns to the main queue. On macOS, SDL's event pump is expected to drain
  it, because it runs the main run loop. On Linux nothing drains it, and the plan already notes that
  `DispatchQueue.main` is not the main thread on Windows. Swift's custom main executors, which would
  let Kania drain the main actor itself each frame, are still a pitch (fourth revision, August 2026).
  So the app loop is `async`, entered from an `async` `@main`, and suspends once per frame. A test on
  all three desktop OSes checks two things: a `Task { @MainActor in }` created during one frame has
  run by the next, and `SDL_IsMainThread()` is true inside the loop. If the second fails on Windows,
  the main actor is not the OS main thread there, and the loop has to be a synchronous main-thread
  loop that drains its own queue instead.
- **`~Copyable` handles spread to whatever stores them.** A struct that stores a `Texture` must itself
  be `~Copyable`, and `Array`, `Set` and `Dictionary` can't hold them. The `ID` types, and borrow
  accessors such as `canvas.texture`, keep that out of ordinary game code. Handles are also
  `~Sendable` (SE-0518, Swift 6.4), so they cannot leave the main actor, and their `deinit` runs there.
- **CF can still hold a dangling id.** A material stores its textures' raw ids inside CF, so Swift
  cannot stop a material from outliving a texture it uses.

## Open

- **`inout [Sprite]` against the alternatives.** Phase 0 measured iteration through `MutableSpan`
  (within 1–4% of C at 10k sprites), not an `inout Array` parameter. `SpriteBench` gets two more
  variants, an `inout [Sprite]` parameter and Swift 6.4's `UniqueArray`, which has no copy-on-write
  checks. The C twin does not change.
- **3D scope** (draw 3D, models, Box3D). This decides the size of the "remaining subsystems" task.
