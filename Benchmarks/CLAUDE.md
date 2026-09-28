# Benchmarks

`SpriteBench` (Swift) and `SpriteBenchC` (C) time the draw path. Each frame they move, animate and
draw N copies of CF's demo sprite. `Scripts/bench.rb` runs the whole matrix. Results and their
reading are in `PHASE0.md` and `PHASE1.md`, and the tables are in `Results/`.

## Rules

- **The two are twins.** Both use the same LCG, entity order, bounce rule, CLI and JSON output.
  Change them together. A Swift variant counts only if its `checksum` equals C's at the same
  `--count` and `--frames`. `bench.rb`'s table marks any difference.
- **The C twin's flags are part of the contract.** It builds at `-O3`, CMake's Release level for C
  and the level CF uses. `CMakeLists.txt` adds `-ffp-contract=off`, because clang fuses `a + b * c`
  into an FMA and Swift never does; without it the checksums differ in the last bits.
- **`step(frame:)` holds only the frame's submission work.** It is the only part timed as
  `submit_ms`, so setup belongs in `init`.
- **Adding a Swift variant** takes a `Workload` class in `Implementations.swift` whose doc comment
  says what it models, a case in `makeWorkload`, and its name in `spriteImpls` in `main.swift`.
  `bench.rb` gets the list from `SpriteBench --list-impls`, so it needs no change. A variant that
  needs a newer OS than Kania's minimum is gated with `#available` and left out of `spriteImpls`
  where it can't run.
- **Delete a variant once its question is answered.** The finding goes in `PHASE<n>.md` and the
  code stays in git history. The benchmark keeps only the floor (`raw-buffer`) and the shape Kania
  ships, so CI's smoke test runs what matters. `kania` runs the public `Sprite` and `Draw` API, so
  a regression in the shipped path shows there; `overlay-span-inplace` is a hand-rolled copy that
  stays only until `kania` matches it (`TODO.md`).

## Measuring

- **Keep the display awake and the window visible.** Otherwise macOS paces every frame to the
  display refresh or slower, 16–50 ms instead of about 2 ms, and each run takes 10–20 times longer.
  `submit_ms` stays valid when that happens; `frame_ms` does not. A `frame_ms` median near 16.7 ms
  is the sign.
- **How `bench.rb` runs:** it starts a fresh process per run and interleaves implementations
  round-robin, so thermal drift hits all of them equally. It prints a Markdown table (`--output`
  also writes it) and writes every raw run to `Results/raw/<label>.jsonl`, replacing that label's
  earlier file. Use a new label rather than overwrite a record from an earlier phase, such as
  `macos-arm64`.
- **Compare within one batch.** C varied by up to 4% between batches in phase 0, so differences
  smaller than that across batches are noise.
- **Run only what the question needs.** `--impls a,b` limits the Swift variants (C always runs
  as the baseline) and `--counts` the sprite counts. With `--runs 3 --frames 300`, comparing three
  variants at 1k and 10k sprites takes about 90 seconds. Run the full matrix (5 runs of 600
  frames, every variant, every count) only for a record that replaces a whole results table.
- **Quick parity check:** `--count 1000 --frames 60` on both binaries, then compare `checksum`.
