# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Kania is a Swift 2D game framework that starts on Cute Framework (CF) and replaces it phase by
phase until only SDL3, Box2D and Dear ImGui remain in C. The repository is at the end of phase 0
(a spike, findings in `PHASE0.md`); no Kania API exists yet. Minimum Apple versions: macOS 26 and
iOS 26. Toolchain: Swift 6.4 (`.swift-version`, installed with swiftly).

## Commands

```sh
Scripts/build-cf.sh                  # CMake-build static CF for this triple; rerun after any change under Vendor/
swift build -c release               # all targets; binaries land in $(swift build -c release --show-bin-path)
swift format lint --strict --recursive Package.swift Sources Samples Benchmarks
Scripts/bench.rb --label local       # benchmark matrix; --runs 3 --frames 300 for a quick pass
Scripts/linux-container.sh           # Linux (native arch) build + HelloTriangle + benchmark in Docker, Xvfb + lavapipe
```

There is no test target yet. Verification is a screenshot and the benchmark checksum:
`HelloTriangle --frames 30 --screenshot out.png`, and `SpriteBench`/`SpriteBenchC` with
`--count 1000 --frames 60`, whose JSON `checksum` fields must be equal.

## How the pieces fit

- **CF is prebuilt, not compiled by SwiftPM.** `Scripts/build-cf.sh` runs CF's CMake into
  `Vendor/build/<triple>/` and collects static libs, public headers and CMake's own sample link
  line (`link.txt`) into `Vendor/prebuilt/<triple>/`. `Package.swift` links those with
  `unsafeFlags` (`-L`, `-I`, frameworks mirrored from `link.txt`), so the package cannot yet be a
  remote SwiftPM dependency; choosing real packaging is a phase 1 task. The macOS deployment target
  in `build-cf.sh` must match `Package.swift` (26.0).
- **`Sources/CCute` is the only C shim.** Swift drops C11 `_Generic` macros, variadic macros such
  as `cf_v2` (use `CF_V2(x:y:)`), and mutable C globals under Swift 6. The shim wraps the binding
  macros, CF's `extern` time globals and `stderr`. Glibc's `stderr` compiles on macOS but fails on
  Linux, so anything touching libc globals goes through the shim.
- **`Benchmarks/SpriteBenchC` and `Benchmarks/SpriteBench` are twins.** Both must do the same
  work: same LCG, same entity order, same bounce rule, same CLI and JSON output. Change them
  together. The C twin is built with `-O3` (CF's CMake Release level; SwiftPM's release default
  for C is `-Os`) and `-ffp-contract=off`, because clang fuses `a + b * c` into an FMA and Swift
  never does; without it the checksums differ in the last bits.
- **Swift variants** (`--impl`) live in `Implementations.swift`: `raw-array`, `raw-buffer`,
  `overlay-struct`, `overlay-span`, `overlay-class`. `KANIA_BENCH_SWIFTFLAGS` adds compiler flags
  to `SpriteBench` only; build such variants with their own `--scratch-path` and pass the result to
  `bench.rb --bin`.
- **Benchmarks run a visible window**: macOS throttles hidden windows to the display refresh. CF has
  no GPU command buffer between `cf_app_draw_onto_screen` and the next `cf_app_update`, so
  `writeScreenshot` must follow an update and draw.
- **`Scripts/bench.rb`** starts a fresh process per run, interleaves implementations round-robin,
  prints a Markdown table (`--output FILE` also writes it), and appends raw runs to
  `Results/raw/<label>.jsonl`. Differences under about 4% between batches are noise.

## CF changes

CF is frozen at a pinned commit. Kania's patches go on the `kania` branch of the submodule
(pusewicz/cute_framework). Push that branch before pushing a Kania commit that moves the
submodule pointer, or clones break.

## Plan and progress

The plan is the artifact https://claude.ai/artifact/Kw2QXw8pMyzb2q3T8GV71Y. Its progress meter
and per-phase checklists render live from the artifact's database; only editors can write it.

- `phases/p<n>` (n = 0–8): `{n, title, weeks: [low, high], status: "planned" | "active" | "done", started, finished}`
- `tasks/<id>` (ids like `p1-packaging`): `{phase, order, title, done, done_on, ref}`

Keep it current as part of finishing work, with the `ArtifactData` tool (one `batch` per update):

- A task is done: `update` it with `done: true`, `done_on` (YYYY-MM-DD) and `ref` (short commit
  SHA, PR number, or a one-word reason such as `deferred`).
- Work starts on a phase: set its `status` to `active` and `started`. Its gate passes: `done` and
  `finished`.
- Scope grows: add a task with the next `order` in its phase. Scope shrinks: delete the task
  unless it is done. Never rewrite a done task's title.
- Read before writing and pass `if_version`.

Decisions, findings and estimate changes are prose, not data: read the artifact, edit the HTML
from that read, and publish it to the same URL without `capabilities` so the database and its
rules are kept. Record phase findings in the repo too (`PHASE0.md` for phase 0).

## CI

`.github/workflows/phase0.yml` builds and runs on macOS 26, Linux (Swift container, lavapipe) and
Windows (MSVC-built CF). GitHub Actions is currently blocked by account billing, so Linux is
verified locally with `Scripts/linux-container.sh` and Windows is unverified with Swift 6.4.
