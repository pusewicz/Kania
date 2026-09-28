# Kania

A Swift 2D game framework that starts on [Cute Framework](https://github.com/RandyGaul/cute_framework)
(CF) and replaces it piece by piece, until only SDL3, Box2D and Dear ImGui remain in C.

Phase 0, a spike that checked Swift can drive CF without losing draw performance, is done; its
findings are in [`PHASE0.md`](PHASE0.md). Phase 1 builds Kania's Swift API over CF; its decisions
and results are in [`PHASE1.md`](PHASE1.md). No Kania API exists yet.

## Build

Requirements: [swiftly](https://www.swift.org/install/) (toolchain pinned in `.swift-version`),
CMake >= 4.2, Ninja and Ruby. Linux also needs SDL3's X11/Wayland/audio development packages
(see `.github/workflows/ci.yml`). Windows needs Visual Studio Build Tools; configure from a
developer prompt.

```sh
git clone --recurse-submodules <this repo>
cd Kania
cmake --preset release         # CF, SDL3, Box2D and PhysFS build as subprojects
cmake --build --preset release # executables land in build/release/bin
```

## Use it in a game

A game is a CMake project that pulls Kania in with `FetchContent`;
[`Examples/MinimalGame`](Examples/MinimalGame/CMakeLists.txt) is the smallest one.

## Run

```sh
B=build/release/bin
$B/HelloTriangle                                  # Swift port of CF's hello_triangle sample
$B/SpriteBenchC --count 10000                     # C baseline
$B/SpriteBench --count 10000 --impl raw-array     # Swift twin; --list-impls names the variants
Scripts/bench.rb --impls overlay-span --runs 3    # C against chosen variants, Markdown table
```

Both benchmarks print one JSON line: CPU time spent submitting draw commands (`submit_ms`),
whole-frame time (`frame_ms`), and a position checksum that must match between C and Swift.

## Layout

```
Vendor/cute_framework/   CF, pinned (submodule of pusewicz/cute_framework)
CMakeLists.txt           builds CF as a subproject, then Kania, samples and benchmarks
Sources/CCute/           C shim over CF for Swift (wraps _Generic macros and extern globals)
Sources/Kania/           the Kania library (the API starts in phase 1)
Examples/MinimalGame/    a game project consuming Kania with FetchContent
Tests/AppLoop/           checks the frame loop; run with ctest
Sources/SpikeSupport/    option parsing, timing summaries, PNG screenshots
Samples/HelloTriangle/   low-level graphics API from Swift
Benchmarks/SpriteBench*/ draw-path benchmark, C and Swift twins
Scripts/bench.rb         runs the benchmark matrix (Benchmarks/CLAUDE.md has the rules)
Scripts/linux-container.sh  builds and benchmarks in the Swift Linux image (Xvfb + lavapipe)
Results/                 benchmark tables per platform
```

## Licence

Kania's code starts as a translation of CF and is derived from it. CF's licence (zlib or public
domain, at your choice) is reproduced in [`LICENSE-cute_framework`](LICENSE-cute_framework).
