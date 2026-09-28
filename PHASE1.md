# Phase 1: Kania over CF

Started 2026-09-28. Plan: [Kania Framework Plan](https://claude.ai/artifact/Kw2QXw8pMyzb2q3T8GV71Y), phase 1.

Phase 1 ships Kania's Swift API over CF. From the end of this phase the API is the fixed contract,
and its tests are the oracle for every later phase, so the decisions below are made here and not
deferred to the phases that later rewrite each subsystem.

## Decisions (2026-09-28)

| Question | Decision |
|---|---|
| How games consume Kania | **CMake.** Kania is a CMake project that builds CF as a subproject and Kania's Swift targets with CMake's Swift support. Games are CMake projects that pull Kania in with `FetchContent`. `Package.swift`, `Scripts/build-cf.sh` and the `unsafeFlags` link line are gone (see *CMake build* below). SwiftPM support may come back later as its own task. |
| Isolation | **`@MainActor`.** SDL3 wants windowing and events on the main thread, and CF's state is global. The public API is annotated explicitly rather than through a module-wide default-isolation flag, so the isolation shows in the interface whatever the build system. |
| GPU and audio handles | **`~Copyable` owners plus `Hashable` IDs.** `Texture`, `Canvas`, `Shader`, `Mesh`, `Material`, `Audio` and the other types CF makes you destroy are `~Copyable` structs whose `deinit` queues the destroy. Each has a copyable, `Hashable` `ID` for dictionary keys and non-owning references. Types with nothing to destroy (`Sprite`, `Color`, vectors, transforms) stay copyable. |
| Errors | **Typed `throws`** in place of `CF_Result`. Swift 6.4's typed-throwing `Task` initializers carry the same error type across `async` code. |
| Draw path | **Value-type sprites, `inout [Sprite]` in the signature, `mutableSpan` inside, and each sprite handed to CF in place.** Measured below: that loop matches C (+1.2% at 10k, −2.8% at 1k). Passing CF a copy instead costs up to 6%, indexing the `inout` array directly 9–10%, and a class-held `UniqueArray` 13–20%. |
| Minimum Apple versions | **Stay at macOS 26 and iOS 26.** The standard library's `UniqueArray` needs macOS 27 / iOS 27. Where Kania needs a noncopyable-capable array, it uses swift-collections' `BasicContainers.UniqueArray`, a stable module that runs on macOS 26 and builds with CMake. |

## What the decisions imply

- **Destroys wait for the end of the frame.** CF releases GPU objects through `SDL_ReleaseGPU*`, which
  waits until the GPU is done with them. But CF's draw batch keeps texture ids until
  `cf_app_draw_onto_screen` flushes it, so a texture destroyed mid-frame after being drawn is a
  use-after-free at the flush. `deinit` therefore queues the destroy, and the app loop drains the
  queue after the flush. An explicit `destroy()` would need the same queue.
- **SDL owns the frame loop; main-actor tasks still have to run between frames.** See *App loop*
  below.
- **`~Copyable` handles spread to whatever stores them.** A struct that stores a `Texture` must itself
  be `~Copyable`, and `Array`, `Set` and `Dictionary` can't hold them. The `ID` types, and borrow
  accessors such as `canvas.texture`, keep that out of ordinary game code. Handles are also
  `~Sendable` (SE-0518, Swift 6.4), so they cannot leave the main actor, and their `deinit` runs there.
- **CF can still hold a dangling id.** A material stores its textures' raw ids inside CF, so Swift
  cannot stop a material from outliving a texture it uses.

## Draw-path benchmark (2026-09-28)

Phase 0 measured iteration through `MutableSpan` but not an `inout` array parameter. `SpriteBench`
gained two variants:

- `overlay-inout` passes the array `inout` to a non-inlined function that indexes it, as a Kania API
  in another module would.
- `overlay-unique` stores the sprites in a class-held `BasicContainers.UniqueArray`, which has no
  copy-on-write checks.

The C twin did not change. Every checksum matches C. The numbers are from macOS arm64 (Apple M3
Max, Swift 6.4, `-O`): the median of 3 interleaved runs of 300 frames each, all in one batch
(`Results/macos-arm64-phase1.md`).

| count | impl | submit ms | vs C | runtime calls per sprite |
|---:|---|---:|---:|---|
| 1000 | c | 0.0493 | | |
| 1000 | overlay-span | 0.0521 | +5.7% | none |
| 1000 | overlay-inout | 0.0544 | +10.3% | none |
| 1000 | overlay-unique | 0.0590 | +19.7% | `swift_beginAccess` + `swift_endAccess` |
| 10000 | c | 0.5087 | | |
| 10000 | overlay-span | 0.5276 | +3.7% | none |
| 10000 | overlay-inout | 0.5545 | +9.0% | none |
| 10000 | overlay-unique | 0.5743 | +12.9% | `swift_beginAccess` + `swift_endAccess` |

- **An `inout` parameter removes the runtime calls but not all the overhead.** The disassembly
  shows the uniqueness check hoisted out of the loop, with no exclusivity checks inside it. After
  each call into C, though, the loop writes the buffer pointer back, reloads the count and
  re-checks bounds. That is because the C call is opaque, so the compiler can't assume the array
  is unchanged. A span's base and count are fixed for the whole loop, so none of that repeats.
- **`UniqueArray` in a class trades copy-on-write checks for exclusivity checks.** Each element
  access still goes through `swift_beginAccess` on the class property, so it lands between
  phase 0's `overlay-struct` and the span. Iterated through its own `mutableSpan` it would match
  `overlay-span`, so it gives the draw path nothing that `Array` plus `mutableSpan` doesn't.
- **So Kania's batch APIs take `inout [Sprite]`, which is familiar and needs no new types, and
  iterate through `mutableSpan` inside.** Game code that loops over its own sprites gets the same
  advice in the docs.

### Closing the last gap: no copy on the way into C

The span loop still trailed C. Its disassembly showed why: `Sprite.draw()` called
`withUnsafePointer(to: raw)` on a non-`inout` value, which points at a temporary, so all 144
bytes of `CF_Sprite` were copied to the stack before every `cf_draw_sprite`. `overlay-span-inplace`
hands CF the element's own storage (`cf_draw_sprite(&raw)` in a `mutating` method reached through
the span) and reads elements with `subscript(unchecked:)`. Its loop has no copy. The plain span
loop already had no per-element bounds-check traps, so the copy was the difference. One batch,
3 runs of 300 frames (`Results/macos-arm64-phase1-inplace.md`):

| count | impl | submit ms | vs C |
|---:|---|---:|---:|
| 1000 | c | 0.0538 | |
| 1000 | raw-buffer | 0.0530 | −1.5% |
| 1000 | overlay-span | 0.0542 | +0.7% |
| 1000 | overlay-span-inplace | 0.0523 | −2.8% |
| 10000 | c | 0.5193 | |
| 10000 | raw-buffer | 0.5268 | +1.4% |
| 10000 | overlay-span | 0.5491 | +5.7% |
| 10000 | overlay-span-inplace | 0.5255 | +1.2% |

The in-place loop is at C and at `raw-buffer`, the floor. Kania's draw path therefore never hands a
C function a pointer to a copied value: the internal loop passes each element's storage through
the span. Game code never sees this. The display paced frames to 16 ms during this batch, which
slows each run down but leaves `submit_ms` comparable within the batch. Going faster than C
means changing CF's per-sprite work, which is phase 6.


## CMake build (2026-09-28)

`CMakeLists.txt` adds CF as a subproject, and CF fetches SDL3, Box2D, Box3D and PhysFS. `CCute`
and the `Kania` library sit on top, and the samples and benchmarks build only when Kania is the
top-level project. `Examples/MinimalGame` pulls Kania in with `FetchContent`, as a game outside
the repository would, and CI builds and runs it against the checkout on all three OSes.

Gate, on macOS arm64:
- The `HelloTriangle` screenshot is byte-identical to the SwiftPM build's.
- Every benchmark checksum matches C.
- Each Swift variant's submit time is within 5% of its SwiftPM-built twin, inside batch noise
  and in no consistent direction.

On Linux aarch64 (Docker), the screenshot is byte-identical to macOS and every checksum matches.

CMake did less than SwiftPM had done implicitly, and each gap was silent until checked:

- **Swift 6 language mode.** CMake defaults to Swift 5 mode, which turns strict concurrency off.
  The build sets `CMAKE_Swift_LANGUAGE_VERSION 6` and whole-module optimization in Release.
- **The macOS deployment target.** CMake passes `CMAKE_OSX_DEPLOYMENT_TARGET` to C but not to
  Swift, so swiftc targeted the build machine's macOS 27. The build sets
  `CMAKE_Swift_COMPILER_TARGET` from it, and the binaries now say `minos 26.0`.
- **Which Swift.** With Ninja on macOS, CMake asks `xcrun` for `swiftc` and gets the Command Line
  Tools' Swift rather than the swiftly toolchain `.swift-version` pins. The presets take `swiftc`
  from `PATH`.
- **`-pthread` on Linux.** SDL3 (a link option) and s2n (through FindThreads) link with
  `-pthread`, which swiftc rejects. Swift links hand it to clang with `-Xclang-linker` instead.
  Kania creates `Threads::Threads` before CF so it can adjust it.
- **Windows.** Every configuration uses the release DLL C runtime, because Swift has no debug
  variant, and C and C++ are built with MSVC `cl`.
- **swift-collections as a subproject.** It turns on shared libraries on Darwin and Windows unless
  `BUILD_SHARED_LIBS` is already set, and every module joins `all`. The build sets
  `BUILD_SHARED_LIBS OFF` and fetches it `EXCLUDE_FROM_ALL`.

`xvfb-run` hung in `Scripts/linux-container.sh` whenever it became the container's PID 1, as the
last command of `bash -c` does. It waits for a signal from Xvfb that never arrives there. The
script runs the container with `docker run --init`. GitHub Actions keeps its own process as PID 1,
so CI never had the problem.

## App loop (2026-09-28)

Kania runs a game through SDL's main callbacks, as CF supports since 2026-09-18
(`docs/topics/app_callbacks.md`). Callbacks avoid the frozen window while it is dragged or
resized, and they are how SDL integrates with iOS and the browser. A game marks a type
`@main` and conforms it to `Game`. `Game.main()` calls `SDL_RunApp` and `SDL_EnterAppMainCallbacks`
with Kania's own callbacks, written in Swift. CF's `CF_MAIN` macro is not used, because it has to
be defined in a C file of the game. Each frame, Kania calls CF's update, the game's `update()` and
`draw()`, then CF's present.

- **Isolation.** SDL calls start, iterate and quit on the main thread, so Kania enters the main
  actor with `MainActor.assumeIsolated`. The event callback stays outside it, because SDL delivers
  lifecycle events (terminating, low memory, background and foreground) straight from the thread
  that raised them. When that happens on another thread, SDL also dispatches every queued event
  from that thread.
- **Events off the main thread are dropped for now.** CF's event queue is not thread-safe, so
  Kania passes CF only events that arrive on the main thread. On the desktop that is every event
  except in the rare case above. The proper fix, needed for iOS and Android, is a `Mutex`-guarded
  buffer that the next iterate hands to CF.
- **Main-actor tasks.** SDL's loop on macOS, Linux and Windows is a plain `while` loop; only iOS
  uses a display link. On macOS, SDL's event pump runs the Cocoa run loop, which also runs
  main-actor jobs. On Linux, and Windows, nothing does, so Kania drains libdispatch's main queue
  after each frame through `_dispatch_main_queue_callback_4CF`, the hook Foundation's run loop
  uses. It is never called on Apple platforms, where it is private API. Swift 6.4 has no public
  main-executor API; custom main executors are still a pitch.
- **Shutdown.** The quit callback releases the game before `cf_destroy_app`, so the game's
  resources, and later the `~Copyable` handles' `deinit`s, are freed while CF still exists.

`Tests/AppLoop` is a small game that `ctest` runs in its own process, because SDL's loop needs the
process's real `main`. It checks that every frame runs on SDL's main thread and that a
`Task { @MainActor in }` started in frame 0 has run before frame 1's update. It passes on macOS, 20
runs out of 20, where Kania calls no drain at all, so the Cocoa run loop does drain the main queue.
It passes on Linux under Xvfb. With the Linux drain removed, it fails with "a main-actor task started in
frame 0 had not run by frame 1", so the test is what catches a missing drain. Windows is not run
yet. Swift Testing is not set up either; it comes with the Kania API tests (`p1-tests`), since the
loop can't run inside a test runner.


## Open

- **3D scope** (draw 3D, models, Box3D). This decides the size of the "remaining subsystems" task.
- **Windows benchmark crash.** On the Windows CI runner, which has no GPU, `SpriteBench` at 10k
  sprites stopped at `CF_ASSERT(tex)` in `cute_graphics_sdlgpu.cpp:612`:
  `SDL_CreateGPUTexture` returned NULL during `cf_app_draw_onto_screen`. It happened on the fifth
  10k run, and the four before it, C included, passed. The step is `continue-on-error`, so the job
  still passed. The CI task stays open until the step runs without that flag.
