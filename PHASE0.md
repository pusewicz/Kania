# Phase 0: spike and decide

Status as of 2026-09-28. Plan: [Kania Framework Plan](https://claude.ai/artifact/Kw2QXw8pMyzb2q3T8GV71Y), phase 0.

## Verdict

| Question | Answer |
|---|---|
| Can Swift hold CF's draw performance? | **Yes.** Swift calling CF over raw memory is within ±3% of C. Idiomatic Swift adds 15–28% to the CPU submission loop at 10k sprites when it mutates a class-held `Array` element by element. That is at most 0.14 ms per frame, and whole-frame time does not change. The cost is dynamic exclusivity checks, copy-on-write checks and ARC. The same code iterated through a `MutableSpan` is within 2% of C on macOS and 4% on Linux. |
| Is the web in Kania's first release? | **No, deferred** (owner decision, 2026-09-28). No Swift SDK targets Emscripten yet (checked the same day), and stage 1 runs on CF, which needs SDL3, which needs Emscripten in the browser. |
| Does Swift + CF build and run on the desktop OSes? | macOS arm64: yes. Linux aarch64 (Ubuntu 24.04 container, Xvfb + lavapipe): yes, and `HelloTriangle` writes a PNG byte-identical to the macOS one. Linux x86_64 was not run locally. Windows: not verified with Swift 6.4 (GitHub Actions is blocked by account billing on the private repo); swift-game-spike verified it with Swift 6.3.3. |
| CF commit Kania builds on | `e4786898` (2026-09-20) plus Kania patches on the `kania` branch of pusewicz/cute_framework: `778f78c6` limits `-msse4.1` to x86 so aarch64 Linux builds. |

## What was built

- `Scripts/build-cf.sh`: CMake builds CF as a static library per target triple and collects the libraries, public headers and CMake's own link line. SDL3 3.4.0, Box2D 3.1.1, Box3D 0.1.0 and PhysFS are fetched by CF's CMake.
- `Sources/CCute`: the only C shim needed. It wraps the `_Generic` binding macros, the `extern` time globals and `stderr`.
- `Samples/HelloTriangle`: CF's `hello_triangle.c` in Swift (mesh, GLSL compiled at runtime by CF, low-level draw). Its screenshot is byte-identical on macOS (Metal) and Linux (lavapipe Vulkan).
- `Benchmarks/SpriteBenchC` and `Benchmarks/SpriteBench`: the same workload in C and Swift. N copies of the demo sprite are moved, animated and drawn with `cf_sprite_update` + `cf_draw_sprite`. Both print CPU submission time, whole-frame time and a position checksum. The checksums must match, and they do for every run.
  - `raw-array`: the imported C API on a Swift `Array` held by a class.
  - `raw-buffer`: the imported C API on manually allocated memory, the floor.
  - `overlay-struct`: a value-type `Sprite` wrapper with `SIMD2<Float>` positions and methods.
  - `overlay-span`: the same, iterated through `Array.mutableSpan`.
  - `overlay-class`: sprites as `final class` nodes, the scene-graph shape.
  - text scene: N labels per frame built with string interpolation and passed as `const char*`.

## Results (macOS, Apple M3 Max, Swift 6.4, `-O`)

Median over 5 interleaved runs of each run's median across 600 frames. `submit` is the CPU time of the update-and-draw loop, the only part that differs between implementations. `frame` includes CF's flush and presentation, which is identical C code for all of them.

| scene | count | impl | submit ms (median) | vs C | per item ns | frame ms (median) | checksum |
|---|---:|---|---:|---:|---:|---:|---|
| sprites | 10000 | c | 0.5185 | +0.0% | 51.8 | 2.166 | matches C |
| sprites | 10000 | raw-array | 0.6156 | +18.7% | 61.6 | 2.006 | matches C |
| sprites | 10000 | raw-buffer | 0.5315 | +2.5% | 53.2 | 1.933 | matches C |
| sprites | 10000 | overlay-struct | 0.5939 | +14.5% | 59.4 | 2.086 | matches C |
| sprites | 10000 | overlay-span | 0.5267 | +1.6% | 52.7 | 2.026 | matches C |
| sprites | 10000 | overlay-class | 0.6613 | +27.5% | 66.1 | 2.039 | matches C |
| text | 1000 | c | 8.4415 | +0.0% | 8441.5 | 9.540 | matches C |
| text | 1000 | swift | 8.3856 | -0.7% | 8385.6 | 9.488 | matches C |

All counts (100, 1k, 10k) are in [`Results/macos-arm64.md`](Results/macos-arm64.md), with the flag variants beside it. Every row's checksum matches C.

Linux aarch64 (Ubuntu 24.04 in OrbStack on the same machine, lavapipe, 3 runs × 300 frames) shows the same pattern at 10k sprites: raw-buffer +0.3%, overlay-span +3.7%, overlay-struct +14.2%, raw-array +19.3%, overlay-class +19.9%. Frame time there is dominated by software rendering (24 ms). The full table is in [`Results/linux-aarch64.md`](Results/linux-aarch64.md).

Where the overhead comes from, from the disassembly of each loop and the flag variants. Each column comes from its own batch, and C varied by up to 3% between batches, so differences under about 3% are noise. The flag columns are diagnostic only; Kania would not ship with exclusivity checking turned off.

| Variant | Runtime calls per sprite | 10k, default | 10k, `-enforce-exclusivity=unchecked` | 10k, `-Ounchecked` |
|---|---|---:|---:|---:|
| raw-array | 5 `swift_beginAccess`, 3 uniqueness checks | +18.7% | +5.3% | +4.5% |
| overlay-struct | 2 `swift_beginAccess`, 1 uniqueness check | +14.5% | +5.7% | +11.0% |
| overlay-span | 1 `swift_beginAccess` and 1 uniqueness check per frame, none per sprite | +1.6% | n/a | n/a |
| overlay-class | `swift_retain`/`release`, NSArray bridging checks, 2 `swift_beginAccess` | +27.5% | +3.0% | +3.9% |
| raw-buffer | none | +2.5% | −2.1% | +2.2% |

## Findings that shape phase 1

1. **Hot loops need one exclusive access, not one per element.** Mutating a class-held `Array` element by element makes Swift check exclusivity and uniqueness on every access. Iterating through `Array.mutableSpan` hoists both checks out of the loop and brings idiomatic, bounds-checked Swift within 2% (macOS) to 4% (Linux) of C at 10k sprites. `Array.mutableSpan` needs macOS 26 / iOS 26, so if Kania supports older OSes the draw path needs `withUnsafeMutableBufferPointer` or its own storage there. Kania's draw-path API should take spans or `inout` arrays, and sprites should be value types. Scene-graph nodes as classes cost the most.
2. **The per-call cost of Swift → C is zero.** `raw-buffer` matches C, so wrapping CF in Swift types costs nothing when the loop is written well. Crossing `String` → `const char*` is also free in practice: 1,000 interpolated labels per frame are within noise of C (−0.7% on macOS, −5.6% on Linux), because CF's text layout dominates.
3. **FMA contraction differs.** Clang fuses `a + b * c` into one FMA instruction by default and Swift never does, so C and Swift results differ in the last bits. The benchmark's checksums matched only after building the C side with `-ffp-contract=off`. Phase 3 math parity and phase 6 pixel parity need that flag on CF, or a tolerance.
4. **Importer friction is small and known.** `cf_v2` and similar constructors are variadic macros in C mode and are not imported, so Swift uses `CF_V2(x:y:)`. App option flags import as `UInt32` enum constants while the parameter is `Int32`. `_Generic` macros and `extern` globals need the shim. `CF_OFFSET_OF` becomes `MemoryLayout.offset(of:)`. Glibc declares `stderr` as a mutable global, which Swift 6 rejects on Linux although the same code compiles on macOS, and the Windows CRT makes it a macro, so stdio globals go through the shim too. Kania's overlay hides all of these, and Linux CI has to be in place from the first Kania commit.
5. **Packaging is the open phase 1 problem.** The spike links prebuilt CF with `unsafeFlags`, which SwiftPM refuses in remote dependencies. Phase 1 has to choose between a per-platform binary artifact bundle, compiling CF as SwiftPM C/C++ targets, or a CMake-first build for games.
6. **Measurement notes.** macOS throttles hidden windows to display refresh, so frame times need a visible window. CF has no command buffer between `cf_app_draw_onto_screen` and the next `cf_app_update`, so a screenshot taken after the loop must call `cf_app_update` first.
7. **Swift 6.4 builds against the macOS 27 SDK without the workaround swift-game-spike needed for 6.3.x.**

## Not done

- Windows with Swift 6.4, and CI on all three OSes: blocked until Actions billing is fixed or the repository is public. `.github/workflows/phase0.yml` is ready.
- Debugger quality on Linux and Windows.
- Frame pacing beyond medians and p95.
