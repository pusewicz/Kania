# TODO

- **Close the `kania` benchmark gap, then drop the copy.** `SpriteBench`'s `kania` variant runs the
  real `Sprite` and `Draw.sprites`, and at 10k sprites it is 3–8% behind `overlay-span-inplace`, the
  hand-rolled copy (`PHASE1.md`, "Benchmarking the shipped API"). Make `Sprite.update()` inlinable
  or find what else costs the difference, then re-measure both in one batch. Once `kania`'s
  `submit_ms` is within noise, delete `overlay-span-inplace` with its `Vec2`, `Sprite` and `Entity`
  copy, and make `kania` the default `--impl`.
