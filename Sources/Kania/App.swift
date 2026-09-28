internal import CCute

/// The running app.
@MainActor
public enum App {
  /// Asks the app to stop. The current frame finishes, then the app shuts down.
  public static func quit() {
    cf_app_signal_shutdown()
  }

  /// The game SDL's callbacks drive.
  private static var runner: Runner?

  /// Runs `game` through SDL's main callbacks and returns the process exit status.
  ///
  /// SDL owns the frame loop: it calls back once to start, once per frame, for each event, and once
  /// to stop. The start, frame and stop callbacks run on the main thread, which is the main actor.
  static func run<G: Game & ~Copyable>(_ game: G.Type) -> Int32 {
    runner = Runner(window: G.window) { () throws(KaniaError) -> any FrameHandler in
      try GameHandler(game: G())
    }
    return SDL_RunApp(
      CommandLine.argc, CommandLine.unsafeArgv,
      { argc, argv in
        SDL_EnterAppMainCallbacks(
          argc, argv,
          { _, _, argv in
            MainActor.assumeIsolated { App.runner?.start(argv0: argv?.pointee) ?? SDL_APP_FAILURE }
          },
          { _ in
            MainActor.assumeIsolated { App.runner?.iterate() ?? SDL_APP_FAILURE }
          },
          { _, event in
            // SDL delivers lifecycle events straight from the thread that raised them. CF's event
            // queue is not thread-safe, so only events on the main thread reach it.
            if let event, SDL_IsMainThread() { cf_app_push_event(event) }
            return SDL_APP_CONTINUE
          },
          { _, _ in
            MainActor.assumeIsolated { App.runner?.stop() }
          })
      }, nil)
  }
}

/// One frame of a game, with the game's type erased.
@MainActor
protocol FrameHandler: AnyObject {
  /// Updates and draws the game once.
  func frame()
}

/// Holds a game and runs its frames.
@MainActor
final class GameHandler<G: Game & ~Copyable>: FrameHandler {
  private var game: G

  /// Holds `game`.
  init(game: consuming G) {
    self.game = game
  }

  func frame() {
    game.update()
    game.draw()
  }
}

/// Starts CF and the game, runs frames, and shuts both down, as SDL's callbacks ask.
@MainActor
final class Runner {
  private let window: WindowOptions
  private let makeGame: @MainActor () throws(KaniaError) -> any FrameHandler
  private var game: (any FrameHandler)?

  /// Frames left before the app quits by itself, from `KANIA_EXIT_AFTER_FRAMES`; `nil` runs until
  /// the game quits.
  private var framesLeft: Int?

  /// Creates a runner that opens `window`, then creates the game with `makeGame`.
  init(window: WindowOptions, makeGame: @escaping @MainActor () throws(KaniaError) -> any FrameHandler) {
    self.window = window
    self.makeGame = makeGame
  }

  /// Creates CF's app and window, then the game.
  func start(argv0: UnsafeMutablePointer<CChar>?) -> SDL_AppResult {
    let result = cf_make_app(
      window.title, 0, 0, 0, Int32(window.width), Int32(window.height),
      CF_AppOptionFlags(CF_APP_OPTIONS_WINDOW_POS_CENTERED_BIT.rawValue), argv0)
    if cf_is_error(result) {
      report(KaniaError(result))
      return SDL_APP_FAILURE
    }
    if let value = getenv("KANIA_EXIT_AFTER_FRAMES"), let frames = Int(String(cString: value)), frames > 0 {
      framesLeft = frames
    }
    do {
      game = try makeGame()
    } catch {
      report(error)
      return SDL_APP_FAILURE
    }
    return SDL_APP_CONTINUE
  }

  /// Runs one frame, then finishes what has to wait until it is presented: starting readbacks,
  /// destroying released GPU objects and running the main-actor jobs the frame queued.
  func iterate() -> SDL_AppResult {
    cf_app_update(nil)
    game?.frame()
    if let left = framesLeft {
      framesLeft = left - 1
      if left == 1 { cf_app_signal_shutdown() }
    }
    cf_app_draw_onto_screen(true)
    Readback.afterPresent()
    DestroyQueue.drain()
    #if !canImport(Darwin)
      cfs_drain_main_queue()
    #endif
    return cf_app_is_running() ? SDL_APP_CONTINUE : SDL_APP_SUCCESS
  }

  /// Releases the game, then CF. The game goes first, and the GPU objects it released are
  /// destroyed, while CF still exists.
  func stop() {
    game = nil
    Readback.cancelAll()
    DestroyQueue.drain()
    cf_destroy_app()
  }

  /// Prints why the app could not start.
  private func report(_ error: KaniaError) {
    cfs_host_print_error("Kania: \(error)\n")
  }
}
