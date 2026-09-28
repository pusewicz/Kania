internal import CCute

/// An offscreen image that the game can render into and read back.
///
/// A canvas owns GPU memory, so it is `~Copyable`: exactly one value owns it. When that value goes
/// away, Kania destroys the canvas at the end of the frame, once nothing drawn this frame can still
/// use it. Refer to a canvas without owning it through its ``id``.
public struct Canvas: ~Copyable {
  /// CF's handle.
  let raw: CF_Canvas

  /// The width in pixels.
  public let width: Int

  /// The height in pixels.
  public let height: Int

  private var storedClearColor = Color(red: 0, green: 0, blue: 0, alpha: 0)

  /// Creates a `width` by `height` canvas that clears to transparent black.
  @MainActor
  public init(width: Int, height: Int) throws(KaniaError) {
    guard width > 0, height > 0 else {
      throw KaniaError("a canvas must be at least 1 by 1 pixel, not \(width) by \(height)")
    }
    let raw = cf_make_canvas(cf_canvas_defaults(Int32(width), Int32(height)))
    guard raw.id != 0 else { throw KaniaError("could not create a \(width) by \(height) canvas") }
    self.raw = raw
    self.width = width
    self.height = height
    cf_canvas_set_clear_color(raw, storedClearColor.cf)
  }

  deinit {
    DestroyQueue.destroyAtEndOfFrame(.canvas(raw.id))
  }

  /// The colour the canvas is filled with when rendering into it clears it.
  @MainActor
  public var clearColor: Color {
    get { storedClearColor }
    set {
      storedClearColor = newValue
      cf_canvas_set_clear_color(raw, newValue.cf)
    }
  }

  /// Identifies this canvas without owning it.
  public var id: ID { ID(raw: raw.id) }

  /// Identifies a canvas without owning it. Two IDs are equal when they name the same canvas.
  ///
  /// Once the canvas is destroyed, a new canvas may be given the same ID.
  public struct ID: Hashable, Sendable {
    let raw: UInt64
  }

  /// Starts copying the canvas's pixels back from the GPU.
  ///
  /// The copy starts once the current frame is presented, so it includes everything rendered into
  /// the canvas during this frame. Check the returned ``Readback`` in later frames.
  @MainActor
  public func readPixels() -> Readback {
    let readback = Readback(canvas: raw, width: width, height: height)
    Readback.queue(readback)
    return readback
  }
}
