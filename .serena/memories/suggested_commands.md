# Commands

- Build, test, lint, screenshot, benchmark and Linux-container commands: repo `CLAUDE.md` § Commands.
- Benchmark runs and comparisons (`Scripts/bench.rb`): `Benchmarks/CLAUDE.md`.
- Built executables land in `build/release/bin`.
- PRs: `gh pr create`; the owner merges.

## Darwin

- BSD `sed`: in-place edit is `sed -i ''`; prefer a Ruby one-liner for anything nontrivial.
- The user's interactive shell is fish; scripts should not assume bash syntax in the user's terminal.
