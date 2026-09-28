// Checks Kania's frame loop on SDL's main callbacks: every frame runs on SDL's main thread, and a
// main-actor task started during one frame has run before the next frame's update. Exits with
// status 0 when both hold, and 1 with the reason when either does not.
import CCute
import Kania

/// Records whether the task started in frame 0 has run.
@MainActor
enum Probe {
  static var taskRan = false
}

@main
struct AppLoopTest: Game {
  static var window: WindowOptions { WindowOptions(title: "AppLoopTest", width: 320, height: 240) }

  private var frame = 0

  mutating func update() {
    guard SDL_IsMainThread() else { fail("frame \(frame) did not run on SDL's main thread") }
    switch frame {
    case 0:
      Task { @MainActor in Probe.taskRan = true }
    case 1:
      guard Probe.taskRan else { fail("a main-actor task started in frame 0 had not run by frame 1") }
    case 3:
      App.quit()
    default:
      break
    }
    frame += 1
  }
}

/// Prints why the test failed and exits with status 1.
func fail(_ reason: String) -> Never {
  cfs_host_print_error("AppLoopTest: \(reason)\n")
  exit(1)
}
