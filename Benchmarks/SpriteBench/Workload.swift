import CCute

/// Window size shared with the C benchmark.
let width: Float = 1280
let height: Float = 720
let fixedDelta: Float = 1.0 / 60.0
let animations = ["up", "side", "hold_down", "hold_side", "hold_up", "idle"]

/// The same LCG as the C benchmark, so both place and move sprites identically.
struct Random {
  private var state: UInt32 = 1

  /// Returns the next value in [0, 1).
  mutating func next() -> Float {
    state = state &* 1_664_525 &+ 1_013_904_223
    return Float(state >> 8) / 16_777_216
  }

  /// Returns the next value in [low, high).
  mutating func next(in low: Float, _ high: Float) -> Float {
    low + (high - low) * next()
  }
}

/// A per-frame workload. `step(frame:)` submits one frame of draw commands and nothing else,
/// because it is the only part of the frame the benchmark attributes to the implementation.
@MainActor protocol Workload: AnyObject {
  /// Submits frame `frame`'s draw commands.
  func step(frame: Int)

  /// Sum of all sprite positions, compared against the C benchmark to prove equal work.
  var checksum: Double { get }
}

/// Generates the entities for `count` sprites in the order the C benchmark does, handing each
/// one's animation name, position and velocity to `body`. Creating the sprite is left to the
/// caller, because each implementation builds it through its own API.
func makeEntities(count: Int, _ body: (_ animation: String, _ position: CF_V2, _ velocity: CF_V2) -> Void) {
  var random = Random()
  for i in 0..<count {
    let px = random.next(in: -width / 2, width / 2)
    let py = random.next(in: -height / 2, height / 2)
    let vx = random.next(in: -100, 100)
    let vy = random.next(in: -100, 100)
    body(animations[i % animations.count], CF_V2(x: px, y: py), CF_V2(x: vx, y: vy))
  }
}
