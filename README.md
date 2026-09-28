# Kania

A Swift 2D game framework that starts on [Cute Framework](https://github.com/RandyGaul/cute_framework)
(CF) and replaces it piece by piece, until only SDL3, Box2D and Dear ImGui remain in C.

This repository is at **Phase 0**: a spike that checks Swift can drive CF without losing draw
performance, before any Kania API exists. Findings are in [`PHASE0.md`](PHASE0.md).

## Build

Requirements: [swiftly](https://www.swift.org/install/) (toolchain pinned in `.swift-version`),
CMake >= 4.2, Ninja and Ruby. Linux also needs SDL3's X11/Wayland/audio development packages
(see `.github/workflows/phase0.yml`); Windows needs Visual Studio Build Tools.

```sh
git clone --recurse-submodules <this repo>
cd Kania
Scripts/build-cf.sh            # builds CF once per target triple into Vendor/prebuilt/<triple>/
swift build -c release
```

## Run

```sh
B=$(swift build -c release --show-bin-path)
$B/HelloTriangle                                  # Swift port of CF's hello_triangle sample
$B/SpriteBenchC --count 10000                     # C baseline
$B/SpriteBench --count 10000 --impl raw-array     # Swift twin; see --impl in its main.swift
Scripts/bench.rb --label local                    # full matrix, Markdown table on stdout
```

Both benchmarks print one JSON line: CPU time spent submitting draw commands (`submit_ms`),
whole-frame time (`frame_ms`), and a position checksum that must match between C and Swift.

## Layout

```
Vendor/cute_framework/   CF, pinned (submodule of pusewicz/cute_framework)
Scripts/build-cf.sh      CMake build of static CF + collected headers and link line
Sources/CCute/           C shim over CF for Swift (wraps _Generic macros and extern globals)
Sources/SpikeSupport/    option parsing, timing summaries, PNG screenshots
Samples/HelloTriangle/   low-level graphics API from Swift
Benchmarks/SpriteBench*/ draw-path benchmark, C and Swift twins
Scripts/bench.rb         runs the benchmark matrix
Scripts/linux-container.sh  builds and benchmarks in the Swift Linux image (Xvfb + lavapipe)
Results/                 benchmark tables per platform
```

## Licence

Kania's code starts as a translation of CF and is derived from it. CF's licence (zlib or public
domain, at your choice) is reproduced in [`LICENSE-cute_framework`](LICENSE-cute_framework).
