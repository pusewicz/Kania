# Kania

Swift 2D game framework that starts on Cute Framework (CF, pinned in `Vendor/cute_framework`,
branch `kania` of pusewicz/cute_framework) and replaces it phase by phase. Minimum Apple
versions: macOS 26 and iOS 26.

## Build and check

```sh
Scripts/build-cf.sh                  # once per target triple, and after any change under Vendor/
swift build -c release
swift format lint --strict --recursive Package.swift Sources Samples Benchmarks
Scripts/bench.rb --label local       # draw-path benchmark matrix (C twin vs Swift variants)
Scripts/linux-container.sh           # Linux build + benchmark in Docker (Xvfb + lavapipe)
```

Changes to CF go on the `kania` branch of the submodule. Push that branch before pushing a Kania
commit that moves the submodule pointer, or clones break.

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
