# TODO

- **Benchmark the real API.** `SpriteBench`'s `overlay-span-inplace` is a hand-rolled copy of
  `Sprite`, `Entity` and `Vec2`, not `Kania.Draw.sprites`, so a regression in the shipped path
  wouldn't show up in CI. Have the variant call `Draw.sprites(&sprites)` and delete the copy. The
  workload becomes `[Sprite]` plus a separate velocity array, so check that its checksum still
  equals C's and its `submit_ms` stays within noise of `overlay-span-inplace` before deleting that.
