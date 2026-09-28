internal import CCute

/// Queues drawing for the current frame. Kania presents what is queued after ``Game/draw()``.
@MainActor
public enum Draw {
  /// Renders everything queued so far into `canvas` instead of the screen, clearing the canvas to
  /// its ``Canvas/clearColor`` first when `clearing` is true. Drawing queued afterwards goes to the
  /// screen as usual.
  public static func render(to canvas: borrowing Canvas, clearing: Bool = true) {
    cf_render_to(canvas.raw, clearing)
  }

  /// Queues `sprite`.
  public static func sprite(_ sprite: Sprite) {
    var sprite = sprite
    sprite.draw()
  }

  /// Queues every sprite in `sprites`, in order.
  ///
  /// The array is `inout` only so CF can read each sprite where it is stored; the sprites don't
  /// change. In Kania's benchmark this loop matches C, while drawing sprites one at a time with
  /// ``sprite(_:)`` copies each one first.
  public static func sprites(_ sprites: inout [Sprite]) {
    var span = sprites.mutableSpan
    for index in span.indices {
      unsafe span[unchecked: index].draw()
    }
  }
}
