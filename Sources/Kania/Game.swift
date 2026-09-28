internal import CCute

/// A game Kania runs.
///
/// Mark the conforming type `@main`. Kania supplies `main()`: it opens the window, creates the
/// game, then calls ``update()`` and ``draw()`` once per frame on the main actor, until the window
/// closes or the game calls ``App/quit()``.
///
/// ```swift
/// import Kania
///
/// @main
/// struct MyGame: Game {
///   mutating func update() {}
/// }
/// ```
@MainActor
public protocol Game {
  /// The window the game opens in.
  static var window: WindowOptions { get }

  /// Creates the game once the window and graphics are ready.
  init() throws(KaniaError)

  /// Advances the game by one frame.
  mutating func update()

  /// Queues the frame's drawing; Kania presents it when this returns.
  mutating func draw()
}

extension Game {
  /// A 1280 by 720 window titled "Kania".
  public static var window: WindowOptions { WindowOptions() }

  /// Draws nothing.
  public mutating func draw() {}

  /// Runs the game, then exits the process with status 0, or 1 if the game failed to start.
  public static func main() {
    exit(App.run(Self.self))
  }
}

/// How a game's window opens. The window opens centred on the main display.
public struct WindowOptions: Sendable {
  /// The title in the window's title bar.
  public var title: String

  /// The width of the window's content, in points.
  public var width: Int

  /// The height of the window's content, in points.
  public var height: Int

  /// Creates options for a window titled `title`, `width` by `height` points.
  public init(title: String = "Kania", width: Int = 1280, height: Int = 720) {
    self.title = title
    self.width = width
    self.height = height
  }
}
