internal import CCute

/// Pixels being copied back from the GPU, started with ``Canvas/readPixels()``.
///
/// The copy takes a frame or more. Check ``pixels`` in later frames; it stays `nil` until the copy
/// is done, and for good if the copy failed, in which case ``error`` says why.
@MainActor
public final class Readback {
  /// The pixels, in rows of ``width`` pixels, once the copy is done.
  public private(set) var pixels: [Pixel]?

  /// Why the copy failed, if it did.
  public private(set) var error: KaniaError?

  /// The width of the canvas being read, in pixels.
  public let width: Int

  /// The height of the canvas being read, in pixels.
  public let height: Int

  private let canvas: CF_Canvas
  private var started: CF_Readback?

  init(canvas: CF_Canvas, width: Int, height: Int) {
    self.canvas = canvas
    self.width = width
    self.height = height
  }

  /// Readbacks requested this frame, started once it is presented.
  private static var requested: [Readback] = []

  /// Readbacks whose copy is on the GPU.
  private static var inFlight: [Readback] = []

  /// Starts `readback` after the current frame is presented.
  static func queue(_ readback: Readback) {
    requested.append(readback)
  }

  /// Starts the readbacks requested this frame and collects the ones the GPU has finished.
  ///
  /// Call after the frame is presented. CF copies on its own command buffer, submitted at once,
  /// while the frame's drawing is submitted at present; starting earlier would copy stale pixels.
  static func afterPresent() {
    for readback in requested {
      let started = cf_canvas_readback(readback.canvas)
      if started.id == 0 {
        readback.error = KaniaError("could not start reading back a canvas")
      } else {
        readback.started = started
        inFlight.append(readback)
      }
    }
    requested.removeAll()
    inFlight.removeAll { $0.collect() }
  }

  /// Drops requested readbacks and waits for the ones on the GPU. Call before CF shuts down.
  static func cancelAll() {
    for readback in requested {
      readback.error = KaniaError("the app stopped before the readback started")
    }
    requested.removeAll()
    for readback in inFlight {
      if let started = readback.started { cf_destroy_readback(started) }
      readback.error = KaniaError("the app stopped before the readback finished")
    }
    inFlight.removeAll()
  }

  /// Copies the pixels out and releases CF's readback if the GPU is done. Returns whether it was.
  private func collect() -> Bool {
    guard let started, cf_readback_ready(started) else { return false }
    defer {
      cf_destroy_readback(started)
      self.started = nil
    }
    // Canvas.init guarantees this fits in the Int32 CF takes.
    let byteCount = width * height * 4
    var bytes = [UInt8](repeating: 0, count: byteCount)
    let copied = bytes.withUnsafeMutableBytes {
      Int(cf_readback_data(started, $0.baseAddress, Int32(byteCount)))
    }
    guard copied == byteCount else {
      error = KaniaError("a readback returned \(copied) bytes, not \(byteCount)")
      return true
    }
    pixels = (0..<width * height).map {
      Pixel(red: bytes[$0 * 4], green: bytes[$0 * 4 + 1], blue: bytes[$0 * 4 + 2], alpha: bytes[$0 * 4 + 3])
    }
    return true
  }
}
