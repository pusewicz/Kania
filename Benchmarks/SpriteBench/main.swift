// Swift side of the Phase 0 draw-path benchmark. Benchmarks/SpriteBenchC is the C twin;
// both must run the same workload, so change them together.
//
// Usage: SpriteBench [--impl raw-array|raw-buffer|overlay-struct|overlay-span|overlay-class]
//                    [--scene sprites|text] [--count N] [--frames N] [--warmup N] [--hidden 0|1]
//                    [--screenshot path]
// Prints one JSON line with per-frame CPU submission and whole-frame times in milliseconds.
import CCute
import SpikeSupport

let options = SpikeOptions(allowed: ["impl", "scene", "count", "frames", "warmup", "hidden", "screenshot"])
let scene = options.string("scene", default: "sprites")
let impl = scene == "text" ? "swift" : options.string("impl", default: "raw-array")
let count = options.int("count", default: 10_000)
let frames = options.int("frames", default: 600)
let warmup = options.int("warmup", default: 60)
let hidden = options.int("hidden", default: 0) != 0

let result = cf_make_app(
  "SpriteBench", 0, 0, 0, Int32(width), Int32(height),
  CF_AppOptionFlags(
    CF_APP_OPTIONS_WINDOW_POS_CENTERED_BIT.rawValue | (hidden ? CF_APP_OPTIONS_HIDDEN_BIT.rawValue : 0)),
  CommandLine.unsafeArgv[0])
guard !cf_is_error(result) else { fatalError("cf_make_app failed") }
let immediate = cf_app_set_present_mode(CF_PRESENT_MODE_IMMEDIATE)

/// Creates the workload for `scene` and `impl`, exiting on an unknown or unavailable pair.
func makeWorkload(scene: String, impl: String, count: Int) -> any Workload {
  switch (scene, impl) {
  case ("text", _): return TextWorkload(count: count)
  case ("sprites", "raw-array"): return RawArrayWorkload(count: count)
  case ("sprites", "raw-buffer"): return RawBufferWorkload(count: count)
  case ("sprites", "overlay-struct"): return OverlayStructWorkload(count: count)
  case ("sprites", "overlay-span"):
    guard #available(macOS 26, iOS 26, *) else { fatalError("overlay-span needs Array.mutableSpan") }
    return OverlaySpanWorkload(count: count)
  case ("sprites", "overlay-class"): return OverlayClassWorkload(count: count)
  default: fatalError("unknown scene/impl \(scene)/\(impl)")
  }
}

let workload = makeWorkload(scene: scene, impl: impl, count: count)

var submit: [Double] = []
var whole: [Double] = []
submit.reserveCapacity(frames)
whole.reserveCapacity(frames)

for frame in 0..<(warmup + frames) {
  let t0 = cf_get_ticks()
  cf_app_update(nil)
  let t1 = cf_get_ticks()
  workload.step(frame: frame)
  let t2 = cf_get_ticks()
  cf_app_draw_onto_screen(true)
  let t3 = cf_get_ticks()
  if frame >= warmup {
    submit.append(milliseconds(from: t1, to: t2))
    whole.append(milliseconds(from: t0, to: t3))
  }
}

if let path = options.optionalString("screenshot") {
  cf_app_update(nil)
  workload.step(frame: 0)
  writeScreenshot(to: path, width: Int32(width), height: Int32(height))
}

print(
  "{\"impl\":\"\(impl)\",\"scene\":\"\(scene)\",\"count\":\(count),\"frames\":\(frames),"
    + "\"immediate\":\(immediate),\"checksum\":\(String(format3: workload.checksum)),"
    + "\"submit_ms\":\(Summary(submit).json),\"frame_ms\":\(Summary(whole).json)}")
cf_destroy_app()
