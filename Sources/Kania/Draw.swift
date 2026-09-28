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
}
