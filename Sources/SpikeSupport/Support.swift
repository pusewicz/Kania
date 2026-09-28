import CCute

#if os(Windows)
  import ucrt
#elseif canImport(Glibc)
  import Glibc
#else
  import Darwin
#endif

/// Command-line options shared by the Phase 0 executables. Every option takes one value.
public struct SpikeOptions {
  private var values: [String: String] = [:]

  /// Parses `--name value` pairs from `CommandLine.arguments`, exiting on a malformed list.
  public init(allowed: Set<String>) {
    var arguments = CommandLine.arguments.dropFirst()
    while let flag = arguments.popFirst() {
      let name = String(flag.drop(while: { $0 == "-" }))
      guard flag.hasPrefix("--"), allowed.contains(name), let value = arguments.popFirst() else {
        cfs_host_print_error("unknown or incomplete option \(flag); allowed: \(allowed.sorted())\n")
        exit(2)
      }
      values[name] = value
    }
  }

  /// Returns the string value of `name`, or `fallback` when it was not given.
  public func string(_ name: String, default fallback: String) -> String {
    values[name] ?? fallback
  }

  /// Returns the string value of `name`, or nil when it was not given.
  public func optionalString(_ name: String) -> String? {
    values[name]
  }

  /// Returns the integer value of `name`, or `fallback` when it was not given.
  public func int(_ name: String, default fallback: Int) -> Int {
    values[name].flatMap { Int($0) } ?? fallback
  }
}

/// Median, 95th percentile and mean of a series of per-frame timings in milliseconds.
public struct Summary {
  public let median: Double
  public let p95: Double
  public let mean: Double

  /// Summarises `samples` with the same rank rules as the C benchmark.
  public init(_ samples: [Double]) {
    precondition(!samples.isEmpty)
    let sorted = samples.sorted()
    let n = sorted.count
    median = sorted[(n - 1) / 2]
    p95 = sorted[Int(Double(n - 1) * 0.95 + 0.5)]
    mean = sorted.reduce(0, +) / Double(n)
  }

  /// The summary as a JSON object, four decimals per value.
  public var json: String {
    "{\"median\":\(format(median)),\"p95\":\(format(p95)),\"mean\":\(format(mean))}"
  }

  /// Rounds `value` to four decimals for the JSON output.
  private func format(_ value: Double) -> String {
    let scaled = (value * 10_000).rounded() / 10_000
    return String(scaled)
  }
}

extension String {
  /// Formats `value` with exactly three decimals, matching C's `%.3f`.
  public init(format3 value: Double) {
    var buffer = [CChar](repeating: 0, count: 64)
    _ = withVaList([value]) { vsnprintf(&buffer, buffer.count, "%.3f", $0) }
    self = String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
  }
}

/// Converts a `cf_get_ticks` interval to milliseconds.
public func milliseconds(from start: UInt64, to end: UInt64) -> Double {
  Double(end &- start) / Double(cf_get_tick_frequency()) * 1000
}

/// Renders the current frame's draw commands into an offscreen canvas and writes it as a PNG.
///
/// Call after submitting draw commands and instead of `cf_app_draw_onto_screen`, mirroring the
/// screenshot path in CF's `draw_lists` sample.
public func writeScreenshot(to path: String, width: Int32, height: Int32) {
  let canvas = cf_make_canvas(cf_canvas_defaults(width, height))
  defer { cf_destroy_canvas(canvas) }
  cf_render_to(canvas, true)
  cf_app_draw_onto_screen(false)
  savePNG(of: canvas, width: width, height: height, to: path)
}

/// Reads `canvas` back from the GPU, blocking until the copy lands, and writes it as a PNG.
public func savePNG(of canvas: CF_Canvas, width: Int32, height: Int32, to path: String) {
  let readback = cf_canvas_readback(canvas)
  defer { cf_destroy_readback(readback) }
  while !cf_readback_ready(readback) {}
  let count = Int(width) * Int(height)
  var pixels = [CF_Pixel](repeating: CF_Pixel(), count: count)
  pixels.withUnsafeMutableBufferPointer { buffer in
    cf_readback_data(readback, buffer.baseAddress, Int32(count * MemoryLayout<CF_Pixel>.stride))
    var image = CF_Image(w: width, h: height, pix: buffer.baseAddress)
    var png: UnsafeMutableRawPointer? = nil
    var size: Int32 = 0
    guard !cf_is_error(cf_image_save_png_to_memory(&image, &png, &size)), let png else {
      cfs_host_print_error("screenshot: PNG encoding failed\n")
      return
    }
    defer { cf_free(png) }
    guard let file = fopen(path, "wb") else {
      cfs_host_print_error("screenshot: cannot open \(path)\n")
      return
    }
    fwrite(png, 1, Int(size), file)
    fclose(file)
  }
}
