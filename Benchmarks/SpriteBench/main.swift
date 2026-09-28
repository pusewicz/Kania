// Swift side of the draw-path benchmark. Benchmarks/SpriteBenchC is the C twin;
// both must run the same workload, so change them together.
//
// Usage: SpriteBench [--impl NAME] [--count N] [--frames N] [--warmup N] [--hidden 0|1]
//                    [--screenshot path]
//        SpriteBench --list-impls
// Prints one JSON line with per-frame CPU submission and whole-frame times in milliseconds.
// --list-impls prints the sprite implementations, one per line.
import CCute
import SpikeSupport

/// The sprite implementations, in report order.
let spriteImpls = ["raw-buffer", "overlay-span-inplace"]

if CommandLine.arguments.dropFirst().elementsEqual(["--list-impls"]) {
  print(spriteImpls.joined(separator: "\n"))
  exit(0)
}

let options = SpikeOptions(allowed: ["impl", "count", "frames", "warmup", "hidden", "screenshot"])
let impl = options.string("impl", default: "overlay-span-inplace")
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

/// Creates the workload for `impl`, exiting on an unknown name.
func makeWorkload(impl: String, count: Int) -> any Workload {
  switch impl {
  case "raw-buffer": return RawBufferWorkload(count: count)
  case "overlay-span-inplace": return OverlaySpanInPlaceWorkload(count: count)
  default: fatalError("unknown impl \(impl)")
  }
}

let workload = makeWorkload(impl: impl, count: count)

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
  "{\"impl\":\"\(impl)\",\"count\":\(count),\"frames\":\(frames),"
    + "\"immediate\":\(immediate),\"checksum\":\(String(format3: workload.checksum)),"
    + "\"submit_ms\":\(Summary(submit).json),\"frame_ms\":\(Summary(whole).json)}")
cf_destroy_app()
