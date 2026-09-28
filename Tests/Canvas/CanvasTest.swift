// Checks canvases: a canvas cleared to a colour reads back as that colour, a canvas released
// mid-frame is destroyed only after the frame is presented, and a zero-sized canvas is an error.
// Exits with status 0 when all hold, and 1 with the reason when one does not.
import CCute
import Kania

@main
struct CanvasTest: Game, ~Copyable {
  static var window: WindowOptions { WindowOptions(title: "CanvasTest", width: 320, height: 240) }

  private static let side = 32
  private static let red = Pixel(red: 255, green: 0, blue: 0, alpha: 255)

  private var canvas: Canvas
  private var readback: Readback?
  private var frame = 0

  init() throws(KaniaError) {
    canvas = try Canvas(width: Self.side, height: Self.side)
    canvas.clearColor = Color(red: 1, green: 0, blue: 0)
  }

  mutating func update() {
    switch frame {
    case 0:
      checkZeroSizedCanvasThrows()
      releaseCanvasMidFrame()
      Draw.render(to: canvas)
      readback = canvas.readPixels()
    case 1:
      let pending = Diagnostics.pendingDestroyCount
      guard pending == 0 else { fail("canvases from frame 0 still waiting to be destroyed: \(pending)") }
    default:
      checkReadback()
    }
    frame += 1
  }

  private func checkZeroSizedCanvasThrows() {
    do {
      _ = try Canvas(width: 0, height: 8)
      fail("a 0 by 8 canvas was created")
    } catch {}
  }

  /// Renders into a canvas that goes away at the end of this function, then checks that it is
  /// waiting to be destroyed rather than destroyed already.
  private func releaseCanvasMidFrame() {
    do {
      let scratch = try Canvas(width: 8, height: 8)
      Draw.render(to: scratch)
    } catch {
      fail("could not create a canvas: \(error)")
    }
    let pending = Diagnostics.pendingDestroyCount
    guard pending == 1 else { fail("canvases waiting to be destroyed mid-frame: \(pending), not 1") }
  }

  private func checkReadback() {
    guard let readback else { fail("no readback was started") }
    if let error = readback.error { fail("the readback failed: \(error)") }
    guard let pixels = readback.pixels else {
      if frame > 60 { fail("the readback had not finished by frame 60") }
      return
    }
    guard pixels.count == Self.side * Self.side else {
      fail("the readback returned \(pixels.count) pixels, not \(Self.side * Self.side)")
    }
    if let wrong = pixels.firstIndex(where: { $0 != Self.red }) {
      fail("pixel \(wrong) of the red canvas read back as \(pixels[wrong])")
    }
    App.quit()
  }
}

/// Prints why the test failed and exits with status 1.
func fail(_ reason: String) -> Never {
  cfs_host_print_error("CanvasTest: \(reason)\n")
  exit(1)
}
