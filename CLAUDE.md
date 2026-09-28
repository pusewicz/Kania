# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Kania is a Swift 2D game framework that starts on Cute Framework (CF) and replaces it phase by
phase until only SDL3, Box2D and Dear ImGui remain in C. Phase 0 (a spike) is done, with findings in
`PHASE0.md`. Phase 1 (the Kania API over CF) has started; its decisions are in `PHASE1.md`. No Kania
API exists yet. Minimum Apple versions: macOS 26 and iOS 26. Toolchain: Swift 6.4 (`.swift-version`,
installed with swiftly).

## Commands

```sh
cmake --preset release               # configure build/release with Ninja (debug preset: build/debug)
cmake --build --preset release       # everything; executables land in build/release/bin
ctest --test-dir build/release --output-on-failure  # tests; on Linux, run under xvfb-run
swift format lint --strict --recursive Sources Samples Benchmarks Examples Tests
Scripts/bench.rb --impls a,b --runs 3 --frames 300  # focused comparison; rules in Benchmarks/CLAUDE.md
Scripts/linux-container.sh           # Linux (native arch) build + HelloTriangle + benchmark in Docker, Xvfb + lavapipe
```

`ctest` runs `Tests/AppLoop`, a small game that checks the frame loop; Swift Testing comes with the
Kania API tests. Beyond that, verification is a screenshot and the benchmark checksum:
`HelloTriangle --frames 30 --screenshot out.png`, and `SpriteBench`/`SpriteBenchC` with
`--count 1000 --frames 60`, whose JSON `checksum` fields must be equal. On Windows, configure from
a Visual Studio developer prompt.

## How the pieces fit

- **CMake builds everything.** `CMakeLists.txt` adds CF (the submodule) as a subproject, and CF
  fetches SDL3, Box2D, Box3D and PhysFS. The `CCute` shim and the `Kania` library sit on top.
  Samples and benchmarks build only when Kania is the top-level project. Source files are listed
  explicitly, so a new Swift file goes into its target's list.
- **Games consume Kania with `FetchContent`.** `Examples/MinimalGame` is that setup, and CI
  builds it against the checkout with `-DFETCHCONTENT_SOURCE_DIR_KANIA`. A change that breaks it
  breaks every game.
- **CMake does less for Swift than SwiftPM did, so `CMakeLists.txt` sets it explicitly:**
  - Swift 6 language mode and whole-module optimization in Release.
  - A Swift `-target` carrying the macOS deployment target (26.0); without it swiftc targets the
    build machine's OS.
  - The MSVC release DLL runtime on Windows.
  - Linux `-pthread` handling: SDL3 and s2n link with it, and swiftc rejects it.
  - `swiftc` from `PATH`, set in the presets. Otherwise CMake on macOS asks `xcrun` and gets the
    Command Line Tools' Swift, not the swiftly toolchain.
- **Kania runs games through SDL's main callbacks.** A game conforms a `@main` type to `Game`, and
  `Game.main()` hands SDL Kania's callbacks, which enter the main actor with
  `MainActor.assumeIsolated`. SDL's loop on Linux and Windows never drains libdispatch's main
  queue, so Kania does after each frame; `Tests/AppLoop` fails without it. Only events that
  arrive on the main thread reach CF, whose event queue is not thread-safe. `PHASE1.md` has the
  details.
- **`Sources/CCute` is the only C shim.** Swift drops C11 `_Generic` macros, variadic macros such
  as `cf_v2` (use `CF_V2(x:y:)`), and mutable C globals under Swift 6. The shim wraps the binding
  macros, CF's `extern` time globals and `stderr`. Glibc's `stderr` compiles on macOS but fails on
  Linux, so anything touching libc globals goes through the shim. Swift sees it through
  `Sources/CCute/include/module.modulemap`.
- **The draw-path benchmarks** (`Benchmarks/SpriteBench`, its C twin `Benchmarks/SpriteBenchC`,
  and `Scripts/bench.rb`) have their own rules in `Benchmarks/CLAUDE.md`.
- **Screenshots:** CF has no GPU command buffer between `cf_app_draw_onto_screen` and the next
  `cf_app_update`, so `writeScreenshot` must follow an update and a draw.

## Workflow

Changes reach `main` only through pull requests; branch protection enforces it. Work on a branch,
push it, open the PR with `gh pr create`, and stop there: the owner reviews and merges, with a merge
commit. Merged branches are deleted automatically. The `macos` and `linux` CI jobs must pass; the
Windows job doesn't block yet.

## CF changes

CF is pinned at a commit on the `kania` branch of the submodule (pusewicz/cute_framework): upstream
master plus Kania's patches. Push that branch before opening a Kania PR that moves the submodule
pointer, or clones break.

## Plan and progress

The plan is the artifact https://claude.ai/artifact/Kw2QXw8pMyzb2q3T8GV71Y. Its progress meter
and per-phase checklists render live from the artifact's database; only editors can write it.

- `phases/p<n>` (n = 0–8): `{n, title, weeks: [low, high], status: "planned" | "active" | "done", started, finished}`
- `tasks/<id>` (ids like `p1-packaging`): `{phase, order, title, done, done_on, ref}`

Keep it current as part of finishing work, with the `ArtifactData` tool (one `batch` per update):

- A task is done: `update` it with `done: true`, `done_on` (YYYY-MM-DD) and `ref` (the PR number
  such as `#12`, a short commit SHA, or a one-word reason such as `deferred`). Mark it when opening
  the PR that finishes it; if that PR closes unmerged, reopen the task.
- Work starts on a phase: set its `status` to `active` and `started`. Its gate passes: `done` and
  `finished`.
- Scope grows: add a task with the next `order` in its phase. Scope shrinks: delete the task
  unless it is done. Never rewrite a done task's title.
- Read before writing and pass `if_version`.

Decisions, findings and estimate changes are prose, not data: read the artifact, edit the HTML
from that read, and publish it to the same URL without `capabilities` so the database and its
rules are kept. Record phase decisions and findings in the repo too, in `PHASE<n>.md`.

## CI

`.github/workflows/ci.yml` builds the release preset, runs HelloTriangle and the benchmark, and
builds `Examples/MinimalGame` on macOS 26, Linux (Swift container, lavapipe) and Windows (MSVC) on
every push; the repository is public, so Actions costs nothing. A newer
push to the same branch cancels the run in progress. The benchmark step there is a one-run smoke
test: runners have no GPU, so CI timings mean nothing, but every variant must run and match C's
checksum. The Windows benchmark step is `continue-on-error` until CF's texture assert at 10k
sprites is fixed (`PHASE1.md`). `Scripts/linux-container.sh` reproduces the Linux job locally.
