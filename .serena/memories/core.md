# Kania

Swift 2D game framework over Cute Framework (CF), replacing CF phase by phase until only SDL3, Box2D and Dear ImGui remain in C.

- Repo `CLAUDE.md` is authoritative for build, architecture, workflow (PR-only `main`) and plan tracking. Don't copy it into memories.
- Toolchain, build system, code-intelligence setup: `mem:tech_stack`.
- Where commands live, Darwin quirks: `mem:suggested_commands`.
- Swift idioms (handle ownership, isolation, typed throws, doc comments): `mem:conventions`.
- Verification required before work counts as done: `mem:task_completion`.

## Source map

- `Sources/Kania`: the public Swift API. `Sources/CCute`: the only C shim. `Sources/SpikeSupport`: phase 0 helpers for samples and benchmarks.
- `Tests/<Name>`: each test is a small `@main` game that exits 0 or 1.
- `Samples/HelloTriangle`, `Benchmarks/SpriteBench` + C twin `SpriteBenchC`, `Examples/MinimalGame` (the FetchContent consumer every game mirrors).
- `Vendor/cute_framework`: CF submodule on its `kania` branch; never edited from a Kania PR.
- `PHASE<n>.md`: per-phase decisions and findings.
