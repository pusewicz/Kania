internal import CCute

/// An animated sprite: frames from an Aseprite file, with its own position, scale, opacity and
/// playback state.
///
/// A sprite is a value, so copies move and animate independently. The frame images are shared, and
/// stay loaded in CF's sprite cache.
public struct Sprite {
  /// CF's sprite.
  var raw: CF_Sprite

  /// CF's built-in demo sprite: a girl, with the animations "idle", "up", "side", "hold_down",
  /// "hold_side" and "hold_up".
  ///
  /// Loading it creates GPU textures, so call it once the game is running, from ``Game/init()`` on.
  @MainActor
  public static func demo() -> Sprite {
    Sprite(raw: cf_make_demo_sprite())
  }

  /// Where the sprite is drawn. The origin is the centre of the window, x points right and y up,
  /// and one unit is one point.
  public var position: SIMD2<Float> {
    get { SIMD2(raw.transform.p.x, raw.transform.p.y) }
    set { raw.transform.p = CF_V2(x: newValue.x, y: newValue.y) }
  }

  /// How much the sprite is stretched along x and y. At (1, 1) it is drawn at its original size.
  public var scale: SIMD2<Float> {
    get { SIMD2(raw.scale.x, raw.scale.y) }
    set { raw.scale = CF_V2(x: newValue.x, y: newValue.y) }
  }

  /// How opaque the sprite is drawn, from 0 (invisible) to 1 (fully opaque).
  public var opacity: Float {
    get { raw.opacity }
    set { raw.opacity = newValue }
  }

  /// The width of one frame in pixels, before scaling.
  public var width: Int { Int(raw.w) }

  /// The height of one frame in pixels, before scaling.
  public var height: Int { Int(raw.h) }

  /// Starts playing `animation` from its first frame.
  @MainActor
  public mutating func play(_ animation: String) {
    cf_sprite_play(&raw, animation)
  }

  /// Advances the animation by the time the last frame took.
  @MainActor
  public mutating func update() {
    cf_sprite_update(&raw)
  }

  /// Queues the sprite, handing CF this value's own storage rather than a copy. `mutating` only so
  /// the pointer is to this value in place; CF reads the sprite and does not change it.
  @MainActor
  mutating func draw() {
    cf_draw_sprite(&raw)
  }
}
